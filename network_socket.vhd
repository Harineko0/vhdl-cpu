library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- 

entity network_socket is
    port(
      clk, xrst: in std_logic;
      -- io(7..0): data bits
      -- io(8): send signal
      -- io(9): receive signal
      -- io(10): ready signal
      io: inout std_logic_vector(15 downto 0));
end network_socket;

architecture rtl of network_socket is
  type state_type is (idle);
  signal state, nx_state: state_type;
begin
    
end rtl;

