-- pingpong.vhd
-- 乒乓球 LED（單板版）
-- [CHANGE v1.2] 七段顯示器棄用（實測無法點亮）：移除 seg 埠、SEG_ACTIVE_LOW、七段碼函式。
--               分數改用 LED 以 4 位元二進位顯示，見檔案最後的「顯示」區段。
-- 規則：
--   player1 = BTNL（'0'，球位置 0 端 = LED0），player2 = BTNR（'1'，球位置 7 端 = LED7）
--   發球後才判定：球飛向接球者時按鍵 = 太早；端點 LED 那一步時間內沒按 = 太晚
--   太早 / 太晚 都是接球者失分，對手 +1，得分者發球；先到 WIN_SCORE 分獲勝
--   變速：每次有效回擊（含發球）取樣 LFSR，決定下一趟每步時間
-- 撰寫原則：每個 signal 只由一個 process（或一條並行指定）驅動
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pingpong is
  generic (
    CLK_HZ         : integer := 100_000_000;
    WIN_SCORE      : integer range 1 to 15 := 5;    -- 獲勝分數（4 位元二進位最多 15）[CHANGE]
    RAND_BITS      : integer range 1 to 4 := 2;     -- 變速取樣的 LFSR bit 數
    CONST_STEP_MS  : integer := 250;                -- 勻速：每步時間
    STEP_MIN_MS    : integer := 150;                -- 變速：最短每步時間
    STEP_UNIT_MS   : integer := 100;                -- 變速：亂數每加 1 增加的時間
    SHOW_TIME_MS   : integer := 1000;               -- 得分顯示時間
    DEBOUNCE_MS    : integer := 10                  -- 去彈跳時間
  );
  port (
    clk     : in  std_logic;                        -- 100 MHz
    rst_n   : in  std_logic;                        -- SW7，低電位 = reset
    mode_sw : in  std_logic;                        -- SW0，0 = 勻速，1 = 變速
    btn_l   : in  std_logic;                        -- BTNL = player1
    btn_r   : in  std_logic;                        -- BTNR = player2
    led     : out std_logic_vector(7 downto 0)      -- LED0..LED7
  );
end entity pingpong;

architecture rtl of pingpong is

  ---------------------------------------------------------------------------
  -- 常數
  ---------------------------------------------------------------------------
  constant CNT_W          : integer := 27;                       -- 計數器寬度
  constant CYC_PER_MS     : integer := CLK_HZ / 1000;
  constant CONST_STEP_CYC : integer := CONST_STEP_MS * CYC_PER_MS;
  constant STEP_MIN_CYC   : integer := STEP_MIN_MS   * CYC_PER_MS;
  constant STEP_UNIT_CYC  : integer := STEP_UNIT_MS  * CYC_PER_MS;
  constant SHOW_CYC       : integer := SHOW_TIME_MS  * CYC_PER_MS;
  constant DEB_CYC        : integer := DEBOUNCE_MS   * CYC_PER_MS;
  constant STEP_MAX_CYC   : integer := STEP_MIN_CYC + (2**RAND_BITS - 1) * STEP_UNIT_CYC;
  constant HALF_SHOW_CYC  : integer := SHOW_CYC / 2;   -- [CHANGE] 得分顯示：前半亮、後半滅

  ---------------------------------------------------------------------------
  -- 型別
  ---------------------------------------------------------------------------
  type state_t is (S_WAIT_SERVE, S_FLY, S_HIT_WIN, S_POINT, S_GAME_OVER);

  ---------------------------------------------------------------------------
  -- 暫存器類 signal（各自只有一個 process 驅動）
  ---------------------------------------------------------------------------
  signal state       : state_t := S_WAIT_SERVE;
  signal pos         : unsigned(2 downto 0) := (others => '0');   -- 球位置 0..7
  signal dir         : std_logic := '1';                          -- 1 = 往 player2，0 = 往 player1
  signal last_scorer : std_logic := '0';                          -- 最近得分者（也是發球者）
  signal cnt         : unsigned(CNT_W - 1 downto 0) := (others => '0');
  signal step_upbnd  : unsigned(CNT_W - 1 downto 0) := to_unsigned(CONST_STEP_CYC, CNT_W);
  signal lfsr        : std_logic_vector(7 downto 0) := x"A5";
  signal score_l     : integer range 0 to WIN_SCORE := 0;
  signal score_r     : integer range 0 to WIN_SCORE := 0;

  ---------------------------------------------------------------------------
  -- 輸入整理後的 signal（由 btn_cond 驅動）
  ---------------------------------------------------------------------------
  signal rst_n_s : std_logic;
  signal mode_s  : std_logic;
  signal hit_l   : std_logic;
  signal hit_r   : std_logic;

  ---------------------------------------------------------------------------
  -- 並行（組合）signal：事件與衍生值
  ---------------------------------------------------------------------------
  signal upbnd      : unsigned(CNT_W - 1 downto 0);
  signal cnt_en     : std_logic;
  signal tick       : std_logic;     -- cnt 數滿 upbnd
  signal rx_hit     : std_logic;     -- 接球者按鍵（接球者 = dir 指向的人）
  signal sv_hit     : std_logic;     -- 發球者按鍵
  signal at_last    : std_logic;     -- 下一步就到端點
  signal move_dir   : std_logic;     -- 球這次要移動的方向
  signal ev_serve   : std_logic;
  signal ev_early   : std_logic;
  signal ev_step    : std_logic;
  signal ev_arrive  : std_logic;
  signal ev_return  : std_logic;
  signal ev_late    : std_logic;
  signal ev_point   : std_logic;
  signal ev_move    : std_logic;
  signal game_won   : std_logic;
  signal ball_leds  : std_logic_vector(7 downto 0);
  signal score_bits : unsigned(3 downto 0);            -- [CHANGE] 得分者的分數
  signal score_leds : std_logic_vector(7 downto 0);    -- [CHANGE] 二進位顯示用 LED

