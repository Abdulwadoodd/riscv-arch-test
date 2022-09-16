// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------

/* VM test in sv32 mode where stores are performed when VA!=PA in S mode */

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

RVTEST_SIGBASE( x3,signature_x3_1)

main: 
  
#define RWX  (PMP_R|PMP_W|PMP_X)

    li a5, -1     // complete physical memory in pmp region
	csrw 	pmpaddr0, a5
    /* Decalring pmp configuration register */
	LI(a5, (RWX | PMP_TOR | PMP_L))
    csrw pmpcfg0, a5

    csrw satp, zero                     // Disable address translation.
	LA (t0, mtvec_handler)
    csrw mtvec, t0						// Write vector table address

	# li      t0, MSTATUS_MPRV
    # csrs    mstatus, t0

    la x1, rvtest_sroot_pg_tbl

    la x3, signature_x3_1
    sw x1, 0(x3)

    la x2, rvtest_slvl1_pg_tbl

    sw x2, 4(x3)
    

    SATP_SETUP

	li x5, 0x80000000
	li x7, (PTE_A | PTE_X | PTE_V)
	PTE_SETUP_SV32(x5,x0,x7,1)

	li x5, 0x8001010c
	li x6, 0x80005000
	li x7, (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)
	PTE_SETUP_SV32(x5,x6,x7,0)
     /* Goto S mode */
	LA (t3, Goto_smode)
	jalr t3
	# li t0, MSTATUS_MPRV
	# csrs mstatus, t0

	//sfence.vma

    li x1, 0xabababab
    li x5, 0x8001010c
	sw x1, 0(x5)

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
    li t1,0xceeeeeed
	sw t1, 4(x5)

	la t0, Goto_mmode
	jalr t0
	

#endif
    
RVTEST_CODE_END
RVMODEL_HALT


RVTEST_DATA_BEGIN
rvtest_data:
.fill 0*(XLEN/32),4, 0xabababab
rvtest_sroot_pg_tbl:    // address of root page table	
    RVTEST_PTE_IDENT_MAP
rvtest_slvl1_pg_tbl:    // base address of level 1 page table
    RVTEST_PTE_IDENT_MAP
RVTEST_DATA_END



RVMODEL_DATA_BEGIN

signature_x3_0:
    .fill 0*(XLEN/32),4,0x00000000


signature_x3_1:
    .fill 70*(XLEN/32),4,0xcafebeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 12*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 5*(XLEN/32),4,0xdeadbeef

#endif

RVMODEL_DATA_END