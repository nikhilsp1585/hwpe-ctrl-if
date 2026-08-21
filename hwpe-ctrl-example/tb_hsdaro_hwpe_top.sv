`timescale 1ns/1ps

import hsdaro_pkg::*;

module tb_hsdaro_hwpe_top;


//============================================================
// Clock / Reset
//============================================================

logic i_clk;
logic i_resetn;

integer errors;


//============================================================
// HWPE Control Interface
//============================================================

hwpe_ctrl_if_pheriph #(
    .ID_WIDTH(4)
) hsdaro_hwpe_ctrl_if (
    .clk(i_clk)
);


//============================================================
// DUT
//============================================================

hsdaro_hwpe_top dut (

    .i_clk               (i_clk),
    .i_resetn            (i_resetn),

    .hsdaro_hwpe_ctrl_if (hsdaro_hwpe_ctrl_if)

);


//============================================================
// Clock
//============================================================

always #5 i_clk = ~i_clk;


//============================================================
// Main Test
//============================================================

initial begin

    i_clk    = 1'b0;
    i_resetn = 1'b0;

    errors = 0;


    //--------------------------------------------------------
    // Interface defaults
    //--------------------------------------------------------

    hsdaro_hwpe_ctrl_if.req  = 1'b0;
    hsdaro_hwpe_ctrl_if.add  = '0;
    hsdaro_hwpe_ctrl_if.wen  = 1'b1;
    hsdaro_hwpe_ctrl_if.be   = 4'b1111;
    hsdaro_hwpe_ctrl_if.data = '0;
    hsdaro_hwpe_ctrl_if.id   = '0;


    //--------------------------------------------------------
    // Reset
    //--------------------------------------------------------

    repeat(3)
        @(posedge i_clk);

    @(negedge i_clk);

    i_resetn = 1'b1;

    repeat(2)
        @(posedge i_clk);


    $display("");
    $display("==========================================");
    $display("       HSDARO HWPE REGISTER TEST");
    $display("==========================================");
    $display("");


    //========================================================
    // CTRL
    //========================================================

    write_reg(
        HSDARO_HWPE_CTRL_REG,
        32'h1234_5678
    );

    read_check(
        HSDARO_HWPE_CTRL_REG,
        32'h1234_5678
    );


    //========================================================
    // STATUS
    //========================================================

    write_reg(
        HSDARO_HWPE_STATUS_REG,
        32'hA5A5_5A5A
    );

    read_check(
        HSDARO_HWPE_STATUS_REG,
        32'hA5A5_5A5A
    );


    //========================================================
    // WEIGHTS START ADDRESS
    //========================================================

    write_reg(
        HSDARO_HWPE_WEIGHTS_START_ADDR_REG,
        32'h1000_0000
    );

    read_check(
        HSDARO_HWPE_WEIGHTS_START_ADDR_REG,
        32'h1000_0000
    );


    //========================================================
    // IMAGE START ADDRESS
    //========================================================

    write_reg(
        HSDARO_HWPE_IMAGE_START_ADDR_REG,
        32'h2000_0000
    );

    read_check(
        HSDARO_HWPE_IMAGE_START_ADDR_REG,
        32'h2000_0000
    );


    //========================================================
    // Overwrite CTRL
    //========================================================

    write_reg(
        HSDARO_HWPE_CTRL_REG,
        32'hDEAD_BEEF
    );

    read_check(
        HSDARO_HWPE_CTRL_REG,
        32'hDEAD_BEEF
    );


    //========================================================
    // Check other registers were not modified
    //========================================================

    read_check(
        HSDARO_HWPE_STATUS_REG,
        32'hA5A5_5A5A
    );

    read_check(
        HSDARO_HWPE_WEIGHTS_START_ADDR_REG,
        32'h1000_0000
    );

    read_check(
        HSDARO_HWPE_IMAGE_START_ADDR_REG,
        32'h2000_0000
    );


    //========================================================
    // Overwrite weights address
    //========================================================

    write_reg(
        HSDARO_HWPE_WEIGHTS_START_ADDR_REG,
        32'hCAFE_BABE
    );

    read_check(
        HSDARO_HWPE_WEIGHTS_START_ADDR_REG,
        32'hCAFE_BABE
    );


    //========================================================
    // Invalid address
    //========================================================

    read_check(
        32'hFFFF_FFFC,
        32'h0000_0000
    );


    //========================================================
    // Finish
    //========================================================

    repeat(3)
        @(posedge i_clk);


    $display("");

    if(errors == 0) begin

        $display("==========================================");
        $display("              TEST PASSED");
        $display("==========================================");

    end

    else begin

        $display("==========================================");
        $display("        TEST FAILED : %0d ERRORS", errors);
        $display("==========================================");

    end

    $display("");

    $finish;

end



//============================================================
// WRITE TASK
//============================================================

task automatic write_reg(

    input logic [31:0] addr,
    input logic [31:0] wr_data

);

begin

    //--------------------------------------------------------
    // Drive before active edge
    //--------------------------------------------------------

    @(negedge i_clk);

    hsdaro_hwpe_ctrl_if.req  = 1'b1;
    hsdaro_hwpe_ctrl_if.add  = addr;

    // HWPE-Periph:
    // wen = 0 -> WRITE
    hsdaro_hwpe_ctrl_if.wen  = 1'b0;

    hsdaro_hwpe_ctrl_if.be   = 4'b1111;
    hsdaro_hwpe_ctrl_if.data = wr_data;


    //--------------------------------------------------------
    // DUT writes here
    //--------------------------------------------------------

    @(posedge i_clk);

    #1;


    //--------------------------------------------------------
    // Grant check
    //--------------------------------------------------------

    if(hsdaro_hwpe_ctrl_if.gnt !== 1'b1) begin

        $error(
            "WRITE GNT ERROR addr=%h",
            addr
        );

        errors++;

    end


    //--------------------------------------------------------
    // End request
    //--------------------------------------------------------

    @(negedge i_clk);

    hsdaro_hwpe_ctrl_if.req  = 1'b0;
    hsdaro_hwpe_ctrl_if.add  = '0;
    hsdaro_hwpe_ctrl_if.data = '0;


    $display(
        "WRITE      addr=%h data=%h",
        addr,
        wr_data
    );

end

endtask



//============================================================
// READ + CHECK TASK
//============================================================

task automatic read_check(

    input logic [31:0] addr,
    input logic [31:0] expected

);

logic [31:0] actual;

begin

    //--------------------------------------------------------
    // Drive before active edge
    //--------------------------------------------------------

    @(negedge i_clk);

    hsdaro_hwpe_ctrl_if.req  = 1'b1;
    hsdaro_hwpe_ctrl_if.add  = addr;

    // HWPE-Periph:
    // wen = 1 -> READ
    hsdaro_hwpe_ctrl_if.wen  = 1'b1;

    hsdaro_hwpe_ctrl_if.be   = 4'b1111;
    hsdaro_hwpe_ctrl_if.data = '0;


    //--------------------------------------------------------
    // Allow combinational read/access to settle
    //--------------------------------------------------------

    @(posedge i_clk);

    #1;


    //--------------------------------------------------------
    // Grant check
    //--------------------------------------------------------

    if(hsdaro_hwpe_ctrl_if.gnt !== 1'b1) begin

        $error(
            "READ GNT ERROR addr=%h",
            addr
        );

        errors++;

    end


    //--------------------------------------------------------
    // Capture data while request/address are still active
    //--------------------------------------------------------

    actual = hsdaro_hwpe_ctrl_if.r_data;


    //--------------------------------------------------------
    // Self check
    //--------------------------------------------------------

    if(actual !== expected) begin

        $error(
            "READ ERROR addr=%h expected=%h got=%h",
            addr,
            expected,
            actual
        );

        errors++;

    end

    else begin

        $display(
            "READ PASS  addr=%h data=%h",
            addr,
            actual
        );

    end


    //--------------------------------------------------------
    // End request
    //--------------------------------------------------------

    @(negedge i_clk);

    hsdaro_hwpe_ctrl_if.req = 1'b0;
    hsdaro_hwpe_ctrl_if.add = '0;

end

endtask



//============================================================
// Timeout
//============================================================

initial begin

    #10000;

    $error("TESTBENCH TIMEOUT");

    $finish;

end


endmodule