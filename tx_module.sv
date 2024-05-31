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
  parameter integer BAUD_DIV_MAX = 48 // 1 Mbps için (48 MHz / 1 Mbps)
) 
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] tx_data_in,
  input tx_en,
  output reg tx_busy,
  output reg tx_out
);

  // TX arabelleði
  reg [DATA_WIDTH-1:0] tx_buffer [FIFO_DEPTH-1:0];
  // TX okuma iþaretçisi
  reg [LOG2(FIFO_DEPTH)-1:0] tx_rd_ptr;
  // TX yazma iþaretçisi
  reg [LOG2(FIFO_DEPTH)-1:0] tx_wr_ptr;
  // TX durum deðiþkenleri
  reg tx_start_bit;
  reg tx_data_valid;
  // TX kenar algýlama sayaçlarý
  reg [3:0] clk_count_startbit;
  reg [3:0] clk_count_databit;
  reg [3:0] clk_count_stopbit;

  // Baud hýzý sayaçlarý
  reg [BAUD_DIV_MAX-1:0] baud_cnt_tx;
  reg baud_pulse_tx;

  // Kenar algilama icin sayaclarý sifirladik
  always @(posedge clk) begin
    if (rst) begin
      clk_count_startbit <= 0;
      clk_count_databit <= 0;
      clk_count_stopbit <= 0;
      baud_cnt_tx <= 0;
    end
  end

  // Baud hizi güncelledik
  always @(posedge clk) begin
    if (rst) begin
      baud_cnt_tx <= 0;
    end else begin
      if (tx_en) begin
        baud_cnt_tx <= baud_cnt_tx + 1;
        if (baud_cnt_tx == rx_en) begin // baud_rate_in ile deðiþtir
          baud_pulse_tx <= 1;
          baud_cnt_tx <= 0; // Baud dönemi sifirla
        end else begin
          baud_pulse_tx <= 0;
        end
      end
    end
  end

  // TX iþlemleri
  always @(posedge clk) begin
    if (rst) begin
      tx_wr_ptr <= 0;
      tx_rd_ptr <= 0;
      tx_start_bit <= 0;
      tx_data_valid <= 0;
      tx_busy <= 0;
      tx_out <= 1'b1; // Baslangicta yuksek seviye (idle)
    end else begin
      if (tx_en) begin
        tx_busy <= 1; // Veri gonderilmeye baslandi

        if (tx_wr_ptr == tx_rd_ptr && tx_data_valid == 0) begin
          tx_buffer[tx_wr_ptr] <= tx_data_in;
          tx_wr_ptr <= tx_wr_ptr + 1;
          if (tx_wr_ptr == FIFO_DEPTH) begin
            tx_wr_ptr <= 0;
          end
          tx_data_valid <= 1;
        end

        if (tx_data_valid && ~tx_start_bit && baud_pulse_tx) begin
          tx_out <= 1'b0;
          clk_count_startbit <= 1;
          tx_start_bit <= 1;
        end

  if (tx_start_bit && baud_pulse_tx && tx_data_valid) begin
    clk_count_databit <= clk_count_databit + 1;
     if (clk_count_databit == DATA_WIDTH) begin
      tx_out <= tx_buffer[tx_rd_ptr];
      tx_rd_ptr <= tx_rd_ptr + 1;
      if (tx_rd_ptr == FIFO_DEPTH) begin
        tx_rd_ptr <= 0;
      end
      clk_count_databit <= 0; // Veri bitleri bitti, sýfýrla
      tx_data_valid <= 0; // Bir sonraki veri bitine hazýrlansýn
    end
  end

  if (tx_start_bit && ~baud_pulse_tx) begin
    clk_count_stopbit <= clk_count_stopbit + 1;
    if (clk_count_stopbit == 1) begin // 1 bitlik durma biti yeterli
     tx_out <= 1'b1; 
      clk_count_stopbit <= 0; 
      tx_start_bit <= 0; 
      tx_busy <= 0; // Gönderme iþlemi tamamlandý
    end
  end

  if (tx_wr_ptr == tx_rd_ptr && tx_data_valid == 0 && tx_busy == 1) begin
    tx_busy <= 0;
  end

endmodule
