// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------
//
// This assembly file tests the ejal instruction of the RISC-V I extension.
// 

/* 
	PMP Test for RWX of memory region in TOR address matching mode
	PMP memory region is defined b/w pmpaddr0 and base address
	pmpcfg0 is used with the corresponding address registers 
 */


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
    RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True",pmp-tor)
RVTEST_SIGBASE( x3,signature_x3_1)

	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align	2
  
    
main: 
                    
                        
/* SETTING DEFAULTS TO ZERO */
	csrw pmpcfg0, x0
	csrw pmpcfg1, x0
	csrw pmpcfg2, x0
	csrw pmpcfg3, x0
	csrw pmpaddr0, x0
	csrw pmpaddr1, x0
	csrw pmpaddr2, x0
	csrw pmpaddr3, x0
	csrw pmpaddr4, x0
	csrw pmpaddr5, x0
	csrw pmpaddr6, x0
	csrw pmpaddr7, x0
	csrw pmpaddr8, x0
	csrw pmpaddr9, x0
	csrw pmpaddr10, x0
	csrw pmpaddr11, x0
	csrw pmpaddr12, x0
	csrw pmpaddr13, x0
	csrw pmpaddr14, x0
	csrw pmpaddr15, x0

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
                                                                     
/* Setup some data for testing */
#define DATA_VALUE_FOR_READ1                 0xAAAAAAAA
#define DATA_VALUE_FOR_READ2                 0xBBBBBBBB
#define DATA_VALUE_FOR_READ3                 0xCCCCCCCC
#define DATA_VALUE_FOR_READ4                 0xDDDDDDDD
#define DATA_VALUE_FOR_WRITE1                0x11111111
#define DATA_VALUE_FOR_WRITE2                0x22222222
#define DATA_VALUE_FOR_WRITE3                0x33333333
#define DATA_VALUE_FOR_WRITE4                0x44444444

/* SET UP DATA IN THE MEMORY */
	LI(a5, RAM_LOCATION_FOR_TEST)
	LI(a4, DATA_VALUE_FOR_READ1)
	sw	a4,4(a5)
	lw	a4,4(a5)
// VERIFICATION
    LI(a4, DATA_VALUE_FOR_READ2)
    sw a4, 8(a5)
    lw a4, 8(a5)
// VERIFICATION
    LI(a4, DATA_VALUE_FOR_READ3)
    sw a4, 12(a5)
    lw a4, 12(a5)
// VERIFICATION
	LI(a4, DATA_VALUE_FOR_READ4)
    sw a4, 16(a5)
    lw a4, 16(a5)
// VERIFICATION=
    /* Assigning addresses to PMP address registers */
    LI(a5, REGION0_ADDR)
	csrw 	pmpaddr0, a5

	LI(a5, REGION1_ADDR)
	csrw 	pmpaddr1, a5

    LI(a5, REGION2_ADDR)
	csrw 	pmpaddr2, a5

	LI(a5, REGION3_ADDR)
	csrw 	pmpaddr3, a5

    /* Reading pmp address registers to verify the results */
	csrr 	x2, pmpaddr0
	csrr 	x2, pmpaddr1
    csrr 	x2, pmpaddr2	
    csrr 	x2, pmpaddr3	

    /* Decalring pmp configuration register */
	LI(a5, PMPCONFIG0)
	csrw pmpcfg0, a5
	csrr x2, pmpcfg0

    /* VERIFICATION	
	READING data from the memory region
    Throws exception if READability is blocked */
    LI(a5, RAM_LOCATION_FOR_TEST)
    lw	a4,4(a5)
    lw	a4,8(a5)
    lw	a4,12(a5)
    lw	a4,16(a5)

    /*WRITING new value to memory region
    Throws exception if the WRITability is blocked */
	LI(a5, RAM_LOCATION_FOR_TEST)
	LI(a4, DATA_VALUE_FOR_WRITE1)
	sw	a4,4(a5)
	lw	a4,4(a5)

	LI(a5, RAM_LOCATION_FOR_TEST)
    LI(a4, DATA_VALUE_FOR_WRITE2)
	sw	a4,8(a5)
	lw	a4,8(a5)

	LI(a5, RAM_LOCATION_FOR_TEST)
    LI(a4, DATA_VALUE_FOR_WRITE3)
	sw	a4,12(a5)
	lw	a4,12(a5)

	LI(a5, RAM_LOCATION_FOR_TEST)
    LI(a4, DATA_VALUE_FOR_WRITE4)
	sw	a4,16(a5)
	lw	a4,16(a5)

	/*--------------------------MAIN Program-------------------------*/
	csrw mie, zero
  	csrw satp, zero                              	// Disable address translation.
	
	la   t0, mtvec_handler
    csrw mtvec, t0									// Write vector table address

	csrr a5, mstatus
	RVTEST_SIGUPD(x3,a5,0)
	addi x3,x3,4

	ebreak

	/* Goto S mode */
	la t3, Goto_smode
	jalr t3
	
	ecall

	li t0,0x91234567
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	j exit
	
	
 	.align 4
  	.global mtvec_handler

	/* Trap Handler Starts */
mtvec_handler:
	// read mcause
	csrr a7, mcause
	RVTEST_SIGUPD(x3,a7,0)
	addi x3,x3,4
	// read mstatus
	csrr t0, mstatus
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4
	// set mepc to return address
	csrr s0, mepc
	addi s0,s0,4
	csrw mepc, s0
	csrr 	a1, mepc
	RVTEST_SIGUPD(x3,a1,0)
	addi x3,x3,4
	beq a6, a7, m_mode	// returning to mmode
	mret
m_mode:
	li      t2, 0x1800
  	csrs    mstatus, t2		// set mstatus.mpp=11
	csrr 	a1, mstatus
	RVTEST_SIGUPD(x3,a1,0)
	addi x3,x3,4
	mret	
	/* Trap Handler ends here  */

Goto_smode:
	li 		t2, 0x1800
	csrc	mstatus, t2		// clear mstatus
	li      t2, 0x800
    csrs    mstatus, t2		// set mstatus.mpp=01

	csrr t1, mstatus
	RVTEST_SIGUPD(x3,t1,0)
	addi x3,x3,4
	RVTEST_SIGUPD(x3,x1,0)
	addi x3,x3,4
	csrw mepc, x1
	mret

exit:
	/* Returning to M mode */
	li a6,0x3

	ebreak
	ecall
	li t0,0xbeeeeeef
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4


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