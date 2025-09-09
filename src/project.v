/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // =====================================================
    // Adaptable Sequence Detector Instance
    // =====================================================

    // Parameters
    localparam MAX_N = 32;

    // Signal connections
    wire data_in     = ui_in[0];        // use ui_in[0] as serial input
    wire [4:0] seq_len = ui_in[5:1];    // use ui_in[5:1] for sequence length (up to 31)
    wire [MAX_N-1:0] pattern = {uio_in, ui_in}; 
    // (example: pattern loaded from 8-bit uio_in + 8-bit ui_in for demo purposes)

    wire match;

    // shift register (LSB = most recent bit)
    reg [MAX_N-1:0] shift_reg;

    // create mask based on seq_len (lower seq_len bits = 1)
    wire [MAX_N-1:0] mask;
    assign mask = (seq_len == 0) ? {MAX_N{1'b0}} : (({MAX_N{1'b1}}) >> (MAX_N - seq_len));

    // combinational compare (masked)
    wire match_comb;
    assign match_comb = ((shift_reg & mask) == (pattern & mask)) && (seq_len != 0);

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= {MAX_N{1'b0}};
        end else begin
            // shift left, insert new bit at LSB
            shift_reg <= {shift_reg[MAX_N-2:0], data_in};
        end
    end

    // Register match pulse
    reg match_reg;
    always @(posedge clk) begin
        if (!rst_n) 
            match_reg <= 1'b0;
        else
            match_reg <= match_comb;
    end

    assign match = match_reg;

    // =====================================================
    // Outputs
    // =====================================================
    assign uo_out  = {7'b0, match};  // match on bit0 of output
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // =====================================================
    // Unused signals to avoid warnings
    // =====================================================
    wire _unused = &{ena, 1'b0};

endmodule
