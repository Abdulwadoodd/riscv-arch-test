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

	csrw mie, zero
	li t2, -1	// WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x8F		// TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2

	csrr t0, mstatus
	//SATP_SETUP
    la t0, rvtest_Sroot_pg_tbl
    srli t0,t0,12
	li t1, 0x8000000000000000
	or t2,t0,t1
	csrw satp,t2

    csrr t0, satp

    // PTE setup
    li t0,0x80000000             // virtual address
    srli t0,t0,12
    slli t0,t0,10               // 
    li t1,(PTE_D | PTE_A | !PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)       // permissions for PTE to for address instruction of instruction memory
    or t6,t0,t1 // Final PTE
    
    // clearing lower 12 bits
    la t3, rvtest_Sroot_pg_tbl  // Base address of level 1 / root page table
    srli t3,t3,12       
    slli t3,t3,12
#define perm (!PTE_D | !PTE_A | !PTE_U | !PTE_X | !PTE_W | !PTE_R | PTE_V)
    //level 1 PTE
    la a0, rvtest_lvl1_tbl          // base of level 2
    srli a1,a0,12
    slli a2,a1,10
    ori a2, a2, perm             // for pte
    slli a3,a1,12             // for base address
    
    la a4, rvtest_lvl2_tbl         // base of level 3
    srli a4,a4,12
    slli a5,a4,10            
    ori a5,a5, perm             // for pte
    slli a6,a4,12            // for base address

    // offset to the base address of page table -level 1
    li t0, 0x80000000   
    srli t2,t0,30
    slli t2,t2,3

    add t1,t2,t3       // address to store PTE at root
    sw a2, 0(t1)
    
    sw a5, 0(a3)

    sw t6, 0(a6)

#define PTE1 0x80003000 
#define PTE2 0x80004000 
#define PTE3 0x80005000 
#define mask 0xFFF

    li a1, mask
    li t3, PTE1
    srli t3,t3,12
    slli t3,t3,3
    and t3,t3,a1
    add t3,t3,a6    

    li t0,PTE1             // virtual address
    srli t0,t0,12
    slli t0,t0,10               // 
    li t1,(PTE_D | PTE_A | !PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)       // permissions for PTE to for address instruction of instruction memory
    or t2,t0,t1 // Final PTE

    sw t2, 0(t3)


    li t3, PTE2
    srli t3,t3,12
    slli t3,t3,3
    and t3,t3,a1
    add t3,t3,a6    

    li t0,PTE2             // virtual address
    srli t0,t0,12
    slli t0,t0,10               // 
    li t1,(PTE_D | PTE_A | !PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)       // permissions for PTE to for address instruction of instruction memory
    or t2,t0,t1 // Final PTE

    sw t2, 0(t3)

    li t3, PTE3
    srli t3,t3,12
    slli t3,t3,3
    and t3,t3,a1
    add t3,t3,a6    

    li t0,PTE3             // virtual address
    srli t0,t0,12
    slli t0,t0,10               // 
    li t1,(PTE_D | PTE_A | !PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)       // permissions for PTE to for address instruction of instruction memory
    or t2,t0,t1 // Final PTE
    
    sw t2, 0(t3)


 	RVTEST_GOTO_LOWER_MODE	Smode	// Switching to S mode
# s_mode:
# 	li t0, 0x812341F0 
#     li t1, 0xcdef 
#     sw t1, 4(t0)
# 	nop
# 	nop
# 	csrw satp, x0			// Just a random instruction to check if trap handler returns
# 	RVTEST_GOTO_MMODE		// Switching back to M mode
# 	nop
# 	nop
# 	ebreak				// Mode check
# 	nop
# 	nop
# 	csrw pmpaddr0, t2		// If in M-mode, this instruction will work otherwise not.
# 	nop
# 	nop
	li a4, 0xabab			// Verification if handler is returning and SIGUPD is working afer the handler
	RVTEST_SIGUPD(x13,a4)

    RVTEST_GOTO_MMODE

    li a4, 0xabab			// Verification if handler is returning and SIGUPD is working afer the handler
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


#define PTE_SETUP_SV39 (virtual, physical, permission_reg, level)