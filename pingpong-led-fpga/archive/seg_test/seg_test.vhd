-- seg_test.vhd
-- Diagnostic only: connects switches straight to the seven-segment pins.
-- sw(0) -> seg(0) = G ... sw(6) -> seg(6) = A, sw(7) -> LED only.
-- No clock, no logic, so any result comes from the board / pins / polarity.
library ieee;
use ieee.std_logic_1164.all;

entity seg_test is
  port (
    sw  : in  std_logic_vector(7 downto 0);
    led : out std_logic_vector(7 downto 0);
    seg : out std_logic_vector(6 downto 0)
  );
end entity seg_test;

architecture rtl of seg_test is
begin
  led <= sw;
  seg <= sw(6 downto 0);
end architecture rtl;
