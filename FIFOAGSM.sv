module FIFOAGSM #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8)(
      input    clk,
      input    resetn,
      input logic [DATA_WIDTH - 1: 0]  dataIn,
      input logic dataInValid,
      output logic dataInReady,

      output logic [DATA_WIDTH - 1:0] dataOut,
      output logic dataOutValid,
      input logic dataOutReady
  );

  // AXI4Stream.Master masterPort,
  // AXI4Stream.Slave  slavePort

  // localparam DATA_WIDTH = masterPort.DATA_WIDTH;
  ///// ------- Module Starts ------- /////
  // Internsal signals
  logic  _fifoFull, _fifoEmpty;
  
  // States 
  typedef enum {
    RESET   = 'b0,
    WAIT    = 'b1
  } stateTypes;
  
  stateTypes _state, _stateNext;  
  
  // FIFO 
  logic [DATA_WIDTH - 1:0] _FIFO [FIFO_DEPTH - 1:0]; 
  
  // Counters
  logic [$clog2(FIFO_DEPTH) :0] _counter = 0;
  
  // Assignments
  
  assign _fifoEmpty = (_counter == 0);
  assign _fifoFull = (_counter == FIFO_DEPTH);
  
  assign dataInReady = ~_fifoFull;
  // assign dataOut = _FIFO[0];
  
  // State Transistion
  always_ff @ (posedge clk)
  begin
    if(!resetn)
    begin
      _state <= RESET;
    end
    else
      _state <= _stateNext;
  end   
  
  // Next State Logic
  always_comb 
  begin
     case (_state)
        RESET: 
        begin
          dataOutValid <= 'b0;
          if(_counter == 0)
            _stateNext <= RESET;
          else if(_counter > 0)
            _stateNext <= WAIT;
        end
        WAIT:
        begin
          dataOutValid <= 'b1;
          if(dataOutReady)
          begin
            if(_counter == 0)
              _stateNext <= RESET;
            else if( _counter - 1 > 0 ) 
              _stateNext <= WAIT;
            else 
              _stateNext <= RESET;
          end
          else
            _stateNext <= WAIT;
        end
        default: 
        begin
          dataOutValid <= 'b0;
          _stateNext <= RESET;
        end
     endcase   
  end
  
  
  always_ff @(posedge clk)
  begin
    if(resetn)
    begin
      // Downstream is asking for a new data
      if(_state == WAIT && dataOutReady == 1) //_shiftOut
      begin
        // Upstream is asking to add data to the queue
        if(dataInValid)  //_shiftIn -- slavePort.data
        begin
          // We have a queue to shift
          if(_counter > 0)
          begin
            // Shift the FIFO
            for(int i = 0; i < _counter - 1; i++) 
            begin: FIFOShift
              _FIFO[i] <= _FIFO[i + 1];
            end
            // Add the data at counter
            _FIFO[_counter - 1] <= dataIn;
          end
          // We have no queue
          else //(_counter == 0)
            // Place the dataIn (slavePort.data) directly on to dataOut - masterPort.data - FIFO[_counter] // _counter = 0
            _FIFO[0] <= dataIn;
        end
        else // No upstream request to push in data; downstream is requesting data 
        begin
          if(_counter > 0) // We have data
          begin
            // Shift last data out on to masterPort.data
            dataOut <= _FIFO[0];
            // Shift the FIFO
            for(int i = 0; i < _counter - 1; i++)
            begin: FIFOShift1
              _FIFO[i] <= _FIFO[i + 1];
            end  
            // Decrement the counter 
            _counter <= _counter - 1;
          end
        end  
      end
      else // Downstream not requesting data
      begin
        // There is request from upstream to push in data
        if(dataInValid == 1 && _counter < FIFO_DEPTH)
        begin
          // Add data to the FIFO
          _FIFO[_counter] <= dataIn;
          //Increment the counter
          _counter <= _counter + 1;
        end
      end
    end
    //  $display (_FIFO);
    //  $display ("counter:", _counter);
  end  
  
endmodule