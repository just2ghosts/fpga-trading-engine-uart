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
// UART receive line
module uart_rx #(
    parameter CLK_FREQ = 50000000,     // 50 MHz
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,         // sys clock 
    input  wire       rst,         // sync reset
    input  wire       rx,          // serial input
    output reg  [7:0] data_out,    // received byte
    output reg        data_valid   // high for 1 clock when data_out is ready
);

    // compute number of clock cycles per bit period
    localparam integer CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state = IDLE;

    reg [15:0] clk_count = 0;   // counts down to sample times
    reg [2:0]  bit_index = 0;   // 0 to 7 for 8 data bits
    reg [7:0]  rx_shift  = 0;   // assembles incoming byte
    reg        rx_sync   = 1;   // synchronized RX input

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            clk_count  <= 0;
            bit_index  <= 0;
            data_out   <= 8'd0;
            data_valid <= 0;
            rx_shift   <= 8'd0;
        end else begin
            data_valid <= 0;  // Default: no new data

            rx_sync <= rx;  // synchronize RX input

            case (state)
                // wait for zero (start bit)
                IDLE: begin
                    if (rx_sync == 0) begin
                        clk_count <= CLK_PER_BIT / 2;
                        state <= START;
                    end
                end

                // wait half a bit time before sampling
                START: begin
                    if (clk_count == 0) begin
                        clk_count <= CLK_PER_BIT;
                        bit_index <= 0;
                        state <= DATA;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end

                // read 8 bits (LSB first)
                DATA: begin
                    if (clk_count == 0) begin
                        rx_shift[bit_index] <= rx_sync;
                        bit_index <= bit_index + 1;

                        if (bit_index == 3'd7)
                            state <= STOP;

                        clk_count <= CLK_PER_BIT;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end

                // wait one stop bit
                STOP: begin
                    if (clk_count == 0) begin
                        data_out <= rx_shift;
                        data_valid <= 1;
                        state <= IDLE;
                    end else begin
                        clk_count <= clk_count - 1;
                    end
                end
            endcase
        end
    end
endmodule
