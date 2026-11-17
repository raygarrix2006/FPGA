# FPGA LED 乒乓球

以 VHDL 在 EGO-XZ7 開發板實作雙人乒乓球遊戲。八顆 LED 顯示球的位置，兩個按鍵控制發球與回擊；支援失誤判定、二進位計分及偽隨機變速。

## 系統規格

| 項目 | 規格 |
|---|---|
| 開發板／FPGA | EGO-XZ7／XC7Z020-CLG484-1 |
| 語言／開發工具 | VHDL／Vivado 2018.3 |
| 系統時脈 | 100 MHz |
| 操作介面 | BTNL、BTNR、SW0、SW7、LED0～LED7 |
| 勝利條件 | 先得 5 分；參數支援 1～9 分 |

## 操作方式

SW7 為低時重置，高時運作。Player 1 按 BTNL 發球；球抵達對方端點時，接球者按鍵回擊。太早按鍵或超過端點回擊時間均判失分，由得分者發下一球。SW0 為低時每步 250 ms，為高時在發球或有效回擊時重新決定下一趟速度。

得分時，Player 1 使用 LED0～3、Player 2 使用 LED4～7 顯示該方二進位分數，最高位元分別為 LED0、LED4。前 0.5 秒顯示，後 0.5 秒熄滅；獲勝後勝方四顆 LED 恆亮，直到重置。

## 開發文件

| 階段 | 內容 |
|---|---|
| 1. [需求](docs/01-requirements.md) | 功能規格、範圍與驗收條件 |
| 2. [分析](docs/02-analysis.md) | 硬體資源、時序與事件優先順序 |
| 3. [設計](docs/03-design.md) | 系統架構、狀態機及訊號分工 |
| 4. [實作](docs/04-implementation.md) | 原始碼組織、建置與模擬方式 |
| 5. [驗證](docs/05-verification.md) | 測試覆蓋、實作結果及限制 |

## 建置與驗證

在 Vivado 建立 part 為 xc7z020clg484-1 的工程，加入 src/ 的兩份 VHDL 與 constraints/pingpong.xdc，設計頂層為 pingpong。詳細流程見實作文件。

已安裝 Python 3 與 GHDL 的環境可在此資料夾執行：

```sh
python3 scripts/simulate.py
python3 tools/lfsr_check.py
```

遊戲 T1～T9、按鍵 B1～B6 模擬通過。實驗室建置完成合成、實作與 bitstream 產生；100 MHz 約束下 WNS 為 2.690 ns、WHS 為 0.180 ns。實機功能經授課教師檢查，依專案作者驗收說明記錄。測試依據與未涵蓋項目見驗證文件。

## 目錄

```text
src/          VHDL 設計
constraints/  腳位與時脈約束
sim/          自我檢查 testbench
scripts/      工程建立與模擬入口
tools/        LFSR 週期檢查
docs/         五階段技術文件
reports/      模擬、時序與資源報告
```
