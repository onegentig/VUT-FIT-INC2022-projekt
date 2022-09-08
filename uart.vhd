-- uart.vhd: UART controller - receiving part
-- Author: xplagi00
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

-------------------------------------------------
entity UART_RX is
port(
   CLK      :   in std_logic;                       -- clock signal
   RST      :   in std_logic;                       -- reset signal
   DIN      :   in std_logic;                       -- data input
   DOUT     :   out std_logic_vector(7 downto 0);   -- data output
   DOUT_VLD :   out std_logic                       -- validation signal
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
   signal  cnt     :   std_logic_vector(4 downto 0);   -- CLK counter
   signal  cnt2    :   std_logic_vector(3 downto 0);   -- CLK % 16 counter
   signal  vld     :   std_logic;                      -- validation signal
   signal  rx_en   :   std_logic;                      -- enabling signal for CNT2 and DMX
   signal  cnt_en  :   std_logic;                      -- enabling signal for CNT
begin
   FSM: entity work.UART_FSM(behavioral)
   port map(
      CLK           =>  CLK,
      RST           =>  RST,
      DIN           =>  DIN,
      CNT           =>  cnt,
      CNT2          =>  cnt2,
      DOUT_VLD      =>  vld,
      RX_EN         =>  rx_en,
      CNT_EN        =>  cnt_en
   );

   DOUT_VLD <= vld;

   -- CNT - sync. counter with initial state selection (LOAD) and enabling signal (CE)
   p_cnt: process(CLK, RST, cnt_en, rx_en) begin
      if (RST = '1' or cnt_en = '0') then
         cnt <= "00000";
      elsif rising_edge(CLK) then
         if (cnt(4) = '1' and rx_en = '1') then
            cnt <= "00001";
         else
            cnt <= cnt + 1;
         end if;
      end if;
   end process p_cnt;

   -- CNT2 - sync. counter of transferred bits with enabling signal (CE)
   p_cnt2: process(CLK, RST, rx_en) begin
      if (RST = '1' or rx_en = '0') then
         cnt2 <= "0000";
      elsif rising_edge(CLK) then
         if (cnt(4) = '1' and rx_en = '1') then
            cnt2 <= cnt2 + 1;
         end if;
      end if;
   end process p_cnt2;

   -- demultiplexer & registers
   p_dmx_reg: process(CLK, RST, cnt2, rx_en, DIN) begin
      if (RST = '1') then
         DOUT <= "00000000";
      elsif rising_edge(CLK) then
         if (cnt(4) = '1' and rx_en = '1') then
            case cnt2 is
               when "0000" => DOUT(0) <= DIN;
               when "0001" => DOUT(1) <= DIN;
               when "0010" => DOUT(2) <= DIN;
               when "0011" => DOUT(3) <= DIN;
               when "0100" => DOUT(4) <= DIN;
               when "0101" => DOUT(5) <= DIN;
               when "0110" => DOUT(6) <= DIN;
               when "0111" => DOUT(7) <= DIN;
               when others => null;
            end case;
         end if;
      end if;
   end process p_dmx_reg;
   
end architecture behavioral;