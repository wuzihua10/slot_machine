module RISC16_DE0_NANO (
    input        CLOCK_50,
    input  [1:0] KEY,
    input  [3:0] SW,
    output [7:0] LED,
    output [6:0] seg0, seg1, seg2
);

    wire [31:0] io_in;
    wire [31:0] io_out;
    wire        halted;

    // Port 0: SW[3:0]
    // Port 1-3: currently tied to zero
    assign io_in = {28'd0, SW[3:0]};

    // DE0-Nano pushbuttons are active-low.
    // Press KEY[0] to reset the CPU.
    risc16_cpu #(
        .MEM_FILE("program_slot_machine.hex")
    ) cpu (
        .clk    (CLOCK_50),
        .reset  (~KEY[0]),
        .io_in  (io_in),
        .io_out (io_out),
        .halted (halted)
    );

    assign seg0 = (KEY[0] == 1'b0)? 7'h1C: io_out[6:0];
    assign seg1 = (KEY[0] == 1'b0)? 7'h10: io_out[14:8];
    assign seg2 = (KEY[0] == 1'b0)? 7'h7F: io_out[22:16];
    assign LED  = io_out[31:24];

endmodule
