module top(
	input wire t_clk,
	input wire t_rst,

	inout wire [7:0] t_uart_data,
	input wire t_uart_txe,
	input wire t_uart_rxf,
	output wire t_uart_wr,
	output wire t_uart_rd
);

	wire clk = t_clk;


	wire srst;
	synchronizer rst_sync(
		.clk(clk),
		.in(t_rst),
		.out(srst)
	);

	reg [7:0] rst_tmr = 8'h0;
	wire por = rst_tmr != 255;
	always @(posedge clk) begin
		if(por) begin
			rst_tmr <= rst_tmr + 1;
		end
	end

	wire rst = ~srst | por;


	wire stxe;
	synchronizer txe_sync(
		.clk(clk),
		.in(t_uart_txe),
		.out(stxe)
	);

	wire srxf;
	synchronizer rxf_sync(
		.clk(clk),
		.in(t_uart_rxf),
		.out(srxf)
	);


	wire [7:0] uart_do;
	wire uart_wr;
	wire uart_rd;

    assign t_uart_data = t_uart_wr ? 8'bZZZZZZZZ : uart_do;
	assign t_uart_wr = ~uart_wr;
	assign t_uart_rd = ~uart_rd;
    

    SicoSOC soc(
        .clk(clk),
        .reset(rst),
        .io_uart_rdata(t_uart_data),
		.io_uart_wdata(uart_do),
		.io_uart_txe(stxe),
		.io_uart_rxf(srxf),
		.io_uart_wr(uart_wr),
		.io_uart_rd(uart_rd)
    );


endmodule