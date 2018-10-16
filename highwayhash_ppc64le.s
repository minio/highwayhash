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

TEXT ·updatePpc64Le(SB), 7, $0
        MOVD state+0(FP), R14
        MOVD msg_base+8(FP), R10
        MOVD msg_len+16(FP), R5 // length of message

        WORD $0x3AE00000        // li      r23,0
        WORD $0x3B000010        // li      r24,0x10

        // Load constants table pointer
        MOVD $·constants(SB), R20
        WORD $0x7CF4BE99        // lxvd2x  vs39,r20,r23
        WORD $0xF0E73A57        // xxswapd vs39,vs39        // necessary?
        WORD $0x7D14C699        // lxvd2x  vs40,r20,r24
        WORD $0xF1084257        // xxswapd vs40,vs40        // necessary?
        WORD $0xF1084597        // xxlnand vs40,vs40,vs40   // necessary?

        WORD $0x3B200020        // li      r25,0x20
        WORD $0x3B400030        // li      r26,0x30
        WORD $0x3B600040        // li      r27,0x40
        WORD $0x3B800050        // li      r28,0x50
        WORD $0x3BA00060        // li      r29,0x60
        WORD $0x3AC00070        // li      r22,0x70

        // Load state
        WORD $0x7DAEBE99        // lxvd2x  vs45,r14,r23
        WORD $0x7D6EC699        // lxvd2x  vs43,r14,r24
        WORD $0x7C2ECE99        // lxvd2x  vs33,r14,r25
        WORD $0x7C0ED699        // lxvd2x  vs32,r14,r26
        WORD $0x7C4EDE99        // lxvd2x  vs34,r14,r27
        WORD $0x7C6EE699        // lxvd2x  vs35,r14,r28
        WORD $0x7C8EEE99        // lxvd2x  vs36,r14,r29
        WORD $0x7CAEB699        // lxvd2x  vs37,r14,r22

        WORD $0xF1AD6A57        // xxswapd vs45,vs45
        WORD $0xF16B5A57        // xxswapd vs43,vs43
        WORD $0xF0210A57        // xxswapd vs33,vs33
        WORD $0xF0000257        // xxswapd vs32,vs32
        WORD $0xF0421257        // xxswapd vs34,vs34
        WORD $0xF0631A57        // xxswapd vs35,vs35
        WORD $0xF0842257        // xxswapd vs36,vs36
        WORD $0xF0A52A57        // xxswapd vs37,vs37

        WORD $0x38a5ffe0        // ADD R5, $-32, R5
        WORD $0x7c250000        // CMP R0, R5
        BLE complete

loop:
        WORD $0x38EA0010        // addi    r7,r10,16
        WORD $0x7D805699        // lxvd2x  vs44,0,r10
        WORD $0x112D20C0        // vaddudm v9,v13,v4
        WORD $0x10CD38C4        // vrld    v6,v13,v7
        WORD $0x394A0020        // addi    r10,r10,32
        WORD $0x114558C0        // vaddudm v10,v5,v11
        WORD $0x7C003E98        // lxvd2x  vs0,0,r7
        WORD $0xF18C6257        // xxswapd vs44,vs44
        WORD $0xF1A00251        // xxswapd vs45,vs0
        WORD $0x118C10C0        // vaddudm v12,v12,v2
        WORD $0x11AD18C0        // vaddudm v13,v13,v3
        WORD $0x102C08C0        // vaddudm v1,v12,v1
        WORD $0x118B3EC4        // vsrd    v12,v11,v7
        WORD $0x100D00C0        // vaddudm v0,v13,v0
        WORD $0x11A10A2B        // vperm   v13,v1,v1,v8
        WORD $0x10C13088        // vmulouw v6,v1,v6
        WORD $0x1260022B        // vperm   v19,v0,v0,v8
        WORD $0x11AD48C0        // vaddudm v13,v13,v9
        WORD $0x11806088        // vmulouw v12,v0,v12
        WORD $0x117350C0        // vaddudm v11,v19,v10
        WORD $0x124D6A2B        // vperm   v18,v13,v13,v8
        WORD $0x120138C4        // vrld    v16,v1,v7
        WORD $0x12203EC4        // vsrd    v17,v0,v7
        WORD $0x126B5A2B        // vperm   v19,v11,v11,v8
        WORD $0xF04234D7        // xxlxor  vs34,vs34,vs38
        WORD $0x11298088        // vmulouw v9,v9,v16
        WORD $0x114A8888        // vmulouw v10,v10,v17
        WORD $0xF06364D7        // xxlxor  vs35,vs35,vs44
        WORD $0xF0844CD7        // xxlxor  vs36,vs36,vs41
        WORD $0xF0A554D7        // xxlxor  vs37,vs37,vs42
        WORD $0x103208C0        // vaddudm v1,v18,v1
        WORD $0x101300C0        // vaddudm v0,v19,v0

        WORD $0x38a5ffe0        // ADD R5, $-32, R5
        WORD $0x28250020        // CMPLDI $32, R5
        BGE loop

complete:
        WORD $0xF1AD6A57        // xxswapd vs45,vs45
        WORD $0xF16B5A57        // xxswapd vs43,vs43
        WORD $0xF0210A57        // xxswapd vs33,vs33
        WORD $0xF0000257        // xxswapd vs32,vs32
        WORD $0xF0421257        // xxswapd vs34,vs34
        WORD $0xF0631A57        // xxswapd vs35,vs35
        WORD $0xF0842257        // xxswapd vs36,vs36
        WORD $0xF0A52A57        // xxswapd vs37,vs37

        // Save state
        WORD $0x7DAEBF99        // stxvd2x vs45,r14,r23
        WORD $0x7D6EC799        // stxvd2x vs43,r14,r24
        WORD $0x7C2ECF99        // stxvd2x vs33,r14,r25
        WORD $0x7C0ED799        // stxvd2x vs32,r14,r26
        WORD $0x7C4EDF99        // stxvd2x vs34,r14,r27
        WORD $0x7C6EE799        // stxvd2x vs35,r14,r28
        WORD $0x7C8EEF99        // stxvd2x vs36,r14,r29
        WORD $0x7CAEB799        // stxvd2x vs37,r14,r22

        RET

// Constants for zipper merge
DATA ·constants+0x0(SB)/8, $0x0000000000000020
DATA ·constants+0x8(SB)/8, $0x0000000000000020
DATA ·constants+0x10(SB)/8, $0x000f010e05020c03 // zipper merge constant
DATA ·constants+0x18(SB)/8, $0x070806090d0a040b

GLOBL ·constants(SB), 8, $32

