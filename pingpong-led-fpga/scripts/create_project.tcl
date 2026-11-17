# create_project.tcl
# Usage (Vivado Tcl console):  source scripts/create_project.tcl
# NOTE: this script was written without access to Vivado and has NOT been run.
set repo [file normalize [file join [file dirname [info script]] ..]]

create_project pingpong_prj $repo/vivado_prj -part xc7z020clg484-1 -force

add_files [list $repo/src/btn_cond.vhd $repo/src/pingpong.vhd]
add_files -fileset sim_1     $repo/sim/tb_pingpong.vhd
add_files -fileset sim_1     $repo/sim/tb_btn_cond.vhd
add_files -fileset constrs_1 $repo/constraints/pingpong.xdc

set_property top pingpong    [get_filesets sources_1]
set_property top tb_pingpong [get_filesets sim_1]
update_compile_order -fileset sources_1
