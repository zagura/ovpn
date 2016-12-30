library ieee;
use ieee.std_logic_1164.all;

package common is

	type rxstate_type is (drop, idle, preamble, sfd, dst_mac, src_mac, frame_type, data, OK);
	type field_indicator is (dst_mac, src_mac, frame_type, data, error);
	
	type cnt_input_signals is record
		Rst : std_logic;
		Start : std_logic;
	end record cnt_input_signals;
	
	type frame_cnt_signals is record
		FrameSizeOK : std_logic;
		CurrentField : field_indicator;
	end record frame_cnt_signals;
	
	type ifg_cnt_signals is record
		IFGCntEq12 : std_logic;	
	end record ifg_cnt_signals;
	
end package common;