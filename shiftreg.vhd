--EP2C70F896C6

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shiftreg is
	port (
		--input
		clk : in std_logic;
		rst : in std_logic;
		data_in : in std_logic;
		
		--output
		data_out : out std_logic_vector(3 downto 0);
		output_rdy : out std_logic
	);
end entity shiftreg;

architecture RTL of shiftreg is
	signal reg : std_logic_vector(3 downto 0) := (others=>'0');
	signal cnt : natural := 0;
	
begin
	sreg : process(clk, rst) is
	begin
		if rst='1' then
			reg <= (others=>'0');
			data_out <= (others=>'0');
			output_rdy <= '0';
			cnt <= 0;
		elsif rising_edge(clk) then
			reg <= reg(2 downto 0) & data_in;
			cnt <= cnt+1;
			if cnt = 4 then
				cnt <= 0;
				output_rdy <= '1';
			else
				output_rdy <= '0';
			end if;		
		end if;
	end process sreg;

	data_out  <= reg;
	
	
end architecture RTL;
