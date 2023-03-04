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
	
	csrr sp, mscratch

	li t2, -1		// WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x8F		// TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2
	// write satp with all zeros (bare mode)
	csrw satp, x0
# 	old va = 0x80000000
# 	new va = 0x90000000 

	.set va, 0x90000000
	.set old_va, 0x80000000 
	li a0,0x80000000 
    li a1,(PTE_V | PTE_X | PTE_A | PTE_R| PTE_W | PTE_D)   // permissions for PTE to for address instruction of instruction memory
   	PTE_SETUP_SV32(a0, a1, t0, t1, t2, va, 0)
	
	#li a1,(PTE_V | PTE_X | PTE_A | PTE_R | PTE_W | PTE_D)   // permissions for PTE to for address instruction of instruction memory
	#li a0,0x80000000        // virtual address
	/*
	a0 contain physical address,
	a1 contain permissions
	t0,t1,t2 are test registers
	0x80000000 is virtual address
	0 represent no. of translation levels. (only root page table).
	*/
	PTE_SETUP_SV32(a0, a1, t0, t1, t2, 0x80000000, 0)


    la a0, signature_x13_1      // physical address
    li a1, (PTE_V | PTE_A | PTE_R | PTE_W | PTE_D)    // permissions
	PTE_SETUP_SV32(a0, a1, t0, t1, t2, 0x81000000, 0)

	li t1, 0xABCFFFFF
	RVTEST_SIGUPD(x13, t1)



	SATP_SETUP

	LI(t0, va-old_va)
	csrr sp, mscratch
	add t1,sp,t0
	csrw sscratch, t1
	// data
	LREG t1, data_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, data_bgn_off+1*sv_area_sz(sp)
	LREG t1, data_end_off+1*sv_area_sz(sp)
	add t1,t1,t0
	SREG t1, data_end_off+1*sv_area_sz(sp)
	//code 
	LREG t1, code_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, code_bgn_off+1*sv_area_sz(sp)
	LREG t1, code_end_off+1*sv_area_sz(sp)
	add t1,t1,t0
	SREG t1, code_end_off+1*sv_area_sz(sp)
	//signature
	LREG t1, sig_bgn_off+0*sv_area_sz(sp)
	add t2, t1,t0
	SREG t2, sig_bgn_off+1*sv_area_sz(sp)
	LREG t1, sig_end_off+1*sv_area_sz(sp)
	add t1,t1,t0
	SREG t1, sig_end_off+1*sv_area_sz(sp)


	
	RVTEST_GOTO_LOWER_MODE	Smode		   // Switching to S mode


vm_en:
	li t0, 0x81005000
    li t1, 0xFDABC 
    sw t1, 0(t0)
	
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
.align 4

rvtest_data:
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
RVTEST_DATA_END
#ifdef rvtest_strap_routine
.align 12
	rvtest_slvl1_pg_tbl:
		RVTEST_PTE_IDENT_MAP
#endif

RVMODEL_DATA_BEGIN
rvtest_sig_begin:

signature_x1_0:
    .fill 0*(XLEN/32),4,0xdeadbeef

signature_x13_1:
    .fill 10*(XLEN/32),4,0xcafebeef


#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 10*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif

rvtest_sig_end:
RVMODEL_DATA_END
