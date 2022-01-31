module lfsr (input clk, input reset, output [1:8] result);

	reg[1:8] QUEUE_OUT, QUEUE_NEXT;
	
	wire taps;
	
	always @(posedge clk) begin
		if(~reset) QUEUE_OUT <= 'd1; // Must be bigger than 'd0
		else QUEUE_OUT <= QUEUE_NEXT;
	end
	
	always @(taps, QUEUE_OUT) begin
		QUEUE_NEXT = {
			taps, 
			QUEUE_OUT[1:7]
		};
	end
	
	assign result = QUEUE_OUT;
	assign taps = QUEUE_OUT[8] ^ QUEUE_OUT[6] ^ QUEUE_OUT[5] ^ QUEUE_OUT[4];
endmodule 
