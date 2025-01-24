library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity alu is
  generic(K: integer := 8);
  port(
    za, zb, na, nb, no, f: in std_logic;
    ain, bin: in std_logic_vector (K-1 downto 0);
    fout: out std_logic_vector (K-1 downto 0));
end alu;

architecture rtl of alu is
    constant Z_VEC_K : std_logic_vector(K-1 downto 0) := (others => '0'); -- k bit zero vector
    signal a, b, na_vec, nb_vec, no_vec: std_logic_vector(K-1 downto 0);
begin
  a <= Z_VEC_K when za = '1' else ain;
  b <= Z_VEC_K when zb = '1' else bin;
  na_vec <= "11111111" when na = '1' else Z_VEC_K;
  nb_vec <= "11111111" when nb = '1' else Z_VEC_K;
  no_vec <= "11111111" when no = '1' else Z_VEC_K;
  fout  <= no_vec xor ((na_vec xor a)  +  (nb_vec xor b)) when f = '1' else
           no_vec xor ((na_vec xor a) and (nb_vec xor b)) when f = '0' else
           Z_VEC_K;
end rtl;

