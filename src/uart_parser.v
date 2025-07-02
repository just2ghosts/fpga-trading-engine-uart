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
//parses ASCII into type and stores integer in appropiate register
module uart_parser (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  rx_byte,
    input  wire        rx_valid,
    output reg  [15:0] price,
    output reg  [15:0] threshold,
	 output reg         new_price
);

    localparam IDLE        = 3'd0;
    localparam READ_HEADER = 3'd1;
    localparam READ_NUMBER = 3'd2;
    localparam CONVERT     = 3'd3;
    localparam STORE       = 3'd4;

    reg [2:0]  state = IDLE;
    reg [7:0]  buffer [0:15];    // message buffer
    reg [3:0]  index = 0;
    reg [3:0]  convert_index = 0;
    reg        is_price = 0;
    reg [15:0] parsed_value = 0;

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            index         <= 0;
            convert_index <= 0;
            price         <= 0;
            threshold     <= 0;
            parsed_value  <= 0;
            is_price      <= 0;
				new_price     <= 0;
        end else begin
				new_price     <= 0;   // default
		  
            case (state)
                IDLE: begin
                    if (rx_valid) begin
                        if (rx_byte == "P") begin
                            is_price <= 1;
                            buffer[0] <= "P";
                            index <= 1;
                            state <= READ_HEADER;
                        end else if (rx_byte == "S") begin
                            is_price <= 0;
                            buffer[0] <= "S";
                            index <= 1;
                            state <= READ_HEADER;
                        end
                    end
                end

                READ_HEADER: begin
                    if (rx_valid) begin
                        buffer[index] <= rx_byte;
                        index <= index + 1;
                        if (rx_byte == ":")
                            state <= READ_NUMBER;
                    end
                end

                READ_NUMBER: begin
                    if (rx_valid) begin
                        if (rx_byte == "\n") begin
                            parsed_value  <= 0;
                            convert_index <= 0;
                            state <= CONVERT;
                        end else if (rx_byte != ".") begin
                            buffer[index] <= rx_byte;
                            index <= index + 1;
                        end
                    end
                end

                CONVERT: begin
                    if (convert_index < index) begin
                        if (buffer[convert_index] >= "0" && buffer[convert_index] <= "9") begin    // using ascii code to get relative positions to 0 to reveal value
                            parsed_value <= (parsed_value * 10) + (buffer[convert_index] - "0");   // starts with most significant digit so move it left when it detects another number
                        end
                        convert_index <= convert_index + 1;
                    end else begin
                        state <= STORE;
                    end
                end

                STORE: begin
                    if (is_price) begin
                        price <= parsed_value;
								new_price <= 1;
                    end else begin
                        threshold <= parsed_value;
						  end
                    index <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule