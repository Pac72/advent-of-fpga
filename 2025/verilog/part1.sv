`default_nettype none
`timescale 1ns/1ns

module part1 (
    // clock & reset
    input logic clk,
    input logic rst_n,

    // input data management
    input logic [7:0] data_in,
    input logic data_valid,
    output logic data_ack,

    // result management
    output logic [31:0] result,
    output logic result_ready,

    // basic error management
    output logic data_error,
    input logic error_clear
);

    // FSM states
    typedef enum logic [2:0] {
        S_EXPECT_DIGIT          = 0,
        S_EXPECT_DIGIT_OR_EOL   = 1,
        S_PROCESS               = 2,
        S_PROCESS_ACK           = 3,
        S_PREPARE_UPDATE_RESULT = 4,
        S_RESULT_READY          = 5,
        S_ERROR                 = 6
    } state_t /* verilator public */;

    // constants
    localparam logic [7:0] ASCII_NEWLINE = "\n";
    localparam logic [7:0] ASCII_0 = "0";
    localparam logic [7:0] ASCII_9 = "9";

    /*
     * internal registers
     */

    // data_in traslated to decimal: '0' -> 0, ... '9' -> 9
    int bin_data_in;

    // current and next state for the FSM
    state_t current_state, next_state;

    // sum of all intermediate results since reset
    int current_result;

    // algorithm variables
    int max1;
    int max2;
    int saved_max1;
    int saved_max2;
    int saved_data_in;
    logic max1_just_found;

    // temporary result; computed with combinatorial logic
    int temp_result;

    // input is a valid ascii digit (an ASCII char in range '0'..'9')
    wire is_ascii_digit;
    wire is_terminator;

    // the following help simulation and should be synthesizable on FPGAs
    // the values are the same as the ones in reset
    initial current_state = S_EXPECT_DIGIT;
    initial current_result = 0;
    initial max1 = -1;
    initial max2 = -1;
    initial saved_max1 = -1;
    initial saved_max2 = -1;
    initial saved_data_in = -1;
    initial max1_just_found = 1'b0;

    // helper assignments
    assign is_terminator = data_in == ASCII_NEWLINE;
    assign is_ascii_digit = (data_in >= ASCII_0 && data_in <= ASCII_9);
    assign bin_data_in = int'(data_in) - int'(ASCII_0);
    assign result = current_result;

    // combinatorial logic to compute temp_result
    always_comb begin
        temp_result = max1 * 10 + max2;

        if (max1_just_found) begin
            if (saved_data_in > max2) begin
                temp_result = saved_max1 * 10 + saved_data_in;
            end else begin
                temp_result = saved_max1 * 10 + saved_max2;
            end
        end
    end

    // FSM - state update
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            data_error <= 1'b0;
            current_state <= S_EXPECT_DIGIT;
            current_result <= 0;
        end else begin
            data_error <= next_state == S_ERROR;
            current_state <= next_state;
        end
    end

    // FSM - combinatorial logic
    // compute
    //  - next_state
    //  - data_ack
    //  - result_ready
    always_comb begin
        next_state = current_state;
        data_ack = 1'b0;
        result_ready = 1'b0;

        unique case (current_state)
            S_EXPECT_DIGIT: begin
                if (data_valid) begin
                    if (is_ascii_digit) begin
                        next_state = S_PROCESS;
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end

            S_EXPECT_DIGIT_OR_EOL: begin
                if (data_valid) begin
                    if (is_ascii_digit) begin
                        next_state = S_PROCESS;
                    end else if (is_terminator) begin
                        next_state = S_PREPARE_UPDATE_RESULT;
                    end else begin
                        next_state = S_ERROR;
                    end
                end
            end

            S_PROCESS: begin
                next_state = S_PROCESS_ACK;
            end

            S_PROCESS_ACK: begin
                data_ack = 1'b1;
                if (!data_valid) begin
                    next_state = S_EXPECT_DIGIT_OR_EOL;
                end
            end

            S_PREPARE_UPDATE_RESULT: begin
                next_state = S_RESULT_READY;
            end

            S_RESULT_READY: begin
                data_ack = 1'b1;
                result_ready = 1'b1;
                if (!data_valid) begin
                    next_state = S_EXPECT_DIGIT;
                end
            end

            S_ERROR: begin
                if (error_clear) begin
                    next_state = S_EXPECT_DIGIT;
                end
            end

            default: begin
                next_state = S_EXPECT_DIGIT;
            end
        endcase
    end

    // FSM - sequential logic - update registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_result <= 0;
            max1 <= -1;
            max2 <= -1;
            saved_max1 <= -1;
            saved_max2 <= -1;
            saved_data_in <= -1;
            max1_just_found <= 1'b0;
        end else begin
            unique case (current_state)
                S_EXPECT_DIGIT: begin
                    // nothing to do
                end

                S_EXPECT_DIGIT_OR_EOL: begin
                    // nothing to do
                end

                S_PROCESS: begin
                    max1_just_found <= 1'b0;
                    if (bin_data_in > max1) begin
                        saved_max1 <= max1;
                        saved_max2 <= max2;
                        saved_data_in <= bin_data_in;
                        max1 <= bin_data_in;
                        max2 <= -1;
                        max1_just_found <= 1'b1;
                    end else if (bin_data_in > max2) begin
                        max2 <= bin_data_in;
                    end
                end

                S_PROCESS_ACK: begin
                    // nothing to do
                end

                S_PREPARE_UPDATE_RESULT: begin
                    current_result <= current_result + temp_result;
                end

                S_RESULT_READY: begin
                    max1 <= -1;
                    max2 <= -1;
                    saved_max1 <= -1;
                    saved_max2 <= -1;
                    saved_data_in <= -1;
                    max1_just_found <= 1'b0;
                end

                S_ERROR: begin
                    // nothing to do
                end

                default: begin
                    // nothing to do
                end
            endcase
        end
    end
endmodule;
