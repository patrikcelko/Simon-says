module divider (input clk, input reset, output result);

    reg [31:0] CNTR;
    reg CLK_DIV;

 	always @(posedge clk) begin
		if(!reset || !CNTR) CNTR <= 15_000_000; // Every 0.5 sec.
		else CNTR <= CNTR - 1;
		
		if(CNTR == 1) CLK_DIV = 1;
		else CLK_DIV = 0;
	end
	
	assign result = CLK_DIV;
endmodule
