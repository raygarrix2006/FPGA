library ieee;
use ieee.std_logic_1164.all;
entity tb_btn_cond is end entity;
architecture sim of tb_btn_cond is
  signal clk : std_logic := '0';
  signal din : std_logic := '0';
  signal level, pulse : std_logic;
  signal done : boolean := false;
  signal pulse_count : natural := 0;
begin
  dut : entity work.btn_cond generic map(DEB_CYC => 4)
    port map(clk => clk, din => din, level => level, pulse => pulse);
  clocking : process begin
    while not done loop
      clk <= '0'; wait for 5 ns; clk <= '1'; wait for 5 ns;
    end loop;
    wait;
  end process;
  count_pulses : process(clk) begin
    if rising_edge(clk) then
      if pulse = '1' then pulse_count <= pulse_count + 1; end if;
    end if;
  end process;
  test : process begin
    wait for 100 ns;
    din <= '1'; wait for 20 ns; din <= '0'; wait for 120 ns;
    assert level = '0' and pulse_count = 0 report "B1 short bounce accepted" severity failure;
    din <= '1'; wait for 200 ns;
    assert level = '1' and pulse_count = 1 report "B2 stable press missing" severity failure;
    wait for 500 ns;
    assert pulse_count = 1 report "B3 held press repeated" severity failure;
    din <= '0'; wait for 20 ns; din <= '1'; wait for 100 ns;
    assert level = '1' and pulse_count = 1 report "B4 release bounce accepted" severity failure;
    din <= '0'; wait for 120 ns;
    assert level = '0' and pulse_count = 1 report "B5 release wrong" severity failure;
    din <= '1'; wait for 120 ns;
    assert level = '1' and pulse_count = 2 report "B6 second press missing" severity failure;
    report "ALL BUTTON TESTS PASSED"; done <= true; wait;
  end process;
end architecture;
