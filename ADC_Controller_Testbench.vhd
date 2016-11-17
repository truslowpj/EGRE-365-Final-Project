Library IEEE;
use IEEE.std_logic_1164.all;

entity ADC_Controller_Testbench is
end ADC_Controller_Testbench;

architecture behavior of ADC_Controller_Testbench is

  --------------------------------------------------------
  ----
  -- ProcedureName: waitclocks
  --
  -- This procedure halts a process execution for a given
  -- number of clock cycles. The clock cycle used in this
  -- procedure is falling-edge.
  --------------------------------------------------------
  ----
  procedure waitclocks(signal clock : std_logic;
                       N : INTEGER) is
		begin
			for i in 1 to N loop
				wait until clock'event and clock='0';	-- wait on falling edge
			end loop;
	end waitclocks;

  --------------------------------------------------------
  -- ADC controller specific signals. These signals are
  -- specific to the ADC controller.
  --------------------------------------------------------  
  signal RST_sig	: std_logic;
  signal START_sig : std_logic := '0';
  signal DATA_OUT_sig : std_logic_vector(15 downto 0);
  
  --------------------------------------------------------
  -- Intermediate signals. These signals are between the
  -- ADC controller and the TWICtl.
  --------------------------------------------------------
  signal CLK_sig : std_logic := '0';
  signal SRST_sig : std_logic;
  signal STB_I_sig : std_logic;
  signal MSG_I_sig : std_logic;
  signal A_I_sig : std_logic_vector (7 downto 0);
  signal D_I_sig : std_logic_vector (7 downto 0);
  signal DONE_O_sig : std_logic;
  signal ERR_O_sig : std_logic;
  signal D_O_sig : std_logic_vector (7 downto 0);

  --------------------------------------------------------
  -- TWICtl specific signals. These signals are specific to
  -- the TWI controller.
  --------------------------------------------------------
  signal SDA_sig : std_logic;
  signal SCL_sig : std_logic;     
  
	begin
	
	--------------------------------------------------------
  ----
  -- ProcessName: clock
  --
  -- This process is responsible for generating the clock
  -- signal for the TWI controller and the ADC controller.
  --------------------------------------------------------
  ----
  clock : process(CLK_sig)
  begin
    CLK_sig <= (NOT CLK_sig) after 25 NS;
  end process clock;

  --------------------------------------------------------
  ----
  -- ProcessName: start_clock
  --
  -- This process is responsible for generating the START 
  -- signal for the ADC controller. This signal is driven
  -- by a clock divider which is connected to the same
  -- clock that drives the ADC controller and TWI controller.  
  --------------------------------------------------------
  ----  
  start_clock : process (START_sig)
  begin
    START_sig <= (NOT START_sig) after 50 ns;
   end process start_clock;
  
	--------------------------------------------------------
  ----
  -- ComponentName: Controller (ADC controller)
  --
  -- This is the the Controller instantiation for the DUT. For
  -- this test bench, the DUT is the ADC controller.
  --------------------------------------------------------
  ----  
  ADC_DUT : entity work.Controller(simple)
    port map(MSG_I => MSG_I_sig,
                  STB_I => STB_I_sig,
                  A_I => A_I_sig,
                  D_I => D_I_sig,
                  DONE_O => DONE_O_sig,
                  ERR_O => ERR_O_sig,
                  CLK => CLK_sig,
                  SRST => SRST_sig,
                  RST => RST_sig,
                  DATA_OUT => DATA_OUT_sig,
                  START => START_sig,
                  D_O => D_O_sig);
  
	--------------------------------------------------------
  ----
  -- ComponentName: TWICtl (TWI controller)
  --
  -- This is the the instantiation for the TWICtl DUT. For
  -- this test bench, the DUT is the ADC controller.
  --------------------------------------------------------
  ----
    TWICtl_DUT : entity work.TWICtl(Behavioral)
    generic map(CLOCKFREQ => 100)
    port map(MSG_I => MSG_I_sig,
                  STB_I => STB_I_sig,
                  A_I => A_I_sig,
                  D_I => D_I_sig,
                  DONE_O => DONE_O_sig,
                  ERR_O => ERR_O_sig,
                  CLK => CLK_sig,
                  SRST => SRST_sig,                       
                  SDA => SDA_sig,                        
                  SCL => SCL_sig);
  
  --------------------------------------------------------
  ----
  -- ProcessName: slave_stimulus
  --
  -- This process is responsible for generating the slave 
  -- response for the TWI controller. It drives the SDA 
  -- signal to '0' at the appropriate times ti furnish an
  -- "ACK" signal to the TWI master device and '0' and 'H'
  -- at appropriate times to simulate the data being
  -- returned from the ADC over the TWI bus.
  --------------------------------------------------------
  ----  
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

end Behavior;