library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Network interface (Ethernet
-- 送信:
-- * 送信準備: rts=1
-- 
-- 受信:
-- * 受信準備: cls=1
entity network_interface is
    generic(K: integer := 8);
    port(
      clk, xrst: in std_logic;
      rxd: in std_logic;
      txd: out std_logic;
      -- io(K-1 downto 0): data bits
      -- io(8): send signal
      -- io(9): recv signal
      io_in: in std_logic_vector(9 downto 0);
      io_out: out std_logic_vector(9 downto 0);
      -- gpio(0): in  rxd (Rx Data)
      -- gpio(1): out txd (Tx Data)
      -- gpio(2): out dtr (Data Terminal Ready)
      -- gpio(3): in  dsr (Data Set Ready)
      -- gpio(4): out rts (Request To Send)
      -- gpio(5): in  cls (Clear To Send)
      gpio: inout std_logic_vector(5 downto 0));
end network_interface;

architecture rtl of network_interface is
  type state_type is (idle, s0, r0);
  signal state, nx_state: state_type;
begin
    
end rtl;


-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;

-- -- Network interface (Ethernet MII)
-- -- 送信:
-- -- * enable tx_clk
-- -- * tx_en = H
-- -- * txd0-3 = data(0~3)
-- -- * txd0-3 = data(4~7)
-- -- * ..
-- -- * txd0-3 = data(B-1 downto B-4)
-- -- * tx_en = L
-- -- 
-- -- 受信:
-- -- * 受信準備: cls=1
-- entity network_interface is
--     -- B: buffer size
--     generic(B: integer := 16);
--     port(
--       clk, xrst: in std_logic;
--       rxd: in std_logic;
--       txd: out std_logic;
--       -- io(K-1 downto 0): data bits
--       -- io(8): send signal
--       -- io(9): recv signal
--       io_in: in std_logic_vector(9 downto 0);
--       io_out: out std_logic_vector(9 downto 0);
--       -- gpio(0): inout tx_clk/rx_clk
--       -- gpio(1): inout txd0/rxd0
--       -- gpio(2): inout txd1/rxd1
--       -- gpio(3): inout txd2/rxd2
--       -- gpio(4): inout txd3/rxd3
--       -- gpio(5): out   tx_en
--       -- gpio(6): in    rx_dv
--       gpio: inout std_logic_vector(5 downto 0));
-- end network_interface;

-- architecture rtl of network_interface is
--   type state_type is (idle, s0, r0);
--   signal state, nx_state: state_type;
-- begin
    
-- end rtl;

