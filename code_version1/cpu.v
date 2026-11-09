
module cpu #(
    parameter MEM_FILE = "program.hex"
)(
    input         clk,
    input         reset,
    input  [31:0] io_in,
    output reg [31:0] io_out,
    output reg    halted
);

    // ------------------------------------------------
    // 4K x 16-bit unified memory
    // ------------------------------------------------
    reg [15:0] mem [0:255];

    // 16 general-purpose registers
    reg [15:0] regfile [0:15];

    // CPU control
    reg [11:0] pc;
    reg [11:0] rar;     // Return Address Register
    reg [15:0] ir;      // Instruction Register
    reg [1:0]  state;

    localparam FETCH   = 2'd0;
    localparam DECODE  = 2'd1;
    localparam EXECUTE = 2'd2;

    integer i;

    // ------------------------------------------------
    // Memory initialization
    // ------------------------------------------------
    initial begin
        $readmemh(MEM_FILE, mem);
    end

    // ------------------------------------------------
    // Three-stage FSM: FETCH / DECODE / EXECUTE
    // ------------------------------------------------
    always @(posedge clk) begin

        if (reset) begin
            pc     <= 12'd0;
            rar    <= 12'd0;
            ir     <= 16'd0;
            io_out <= 32'd0;
            halted <= 1'b0;
            state  <= FETCH;

            for (i = 0; i < 16; i = i + 1)
                regfile[i] <= 16'd0;
        end

        else if (!halted) begin

            // R0 is always zero
            regfile[0] <= 16'd0;

            case (state)

                // ------------------------------------
                // FETCH
                // Read instruction and advance PC
                // ------------------------------------
                FETCH: begin
                    ir    <= mem[pc];
                    pc    <= pc + 12'd1;
                    state <= DECODE;
                end

                // ------------------------------------
                // DECODE
                // Instruction decode stage
                // ------------------------------------
                DECODE: begin
                    state <= EXECUTE;
                end

                // ------------------------------------
                // EXECUTE
                // ------------------------------------
                EXECUTE: begin

                    case (ir[15:12])

                        // ADD Rd, Rs, Rt
                        4'h0: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    regfile[ir[7:4]] +
                                    regfile[ir[3:0]];

                            state <= FETCH;
                        end

                        // SUB Rd, Rs, Rt
                        4'h1: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    regfile[ir[7:4]] -
                                    regfile[ir[3:0]];

                            state <= FETCH;
                        end

                        // AND Rd, Rs, Rt
                        4'h2: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    regfile[ir[7:4]] &
                                    regfile[ir[3:0]];

                            state <= FETCH;
                        end

                        // OR Rd, Rs, Rt
                        4'h3: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    regfile[ir[7:4]] |
                                    regfile[ir[3:0]];

                            state <= FETCH;
                        end

                        // ADDI Rd, Rs, signed imm4
                        4'h4: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    regfile[ir[7:4]] +
                                    {{12{ir[3]}}, ir[3:0]};

                            state <= FETCH;
                        end

                        // LDI Rd, imm8 (zero-extended)
                        4'h5: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    {8'd0, ir[7:0]};

                            state <= FETCH;
                        end

                        // LD Rd, [Rs]
                        4'h6: begin
                            if (ir[11:8] != 4'd0)
                                regfile[ir[11:8]] <=
                                    mem[regfile[ir[7:4]][11:0]];

                            state <= FETCH;
                        end

                        // ST Rd, [Rs]
                        // Store Rd at address in Rs
                        4'h7: begin
                            mem[regfile[ir[7:4]][11:0]] <=
                                regfile[ir[11:8]];

                            state <= FETCH;
                        end

                        // JMP absolute_address
                        4'h8: begin
                            pc    <= ir[11:0];
                            state <= FETCH;
                        end

                        // CALL absolute_address
                        // RAR saves return address
                        4'h9: begin
                            rar   <= pc;
                            pc    <= ir[11:0];
                            state <= FETCH;
                        end

                        // RET
                        4'hA: begin
                            pc    <= rar;
                            state <= FETCH;
                        end

                        // BEQZ Rd, signed offset8
                        // Offset relative to incremented PC
                        4'hB: begin
                            if (regfile[ir[11:8]] == 16'd0)
                                pc <= pc +
                                      {{4{ir[7]}}, ir[7:0]};

                            state <= FETCH;
                        end

                        // BNEZ Rd, signed offset8
                        4'hC: begin
                            if (regfile[ir[11:8]] != 16'd0)
                                pc <= pc +
                                      {{4{ir[7]}}, ir[7:0]};

                            state <= FETCH;
                        end

                        // IN Rd, port
                        4'hD: begin
                            if (ir[11:8] != 4'd0) begin

                                case (ir[1:0])

                                    2'd0:
                                        regfile[ir[11:8]] <=
                                            {8'd0, io_in[7:0]};

                                    2'd1:
                                        regfile[ir[11:8]] <=
                                            {8'd0, io_in[15:8]};

                                    2'd2:
                                        regfile[ir[11:8]] <=
                                            {8'd0, io_in[23:16]};

                                    2'd3:
                                        regfile[ir[11:8]] <=
                                            {8'd0, io_in[31:24]};

                                endcase
                            end

                            state <= FETCH;
                        end

                        // OUT Rd, port
                        4'hE: begin

                            case (ir[1:0])

                                2'd0:
                                    io_out[7:0] <=
                                        regfile[ir[11:8]][7:0];

                                2'd1:
                                    io_out[15:8] <=
                                        regfile[ir[11:8]][7:0];

                                2'd2:
                                    io_out[23:16] <=
                                        regfile[ir[11:8]][7:0];

                                2'd3:
                                    io_out[31:24] <=
                                        regfile[ir[11:8]][7:0];

                            endcase

                            state <= FETCH;
                        end

                        // HALT
                        4'hF: begin
                            halted <= 1'b1;
                        end

                        default: begin
                            state <= FETCH;
                        end

                    endcase
                end

                default: begin
                    state <= FETCH;
                end

            endcase
        end
    end

endmodule
