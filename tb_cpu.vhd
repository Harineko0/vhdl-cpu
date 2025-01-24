library ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;

entity tb_cpu is
    generic(K: integer := 8;
            W: integer := 8);
end tb_cpu;

architecture testbench of tb_cpu is
  type test_vec_t is record
    prog: integer;
    result: integer;
  end record;
  type test_vec_array_t is array(natural range <>) of test_vec_t;
  constant input_table: test_vec_array_t :=
    ((16#40#, 16#40#), -- LD
     (16#08#, 16#08#), -- 8
     (16#00#, 16#00#), -- AD
     (16#09#, 16#09#), -- 9
     (16#50#, 16#50#), -- ST
     (16#08#, 16#08#), -- 8
     (16#80#, 16#80#), -- JU
     (16#06#, 16#06#), -- 6
     (16#03#, 16#07#), -- 3
     (16#04#, 16#04#));-- 4
  constant period: time := 0.04 ns;
  signal clk: std_logic := '0';
  signal xrst: std_logic;
  signal key: std_logic_vector(3 downto 0);
  signal sw: std_logic_vector(9 downto 0);
  signal gpio: std_logic_vector (35 downto 0);
  type mem is array(0 to (2**W)-1) of std_logic_vector(K-1 downto 0);
  signal cpu_ram, res_ram: mem;
  component cpu
    generic(K: integer;
            W: integer);
    port(
      CLOCK_50, RESET_N: in std_logic;
      KEY: in std_logic_vector(3 downto 0);
      SW: in std_logic_vector(9 downto 0);
      GPIO_1: inout std_logic_vector (35 downto 0);
      LEDR: out std_logic_vector (9 downto 0);
      HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: out std_logic_vector(6 downto 0));
  end component;
begin
  clock: process
  begin
    wait for period*0.25;
    clk <= not clk;
    wait for period*0.25;
  end process;

  write_prog: process
  begin
    xrst <= '1';
    key <= (others => '1');
    sw <= (others => '0');
    wait for period;
    xrst <= '0';
    wait for period;
    xrst <= '1';
    wait for period;
    for i in input_table'range loop
      key <= "1101"; -- write
      sw(7 downto 0) <= std_logic_vector(to_unsigned(input_table(i).prog, K));
      wait for period;
      key <= "1011"; -- address increment
      sw(7 downto 0) <= std_logic_vector(to_unsigned(input_table(i).prog, K));
      wait for period;
    end loop;
    key <= "1110"; -- run
    wait;
  end process;
  
  check: process
  begin
    init_signal_spy("tb_cpu/cpu/ram1/ram_block","/cpu_ram",1);
    wait until key(0) = '0';
    wait for period * 10 * input_table'length; -- average 10 step per 1 instruction
    
    for i in input_table'range loop -- set ram_res
      res_ram(conv_integer(std_logic_vector(to_unsigned(i, W)))) <= std_logic_vector(to_unsigned(input_table(i).result, K));
    end loop;
    
    assert (cpu_ram /= res_ram) report "CPU RAM does not match expected result" severity failure;
    wait for period * 10;
    assert (false) report "Simulation successfully completed!" severity failure;
  end process;

  cpu1: cpu generic map(K => K, W => W) port map(CLOCK_50 => clk,
                   RESET_N => xrst,
                   KEY => key,
                   SW => sw,
                   GPIO_1 => gpio,
                   LEDR => open,
                   HEX0 => open,
                   HEX1 => open,
                   HEX2 => open,
                   HEX3 => open,
                   HEX4 => open,
                   HEX5 => open);

end testbench;

