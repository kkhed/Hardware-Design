/*
 * Self Improvement Project - FIFO Design
 * 
 * Author(s): 
 * 
 * - Kishore Khed <kishorekhed@gmail.com> --- Logic
 * 
 */


interface AvalonStream #(
  parameter DATA_WIDTH      = 32
);

  logic                       valid;      
  logic [DATA_WIDTH - 1:0]    data;       // data (issued by Source; accepted by Sink) // Data in
  
  logic                       ready;      // Ready to accept data in

  
  modport Master(    // only relevant avalon-st Source signals
      output  valid,
      output  data,
      input   ready,
        );
  
  modport Slave(    // only relevant avalon-st Sink signals
      input  valid,
      input  data,
      output ready,
        );

endinterface
