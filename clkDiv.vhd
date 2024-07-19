
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity clkDiv is

Port ( clkin : in STD_LOGIC;
       clkout : out std_logic);

end clkDiv;

architecture Behavioral of clkDiv is

signal CNT: unsigned (26 downto 0);

begin

   process(clkin)
    begin
        if rising_edge(clkin) then
                CNT <= CNT+1;
        end if;
    
    end process;
    clkout <= std_logic(CNT(26));


end Behavioral;
