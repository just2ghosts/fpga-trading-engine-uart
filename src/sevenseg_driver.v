// MIT License
// Copyright (c) 2025 Just2Ghosts
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////
// module that drives the seven seg displays
module sevenseg_driver (
    input  wire        clk,          
    input  wire        rst,          // active-high reset
    input  wire [15:0] price,        
    input  wire [15:0] threshold,    
    input  wire        new_price,    // pulse high for 1 cycle when new price is received
    output wire [6:0]  seg0,
    output wire [6:0]  seg1,
    output wire [6:0]  seg2,
    output wire [6:0]  seg3,
    output wire [6:0]  seg4,
    output wire [6:0]  seg5
);


    localparam integer MAX_COUNT = 25000000;  // 0.5 s
    reg [24:0] timer = 0;
    reg        show_price = 0;

	 // timer
    always @(posedge clk) begin
        if (rst) begin
            timer <= 0;
            show_price <= 0;
        end else if (new_price) begin
            timer <= 0;
            show_price <= 1;
        end else if (show_price) begin
            if (timer >= MAX_COUNT) begin
                show_price <= 0;
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end
        end
    end

    wire [15:0] to_display = show_price ? price : threshold;

    // double dabble logic for 6-digit BCD
    reg [3:0] digits [5:0];  
    reg [39:0] combined;         // 16bit bin + 6*4 BCD = 40 bits
    integer i;

    always @(*) begin
        combined = {24'd0, to_display}; // zero extend and place binary input in LSB

        for (i = 0; i < 16; i = i + 1) begin
            // add 3 if any BCD digit geq 5
            if (combined[39:36] >= 5) combined[39:36] = combined[39:36] + 3; // digit 5
            if (combined[35:32] >= 5) combined[35:32] = combined[35:32] + 3; // digit 4
            if (combined[31:28] >= 5) combined[31:28] = combined[31:28] + 3; // digit 3
            if (combined[27:24] >= 5) combined[27:24] = combined[27:24] + 3; // digit 2
            if (combined[23:20] >= 5) combined[23:20] = combined[23:20] + 3; // digit 1
            if (combined[19:16] >= 5) combined[19:16] = combined[19:16] + 3; // digit 0

            combined = combined << 1;
        end

        digits[5] = combined[39:36];
        digits[4] = combined[35:32];
        digits[3] = combined[31:28];
        digits[2] = combined[27:24];
        digits[1] = combined[23:20];
        digits[0] = combined[19:16];
    end

    // function for encoding the display
    function [6:0] seg_decode;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seg_decode = 7'b1000000;
                4'd1: seg_decode = 7'b1111001;
                4'd2: seg_decode = 7'b0100100;
                4'd3: seg_decode = 7'b0110000;
                4'd4: seg_decode = 7'b0011001;
                4'd5: seg_decode = 7'b0010010;
                4'd6: seg_decode = 7'b0000010;
                4'd7: seg_decode = 7'b1111000;
                4'd8: seg_decode = 7'b0000000;
                4'd9: seg_decode = 7'b0010000;
                default: seg_decode = 7'b1111111; // blank (active-low displays)
            endcase
        end
    endfunction


    assign seg0 = seg_decode(digits[0]);
    assign seg1 = seg_decode(digits[1]);
    assign seg2 = seg_decode(digits[2]);
    assign seg3 = seg_decode(digits[3]);
    assign seg4 = seg_decode(digits[4]);
    assign seg5 = show_price ? 7'b0001100 : 7'b1111111; // P or Blank

endmodule
