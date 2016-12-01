library ieee;
use ieee.std_logic_1164.all;

entity TWI_testbench is
end TWI_testbench;

architecture behavior of TWI_testbench is

  --------------------------------------------------------
  -- This procedure waits for N number of falling edges on 
  -- the specified clock signal
  --
  -- parameter: clock - system clock signal 
  -- parameter: N - number of clock cycles to wait
	--------------------------------------------------------
	procedure waitclocks(signal clock : std_logic;
                                 N : INTEGER) is
	begin
  
    -- Wait for a falling edge event N times
    for i in 1 to N loop
    
      -- Wait for falling edge
      wait until clock'event AND clock = '0';
    end loop;
	end waitclocks;

  --------------------------------------------------------
  -- TWI core signals
  -- Signal names containing 'I' denote TWI input
  -- Signal names containing 'O' denote TWI output
  --------------------------------------------------------
  signal CLK_sig : std_logic := '0';  -- Clock signal		
  signal RESET_sig : std_logic := '0';  -- Rest signal
  
  -- 8-bit input address and data signals
  signal A_I_sig : STD_LOGIC_VECTOR (7 downto 0);
  signal D_I_sig : STD_LOGIC_VECTOR (7 downto 0);
    
  -- Signals multi-byte transfer ??
  signal MSG_I_sig : std_logic;
  
  signal STB_I_sig : std_logic; -- Initializes data transfer
  
  -- 8-bit output data signal
  signal D_O_sig : STD_LOGIC_VECTOR (7 downto 0);
  
  signal DONE_O_sig : std_logic;  -- Transfer done signal
  signal ERR_O_sig : std_logic; -- Transfer error signal
  
  signal SCL_sig : std_logic; -- Clock signal
  signal SDA_sig : std_logic; -- Data signal 
  
  signal LED_sig : STD_LOGIC_VECTOR(15 downto 0);	-- 16-bit "result" of 2-byte read from ADC

  --------------------------------------------------------
  -- Testbench constants
  --------------------------------------------------------
  constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := "0101100";	-- TWI address for the ADC
  constant writeCfg	 : STD_LOGIC_VECTOR(7 downto 0) := "00100000";	-- configuration register value for the ADC - read VIN0
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0'; 
  constant Tperiod : time := 10 ns; -- 100 MHz clock period
    
begin
  
  --------------------------------------------------------
  -- This process generates the 100 MHz system clock.
  -- This process is run every time the CLK_sig changes.
  --
  -- sensitivity: CLK_sig - the system clock signal
  --------------------------------------------------------
  process(CLK_sig)
    begin
    
      -- Invert clock signal after half of clock period
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
	
  --------------------------------------------------------
  -- This process simulates the master stimulus state
  -- machine that drives the TWI controller. It drives all of 
  -- the non-TWI (not SCL and SDA) input singals except 
  -- for the clock signal. This process is run constantly.
  --
  -- sensitivity: n/a
  --------------------------------------------------------
	master_stimulus : process
  begin
	  
    -- Set signals default values
    MSG_I_sig <= '0';
    STB_I_sig <= '0'; -- No data transfer active
		RESET_SIG <= '0';
    
    -- Load ADC address + write bit (0) into TWI address
    -- register
		A_I_sig <= addrAD2 & write_Bit;
    
    -- Load ADC configuration data into data input register
		D_I_sig <= writeCfg;
		
    -- Wait for 10 clock cyckes, then activate RESET
    -- for 2 clock cycles
		waitclocks(clk_sig, 10);
		RESET_sig <= '1';
		waitclocks(clk_sig, 2);
		RESET_sig <= '0';
																
    -- Wait for TWI bus to be "free" (must wait at least 
    -- 1000 clocks)
		waitclocks(clk_sig, 1200);
		
    -- Start configuration write operation
    -- STB must be asserted for two cycles
		STB_I_sig <= '1';
		waitclocks(clk_sig, 2);
		STB_I_sig <= '0';

    	-- Wait until TWI controller signals done
		wait until DONE_O_sig'event and DONE_O_sig='0';
    
    
    -- Load ADC address + read bit (1) into TWI address
    -- register
		A_I_sig <= addrAD2 & read_Bit;
        
    -- Signal a multi-byte read operation. The MSG signal
    -- has to be asserted with the STB signal, so MSG is
    -- held high until after 2 clock cycles. After 2 clock
    -- cycles, the STB signal should be captured and the 
    -- MSG signal can be set low
		MSG_I_sig <= '1';
		STB_I_sig <= '1';
		waitclocks(clk_sig, 2);
		MSG_I_sig <= '0';

    -- Wait until TWI controller signals done
		wait until DONE_O_sig'event and DONE_O_sig='0';	
																																									--stb_hold_wait
		waitclocks(clk_sig, 510);						-- you have to go past 1/2 SCL cycle before dropping
		STB_I_sig <= '0';								-- STB, I'm not sure why
																																									--read_msbyte
		LED_sig(15 downto 8) <= D_O_sig;				-- load MSB data read
																																									--read_msbyte_wait

    -- Wait until TWI controller signals done
		wait until DONE_O_sig'event and DONE_O_sig='0';
		LED_sig(7 downto 0) <= D_O_sig;					-- load LSB data read									--read_lsbyte

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
    DUT : entity work.TWICtl(Behavioral)
		generic map (CLOCKFREQ => 100) -- System clock in MHz
		port map(MSG_I  => MSG_I_sig,  -- new message
                 STB_I  => STB_I_sig,  -- strobe
                 A_I    => A_I_sig,    -- address input bus
                 D_I    => D_I_sig,    -- data input bus
                 D_O    => D_O_sig,    -- data output bus
                 DONE_O => DONE_O_sig, -- done status signal
                 ERR_O  => ERR_O_sig,  -- error status
                 CLK    => clk_sig,    -- Input Clock
                 SRST   => RESET_sig,  -- Reset

                 SDA    => SDA_sig,    --TWI SDA
                 SCL    => SCL_sig);   --TWI SCL
			 
 
											-- address write (write)
 
end behavior;