library ieee;
use ieee.std_logic_1164.all;

package common is

	type rxstate_type is (drop, idle, preamble, sfd, data1, data0, OK);
	type field_indicator is (dst_mac, src_mac, frame_type, data);
	
end package common;