# seg_test.xdc - diagnostic constraints (EGO-XZ7, XC7Z020-CLG484)
# Pins from the EGO-XZ7 hardware manual V1.2, Table 15 and Table 16
# IOSTANDARD: LVCMOS33 (provided by user)

# switches SW0..SW7
set_property PACKAGE_PIN F22 [get_ports {sw[0]}]
set_property PACKAGE_PIN G22 [get_ports {sw[1]}]
set_property PACKAGE_PIN H22 [get_ports {sw[2]}]
set_property PACKAGE_PIN F21 [get_ports {sw[3]}]
set_property PACKAGE_PIN H19 [get_ports {sw[4]}]
set_property PACKAGE_PIN H18 [get_ports {sw[5]}]
set_property PACKAGE_PIN H17 [get_ports {sw[6]}]
set_property PACKAGE_PIN M15 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

# LED0..LED7
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# seven segment: seg(6)=A ... seg(0)=G
set_property PACKAGE_PIN U10  [get_ports {seg[6]}]
set_property PACKAGE_PIN U9   [get_ports {seg[5]}]
set_property PACKAGE_PIN AA12 [get_ports {seg[4]}]
set_property PACKAGE_PIN W12  [get_ports {seg[3]}]
set_property PACKAGE_PIN V12  [get_ports {seg[2]}]
set_property PACKAGE_PIN U11  [get_ports {seg[1]}]
set_property PACKAGE_PIN U12  [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]
