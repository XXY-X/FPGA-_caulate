module plan_b
(
input clk,
input rst,

output  rclk_out_top,
output  sclk_out_top,
output  sdio_out_top,

input			[3:0]	col_top,
output      	[3:0]	row_top
);

wire [3:0] seg_data_1;
wire [3:0] seg_data_2;
wire [3:0] seg_data_3;
wire [3:0] seg_data_4;
wire [3:0] seg_data_5;
wire [3:0] seg_data_6;
wire [3:0] seg_data_7;
wire [3:0] seg_data_8;
wire [7:0] seg_data_en;
wire [7:0] seg_dot_en;



wire [15:0] key_out;
wire clk_200_hz;
wire [15:0] key_pulse;

array_keyboard my_Array_KeyBoard
(
.clk    (clk),
.rst_n  (rst),
.key_out   (key_out),
.col    (col_top),
.row    (row_top),
.key_pulse (key_pulse)
);

segment_scan my_Segment_scan
(
.clk      (clk),
.rst_n    (rst),
.dat_1  (seg_data_1),
.dat_2  (seg_data_2),
.dat_3  (seg_data_3),
.dat_4  (seg_data_4),
.dat_5  (seg_data_5),
.dat_6  (seg_data_6),
.dat_7  (seg_data_7),
.dat_8  (seg_data_8),
.dat_en (seg_data_en),
.dot_en  (seg_dot_en),
.seg_rck    (rclk_out_top),
.seg_sck    (sclk_out_top),
.seg_din    (sdio_out_top)

);


control my_control
(
.clk_in      (clk),
.rst_n_in    (rst),
.seg_data_1  (seg_data_1),
.seg_data_2  (seg_data_2),
.seg_data_3  (seg_data_3),
.seg_data_4  (seg_data_4),
.seg_data_5  (seg_data_5),
.seg_data_6  (seg_data_6),
.seg_data_7  (seg_data_7),
.seg_data_8  (seg_data_8),
.seg_data_en (seg_data_en),
.seg_dot_en  (seg_dot_en),
.key_out     (key_out),
.key_pulse     (key_pulse)
);

endmodule