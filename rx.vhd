library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity rx is
	generic (
		LocalMac : std_logic_vector(47 downto 0)
	);
	port (
		RxClk : in std_logic;
		Rst : in std_logic;
		RxDataIn : in std_logic_vector(7 downto 0);
		RxValidDataIn : in std_logic;
		RxEndTransmission : in std_logic;
		RxCurrentState : out rxstate_type;
		
		
		--DEBUG
		RxNextState : out rxstate_type;
		DstMacValidDEBUG : out std_logic;
		CurrentFieldDEBUG : out field_indicator;
		FrameCntDDEBUG : out std_logic_vector(10 downto 0);
		IFGCntDDEBUG : out std_logic_vector(3 downto 0);
		DstMacDEBUG : out std_logic_vector(47 downto 0);
		FrameTypeDEBUG : out std_logic_vector(15 downto 0);
		ByteEq0xabDEBUG : out std_logic
	);
end entity rx;

architecture RTL of rx is
	
	component rxcounters
		port(
			RxClk         : in  std_logic;
			FrameStart    : in  std_logic;
			FrameSizeOK   : out std_logic;
			CurrentField  : out field_indicator;
			IFGStart      : in  std_logic;
			IFGCntEq12    : out std_logic;
			
			--DEBUG
			FrameCntDEBUG : out std_logic_vector(10 downto 0);
			IFGCntDEBUG   : out std_logic_vector(3 downto 0)
		);
	end component rxcounters;
	
	--Połączenia między maszyną, a licznikami
	signal FrameStart : std_logic;
	signal IFGStart : std_logic;
	signal FrameSizeOK : std_logic;
	signal CurrentField : field_indicator;
	signal IFGCntEq12 : std_logic;
	
	--Różne pierdółki
	signal ByteEq0xAA : std_logic;
	signal ByteEq0xAB : std_logic;
	signal DstMacValid : std_logic;
	signal SrcMacValid : std_logic;
	signal FrameTypeValid : std_logic;
	signal CrcValid : std_logic;
	
	signal DstMac : std_logic_vector(47 downto 0) := (others => '0') ;
	signal FrameType : std_logic_vector(15 downto 0) := (others => '0');
	
	--DEBUG
	signal FrameCntDEBUG : std_logic_vector(10 downto 0);
	signal IFGCntDEBUG : std_logic_vector(3 downto 0);
	
	--MASZYNA
	signal current_state : rxstate_type := idle;
	signal next_state : rxstate_type;
	
