module FIFOAG #(
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH = 8,
  parameter FULL_AXIS = 0
)(
  input  logic clk,
  input  logic resetn,
  input  logic [DATA_WIDTH - 1 :0] dataIn,
  input  logic dataInValid,
  output logic dataInReady,

  output logic [DATA_WIDTH - 1: 0] dataOut,
  output logic dataOutValid,
  input  logic dataOutReady,
  output logic [$clog2(FIFO_DEPTH)+1: 0] writeCounter

);


  // AXI4Stream.Master masterPort,
  // AXI4Stream.Slave slavePort

  //localparam DATA_WIDTH = $bits(masterPort.data);
  localparam REGISTER_WIDTH = DATA_WIDTH;

  logic [REGISTER_WIDTH-1: 0] _FIFO [FIFO_DEPTH-1:0];
  typedef logic signed [$clog2(FIFO_DEPTH)+1:0] CounterType;

  CounterType _writeCounter, _writeCounterPlus1, _writeCounterMinus1, _writeCounterPrev=-1;

  assign _writeCounterPlus1 = _writeCounterPrev + 1;
  assign _writeCounterMinus1 = _writeCounterPrev - 1;

  logic _in, _out, _dataInReady, _dataOutValid;

  assign writeCounter = _writeCounterPlus1;
  assign dataOutValid = _dataOutValid;
  assign _dataOutValid = _writeCounterPrev >= 0;

  assign dataInReady = _dataInReady;
  assign _dataInReady = _writeCounterPrev < FIFO_DEPTH-1;

  assign _in = dataInValid & _dataInReady;
  assign _out = _dataOutValid & dataOutReady;


  assign dataOut = _FIFO[0];


  always_comb
  begin
    if(_in & _out)
      _writeCounter = _writeCounterPrev;
    else
    begin
      if(_in & ~_out)
        _writeCounter = _writeCounterPlus1;
      else
      begin
        if(~_in & _out)
          _writeCounter = _writeCounterMinus1;
        else
          _writeCounter = _writeCounterPrev;
      end
    end
  end


  always_ff @(posedge clk)
  begin
    if(resetn)
    begin
      if(_in)
      begin
      _FIFO[_writeCounter] <= dataIn;
      end

      if(_out)
      begin
        for(int i=0; i<_writeCounterPrev; i++)
          _FIFO[i] <= _FIFO[i+1];
      end
      _writeCounterPrev <= _writeCounter;
    end
    else
    begin
      _writeCounterPrev <= -1;
    end
  end
endmodule
