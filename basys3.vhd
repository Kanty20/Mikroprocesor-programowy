

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity basys3 is
    Port ( clk : in STD_LOGIC;
           btnC : in STD_LOGIC;
           led : out STD_LOGIC_VECTOR (7 downto 0));
end basys3;

architecture Behavioral of basys3 is

component procesor is
    Port ( Z : in STD_LOGIC;
           INT : in STD_LOGIC;
           IOIN: in STD_LOGIC_VECTOR (7 downto 0);
           CLK : in STD_LOGIC;
           RESET : in STD_LOGIC;
           IOADR : out STD_LOGIC_VECTOR (7 downto 0);
           IOOUT : out STD_LOGIC_VECTOR (7 downto 0);
           IOWR : out STD_LOGIC;
           IORD : out STD_LOGIC;
           GPIO : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component clkDiv is

Port ( clkin : in STD_LOGIC;
       clkout : out std_logic);

end component;

signal net: std_logic;

begin

    C1: clkDiv port map (clkin=>clk, clkout=>net);
    P1: procesor port map (CLK=>net, RESET=>btnC, IOOUT=>led, Z=>'0', INT=>'0', IOIN=>x"00",IOADR=>open, IOWR=>open, IORD=>open, GPIO=>open);

end Behavioral;
