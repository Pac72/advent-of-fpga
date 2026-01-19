`default_nettype none
`timescale 1ns/1ns

module tb_part1;

    // clock & reset
    logic clk;
    logic rst_n;

    // DUT signals
    logic [7:0] data_in;
    logic data_valid;
    logic data_ack;
    logic [31:0] result;
    logic result_ready;
    logic error_clear;
    logic data_error;

    // last intermediate result is the final result
    integer last_result;

    // safety timeout stop after 1M cycles
    // it took some runs to get to the result :-)

    /* verilator lint_off PROCASSINIT */
    integer cycle_count = 0;
    parameter integer MAX_SIM_CYCLES = 1_000_000;

    parameter string INPUT_FILENAME = "input.txt";

    // Instantiate the DUT
    part1 dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_ack(data_ack),
        .result(result),
        .result_ready(result_ready),
        .error_clear(error_clear),
        .data_error(data_error)
    );

    // Clock generation (period 10 ns, frequency 100MHz)
    always #5 clk = ~clk;

    // Simulation timeout check
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count > MAX_SIM_CYCLES) begin
            $display("ERROR: simulation timed out after %d cycles.", MAX_SIM_CYCLES);
            $finish;
        end
    end

    // Error line check
    always @(posedge clk) begin
        if (data_error == 1'b1) begin
            $display("ERROR: data_error == 1 after %d cycles.", cycle_count);
            $finish;
        end
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_part1);
    end

    initial begin
        integer file_handle;
        integer char;

        $display("Starting simulation with input filename \"%s\"", INPUT_FILENAME);

        // initialize input signals
        clk = 1'b0;
        rst_n = 1'b1;
        data_valid = 1'b0;
        data_in = 8'h00;
        error_clear = 1'b0;

        // perform reset
        #10;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        @(posedge clk);

        // open input file with bank of batteries
        file_handle = $fopen(INPUT_FILENAME, "r");
        if (file_handle == 0) begin
            $display("ERROR: \"%s\" could not be opened.", INPUT_FILENAME);
            $finish;
        end

        $display("Reading from \"%s\" and sending to DUT...", INPUT_FILENAME);

        char = $fgetc(file_handle);
        while (char >= 0) begin

            // send data
            data_in = char[7:0];
            data_valid = 1'b1;

            // wait for acknowledge
            do @(posedge clk); while (!data_ack);

            // we expect an intermediate result at the end of the bank
            if (char == "\n") begin
                // another safety timeout - as told before,
                // it took a bit to get things working right...
                int max_wait_clk_count = 100;
                while (!result_ready) begin
                    @(posedge clk);
                    max_wait_clk_count--;
                end

                if (result_ready) begin
                    $display("INFO: Intermediate result: %d", result);
                    last_result = result;
                end else begin
                    $display("WARNING: timeout waiting for result_ready");
                end
            end

            // de-assert valid at the end of each digit but also
            // to clear result_ready
            data_valid = 1'b0;

            // wait for data_ack to be de-asserted before sending next byte
            do @(posedge clk); while (data_ack);

            // read next character
            char = $fgetc(file_handle);
        end

        $fclose(file_handle);

        $display("Simulation finished.");
        $display("Final result is: %d", last_result);

        $finish;
    end

endmodule
