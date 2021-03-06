library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity cpucontrol is
port(
		clk : in std_logic;
		reset : in std_logic;
		IR : in std_logic_Vector(7 downto 0);
		Zflag : in std_logic;
		--addrbus : out std_logic_vector(15 downto 0);
		--databus : inout std_logic_vector(7 downto 0);
	--memory
		cpuread :out std_logic;
		cpuwrite : out std_logic;
	--AR	
		ARLOAD : out std_logic;
		ARINC : out std_logic;
	--PC	
		PCLOAD : out std_logic;
		PCINC : out std_logic;
		
		PCBUS : out std_logic;
	--DR	
		DRLOAD : out std_logic;
		
		DRHBUS :	out std_logic;
		DRLBUS :	out std_logic;
	--TR
		TRLOAD : out std_logic;
		
		TRBUS : out std_logic;
	--IR
		IRLOAD : out std_logic;
	--R
		RLOAD : out std_logic;
		
		RBUS : out std_logic;
	--AC
		ACLOAD : out std_logic;
		ACINC : out std_logic;
		ACBUS : out std_logic;
	--MEMBUS
		MEMBUS_OUT_ENA : out std_logic;
		MEMBUS_IN_ENA : out std_logic;
	--ALU
		ALUs : out std_logic_Vector(1 downto 0));
	--Z
		--ZLOAD : out std_logic
		
end entity;

