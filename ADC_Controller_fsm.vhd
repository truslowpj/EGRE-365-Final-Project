library IEEE;
use IEEE.std_logic_1164.all;

entity Controller is
	port ( MSG_I  : out STD_LOGIC;                           --new message
           STB_I  : out  STD_LOGIC;                           --strobe
           A_I    : out  STD_LOGIC_VECTOR (7 downto 0);      --address input bus
           D_I    : out  STD_LOGIC_VECTOR (7 downto 0);      --data input bus
           D_O    : in  STD_LOGIC_VECTOR (7 downto 0);     --data output bus
           DONE_O : in  STD_LOGIC;                         --done status signal
           ERR_O  : in  STD_LOGIC;                         --error status
           CLK    : in std_logic;                           --main clock input
           SRST   : out std_logic;
					 RST		: in std_logic;
					 DATA_OUT: out std_logic_vector (15 downto 0);
					 START 	: in std_logic);
	end Controller;
	
architecture Simple of Controller is
	type state_type is (ready, config_Strobe, config_strobe_hold config_Wait, address_strobe, address_strobe_hold, address_wait, 
													stb_hold_wait, read_msbyte, read_msbyte_wait, read_lsbyte);
	Signal current_state, next_state : state_type;
	
	BEGIN
	
	memory : PROCESS(clk,rst)
   BEGIN
     IF(rst='1') THEN 
       current_state <= FIRST;
    ELSIF(rising_edge(clk)) THEN
      current_state <= next_state;
    END IF;  
 END PROCESS memory;
 
nextstate : PROCESS(current_state,START, ERR_O, DONE_O)
	VARIABLE count : integer range 0 to 510;
	BEGIN
	
		CASE current_state IS
			WHEN ready =>
						IF (START = '1') THEN
							next_state <= config_STROBE;
						ELSE next_state <= ready;
						END IF;
						
			WHEN config_STROBE =>
						next_state <= config_strobe_hold;
			
			WHEN config_strobe_hold =>
						next_state <= config_wait;
			
			WHEN config_wait =>
						IF (DONE_O = '0') THEN
							next_state <= address_strobe;
						ELSE next_state <= config_wait;
						END IF;
						
			WHEN address_strobe =>
						next_state <= address_strobe_hold;		
			
			WHEN address_strobe_hold =>
						next_state <= address_wait;
			
			WHEN address_wait =>
						IF (DONE_O = '0') THEN
							next_state <= stb_hold_wait;
						ELSE next_state <= stb_hold_wait;
							count := 0;
						END IF;						
			
			WHEN stb_hold_wait =>
						IF (count = 510) THEN
							next_state <= read_msbyte;
							count := 0;
						ELSE next_state <= stb_hold_wait;
							count := count + 1;
						END IF;
						
			WHEN read_msbyte =>
						if (DONE_O = '0') THEN
							next_state := read_lsbyte;			
			
			WHEN read_lsbyte =>
						if (DONE_O) = '0' THEN
							next_state := ready;
			
			END CASE;
			
			
			
output_process : PROCESS(current_state, ERR_O, DONE_O, D_O)
		CASE current_state IS
			WHEN ready =>
			
			
			WHEN config_STROBE =>
			
			
			WHEN config_strobe_hold =>
			
			
			WHEN config_wait =>
			
			
			WHEN address_strobe =>
			
			
			WHEN address_strobe_hold =>
			
			
			WHEN address_wait =>
			
			
			WHEN stb_hold_wait =>
			
			
			WHEN read_msbyte =>
			
			
			WHEN read_msbyte_wait =>
			
			
			WHEN read_lsbyte =>
			
			
			END CASE;			
			