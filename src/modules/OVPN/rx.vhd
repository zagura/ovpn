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
		RxCurrentState : out rxstate_type;
		
		
		--DEBUG
		FrameOutputDEBUG : out frame_cnt_signals;
		FrameCntDDEBUG : out std_logic_vector(10 downto 0);
		IFGCntDDEBUG : out std_logic_vector(3 downto 0);
		DstMacDEBUG : out std_logic_vector(47 downto 0);
		FrameTypeDEBUG : out std_logic_vector(15 downto 0);
		ByteEq0xab : out std_logic
	);
end entity rx;

architecture RTL of rx is
	
	component rxstatem
		port(
			RxClk          : in  std_logic;
			Rst            : in  std_logic;
			RxValidData    : in  std_logic;
			ByteEq0x55     : in  std_logic;
			ByteEq0xd5     : in  std_logic;
			DstMacValid    : in  std_logic;
			SrcMacValid    : in  std_logic;
			FrameTypeValid : in  std_logic;
			CrcValid       : in  std_logic;
			FrameInput     : out cnt_input_signals;
			FrameOutput    : in  frame_cnt_signals;
			IFGInput       : out cnt_input_signals;
			IFGOutput      : in  ifg_cnt_signals;
			RxState        : out rxstate_type
		);
	end component rxstatem;
	
	component rxcounters
		port(
			RxClk       : in  std_logic;
			FrameInput  : in  cnt_input_signals;
			FrameOutput : out frame_cnt_signals;
			IFGInput    : in  cnt_input_signals;
			IFGOutput   : out ifg_cnt_signals;
			
			--DEBUG
			FrameCntDEBUG : out std_logic_vector(10 downto 0);
			IFGCntDEBUG : out std_logic_vector(3 downto 0)
		);
	end component rxcounters;
	
	--Połączenia między maszyną, a licznikami
	signal FrameInput : cnt_input_signals;
	signal IFGInput : cnt_input_signals;
	signal FrameOutput : frame_cnt_signals;
	signal IFGOutput : ifg_cnt_signals;
	
	--Różne pierdółki
	signal ByteEq0x55 : std_logic;
	signal ByteEq0xd5 : std_logic;
	signal DstMacValid : std_logic;
	signal SrcMacValid : std_logic;
	signal FrameTypeValid : std_logic;
	signal CrcValid : std_logic;
	
	signal RxState : rxstate_type;
	
	signal DstMac : std_logic_vector(47 downto 0) := (others => '0') ;
	signal FrameType : std_logic_vector(15 downto 0) := (others => '0');
	
	--DEBUG
	signal FrameCntDEBUG : std_logic_vector(10 downto 0);
	signal IFGCntDEBUG : std_logic_vector(3 downto 0);
	
begin
	
	--DEBUG
	FrameOutputDEBUG <= FrameOutput;
	FrameCntDDEBUG <= FrameCntDEBUG;
	IFGCntDDEBUG <= IFGCntDEBUG;
	DstMacDEBUG <= DstMac;
	FrameTypeDEBUG <= FrameType;
	
	RxCurrentState <= RxState;
	
	ByteEq0xab <= ByteEq0xd5;
	
	ByteEq0x55 <= '1' when (RxDataIn = X"AA") else
						'0';
	ByteEq0xd5 <= '1' when (RxDataIn = X"AB") else
						'0';
	SrcMacValid <= '1'; --Właściwie to nie wiem po co to dałem ;D
	
	--na razie nie bawimy się w multicasty
	DstMacValid <= '1' when (DstMac = LocalMac or DstMac = X"FFFFFFFFFFFF") else
						'0';
	
	--na razie tylko ramki IP
	--0x0800 <= IPv4
	--0x86DD <= IPv6
	FrameTypeValid <= '1' when (FrameType = X"86DD") else
							'0';
	
	CrcValid <= '1';
	
	filldstmac : process (RxClk, Rst) is
	begin
	 	if Rst = '1' then
	 		DstMac <= (others => '0');
	 	elsif rising_edge(RxClk) and RxState = dst_mac then
	 		--Wrzucamy bajty do DstMac 
	 	end if;
	end process filldstmac;
	 
	fill_frame_type : process (RxClk, Rst) is
	begin
	 	if Rst = '1' then
	 		FrameType <= (others => '0');
	 	elsif rising_edge(RxClk) and RxState = frame_type then
	 		--Wrzucamy bajty do FrameType 
		end if;
	end process fill_frame_type;
	
	machine : rxstatem
		port map(
			RxClk          => RxClk,
			Rst            => Rst,
			RxValidData    => RxValidDataIn,
			ByteEq0x55     => ByteEq0x55,
			ByteEq0xd5     => ByteEq0xd5,
			DstMacValid    => DstMacValid,
			SrcMacValid    => SrcMacValid,
			FrameTypeValid => FrameTypeValid,
			CrcValid       => CrcValid,
			FrameInput     => FrameInput,
			FrameOutput    => FrameOutput,
			IFGInput       => IFGInput,
			IFGOutput      => IFGOutput,
			RxState        => RxState
		);
	
	counters : rxcounters
		port map(
			RxClk         => RxClk,
			FrameInput    => FrameInput,
			FrameOutput   => FrameOutput,
			IFGInput      => IFGInput,
			IFGOutput     => IFGOutput,
			
			--DEBUG
			FrameCntDEBUG => FrameCntDEBUG,
			IFGCntDEBUG   => IFGCntDEBUG
		);

end architecture RTL;
