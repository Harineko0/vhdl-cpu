library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity display is
  port(
    CLOCK_50, RESET_N: in std_logic;
    -- KEY(0): start button
    -- KEY(2): write enable
    -- KEY(3): address increment
    KEY: in std_logic_vector(3 downto 0);
    -- SW(9): shuffle clock speed
    -- SW(7 downto 6): mode
    -- SW(3 downto 0): din
    SW: in std_logic_vector(9 downto 0);
    -- GPIO_1(3 downto 0): data bits
    -- GPIO_1(4): start bit
    -- GPIO_1(5) ready bit
    GPIO_1: inout std_logic_vector (35 downto 0);
    -- LEDR(9 dowto 6): clock speed indicator
    LEDR: out std_logic_vector (9 downto 0);
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: out std_logic_vector(6 downto 0));
    -- HEX5: clock speed indicator
end display;

architecture rtl of display is
  signal clk, xrst: std_logic;
  -- 7セグメントデコーダ
  component seven_seg_decoder is
    port(clk: in std_logic;
         xrst: in std_logic;
         din: in  std_logic_vector(3 downto 0);
         dout: out std_logic_vector(6 downto 0));
  end component;
begin
  clk <= CLOCK_50;
  xrst <= RESET_N;

  ssd_gpio1: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(3 downto 0), dout => HEX0);
  ssd_gpio2: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(7 downto 4), dout => HEX1);
  ssd_gpio3: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(11 downto 8), dout => HEX2);
  ssd_gpio4: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(15 downto 12), dout => HEX3);
  ssd_gpio5: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(19 downto 16), dout => HEX4);
  ssd_gpio6: seven_seg_decoder port map(clk => CLOCK_50, xrst => RESET_N, din => GPIO_1(23 downto 20), dout => HEX5);
end rtl;

