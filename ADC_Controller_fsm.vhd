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
					 START 	: in std_logic;
					 STATE_DEBUG	:out std_logic_vector(3 downto 0);
					 count : out integer range 0 to 510;
					 DONE_O_DELAY_OUT : out std_logic);
	end Controller;
	 
architecture simple of Controller is
	type state_type is (ready, config_Strobe, config_strobe_hold, config_Wait, address_strobe, address_strobe_hold, address_wait, 
													stb_hold_wait, read_msbyte, read_msbyte_wait, read_lsbyte, read_lsbyte_latch);
	Signal current_state, next_state : state_type;
	Signal current_DATA_OUT, next_DATA_OUT : std_logic_vector(15 downto 0);
	Signal last_DONE_O : std_logic;
	Signal count_next : integer range 0 to 510 := 0;
	Signal count_last : integer range 0 to 510 := 0;
	
	constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := "0101000";	-- TWI address for the ADC
  constant writeCfg	 : STD_LOGIC_VECTOR(7 downto 0) := "00010000";	-- configuration register value for the ADC - read VIN0
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0';
	constant null_byte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	constant null_2_byte : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
	
	BEGIN

	memory : PROCESS(clk,rst)
   BEGIN
     IF(rst='1') THEN 
       current_state <= ready;
			 current_DATA_OUT <= null_2_byte;
    ELSIF(rising_edge(clk)) THEN
      current_state <= next_state;
			current_DATA_OUT <= next_DATA_OUT;
    END IF;  
 END PROCESS memory;
 
debug : PROCESS(current_state, count_next, count_last, CLK)
	BEGIN
		IF(rising_edge(clk)) THEN
      count_last <= count_next;
    END IF;  
		count <= count_last;
	
		CASE current_state IS
			WHEN ready =>
						STATE_DEBUG <= "0000";
						
			WHEN config_STROBE =>
						STATE_DEBUG <= "0001";
			WHEN config_strobe_hold =>
						STATE_DEBUG <= "0010";
			WHEN config_wait =>
						STATE_DEBUG <= "0011";
			WHEN address_strobe =>
						STATE_DEBUG <= "0100";
			WHEN address_strobe_hold =>
						STATE_DEBUG <= "0101";
			WHEN address_wait =>
						STATE_DEBUG <= "0110";		
			
			WHEN stb_hold_wait =>
						STATE_DEBUG <= "0111";
			WHEN read_msbyte_wait =>
						STATE_DEBUG <= "1000";
			WHEN read_msbyte =>
						STATE_DEBUG <= "1001";
			WHEN read_lsbyte =>
						STATE_DEBUG <= "1010";
			when read_lsbyte_latch =>
						STATE_DEBUG <= "1011";
						
			WHEN others =>
						STATE_DEBUG <= "1111";
			END CASE;
			
	END PROCESS debug; 
 
nextstate : PROCESS(current_state,START, ERR_O, DONE_O, count_last, last_DONE_O, current_DATA_OUT)
	BEGIN
		DONE_O_DELAY_OUT <= last_DONE_O;
		CASE current_state IS
			WHEN ready =>
						IF (START = '1') THEN
							next_state <= config_STROBE;
						ELSE next_state <= ready;
						END IF;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
						
			WHEN config_STROBE =>
						next_state <= config_strobe_hold;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
			
			WHEN config_strobe_hold =>
						next_state <= config_wait;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
			
			WHEN config_wait =>
						IF (last_DONE_O = '1' and DONE_O ='0') THEN
							next_state <= address_strobe;
						ELSE next_state <= config_wait;
						END IF;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
						
			WHEN address_strobe =>
						next_state <= address_strobe_hold;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);	
							count_next <= 0;	
			
			WHEN address_strobe_hold =>
						next_state <= address_wait;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
			
			WHEN address_wait =>
						next_state <= read_msbyte_wait;
							count_next <= 0;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;

			WHEN read_msbyte_wait =>
						if (last_DONE_O = '1' and DONE_O ='0') THEN -- 
							next_state <= read_msbyte;		
						ELSE next_state <= read_msbyte_wait;
						END IF;						
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;

			WHEN read_msbyte =>
							next_state <= stb_hold_wait;
							next_DATA_OUT(15 downto 8) <= D_O(7 downto 0);
							next_DATA_OUT(7 downto 0) <= current_DATA_OUT(7 downto 0);
							count_next <= 0;
						
			WHEN stb_hold_wait =>
						IF (count_last >= 510) THEN
							next_state <= read_lsbyte;
							count_next <= 0;
						ELSE next_state <= stb_hold_wait;
							count_next <= count_last + 1;
						END IF;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
						
			WHEN read_lsbyte =>
						if (last_DONE_O = '1' and DONE_O ='0') THEN --last_DONE_O = '1' and 
							next_state <= read_lsbyte_latch;
						ELSE next_state <= read_lsbyte;
						END IF;			
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
						
			WHEN read_lsbyte_latch =>
					next_state <= ready;
							next_DATA_OUT(15 downto 8) <= current_DATA_OUT(15 downto 8);
							next_DATA_OUT(7 downto 0) <= D_O(7 downto 0);
							count_next <= 0;
						
			WHEN others =>
						next_state <= ready;
						next_DATA_OUT(15 downto 0) <= current_DATA_OUT(15 downto 0);
							count_next <= 0;
			
			END CASE;
			
	END PROCESS nextstate;
			
output_process : PROCESS(current_state, ERR_O, DONE_O, D_O, RST)
		
	BEGIN
		
		DATA_OUT <= current_DATA_OUT;
		
		IF (RST = '1') THEN
			SRST <= '1';
		ELSE SRST <= '0';
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
						A_I 	<= 	addrAD2 & write_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN address_strobe =>
						MSG_I <= 	'1';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN address_strobe_hold =>
						MSG_I <= 	'1';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN address_wait =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;
			
			WHEN read_msbyte_wait =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;

			WHEN read_msbyte =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;

			WHEN stb_hold_wait =>
						MSG_I <= 	'0';
						STB_I <=	'1';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;						
						
			WHEN read_lsbyte =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;						
						
			WHEN read_lsbyte_latch =>
						MSG_I <= 	'0';
						STB_I <=	'0';
						A_I 	<= 	addrAD2 & read_Bit;	
						D_I 	<= 	writeCfg;

			END CASE;			
			
	END PROCESS output_process;
	
	DONE_O_DELAY : entity work.delay_register(simple)
		port map (input => DONE_O,
							output => last_DONE_O,
							clk		=> clk);

	END ARCHITECTURE SIMPLE;
	
			