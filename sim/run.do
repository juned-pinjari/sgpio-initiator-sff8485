vlib work
vlog -sv ../rtl/initiator/*.v ../tb/tb_sgpio_blink_gen.v
vsim work.tb_sgpio_blink_gen
add wave /tb_sgpio_blink_gen/*
run -all
