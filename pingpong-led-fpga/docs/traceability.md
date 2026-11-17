# 需求、設計、程式與驗證追溯

以下定位均指目前 v1.2；測項存在不等於已通過。詳細規則以 [需求](01-requirements.md)為準。

| 需求 | 分析／設計重點 | 程式定位 | 驗證與缺口 |
|---|---|---|---|
| FR-01 玩家輸入 | BTNL／BTNR 角色與腳位 | constraints/pingpong.xdc；u_btnl、u_btnr | 實板左右對應待正式記錄 |
| FR-02 球道顯示 | 3-bit pos、單顆 LED | p_pos、gen_ball | T1、T2；v1.2 待執行 |
| FR-03 發球 | S_WAIT_SERVE、得分者發球 | sv_hit、ev_serve、p_last_scorer | T1、T2、T5；待執行 |
| FR-04 回擊 | 端點窗口與反向 | ev_return、p_dir、p_pos | T2；待執行 |
| FR-05 太晚 | 窗口 tick 且無 rx_hit | ev_late、p_score_l、p_score_r | T3；待執行 |
| FR-06 太早／飛離忽略 | 接球者角色、飛行中按鍵 | rx_hit、ev_early | T4；飛離忽略缺專屬測項 |
| FR-07 獲勝 | S_GAME_OVER、WIN_SCORE | game_won、p_state、led | T6；左方獲勝缺專屬測項 |
| FR-08 分數顯示 | 半邊二進位、前亮後暗 | score_bits、gen_score、HALF_SHOW_CYC | T3、T4、T6、T7；待執行 |
| FR-09 變速 | LFSR 取樣、每趟固定步長 | p_lfsr、p_step_upbnd | T7 僅量部分步長；回擊取樣與整趟固定需補測 |
| FR-10 reset | 同步去彈跳後重置 | u_rst、rst_n_s、各暫存器 process | T1、T7；遊戲途中 reset 需補測 |
| FR-11 輸入整理 | 同步、去彈跳、單次脈波 | src/btn_cond.vhd | 目前以設計審查為主；彈跳與長按需補測 |

非功能需求：NFR-01～03 對應第 3 階段架構與 generic；NFR-04 對應 sim/tb_pingpong.vhd；NFR-05 是擴充設計目標，未以 VGA 或雙板實作驗證。

證據層級：歷史 v1.0 截圖、作者上板回報、Python LFSR 檢查與新版 RTL 模擬分別記錄，不互相替代。完整結果在 [第 5 階段](05-verification.md)。
