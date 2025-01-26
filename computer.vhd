library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity computer is
  generic(K: integer := 8;
          W: integer := 8);
  port(
    CLOCK_50, RESET_N: in std_logic;
    -- KEY(0): start program
    -- KEY(1): if (state = idle) write to memory else next step
    -- KEY(2): address increment
    -- KEY(3): address decrement
    KEY: in std_logic_vector(3 downto 0);
    -- SW(9..8) mode (00: normal, 01: debug)
    -- SW(7..0) din
    SW: in std_logic_vector(9 downto 0);
    GPIO_1: inout std_logic_vector (35 downto 0);
    -- LEDR(0) clock
    LEDR: out std_logic_vector (9 downto 0);
    -- when idle:
    --  HEX(3..0) メモリ内容表示
    --  HEX(5..4) アドレス表示 (0x00 ~ 0xFF)
    -- else:
    --  HEX(5)    state
    --  HEX(4)    IR
    --  HEX(3..2) PC
    --  HEX(1..0) AC
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: out std_logic_vector(6 downto 0));
end computer;

architecture rtl of computer is
  -- CPU
  component cpu
    generic(K: integer;
            W: integer);
    port(
        clk, xrst, start, writem, incr, decr, mode, din: in std_logic;
        state: out std_logic_vector(3 downto 0);
        hx0, hx1, hx2, hx3, hx4, hx5: out std_logic_vector(3 downto 0);
    );
  end component;
  -- 7 segment decoder
  component seven_seg_decoder is
    port(clk: in std_logic;
         xrst: in std_logic;
         din: in  std_logic_vector(3 downto 0);
         dout: out std_logic_vector(6 downto 0));
  end component;
begin
  clk <= CLOCK_50;
  xrst <= RESET_N;
  k_start <= not KEY(0);
  k_write <= not KEY(1);
  k_incr <= not KEY(2);
  k_decr <= not KEY(3);
  sw_mode <= SW(9 downto 8);
  sw_din <= SW(7 downto 0);

  -- Display
  ssd_0: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx0, dout => HEX0);
  ssd_1: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx1, dout => HEX1);
  ssd_2: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx2, dout => HEX2);
  ssd_3: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx3, dout => HEX3);
  ssd_4: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx4, dout => HEX4);
  ssd_5: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => hx5, dout => HEX5);
  hx0 <= dout(3 downto 0)      when state = idle else ac1(3 downto 0);
  hx1 <= dout(7 downto 4)      when state = idle else ac1(7 downto 4);
  hx2 <= dout_prev(3 downto 0) when state = idle else pc(3 downto 0);
  hx3 <= dout_prev(7 downto 4) when state = idle else pc(7 downto 4);
  hx4 <= adr(3 downto 0)       when state = idle else ir(3 downto 0);
  hx5 <= adr(7 downto 4)       when state = idle else ir(7 downto 4);

  LEDR(3 downto 0) <= state_slv;
  
end rtl;