begin

  -- 參數檢查（編譯 / 合成時就會報錯，避免默默出錯）；訊息用英文，因為字串常值只保證支援 Latin-1
  assert STEP_MAX_CYC < 2**CNT_W and SHOW_CYC < 2**CNT_W
    report "Time parameters exceed the CNT_W counter width" severity failure;
  assert STEP_MIN_CYC >= 2 and CONST_STEP_CYC >= 2
    report "Step time must be at least 2 clock cycles" severity failure;

  ---------------------------------------------------------------------------
  -- 輸入整理
  ---------------------------------------------------------------------------
  u_rst  : entity work.btn_cond generic map (DEB_CYC => DEB_CYC)
           port map (clk => clk, din => rst_n,   level => rst_n_s, pulse => open);
  u_mode : entity work.btn_cond generic map (DEB_CYC => DEB_CYC)
           port map (clk => clk, din => mode_sw, level => mode_s,  pulse => open);
  u_btnl : entity work.btn_cond generic map (DEB_CYC => DEB_CYC)
           port map (clk => clk, din => btn_l,   level => open,    pulse => hit_l);
  u_btnr : entity work.btn_cond generic map (DEB_CYC => DEB_CYC)
           port map (clk => clk, din => btn_r,   level => open,    pulse => hit_r);

  ---------------------------------------------------------------------------
  -- 並行指定：計時相關
  ---------------------------------------------------------------------------
  cnt_en <= '1' when state = S_FLY or state = S_HIT_WIN or state = S_POINT else '0';
  upbnd  <= to_unsigned(SHOW_CYC, CNT_W) when state = S_POINT else step_upbnd;
  tick   <= '1' when cnt_en = '1' and cnt = upbnd - 1 else '0';

  ---------------------------------------------------------------------------
  -- 並行指定：按鍵角色與事件
  ---------------------------------------------------------------------------
  rx_hit <= (hit_r and dir) or (hit_l and not dir);
  sv_hit <= (hit_l and not last_scorer) or (hit_r and last_scorer);
  at_last <= '1' when (dir = '1' and pos = "110") or (dir = '0' and pos = "001") else '0';

  ev_serve  <= '1' when state = S_WAIT_SERVE and sv_hit = '1' else '0';
  ev_early  <= '1' when state = S_FLY and rx_hit = '1' else '0';
  ev_step   <= '1' when state = S_FLY and tick = '1' and rx_hit = '0' else '0';
  ev_arrive <= ev_step and at_last;
  ev_return <= '1' when state = S_HIT_WIN and rx_hit = '1' else '0';
  ev_late   <= '1' when state = S_HIT_WIN and tick = '1' and rx_hit = '0' else '0';
  ev_point  <= ev_early or ev_late;
  ev_move   <= ev_serve or ev_return or ev_step;
  move_dir  <= (not dir) when ev_return = '1' else dir;
  game_won  <= '1' when score_l = WIN_SCORE or score_r = WIN_SCORE else '0';

  ---------------------------------------------------------------------------
  -- state
  ---------------------------------------------------------------------------
  p_state : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        state <= S_WAIT_SERVE;
      else
        case state is
          when S_WAIT_SERVE =>
            if ev_serve = '1' then
              state <= S_FLY;
            end if;
          when S_FLY =>
            if ev_early = '1' then
              state <= S_POINT;
            elsif ev_arrive = '1' then
              state <= S_HIT_WIN;
            end if;
          when S_HIT_WIN =>
            if ev_return = '1' then
              state <= S_FLY;
            elsif ev_late = '1' then
              state <= S_POINT;
            end if;
          when S_POINT =>
            if tick = '1' then
              if game_won = '1' then
                state <= S_GAME_OVER;
              else
                state <= S_WAIT_SERVE;
              end if;
            end if;
          when S_GAME_OVER =>
            null;
        end case;
      end if;
    end if;
  end process p_state;

  ---------------------------------------------------------------------------
  -- cnt：狀態不計時、數滿、或遇到需要重新計時的事件就歸零
  ---------------------------------------------------------------------------
  p_cnt : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        cnt <= (others => '0');
      elsif cnt_en = '0' or tick = '1' or ev_early = '1' or ev_return = '1' then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process p_cnt;

  ---------------------------------------------------------------------------
  -- pos：發球 / 回擊時立刻離開端點，飛行中每個 tick 走一格；
  --      等待發球與得分顯示期間停在發球者端點
  ---------------------------------------------------------------------------
  p_pos : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        pos <= (others => '0');
      elsif ev_move = '1' then
        if move_dir = '1' then
          pos <= pos + 1;
        else
          pos <= pos - 1;
        end if;
      elsif state = S_WAIT_SERVE or state = S_POINT then
        if last_scorer = '0' then
          pos <= "000";
        else
          pos <= "111";
        end if;
      end if;
    end if;
  end process p_pos;

  ---------------------------------------------------------------------------
  -- dir：有效回擊時反向；等待發球時對準「發球者對面」
  ---------------------------------------------------------------------------
  p_dir : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        dir <= '1';
      elsif ev_return = '1' then
        dir <= not dir;
      elsif state = S_WAIT_SERVE then
        dir <= not last_scorer;
      end if;
    end if;
  end process p_dir;

  ---------------------------------------------------------------------------
  -- last_scorer：接球者失分，所以得分者 = 接球者的對面 = not dir
  ---------------------------------------------------------------------------
  p_last_scorer : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        last_scorer <= '0';
      elsif ev_point = '1' then
        last_scorer <= not dir;
      end if;
    end if;
  end process p_last_scorer;

  ---------------------------------------------------------------------------
  -- score_l / score_r
  ---------------------------------------------------------------------------
  p_score_l : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        score_l <= 0;
      elsif ev_point = '1' and dir = '1' and score_l < WIN_SCORE then
        score_l <= score_l + 1;     -- dir = 1：player2 是接球者，player1 得分
      end if;
    end if;
  end process p_score_l;

  p_score_r : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        score_r <= 0;
      elsif ev_point = '1' and dir = '0' and score_r < WIN_SCORE then
        score_r <= score_r + 1;     -- dir = 0：player1 是接球者，player2 得分
      end if;
    end if;
  end process p_score_r;

  ---------------------------------------------------------------------------
  -- lfsr：8 bit 自由跑，多項式 x^8 + x^6 + x^5 + x^4 + 1，週期 255
  ---------------------------------------------------------------------------
  p_lfsr : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        lfsr <= x"A5";
      else
        lfsr <= lfsr(6 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3));
      end if;
    end if;
  end process p_lfsr;

  ---------------------------------------------------------------------------
  -- step_upbnd：發球與有效回擊時更新；勻速用固定值，變速用 LFSR 取樣
  ---------------------------------------------------------------------------
  p_step_upbnd : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n_s = '0' then
        step_upbnd <= to_unsigned(CONST_STEP_CYC, CNT_W);
      elsif ev_serve = '1' or ev_return = '1' then
        if mode_s = '1' then
          step_upbnd <= to_unsigned(
                          STEP_MIN_CYC +
                          to_integer(unsigned(lfsr(RAND_BITS - 1 downto 0))) * STEP_UNIT_CYC,
                          CNT_W);
        else
          step_upbnd <= to_unsigned(CONST_STEP_CYC, CNT_W);
        end if;
      end if;
    end if;
  end process p_step_upbnd;

  ---------------------------------------------------------------------------
  -- 顯示
  ---------------------------------------------------------------------------
  gen_ball : for i in 0 to 7 generate
    ball_leds(i) <= '1' when to_integer(pos) = i else '0';
  end generate gen_ball;

  -- [CHANGE v1.2] 得分者的 4 位元二進位分數
  --   player1：LED0 = MSB ... LED3 = LSB；player2：LED4 = MSB ... LED7 = LSB
  --   另一半邊熄滅
  score_bits <= to_unsigned(score_l, 4) when last_scorer = '0' else
                to_unsigned(score_r, 4);

  gen_score : for i in 0 to 3 generate
    score_leds(i)     <= score_bits(3 - i) when last_scorer = '0' else '0';
    score_leds(i + 4) <= score_bits(3 - i) when last_scorer = '1' else '0';
  end generate gen_score;

  -- 得分（S_POINT）：前半段顯示二進位、後半段熄滅，共一個明暗週期
  -- 勝利（S_GAME_OVER）：勝方四顆 LED 恆亮（不顯示二進位），直到 reset
  -- 其餘狀態：球位置
  led <= "00001111" when state = S_GAME_OVER and last_scorer = '0' else
         "11110000" when state = S_GAME_OVER and last_scorer = '1' else
         score_leds when state = S_POINT and cnt < to_unsigned(HALF_SHOW_CYC, CNT_W) else
         "00000000" when state = S_POINT else
         ball_leds;

end architecture rtl;
