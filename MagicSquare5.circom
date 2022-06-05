// Magic Square 5x5
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
    signal input a[5][5];
    signal output out1;
    
   component comp = matElemSum(1,5);

    comp.a[0][0] <== a[0][4];
    comp.a[0][1] <== a[1][3];
    comp.a[0][2] <== a[2][2];
    comp.a[0][3] <== a[3][1];
    comp.a[0][4] <== a[4][0];

    out1 <== comp.out;
}

template MagicSquare5() {
    signal input puzzle[5][5]; // 0  where blank
    signal input solution[5][5]; // 0 where original puzzle is not blank
    signal input privSalt;
    signal input pubSolnHash;
    signal output OUT;

    // check whether the solution is zero everywhere the puzzle has values (to avoid trick solution)
    component mul = matElemMul(5,5);
    
    component RangeP[5][5]; 
    component RangeS[5][5];
    // all elements are from 0 to 25
    for (var i=0; i<5; i++) {
        for (var j=0; j<5; j++) {
            RangeP[i][j] = RangeProof(8);
            RangeP[i][j].in <== puzzle[i][j];
            RangeP[i][j].range[0] <== 0;
            RangeP[i][j].range[1] <== 25;
            RangeP[i][j].out === 2;
            RangeS[i][j] = RangeProof(8);
            RangeS[i][j].in <== solution[i][j];
            RangeS[i][j].range[0] <== 0;
            RangeS[i][j].range[1] <== 25;
            RangeS[i][j].out === 2;
            mul.a[i][j] <== puzzle[i][j];
            mul.b[i][j] <== solution[i][j];
        }
    }
    for (var i=0; i<5; i++) {
        for (var j=0; j<5; j++) {
            mul.out[i][j] === 0;
        }
    }

    // sum up the two inputs to get full solution and square the full solution
    component add = matAdd(5,5);
    
    for (var i=0; i<5; i++) {
        for (var j=0; j<5; j++) {
            add.a[i][j] <== puzzle[i][j];
            add.b[i][j] <== solution[i][j];
        }
    }

    // sums all rows, columns and diagonals need to be 65 
    component row[5];
    component col[5];
    component diagonal1;
    component diagonal2;

    for (var k=0; k<5; k++) {
        row[k] = matElemSum(1,5);
        col[k] = matElemSum(1,5);

        for (var i=0; i<5; i++) {
            row[k].a[0][i] <== add.out[k][i];
            col[k].a[0][i] <== add.out[i][k];
        }
        row[k].out === 65;
        col[k].out === 65;
    }

    diagonal1 = trace(5);
    diagonal2 = dio2();

    for (var k=0; k<5; k++) {
        for (var i=0; i<5; i++) {
        diagonal1.a[k][i] <== add.out[k][i];
        diagonal2.a[k][i] <== add.out[k][i];
        }
    }
    diagonal1.out === 65;
    diagonal2.out1 === 65;
    
    // Verify that the hash(private solution, hash of first 15 fields, hash of the last 10 fields) matches pubSolnHash
    component poseidon0 = Poseidon(15);
    poseidon0.inputs[0] <== solution[0][0];
    poseidon0.inputs[1] <== solution[0][1];
    poseidon0.inputs[2] <== solution[0][2];
    poseidon0.inputs[3] <== solution[0][3];
    poseidon0.inputs[4] <== solution[0][4];
    poseidon0.inputs[5] <== solution[1][0];
    poseidon0.inputs[6] <== solution[1][1];
    poseidon0.inputs[7] <== solution[1][2];
    poseidon0.inputs[8] <== solution[1][3];
    poseidon0.inputs[9] <== solution[1][4];
    poseidon0.inputs[10] <== solution[2][0];
    poseidon0.inputs[11] <== solution[2][1];
    poseidon0.inputs[12] <== solution[2][2];
    poseidon0.inputs[13] <== solution[2][3];
    poseidon0.inputs[14] <== solution[2][4];
    
    component poseidon1 = Poseidon(10);
    poseidon1.inputs[0] <== solution[3][0];
    poseidon1.inputs[1] <== solution[3][1];
    poseidon1.inputs[2] <== solution[3][2];
    poseidon1.inputs[3] <== solution[3][3];
    poseidon1.inputs[4] <== solution[3][4];
    poseidon1.inputs[5] <== solution[4][0];
    poseidon1.inputs[6] <== solution[4][1];
    poseidon1.inputs[7] <== solution[4][2];
    poseidon1.inputs[8] <== solution[4][3];
    poseidon1.inputs[9] <== solution[4][4];

    component poseidon2 = Poseidon(3);
    poseidon2.inputs[0] <== privSalt;
    poseidon2.inputs[1] <== poseidon0.out;
    poseidon2.inputs[2] <== poseidon1.out;
   
   
    OUT <== poseidon2.out;
    pubSolnHash === OUT;

   
}

component main {public [pubSolnHash]}= MagicSquare5();