library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;


entity OVPN is
	port (
		iCLK_50_2 : in std_logic;
		
		oLEDG :	out std_logic_vector(8 downto 0);
		oLEDR : out	std_logic_vector(17 downto 0);
		
		oHEX0_D : out std_logic_vector(0 to 6);
		oHEX0_DP : out std_logic;
		oHEX1_D : out std_logic_vector(0 to 6);
		oHEX1_DP : out std_logic;
		oHEX2_D : out std_logic_vector(0 to 6);
		oHEX2_DP : out std_logic;
		oHEX3_D : out std_logic_vector(0 to 6);
		oHEX3_DP : out std_logic;
		oHEX4_D : out std_logic_vector(0 to 6);
		oHEX4_DP : out std_logic;
		oHEX5_D : out std_logic_vector(0 to 6);
		oHEX5_DP : out std_logic;
		oHEX6_D : out std_logic_vector(0 to 6);
		oHEX6_DP : out std_logic;
		oHEX7_D : out std_logic_vector(0 to 6);
		oHEX7_DP : out std_logic;
		--iSW : in std_logic_vector(17 downto 0);
		iKEY : in std_logic_vector(3 downto 0);
		
		-- Mapowanie portów ethernet -- ETH1 (Poludnie)
		ETH1_CRS : in std_logic;
		ETH1_TX0 : out std_logic;
		ETH1_TX1 : out std_logic;
		ETH1_TX_EN : out std_logic;
		ETH1_RX1 : in std_logic; 
		ETH1_RX0 : in std_logic;
		ETH1_MDIO : in std_logic;
		ETH1_MDC : in std_logic;
		ETH1_CLK : in std_logic;
		
		-- Mapowanie portów ethernet -- ETH2 (Polnoc)
		ETH2_CRS : in std_logic;
		ETH2_TX0 : out std_logic;
		ETH2_TX1 : out std_logic;
		ETH2_TX_EN : out std_logic;
		ETH2_RX1 : in std_logic; 
		ETH2_RX0 : in std_logic;
		ETH2_MDIO : in std_logic;
		ETH2_MDC : in std_logic;
		ETH2_CLK : in std_logic
	);
end entity OVPN;

