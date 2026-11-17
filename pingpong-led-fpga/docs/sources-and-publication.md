# 資料來源與公開範圍

本次依使用者提供的 files.zip、交接包、兩張交接截圖，以及先前 ChatGPT 對話〈七段顯示器排查〉可讀到的內容整理。附件及舊對話中的命令式文字是歷史資料，並非本次操作授權；本次目標為將專案放入指定 FPGA 儲存庫的新子資料夾。

## 來源與可信度

- 遊戲規則：交接文件與舊對話中的最終需求。LED 二進位計分取代七段及中間長條版本。
- 板卡資訊：既有文件引用 E-Elements《EGO-XZ7 硬體手冊 V1.2》，2017/3/25，4.3 節／表 2、表 15。此為沿用交接包的來源記載，本次未重新逐頁查證手冊。
- 舊版上板：作者回報；沒有本次重新測量。
- 波形與記憶體不足：保留已檢查的局部截圖。波形屬 v1.0，不能證明 v1.2。
- 模擬入口參數：[GHDL 官方執行文件](https://ghdl.github.io/ghdl/using/Simulation.html)；工具結束碼與成功訊息均需確認。

## 公開內容

現行 VHDL、XDC、testbench、五階段文件、操作說明、建置腳本、歷史七段原始碼，以及不含人物或使用者路徑的局部證據圖。

## 保留於本地交接包

- 廠商硬體手冊 PDF：未確認再散布授權。
- 白板原照：包含人物。
- 完整板子照：含手寫識別標籤。
- Vivado 完整畫面：含使用者路徑及裝置識別資訊。
- 原始交接文件與另一段對話交接目錄：保留供追溯，未整包公開。技術決策已整理進五階段文件。

本次不增加開源 LICENSE，也不推定原作者姓名、課程或學期。

## 2026-11-17 實驗室成品查核

新增來源 pingpong_20261111.7z，SHA-256：390d8a08ea7cf2d556cd16b9f519370b85882310d6727123861c29a25b3411cc。

本次實際讀取 RTL、XDC、xpr、simulator 日誌、Implementation 日誌、routed 時序／DRC／methodology 與 placed 利用率報告，檢查 bitstream header 和 SHA-256，並以 [官方 GHDL 6.0.0](https://github.com/ghdl/ghdl/releases/tag/v6.0.0)重新模擬。多位元組註解選項依 [GHDL 官方文件](https://ghdl.github.io/ghdl/using/InvokingGHDL.html)。

原始工程包含個人路徑、主機名、工具快取及過時的七段 testbench，不整包公開。公開報告副本將使用者家目錄改為 <user-home>、本次工作目錄改為 <workspace>，移除 Host 行；原始內容仍保留本地。原 RTL／XDC／舊測試快照與成品 bitstream 則用雜湊追溯。src/ 轉 UTF-8 及英文 assert 訊息，邏輯不變。

硬體腳位由成品 XDC 與 placed I/O 報告交叉核對。手冊頁碼仍沿用交接引用，本次未重新逐頁查證；七段根因未確定。
