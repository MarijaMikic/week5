// Magic Square 3x3
//I made test for the circuit and test passes
pragma circom 2.0.3;

include "../../node_modules/circomlib-matrix/circuits/matAdd.circom";
include "../../node_modules/circomlib-matrix/circuits/matElemMul.circom";
include "../../node_modules/circomlib-matrix/circuits/matElemSum.circom";
include "../../node_modules/circomlib-matrix/circuits/matElemPow.circom";
include "../../node_modules/circomlib-matrix/circuits/trace.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "RangeProof.circom";

// calculate sum of elements of matrix on second diagonal
template dio2() {
    signal input a[3][3];
    signal output out1;
    
   component comp = matElemSum(1,3);

    comp.a[0][0] <== a[0][2];
    comp.a[0][1] <== a[1][1];
    comp.a[0][2] <== a[2][0];

    out1 <== comp.out;
}

template MagicSquare3() {
    signal input puzzle[3][3]; // 0  where blank
    signal input solution[3][3]; // 0 where original puzzle is not blank
    signal input privSalt;
    signal input pubSolnHash;
    signal output OUT;

    // check whether the solution is zero everywhere the puzzle has values (to avoid trick solution)
    component mul = matElemMul(3,3);
    
    component RangeP[3][3]; 
    component RangeS[3][3];
    // all elements are from 0 to 9
    for (var i=0; i<3; i++) {
        for (var j=0; j<3; j++) {
            RangeP[i][j] = RangeProof(8);
            RangeP[i][j].in <== puzzle[i][j];
            RangeP[i][j].range[0] <== 0;
            RangeP[i][j].range[1] <== 9;
            RangeP[i][j].out === 2;
            RangeS[i][j] = RangeProof(8);
            RangeS[i][j].in <== solution[i][j];
            RangeS[i][j].range[0] <== 0;
            RangeS[i][j].range[1] <== 9;
            RangeS[i][j].out === 2;
            mul.a[i][j] <== puzzle[i][j];
            mul.b[i][j] <== solution[i][j];
        }
    }
    for (var i=0; i<3; i++) {
        for (var j=0; j<3; j++) {
            mul.out[i][j] === 0;
        }
    }

    // sum up the two inputs to get full solution and square the full solution
    component add = matAdd(3,3);
    
    for (var i=0; i<3; i++) {
        for (var j=0; j<3; j++) {
            add.a[i][j] <== puzzle[i][j];
            add.b[i][j] <== solution[i][j];
        }
    }

    // sums all rows, columns and diagonals need to be 15 
    component row[3];
    component col[3];
    component diagonal1;
    component diagonal2;

    for (var k=0; k<3; k++) {
        row[k] = matElemSum(1,3);
        col[k] = matElemSum(1,3);

        for (var i=0; i<3; i++) {
            row[k].a[0][i] <== add.out[k][i];
            col[k].a[0][i] <== add.out[i][k];
        }
        row[k].out === 15;
        col[k].out === 15;
    }

    diagonal1 = trace(3);
    diagonal2 = dio2();

    for (var k=0; k<3; k++) {
        for (var i=0; i<3; i++) {
        diagonal1.a[k][i] <== add.out[k][i];
        diagonal2.a[k][i] <== add.out[k][i];
        }
    }
    diagonal1.out === 15;
    diagonal2.out1 === 15;
    
    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(10);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== solution[0][0];
    poseidon.inputs[2] <== solution[0][1];
    poseidon.inputs[3] <== solution[0][2];
    poseidon.inputs[4] <== solution[1][0];
    poseidon.inputs[5] <== solution[1][1];
    poseidon.inputs[6] <== solution[1][2];
    poseidon.inputs[7] <== solution[2][0];
    poseidon.inputs[8] <== solution[2][1];
    poseidon.inputs[9] <== solution[2][2];

    OUT <== poseidon.out;
    pubSolnHash === OUT;

   
}

component main {public [pubSolnHash]}= MagicSquare3();