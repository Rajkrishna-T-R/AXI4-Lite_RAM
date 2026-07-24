`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 15:11:11
// Design Name: 
// Module Name: Vio_wrapper
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


module Vio_wrapper(
input aclk
    );
    

// Reset
wire        arst_bar;

// Write Address Channel
wire [3:0]  s_axi_awaddr;
wire        s_axi_awvalid;
wire        s_axi_awready;

// Write Data Channel
wire [31:0] s_axi_wdata;
wire        s_axi_wvalid;
wire        s_axi_wready;

// Write Response Channel
wire        s_axi_bready;
wire [1:0]  s_axi_bresp;
wire        s_axi_bvalid;

// Read Address Channel
wire [3:0]  s_axi_araddr;
wire        s_axi_arvalid;
wire        s_axi_arready;

// Read Data Channel
wire        s_axi_rready;
wire [31:0] s_axi_rdata;
wire        s_axi_rvalid;
wire [1:0]  s_axi_rresp;
    
AXI_wrapper_RAM#(.data_width(32),
                 .addr_width(4),
                 .depth(16))uut(
                        
                .aclk(aclk),
                .arst_bar(arst_bar),
                 
               // write address channel
               .s_axi_awaddr(s_axi_awaddr), // Given by the Testbench
               .s_axi_awvalid(s_axi_awvalid),
               
               .s_axi_awready(s_axi_awready),
               
               // write data channel
               .s_axi_wdata(s_axi_wdata),
               .s_axi_wvalid(s_axi_wvalid),
               
               .s_axi_wready(s_axi_wready),
               
               // write response channel
               .s_axi_bready(s_axi_bready),
               
               .s_axi_bresp(s_axi_bresp),
               .s_axi_bvalid(s_axi_bvalid),
               
               
               
               // Read address channel
               .s_axi_araddr(s_axi_araddr),
               .s_axi_arvalid(s_axi_arvalid),
               
               .s_axi_arready(s_axi_arready),
               
               
               // Read data channel
               .s_axi_rready(s_axi_rready),
                
               .s_axi_rdata(s_axi_rdata),
               .s_axi_rvalid(s_axi_rvalid),
               .s_axi_rresp(s_axi_rresp)
              
               
               
                            
    );
    
    
    
    vio_0 VIO(.clk(aclk),
              .probe_in0(s_axi_awready),
              .probe_in1(s_axi_wready),
              .probe_in2(s_axi_bvalid),
              .probe_in3(s_axi_bresp),
              .probe_in4(s_axi_arready),
              .probe_in5(s_axi_rvalid),
              .probe_in6(s_axi_rresp),
              .probe_in7(s_axi_rdata),
              .probe_out0(arst_bar),
              .probe_out1(s_axi_awaddr),
              .probe_out2(s_axi_awvalid),
              .probe_out3(s_axi_wdata),
              .probe_out4(s_axi_wvalid),
              .probe_out5(s_axi_bready),
              .probe_out6(s_axi_araddr),
              .probe_out7(s_axi_arvalid),
              .probe_out8(s_axi_rready)
              );
endmodule
