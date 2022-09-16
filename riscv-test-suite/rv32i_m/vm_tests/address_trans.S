// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This is a random test file which has been written to verify the working of trap handler and other macros
// 

#define rvtest_strap_routine
#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV32I")


# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN
#ifdef TEST_CASE_1
    RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True",PMP-CFG-reg)

RVTEST_SIGBASE( x13,signature_x13_1)
	.option nopic
	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align	2
  	
main:
#ifdef rvtest_mtrap_routine	// Verification of existance of rvtest_mtrap_routine
	li a4, 0xceed
	RVTEST_SIGUPD(x13,a4)
#endif
#ifdef rvtest_strap_routine	// Verification of existance of rvtest_strap_routine
	li a4, 0xbeed
	RVTEST_SIGUPD(x13,a4)
#endif

    li t0,0x80000000        // virtual address
    li t2,(PTE_V | PTE_X | PTE_A)   // permissions for PTE to for address instruction of instruction memory

    PTE_SETUP_SV32(t0,x0,t2,1)  // PTE setup with identity mapped

    li t0, 0x812341F0       // virtual address
    la t1, signature_x13_1      // physical address
    li t2, (PTE_V | PTE_R | PTE_W | PTE_D | PTE_A)    // permissions
    PTE_SETUP_SV32(t0,t1,t2,0)  // PTE setup with un-identity mapped
   
	csrw mie, zero
	li t2, -1		// WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x8F		// TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2

	csrr t0, mstatus
	SATP_SETUP
	RVTEST_GOTO_LOWER_MODE	Smode	// Switching to S mode
s_mode:
	li t0, 0x812341F0 
    li t1, 0xcdef 
    sw t1, 4(t0)
	nop
	nop
	csrw satp, x0			// Just a random instruction to check if trap handler returns
	RVTEST_GOTO_MMODE		// Switching back to M mode
	nop
	nop
	ebreak				// Mode check
	nop
	nop
	csrw pmpaddr0, t2		// If in M-mode, this instruction will work otherwise not.
	nop
	nop
	li a4, 0xabab			// Verification if handler is returning and SIGUPD is working afer the handler
	RVTEST_SIGUPD(x13,a4)

	
	RVTEST_SIGUPD(x13,a4)
#endif

 # ---------------------------------------------------------------------------------------------
    # HALT
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 3
rvtest_data:
.word 0xdeadcafe
rvtest_sroot_pg_tbl:
    RVTEST_PTE_IDENT_MAP
rvtest_slvl1_pg_tbl:
    RVTEST_PTE_IDENT_MAP
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
signature_x13_0:
    .fill 0*(XLEN/32),4,0x0
signature_x13_1:
    .fill 64*(XLEN/32),4,0xcafebeef

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 24*(XLEN/32),4,0xc9a8b7f1
#endif
RVMODEL_DATA_END
