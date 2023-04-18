// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This is a VM test file with SV32 address translation scheme, to verify the working of trap handler and other macros in arch_test.h
// 

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
    RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def rvtest_strap_routine=True; def TEST_CASE_1=True",sv32)

RVTEST_SIGBASE( x13,signature_x13_1)
  	
main:
#ifdef rvtest_mtrap_routine	// Verification of existance of rvtest_mtrap_routine
	li a4, 0xceed
	RVTEST_SIGUPD(x13,a4)
#endif
#ifdef rvtest_strap_routine	// Verification of existance of rvtest_strap_routine
	li a4, 0xbeed
	RVTEST_SIGUPD(x13,a4)
#endif
	
	li t2, -1		// WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x8F		// TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2
	// write satp with all zeros (bare mode)
	csrw satp, x0

	.set va, 0x91240000
	.set pa, 0x80000000 
	li a0,pa 
    li a1,(PTE_V | PTE_X | PTE_A | PTE_R| PTE_W | PTE_D)   // permissions for PTE to for address instruction of instruction memory
   	// PTE setup for Instruction memory 0x90000000 -> 0x80000000
	PTE_SETUP_SV32(a0, a1, t0, t1, t2, va, 0)

    la a0, my_test_data      		   // physical address
    li a1, (PTE_V | PTE_A | PTE_R)    // permissions
	// PTE setup for Data region 	0x710000000
	PTE_SETUP_SV32(a0, a1, t0, t1, t2, 0x71000000, 1)

	SATP_SETUP

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

	/******* data *******/
	la t1,my_test_data
	li t4, 0x71000000
	sub t4, t4, t1
	// update save area
	LREG t1, data_bgn_off+0*sv_area_sz(sp)
	add  t2, t1,t4
	SREG t2, data_bgn_off+1*sv_area_sz(sp)
	//signature
	//LREG t1, sig_bgn_off+0*sv_area_sz(sp)
	//add t2, t1, t0
	//SREG t2, sig_bgn_off+1*sv_area_sz(sp)
	//VM
	//LREG t1, vmem_bgn_off+0*sv_area_sz(sp)
	//add t2, t1,t0
	//SREG t2, vmem_bgn_off+1*sv_area_sz(sp)

	// set mstatus.MXR: make eXecuteable Readable)
	//li t1, MSTATUS_MXR
	//csrs mstatus, t1

	// set mstatus.SUM 
	# li t1, MSTATUS_SUM
	# csrs mstatus, t1
	
	RVTEST_GOTO_LOWER_MODE	Smode		   // Switching to S mode

vm_en:
	li t1, 0x12
	li t2, 0x13
	li t3, 0x14
	li t4, 0x15
	li t5, 0x16
	li t6, 0x17
	li sp, 0x18
	LA(t1, my_test_data)
	slli t1,t1,16
	srli t1,t1,16
	li t0, 0x71000000
	or t0,t0,t1 
    lw t1, 0(t0) // must be trapped: Dump 4 words in signatures
	nop
	// Trap must return on Virtual addr of following instructions
	add t0, t0, x0
	add t1, t1, x0
	add t2, t2, x0
	add t3, t3, x0
	add t4, t4, x0
	add t5, t5, x0
	add t6, t6, x0
	add sp, sp, x0

	RVTEST_GOTO_MMODE		// Switching back to M mode

mmode:
	add t0, t0, x0
	add t1, t1, x0
	add t2, t2, x0
	add t3, t3, x0
	add t4, t4, x0
	add t5, t5, x0
	add t6, t6, x0
	add sp, sp, x0
	li t2, 0xabab			// Verification if handler is returning and SIGUPD is working afer the handler
	csrw pmpaddr1, t2		// If in M-mode, this instruction will work otherwise not.
	csrr a4, pmpaddr1
	RVTEST_SIGUPD(x13,a4)

#endif

 # ---------------------------------------------------------------------------------------------
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
my_test_data:
	.fill 1*(XLEN/32),4,0x123456FF

RVTEST_DATA_END
#ifdef rvtest_strap_routine
.align 12
	rvtest_slvl1_pg_tbl:
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
