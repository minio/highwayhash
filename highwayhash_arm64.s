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
	MOVD $·zippermerge(SB), R3
	// and cache zipper merge constant in register v20
	WORD $0x4c407874 // ld1    {v20.4s}, [x3]

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

// Constant for zipper merge via TBL instruction
DATA ·zippermerge+0x0(SB)/8, $0x000f010e05020c03
DATA ·zippermerge+0x8(SB)/8, $0x070806090d0a040b

GLOBL ·zippermerge(SB), 8, $16
