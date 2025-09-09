library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        pixel_data  : in std_logic_vector(7 downto 0);
        pixel_en    : in std_logic;
        hsync, vsync : out std_logic;
        red, green, blue : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of vga_controller is
    constant H_VISIBLE   : integer := 640;
    constant H_FRONT     : integer := 16;
    constant H_SYNC      : integer := 96;
    constant H_BACK      : integer := 48;
    constant H_TOTAL     : integer := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    constant V_VISIBLE   : integer := 480;
    constant V_FRONT     : integer := 10;
    constant V_SYNC      : integer := 2;
    constant V_BACK      : integer := 33;
    constant V_TOTAL     : integer := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    signal h_count : integer range 0 to H_TOTAL-1 := 0;
    signal v_count : integer range 0 to V_TOTAL-1 := 0;

    signal active_video : std_logic;
    signal pixel : std_logic_vector(7 downto 0) := (others => '0');

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if h_count = H_TOTAL - 1 then
                h_count <= 0;
                if v_count = V_TOTAL - 1 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    hsync <= '0' when (h_count >= H_VISIBLE + H_FRONT and h_count < H_VISIBLE + H_FRONT + H_SYNC) else '1';
    vsync <= '0' when (v_count >= V_VISIBLE + V_FRONT and v_count < V_VISIBLE + V_FRONT + V_SYNC) else '1';

    active_video <= '1' when (h_count < H_VISIBLE and v_count < V_VISIBLE) else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if pixel_en = '1' then
                pixel <= pixel_data;
            end if;

            if active_video = '1' and
               h_count >= 160 and h_count < 480 and
               v_count >= 120 and v_count < 360 then
                red   <= pixel(7 downto 4);
                green <= pixel(7 downto 4);
                blue  <= pixel(7 downto 4);
            else
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            end if;
        end if;
    end process;
end architecture;
