//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-05-25 23:45:43
create_clock -name internal_crystal -period 37.037 -waveform {0 18.518} [get_ports {I_clk_27m}]
