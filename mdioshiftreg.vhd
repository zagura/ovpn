library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mdioshiftreg is
	port (
		MClk : in std_logic;
		Rst : in std_logic;
		Direction : in std_logic; --1 - send, 0 - receive
		
		StartSending : inout std_logic;
		DataReceived : inout std_logic;
		
		BitInOut : inout std_logic;
		
		DataIn : in std_logic_vector(15 downto 0);
		DataOut : out std_logic_vector(15 downto 0)
	);
end entity mdioshiftreg;

architecture RTL of mdioshiftreg is
	signal sreg : std_logic_vector(15 downto 0) := (others => '0');
	signal dir : std_logic := '1';
	signal stopped : std_logic := '1';
begin
	
	set_direction : with stopped select
		dir <=
			Direction when '1',
			dir when others;

	set_data : with stopped select
		sreg <=
			DataIn when '1',
			sreg when others;
			
	set_bitout : with stopped select
		BitOut <=
			'Z' when '1',
			 when others;
	
	
	
	
	
	
	sregproc : process (MClk) is
	begin
		if rising_edge(MClk) then
			if Rst = '1' then
				sreg <= (others => '0');
			else
				
			end if;
		end if;
	end process sregproc;
	
end architecture RTL;
