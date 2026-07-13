`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2026 14:27:05
// Design Name: 
// Module Name: RAM_v1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// If read and write operation done on same address then read will get the new data
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RAM_v1#(parameter data_width=32,
               parameter addr_width=4,
               parameter depth=16)(
               input clk,
               input rst_bar,
               input [addr_width-1:0]wr_addr,
               input [addr_width-1:0]rd_addr,
               
               
               input rd_en,
               input wr_en,
               input [data_width-1:0]data_in,
               output [data_width-1:0]data_output

    );
    
    
   
    reg[data_width-1:0] rd_data_out;
    
    integer i=0;
    
    reg [data_width-1:0]RAM_mem[0:depth-1];
    
 
    assign rd_data_output = rd_data_out;
    
    // FOR BRAM
    initial
        begin
            for(i=0;i<depth;i=i+1)
                begin 
                    RAM_mem[i]<={data_width{1'b0}};
                end
        end
    
    
    
    always@(posedge clk)
        begin
            if(rst_bar==0)
                begin  
                    rd_data_out<=0;
                end
            else 
                begin
                
                // Write port
                    if(wr_en)
                        begin
                            RAM_mem[wr_addr]<=data_in;
                        end
                        
                // Read port
                    if(rd_en)
                        begin
                             if(wr_en==1 && (rd_addr==wr_addr))  // Data forwarding
                                begin
                                   rd_data_out<=data_in;
                                end
                             else 
                                begin
                                    rd_data_out<=RAM_mem[rd_addr];
                                end
                         end
                 end
                 
          end
                    
    
    
endmodule
