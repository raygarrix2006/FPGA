# 04 程式實作

## 原始碼組織

| 檔案 | 用途 |
|---|---|
| src/pingpong.vhd | 頂層：狀態機、事件、球位置、計時、計分與 LED 顯示 |
| src/btn_cond.vhd | 輸入同步、去彈跳及單週期按鍵事件 |
| constraints/pingpong.xdc | EGO-XZ7 腳位、LVCMOS33 與 100 MHz 時脈約束 |
| sim/tb_pingpong.vhd | 遊戲自我檢查測試 T1～T9 |
| sim/tb_btn_cond.vhd | 按鍵整理測試 B1～B6 |
| scripts/simulate.py | 執行兩個 GHDL testbench 並檢查結果 |
| scripts/create_project.tcl | Vivado 工程建立入口 |
| tools/lfsr_check.py | LFSR 週期檢查 |

RTL 以實驗室成品為基準，保留既有狀態機與各暫存器的單一驅動結構。來源採 UTF-8 註解，assert 訊息使用英文以維持工具相容性。

## Vivado 建置

1. 建立 RTL Project，part 選 xc7z020clg484-1。
2. 加入 Design Sources：src/btn_cond.vhd、src/pingpong.vhd。
3. 加入 Constraints：constraints/pingpong.xdc。
4. 加入 Simulation Sources：sim/ 下的兩份 testbench。
5. 設計頂層選 pingpong；遊戲模擬頂層選 tb_pingpong。
6. 執行 Synthesis、Implementation、Generate Bitstream。

亦可在專案資料夾的 Tcl Console 執行 source scripts/create_project.tcl 建立工程。此工程建立腳本尚未以 Vivado 重新執行；實驗室既有工程的建置成功紀錄與此腳本分開看待。

行為模擬執行 run all；按鍵獨立模擬將頂層改為 tb_btn_cond。燒錄使用 Hardware Manager 連接 JTAG、選取產生的 bitstream。板卡 JTAG 模式及電源接法應依實板標示與硬體手冊設定。

## GHDL 模擬

需求：Python 3、GHDL。從 pingpong-led-fpga 資料夾執行：

```sh
python3 scripts/simulate.py
python3 tools/lfsr_check.py
```

Windows 可使用對應的 Python 3 命令名稱。模擬入口使用 VHDL-93 與 --mb-comments 支援 UTF-8 註解，並設定 --assert-level=error。任一編譯錯誤、assert、逾時或缺少成功標記皆回傳非零結束碼。

輸出日誌與 VCD 波形位於 build/ghdl/，由 .gitignore 排除。有效結果須同時包含 ALL TESTS PASSED、ALL BUTTON TESTS PASSED，且執行結束碼為 0。
