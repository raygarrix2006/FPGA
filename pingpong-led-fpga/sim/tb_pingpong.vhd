-- tb_pingpong.vhd
-- 自我檢查的 testbench：用縮短的時間參數，模擬很快就能跑完
-- CLK_HZ = 10_000 -> 1 ms = 10 個 clock，所以：
--   去彈跳 1 ms = 10 clk，勻速每步 20 ms = 200 clk，得分顯示 50 ms = 500 clk
-- 失敗時 assert 會印出訊息並停止；全部通過會印 "ALL TESTS PASSED"
-- 分數以 4 位元二進位顯示在得分者那半邊：
--   player1：LED0 = MSB ... LED3 = LSB；player2：LED4 = MSB ... LED7 = LSB
-- 得分顯示 500 clk：前 250 clk 顯示二進位、後 250 clk 熄滅；勝利後勝方四顆恆亮
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pingpong is
end entity tb_pingpong;

architecture sim of tb_pingpong is

  constant T_CLK : time := 10 ns;

  signal clk     : std_logic := '0';
  signal rst_n   : std_logic := '0';
  signal mode_sw : std_logic := '0';
  signal btn_l   : std_logic := '0';
  signal btn_r   : std_logic := '0';
  signal led     : std_logic_vector(7 downto 0);
  signal done    : boolean := false;

  -- 縮短後的參數（需與 generic map 一致）
  constant STEP_MIN_CYC : integer := 10 * 10;           -- STEP_MIN_MS = 10
  constant STEP_MAX_CYC : integer := (10 + 3 * 5) * 10; -- STEP_MIN + 3 * STEP_UNIT

  -- player1 得 k 分時的 LED 圖樣：LED0 = bit3 ... LED3 = bit0
  function bin_p1(k : integer) return std_logic_vector is
    variable v : std_logic_vector(7 downto 0) := (others => '0');
    variable b : std_logic_vector(3 downto 0);
  begin
    b := std_logic_vector(to_unsigned(k, 4));
    for i in 0 to 3 loop
      v(i) := b(3 - i);
    end loop;
    return v;
  end function bin_p1;

  -- player2 得 k 分時的 LED 圖樣：LED4 = bit3 ... LED7 = bit0
  function bin_p2(k : integer) return std_logic_vector is
    variable v : std_logic_vector(7 downto 0) := (others => '0');
    variable b : std_logic_vector(3 downto 0);
  begin
    b := std_logic_vector(to_unsigned(k, 4));
    for i in 0 to 3 loop
      v(i + 4) := b(3 - i);
    end loop;
    return v;
  end function bin_p2;

