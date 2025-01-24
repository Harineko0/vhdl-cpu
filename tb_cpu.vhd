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
    -- // Fibonacci sequence
    -- i = 1, j = 1, k = 0, n = 5
    -- while (n != 0) {
    --   k = j;
    --   j = i + j;
    --   i = k;
    --   n = n - 1;
    -- }
    -- result: i = 5, j = 8, k = 5, n = 0
    -- 00: LD 0x1F -- LD n
    -- 02: JZ 0x1A -- break loop
    -- 04: LD 0x1D -- j
    -- 06: ST 0x1E -- k
    -- 08: LD 0x1C -- i
    -- 0A: AD 0x1D -- j
    -- 0C: ST 0x1D -- j
    -- 0E: LD 0x1E -- k
    -- 10: ST 0x1C -- i
    -- 12: LD 0x1F -- n
    -- 14: DECREMENT 0x00
    -- 16: ST 0x1F -- n
    -- 18: JU 0x02 -- continue loop
    -- 1A: JU 0x1A -- end
    -- 1C: 0x01 -- i
    -- 1D: 0x01 -- j
    -- 1E: 0x00 -- k
    -- 1F: 0x05 -- n
    ((16#40#, 16#40#), -- LD
     (16#1F#, 16#1F#), -- n   
     (16#90#, 16#90#), -- JZ
     (16#1A#, 16#1A#),
     (16#40#, 16#40#), -- LD
     (16#1D#, 16#1D#), -- j
     (16#50#, 16#50#), -- ST
     (16#1E#, 16#1E#), -- k
     (16#40#, 16#40#), -- LD
     (16#1C#, 16#1C#), -- i
     (16#02#, 16#02#), -- AD
     (16#1D#, 16#1D#),
     (16#50#, 16#50#), -- ST
     (16#1D#, 16#1D#),
     (16#40#, 16#40#), -- LD
     (16#1E#, 16#1E#), -- k
     (16#50#, 16#50#), -- ST
     (16#1C#, 16#1C#), -- i
     (16#40#, 16#40#), -- LD
     (16#1F#, 16#1F#), -- n
     (16#0E#, 16#0E#), -- DECREMENT
     (16#00#, 16#00#),
     (16#50#, 16#50#), -- ST
     (16#1F#, 16#1F#), -- n
     (16#80#, 16#80#), -- JU
     (16#02#, 16#02#),
     (16#80#, 16#80#), -- JU
     (16#1A#, 16#1A#),
     (16#01#, 16#08#), -- 1C
     (16#01#, 16#0D#), -- 1D
     (16#00#, 16#08#), -- 1E
     (16#05#, 16#00#)  -- 1F
     );
    -- // Simple adder (i = i + j)
    -- 00: LD 0x08
    -- 02: AD 0x09
    -- 04: ST 0x08
    -- 06: JU 0x06
    -- 08: 0x03 -- i
    -- 09: 0x04 -- j
    -- ((16#40#, 16#40#), -- LD
    --  (16#08#, 16#08#), -- 8
    --  (16#02#, 16#02#), -- AD
    --  (16#09#, 16#09#), -- 9
    --  (16#50#, 16#50#), -- ST
    --  (16#08#, 16#08#), -- 8
    --  (16#80#, 16#80#), -- JU
    --  (16#06#, 16#06#), -- 6
    --  (16#03#, 16#07#), -- 3
    --  (16#04#, 16#04#));-- 4
  constant period: time := 0.04 ns;
  signal clk: std_logic := '0';
  signal xrst: std_logic;
  signal key: std_logic_vector(3 downto 0);
  signal sw: std_logic_vector(9 downto 0);
  signal gpio: std_logic_vector (35 downto 0);
  type mem is array(0 to (2**W)-1) of std_logic_vector(K-1 downto 0);
  signal cpu_ram, res_ram: mem;
  type state_type is (idle, f0, f1, f2, f3, e0, e1, e2, e3, e4, e5);
  signal cpu_state: state_type;
  signal cpu_ir, cpu_pc, old_pc: std_logic_vector(K-1 downto 0);
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
    init_signal_spy("tb_cpu/cpu1/ir","/cpu_ir",1);
    init_signal_spy("tb_cpu/cpu1/pc","/cpu_pc",1);
    init_signal_spy("tb_cpu/cpu1/state","/cpu_state",1);

    wait until cpu_state = f3;
    
    old_pc <= cpu_pc;

    wait until cpu_state = f0; -- next instruction

    -- detect infinite loop
    if ((old_pc = cpu_pc and cpu_ir = "10000000")) then
      for i in input_table'range loop -- set ram_res
        res_ram(conv_integer(std_logic_vector(to_unsigned(i, W)))) <= std_logic_vector(to_unsigned(input_table(i).result, K));
      end loop;
      
      assert (cpu_ram /= res_ram) report "CPU RAM does not match expected result" severity failure;
      wait for period * 10;
      assert (false) report "Simulation successfully completed!" severity failure;
    end if;
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

