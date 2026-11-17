-- btn_cond.vhd
-- 輸入整理：2 級同步器 -> 去彈跳 -> 邊緣脈波
-- 一個 process 只驅動一個 signal
library ieee;
use ieee.std_logic_1164.all;

entity btn_cond is
  generic (
    DEB_CYC : integer range 2 to 100_000_000 := 1_000_000  -- 去彈跳 clock 數
  );
  port (
    clk   : in  std_logic;
    din   : in  std_logic;   -- 外部非同步輸入
    level : out std_logic;   -- 去彈跳後的穩定準位
    pulse : out std_logic    -- 穩定準位上升沿，單一 clock 寬
  );
end entity btn_cond;

architecture rtl of btn_cond is
  -- 初值 '0'：上電後 level 先為 0，之後才依實際輸入更新
  signal sync_ff : std_logic_vector(1 downto 0) := "00";
  signal db_cnt  : integer range 0 to DEB_CYC - 1 := 0;
  signal stable  : std_logic := '0';
  signal prev    : std_logic := '0';
begin

  -- sync_ff：2 級同步器
  p_sync_ff : process(clk)
  begin
    if rising_edge(clk) then
      sync_ff <= sync_ff(0) & din;
    end if;
  end process p_sync_ff;

  -- db_cnt：輸入與穩定值不同時計時，相同則歸零
  p_db_cnt : process(clk)
  begin
    if rising_edge(clk) then
      if sync_ff(1) = stable then
        db_cnt <= 0;
      elsif db_cnt /= DEB_CYC - 1 then
        db_cnt <= db_cnt + 1;
      end if;
    end if;
  end process p_db_cnt;

  -- stable：不同狀態持續滿 DEB_CYC 才接受新值
  p_stable : process(clk)
  begin
    if rising_edge(clk) then
      if sync_ff(1) /= stable and db_cnt = DEB_CYC - 1 then
        stable <= sync_ff(1);
      end if;
    end if;
  end process p_stable;

  -- prev：stable 延遲一拍，用來偵測上升沿
  p_prev : process(clk)
  begin
    if rising_edge(clk) then
      prev <= stable;
    end if;
  end process p_prev;

  level <= stable;
  pulse <= stable and not prev;

end architecture rtl;