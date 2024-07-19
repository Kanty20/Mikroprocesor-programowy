library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity procesor is
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
end procesor;

architecture Behavioral of procesor is

--kody instrukcji w formacie 0:od najstarszego 8bitow na instrukcje i 8bitow na argument
constant C_OUTP : std_logic_vector(7 downto 0) := x"01";
constant C_BZ : std_logic_vector(7 downto 0) := x"11";
constant C_NOP : std_logic_vector(7 downto 0) := x"00";
constant C_B : std_logic_vector(7 downto 0) := x"10";
constant C_BSET : std_logic_vector(7 downto 0) := x"02";
constant C_BCLR : std_logic_vector(7 downto 0) := x"03";
constant C_CALL : std_logic_vector(7 downto 0) := x"04";
constant C_RCALL : std_logic_vector(7 downto 0) := x"05";
constant C_RET : std_logic_vector(7 downto 0) := x"06";
constant C_RETI : std_logic_vector(7 downto 0) := x"07";

--kody instrukcji w formacie R: od najstarszego 10bitow na instrukcjê i 2x po 3bity na rejestry
constant C_MOV : std_logic_vector(9 downto 0) := "0100000001";
constant C_LD : std_logic_vector(9 downto 0) := "0100000010";
constant C_ST : std_logic_vector(9 downto 0) := "0100000100";
constant C_ADC : std_logic_vector(9 downto 0) := "0100000011";
constant C_SBC : std_logic_vector(9 downto 0) := "0100000111";
constant C_MUL : std_logic_vector(9 downto 0) := "0100001111";
constant C_MULS : std_logic_vector(9 downto 0) := "0100011111";
constant C_AND : std_logic_vector(9 downto 0) := "0100111111";
constant C_OR : std_logic_vector(9 downto 0) := "0101111111";
constant C_XOR : std_logic_vector(9 downto 0) := "0111111111";
constant C_CP : std_logic_vector(9 downto 0) := "0111001100";

--kody instrukcji w formacie I: od najstarszego 5bitow na instrukcjê , 3bity na rejestry i 8 bitow na stala
constant C_LDI : std_logic_vector(4 downto 0) := "10001";
constant C_LDS : std_logic_vector(4 downto 0) := "10010";
constant C_STS : std_logic_vector(4 downto 0) := "10100";
constant C_ADCI : std_logic_vector(4 downto 0) := "10011";
constant C_SBCI : std_logic_vector(4 downto 0) := "10101";
constant C_ANDI : std_logic_vector(4 downto 0) := "10111";
constant C_ORI : std_logic_vector(4 downto 0) := "10000";
constant C_XORI : std_logic_vector(4 downto 0) := "10110";

--kody instrukcji w formacie I2: to samo co kody I tylko zabrak³o mi adresów
constant C_BRBS : std_logic_vector(4 downto 0) := "11000";
constant C_BRBC : std_logic_vector(4 downto 0) := "11001";
constant C_CPI : std_logic_vector(4 downto 0) := "11010";
constant C_IOUTP : std_logic_vector(4 downto 0) := "11011";
constant C_INP : std_logic_vector(4 downto 0) := "11100";

--instrukcje ioutp i inp trwaja wiecej niz jeden cykl i potrzebuje masek
constant M_IOUTP : std_logic_vector(15 downto 0) := "11011-----------";
constant M_INP : std_logic_vector(15 downto 0) := "11100-----------";

--2 najstarsze bity okreslaja w jakim formacie zapisywana jest instrukcja
constant Format0 : std_logic_vector(1 downto 0) := "00";
constant FormatR : std_logic_vector(1 downto 0) := "01";
constant FormatI : std_logic_vector(1 downto 0) := "10";
constant FormatI2 : std_logic_vector(1 downto 0) := "11";

