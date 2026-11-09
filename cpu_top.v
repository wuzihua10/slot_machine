module cpu_top (
    input        CLOCK_50,
    input  [1:0] KEY,
    input  [3:0] SW,
    output [7:0] seg0,
	 output [7:0] seg1, 
	 output [7:0] seg2, 
	 output [7:0] led
);

    wire [31:0] io_in;
    wire [31:0] io_out;
    wire        halted;

    // Port 0: SW[3:0]
    // Port 1-3: Currently tied to zero
    assign io_in = {24'd0, 4'd0, SW};

    // DE0-Nano pushbuttons are active-low.
    // Press KEY[0] to reset the CPU.
    cpu #(
        .MEM_FILE ("program.hex")
    ) cpu (
        .clk     (CLOCK_50),
        .reset   (~KEY[0]),
        .io_in   (io_in),
        .io_out  (io_out),
        .halted  (halted)
    );

    // Port 0 drives the eight LEDs.
    assign seg0 = io_out[7:0];
	 assign seg1 = io_out[15:8];
	 assign seg2 = io_out[23:16]; 
	 assign led  = io_out[31:24]; 

endmodule
