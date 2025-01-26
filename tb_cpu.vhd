library ieee;
library modelsim_lib;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use modelsim_lib.util.all;

entity tb_cpu is
    generic(K: integer := 8;
            W: integer := 10);
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
    -- 00: LD $t0 0x18 -- LD i
    -- 02: LD $t1 0x19 -- LD j
    -- 04: LD $t2 0x20 -- LD n
    -- 06: JZ $t2 0x12 -- break loop
    -- 08: RT $t3 $t1 -- (k = j)
    -- 0A: RT $t1 $t0 -- (j = j + i)
    -- 0C: RT $t0 $t3 -- (i = k)
    -- 0E: RT $t2 $0  -- (n = n - 1)
    -- 10: JU 0x06 -- continue loop
    -- 12: ST $t0 0x18 -- ST i
    -- 14: ST $t1 0x19 -- ST j
    -- 16: JU 0x12 -- end
    -- 18: 0x01 -- i
    -- 19: 0x01 -- j
    -- 1A: 0x05 -- n
    ((16#44#, 16#44#), -- LD i
     (16#18#, 16#18#), -- 
     (16#45#, 16#45#), -- LD j
     (16#19#, 16#19#), -- 
     (16#46#, 16#46#), -- LD n
     (16#1A#, 16#1A#), -- 
     (16#96#, 16#96#), -- JZ n
     (16#12#, 16#12#),
     (16#30#, 16#30#), -- k = j
     (16#75#, 16#75#),
     (16#02#, 16#02#), -- j = j + 1
     (16#54#, 16#54#),
     (16#30#, 16#30#), -- i = k
     (16#47#, 16#47#),
     (16#0E#, 16#0E#), -- n = n - 1
     (16#60#, 16#60#),
     (16#80#, 16#80#), -- JU
     (16#06#, 16#06#),
     (16#54#, 16#54#), -- ST i
     (16#18#, 16#18#),
     (16#55#, 16#55#), -- ST j
     (16#19#, 16#19#),
     (16#80#, 16#80#), -- JU
     (16#16#, 16#16#),
     (16#01#, 16#08#), -- i
     (16#01#, 16#0D#), -- j
     (16#05#, 16#05#)  -- n
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
  signal cpu_ir: std_logic_vector(K-1 downto 0);
  signal cpu_pc, old_pc: std_logic_vector(W-1 downto 0);
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
        assert (cpu_ram(i) /= std_logic_vector(to_unsigned(input_table(i).result, K))) report "CPU RAM does not match expected result" severity failure;
      end loop;
      
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

