// Copyright (c) 2017 Minio Inc. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// +build amd64 !gccgo !appengine !nacl

#include "textflag.h"

DATA ·cons<>+0x00(SB)/8, $0xdbe6d5d5fe4cce2f
DATA ·cons<>+0x08(SB)/8, $0xa4093822299f31d0
DATA ·cons<>+0x10(SB)/8, $0x13198a2e03707344
DATA ·cons<>+0x18(SB)/8, $0x243f6a8885a308d3
DATA ·cons<>+0x20(SB)/8, $0x3bd39e10cb0ef593
DATA ·cons<>+0x28(SB)/8, $0xc0acf169b5f18a8c
DATA ·cons<>+0x30(SB)/8, $0xbe5466cf34e90c6c
DATA ·cons<>+0x38(SB)/8, $0x452821e638d01377
GLOBL ·cons<>(SB), (NOPTR+RODATA), $64

DATA ·zipperMerge<>+0x00(SB)/8, $0xf010e05020c03
DATA ·zipperMerge<>+0x08(SB)/8, $0x70806090d0a040b
GLOBL ·zipperMerge<>(SB), (NOPTR+RODATA), $16

#define v00 X0
#define v01 X1
#define v10 X2
#define v11 X3
#define m00 X4
#define m01 X5
#define m10 X6
#define m11 X7

#define t0 X8
#define t1 X9
#define t2 X10

#define REDUCE_MOD(x0, x1, x2, x3, tmp0, tmp1, y0, y1) \
	MOVQ $0x3FFFFFFFFFFFFFFF, tmp0 \
	ANDQ tmp0, x3                  \
	MOVQ x2, y0                    \
	MOVQ x3, y1                    \
	                               \
	MOVQ x2, tmp0                  \
	MOVQ x3, tmp1                  \
	SHLQ $1, tmp1                  \
	SHRQ $63, tmp0                 \
	MOVQ tmp1, x3                  \
	ORQ  tmp0, x3                  \
	                               \
	SHLQ $1, x2                    \
	                               \
	MOVQ y0, tmp0                  \
	MOVQ y1, tmp1                  \
	SHLQ $2, tmp1                  \
	SHRQ $62, tmp0                 \
	MOVQ tmp1, y1                  \
	ORQ  tmp0, y1                  \
	                               \
	SHLQ $2, y0                    \
	                               \
	XORQ x0, y0                    \
	XORQ x2, y0                    \
	XORQ x1, y1                    \
	XORQ x3, y1

#define UPDATE(msg0, msg1) \
	PADDQ   msg0, v10 \
	PADDQ   m00, v10  \
	PADDQ   msg1, v11 \
	PADDQ   m01, v11  \
	                  \
	MOVO    v00, t0   \
	MOVO    v01, t1   \
	PSRLQ   $32, t0   \
	PSRLQ   $32, t1   \
	PMULULQ v10, t0   \
	PMULULQ v11, t1   \
	PXOR    t0, m00   \
	PXOR    t1, m01   \
	                  \
	PADDQ   m10, v00  \
	PADDQ   m11, v01  \
	                  \
	MOVO    v10, t0   \
	MOVO    v11, t1   \
	PSRLQ   $32, t0   \
	PSRLQ   $32, t1   \
	PMULULQ v00, t0   \
	PMULULQ v01, t1   \
	PXOR    t0, m10   \
	PXOR    t1, m11   \
	                  \
	MOVO    v10, t0   \
	PSHUFB  t2, t0    \
	MOVO    v11, t1   \
	PSHUFB  t2, t1    \
	PADDQ   t0, v00   \
	PADDQ   t1, v01   \
	                  \
	MOVO    v00, t0   \
	PSHUFB  t2, t0    \
	MOVO    v01, t1   \
	PSHUFB  t2, t1    \
	PADDQ   t0, v10   \
	PADDQ   t1, v11

// func initializeSSE4(state *[16]uint64, key []byte)
TEXT ·initializeSSE4(SB), 4, $0-32
	MOVQ state+0(FP), AX
	MOVQ key_base+8(FP), BX
	MOVQ $·cons<>(SB), CX

	MOVOU 0(BX), v00
	MOVOU 16(BX), v01

	PSHUFD $177, v00, v10
	PSHUFD $177, v01, v11

	MOVOU 0(CX), m00
	MOVOU 16(CX), m01
	MOVOU 32(CX), m10
	MOVOU 48(CX), m11

	PXOR m00, v00
	PXOR m01, v01
	PXOR m10, v10
	PXOR m11, v11

	MOVOU v00, 0(AX)
	MOVOU v01, 16(AX)
	MOVOU v10, 32(AX)
	MOVOU v11, 48(AX)
	MOVOU m00, 64(AX)
	MOVOU m01, 80(AX)
	MOVOU m10, 96(AX)
	MOVOU m11, 112(AX)
	RET

