#!/usr/bin/env julia
using Base: LineEdit, REPL
using Base.LineEdit: Prompt

function stripblock(block::Vector{SubString{String}})
    length(block) > 0 && block[1] == "begin" || return block
    shift!(block)

    length(block) > 0 && block[end] == "end" || return :incomplete
    pop!(block)
    block
end

splitstring(x) = split(String(x), "\n"; keep=false)

function return_callback(leps::LineEdit.PromptState)
    # this could probably be more efficient
    tmp = splitstring(LineEdit.buffer(leps))
    stripblock(tmp) !== :incomplete
end

function RunShell(lang::AbstractString = "mdl")
    t = Base.Terminals.TTYTerminal("xterm", STDIN, STDOUT, STDERR)
    repl = REPL.LineEditREPL(t)

    replc = REPL.REPLCompletionProvider()
    render_prompt = Prompt(rpad(lang, 5) * "> ";
                           prompt_prefix = repl.hascolor ? Base.text_colors[:magenta] : "",
                           prompt_suffix = repl.hascolor ? Base.input_color : "",
                           keymap_func_data = repl,
                           on_enter = return_callback)

    # unified history
    hp = REPL.REPLHistoryProvider(Dict{Symbol,Any}(:render => render_prompt))

    REPL.history_reset_state(hp)
    render_prompt.hist = hp

    render_prompt.on_done = (s, buf, ok) -> begin
        ok || return transition(s, :abort)
        try
            # this is awfully complicated
            toparse = String.(take!(buf) |> splitstring |> stripblock)
            ps = Render.renderfile(toparse, lang)
            length(toparse) == 1 && Render.display(ps, `display`)
        catch err
            REPL.print_response(repl, err, catch_backtrace(), true, Base.have_color)
        end
        REPL.reset(repl)
        REPL.prepare_next(repl)
        REPL.reset_state(s)
        s.current_mode.sticky || transition(s, render_prompt)
    end

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)

    repl_transition(symb::Char, mode, s, o...) = begin
        if isempty(s) || position(LineEdit.buffer(s)) == 0
            buf = copy(LineEdit.buffer(s))
            LineEdit.transition(s, mode) do
                LineEdit.state(s, mode).input_buffer = buf
            end
        else
            edit_insert(s, symb)
        end
    end

    prefix_prompt, prefix_keymap = LineEdit.setup_prefix_keymap(hp, render_prompt)

    a = Dict{Any,Any}[skeymap, prefix_keymap, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]
    render_prompt.keymap_dict = LineEdit.keymap(a)

    b = Dict{Any,Any}[skeymap, REPL.mode_keymap(render_prompt), prefix_keymap, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]

    modal = LineEdit.ModalInterface([render_prompt, search_prompt, prefix_prompt])

    println("""
            Welcome to interactive mode!
            Every block is parsed as a separate file.
            The special keywords `begin` and `end` are available for declaring multi-line blocks.
            A line outside of a block will be run, and then displayed.
            """)

    REPL.run_interface(t, modal)
end
RunShell()