begin

  dut : entity work.pingpong
    generic map (
      CLK_HZ        => 10_000,
      WIN_SCORE     => 5,
      RAND_BITS     => 2,
      CONST_STEP_MS => 20,
      STEP_MIN_MS   => 10,
      STEP_UNIT_MS  => 5,
      SHOW_TIME_MS  => 50,
      DEBOUNCE_MS   => 1
    )
    port map (
      clk => clk, rst_n => rst_n, mode_sw => mode_sw,
      btn_l => btn_l, btn_r => btn_r, led => led
    );

  p_clk : process
  begin
    while not done loop
      clk <= '0'; wait for T_CLK / 2;
      clk <= '1'; wait for T_CLK / 2;
    end loop;
    wait;
  end process p_clk;

  p_test : process

    -- 按鍵：按住 40 clk 再放開 40 clk（大於去彈跳時間）
    procedure press(signal b : out std_logic) is
    begin
      b <= '1';
      wait for 40 * T_CLK;
      b <= '0';
      wait for 40 * T_CLK;
    end procedure press;

    -- 等 LED 變成指定圖樣，逾時就報錯
    procedure wait_led(constant pat     : in std_logic_vector(7 downto 0);
                       constant max_cyc : in integer;
                       constant msg     : in string) is
    begin
      for i in 1 to max_cyc loop
        exit when led = pat;
        wait until rising_edge(clk);
      end loop;
      assert led = pat report "TIMEOUT: " & msg severity failure;
    end procedure wait_led;

    variable n : integer;

  begin
    -------------------------------------------------------------------
    -- T1：reset 後球在 player1 端（LED0）
    -------------------------------------------------------------------
    rst_n <= '0';
    wait for 50 * T_CLK;
    rst_n <= '1';
    wait for 60 * T_CLK;
    assert led = "00000001" report "T1: after reset LED0 should be lit" severity failure;

    -------------------------------------------------------------------
    -- T2：player1 發球 -> 球飛向 LED7 -> player2 有效回擊 -> 球飛回 LED0
    -------------------------------------------------------------------
    press(btn_l);
    wait_led("00000010", 100, "T2 ball leaves LED0 after serve");
    wait_led("10000000", 8 * 200, "T2 ball reaches LED7");
    press(btn_r);
    wait_led("01000000", 100, "T2 ball returns to LED6");
    wait_led("00000001", 8 * 200, "T2 ball reaches LED0");

    -------------------------------------------------------------------
    -- T3：太晚。player1 不按 -> player2 得 1 分
    --     球在 LED0 的窗口 200 clk 後進入 S_POINT；等 300 clk 時仍在前半段，
    --     應顯示 player2 的二進位 0001（LED7）；之後熄滅，再回到發球端 LED7
    -------------------------------------------------------------------
    wait for 300 * T_CLK;
    assert led = bin_p2(1) report "T3 late: player2 score 1 should show 0001 on LED4..7" severity failure;
    wait_led("00000000", 400, "T3 blink-off phase");
    wait_led("10000000", 800, "T3 winner (player2) serves from LED7");

    -------------------------------------------------------------------
    -- T4：太早。player2 發球後，player1 在球飛行中按鍵 -> player2 再 +1（共 2 分）
    --     按鍵結束時約在 S_POINT 前半段，應顯示 0010（LED6）
    -------------------------------------------------------------------
    press(btn_r);
    wait_led("01000000", 100, "T4 serve moves ball to LED6");
    press(btn_l);
    assert led = bin_p2(2) report "T4 early: player2 score 2 should show 0010" severity failure;
    wait_led("00000000", 400, "T4 blink-off phase");
    wait_led("10000000", 800, "T4 back to wait serve");

    -------------------------------------------------------------------
    -- T5：等待發球時，非發球者按鍵無效
    -------------------------------------------------------------------
    press(btn_l);
    assert led = "10000000" report "T5: non-server press must be ignored" severity failure;

    -------------------------------------------------------------------
    -- T6：player2 再得 3 分達 5 分
    --     每分：前半段顯示二進位（3 = 0011、4 = 0100、5 = 0101），後半熄滅
    --     第 5 分之後進入 game over：勝方 LED4..7 恆亮，按鍵無效
    -------------------------------------------------------------------
    for k in 3 to 5 loop
      press(btn_r);
      wait_led("01000000", 100, "T6 serve");
      press(btn_l);
      assert led = bin_p2(k) report "T6 early point: wrong binary score pattern" severity failure;
      wait_led("00000000", 400, "T6 blink-off phase");
      if k < 5 then
        wait_led("10000000", 800, "T6 wait serve");
      end if;
    end loop;
    wait_led("11110000", 400, "T6 game over: winner LED4..7 solid");
    wait for 1500 * T_CLK;   -- 超過得分顯示時間
    assert led = "11110000" report "T6: game over LEDs should stay lit" severity failure;
    press(btn_r);
    press(btn_l);
    assert led = "11110000" report "T6: buttons must be ignored in game over" severity failure;

    -------------------------------------------------------------------
    -- T7：reset 後切變速，等待 LED2 新區間開始，再量 LED2 -> LED3 的完整步長
    -------------------------------------------------------------------
    rst_n <= '0';
    wait for 50 * T_CLK;
    mode_sw <= '1';
    rst_n <= '1';
    wait for 60 * T_CLK;
    for r in 1 to 4 loop
      press(btn_l);
      wait_led("00000010", 100, "T7 serve");
      wait_led("00000100", STEP_MAX_CYC + 50, "T7 start a complete LED2 interval");
      n := 0;
      while led /= "00001000" and n <= STEP_MAX_CYC + 50 loop
        wait until rising_edge(clk);
        n := n + 1;
      end loop;
      report "T7 round " & integer'image(r) & ": step = " & integer'image(n) & " clk";
      assert n >= STEP_MIN_CYC - 2 and n <= STEP_MAX_CYC + 2
        report "T7: step time out of range" severity failure;
      -- 讓這一球結束：player2 在端點不按 -> player1 得分，再回到等待發球
      wait_led("10000000", 8 * 260, "T7 reach LED7");
      wait for 300 * T_CLK;   -- 步長 100..250 clk，300 clk 時仍在 S_POINT 前半段
      assert led = bin_p1(r) report "T7 late point: wrong binary score pattern" severity failure;
      wait_led("00000000", 400, "T7 blink-off phase");
      wait_led("00000001", 800, "T7 wait serve (player1)");
    end loop;

    -- T8: ignore the sender while the ball flies away; reset during flight.
    rst_n <= '0'; mode_sw <= '0';
    wait for 60 * T_CLK;
    rst_n <= '1'; wait for 60 * T_CLK;
    press(btn_l);
    press(btn_l);
    assert led = "00000010" report "T8: sender press during flight must be ignored" severity failure;
    wait_led("00000100", 250, "T8 flight continues");
    rst_n <= '0'; wait for 60 * T_CLK;
    assert led = "00000001" report "T8: reset during flight" severity failure;
    wait for 300 * T_CLK;
    assert led = "00000001" report "T8: reset must hold the game" severity failure;
    rst_n <= '1'; wait for 60 * T_CLK;
    report "T8 PASSED";

    -- T9: player1 binary scores and left-side game over.
    for k in 1 to 5 loop
      press(btn_l);
      wait_led("00000010", 100, "T9 serve");
      press(btn_r);
      assert led = bin_p1(k) report "T9: wrong player1 binary score" severity failure;
      wait_led("00000000", 400, "T9 off phase");
      if k < 5 then
        wait_led("00000001", 800, "T9 player1 serves again");
      end if;
    end loop;
    wait_led("00001111", 400, "T9 player1 wins");
    press(btn_l); press(btn_r);
    wait for 1000 * T_CLK;
    assert led = "00001111" report "T9: left winner must stay lit" severity failure;
    report "T9 PASSED";

    report "ALL TESTS PASSED";
    done <= true;
    wait;
  end process p_test;

end architecture sim;
