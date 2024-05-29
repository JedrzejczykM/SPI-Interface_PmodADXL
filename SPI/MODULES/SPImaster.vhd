-- ----------------------------------------------------------------------------------------
-- University: Warsaw University of Technology
-- Author:     Wiktor Chocianowicz
-- ----------------------------------------------------------------------------------------
-- Create Date:    23/04/2024
-- Module Name:    SPImaster
-- Target Devices: CMOD C7
-- Description:    SPI interface and master implementation.
-- ----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity SPImaster is
  generic (
    PRESCALER     : STD_LOGIC_VECTOR(7 downto 0) := X"28"; -- 2.5 MHz (Int. clock over 100 MHz)
    DELAY_COUNTER : STD_LOGIC_VECTOR(7 downto 0) := X"15"  -- 210 ns + 10 ns
  );
  port (
    -- SPI signals
    clk        : in STD_LOGIC;                                        -- Clock signal
    reset      : in STD_LOGIC;                                        -- Reset signal
    cs         : out STD_LOGIC := '1';                                -- Chip select signal
    sclk       : out STD_LOGIC := '1';                                -- Serial clock signal
    mosi       : out STD_LOGIC := '0';                                -- Master Out Slave In signal
    miso       : in STD_LOGIC;                                        -- Master In Slave Out signal
    read_data  : in STD_LOGIC;                                        -- Start reading data from adxl
    xaxis_data : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0'); -- X axis data
    yaxis_data : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0'); -- Y axis data
    zaxis_data : out STD_LOGIC_VECTOR(9 downto 0) := (others => '0')  -- Z axis data
  );
end SPImaster;

architecture Behavioral of SPImaster is
  constant NR_OF_EDGES : STD_LOGIC_VECTOR(7 downto 0) := X"10"; -- 16 edges, 8 cycles

  constant DATAX0 : STD_LOGIC_VECTOR (15 downto 0) := X"B200"; --10110010  \
  constant DATAX1 : STD_LOGIC_VECTOR (15 downto 0) := X"B300"; --10110011  |
  constant DATAY0 : STD_LOGIC_VECTOR (15 downto 0) := X"B400"; --10110100  |> read only registers
  constant DATAY1 : STD_LOGIC_VECTOR (15 downto 0) := X"B500"; --10110101  |
  constant DATAZ0 : STD_LOGIC_VECTOR (15 downto 0) := X"B600"; --10110110  |
  constant DATAZ1 : STD_LOGIC_VECTOR (15 downto 0) := X"B700"; --10110111  /
  -- constant DATAW  : STD_LOGIC_VECTOR (15 downto 0) := X"2A91"; --00101010 10010001

  type WRITE_Data_TypeDef is (idle, writing);
  signal WRITE_STATE : WRITE_Data_TypeDef;

  type READ_Data_TypeDef is (idle, reading, waiting);
  signal READ_STATE : READ_Data_TypeDef;

  type SCLK_Gen_TypeDef is (idle, running);
  signal SCLK_STATE : SCLK_Gen_TypeDef;

  type TRANSMIT_TypeDef is (idle, transmitting);
  signal TRANSMIT_STATE : TRANSMIT_TypeDef;

  type RECEIVE_TypeDef is (idle, receiving);
  signal RECEIVE_STATE : RECEIVE_TypeDef;

  signal DATA_CYCLE : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

  signal r_sclk         : STD_LOGIC                    := '1';
  signal r_sclk_prev    : STD_LOGIC                    := '1';
  signal r_sclk_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

  signal r_delay_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

  signal r_transmit : STD_LOGIC := '0';

  signal r_transmit_done : STD_LOGIC := '0';
  signal r_read_done     : STD_LOGIC := '0';
  signal r_can_copy_data : STD_LOGIC := '0';

  signal r_falling_edge_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal r_rising_edge_counter  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

  signal r_transmit_buffer : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
  signal transmit_buffer   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
  signal receive_buffer    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

