library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_filter is
    port (
        clk        : in std_logic;
        rst        : in std_logic;
        pixel_in   : in std_logic_vector(7 downto 0);
        valid_in   : in std_logic;
        pixel_out  : out std_logic_vector(7 downto 0);
        valid_out  : out std_logic
    );
end entity;

architecture rtl of sobel_filter is
	constant IMG_WIDTH : integer := 320;

    type line_buf_t is array(0 to IMG_WIDTH - 1) of std_logic_vector(7 downto 0);
    signal line0, line1, line2 : line_buf_t := (others => (others => '0'));

    signal write_col : integer range 0 to IMG_WIDTH-1 := 0;

    signal r0c0, r0c1, r0c2 : std_logic_vector(7 downto 0);
    signal r1c0, r1c1, r1c2 : std_logic_vector(7 downto 0);
    signal r2c0, r2c1, r2c2 : std_logic_vector(7 downto 0);

    signal valid_delay : std_logic_vector(2 downto 0) := (others => '0');
begin

    process(clk)
        variable x0, x1, x2 : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                write_col <= 0;
                valid_delay <= (others => '0');
            elsif valid_in = '1' then
                -- Shift line buffers
                line0(write_col) <= line1(write_col);
                line1(write_col) <= line2(write_col);
                line2(write_col) <= pixel_in;

                -- Update column position
                if write_col = IMG_WIDTH - 1 then
                    write_col <= 0;
                else
                    write_col <= write_col + 1;
                end if;

                -- Compute wrap-around indices
                x0 := (write_col + IMG_WIDTH - 2) mod IMG_WIDTH;
                x1 := (write_col + IMG_WIDTH - 1) mod IMG_WIDTH;
                x2 := write_col;

                -- Extract 3x3 window
                r0c0 <= line0(x0); r0c1 <= line0(x1); r0c2 <= line0(x2);
                r1c0 <= line1(x0); r1c1 <= line1(x1); r1c2 <= line1(x2);
                r2c0 <= line2(x0); r2c1 <= line2(x1); r2c2 <= line2(x2);

                -- Shift valid pipeline
                valid_delay <= valid_delay(1 downto 0) & '1';
            else
                valid_delay <= valid_delay(1 downto 0) & '0';
            end if;
        end if;
    end process;

    process(clk)
        variable gx, gy, mag : integer;
        variable p0, p1, p2, p3, p4, p5, p6, p7, p8 : integer;
    begin
        if rising_edge(clk) then
            if valid_delay(2) = '1' then
                -- Convert window to integers
                p0 := to_integer(unsigned(r0c0));
                p1 := to_integer(unsigned(r0c1));
                p2 := to_integer(unsigned(r0c2));
                p3 := to_integer(unsigned(r1c0));
                p4 := to_integer(unsigned(r1c1));
                p5 := to_integer(unsigned(r1c2));
                p6 := to_integer(unsigned(r2c0));
                p7 := to_integer(unsigned(r2c1));
                p8 := to_integer(unsigned(r2c2));

                -- Apply Sobel kernels
                gx := -p0 + p2 - 2*p3 + 2*p5 - p6 + p8;
                gy :=  p0 + 2*p1 + p2 - p6 - 2*p7 - p8;

                mag := abs(gx) + abs(gy);
                if mag > 255 then
                    pixel_out <= x"FF";
                else
                    pixel_out <= std_logic_vector(to_unsigned(mag, 8));
                end if;

                valid_out <= '1';
            else
                pixel_out <= (others => '0');
                valid_out <= '0';
            end if;
        end if;
    end process;

end architecture;
