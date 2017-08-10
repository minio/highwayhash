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

	// Load constants table pointer
	MOVD $·constants(SB), R3

	// and load constants into v20, v21, and v22
	WORD $0x4c406074 // ld1    {v20.16b-v22.16b}, [x3]

	WORD $0x4cdf2c00 // ld1   {v0.2d-v3.2d}, [x0], #64
	WORD $0x4c402c04 // ld1   {v4.2d-v7.2d}, [x0]
	SUBS $64, R0

loop:
	// Main loop
	WORD $0x4cdfa830 // ld1   {v16.4s-v17.4s}, [x1], #32

	// Add message
	WORD $0x4ef08442 // add   v2.2d, v2.2d, v16.2d
	WORD $0x4ef18463 // add   v3.2d, v3.2d, v17.2d

	// v1 += mul0
	WORD $0x4ee48442 // add   v2.2d, v2.2d, v4.2d
	WORD $0x4ee58463 // add   v3.2d, v3.2d, v5.2d

	// First multiply
	WORD $0x4e15200a // tbl   v10.16b,{v0.16b,v1.16b},v21.16b
	WORD $0x4e16204b // tbl   v11.16b,{v2.16b,v3.16b},v22.16b
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1c84 // eor   v4.16b,v4.16b,v12.16b

	// Second multiply
	WORD $0x6eaac16c // umull2 V12.2D, V11.4S, V10.4S
	WORD $0x6e2c1ca5 // eor    v5.16b,v5.16b,v12.16b

	// v0 += mul1
	WORD $0x4ee68400 // add   v0.2d, v0.2d, v6.2d
	WORD $0x4ee78421 // add   v1.2d, v1.2d, v7.2d

	// Third multiply
	WORD $0x4e16200a // tbl   v10.16b,{v0.16b,v1.16b},v22.16b
	WORD $0x4e15204b // tbl   v11.16b,{v2.16b,v3.16b},v21.16b
	WORD $0x2eaac16c // umull V12.2D, V11.2S, V10.2S
	WORD $0x6e2c1cc6 // eor   v6.16b,v6.16b,v12.16b

	// Fourth multiply
	WORD $0x6eaac16c // umull2 V12.2D, V11.4S, V10.4S
	WORD $0x6e2c1ce7 // eor    v7.16b,v7.16b,v12.16b

	// First zipper-merge
	WORD $0x4e140049 // tbl v9.16b,{v2.16b},v20.16b
	WORD $0x4ee98400 // add v0.2d, v0.2d, v9.2d

	// Second zipper-merge
	WORD $0x4e140069 // tbl v9.16b,{v3.16b},v20.16b
	WORD $0x4ee98421 // add v1.2d, v1.2d, v9.2d

	// Third zipper-merge
	WORD $0x4e140009 // tbl v9.16b,{v0.16b},v20.16b
	WORD $0x4ee98442 // add v2.2d, v2.2d, v9.2d

	// Fourth zipper-merge
	WORD $0x4e140029 // tbl v9.16b,{v1.16b},v20.16b
	WORD $0x4ee98463 // add v3.2d, v3.2d, v9.2d

	SUBS $32, R2
	BPL  loop

	// Store result
	WORD $0x4c9f2c00 // st1    {v0.2d-v3.2d}, [x0], #64
	WORD $0x4c002c04 // st1    {v4.2d-v7.2d}, [x0]

complete:
	RET

// Constants for TBL instructions
DATA ·constants+0x0(SB)/8, $0x000f010e05020c03 // zipper merge constant
DATA ·constants+0x8(SB)/8, $0x070806090d0a040b
DATA ·constants+0x10(SB)/8, $0x0f0e0d0c07060504 // setup first register for multiply
DATA ·constants+0x18(SB)/8, $0x1f1e1d1c17161514
DATA ·constants+0x20(SB)/8, $0x0b0a090803020100 // setup second register for multiply
DATA ·constants+0x28(SB)/8, $0x1b1a191813121110

GLOBL ·constants(SB), 8, $48