architecture cpu_behav of cpucontrol is
	
	signal NextPC : std_logic_vector(15 downto 0);

	signal State : std_logic_vector(5 downto 0);
	signal NextState : std_logic_Vector(5 downto 0);
	
	constant fetch1 : std_logic_vector(5 downto 0) := "000000";
	constant fetch2 : std_logic_vector(5 downto 0) := "000001";
	constant fetch3 : std_logic_vector(5 downto 0) := "000010";
	
	constant NOP1 : std_logic_vector(5 downto 0) := "000011";
	constant MVAC1 : std_logic_vector(5 downto 0) := "000100";
	constant JNZ1 : std_logic_vector(5 downto 0) := "000101";
	constant JNZ2 : std_logic_vector(5 downto 0) := "000110";
	constant JNZ3 : std_logic_vector(5 downto 0) := "001110";
	constant JZ1 : std_logic_vector(5 downto 0) := "001100";
	constant JZ2 : std_logic_vector(5 downto 0) := "001101";
	constant ADD1 : std_logic_vector(5 downto 0) := "000111";
	constant SUB1 : std_logic_vector(5 downto 0) := "001000";
	constant CLAC1 : std_logic_vector(5 downto 0) := "001001";
	constant INAC1 : std_logic_vector(5 downto 0) := "001010";
	
	constant LDAC1 : std_logic_vector(5 downto 0) := "010000";
	constant LDAC2 : std_logic_vector(5 downto 0) := "010001";
	constant LDAC3 : std_logic_vector(5 downto 0) := "010010";
	constant LDAC4 : std_logic_vector(5 downto 0) := "010011";
	constant LDAC5 : std_logic_vector(5 downto 0) := "010100";
	
	constant STAC1 : std_logic_vector(5 downto 0) := "100000";
	constant STAC2 : std_logic_vector(5 downto 0) := "100001";
	constant STAC3 : std_logic_vector(5 downto 0) := "100010";
	constant STAC4 : std_logic_vector(5 downto 0) := "100011";
	constant STAC5 : std_logic_vector(5 downto 0) := "100100";
	
	
	begin
		-- Update addrbus and databus
		--addrbus <= AR;
		--databus <= DR when cpuwrite='1' else "ZZZZZZZZ";
		
		--Update PC, State and Registers
		--Update_registers:process(clk)
		--begin 
			--if(rising_edge(clk)) then
				--if(reset='1') then 
					--PC <= X"00000000";
					--State <= fetch1;
				--else
					--PC <= NextPC;
					--State <= NextState;
				--end if;
			--end if;
		--end process Update_registers;
		
		--Generate NextState
		
		Gen_NextState:process(IR,clk,Zflag,reset)
		begin
			case State is
				when fetch1 =>
					NextState <= fetch2;
				when fetch2 =>
					NextState <= fetch3;
				when fetch3 =>
					case IR is
						when "00000000" =>
							NextState <= NOP1;
						when "00000001" =>
							NextState <= LDAC1;
						when "00000010" =>
							NextState <= STAC1;
						when "00000011" =>
							NextState <= MVAC1;
						when "00000100" =>
							NextState <= CLAC1;
						when "00000101" =>
							NextState <= INAC1;
						when "00000110" =>
							NextState <= ADD1;
						when "00000111" =>
							NextState <= SUB1;
						when "00001000" =>
							if(Zflag='0') then
								NextState <= JNZ1;
							else
								NextState <= JZ1;
							end if;
						when others =>null;
					end case;
				when STAC1 =>
					NextState <= STAC2;
				when STAC2 =>
					NextState <= STAC3;
				when STAC3 =>
					NextState <= STAC4;
				when STAC4 =>
					NextState <= STAC5;
				
				when LDAC1 =>
					NextState <= LDAC2;
				when LDAC2 =>
					NextState <= LDAC3;
				when LDAC3 =>
					NextState <= LDAC4;
				when LDAC4 =>
					NextState <= LDAC5;
					
				when JNZ1 =>
					NextState <= JNZ2;
				when JNZ2 =>
					NextState <= JNZ3;
					
				when JZ1 =>
					NextState <= JZ2;
					
				when others =>
					NextState <= fetch1;
			end case;
			if(rising_edge(clk)) then
				if(reset='1') then
					State <= fetch1;
				end if;
			end if;
			if(clk='0') then
				State <= NextState;
			end if;
		end process Gen_NextState;
		
		--Generate operate
		Gen_operate:process(clk,state)
		begin
			if(rising_edge(clk)) then
				case state is
					when fetch1 =>			--AR <= PC
						PCBUS <= '1';
						ARLOAD <= '1';
					when fetch2 =>		--DR <= M	PC <= PC+1
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						DRLOAD <= '1';
						PCINC <= '1';
					when fetch3 =>		--IR <= DR  --AR <= PC
						IRLOAD <= '1';
						PCBUS <= '1';
						ARLOAD <= '1';
				--LDAC
					when LDAC1 =>		--DR <= M	PC <= PC+1	AR <= AR+1
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						PCINC <= '1';
						ARINC <= '1';
					when LDAC2  =>		--TR <= DR	DR <= M	PC <= PC+1;
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						PCINC <= '1';
						DRLOAD <= '1';
						TRLOAD <= '1';
					when LDAC3 =>		--AR <= DR&&TR;
						TRBUS <= '1';
						DRHBUS <= '1';
						ARLOAD <= '1';
					when LDAC4 =>		--DR <= M
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						DRLOAD <= '1';
					when LDAC5 =>		--AC <= DR;
						DRLBUS <= '1';
						ACLOAD <= '1';
						
				--STAC
					when STAC1 =>		--DR <= M	PC <= PC+1	AR <= AR+1;
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						DRLOAD <= '1';
						PCINC <= '1';
						ARINC <= '1';
					when STAC2 =>		--TR <= DR	--DR <= M	PC <= PC+1;
						MEMBUS_OUT_ENA <= '1';
						cpuread <= '1';
						TRLOAD <= '1';
						DRLOAD <= '1';
						PCINC <= '1';
					when STAC3 =>		--AR <= DR&&TR;
						TRBUS <= '1';
						DRHBUS <= '1';
						ARLOAD <= '1';
					when STAC4 =>		--DR <= AC;
						DRLOAD <= '1';
						ACBUS <= '1';
					when STAC5 =>		--M <= DR
						MEMBUS_IN_ENA <= '1';
						cpuwrite <= '1';
						DRLBUS <= '1';
				--MVAC
					when MVAC1 =>			--R <= AC;
						RLOAD <= '1';
						ACBUS <= '1';
				--JNZ	
					when JNZ1 =>
						MEMBUS_IN_ENA <= '1';
						cpuwrite <= '1';
						DRLOAD <= '1';
						ARINC <= '1';
					when JNZ2 =>
						MEMBUS_IN_ENA <= '1';
						cpuwrite <= '1';
						TRLOAD <= '1';
						DRLOAD <= '1';
					when JNZ3 =>
						PCLOAD <= '1';
						DRHBUS <= '1';
						TRBUS <= '1';
				--JZ
					when JZ1 =>
						PCINC <= '1';
					when JZ2 =>
						PCINC <= '1';
				--ADD	
					when ADD1  =>	--格式转换
						--AC <= AC+R;
						ALUs <= "01";
						RBUS <= '1';
				--SUB
					when SUB1 =>	--格式转换
						ALUs <= "10";
						RBUS <= '1';
				--INAC
					when INAC1 =>	--格式转换
						ACINC <= '1';
				--CLAC
					--when CLAC1 =>
						--AC <= 0;
						--Zflag <= 1;
				--NOP and other State
					when others =>
						null;
				end case;
			end if;
			if(clk='0') then
				cpuread <= '0';
				cpuwrite <= '0';
				ARLOAD <= '0';
				ARINC <= '0';
				PCLOAD <= '0';
				PCINC <= '0';
				PCBUS <= '0';
				DRLOAD <= '0';
				DRHBUS <= '0';
				DRLBUS <= '0';
				TRLOAD <= '0';
				TRBUS <= '0';
				IRLOAD <= '0';
				RLOAD <= '0';
				RBUS <= '0';
				ACLOAD <= '0';
				ACINC <= '0';
				ACBUS <= '0';
				ALUs <= "00";
				MEMBUS_IN_ENA <= '0';
				MEMBUS_OUT_ENA <= '0';
				--ZLOAD <= '0';
			end if;
		end process Gen_operate;
				
end cpu_behav;