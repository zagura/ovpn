library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity tx is
	generic (
		LocalMac : std_logic_vector(47 downto 0)
	);
	port (
		TxClk : in std_logic;
		Rst : in std_logic;
		Start : in std_logic;
		TxDataIn : in std_logic_vector(3 downto 0);
		TxNextState : out txstate_type;
		TxDstMac : in std_logic_vector(47 downto 0);
		
		TxValidDataOut : out std_logic;
		TxDataOut : out std_logic_vector(3 downto 0)
		
	);
end entity tx;

architecture RTL of tx is
	
	component txcounters
	port (
		TxClk : in std_logic;
		
		FrameStart : in std_logic;
		FrameSizeOK : out std_logic;
		CurrentField : out field_indicator;
		
		IFGStart : in std_logic;
		IFGCntEq12 : out std_logic
		
	);
	end component txcounters;

	--MASZYNA
	signal current_state : txstate_type;
	signal next_state : txstate_type;
	
	signal FrameStart : std_logic;
	signal IFGStart : std_logic;
	signal FrameSizeOK : std_logic;
	signal CurrentField : txfield_indicator;
	signal IFGCntEq12 : std_logic;
	
begin
	TxNextState <= next_state;
	
	counters : txcounters
		port map(
			TxClk        => TxClk,
			FrameStart   => FrameStart,
			FrameSizeOK  => FrameSizeOK,
			CurrentField => CurrentField,
			IFGStart     => IFGStart,
			IFGCntEq12   => IFGCntEq12
		);
	
	ns : process(TxClk, Rst) is
	begin
		if Rst = '1' then
			current_state <= idle;
		elsif rising_edge(TxClk) then
			current_state <= next_state;
		end if;
	end process ns;
	
	fsm : process(current_state, Rst) is
		begin
			if Rst = '1' then
				next_state <= idle;
			else 
				case current_state is
					
				when idle => 
					if Start = '1' then
						next_state <= preamble;
					end if;
					next_state <= idle;
				
				when preamble => 
					if 
				
				when sfd =>
					
				when data1 =>
					
				when data0 =>
				
				when fcs =>
				
				when ifg =>
										
				end case;
			end if;
	end process fsm;
	
	
	
		--To cudo pod spodem odpala nam IFGCounter
	IFGStart_p : process (RxClk, Rst) is
	begin
		if Rst = '1' then
			IFGStart <= '0';
		elsif rising_edge(RxClk) then
			if next_state = ifg then
				IFGStart <= '1';
			else
				IFGStart <= '0';
			end if;
		end if;
	end process IFGStart_p;
	
		--To cudo pod spodem odpala nam FrameCounter
	FrameStart_p : process (RxClk, Rst) is
	begin
		if Rst = '1' then
			FrameStart <= '0';
		elsif rising_edge(RxClk) then
			if next_state = preamble or next_state = sfd or next_state = data1 or next_state = data0 or next_state = fcs then
				FrameStart <= '1';
			else
				FrameStart <= '0';
			end if;
		end if;
	end process FrameStart_p;
	
end architecture RTL;