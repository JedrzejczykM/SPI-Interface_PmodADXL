-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Michał Jędrzejczyk
-- ----------------------------------------------------------------------------------------
-- Create Date:    24/04/2024
-- Module Name:    PmodACL
-- Target Devices: CMOD C7
-- Description:    PmodACL emulator.
-- ----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity PmodACL is
  port (
    clk  : in STD_LOGIC;        -- Emulator clock signal 100MHz
    cs   : in STD_LOGIC;        -- Chip select signal
    sclk : in STD_LOGIC;        -- Serial clock signal 2,5MHz
    mosi : in STD_LOGIC;        -- Master Out Slave In signal
    miso : out STD_LOGIC := '0' -- Master In Slave Out signal
  );
end PmodACL;

architecture Behavioral of PmodACL is
  constant DATAX0 : STD_LOGIC_VECTOR (7 downto 0) := X"B2"; --10110010  \
  constant DATAX1 : STD_LOGIC_VECTOR (7 downto 0) := X"B3"; --10110011  |
  constant DATAY0 : STD_LOGIC_VECTOR (7 downto 0) := X"B4"; --10110100  |> read only registers
  constant DATAY1 : STD_LOGIC_VECTOR (7 downto 0) := X"B5"; --10110101  |
  constant DATAZ0 : STD_LOGIC_VECTOR (7 downto 0) := X"B6"; --10110110  |
  constant DATAZ1 : STD_LOGIC_VECTOR (7 downto 0) := X"B7"; --10110111  /

  constant TO_BE_SENT_DATAX0 : STD_LOGIC_VECTOR (7 downto 0) := X"DC"; --  \
  constant TO_BE_SENT_DATAX1 : STD_LOGIC_VECTOR (7 downto 0) := X"00"; --  |
  constant TO_BE_SENT_DATAY0 : STD_LOGIC_VECTOR (7 downto 0) := X"DC"; --  |> examle data to be sent
  constant TO_BE_SENT_DATAY1 : STD_LOGIC_VECTOR (7 downto 0) := X"02"; --  |
  constant TO_BE_SENT_DATAZ0 : STD_LOGIC_VECTOR (7 downto 0) := X"08"; --  |
  constant TO_BE_SENT_DATAZ1 : STD_LOGIC_VECTOR (7 downto 0) := X"00"; --  /

  signal r_miso          : STD_LOGIC := '0'; -- miso output signal
  signal r_can_copy_data : STD_LOGIC := '0';

  signal r_sclk      : STD_LOGIC := '1';
  signal r_sclk_prev : STD_LOGIC := '1';

  signal r_rising_edge_counter : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- rising edge counter

  signal transmit_buffer : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- transmit buffer

  signal recieve_buffer : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- recieve buffer

  signal status : STD_LOGIC_VECTOR(1 downto 0) := (others => '0'); -- status signal - 10 succed, 01 error

  type STATE_Data_TypeDef is (idle, transmitting, receiving); -- machine States
  signal STATE : STATE_Data_TypeDef;

begin
  -- Send data process
  process (clk)
  begin
    if rising_edge(clk) then
      r_sclk <= sclk;

      case STATE is
        when idle =>
          -- Go to receiving state when
          if cs = '0' then
            STATE <= receiving;
          end if;

          -- What to do in idle state
          recieve_buffer  <= (others => '0');
          miso            <= '0';
          r_can_copy_data <= '0';
          status <= "00";

        when receiving =>
          -- Back to idle state when
          if cs = '1' then
            STATE <= idle;
          end if;

          -- What to do in receiving state
          if r_sclk = '0' and sclk = '1' and r_rising_edge_counter <= 7 then
            recieve_buffer                                           <= recieve_buffer(6 downto 0) & mosi;
            r_rising_edge_counter                                    <= r_rising_edge_counter + '1';

            -- Go to transmitting state when
          elsif r_rising_edge_counter > 7 then
            r_rising_edge_counter <= "0000";
            STATE                 <= transmitting;
          end if;

        when transmitting =>
          -- Back to idle state when
          if cs = '1' then
            STATE <= idle;

            -- What to do in transmitting state
          else
            case recieve_buffer is
              when DATAX0 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAX0;
                end if;
                r_can_copy_data <= '1';

              when DATAX1 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAX1;
                end if;
                r_can_copy_data <= '1';

              when DATAY0 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAY0;
                end if;
                r_can_copy_data <= '1';

              when DATAY1 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAY1;
                end if;
                r_can_copy_data <= '1';

              when DATAZ0 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAZ0;
                end if;
                r_can_copy_data <= '1';

              when DATAZ1 =>
                if r_can_copy_data = '0' then
                  transmit_buffer <= TO_BE_SENT_DATAZ1;
                end if;
                r_can_copy_data <= '1';

              when others =>
                status          <= "01";
                r_can_copy_data <= '1';
            end case;
            if r_sclk = '1' and sclk = '0' then
              miso            <= transmit_buffer(7);
              transmit_buffer <= transmit_buffer(6 downto 0) & '0';
              if transmit_buffer = X"0" then
                status <= "10";
              end if;
            end if;
          end if;
        when others =>
          status <= "01";
      end case;
    end if;
  end process;

end Behavioral;
