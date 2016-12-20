library ieee;
use ieee.std_logic_1164.all;

package common is

	type rxstate_type is (drop, idle, preamble, sfd, data1, data0, OK);
	type txstate_type is (idle, preamble, sfd, data1, data0, fcs, ifg);
	type field_indicator is (dst_mac, src_mac, frame_type, data);
	type txfield_indicator is (preamble, sfd0, sfd1, data_pad, data);
	
end package common;