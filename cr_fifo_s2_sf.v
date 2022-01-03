// SPDX-License-Identifier: Apache-2.0
/*
 * Copyright 2022, Luke E. McKay.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** Synchronous Dual Clock FIFO with Static Flags
 *  Version 0.1.0
 */
module cr_fifo_s2_sf
#(
  parameter pWidth = 8;       //!< Width in bits of FIFO word
  parameter pDepth = 8,       //!< Depth/size of FIFO in words, power of 2
  parameter pPushAeLevel = 2, //!< PushAlmostEmpty is set when FIFO count <= this
  parameter pPushAfLevel = 2, //!< PushAlmostFull is set when FIFO count > this
  parameter pPopAeLevel = 2,  //!< PopAlmostEmpty is set when FIFO count <= this
  parameter pPopAfLevel = 2,  //!< PopAlmostFull is set when FIFO count is > this
//  parameter pErrMode = 0,     //!< 0 -> set till reset;  1 -> set while error exists  @todo this make sense?
//  parameter pPushSync = 2,    //!< Push flag sync mode
//  parameter pPopSync = 2,     //!< Pop flag sync mode
  parameter pRstMode = 0      //!< 0 -> asynchronous reset;  1 -> synchronous reset
)(
  //# {{clocks|}}
  input  wire Push_clk,        //!< Clock input for push interface
  input  wire Push_rst_n,      //!< Reset input for push interface, active low
  input  wire Pop_clk,         //!< Clock input for pop interface
  input  wire Pop_rst_n,       //!< Clock input for pop interface, active low
  //# {{}}
  input  wire PushReq_n,       //!< FIFO push request, active low
  output wire PushWordCount,   //!< Number of words in FIFO
  output wire PushEmpty,       //!< Status flag FIFO empty
  output wire PushAlmostEmpty, //!< Status flag FIFO almost empty (pPushAeLevel)
  output wire PushHalfFull,    //!< Status flag FIFO half full
  output wire PushAlmostFull,  //!< Status flag FIFO almost full (pPushAfLevel)
  output wire PushFull,        //!< Status flag FIFO full
  output wire PushError,       //!< Status flag FIFO overrun error
  //# {{}}
  input  wire PopReq_n,        //!< FIFO pop request, active low
  output wire PopWordCount,    //!< Number of words in FIFO
  output wire PopEmpty,        //!< Status flag FIFO empty
  output wire PopAlmostEmpty,  //!< Status flag FIFO almost empty (pPopAeLevel)
  output wire PopHalfFull,     //!< Status flag FIFO half full
  output wire PopAlmostFull,   //!< Status flag FIFO almost full (pPopAfLevel)
  output wire PopFull,         //!< Status flag FIFO full
  output wire PopError,        //!< Status flag FIFO underrun error
  //# {{}}
  input  wire [pWidth-1:0] PopFifoData;
  output wire [pWidth-1:0] PushFifoData;
);

localparam ADDR_SIZE = $clog2(pDepth);
// @todo add error for incorrect size
// @todo FALLTHROUGH
localparam FALLTHROUGH = 0;

wire pop_read_enable;
wire push_write_enable;

wire [ADDR_SIZE-1:0] push_write_addr;
wire [ADDR_SIZE-1:0] pop_read_addr;

// FIFO Controller
cr_fifoctl_s2_sf #(
  pDepth       (pDepth),
  pPushAeLevel (pPushAeLevel),
  pPushAfLevel (pPushAfLevel),
  pPopAeLevel  (pPopAeLevel),
  pPopAfLevel  (pPopAfLevel),
//  pErrMode     (pErrMode),
//  pPushSync    (pPushSync),
//  pPopSync     (pPopSync),
  pRstMode     (pRstMode) )
inst_fifoctl (
  .Push_clk        (Push_clk),
  .Push_rst_n      (Push_rst_n),
  .Pop_clk         (Pop_clk),
  .Pop_rst_n       (Pop_rst_n),
  .PushReq_n       (PushReq_n),
  .PushWordCount   (PushWordCount),
  .PushEmpty       (PushEmpty),
  .PushAlmostEmpty (PushAlmostEmpty),
  .PushHalfFull    (PushHalfFull),
  .PushAlmostFull  (PushAlmostFull),
  .PushFull        (PushFull),
  .PushError       (PushError),
  .PopReq_n        (PopReq_n),
  .PopWordCount    (PopWordCount),
  .PopEmpty        (PopEmpty),
  .PopAlmostEmpty  (PopAlmostEmpty),
  .PopHalfFull     (PopHalfFull),
  .PopAlmostFull   (PopAlmostFull),
  .PopFull         (PopFull),
  .PopError        (PopError),
  .WrEn_n          (push_write_enable),
  .WrAddr          (push_write_addr),
  .RdEn_n          (pop_read_enable),
  .RdAddr          (pop_read_addr)
);

// Physical memory for the FIFO
cr_ram_r_w_2c #(
  .pWidth(pWidth),
  .pAddrSize(ADDR_SIZE),
  .pAsyncRead(FALLTHROUGH) )
inst_ram (
  .RdClk  (PopClk),
  .RdAddr (pop_read_addr),
  .RdEn   (pop_read_enable),
  .RdData (PopFifoData),
  .WrClk  (PushClk)
  .WrAddr (push_write_addr),
  .WrEn   (push_write_enable), // @todo prevent overflow underflow options?   & !PushFull),
  .WrData (PushFifoData),
);

endmodule
