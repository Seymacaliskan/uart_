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
  parameter integer BAUD_DIV_MAX = 48 // 1 Mbps için (48 MHz / 1 Mbps)
) (
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] rx_in,
  input rx_en,
  output reg [DATA_WIDTH-1:0] rx_data_out,
  output reg rx_buffer_empty,
  output reg rx_error
);

  // RX arabelleði
  reg [DATA_WIDTH-1:0] rx_buffer [FIFO_DEPTH-1:0];
  // RX yazma iþaretçisi
  reg [LOG2(FIFO_DEPTH)-1:0] rx_wr_ptr;
  // RX okuma iþaretçisi
  reg [LOG2(FIFO_DEPTH)-1:0] rx_rd_ptr;
  // RX durum deðiþkenleri
  reg rx_start_bit;
  reg rx_data_valid;
  reg rx_error_flag;
  // RX kenar algýlama sayaçlarý
  reg [3:0] clk_count_startbit;
  reg [3:0] clk_count_databit;
  reg [3:0] clk_count_stopbit;

  // Baud hýzý sayaçlarý
  reg [BAUD_DIV_MAX-1:0] baud_cnt_rx;
  reg baud_pulse_rx;

  // Kenar algýlama için sayaçlarý sýfýrla
  always @(posedge clk) begin
    if (rst) begin
      clk_count_startbit <= 0;
      clk_count_databit <= 0;
      clk_count_stopbit <= 0;
      baud_cnt_rx <= 0;
    end
  end

  // Baud hýzý güncelle
  always @(posedge clk) begin
    if (rst) begin
      baud_cnt_rx <= 0;
    end else begin
      if (rx_en) begin
        baud_cnt_rx <= baud_cnt_rx + 1;
        if (baud_cnt_rx == rx_en) begin // baud_rate_in ile deðiþtir
          baud_pulse_rx <= 1;
          baud_cnt_rx <= 0; // Baud dönemi sýfýrla
        end else begin
          baud_pulse_rx <= 0;
        end
      end
    end
  end

  // RX iþlemleri
  always @(posedge clk) begin
    if (rst) begin
      rx_wr_ptr <= 0;
      rx_rd_ptr <= 0;
      rx_start_bit <= 0;
      rx_data_valid <= 0;
      rx_error_flag <= 0;
    end else begin
      if (rx_en) begin
        // Baþlangýç bitini algýla
        if (~rx_start_bit && baud_pulse_rx && rx_in == 1'b0) begin
          clk_count_startbit <= 1;
        end else begin
          clk_count_startbit <= 0; // Baþlangýç biti algýlandýktan sonra sýfýrla
        end

        // Veri bitlerini al
        if (rx_start_bit && baud_pulse_rx && rx_valid) begin
          clk_count_databit <= clk_count_databit + 1;
          if (clk_count_databit == DATA_WIDTH) begin // Veri bitleri için DATA_WIDTH kullan
            rx_buffer[rx_wr_ptr] <= rx_in;
            rx_wr_ptr <= rx_wr_ptr + 1;
            if (rx_wr_ptr == FIFO_DEPTH) begin
              rx_wr_ptr <= 0;
            end
            rx_data_valid <= 1;
            clk_count_databit <= 0;
          end
        end else begin
          clk_count_databit <= 0; // Veri bitleri bitmiyorsa sýfýrla
        end

 // Durma bitini algýla
if (rx_start_bit && ~baud_pulse_rx) begin
  clk_count_stopbit <= clk_count_stopbit + 1;
  if (clk_count_stopbit == 1) begin // 1 bitlik durma biti yeterli
    // Veri alýmý tamamlandý, hata yok
    rx_error_flag <= 0;
    rx_start_bit <= 0; // Bir sonraki karakter için hazýrla
  end else if (clk_count_stopbit > 1) begin
    // Fazla durma biti: hata
    rx_error_flag <= 1;
    rx_start_bit <= 0; // Bir sonraki karakter için hazýrla
  end
end

// RX çýkýþ verisi
assign rx_data_out = (rx_data_valid) ? rx_buffer[rx_rd_ptr] : 8'bzzzzzzzz; //yüksek empedans

// RX arabellek okuma iþlemi
always @(posedge clk) begin
  if (rx_en && rx_data_valid) begin
    rx_rd_ptr <= rx_rd_ptr + 1;
    if (rx_rd_ptr == FIFO_DEPTH) begin
      rx_rd_ptr <= 0;
    end
    rx_data_valid <= 0; // Bir sonraki okunmaya hazýrlan
  end
end

// RX arabellek durumu
assign rx_buffer_empty = (rx_wr_ptr == rx_rd_ptr);

endmodule
    

