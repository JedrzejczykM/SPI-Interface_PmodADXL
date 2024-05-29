-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Wiktor Chocianowicz
-- ----------------------------------------------------------------------------------------
-- Create Date:    13/01/2024
-- Module Name:    debouncer
-- Target Devices: Any
-- Description:    Debounce and switch a monostable button.
-- ----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity debouncer is
  generic (
    DEBOUNCER_CNT_LIMIT : INTEGER := 250);
  port (
    i_clk       : in STD_LOGIC;
    i_button    : in STD_LOGIC;
    o_debouncer : out STD_LOGIC
  );
end debouncer;

architecture behavioural of debouncer is
  signal r_cnt        : INTEGER range 0 to DEBOUNCER_CNT_LIMIT := 0;
  signal r_button     : STD_LOGIC                              := '0';
  signal r_count_flag : STD_LOGIC                              := '0';
  signal r_debouncer  : STD_LOGIC                              := '0';
begin

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_button /= r_button) then
        r_count_flag <= '1';
      end if;
      if (r_count_flag = '1' and r_cnt < DEBOUNCER_CNT_LIMIT) then
        r_cnt <= r_cnt + 1;
      elsif (r_count_flag = '1' and r_cnt >= DEBOUNCER_CNT_LIMIT and i_button = '1') then
        r_count_flag <= '0';
        r_cnt        <= 0;
        r_debouncer  <= not r_debouncer;
      elsif (r_count_flag = '1' and r_cnt >= DEBOUNCER_CNT_LIMIT and i_button = '0') then
        r_count_flag <= '0';
        r_cnt        <= 0;
      end if;
      r_button <= i_button;

    end if;
  end process;

  o_debouncer <= r_debouncer;

end behavioural; -- behavioural
