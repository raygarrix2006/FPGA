# pingpong.xdc  (EGO-XZ7, XC7Z020-CLG484)
# Pins: EGO-XZ7 hardware manual V1.2, Table 2 and Table 15
# IOSTANDARD: LVCMOS33 (provided by the user: course boards use LVCMOS33 for all IO)
# Seven-segment pins are intentionally NOT used (see docs/05-verification.md, section 5.6)
# ASCII-only comments on purpose, to avoid encoding problems in Vivado

# ---- 100 MHz PL clock (GCLK = Y9) ----
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# ---- rst_n = SW7 (low = reset) ----
set_property PACKAGE_PIN M15 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# ---- mode_sw = SW0 (0 = constant speed, 1 = variable speed) ----
set_property PACKAGE_PIN F22 [get_ports mode_sw]
set_property IOSTANDARD LVCMOS33 [get_ports mode_sw]

# ---- buttons: btn_l = BTNL (player1), btn_r = BTNR (player2) ----
set_property PACKAGE_PIN N15 [get_ports btn_l]
set_property PACKAGE_PIN R18 [get_ports btn_r]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_l btn_r}]

# ---- LED0..LED7 ----
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
