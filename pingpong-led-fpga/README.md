# FPGA 乒乓球 LED — EGO-XZ7 / VHDL

兩位玩家用 BTNL／BTNR 對打，以 LED0～LED7 表示球的位置；每回合以得分者半邊的四顆 LED 顯示二進位分數。先得 5 分獲勝，勝方半邊恆亮；七段不使用。

[五階段總覽](docs/README.md) · [需求追溯](docs/traceability.md) · [架構圖](docs/03-design.md) · [驗證證據與限制](docs/05-verification.md) · [操作說明](docs/user-guide.md)

## 五階段開發文件

| 階段 | 文件與產出 |
|---|---|
| 1. 需求 | [規則、範圍與驗收](docs/01-requirements.md) |
| 2. 分析 | [硬體、事件、時間、風險](docs/02-analysis.md) |
| 3. 設計 | [成品架構、FSM、訊號與二進位對照](docs/03-design.md) |
| 4. 程式實作 | [來源、工程重建與修改說明](docs/04-implementation.md) |
| 5. 驗證 | [模擬、建置、時序與實機回報](docs/05-verification.md) |

## 目前驗證狀態

| 項目 | 結果 |
|---|---|
| 實驗室合成／實作／bitstream | 包內日誌證實成功；成品 4,045,668 bytes |
| 本次 RTL 模擬 | T1～T9、按鍵 B1～B6 通過，GHDL 6.0.0 mcode |
| LFSR | Python 重新驗證週期 255 |
| 實驗室時序 | WNS 2.690 ns、WHS 0.180 ns；已設定約束均滿足 |
| 待處理限制 | 12 個 TIMING-18（I/O delay 缺失）、1 個 ZPS7-1（PS7 block required）；精準對拍與變速完整覆蓋待補 |
| 實機驗收 | 作者回報老師已檢查、正常；未提供逐項簽核／影片 |


## 專案結構

```text
pingpong-led-fpga/
├── README.md
├── src/                         # 成品 RTL，UTF-8
├── constraints/pingpong.xdc      # 成品腳位，無七段
├── sim/                         # 遊戲與按鍵兩個自我檢查 bench
├── docs/                        # 五階段、追溯、操作及證據
├── scripts/                     # Vivado 工程與 GHDL 模擬入口
├── tools/lfsr_check.py
├── artifacts/lab-20261111/       # 原始成品 bitstream
└── archive/                     # 原始 CP950 快照及七段歷史，勿加入工程
```

## 建置與操作

目標 part：xc7z020clg484-1，100 MHz。Vivado 直接選 part 建立工程，加入 src/、constraints/ 與 sim/；不要匯入 archive/。詳細步驟在第 4 階段。

在本專案資料夾、具 Python 3 與 GHDL 的環境執行：

```sh
python3 scripts/simulate.py
python3 tools/lfsr_check.py
```

結果／波形在 build/ghdl/。燒錄可使用 [實驗室 bitstream](artifacts/lab-20261111/pingpong.bit)，先核對 [原始雜湊](docs/evidence/lab-original.sha256)。SW7 低為 reset、高為運作；SW0 為勻速／變速。發球後才移動，太早或太晚回擊讓對手得分。

player1 分數使用 LED0～3（LED0 為 MSB），player2 使用 LED4～7（LED4 為 MSB）；這是 LED 編號順序，不是文字字串的左右位置。前半秒顯示、後半秒熄滅，第 5 分後勝方四顆恆亮。WIN_SCORE 成品範圍為 1..9，預設 5。

## 來源與授權

技術結論以原始碼、報告、重跑及明確回報分層核對，見 [來源與公開範圍](docs/sources-and-publication.md)。

維護帳號：[raygarrix2006](https://github.com/raygarrix2006)

