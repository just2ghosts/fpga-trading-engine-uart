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
module trading_engine (
    input  wire       clk,       // 50 MHz clock
    input  wire       rst,       // active-high reset
    input  wire       rx,        // UART RX from PC
    output wire       led_buy,   // BUY signal indicator
	 output wire       led_sell,  // SELL signal indicator
	 output wire [6:0] seg0,      // Display 5th digit (cents)
	 output wire [6:0] seg1,      // Display 4th digit (dimes)
	 output wire [6:0] seg2,      // Display 3rd digit (dollars)
	 output wire [6:0] seg3,      // Display 2nd digit (tens)
	 output wire [6:0] seg4,      // Display 1st digit (hundreds)
	 output wire [6:0] seg5       // Price indicator in front (P)
);

    // signals
    wire [7:0]  uart_byte;
    wire        uart_valid;

	 wire rst_inv = ~rst;
	 
    wire [15:0] price;
    wire [15:0] threshold;
    wire        new_price;

    // UART RX instance
    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(115200)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst_inv),
        .rx(rx),
        .data_out(uart_byte),
        .data_valid(uart_valid)
    );

    // parser FSM instance
    uart_parser parser_inst (
        .clk(clk),
        .rst(rst_inv),
        .rx_byte(uart_byte),
        .rx_valid(uart_valid),
        .price(price),
        .threshold(threshold),
		  .new_price(new_price)
    );

    // breakout strategy, buy below threshold
    assign led_buy = (price < threshold) ? 1'b1 : 1'b0;
	 
	 // breakdown strategy, sell above threshold
    assign led_sell = (price > threshold) ? 1'b1 : 1'b0;
	 
	 // seven seg driver instance
	 sevenseg_driver driver_inst (
        .clk(clk),
        .rst(rst_inv),
        .price(price),
        .threshold(threshold),
        .new_price(new_price),
        .seg0(seg0),
        .seg1(seg1),
        .seg2(seg2),
        .seg3(seg3),
        .seg4(seg4),
        .seg5(seg5)
    );

endmodule