# 實驗室原始快照（2026-11-11）

此目錄保留成品壓縮包內的原始來源位元組；兩份 RTL 及舊 testbench 為 CP950，不是 UTF-8。不要把本目錄加入現行 Vivado 工程。

目前 src/ 以這份實驗室 RTL 為基準，僅轉 UTF-8 並將兩個 assert 訊息改成英文，邏輯及 WIN_SCORE=1..9 均保留。XDC 與實驗室檔案內容一致。

tb_pingpong_7seg.vhd 仍含 seg 介面，不相容於成品頂層，僅供歷史分析。舊模擬紀錄有 T7 failure，即使結尾出現成功訊息也不能視為通過。
