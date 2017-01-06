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
		
		-- Mapowanie portow ethernet -- ETH1 (Poludnie)
		ETH1_CRS : in std_logic;
		ETH1_TX : out std_logic_vector(1 downto 0);
		ETH1_TX_EN : out std_logic;
		ETH1_RX : in std_logic_vector(1 downto 0); 
		ETH1_MDIO : in std_logic;
		ETH1_MDC : in std_logic;
		ETH1_CLK : in std_logic;
		
		-- Mapowanie portow ethernet -- ETH2 (Polnoc)
		ETH2_CRS : in std_logic;
		ETH2_TX : out std_logic_vector(1 downto 0);
		ETH2_TX_EN : out std_logic;
		ETH2_RX : in std_logic_vector(1 downto 0); 
		ETH2_MDIO : in std_logic;
		ETH2_MDC : in std_logic;
		ETH2_CLK : in std_logic
	);
end entity OVPN;

architecture RTL of OVPN is
	
	component RMII2MII
		port(
			rst        : IN  STD_LOGIC;
			mac_RXD    : OUT STD_LOGIC_VECTOR(3 downto 0);
			mac_RX_CLK : OUT STD_LOGIC;
			mac_RX_DV  : OUT STD_LOGIC;
			mac_TXD    : IN  STD_LOGIC_VECTOR(3 downto 0);
			mac_TX_CLK : OUT STD_LOGIC;
			mac_TX_EN  : IN  STD_LOGIC;
			phy_CLK    : IN  STD_LOGIC;
			phy_TXD    : OUT STD_LOGIC_VECTOR(1 downto 0);
			phy_TX_EN  : OUT STD_LOGIC;
			phy_RXD    : IN  STD_LOGIC_VECTOR(1 downto 0);
			phy_CRS    : IN  STD_LOGIC
		);
	end component RMII2MII;
	
	component rx
		generic(LocalMac : std_logic_vector(47 downto 0));
		port(
			RxClk             : in  std_logic;
			Rst               : in  std_logic;
			RxDataIn          : in  std_logic_vector(3 downto 0);
			RxValidDataIn     : in  std_logic;
			RxCurrentState    : out rxstate_type;
			RxNextState : out rxstate_type;

			
			--DEBUG
			CurrentFieldDEBUG : out field_indicator;
			DstMacValidDEBUG : out std_logic;
			FrameCntDDEBUG    : out std_logic_vector(11 downto 0);
			IFGCntDDEBUG      : out std_logic_vector(4 downto 0);
			DstMacDEBUG       : out std_logic_vector(47 downto 0);
			FrameTypeDEBUG    : out std_logic_vector(15 downto 0);
			ByteEq0xabDEBUG   : out std_logic
		);
	end component rx;
	
	component tx
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
	end component tx;
	
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
	
	--MII interface ETH1
	signal mETH1_RX : std_logic_vector(3 downto 0);
	signal mETH1_TX : std_logic_vector(3 downto 0);
	signal mETH1_RX_CLK : std_logic;
	signal mETH1_TX_CLK : std_logic;
	signal mETH1_RX_DV : std_logic;
	signal mETH1_TX_EN : std_logic;
	
	--MII interface ETH2
	signal mETH2_RX : std_logic_vector(3 downto 0);
	signal mETH2_TX : std_logic_vector(3 downto 0);
	signal mETH2_RX_CLK : std_logic;
	signal mETH2_TX_CLK : std_logic;
	signal mETH2_RX_DV : std_logic;
	signal mETH2_TX_EN : std_logic;
	
	
	
	
	
	
	--Do not touch things above this line, unless you know what are you doing
	--Things above seems to be good ;D
	
	component CRC
		port(
			-- input
		clk      : in std_logic;
		rst      : in std_logic;
		data_in  : in std_logic_vector(3 downto 0);
		
			-- output
			
		crc_out  : out std_logic_vector(31 downto 0);
		error : out std_logic
		
		);
	end component CRC;
	
	
	type hex_display_array is array (0 to 7) of std_logic_vector(6 downto 0);
	type nibble_array is array (0 to 7) of std_logic_vector(3 downto 0);
	
	signal RxCurrentState : rxstate_type;
	signal RxDataIn : std_logic_vector(7 downto 0);
	signal RxValidDataIn : std_logic;
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
	
	signal FrameCntDDEBUG   : std_logic_vector(11 downto 0);
	signal IFGCntDDEBUG     : std_logic_vector(4 downto 0);
	signal DstMacDEBUG      : std_logic_vector(47 downto 0);
	signal FrameTypeDEBUG   : std_logic_vector(15 downto 0);
	signal ByteEq0xabDEBUG  : std_logic;
		
	-- crc-32 signals
	signal crc_value : std_logic_vector(31 downto 0):= (others => '0');
	signal crc_error : std_logic;

	--RX
	signal TxDataIn : std_logic_vector(3 downto 0);
	signal TxValidDataIn : std_logic;
	signal TxNextState : txstate_type;
	signal StopSending : std_logic;
	signal Start : std_logic;
	
	signal nibbleInvalid : std_logic;
	signal CrcIn : std_logic_vector(3 downto 0);
	signal CrcOut : std_logic_vector(31 downto 0);
	signal CrcError : std_logic;
	
	
