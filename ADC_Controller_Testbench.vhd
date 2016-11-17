Library IEEE;
use IEEE.std_logic_1164.all;

entity ADC_Controller_Testbench is
end ADC_Controller_Testbench;

architecture behavior of ADC_Controller_Testbench is
    
  --------------------------------------------------------
  -- ADC controller specific signals. These signals are
  -- specific to the ADC controller.
  --------------------------------------------------------
  signal ADC_CLK_sig : std_logic;
  signal RST	: std_logic;
  signal START : std_logic;
  
  --------------------------------------------------------
  -- Intermediate signals. These signals are between the
  -- ADC controller and the TWICtl.
  --------------------------------------------------------
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
  signal TWICtl_CLK_sig : std_logic;
  signal SDA_sig : std_logic;
  signal SCL_sig : std_logic;     
  
	begin
	
	--------------------------------------------------------
  ----
  -- ProcessName: TWICtl_clock
  --
  -- This process is responsible for generating the clock
  -- signal for the TWI controller. This clock should be
  -- faster than the ADC controller clock.
  --------------------------------------------------------
  ----
	process TWICtl_clock(TWICtl_CLK_sig)
  begin
    TWICtl_CLK_sig <= not TWICtl_CLK_sig after 50ns;
  end process;

  --------------------------------------------------------
  ----
  -- ProcessName: ADC_clock
  --
  -- This process is responsible for generating the clock
  -- signal for the ADC controller. This clock should be 
  -- slower than the TWI controller clock.
  --------------------------------------------------------
  ----  
  process ADC_clock(ADC_CLK_sig)
  begin
    ADC_CLK_sig <= not ADC_CLK_sig after 25ns;
   end process;
  
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
                  CLK => ADC_CLK_sig,
                  SRST => STRT_sig,
                  RST => RST_sig,
                  DATA_OUT => DATA_OUT_sig,
                  START => START_sig);
  
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
                  CLK => TWICtl_CLK_sig,
                  SRST => STRT_sig,                       
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

end architecture;