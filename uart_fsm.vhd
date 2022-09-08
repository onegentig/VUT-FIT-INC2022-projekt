-- uart_fsm.vhd: UART controller - finite state machine
-- Author: xplagi00
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

-------------------------------------------------
entity UART_FSM is
port(
   CLK      :  in std_logic;                    -- clock signal
   RST      :  in std_logic;                    -- reset signal
   DIN      :  in std_logic;                    -- data input
   CNT      :  in std_logic_vector(4 downto 0); -- CLK counter
   CNT2     :  in std_logic_vector(3 downto 0); -- CLK % 16 counter
   DOUT_VLD :  out std_logic;                   -- validity signal
   RX_EN    :  out std_logic;                   -- enabling signal for CNT2 and DMX
   CNT_EN   :  out std_logic                    -- enabling signal for CNT
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
   type t_state is (IDLE, AWAIT_FIRST, READ_DATA, AWAIT_STOP, VALIDATE);
   signal STATE_T : t_state := IDLE; 
   attribute fsm_encoding : string;
   attribute fsm_encoding of STATE_T : signal is "sequential";
begin

   state_logic : process(CLK, RST) begin
      if rising_edge(CLK) then
         if RST = '1' then
            STATE_T <= IDLE;
         else 
            case STATE_T is
            -- -----------------------
               -- IDLE --[0, X, X]--> AWAIT_FIRST
               when IDLE =>
                  if DIN = '0' then
                     STATE_T <= AWAIT_FIRST;
                  end if;
            -- -----------------------
               -- AWAIT_FIRST --[X, 24, X]--> READ_DATA
               when AWAIT_FIRST =>
                  if CNT = "11000" then
                     STATE_T <= READ_DATA;
                  end if;
            -- -----------------------
               -- READ_DATA --[X, X, 8]--> AWAIT_STOP
               when READ_DATA =>
                  if CNT2 = "1000" then
                     STATE_T <= AWAIT_STOP;
                  end if;
            -- -----------------------
               -- AWAIT_STOP --[X, 16, X]--> VALIDATE
               when AWAIT_STOP =>
                  if CNT = "10000" then
                     STATE_T <= VALIDATE;
                  end if;
            -- -----------------------
               -- VALIDATE --[X, X, X]--> IDLE
               when VALIDATE =>
                  STATE_T <= IDLE;
            -- -----------------------
               -- undefined state (should not happen)
               when others => 
                  STATE_T <= IDLE;
            -- -----------------------
            end case;
         end if;
      end if;
   end process state_logic;

   output_logic : process(STATE_T) begin
      case (STATE_T) is
      -- -----------------------
         when IDLE =>
            DOUT_VLD <= '0';
            RX_EN <= '0';
            CNT_EN <= '0';
      -- -----------------------
         when AWAIT_FIRST =>
            DOUT_VLD <= '0';
            RX_EN <= '0';
            CNT_EN <= '1';
      -- -----------------------
         when READ_DATA =>
            DOUT_VLD <= '0';
            RX_EN <= '1';
            CNT_EN <= '1';
      -- -----------------------
         when AWAIT_STOP =>
            DOUT_VLD <= '0';
            RX_EN <= '0';
            CNT_EN <= '1';
      -- -----------------------
         when VALIDATE =>
            DOUT_VLD <= '1';
            RX_EN <= '0';
            CNT_EN <= '0';
      -- -----------------------
      end case;
   end process output_logic;

end architecture behavioral;