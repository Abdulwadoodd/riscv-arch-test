// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------

/* VM test in sv32 mode where Loads are performed when VA!=PA in S mode*/
//#define rvtest_strap_routine
#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I")
        
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_CASE(0,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True",sv32)

RVTEST_SIGBASE( x12,signature_x12_1)

main: 

    li t0, -1
    csrw pmpaddr0, t0
    li t0, (PMP_R | PMP_W | PMP_X | PMP_TOR | PMP_L)
    csrw pmpcfg0, t0

// Definitions for PTEs
#define PTE_L1_addr 0x81000000  // base address of root (1st level) page table
#define PTE_L2_addr 0x82000000  // base address of 2nd level page table
// 
#define PA0 0x80000000 >> 2
#define PA1 0x80003000 >> 2
#define PA2 0x80002000 >> 2
// satp register for sv32: satp.mode = 1, satp.ppn = PTE_L1_addr
#define SATP_REG (SATP32_MODE | (PTE_L1_addr >> 12))
// setting up Page Table entries
#define PTE1_L1 ((PTE_L2_addr >> 2) | PTE_V)
#define PTE0_L2 (PA0 | PTE_V | PTE_X | PTE_A )
#define PTE1_L2 (PA1 | PTE_V | PTE_R | PTE_W | PTE_D | PTE_A ) 	// sw
#define PTE2_L2 (PA2 | PTE_V | PTE_R | PTE_A )	// lw

    csrw mie, zero
  	csrw satp, zero                     // Disable address translation.
	LA (t0, mtvec_handler)
    csrw mtvec, t0						// Write vector table address

    SATP_SETUP

    li t0,0x80000000        // virtual address
    li t2,(PTE_V | PTE_X | PTE_A)   // permissions for PTE to for address instruction of instruction memory

    PTE_SETUP_SV32(t0,x0,t2,1)  // PTE setup with identity mapped

    li t0, 0x812341F0       // virtual address
    la t1, rvtest_data      // physical address
    li t2, (PA2 | PTE_V | PTE_R | PTE_A)    // permissions
    PTE_SETUP_SV32(t0,t1,t2,0)  // PTE setup with un-identity mapped
    # la t0, rvtest_data
    # li t2, (PTE_V | PTE_R | PTE_A)
    # PTE_SETUP_SV32(t0,x0,t2,1)

    /* Goto S mode */
	LA (t3, Goto_smode)
	jalr t3
    

    li t0, 0x812341F0 
    lw t1, 0(t0)
    lw t2, 4(t0)
    


j exit


	/* Trap Handler Starts */
mtvec_handler:
	csrr t1, mcause			// read mcause
	# RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4
	# csrr t0, mstatus		// read mstatus
	# RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4
	// set up temporary registers
    li t3, 0x3
	li t4, 0x9
	li t5, 0x10
	li t6, 0x11
	// set mepc to return address
	csrr 	t0, mepc
	addi 	t0,t0,4
	csrw 	mepc, t0
	# csrr 	t0, mepc
	# RVTEST_SIGUPD(x3,t0,0)
	# addi 	x3,x3,4
	beq 	t4,s1, u_mode
	beq 	t5,s1, s_mode
	beq 	t6,s1, m_mode
    bne     t3,t1, m_mode
	mret
m_mode:
	li      t0, MSTATUS_MPP
    csrs    mstatus, t0		// set mstatus.mpp=11
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret	
s_mode:
	li 		t0, MSTATUS_MPP
	csrc	mstatus, t0		// clear mstatus
	li      t0, 0x800
    csrs    mstatus, t0		// set mstatus.mpp=01
    # li      t0, MSTATUS_MXR
    # csrs    mstatus, t0
    # li      t0, MSTATUS_SUM
    # csrs    mstatus, t0
    # li      t0, MSTATUS_MPRV
    # csrs    mstatus, t0

	mret
u_mode:
	li 		t0, MSTATUS_MPP
	csrc	mstatus, t0		// clear mstatus --> mstatus.MPP=00
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret

	/* Trap Handler ends here  */

Goto_mmode:
	addi s1,x0,0x11
	ebreak
	addi s1,x0,0x0
	jr ra
Goto_smode:
	addi s1,x0,0x10
	ebreak
	addi s1,x0,0x0
	jr ra
Goto_umode:
	addi s1,x0,0x9
	ebreak
	addi s1,x0,0x0
	jr ra

exit: 
    la t0, Goto_mmode
	jalr t0
	# li t0,0xceeeeeed
	# RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

#endif
    
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.fill 10*(XLEN/32),4, 0xbabecafe
rvtest_sroot_pg_tbl:	
    RVTEST_PTE_IDENT_MAP

  rvtest_slvl1_pg_tbl:
    RVTEST_PTE_IDENT_MAP
RVTEST_DATA_END

RVMODEL_DATA_BEGIN

signature_x3_0:
    .fill 0*(XLEN/32),4,0x00000000


signature_x12_1:
    .fill 23*(XLEN/32),4,0xcafebeef

signature_x1_0:
    .fill 9*(XLEN/32),4,0xcafebeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 12*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 5*(XLEN/32),4,0xdeadbeef

#endif

RVMODEL_DATA_END