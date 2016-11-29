library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mdioshiftreg is
	port (
		MClk : in std_logic;
		Rst : in std_logic;
		Direction : in std_logic; --1 - send, 0 - receive
		
		Start : inout std_logic;
		
		BitInOut : inout std_logic;
		
		DataIn : in std_logic_vector(15 downto 0);
		DataOut : out std_logic_vector(15 downto 0)
	);
end entity mdioshiftreg;

architecture RTL of mdioshiftreg is
	signal sreg : std_logic_vector(15 downto 0) := (others => '0');
	signal dir : std_logic := '1';--1 - send, 0 - receive
	signal stopped : std_logic := '1';
	signal BitInOutWrapper : std_logic := 'Z';
begin
	
	BitInOut <= '0' when BitInOutWrapper = '0' else
					'Z';
					
	BitInOutWrapper <=	'1' when BitInOut /= '0' else
								'0' when BitInOut = '0';
	
	set_direction : with stopped select
		dir <=
			Direction when '1',
			dir when others;

	set_data : with stopped select
		sreg <=
			DataIn when '1',
			sreg when others;
			
	stopped <= '0' when Start = '1' and stopped = '1' else
					stopped;
			
	DataOut <= sreg;
	
	
	
	sregproc : process (MClk) is
		variable i : natural := 0;
	begin
		if rising_edge(MClk) then
		
			if Rst = '1' then
				sreg <= (others => '0');
				i := 0;
			elsif stopped = '0' then
				if (dir = '1') then
					BitInOutWrapper <= sreg(15);
				end if;
					sreg <= sreg(14 downto 0) & BitInOutWrapper;
					i := i+1;
			end if;
			
			if i = 16 then
				stopped <= '1';
				i := 0;
			end if;
			
		end if;
	end process sregproc;
	
end architecture RTL;
