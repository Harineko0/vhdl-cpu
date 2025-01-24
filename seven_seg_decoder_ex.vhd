library ieee;
use ieee.std_logic_1164.all;

entity seven_seg_decoder_ex is
  port(clk: in std_logic;
        xrst: in std_logic;
        -- 0b000000 ~ 0b001111: 0 ~ F
        -- 0b010000: G
        -- 0b010001: H
        -- 0b010010: I
        -- 0b010011: J
        -- 0b010100: K
        -- 0b010101: L
        -- 0b010110: M
        -- 0b010111: N
        -- 0b011000: O
        -- 0b011001: P
        -- 0b011010: Q
        -- 0b011011: R
        -- 0b011100: S
        -- 0b011101: T
        -- 0b011110: U
        -- 0b011111: V
        -- 0b100000: W
        -- 0b100001: X
        -- 0b100010: Y
        -- 0b100011: Z
        din: in std_logic_vector(5 downto 0);
        -- abcdefg
        -- b g f
        -- c a e
        --   d  
        dout: out std_logic_vector(6 downto 0));
end seven_seg_decoder_ex;

architecture rtl of seven_seg_decoder_ex is
begin
  process(clk, xrst)
  begin
    if(xrst = '0') then
      dout <= "0000000";
    elsif(clk'event and clk = '1') then
      case din is
        when "000000" => dout <= "1000000";
        when "000001" => dout <= "1111001"; -- 1
        when "000010" => dout <= "0100100"; -- 2
        when "000011" => dout <= "0110000";
        when "000100" => dout <= "0011001";
        when "000101" => dout <= "0010010";
        when "000110" => dout <= "0000010";
        when "000111" => dout <= "1111000";
        when "001000" => dout <= "0000000";
        when "001001" => dout <= "0010000"; -- 9
        when "001010" => dout <= "0001000"; -- A
        when "001011" => dout <= "0000011"; -- B
        when "001100" => dout <= "1000110"; -- C
        when "001101" => dout <= "0100001"; -- D
        when "001110" => dout <= "0000110"; -- E
        when "001111" => dout <= "0001110"; -- F
        when "010000" => dout <= "1000010"; -- G
        when "010001" => dout <= "0001011"; -- H
        when "010010" => dout <= "1101110"; -- I
        when "010011" => dout <= "1110010"; -- J
        when "010100" => dout <= "0001010"; -- K
        when "010101" => dout <= "1000111"; -- L
        when "010110" => dout <= "0101010"; -- M
        when "010111" => dout <= "0101011"; -- N
        when "011000" => dout <= "0100011"; -- O
        when "011001" => dout <= "0001100"; -- P
        when "011010" => dout <= "0011000"; -- Q
        when "011011" => dout <= "0101111"; -- R
        when "011100" => dout <= "1010010"; -- S
        when "011101" => dout <= "0000111"; -- T
        when "011110" => dout <= "1100011"; -- U
        when "011111" => dout <= "1010101"; -- V
        when "100000" => dout <= "0010101"; -- W
        when "100001" => dout <= "1101011"; -- X
        when "100010" => dout <= "0010001"; -- Y
        when "100011" => dout <= "1100100"; -- Z
        when others => dout <= "0000000";
      end case;
    end if;
  end process;
end rtl;
