//+build !noasm !appengine

//
// Minio Cloud Storage, (C) 2017 Minio, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// Use github.com/minio/asm2plan9s on this file to assemble ARM instructions to
// the opcodes of their Plan9 equivalents

TEXT ·updateArm64(SB), 7, $0
	MOVD state+0(FP), R0
	MOVD msg_base+8(FP), R1
	MOVD msg_len+16(FP), R2 // length of message
	SUBS $32, R2
	BMI  complete

	// Definition of registers
	//  v0 = v0.lo
	//  v1 = v0.hi
	//  v2 = v1.lo
	//  v3 = v1.hi
	//  v4 = mul0.lo
	//  v5 = mul0.hi
	//  v6 = mul1.lo
	//  v7 = mul1.hi

	WORD $0x4cdf2c00 // ld1   {v0.2d-v3.2d}, [x0], #64
	WORD $0x4c402c04 // ld1   {v4.2d-v7.2d}, [x0]
	SUBS $64, R0

loop:
	// Main loop
	WORD $0x4cdfa830 // ld1   {v16.4s-v17.4s}, [x1], #32

	// Add message
	WORD $0x4ef08442 // add   v2.2d, v2.2d, v16.2d
	WORD $0x4ef18463 // add   v3.2d, v3.2d, v17.2d
	WORD $0x4ee48442 // add   v2.2d, v2.2d, v4.2d
	WORD $0x4ee58463 // add   v3.2d, v3.2d, v5.2d

    // First multiply
	WORD $0x6e04240a // ins   V10.S[0], V0.S[1]
	WORD $0x6e0c640a // ins   V10.S[1], V0.S[3]
	WORD $0x4ea21c4b // mov   v11.16b, v2.16b
	WORD $0x6e0c456b // ins   V11.S[1], V11.S[2]
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1c84 // eor   v4.16b,v4.16b,v12.16b

	WORD $0x4ee68400 // add   v0.2d, v0.2d, v6.2d

    // Second multiply
	WORD $0x4ea31c6b // mov   v11.16b, v3.16b
	WORD $0x6e04242a // ins   V10.S[0], V1.S[1]
	WORD $0x6e0c642a // ins   V10.S[1], V1.S[3]
	WORD $0x6e0c456b // ins   V11.S[1], V11.S[2]
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1ca5 // eor   v5.16b,v5.16b,v12.16b

    // Third multiply
	WORD $0x4ea01c0a // mov   v10.16b, v0.16b
	WORD $0x6e04244b // ins   V11.S[0], V2.S[1]
	WORD $0x6e0c644b // ins   V11.S[1], V2.S[3]
	WORD $0x6e0c440a // ins   V10.S[1], V0.S[2]
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1cc6 // eor   v6.16b,v6.16b,v12.16b

	WORD $0x4ee78421 // add   v1.2d, v1.2d, v7.2d

    // Fourth multiply
	WORD $0x4ea11c2a // mov   v10.16b, v1.16b
	WORD $0x6e04246b // ins   V11.S[0], V3.S[1]
	WORD $0x6e0c442a // ins   V10.S[1], V1.S[2]
	WORD $0x6e0c646b // ins   V11.S[1], V3.S[3]
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1ce7 // eor   v7.16b,v7.16b,v12.16b

	// First zipper-merge
	WORD $0x6e051449 // ins v9.B[2], v2.B[2]
	WORD $0x6e0d7c49 // ins v9.B[6], v2.B[8+7]
	WORD $0x6e072c49 // ins v9.B[3], v2.B[5]
	WORD $0x6e097449 // ins v9.B[4], v2.B[8+6]
	WORD $0x6e011c49 // ins v9.B[0], v2.B[3]
	WORD $0x6e036449 // ins v9.B[1], v2.B[8+4]
	WORD $0x6e0b0c49 // ins v9.B[5], v2.B[1]
	WORD $0x6e0f0449 // ins v9.B[7], v2.B[0]
	WORD $0x6e1f3c49 // ins v9.B[8+7], v2.B[7]
	WORD $0x6e155449 // ins v9.B[8+2], v2.B[8+2]
	WORD $0x6e1b3449 // ins v9.B[8+5], v2.B[6]
	WORD $0x6e176c49 // ins v9.B[8+3], v2.B[8+5]
	WORD $0x6e115c49 // ins v9.B[8+0], v2.B[8+3]
	WORD $0x6e132449 // ins v9.B[8+1], v2.B[4]
	WORD $0x6e1d4449 // ins v9.B[8+6], v2.B[8+0]
	WORD $0x6e194c49 // ins v9.B[8+4], v2.B[8+1]
	WORD $0x4ee98400 // add v0.2d, v0.2d, v9.2d

	// Second zipper-merge
	WORD $0x6e051469 // ins v9.B[2], v3.B[2]
	WORD $0x6e0d7c69 // ins v9.B[6], v3.B[8+7]
	WORD $0x6e072c69 // ins v9.B[3], v3.B[5]
	WORD $0x6e097469 // ins v9.B[4], v3.B[8+6]
	WORD $0x6e011c69 // ins v9.B[0], v3.B[3]
	WORD $0x6e036469 // ins v9.B[1], v3.B[8+4]
	WORD $0x6e0b0c69 // ins v9.B[5], v3.B[1]
	WORD $0x6e0f0469 // ins v9.B[7], v3.B[0]
	WORD $0x6e1f3c69 // ins v9.B[8+7], v3.B[7]
	WORD $0x6e155469 // ins v9.B[8+2], v3.B[8+2]
	WORD $0x6e1b3469 // ins v9.B[8+5], v3.B[6]
	WORD $0x6e176c69 // ins v9.B[8+3], v3.B[8+5]
	WORD $0x6e115c69 // ins v9.B[8+0], v3.B[8+3]
	WORD $0x6e132469 // ins v9.B[8+1], v3.B[4]
	WORD $0x6e1d4469 // ins v9.B[8+6], v3.B[8+0]
	WORD $0x6e194c69 // ins v9.B[8+4], v3.B[8+1]
	WORD $0x4ee98421 // add v1.2d, v1.2d, v9.2d

	// Third zipper-merge
	WORD $0x6e051409 // ins v9.B[2], v0.B[2]
	WORD $0x6e0d7c09 // ins v9.B[6], v0.B[8+7]
	WORD $0x6e072c09 // ins v9.B[3], v0.B[5]
	WORD $0x6e097409 // ins v9.B[4], v0.B[8+6]
	WORD $0x6e011c09 // ins v9.B[0], v0.B[3]
	WORD $0x6e036409 // ins v9.B[1], v0.B[8+4]
	WORD $0x6e0b0c09 // ins v9.B[5], v0.B[1]
	WORD $0x6e0f0409 // ins v9.B[7], v0.B[0]
	WORD $0x6e1f3c09 // ins v9.B[8+7], v0.B[7]
	WORD $0x6e155409 // ins v9.B[8+2], v0.B[8+2]
	WORD $0x6e1b3409 // ins v9.B[8+5], v0.B[6]
	WORD $0x6e176c09 // ins v9.B[8+3], v0.B[8+5]
	WORD $0x6e115c09 // ins v9.B[8+0], v0.B[8+3]
	WORD $0x6e132409 // ins v9.B[8+1], v0.B[4]
	WORD $0x6e1d4409 // ins v9.B[8+6], v0.B[8+0]
	WORD $0x6e194c09 // ins v9.B[8+4], v0.B[8+1]
	WORD $0x4ee98442 // add v2.2d, v2.2d, v9.2d

	// Fourth zipper-merge
	WORD $0x6e051429 // ins v9.B[2], v1.B[2]
	WORD $0x6e0d7c29 // ins v9.B[6], v1.B[8+7]
	WORD $0x6e072c29 // ins v9.B[3], v1.B[5]
	WORD $0x6e097429 // ins v9.B[4], v1.B[8+6]
	WORD $0x6e011c29 // ins v9.B[0], v1.B[3]
	WORD $0x6e036429 // ins v9.B[1], v1.B[8+4]
	WORD $0x6e0b0c29 // ins v9.B[5], v1.B[1]
	WORD $0x6e0f0429 // ins v9.B[7], v1.B[0]
	WORD $0x6e1f3c29 // ins v9.B[8+7], v1.B[7]
	WORD $0x6e155429 // ins v9.B[8+2], v1.B[8+2]
	WORD $0x6e1b3429 // ins v9.B[8+5], v1.B[6]
	WORD $0x6e176c29 // ins v9.B[8+3], v1.B[8+5]
	WORD $0x6e115c29 // ins v9.B[8+0], v1.B[8+3]
	WORD $0x6e132429 // ins v9.B[8+1], v1.B[4]
	WORD $0x6e1d4429 // ins v9.B[8+6], v1.B[8+0]
	WORD $0x6e194c29 // ins v9.B[8+4], v1.B[8+1]
	WORD $0x4ee98463 // add v3.2d, v3.2d, v9.2d

	SUBS $32, R2
	BPL  loop

	// Store result
	WORD $0x4c9f2c00 // st1    {v0.2d-v3.2d}, [x0], #64
	WORD $0x4c002c04 // st1    {v4.2d-v7.2d}, [x0]

complete:
	RET
