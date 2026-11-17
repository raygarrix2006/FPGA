# 04 程式實作（Implementation）

## 4.1 現行來源與版本

基準為 pingpong_20261111.7z 中 2026-11-11 的實驗室成品。src/pingpong.vhd、src/btn_cond.vhd 由 CP950 轉為 UTF-8，僅兩個 assert 訊息改為英文；遊戲邏輯未重構。WIN_SCORE 採實驗室的 1..9，預設 5。constraints/pingpong.xdc 直接沿用成品。

| 目錄／檔案 | 用途 |
|---|---|
| src/ | 當前可建置的兩份 RTL；各訊號單一驅動來源 |
| constraints/pingpong.xdc | 13 個埠的腳位／LVCMOS33，100 MHz clock；無 seg |
| sim/tb_pingpong.vhd | LED 版 T1～T9；T7 改量完整步長，新增飛離忽略、途中 reset、左方獲勝 |
| sim/tb_btn_cond.vhd | B1～B6：短彈跳、穩定按下、長按、釋放彈跳、釋放、再次按下 |
| scripts/simulate.py | GHDL 編譯、兩個 bench、嚴格 assert、成功標記與 timeout 檢查 |
| scripts/create_project.tcl | 建立可搬移的 Vivado 專案，直接選 part；未在本機 Vivado 實跑 |
| scripts/build_batch.tcl | 非專案模式建置；未在本機 Vivado 實跑 |
| archive/lab-20261111/ | 原始位元組快照；舊七段 testbench 僅供參考 |
| artifacts/lab-20261111/pingpong.bit | 原始成品 bitstream；非本次重新合成結果 |
| docs/evidence/ | 去除使用者路徑／主機名的報告與重跑日誌 |

## 4.2 設計紀律

維持一個暫存器 signal 一個 process，事件使用並行組合邏輯。只用 clk 上升緣及計數 enable，不產生衍生 clock。命名與架構圖逐項對照，沒有為文件整理拆改已驗收的遊戲 RTL。

## 4.3 執行模擬

安裝 Python 3 與 GHDL，從 pingpong-led-fpga 資料夾執行：

```sh
python3 scripts/simulate.py
python3 tools/lfsr_check.py
```

Windows 可將 python3 換成已安裝 Python 3 的命令名稱。GHDL 本次使用 6.0.0 mcode；腳本的 --mb-comments 允許 UTF-8 註解，--assert-level=error 遇到錯誤即停止。完整輸出在 build/ghdl/simulation.log，波形同目錄。需兩個成功標記均出現且結束碼為 0。

## 4.4 建立 Vivado 工程

Vivado Tcl Console 在專案資料夾執行 source scripts/create_project.tcl；或手動建立 xc7z020clg484-1 工程，只加入 src/、constraints/pingpong.xdc 與 sim/。Design top 為 pingpong；Simulation top 為 tb_pingpong，按鍵獨立測試則選 tb_btn_cond。執行 run all，assert 設為失敗停止。

勿把 archive/、實驗室 .xpr 或其快取整包加入。原 .xpr 的 zc702 board_part 不作為 EGO-XZ7 的板卡識別依據。

## 4.5 本次修正與限制

- 還原成品參數上限 9，取代前次整理版擴出的 15。
- 修正 T7 從已經過一部分的 LED1 區間開始量測，改等 LED2 新區間開始後量到 LED3。
- 加入多位元組註解選項；修正前次尚未實測的 GHDL 執行入口。
- 新增 T8、T9 與按鍵 bench，不更改遊戲行為來配合測試。
- 本次通過 RTL 模擬；沒有在此電腦重新跑 Vivado 合成、實作或燒錄。成品 bitstream、時序與資源報告屬 2026-11-11。
