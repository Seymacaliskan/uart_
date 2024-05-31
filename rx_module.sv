`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2024 20:43:44
// Design Name: 
// Module Name: rx_module
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

module rx_module#(
  parameter integer DATA_WIDTH = 8,
  parameter integer FIFO_DEPTH = 32,
  parameter integer BAUD_DIV_MAX = 48 // 1 Mbps i�in (48 MHz / 1 Mbps)
) (
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] rx_in,
  input rx_en,
  output reg [DATA_WIDTH-1:0] rx_data_out,
  output reg rx_buffer_empty,
  output reg rx_error
);

  // RX arabelle�i
  reg [DATA_WIDTH-1:0] rx_buffer [FIFO_DEPTH-1:0];
  // RX yazma i�aret�isi
  reg [LOG2(FIFO_DEPTH)-1:0] rx_wr_ptr;
  // RX okuma i�aret�isi
  reg [LOG2(FIFO_DEPTH)-1:0] rx_rd_ptr;
  // RX durum de�i�kenleri
  reg rx_start_bit;
  reg rx_data_valid;
  reg rx_error_flag;
  // RX kenar alg�lama saya�lar�
  reg [3:0] clk_count_startbit;
  reg [3:0] clk_count_databit;
  reg [3:0] clk_count_stopbit;

  // Baud h�z� saya�lar�
  reg [BAUD_DIV_MAX-1:0] baud_cnt_rx;
  reg baud_pulse_rx;

  // Kenar alg�lama i�in saya�lar� s�f�rla
  always @(posedge clk) begin
    if (rst) begin
      clk_count_startbit <= 0;
      clk_count_databit <= 0;
      clk_count_stopbit <= 0;
      baud_cnt_rx <= 0;
    end
  end

  // Baud h�z� g�ncelle
  always @(posedge clk) begin
    if (rst) begin
      baud_cnt_rx <= 0;
    end else begin
      if (rx_en) begin
        baud_cnt_rx <= baud_cnt_rx + 1;
        if (baud_cnt_rx == rx_en) begin // baud_rate_in ile de�i�tir
          baud_pulse_rx <= 1;
          baud_cnt_rx <= 0; // Baud d�nemi s�f�rla
        end else begin
          baud_pulse_rx <= 0;
        end
      end
    end
  end

  // RX i�lemleri
  always @(posedge clk) begin
    if (rst) begin
      rx_wr_ptr <= 0;
      rx_rd_ptr <= 0;
      rx_start_bit <= 0;
      rx_data_valid <= 0;
      rx_error_flag <= 0;
    end else begin
      if (rx_en) begin
        // Ba�lang�� bitini alg�la
        if (~rx_start_bit && baud_pulse_rx && rx_in == 1'b0) begin
          clk_count_startbit <= 1;
        end else begin
          clk_count_startbit <= 0; // Ba�lang�� biti alg�land�ktan sonra s�f�rla
        end

        // Veri bitlerini al
        if (rx_start_bit && baud_pulse_rx && rx_valid) begin
          clk_count_databit <= clk_count_databit + 1;
          if (clk_count_databit == DATA_WIDTH) begin // Veri bitleri i�in DATA_WIDTH kullan
            rx_buffer[rx_wr_ptr] <= rx_in;
            rx_wr_ptr <= rx_wr_ptr + 1;
            if (rx_wr_ptr == FIFO_DEPTH) begin
              rx_wr_ptr <= 0;
            end
            rx_data_valid <= 1;
            clk_count_databit <= 0;
          end
        end else begin
          clk_count_databit <= 0; // Veri bitleri bitmiyorsa s�f�rla
        end

 // Durma bitini alg�la
if (rx_start_bit && ~baud_pulse_rx) begin
  clk_count_stopbit <= clk_count_stopbit + 1;
  if (clk_count_stopbit == 1) begin // 1 bitlik durma biti yeterli
    // Veri al�m� tamamland�, hata yok
    rx_error_flag <= 0;
    rx_start_bit <= 0; // Bir sonraki karakter i�in haz�rla
  end else if (clk_count_stopbit > 1) begin
    // Fazla durma biti: hata
    rx_error_flag <= 1;
    rx_start_bit <= 0; // Bir sonraki karakter i�in haz�rla
  end
end

// RX ��k�� verisi
assign rx_data_out = (rx_data_valid) ? rx_buffer[rx_rd_ptr] : 8'bzzzzzzzz; //y�ksek empedans

// RX arabellek okuma i�lemi
always @(posedge clk) begin
  if (rx_en && rx_data_valid) begin
    rx_rd_ptr <= rx_rd_ptr + 1;
    if (rx_rd_ptr == FIFO_DEPTH) begin
      rx_rd_ptr <= 0;
    end
    rx_data_valid <= 0; // Bir sonraki okunmaya haz�rlan
  end
end

// RX arabellek durumu
assign rx_buffer_empty = (rx_wr_ptr == rx_rd_ptr);

endmodule
    

