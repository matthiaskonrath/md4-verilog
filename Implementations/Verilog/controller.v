`timescale 1ns / 1ps
/*
---- ---- ---- ---- ---- ---- ---- ----
            Information
---- ---- ---- ---- ---- ---- ---- ----
Author: Matthias Konrath
Email:  matthias AT inet-sec.at
---- ---- ---- ---- ---- ---- ---- ----
                LICENSE
---- ---- ---- ---- ---- ---- ---- ----
MIT License
Copyright (c) 2021 Matthias Konrath
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/



module controller(
    input wire CLK100MHZ,
    input wire btnCpuReset,
    input wire btnC,
    output wire [7:0] led
    );
    
    parameter DATA_SIZE=16;
    parameter HASH_SIZE=16;
    
    reg [7:0] data [0:255];
    reg [15:0] data_counter;
    reg [7:0] hash [0:15];
    reg [7:0] hash_counter;
    reg btn_debounce;
    
    assign led[7:0] = hash[15];
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //    CLOCK SETUP (via Clocking Wizard)
    // ---- ---- ---- ---- ---- ---- ---- ----
    wire CLK85MHZ;
    assign alternative_clk = CLK85MHZ;
    
    clk_wiz_0 clk_generator (
      // Clock out ports
      .clk_out1(CLK85MHZ),
      .clk_in1(CLK100MHZ)
    );
    // STOP CLOCK SETUP
    
    
    
    // ---- ---- ---- ---- ---- ---- ---- ----
    //              MD4 INTERFACE
    // ---- ---- ---- ---- ---- ---- ---- ----
    reg MD4_START;
    wire MD4_BUSY;
    wire MD4_DONE;
    reg [63:0] MD4_DATA_SIZE;
    // FIFOs
    reg [7:0] MD4_DATA_BYTE;
    reg MD4_DATA_EMPTY;
    wire MD4_DATA_READ;
    wire [7:0] MD4_HASH_BYTE;
    reg MD4_HASH_FULL;
    wire MD4_HASH_WRITE;
    
    md4 md4_interface(
        .CLK(alternative_clk),
        .RESET_N(btnCpuReset),
        // CONTROL
        .START_IN(MD4_START),
        .BUSY_OUT(MD4_BUSY),
        .DONE_OUT(MD4_DONE),
        .INPUT_SIZE_IN(MD4_DATA_SIZE),
        // INPUT FIFO
        .INPUT_BYTE(MD4_DATA_BYTE),
        .INPUT_EMPTY(MD4_DATA_EMPTY),
        .INPUT_READ(MD4_DATA_READ),
        // OUTPUT FIFO
        .OUTPUT_BYTE(MD4_HASH_BYTE),
        .OUTPUT_FULL(MD4_HASH_FULL),
        .OUTPUT_WRITE(MD4_HASH_WRITE)
    ); // STOP MD4
    
    
    
    always @(posedge alternative_clk) begin
        if (!btnCpuReset) begin
            btn_debounce <= 1;
            data_counter <= 1;
            hash_counter <= 0;
            MD4_START <= 0;
            MD4_DATA_SIZE <= DATA_SIZE;   
            // SET THE FIFO PINS
            MD4_DATA_EMPTY <= 1;
            MD4_HASH_FULL <= 1;
            hash[8'h00] <= 8'h00; hash[8'h01] <= 8'h00; hash[8'h02] <= 8'h00; hash[8'h03] <= 8'h00; hash[8'h04] <= 8'h00; hash[8'h05] <= 8'h00; hash[8'h06] <= 8'h00; hash[8'h07] <= 8'h00;
            hash[8'h08] <= 8'h00; hash[8'h09] <= 8'h00; hash[8'h0a] <= 8'h00; hash[8'h0b] <= 8'h00; hash[8'h0c] <= 8'h00; hash[8'h0d] <= 8'h00; hash[8'h0e] <= 8'h00; hash[8'h0f] <= 8'h00;
            data[8'h00] <= 8'h31; data[8'h01] <= 8'h32; data[8'h02] <= 8'h33; data[8'h03] <= 8'h34; data[8'h04] <= 8'h35; data[8'h05] <= 8'h36; data[8'h06] <= 8'h37; data[8'h07] <= 8'h38;
            data[8'h08] <= 8'h39; data[8'h09] <= 8'h31; data[8'h0a] <= 8'h32; data[8'h0b] <= 8'h33; data[8'h0c] <= 8'h34; data[8'h0d] <= 8'h35; data[8'h0e] <= 8'h36; data[8'h0f] <= 8'h37;
            
            MD4_DATA_BYTE <= 8'h31;
        end else begin
        
            // ---- ---- ---- ---- ---- ---- ---- ----
            //              START SIGNAL
            // ---- ---- ---- ---- ---- ---- ---- ----
            if(btnC && btn_debounce) begin
                btn_debounce <= 0;
                MD4_START <= 1'b1;
            end
            if (MD4_DONE) begin
                MD4_START <= 0;
            end // STOP START SIGNAL
        
        
        
            // ---- ---- ---- ---- ---- ---- ---- ----
            //              DATA TRANSFARE
            // ---- ---- ---- ---- ---- ---- ---- ----
            if (MD4_DATA_READ) begin
                if (data_counter == MD4_DATA_SIZE) begin
                    data_counter <= 0;
                    MD4_DATA_BYTE <= 8'b00;
                end
                else begin
                    data_counter <= data_counter +1;
                    MD4_DATA_BYTE <= data[data_counter];
                end
            end
            
            
            
            // ---- ---- ---- ---- ---- ---- ---- ----
            //              HASH TRNASFARE
            // ---- ---- ---- ---- ---- ---- ---- ----
            // HASH SHOULD BE 0x2baa0645e8c33c14022716e6da14b81c
            //      LED = 1C --> 00011100
            if (MD4_HASH_WRITE) begin
                hash[hash_counter] <= MD4_HASH_BYTE;
                if (hash_counter == HASH_SIZE-1)
                    hash_counter <= 0;
                else
                    hash_counter <= hash_counter +1;
            end
        end
    end
endmodule
