# 04 程式（Implementation）

> 軟體開發五個週期的第 4 階段。說明程式的組織、寫法規範、建置方式與修改指引。

## 4.1 檔案

| 檔案 | 說明 |
|---|---|
| `src/pingpong.vhd` | 頂層，包含 FSM、計時、計分、亂數、顯示 |
| `src/btn_cond.vhd` | 輸入整理：同步、去彈跳、邊緣脈波 |
| `sim/tb_pingpong.vhd` | 自我檢查 testbench（T1–T7） |
| `constraints/pingpong.xdc` | 腳位與時脈約束（純 ASCII 註解） |
| `scripts/create_project.tcl` | 建立 Vivado 專案的 Tcl（**未實際執行過**） |
| `scripts/build_batch.tcl` | 不開 GUI 的批次流程（synth → impl → bitstream），給記憶體不足時嘗試（**未實際執行過**） |
| `tools/lfsr_check.py` | 驗證 LFSR 週期為 255 |
| `archive/pingpong_7seg_v1.0.vhd` | 七段顯示版本（v1.0），僅供歷史參考，**不要加入專案** |
| `archive/seg_test/` | 七段診斷設計（已測試，仍無法點亮，不再使用） |

## 4.2 寫法規範

1. **一個 signal 一個 process**：每個暫存器各自有一個 `p_<訊號名>` process；組合邏輯用並行指定。
2. **命名**：process 以 `p_` 開頭、事件以 `ev_` 開頭、狀態以 `S_` 開頭、generic 全大寫。
3. **同步 reset**：所有 process 都用 `rst_n_s`（已同步、去彈跳）做同步重置。
4. **不使用衍生 clock**：時間一律由計數器產生 enable 脈波（`tick`）。
5. **註解**：區塊用 `---` 分隔線；與舊版不同的地方標 `[CHANGE]`。
6. **編碼**：VHDL 檔含繁體中文註解，請以 **UTF-8** 儲存與開啟。XDC 刻意只用 ASCII，避免 Vivado 編碼問題。
7. 沒有使用 VHDL-2008 專屬語法，預設的 VHDL 設定即可。

## 4.3 建置（Vivado）

> 使用者環境：Vivado 2018.3、Windows、8 GB RAM。

方法 A：使用腳本（**腳本未實際執行過**，若失敗請改用方法 B）

```tcl
cd <repo 根目錄>
source scripts/create_project.tcl
```

方法 B：手動

1. 建立專案，Part 選 `xc7z020clg484-1`（手冊圖 2）；或使用廠商提供的 `EGO-XZ7` 板卡檔。
2. 加入 Design Sources：`src/btn_cond.vhd`、`src/pingpong.vhd`。
3. 加入 Simulation Sources：`sim/tb_pingpong.vhd`。
4. 加入 Constraints：`constraints/pingpong.xdc`。
5. 頂層：Design 設為 `pingpong`，Simulation 設為 `tb_pingpong`。
6. Run Synthesis → Run Implementation → Generate Bitstream。
7. 燒錄方式見 `user-guide.md`。

## 4.4 常見修改

| 想改什麼 | 改哪裡 |
|---|---|
| 獲勝分數 | `WIN_SCORE`（1..15；預設 5） |
| 球速 | 勻速改 `CONST_STEP_MS`；變速改 `STEP_MIN_MS`、`STEP_UNIT_MS`、`RAND_BITS` |
| 得分顯示時間 | `SHOW_TIME_MS` |
| 兩位玩家按鍵對調 | `constraints/pingpong.xdc` 中 `btn_l` 與 `btn_r` 的腳位對調 |
| 球方向對調（LED0 與 LED7） | `pingpong.vhd` 的 `led` 輸出做位元反轉，或對調 XDC 的 LED 腳位 |

> 修改 generic 預設值後，記得同步檢查 testbench（它用自己的 generic map 縮短時間，不受預設值影響）。

## 4.5 與 v1.0（七段版）的差異

所有改動在程式內都有 `[CHANGE]` 標記：

- 移除埠 `seg`、generic `SEG_ACTIVE_LOW`、函式 `seg_pattern`、訊號 `disp_score`
- `WIN_SCORE` 範圍由 `1 to 9` 改為 `1 to 15`（4 位元二進位的上限）
- 新增常數 `HALF_SHOW_CYC`、訊號 `score_bits`、`score_leds`
- 顯示段改為：球 → 二進位（前半）→ 全暗（後半）；勝利時勝方四顆恆亮
- 兩個 `assert` 的訊息由中文改為英文（字串常值只保證支援 Latin-1，避免其他工具編譯出錯）
- 狀態機、計時、計分、亂數、輸入整理**邏輯完全沒有改動**

## 4.6 已知限制

- 目前版本（v1.2）撰寫時沒有 VHDL 編譯器可用，**尚未經過編譯與模擬**。v1.0 曾由使用者在 Vivado 模擬並看到完整跑完，並已上板確認球與獲勝邏輯，見 `05-verification.md`。
- 使用者環境的 Vivado 版本為 **2018.3**（Windows，8 GB RAM）；在該環境對目前版本執行 Implementation 時發生 `Out of memory`，見 `05-verification.md` 5.6。
- 同拍按鍵優先、彈跳等細節沒有專屬測試，見 05 的測試缺口。
