# Simple simulation script for ModelSim
vlib work
vlog -sv ../rtl/initiator/sgpio_clk_gen.v ../tb/tb_sgpio_clk_gen.v
vsim work.tb_sgpio_clk_gen
add wave -r /*
run -all
