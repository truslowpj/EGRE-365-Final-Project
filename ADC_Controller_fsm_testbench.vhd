-- // PETER

library ieee;
use ieee.std_logic_1164.all;

entity ADC_testbench is
end ADC_testbench;

architecture behavior of ADC_testbench is

	-- This procedure waits for N number of falling edges on the specified
	-- clock signal
	
	procedure waitclocks(signal clock : std_logic;
                       N : INTEGER) is
		begin
			for i in 1 to N loop
				wait until clock'event and clock='0';	-- wait on falling edge
			end loop;
	end waitclocks;

  signal CLK_sig    : std_logic := '0';					-- signals to connect to the TWI
  signal RESET_sig  : std_logic := '0';
	signal SRESET_SIG : std_logic := '0';
  signal SCL_sig    : std_logic;
  signal MSG_I_sig  : std_logic;
  signal STB_I_sig  : std_logic;
  signal DONE_O_sig : std_logic;
  signal ERR_O_sig  : std_logic;
  signal SDA_sig    : std_logic;
  signal A_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
  signal D_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
  signal D_O_sig    : STD_LOGIC_VECTOR (7 downto 0);
	signal START_SIG	:STD_LOGIC;
	signal slave_rdy	: STD_LOGIC;
	signal DONE_O_DELAY_sig : STD_LOGIC;
	
	signal STATE_DEBUG_SIG			:STD_LOGIC_VECTOR (3 downto 0);
	signal COUNT_SIG						:integer range 0 to 510;
  
  signal LED_sig    : STD_LOGIC_VECTOR(15 downto 0);	-- 16-bit "result" of 2-byte read from ADC

  constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := "0101100";	-- TWI address for the ADC
  constant writeCfg	 : STD_LOGIC_VECTOR(7 downto 0) := "00100000";	-- configuration register value for the ADC - read VIN0
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0';

  
  constant Tperiod : time := 10 ns;						-- 100 MHz clock
  
  
  begin
  
	-- This process generates the 100 MHz system clock
	
    process(CLK_sig)
      begin
        CLK_sig <= not CLK_sig after Tperiod/2;
    end process;
		
		
		
		
  
	-- This process simulates the state machine that drives the TWI controller to perform the bus
	-- master operations. These include a configuration register write, followed by a two-byte
	-- data register read. This process drives all of the non-TWI bus inputs to the TWI controller,
	-- (except the 100 MHz system clock) which includes:
	-- MSG_I --new message input to signal multi-byte transfer
    -- STB_I --strobe to start TWI bus cycle
    -- A_I   --address input bus
    -- D_I   --data input bus
	
	master_stimulus : process
      begin
			
			RESET_sig <= '1';
			waitclocks(CLK_sig,10);
			RESET_sig <= '0';

																																												

        wait; -- stop the process to avoid an infinite loop

	end process master_stimulus;

	-- This process the ADC slave device on the TWI bus. It drives the SDA signal to '0' at the appropriate
	-- times to furnish an "ACK" signal to the TWI master device and '0' and 'H' at appropriate times to 
	-- simulate the data being returned from the ADC over the TWI bus.
	
	slave_stimulus : process
      begin
		SDA_sig <= 'H';						-- not driven
		SCL_sig <= 'H';						-- not driven

										-- address write
		waitclocks(SCL_sig, 9);			-- wait for transmission time
		slave_rdy <= '0';
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';
										-- config register write
		waitclocks(SCL_sig, 8);			-- wait for transmission time
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';

										-- address write
		waitclocks(SCL_sig, 9);			-- wait for transmission time
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';

		SDA_sig <= 'H';					-- MSB (upper byte)
		waitclocks(SCL_sig, 1);	
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- LSB
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- Release bus

		
		waitclocks(SCL_sig, 1);			
		SDA_sig <= '0';					-- MSB (lower byte)
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- LSB (lower byte)
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig,1);
				slave_rdy <= '1';
		
		

		-------------------------------------------------------again
			waitclocks(SCL_sig,1);
			slave_rdy <= '0';
			waitclocks(SCL_sig, 8);			-- wait for transmission time
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';
										-- config register write
		waitclocks(SCL_sig, 8);			-- wait for transmission time
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';

										-- address write
		waitclocks(SCL_sig, 9);			-- wait for transmission time
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);			-- wait for ack time
		SDA_sig <= 'H';

		SDA_sig <= 'H';					-- MSB (upper byte)
		waitclocks(SCL_sig, 1);	
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- LSB
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- Release bus

		
		waitclocks(SCL_sig, 1);			
		SDA_sig <= '0';					-- MSB (lower byte)
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= '0';
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';					-- LSB (lower byte)
		waitclocks(SCL_sig, 1);
		SDA_sig <= 'H';
		
		
		
        wait; -- stop the process to avoid an infinite loop

	end process slave_stimulus;

 
    -- this is the component instantiation for the
    -- DUT - the device we are testing
		ADC_DUT : entity work.Controller(simple)
	  port map(MSG_I  => MSG_I_sig,  -- new message
                 STB_I  => STB_I_sig,  -- strobe
                 A_I    => A_I_sig,    -- address input bus
                 D_I    => D_I_sig,    -- data input bus
                 D_O    => D_O_sig,    -- data output bus
                 DONE_O => DONE_O_sig, -- done status signal
                 ERR_O  => ERR_O_sig,  -- error status
                 CLK    => clk_sig,    -- Input Clock
                 SRST   => SRESET_sig,  -- Reset
								 RST		=> RESET_sig,		--state machine reset
								 DATA_OUT => LED_sig,
								 start 	=>	START_SIG	,								
								 Count	=>	COUNT_SIG,
								 STATE_DEBUG => STATE_DEBUG_SIG,
								 DONE_O_DELAY_OUT => DONE_O_DELAY_sig
								 );
		
    TWI_DUT : entity work.TWICtl(Behavioral)
		generic map (CLOCKFREQ => 100) -- System clock in MHz
		port map(MSG_I  => MSG_I_sig,  -- new message
                 STB_I  => STB_I_sig,  -- strobe
                 A_I    => A_I_sig,    -- address input bus
                 D_I    => D_I_sig,    -- data input bus
                 D_O    => D_O_sig,    -- data output bus
                 DONE_O => DONE_O_sig, -- done status signal
                 ERR_O  => ERR_O_sig,  -- error status
                 CLK    => clk_sig,    -- Input Clock
                 SRST   => SRESET_sig,  -- Reset passthrough to twi core

                 SDA    => SDA_sig,    --TWI SDA
                 SCL    => SCL_sig   --TWI SCL
								 
);
			DIVIDER : entity work.clock_divider(behavior)
			generic map (Divisor => 60000) 
			port map (mclk => clk_sig,
								sclk => START_SIG);
 
											-- address write (write)
 
end behavior;