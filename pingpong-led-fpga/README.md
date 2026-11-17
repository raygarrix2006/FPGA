# 乒乓球 LED（Ping-Pong LED）— EGO-XZ7 / Zynq-7020 / VHDL

> **閱讀起點**：[五階段總覽](docs/README.md) → [需求追溯表](docs/traceability.md) → [目前狀態與待辦](docs/project-status.md)。
> 本專案位於 [FPGA 儲存庫的 pingpong-led-fpga 子資料夾](https://github.com/raygarrix2006/FPGA/tree/main/pingpong-led-fpga)，與既有 hw2 作業分開。
> **v1.2 尚無成功模擬、bitstream 或上板結果。** 歷史波形屬 v1.0，不能作為新版通過的證據。


用一排 LED 當球、兩個按鍵當球拍的雙人乒乓球遊戲。在 E-Elements **EGO-XZ7**（Zynq XC7Z020-CLG484）的 PL 端以 **VHDL** 實作，使用 Vivado 開發。

這是一份數位設計／FPGA 課程作業，也是一次完整走過**軟體開發五個週期**的練習：**需求 → 分析 → 設計 → 程式 → 驗證**，每一階段都有對應文件。

## 遊戲玩法（一分鐘版）

- 兩位玩家：player1 按 **BTNL**，player2 按 **BTNR**。
- LED0–LED7 是球道，球從發球者那端飛向對面。
- 球到端點 LED 時，接球者要在那一段時間內按鍵回擊，球就反向飛回。
- **太晚**（時間到沒按）或**太早**（球還在飛向你就按）都算失分，對手得 1 分。
- 得分者發球；先得 5 分獲勝。
- **得分顯示**：得分者那半邊用 **4 位元二進位**顯示分數（player1：LED0 最高位元；player2：LED4 最高位元），亮半秒、熄半秒。
- **獲勝**：勝方那半邊四顆 LED 恆亮，直到 reset。
- **SW0**：勻速／隨機變速；**SW7**：往上運作、往下 reset。

完整操作請看 [使用說明](docs/user-guide.md)。

## 專案狀態

| 項目 | 狀態 |
|---|---|
| 五階段文件 | 已整理；驗證計畫已寫，驗證執行仍有待完成項目 |
| v1.0（七段顯示版）Vivado 模擬 | 完整跑完（波形見 `docs/images`）；Console 輸出未取得 |
| v1.0 上板 | 球、按鍵、reset、5 分獲勝（勝方四顆 LED 恆亮）運作；**七段顯示器不亮** |
| **v1.2（目前版本，LED 二進位計分）編譯與模擬** | **尚未執行** |
| v1.2 Implementation | **失敗：Vivado 2018.3 `Out of memory`**（原因未定，見驗證文件 5.6） |
| v1.2 上板 | **尚未執行** |

七段顯示器實測無法點亮（含獨立測試設計），已決定**棄用**，改用 LED 顯示分數。詳見 [驗證文件 5.7](docs/05-verification.md)。

## 開發文件（五個週期）

| 階段 | 文件 | 內容 |
|---|---|---|
| 1. 需求 | [docs/01-requirements.md](docs/01-requirements.md) | 白板需求轉錄、功能／非功能需求、決策與變更紀錄 |
| 2. 分析 | [docs/02-analysis.md](docs/02-analysis.md) | 硬體資源、狀態與事件、時間與亂數分析、風險 |
| 3. 設計 | [docs/03-design.md](docs/03-design.md) | 架構圖、參數、腳位、訊號、更新規則、設計決策 |
| 4. 程式 | [docs/04-implementation.md](docs/04-implementation.md) | 檔案、寫法規範、建置、修改指引 |
| 5. 驗證 | [docs/05-verification.md](docs/05-verification.md) | 測試計畫、結果、需求追溯、已知問題 |
| 使用說明 | [docs/user-guide.md](docs/user-guide.md) | 燒錄、操作、LED 意義、疑難排解 |

## 專案結構

```
.
├── README.md
├── CHANGELOG.md
├── src/
│   ├── pingpong.vhd          # 頂層：FSM、計時、計分、LFSR、顯示
│   └── btn_cond.vhd          # 輸入整理：同步、去彈跳、邊緣脈波
├── sim/
│   └── tb_pingpong.vhd       # 自我檢查 testbench（T1–T7）
├── constraints/
│   └── pingpong.xdc          # EGO-XZ7 腳位與時脈（不含七段）
├── docs/                     # 五階段文件、使用說明、圖片
├── scripts/
│   ├── create_project.tcl    # 建立 Vivado 專案（未實際執行過）
│   └── build_batch.tcl       # 批次建置（未實際執行過）
├── tools/
│   └── lfsr_check.py         # 驗證 LFSR 週期為 255
└── archive/                  # 歷史資料，不要加入專案
    ├── pingpong_7seg_v1.0.vhd
    └── seg_test/
```

## 快速開始

1. 建立 Vivado 專案，Part 選 `xc7z020clg484-1`，加入 `src/*.vhd`、`sim/tb_pingpong.vhd`、`constraints/pingpong.xdc`，頂層設為 `pingpong`。
   （也可嘗試 `source scripts/create_project.tcl`，該腳本未實際執行過。）
2. 模擬：頂層選 `tb_pingpong`，`run all`，看 Console 是否出現 `ALL TESTS PASSED`。
3. 上板：SW8[4:2] 設為 `000`（JTAG），產生 bitstream 後燒錄。

細節見 [使用說明](docs/user-guide.md) 與 [程式文件](docs/04-implementation.md)。

## 設計重點

- 單一 100 MHz clock 的同步設計，不產生衍生 clock。
- **一個 signal 一個 process**；事件（`ev_*`）由組合邏輯產生，各暫存器只看事件更新。
- 時間、分數、亂數 bit 數都是 `generic`，改一處即可。
- 隨機變速用 8 bit **LFSR**（週期 255，已用 Python 驗證），只在發球／有效回擊時取樣。
- 所有按鍵與開關都經過 2 級同步器、去彈跳與邊緣偵測。

## 硬體與環境

- 開發板：E-Elements EGO-XZ7（板上標示 Ver.B），Zynq XC7Z020-CLG484-1
- 資源：100 MHz PL 時脈（Y9）、8 顆 LED、8 個撥動開關、5 個按鍵
- 腳位來源：*EGO-XZ7 硬體手冊 V1.2*（E-Elements，2017/3/25）表 2、表 15
- IO 標準 LVCMOS33 為課程板子的慣例（手冊未記載）
- 作者環境：Vivado 2018.3、Windows、8 GB RAM

## 已知問題

- **Vivado 2018.3 Implementation 發生 `Out of memory`**，尚未取得 v1.2 的 bitstream。原因未確定，見 [驗證文件 5.6](docs/05-verification.md)。
- **七段顯示器棄用**：實板有兩顆七段（D9、D1），手冊只記載一顆，實測無法點亮。
- BTNL／BTNR 的實體位置為依手冊與照片推論，需以實測為準。
- 變速最快 150 ms，回擊窗口可能偏短，需上板調整參數。
- v1.2 尚未經過編譯與模擬。

## 後續方向

依課堂白板：**VGA 版本**，以及**兩塊以上板子互打**。這些不在本專案範圍內。

## 作者與授權

- 維護帳號：[raygarrix2006](https://github.com/raygarrix2006)；作者、課程與學期尚未提供，未代填。
- 尚未選定開源授權；公開原始碼不等於已授予開源授權。

## 本次整理與可重現檢查

本次僅整理文件、公開資料範圍與執行入口；現行 RTL、XDC 和 testbench 保持交接版本。

在此專案資料夾執行：

```sh
python3 tools/lfsr_check.py
python3 scripts/simulate.py
```

Windows 可使用已安裝的 Python 3 執行上述檔案。第二項另需 GHDL；會明確檢查結束碼與 `ALL TESTS PASSED`，結果寫入 `build/ghdl/simulation.log`。本次環境未找到 GHDL，這個新入口尚未實跑，不代表測試已通過。Vivado 流程仍以 [第 4 階段](docs/04-implementation.md) 為準。

資料來源與公開範圍見 [來源說明](docs/sources-and-publication.md)。
