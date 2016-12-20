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
		TxValidDataIn : in std_logic;
		TxNextState : out txstate_type;
		
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
		CurrentField : out txfield_indicator;
		
		IFGStart : in std_logic;
		IFGCntEq12 : out std_logic;
		
		FCSStart : in std_logic;
		FCSCounter : out natural
		
	);
	end component txcounters;

	--MASZYNA
	signal current_state : txstate_type;
	signal next_state : txstate_type;
	
	signal FrameStart : std_logic;
	signal IFGStart : std_logic;
	signal FCSStart : std_logic;
	signal FrameSizeOK : std_logic;
	signal CurrentField : txfield_indicator;
	signal IFGCntEq12 : std_logic;
	
	signal CRCVal : std_logic_vector(31 downto 0);
	
	signal FCSCounter : natural;
	
begin
	TxNextState <= next_state;
	
	counters : txcounters
		port map(
			TxClk        => TxClk,
			FrameStart   => FrameStart,
			FrameSizeOK  => FrameSizeOK,
			CurrentField => CurrentField,
			IFGStart     => IFGStart,
			IFGCntEq12   => IFGCntEq12,
			FCSStart		 => FCSStart,
			FCSCounter	 => FCSCounter
		);
	
	ns : process(TxClk, Rst) is
	begin
		if Rst = '1' then
			current_state <= idle;
		elsif rising_edge(TxClk) then
			current_state <= next_state;
		end if;
	end process ns;
	
	fsm : process(	current_state,
						Rst,
						CurrentField,
						TxValidDataIn) is
	begin
		if Rst = '1' then
			next_state <= idle;
		else
			TxValidDataOut <= '0';
			case current_state is
				
			when idle => 
				if Start = '1' then
					next_state <= preamble;
					TxDataOut <= X"5";
					TxValidDataOut <= '1';
				else
					next_state <= idle;
				end if;
				
			
			when preamble => 
				if currentField = preamble then
					TxDataOut <= X"5";
					TxValidDataOut <= '1';
					next_state <= preamble;
				elsif currentField = sfd then
					TxDataOut <= X"D";
					TxValidDataOut <= '1';
					next_state <= data1;
				end if;
					
				
			when data1 =>
				if TxValidDataIn = '1' then
					TxDataOut <= TxDataIn;
					TxValidDataOut <= '1';
				else
					TxDataOut <= X"0";
					TxValidDataOut <= '1';
				end if;
				next_state <= data0;
				
			when data0 => --potencjalne bugi przy zbyt duzej ramce ;D
				if TxValidDataIn = '1' then
					TxDataOut <= TxDataIn;
					TxValidDataOut <= '1';
					next_state <= data1;
				elsif currentField = data_pad then
					TxDataOut <= X"0";
					TxValidDataOut <= '1';
					next_state <= data1;
				else
					next_state <= fcs;
				end if;
				
			when fcs =>
				if FCSCounter < 8 then
					TxDataOut <= CRCVal( 31-(FCSCounter*4) downto 28-(FCSCounter*4));
					TxValidDataOut <= '1';
					next_state <= fcs;
				else
					next_state <= ifg;
				end if;
	
			when ifg =>
				if IFGCntEq12 = '1' then
					next_state <= idle;
				else
					next_state <= ifg;
				end if;
			end case;
		end if;
	end process fsm;
	
	
	
		--To cudo pod spodem odpala nam IFGCounter
	IFGStart_p : process (TxClk, Rst) is
	begin
		if Rst = '1' then
			IFGStart <= '0';
		elsif rising_edge(TxClk) then
			if next_state = ifg then
				IFGStart <= '1';
			else
				IFGStart <= '0';
			end if;
		end if;
	end process IFGStart_p;
	
		--To cudo pod spodem odpala nam FrameCounter
	FrameStart_p : process (TxClk, Rst) is
	begin
		if Rst = '1' then
			FrameStart <= '0';
		elsif rising_edge(TxClk) then
			if next_state = preamble or next_state = data1 or next_state = data0 or next_state = fcs then
				FrameStart <= '1';
			else
				FrameStart <= '0';
			end if;
		end if;
	end process FrameStart_p;
	
		--To cudo pod spodem odpala nam FCSCounter
	FCSStart_p : process (TxClk, Rst) is
	begin
		if Rst = '1' then
			FCSStart <= '0';
		elsif rising_edge(TxClk) then
			if current_state = fcs then
				FCSStart <= '1';
			else
				FCSStart <= '0';
			end if;
		end if;
	end process FCSStart_p;
	
end architecture RTL;