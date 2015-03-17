# Introduction #

The _mrmath_ library contains a set of functions for matrix manipulation. It contains a hughe set for standard matrix handling - like adding or multiplying two matrices as well as function to apply a transformation function on each matrix element. In addition the library contains quite a set of standard linear algebra functions like the QR decomposition or Singular Value Decomposition.

An aim of this library was to provide highly optimized assembler versions in both x86 and x64 code for at least the lower level functions. To access the optimized functionality one needs at least a SSE3 capable processer - anyway the library decides on startup if the processor offers the expected features and if not it switches back to the pure Pascal implementation.

The library itself is split into three parts: the first one consists of a set of pure Pascal procedural functions, a set of procedural highly optimized assembler functions in x86 and x64 versions and a matrix class tying the procedural functions together for easy matrix manipulation.

# Installation #

To install the library download the library and add the base directory as well as the mac and win directory to the library path open and compile the _marMath.dpk_ file so the package gets installed. From now on you should be able to add the matrix functions to your project.

# Memory layout #

A matrix is basically interpreted and also stored as an array of double values. The interpretation is row wise e.g. a 4x4 matrix is stored in an array of 16 double values whereas the first row consists of the first 4 values in the array, the second row of the next 4 values etc.

To be more flexible in the calculations and to exihibit the advantages of proper memory alignment all of the functions provide some kind of _LineWidth_ parameter for the input and output matrices. This also allows you to easily address sub matrices without doing any memory reallocation.

# Matrix class #

The matrix class provides an interface for base matrix manipulation and matrix memory management. It is basically a wrapper around the standard procedural functions and cares about the nasty details regarding memory management, data access and data initialization.

  * [Construction of objects and assigning data - memory management](MatrixConstructors.md)
  * [Loading and storing data from and to a stream/file](Persistence.md)
  * [Simple matrix manipulation function](SimpleMatrixFct.md)
  * [Linear algebra](LinAlg.md)
  * Eigenvalue calculation