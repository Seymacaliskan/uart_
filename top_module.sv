`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2024 21:13:43
// Design Name: 
// Module Name: top_module
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


module top_module #(
  parameter integer DATA_WIDTH = 8,
  parameter integer FIFO_DEPTH = 32,
  parameter integer BAUD_DIV_MAX = 48 // 1 Mbps için (48 MHz / 1 Mbps)
) (
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] tx_data_in,
  output reg tx_busy,
  output reg [DATA_WIDTH-1:0] rx_data_out,
  output reg rx_error_flag
);

  // TX modülü
  wire tx_out;
  tx_module #(
    .DATA_WIDTH = DATA_WIDTH,
    .FIFO_DEPTH = FIFO_DEPTH,
    .BAUD_DIV_MAX = BAUD_DIV_MAX
  ) tx_inst (
    .clk(clk),
    .rst(rst),
    .tx_data_in(tx_data_in),
    .tx_en(tx_busy),
    .tx_out(tx_out),
    .tx_busy(tx_busy)
  );

  // RX modülü
  wire rx_en;
  rx_module #(
    .DATA_WIDTH = DATA_WIDTH,
    .FIFO_DEPTH = FIFO_DEPTH,
    .BAUD_DIV_MAX = BAUD_DIV_MAX
  ) rx_inst (
    .clk(clk),
    .rst(rst),
    .rx_in(tx_out), // TX çýkýþýný RX giriþine baðladýk
    .rx_en(rx_en),
    .rx_data_out(rx_data_out),
    .rx_buffer_empty(rx_buffer_empty), 
    .rx_error(rx_error_flag)
  );

  // RX modülünü etkinleþtirmek için
  always @(posedge clk) begin
    if (rst) begin
      rx_en <= 1'b0;
    end else begin
      rx_en <= tx_busy; 
    end
  end

endmodule
