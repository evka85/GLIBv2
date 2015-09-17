----------------------------------------------------------------------------------
-- Company:        IIHE - ULB
-- Engineer:       Thomas Lenzi (thomas.lenzi@cern.ch)
-- 
-- Create Date:    08:37:33 07/07/2015 
-- Design Name:    GLIB v2
-- Module Name:    gtx_rx_tracking - Behavioral 
-- Project Name:   GLIB v2
-- Target Devices: xc6vlx130t-1ff1156
-- Tool versions:  ISE  P.20131013
-- Description: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;

entity gtx_rx_tracking is
port(

    gtx_clk_i       : in std_logic;    
    reset_i         : in std_logic;
    
    req_en_o        : out std_logic;
    req_data_o      : out std_logic_vector(31 downto 0);
    
    rx_kchar_i      : in std_logic_vector(1 downto 0);
    rx_data_i       : in std_logic_vector(15 downto 0)
    
);
end gtx_rx_tracking;

architecture Behavioral of gtx_rx_tracking is    

    type state_t is (COMMA, HEADER, DATA_0, DATA_1);
    
    signal state        : state_t;
    
    signal req_data     : std_logic_vector(47 downto 0);

begin  
    
    --== Transitions between states ==--

    process(gtx_clk_i)
    begin
        if (rising_edge(gtx_clk_i)) then
            if (reset_i = '1') then
                state <= COMMA;
            else
                case state is
                    when COMMA =>
                        if (rx_kchar_i = "01" and rx_data_i = x"00BC") then
                            state <= HEADER;
                        end if;
                    when HEADER => state <= DATA_0;
                    when DATA_0 => state <= DATA_1;
                    when DATA_1 => state <= COMMA;
                    when others => state <= COMMA;
                end case;
            end if;
        end if;
    end process;
    
    --== Data to receive at each state ==-- 

    process(gtx_clk_i)
    begin
        if (rising_edge(gtx_clk_i)) then
            if (reset_i = '1') then
                req_data_o <= (others => '0');
            else
                case state is
                    when COMMA =>            
                        if (req_data(47) = '1') then
                            req_en_o <= '1';
                            req_data_o <= req_data(31 downto 0);
                        end if;
                    when HEADER => 
                        req_en_o <= '0';
                        req_data(47 downto 32) <= rx_data_i;
                    when DATA_0 => 
                        req_data(31 downto 16) <= rx_data_i;
                    when DATA_1 => 
                        req_data(15 downto 0) <= rx_data_i;
                    when others => 
                        req_en_o <= '0';
                end case;                
            end if;
        end if;
    end process;
    
end Behavioral;