begin
	crc_inst : CRC
	port map(
		-- input
	clk      => mETH2_TX_CLK,
	rst      => Button(2),
	data_in  => CrcIn,
	
		-- output
		
	crc_out  => CrcOut,
	error    => CrcError
	
	);

	process(mETH2_TX_CLK, Button(2)) is
		variable toSend : std_logic_vector(579 downto 0) :=
		X"55555555555555D5FFFFFFFFFFFFCAFEC0DEBABE0806000108000604000100000000000000000000CAFEC0DEBABE0A00000100000000000000000000000000000000000004FA24B8A";--- 9DA37479";
	--	X"555555555555555DFFFFFFFFFFFFCAFEC0DEBABE0800DEADBEEF";
		variable i : natural;
		variable parity : boolean;
	begin
		if Button(2) = '1' then
			i := 0;
		   mETH2_TX_EN <= '0';
			parity := True;
		elsif rising_edge(mETH2_TX_CLK) and i<138 and Start = '1' then
			StopSending <= '0';
			--mETH2_TX_EN <= '0';
			--if (TxNextState = data0 or TxNextState = data1) then
				if parity = True then
					mETH2_TX <= toSend(579-((i+1)*4) downto 576 -((i+1)*4));
				else
					mETH2_TX <= toSend(579-((i-1)*4) downto 576 -((i-1)*4));
				end if;
				parity := not parity;
				if i >= 16 then
					CrcIn <= toSend(579 - (i*4) downto 576-(i*4));
				end if;
				mETH2_TX_EN <= '1';
				i := i+1;
		elsif rising_edge(mETH2_TX_CLK) and Start = '0' then
			i := 0;
			mETH2_TX_EN <= '0';
			--end if;
		elsif rising_edge(mETH2_TX_CLK) and i >= 138 and i <146 and Start ='1' then
			mETH2_TX <= CrcOut(31-((i-138)*4) downto 28-((i-138)*4));
			mETH2_TX_EN <= '1';
			i := i+1;
		elsif rising_edge(mETH2_TX_CLK) and i = 146 then
			StopSending <= '1';
			mETH2_TX_EN <= '0';
			parity := True;
		end if;
		
	end process;

	process (Button(3), Button(2), StopSending, Start) is
	begin
		if Start = '0' then
			Start <= '1';
		end if;
		if Button(2) = '1' then
			Start <= '0';
		elsif Button(3) = '1' then
			Start <= '1';
		elsif StopSending = '1' then
			Start <= '0';
		end if;
	end process;
	
	conv1 : component RMII2MII
		port map(
			rst        => ButtonN(2),
			mac_RXD    => mETH1_RX,
			mac_RX_CLK => mETH1_RX_CLK,
			mac_RX_DV  => mETH1_RX_DV,
			mac_TXD    => mETH1_TX,
			mac_TX_CLK => mETH1_TX_CLK,
			mac_TX_EN  => mETH1_TX_EN,
			phy_CLK    => ETH1_CLK,
			phy_TXD    => ETH1_TX,
			phy_TX_EN  => ETH1_TX_EN,
			phy_RXD    => ETH1_RX,
			phy_CRS    => ETH1_CRS
		);
		
	conv2 : component RMII2MII
		port map(
			rst        => ButtonN(2),
			mac_RXD    => mETH2_RX,
			mac_RX_CLK => mETH2_RX_CLK,
			mac_RX_DV  => mETH2_RX_DV,
			mac_TXD    => mETH2_TX,
			mac_TX_CLK => mETH2_TX_CLK,
			mac_TX_EN  => mETH2_TX_EN,
			phy_CLK    => ETH2_CLK,
			phy_TXD    => ETH2_TX,
			phy_TX_EN  => ETH2_TX_EN,
			phy_RXD    => ETH2_RX,
			phy_CRS    => ETH2_CRS
		);


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
	FrameCntNIB(3) <= FrameTypeDEBUG(15 downto 12);
	FrameCntNIB(2) <= FrameTypeDEBUG(11 downto 8);
	FrameCntNIB(1) <= FrameTypeDEBUG(7 downto 4);
	FrameCntNIB(0) <= FrameTypeDEBUG(3 downto 0);
	
	DstMacNIB(7) <= DstMacDEBUG(47 downto 44);
	DstMacNIB(6) <= DstMacDEBUG(43 downto 40);
	DstMacNIB(5) <= DstMacDEBUG(39 downto 36);
	DstMacNIB(4) <= DstMacDEBUG(35 downto 32);
	DstMacNIB(3) <= DstMacDEBUG(31 downto 28);
	DstMacNIB(2) <= DstMacDEBUG(27 downto 24);
	DstMacNIB(1) <= DstMacDEBUG(23 downto 20);
	DstMacNIB(0) <= DstMacDEBUG(19 downto 16);

	Nibbles <= DstMacNIB;
	
	
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
	
	Button <= not ButtonN;
	oLEDR(12) <= mETH2_TX_CLK;
	rx_instance : rx
		generic map(
			LocalMac => X"CAFEC0DEBABE"
		)
		port map(
			RxClk             => mETH1_RX_CLK,
			Rst               => Button(2),
			RxDataIn          => mETH1_RX,
			RxValidDataIn     => mETH1_RX_DV,
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
		
		RxValidDataIn <= '1';
		
/*		
	tx_instance : tx
		generic map(
			LocalMac => X"CAFEC0DEBABE"
		)
		port map(
			TxClk => mETH1_TX_CLK,
			Rst => Button(2),
			Start => StartSending,
			TxDataIn => TxDataIn,
			TxValidDataIn => TxValidDataIn,
			TxNextState => TxNextState,
			TxValidDataOut => mETH1_TX_EN,
			TxDataOut => mETH1_TX		
		);
*/		
	--LEDS
	
	oLEDR(5) <= mETH2_TX(0);		--'1' when (RxCurrentState = idle) else '0';

	oLEDR(4) <= metH2_TX(1);	--'1' when (RxCurrentState = preamble) else '0';
	oLEDR(3) <= mETH2_TX_EN;					--'1' when (RxCurrentState = sfd) else '0';
	oLEDR(2) <= '1' when (RxCurrentState = data1 or RxCurrentState = data0) else '0';
	oLEDR(1) <= '1' when (RxCurrentState = OK) else '0';
	oLEDR(0) <= '1' when (RxCurrentState = drop) else '0';
	oLEDR(11) <= Button(3);
	
	oLEDG(5) <= '1' when (RxNextState = idle) else '0';
	oLEDG(4) <= '1' when (RxNextState = preamble) else '0';
	oLEDG(3) <= '1' when (RxNextState = sfd) else '0';
	oLEDG(2) <= '1' when (RxNextState = data1 or RxNextState = data0) else '0';
	oLEDG(1) <= '1' when (RxNextState = OK) else '0';
	oLEDG(0) <= '1' when (RxNextState = drop) else '0';
	
	
	oLEDR(17) <= '1' when (CurrentFieldDEBUG = dst_mac) else '0';
	oLEDR(16) <= '1' when (CurrentFieldDEBUG = src_mac) else '0';
	oLEDR(15) <= '1' when (CurrentFieldDEBUG = frame_type) else '0';
	oLEDR(14) <= '1' when (CurrentFieldDEBUG = data) else '0';
	
	oLEDG(8) <= ByteEq0xabDEBUG;
	oLEDG(6) <= DstMacValidDEBUG;

		 
end architecture RTL;
