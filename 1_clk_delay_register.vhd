----------------------------------------------------------------------------------
-- Class: EGRE-365
-- Students: Adam Morrissett
--               Peter Truslow
-- 
-- Create Date:    11/28/2016
--
-- Module Name:   Delay Register
-- Project Name:	 EGRE-365 Final Project
--
-- Description: This entity is used to detect a falling edge
-- on a clock signal. This entity works by storing 
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.math_real.all;

entity delay_register is
	port (input : in std_logic;       -- Input signal
          output : out std_logic;   -- Delayed input signal
				clk : in std_logic);           -- Main clock of system
end delay_register;				

				
architecture simple of delay_register is

  -- When clock falls, the 
  signal outbox : std_logic := '0';  -- 
  signal inbox : std_logic := '0';
  
begin
    
  process(clk, input)
  
  begin
		
			if (falling_edge(clk)) THEN
				inbox <= input;
				output <= outbox;
			end if;
			
			if (rising_edge(clk)) THEN
				outbox <= inbox;
			end if;
						
		end process;
		
  end simple;