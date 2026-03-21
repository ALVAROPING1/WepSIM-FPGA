# Create analog clk divider component
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_divider
# Configure component
# NOTE: values obtained from vivado's GUI wizard
set_property -dict [list \
  CONFIG.CLKOUT1_JITTER {333.843} \
  CONFIG.CLKOUT1_PHASE_ERROR {293.793} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {15} \
  CONFIG.CLK_OUT1_PORT {clk_out} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {49.875} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {66.500} \
  CONFIG.MMCM_DIVCLK_DIVIDE {5} \
  CONFIG.PRIMARY_PORT {clk_in} \
  CONFIG.USE_LOCKED {false} \
  CONFIG.USE_RESET {false} \
] [get_ips clk_divider]

create_ip_run [get_ips clk_divider]
launch_runs clk_divider_synth_1 -jobs 8
