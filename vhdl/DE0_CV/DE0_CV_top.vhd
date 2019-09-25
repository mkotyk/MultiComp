library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.all;

entity DE0_CV_top is
    port (
             CLOCK1_50MHZ        : in    std_logic;
             CLOCK2_50MHZ        : in    std_logic;
             CLOCK3_50MHZ        : in    std_logic;
             CLOCK4_50MHZ        : in    std_logic;

             DRAM_ADDR           : out   std_logic_vector(12 downto 0);
             DRAM_BA             : out   std_logic_vector(1 downto 0);
             DRAM_CAS_N          : out   std_logic;
             DRAM_CKE            : out   std_logic;
             DRAM_CLK            : out   std_logic;
             DRAM_CS_N           : out   std_logic;
             DRAM_DQ             : inout std_logic_vector(15 downto 0);
             DRAM_LDQM           : out   std_logic;
             DRAM_RAS_N          : out   std_logic;
             DRAM_UDQM           : out   std_logic;
             DRAM_WE_N           : out   std_logic;

             GPIO_0              : inout std_logic_vector(35 downto 0);
             GPIO_1              : inout std_logic_vector(35 downto 0);

             HEX0                : out   std_logic_vector(6 downto 0);
             HEX1                : out   std_logic_vector(6 downto 0);
             HEX2                : out   std_logic_vector(6 downto 0);
             HEX3                : out   std_logic_vector(6 downto 0);
             HEX4                : out   std_logic_vector(6 downto 0);
             HEX5                : out   std_logic_vector(6 downto 0);

             KEY                 : in    std_logic_vector(3 downto 0);

             LEDR                : out   std_logic_vector(9 downto 0);

             SW                  : in    std_logic_vector(9 downto 0);

             PS2_CLK             : inout std_logic;
             PS2_DAT             : inout std_logic;

             PS2_CLK2            : inout std_logic;
             PS2_DAT2            : inout std_logic;

             RESET_N             : in    std_logic;

             SD_CLK              : out   std_logic;
             SD_CMD              : inout std_logic;
             SD_DATA             : inout std_logic_vector(3 downto 0);

             VGA_R               : out   std_logic_vector(3 downto 0);
             VGA_G               : out   std_logic_vector(3 downto 0);
             VGA_B               : out   std_logic_vector(3 downto 0);
             VGA_HS              : out   std_logic;
             VGA_VS              : out   std_logic
         );
end DE0_CV_top;

architecture struct of DE0_CV_top is
   signal n_WR                     : std_logic;
   signal n_RD                     : std_logic;
   signal cpuAddress               : std_logic_vector(15 downto 0);
   signal cpuDataOut               : std_logic_vector(7 downto 0);
   signal cpuDataIn                : std_logic_vector(7 downto 0);

   signal basRomData               : std_logic_vector(7 downto 0);
   signal internalRam1DataOut      : std_logic_vector(7 downto 0);
   signal internalRam2DataOut      : std_logic_vector(7 downto 0);
   signal interface1DataOut        : std_logic_vector(7 downto 0);
   signal interface2DataOut        : std_logic_vector(7 downto 0);
   signal sdCardDataOut            : std_logic_vector(7 downto 0);

   signal n_memWR                  : std_logic :='1';
   signal n_memRD                  : std_logic :='1';

   signal n_ioWR                   : std_logic :='1';
   signal n_ioRD                   : std_logic :='1';

   signal n_MREQ                   : std_logic :='1';
   signal n_IORQ                   : std_logic :='1';

   signal n_int1                   : std_logic :='1';
   signal n_int2                   : std_logic :='1';

   signal n_externalRamCS          : std_logic :='1';
   signal n_internalRam1CS         : std_logic :='1';
   signal n_internalRam2CS         : std_logic :='1';
   signal n_basRomCS               : std_logic :='1';
   signal n_interface1CS           : std_logic :='1';
   signal n_interface2CS           : std_logic :='1';
   signal n_sdCardCS               : std_logic :='1';

   signal clk                      : std_logic;
   signal serialClkCount           : std_logic_vector(15 downto 0);
   signal clkSpeed                 : integer;
   signal clkDuty                  : integer;
   signal cpuClkCount              : std_logic_vector(31 downto 0);
   signal sdClkCount               : std_logic_vector(5 downto 0);
   signal cpuClock                 : std_logic;
   signal serialClock              : std_logic;
   signal sdClock                  : std_logic;

   signal rxd1                     : std_logic;
   signal txd1                     : std_logic;
   signal rts1                     : std_logic;
begin


-- ____________________________________________________________________________________
-- CPU CHOICE GOES HERE
    cpu1 : entity work.t80s
    generic map(
                   mode => 1,
                   t2write => 1,
                   iowait => 0
               )
    port map(
                reset_n => RESET_N,
                clk_n => cpuClock,
                wait_n => '1',
                int_n => '1',
                nmi_n => '1',
                busrq_n => '1',
                mreq_n => n_MREQ,
                iorq_n => n_IORQ,
                rd_n => n_RD,
                wr_n => n_WR,
                a => cpuAddress,
                di => cpuDataIn,
                do => cpuDataOut
            );

-- ____________________________________________________________________________________
-- ROM GOES HERE
    rom1 : entity work.Z80_BASIC_ROM -- 8KB BASIC
    port map(
        address => cpuAddress(12 downto 0),
        clock => clk,
        q => basRomData
    );
-- ____________________________________________________________________________________
-- RAM GOES HERE
    ram1: entity work.InternalRam4K
    port map
    (
        address => cpuAddress(11 downto 0),
        clock => clk,
        data => cpuDataOut,
        wren => not(n_memWR or n_internalRam1CS),
        q => internalRam1DataOut
    );

