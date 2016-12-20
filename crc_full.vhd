---------------------------------------------------------------
--                      Projekt OpenVPN                      --
-- Autor              : Michał Zagórski                      --
-- Nazwa modułu       : crc-1                                --
-- Wejścia            : CLK       - zeger                    --
--                    : Enable    - aktywacja modułu         --
---------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crc_4bit.all;

entity CRC is
	port(
		-- input
	clk      : in std_logic;
	rst      : in std_logic;
	data_in  : in std_logic_vector(3 downto 0);
	
		-- output
		
	crc_out  : out std_logic_vector(31 downto 0);
	error : out std_logic);

end entity;

architecture crc_verification of CRC is
	signal verify: std_logic;
	signal crc: std_logic_vector(31 downto 0);
	--buffer crc_buff: std_logic_vector(31 downto 0);
	-- variable polynomial: std_logic_vector(32 downto 0) := '100000100110000010001110110110111';
	-- IEEE 802.3 : x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
	-- Hex representation: 0x82608EDB 
	-- Magic number: 0xC704DD7B
	
begin
	process (clk)
		--variable last: std_logic_vector(31 downto 0);
		variable crc2: std_logic_vector(31 downto 0);
	begin
		if (rst = '1') then
			crc2 := (others => '0');
			verify <= '0';
			--crc <= X"FEEDFACE";
		elsif (clk'event and clk = '1') then
			crc2 := nextCRC32_D4(data_in, crc); 
			
			--if (crc_out = '11000111000001001101110101111011') then
			-- Wypisuje f6 e7 f6 28
			if (crc2 = X"C704DD7B") then
				verify <= '1';
			else
				verify <= '0';
			end if;
			crc <= crc2;
		end if;
		
	end process;
	crc_out <= crc;
	error <= not verify;
end architecture crc_verification;
