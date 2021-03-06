// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2011, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit TestLineEquations;

interface

uses
  {$IFDEF FPC} testregistry {$ELSE} TestFramework {$ENDIF} ,
  Classes, SysUtils, Types, OptimizedFuncs, BaseMatrixTestCase,
  MatrixConst;

type
 // Testmethoden f�r Klasse TDoubleMatrix

 TTestLinearEquations = class(TBaseMatrixTestCase)
 published
  procedure TestDeterminant1;
  procedure TestDeterminant2;
  procedure TestGaussJordan1;
  procedure TestLUDecomp1;
  procedure TestLUBackSubst1;
  procedure TestLUBackSubst2;
  procedure TestInvert1;
  procedure TestInvert2;
  procedure TestInvert3;
  procedure TestSVD1;
  procedure TestSVD2;
  procedure TestSVD3;
  procedure TestCholesky;
  procedure TestCholesky2;
  procedure TestCholesky3;
  procedure TestQRDecomp;
  procedure TestQRDecomp2;
  procedure TestQRDecomp3;
  procedure TestFullQRDecomp;
  procedure TestLargeFullQRDecomp;
  procedure TestAsymQRDecomp1;
  procedure TestAsymQRDecomp2;
  procedure TestPseudoInversion;
  procedure TestPseudoInversion2;
  procedure TestBigLUDecomp;
  procedure TestMatrixSolve;
 end;

implementation

uses LinearAlgebraicEquations, MtxThreadPool, ThreadedLinAlg, math, MtxTimer;

{ TestTDoubleMatrix }

procedure TTestLinearEquations.TestBigLUDecomp;
const cBlkWidth = 1024;
      cBlkSize = cBlkWidth*cBlkWidth;

var x, y : TDoubleDynArray;
    i: Integer;
    idx : Array[0..cBlkWidth-1] of integer;
    start, stop : Int64;
    index : integer;
