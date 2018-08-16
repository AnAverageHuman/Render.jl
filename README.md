# Render.jl

[![Build Status](https://travis-ci.com/AnAverageHuman/Render.jl.svg?branch=master)](https://travis-ci.com/AnAverageHuman/Render.jl)

An implementation of a rendering engine, written in Julia.

## Installation

Julia will automatically resolve dependencies when the package is installed like so:

```julia
julia> Pkg.clone("https://github.com/AnAverageHuman/Render.jl")
```

## Usage

### From Julia

A `renderfile()` function is provided. It processes instructions for rendering
an image, given that the instruction language is supported.

Example rendering "scripts" are provided in the [scripts](scripts/) directory.

### Standalone

A Makefile is provided for standalone use in `~/.julia/v0.6/Render/`.

To use an interactive prompt:

```sh
$ make interactive
```

To run a script, either of the following works:

```sh
$ make SCRIPT=/path/to/script

$ SCRIPT=/path/to/script make
```

