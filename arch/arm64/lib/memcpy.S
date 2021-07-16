/*
 * Copyright (c) 2012-2021, Arm Limited.
 *
 * Adapted from the original at:
 * https://github.com/ARM-software/optimized-routines/blob/afd6244a1f8d9229/string/aarch64/memcpy.S
 */

#include <linux/linkage.h>
#include <asm/assembler.h>
#include <asm/cache.h>

/*
 * Copy a buffer from src to dest (alignment handled by the hardware)
 *
 * Parameters:
 *	x0 - dest
 *	x1 - src
 *	x2 - n
 * Returns:
 *	x0 - dest
 */
	.macro ldrb1 ptr, regB, val
	ldrb  \ptr, [\regB], \val
	.endm

	.macro strb1 ptr, regB, val
	strb \ptr, [\regB], \val
	.endm

	.macro ldrh1 ptr, regB, val
	ldrh  \ptr, [\regB], \val
	.endm

	.macro strh1 ptr, regB, val
	strh \ptr, [\regB], \val
	.endm

	.macro ldr1 ptr, regB, val
	ldr \ptr, [\regB], \val
	.endm

	.macro str1 ptr, regB, val
	str \ptr, [\regB], \val
	.endm

	.macro ldp1 ptr, regB, regC, val
	ldp \ptr, \regB, [\regC], \val
	.endm

	.macro stp1 ptr, regB, regC, val
	stp \ptr, \regB, [\regC], \val
	.endm

ENTRY(__memcpy)
WEAK(memcpy)
#include "copy_template.S"
	ret

	.p2align 4
	/* Copy more than 128 bytes.  */
L(copy_long):
	/* Use backwards copy if there is an overlap.  */
	sub	tmp1, dstin, src
	cbz	tmp1, L(copy0)
	cmp	tmp1, count
	b.lo	L(copy_long_backwards)

	/* Copy 16 bytes and then align dst to 16-byte alignment.  */

	ldp	D_l, D_h, [src]
	and	tmp1, dstin, 15
	bic	dst, dstin, 15
	sub	src, src, tmp1
	add	count, count, tmp1	/* Count is now 16 too large.  */
	ldp	A_l, A_h, [src, 16]
	stp	D_l, D_h, [dstin]
	ldp	B_l, B_h, [src, 32]
	ldp	C_l, C_h, [src, 48]
	ldp	D_l, D_h, [src, 64]!
	subs	count, count, 128 + 16	/* Test and readjust count.  */
	b.ls	L(copy64_from_end)

L(loop64):
	stp	A_l, A_h, [dst, 16]
	ldp	A_l, A_h, [src, 16]
	stp	B_l, B_h, [dst, 32]
	ldp	B_l, B_h, [src, 32]
	stp	C_l, C_h, [dst, 48]
	ldp	C_l, C_h, [src, 48]
	stp	D_l, D_h, [dst, 64]!
	ldp	D_l, D_h, [src, 64]!
	subs	count, count, 64
	b.hi	L(loop64)

	/* Write the last iteration and copy 64 bytes from the end.  */
L(copy64_from_end):
	ldp	E_l, E_h, [srcend, -64]
	stp	A_l, A_h, [dst, 16]
	ldp	A_l, A_h, [srcend, -48]
	stp	B_l, B_h, [dst, 32]
	ldp	B_l, B_h, [srcend, -32]
	stp	C_l, C_h, [dst, 48]
	ldp	C_l, C_h, [srcend, -16]
	stp	D_l, D_h, [dst, 64]
	stp	E_l, E_h, [dstend, -64]
	stp	A_l, A_h, [dstend, -48]
	stp	B_l, B_h, [dstend, -32]
	stp	C_l, C_h, [dstend, -16]
	ret

	.p2align 4

	/* Large backwards copy for overlapping copies.
	   Copy 16 bytes and then align dst to 16-byte alignment.  */
L(copy_long_backwards):
	ldp	D_l, D_h, [srcend, -16]
	and	tmp1, dstend, 15
	sub	srcend, srcend, tmp1
	sub	count, count, tmp1
	ldp	A_l, A_h, [srcend, -16]
	stp	D_l, D_h, [dstend, -16]
	ldp	B_l, B_h, [srcend, -32]
	ldp	C_l, C_h, [srcend, -48]
	ldp	D_l, D_h, [srcend, -64]!
	sub	dstend, dstend, tmp1
	subs	count, count, 128
	b.ls	L(copy64_from_start)

L(loop64_backwards):
	stp	A_l, A_h, [dstend, -16]
	ldp	A_l, A_h, [srcend, -16]
	stp	B_l, B_h, [dstend, -32]
	ldp	B_l, B_h, [srcend, -32]
	stp	C_l, C_h, [dstend, -48]
	ldp	C_l, C_h, [srcend, -48]
	stp	D_l, D_h, [dstend, -64]!
	ldp	D_l, D_h, [srcend, -64]!
	subs	count, count, 64
	b.hi	L(loop64_backwards)

	/* Write the last iteration and copy 64 bytes from the start.  */
L(copy64_from_start):
	ldp	G_l, G_h, [src, 48]
	stp	A_l, A_h, [dstend, -16]
	ldp	A_l, A_h, [src, 32]
	stp	B_l, B_h, [dstend, -32]
	ldp	B_l, B_h, [src, 16]
	stp	C_l, C_h, [dstend, -48]
	ldp	C_l, C_h, [src]
	stp	D_l, D_h, [dstend, -64]
	stp	G_l, G_h, [dstin, 48]
	stp	A_l, A_h, [dstin, 32]
	stp	B_l, B_h, [dstin, 16]
	stp	C_l, C_h, [dstin]
	ret

SYM_FUNC_END_PI(memcpy)
SYM_FUNC_END_ALIAS(__memcpy)
SYM_FUNC_END_ALIAS_PI(memmove)
SYM_FUNC_END_ALIAS(__memmove)