begin
     InitMtxThreadPool;

     SetLength(x, cBlkSize);
     SetLength(y, cBlkSize);

     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         x[i] := Random - 0.5;

     x[0] := 0.4;
     x[1] := 0.7;
     x[2] := -0.2;
     x[3] := 0.8;
     x[4] := 0.1;
     x[5] := -0.1;
     x[6] := -0.7;
     x[7] := 0.3;
     x[8] := -0.2;
     x[9] := 0.25;
     x[10] := 0.15;
     x[11] := -0.11;
     x[12] := -0.79;
     x[13] := 0.34;
     x[14] := -0.25;
     x[15] := 0.44;

     index := 0;
    // WriteMatlabData('D:\x.txt', x, cBlkWidth);
     Move(x[0], y[0], sizeof(double)*length(x));

     start := MtxGetTime;
     MatrixLUDecompInPlace(@x[0], cBlkWidth*sizeof(double), cBlkWidth, @idx[0], nil);
     stop := MtxGetTime;
     Status(Format('Blocked LU decomp: %.2fms', [(stop - start)/mtxFreq*1000]));

    // WriteMatlabData('D:\xlu.txt', x, cBlkWidth);

     start := MtxGetTime;
     ThrMatrixLUDecomp(@y[0], cBlkWidth*sizeof(double), cBlkWidth, @idx[0], nil);
     stop := MtxGetTime;
     Status(Format('Threaded LU decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     FinalizeMtxThreadPool;

     Check(CheckMtxIdx(x, y, index), Format('error LU decomposition. Error at x[%d] = %.5f, y[%d] = %.5f', [index, x[index], index, y[index]]));
end;

procedure TTestLinearEquations.TestCholesky;
const A : Array[0..8] of double = (1, 2, 2, -1, 4, -2, 2, 2, -1);
      B : Array[0..2] of double = (2, -1, -1);
      cResX : Array[0..2] of double = (0.338888889, 0.00555555556, -0.2666666667);

var AL : TDoubleDynArray;
    X : TDoubleDynArray;
    P : Array[0..8] of double;
    res : TCholeskyResult;
    ResX : Array[0..2] of double;
begin
     AL := MatrixTranspose(@A[0], 3*sizeof(double), 3, 3);
     X := MatrixMult(@A[0], @AL[0], 3, 3, 3, 3, 3*sizeof(double), 3*sizeof(double));

     FillChar(P[0], sizeof(P), 0);
     res := MatrixCholeskyInPlace(@X[0], 3*sizeof(double), 3, @P[0], 4*sizeof(double));
     Check(res = crOk, WriteMtx(X, 3));

     Move(A, X[0], sizeof(A));
     FillChar(P[0], sizeof(P), 0);
     res := MatrixCholeskyInPlace(@X[0], 3*sizeof(double), 3, @P[0], 4*sizeof(double));

     Check(res = crNoPositiveDefinite, WriteMtx(X, 3));

     // check solver
     X := MatrixMult(@A[0], @AL[0], 3, 3, 3, 3, 3*sizeof(double), 3*sizeof(double));
     MatrixCholeskyInPlace(@X[0], 3*sizeof(double), 3, @P[0], 4*sizeof(double));
     MatrixCholeskySolveLinEq(@X[0], 3*sizeof(double), 3, @P[0], 4*sizeof(double), @B[0], sizeof(double), @ResX[0], sizeof(double));

     Check(CheckMtx(ResX, cResX), 'Cholesky error');
end;

procedure TTestLinearEquations.TestCholesky2;
const cA : Array[0..8] of double = (1, 2, 2, -1, 4, -2, 2, 2, -1);
      cA2 : Array[0..15] of double = (1, 2, 2, 0.5,
                                   -1, 4, -2, -0.1,
                                   2, 2, -1, 1.2,
                                   3, 2, -1, -1.1);
var A : Array[0..8] of double;
    AL, X, X1 : TDoubleDynArray;
    res : TCholeskyResult;
begin
     AL := MatrixTranspose(@cA[0], 3*sizeof(double), 3, 3);
     X := MatrixMult(@cA[0], @AL[0], 3, 3, 3, 3, 3*sizeof(double), 3*sizeof(double));
     X1 := copy(X, 0, Length(x));

     res := MatrixCholeskyInPlace4(@X1[0], 3*sizeof(double), 3, 2);

     Check(res = crOk, 'Cholesky failed');
     
     Status(WriteMtx(x1, 3));
     
     res := MatrixCholeskyInPlace2(@X[0], 3*sizeof(double), 3);

     Status(WriteMtx(X, 3));
     Check(res = crOk, WriteMtx(x, 3));


     AL := MatrixTranspose(@cA2[0], 4*sizeof(double), 4, 4);
     X := MatrixMult(@cA2[0], @AL[0], 4, 4, 4, 4, 4*sizeof(double), 4*sizeof(double));

     res := MatrixCholeskyInPlace2(@X[0], 4*sizeof(double), 4);

     Status(WriteMtx(X, 4));
     Check(res = crOk, WriteMtx(x, 4));

     AL := MatrixTranspose(@cA2[0], 4*sizeof(double), 4, 4);
     X := MatrixMult(@cA2[0], @AL[0], 4, 4, 4, 4, 4*sizeof(double), 4*sizeof(double));

     res := MatrixCholeskyInPlace4(@X[0], 4*sizeof(double), 4, 2);

     Status(WriteMtx(X, 4));
     Check(res = crOk, WriteMtx(x, 4));
     
     Move(cA, A[0], sizeof(cA));
     res := MatrixCholeskyInPlace2(@A[0], 3*sizeof(double), 3, nil);
     Check(res = crNoPositiveDefinite, WriteMtx(A, 3));
end;

procedure TTestLinearEquations.TestCholesky3;
const cLargeCholSize = 2048;
var x, y : TDoubleDynArray;
    p1, p2 : PDouble;
    a, a1, a2, a3 : TDoubleDynArray;
    res : TCholeskyResult;
    start, stop : Int64;
begin
     InitMtxThreadPool;

     FillMatrix(cLargeCholSize*cLargeCholSize, x, y, p1, p2);
     FreeMem(p1);
     FreeMem(p2);

     y := MatrixTranspose(@x[0], cLargeCholSize*sizeof(double), cLargeCholSize, cLargeCholSize);

     a := MatrixMult(x, y, cLargeCholSize, cLargeCholSize, cLargeCholSize, cLargeCholSize);

//     WriteMatlabData('D:\cholIn.txt', a, cLargeCholSize);
     a1 := Copy(a, 0, Length(a));
     a2 := Copy(a, 0, Length(a));
     a3 := Copy(a, 0, Length(a));

     start := MtxGetTime;
     res := MatrixCholeskyInPlace2(@a[0], cLargeCholSize*sizeof(double), cLargeCholSize);
     stop := MtxGetTime;
     Status(Format('Cholesky large %d: %.2fms', [cLargeCholSize, (stop - start)/mtxfreq*1000]));

     Check(res = crOk, 'Error large cholesky failed');

     start := MtxGetTime;
     res := MatrixCholeskyInPlace3(@a1[0], cLargeCholSize*sizeof(double), cLargeCholSize);
     stop := MtxGetTime;                            
     Status(Format('Cholesky large recursive %d: %.2fms', [cLargeCholSize, (stop - start)/mtxfreq*1000]));

     Check(res = crOk, 'Error large cholesky failed');

     start := MtxGetTime;
     res := MatrixCholeskyInPlace4(@a2[0], cLargeCholSize*sizeof(double), cLargeCholSize, 24);
     stop := MtxGetTime;                            
     Status(Format('Cholesky large panel: %.2fms', [(stop - start)/mtxfreq*1000]));

     Check(res = crOk, 'Error large cholesky failed');

     start := MtxGetTime;
     res := ThrMatrixCholeskyDecomp(@a3[0], cLargeCholSize*sizeof(double), cLargeCholSize, 24, nil, nil);
     stop := MtxGetTime;                            
     Status(Format('Cholesky threaded: %.2fms', [(stop - start)/mtxfreq*1000]));

     Check(res = crOk, 'Error in threaded cholesky decomp');
     
     Check(CheckMtx(a, a2), 'Panel implementation of Cholesky decomposition failed');
     Check(CheckMtx(a, a1), 'Recursive implementation of Cholesky decomposition failed');
     Check(CheckMtx(a, a3), 'Threaded implementation of Cholesky decomposition failed');
     
//     WriteMatlabData('D:\cholOut.txt', a, cLargeCholSize);
//     WriteMatlabData('D:\cholOut1.txt', a1, cLargeCholSize);
//     WriteMatlabData('D:\cholOut2.txt', a2, cLargeCholSize);

     FinalizeMtxThreadPool;
end;

procedure TTestLinearEquations.TestDeterminant1;
const A : Array[0..3] of double = (1, 2, 2, -1);
var det : double;
begin
     det := MatrixDeterminant(@A[0], 2*sizeof(double), 2);

     Check(det = -5, 'Error determinant differs: ' + Format('%.3f', [det]));
end;

procedure TTestLinearEquations.TestDeterminant2;
const cBlkWidth = 256;
      cBlkSize = cBlkWidth*cBlkWidth;
var x : TDoubleDynArray;
    i: Integer;
    start, stop : Int64;
    det, detThr : double;
begin
     InitMtxThreadPool;
     // big inversion
     SetLength(x, cBlkSize);
     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         x[i] := Random/3.8 - 0.5/3.8;

     //WriteMatlabData('d:\x1.txt', x, cBlkWidth);

     start := MtxGetTime;
     det := MatrixDeterminant(@x[0], cBlkWidth*sizeof(double), cBlkWidth);
     Check(det <> 0, 'Singular matrix');
     stop := MtxGetTime;
     Status(Format('Big determinant: %.2fms with value %.5f', [(stop - start)/mtxfreq*1000, det]));

     start := MtxGetTime;
     detThr := ThrMatrixDeterminant(@x[0], cBlkWidth*sizeof(double), cBlkWidth);
     Check(detThr <> 0, 'Singular matrix');
     stop := MtxGetTime;

     Status(Format('Big threaded determinant: %.2fms with value %.5f', [(stop - start)/mtxfreq*1000, detThr]));

     FinalizeMtxThreadPool;

     Check(SameValue(det, detThr), 'Error Determinants differ too much');
end;

procedure TTestLinearEquations.TestGaussJordan1;
const A : Array[0..3] of double = (1, 2, 2, -1);
      B : Array[0..1] of double = (1, 1);
      D : Array[0..3] of double = (1, 2, 2, 4);
var invA : Array[0..3] of double;
    solvedX : Array[0..1] of double;
    res : TLinEquResult;
begin
     Move(A, invA, sizeof(A));
     Move(B, solvedX, sizeof(B));

     res := MatrixGaussJordanInPlace(@invA[0], 2*sizeof(double), @solvedX[0], sizeof(double), 2, 1);

     Check(res = leOk, 'Singularity detected');

     Move(D, invA, sizeof(A));
     Move(B, solvedX, sizeof(B));
     res := MatrixGaussJordanInPlace(@invA[0], 2*sizeof(double), @solvedX[0], sizeof(double), 2, 1);

     Check(res = leSingular, 'Singularity missed');     
end;

procedure TTestLinearEquations.TestInvert1;
const A : Array[0..3] of double = (1, 2, 2, -1);
      AInv : Array[0..3] of double = (0.2, 0.4, 0.4, -0.2);
var Inv : Array[0..3] of double;
    res : TLinEquResult;
begin
     Move(A, Inv, sizeof(A));

     res := MatrixInverseInPlace(@Inv[0], 2*sizeof(double), 2);
     Check(res = leok, 'Singularity detected!');
     CheckEqualsMem(@AInv[0], @inv[0], sizeof(AInv), 'Error inverting Mtx: ' + WriteMtx(inv, 2));
end;

procedure TTestLinearEquations.TestInvert2;
const A : Array[0..8] of double = (1, 2, 3, 2, 4, 6, 3, 3, -1);
var inv : Array[0..8] of double;
begin
     move(A, inv, sizeof(a));

     Check(MatrixInverseInPlace(@inv[0], 3*sizeof(double), 3) = leSingular, 'Matrix inversion seems not to be singular');
end;

procedure TTestLinearEquations.TestInvert3;
const cBlkWidth = 512;
      cBlkSize = cBlkWidth*cBlkWidth;
var x, y : TDoubleDynArray;
    i: Integer;
    start, stop : Int64;
begin
     InitMtxThreadPool;
     // big inversion
     SetLength(x, cBlkSize);
     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         x[i] := Random - 0.5;

     //WriteMatlabData('D:\x1.txt', x, cBlkWidth);

     y := Copy(x, 0, Length(x));

     start := MtxGetTime;
     Check(MatrixInverseInPlace(@x[0], cBlkWidth*sizeof(double), cBlkWidth) <> leSingular, 'Matrix inversion seems not to be singular');
     stop := MtxGetTime;
     Status(Format('Big Inversion: %.2fms', [(stop - start)/mtxfreq*1000]));

     start := MtxGetTime;
     Check(ThrMatrixInverse(@y[0], cBlkWidth*sizeof(double), cBlkWidth) <> leSingular, 'Matrix inversion seems not to be singular');
     stop := MtxGetTime;
     Status(Format('Big Inversion Threaded: %.2fms', [(stop - start)/mtxfreq*1000]));

     //WriteMatlabData('D:\invx.txt', x, cBlkWidth);
     FinalizeMtxThreadPool;
     check(checkMtx(x, y), 'Error inversion of the threaded version is not the same as the single thread one');
end;

procedure TTestLinearEquations.TestLUBackSubst1;
const A : Array[0..3] of double = (1, 2, 2, -1);
      C : Array[0..3] of double = (2, -1, 0.5, 2.5);
      D : Array[0..1] of double = (0, 1);
var LUDecomp : Array[0..3] of double;
    res : TLinEquResult;
    idx : Array[0..1] of integer;
    B : Array[0..1] of double;
begin
     Move(A, LUDecomp, sizeof(A));

     idx[0] := 0;
     idx[1] := 0;
     res := MatrixLUDecompInPlace(@LUDecomp[0], 2*sizeof(double), 2, @idx[0]);

     Check(res = leOk, 'Singularity detected!');
     CheckEqualsMem(@C[0], @LUDecomp[0], sizeof(C), 'LU decomp failed with: ' + WriteMtx(LUDecomp, 2));

     // back substitute
     B[0] := 2;
     B[1] := -1;
     MatrixLUBackSubst(@LUDecomp[0], 2*sizeof(double), 2, @idx[0], @B[0], sizeof(double));

     CheckEqualsMem(@D[0], @B[0], sizeof(D), 'Error solving Mtx: ' + WriteMtx(B, 1));
end;

procedure TTestLinearEquations.TestLUBackSubst2;
const A : Array[0..5] of double = (1, 2, 0, 2, -1, 0);
      C : Array[0..5] of double = (2, -1, 0, 0.5, 2.5, 0);
      D : Array[0..3] of double = (0, 0, 1, 0);
var LUDecomp : Array[0..5] of double;
    res : TLinEquResult;
    idx : Array[0..1] of integer;
    B : Array[0..3] of double;
begin
     Move(A, LUDecomp, sizeof(A));

     idx[0] := 0;
     idx[1] := 0;
     res := MatrixLUDecompInPlace(@LUDecomp[0], 3*sizeof(double), 2, @idx[0]);

     Check(res = leOk, 'Singularity detected!');
     CheckEqualsMem(@C[0], @LUDecomp[0], sizeof(C), 'LU decomp failed with: ' + WriteMtx(LUDecomp, 2));

     // back substitute
     B[0] := 2;
     B[1] := 0;
     B[2] := -1;
     B[3] := 0;
     MatrixLUBackSubst(@LUDecomp[0], 3*sizeof(double), 2, @idx[0], @B[0], 2*sizeof(double));

     CheckEqualsMem(@D[0], @B[0], sizeof(D), 'Error solving Mtx: ' + WriteMtx(B, 1));
end;

procedure TTestLinearEquations.TestLUDecomp1;
const A : Array[0..3] of double = (1, 2, 2, -1);
      B : Array[0..3] of double = (2, -1, 0.5, 2.5);
var LUDecomp : Array[0..3] of double;
    res : TLinEquResult;
    idx : Array[0..1] of integer;
    C : TDoubleDynArray;
begin
     Move(A, LUDecomp, sizeof(A));


     res := MatrixLUDecompInPlace(@LUDecomp[0], 2*sizeof(double), 2, @idx[0]);

     Check(res = leOk, 'Singularity detected!');
     CheckEqualsMem(@b[0], @LUDecomp[0], sizeof(B), 'LU decomp failed with: ' + WriteMtx(LUDecomp, 2));

     SetLength(C, 4);
     res := MatrixLUDecomp(@A[0], 2*sizeof(double), @C[0], 2*sizeof(double), 2);
     Check(res = leOk, 'Singularity detected!');
     CheckEqualsMem(@B[0], @C[0], sizeof(B), 'LU decomp failed with: ' + WriteMtx(LUDecomp, 2));
end;

procedure TTestLinearEquations.TestMatrixSolve;
const cBlkWidth = 48;
      cBlkSize = cBlkWidth*cBlkWidth;
var a, x1, x2, b : TDoubleDynArray;
    i : integer;
    start, stop : int64;
    index : integer;
begin
     InitMtxThreadPool;

     SetLength(a, cBlkSize);
     SetLength(b, 3*cBlkWidth);
     SetLength(x1, 3*cBlkWidth);
     SetLength(x2, 3*cBlkWidth);

     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         a[i] := Random - 0.5;

     for i := 0 to 3*cBlkWidth - 1 do
         b[i] := Random - 0.5;


     start := MtxGetTime;
     MatrixLinEQSolve(@a[0], cBlkWidth*sizeof(double), cBlkWidth, @b[0], 3*sizeof(double), @x1[0], 3*sizeof(double), 3, 0);
     stop := MtxGetTime;
     Status(Format('Blocked LU decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     start := MtxGetTime;
     ThrMatrixLinEQSolve(@a[0], cBlkWidth*sizeof(double), cBlkWidth, @b[0], 3*sizeof(double), @x2[0], 3*sizeof(double), 3);
     stop := MtxGetTime;
     Status(Format('Threaded LU decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     FinalizeMtxThreadPool;

     index := 0;
     Check(CheckMtxIdx(x1, x2, index), Format('error Lin equation solve. Error at x[%d] = %.5f, y[%d] = %.5f', [index, x1[index], index, x2[index]]));
end;

procedure TTestLinearEquations.TestPseudoInversion;
const A : Array[0..9] of double = (1, 1, 2, -2, 3, -1, -1, 2, -2, 3);
      Res : Array[0..9] of double = (0.2000, 0.0606, 0.2606, 0.0545, 0.0242, 0.2000, -0.0606, 0.1394, 0.1455, 0.1758);
      Res1 : Array[0..9] of double = (0.2500, -0.2500, 0.2500, -0.2500, 0.0588, 0.0588, -0.0588, -0.0588, 0.0882, 0.0882);
var dest : Array[0..9] of double;
    Ain : Array[0..9] of double;
begin
     exit;
     Move(A, Ain, sizeof(A));

     Check(MatrixPseudoinverse(@dest[0], 5*sizeof(double), @Ain[0], 2*sizeof(Double),  2, 5) = srOk, 'Error Pseudo Inversion: ' + WriteMtx(A, 2));
     Check(CheckMtx(Dest, Res), 'Error Pseudo Inversion calculation: ' + WriteMtx(dest, 5));

     Move(A, Ain, sizeof(A));
     Check(MatrixPseudoinverse(@dest[0], 2*sizeof(double), @Ain[0], 5*sizeof(double), 5, 2) = srOk, 'Error Pseudo Inversion: ' + WriteMtx(A, 2));
     Check(CheckMtx(Dest, Res1), 'Error Pseudo Inversion calculation: ' + WriteMtx(dest, 5));
end;

procedure TTestLinearEquations.TestPseudoInversion2;
var A : TDoubleDynArray;
    B : TDoubleDynArray;
    C : TDoubleDynArray;
    i : Integer;
begin
     SetLength(A, 25*5);
     for i := 0 to Length(A) - 1 do
     begin
          A[i] := i + 1;
     end;

     SetLength(B, 25*5);
     Check(MatrixPseudoinverse(@B[0], 25*sizeof(double), @A[0], 5*sizeof(double), 5, 25) = srOk, 'Error Pseudoinversion failed');

     SetLength(A, 25*5);
     for i := 0 to Length(A) - 1 do
     begin
          A[i] := i + 1;
     end;

     // check if A*pinv(A)*A = A
     C := MatrixMult(A, B, 5, 25, 25, 5);
     C := MatrixMult(C, A, 25, 25, 5, 25);

     Check(CheckMtx(C, A), 'Error Pseudoinversion Test A*pinv(A)*A = A failed');
end;

procedure TTestLinearEquations.TestQRDecomp;
const A : Array[0..8] of double = (1, 2, 2, -1, 4, -2, 2, 2, -1);
      BIn : Array[0..2] of double = (1, -1, 2);
      Bexp : Array[0..2] of double = (1, 0, 0);
var dest : Array[0..8] of double;
    D : Array[0..2] of double;
    C : Array[0..2] of double;
    B : Array[0..2] of double;
begin
     Move(Bin, B, sizeof(Bin));
     MatrixQRDecomp(@dest[0], 3*sizeof(double), @A[0], 3*sizeof(double), 3, @C[0], sizeof(double), @D[0], sizeof(double));
     MatrixQRSolveLinEq(@dest[0], 3*sizeof(double), 3, @C[0], sizeof(double), @D[0], sizeof(double), @B[0], sizeof(double));

     Check(CheckMtx(Bexp, B), 'Error QR decomposistion: ' + WriteMtx(B, 3));
end;

procedure TTestLinearEquations.TestQRDecomp2;
const A : Array[0..15] of double = (1, 2, 2, 0.5,
                                   -1, 4, -2, -0.1,
                                   2, 2, -1, 1.2,
                                   3, 2, -1, -1.1);
var dest : Array[0..15] of double;
    dest2 : Array[0..15] of double;
    tau : Array[0..3] of double;
    work : Array[0..3] of double;
    i, j : integer;
begin
     Move(A, dest, sizeof(A));
     MatrixQRDecompInPlace2(@dest[0], 4*sizeof(double), 4, 4, @tau[0], nil, 4);

     Move(A, dest2, sizeof(A));
     MatrixQRDecompInPlace(@dest2[0], 4*sizeof(double), 4, @tau[0], sizeof(double), @work[0], sizeof(double));

     // overwrite diagonal elements of dest2 with D
     for i := 0 to 3 do
         dest2[i + 4*i] := work[i];


     // compare only matrix R - the two algorithms differ on Q
     for i := 0 to 3 do
     begin
          for j := i to 3 do
              Check(SameValue(dest[i*4 + j], dest2[i*4 + j], 1e-8));
     end;
end;


procedure TTestLinearEquations.TestQRDecomp3;
var a : TDoubleDynArray;
    tau : TDoubleDynArray;
const cSize = 6;
      cA : Array[0..cSize*cSize - 1] of double = (1, 2, 2, 0.5, -1, -2,
                                   -1, 4, -2, -0.1, 0.1, -1,
                                   2, 2, -1, 1.2, 1, 1,
                                   3, 2, -1, -1.1, -1.1, -2,
                                   1.5, 3, -1, -1, -2, 1,
                                   1, 1, 2, 2, -1, -1);
      // economy size qr decomp output from matlab
      cC : Array[0..cSize*cSize-1] of double = (-4.272002, -3.160111, 0.117041, -0.046816, 1.498127, 1.053370,
                                                -0.189681, -5.292797, 1.630544, 0.065739, 0.768167, 0.882564,
                                                 0.379363, 0.004132, 3.511072, 1.708392, -1.004785, -1.584230,
                                                 0.569044, -0.091157, 0.454708, 2.232685, 1.628624, 0.984368,
                                                 0.284522, 0.149133, 0.200997, 0.301584, 1.312831, -1.029085,
                                                 0.189681, 0.002066, -0.316509, -0.502364, 0.442936, -2.360871);
begin
     SetLength(tau, cSize*cSize);

     SetLength(a, cSize*cSize);
     Move(ca, a[0], sizeof(ca));

     MatrixQRDecompInPlace2(@a[0], cSize*sizeof(double), cSize, cSize, @tau[0], nil, 4);

     Check(CheckMtx(cC, a), 'QR Decomposition 2 failed' );
end;

procedure TTestLinearEquations.TestLargeFullQRDecomp;
var a : TDoubleDynArray;
    tau : TDoubleDynArray;
    b, c : TDoubleDynArray;
    q1, q2 : TDoubleDynArray;
    counter: Integer;
    start, stop : Int64;
const cSize = 1258;
begin
     MtxThreadPool.InitMtxThreadPool;
     RandSeed := 243;
     SetLength(a, cSize*cSize);

     for counter := 0 to Length(a) - 1 do
         a[counter] := random - 0.5;
     b := Copy(a, 0, Length(a));
     c := Copy(a, 0, Length(a));

     SetLength(tau, cSize);

     start := MtxGetTime;
     MatrixQRDecompInPlace2(@a[0], cSize*sizeof(double), cSize, cSize, @tau[0], nil, 24);
     stop := MtxGetTime;
     Status(Format('Blocked QR decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     start := MtxGetTime;
     ThrMatrixQRDecomp(@c[0], cSize*sizeof(double), cSize, cSize, @tau[0], nil, 24);
     stop := MtxGetTime;
     Status(Format('Threaded QR decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     // compare against the unblocked version
     start := MtxGetTime;
     MatrixQRDecompInPlace2(@b[0], cSize*sizeof(double), cSize, cSize, @tau[0], nil, cSize);
     stop := MtxGetTime;
     Status(Format('QR decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     Check(CheckMtx(a, b), 'Blocked QR failed miserably');
     Check(CheckMtx(a, c), 'Threaded QR failed miserably');

     // now check the creation of the full Q an R matrices:
     q1 := Copy(a, 0, Length(a));
     q2 := Copy(a, 0, Length(a));

     start := MtxGetTime;
     MatrixQFromQRDecomp(@q1[0], cSize*SizeOf(double), cSize, cSize, @tau[0], 24, nil);
     stop := MtxGetTime;

     Status(Format('Q from ecosize QR decomp: %.2fms', [(stop - start)/mtxfreq*1000]));

     start := MtxGetTime;
     ThrMatrixQFromQRDecomp(@q2[0], cSize*SizeOf(double), cSize, cSize, @tau[0], 24, nil);
     stop := MtxGetTime;

     Status(Format('Threaded Q from ecosize QR decomp: %.2fms', [(stop - start)/mtxfreq*1000]));
     Check(CheckMtx(q1, q2), 'Threaded Q from ecsosize QR failed');
     
     MtxThreadPool.FinalizeMtxThreadPool;
end;

procedure TTestLinearEquations.TestFullQRDecomp;
var q : TDoubleDynArray;
    qBlk : TDoubleDynArray;
    R : TDoubleDynArray;
    tau : TDoubleDynArray;
    x, y : integer;
    dest : TDoubleDynArray;
const cSize = 6;
      cA : Array[0..cSize*cSize - 1] of double = (1, 2, 2, 0.5, -1, -2,
                                   -1, 4, -2, -0.1, 0.1, -1,
                                   2, 2, -1, 1.2, 1, 1,
                                   3, 2, -1, -1.1, -1.1, -2,
                                   1.5, 3, -1, -1, -2, 1,
                                   1, 1, 2, 2, -1, -1);
begin
     SetLength(tau, cSize*cSize);

     SetLength(q, cSize*cSize);
     Move(ca, q[0], sizeof(ca));

     MatrixQRDecompInPlace2(@q[0], cSize*sizeof(double), cSize, cSize, @tau[0], nil, 4);
     R := Copy(q, 0, length(q));
     qBlk := Copy(q, 0, length(q));
     // zero out the parts occupied by Q
     for y := 1 to cSize - 1 do
     begin
          for x := 0 to y - 1 do
              R[x + y*cSize] := 0;
     end;
     MatrixQFromQRDecomp(@q[0], cSize*sizeof(double), cSize, cSize, @tau[0], cSize, nil);

     // blocked version
     MatrixQFromQRDecomp(@qBlk[0], cSize*sizeof(double), cSize, cSize, @tau[0], 2, nil );

     // simple test if Q*R matches cA
     dest := MatrixMult(Q, r, cSize, cSize, cSize, cSize);

     Check(CheckMtx(dest, ca), 'Error Q*R does not match A');

     dest := MatrixMult(QBlk, r, cSize, CSize, CSize, CSize);

     Check(CheckMtx(dest, ca), 'Error blocked Q*R does not match A');
end;

procedure TTestLinearEquations.TestAsymQRDecomp1;
const cBlkWidth = 12;
      cBlkHeight = 7;
      cBlkSize = cBlkWidth*cBlkHeight;
var x, y : integer;
    i: Integer;
    A, q, R, qBlk : TDoubleDynArray;
    tau, dest : TDoubleDynArray;
begin
     SetLength(q, cBlkWidth*cBlkHeight);
     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         q[i] := Random - 0.5;

     A := Copy(q, 0, Length(q));
     SetLength(tau, cBlkWidth);

     MatrixQRDecompInPlace2(@q[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0]);

     R := Copy(q, 0, length(q));
     qBlk := Copy(q, 0, length(q));
     // zero out the parts occupied by Q
     for y := 1 to cBlkHeight - 1 do
     begin
          for x := 0 to y - 1 do
              R[x + y*cBlkWidth] := 0;
     end;
     MatrixQFromQRDecomp(@q[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0], cBlkWidth, nil);

     // blocked version
     MatrixQFromQRDecomp(@qBlk[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0], 4, nil);

     Check(CheckMtx(q, qBlk, cBlkWidth), 'Error: blocked Q version differs from unblocked');

     // simple test if Q*R matches A
     dest := MatrixMult(@qBlk[0], @r[0], cBlkHeight, cBlkHeight, cBlkWidth, cBlkHeight, cBlkWidth*sizeof(double), cBlkWidth*sizeof(double));
     Check(CheckMtx(dest, a), 'Error Q*R does not match A');
end;

procedure TTestLinearEquations.TestAsymQRDecomp2;
const cBlkWidth = 7;
      cBlkHeight = 12;
      cBlkSize = cBlkWidth*cBlkHeight;
var x, y : integer;
    i: Integer;
    A, q, R, qBlk : TDoubleDynArray;
    tau, dest : TDoubleDynArray;
begin
     SetLength(q, cBlkWidth*cBlkHeight);
     RandSeed := 15;
     for i := 0 to cBlkSize - 1 do
         q[i] := Random - 0.5;

     A := Copy(q, 0, Length(q));
     SetLength(tau, cBlkWidth);

     MatrixQRDecompInPlace2(@q[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0]);

     R := Copy(q, 0, length(q));
     qBlk := Copy(q, 0, length(q));
     // zero out the parts occupied by Q
     for y := 1 to cBlkHeight - 1 do
     begin
          for x := 0 to Min(cBlkWidth, y) - 1 do
              R[x + y*cBlkWidth] := 0;
     end;

     MatrixQFromQRDecomp(@q[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0], cBlkWidth, nil);

     // blocked version
     MatrixQFromQRDecomp(@qBlk[0], cBlkWidth*sizeof(double), cBlkWidth, cBlkHeight, @tau[0], 4, nil);

     Check(CheckMtx(q, qBlk, cBlkWidth), 'Error: blocked Q version differs from unblocked');

     // simple test if Q*R matches A
     dest := MatrixMult(@qBlk[0], @r[0], cBlkWidth, cBlkHeight, cBlkWidth, cBlkWidth, cBlkWidth*sizeof(double), cBlkWidth*sizeof(double));
     Check(CheckMtx(dest, a), 'Error Q*R does not match A');
end;

procedure TTestLinearEquations.TestSVD1;
const A : Array[0..3] of double = (1, 2, 2, -1);
var res : TSVDResult;
    S : Array[0..3] of double;
    W : Array[0..3] of double;
    V : Array[0..3] of double;
    V1 : TDoubleDynArray;
    X : TDoubleDynArray;
    Dest : Array[0..3] of double;
begin
     FillChar(w[0], sizeof(w), 0);
     FillChar(V[0], sizeof(V), 0);
     Move(A, S, sizeof(A));

     res := MatrixSVDInPlace(@S[0], 2*sizeof(double), 2, 2, @W[0], 3*sizeof(double), @V[0], 2*sizeof(double));

     // S*W*V should be the start matrix
     V1 := MatrixTranspose(@v[0], 2*sizeof(double), 2, 2);
     X := MatrixMult(@W[0], @V1[0], 2, 2, 2, 2, 2*sizeof(double), 2*sizeof(double));
     MatrixMult(@dest[0], 2*sizeof(double), @S[0], @X[0], 2, 2, 2, 2, 2*sizeof(double), 2*sizeof(double));

     Check(res = srOk, 'S = ' + WriteMtx(S, 2) + ', W = ' + WriteMtx(W, 2) + ', V = ' + WriteMtx(V, 2));
     Check(CheckMtx(A, Dest), 'Result Multiplication: ' + WriteMtx(Dest, 2));
end;

procedure TTestLinearEquations.TestSVD2;
const A : Array[0..7] of double = (1, 2, 3, 4, 5, 6, 7, 8);
var res : TSVDResult;
    S : Array[0..7] of double;
    W : Array[0..3] of double;
    V : Array[0..3] of double;
    X : TDoubleDynArray;
    V1 : TDoubleDynArray;
    Dest : Array[0..7] of double;
begin
     FillChar(w[0], sizeof(w), 0);
     FillChar(V[0], sizeof(V), 0);

     res := MatrixSVD(@A[0], 2*sizeof(Double), 2, 4, @S[0], 2*sizeof(double), @W[0], 3*sizeof(double), @V[0], 2*sizeof(double));

     // S*W*V should be the start matrix
     V1 := MatrixTranspose(@v[0], 2*sizeof(double), 2, 2);
     X := MatrixMult(@W[0], @V1[0], 2, 2, 2, 2, 2*sizeof(double), 2*sizeof(double));
     MatrixMult(@dest[0], 2*sizeof(double), @S[0], @X[0], 2, 4, 2, 2, 2*sizeof(double), 2*sizeof(double));

     Check(res = srOk, 'S = ' + WriteMtx(S, 2) + ', W = ' + WriteMtx(W, 2) + ', V = ' + WriteMtx(V, 2));
     Check(CheckMtx(A, Dest), 'Result Multiplication: ' + WriteMtx(Dest, 2));
end;

procedure TTestLinearEquations.TestSVD3;
const A : Array[0..19] of double =
  ( 2.5000e+001,  2.5000e+001,  2.5000e+001,  2.5300e+001,  2.5200e+001,  2.5200e+001,  2.4800e+001,  2.4700e+001,  2.5100e+001,  2.4700e+001,
    -2.5000e+001,  -2.5000e+001,  -2.5000e+001,  -2.5300e+001,  -2.5200e+001,  -2.5200e+001,  -2.4800e+001,  -2.4700e+001,  -2.5100e+001,  -2.4700e+001);
var res : TSVDResult;
    S : Array[0..19] of double;
    W : Array[0..3] of double;
    V : Array[0..3] of double;
    X : TDoubleDynArray;
    V1 : TDoubleDynArray;
    Dest : Array[0..19] of double;
begin
     // test accuracy of linear dependent matrices:
     FillChar(w[0], sizeof(w), 0);
     FillChar(V[0], sizeof(V), 0);

     res := MatrixSVD(@A[0], 2*sizeof(Double), 2, 10, @S[0], 2*sizeof(double), @W[0], 3*sizeof(double), @V[0], 2*sizeof(double));

     // S*W*V should be the start matrix
     V1 := MatrixTranspose(@v[0], 2*sizeof(double), 2, 2);
     X := MatrixMult(@W[0], @V1[0], 2, 2, 2, 2, 2*sizeof(double), 2*sizeof(double));
     MatrixMult(@dest[0], 2*sizeof(double), @S[0], @X[0], 2, 10, 2, 2, 2*sizeof(double), 2*sizeof(double));

     Check(res = srOk, 'S = ' + WriteMtx(S, 2) + ', W = ' + WriteMtx(W, 2) + ', V = ' + WriteMtx(V, 2));
     Check(CheckMtx(A, Dest), 'Result Multiplication: ' + WriteMtx(Dest, 2));
end;

initialization
  RegisterTest(TTestLinearEquations{$IFNDEF FPC}.Suite{$ENDIF});

end.
