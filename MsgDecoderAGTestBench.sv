`timescale 1ns / 1ps


module top();

    // Parameter, Localparam, and variable definitions
    parameter IN_DATA_WIDTH   = 64;
    parameter OUT_DATA_WIDTH = 256;
    parameter BYTE_MASK_WIDTH = 32;
    
    localparam SIMULATION_RUN_TIME = 1000;              // Simulation time
    localparam SAMPLE_COUNT = 6;                          // Number of Data Samples
    
    logic                                   clk=1;
    logic                                   resetn=0;
    logic                                   inValid=0;
    logic                                   inStartOfPayload=0;
    logic                                   inEndOfPayload=0;
    logic                                   inReady;
    logic [IN_DATA_WIDTH -1 : 0]            inData;
    logic [2: 0]                            inEmpty;
    logic                                   inError=0;
    logic [OUT_DATA_WIDTH - 1:0]            outData;
    logic                                   outValid;
    logic [BYTE_MASK_WIDTH - 1 : 0]         outByteMask;
    
    integer filehandle, filehandleOut, filehandleEstimate;
    integer i=0, j=0, k=0;
      
    logic [IN_DATA_WIDTH -1 : 0] dataIn [SAMPLE_COUNT - 1:0];  // Data is fetched and stored in 2D array from the "input.txt" file
    // logic [IN_DATA_WIDTH -1: 0 ] _dataInTmp = 64'h0008000962626262;
    
    assign dataIn[0] = 64'h0008000962626262;
    assign dataIn[1] = 64'h6262626262000b43;
    assign dataIn[2] = 64'h4343434343434343;
    assign dataIn[3] = 64'h4343000e72727272;
    assign dataIn[4] = 64'h7272727272727272;
    assign dataIn[5] = 64'h7272000856565656;

    //Clock generation
    always #(2ns) clk = ~clk;
    
    // Instance of the dut
    MsgDecoderAG #(
      .IN_DATA_WIDTH(IN_DATA_WIDTH),
      .OUT_DATA_WIDTH(OUT_DATA_WIDTH),
      .BYTE_MASK_WIDTH(BYTE_MASK_WIDTH)
    ) msgDecoderAG(
     .clk                  (clk),
     .resetn               (resetn),
     .inValid              (inValid),
     .inStartOfPayload     (inStartOfPayload),
     .inEndOfPayload       (inEndOfPayload),
     .inReady              (inReady),
     .inData               (inData),
     .inEmpty              (inEmpty),
     .inError              (inError),
     .outData              (outData),
     .outValid             (outValid),
     .outByteMask          (outByteMask)
    );

    // Initialization of signals
    initial
    begin   
        // // Adding input from a file (location is in the parent directory of the project)
        // j=$fopen("../../../../input.txt","r");               // reading input
        // while (! $feof(j))                                   // Read until an "end of file" is reached
        // begin
        //     $fscanf(j,"%h\n", dataIn[k]);                    // Scan each line and get the value as an hexadecimal
        //     k++;
        // end
        // $fclose(j);                                          // Once reading and writing is finished, close the file


        // filehandle = $fopen("../../../../input.hex", "r");

        // while (filehandle && !$feof(filehandle)) //read until an "end of file" is reached.
        // begin
        // // Read one line
        // $fscanf(filehandle,"%h\n", dataIn[k]); //scan each line and get the value as an hexadecimal
        // k = k + 1;
        // end
        // $display("Reading input %d lines", k);

        inData    =  0;
        #200ns;
        resetn            = 1;                              // Asynchronous reset
        // @(posedge clk);
        // @(posedge clk);
        // @(posedge clk);
        if (inReady)
        begin
          inStartOfPayload  = 1;
          @(posedge clk);
          inStartOfPayload  = 0;
        end
    end

    // // Write output to the file (location is in the parent directory of the project)
    // integer f =0;
    // initial 
    // begin
    //     f = $fopen("../../../../../output.txt","w");
    //     #SIMULATION_RUN_TIME;                                 // Simulation run time
    //     $fclose(f);
    //     $finish;                                              // End of simulation
    // end

    // // Purpose: Writing data to the file
    // always @(posedge clk)
    // begin
    //     if(outValid)
    //         $fwrite(f,"%0h\n",outData);
    // end 
    
    // Purpose: Generating and sending data to dut
    always @(posedge clk)
    begin
      if (resetn)
      begin
          if (inReady)
          begin
              $display("Data Entering.....");
              inValid <=  1;
              inStartOfPayload <= 1;
            //   inData <= _dataInTmp;
              if (i == 0)
              begin
                inStartOfPayload <= 1;
                i <= i+1;
                inData <= dataIn[i];
              end 
              if(i>0 && i<SAMPLE_COUNT)
              begin
                  inData  <= dataIn[i];
                  i <= i + 1;
                  inStartOfPayload <= 0;
              end
              if (i == SAMPLE_COUNT -1)
              begin
                  inEndOfPayload    <= 1;
                  inEmpty           <= 4;
                  i <= i + 1;
                  inStartOfPayload <= 0;
              end
              if(i >= SAMPLE_COUNT)
              begin
                  inEndOfPayload <= 0;
                  inStartOfPayload <= 0;
                  inEmpty        <= 0;
                  inData  <=  0;
                  inValid <=  0; 
              end
          end
          else
          begin
            inValid <=  0;
            inData  <=  0;   
          end
      end
    end
    
endmodule 
