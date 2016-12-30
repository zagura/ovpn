library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

--DEBUG
use work.common.frame_cnt_signals;

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
		iKEY : in std_logic_vector(3 downto 0)
		
	);
end entity OVPN;

architecture RTL of OVPN is
	component rx
		generic(LocalMac : std_logic_vector(47 downto 0));
		port(
			RxClk            : in  std_logic;
			Rst              : in  std_logic;
			RxDataIn         : in  std_logic_vector(7 downto 0);
			RxValidDataIn    : in  std_logic;
			RxCurrentState   : out rxstate_type;
			
			--DEBUG
			FrameOutputDEBUG : out frame_cnt_signals;
			FrameCntDDEBUG   : out std_logic_vector(10 downto 0);
			IFGCntDDEBUG     : out std_logic_vector(3 downto 0);
			DstMacDEBUG      : out std_logic_vector(47 downto 0);
			FrameTypeDEBUG   : out std_logic_vector(15 downto 0);
			ByteEq0xab : out std_logic
		);
	end component rx;
	
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
	--For debug purposes
	signal HEX : hex_display_array;
	signal Button : std_logic_vector(1 downto 0);
	signal ButtonN : std_logic_vector(1 downto 0);
	signal Nibbles : nibble_array;
	signal FrameOutput : frame_cnt_signals;
	
	signal FrameCntNIB : nibble_array := (others => "0000");
	signal DstMacNIB : nibble_array := (others => "0000");
	
	signal FrameCntDDEBUG   : std_logic_vector(10 downto 0);
	signal IFGCntDDEBUG     : std_logic_vector(3 downto 0);
	signal DstMacDEBUG      : std_logic_vector(47 downto 0);
	signal FrameTypeDEBUG   : std_logic_vector(15 downto 0);
	
	signal RomCnt : std_logic_vector(7 downto 0) register := (others=>'0');
	
begin
	Button <= not ButtonN;

	--ROM
	rom : eth_frame
		port map(
			address => RomCnt,
			clock => iCLK_50_2,
			q => RxDataIn
		);
		
	ifg_cntr : process (Button(1)) is
	begin
		if rising_edge(Button(1)) then
			RomCnt <= RomCnt + 1;
		end if;
	end process ifg_cntr;

	RxValidDataIn <= '1';

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
	FrameCntNIB(1) <= RxDataIn(7 downto 4);
	FrameCntNIB(0) <= RxDataIn(3 downto 0);
	
	Nibbles <= FrameCntNIB;
	
	--BUTTONS
	generate_debouncers : for i in 0 to 1 generate
		deb1 : debounce
			generic map(
				counter_size => 10
			)
			port map(
				clk    => iCLK_50_2,
				button => iKEY(i+2),
				result => ButtonN(i)
			);
	end generate generate_debouncers;
	
	rx_instance : rx
		generic map(
			LocalMac => X"CAFEC0DEBABE"
		)
		port map(
			RxClk          => Button(1),
			Rst            => Button(0),
			RxDataIn       => RxDataIn,
			RxValidDataIn  => RxValidDataIn,
			RxCurrentState => RxCurrentState,
			
			--DEBUG
			FrameOutputDEBUG => FrameOutput,
			FrameCntDDEBUG   => FrameCntDDEBUG,
			IFGCntDDEBUG     => IFGCntDDEBUG,
			DstMacDEBUG      => DstMacDEBUG,
			FrameTypeDEBUG   => FrameTypeDEBUG,
			ByteEq0xab => oLEDG(1)
			
		);
		
		
	--LEDS
	
	oLEDR(17) <= '1' when (RxCurrentState = idle) else '0';
	oLEDR(16) <= '1' when (RxCurrentState = preamble) else '0';
	oLEDR(15) <= '1' when (RxCurrentState = sfd) else '0';
	oLEDR(14) <= '1' when (RxCurrentState = dst_mac) else '0';
	oLEDR(13) <= '1' when (RxCurrentState = src_mac) else '0';
	oLEDR(12) <= '1' when (RxCurrentState = frame_type) else '0';
	oLEDR(11) <= '1' when (RxCurrentState = data) else '0';
	oLEDR(10) <= '1' when (RxCurrentState = OK) else '0';
	oLEDR(9) <= '1' when (RxCurrentState = drop) else '0';
	oLEDR(8) <= Button(1);
	
	
	oLEDG(8) <= '1' when (FrameOutput.CurrentField = dst_mac) else '0';
	oLEDG(7) <= '1' when (FrameOutput.CurrentField = src_mac) else '0';
	oLEDG(6) <= '1' when (FrameOutput.CurrentField = frame_type) else '0';
	oLEDG(5) <= '1' when (FrameOutput.CurrentField = data) else '0';
	oLEDG(4) <= '1' when (FrameOutput.CurrentField = error) else '0';
		 
end architecture RTL;
