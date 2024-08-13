onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/clk_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/rst_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/addr_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/wr_data_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/wr_en_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/m_ready_i
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/m_valid_o
add wave -noupdate -expand -group dut /tb_statistics/dut_inst/m_data_o
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage1_wr_en
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage1_first_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage1_last_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage1_row_cells
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage2_wr_en
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage2_first_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage2_last_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage2_cell_count_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage3_wr_en
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage3_first_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage3_last_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage3_cell_count_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage4_wr_en
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/stage4_last_row
add wave -noupdate -expand -group dut -expand -group Internal /tb_statistics/dut_inst/total
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 fs} 0}
quietly wave cursor active 0
configure wave -namecolwidth 183
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {999978445 fs} {1000000670 fs}
