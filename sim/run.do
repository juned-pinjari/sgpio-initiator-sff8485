vlib work
vlog -sv ../rtl/initiator/sgpio_clk_gen.v ../rtl/initiator/sgpio_fsm.v ../tb/tb_sgpio_fsm.v
vsim work.tb_sgpio_fsm
add wave /tb_sgpio_fsm/*
run -all
