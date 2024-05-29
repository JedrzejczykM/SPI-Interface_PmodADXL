-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Michał Jędrzejczyk
-- ----------------------------------------------------------------------------------------
-- Create Date:    29/04/2024
-- Module Name:    SPIconverter
-- Target Devices: CMOD C7
-- Description:    Data converter from LSB to mg.
-- ----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity SPIconverter is
  port (
    clk            : in STD_LOGIC;                                        -- Clock signal
    reset          : in STD_LOGIC;                                        -- Reset signal
    xaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);                     -- X axis data
    yaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);                     -- Y axis data
    zaxis_data_in  : in STD_LOGIC_VECTOR(9 downto 0);                     -- Z axis data
    xaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0'); -- X axis data
    yaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0'); -- Y axis data
    zaxis_data_out : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0')  -- Z axis data
  );
end SPIconverter;

architecture Behavioral of SPIconverter is
begin
  -- Convert data process
  convert_data_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        xaxis_data_out <= (others => '0');
        yaxis_data_out <= (others => '0');
        zaxis_data_out <= (others => '0');
      else
        -- If data is negative in U2, it is converted to positive number and
        -- the MSB is set to 1 for further conversion in ILA.
        if xaxis_data_in(9) = '1' then
          xaxis_data_out <= not xaxis_data_in(9 downto 0) + '1';
          xaxis_data_out(9) <= '1';
        else
          xaxis_data_out <= xaxis_data_in;
        end if;

        if yaxis_data_in(9) = '1' then
          yaxis_data_out <= not yaxis_data_in(9 downto 0) + '1';
          yaxis_data_out(9) <= '1';
        else
          yaxis_data_out <= yaxis_data_in;
        end if;

        if zaxis_data_in(9) = '1' then
          zaxis_data_out <= not zaxis_data_in(9 downto 0) + '1';
          zaxis_data_out(9) <= '1';
        else
          zaxis_data_out <= zaxis_data_in;
        end if;
      end if;
    end if;
  end process;
end Behavioral;