// func updateSSE4(state *[16]uint64, msg []byte)
TEXT ·updateSSE4(SB), 4, $0-32
	MOVQ state+0(FP), AX
	MOVQ msg_base+8(FP), BX
	MOVQ msg_len+16(FP), CX

	CMPQ CX, $32
	JB   DONE

	MOVOU 0(AX), v00
	MOVOU 16(AX), v01
	MOVOU 32(AX), v10
	MOVOU 48(AX), v11
	MOVOU 64(AX), m00
	MOVOU 80(AX), m01
	MOVOU 96(AX), m10
	MOVOU 112(AX), m11

	MOVOU ·zipperMerge<>(SB), t2

LOOP:
	MOVOU 0(BX), t0
	MOVOU 16(BX), t1

	UPDATE(t0, t1)

	ADDQ $32, BX
	SUBQ $32, CX
	JA   LOOP

	MOVOU v00, 0(AX)
	MOVOU v01, 16(AX)
	MOVOU v10, 32(AX)
	MOVOU v11, 48(AX)
	MOVOU m00, 64(AX)
	MOVOU m01, 80(AX)
	MOVOU m10, 96(AX)
	MOVOU m11, 112(AX)

DONE:
	RET

TEXT ·finalizeSSE4(SB), 4, $0-32
	MOVQ state+24(FP), AX
	MOVQ out_base+0(FP), BX
	MOVQ out_len+8(FP), CX

	MOVOU 0(AX), v00
	MOVOU 16(AX), v01
	MOVOU 32(AX), v10
	MOVOU 48(AX), v11
	MOVOU 64(AX), m00
	MOVOU 80(AX), m01
	MOVOU 96(AX), m10
	MOVOU 112(AX), m11

	MOVOU ·zipperMerge<>(SB), t2

	PSHUFD $177, v01, t0
	PSHUFD $177, v00, t1
	UPDATE(t0, t1)

	PSHUFD $177, v01, t0
	PSHUFD $177, v00, t1
	UPDATE(t0, t1)

	PSHUFD $177, v01, t0
	PSHUFD $177, v00, t1
	UPDATE(t0, t1)

	PSHUFD $177, v01, t0
	PSHUFD $177, v00, t1
	UPDATE(t0, t1)

	MOVOU v00, 0(AX)
	MOVOU v01, 16(AX)
	MOVOU v10, 32(AX)
	MOVOU v11, 48(AX)
	MOVOU m00, 64(AX)
	MOVOU m01, 80(AX)
	MOVOU m10, 96(AX)
	MOVOU m11, 112(AX)

	CMPQ CX, $8
	JE   HASH_64
	CMPQ CX, $16
	JE   HASH_128

HASH_256:
	PADDQ v00, m00
	PADDQ v10, m10
	PADDQ v01, m01
	PADDQ v11, m11

	MOVQ   m00, R8
	PEXTRQ $1, m00, R9
	MOVQ   m10, R10
	PEXTRQ $1, m10, R11
	REDUCE_MOD(R8, R9, R10, R11, R12, R13, R14, R15)
	MOVQ   R14, 0(BX)
	MOVQ   R15, 8(BX)

	MOVQ   m01, R8
	PEXTRQ $1, m01, R9
	MOVQ   m11, R10
	PEXTRQ $1, m11, R11
	REDUCE_MOD(R8, R9, R10, R11, R12, R13, R14, R15)
	MOVQ   R14, 16(BX)
	MOVQ   R15, 24(BX)
	RET

HASH_128:
	PADDQ v00, v11
	PADDQ m00, m11
	PADDQ v11, m11
	MOVOU m11, 0(BX)
	RET

HASH_64:
	PADDQ v00, v10
	PADDQ m00, m10
	PADDQ v10, m10
	MOVQ  m10, DX
	MOVQ  DX, 0(BX)
	RET

// func supportsSSE4() bool
TEXT ·supportsSSE4(SB), 4, $0-1
	MOVL $1, AX
	CPUID
	SHRL $19, CX       // Bit 19 indicates SSE4 support
	ANDL $1, CX        // CX != 0 if support SSE4
	MOVB CX, ret+0(FP)
	RET