--w tablicy ROM umieszczam kolejne kody instrukcji ktore beda wykonywane w programie
type rom_t is array (0 to 31) of std_logic_vector(15 downto 0);
--constant ROM: rom_t := (C_OUTP & x"FF", C_OUTP & x"55", C_BZ & x"02", C_OUTP & x"00", C_NOP & x"00", C_B & x"00", others => x"0000");
--constant ROM: rom_t := ( C_BSET & x"FF", C_BCLR & x"55", C_LDI & "001" & x"35", C_LDI & "100" & x"79", C_MOV & "101" & "001",C_LDI & "001" & x"02", C_ST & "001" & "100", C_STS & "100" & x"05", C_LD & "110" & "001", C_LDS & "111" & x"05", C_B & x"00",others => x"0000");
--constant ROM: rom_t := (C_LDI & "001" & x"8e", C_LDI & "011" & x"c6", C_AND & "001" & "011", C_LDI & "001" & x"cc", C_LDI & "011" & x"59", C_MULS & "001" & "011", C_B & x"00", others => x"0000");
--constant ROM: rom_t := (C_BCLR & x"ff", C_LDI & "000" & x"02", C_MOV & "010" & "000", C_LDI & "001" & x"05", C_LDI & "100" & x"00", C_ADCI & "100" & x"01", C_CP & "100" & "001", C_BRBS & "001" & x"04", C_MUL & "010" & "000", C_MOV & "010" & "011",C_B & x"05", C_B & x"0b" ,others => x"0000");
--constant ROM: rom_t := (C_BSET &x"80", C_LDI & "001" & x"35", C_IOUTP & "001" & x"11", C_INP & "001" & x"22", C_LDI & "100" & x"79", C_RCALL & x"0d", C_MOV &"101" &"001", C_LDI &"001" &x"02",C_ST &"001" &"100",C_STS &"100" &x"05", C_LD &"110" &"001",C_LDS &"111" &x"05", C_LDI &"000" &x"05", C_ADC &"001" &"000",C_ADCI &"001" &x"11",C_LDI &"000" &x"81",C_ADCI &"000" &x"7f", C_B & x"00", C_LDI &"000" &x"f0", C_IOUTP &"000" &x"33", C_RET &x"00", C_IOUTP &"000" &x"55",C_RETI &x"00", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", C_B &x"15");
constant ROM: rom_t := (C_LDI & "000" & x"ff", C_IOUTP & "000" & x"11", C_NOP & x"00", C_LDI & "000" & x"00", C_IOUTP & "000" & x"11", C_NOP & x"00", C_LDI & "000" & x"88", C_IOUTP & "000" & x"11", C_NOP & x"00", C_LDI & "000" & x"11", C_IOUTP & "000" & x"11", C_NOP & x"00", C_B & x"00", others => x"0000");

--tablica ram symuluje pamiec danych mikrokontrolera
type ram_array is array (0 to 31) of std_logic_vector(7 downto 0);
signal RAM: ram_array:=(others => x"00");

--tablica R to rejestry robocze
type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
signal R: reg_array:=(others => x"00");

--tablica STACK to stos do odkladania ardesow skokow do podprogramow i przerwan
type stack_array is array (0 to 31) of unsigned(7 downto 0);
signal STACK: stack_array:=(others => x"00");

--SREG to rejestr statusowy
signal SREG: unsigned(7 downto 0):= x"00";
signal SREGM: unsigned(7 downto 0):= x"00";

--aliasy dla kolejnych flag status registera
alias SREG_C: std_logic is SREG(0);
alias SREG_Z: std_logic is SREG(1);
alias SREG_N: std_logic is SREG(2);
alias SREG_V: std_logic is SREG(3);
alias SREG_S: std_logic is SREG(4);
alias SREG_H: std_logic is SREG(5);
alias SREG_T: std_logic is SREG(6);
alias SREG_I: std_logic is SREG(7);

signal PC: unsigned(7 downto 0):= x"00"; --program counter to licznik rozkazow
signal IR: std_logic_vector(15 downto 0); --tu pobieram aktualnie wykonywana instrukcje
signal SPTR: unsigned(7 downto 0):= x"00"; --wskaznik stosu

alias FormatType: std_logic_vector(1 downto 0) is IR (15 downto 14);

alias OPCODE: std_logic_vector(7 downto 0) is IR(15 downto 8);
alias ARG: std_logic_vector(7 downto 0) is IR(7 downto 0);

alias RCode: std_logic_vector(9 downto 0) is IR(15 downto 6);
alias RRd: std_logic_vector(2 downto 0) is IR(5 downto 3);
alias RRs: std_logic_vector(2 downto 0) is IR(2 downto 0);

alias ICode: std_logic_vector(4 downto 0) is IR(15 downto 11);
alias IRd: std_logic_vector(2 downto 0) is IR(10 downto 8);
alias IK: std_logic_vector(7 downto 0) is IR(7 downto 0);

type stan is (S_FETCH, S_EX);
signal state: stan;

begin

    process(RESET,CLK)
   
    --zmienne do wyliczania wynikow operacji arytmetyczno logicznych
    variable src1, src2: signed(7 downto 0);
    variable srcm1, srcm2: unsigned(7 downto 0);
    variable res: signed(8 downto 0);
    variable resmul: unsigned (15 downto 0);
    variable resmuls: signed (15 downto 0);
    variable n,v: std_logic; --zmienne pomagajace ustawiac flagi
    variable czyinp: std_logic; --zmnienna do wykonania instrukcji na 3 cylke
    variable adres: std_logic_vector (2 downto 0); --adres do rozkazu inp
   
    begin
   
        if RESET = '1' then
            PC <= x"00";
            SPTR <= x"00";
            GPIO <= x"00";
            IOWR <= '0';
            IORD <= '0';
            IOADR <= x"00";
            IOOUT <= x"00";
            state <= S_FETCH;
        elsif rising_edge(CLK) then
       
            case state is
            when S_FETCH =>
                IR <= ROM(to_integer(PC));
                czyinp := '0';
                if std_match(IR, M_IOUTP) then
                    IOWR <= '1';
                elsif std_match(IR, M_INP) then
                    IORD <= '1';
                    czyinp := '1';
                    adres := IRd;
                end if;
                state <= S_EX;
             
            when S_EX =>
           
                if czyinp = '1' then
                    R(TO_INTEGER(unsigned(adres))) <= IOIN;
                end if;
               
                IOWR <= '0';
                IORD <= '0';
               
                if INT = '1' and SREG_I = '1' then
                    STACK(TO_INTEGER(SPTR)) <= PC;
                    SPTR <= SPTR + 1;
                    SREGM <= SREG;
                    SREG_I <= '0';
                    PC <= x"1f";
                    state <= S_FETCH;
                else
               
                    case FormatType is
                    when Format0 =>
                   
                        case OPCODE is
                  --wysy³a na magistralê GPIO wartoœæ 8-bitow¹ bêd¹c¹ argumentem rozkazu
                        when C_OUTP =>
                            GPIO <= ARG;
                            PC <= PC +1;
                  --je¿eli linia Z jest ustawiona na 1 to wykonuje skok w pamiêci programu do rozkazu o adresie bêd¹cym argumentem rozkazu
                        when C_BZ =>
                            if Z='1' then
                                PC <= unsigned(ARG);
                            else
                                PC <= PC +1;
                            end if;
                  --rozkaz nie daj¹cy ¿adnego efektu ale trwaj¹cy jeden cykl rozkazowy
                        when C_NOP =>
                            PC <= PC +1;
                  --wykonuje skok w pamiêci programu do rozkazu o adresie bêd¹cym argumentem rozkazu    
                        when C_B =>
                            PC <= unsigned(ARG);
                  --ustawia bity rejestru SREG w miejscach wystêpowania jedynek w sta³ej K
                        when C_BSET =>
                            SREG <= SREG or unsigned(ARG);
                            PC <= PC +1;
                  --zeruje bity rejestru SREG w miejscach wystêpowania jedynek w sta³ej K
                        when C_BCLR =>
                            SREG <= SREG and not(unsigned(ARG));
                            PC <= PC +1;
                  --skok do podprogramu z adresowaniem bezposrednim
                        when C_CALL =>
                            STACK(TO_INTEGER(SPTR)) <= PC + 1;
                            SPTR <= SPTR + 1;
                            PC <= unsigned(ARG);
                  --skok do podprogramu z adresowaniem posrednim    
                        when C_RCALL =>
                            STACK(TO_INTEGER(SPTR)) <= PC + 1;
                            SPTR <= SPTR + 1;
                            PC <= PC + unsigned(ARG);
                  --instrukcja powrotu z podprogramu
                        when C_RET =>
                            PC <= STACK(TO_INTEGER(SPTR - 1));
                            SPTR <= SPTR - 1;
                        when C_RETI =>
                            PC <= STACK(TO_INTEGER(SPTR - 1));
                            SPTR <= SPTR - 1;
                            SREG <= SREGM;
                        when others =>
                        PC <= x"00";
                        GPIO <= x"00";
                       
                        end case;
                        state <= S_FETCH;
                   
                    when FormatR =>
                        state <= S_FETCH;
                        PC <= PC +1;
                        src1 := signed(R(TO_INTEGER(unsigned(RRd))));
                        src2 := signed(R(TO_INTEGER(unsigned(RRs))));
                        case RCode is
                  --przes³anie zawartoœci rejestru Rs do rejestru Rd
                        when C_MOV =>
                            R(TO_INTEGER(unsigned(RRd))) <= R(TO_INTEGER(unsigned(RRs)));
                  --za³adowanie do rejestru Rd wartoœci z pamiêci RAM spod adresu, na który wskazuje rejestr Rs
                        when C_LD =>
                            R(TO_INTEGER(unsigned(RRd))) <= RAM(TO_INTEGER(unsigned(R(TO_INTEGER(unsigned(RRs))))));
                  --zapisanie zawartoœci rejestru Rs do pamiêci RAM pod adres bêd¹cy zawartoœci¹ rejestru Rd
                        when C_ST =>
                            RAM(TO_INTEGER(unsigned(R(TO_INTEGER(unsigned(RRd)))))) <= R(TO_INTEGER(unsigned(RRs)));
                  --dodaje do rejestru Rd rejestr Rs oraz bit przeniesienia C
                        when C_ADC =>
                            res := "00000000" & SREG_C;
                            res := res + ('0' & src1) + ('0' & src2);
                            SREG_C <= (src1(7) and src2(7)) or (src1(7) and not res(7)) or (src2(7) and not res(7));
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= (src1(7) and src2(7) and not res(7)) or (not src1(7) and not src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (src1(3) and src2(3)) or (src2(3) and not res(3)) or (not res(3) and src1(3));
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(res(7 downto 0));
                  --odejmuje od rejestru Rd rejestr Rs i bit przeniesienia C
                        when C_SBC =>
                            res := ('0' & src1) - ('0' & src2) - ("00000000" & SREG_C);
                            SREG_C <= (not src1(7) and src2(7)) or (src2(7) and res(7)) or (res(7) and not src1(7));
                            SREG_Z <= not res(7) and not res(6) and not res(5) and not res(4) and not res(3) and not res(2) and not res(1) and not res(0) and SREG_Z;
                            n:= res(7);
                            SREG_N <= n;
                            v:= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (not src1(3) and src2(3)) or (src2(3) and res(3)) or (res(3) and not src1(3));
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(res(7 downto 0));
                  --mno¿y bez znaku rejestry Rs i Rd a wynik zapisuje w rejestrach Rd+1:Rd
                        when C_MUL =>
                            srcm1 := unsigned(R(TO_INTEGER(unsigned(RRd))));
                            srcm2 := unsigned(R(TO_INTEGER(unsigned(RRs))));
                            resmul:= srcm1 * srcm2;
                            SREG_C <= resmul(15);
                            if resmul(15 downto 0) = x"0000" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(resmul(15 downto 8));
                            R(to_integer(unsigned(RRd))+1) <= std_logic_vector(resmul(7 downto 0));
                  --mno¿y ze znakiem rejestry Rs i Rd a wynik zapisuje w rejestrach Rd+1:Rd
                        when C_MULS =>
                            resmuls:= src1 * src2;
                            SREG_C <= resmuls(15);
                            if resmuls(15 downto 0) = x"0000" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(resmuls(15 downto 8));
                            R(to_integer(unsigned(RRd))+1) <= std_logic_vector(resmuls(7 downto 0));
                  --iloczyn logiczny rejestrów Rs i Rd
                        when C_AND =>
                            res:= ('0' & src1) and ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(res(7 downto 0));
                  --suma logiczna rejestrów Rs i Rd
                        when C_OR =>
                            res:= ('0' & src1) or ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(res(7 downto 0));
                  --alternatywa roz³¹czna rejestrów Rs i Rd
                        when C_XOR =>
                            res:= ('0' & src1) xor ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(RRd))) <= std_logic_vector(res(7 downto 0));
                  --porownanie zawartosci dwoch rejestrow
                        when C_CP =>
                            res := ('0' & src1) - ('0' & src2);
                            SREG_C <= (not src1(7) and src2(7)) or (src2(7) and res(7)) or (res(7) and not src1(7));
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            SREG_N <= res(7);
                            n:= res(7);
                            v:= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (not src1(3) and src2(3)) or (src2(3) and res(3)) or (res(3) and not src1(3));
                        when others =>
                        PC <= x"00";
                        GPIO <= x"00";
                        end case;
                   
                    when FormatI =>
                        PC <= PC +1;
                        state <= S_FETCH;
                        src1 := signed(R(TO_INTEGER(unsigned(IRd))));
                        src2 := signed(IK);
                        case ICode is
                  --za³adowanie sta³ej 8-bitowej K do rejestru Rd
                        when C_LDI =>
                            R(TO_INTEGER(unsigned(IRd))) <= IK;
                  --za³adowanie do rejestru Rd wartoœci z pamiêci RAM spod adresu okreœlonego sta³¹ 8-bitow¹ K
                        when C_LDS =>
                            R(TO_INTEGER(unsigned(IRd))) <= RAM(TO_INTEGER(unsigned(IK)));
                  --zapisanie zawartoœci rejestru Rs do pamiêci RAM pod adres okreœlony sta³¹ 8-bitow¹ K
                        when C_STS =>
                            RAM(TO_INTEGER(unsigned(IK))) <= R(TO_INTEGER(unsigned(IRd)));
                  --dodaje do rejestru Rd sta³¹ 8-bitow¹ K i bit przeniesienia C
                        when C_ADCI =>
                            res := "00000000" & SREG_C;
                            res := res + ('0' & src1) + ('0' & src2);
                            SREG_C <= (src1(7) and src2(7)) or (src1(7) and not res(7)) or (src2(7) and not res(7));
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= (src1(7) and src2(7) and not res(7)) or (not src1(7) and not src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (src1(3) and src2(3)) or (src2(3) and not res(3)) or (not res(3) and src1(3));
                            R(to_integer(unsigned(IRd))) <= std_logic_vector(res(7 downto 0));
                  --odejmuje od rejestru Rd sta³¹ 8-bitow¹ K i bit przeniesienia C
                        when C_SBCI =>
                            res := ('0' & src1) - ('0' & src2) - ("00000000" & SREG_C);
                            SREG_C <= (not src1(7) and src2(7)) or (src2(7) and res(7)) or (res(7) and not src1(7));
                            SREG_Z <= not res(7) and not res(6) and not res(5) and not res(4) and not res(3) and not res(2) and not res(1) and not res(0) and SREG_Z;
                            n:= res(7);
                            SREG_N <= n;
                            v:= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (not src1(3) and src2(3)) or (src2(3) and res(3)) or (res(3) and not src1(3));
                            R(to_integer(unsigned(IRd))) <= std_logic_vector(res(7 downto 0));
                  --iloczyn logiczny rejestru Rd i sta³ej 8-bitowej K
                        when C_ANDI =>
                            res := ('0' & src1) and ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(IRd))) <= std_logic_vector(res(7 downto 0));
                  --suma logiczna rejestru Rd i sta³ej 8-bitowej K
                        when C_ORI =>
                            res := ('0' & src1) or ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(IRd))) <= std_logic_vector(res(7 downto 0));
                  --alternatywa roz³¹czna rejestru Rd i sta³ej 8-bitowej K
                        when C_XORI =>
                            res := ('0' & src1) xor ('0' & src2);
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            n:= res(7);
                            SREG_N <= n;
                            v:= '0';
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            R(to_integer(unsigned(IRd))) <= std_logic_vector(res(7 downto 0));
                        when others =>
                        PC <= x"00";
                        GPIO <= x"00";
                        end case;
                   
                    when FormatI2 =>
                        state <= S_FETCH;
                        src1 := signed(R(TO_INTEGER(unsigned(IRd))));
                        src2 := signed(IK);
                        case ICode is
                  --skok warunkowy jezeli dana flaga sreg=1
                        when C_BRBS =>
                            if SREG(TO_INTEGER(unsigned(IRd))) = '1' then
                                PC <= PC + unsigned(src2);
                            else
                                PC <= PC + 1;
                            end if;
                  --skok warunkowy jezeli dana flaga sreg=0
                        when C_BRBC =>
                            if SREG(TO_INTEGER(unsigned(IRd))) = '0' then
                                PC <= PC + unsigned(src2);
                            else
                                PC <= PC + 1;
                            end if;
                  --porownanie stalej k z zawartoscia rejestru
                        when C_CPI =>
                            res := ('0' & src1) - ('0' & src2);
                            SREG_C <= (not src1(7) and src2(7)) or (src2(7) and res(7)) or (res(7) and not src1(7));
                            if res(7 downto 0) = x"00" then
                                SREG_Z <= '1';
                            else
                                SREG_Z <= '0';
                            end if;
                            SREG_N <= res(7);
                            n:= res(7);
                            v:= (src1(7) and not src2(7) and not res(7)) or (not src1(7) and src2(7) and res(7));
                            SREG_V <= v;
                            SREG_S <= n xor v;
                            SREG_H <= (not src1(3) and src2(3)) or (src2(3) and res(3)) or (res(3) and not src1(3));
                            PC <= PC +1;
                        when C_IOUTP =>
                            IOADR <= IK;
                            IOOUT <= R(TO_INTEGER(unsigned(IRd)));
                            PC <= PC + 1;
                        when C_INP =>
                            IOADR <= IK;
                            PC <= PC + 1;
                        when others =>
                            PC <= x"00";
                            GPIO <= x"00";
                        end case;
                   
                    when others =>
                    PC <= x"00";
                    GPIO <= x"00";
                    state <= S_FETCH;
                    end case;
               
                end if;
           
            when others =>
            PC <= x"00";
            GPIO <= x"00";
            state <= S_FETCH;
           
            end case;
       
        end if;
   
    end process;

end Behavioral;