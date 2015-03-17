# Simple Matrix Operations #

This section describes the usage of the simple simple matrix operations
**Add/sub** Mul/Transpose
**Functions applied to each element** Mean and sum

Most of the functions have two forms. One returns a complete new matrix object the other one operates on the calling object and replaces it's memory by the result. The functions also come in two flavors one with interfaces and one without. Do not mix them in code!

## Add/Sub/Element wise multiplication ##

The matrix addition and matrix subtraction is simply a value by
value operation on each element so an addition is defined as
`c[x, y] = a[x, y] + b[x, y]` and the element wise multiplication as
`c[x, y] = a[x, y] * b[x, y]`

```
    procedure AddInplace(Value : TDoubleMatrix); overload;
    function Add(Value : TDoubleMatrix) : TDoubleMatrix; overload;
    procedure SubInPlace(Value : TDoubleMatrix); overload;
    function Sub(Value : TDoubleMatrix) : TDoubleMatrix; overload;
    
    procedure AddInplace(Value : IMatrix); overload;
    function Add(Value : IMatrix) : TDoubleMatrix; overload;
    procedure SubInPlace(Value : IMatrix); overload;
    function Sub(Value : IMatrix) : TDoubleMatrix; overload;

    procedure ElementWiseMultInPlace(Value : TDoubleMatrix); overload;
    function ElementWiseMult(Value : TDoubleMatrix) : TDoubleMatrix; overload;
     
    procedure ElementWiseMultInPlace(Value : IMatrix); overload;
    function ElementWiseMult(Value : IMatrix) : TDoubleMatrix; overload;
```

## Multiplication/Transposition ##

The base matrix multiplication algorithm is implemented as a recursive version of the Strassen multiplication until a certain matrix size is reached. Then the algorithm changes from the general matrix multiplication algorithm to a blocked version which internally still uses the Strassen algorithm. Use the global variable `BlockedMatrixMultSize` to change the default settings.

Note: One can switch the libs default behaviour by using the `InitMathFunctions` in `OptimizedFuncs.pas` to setup the multiplication mode as well as turning SSE optimizations completely off.

One element is calculated as c[i, j] = sum\_n(a[n,j]**b[i,n])**

```
    procedure MultInPlace(Value : IMatrix); overload;
    function Mult(Value : IMatrix) : TDoubleMatrix; overload;
    procedure MultInPlace(Value : TDoubleMatrix); overload;
    function Mult(Value : TDoubleMatrix) : TDoubleMatrix; overload;

    procedure TransposeInPlace;
    function Transpose : TDoubleMatrix;
```

## Element wise functions ##

Element wise functions are simply functions applied to each element of the matrix.

```
    procedure AddAndScaleInPlace(const Offset, Scale : double);
    function AddAndScale(const Offset, Scale : double) : TDoubleMatrix;

    function Scale(const Value : double) : TDoubleMatrix;
    procedure ScaleInPlace(const Value : Double);
    function ScaleAndAdd(const Offset, Scale : double) : TDoubleMatrix;
    procedure ScaleAndAddInPlace(const Offset, Scale : double);
    function SQRT : TDoubleMatrix;
    procedure SQRTInPlace;

    procedure ElementwiseFuncInPlace(func : TMatrixFunc); overload;
    function ElementwiseFunc(func : TMatrixFunc) : TDoubleMatrix; overload;
    procedure ElementwiseFuncInPlace(func : TMatrixObjFunc); overload;
    function ElementwiseFunc(func : TMatrixObjFunc) : TDoubleMatrix; overload;
    procedure ElementwiseFuncInPlace(func : TMatrixMtxRefFunc); overload;
    function ElementwiseFunc(func : TMatrixMtxRefFunc) : TDoubleMatrix; overload;
    procedure ElementwiseFuncInPlace(func : TMatrixMtxRefObjFunc); overload;
    function ElementwiseFunc(func : TMatrixMtxRefObjFunc) : TDoubleMatrix; overload;

    procedure MaskedSetValue(const Mask : Array of boolean; const newVal : double);
```

Notes:
  * The difference of AddAndScale and ScaleAndAdd is the order of execution. The AddAndScale routine first adds a value and then scales it (and vice versa)
  * The routine SQRT applies the root function on each element separately don't confuse it with the root of a matrix.
  * The MaskedSetValue treats the matrix as a vector! So the first row of the matrix is reflected in the first n elements of the mask.

## Examples ##

Multiplying two matrices

```
  procedure TestIMatrix.TestMult2;
const x : Array[0..8] of double = (1, 2, 3, 4, 5, 6, 7, 8, 9);
    y : Array[0..8] of double = (0, 1, 2, 3, 4, 5, 6, 7, 8);
    res : Array[0..8] of double = (24, 30, 36, 51, 66, 81, 78, 102, 126);
var m1, m2 : IMatrix;
    m3 : IMatrix;
begin
     m1 := TDoubleMatrix.Create;
     m1.Assign(x, 3, 3);
     m2 := TDoubleMatrix.Create;
     m2.Assign(y, 3, 3);

     m3 := m1.Mult(m2);

     Check(CheckMtx(res, m3.SubMatrix, 3, 3), 'Error multiplication failed');
end;
```

Transposition/multiplication of a matrix

```
procedure TransposeMult;
var mtx : IMatrix;
    m1, m2 : IMatrix;
const x : Array[0..8] of double = (1, 2, 3, 4, 5, 6, 7, 8, 9);

begin
     m1 := TDoubleMatrix.Create; 
     m1.Assign(x, 3, 3);
     m2 := m1.Transpose;
     mtx := fRefMatrix1.Mult(mtx1);
end;
```

Applying a function to each element of the matrix

```

procedure sinxDivX(var x : double);
begin
     if SameValue(x, 0, 1e-7)
     then 
         x := 1
     else
         x := sin(x)/x;
end;

procedure ApplyFunc;
var m1 : IMatrix;
    m2 : IMatrix;
    i : integer;
begin
     m1 := TDoubleMatrix.Create(100, 1); 
     for i := 0 to 99 do
         m1[i, 0] := -pi + pi/100;
     m2 := m1.ElementwiseFunc(sinxDivX);
end;
```