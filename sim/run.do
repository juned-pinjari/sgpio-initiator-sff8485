vlib work
vlog -sv ../rtl/initiator/*.v ../tb/tb_sgpio_regfile.v
vsim work.tb_sgpio_regfile
add wave /tb_sgpio_regfile/*
run -all
