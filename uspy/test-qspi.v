/*
 * Test the QSPI async implementation
 *
 */
`default_nettype none
`include "qspi.v"

module top();
	reg clk;
	reg reset;

	initial begin
		$dumpfile("test-qspi.vcd");
		$dumpvars(0,top);
		clk = 0;
		reset = 1;
		repeat(4) #5 clk = ~clk;
		reset = 0;
		forever #5 clk = ~clk;
	end

	always @(posedge clk)
	begin

		#10000
		$finish;
	end

	reg spi_clk = 0;
	reg spi_cs = 1;

	reg [3:0] spi_data = 0;
	wire [3:0] spi_data_out;

	wire [7:0] spi_byte;
	wire spi_start_strobe;
	wire spi_byte_strobe;
	reg [7:0] spi_byte_tx = 0;

	qspi_raw qspi_i(
		//.clk(clk),
		.reset(reset),
		.spi_clk_in(spi_clk),
		.spi_cs_in(spi_cs),
		.spi_data_in(spi_data),
		.spi_data_out(spi_data_out),
		.byte(spi_byte),
		.byte_tx(spi_byte_tx),
		.start_strobe(spi_start_strobe),
		.byte_strobe(spi_byte_strobe)
	);

	reg spi_data_ack = 1;
	reg [7:0] spi_data_in = 0;
	reg [7:0] spi_data_orig = 0;


	always @(posedge spi_clk)
	begin
		if (spi_byte_strobe)
		begin
/*
			if (spi_data_ack)
				$display("ERROR: multiple byte strobes");
			if (spi_data_orig != spi_byte)
				$display("ERROR: expected %02x, recieved %02x", spi_data_orig, spi_byte);
			spi_data_ack = 1;
*/
		end

		if (spi_start_strobe)
		begin
			//spi_byte_tx <= 0;
			spi_byte_tx <= spi_byte_tx + 8'h80;
			$display("cmd %02x", spi_byte);
		end else
		if (spi_byte_strobe)
		begin
			spi_byte_tx <= spi_byte_tx + 1;
			$display("dat %02x", spi_byte);
		end
	end

parameter spi_freq = 13;

	/* if (!spi_data_ack) $display("!!! PREVIOUS SPI DATA NOT ACKED"); */

`define spi_send_1(data) \
	spi_data_ack = 0; \
	spi_data_orig = data; \
	spi_data_in = data; \
	repeat(8) begin \
		spi_data[0] = spi_data_in[7]; \
		spi_data_in <<= 1; \
		#spi_freq spi_clk = 1; \
		#spi_freq spi_clk = 0; \
	end

	/* if (!spi_data_ack) $display("!!! PREVIOUS SPI DATA NOT ACKED"); */

`define spi_send_4(data) \
	spi_data_ack = 0; \
	spi_data_orig = data; \
	spi_data_in = data; \
	repeat(2) begin \
		spi_data[3:0] = spi_data_in[7:4]; \
		spi_data_in <<= 4; \
		#spi_freq spi_clk = 1; \
		#spi_freq spi_clk = 0; \
	end

	always
	begin
		#49

		#spi_freq spi_cs = 0;
		`spi_send_1(8'h03);
		`spi_send_1(8'hA5);
		`spi_send_1(8'h5A);
		`spi_send_1(8'h01);
		`spi_send_1(8'h02);
		#spi_freq spi_cs = 1;

		#spi_freq spi_cs = 0;
		`spi_send_1(8'hEB);
		`spi_send_4(8'hA5);
		`spi_send_4(8'h5A);
		`spi_send_4(8'h01);
		`spi_send_4(8'h02);
		#spi_freq spi_cs = 1;

		#spi_freq spi_cs = 0;
		`spi_send_1(8'hEB);
		`spi_send_4(8'h10);
		`spi_send_4(8'h20);
		`spi_send_4(8'h30);
		`spi_send_4(8'h40);
		#spi_freq spi_cs = 1;

		$finish;
	end
endmodule
