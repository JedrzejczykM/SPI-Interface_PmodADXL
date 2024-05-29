-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Wiktor Chocianowicz
-- ----------------------------------------------------------------------------------------
-- Create Date:    23/03/2024
-- Module Name:    testbench
-- Target Devices: CMOD C7
-- Description:    Testbench for signal simulation.
-- ----------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.env.stop;

entity testbench is
end testbench;

architecture behavioural of testbench is
  signal clk       : STD_LOGIC := '0';
  signal btn_reset : STD_LOGIC := '0';
  signal btn_read  : STD_LOGIC := '0';

  signal xaxis_data : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
  signal yaxis_data : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
  signal zaxis_data : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');

  component top is
    port (
      clk               : in STD_LOGIC;                     -- clk
      btn_read          : in STD_LOGIC;                     -- start reading button
      btn_reset         : in STD_LOGIC;                     -- reset button
      xaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0); -- X axis data
      yaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0); -- Y axis data
      zaxis_data_output : out STD_LOGIC_VECTOR(9 downto 0)  -- Z axis data
    );
  end component top;
begin

  -- Clock
  clk <= not clk after 5 ns;

  dut : top port map(
    clk               => clk,
    btn_read          => btn_read,
    btn_reset         => btn_reset,
    xaxis_data_output => xaxis_data,
    yaxis_data_output => yaxis_data,
    zaxis_data_output => zaxis_data
  );

  stimulus :
  process begin
    wait for 20 ns;
    for i in 0 to 800 loop
      btn_read <= '0';
      wait for 500 ps;
      btn_read <= '1';
      wait for 500 ps;
    end loop;
    wait for 300 ns;
    btn_read <= '0';

    wait for 200 us;
    for i in 0 to 800 loop
      btn_reset <= '0';
      wait for 500 ps;
      btn_reset <= '1';
      wait for 500 ps;
    end loop;
    wait for 300 ns;
    btn_reset <= '0';

    wait for 50 us;
    for i in 0 to 800 loop
      btn_reset <= '0';
      wait for 500 ps;
      btn_reset <= '1';
      wait for 500 ps;
    end loop;
    wait for 300 ns;
    btn_reset <= '0';

    wait for 20 us;
    for i in 0 to 800 loop
      btn_read <= '0';
      wait for 500 ps;
      btn_read <= '1';
      wait for 500 ps;
    end loop;
    wait for 300 ns;
    btn_read <= '0';

    wait for 40 us;
    for i in 0 to 800 loop
      btn_read <= '0';
      wait for 500 ps;
      btn_read <= '1';
      wait for 500 ps;
    end loop;
    wait for 300 ns;
    btn_read <= '0';

    wait for 1 ms;
    stop;
  end process stimulus;
end behavioural; -- behavioural
