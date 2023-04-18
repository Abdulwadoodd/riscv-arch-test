// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This is a random test file which has been written to verify the working of trap handler and other macros
// 

#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV64I")


# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN
#ifdef TEST_CASE_1
    RVTEST_CASE(1,"//check ISA:=regex(.*64.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def rvtest_strap_routine=True; def TEST_CASE_1=True",sv39)

RVTEST_SIGBASE( x13,signature_x13_1)
	# .option nopic
	# .attribute unaligned_access, 0
	# .attribute stack_align, 16
  	# .align	2
  	
main:
#ifdef rvtest_mtrap_routine	// Verification of existance of rvtest_mtrap_routine
	li a4, 0xceed
	RVTEST_SIGUPD(x13,a4)
#endif
#ifdef rvtest_strap_routine	// Verification of existance of rvtest_strap_routine
	li a4, 0xbeed
	RVTEST_SIGUPD(x13,a4)
#endif

	li t2, -1	// WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x8F		// TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2

	csrr t0, mstatus
	//SATP.mode: sv39 tranlation
    la t0, rvtest_Sroot_pg_tbl
    srli t0,t0,12
	li t1, 0x8000000000000000
	or t2,t0,t1
	csrw satp,t2

    csrr t0, satp

    .set va, 0x990000000
	.set pa, 0x80000000
    li a0, pa 
    li a1,(PTE_V | PTE_X | PTE_A | PTE_R| PTE_W | PTE_D)
    PTE_SETUP_SV39(a0, a1, va, 1)

    /* Save Virtual addresses in of Code and Data 
	 in their respective S-mode save area */
	
	/****** code ******/
	LI (t0, va)
	LI (t1, pa)
	sub t0, t0, t1 // Note: VA > PA 
	csrr sp, mscratch
	add t1,sp,t0
	csrw sscratch, t1
	
	LREG t1, code_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, code_bgn_off+1*sv_area_sz(sp)



 	RVTEST_GOTO_LOWER_MODE	Smode	// Switching to S mode
s_mode:
	li t0, 0x812341F0
    li t1, 0xcdef 
    //sw t1, 4(t0)
	nop
	nop
	
    
    RVTEST_GOTO_MMODE		// Switching back to M mode

mmode:
	li t2, 0xabab			// Verification if handler is returning and SIGUPD is working afer the handler
	csrw pmpaddr1, t2		// If in M-mode, this instruction will work otherwise not.
	csrr a4, pmpaddr1
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
RVTEST_DATA_END

#ifdef rvtest_strap_routine
    .align 12
	rvtest_lvl1_tbl:
		RVTEST_PTE_IDENT_MAP
    .align 12
	rvtest_lvl2_tbl:
		RVTEST_PTE_IDENT_MAP
#endif

RVMODEL_DATA_BEGIN
rvtest_sig_begin:

// test signatures initialization
signature_x13_1:
    .fill 8*(XLEN/32),4,0xcafebeef

// trap signatures initialization
#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 8*(XLEN/32),4,0xdeadbeef
#endif

rvtest_sig_end:
RVMODEL_DATA_END
