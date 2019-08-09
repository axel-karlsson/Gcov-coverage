# **Code coverage analyzer.**

Should statically link to the llvm tool "llvm-cov" and call the external functions from the app.d file, for example. Preferably, the arguments given should be passed on to the functions that llvm-cov contains.

Link: *https://github.com/llvm-mirror/llvm/tree/master/tools/llvm-cov*

## **Setup: Linkage**
Compile the C++ files and include the necessary dependencies in order to generate the object files (.o file). Use the -c file with GCC in order to discard the gcc linker. The D compiler will take care of the linking instead.

#### Example:
 *g++ -lstd=c++11 __fileToBuild.cpp__ -I __fileToInclude.h__  -c* will generate __fileToBuild.o__

Setup dub and use to build the D files with __*dub build*__. Use __*dub run*__ in order to build and run the program,  

Link to instructions on how to install dub:
*https://dub.pm/*

In __dub.sdl__ setup dependencies, flags and sourceFiles. To make an executable, specify this in the targetType.

#### Example:
targetType "*executable*"

lflags "*flagToInclude*"

libs   "*libToSetup*"

sourcefile "*sourceFileToInclude" (fileToBuild.o)*

__Also:__ See the current .sdl file for examples.

Link to information about dub sdl: *https://dub.pm/package-format-sdl*

When running the command __*dub build*__ the D compiler will try to link the object files to the project. This way we can make use of external functions from the C++ program in our D code via interfacing.

Link to info about interfacing with C++: *https://dlang.org/spec/cpp_interface.html*

## Current status


The current __app.d__ should call functions from llvm-cov in order to use its code coverage. See the link mentioned above in order to look through the llvm-cov repository as well as the tool llvm-cov and its relevant files. These files can be used to compile with gcc and generate object files.


## Notes when interfacing to C++

Strings in D are not zero terminated. This means that they have to be converted to a C++ string in order to properly use them together with the external C++ functions. In order to enable sending strings between D and C++, look inside the __*cpp_source*__ folder.
