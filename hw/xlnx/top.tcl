create_project -force -part xc7a100tcsg324-1 top


add_files ../../gen/SicoSOC.v
add_files ../../verilog/top.v
#add_files ../../verilog/soc_mmcm.v
add_files ../../verilog/synchronizer.v


read_xdc ../top.xdc
synth_design -top top 


#report_timing_summary -file top_timing_synth.rpt
#report_utilization -hierarchical -file top_utilization_hierarchical_synth.rpt
#report_utilization -file top_utilization_synth.rpt
opt_design
place_design


#report_utilization -hierarchical -file top_utilization_hierarchical_place.rpt
#report_utilization -file top_utilization_place.rpt
#report_io -file top_io.rpt
#report_control_sets -verbose -file top_control_sets.rpt
#report_clock_utilization -file top_clock_utilization.rpt
route_design


phys_opt_design
report_timing_summary -no_header -no_detailed_paths
#write_checkpoint -force top_route.dcp
#report_route_status -file top_route_status.rpt
#report_drc -file top_drc.rpt
#report_methodology -file top_methodology.rpt
#report_timing_summary -datasheet -max_paths 10 -file top_timing.rpt
#report_power -file top_power.rpt


write_bitstream -force -bin_file top.bit


quit