if {[llength $argv] != 1} {
	puts stderr "Usage: $argv0 <condition>"
	exit 1
}
lassign $argv gui

set source_files [glob "./rtl/*.sv"]
set tb_files ./tb/tb_stream_upsize.sv

if {$gui == 1} {
	start_gui
}

create_project simulation ./tmp/sim_output

add_files -fileset sources_1 $source_files
add_files -fileset sim_1 $tb_files

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

export_ip_user_files -of_objects  [get_files ./wf/tb_stream_upsize_behav.wcfg] -no_script -reset -force -quiet
remove_files -fileset sim_1 ./wf/tb_stream_upsize_behav.wcfg

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ./wf/tb_stream_upsize_behav.wcfg

launch_simulation
