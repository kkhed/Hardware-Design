/*
 * Self Learning Project
 * 
 * File: sync_r2w.sv
 *  
 * Author:
 * 
 * - Kishore Khed <kishore.khed@gmail.com> 
 * 
 * 1. Borrowed logic from http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
 * 2. Adapted to SystemVerilog.
 */


module sync_r2w #(parameter ADDRSIZE = 4)

                 (output logic [ADDRSIZE:0] wq2_rptr,
                  input        [ADDRSIZE:0] rptr,
                  input                     wclk, wrst_n);
    
	// # reg [ADDRSIZE:0] wq1_rptr;
    logic [ADDRSIZE:0] wq1_rptr;
	
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
        else         {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
		 
endmodule