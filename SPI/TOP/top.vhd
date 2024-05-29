-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Michał Jędrzejczyk
-- ----------------------------------------------------------------------------------------
-- Create Date:    01/05/2024
-- Module Name:    top
-- Target Devices: CMOD C7
-- Description:    Top module to upload to the device.
--                 Also used to simplify testbench. 
-- ----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity top is
  port (
    clk               : in STD_LOGIC;                     -- clk
    btn_read          : in STD_LOGIC;                     -- start reading button
    btn_reset         : in STD_LOGIC;                     -- reset button
    xaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0); -- X axis data
    yaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0); -- Y axis data
    zaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0)  -- Z axis data
  );

end top;

architecture behavioral of top is
  component SPImaster
    port (
      -- SPI signals
      clk        : in STD_LOGIC;                     -- Clock signal
      reset      : in STD_LOGIC;                     -- Reset signal
      cs         : out STD_LOGIC;                    -- Chip select signal
      sclk       : out STD_LOGIC;                    -- Serial clock signal
      mosi       : out STD_LOGIC;                    -- Master Out Slave In signal
      miso       : in STD_LOGIC;                     -- Master In Slave Out signal
      read_data  : in STD_LOGIC;                     -- Start reading data from adxl
      xaxis_data : out STD_LOGIC_VECTOR(9 downto 0); -- X axis data
      yaxis_data : out STD_LOGIC_VECTOR(9 downto 0); -- Y axis data
      zaxis_data : out STD_LOGIC_VECTOR(9 downto 0)  -- Z axis data
    );
  end component;

  component SPIconverter
    port (
      -- SPI signals
      clk            : in STD_LOGIC;                     -- Clock signal
      reset          : in STD_LOGIC;                     -- Reset signal
      xaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);  -- X axis data
      yaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);  -- Y axis data
      zaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);  -- Z axis data
      xaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0); -- X axis data
      yaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0); -- Y axis data
      zaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0)  -- Z axis data
    );
  end component;

  component PmodACL
    port (
      clk  : in STD_LOGIC; -- Emulator clock signal 100MHz
      cs   : in STD_LOGIC; -- Chip select signal
      sclk : in STD_LOGIC; -- Serial clock signal 2,5MHz
      mosi : in STD_LOGIC; -- Master Out Slave In signal
      miso : out STD_LOGIC -- Master In Slave Out signal
    );
  end component;

  component debouncer
    port (
      i_clk       : in STD_LOGIC; -- clk debouncer input
      i_button    : in STD_LOGIC; -- input button 
      o_debouncer : out STD_LOGIC -- debounced button signal
    );
  end component;

  signal btn_reset_D : STD_LOGIC; -- debounced reset button
  signal btn_read_D  : STD_LOGIC; -- debounced start reading button

  signal cs_SPImaster_out         : STD_LOGIC;                    -- cs SPImaster out
  signal sclk_SPImaster_out       : STD_LOGIC;                    -- sclk SPImaster out
  signal mosi_SPImaster_out       : STD_LOGIC;                    -- mosi SPImaster out
  signal miso_SPImaster_out       : STD_LOGIC;                    -- miso SPImaster out
  signal xaxis_data_SPImaster_out : STD_LOGIC_VECTOR(9 downto 0); -- xaxis data SPImaster out
  signal yaxis_data_SPImaster_out : STD_LOGIC_VECTOR(9 downto 0); -- yaxis data SPImaster out
  signal zaxis_data_SPImaster_out : STD_LOGIC_VECTOR(9 downto 0); -- zaxis data SPImaster out

begin
  debouncer_Reset : entity work.debouncer
    generic map(DEBOUNCER_CNT_LIMIT => 100 - 1)
    port map(
      i_clk       => clk,
      i_button    => btn_reset,
      o_debouncer => btn_reset_D
    );

  debouncer_Read : entity work.debouncer
    generic map(DEBOUNCER_CNT_LIMIT => 100 - 1)
    port map(
      i_clk       => clk,
      i_button    => btn_read,
      o_debouncer => btn_read_D
    );

  SPImaster_1 : entity work.SPImaster
    generic map(
      PRESCALER     => X"28", -- 2.5 MHz (Int. clock over 100 MHz)
      DELAY_COUNTER => X"15"  -- 210 ns + 10 ns
    )
    port map(
      clk        => clk,
      reset      => btn_reset_D,
      cs         => cs_SPImaster_out,
      sclk       => sclk_SPImaster_out,
      mosi       => mosi_SPImaster_out,
      miso       => miso_SPImaster_out,
      read_data  => btn_read_D,
      xaxis_data => xaxis_data_SPImaster_out,
      yaxis_data => yaxis_data_SPImaster_out,
      zaxis_data => zaxis_data_SPImaster_out
    );

  SPIconverter_1 : entity work.SPIconverter port map (
    clk            => clk,
    reset          => btn_reset_D,
    xaxis_data_in  => xaxis_data_SPImaster_out,
    yaxis_data_in  => yaxis_data_SPImaster_out,
    zaxis_data_in  => zaxis_data_SPImaster_out,
    xaxis_data_out => xaxis_data_output,
    yaxis_data_out => yaxis_data_output,
    zaxis_data_out => zaxis_data_output
    );

  PmodACL_1 : entity work.PmodACL port map(
    clk  => clk,
    cs   => cs_SPImaster_out,
    sclk => sclk_SPImaster_out,
    mosi => mosi_SPImaster_out,
    miso => miso_SPImaster_out
    );
end behavioral;
