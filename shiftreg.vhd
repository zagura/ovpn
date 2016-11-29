--EP2C70F896C6

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shiftreg is
	generic (
		depth : integer);
	port (
		--input
		RMIIClk : in std_logic;
		Rst : in std_logic;
		DataIn : in std_logic;
		
		--output
		DataOut : out std_logic_vector(depth-1 downto 0)
	);
end entity shiftreg;

architecture RTL of shiftreg is
	signal reg : std_logic_vector(depth-1 downto 0) := (others=>'0');
	
begin
	sreg : process(RMIIClk, Rst) is
	begin
		if Rst='1' then
			reg <= (others=>'0');
		elsif rising_edge(RMIIClk) then
			reg <= reg(depth-2 downto 0) & DataIn;	
		end if;
	end process sreg;

	DataOut <= reg;
	
	
end architecture RTL;