begin
	
	--DEBUG
	CurrentFieldDEBUG <= CurrentField;
	FrameCntDDEBUG <= FrameCntDEBUG;
	IFGCntDDEBUG <= IFGCntDEBUG;
	DstMacDEBUG <= DstMac;
	FrameTypeDEBUG <= FrameType;
	
	RxCurrentState <= current_state;
	RxNextState <= next_state;
	
	ByteEq0xabDEBUG <= ByteEq0xAB;
	
	ByteEq0xAA <= '1' when (RxDataIn = X"AA") else
						'0';
	ByteEq0xAB <= '1' when (RxDataIn = X"AB") else
						'0';
	SrcMacValid <= '1'; --Właściwie to nie wiem po co to dałem ;D
	
	--na razie nie bawimy się w multicasty
	DstMacValid <= '1' when (DstMac = LocalMac or DstMac = X"FFFFFFFFFFFF") else
						'0';
						
	DstMacValidDEBUG <= DstMacValid;
	
	--na razie tylko ramki IP
	--0x0800 <= IPv4
	--0x86DD <= IPv6
	FrameTypeValid <= '1' when (FrameType = X"0800") else
							'0';
	
	CrcValid <= '1';
	
	counters : rxcounters
		port map(
			RxClk         => RxClk,
			FrameStart    => FrameStart,
			FrameSizeOK   => FrameSizeOK,
			CurrentField  => CurrentField,
			IFGStart      => IFGStart,
			IFGCntEq12    => IFGCntEq12,
			
			--DEBUG
			FrameCntDEBUG => FrameCntDEBUG,
			IFGCntDEBUG   => IFGCntDEBUG
		);

	--MASZYNA STANOW
	--Stosujemy model dwuprocesorowy, opisany w literaturze
	ns : process(RxClk, Rst) is
	begin
		if Rst = '1' then
			current_state <= preamble;
		elsif rising_edge(RxClk) then
			current_state <= next_state;
		end if;
	end process ns;
	
	--Pomysł jest taki, że stan mówi, czego oczekujemy
	--Bo przypisanie do current_state jest opóźnione o jeden takt

	fsm : process(	current_state, 
						Rst,
						RxValidDataIn,
						IFGCntEq12,
						RxDataIn,
						RxEndTransmission,
						DstMacValid,
						SrcMacValid,
						CrcValid,
						FrameSizeOK) is
		begin
			if Rst = '1' then
				next_state <= preamble;
			else 
				case current_state is
					
					
					when idle =>
						if RxValidDataIn = '1' and IFGCntEq12 = '1' then
							next_state <= preamble;
						elsif RxValidDataIn = '1' and RxDataIn = X"AA" and IFGCntEq12 = '1' then
							next_state <= sfd;
						elsif RxValidDataIn = '1' and RxDataIn = X"AB" and IFGCntEq12 = '1' then
							next_state <= data;
						else
							next_state <= idle;
						end if;
					
						
					when preamble =>
						if RxValidDataIn = '0' then
							next_state <= idle;
						elsif RxValidDataIn = '1' and RxDataIn = X"AA" then
							next_state <= sfd;
						elsif RxValidDataIn = '1' and RxDataIn = X"AB" then
							next_state <= data;
						else
							next_state <= preamble;
						end if;
						
					when sfd =>
						if RxValidDataIn = '0' then
							next_state <= idle;
						elsif RxValidDataIn = '1' and RxDataIn = X"AA" then
							next_state <= sfd;
						elsif RxValidDataIn = '1' and RxDataIn = X"AB" then
							next_state <= data;
						else
							next_state <= drop;
					end if;	
						
					when data =>
						if RxValidDataIn = '0' then
							next_state <= idle;
						elsif RxEndTransmission = '1' and DstMacValid = '1' and SrcMacValid = '1' and CrcValid = '1' and FrameSizeOK = '1' then
							next_state <= OK;
						elsif RxEndTransmission = '1' and (DstMacValid = '0' or SrcMacValid = '0' or CrcValid = '0' or FrameSizeOK = '0') then
							next_state <= drop;
						else
							next_state <= data;

						end if;
						
					when drop =>
						next_state <= idle;
						
					when OK =>
						next_state  <= idle;
						
				end case;
			end if;
	end process fsm;
	
		
	--Ustawienia Counterów
	IFGStart <= '1' when (next_state = idle or next_state = drop or next_state = OK) else
				'0';
				
	FrameStart <= 	'1' when (next_state = data) else
					'0';
	
	--Procesy zależne od stanu maszyny
	filldstmac : process (RxClk, Rst) is
		variable i : natural := 0;
	begin
	 	if Rst = '1' or current_state = idle then
	 		DstMac <= (others => '0');
	 		i := 0;
	 	elsif rising_edge(RxClk) and CurrentField = dst_mac and current_state = data then
	 		DstMac(47-(8*i) downto 40-(8*i)) <= RxDataIn;
	 		i := i + 1;
	 		
	 	end if;
	end process filldstmac;
	 
	fill_frame_type : process (RxClk, Rst) is
		variable i : natural := 0;
	begin
	 	if Rst = '1' or current_state = idle then
	 		FrameType <= (others => '0');
	 		i := 0;
	 	elsif rising_edge(RxClk) and CurrentField = frame_type and current_state = data then
	 		FrameType(15-(8*i) downto 8-(8*i)) <= RxDataIn;
	 		i := i + 1;
		end if;
	end process fill_frame_type;

end architecture RTL;
