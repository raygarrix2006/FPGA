# Changelog

## v1.2（目前版本）
- 分數改為 **4 位元二進位**顯示在得分者那半邊（player1：LED0 最高位元；player2：LED4 最高位元），顯示時間前半亮、後半熄滅
- 勝利改為**勝方那半邊四顆 LED 恆亮**（第 5 分先顯示一次 0101 再進入恆亮）
- **七段顯示器棄用**：移除 `seg` 埠、`SEG_ACTIVE_LOW`、七段碼函式，XDC 不含七段腳位
- `WIN_SCORE` 範圍 1..15（4 位元上限）
- 兩個 `assert` 訊息改為英文
- testbench 改寫以檢查二進位與恆亮
- 新增 `scripts/build_batch.tcl`（未實測）
- 新增完整文件（需求、分析、設計、程式、驗證、使用說明）與交接紀錄
- 狀態：**尚未編譯與模擬**；使用者的 Vivado 2018.3 在 Implementation 發生 Out of memory，尚未取得 bitstream

## v1.1（中間版本，已被取代）
- 曾把分數改為 LED 長條；後來被 v1.2 的二進位需求取代，原始碼不保留

## v1.0
- 完成：FSM、計時、計分、LFSR 變速、輸入整理
- 分數用七段顯示
- Vivado 模擬完整跑完（波形見 `docs/images`）；上板球與獲勝邏輯正常，七段無反應
- 程式保存在 `archive/pingpong_7seg_v1.0.vhd`
