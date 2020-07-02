/*
 * Project            : AlphaGrep Securities Take Home Test
 * Language           : SystemVerilog
 * File name          : MsgDecoderAG.sv
 * Author             : Kishore Khed
 * Date created       : 20200623
 * Purpose            : Take Home Test - Decode MSG
 * Revision           : v0.1
 * Date        Author          Ref      Revision
 * 20200623    Kishore Khed     1       
 *
*/

module MsgDecoderAG #(
  parameter IN_DATA_WIDTH = 64,
  parameter OUT_DATA_WIDTH = 256,
  parameter BYTE_MASK_WIDTH = 32
)(
  input logic                       clk,
  input logic                       resetn,
  input logic                       inValid,
  input logic                       inStartOfPayload,
  input logic                       inEndOfPayload,
  input logic [IN_DATA_WIDTH-1:0]   inData,
  input logic [2:0]                 inEmpty,
  input logic                       inError,

  output logic                      inReady,
  output logic [OUT_DATA_WIDTH-1:0] outData,
  output logic                      outValid,
  output logic [BYTE_MASK_WIDTH-1:0]outByteMask
);
  
  localparam BYTE_LENGTH = 8;
  localparam MESSAGE_COUNT_BYTES = 2;
  localparam MESSAGE_LENGTH_BYTES = 2;
  localparam MESSAGE_COUNT_BITS = MESSAGE_COUNT_BYTES*BYTE_LENGTH;
  localparam MESSAGE_LENGTH_BITS = MESSAGE_LENGTH_BYTES*BYTE_LENGTH;

  localparam MAX_MESSAGE_COUNT_BYTES = 32;
  localparam MIN_MESSAGE_COUNT_BYTES = 8;

  // StateMachine

  typedef enum {
    RESET               =  'b000,
    START_OF_PAYLOAD    =  'b001,
    MESSAGE_DATA        =  'b010,
    NEW_MESSAGE_DATA    =  'b011,
    END_OF_PAYLOAD      =  'b100
  } stateTypes;
  
  stateTypes _state, _stateNext;

  logic [MESSAGE_COUNT_BITS-1: 0] _messageCount, _remainingMsgCount;
  logic [MESSAGE_LENGTH_BITS-1: 0] _messageLength, _remainingMsgLength;

  logic [IN_DATA_WIDTH - 1: 0] _fifoOutData;
  logic _inReady;

  logic [4*BYTE_LENGTH - 1: 0] _outDataNMtwo;
  logic [1*BYTE_LENGTH - 1: 0] _outDataSMsev;
  logic [2*BYTE_LENGTH - 1: 0] _outDataSMsix;

  logic _twoBytesTxd, _threeBytesTxd, _fourBytesTxd, _fiveBytesTxd, _sixBytesTxd, _sevenBytesTxd, _eightBytesTxd;

  logic _oneByteTxdNM, _twoBytesTxdNM, _threeBytesTxdNM, _fourBytesTxdNM, _fiveBytesTxdNM, _sixBytesTxdNM, _sevenBytesTxdNM, _eightBytesTxdNM;

  logic [OUT_DATA_WIDTH - 1: 0] _outData, _outDataTemp;
  logic [4*BYTE_LENGTH - 1: 0] _outDataFP;
  logic [BYTE_MASK_WIDTH - 1: 0] _outByteMask;
  logic [4 - 1: 0] _outByteMaskFP;

  logic _outValid, _fifoOutValid, _fifoOutReady;

  assign outData = _outData;

  assign outValid = _outValid;
  assign outByteMask = _outByteMask;

  assign inReady = _inReady;

  // Buffer the inComing Data using a FIFO

  FIFOAXISX fifoBuffer (
  .s_axis_aresetn   (resetn),
  .s_axis_aclk      (clk),
  .s_axis_tvalid    (inValid),
  .s_axis_tready    (_inReady),
  .s_axis_tdata     (inData),
  .m_axis_tvalid    (_fifoOutValid),
  .m_axis_tready    (_fifoOutReady),
  .m_axis_tdata     (_fifoOutData)
);


  // State Transistion
  always_ff @ (posedge clk)
  begin
    if(!resetn)
      _state <= RESET;
    else
      _state <= _stateNext;
  end

  always_comb 
  begin
     case (_state)
     RESET: 
     begin
       if(!resetn)
       begin
         _outData <= 0;
         _outValid <= 0;
         _outByteMask <= 0;
         _twoBytesTxd <= 0;
         _threeBytesTxd <= 0;
         _fourBytesTxd <= 0;
         _fiveBytesTxd <= 0;
         _sixBytesTxd <= 0;
         _sevenBytesTxd <= 0;
         _eightBytesTxd <= 0;

          _oneByteTxdNM <= 0;
          _twoBytesTxdNM <= 0;
          _threeBytesTxdNM <= 0;
         _fourBytesTxdNM <= 0;
         _fiveBytesTxdNM <= 0;
         _sixBytesTxdNM <= 0;
         _sevenBytesTxdNM <= 0;
         _eightBytesTxdNM <= 0;

         _fifoOutReady <= 0;
         // _inReady <= 0;
       end
       else
         _stateNext <= START_OF_PAYLOAD;
     end
     START_OF_PAYLOAD:
     begin
       _fifoOutReady <= 1'b1;
       if(_fifoOutValid)
       begin
         _messageCount <= _fifoOutData[IN_DATA_WIDTH -1 -: MESSAGE_COUNT_BITS];
         _messageLength <= _fifoOutData[IN_DATA_WIDTH -1 -MESSAGE_COUNT_BITS -: MESSAGE_LENGTH_BITS];
         _outDataFP <= _fifoOutData[IN_DATA_WIDTH -(MESSAGE_COUNT_BITS + MESSAGE_LENGTH_BITS) -1 -: 4*BYTE_LENGTH];
         _stateNext <= MESSAGE_DATA;
       end
     end
     MESSAGE_DATA:
     begin
        _fifoOutReady <= 1'b0;
        if (_fourBytesTxd | _fiveBytesTxd | _sixBytesTxd | _sevenBytesTxd | _eightBytesTxd )
        begin
          _stateNext <= NEW_MESSAGE_DATA;
          _remainingMsgCount <= _messageCount - 1;
        end
        else
          _stateNext <= MESSAGE_DATA;
     end
     NEW_MESSAGE_DATA:
     begin
       _fifoOutReady <= 1'b1;
       _stateNext <= NEW_MESSAGE_DATA;
     end
     default: 
     begin
       _outData <= 64'h001234ABCD;
     end
     endcase
  end


  always_ff @(posedge clk) 
  begin
    if(_messageLength >= 8 && _state == START_OF_PAYLOAD)
    begin
      _remainingMsgLength <= _messageLength - 4;
      _outByteMaskFP <= 4'hF;
    end
    else if (_remainingMsgLength >= 4 && _state == MESSAGE_DATA) // state = MESSAGE_DATA
    begin
      if (_remainingMsgLength == 4)
      begin
        $display("MESSAGE_DATA_4");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataFP,_fifoOutData[IN_DATA_WIDTH-1 -: 4*BYTE_LENGTH]};
        _outValid <= 1'b1;
        _outByteMask <= {4'hF,'b1111};
        _fourBytesTxd <= 1'b1;
      end
      else if (_remainingMsgLength == 5)
      begin
        $display("MESSAGE_DATA_5");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataFP,_fifoOutData[IN_DATA_WIDTH-1 -: (5*BYTE_LENGTH)]};
        _outValid <= 1'b1;
        _outByteMask <= {4'hF ,5'h1F};
        _remainingMsgLength <= _remainingMsgLength - 5;
        _fiveBytesTxd <= 1'b1;
      end
      else if (_remainingMsgLength == 6)
      begin
        $display("MESSAGE_DATA_6");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataFP,_fifoOutData[IN_DATA_WIDTH-1 -: (6*BYTE_LENGTH)]};
        _outValid <= 1'b1;
        _outByteMask <= {4'hF,6'h3F};
        _remainingMsgLength <= _remainingMsgLength - 6;
        _sixBytesTxd <= 1'b1;
      end
      else if (_remainingMsgLength == 7)
      begin
        $display("MESSAGE_DATA_7");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataFP,_fifoOutData[IN_DATA_WIDTH-1 -: (7*BYTE_LENGTH)]};
        _outValid <= 1'b1;
        _outByteMask <= {4'hF,7'h7F};
        _remainingMsgLength <= _remainingMsgLength - 7;
        _sevenBytesTxd <= 1'b1;
      end
      else if (_remainingMsgLength >= 8)
      begin
        $display("MESSAGE_DATA_8");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataFP,_fifoOutData[IN_DATA_WIDTH-1 -: (8*BYTE_LENGTH)]};
        _outValid <= 1'b1;
        _outByteMask <= {4'hF,8'hFF};
        _remainingMsgLength <= _remainingMsgLength - 8;
        _eightBytesTxd <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk)
  begin
    if(_state == NEW_MESSAGE_DATA)
    begin
      if(_twoBytesTxd)
      begin
        if(_remainingMsgLength == 0)
        begin
        _remainingMsgCount <= _remainingMsgCount - 1;
        _messageLength <= _fifoOutData[IN_DATA_WIDTH -(2*BYTE_LENGTH)-1 -: (2*BYTE_LENGTH)];
        _fifoOutReady <= 1'b1;
        _remainingMsgLength <= _messageLength;
        end
        _outDataNMtwo <= {_fifoOutData[IN_DATA_WIDTH - ((2+2)*BYTE_LENGTH) -: 4*(BYTE_LENGTH)]};
      end
      else if(_fourBytesTxd)
      begin
        _messageLength <= _fifoOutData[IN_DATA_WIDTH -(4*BYTE_LENGTH)-1 -: (2*BYTE_LENGTH)];
        _outDataSMsix <= {_fifoOutData[IN_DATA_WIDTH - ((4+2)*BYTE_LENGTH)-1 -: (2*BYTE_LENGTH)]};
        _remainingMsgLength <= _messageLength - 2;
        _twoBytesTxdNM <= 1'b1;
        _fifoOutReady <= 1'b1;
      end
      else if(_fiveBytesTxd)
      begin
        _messageLength <= _fifoOutData[IN_DATA_WIDTH -(5*BYTE_LENGTH)-1 -: (2*BYTE_LENGTH)];
        _outDataSMsev <= _fifoOutData[IN_DATA_WIDTH - ((5+2)*BYTE_LENGTH)-1 -: (1*BYTE_LENGTH)];
        _remainingMsgLength <= _messageLength - 1;
        _oneByteTxdNM <= 1'b1;
        _fifoOutReady <= 1'b1;
      end
      else if(_sixBytesTxd)
      begin
        _messageLength <= _fifoOutData[IN_DATA_WIDTH -(6*BYTE_LENGTH)-1 -: (2*BYTE_LENGTH)];
        _remainingMsgLength <= _messageLength;
        _fifoOutReady <= 1'b1;
      end
      else if(_sevenBytesTxd)
      begin
        _messageLength <= _fifoOutData[IN_DATA_WIDTH -(6*BYTE_LENGTH)-1 -: (1*BYTE_LENGTH)];
        _fifoOutReady <= 1'b1;
      end
      else if(_eightBytesTxd)
      begin
        _fifoOutReady <= 1'b1;
        _remainingMsgLength <= _remainingMsgLength - 8;
      end
    end
  end

  always_ff @(posedge clk)
  begin
    if (_state == NEW_MESSAGE_DATA)
    begin
      if (_remainingMsgLength == 2)
      begin
        $display("MESSAGE_DATA_2_2");
        _fifoOutReady <= 1'b1;
        _outData <= {_outData, _fifoOutData[IN_DATA_WIDTH-1 -: 2*BYTE_LENGTH]};
        _outValid <= 1'b1;
        _twoBytesTxdNM <= 1'b1;
        _remainingMsgLength <= _remainingMsgLength - 2;
      end
      else if(_remainingMsgLength == 6)
      begin
        $display("MESSAGE_DATA_6_2");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataSMsix, _fifoOutData[IN_DATA_WIDTH-1 -: 6*BYTE_LENGTH]};
        _outValid <= 1'b1;
      end
      else if(_remainingMsgLength == 7)
      begin
        $display("MESSAGE_DATA_7_2");
        _fifoOutReady <= 1'b1;
        _outData <= {_outDataSMsev, _fifoOutData[IN_DATA_WIDTH-1 -: 7*BYTE_LENGTH]};
        _outValid <= 1'b1;
      end
      else if(_remainingMsgLength >= 8)
      begin
        $display("MESSAGE_DATA_8_2");
        if(_oneByteTxdNM)
        begin
          // $display("FiveBytes Indside EightByte");
          _fifoOutReady <= 1'b1;
          _outData <= {_outDataSMsev, _fifoOutData[IN_DATA_WIDTH-1 -: 8*BYTE_LENGTH]};
          _outValid <= 1'b1;
          _eightBytesTxdNM <= 1'b1;
          _oneByteTxdNM <= 0;
        end
        else if (_twoBytesTxdNM)
        begin
          _outData <= {_outDataNMtwo, _fifoOutData[IN_DATA_WIDTH-1 -: 8*BYTE_LENGTH]};
          _outValid <= 1'b1;
          _eightBytesTxdNM <= 1'b1;
          _twoBytesTxdNM <= 1'b0;
        end
        else if (_fourBytesTxdNM)
        begin
          _outData <= {_outDataSMsix, _fifoOutData[IN_DATA_WIDTH-1 -: 7*BYTE_LENGTH]};
          _outValid <= 1'b1;
          _sevenBytesTxdNM <= 1'b1;
          _fourBytesTxdNM <= 0;
        end
        else if (_fiveBytesTxdNM)
        begin
          $display("FiveBytes Indside EightByte");
          _fifoOutReady <= 1'b1;
          _outData <= {_outDataSMsev, _fifoOutData[IN_DATA_WIDTH-1 -: 8*BYTE_LENGTH]};
          _outValid <= 1'b1;
          _eightBytesTxdNM <= 1'b1;
          _fiveBytesTxdNM <= 0;
        end
      end
    end
  end


endmodule