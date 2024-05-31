`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2024 21:08:58
// Design Name: 
// Module Name: tx_module
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


module tx_module#(
  parameter integer DATA_WIDTH = 8,
  parameter integer FIFO_DEPTH = 32,
  parameter integer BAUD_DIV_MAX = 48 // 1 Mbps i�in (48 MHz / 1 Mbps)
) 
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] tx_data_in,
  input tx_en,
  output reg tx_busy,
  output reg tx_out
);

  // TX arabelle�i
  reg [DATA_WIDTH-1:0] tx_buffer [FIFO_DEPTH-1:0];
  // TX okuma i�aret�isi
  reg [LOG2(FIFO_DEPTH)-1:0] tx_rd_ptr;
  // TX yazma i�aret�isi
  reg [LOG2(FIFO_DEPTH)-1:0] tx_wr_ptr;
  // TX durum de�i�kenleri
  reg tx_start_bit;
  reg tx_data_valid;
  // TX kenar alg�lama saya�lar�
  reg [3:0] clk_count_startbit;
  reg [3:0] clk_count_databit;
  reg [3:0] clk_count_stopbit;

  // Baud h�z� saya�lar�
  reg [BAUD_DIV_MAX-1:0] baud_cnt_tx;
  reg baud_pulse_tx;

  // Kenar alg�lama i�in saya�lar� s�f�rla
  always @(posedge clk) begin
    if (rst) begin
      clk_count_startbit <= 0;
      clk_count_databit <= 0;
      clk_count_stopbit <= 0;
      baud_cnt_tx <= 0;
    end
  end

  // Baud h�z� g�ncelle
  always @(posedge clk) begin
    if (rst) begin
      baud_cnt_tx <= 0;
    end else begin
      if (tx_en) begin
        baud_cnt_tx <= baud_cnt_tx + 1;
        if (baud_cnt_tx == rx_en) begin // baud_rate_in ile de�i�tir
          baud_pulse_tx <= 1;
          baud_cnt_tx <= 0; // Baud d�nemi s�f�rla
        end else begin
          baud_pulse_tx <= 0;
        end
      end
    end
  end

  // TX i�lemleri
  always @(posedge clk) begin
    if (rst) begin
      tx_wr_ptr <= 0;
      tx_rd_ptr <= 0;
      tx_start_bit <= 0;
      tx_data_valid <= 0;
      tx_busy <= 0;
      tx_out <= 1'b1; // Ba�lang��ta y�ksek seviye (idle)
    end else begin
      if (tx_en) begin
        tx_busy <= 1; // Veri g�nderilmeye ba�land�

        // TX  bo�sa, g�nderilecek veriyi arabelle�e at
        if (tx_wr_ptr == tx_rd_ptr && tx_data_valid == 0) begin
          tx_buffer[tx_wr_ptr] <= tx_data_in;
          tx_wr_ptr <= tx_wr_ptr + 1;
          if (tx_wr_ptr == FIFO_DEPTH) begin
            tx_wr_ptr <= 0;
          end
          tx_data_valid <= 1;
        end

        // Ba�lang�� bitini g�nder
        if (tx_data_valid && ~tx_start_bit && baud_pulse_tx) begin
          tx_out <= 1'b0;
          clk_count_startbit <= 1;
          tx_start_bit <= 1;
        end
// Veri bitlerini g�nder
if (tx_start_bit && baud_pulse_tx && tx_data_valid) begin
  clk_count_databit <= clk_count_databit + 1;
  if (clk_count_databit == DATA_WIDTH) begin
    tx_out <= tx_buffer[tx_rd_ptr];
    tx_rd_ptr <= tx_rd_ptr + 1;
    if (tx_rd_ptr == FIFO_DEPTH) begin
      tx_rd_ptr <= 0;
    end
    clk_count_databit <= 0; // Veri bitleri bitti, s�f�rla
    tx_data_valid <= 0; // Bir sonraki veri bitine haz�rlans�n
  end
end

// Durma bitini g�nder
if (tx_start_bit && ~baud_pulse_tx) begin
  clk_count_stopbit <= clk_count_stopbit + 1;
  if (clk_count_stopbit == 1) begin // 1 bitlik durma biti yeterli
    tx_out <= 1'b1; // Durma bitini g�nder
    clk_count_stopbit <= 0; // Durma biti bitti, s�f�rla
    tx_start_bit <= 0; // Bir sonraki veri i�in haz�rlans�n
    tx_busy <= 0; // G�nderme i�lemi tamamland�
  end
end

// TX arabelle�i bo�sa ve veri g�nderilmiyorsa, busy sinyali d���k olacak
if (tx_wr_ptr == tx_rd_ptr && tx_data_valid == 0 && tx_busy == 1) begin
  tx_busy <= 0;
end

endmodule
