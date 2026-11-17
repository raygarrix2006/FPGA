# 05 驗證（Verification）

查核日期：2026-11-17。基準：2026-11-11 實驗室成品。分開記錄原始建置、重新模擬及使用者實機回報。

## 5.1 結論與證據

| 項目 | 結果 | 依據／限制 |
|---|---|---|
| 合成／Implementation | 實驗室成功 | [原始建置日誌去識別版](evidence/lab-runme.txt)，opt、place、route、write_bitstream 均成功 |
| bitstream | 確實存在，4,045,668 bytes | [成品檔](../artifacts/lab-20261111/pingpong.bit)；header 日期 2026/11/11 18:02:48；[原檔 SHA-256](evidence/lab-original.sha256) |
| 已約束內部時序 | 通過，WNS 2.690 ns、WHS 0.180 ns、TNS／THS 0 | [routed 報告](evidence/lab-pingpong_timing_summary_routed.rpt)；非所有外部時序已驗證 |
| 外部時序警告 | 12 個 TIMING-18 | [methodology](evidence/lab-pingpong_methodology_drc_routed.rpt)：4 輸入與 8 LED 輸出缺 delay |
| 資源 | 138 LUT、162 FF、0 latch | [placed 利用率](evidence/lab-pingpong_utilization_placed.rpt)；不是本次重跑 |
| DRC | 1 個 ZPS7-1 Warning（PS7 block required） | [routed DRC](evidence/lab-pingpong_drc_routed.rpt)；不能代替外部時序或實機測試 |
| 本次 LED 遊戲模擬 | T1～T9 通過 | GHDL 6.0.0 mcode，[本次完整輸出](evidence/current-ghdl.txt) |
| 本次按鍵模擬 | B1～B6 通過 | 同一日誌，含短彈跳、長按及再按 |
| LFSR | 通過，週期 255 | tools/lfsr_check.py 重新執行；不代表隨機取樣分布已測完 |
| 實機／老師檢查 | 作者回報整體功能正常 | 2026-11-17 使用者說明，上週實驗室完成並給老師檢查；未有逐項簽核／影片 |

目前 src 與成品的差異僅編碼、assert 訊息；成品參數範圍保留 1..9。原始位元組在 archive/lab-20261111。此電腦沒有重跑 Vivado 或重新燒錄，不能把本次 RTL 模擬當作本次實機測試。

## 5.2 舊模擬紀錄的問題

[包內舊模擬日誌](evidence/lab-simulate.txt)同時存在 T7 step=84／85 clk 的 failure 和最後 ALL TESTS PASSED。不能只看最後一行宣稱通過。附帶 testbench 仍有 seg 介面，也不相容於最終 LED 頂層，故不列為成品模擬通過證據。

本次先對前次 GitHub LED testbench 重跑，在 76225 ns 重現 T7 step=84 clk 失敗，見 [修正前輸出](evidence/github-before-t7.txt)。press 程序包含按下、放開及等待；它返回時 LED1 可能已經亮了一段時間，後續計數只量到剩餘時間。這是量測起點錯誤，不能據此判定遊戲步長錯誤。

修正後先等 LED2 新區間，再量至 LED3。四輪完整步長為 150、250、250、150 clk，均在測試參數的 100～250 clk 範圍。這四輪沒有涵蓋所有可取步長，也未證明分布均勻。

## 5.3 測試與需求對照

| 測試 | 內容 | 對應需求／結果 |
|---|---|---|
| T1 | reset 後 LED0 | FR-02、03、10；通過 |
| T2 | 發球、到端點、有效回擊、反向 | FR-02、03、04；通過 |
| T3 | 太晚失分、右方 1 分、亮暗 | FR-05、08；通過 |
| T4 | 太早失分、右方 2 分 | FR-06、08；通過 |
| T5 | 非發球者按鍵忽略 | FR-03；通過 |
| T6 | 右方 3～5 分，獲勝恆亮／按鍵忽略 | FR-07、08；通過 |
| T7 | 變速完整步長、左方 1～4 分 | FR-08、09；通過 |
| T8 | 飛離時再按忽略、飛行中 reset／保持 | FR-06、10；通過 |
| T9 | 左方 1～5 分、獲勝恆亮／按鍵忽略 | FR-07、08；通過 |
| B1～B6 | 按鍵整理短彈跳、長按不重複、再按 | FR-11；通過 |

執行：python3 scripts/simulate.py。腳本遇 assert error/failure 即停止，另檢查退出碼、兩個成功標記與 120 秒每步 timeout；模擬時間上限 5 ms。通過訊息分別為 ALL TESTS PASSED、ALL BUTTON TESTS PASSED。

## 5.4 仍未驗證的邊界

- 同拍回擊與 tick 的優先順序目前由 RTL 審查確認，尚無專屬精準對拍測試。
- 每次有效回擊重新鎖存速度、切換 mode 後整趟固定、全部 LFSR 取樣值與分布尚未完整測試。
- 所有合法 generic 組合並未掃描；本次為 WIN_SCORE=5、縮短時間的測試參數。
- 兩級同步器降低亞穩態風險；RTL 模擬無法驗證類比亞穩態或真實機械彈跳的全部情形。
- 老師檢查是整體功能回報，不代填逐項實機測試通過。
- DRC 還有 ZPS7-1（PS7 block required）警告；本次未變更 PS／PL 配置，成功產生 bitstream 不表示此警告已消除。
- TIMING-18 須依真實外部介面補充建模／審查，不能用任意 delay 或 blanket false path 隱藏警告。

## 5.5 七段與 OOM 歷史

七段曾以不同極性及獨立測試仍未亮，之後依作者決策改 LED 二進位。缺乏足夠電路／量測證據，不能斷言七段「必定不能由程式控制」或硬體已故障。

先前家用 Vivado 2018.3 出現 Out of memory；實驗室包則確有成功 bitstream。兩者屬不同環境的證據，成功成品不表示家用 OOM 根因已解決。[歷史錯誤截圖](images/vivado_2018_3_opt_design_oom.png)保留作追溯。

## 5.6 實機紀錄

作者回報日期 2026-11-17；成品檔案／報告日期 2026-11-11。整體功能已給老師檢查、正常。詳細的上下 LED 操作、每分顯示、兩邊獲勝、按鍵手感等未提供分項紀錄；若後續補拍，可記錄日期、bitstream SHA-256、板卡版本、測項與影片連結。

