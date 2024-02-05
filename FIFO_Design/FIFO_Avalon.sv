/*
 * Self Improvement Project - FIFO Design
 * 
 * Author: 
 * 
 * - Kishore Khed <kishorekhed@gmail.com> --- Logic
 * 
 */
 
`ifndef FIFO_SV
  `define FIFO_SV

`include "AvalonStream.sv"
 
module FIFO #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8)(
      input    clk,
      input    aresetn,
      AvalonStream.Master sourcePort,
      AvalonStream.Slave  sinkPort
  );

    // Module Instantiation
  fifo1 #(.DSIZE(DATA_WIDTH),
          .ASIZE(FIFO_DEPTH)
		  )fifo_1(
		  .rdata  (_dataOut),
			.wfull  (_writefull),
			.rempty (_readempty),
			
		  .wdata  (_dataIn),
			.winc   (_winc),
			.wclk   (aclk),
			.wrst_n (aresetn),
			.rinc   (_rinc),
			.rclk   (aclk),
			.rrst_n (aresetn)
			);

  assign sourcePort.valid =  _sourcePortValid; // input
  assign sourcePort.ready = !(_writefull); // output
  assign sourcePort.data = _dataOut; // input
  
  assign sinkPort.valid =  ! (_readempty); // output
  assign sinkPort.ready = _sinkPortReady; // input
  assign sinkPort.data = (_sinkPortReady & ! _readempty) ? _dataOut : 0; // output
  
  
  

  