-- ____________________________________________________________________________________
-- INPUT/OUTPUT DEVICES GO HERE
    VGA_R(0) <= '0';
    VGA_R(1) <= '0';
    VGA_G(0) <= '0';
    VGA_G(0) <= '0';
    VGA_B(1) <= '0';
    VGA_B(1) <= '0';

    io1 : entity work.SBCTextDisplayRGB
    port map (
                 n_reset => RESET_N,
                 clk => clk,

    -- RGB video signals
                 hSync => VGA_HS,
                 vSync => VGA_VS,
                 videoR0 => VGA_R(2),
                 videoR1 => VGA_R(3),
                 videoG0 => VGA_G(2),
                 videoG1 => VGA_G(3),
                 videoB0 => VGA_B(2),
                 videoB1 => VGA_B(3),

    -- Monochrome video signals (when using TV timings only)
                 sync => GPIO_0(10),
                 video => GPIO_0(11),

                 n_wr => n_interface1CS or n_ioWR,
                 n_rd => n_interface1CS or n_ioRD,
                 n_int => n_int1,
                 regSel => cpuAddress(0),
                 dataIn => cpuDataOut,
                 dataOut => interface1DataOut,
                 ps2Clk => PS2_CLK,
                 ps2Data => PS2_DAT
             );

    --rxd1 <= not GPIO_0(0);
    --rts1 <= GPIO_0(2);

    --io1 : entity work.bufferedUART
    --port map(
                --clk => clk,
                --n_wr => n_interface1CS or n_ioWR,
                --n_rd => n_interface1CS or n_ioRD,
                --n_int => n_int1,
                --regSel => cpuAddress(0),
                --dataIn => cpuDataOut,
                --dataOut => interface1DataOut,
                --rxClock => serialClock,
                --txClock => serialClock,
                --rxd => rxd1,
                --txd => txd1,
                --n_cts => '0',
                --n_dcd => '0',
                --n_rts => GPIO_0(2)
            --);
    --GPIO_0(1) <= not txd1;

    LEDR(0) <= not RESET_N;
    LEDR(1) <= not n_WR;
    LEDR(2) <= not n_RD;
    LEDR(3) <= not n_IORQ;
    LEDR(4) <= not n_MREQ;

    hex_display_5 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuAddress(15 downto 12)),
        output => HEX5
    );

    hex_display_4 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuAddress(11 downto 8)),
        output => HEX4
    );

    hex_display_3 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuAddress(7 downto 4)),
        output => HEX3
    );

    hex_display_2 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuAddress(3 downto 0)),
        output => HEX2
    );

    hex_display_1 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuDataIn(7 downto 4)),
        output => HEX1
    );

    hex_display_0 : entity work.hex_decoder
    port map(
        nibble => unsigned(cpuDataIn(3 downto 0)),
        output => HEX0
    );

-- ____________________________________________________________________________________
-- MEMORY READ/WRITE LOGIC GOES HERE
    n_ioWR <= n_WR or n_IORQ;
    n_memWR <= n_WR or n_MREQ;
    n_ioRD <= n_RD or n_IORQ;
    n_memRD <= n_RD or n_MREQ;

-- ____________________________________________________________________________________
-- CHIP SELECTS GO HERE

    n_basRomCS <= '0' when cpuAddress(15 downto 13) = "000" else '1'; --8K at bottom of memory
    n_interface1CS <= '0' when cpuAddress(7 downto 1) = "1000000" and (n_ioWR='0' or n_ioRD = '0') else '1'; -- 2 Bytes $80-$81
    n_interface2CS <= '0' when cpuAddress(7 downto 1) = "1000001" and (n_ioWR='0' or n_ioRD = '0') else '1'; -- 2 Bytes $82-$83
    n_sdCardCS <= '0' when cpuAddress(7 downto 3) = "10001" and (n_ioWR='0' or n_ioRD = '0') else '1'; -- 8 Bytes $88-$8
    n_internalRam1CS <= '0' when cpuAddress(15 downto 12) = "0010" else '1';

-- ____________________________________________________________________________________
-- BUS ISOLATION GOES HERE


    cpuDataIn <=
        interface1DataOut when n_interface1CS = '0' else
        interface2DataOut when n_interface2CS = '0' else
        sdCardDataOut when n_sdCardCS = '0' else
        basRomData when n_basRomCS = '0' else
        internalRam1DataOut when n_internalRam1CS= '0' else
        --sramData when n_externalRamCS= '0' else
        x"FF";

-- ____________________________________________________________________________________
-- SYSTEM CLOCKS GO HERE

    -- SUB-CIRCUIT CLOCK SIGNALS
    clk <= CLOCK1_50MHZ;

    clkSpeed <= 4 when SW(0) = '0' else 4000000;
    clkDuty  <= 2 when SW(0) = '0' else 2000000;

    serialClock <= serialClkCount(15);
    process (clk)
    begin
        if rising_edge(clk) then

            if cpuClkCount < clkSpeed then -- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
                cpuClkCount <= cpuClkCount + 1;
            else
                cpuClkCount <= (others=>'0');
            end if;
            if cpuClkCount < clkDuty then -- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
                cpuClock <= '0';
            else
                cpuClock <= '1';
            end if;

            if sdClkCount < 49 then -- 1MHz
                sdClkCount <= sdClkCount + 1;
            else
                sdClkCount <= (others=>'0');
            end if;
            if sdClkCount < 25 then
                sdClock <= '0';
            else
                sdClock <= '1';
            end if;

            -- Serial clock DDS
            -- 50MHz master input clock:
            -- Baud Increment
            -- 115200 2416
            -- 38400 805
            -- 19200 403
            -- 9600 201
            -- 4800 101
            -- 2400 50
            serialClkCount <= serialClkCount + 50;
        end if;
    end process;

end;

