library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity digital_lock is
    Port( clk : in std_logic;
          btn : in std_logic_vector(3 downto 0);
          led_r : out std_logic;
          led_g : out std_logic;
          led_b : out std_logic);
end entity digital_lock;

architecture Behavioral of digital_lock is

    type state_type is (IN0, IN1, IN2, IN3, ERR, CORR);
    signal current_state, next_state : state_type;
    
    signal rst: std_logic;
    signal unlock: std_logic;
    signal btn_db: std_logic_vector(3 downto 0);
    signal btn_pulse: std_logic_vector(3 downto 0);
    signal rgb_reg: std_logic_vector(2 downto 0);
    signal alarm_rst_proc: std_logic;
    signal err_detected: std_logic;
    signal prev_rst: std_logic;
    
    component debounce is
        generic
        (
            clk_freq    : integer := 125_000_000;
            stable_time : integer := 10);
        port
        (
            clk    : in std_logic;
            rst    : in std_logic;
            button : in std_logic;
            result : out std_logic);
    end component;
    
    component single_pulse_detector is
        generic
        (
            detect_type: std_logic_vector(1 downto 0) := "00");
        port
        (
            clk          : in std_logic;
            rst          : in std_logic;
            input_signal : in std_logic;
            output_pulse : out std_logic);
    end component;
    
begin

    debounce_inst_0: debounce port map(clk => clk, rst => rst, button => btn(0), result => btn_db(0));
    debounce_inst_1: debounce port map(clk => clk, rst => rst, button => btn(1), result => btn_db(1));
    debounce_inst_2: debounce port map(clk => clk, rst => rst, button => btn(2), result => btn_db(2));
    debounce_inst_3: debounce port map(clk => clk, rst => rst, button => btn(3), result => btn_db(3));

    pulse_inst_0: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(0), output_pulse => btn_pulse(0));
    pulse_inst_1: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(1), output_pulse => btn_pulse(1));
    pulse_inst_2: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(2), output_pulse => btn_pulse(2));
    pulse_inst_3: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(3), output_pulse => btn_pulse(3));
    
    process(clk, rst, current_state)
    begin
        if rising_edge(clk) then
            case current_state is
                when IN0 =>
                    rgb_reg <= "100";
                    if (btn_pulse(1) = '1') then
                        next_state <= IN1;
                        unlock <= '0';
                    elsif (btn_pulse(0) = '1') then
                        prev_rst <= '1';
                        err_detected <= '1';
                        next_state <= IN1;
                    elsif (btn_pulse(2) = '1' or btn_pulse(3) = '1') then
                        err_detected <= '1';
                        next_state <= IN1;
                    end if;
                when IN1 =>
                    rgb_reg <= "000";
                    if (btn_pulse(2) = '1') then
                        next_state <= IN2;
                        unlock <= '0';
                    elsif (btn_pulse(0) = '1' and prev_rst = '1') then
                        prev_rst <= '0';
                        err_detected <= '0';
                        next_state <= IN0;
                    elsif (btn_pulse(0) = '1') then
                        prev_rst <= '1';
                        err_detected <= '1';
                        next_state <= IN2;
                    elsif (btn_pulse(1) = '1' or btn_pulse(3) = '1') then
                        err_detected <= '1';
                        next_state <= IN2;
                    end if;
                when IN2 =>
                    rgb_reg <= "000";
                    if (btn_pulse(0) = '1' and prev_rst = '1') then
                        prev_rst <= '0';
                        err_detected <= '0';
                        next_state <= IN0;
                    elsif (btn_pulse(0) = '1') then
                        prev_rst <= '1';
                        next_state <= IN3;
                        unlock <= '0';
                    elsif (btn_pulse(1) = '1' or btn_pulse(2) = '1' or btn_pulse(3) = '1') then
                        err_detected <= '1';
                        next_state <= IN3;
                    end if;
                when IN3 =>
                    rgb_reg <= "000";
                    if (btn_pulse(2) = '1' and err_detected = '0') then
                        next_state <= CORR;
                        unlock <= '1';
                    elsif (btn_pulse(0) = '1' and prev_rst = '1') then
                        prev_rst <= '0';
                        err_detected <= '0';
                        next_state <= IN0;
                    elsif (btn_pulse(0) = '1') then
                        prev_rst <= '1';
                        err_detected <= '1';
                        next_state <= ERR;
                    elsif (btn_pulse(1) = '1' or btn_pulse(2) = '1' or btn_pulse(3) = '1') then
                        err_detected <= '1';
                        next_state <= ERR;
                    end if;
                when CORR =>
                    rgb_reg <= "010";
                    if (btn_pulse(0) = '1' or btn_pulse(1) = '1' or btn_pulse(2) = '1' or btn_pulse(3) = '1') then
                        next_state <= IN0;
                    end if;
                when ERR =>
                    rgb_reg <= "001";
                    if (btn_pulse(2) = '1') then
                        alarm_rst_proc <= '1';
                    end if;
                    if (btn_pulse(0) = '1' and alarm_rst_proc = '1') then
                        err_detected <= '0';
                        alarm_rst_proc <= '0';
                        next_state <= IN0;
                    elsif ((btn_pulse(1) = '1' or btn_pulse(2) = '1' or btn_pulse(3) = '1') and alarm_rst_proc = '1') then
                        alarm_rst_proc <= '0';
                        next_state <= current_state;
                    end if;
            end case;
            current_state <= next_state;
        end if;
    end process;
    
    led_r <= rgb_reg(0);
    led_g <= rgb_reg(1);
    led_b <= rgb_reg(2);
    
end Behavioral;