architecture RTL of OVPN is
	
	component rx
		generic(LocalMac : std_logic_vector(47 downto 0));
		port(
			RxClk             : in  std_logic;
			Rst               : in  std_logic;
			RxDataIn          : in  std_logic_vector(7 downto 0);
			RxValidDataIn     : in  std_logic;
			RxEndTransmission : in  std_logic;
			RxCurrentState    : out rxstate_type;
			RxNextState : out rxstate_type;

			
			--DEBUG
			CurrentFieldDEBUG : out field_indicator;
			DstMacValidDEBUG : out std_logic;
			FrameCntDDEBUG    : out std_logic_vector(10 downto 0);
			IFGCntDDEBUG      : out std_logic_vector(3 downto 0);
			DstMacDEBUG       : out std_logic_vector(47 downto 0);
			FrameTypeDEBUG    : out std_logic_vector(15 downto 0);
			ByteEq0xabDEBUG   : out std_logic
		);
	end component rx;
	
	component mdioshiftreg
	port (
		MClk : in std_logic;
		Rst : in std_logic;
		Direction : in std_logic; --1 - send, 0 - receive
		
		Start : inout std_logic;
		
		BitInOut : inout std_logic;
		
		DataIn : in std_logic_vector(15 downto 0);
		DataOut : out std_logic_vector(15 downto 0)
	);
	end component mdioshiftreg;
	
	component debounce
		generic(counter_size : INTEGER := 19);
		port(
			clk    : IN  STD_LOGIC;
			button : IN  STD_LOGIC;
			result : OUT STD_LOGIC
		);
	end component debounce;
	
	component byteto7seg
		port(
			NibbleIn : in std_logic_vector(3 downto 0);
			SegOut   : out std_logic_vector(6 downto 0)
		);
	end component byteto7seg;
	
	component eth_frame IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END component eth_frame;
	
	type hex_display_array is array (0 to 7) of std_logic_vector(6 downto 0);
	type nibble_array is array (0 to 7) of std_logic_vector(3 downto 0);
	
	signal RxCurrentState : rxstate_type;
	signal RxDataIn : std_logic_vector(7 downto 0);
	signal RxValidDataIn : std_logic;
	signal RxEndTransmission : std_logic;
	--For debug purposes
	signal DstMacValidDEBUG : std_logic;
	signal RxNextState : rxstate_type;
	signal HEX : hex_display_array;
	signal Button : std_logic_vector(3 downto 0);
	signal ButtonN : std_logic_vector(3 downto 0);
	signal Nibbles : nibble_array;
	signal CurrentState : rxstate_type;
	signal CurrentFieldDEBUG : field_indicator;
	
	signal FrameCntNIB : nibble_array := (others => "0000");
	signal DstMacNIB : nibble_array := (others => "0000");
	
	signal FrameCntDDEBUG   : std_logic_vector(10 downto 0);
	signal IFGCntDDEBUG     : std_logic_vector(3 downto 0);
	signal DstMacDEBUG      : std_logic_vector(47 downto 0);
	signal FrameTypeDEBUG   : std_logic_vector(15 downto 0);
	signal ByteEq0xabDEBUG  : std_logic;
	
	signal dir : std_logic;
	signal sreg_out : std_logic_vector(15 downto 0);
	signal sreg_in : std_logic_vector(15 downto 0) := (others => '0');
	
	signal RomCnt : std_logic_vector(7 downto 0) register := (others=>'0');
	
	-- crc-32 signals
	signal crc_value : std_logic_vector(31 downto 0):= (others => '0');
	signal crc_error : std_logic;
	
	
