/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef __OSNAP_GLOBAL_REGS_H__
#define __OSNAP_GLOBAL_REGS_H__

/**
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#ifdef __cplusplus
extern "C" {
#endif
//***************************************************************************
//***************************************************************************
//
//This file defines the registers in Global MMIO space, or snap registers.
//
//***************************************************************************
//***************************************************************************

#define  CORE_BASE_ADDR 0x0
#define DEBUG_BASE_ADDR 0x1A000
#define   FIR_BASE_ADDR 0x1C000

#define SNAP_M_FIR_NUM  5
//***************************************************************************
//***************************************************************************
/*
 * Implementation Version Register (IVR)
 * =====================================
 * 63..40 RO: SNAP Release
 * 63..56 Major release number
 * 55..48 Intermediate release number
 * 47..40 Minor release number
 * 39..32 RO: Distance of commit to SNAP release
 * 31.. 0 RO: First eight digits of SHA ID for commit
 *
 * POR value depends on source for the build.
 * Example for build based on commit with SHA ID eb43f4d80334d6a127af150345fed12dc5f45b7c
 * and with distance 13 to SNAP Release v1.25.4: 0x0119040D_EB43F4D8
 */
#define        SNAP_IVR        (CORE_BASE_ADDR + 0)

/*
 * Build Date Register (BDR)
 * =========================
 * 63..48 RO: Reserved
 * 47.. 0 RO: BCD coded build date and time
 *        47..32: YYYY (year)
 *        31..24: mm   (month)
 *        23..16: dd   (day of month)
 *        15..08: HH   (hour)
 *        07..00: MM   (minute)
 *
 *   POR value depends on build date and time.
 *   Example for build on January 12th, 2017 at 15:27: 0x00002017_01121527
 */
#define SNAP_BDR               (CORE_BASE_ADDR + 0x8)

/*
 * SNAP Command Register (SCR) (commands <Reset>, <Abort>, <Stop> are not yet implemente)
 * ===========================
 * 63..48 RW: Argument
 * 47.. 8 RO: Reserved
 *  7.. 0 RW: Command
 *  Legal commands are:
 *        0x10 Exploration Done: Set Exploration Done bit in SNAP status register
 *                                Argument bits 63..52: Don't care
 *                                Argument bits 51..48: Maximum Short Action Type
 *        0x08 Reset:            Reset the complete SNAP framework including all actions immediately
 *                                Argument: Don't care
 *        0x04 Abort:            Abort current jobs and set accelerator to finished immediately (asserting aXh_jdone)
 *                                Argument: Don't care
 *        0x02 Stop:             Finish current jobs, then set accelerator to finished (asserting aXh_jdone)
 *                                Argument: Don't care
 *        0x00 NOP
 */
#define SNAP_SCR               (CORE_BASE_ADDR + 0x10)

/*
 * SNAP Status Register (SSR)
 * =========================
 * 63..9  RO: Reserved
 *     8  RO: Exploration Done
 *            This means that the ATRi setup is complete and the values are valid
 *  7..4  RO: Maximum Short Action Type (number of Short Action Types - 1)
 *  3..0  RO: Maximum Action ID
 *
 *  POR value: 0x0000000000000000
 */
#define SNAP_SSR               (CORE_BASE_ADDR + 0x18)


/*
 *  SNAP Capability Register (CAP)
 *  ===================================
 *   63..40 RO: Reserved
 *   39..36 RO: Minimum size for DMA transfers to/from Host
 *              Value t means that minimum transfer size is 2^t B
 *   35..32 RO: Data alignment for DMA transfers to/from Host
 *              Value a means that transfers need to be 2^a B aligned
 *   31..16 RO: Size of attached on-card SDRAM in MB
 *   15..9  RO: Reserved
 *       8  RO: NVMe enabled
 *    7..0  RO: Card type:
 *              0x31 : AD9V3
 */
#define SNAP_CAP               (CORE_BASE_ADDR + 0x30)

#define SNAP_NVME_ENA   0x100
#define AD9V3_OC_CARD   0x031     /* OpenCAPI 3.0*/
#define AD9H3_OC_CARD   0x032     /* OpenCAPI 3.0*/
#define AD9H7_OC_CARD   0x033     /* OpenCAPI 3.0*/

/*
 * Freerunning Timer (FRT)
 * =======================
 * 63..0  RO: Counter counting the number of clock cycles since reset (afu open)
 *            This counter increments with the 250MHz PSL clock
 */
