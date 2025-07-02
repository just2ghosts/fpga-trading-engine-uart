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
`timescale 1ns / 1ps

module tb_trading_engine;

    reg clk = 0;
    reg rst = 1;
    reg rx = 1;

    wire led_buy, led_sell;
    wire [6:0] seg0, seg1, seg2, seg3, seg4, seg5;

    trading_engine uut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .led_buy(led_buy),
        .led_sell(led_sell),
        .seg0(seg0),
        .seg1(seg1),
        .seg2(seg2),
        .seg3(seg3),
        .seg4(seg4),
        .seg5(seg5)
    );

    // Clock (50 MHz)
    always #10 clk = ~clk;  // 20 ns period

    // func to simulate UART transmission of a byte
    task send_uart_byte(input [7:0] byte);
    integer i;
    begin
			rx = 0;  // Start bit
			#(8680);

			for (i = 0; i < 8; i = i + 1) begin
				rx = byte[i];
				#(8680);
			end

			rx = 1;  // Stop bit
			#(8680);
		end
	endtask

    // func to send a string as UART characters
    task send_uart_string(input [8*16-1:0] str, input integer len);
		 integer j;
		 begin
			  for (j = 0; j < len; j = j + 1) begin
					send_uart_byte(str[8*(len-j)-1 -: 8]);
			  end
		 end
	endtask
	 
	initial begin
		 // reset
		 rst = 0;
		 #100;
		 rst = 1;

		 // Wait a bit before sending
		 #100000;
		 
		 // Send "S:200.00\n"
		 send_uart_string("S:200.00\n", 9);

		 #500000;

		 // Send "P:123.45\n"
		 send_uart_string("P:123.45\n", 9);

		 #1000000;  // allow display of threshold

		 $stop;
	end


endmodule
