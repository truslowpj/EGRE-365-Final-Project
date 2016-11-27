----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:51:54 03/09/2016 
-- Design Name: 
-- Module Name:    divider - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

ENTITY start_trigger is
-- use these values for simulation -----
--  GENERIC(DIVISOR : positive := 100);
----------------------------------------
-- use these values for synthesis ------
  GENERIC(DIVISOR : positive := 10000);
-----------------------------------------
  PORT(mclk : IN  std_logic;
       sclk : OUT std_logic);
END start_trigger;

ARCHITECTURE behavior OF start_trigger IS

	SIGNAL sclki : std_logic := '0';
  
  BEGIN

    div_clk : PROCESS(mclk)
    
      VARIABLE count : integer RANGE 0 to DIVISOR/2 := 0;

      BEGIN
        IF(rising_edge(mclk)) THEN
          IF(count = (DIVISOR/2)-1) THEN
            count := 0;
          ELSE
            count := count + 1;
          END IF;
        END IF;
				IF (count > ((DIVISOR/2)-1-100) ) THEN
				sclk <= '1';
				ELSE 
				sclk <= '0';
				END IF;
    END PROCESS div_clk;

    --sclk <= sclki;
	 
END behavior;


