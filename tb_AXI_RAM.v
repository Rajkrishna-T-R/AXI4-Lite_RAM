`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2026 15:48:08
// Design Name: 
// Module Name: tb_AXI_RAM
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


module tb_AXI_RAM;

    //--------------------------------------------------------------
    // Parameters (mirror DUT parameters so both can be scaled together)
    //--------------------------------------------------------------
    parameter DATA_WIDTH      = 32;
    parameter ADDR_WIDTH      = 4;
    parameter DEPTH           = 16;
    parameter CLK_PERIOD      = 10;      // ns
    parameter NUM_RANDOM_TXNS = 200;      // scale this up/down as desired
    parameter VERBOSE         = 1;        // 1 = print every transaction

    //--------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------
    reg                     aclk;
    reg                     arst_bar;

    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr;
    reg                     s_axi_awvalid;
    wire                    s_axi_awready;

    reg  [DATA_WIDTH-1:0]   s_axi_wdata;
    reg                     s_axi_wvalid;
    wire                    s_axi_wready;

    wire [1:0]              s_axi_bresp;
    wire                    s_axi_bvalid;
    reg                     s_axi_bready;

    reg  [ADDR_WIDTH-1:0]   s_axi_araddr;
    reg                     s_axi_arvalid;
    wire                    s_axi_arready;

    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire                    s_axi_rvalid;
    wire                    s_axi_rresp;
    reg                     s_axi_rready;

    //--------------------------------------------------------------
    // Scoreboard / bookkeeping
    //--------------------------------------------------------------
    reg  [DATA_WIDTH-1:0]   shadow_mem [0:DEPTH-1];   // reference model
    reg  [DATA_WIDTH-1:0]   shadow_valid_bits         ;// bit per addr: has it been written?
    integer                 test_count;
    integer                 pass_count;
    integer                 fail_count;
    integer                 i;

    //--------------------------------------------------------------
    // DUT instantiation
    //--------------------------------------------------------------
    AXI_wrapper_RAM #(
        .data_width (DATA_WIDTH),
        .addr_width (ADDR_WIDTH),
        .depth      (DEPTH)
    ) DUT (
        .aclk           (aclk),
        .arst_bar       (arst_bar),

        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),

        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),

        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),

        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),

        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rresp          (s_axi_rresp),
        .s_axi_rready   (s_axi_rready)
    );

    //--------------------------------------------------------------
    // Clock generation
    //--------------------------------------------------------------
    initial aclk = 1'b0;
    always #(CLK_PERIOD/2) aclk = ~aclk;

    //--------------------------------------------------------------
    // Watchdog: kill the sim if a handshake ever hangs, instead of
    // letting the simulator run forever while you're scaling tests up.
    //--------------------------------------------------------------
    integer watchdog_limit = 2000; // clk cycles per task call
    reg     watchdog_fired;

    //--------------------------------------------------------------
    // Reset task
    //--------------------------------------------------------------
    task automatic apply_reset;
        begin
            arst_bar      = 1'b0;
            s_axi_awaddr  = 0;
            s_axi_awvalid = 1'b0;
            s_axi_wdata   = 0;
            s_axi_wvalid  = 1'b0;
            s_axi_bready  = 1'b0;
            s_axi_araddr  = 0;
            s_axi_arvalid = 1'b0;
            s_axi_rready  = 1'b0;
            repeat (5) @(posedge aclk);
            @(negedge aclk);
            arst_bar = 1'b1;
            @(negedge aclk);

            // shadow model mirrors RAM_v1's reset-time contents (all zero)
            for (i = 0; i < DEPTH; i = i + 1)
                shadow_mem[i] = {DATA_WIDTH{1'b0}};
        end
    endtask

    //--------------------------------------------------------------
    // AXI write task
    //--------------------------------------------------------------
    task automatic axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        integer cycles;
        begin
            cycles = 0;
            @(negedge aclk);
            // wait until slave can accept both address and data
            while (!(s_axi_awready && s_axi_wready)) begin
                @(negedge aclk);
                cycles = cycles + 1;
                if (cycles > watchdog_limit) begin
                    $display("[%0t] ERROR: TIMEOUT waiting for awready/wready (addr=%0h)", $time, addr);
                    fail_count = fail_count + 1;
                    disable axi_write;
                end
            end

            s_axi_awaddr  = addr;
            s_axi_awvalid = 1'b1;
            s_axi_wdata   = data;
            s_axi_wvalid  = 1'b1;

            @(posedge aclk); // address+data captured here
            @(negedge aclk);
            s_axi_awvalid = 1'b0;
            s_axi_wvalid  = 1'b0;

            cycles = 0;
            while (!s_axi_bvalid) begin
                @(negedge aclk);
                cycles = cycles + 1;
                if (cycles > watchdog_limit) begin
                    $display("[%0t] ERROR: TIMEOUT waiting for bvalid (addr=%0h)", $time, addr);
                    fail_count = fail_count + 1;
                    disable axi_write;
                end
            end

            if (s_axi_bresp !== 2'b00)
                $display("[%0t] WARNING: write to addr %0h got non-OKAY bresp=%0b", $time, addr, s_axi_bresp);

            s_axi_bready = 1'b1;
            @(negedge aclk);
            s_axi_bready = 1'b0;

            // update reference model
            shadow_mem[addr] = data;

            if (VERBOSE)
                $display("[%0t] WRITE  addr=%0h data=%0h", $time, addr, data);
        end
    endtask

    //--------------------------------------------------------------
    // AXI read task
    //--------------------------------------------------------------
    task automatic axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        integer cycles;
        begin
            cycles = 0;
            @(negedge aclk);
            while (!s_axi_arready) begin
                @(negedge aclk);
                cycles = cycles + 1;
                if (cycles > watchdog_limit) begin
                    $display("[%0t] ERROR: TIMEOUT waiting for arready (addr=%0h)", $time, addr);
                    fail_count = fail_count + 1;
                    disable axi_read;
                end
            end

            s_axi_araddr  = addr;
            s_axi_arvalid = 1'b1;

            @(posedge aclk); // address captured here
            @(negedge aclk);
            s_axi_arvalid = 1'b0;

            cycles = 0;
            while (!s_axi_rvalid) begin
                @(negedge aclk);
                cycles = cycles + 1;
                if (cycles > watchdog_limit) begin
                    $display("[%0t] ERROR: TIMEOUT waiting for rvalid (addr=%0h)", $time, addr);
                    fail_count = fail_count + 1;
                    disable axi_read;
                end
            end

            data = s_axi_rdata;

            s_axi_rready = 1'b1;
            @(negedge aclk);
            s_axi_rready = 1'b0;

            if (VERBOSE)
                $display("[%0t] READ   addr=%0h data=%0h", $time, addr, data);
        end
    endtask

    //--------------------------------------------------------------
    // Checker: read back an address and compare to shadow model
    //--------------------------------------------------------------
    task automatic check_read(input [ADDR_WIDTH-1:0] addr);
        reg [DATA_WIDTH-1:0] got;
        reg [DATA_WIDTH-1:0] expected;
        begin
            axi_read(addr, got);
            expected  = shadow_mem[addr];
            test_count = test_count + 1;

            if (got === expected) begin
                pass_count = pass_count + 1;
                if (VERBOSE)
                    $display("        -> PASS (expected=%0h)", expected);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL   addr=%0h expected=%0h got=%0h", $time, addr, expected, got);
            end
        end
    endtask

    //--------------------------------------------------------------
    // Directed test scenarios
    //--------------------------------------------------------------
    task automatic test_reset_contents;
        begin
            $display("\n--- TEST: post-reset contents should be all-zero ---");
            check_read(0);
            check_read(DEPTH-1);
        end
    endtask

    task automatic test_basic_write_read;
        begin
            $display("\n--- TEST: basic write then read-back ---");
            axi_write(4'h0, 32'hDEAD_BEEF);
            check_read(4'h0);

            axi_write(4'h5, 32'h1234_5678);
            check_read(4'h5);

            axi_write(DEPTH-1, 32'hFFFF_FFFF);
            check_read(DEPTH-1);
        end
    endtask

    task automatic test_overwrite;
        begin
            $display("\n--- TEST: overwrite an existing address ---");
            axi_write(4'h3, 32'hAAAA_AAAA);
            check_read(4'h3);
            axi_write(4'h3, 32'h5555_5555);
            check_read(4'h3);
        end
    endtask

    task automatic test_fill_all_addresses;
        begin
            $display("\n--- TEST: sequential fill of every address, then read all back ---");
            for (i = 0; i < DEPTH; i = i + 1)
                axi_write(i[ADDR_WIDTH-1:0], i * 32'h0001_0001 + 32'hA5A5_0000);
            for (i = 0; i < DEPTH; i = i + 1)
                check_read(i[ADDR_WIDTH-1:0]);
        end
    endtask

    task automatic test_back_to_back_write_read;
        begin
            $display("\n--- TEST: write immediately followed by read of same address ---");
            axi_write(4'h7, 32'hCAFE_F00D);
            check_read(4'h7);
            axi_write(4'h7, 32'h0BAD_CAFE);
            check_read(4'h7);
        end
    endtask

    task automatic test_random_traffic;
        reg [ADDR_WIDTH-1:0] rand_addr;
        reg [DATA_WIDTH-1:0] rand_data;
        integer               n;
        begin
            $display("\n--- TEST: %0d randomized write/read transactions ---", NUM_RANDOM_TXNS);
            for (n = 0; n < NUM_RANDOM_TXNS; n = n + 1) begin
                rand_addr = $random % DEPTH;
                rand_data = $random;

                if ($random % 2) begin
                    axi_write(rand_addr, rand_data);
                end else begin
                    check_read(rand_addr);
                end
            end
        end
    endtask

    //--------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------
    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        apply_reset;

        test_reset_contents;
        test_basic_write_read;
        test_overwrite;
        test_fill_all_addresses;
        test_back_to_back_write_read;
        test_random_traffic;

        $display("\n==================== SCOREBOARD ====================");
        $display(" Total checks : %0d", test_count);
        $display(" Passed       : %0d", pass_count);
        $display(" Failed       : %0d", fail_count);
        if (fail_count == 0)
            $display(" RESULT       : ALL TESTS PASSED");
        else
            $display(" RESULT       : FAILURES DETECTED");
        $display("=====================================================\n");

        $finish;
    end

   

endmodule
