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

`ifndef _ODMA_REG_DEFINES_SV
`define _ODMA_REG_DEFINES_SV

`define REG_ODMA_MIN_ADDR                   64'h0000_0008_8000_0000
`define REG_ODMA_MAX_ADDR                   64'h0000_0008_8000_FFFC

//A2H channel registers
`define REG_A2H_CH0_CTRL_W1S                64'h0000_0008_8000_1008
`define REG_A2H_CH0_CTRL_W1C                64'h0000_0008_8000_100C
`define REG_A2H_CH0_WB_SIZE                 64'h0000_0008_8000_1080
`define REG_A2H_CH0_WB_ADDR_LO              64'h0000_0008_8000_1088
`define REG_A2H_CH0_WB_ADDR_HI              64'h0000_0008_8000_108C
`define REG_A2H_CH1_CTRL_W1S                64'h0000_0008_8000_1108
`define REG_A2H_CH1_CTRL_W1C                64'h0000_0008_8000_110C
`define REG_A2H_CH1_WB_SIZE                 64'h0000_0008_8000_1180
`define REG_A2H_CH1_WB_ADDR_LO              64'h0000_0008_8000_1188
`define REG_A2H_CH1_WB_ADDR_HI              64'h0000_0008_8000_118C
`define REG_A2H_CH2_CTRL_W1S                64'h0000_0008_8000_1208
`define REG_A2H_CH2_CTRL_W1C                64'h0000_0008_8000_120C
`define REG_A2H_CH2_WB_SIZE                 64'h0000_0008_8000_1280
`define REG_A2H_CH2_WB_ADDR_LO              64'h0000_0008_8000_1288
`define REG_A2H_CH2_WB_ADDR_HI              64'h0000_0008_8000_128C
`define REG_A2H_CH3_CTRL_W1S                64'h0000_0008_8000_1308
`define REG_A2H_CH3_CTRL_W1C                64'h0000_0008_8000_130C
`define REG_A2H_CH3_WB_SIZE                 64'h0000_0008_8000_1380
`define REG_A2H_CH3_WB_ADDR_LO              64'h0000_0008_8000_1388
`define REG_A2H_CH3_WB_ADDR_HI              64'h0000_0008_8000_138C

//H2A channel registers
`define REG_H2A_CH0_CTRL_W1S                64'h0000_0008_8000_0008
`define REG_H2A_CH0_CTRL_W1C                64'h0000_0008_8000_000C
`define REG_H2A_CH0_WB_SIZE                 64'h0000_0008_8000_0080
`define REG_H2A_CH0_WB_ADDR_LO              64'h0000_0008_8000_0088
`define REG_H2A_CH0_WB_ADDR_HI              64'h0000_0008_8000_008C
`define REG_H2A_CH1_CTRL_W1S                64'h0000_0008_8000_0108
`define REG_H2A_CH1_CTRL_W1C                64'h0000_0008_8000_010C
`define REG_H2A_CH1_WB_SIZE                 64'h0000_0008_8000_0180
`define REG_H2A_CH1_WB_ADDR_LO              64'h0000_0008_8000_0188
`define REG_H2A_CH1_WB_ADDR_HI              64'h0000_0008_8000_018C
`define REG_H2A_CH2_CTRL_W1S                64'h0000_0008_8000_0208
`define REG_H2A_CH2_CTRL_W1C                64'h0000_0008_8000_020C
`define REG_H2A_CH2_WB_SIZE                 64'h0000_0008_8000_0280
`define REG_H2A_CH2_WB_ADDR_LO              64'h0000_0008_8000_0288
`define REG_H2A_CH2_WB_ADDR_HI              64'h0000_0008_8000_028C
`define REG_H2A_CH3_CTRL_W1S                64'h0000_0008_8000_0308
`define REG_H2A_CH3_CTRL_W1C                64'h0000_0008_8000_030C
`define REG_H2A_CH3_WB_SIZE                 64'h0000_0008_8000_0380
`define REG_H2A_CH3_WB_ADDR_LO              64'h0000_0008_8000_0388
`define REG_H2A_CH3_WB_ADDR_HI              64'h0000_0008_8000_038C

