-- // klenke - peter

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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This is the library we need to include for the PULLUP components
-- it should be automatically known to the Vivado tools
Library UNISIM;
use UNISIM.vcomponents.all;

entity ADC_toplevel is
    Port ( CPU_RESETN  : in		STD_LOGIC;
           SYS_CLK     : in		STD_LOGIC;
           AD2_SCL     : inout	STD_LOGIC;
           AD2_SDA     : inout	STD_LOGIC;
					 debug			 : out STD_LOGIC;
					 JA					 : out STD_LOGIC_VECTOR(7 downto 0);
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
	signal DATA_OUT_SIG : STD_LOGIC_VECTOR (15 downto 0);
	signal DONE_O_DELAY_sig : STD_LOGIC;
	signal state_debug_sig : STD_LOGIC_VECTOR (3 downto 0);
	
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
	debug <= DONE_O_sig;
	JA <= D_O_SIG;
	
	--process(state_debug_sig)
	--begin
	--if (state_debug_sig = "1001") then
	--		debug <= '1';
	--		else debug <= '0';
	--end if;
	--if (state_debug_sig = "1011") then
--			debug2 <= '1';
	--		else debug2 <= '0';
	--end if;
		
	--end process;
		
	-- CPU_RESETN input is active low, so we need to invert it
	RESET_sig <= not CPU_RESETN;
	--LED(15 downto 0) <= DATA_OUT_SIG(15 downto 0);
	
	--LEd(0) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod 1) = 0 ELSE '1';
	--LEd(1) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (1 * 256)) = 0 ELSE '1';
	--LEd(2) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (2 * 256)) = 0 ELSE '1';
	--LEd(3) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (13 * 256)) = 0 ELSE '1';
	--LEd(4) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (14 * 256)) = 0 ELSE '1';
	--LEd(5) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (15 * 256)) = 0 ELSE '1';
	--LEd(6) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (16 * 256)) = 0 ELSE '1';
	--LEd(7) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (17 * 256)) = 0 ELSE '1';
	--LEd(8) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (18 * 256)) = 0 ELSE '1';
	--LEd(9) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (19 * 256)) = 0 ELSE '1';
	--LEd(10) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (10 * 256)) = 0 ELSE '1';
	--LEd(11) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (11 * 256)) = 0 ELSE '1';
	--LEd(12) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (12 * 256)) = 0 ELSE '1';
	--LEd(13) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (13 * 256)) = 0 ELSE '1';
	--LEd(14) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (14 * 256)) = 0 ELSE '1';
	--LEd(15) <= '0' WHEN (to_integer(unsigned(DATA_OUT_SIG(15 downto 0))) mod (15 * 256)) = 0 ELSE '1';
	
	--LED (15 downto 12) <= state_debug_sig(3 downto 0);
	--LED(11) <= START_SIG;
    
    PROCESS(DATA_OUT_SIG)
    VARIABLE OUTPUT_VALUE : INTEGER := 0;
    BEGIN
        OUTPUT_VALUE := to_integer(unsigned(DATA_OUT_SIG(15 downto 0)));
    
        IF OUTPUT_VALUE > 0 THEN
            LED(0) <= '1';
        ELSE
            LED(0) <= '0';
        END IF;
    
        IF OUTPUT_VALUE > 256 THEN
            LED(1) <= '1';
        ELSE
            LED(1) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 512 THEN
            LED(2) <= '1';
        ELSE
            LED(2) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 768 THEN
            LED(3) <= '1';
        ELSE
            LED(3) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 1024 THEN
            LED(4) <= '1';
        ELSE
            LED(4) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 1280 THEN
            LED(5) <= '1';
        ELSE
            LED(5) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 1536 THEN
            LED(6) <= '1';
        ELSE
            LED(6) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 1792 THEN
            LED(7) <= '1';
        ELSE
            LED(7) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 2048 THEN
            LED(8) <= '1';
        ELSE
            LED(8) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 2304 THEN
            LED(9) <= '1';
        ELSE
            LED(9) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 2560 THEN
            LED(10) <= '1';
        ELSE
            LED(10) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 2816 THEN
            LED(11) <= '1';
        ELSE
            LED(11) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 3072 THEN
            LED(12) <= '1';
        ELSE
            LED(12) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 3328 THEN
            LED(13) <= '1';
        ELSE
            LED(13) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 3584 THEN
            LED(14) <= '1';
        ELSE
            LED(14) <= '0';
        END IF;
        
        IF OUTPUT_VALUE > 3840 THEN
            LED(15) <= '1';
        ELSE
            LED(15) <= '0';
        END IF;
                                                
    END PROCESS;       
    
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
								 DATA_OUT => DATA_OUT_SIG,
								 start 	=>	START_SIG	,								
								 Count	=>	COUNT_SIG,
								 STATE_DEBUG => state_debug_sig,
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
                 CLK    => sys_clk,    -- Input Clock
                 SRST   => SRESET_sig,  -- Reset passthrough to twi core

                 SDA    => AD2_SDA,    --TWI SDA
                 SCL    => AD2_SCL   --TWI SCL
								 
);
			DIVIDER : entity work.start_trigger(behavior)
			generic map (Divisor => 5000000) 
			port map (mclk => sys_clk,
								sclk => START_SIG);
	
	
end Structural;

