library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- # CPU
-- 
-- ## Instructions
-- ### Basic
-- RT $addr: AC = AC + RAM[addr]      (0b00000000 (0x00)) (R-Type. 0b00abcdef, a: za, b: zb, c: na, d: nb, e: f, f: no)
-- (ADD: 0b00000010, SUB: 0b010011, AND: 0b00000000, OR: 0b01010101, DECREMENT: 0b001110)
-- LD $addr: AC = RAM[addr]           (0b01000000 (0x40))
-- ST $addr: RAM[addr] = AC           (0b01010000 (0x50))
-- JU $addr: PC = addr                (0b10000000 (0x80))
-- JZ $addr: if AC = 0 then PC = addr (0b10010000 (0x90))
-- 
-- ### ToDo
-- LDI $val: AC = val                 (0b01010000 (0x50))
-- SYS $val: syscall val              (0b
-- 
-- ### State transition (Only Execute cycle)
-- #### JU
-- 0. Load_MAR, Gate_PC
-- 1. Load_Memory
-- 2. Load_PC, Gate_MBR
-- 
-- ## Registers
-- RAM: 8 bit, 64 word
-- AC: 8 bit (accumulator)
-- PC: 8 bit (program counter)
-- IR: 8 bit (instruction register)
-- MAR: 8 bit (memory address register)
-- MBR: 8 bit (memory buffer register)
--
-- ## Signals
-- BUS: 8 bit
--
-- ### 制御信号
-- Gate_PC: 1 bit
-- Gate_AC: 1 bit
-- Gate_MBR: 1 bit
--  
-- ## State
-- Fetch -> Decode -> Fetch -> Execute -> Writeback
--
-- f_0: MAR <- PC
-- f_1: MBR <- RAM[MAR]
-- f_2: IR <- MBR
-- f_3: PC <- PC + 1 
-- e_0
-- e_1
-- e_2
-- e_3
-- e_4
-- e_5
--
-- ## Network
-- ### Server
-- syscall socket
-- syscall listen
-- syscall recv
-- syscall send
-- syscall close
-- 
-- ### Client
-- syscall socket
-- syscall connect
-- syscall send
-- syscall recv
-- syscall close
-- 
-- ## Example Program
-- 0: 0x40 (LD)
-- 1: 0x08 (M[8])
-- 2: 0x00 (ADD)
-- 3: 0x09 (M[9])
-- 4: 0x50 (ST)
-- 5: 0x08 (M[8])
-- 6: 0x80 (JU)
-- 7: 0x06 (6)
-- 8: 0x05 (5)
-- 9: 0x06 (6)

entity cpu is
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
end cpu;

architecture rtl of cpu is
  type state_type is (idle, f0, f1, f2, f3, e0, e1, e2, e3, e4, e5);
  signal state, nx_state: state_type;
  signal state_slv: std_logic_vector(3 downto 0);
  signal clk, xrst: std_logic;
  -- constants
  constant Z_VEC_K : std_logic_vector(K-1 downto 0) := (others => '0'); -- k bit zero vector
  -- inputs
  signal k_start, k_write, k_incr, k_decr: std_logic;
  signal k_incr_last, k_decr_last, k_start_last: std_logic; -- registers for key input
  signal sw_mode: std_logic_vector(1 downto 0);
  signal sw_din: std_logic_vector(7 downto 0);
  -- memory
  signal din, dout, dout_prev, adr, adr_reg: std_logic_vector (7 downto 0);
  signal we: std_logic;
  -- display
  signal hx0, hx1, hx2, hx3, hx4, hx5: std_logic_vector(3 downto 0);
  -- registers and bus
  signal mar, mbr, ac, pc, ir, buss: std_logic_vector (7 downto 0);
  -- control signals
  signal gate_pc, gate_ac, gate_mbr,
         inc_pc, clear_pc, load_pc, load_ir,
         load_ac, load_mar, load_mbr, load_mem, r_w,
         -- za: zero ac, na: negative ac, zb: zero b, nb: negative b, f: ac and buss if 0 else ac + buss, no: negative output
         alu_za, alu_na, alu_zb, alu_nb, alu_f, alu_no: std_logic;
  signal alu_out: std_logic_vector (K-1 downto 0);
  signal nx_mar, nx_mbr, nx_ac, nx_pc, nx_ir: std_logic_vector (7 downto 0);
  signal ir_opr, ir_opnd: std_logic_vector (3 downto 0);
  type opcode_type is (RT, LD, ST, JZ, JU, UNK);
  signal op: opcode_type;
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
  -- 7 segment decoder
  component seven_seg_decoder is
    port(clk: in std_logic;
         xrst: in std_logic;
         din: in  std_logic_vector(3 downto 0);
         dout: out std_logic_vector(6 downto 0));
  end component;
  -- ALU
  component alu is
    generic(K: integer);
    port(
      za, na, zb, nb, f, no: in std_logic;
      ain, bin: in std_logic_vector (K-1 downto 0);
      fout: out std_logic_vector (K-1 downto 0));
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
  hx0 <= dout(3 downto 0)      when state = idle else ac(3 downto 0);
  hx1 <= dout(7 downto 4)      when state = idle else ac(7 downto 4);
  hx2 <= dout_prev(3 downto 0) when state = idle else pc(3 downto 0);
  hx3 <= dout_prev(7 downto 4) when state = idle else pc(7 downto 4);
  hx4 <= adr(3 downto 0)       when state = idle else ir(3 downto 0);
  hx5 <= adr(7 downto 4)       when state = idle else ir(7 downto 4);
  GPIO_1(7 downto 0) <= buss;
  GPIO_1(15 downto 8) <= mar;
  GPIO_1(23 downto 16) <= mbr;

  LEDR(3 downto 0) <= state_slv;
  LEDR(4) <= alu_za;
  LEDR(5) <= alu_na;
  LEDR(6) <= alu_zb;
  LEDR(7) <= alu_nb;
  LEDR(8) <= alu_f;
  LEDR(9) <= alu_no;

  -- Memory
  ram1: ram_WxK generic map(K => K, W => W) port map(clk => CLOCK_50, din => din, wadr => adr, radr => adr, we => we, dout => dout, dout_prev => dout_prev);
  din <= sw_din  when state = idle else mbr;
  we  <= k_write when state = idle else r_w;
  adr <= adr_reg when state = idle else mar;

  -- Control unit
  buss <= pc  when gate_pc = '1' else
          ac  when gate_ac = '1' else
          mbr when gate_mbr = '1' else Z_VEC_K;
  gate_pc  <= '1' when (state = f0) or (state = e0) else '0';
  gate_ac  <= '1' when (state = e3 and op = ST) else '0'; -- e3 and ST
  gate_mbr <= '1' when (state = f2) or 
                       (state = e2 and ir_opr(3) = '0') or 
                       (state = e4 and (op = RT or op = LD or op = JZ)) or 
                       (state = e2 and op = JU) else '0'; -- f2 or (e2 and non-JUMP) or (e4 and (LD or RT))
  inc_pc   <= '1' when (state = f3) or (state = e5) or (state = e2 and op = JZ) else '0';
  clear_pc <= '0';
  load_pc  <= '1' when (state = e4 and op = JZ) or (state = e2 and op = JU) else '0';
  load_ir  <= '1' when (state = f2) else '0';
  load_ac  <= '1' when (state = e4 and (op = RT or op = LD)) else '0'; -- e4 and (LD or RT)
  load_mar <= '1' when (state = f0) or (state = e0) or (state = e2 and ir(7) = '0') else '0'; -- 0xxxxxxx: other than JUMP
  load_mbr <= '1' when (state = e3 and op = ST) else '0'; -- e3 and ST
  load_mem <= '1' when (state = f1) or (state = e1) or (state = e3 and (op = RT or op = LD)) else '0';
  r_w      <= '1' when (state = e4 and op = ST) else '0';
  alu_za   <= '1' when (state = e4 and op = LD) else
              ir(5) when (state = e4 and op = RT) else '0';
  alu_na   <= '1' when (state = e4 and op = LD) else
              ir(4) when (state = e4 and op = RT) else '0';
  alu_zb   <= ir(3) when (state = e4 and op = RT) else '0';
  alu_nb   <= ir(2) when (state = e4 and op = RT) else '0';
  alu_f    <= ir(1) when (state = e4 and op = RT) else '0';
  alu_no   <= ir(0) when (state = e4 and op = RT) else '0';
  -- state transition
  nx_state <= f0 when (state = idle and k_start = '1') or  -- run program
                      (state = e4 and ir(7) = '1') or -- if JUMP
                      (state = e5) or  -- execute cycle end
                      (state = e3 and op = JZ and ac /= Z_VEC_K) or  -- if (JZ and ac != 0 (分岐))
                      (state = e2 and op = JU) else -- if JU
              f1 when state = f0 else
              f2 when state = f1 else
              f3 when state = f2 else
              e0 when state = f3 else
              e1 when state = e0 else
              e2 when state = e1 else
              e3 when state = e2 else
              e4 when state = e3 and (op /= JZ or ac = Z_VEC_K) else -- if JZ, e4 when AC = 0 (分岐)
              e5 when (state = e4 and ir(7) = '0') else -- e4 and non-JUMP
              state;
  state_slv <= "0000" when state = idle else
               "0001" when state = f0 else
               "0010" when state = f1 else
               "0011" when state = f2 else
               "0100" when state = f3 else
               "0101" when state = e0 else
               "0110" when state = e1 else
               "0111" when state = e2 else
               "1000" when state = e3 else
               "1001" when state = e4 else
               "1010" when state = e5 else
               "1111";
  -- next register values
  nx_pc  <= Z_VEC_K when state = idle else -- initialize
            buss    when load_pc = '1' else
            pc + 1  when inc_pc = '1' else
            Z_VEC_K when clear_pc = '1' else
            pc;
  nx_ir  <= Z_VEC_K when state = idle else -- initialize
            buss    when load_ir = '1' else
            ir;
  nx_mar <= Z_VEC_K when state = idle else -- initialize
            buss    when load_mar = '1' else
            mar;
  nx_mbr <= Z_VEC_K when state = idle else -- initialize
            dout    when load_mem = '1' else
            buss    when load_mbr = '1' else
            mbr;
  -- ALU
  alu1: alu generic map(K => K) port map(za => alu_za, na => alu_na, zb => alu_zb, nb => alu_nb, f => alu_f, no => alu_no, ain => ac, bin => buss, fout => alu_out);
  nx_ac  <= Z_VEC_K when state = idle else -- initialize
            alu_out when load_ac = '1' else
            ac;
  -- instruction decode
  ir_opr <= ir(7 downto 4);
  ir_opnd <= ir(3 downto 0);
  op <= RT when ir(7 downto 6) = "00" else -- R Type
        LD when ir_opr = "0100" else
        ST when ir_opr = "0101" else
        JZ when ir_opr = "1001" else
        JU when ir_opr = "1000" else
        UNK;
  
  process(clk, xrst)
  begin
    if (xrst = '0') then
      state <= idle;
      pc <= Z_VEC_K;
      ir <= Z_VEC_K;
      ac <= Z_VEC_K;
      mar <= Z_VEC_K;
      mbr <= Z_VEC_K;
      k_incr_last <= '0';
      k_decr_last <= '0';
      k_start_last <= '0';
      adr_reg <= Z_VEC_K;
    elsif (clk 'event and clk = '1') then
      if (sw_mode = "00" or (sw_mode = "01" and k_start = '1' and k_start_last = '0')) then
        state <= nx_state;
        pc <= nx_pc;
        ir <= nx_ir;
        ac <= nx_ac;
        mar <= nx_mar;
        mbr <= nx_mbr;
      end if;

      if (nx_state = idle) then
        if (k_incr = '1' and k_incr_last = '0') then
          adr_reg <= adr_reg + 1;
        elsif (k_decr = '1' and k_decr_last = '0') then
          adr_reg <= adr_reg - 1;
        end if;
      end if;

      k_incr_last <= k_incr;
      k_decr_last <= k_decr;
      k_start_last <= k_start;
      
    end if;
  end process;

end rtl;

