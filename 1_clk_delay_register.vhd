library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.math_real.all;

entity delay_register is
	port (input : in std_logic;
				output : out std_logic;
				clk : in std_logic);
				
end delay_register;				

				
	architecture simple of delay_register is
			signal outbox, inbox : std_logic;
		begin
		process(clk, input)
		begin
		
			if (rising_edge(clk)) THEN
				--output <= outbox;
				inbox <= input;
			end if;
			
			if (falling_edge(clk)) THEN
				output <= inbox;
			end if;
						
		end process;
		
	end simple;