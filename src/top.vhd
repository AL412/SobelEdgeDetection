library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port (
        CLOCK_50 : in std_logic;
        RESET_N  : in std_logic;
        VGA_HS, VGA_VS : out std_logic;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of top is
    constant IMG_WIDTH  : integer := 320;
    constant IMG_HEIGHT : integer := 240;

    signal clk : std_logic;

    signal hcount, vcount : integer range 0 to 799 := 0;
    signal visible        : std_logic := '0';

    signal pixel_x, pixel_y : integer range 0 to IMG_WIDTH-1 := 0;
    signal rom_addr         : std_logic_vector(16 downto 0);
    signal rom_data         : std_logic_vector(7 downto 0);

    signal sobel_out   : std_logic_vector(7 downto 0);
    signal sobel_valid : std_logic;
begin

    clk <= CLOCK_50;

    -- ROM address calculation
    rom_addr <= std_logic_vector(to_unsigned(pixel_y * IMG_WIDTH + pixel_x, 17));

    -- Instantiate image ROM
    image_rom_inst : entity work.image_rom
        port map (
            address => rom_addr,
            clock   => clk,
            q       => rom_data
        );

    -- Instantiate Sobel Filter
    sobel_inst : entity work.sobel_filter
        port map (
            clk       => clk,
            rst       => not RESET_N,
            pixel_in  => rom_data,
            valid_in  => visible,
            pixel_out => sobel_out,
            valid_out => sobel_valid
        );

    -- VGA logic
    vga_proc : process(clk)
    begin
        if rising_edge(clk) then
            if hcount = 799 then
                hcount <= 0;
                if vcount = 524 then
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
                end if;
            else
                hcount <= hcount + 1;
            end if;

            visible <= '0';

            if hcount >= 160 and hcount < 480 and vcount >= 120 and vcount < 360 then
                visible <= '1';
                pixel_x <= hcount - 160;
                pixel_y <= vcount - 120;
            end if;

            -- VGA sync signals
            if hcount >= 656 and hcount < 752 then
                VGA_HS <= '0';
            else
                VGA_HS <= '1';
            end if;

            if vcount >= 490 and vcount < 492 then
                VGA_VS <= '0';
            else
                VGA_VS <= '1';
            end if;

            -- Output Sobel result if valid
            if sobel_valid = '1' then
                VGA_R <= sobel_out(7 downto 4);
                VGA_G <= sobel_out(7 downto 4);
                VGA_B <= sobel_out(7 downto 4);
            else
                VGA_R <= (others => '0');
                VGA_G <= (others => '0');
                VGA_B <= (others => '0');
            end if;
        end if;
    end process;

end architecture;