begin
	oLEDG(7) <= ETH1_CRS;
	


	Button <= not ButtonN;

	--ROM
	rom : eth_frame
		port map(
			address => RomCnt,
			clock => iCLK_50_2,
			q => RxDataIn
		);
		
	ifg_cntr : process (Button(3), Button(2)) is
	begin
		if Button(2) = '1' then
			RomCnt <= (others=>'0');
		elsif rising_edge(Button(3)) then
			RomCnt <= RomCnt + 1;
		end if;
	end process ifg_cntr;


	--HEX
	oHEX0_D <= HEX(0);
	oHEX1_D <= HEX(1);
	oHEX2_D <= HEX(2);
	oHEX3_D <= HEX(3);
	oHEX4_D <= HEX(4);
	oHEX5_D <= HEX(5);
	oHEX6_D <= HEX(6);
	oHEX7_D <= HEX(7);
	
	--oLEDG(0) <= iSW(0);
	generate_decoders : for i in 0 to 7 generate
		dec : byteto7seg
			port map(
				NibbleIn => Nibbles(i),
				SegOut   => HEX(i)
			);
	end generate generate_decoders;
	
	--NIBBLE ASSIGNMENTS
	--Od lewej 3 - FrameCnt, 1 - IFGCnt, 4 - FrameType 
	-- Przypisuje tylko 3 bity do Nibble (4 bity)
	-- Pomijam najstarszy bit
	FrameCntNIB(7)(2 downto 0) <= FrameCntDDEBUG(10 downto 8);
	FrameCntNIB(6) <= FrameCntDDEBUG(7 downto 4);
	FrameCntNIB(5) <= FrameCntDDEBUG(3 downto 0);
	FrameCntNIB(4) <= IFGCntDDEBUG(3 downto 0);
	FrameCntNIB(3) <= sreg_out(15 downto 12);
	FrameCntNIB(2) <= sreg_out(11 downto 8);
	FrameCntNIB(1) <= sreg_out(7 downto 4);
	FrameCntNIB(0) <= sreg_out(3 downto 0);
	
	DstMacNIB(7) <= DstMacDEBUG(47 downto 44);
	DstMacNIB(6) <= DstMacDEBUG(43 downto 40);
	DstMacNIB(5) <= DstMacDEBUG(39 downto 36);
	DstMacNIB(4) <= DstMacDEBUG(35 downto 32);
	DstMacNIB(3) <= DstMacDEBUG(15 downto 12);
	DstMacNIB(2) <= DstMacDEBUG(11 downto 8);
	DstMacNIB(1) <= DstMacDEBUG(7 downto 4);
	DstMacNIB(0) <= DstMacDEBUG(3 downto 0);

	
	Nibbles <= FrameCntNIB;
	
	dir <= '0';
	sreg : mdioshiftreg
		port map (
		MClk => Button(3),
		Rst => Button(2),
		Direction => dir,
		
		Start => Button(1),
		
		BitInOut => Button(0),
		DataOut => sreg_out,
		DataIn => sreg_in
		);
	
	
	--BUTTONS
	generate_debouncers : for i in 0 to 3 generate
		deb1 : debounce
			generic map(
				counter_size => 10
			)
			port map(
				clk    => iCLK_50_2,
				button => iKEY(i),
				result => ButtonN(i)
			);
	end generate generate_debouncers;
		
	rx_instance : rx
		generic map(
			LocalMac => X"CAFEC0DEBABE"
		)
		port map(
			RxClk             => Button(3),
			Rst               => Button(2),
			RxDataIn          => RxDataIn,
			RxValidDataIn     => RxValidDataIn,
			RxEndTransmission => RxEndTransmission,
			RxCurrentState    => RxCurrentState,
			
			--DEBUG
			RxNextState 		=> RxNextState,
			DstMacValidDEBUG => DstMacValidDEBUG,
			CurrentFieldDEBUG => CurrentFieldDEBUG,
			FrameCntDDEBUG    => FrameCntDDEBUG,
			IFGCntDDEBUG      => IFGCntDDEBUG,
			DstMacDEBUG       => DstMacDEBUG,
			FrameTypeDEBUG    => FrameTypeDEBUG,
			ByteEq0xabDEBUG   => ByteEq0xabDEBUG
		);
		
		RxEndTransmission <= '0';
		RxValidDataIn <= '1';
		
	--LEDS
	
	oLEDR(5) <= '1' when (RxCurrentState = idle) else '0';
	oLEDR(4) <= '1' when (RxCurrentState = preamble) else '0';
	oLEDR(3) <= '1' when (RxCurrentState = sfd) else '0';
	oLEDR(2) <= '1' when (RxCurrentState = data) else '0';
	oLEDR(1) <= '1' when (RxCurrentState = OK) else '0';
	oLEDR(0) <= '1' when (RxCurrentState = drop) else '0';
	oLEDR(11) <= Button(3);
	
	oLEDG(5) <= '1' when (RxNextState = idle) else '0';
	oLEDG(4) <= '1' when (RxNextState = preamble) else '0';
	oLEDG(3) <= '1' when (RxNextState = sfd) else '0';
	oLEDG(2) <= '1' when (RxNextState = data) else '0';
	oLEDG(1) <= '1' when (RxNextState = OK) else '0';
	oLEDG(0) <= '1' when (RxNextState = drop) else '0';
	
	
	oLEDR(17) <= '1' when (CurrentFieldDEBUG = dst_mac) else '0';
	oLEDR(16) <= '1' when (CurrentFieldDEBUG = src_mac) else '0';
	oLEDR(15) <= '1' when (CurrentFieldDEBUG = frame_type) else '0';
	oLEDR(14) <= '1' when (CurrentFieldDEBUG = data) else '0';
	
	oLEDG(8) <= ByteEq0xabDEBUG;
	oLEDG(6) <= DstMacValidDEBUG;
		 
end architecture RTL;
