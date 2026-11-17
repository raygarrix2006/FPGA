-- tb_pingpong.vhd
-- 自我檢查的 testbench：用縮短的時間參數，模擬很快就能跑完
-- CLK_HZ = 10_000 -> 1 ms = 10 個 clock，所以：
--   去彈跳 1 ms = 10 clk，勻速每步 20 ms = 200 clk，得分顯示 50 ms = 500 clk
-- 失敗時 assert 會印出訊息；全部通過會印 "ALL TESTS PASSED"
library ieee;
use ieee.std_logic_1164.all;

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
  signal seg     : std_logic_vector(6 downto 0);
  signal done    : boolean := false;

  -- 七段（低電位點亮）期望值：A..G
  constant SEG_0 : std_logic_vector(6 downto 0) := "0000001";
  constant SEG_1 : std_logic_vector(6 downto 0) := "1001111";
  constant SEG_2 : std_logic_vector(6 downto 0) := "0010010";
  constant SEG_5 : std_logic_vector(6 downto 0) := "0100100";

  -- 縮短後的參數（需與 generic map 一致）
  constant STEP_MIN_CYC : integer := 10 * 10;   -- STEP_MIN_MS = 10
  constant STEP_MAX_CYC : integer := (10 + 3 * 5) * 10;

begin

  dut : entity work.pingpong
    generic map (
      CLK_HZ         => 10_000,
      WIN_SCORE      => 5,
      RAND_BITS      => 2,
      CONST_STEP_MS  => 20,
      STEP_MIN_MS    => 10,
      STEP_UNIT_MS   => 5,
      SHOW_TIME_MS   => 50,
      DEBOUNCE_MS    => 1,
      SEG_ACTIVE_LOW => true
    )
    port map (
      clk => clk, rst_n => rst_n, mode_sw => mode_sw,
      btn_l => btn_l, btn_r => btn_r, led => led, seg => seg
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
    procedure wait_led(constant pat : in std_logic_vector(7 downto 0);
                       constant max_cyc : in integer;
                       constant msg : in string) is
    begin
      for i in 1 to max_cyc loop
        exit when led = pat;
        wait until rising_edge(clk);
      end loop;
      assert led = pat report "TIMEOUT: " & msg severity failure;
    end procedure wait_led;

    procedure check_seg(constant exp : in std_logic_vector(6 downto 0);
                        constant msg : in string) is
    begin
      assert seg = exp report "SEG MISMATCH: " & msg severity failure;
    end procedure check_seg;

    variable n : integer;

  begin
    -------------------------------------------------------------------
    -- T1：reset 後球在 player1 端（LED0），七段顯示 0
    -------------------------------------------------------------------
    rst_n <= '0';
    wait for 50 * T_CLK;
    rst_n <= '1';
    wait for 60 * T_CLK;
    assert led = "00000001" report "T1: after reset LED0 should be lit" severity failure;
    check_seg(SEG_0, "T1 score 0");

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
    -- T3：太晚。player1 不按 -> player2 得 1 分，player2 側 4 顆 LED 亮
    -------------------------------------------------------------------
    wait_led("11110000", 400, "T3 late: player2 should score");
    check_seg(SEG_1, "T3 score 1");
    wait_led("10000000", 800, "T3 winner (player2) serves from LED7");

    -------------------------------------------------------------------
    -- T4：太早。player2 發球後，player1 在球飛行中按鍵 -> player2 再 +1
    -------------------------------------------------------------------
    press(btn_r);
    wait_led("01000000", 100, "T4 serve moves ball to LED6");
    press(btn_l);
    wait_led("11110000", 100, "T4 early: player2 should score");
    check_seg(SEG_2, "T4 score 2");
    wait_led("10000000", 800, "T4 back to wait serve");

    -------------------------------------------------------------------
    -- T5：等待發球時，非發球者按鍵無效
    -------------------------------------------------------------------
    press(btn_l);
    assert led = "10000000" report "T5: non-server press must be ignored" severity failure;

    -------------------------------------------------------------------
    -- T6：player2 再得 3 分達 5 分 -> game over，LED 停在 player2 側，七段 5
    -------------------------------------------------------------------
    for k in 3 to 5 loop
      press(btn_r);
      wait_led("01000000", 100, "T6 serve");
      press(btn_l);
      wait_led("11110000", 100, "T6 early point");
      if k < 5 then
        wait_led("10000000", 800, "T6 wait serve");
      end if;
    end loop;
    check_seg(SEG_5, "T6 score 5");
    wait for 1500 * T_CLK;   -- 超過得分顯示時間
    assert led = "11110000" report "T6: game over LED should stay" severity failure;
    press(btn_r);
    press(btn_l);
    assert led = "11110000" report "T6: buttons must be ignored in game over" severity failure;

    -------------------------------------------------------------------
    -- T7：reset 後切變速，量發球後 LED1 -> LED2 的 clock 數是否在範圍內
    -------------------------------------------------------------------
    rst_n <= '0';
    wait for 50 * T_CLK;
    mode_sw <= '1';
    rst_n <= '1';
    wait for 60 * T_CLK;
    for r in 1 to 4 loop
      press(btn_l);
      wait_led("00000010", 100, "T7 serve");
      n := 0;
      while led /= "00000100" and n <= STEP_MAX_CYC + 50 loop
        wait until rising_edge(clk);
        n := n + 1;
      end loop;
      report "T7 round " & integer'image(r) & ": step = " & integer'image(n) & " clk";
      assert n >= STEP_MIN_CYC - 2 and n <= STEP_MAX_CYC + 2
        report "T7: step time out of range" severity failure;
      -- 讓這一球結束再發下一球：player2 在端點不按 -> player1 得分後重新發球
      wait_led("10000000", 8 * 260, "T7 reach LED7");
      wait_led("00001111", 400, "T7 late point");
      wait_led("00000001", 800, "T7 wait serve (player1)");
    end loop;

    report "ALL TESTS PASSED";
    done <= true;
    wait;
  end process p_test;

end architecture sim;