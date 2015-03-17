# Linear Algebra #

Most of the linear algebra functionality are a direct conversion from the numerical recipies in C book (second edition) - so their basics are quite simple and can be looked up there. The routins translated from there
are:

  * Singular Value decomposition
  * QR Decomposition
  * Cholesky Decomposition
  * Gauss Jordan elimination (though not exposed in the matrix class)

Since these original algorithms are not cache oblivious the performance may not be as good as in the simple matrix operations.

An exception here is the LU decomposition which is based on the recursive implementation of the standard LU decomp. The algrithm splits the matrix into two rectangles (m x n/2) until the left part ends up being only a single column.  After that operation the matrix contains 4 parts:

```
A =  L  A12
    A21 A22
```

We then apply transformations on the right part (solve A<sub>12</sub> = L<sup>-1</sup>A<sub>12</sub> and A<sub>22</sub>= A<sub>22</sub> - A<sub>21</sub>A<sub>12</sub>) and apply the LU Algorithm on the right part. The most work in the algrithm is done within the matrix multiplication which can profit from multiple cores.

In the library itself the matrix inversion and matrix determinant calculation are based on the LU decomposition.

In addition the QR Algorithm has now been updated such that it's cache oblivious and uses a panel based approach similar to the one used in linpack (netlib.org). The matrix multiplications used in that algorithm make use of multiple cores meaning that most of the new implementation can benifit from that.