begin
  -- Read data process
  read_acl_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        cs         <= '1';
        READ_STATE <= idle;
      else
        case READ_STATE is
          when idle =>
            if read_data = '1' then
              READ_STATE <= reading;
            end if;
            cs <= '1';

            case DATA_CYCLE is
              when X"0" =>
                r_transmit_buffer <= DATAX0;

              when X"1" =>
                r_transmit_buffer <= DATAX1;

              when X"2" =>
                r_transmit_buffer <= DATAY0;

              when X"3" =>
                r_transmit_buffer <= DATAY1;

              when X"4" =>
                r_transmit_buffer <= DATAZ0;

              when X"5" =>
                r_transmit_buffer <= DATAZ1;

              when others =>
                r_transmit_buffer <= DATAX0;
            end case;

          when reading =>
            if r_delay_counter = DELAY_COUNTER then
              cs              <= '0';
              READ_STATE      <= waiting;
              r_delay_counter <= (others => '0');
            else
              r_delay_counter <= r_delay_counter + '1';
            end if;

          when waiting =>
            if r_transmit_done = '1' and r_read_done = '1' then
              READ_STATE <= idle;
              if DATA_CYCLE = X"5" then
                DATA_CYCLE <= (others => '0');
              else
                DATA_CYCLE <= DATA_CYCLE + '1';
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Clock generation process
  sclk_gen_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset values
        r_sclk         <= '1';
        r_sclk_prev    <= '1';
        r_sclk_counter <= (others => '0');
      else
        case SCLK_STATE is
          when idle =>
            -- Go to running state when
            if cs = '0' then
              SCLK_STATE <= running;
            end if;

            -- What to do in idle state
            r_sclk         <= '1';
            r_sclk_prev    <= '1';
            r_sclk_counter <= (others => '0');

          when running =>
            -- Back to idle state when
            if cs = '1' then
              SCLK_STATE <= idle;
            end if;

            -- What to do in running state
            if r_sclk_counter = PRESCALER then
              r_sclk         <= not r_sclk;
              r_sclk_counter <= (others => '0');
            else
              r_sclk_counter <= r_sclk_counter + '1';
            end if;
        end case;
        r_sclk_prev <= r_sclk;
      end if;
    end if;
  end process;

  sclk <= r_sclk;

  -- Transmit process
  -- falling edge sclk
  transmit_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset values
        mosi                   <= '0';
        r_transmit_done        <= '0';
        transmit_buffer        <= (others => '0');
        r_falling_edge_counter <= (others => '0');
        TRANSMIT_STATE         <= idle;
      else
        case TRANSMIT_STATE is
          when idle =>
            -- Go to transmitting state when
            if cs = '0' then
              TRANSMIT_STATE  <= transmitting;
              transmit_buffer <= r_transmit_buffer;
            end if;

            -- What to do in idle state
            mosi                   <= '0';
            r_falling_edge_counter <= (others => '0');
            r_transmit_done        <= '0';

          when transmitting =>
            -- Back to idle state when
            if cs = '1' then
              TRANSMIT_STATE <= idle;
            end if;

            -- What to do in transmitting state
            if r_sclk_prev = '1' and r_sclk = '0' and r_falling_edge_counter < NR_OF_EDGES then
              mosi                   <= transmit_buffer(15);
              transmit_buffer        <= transmit_buffer(14 downto 0) & '0';
              r_falling_edge_counter <= r_falling_edge_counter + '1';
            elsif r_falling_edge_counter = NR_OF_EDGES then
              r_transmit_done <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Receive process
  -- rising edge sclk
  receive_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset values
        r_read_done           <= '0';
        receive_buffer        <= (others => '0');
        r_rising_edge_counter <= (others => '0');
        xaxis_data            <= (others => '0');
        yaxis_data            <= (others => '0');
        zaxis_data            <= (others => '0');
        RECEIVE_STATE         <= idle;
      else
        case RECEIVE_STATE is
          when idle =>
            -- Go to receiving state when
            if cs = '0' then
              RECEIVE_STATE <= receiving;
            end if;

            -- What to do in idle state
            receive_buffer        <= (others => '0');
            r_rising_edge_counter <= (others => '0');
            r_read_done           <= '0';
            r_can_copy_data       <= '0';

          when receiving =>
            -- Back to idle state when
            if cs = '1' then
              RECEIVE_STATE <= idle;
            end if;

            -- What to do in receiving state
            if r_sclk_prev = '0' and r_sclk = '1' and r_rising_edge_counter <= X"7" then
              r_rising_edge_counter                                           <= r_rising_edge_counter + '1';
            elsif r_sclk_prev = '0' and r_sclk = '1' and r_rising_edge_counter > X"7" then
              receive_buffer        <= receive_buffer(14 downto 0) & miso;
              r_rising_edge_counter <= r_rising_edge_counter + '1';
            elsif r_rising_edge_counter = NR_OF_EDGES then
              r_read_done <= '1';

              case DATA_CYCLE is
                when X"0" =>
                  if r_can_copy_data = '0' then
                    xaxis_data(7 downto 0) <= receive_buffer(7 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when X"1" =>
                  if r_can_copy_data = '0' then
                    xaxis_data(9 downto 8) <= receive_buffer(1 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when X"2" =>
                  if r_can_copy_data = '0' then
                    yaxis_data(7 downto 0) <= receive_buffer(7 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when X"3" =>
                  if r_can_copy_data = '0' then
                    yaxis_data(9 downto 8) <= receive_buffer(1 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when X"4" =>
                  if r_can_copy_data = '0' then
                    zaxis_data(7 downto 0) <= receive_buffer(7 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when X"5" =>
                  if r_can_copy_data = '0' then
                    zaxis_data(9 downto 8) <= receive_buffer(1 downto 0);
                  end if;
                  r_can_copy_data <= '1';

                when others                =>
                  xaxis_data      <= (others => '0');
                  yaxis_data      <= (others => '0');
                  zaxis_data      <= (others => '0');
                  r_can_copy_data <= '1';

              end case;
            end if;
        end case;
      end if;
    end if;
  end process;
end Behavioral;
