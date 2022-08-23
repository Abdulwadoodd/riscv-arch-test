// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------


/* satp tests for csr access in S, M and U mode. */


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

#define REGION0_ADDR         (0x80001000 >> PMP_SHIFT)   
#define REGION1_ADDR         (0x80002000 >> PMP_SHIFT)   
#define REGION2_ADDR         (0x80003000 >> PMP_SHIFT)   
#define REGION3_ADDR         (0x8f000000 >> PMP_SHIFT)   

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
#define DATA 0x0						// In bare mood, all the WARL fields must zero by software
	csrw mie, zero
  	csrw satp, zero                     // Disable address translation.
	la   t0, mtvec_handler
    csrw mtvec, t0						// Write vector table address


//# define PPN  (SATP32_PPN & (SATP_PA >> 12)) 
#define PTE_L1_addr 0x80000000
#define SATP_PA (PTE_L1_addr >> 12) & SATP32_PPN

#define PTE_L2_addr 0x80000000
#define ROOT_L2 PTE_L2_addr >> 2
#define PA0 0x80000000  >> 2
#define PA1 0x80001000 >> 2
#define PA2 0x80002000 >> 2
#define PA3 0x80003000 >> 2

#define BAKWAS (SATP32_MODE | SATP_PA)

#define PTE1_L1 (ROOT_L2 | PTE_V)
#define PTE0_L2 (PA0 | PTE_V | PTE_X | PTE_R | PTE_SOFT | PTE_W | PTE_G | PTE_A )
#define PTE1_L2 (PA1 | PTE_V | PTE_X | PTE_R | PTE_SOFT | PTE_W | PTE_G | PTE_A )
#define PTE2_L2 (PA2 | PTE_V | PTE_X | PTE_R | PTE_SOFT | PTE_W | PTE_G | PTE_A )
#define PTE3_L2 (PA3 | PTE_V | PTE_X | PTE_R | PTE_SOFT | PTE_W | PTE_G | PTE_A )

     /* Goto S mode */
	la t3, Goto_smode
	jalr t3
    
    li t0, PTE_L1_addr
    li t1, 0x800
    add t0, t0,t1
    li t1, PTE1_L1
    sw t1, 0(t0) 

    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    # li t1, PA0
    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    # li t1, PA1
    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    # li t1, PA2
    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    # li t1, PA3
    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    li t0, PTE_L2_addr
    addi t1,t0, 0x04
    addi t2,t0, 0x08
    addi t3,t0, 0x0c

    li t4, PTE0_L2
    sw t4, 0(t0)
    RVTEST_SIGUPD(x3,t4,0)
	addi x3,x3,4
    
    li t4, PTE1_L2
    sw t4, 0(t1)

    li t4, PTE2_L2
    sw t4, 0(t2)

    li t4, PTE3_L2
    sw t4, 0(t3)
    
    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    # RVTEST_SIGUPD(x3,t2,0)
	# addi x3,x3,4

    # RVTEST_SIGUPD(x3,t3,0)
	# addi x3,x3,4
    # RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4

    li t0, 0xefefefef
    RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

    li t0, SATP32_MODE
    li t1, SATP_PA
    or t3, t1,t0
    RVTEST_SIGUPD(x3,t3,0)
	addi x3,x3,4

      

    csrw satp, t3

    
    csrr t0, satp

    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

    
    # li t0, 0xefefefef
    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

    # li t0, ROOT_L2_addr
    # addi t1, t0, 4
    # addi t2, t0, 8
    # addi t3, t0, 12
 
    # li t4, PTE0_L2
    # sw t4, 0(t0)

    # li t4, PTE1_L2
    # sw t4, 0(t1)

    # li t4, PTE2_L2
    # sw t4, 0(t2)

    # li t4, PTE3_L2
    # sw t4, 0(t3)


    # /* Goto S mode */
	# la t6, Goto_smode
	# jalr t6

    # li t0, SATP_f
    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4
    
    # addi t4, t0, 0x1000
    # addi t5, t0, 0x2000
    # addi t6, t0, 0x3000

   

    # li t0, PTE1_L1
    # RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4
# 	li t0,0x96969696
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

# 	li t0, DATA
# 	csrw satp, t0
# 	csrr t0, satp
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4
	
# 	li t0,0x96969696
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

# 	/* Goto S mode */
# 	la t3, Goto_smode
# 	jalr t3
# 	li t0,0x96969696
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

#     ebreak
    
#     li t0,0x96969696
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

#     ecall

# 	li t0, DATA
# 	csrw satp, t0
# 	csrr t0, satp
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

# 	li t0,0x96969696
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

# 	/* Goto U mode */
# 	la t3, Goto_umode
# 	jalr t3
# 	ecall
#     li t0,0xabababab
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4

# 	li t0, DATA
# 	csrw satp, t0
# 	csrr t0, satp
# 	RVTEST_SIGUPD(x3,t0,0)
# 	addi x3,x3,4
	
	
	j exit
	
	
 	.align 4
  	.global mtvec_handler

	/* Trap Handler Starts */
mtvec_handler:
	csrr t1, mcause			// read mcause
	RVTEST_SIGUPD(x3,t1,0)
	addi x3,x3,4
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
    sfence.vma
	li t0,0xceeeeeed
    sfence.vma
	RVTEST_SIGUPD(x3,t0,0)
	addi x3,x3,4

	# la t0, Goto_mmode
	# jalr t0
	# ecall


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