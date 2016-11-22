-----------------------------------------------------------------------
--  Inputs:
--		CPU_RESETN	Main Reset Signal (active low)
--		SYS_CLK		100MHz onboard system clock
--		AD2_SDA		PmodAD2 I2C interface In/Out data line
--		AD2_SCL		PmodAD2 I2C interface In/Out clock line
--		SCL_ALT_IN	signal to connect to 2nd PmodAD2 I2C clock line
--		SDA_ALT_IN	signal to connect to 2nd PmodAD2 I2C data line
--
--  Outputs:
--		LED			16-bit output to LEDs
--
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- This is the library we need to include for the PULLUP components
-- it should be automatically known to the Vivado tools
Library UNISIM;
use UNISIM.vcomponents.all;

entity ADC_toplevel is
    Port ( CPU_RESETN  : in		STD_LOGIC;
           SYS_CLK     : in		STD_LOGIC;
           AD2_SCL     : inout	STD_LOGIC;
           AD2_SDA     : inout	STD_LOGIC;
           LED         : out	STD_LOGIC_VECTOR(15 downto 0);
           SCL_ALT_IN  : inout	STD_LOGIC;
           SDA_ALT_IN  : inout	STD_LOGIC);
end ADC_toplevel;

architecture Structural of ADC_toplevel is

	signal RESET_sig  : std_logic := '0';
	signal SRESET_SIG : std_logic := '0';
	signal START_sig  : std_logic := '0';
	signal MSG_I_sig  : std_logic;
	signal STB_I_sig  : std_logic;
	signal DONE_O_sig : std_logic;
	signal ERR_O_sig  : std_logic;
	signal A_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
	signal D_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
	signal D_O_sig    : STD_LOGIC_VECTOR (7 downto 0);

	signal LED_sig    : STD_LOGIC_VECTOR (15 downto 0);
	
	signal STATE_DEBUG_SIG			:integer range 0 to 20;
	signal COUNT_SIG						:integer range 0 to 510;
  
	constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := "0101100";	-- TWI address for the ADC
  constant writeCfg	 : STD_LOGIC_VECTOR(7 downto 0) := "00100000";	-- configuration register value for the ADC - read VIN0
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0';
	
------------------------------------------------------------------------
-- Implementation
------------------------------------------------------------------------
	begin

	-- The PmodAD2 has dual SDA and SCL lines for daisy chaining TWI bus devices. If 
	-- these other pins are brought low accadentially, then the device will refuse to
	-- transmit data. To prevent this, we drive them as high impedance if they are 
	-- connected. If they are disconnected, they are left floating and the system
	-- should still work.
	SDA_ALT_IN <= 'Z';
	SCL_ALT_IN <= 'Z';

	-- CPU_RESETN input is active low, so we need to invert it
	RESET_sig <= not CPU_RESETN;
    
	-- We want to drive the outputs to the TWI interface like we have pull up resistors attached.
	-- So when controller indicates we're high Z, attach the signal to a weak high signal instead.
	PULLUP_SDA: PULLUP PORT MAP ( O=>AD2_SCL );
	PULLUP_SCL: PULLUP PORT MAP ( O=>AD2_SDA );

	-- here is where we need to instantiate the TWI IP core, the TWI Core Controller
	-- state machine, and a clock divider for the 20 Hz clokc, as well as any other
	-- components required
	
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
                 CLK    => sys_clk,    -- Input Clock
                 SRST   => SRESET_sig,  -- Reset
								 RST		=> RESET_sig,		--state machine reset
								 DATA_OUT => LED_sig,
								 start 	=>	START_SIG	,								
								 Count	=>	COUNT_SIG,
								 STATE_DEBUG => STATE_DEBUG_SIG
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
                 CLK    => sys_clk,    -- Input Clock
                 SRST   => SRESET_sig,  -- Reset passthrough to twi core

                 SDA    => AD2_SDA,    --TWI SDA
                 SCL    => AD2_SCL   --TWI SCL
								 
);
			DIVIDER : entity work.clock_divider(behavior)
			generic map (Divisor => 60000) 
			port map (mclk => sys_clk,
								sclk => START_SIG);
	
	
end Structural;

