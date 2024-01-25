/*
 * Self Learning Project
 * 
 * File: wptr_full.sv
 *  
 * Author:
 * 
 * - Kishore Khed <kishore.khed@gmail.com>  -- Logic & Code
 *
 */
 
 
`timescale 1ns / 1ps
`include "fifo1.sv" //Stateless.sv"
//`include "FIFOStateMachine.sv"

module FIFOTestBench() ;

  localparam DSIZE = 8;
  localparam ASIZE = 4;
  localparam FIFO_DEPTH = 1<<ASIZE;
  

  localparam TEST_LENGTH = 20;

  logic aclk = 0;
  logic aresetn = 0;
  
  logic _winc = 1;
  logic _rinc = 1;

  logic [DSIZE-1:0] _dataArray [TEST_LENGTH:0];

  logic _testPass = 1, _testDone = 0;
  logic [DSIZE-1:0] _dataIn;
  logic [DSIZE-1:0] _dataOut;
  
  logic _writefull, readempty;
  

  // Module Instantiation
  fifo1 #(.DSIZE(DSIZE),
          .ASIZE(ASIZE)
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
  

  always #5ns aclk = ~aclk;

  initial begin
    // initialize Inputs
    aclk <= 0;
    aresetn <= 1'b0;

    #33ns;
    aresetn <= 1'b1;
  end

  always_ff @(posedge aclk)
  begin
    static int _writeCounter = 0;
    if(!aresetn)
    begin
      _dataIn = $urandom();
      // _slavePortValid <= 1'b0; //$urandom; //_writeCounter % 2;
    end
    else
    begin
      if(_writeCounter < TEST_LENGTH)
      begin
        if(!_writefull)
        begin
          _dataArray[_writeCounter] = _dataIn;
          _writeCounter = _writeCounter + 1;
          $display("saving: ", _dataIn,
                   " writeCounter: ", _writeCounter,
                  );

        end

        _dataIn = $urandom();
        // _slavePortValid = $urandom();

        $display ("writing: ", _dataIn ,
                  " writeCounter: ", _writeCounter,
				  " writefull: ", _writefull,
				  " readempty: ", _readempty,
                  " in: ", !(_writefull) );
      end
    end
  end

  always_ff @(posedge aclk)
  begin
    static int _readCounter = 0;
    if(aresetn)
    begin
      if(_readCounter < TEST_LENGTH)
      begin
        if(!(_readempty))
        begin
          $display ("reading: ", _dataOut , " =?= ", _dataArray[_readCounter], " ReadCounter: ", _readCounter, "TEST_PASS: ", _testPass);
          if(_dataOut != _dataArray[_readCounter])
            _testPass <= 0;

          _readCounter <= _readCounter + 1;
          // _masterPortReady <= $urandom(); //$urandom;
        end
        end
      end
      else
      begin
        // _masterPortReady = 1'b0;
        _testDone <= 1'b1;
      end
    end
  end

  always_comb
  begin
    if(_testDone)
    begin
      if(_testPass)
      begin
        $display ("TEST PASS = %d", _testPass);
        $finish();
      end
      else
        $error("TEST FAIL!");
    end
  end
endmodule
