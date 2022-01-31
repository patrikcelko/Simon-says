module segment (input [3:0] data, output reg [6:0] seg);
	
	always @(data) begin
		case (data)
			4'h0: 
				seg = 7'b1000000; // Number - 0
			4'h1:
				seg = 7'b1111001; // Number - 1
			4'h2:
				seg = 7'b0100100; // Number - 2
			4'h3:
				seg = 7'b0110000; // Number - 3
			4'h4: 
				seg = 7'b0011001; // Number - 4
			4'h5: 
				seg = 7'b0010010; // Number - 5
			4'h6: 
				seg = 7'b0000010; // Number - 6
			4'h7: 
				seg = 7'b1111000; // Number - 7
			4'h8: 
				seg = 7'b0000000; // Number - 8
			4'h9: 
				seg = 7'b0010000; // Number - 9
			4'hA:
				seg = 7'b0001110; // Letter - F
			4'hb:
				seg = 7'b0001000; // Letter - A
			4'hC:
				seg = 7'b1001111; // Letter - I
			4'hd:
				seg = 7'b1000111; // Letter - L
			default:
				seg = 7'b1111111; // Default off
		endcase
	end
endmodule
