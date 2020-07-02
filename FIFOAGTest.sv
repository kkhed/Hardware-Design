`timescale 1ns / 1ps
`include "FIFOAG.sv"

module FIFOAGTest() ;

  localparam DATA_WIDTH = 32;
  localparam FIFO_DEPTH = 8;

  localparam TEST_LENGTH = 10;

  logic aclk = 0;
  logic aresetn = 0;

  // AXI4Stream# (.DATA_WIDTH(DATA_WIDTH)) axi4streamMaster();
  // AXI4Stream# (.DATA_WIDTH(DATA_WIDTH)) axi4streamSlave();



  logic [DATA_WIDTH-1:0] _dataArray [TEST_LENGTH:0];

  logic _testPass = 1, _testDone = 0;
  logic [DATA_WIDTH-1:0] _dataIn;
  logic [DATA_WIDTH-1:0] _dataOut;

  logic _dataOutValid, _dataOutReady;
  logic _dataInValid, _dataInReady;


  // Module Instantiation
  FIFOAG #(
    .FIFO_DEPTH(FIFO_DEPTH)
  ) fifoInst (
    .clk(aclk),
    .resetn(aresetn),
    .dataIn(_dataIn),
    .dataInValid(_dataInValid),
    .dataInReady(_dataInReady),
    .dataOut(_dataOut),
    .dataOutValid(_dataOutValid),
    .dataOutReady(_dataOutReady)
  );


  // .masterPort(axi4streamMaster),
  // .slavePort(axi4streamSlave)

  always #5ns aclk = ~aclk;

  // assign dataIn = _dataIn;
  // assign dataInValid = _dataOutValid;
  // assign _dataOutReady = dataInReady ;

  // assign _dataOut = dataOut;
  // assign _dataOutValid = dataOutValid;
  // assign dataOutReady = _dataOutReady;

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
      _dataInValid <= 1'b0; //$urandom; //_writeCounter % 2;
    end
    else
    begin
      if(_writeCounter < TEST_LENGTH)
      begin
        if(_dataOutReady & _dataOutValid)
        begin
          _dataArray[_writeCounter] = _dataIn;
          _writeCounter = _writeCounter + 1;
          $display("saving: ", _dataIn,
                   " writeCounter: ", _writeCounter,
                  );

        end

        _dataIn = $urandom();
        _dataInValid = 1'b1;

        $display ("writing: ", _dataIn ,
                  " writeCounter: ", _writeCounter,
                  " valid: ", _dataInValid,
                  " ready: ", _dataInReady,
                  " in: ", _dataInReady & _dataInValid );
      end
      else
        _dataInValid = 1'b0;
    end
  end

  always_ff @(posedge aclk)
  begin
    static int _readCounter = 0;
    if(!aresetn)
    begin
      _dataOutReady = 1'b0; //$urandom;
    end
    else
    begin
      if(_readCounter < TEST_LENGTH)
      begin
        if(_dataOutReady)
        begin
          if(_dataOutValid)
          begin
            $display ("reading: ", _dataOut , " =?= ", _dataArray[_readCounter], " ReadCounter: ", _readCounter, "TEST_PASS: ", _testPass);
            if(_dataOut != _dataArray[_readCounter])
                _testPass <= 0;

            _readCounter <= _readCounter + 1;
            _dataOutReady <= 1'b0; //$urandom;
          end
        end
        else
        begin
          _dataOutReady <= 1'b0; //$urandom(); //$urandom;
        end
      end
      else
      begin
        _dataOutReady = 1'b0;
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