#define SNAP_FRT               (CORE_BASE_ADDR + 0x40)

//***************************************************************************
//***************************************************************************
/*
 * DEBUG Clear (DBG_CLR)
 * =======================
 * 63..62  RO: Reserved
 *      0  RW: Clear all debug counters
 */
#define DEBUG_DBG_CLR          (DEBUG_BASE_ADDR + 0x0)

/*
 * Counter for TLX_CMD (CNT_TLX_CMD)
 * =======================
 * 63..0   RO: Counter for the number of TLX commands
 */
#define DEBUG_CNT_TLX_CMD      (DEBUG_BASE_ADDR + 0x8)

/*
 * Counter for TLX_RSP (CNT_TLX_RSP)
 * =======================
 * 63..0   RO: Counter for the number of TLX responses
 */
#define DEBUG_CNT_TLX_RSP      (DEBUG_BASE_ADDR + 0x10)


/*
 * Counter for TLX_RTY (CNT_TLX_RTY)
 * =======================
 * 63..0   RO: Counter for the number of TLX retry responses
 */
#define DEBUG_CNT_TLX_RTY      (DEBUG_BASE_ADDR + 0x18)

/*
 * Counter for TLX_FAIL (CNT_TLX_FAIL)
 * =======================
 * 63..0   RO: Counter for the number of TLX fail responses
 */
#define DEBUG_CNT_TLX_FAIL      (DEBUG_BASE_ADDR + 0x20)

/*
 * Counter for TLX_XLP (CNT_TLX_XLP)
 * =======================
 * 63..0   RO: Counter for the number of TLX translation pendings
 */
#define DEBUG_CNT_TLX_XLP      (DEBUG_BASE_ADDR + 0x28)


/*
 * Counter for TLX_XLD (CNT_TLX_XLD)
 * =======================
 * 63..0   RO: Counter for the number of TLX translation done
 */
#define DEBUG_CNT_TLX_XLD      (DEBUG_BASE_ADDR + 0x30)

/*
 * Counter for AXI_W_CMD (CNT_AXI_W_CMD)
 * =======================
 * 63..0   RO: Counter for the number of AXI Write Commands (awvalid)
 */
#define DEBUG_CNT_AXI_W_CMD    (DEBUG_BASE_ADDR + 0x38)

/*
 * Counter for AXI_R_CMD (CNT_AXI_R_CMD)
 * =======================
 * 63..0   RO: Counter for the number of AXI Read Commands (arvalid)
 */
#define DEBUG_CNT_AXI_R_CMD    (DEBUG_BASE_ADDR + 0x40)

/*
 * Counter for AXI_W_RSP (CNT_AXI_W_RSP)
 * =======================
 * 63..0   RO: Counter for the number of AXI Write responses (bvalid)
 */
#define DEBUG_CNT_AXI_W_RSP    (DEBUG_BASE_ADDR + 0x48)

/*
 * Counter for AXI_R_RSP (CNT_AXI_R_RSP)
 * =======================
 * 63..0   RO: Counter for the number of AXI Read responses (rvalid)
 */
#define DEBUG_CNT_AXI_R_RSP    (DEBUG_BASE_ADDR + 0x50)



//***************************************************************************
//***************************************************************************
/*
 * Fault Isolation Register for FIFO overflow (FIFO_OVFL)
 * =======================
 * 63..0   todo
 */
#define FIR_FIFO_OVFL          (FIR_BASE_ADDR + 0x0)

/*
 * Fault Isolation Register for tlx command over commit (TLX_CMD_OC)
 * =======================
 * 63..0   todo
 */
#define FIR_TLX_CMD_OC         (FIR_BASE_ADDR + 0x8)

/*
 * Fault Isolation Register for tlx command response_unsupport (TLX_RSP_US)
 * =======================
 * 63..0   todo
 */
#define FIR_TLX_RSP_US         (FIR_BASE_ADDR + 0x10)

/*
 * Fault Isolation Register for tlx stall timeout (TLX_TO)
 * =======================
 * 63..0   todo
 */
#define FIR_TLX_TO             (FIR_BASE_ADDR + 0x18)

/*
 * Fault Isolation Register for tlx stall timeout (AXI_TO)
 * =======================
 * 63..0   todo
 */
#define FIR_AXI_TO             (FIR_BASE_ADDR + 0x20)


//***************************************************************************
//***************************************************************************
/* NVMe registers are not defined */


#ifdef __cplusplus
}
#endif

#endif        /* __OSNAP_GLOBAL_REGS_H__ */
