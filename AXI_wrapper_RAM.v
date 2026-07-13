`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2026 14:39:18
// Design Name: 
// Module Name: AXI_wrapper_RAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXI_wrapper_RAM#(parameter data_width=32,
                        parameter addr_width=4,
                        parameter depth=16)(
                input aclk,
                input arst_bar,
                 
               // write address channel
               input [addr_width-1:0]s_axi_awaddr, // Given by the Testbench
               input s_axi_awvalid,
               output reg s_axi_awready,
               
               // write data channel
               input [data_width-1:0]s_axi_wdata,
               input s_axi_wvalid,
               output reg s_axi_wready,
               
               // write response channel
               output reg [1:0]s_axi_bresp,
               output reg s_axi_bvalid,
               input s_axi_bready,
               
               
               // Read address channel
               input [addr_width-1:0]s_axi_araddr,
               input s_axi_arvalid,
               output reg s_axi_arready,
               
               
               // Read data channel
               output reg [data_width-1:0]s_axi_rdata,
               output reg s_axi_rvalid,
               output reg [1:0]s_axi_rresp,
               input  s_axi_rready
               
               
                            
    );
    
    localparam resp_okay=2'b00;
    localparam resp_slv_err=2'b01;
    
    
    localparam idle  = 2'b00;
    localparam write = 2'b01;
    localparam read  = 2'b10;
    localparam resp  = 2'b11;
   
 
    
    
    
    // RAM interfacing signals 
    
    reg  [data_width-1:0]ram_write_data;
    wire [data_width-1:0]ram_read_data;
    reg  [addr_width-1:0]wr_ram_addr; // Write address
    reg  [addr_width-1:0]rd_ram_addr; // Read address
    reg  ram_wr_en;
    reg  ram_rd_en;
    
    
    // Internal Registers for write channels
    reg aw_captured;   // Flag to indicate write address is captured
    reg  w_captured;   // Flag to indicate write data is captured
    
    // Internal Registers for read channels
    reg ar_captured;   // Flag to indicate read address is captured
   
    
    
    // Write channel data controll wires
    wire write_complete;
    wire write_response_done;
    
    // RAM module instantiation
    RAM_v1#(.data_width(data_width),
            .addr_width(addr_width),
            .depth(depth))
            
            RAM1( .clk(aclk),
                  .rst_bar(arst_bar),
                  .wr_addr(wr_ram_addr),
                  .rd_addr(rd_ram_addr),
                  
                  .wr_en(ram_wr_en),
                  .rd_en(ram_rd_en),
                  .data_in(ram_write_data),
                  .data_output(ram_read_data));
    
    // Write Address Channel State machine
    
    always@(posedge aclk)
        begin
            if(arst_bar==0)
                begin
                    s_axi_awready<=1'b1; // Ready for next address after reset
                    wr_ram_addr<={addr_width{1'b0}}; // No address to write
                    aw_captured<=1'b0;
                    
                end
                
            else 
                begin
                    
                    if((s_axi_awvalid==1)&&(s_axi_awready==1))
                        begin
                            wr_ram_addr<=s_axi_awaddr; // Capture address when ready
                            s_axi_awready<=1'b0;          // Need to wait until the current address is used
                            aw_captured<=1'b1;            // write address captured
                        end
                   else if(write_response_done==1'b1)
                        begin
                           aw_captured<=1'b0;              // For next write address 
                           s_axi_awready<=1'b1;  
                        end
                     
                end  
               
           end
         // Write Data Channel
         
         
         always@(posedge aclk)
            begin
                if(arst_bar==0)
                    begin
                        s_axi_wready<=1'b1; // Ready for next data after reset
                      //  ram_wr_en<=1'b0;  // Not going to write
                        ram_write_data<={data_width{1'b0}}; // No data to write
                        w_captured<=1'b0;
                    end
                 else 
                    begin
                        
                        if((s_axi_wready==1)&&(s_axi_wvalid==1))
                            begin
                                ram_write_data<=s_axi_wdata; // Capture data when ready
                                s_axi_wready<=1'b0;          // Wait till the current data is used
                                w_captured<=1'b1;            // Write data captured
                            end
                       else if(write_response_done==1'b1)
                            begin
                                w_captured<=1'b0;  // wait for next data
                                s_axi_wready<=1'b1;
                            end
                                
                        
                            
                    end
                    
          end
              
          // Handle the write operation
          always@(posedge aclk)
            begin
                if(arst_bar==0)
                    begin
                        ram_wr_en<=1'b0;
                    end
                else 
                    begin
                        if(write_complete) // En_RAM write only for one cycle
                        //write_complete=(aw_captured==1'b1)&(w_captured==1'b1)&(s_axi_bvalid==1'b0); 
                            begin
                                ram_wr_en<=1'b1; // write to the RAM
                            end
                        else 
                            begin
                                ram_wr_en<=1'b0; // Do Not Write to the RAM
                            end
                    end
          
         end
           // Write Response channel   
       assign write_complete=(aw_captured==1'b1)&(w_captured==1'b1)&(s_axi_bvalid==1'b0); 
       // Both data and address cpatured, and write is done(in the next clock pulse) and the s_axi_bavlid 
       // is currently not in use. 
       assign write_response_done=(s_axi_bvalid==1'b1)&(s_axi_bready==1'b1);
       // When write response is done, use this signal to clear the flags for aw_captured and w_captured
           
           always@(posedge aclk)
            begin
                if(arst_bar==0)
                    begin
                        s_axi_bresp<=resp_okay;
                        s_axi_bvalid<=1'b0;  
                      
                    end
                 else 
                    begin
                       
                       if(write_complete==1'b1)
                            begin
                                s_axi_bresp<=resp_okay;  // Response okay
                                s_axi_bvalid<=1'b1;      // Valid write response signal available
                            end
                       else if((s_axi_bready==1'b1) && (s_axi_bvalid==1'b1))
                       // When master ready and slave valid then change the bvalid signal since 
                       // master has already read it when the condidtion is already seen by the master
                            begin
                                s_axi_bvalid<=1'b0;      // Valid write response not available
                            end
                            
                            
                       
                          
                         
                        
                            
                    end
                    
          end
          
          
          
          // READ ADDRESS CHANNEL
          
          
          always@(posedge aclk)
            begin
                if(arst_bar==1'b0)
                    begin
                       rd_ram_addr<={addr_width{1'b0}};
                       s_axi_arready<=1'b1;     
                       ram_rd_en<=1'b0;     
                    end
                else
                    begin
                        if((s_axi_arvalid==1'b1) && (s_axi_arready==1'b1))
                            begin
                                rd_ram_addr<=s_axi_araddr;
                                ar_captured<=1'b1;  // read address captured
                                ram_rd_en<=1'b1;
                                s_axi_arready<=1'b0;// Not ready for any more address
                               
                             end
                        else
                            begin
                                ram_rd_en<=1'b0; // only for one clock pulse keep the read enable signal high
                                // After data read successfully make the s_axi_rready signal high for next address
                                if((s_axi_rready==1'b1) && (s_axi_rvalid==1'b1))
                                    begin
                                        s_axi_arready<=1'b1; // Ready for next address                               
                                    end
                            end
                            
                    end
                 
                 
            end
                        
         // READ DATA CHANNEL
         
         // This value will be read by the master when read_valid signal is asserted by the slave
         always@(*)
            begin
                s_axi_rdata=ram_read_data;
            end
            
            
            always@(posedge aclk)
                begin   
                    if(arst_bar==0)
                        begin
                           s_axi_rvalid<=1'b0;
                           s_axi_rresp<=resp_okay;
                        end
                        
                    else 
                        begin
                        // Due to NBA if triggered in this clock cycle we can get the data in next clock cycle;
                           if(ram_rd_en==1)
                                begin
                                    s_axi_rvalid<=1'b1; 
                                    s_axi_rresp<=resp_okay;
                                end
                           else if((s_axi_rvalid==1'b1)&&(s_axi_rready==1'b1))
                                begin
                                    s_axi_rvalid<=1'b0;  // Since the master has already read it
                                end
                        end
                            
                    
                end
                
endmodule
