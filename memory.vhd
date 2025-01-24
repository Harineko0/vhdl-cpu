library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity memory is
  generic(K: integer := 8;
          W: integer := 8;
          I: integer := 2);
  port(clk: in std_logic;
       din: in std_logic_vector (K-1 downto 0);
       dout: out std_logic_vector (K-1 downto 0);
       dout_prev: out std_logic_vector (K-1 downto 0);
       iin: in std_logic_vector (K*I - 1 downto 0);
       iout out std_logic_vector (K*I - 1 downto 0);
       wadr: in std_logic_vector (W-1 downto 0);
       radr: in std_logic_vector (W-1 downto 0);
       we: in std_logic);
end memory;

architecture rtl of memory is
  constant ADR_MAX : unsigned(K-1 downto 0) := (others => '1');  -- k bit, 0b11..11
  constant RAM_ADR_MAX : unsigned(K-1 downto 0) := ADR_MAX - to_unsigned(I, K); 
  signal mout: std_logic_vector (K-1 downto 0);
  signal io_ram: std_logic_vector(K*I - 1 downto 0);
  -- K bit, W word RAM
  component ram_WxK
    generic(K: integer;
            W: integer);
    port(clk: in std_logic;
         din: in std_logic_vector (K-1 downto 0);
         wadr: in std_logic_vector (W-1 downto 0);
         radr: in std_logic_vector (W-1 downto 0);
         we: in std_logic;
         dout: out std_logic_vector (K-1 downto 0);
         dout_prev: out std_logic_vector (K-1 downto 0));
  end component;
begin
    ram1: ram_WxK generic map(K => K, W => W) port map(clk => clk, din => din, wadr => wadr, radr => radr, we => we, dout => mout, dout_prev => dout_prev);

    dout <= iin when radr > RAM_ADR_MAX else mout;
    iout <= io_ram;

    process(clk)
    begin
        if (clk 'event and clk = '1') then
            if (we = '1' and wadr > RAM_ADR_MAX) then
                io_ram(conv_integer(wadr)) <= din;
            end if;
        end if;
    end process;
end rtl;