//A2H channel DMA registers
`define REG_A2H_CH0_DMA_ID                  64'h0000_0008_8000_5000
`define REG_A2H_CH0_DMA_DSC_ADDR_LO         64'h0000_0008_8000_5080
`define REG_A2H_CH0_DMA_DSC_ADDR_HI         64'h0000_0008_8000_5084
`define REG_A2H_CH0_DMA_DSC_ADJ             64'h0000_0008_8000_5088
`define REG_A2H_CH0_DMA_DSC_CREDIT          64'h0000_0008_8000_508C
`define REG_A2H_CH1_DMA_ID                  64'h0000_0008_8000_5100
`define REG_A2H_CH1_DMA_DSC_ADDR_LO         64'h0000_0008_8000_5180
`define REG_A2H_CH1_DMA_DSC_ADDR_HI         64'h0000_0008_8000_5184
`define REG_A2H_CH1_DMA_DSC_ADJ             64'h0000_0008_8000_5188
`define REG_A2H_CH1_DMA_DSC_CREDIT          64'h0000_0008_8000_518C
`define REG_A2H_CH2_DMA_ID                  64'h0000_0008_8000_5200
`define REG_A2H_CH2_DMA_DSC_ADDR_LO         64'h0000_0008_8000_5280
`define REG_A2H_CH2_DMA_DSC_ADDR_HI         64'h0000_0008_8000_5284
`define REG_A2H_CH2_DMA_DSC_ADJ             64'h0000_0008_8000_5288
`define REG_A2H_CH2_DMA_DSC_CREDIT          64'h0000_0008_8000_528C
`define REG_A2H_CH3_DMA_ID                  64'h0000_0008_8000_5300
`define REG_A2H_CH3_DMA_DSC_ADDR_LO         64'h0000_0008_8000_5380
`define REG_A2H_CH3_DMA_DSC_ADDR_HI         64'h0000_0008_8000_5384
`define REG_A2H_CH3_DMA_DSC_ADJ             64'h0000_0008_8000_5388
`define REG_A2H_CH3_DMA_DSC_CREDIT          64'h0000_0008_8000_538C

//H2A channel DMA registers
`define REG_H2A_CH0_DMA_ID                  64'h0000_0008_8000_4000
`define REG_H2A_CH0_DMA_DSC_ADDR_LO         64'h0000_0008_8000_4080
`define REG_H2A_CH0_DMA_DSC_ADDR_HI         64'h0000_0008_8000_4084
`define REG_H2A_CH0_DMA_DSC_ADJ             64'h0000_0008_8000_4088
`define REG_H2A_CH0_DMA_DSC_CREDIT          64'h0000_0008_8000_408C
`define REG_H2A_CH1_DMA_ID                  64'h0000_0008_8000_4100
`define REG_H2A_CH1_DMA_DSC_ADDR_LO         64'h0000_0008_8000_4180
`define REG_H2A_CH1_DMA_DSC_ADDR_HI         64'h0000_0008_8000_4184
`define REG_H2A_CH1_DMA_DSC_ADJ             64'h0000_0008_8000_4188
`define REG_H2A_CH1_DMA_DSC_CREDIT          64'h0000_0008_8000_418C
`define REG_H2A_CH2_DMA_ID                  64'h0000_0008_8000_4200
`define REG_H2A_CH2_DMA_DSC_ADDR_LO         64'h0000_0008_8000_4280
`define REG_H2A_CH2_DMA_DSC_ADDR_HI         64'h0000_0008_8000_4284
`define REG_H2A_CH2_DMA_DSC_ADJ             64'h0000_0008_8000_4288
`define REG_H2A_CH2_DMA_DSC_CREDIT          64'h0000_0008_8000_428C
`define REG_H2A_CH3_DMA_ID                  64'h0000_0008_8000_4300
`define REG_H2A_CH3_DMA_DSC_ADDR_LO         64'h0000_0008_8000_4380
`define REG_H2A_CH3_DMA_DSC_ADDR_HI         64'h0000_0008_8000_4384
`define REG_H2A_CH3_DMA_DSC_ADJ             64'h0000_0008_8000_4388
`define REG_H2A_CH3_DMA_DSC_CREDIT          64'h0000_0008_8000_438C

`endif
