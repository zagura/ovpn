library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;

entity rxcounters is
	port (
		RxClk : in std_logic;
		
		FrameStart : in std_logic;
		FrameSizeOK : out std_logic;
		CurrentField : out field_indicator;
		
		IFGStart : in std_logic;
		IFGCntEq12 : out std_logic;
		
		--DEBUG
		FrameCntDEBUG : out std_logic_vector(10 downto 0);
		IFGCntDEBUG : out std_logic_vector(3 downto 0)
		
	);
end entity rxcounters;

architecture RTL of rxcounters is
	--Licznik odpalany jest wraz z rozpoczęciem odbioru adresu MAC
	--Ilość bajtów liczonych (bez preambuły i SFD) musi sie mieścić między 64-1518 bajtów
	--dodatkowo licznik pokazuje część ramki która jest odczytywana
	signal FrameCnt : std_logic_vector(10 downto 0) := (others => '0');
	
	--IFG przy FastEthernet musi odczekać 960 ns czyli 12 bajtów = 96 bitów, 
	--co jest wartością standardową dla ethernet. Dla FE nie przewiduje sie redukcji IFG 
	signal IFGCnt : std_logic_vector(3 downto 0) := (others => '0');
	signal IFGCntEq12sig : std_logic;
	
begin	
	FrameCntDEBUG <= FrameCnt;
	IFGCntDEBUG <= IFGCnt;
	
	IFGCntEq12 <= IFGCntEq12sig;
	
	frame_cntr : process (RxClk) is
	begin
		if rising_edge(RxClk) then
			if FrameStart = '0' then
				FrameCnt <= (others => '0');
			elsif FrameStart = '1' then
				FrameCnt <= FrameCnt + 1;
			end if;
		end if;
	end process frame_cntr;
	
	FrameSizeOK <=  '1' when (FrameCnt >= 64 and FrameCnt <= 1518) else
					'0';
								
	CurrentField <= dst_mac when (FrameCnt >= 0 and FrameCnt < 6) else
					src_mac when (FrameCnt >= 6 and FrameCnt < 12) else
					frame_type when (FrameCnt >= 12 and FrameCnt < 14) else
					data when (FrameCnt >= 14 and FrameCnt < 1518);
	
	
	ifg_cntr : process (RxClk) is
	begin
		if rising_edge(RxClk) then
			if IFGStart = '0' then
				IFGCnt <= (others => '0');
			elsif IFGStart = '1' and IFGCntEq12sig = '0' then
				IFGCnt <= IFGCnt + 1;
			end if;
		end if;
	end process ifg_cntr;
	
	IFGCntEq12sig <= '1' when (IFGCnt >= 12) else
					 '0';
	
end architecture RTL;
