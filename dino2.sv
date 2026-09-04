`timescale 1ns / 1ps

module lfsr_generator(
    input clk,
    input enable,
    output spawn_obstacle
);

reg [7:0] lfsr = 8'b1001_1001;
reg [1:0] spawn_counter = 1'b0;
wire lfsr_next_bit;
assign lfsr_next_bit = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
assign spawn_obstacle = (lfsr[1:0] == 2'b11) && (spawn_counter < 2'd2);

always @(posedge clk) begin
    if (enable) begin
        lfsr <= (lfsr << 1) | lfsr_next_bit;
        if (spawn_obstacle) begin
            spawn_counter <= spawn_counter + 1;
        end else begin
            spawn_counter <= 2'b00;
        end
    end
end
endmodule


module game_core(
    input clk,
    input restart,
    input tick,
    input btn_jump,
    input spawn_obstacle,
    output reg [7:0] obstacle_line,
    output reg dino_y,
    output collision
);

reg [3:0] jump_time;
assign collision = (obstacle_line[6] == 1'b1) && (dino_y == 1'b0);

always @(posedge clk) begin
    if (restart) begin
        obstacle_line <= 8'b0;
        dino_y <= 1'b0;
        jump_time <= 1'b0;
    end else if (tick) begin
        obstacle_line <= (obstacle_line << 1) | spawn_obstacle;
        if (!dino_y && btn_jump) begin
            dino_y <= 1'b1;
            jump_time <= 1'b0;
        end else if (dino_y) begin
            if (jump_time == 2) begin
                dino_y <= 1'b0;
                jump_time <= 1'b0;
            end else
                jump_time <= jump_time +1'b1;
        end
    end
end
endmodule


module number_display(
    input points_display,
    input [3:0] number,
    output [7:0] dig
);
reg[7:0] out = 0;
always @(*) begin
    if (points_display) begin
    case (number)
        0: out = 8'b0011_1111;
        1: out = 8'b0000_0110;
        2: out = 8'b0101_1011;
        3: out = 8'b0100_1111;
        4: out = 8'b0110_0110;
        5: out = 8'b0110_1101;
        6: out = 8'b0111_1101;
        7: out = 8'b0000_0111;
        8: out = 8'b0111_1111;
        9: out = 8'b0110_1111;
        default: out = 8'b1000_0000;
    endcase
    end
end
assign dig = out;
endmodule


module display_change(
    input [1:0] sw,
    input [1:0] state,
    input [7:0] obstacle_line,
    input dino_y,
    output reg [7:0] dig3,
    output reg [7:0] dig2,
    output reg [7:0] dig1,
    output reg [7:0] dig0
);
wire points_display;
assign points_display = sw[0];
    input [3:0] sw,
    output [7:0] dig3,
    output [7:0] dig2,
    output [7:0] dig1,
    output [7:0] dig0
);
 
reg [1:0] state_cur = 2'b00;
reg [1:0] state_next;
reg [31:0] counter = 0;
wire tick;
assign tick = (counter == 32'd6_000_000);

reg [3:0] end_timer = 0;
wire end_delay;
assign end_delay = (end_timer >= 4'd4);

reg [15:0] score = 0;

always @(posedge clk) begin
    if (state_cur == 2'b01) begin
        if (tick)
            counter <= 0;
        else
            counter <= counter + 1'b1;
    end else begin
        counter <= 0;
        end
    state_cur <= state_next;
    if (state_cur == 2'b10) begin
        if (tick && !end_delay)
            end_timer <= end_timer + 1'b1;
    end else begin
            end_timer <= 0;
        end
end

wire spawn_obstacle;
wire [7:0] obstacles;
wire dino_y;
wire collision;
wire game_restart;

assign game_restart = (state_cur == 2'b00);

always @(*) begin
    state_next = state_cur;
    case (state_cur)
        2'b00: begin
            if (| (~btn))
                state_next = 2'b01;
        end
        2'b01: begin
            if (collision)
                state_next = 2'b10;
        end
        2'b10: begin
            if ((| (~btn)) && end_delay)

                state_next = 2'b00;
        end
        default: state_next = 2'b00;
    endcase
end

lfsr_generator random(
    .clk(clk),
    .enable(tick && (state_cur == 2'b01)),
    .spawn_obstacle(spawn_obstacle)
);

game_core core(
    .clk(clk),
    .restart(game_restart),
    .tick(tick),
    .btn_jump(~btn[0]),
    .spawn_obstacle(spawn_obstacle),
    .obstacle_line(obstacles),
    .dino_y(dino_y),
    .collision(collision)
);

display_change display(
    .state(state_cur),
    .obstacle_line(obstacles),
    .dino_y(dino_y),
    .dig3(dig3),
    .dig2(dig2),
    .dig1(dig1),
    .dig0(dig0)
);

endmodule