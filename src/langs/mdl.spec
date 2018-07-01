General Notes:

Items seperated by | are mutually exclusive.
Items enclosed in [] are optional.

For example, rotate is specified as:
rotate x|y|z degress [knob]

The following would be valid rotations:
rotate x 20
rotate y 23 k1

While the following would be invalid:
rotate x|y 20
rotate x y 33
rotate x 33 [k1]


Stack commands
--------------
push    creates a copy of the current coordinate system at the top of the stack
pop     removes the coordinate system at the top of the stack


Transformations
---------------
If a knob is specified, the transformation is scaled by the knob value.
Transformations modify the current coordinate system.

move x y z [knob]               translate
scale x y z [knob]              scale
rotate x|y|z degrees [knob]     rotate (takes only one axis per instruction)


Image creation
--------------
Points will be transformed by the current coordinate system unless coord_system is specified.

sphere x y z r
torus x y z r0 r1
box x0 y0 z0 h w d
    ^        ^~~~~ height, width, and depth of the box
    `~~~~~~~ a corner of the box

line x0 y0 z0 x1 y1 z1


Knobs/Animation
---------------
basename name                                       sets the base filename to save under
frames num_frames                                   the total number of frames
vary knob start_frame end_frame start_val end_val   vary a knob from start_val to end_val over the course of start_frame to end_frame


Miscellaneous
-------------
//                          comment to the end of a line
save filename               save the image in its current state as "filename"
display                     display the current image on the screen

