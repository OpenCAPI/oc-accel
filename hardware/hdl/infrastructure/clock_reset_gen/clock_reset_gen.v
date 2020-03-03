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
`timescale 1ns/1ps




module clock_reset_gen # (parameter INCLUDE_CLK_WIZ = 0)
               (
                input                clock_afu,
                input                reset_afu_n,
                input                soft_reset_action,

                output               clk_wiz_reset,
                input                clk_wiz_locked,
                input                clk_wiz_clk_out, 

                output               clock_action,
                output               reset_action_n
                );

wire reset_action_d;


assign reset_action_d = (INCLUDE_CLK_WIZ == 1) ? 
                        ( (~reset_afu_n) || soft_reset_action || (~clk_wiz_locked) ) :
                        ( (~reset_afu_n) || soft_reset_action);

assign clock_action = (INCLUDE_CLK_WIZ == 1) ? clk_wiz_clk_out : clock_afu; 


reg reset_action_q;
always @ (posedge clock_action)
    reset_action_q <= reset_action_d;

assign reset_action_n = ~reset_action_q;

assign clk_wiz_reset = ~reset_afu_n;
endmodule
