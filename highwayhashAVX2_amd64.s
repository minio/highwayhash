// Copyright (c) 2017 Minio Inc. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// +build go1.8 
// +build amd64 !gccgo !appengine !nacl

#include "textflag.h"

DATA ·consAVX2<>+0x00(SB)/8, $0xdbe6d5d5fe4cce2f
DATA ·consAVX2<>+0x08(SB)/8, $0xa4093822299f31d0
DATA ·consAVX2<>+0x10(SB)/8, $0x13198a2e03707344
DATA ·consAVX2<>+0x18(SB)/8, $0x243f6a8885a308d3
DATA ·consAVX2<>+0x20(SB)/8, $0x3bd39e10cb0ef593
DATA ·consAVX2<>+0x28(SB)/8, $0xc0acf169b5f18a8c
DATA ·consAVX2<>+0x30(SB)/8, $0xbe5466cf34e90c6c
DATA ·consAVX2<>+0x38(SB)/8, $0x452821e638d01377
GLOBL ·consAVX2<>(SB), (NOPTR+RODATA), $64

DATA ·zipperMergeAVX2<>+0x00(SB)/8, $0xf010e05020c03
DATA ·zipperMergeAVX2<>+0x08(SB)/8, $0x70806090d0a040b
DATA ·zipperMergeAVX2<>+0x10(SB)/8, $0xf010e05020c03
DATA ·zipperMergeAVX2<>+0x18(SB)/8, $0x70806090d0a040b
GLOBL ·zipperMergeAVX2<>(SB), (NOPTR+RODATA), $32

#define UPDATE_AVX2(msg) \
	VPADDQ  msg, Y2, Y2                               \
	VPADDQ  Y3, Y2, Y2                                \
	                                                  \
	VPSRLQ  $32, Y1, Y0                               \
	BYTE    $0xC5; BYTE $0xFD; BYTE $0xF4; BYTE $0xC2 \ // VPMULUDQ Y2, Y0, Y0
	VPXOR   Y0, Y3, Y3                                \
	                                                  \
	VPADDQ  Y4, Y1, Y1                                \
	                                                  \
	VPSRLQ  $32, Y2, Y0                               \
	BYTE    $0xC5; BYTE $0xFD; BYTE $0xF4; BYTE $0xC1 \ // VPMULUDQ Y1, Y0, Y0
	VPXOR   Y0, Y4, Y4                                \
	                                                  \
	VPSHUFB Y5, Y2, Y0                                \
	VPADDQ  Y0, Y1, Y1                                \
	                                                  \
	VPSHUFB Y5, Y1, Y0                                \
	VPADDQ  Y0, Y2, Y2

// func initializeAVX2(state *[16]uint64, key []byte)
TEXT ·initializeAVX2(SB), 4, $0-32
	MOVQ state+0(FP), AX
	MOVQ key_base+8(FP), BX
	MOVQ $·consAVX2<>(SB), CX

	VZEROUPPER
	VMOVDQU 0(BX), Y1
	VPSHUFD $177, Y1, Y2

	VMOVDQU 0(CX), Y3
	VMOVDQU 32(CX), Y4

	VPXOR Y3, Y1, Y1
	VPXOR Y4, Y2, Y2

	VMOVDQU Y1, 0(AX)
	VMOVDQU Y2, 32(AX)
	VMOVDQU Y3, 64(AX)
	VMOVDQU Y4, 96(AX)
	VZEROUPPER
	RET

// func updateAVX2(state *[16]uint64, msg []byte)
TEXT ·updateAVX2(SB), 4, $0-32
	MOVQ state+0(FP), AX
	MOVQ msg_base+8(FP), BX
	MOVQ msg_len+16(FP), CX

	CMPQ CX, $32
	JB   DONE
	VZEROUPPER

	VMOVDQU 0(AX), Y1
	VMOVDQU 32(AX), Y2
	VMOVDQU 64(AX), Y3
	VMOVDQU 96(AX), Y4

	VMOVDQU ·zipperMergeAVX2<>(SB), Y5

LOOP:
	VMOVDQU 0(BX), Y0

	UPDATE_AVX2(Y0)

	ADDQ $32, BX
	SUBQ $32, CX
	JA   LOOP

	VMOVDQU Y1, 0(AX)
	VMOVDQU Y2, 32(AX)
	VMOVDQU Y3, 64(AX)
	VMOVDQU Y4, 96(AX)
	VZEROUPPER

DONE:
	RET

// func supportsAVX2() bool
TEXT ·supportsAVX2(SB), 4, $0-1
	MOVQ runtime·support_avx2(SB), AX
	MOVB AX, ret+0(FP)
	RET
