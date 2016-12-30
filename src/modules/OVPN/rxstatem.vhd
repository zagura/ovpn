--Ramka ethernet niekoniecznie musi się zaczynać
--7 bajtową preambułą, czasami wystarcza tylko SFD

--preamble => oczekujemy 0x55
--sfd => oczekujemy 0xD5

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity rxstatem is
	port(
		
		RxClk : in std_logic;
		Rst : in std_logic;
		RxValidData : in std_logic;
		ByteEq0x55 : in std_logic;
		ByteEq0xd5 : in std_logic;
		DstMacValid : in std_logic;
		SrcMacValid : in std_logic;
		FrameTypeValid : in std_logic;
		CrcValid : in std_logic;
		
		FrameInput : out cnt_input_signals;
		FrameOutput : in frame_cnt_signals;
		IFGInput :  out cnt_input_signals;
		IFGOutput : in ifg_cnt_signals;
		
		RxState : out rxstate_type
	);
end entity rxstatem;

architecture fsm of rxstatem is
	
	signal current_state : rxstate_type := idle;
	signal next_state : rxstate_type;
	
begin	
	--Warunki przejsc miedzy stanami
	next_state <= 	preamble when ((current_state = idle  or current_state = preamble) and ByteEq0x55 = '1') else
					sfd when (RxValidData = '1' and (current_state = idle or current_state = preamble) and ByteEq0xd5 = '1') else
					dst_mac when (RxValidData = '1' and (current_state = sfd or FrameOutput.CurrentField = dst_mac)) else
					src_mac when (RxValidData = '1' and FrameOutput.CurrentField = src_mac and DstMacValid = '1') else
					frame_type when (RxValidData = '1' and FrameOutput.CurrentField = frame_type and SrcMacValid = '1') else
					data when (RxValidData = '1' and FrameOutput.CurrentField = data and FrameTypeValid = '1') else
					idle when ((RxValidData = '0' and current_state = idle) or ((current_state = ok or current_state = drop) and IFGOutput.IFGCntEq12 = '1')) else
					OK when (current_state = data and CrcValid = '1' and FrameOutput.FrameSizeOK = '1') else
					current_state;
					
	RxState <= current_state;
	
	FrameInput.Rst <= '1' when (next_state = idle) or (next_state = OK) or next_state = drop or next_state = preamble or next_state = sfd else
							'0';
	FrameInput.Start <= '1' when next_state = dst_mac or next_state = src_mac or next_state = frame_type or next_state = data else
								'0';
	
	IFGInput.Rst <= '1' when current_state = preamble or current_state = sfd or current_state = dst_mac or current_state = src_mac or current_state = frame_type or current_state = data else
							'0';
	IFGInput.Start <= '1' when current_state = idle or current_state = OK or current_state = drop else
							'0';
	
	ns : process(RxClk, Rst) is
	begin
		--if Rst = '1' then
		--	current_state <= drop;
		if rising_edge(RxClk) then
			current_state <= next_state;
		end if;
	end process ns;

end architecture fsm;
