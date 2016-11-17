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
	
architecture SIMPLE of Controller is
	type state_type is (ready, config_Strobe, config_strobe_hold, config_Wait, address_strobe, address_strobe_hold, address_wait, 
													stb_hold_wait, read_msbyte, read_msbyte_wait, read_lsbyte);
	Signal current_state, next_state : state_type;
	
	constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := "0101100";	-- TWI address for the ADC
  constant writeCfg	 : STD_LOGIC_VECTOR(7 downto 0) := "00100000";	-- configuration register value for the ADC - read VIN0
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0';
	constant null_byte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	constant null_2_byte : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
	
	BEGIN
	
	memory : PROCESS(clk,rst)
   BEGIN
     IF(rst='1') THEN 
       current_state <= ready;
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
							next_state <= read_lsbyte;			
						END IF;
						
			WHEN read_lsbyte =>
						if (DONE_O) = '0' THEN
							next_state <= ready;
						END IF;
						
			WHEN others =>
						next_state <= ready;
			
			END CASE;
			
	END PROCESS nextstate;
			
output_process : PROCESS(current_state, ERR_O, DONE_O, D_O, RST)
		
	BEGIN
		
		IF (RST) THEN
			SRST <= '1';
			DATA_OUT <= null_2_byte;
		END IF;
		
		CASE current_state IS
			WHEN ready =>
						MSG_I <= 	'0';
						STB_I <= 	'0';
						A_I 	<= 	addrAD2 & write_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN config_STROBE =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & write_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN config_strobe_hold =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & write_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN config_wait =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
			
			WHEN address_strobe =>
						MSG_I <= 	'1';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
			
			WHEN address_strobe_hold =>
						MSG_I <= 	'1';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
			
			WHEN address_wait =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
			
			WHEN stb_hold_wait =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
			
			WHEN read_msbyte =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
						DATA_OUT(15 downto 8) <= D_O;
			
			WHEN read_msbyte_wait =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
						
			WHEN read_lsbyte =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	null_byte;
						DATA_OUT(7 downto 0) <= D_O;

			END CASE;			
			
	END PROCESS output_process;
	END ARCHITECTURE SIMPLE;
			