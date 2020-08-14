-- (VHDL Comment)
-- Import std_logic library
library IEEE;
use IEEE.std_logic_1164.all;

-- Entity
entity ANDGATE is
  port( A: in std_logic;
        B: in std_logic;
        Y: out std_logic);
end entity ANDGATE;
 
-- Architecture
architecture RTL of ANDGATE is
begin
  Y <= A AND B; 
end architecture RTL;
