ffmpeg-android-macosx
==============

Build scripts to create shared libraries of FFMPEG 3.2 for android apps on MacOS X including platform 21+ 64 bit support. Additional Audio-decoding-only script included for specific app purposes.

building
========

Building is straight forward.
 - execute ./build.sh found in the top level directory.

./build.sh -? will print out which command line arguments are supported.

Example
=======
`
./build.sh -a "/User/bob/Library/Android/sdk/ndk-bundle" -p 21 -v
`

Fork
====
All code was originally forked from [akallabeth/ffmpeg-android](https://github.com/akallabeth/ffmpeg-android)


Known Bugs
====
None
