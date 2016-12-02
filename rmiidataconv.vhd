library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rmiidataconv is
	port (
		RMIIClk : in std_logic;
		Rst : in std_logic;
		
		RMII_RX1 : in std_logic;
		RMII_RX0 : in std_logic;
		RMII_DV : in std_logic;
		
		ByteOut : out std_logic_vector(7 downto 0);
		ByteReady : out std_logic
	);
end entity rmiidataconv;

architecture RTL of rmiidataconv is
	
	component shiftreg
		generic(depth : integer);
		port(
			RMIIClk : in  std_logic;
			RMII_DV : in  std_logic;
			Rst     : in  std_logic;
			DataIn  : in  std_logic;
			DataOut : out std_logic_vector(depth - 1 downto 0)
		);
	end component shiftreg;
	
	signal first_nibble : std_logic_vector(3 downto 0);
	signal second_nibble : std_logic_vector(3 downto 0);
	
	
begin

	first_shiftreg : component shiftreg
		generic map(
			depth => 4
		)
		port map(
			RMIIClk => RMIIClk,
			RMII_DV => RMII_DV,
			Rst     => Rst,
			DataIn  => RMII_RX1,
			DataOut => first_nibble
		);
		
	second_shiftreg : component shiftreg
		generic map(
			depth => 4
		)
		port map(
			RMIIClk => RMIIClk,
			RMII_DV => RMII_DV,
			Rst     => Rst,
			DataIn  => RMII_RX0,
			DataOut => second_nibble
		);

	ByteOut(6) <= first_nibble(3);
	ByteOut(4) <= first_nibble(2);
	ByteOut(2) <= first_nibble(1);
	ByteOut(0) <= first_nibble(0);
	
	ByteOut(7) <= second_nibble(3);
	ByteOut(5) <= second_nibble(2);
	ByteOut(3) <= second_nibble(1);
	ByteOut(1) <= second_nibble(0);
	
	ByteReadyCntr : process (RMIIClk, Rst) is
		variable cnt : integer := 0;
	begin
		if Rst = '1' then
			cnt := 0;
		elsif rising_edge(RMIIClk) and RMII_DV = '1' then
			cnt := cnt + 1;
		end if;
		
		if cnt = 4 then
			ByteReady <= '1';
			cnt := 0;
		else
			ByteReady <= '0';
		end if;
	end process ByteReadyCntr;
	
	
end architecture RTL;
