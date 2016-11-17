library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.common.all;
--use work.common.field_indicator;
--use work.common.frame_cnt_signals;
--use work.common.ifg_cnt_signals;
--use work.common.cnt_input_signals;

entity rxcounters is
	port (
		RxClk : in std_logic;
		
		FrameInput : in cnt_input_signals;
		FrameOutput : out frame_cnt_signals;
		
		IFGInput : in cnt_input_signals;
		IFGOutput : out ifg_cnt_signals;
		
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
	
begin	
	FrameCntDEBUG <= FrameCnt;
	IFGCntDEBUG <= IFGCnt;
	
	
	frame_cntr : process (RxClk) is
	begin
		if rising_edge(RxClk) then
			if FrameInput.Rst = '1' then
				FrameCnt <= (others => '0');
			elsif FrameInput.Start = '1' then
				FrameCnt <= FrameCnt + 1;
			end if;
		end if;
	end process frame_cntr;
	
	FrameOutput.FrameSizeOK <=  '1' when (FrameCnt >= 64 and FrameCnt <= 1518) else
								'0';
								
	FrameOutput.CurrentField <= dst_mac when (FrameCnt > 0 and FrameCnt <= 6) else
								src_mac when (FrameCnt >= 7 and FrameCnt <= 12) else
								frame_type when (FrameCnt >= 13 and FrameCnt <= 14) else
								data when (FrameCnt >= 15 and FrameCnt <= 1518) else
								error;
	
	
	ifg_cntr : process (RxClk) is
	begin
		if rising_edge(RxClk) then
			if IFGInput.Rst = '1' then
				IFGCnt <= (others => '0');
			elsif IFGInput.Start = '1' then
				IFGCnt <= IFGCnt + 1;
			end if;
		end if;
	end process ifg_cntr;
	
	IFGOutput.IFGCntEq12 <= '1' when (IFGCnt >= 12) else
							'0';
	
end architecture RTL;
