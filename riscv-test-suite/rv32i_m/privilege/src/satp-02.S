// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------

/* satp tests to check WARL fields of satp in M mode when address translation is not active */


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
    RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True",satp)
RVTEST_SIGBASE( x3,signature_x3_1)

	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align	2
  
    
main: 
                    
#define RAM_LOCATION_FOR_TEST   0x80000100
#define REGION0_ADDR         (0x80002000 >> PMP_SHIFT)   
#define REGION1_ADDR         (0x80003000 >> PMP_SHIFT)   
#define REGION2_ADDR         (0x80004000 >> PMP_SHIFT)   
#define REGION3_ADDR         (0x80005000 >> PMP_SHIFT)   

/* Define PMP Configuration Fields */

#define OFF             0
#define RWX             (PMP_R|PMP_W|PMP_X)
#define RWXL            (RWX|PMP_L)
#define RW              (PMP_R|PMP_W)
#define RWL             (RW|PMP_L)
#define RX              (PMP_R|PMP_X)
#define RXL             (RX|PMP_L)
#define WX              (PMP_W|PMP_X)
#define WXL             (WX|PMP_L)
#define PMP0_CFG_SHIFT  0
#define PMP1_CFG_SHIFT  8
#define PMP2_CFG_SHIFT  16
#define PMP3_CFG_SHIFT  24

#define PMPCONFIG0      ((((RWX|PMP_L|PMP_TOR)&0xFF) << PMP0_CFG_SHIFT)   | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) << PMP1_CFG_SHIFT)    	  | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) << PMP2_CFG_SHIFT)        | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) << PMP3_CFG_SHIFT))
                                                                     
    /* Assigning addresses to PMP address registers */
    LI(a5, REGION0_ADDR)
	csrw 	pmpaddr0, a5

	LI(a5, REGION1_ADDR)
	csrw 	pmpaddr1, a5

    LI(a5, REGION2_ADDR)
	csrw 	pmpaddr2, a5

	LI(a5, REGION3_ADDR)
	csrw 	pmpaddr3, a5

    /* Decalring pmp configuration register */
	LI(a5, PMPCONFIG0)
	csrw pmpcfg0, a5
	csrr x2, pmpcfg0


	/*--------------------------MAIN Program-------------------------*/


    csrw mie, zero
  	csrw satp, zero                     // Disable address translation.
	la   t0, mtvec_handler
    csrw mtvec, t0						// Write vector table address
	
	li t0,0x96969696
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	li t0, SATP32_PPN
	csrw satp, t0
	csrr t0, satp
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4
	
	li t0,0x96969696
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	li t0, SATP32_ASID
	csrw satp, t0
	csrr t0, satp
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	
	j exit
	
	
 	.align 4
  	.global mtvec_handler

	/* Trap Handler Starts */
mtvec_handler:
	csrr t0, mcause			// read mcause
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4
	# csrr t0, mstatus		// read mstatus
	# RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4
	// set up temporary registers
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
	mret
m_mode:
	li      t0, 0x1800
    csrs    mstatus, t0		// set mstatus.mpp=11
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret	
s_mode:
	li 		t0, 0x1800
	csrc	mstatus, t0		// clear mstatus
	li      t0, 0x800
    csrs    mstatus, t0		// set mstatus.mpp=01
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret
u_mode:
	li 		t0, 0x1800
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
	li t0,0xceeeeeed
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	la t0, Goto_mmode
	jalr t0
	ecall


#endif

 # ---------------------------------------------------------------------------------------------
    # HALT
        

RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xdeadcafe
RVTEST_DATA_END

RVMODEL_DATA_BEGIN


signature_x3_0:
    .fill 0*(XLEN/32),4,0x00000000


signature_x3_1:
    .fill 20*(XLEN/32),4,0xcafebeef



#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 12*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 5*(XLEN/32),4,0xdeadbeef

#endif

RVMODEL_DATA_END