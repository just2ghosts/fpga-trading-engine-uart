# MIT License
# 
# Copyright (c) 2025 Just2Ghosts
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
###############################################################################
import random
import serial
import time

PORT = "COM3"
BAUD_RATE = 115200
INITIAL_THRESHOLD = 123.45 
PRICE_INTERVAL = 2  # seconds
PRICE_VARIATION = 0.05 # cents


def main():
    price = INITIAL_THRESHOLD  # initialize price 

    try:
        with serial.Serial(PORT, BAUD_RATE, timeout=1) as ser:
            print(f"Connected to {PORT} at {BAUD_RATE} baud.")

            # send initial threshold
            threshold_msg = f"SET:{INITIAL_THRESHOLD:.2f}\n"
            ser.write(threshold_msg.encode())
            print(f"> Sent: {threshold_msg.strip()}")

            # begin sending prices
            while True:
                price += random.uniform(-PRICE_VARIATION, PRICE_VARIATION)
                price = round(price, 2)
                message = f"PRICE:{price:.2f}\n"

                ser.write(message.encode())
                print(f"> Sent: {message.strip()}")

                time.sleep(PRICE_INTERVAL)

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
