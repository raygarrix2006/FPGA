# build_batch.tcl
# Non-project batch flow: synthesis -> implementation -> bitstream, without the Vivado GUI.
# Intended as an option when the GUI flow runs out of memory.
# NOTE: written without access to Vivado and NOT run. Whether it avoids the
#       out-of-memory error is untested.
#
# Usage (from the repository root, Vivado 2018.3 Tcl shell or command prompt):
#   vivado -mode batch -source scripts/build_batch.tcl
set repo [file normalize [file join [file dirname [info script]] ..]]
set out  $repo/build
file mkdir $out

set_param general.maxThreads 1

read_vhdl $repo/src/btn_cond.vhd
read_vhdl $repo/src/pingpong.vhd
read_xdc  $repo/constraints/pingpong.xdc

synth_design -top pingpong -part xc7z020clg484-1
write_checkpoint -force $out/post_synth.dcp

opt_design
place_design
route_design
write_checkpoint -force $out/post_route.dcp
report_utilization -file $out/utilization.rpt
report_timing_summary -file $out/timing_summary.rpt

write_bitstream -force $out/pingpong.bit
