library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity part1 is
    port (
        clk          : in std_logic;
        rst_n        : in std_logic;
        data_in      : in std_logic_vector(7 downto 0);
        data_valid   : in std_logic;
        data_ack     : out std_logic;
        result       : out std_logic_vector(31 downto 0);
        result_ready : out std_logic;
        data_error   : out std_logic;
        error_clear  : in std_logic
    );
end entity;

architecture rtl of part1 is
    type state is (
        S_EXPECT_DIGIT,
        S_EXPECT_DIGIT_OR_EOL,
        S_PROCESS,
        S_PROCESS_ACK,
        S_PREPARE_UPDATE_RESULT,
        S_RESULT_READY,
        S_ERROR
    );

    constant ASCII_NEWLINE : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(character'pos(LF), 8));
    constant ASCII_0 : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(character'pos('0'), 8));
    constant ASCII_9 : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(character'pos('9'), 8));

    signal bin_data_in : integer;
    signal current_state, next_state : state;
    signal current_result : integer;

    signal max1 : integer;
    signal max2 : integer;
    signal saved_max1 : integer;
    signal saved_max2 : integer;
    signal saved_data_in : integer;
    signal max1_just_found : std_logic;

    signal temp_result : integer;

    signal is_ascii_digit : boolean;
    signal is_terminator : boolean;

begin
    is_terminator <= data_in = ASCII_NEWLINE;
    is_ascii_digit <= ((unsigned(data_in) >= unsigned(ASCII_0)) and (unsigned(data_in) <= unsigned(ASCII_9)));
    bin_data_in <= to_integer(unsigned(data_in) - unsigned(ASCII_0));
    result <= std_logic_vector(to_unsigned(current_result, result'length));

    p_fsm_status_update: process(clk, rst_n)
    begin
        if (falling_edge(rst_n)) then
            data_error <= '0'; 
            current_state <= S_EXPECT_DIGIT;
        elsif (rising_edge(clk)) then
            if (next_state = S_ERROR) then
                data_error <= '1';
            else
                data_error <= '0';
            end if;
            current_state <= next_state;
        end if;
    end process;

    p_temp_result_comb: process(max1, max2, max1_just_found, saved_max1, saved_max2, saved_data_in)
    begin
        temp_result <= max1 * 10 + max2;
        
        if (max1_just_found = '1') then
            if (saved_data_in > max2) then
                temp_result <= saved_max1 * 10 + saved_data_in;
            else
                temp_result <= saved_max1 * 10 + saved_max2;
            end if;
        end if;
    end process;

    p_fsm_comb: process(current_state, data_valid, is_ascii_digit, is_terminator, error_clear)
    begin
        case current_state is
            when S_EXPECT_DIGIT =>
                data_ack <= '0'; result_ready <= '0';
                if (data_valid = '1') then
                    if (is_ascii_digit) then
                        next_state <= S_PROCESS;
                    else
                        next_state <= S_ERROR;
                    end if;
                end if;

            when S_EXPECT_DIGIT_OR_EOL =>
                data_ack <= '0'; result_ready <= '0';
                if (data_valid = '1') then
                    if (is_ascii_digit) then
                        next_state <= S_PROCESS;
                    elsif (is_terminator) then
                        next_state <= S_PREPARE_UPDATE_RESULT;
                    else
                        next_state <= S_ERROR;
                    end if;
                end if;

            when S_PROCESS =>
                data_ack <= '0'; result_ready <= '0';
                next_state <= S_PROCESS_ACK;

            when S_PROCESS_ACK =>
                data_ack <= '1'; result_ready <= '0';
                if (data_valid = '0') then
                    next_state <= S_EXPECT_DIGIT_OR_EOL;
                end if;

            when S_PREPARE_UPDATE_RESULT =>
                data_ack <= '0'; result_ready <= '0';
                next_state <= S_RESULT_READY;

            when S_RESULT_READY =>
                data_ack <= '1'; result_ready <= '1';
                if (data_valid = '0') then
                    next_state <= S_EXPECT_DIGIT;
                end if;

            when S_ERROR =>
                data_ack <= '0'; result_ready <= '0';
                if (error_clear = '1') then
                    next_state <= S_EXPECT_DIGIT;
                end if;

            when others =>
                data_ack <= '0'; result_ready <= '0';
                next_state <= S_EXPECT_DIGIT;
        end case;
    end process;

    p_fsm_seq: process(clk, rst_n)
    begin
        if (falling_edge(rst_n)) then
            max1 <= -1;
            max2 <= -1;
            saved_max1 <= -1;
            saved_max2 <= -1;
            saved_data_in <= -1;
            max1_just_found <= '0';
            current_result <= 0;
        elsif (rising_edge(clk)) then
            case current_state is
                when S_EXPECT_DIGIT =>
                    -- nothing to do

                when S_EXPECT_DIGIT_OR_EOL =>
                    -- nothing to do

                when S_PROCESS =>
                    max1_just_found <= '0';
                    if (bin_data_in > max1) then
                        saved_max1 <= max1;
                        saved_max2 <= max2;
                        saved_data_in <= bin_data_in;
                        max1 <= bin_data_in;
                        max2 <= -1;
                        max1_just_found <= '1';
                    elsif (bin_data_in > max2) then
                        max2 <= bin_data_in;
                    end if;

                when S_PROCESS_ACK =>
                    -- nothing to do

                when S_PREPARE_UPDATE_RESULT =>
                    current_result <= current_result + temp_result;

                when S_RESULT_READY =>
                    max1 <= -1;
                    max2 <= -1;
                    saved_max1 <= -1;
                    saved_max2 <= -1;
                    saved_data_in <= -1;
                    max1_just_found <= '0';

                when S_ERROR =>
                    -- nothing to do

                when others =>
                    -- nothing to do

            end case;
        end if;
    end process;

end architecture rtl;
