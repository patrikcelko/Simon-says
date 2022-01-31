module simon(input CLOCK_50, output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2, output [6:0] HEX3,
	output [6:0] HEX4, output [6:0] HEX5, input [3:0] KEY, output [9:0] LEDR, input [9:0] SW);
	
	wire half_sec;
	wire reset;
	wire [1:8] random_number;

	reg NO_LED_DELAY, IS_PRESSED, SHOW_LEVEL, SHOW_TIMER;
	
	reg [3:0] SEGMENT1;
	reg [3:0] SEGMENT2;
	reg [3:0] SEGMENT3;
	reg [3:0] SEGMENT4;
	
	reg [9:0] LEDS;
	reg [1:0] SAVED_ORDER[0:9]; // 10 x 2 bits
	
	reg [3:0] STATUS;
	
//=========================================================
//	STATUS:
//			000 - Loading game
//			001 - Generating game
//			010 - Waiting for the timer to start
//			011 - The timer started, waiting for player input
//			100 - FAIL (Restart)
//			111 - OK (Next level)
//=========================================================
	
	integer LEVEL, TIME, SAVED_COUNTER, LOADED_COUNTER, GAME_DELAY, MODULATED_RANDOM;
	
//=========================================================	
//	LEVELS:
//			(LEVEL 01 - 04) -> 4-leds - 17s - 3x delay
//			(LEVEL 05 - 09) -> 5-leds - 15s - 3x delay
//			(LEVEL 10 - 14) -> 6-leds - 13s - 2x delay
//			(LEVEL 15 - 19) -> 7-leds - 11s - 2x delay
//			(LEVEL 20 - 24) -> 8-leds - 09s - 1x delay
//			(LEVEL 25 - 29) -> 9-leds - 07s - 1x delay
//			(LEVEL 30 - Infinity) -> 10-leds - 05s - 1x delay	
//=========================================================
	
	assign reset = SW[0];
	assign LEDR[9:0] = LEDS[9:0];
	
	divider divider_half_sec (CLOCK_50, reset, half_sec);
	lfsr random_generator (CLOCK_50, reset, random_number);
	
	segment segment_part1 (SEGMENT1[3:0], HEX0);
	segment segment_part2 (SEGMENT2[3:0], HEX1);
	segment segment_part3 (SEGMENT3[3:0], HEX2);
	segment segment_part4 (SEGMENT4[3:0], HEX3);
	
	segment segment_part5 (4'hF, HEX4);
	segment segment_part6 (4'hF, HEX5); 
	
	always@(posedge CLOCK_50) begin
		if(!SW[0]) begin // Off | Reset
			LEVEL <= 'd0;
			STATUS <= 'b000;
			
			SHOW_LEVEL <= 1;
			SHOW_TIMER <= 0;
			
			SEGMENT1[3:0] <= 4'hF;
			SEGMENT2[3:0] <= 4'hF;
			SEGMENT3[3:0] <= 4'hF;
			SEGMENT4[3:0] <= 4'hF;
			
			LEDS[3:0] <= 'b0000;
		end
		else if(STATUS == 'b100) begin // Fail
			SEGMENT1[3:0] <= 4'hd; 
			SEGMENT2[3:0] <= 4'hC;
			SEGMENT3[3:0] <= 4'hb;
			SEGMENT4[3:0] <= 4'hA;
		end
		else if(SHOW_LEVEL) begin // Show level
			SEGMENT1[3:0] <= LEVEL % 'd10;
			SEGMENT2[3:0] <= (LEVEL / 'd10) % 'd10;
			SEGMENT3[3:0] <= 4'hd;
			SEGMENT4[3:0] <= 4'hF;
		end
		else if(SHOW_TIMER) begin // Show timer
			SEGMENT1[3:0] <= TIME % 'd10;
			SEGMENT2[3:0] <= (TIME / 'd10) % 'd10;
			SEGMENT3[3:0] <= 4'hF;
			SEGMENT4[3:0] <= 4'hF;
		end
		
		if(STATUS == 'b011 && KEY[0] && KEY[1] && KEY[2] && KEY[3]) begin
			IS_PRESSED <= 0;
			LEDS[3:0] <= 'b0000; // Reset after releas
		end
		
		if(!IS_PRESSED && STATUS == 'b011 && (!KEY[0] || !KEY[1] || !KEY[2] || !KEY[3])) begin
			IS_PRESSED <= 1;
			if(!KEY[SAVED_ORDER[LOADED_COUNTER]]) begin
				LOADED_COUNTER <= LOADED_COUNTER + 'd1;
				LEDS[SAVED_ORDER[LOADED_COUNTER]] <= 1;
			end
			else begin
				STATUS <= 'b100; // Wrong button
				GAME_DELAY <= 'd3;
			end
		end
		
		if(LOADED_COUNTER >= SAVED_COUNTER && STATUS == 'b011) begin
			STATUS <= 'b111; // All buttons were correctly pressed
			GAME_DELAY <= 'd1;
		end	
		
		if(STATUS == 'b010) begin // Creating timer for level
			TIME <= 'd17 - ((LEVEL / 'd5) * 'd2);
			SHOW_LEVEL <= 0;
			SHOW_TIMER <= 1;
			STATUS <= 'b011;
		end
		
		if(STATUS == 'b011 && TIME <= 'd0) begin // Time out
			STATUS <= 'b100;
			GAME_DELAY <= 'd4;
		end
		
		if(half_sec) begin
			case(STATUS)
				'b000: begin // Loading level
					if(LEDS[3:0] == 'b1111) begin
						if(LEVEL <= 'd30) LEVEL <= LEVEL + 1;
						
						LEDS[3:0] <= 'b0000;
						STATUS <= 'b001;
						
						NO_LED_DELAY <= 0; 
						SAVED_COUNTER <= 'd0;
						LOADED_COUNTER <= 'd0;
						GAME_DELAY <= 'd0;
					end 
					else begin
						LEDS <= LEDS << 1;
						LEDS[0] <= 1;
					end
				end
				'b001: begin // Generating game
					if(NO_LED_DELAY) LEDS[3:0] <= 'b0000;
				
					if(GAME_DELAY <= 'd0 && !NO_LED_DELAY) begin
						GAME_DELAY <= 'd3 - (LEVEL / 'd10);
						NO_LED_DELAY <= 1; // Delay between blinks
						
						if(SAVED_COUNTER < ((LEVEL / 5) + 'd4)) begin
							MODULATED_RANDOM <= random_number[1:8] % 'd4; 		
							LEDS[MODULATED_RANDOM] <= 1;
							SAVED_ORDER[SAVED_COUNTER] <= MODULATED_RANDOM[2:0];	
							SAVED_COUNTER <= SAVED_COUNTER + 'd1;
						end
						else STATUS <= 'b010; // All inputs were generated
					end
					else begin
						NO_LED_DELAY <= 0;
						GAME_DELAY <= GAME_DELAY - 'd1;
					end
				end
				'b011: begin // Waiting for player input
					if(GAME_DELAY <= 'd0) begin
						TIME <= TIME - 'd1;
						GAME_DELAY <= 'd2;
					end
					else GAME_DELAY <= GAME_DELAY - 'd1;
				end
				default: begin // Fail | OK
					if(GAME_DELAY <= 'd0) begin
						if(STATUS == 'b100) LEVEL <= 'd0;
					
						SHOW_LEVEL <= 1;
						SHOW_TIMER <= 0;
						GAME_DELAY <= 'd0;
				
						LEDS[3:0] <= 'b0000;
						STATUS <= 'b000;
					end
					else GAME_DELAY <= GAME_DELAY - 'd1;
				end
			endcase
		end
	end
endmodule
