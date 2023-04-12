// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This is a VM test file with SV32 address translation scheme, to verify the working of trap handler and other macros in arch_test.h
// 

#include "model_test.h"
#include "arch_testPR318i.h"

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

	.set va, 0x90000000
	.set pa, 0x80000000 
	li a0,pa 
    li a1,(PTE_V | PTE_X | PTE_A | PTE_R| PTE_W | PTE_D)   // permissions for PTE to for address instruction of instruction memory
   	PTE_SETUP_SV32(a0, a1, t0, t1, t2, va, 1)

    la a0, my_test_data      // physical address
    li a1, (PTE_V | PTE_A | PTE_X)    // permissions
	PTE_SETUP_SV32(a0, a1, t0, t1, t2, 0x71000000, 0)

	li t1, 0xABCFFFFF
	RVTEST_SIGUPD(x13, t1)

	SATP_SETUP

	la t1,my_test_data
	li t4, 0x71000000
	sub t4, t4, t1
	LI(t0, va-pa)
	csrr sp, mscratch
	add t1,sp,t0
	csrw sscratch, t1
	// data
	LREG t1, data_bgn_off+0*sv_area_sz(sp)
	add  t2, t1,t4
	SREG t2, data_bgn_off+1*sv_area_sz(sp)
	//code 
	LREG t1, code_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, code_bgn_off+1*sv_area_sz(sp)
	//signature
	LREG t1, sig_bgn_off+0*sv_area_sz(sp)
	add t2, t1, t0
	SREG t2, sig_bgn_off+1*sv_area_sz(sp)
	//VM
	LREG t1, vmem_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, vmem_bgn_off+1*sv_area_sz(sp)

	// set mstatus.MXR: make eXecuteable Readable)
	//li t1, MSTATUS_MXR
	//csrs mstatus, t1

	// set mstatus.SUM 
	# li t1, MSTATUS_SUM
	# csrs mstatus, t1
	
	RVTEST_GOTO_LOWER_MODE	Smode		   // Switching to S mode

vm_en:
	li t0, 0x7100011C
    li t1, 0xFDABC 
    lw t1, 0(t0)
	// check if this instruction executed after trap
	li t2, 0xFFFF0000
	li t2, 0xFFFF0001
	li t2, 0xFFFF0002

	RVTEST_GOTO_MMODE		// Switching back to M mode

mmode:
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
	.fill 5*(XLEN/32),4,0x123456FF

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
    .fill 10*(XLEN/32),4,0xcafebeef

// trap signatures initialization
#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 10*(XLEN/32),4,0xdeadbeef
#endif

rvtest_sig_end:
RVMODEL_DATA_END
