--===========================================================================--
--
--  S Y N T H E Z I A B L E    cpu11 - HC11 compatible CPU core
--
--  www.OpenCores.Org - September 2003
--  This core adheres to the GNU public license  
--
-- File name      : cpu11.vhd
--
-- Entity name    : cpu11
--
-- Purpose        : HC11 instruction set compatible CPU core
--
-- Dependencies   : ieee.std_logic_1164
--                  ieee.std_logic_unsigned
--
-- Uses           : Nothing
--
-- Author         : John Kent - dilbert57@opencores.org
--
-------------------------------------------------------------------------------
-- Revision list
--
-- Version 0.1 - 13 November 2002 - John Kent
-- revamped 6801 CPU into 68HC11 CPU.
-- Added Y index register
-- Added Y indexing prebyte
-- Added CMPD with prebyte
-- Added bit operators
-- Updated stack operations
--
-- Version 0.3 - 15 December 2002 - John Kent
-- implemented FDIV
-- implemented IDIV
--
-- Version 1.0 - 7 September 2003 - John Kent
-- Released to Open Cores
-- Basic 6800 instructions working
-- but not Divide and bit operations.
--
-- Version 1.1 - 4 April 2004
-- Removed Test_alu and Test_cc signals
-- Moved Dual operand execution into fetch state
-- Fixed Indexed bit operators
--
-- Added by sashz (11 Jul 2017):
-- 13 Jan 2004 1.1                John Kent  
-- As Reported by Michael Hasenfratz CLR did not clear the carry bit.
-- this is because the state sequencer enumerated the ALU with "alu_ld8"
-- rather than "alu_clr". I've also moved the "alu_clr" to the "alu_clc"
-- decode which clears the carry. It should not be necessary, but is a
-- more obvious way of doing things.
--
-- Added by sashz (15 Jul 2017):
-- Fixed mistyped prefix for page4 indexed state
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cpu11 is
	port (	
		clk:	    in  std_logic;
		rst:	    in  std_logic;
		rw:	    out std_logic;
		vma:	    out std_logic;
		address:	 out std_logic_vector(15 downto 0);
	   data_in:	 in  std_logic_vector(7 downto 0);
	   data_out: out std_logic_vector(7 downto 0);
		irq:      in  std_logic;
		xirq:     in  std_logic;
		irq_ext3:  in  std_logic;
		irq_ext2:  in  std_logic;
		irq_ext1:  in  std_logic;
		irq_ext0:  in  std_logic
		);
end;

architecture CPU_ARCH of cpu11 is

  constant SBIT : integer := 7;
  constant XBIT : integer := 6;
  constant HBIT : integer := 5;
  constant IBIT : integer := 4;
  constant NBIT : integer := 3;
  constant ZBIT : integer := 2;
  constant VBIT : integer := 1;
  constant CBIT : integer := 0;

	type state_type is (reset_state, fetch_state, decode_state,
                       extended_state, indexed_state, read8_state, read16_state, immediate16_state,
	                    write8_state, write16_state,
						     execute_state, halt_state, spin_state,
						     exchange_state,
						     mul_state, mulea_state, muld_state, mul0_state,
  							  idiv_state,
							  div1_state, div2_state, div3_state, div4_state, div5_state,
							  jmp_state, jsr_state, jsr1_state,
						     branch_state, bsr_state, bsr1_state,
 							  bitmask_state, brset_state, brclr_state,
							  rts_hi_state, rts_lo_state,
							  int_pcl_state, int_pch_state,
						     int_ixl_state, int_ixh_state,
						     int_iyl_state, int_iyh_state,
						     int_cc_state, int_acca_state, int_accb_state,
						     int_wai_state, int_maski_state, int_maskx_state,
						     rti_state, rti_cc_state, rti_acca_state, rti_accb_state,
						     rti_ixl_state, rti_ixh_state,
						     rti_iyl_state, rti_iyh_state,
						     rti_pcl_state, rti_pch_state,
							  pula_state, psha_state, pulb_state, pshb_state,
						     pulxy_lo_state, pulxy_hi_state, pshxy_lo_state, pshxy_hi_state,
							  vect_lo_state, vect_hi_state );
	type addr_type is (idle_ad, fetch_ad, read_ad, write_ad, push_ad, pull_ad, int_hi_ad, int_lo_ad );
	type dout_type is ( acca_dout, accb_dout, cc_dout,
                       ix_lo_dout, ix_hi_dout, iy_lo_dout, iy_hi_dout,
							  md_lo_dout, md_hi_dout, pc_lo_dout, pc_hi_dout );
   type op_type is (reset_op, fetch_op, latch_op );
   type pre_type is (reset_pre, fetch_pre, latch_pre );
   type acca_type is (reset_acca, load_acca, load_hi_acca, pull_acca, latch_acca );
   type accb_type is (reset_accb, load_accb, pull_accb, latch_accb );
   type cc_type is (reset_cc, load_cc, pull_cc, latch_cc );
	type ix_type is (reset_ix, load_ix, pull_lo_ix, pull_hi_ix, latch_ix );
	type iy_type is (reset_iy, load_iy, pull_lo_iy, pull_hi_iy, latch_iy );
	type sp_type is (reset_sp, latch_sp, load_sp );
	type pc_type is (reset_pc, latch_pc, load_pc, pull_lo_pc, pull_hi_pc, incr_pc );
   type md_type is (reset_md, latch_md, load_md, fetch_first_md, fetch_next_md, shiftl_md );
   type ea_type is (reset_ea, latch_ea, load_ea, fetch_first_ea, fetch_next_ea, add_ix_ea, add_iy_ea );
	type iv_type is (reset_iv, latch_iv, swi_iv, xirq_iv, irq_iv, ext3_iv, ext2_iv, ext1_iv, ext0_iv );
	type count_type is (reset_count, latch_count, inc_count );
	type left_type is (acca_left, accb_left, accd_left, md_left, ix_left, iy_left, pc_left, sp_left, ea_left );
	type right_type is (md_right, zero_right, one_right, accb_right, pre_right, ea_right, sexea_right );
   type alu_type   is (alu_add8, alu_sub8, alu_add16, alu_sub16, alu_adc, alu_sbc, 
                       alu_and, alu_ora, alu_eor,
                       alu_tst, alu_inc, alu_dec, alu_clr, alu_neg, alu_com,
							  alu_inc16, alu_dec16,
						     alu_lsr16, alu_lsl16,
						     alu_ror8, alu_rol8, alu_rol16,
						     alu_asr8, alu_asl8, alu_lsr8,
						     alu_sei, alu_cli, alu_sec, alu_clc, alu_sev, alu_clv,
						     alu_sex, alu_clx, alu_tpa, alu_tap,
						     alu_ld8, alu_st8, alu_ld16, alu_st16, alu_nop, alu_daa,
						     alu_bset, alu_bclr );

	signal op_code:     std_logic_vector(7 downto 0);
	signal pre_byte:    std_logic_vector(7 downto 0);
  	signal acca:        std_logic_vector(7 downto 0);
  	signal accb:        std_logic_vector(7 downto 0);
   signal cc:          std_logic_vector(7 downto 0);
	signal cc_out:      std_logic_vector(7 downto 0);
	signal xreg:        std_logic_vector(15 downto 0);
	signal yreg:        std_logic_vector(15 downto 0);
	signal sp:          std_logic_vector(15 downto 0);
	signal ea:          std_logic_vector(15 downto 0);
	signal pc:	        std_logic_vector(15 downto 0);
	signal md:          std_logic_vector(15 downto 0);
   signal left:        std_logic_vector(15 downto 0);
   signal right:       std_logic_vector(15 downto 0);
	signal out_alu:     std_logic_vector(15 downto 0);
	signal iv:          std_logic_vector(2 downto 0);
	signal ea_bit:      std_logic;
	signal count:       std_logic_vector(4 downto 0);

	signal state:       state_type;
	signal next_state:  state_type;
   signal pc_ctrl:     pc_type;
   signal ea_ctrl:     ea_type; 
   signal op_ctrl:     op_type;
   signal pre_ctrl:    pre_type;
	signal md_ctrl:     md_type;
	signal acca_ctrl:   acca_type;
	signal accb_ctrl:   accb_type;
	signal ix_ctrl:     ix_type;
	signal iy_ctrl:     iy_type;
	signal cc_ctrl:     cc_type;
	signal sp_ctrl:     sp_type;
	signal iv_ctrl:     iv_type;
	signal left_ctrl:   left_type;
	signal right_ctrl:  right_type;
   signal alu_ctrl:    alu_type;
   signal addr_ctrl:   addr_type;
   signal dout_ctrl:   dout_type;
   signal count_ctrl:  count_type;


begin

--------------------------------
--
-- Accumulator A
--
--------------------------------
acca_reg : process( clk, acca_ctrl, out_alu, acca, data_in )
begin
  if clk'event and clk = '0' then
    case acca_ctrl is
    when reset_acca =>
	   acca <= "00000000";
	 when load_acca =>
	   acca <= out_alu(7 downto 0);
	 when load_hi_acca =>
	   acca <= out_alu(15 downto 8);
	 when pull_acca =>
	   acca <= data_in;
	 when others =>
--	 when latch_acca =>
	   acca <= acca;
    end case;
  end if;
end process;

--------------------------------
--
-- Accumulator B
--
--------------------------------
accb_reg : process( clk, accb_ctrl, out_alu, accb, data_in )
begin
  if clk'event and clk = '0' then
    case accb_ctrl is
    when reset_accb =>
	   accb <= "00000000";
	 when load_accb =>
	   accb <= out_alu(7 downto 0);
	 when pull_accb =>
	   accb <= data_in;
	 when others =>
--	 when latch_accb =>
	   accb <= accb;
    end case;
  end if;
end process;

----------------------------------
--
-- Condition Codes
--
----------------------------------

cc_reg: process( clk, cc_ctrl, cc_out, cc, data_in )
begin
  if clk'event and clk = '0' then
    case cc_ctrl is
	 when reset_cc =>
	   cc <= "11000000";
	 when load_cc =>
	   cc <= cc_out;
  	 when pull_cc =>
      cc <= data_in;
	 when others =>
--  when latch_cc =>
      cc <= cc;
    end case;
  end if;
end process;

--------------------------------
--
-- X Index register
--
--------------------------------
ix_reg : process( clk, ix_ctrl, out_alu, xreg, data_in )
begin
  if clk'event and clk = '0' then
    case ix_ctrl is
    when reset_ix =>
	   xreg <= "0000000000000000";
	 when load_ix =>
	   xreg <= out_alu(15 downto 0);
	 when pull_hi_ix =>
	   xreg(15 downto 8) <= data_in;
	 when pull_lo_ix =>
	   xreg(7 downto 0) <= data_in;
	 when others =>
--	 when latch_ix =>
	   xreg <= xreg;
    end case;
  end if;
end process;

--------------------------------
--
-- Y Index register
--
--------------------------------
iy_reg : process( clk, iy_ctrl, out_alu, yreg, data_in )
begin
  if clk'event and clk = '0' then
    case iy_ctrl is
    when reset_iy =>
	   yreg <= "0000000000000000";
	 when load_iy =>
	   yreg <= out_alu(15 downto 0);
	 when pull_hi_iy =>
	   yreg(15 downto 8) <= data_in;
	 when pull_lo_iy =>
	   yreg(7 downto 0) <= data_in;
	 when others =>
--	 when latch_iy =>
	   yreg <= yreg;
    end case;
  end if;
end process;

--------------------------------
--
-- stack pointer
--
--------------------------------
sp_reg : process( clk, sp_ctrl, out_alu )
begin
  if clk'event and clk = '0' then
    case sp_ctrl is
    when reset_sp =>
	   sp <= "0000000000000000";
	 when load_sp =>
	   sp <= out_alu(15 downto 0);
	 when others =>
--	 when latch_sp =>
	   sp <= sp;
    end case;
  end if;
end process;

----------------------------------
--
-- Program Counter Control
--
----------------------------------

pc_reg: process( clk, pc_ctrl, pc, out_alu, data_in )
begin
  if clk'event and clk = '0' then
    case pc_ctrl is
	 when reset_pc =>
	   pc <= "0000000000000000";
	 when incr_pc =>
	   pc <= pc + "0000000000000001";
	 when load_pc =>
	   pc <= out_alu(15 downto 0);
	 when pull_lo_pc =>
	   pc(7 downto 0) <= data_in;
	 when pull_hi_pc =>
	   pc(15 downto 8) <= data_in;
	 when others =>
--	 when latch_pc =>
      pc <= pc;
    end case;
  end if;
end process;

----------------------------------
--
-- Effective Address  Control
--
----------------------------------

ea_reg: process( clk, ea_ctrl, ea, out_alu, data_in, xreg, yreg )
begin

  if clk'event and clk = '0' then
    case ea_ctrl is
	 when reset_ea =>
	   ea <= "0000000000000000";
	 when fetch_first_ea =>
	   ea(7 downto 0) <= data_in;
      ea(15 downto 8) <= "00000000";
  	 when fetch_next_ea =>
	   ea(15 downto 8) <= ea(7 downto 0);
      ea(7 downto 0)  <= data_in;
    when add_ix_ea =>
	   ea <= ea + xreg;
    when add_iy_ea =>
	   ea <= ea + yreg;
	 when load_ea =>
	   ea <= out_alu(15 downto 0);
	 when others =>
--  	 when latch_ea =>
      ea <= ea;
    end case;
  end if;
end process;

--------------------------------
--
-- Memory Data
--
--------------------------------
md_reg : process( clk, md_ctrl, out_alu, data_in, md )
begin
  if clk'event and clk = '0' then
    case md_ctrl is
    when reset_md =>
	   md <= "0000000000000000";
	 when load_md =>
	   md <= out_alu(15 downto 0);
	 when fetch_first_md =>
	   md(15 downto 8) <= "00000000";
	   md(7 downto 0) <= data_in;
	 when fetch_next_md =>
	   md(15 downto 8) <= md(7 downto 0);
		md(7 downto 0) <= data_in;
	 when shiftl_md =>
	   md(15 downto 1) <= md(14 downto 0);
		md(0) <= '0';
	 when others =>
--	 when latch_md =>
	   md <= md;
    end case;
  end if;
end process;

----------------------------------
--
-- interrupt vector
--
----------------------------------

iv_reg: process( clk, iv_ctrl )
begin
  if clk'event and clk = '0' then
    case iv_ctrl is
	when reset_iv =>
	    iv <= "111";
	when xirq_iv =>
	    iv <= "110";
	when swi_iv =>
	    iv <= "101";
	when irq_iv =>
	    iv <= "100";
	when ext3_iv =>
	    iv <= "011";
	when ext2_iv =>
	    iv <= "010";
	when ext1_iv =>
	    iv <= "001";
	when ext0_iv =>
	    iv <= "000";
	when others =>
	    iv <= iv;
    end case;
  end if;
end process;

----------------------------------
--
-- op code register
--
----------------------------------

op_reg: process( clk, data_in, op_ctrl, op_code )
begin
  if clk'event and clk = '0' then
    case op_ctrl is
	 when reset_op =>
	   op_code <= "00000001";	-- nop
  	 when fetch_op =>
      op_code <= data_in;
	 when others =>
--	 when latch_op =>
	   op_code <= op_code;
    end case;
  end if;
end process;

----------------------------------
--
-- pre byte register
--
----------------------------------

pre_reg: process( clk, pre_ctrl, data_in, pre_byte )
begin
  if clk'event and clk = '0' then
    case pre_ctrl is
	 when reset_pre =>
	   pre_byte <= "00000000";
  	 when fetch_pre =>
      pre_byte <= data_in;
	 when others =>
--	 when latch_op =>
	   pre_byte <= pre_byte;
    end case;
  end if;
end process;

----------------------------------
--
-- counter
--
----------------------------------

count_reg: process( clk, count_ctrl, count )
begin
  if clk'event and clk = '0' then
    case count_ctrl is
	 when reset_count =>
	   count <= "00000";
  	 when inc_count =>
      count <= count + "00001";
	 when others =>
--	 when latch_count =>
	   count <= count;
    end case;
  end if;
end process;

----------------------------------
--
-- Address output multiplexer
--
----------------------------------

addr_mux: process( clk, addr_ctrl, pc, ea, sp, iv )
begin
  case addr_ctrl is
    when idle_ad =>
	    address <= "1111111111111111";
		vma     <= '0';
		rw      <= '1';
    when fetch_ad =>
	    address <= pc;
		vma     <= '1';
		rw      <= '1';
    when read_ad =>
	    address <= ea;
		vma     <= '1';
		rw      <= '1';
    when write_ad =>
	    address <= ea;
		vma     <= '1';
		rw      <= '0';
    when push_ad =>
	    address <= sp;
		vma     <= '1';
		rw      <= '0';
    when pull_ad =>
	    address <= sp;
		vma     <= '1';
		rw      <= '1';
    when int_hi_ad =>
	    address <= "111111111111" & iv & "0";
		vma     <= '1';
		rw      <= '1';
    when int_lo_ad =>
	    address <= "111111111111" & iv & "1";
		vma     <= '1';
		rw      <= '1';
    when others =>
	    address <= "1111111111111111";
		vma     <= '0';
		rw      <= '1';
  end case;
end process;

--------------------------------
--
-- Data Bus output
--
--------------------------------
dout_mux : process( clk, dout_ctrl, md, acca, accb, xreg, yreg, pc, cc )
begin
    case dout_ctrl is
	 when acca_dout => -- accumulator a
	   data_out <= acca;
	 when accb_dout => -- accumulator b
	   data_out <= accb;
	 when cc_dout => -- condition codes
	   data_out <= cc;
	 when ix_lo_dout => -- X index reg
	   data_out <= xreg(7 downto 0);
	 when ix_hi_dout => -- X index reg
	   data_out <= xreg(15 downto 8);
	 when iy_lo_dout => -- Y index reg
	   data_out <= yreg(7 downto 0);
	 when iy_hi_dout => -- Y index reg
	   data_out <= yreg(15 downto 8);
	 when md_lo_dout => -- memory data (ALU)
	   data_out <= md(7 downto 0);
	 when md_hi_dout => -- memory data (ALU)
	   data_out <= md(15 downto 8);
	 when pc_lo_dout => -- low order pc
	   data_out <= pc(7 downto 0);
	 when pc_hi_dout => -- high order pc
	   data_out <= pc(15 downto 8);
	 when others =>
	   data_out <= "00000000";
    end case;
end process;

----------------------------------
--
-- ea bit mutiplexer (used by multiply)
--
----------------------------------

ea_bit_mux: process( count, ea )
begin
  case count(3 downto 0) is
	 when "0000" =>
	   ea_bit <= ea(0);
	 when "0001" =>
	   ea_bit <= ea(1);
	 when "0010" =>
	   ea_bit <= ea(2);
	 when "0011" =>
	   ea_bit <= ea(3);
	 when "0100" =>
	   ea_bit <= ea(4);
	 when "0101" =>
	   ea_bit <= ea(5);
	 when "0110" =>
	   ea_bit <= ea(6);
	 when "0111" =>
	   ea_bit <= ea(7);
	 when "1000" =>
	   ea_bit <= ea(8);
	 when "1001" =>
	   ea_bit <= ea(9);
	 when "1010" =>
	   ea_bit <= ea(10);
	 when "1011" =>
	   ea_bit <= ea(11);
	 when "1100" =>
	   ea_bit <= ea(12);
	 when "1101" =>
	   ea_bit <= ea(13);
	 when "1110" =>
	   ea_bit <= ea(14);
	 when "1111" =>
	   ea_bit <= ea(15);
	 when others =>
      null;
  end case;
end process;

----------------------------------
--
-- Left Mux
--
----------------------------------

left_mux: process( left_ctrl, acca, accb, xreg, yreg, sp, pc, ea, md )
begin
  case left_ctrl is
	 when acca_left =>
	   left(15 downto 8) <= "00000000";
		left(7 downto 0)  <= acca;
	 when accb_left =>
	   left(15 downto 8) <= "00000000";
		left(7 downto 0)  <= accb;
	 when accd_left =>
	   left(15 downto 8) <= acca;
		left(7 downto 0)  <= accb;
	 when md_left =>
	   left <= md;
	 when ix_left =>
	   left <= xreg;
	 when iy_left =>
	   left <= yreg;
	 when sp_left =>
	   left <= sp;
	 when pc_left =>
	   left <= pc;
	 when others =>
--	 when ea_left =>
	   left <= ea;
    end case;
end process;

----------------------------------
--
-- Right Mux
--
----------------------------------

right_mux: process( right_ctrl, data_in, md, accb, pre_byte, ea )
begin
  case right_ctrl is
	 when zero_right =>
	   right <= "0000000000000000";
	 when one_right =>
	   right <= "0000000000000001";
	 when accb_right =>
	   right <= "00000000" & accb; -- for abx / aby instructions
	 when pre_right =>
	   right <= "00000000" & pre_byte; -- prebyte register doubles as bit mask
	 when ea_right =>
	   right <= ea;
	 when sexea_right =>
	   if ea(7) = '0' then
	     right <= "00000000" & ea(7 downto 0);
		else
		  right <= "11111111" & ea(7 downto 0);
		end if;
	 when others =>
--	 when md_right =>
	   right <= md;
    end case;
end process;

----------------------------------
--
-- Arithmetic Logic Unit
--
----------------------------------

alu_logic: process( alu_ctrl, cc, left, right, out_alu, cc_out )
variable valid_lo, valid_hi : boolean;
variable carry_in : std_logic;
variable daa_reg : std_logic_vector(7 downto 0);
begin

  case alu_ctrl is
  	 when alu_adc | alu_sbc |
  	      alu_rol8 | alu_ror8 | alu_rol16 =>
	   carry_in := cc(CBIT);
  	 when others =>
	   carry_in := '0';
  end case;

  valid_lo := left(3 downto 0) <= 9;
  valid_hi := left(7 downto 4) <= 9;

  if (cc(CBIT) = '0') then
    if( cc(HBIT) = '1' ) then
		if valid_hi then
		  daa_reg := "00000110";
		else
		  daa_reg := "01100110";
	   end if;
    else
		if valid_lo then
		  if valid_hi then
		    daa_reg := "00000000";
		  else
		    daa_reg := "01100000";
		  end if;
		else
	     if( left(7 downto 4) <= 8 ) then
		    daa_reg := "00000110";
		  else
			 daa_reg := "01100110";
		  end if;
		end if;
	 end if;
  else
    if ( cc(HBIT) = '1' )then
		daa_reg := "01100110";
 	 else
		if valid_lo then
		  daa_reg := "01100000";
	   else
		  daa_reg := "01100110";
		end if;
	 end if;
  end if;

  case alu_ctrl is
  	 when alu_add8  | alu_adc | alu_inc |
  	      alu_add16 | alu_inc16 =>
		out_alu <= left + right + ("000000000000000" & carry_in);
  	 when alu_sub8  | alu_sbc | alu_dec |
  	      alu_sub16 | alu_dec16 =>
	   out_alu <= left - right - ("000000000000000" & carry_in);
  	 when alu_and =>
	   out_alu   <= left and right; 	-- and/bit
  	 when alu_bclr =>
	   out_alu   <= left and (not right); 	-- bclr
  	 when alu_ora | alu_bset =>
	   out_alu   <= left or right; 	-- or
  	 when alu_eor =>
	   out_alu   <= left xor right; 	-- eor/xor
  	 when alu_lsl16 | alu_asl8 | alu_rol8 | alu_rol16 =>
	   out_alu   <= left(14 downto 0) & carry_in; 	-- rol8/rol16/asl8/lsl16
  	 when alu_lsr16 | alu_lsr8 =>
	   out_alu   <= carry_in & left(15 downto 1); 	-- lsr
  	 when alu_ror8 =>
	   out_alu   <= "00000000" & carry_in & left(7 downto 1); 	-- ror
  	 when alu_asr8 =>
	   out_alu   <= "00000000" & left(7) & left(7 downto 1); 	-- asr
  	 when alu_neg =>
	   out_alu   <= right - left; 	-- neg (right=0)
  	 when alu_com =>
	   out_alu   <= not left;
  	 when alu_clr | alu_ld8 | alu_ld16 =>
	   out_alu   <= right; 	         -- clr, ld
	 when alu_st8 | alu_st16 =>
	   out_alu   <= left;
	 when alu_daa =>
	   out_alu   <= left + ("00000000" & daa_reg);
	 when alu_tpa =>
	   out_alu <= "00000000" & cc;
  	 when others =>
	   out_alu   <= left; -- nop
    end case;

	 --
	 -- carry bit
	 --
    case alu_ctrl is
  	 when alu_add8 | alu_adc  =>
      cc_out(CBIT) <= (left(7) and right(7)) or
		                (left(7) and not out_alu(7)) or
						   (right(7) and not out_alu(7));
  	 when alu_sub8 | alu_sbc =>
      cc_out(CBIT) <= ((not left(7)) and right(7)) or
		                ((not left(7)) and out_alu(7)) or
						         (right(7) and out_alu(7));
  	 when alu_add16  =>
      cc_out(CBIT) <= (left(15) and right(15)) or
		                (left(15) and not out_alu(15)) or
						   (right(15) and not out_alu(15));
  	 when alu_sub16 =>
      cc_out(CBIT) <= ((not left(15)) and right(15)) or
		                ((not left(15)) and out_alu(15)) or
						         (right(15) and out_alu(15));
	 when alu_ror8 | alu_lsr16 | alu_lsr8 | alu_asr8 =>
	   cc_out(CBIT) <= left(0);
	 when alu_rol8 | alu_asl8 =>
	   cc_out(CBIT) <= left(7);
	 when alu_lsl16 | alu_rol16 =>
	   cc_out(CBIT) <= left(15);
	 when alu_com =>
	   cc_out(CBIT) <= '1';
	 when alu_neg | alu_clr =>
	   cc_out(CBIT) <= out_alu(7) or out_alu(6) or out_alu(5) or out_alu(4) or
		                out_alu(3) or out_alu(2) or out_alu(1) or out_alu(0); 
    when alu_daa =>
	   if ( daa_reg(7 downto 4) = "0110" ) then
		  cc_out(CBIT) <= '1';
		else
		  cc_out(CBIT) <= '0';
	   end if;
  	 when alu_sec =>
      cc_out(CBIT) <= '1';
  	 when alu_clc =>
      cc_out(CBIT) <= '0';
    when alu_tap =>
      cc_out(CBIT) <= left(CBIT);
  	 when others => -- carry is not affected by cpx
      cc_out(CBIT) <= cc(CBIT);
    end case;
	 --
	 -- Zero flag
	 --
    case alu_ctrl is
  	 when alu_add8 | alu_sub8 |
	      alu_adc | alu_sbc |
  	      alu_and | alu_ora | alu_eor |
  	      alu_inc | alu_dec | 
			alu_neg | alu_com | alu_clr |
			alu_rol8 | alu_ror8 | alu_asr8 | alu_asl8 | alu_lsr8 |
		   alu_ld8  | alu_st8 |
			alu_bset | alu_bclr =>
      cc_out(ZBIT) <= not( out_alu(7)  or out_alu(6)  or out_alu(5)  or out_alu(4)  or
	                        out_alu(3)  or out_alu(2)  or out_alu(1)  or out_alu(0) );
  	 when alu_add16 | alu_sub16 |
  	      alu_lsl16 | alu_lsr16 |
  	      alu_inc16 | alu_dec16 |
		   alu_ld16  | alu_st16  =>
      cc_out(ZBIT) <= not( out_alu(15) or out_alu(14) or out_alu(13) or out_alu(12) or
	                        out_alu(11) or out_alu(10) or out_alu(9)  or out_alu(8)  or
  	                        out_alu(7)  or out_alu(6)  or out_alu(5)  or out_alu(4)  or
	                        out_alu(3)  or out_alu(2)  or out_alu(1)  or out_alu(0) );
    when alu_tap =>
      cc_out(ZBIT) <= left(ZBIT);
  	 when others =>
      cc_out(ZBIT) <= cc(ZBIT);
    end case;

    --
	 -- negative flag
	 --
    case alu_ctrl is
  	 when alu_add8 | alu_sub8 |
	      alu_adc | alu_sbc |
	      alu_and | alu_ora | alu_eor |
  	      alu_rol8 | alu_ror8 | alu_asr8 | alu_asl8 | alu_lsr8 |
  	      alu_inc | alu_dec | alu_neg | alu_com | alu_clr |
			alu_ld8  | alu_st8 |
			alu_bset | alu_bclr =>
      cc_out(NBIT) <= out_alu(7);
	 when alu_add16 | alu_sub16 |
	      alu_lsl16 | alu_lsr16 |
			alu_ld16 | alu_st16 =>
		cc_out(NBIT) <= out_alu(15);
    when alu_tap =>
      cc_out(NBIT) <= left(NBIT);
  	 when others =>
      cc_out(NBIT) <= cc(NBIT);
    end case;

    --
	 -- Interrupt mask flag
    --
    case alu_ctrl is
  	 when alu_sei =>
		cc_out(IBIT) <= '1';               -- set interrupt mask
  	 when alu_cli =>
		cc_out(IBIT) <= '0';               -- clear interrupt mask
	 when alu_tap =>
      cc_out(IBIT) <= left(IBIT);
  	 when others =>
		cc_out(IBIT) <= cc(IBIT);             -- interrupt mask
    end case;

    --
    -- Half Carry flag
	 --
    case alu_ctrl is
  	 when alu_add8 | alu_adc =>
      cc_out(HBIT) <= (left(3) and right(3)) or
                     (right(3) and not out_alu(3)) or 
                      (left(3) and not out_alu(3));
    when alu_tap =>
      cc_out(HBIT) <= left(HBIT);
  	 when others =>
		cc_out(HBIT) <= cc(HBIT);
    end case;

    --
    -- Overflow flag
	 --
    case alu_ctrl is
  	 when alu_add8 | alu_adc =>
      cc_out(VBIT) <= (left(7)  and      right(7)  and (not out_alu(7))) or
                 ((not left(7)) and (not right(7)) and      out_alu(7));
	 when alu_sub8 | alu_sbc =>
      cc_out(VBIT) <= (left(7)  and (not right(7)) and (not out_alu(7))) or
                 ((not left(7)) and      right(7)  and      out_alu(7));
  	 when alu_add16 =>
      cc_out(VBIT) <= (left(15)  and      right(15)  and (not out_alu(15))) or
                 ((not left(15)) and (not right(15)) and      out_alu(15));
	 when alu_sub16 =>
      cc_out(VBIT) <= (left(15)  and (not right(15)) and (not out_alu(15))) or
                 ((not left(15)) and      right(15) and       out_alu(15));
	 when alu_inc =>
	   cc_out(VBIT) <= ((not left(7)) and left(6) and left(5) and left(4) and
		                      left(3)  and left(2) and left(1) and left(0));
	 when alu_dec | alu_neg =>
	   cc_out(VBIT) <= (left(7)  and (not left(6)) and (not left(5)) and (not left(4)) and
		            (not left(3)) and (not left(2)) and (not left(1)) and (not left(0)));
	 when alu_asr8 =>
	   cc_out(VBIT) <= left(0) xor left(7);
	 when alu_lsr8 | alu_lsr16 =>
	   cc_out(VBIT) <= left(0);
	 when alu_ror8 =>
      cc_out(VBIT) <= left(0) xor cc(CBIT);
    when alu_lsl16 =>
      cc_out(VBIT) <= left(15) xor left(14);
	 when alu_rol8 | alu_asl8  =>
      cc_out(VBIT) <= left(7) xor left(6);
    when alu_tap =>
      cc_out(VBIT) <= left(VBIT);
	 when alu_and | alu_ora | alu_eor | alu_com |
	      alu_st8 | alu_st16 | alu_ld8 | alu_ld16 |
			alu_bset | alu_bclr |
		   alu_clv =>
      cc_out(VBIT) <= '0';
    when alu_sev =>
	   cc_out(VBIT) <= '1';
  	 when others =>
		cc_out(VBIT) <= cc(VBIT);
    end case;

	 case alu_ctrl is
  	 when alu_sex =>
		cc_out(XBIT) <= '1';               -- set interrupt mask
  	 when alu_clx =>
		cc_out(XBIT) <= '0';               -- clear interrupt mask
	 when alu_tap =>
      cc_out(XBIT) <= cc(XBIT) and left(XBIT);
	 when others =>
      cc_out(XBIT) <= cc(XBIT) and left(XBIT);
	 end case;

	 case alu_ctrl is
	 when alu_tap =>
      cc_out(SBIT) <= left(SBIT);
	 when others =>
	   cc_out(SBIT) <= cc(SBIT);
	 end case;
end process;


------------------------------------
--
-- state sequencer
--
------------------------------------
state_logic: process( state, op_code, pre_byte, cc, ea, md, irq, xirq,
						irq_ext3, irq_ext2, irq_ext1, irq_ext0, ea_bit, count )
  	begin
		  case state is
          when reset_state =>        --  released from reset
			    -- reset the registers
             op_ctrl    <= reset_op;
             pre_ctrl   <= reset_pre;
				 acca_ctrl  <= reset_acca;
				 accb_ctrl  <= reset_accb;
				 ix_ctrl    <= reset_ix;
				 iy_ctrl    <= reset_iy;
		       sp_ctrl    <= reset_sp;
		       pc_ctrl    <= reset_pc;
	 		    ea_ctrl    <= reset_ea;
				 md_ctrl    <= reset_md;
				 iv_ctrl    <= reset_iv;
				 sp_ctrl    <= reset_sp;
				 count_ctrl <= reset_count;
				 -- idle the ALU
             left_ctrl  <= pc_left;
				 right_ctrl <= zero_right;
				 alu_ctrl   <= alu_nop;
             cc_ctrl    <= reset_cc;
				 -- idle the bus
				 dout_ctrl  <= md_lo_dout;
             addr_ctrl  <= idle_ad;
	 	       next_state <= vect_hi_state;

			 --
			 -- Jump via interrupt vector
			 -- iv holds interrupt type
			 -- fetch PC hi from vector location
			 --
          when vect_hi_state =>
			    -- default the registers
             op_ctrl    <= latch_op;
             pre_ctrl   <= latch_pre;
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             md_ctrl    <= latch_md;
             ea_ctrl    <= latch_ea;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
				 -- idle the ALU
             left_ctrl  <= pc_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
				 -- fetch pc low interrupt vector
		       pc_ctrl    <= pull_hi_pc;
             addr_ctrl  <= int_hi_ad;
             dout_ctrl  <= pc_hi_dout;
	 	       next_state <= vect_lo_state;
			 --
			 -- jump via interrupt vector
			 -- iv holds vector type
			 -- fetch PC lo from vector location
			 --
          when vect_lo_state =>
			    -- default the registers
             op_ctrl    <= latch_op;
             pre_ctrl   <= latch_pre;
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             md_ctrl    <= latch_md;
             ea_ctrl    <= latch_ea;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
				 -- idle the ALU
             left_ctrl  <= pc_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
				 -- fetch the vector low byte
		       pc_ctrl    <= pull_lo_pc;
             addr_ctrl  <= int_lo_ad;
             dout_ctrl  <= pc_lo_dout;
	 	       next_state <= fetch_state;

			 --
			 -- Here to fetch an instruction
			 -- PC points to opcode
			 -- Should service interrupt requests at this point
			 -- either from the timer
			 -- or from the external input.
			 --
           when fetch_state =>
			      case op_code(7 downto 4) is
					when "0000" | -- inherent operators
					     "0001" | -- bit operators come here				        
	                 "0010" | -- branch conditional
	                 "0011" | -- stack operators
	                 "0100" | -- acca single operand
	                 "0101" | -- accb single operand
	                 "0110" | -- indexed single op
	                 "0111" => -- extended single op
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
					  -- idle ALU
                 left_ctrl  <= acca_left;
					  right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  cc_ctrl    <= latch_cc;
	            when "1000" | -- acca immediate
	                 "1001" | -- acca direct
	                 "1010" | -- acca indexed
                    "1011" => -- acca extended
				     case op_code(3 downto 0) is
					  when "0000" => -- suba
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0001" => -- cmpa
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0010" => -- sbca
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sbc;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0011" => -- subd / cmpd
					    left_ctrl   <= accd_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub16;
						 cc_ctrl     <= load_cc;
						 if (pre_byte = "00011010") or (pre_byte = "11001101") then
						   -- CPD
					      acca_ctrl   <= latch_acca;
						   accb_ctrl   <= latch_accb;
						 else
						   -- SUBD
					      acca_ctrl   <= load_hi_acca;
						   accb_ctrl   <= load_accb;
						 end if;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0100" => -- anda
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_and;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0101" => -- bita
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_and;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0110" => -- ldaa
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ld8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0111" => -- staa
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_st8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1000" => -- eora
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_eor;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1001" => -- adca
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_adc;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1010" => -- oraa
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ora;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1011" => -- adda
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_add8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1100" => -- cpx / cpy
					    if (pre_byte = "00011000") or (pre_byte = "00011010") then
							-- cpy
						   left_ctrl   <= iy_left;
						 else
						   -- cpx
					      left_ctrl   <= ix_left;
						 end if;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1101" => -- bsr / jsr
					    left_ctrl   <= pc_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_nop;
						 cc_ctrl     <= latch_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1110" => -- lds
					    left_ctrl   <= sp_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ld16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
						 sp_ctrl     <= load_sp;
					  when "1111" => -- sts / xgdx / xgdy
						 if op_code(7 downto 4) = "1000" then
				         --
			 	         -- exchange registers
				         -- at this point md holds accd
				         -- accd holds either X or Y
				         -- now transfer md to X or Y
				         --
					      left_ctrl  <= md_left;
                     right_ctrl <= zero_right;
                     alu_ctrl   <= alu_st16;
                     cc_ctrl    <= latch_cc;
                     acca_ctrl  <= latch_acca;
                     accb_ctrl  <= latch_accb;
                     sp_ctrl    <= latch_sp;
					      if pre_byte = "00011000" then
                       ix_ctrl    <= latch_ix;
                       iy_ctrl    <= load_iy;
					      else
                       ix_ctrl    <= load_ix;
                       iy_ctrl    <= latch_iy;
					      end if;
                   else
						   -- sts
					      left_ctrl   <= sp_left;
					      right_ctrl  <= md_right;
					      alu_ctrl    <= alu_st16;
						   cc_ctrl     <= load_cc;
					      acca_ctrl   <= latch_acca;
                     accb_ctrl   <= latch_accb;
                     ix_ctrl     <= latch_ix;
                     iy_ctrl     <= latch_iy;
                     sp_ctrl     <= latch_sp;
                   end if;
					  when others =>
					    left_ctrl   <= acca_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_nop;
						 cc_ctrl     <= latch_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  end case;
	            when "1100" | -- accb immediate
	                 "1101" | -- accb direct
	                 "1110" | -- accb indexed
                    "1111" => -- accb extended
				     case op_code(3 downto 0) is
					  when "0000" => -- subb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0001" => -- cmpb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sub8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0010" => -- sbcb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_sbc;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0011" => -- addd
					    left_ctrl   <= accd_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_add16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_hi_acca;
						 accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0100" => -- andb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_and;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0101" => -- bitb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_and;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0110" => -- ldab
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ld8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "0111" => -- stab
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_st8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1000" => -- eorb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_eor;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1001" => -- adcb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_adc;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1010" => -- orab
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ora;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1011" => -- addb
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_add8;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1100" => -- ldd
					    left_ctrl   <= accd_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ld16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= load_hi_acca;
                   accb_ctrl   <= load_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1101" => -- std
					    left_ctrl   <= accd_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_st16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when "1110" => -- ldx / ldy
					    if ((pre_byte = "00011000") or (pre_byte = "00011010"))  then
						   -- LDY
					      left_ctrl   <= iy_left;
                     ix_ctrl     <= latch_ix;
                     iy_ctrl     <= load_iy;
                   else
						   -- LDX
					      left_ctrl   <= ix_left;
                     ix_ctrl     <= load_ix;
                     iy_ctrl     <= latch_iy;
						 end if;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_ld16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
						 sp_ctrl     <= latch_sp;
					  when "1111" => -- stx / sty
					    if ((pre_byte = "00011000") or (pre_byte = "00011010"))  then
                     -- STY
					      left_ctrl   <= iy_left;
                   else
						   -- STX
					      left_ctrl   <= ix_left;
						 end if;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_st16;
						 cc_ctrl     <= load_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  when others =>
					    left_ctrl   <= accb_left;
					    right_ctrl  <= md_right;
					    alu_ctrl    <= alu_nop;
						 cc_ctrl     <= latch_cc;
					    acca_ctrl   <= latch_acca;
                   accb_ctrl   <= latch_accb;
                   ix_ctrl     <= latch_ix;
                   iy_ctrl     <= latch_iy;
                   sp_ctrl     <= latch_sp;
					  end case;
	            when others =>
					  left_ctrl   <= accd_left;
					  right_ctrl  <= md_right;
					  alu_ctrl    <= alu_nop;
					  cc_ctrl     <= latch_cc;
					  acca_ctrl   <= latch_acca;
                 accb_ctrl   <= latch_accb;
                 ix_ctrl     <= latch_ix;
                 iy_ctrl     <= latch_iy;
                 sp_ctrl     <= latch_sp;
               end case;
               ea_ctrl    <= reset_ea;
               md_ctrl    <= latch_md;
				   count_ctrl <= reset_count;
				   -- fetch the op code
			      op_ctrl    <= fetch_op;
               pre_ctrl   <= fetch_pre;
               addr_ctrl  <= fetch_ad;
               dout_ctrl  <= md_lo_dout;
		  	      iv_ctrl    <= latch_iv;
				   -- service non maskable interrupts
			      if (xirq = '1') and (cc(XBIT) = '0') then
                 pc_ctrl    <= latch_pc;
			        next_state <= int_pcl_state;
				   -- service maskable interrupts
			      else
					--
					-- IRQ is level sensitive
					--
				     if (irq = '1') and (cc(IBIT) = '0') then
                   pc_ctrl    <= latch_pc;
			          next_state <= int_pcl_state;
                 else
				     -- Advance the PC to fetch next instruction byte
                   pc_ctrl    <= incr_pc;
			          next_state <= decode_state;
                 end if;
				   end if;
			 --
			 -- Here to decode instruction
			 -- and fetch next byte of intruction
			 -- whether it be necessary or not
			 --
          when decode_state =>
				 -- fetch first byte of address or immediate data
             addr_ctrl  <= fetch_ad;
             dout_ctrl  <= md_lo_dout;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
             pre_ctrl   <= latch_pre;
			    case op_code(7 downto 4) is
				 when "0000" =>
				   md_ctrl    <= reset_md;
               sp_ctrl    <= latch_sp;
               pc_ctrl    <= latch_pc;
			      op_ctrl    <= latch_op;
  	            case op_code(3 downto 0) is
		         when "0000" => -- test -- spin PC
					  left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 ea_ctrl    <= reset_ea;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
					  next_state <= spin_state;
		         when "0001" => -- nop
					  left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 ea_ctrl    <= reset_ea;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
					  next_state <= fetch_state;
		         when "0010" => -- idiv
					  -- transfer IX to ea
                 left_ctrl  <= ix_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 ea_ctrl    <= load_ea;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
					  next_state <= idiv_state;
		         when "0011" => -- fdiv
                 left_ctrl  <= ix_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 ea_ctrl    <= load_ea;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= reset_ix;
					  iy_ctrl    <= latch_iy;
					  next_state <= div1_state;
		         when "0100" => -- lsrd
					  left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_lsr16;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_hi_acca;
					  accb_ctrl  <= load_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "0101" => -- lsld
					  left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_lsl16;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_hi_acca;
					  accb_ctrl  <= load_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "0110" => -- tap
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_tap;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "0111" => -- tpa
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_tpa;
                 cc_ctrl    <= latch_cc;
					  acca_ctrl  <= load_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1000" => -- inx / iny
					  if pre_byte = "00011000" then
					    -- iny
					    left_ctrl  <= iy_left;
					    ix_ctrl    <= latch_ix;
					    iy_ctrl    <= load_iy;
					  else
					    -- inx
					    left_ctrl  <= ix_left;
					    ix_ctrl    <= load_ix;
					    iy_ctrl    <= latch_iy;
					  end if;
                 ea_ctrl    <= reset_ea;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_inc16;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  next_state <= fetch_state;
		         when "1001" => -- dex / dey
					  if pre_byte = "00011000" then
					    -- dey
					    left_ctrl  <= iy_left;
					    ix_ctrl    <= latch_ix;
					    iy_ctrl    <= load_iy;
					  else
					    -- dex
					    left_ctrl  <= ix_left;
					    ix_ctrl    <= load_ix;
					    iy_ctrl    <= latch_iy;
					  end if;
                 ea_ctrl    <= reset_ea;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_dec16;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  next_state <= fetch_state;
		         when "1010" => -- clv
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_clv;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1011" => -- sev
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_sev;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1100" => -- clc
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_clc;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1101" => -- sec
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_sec;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1110" => -- cli
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_cli;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         when "1111" => -- sei
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_sei;
                 cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
               when others =>
					  left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= latch_accb;
					  ix_ctrl    <= latch_ix;
					  iy_ctrl    <= latch_iy;
                 ea_ctrl    <= reset_ea;
					  next_state <= fetch_state;
		         end case;
				 -- acca / accb inherent instructions
	          when "0001" =>
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
               ix_ctrl    <= latch_ix;
               iy_ctrl    <= latch_iy;
               sp_ctrl    <= latch_sp;
	            case op_code(3 downto 0) is
		         when "0000" => -- sba
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_sub8;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "0001" => -- cba
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_sub8;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "0010" => -- brset direct
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= read8_state;
		         when "0011" => -- brclr direct
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= read8_state;
		         when "0100" => -- bset direct
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= read8_state;
		         when "0101" => -- bclr direct
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= read8_state;
		         when "0110" => -- tab
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_st8;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= latch_acca;
					  accb_ctrl  <= load_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "0111" => -- tba
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_ld8;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "1000" => -- indexed y prebyte
			        op_ctrl    <= fetch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= decode_state;
		         when "1001" => -- daa
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_daa;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "1010" => -- prebyte - CPD / CPY / LDY / STY ff,X
			        op_ctrl    <= fetch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= decode_state;
		         when "1011" => -- aba
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_add8;
					  cc_ctrl    <= load_cc;
					  acca_ctrl  <= load_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         when "1100" => -- bset indexed
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= indexed_state;
		         when "1101" => -- bclr indexed
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= indexed_state;
		         when "1110" => -- brset indexed
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= indexed_state;
		         when "1111" => -- brclr indexed
			        op_ctrl    <= latch_op;
					  left_ctrl  <= pc_left;
	              right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= load_pc;
					  next_state <= indexed_state;
		         when others =>
			        op_ctrl    <= latch_op;
					  left_ctrl  <= acca_left;
	              right_ctrl <= accb_right;
					  alu_ctrl   <= alu_nop;
					  cc_ctrl    <= latch_cc;
					  acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
		         end case;
	          when "0010" => -- branch conditional
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
					acca_ctrl  <= latch_acca;
               accb_ctrl  <= latch_accb;
               ix_ctrl    <= latch_ix;
               iy_ctrl    <= latch_iy;
               sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
               case op_code(3 downto 0) is
		         when "0000" => -- bra
                 next_state <= branch_state;
		         when "0001" => -- brn
					  next_state <= fetch_state;
		         when "0010" => -- bhi
					  if (cc(CBIT) or cc(ZBIT)) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "0011" => -- bls
					  if (cc(CBIT) or cc(ZBIT)) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "0100" => -- bcc/bhs
					  if cc(CBIT) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "0101" => -- bcs/blo
					  if cc(CBIT) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "0110" => -- bne
					  if cc(ZBIT) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "0111" => -- beq
					  if cc(ZBIT) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1000" => -- bvc
					  if cc(VBIT) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1001" => -- bvs
					  if cc(VBIT) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1010" => -- bpl
					  if cc(NBIT) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1011" => -- bmi
					  if cc(NBIT) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1100" => -- bge
					  if (cc(NBIT) xor cc(VBIT)) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1101" => -- blt
					  if (cc(NBIT) xor cc(VBIT)) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1110" => -- bgt
					  if (cc(ZBIT) or (cc(NBIT) xor cc(VBIT))) = '0' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when "1111" => -- ble
					  if (cc(ZBIT) or (cc(NBIT) xor cc(VBIT))) = '1' then
					    next_state <= branch_state;
					  else
					    next_state <= fetch_state;
					  end if;
		         when others =>
					  next_state <= fetch_state;
		         end case;
				 --
				 -- Single byte stack operators
				 -- Do not advance PC
				 --
	          when "0011" =>
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
					acca_ctrl  <= latch_acca;
               accb_ctrl  <= latch_accb;
               pc_ctrl    <= latch_pc;
	            case op_code(3 downto 0) is
		         when "0000" => -- tsx / tsy
		            left_ctrl  <= sp_left;
		            right_ctrl <= one_right;
						alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
                  sp_ctrl    <= latch_sp;
					   if pre_byte = "00011000" then
						  -- tsy
					     ix_ctrl    <= latch_ix;
					     iy_ctrl    <= load_iy;
					   else
						  -- tsx
					     ix_ctrl    <= load_ix;
					     iy_ctrl    <= latch_iy;
					   end if;
						next_state <= fetch_state;
		         when "0001" => -- ins
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= fetch_state;
		         when "0010" => -- pula
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= pula_state;
		         when "0011" => -- pulb
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= pulb_state;
		         when "0100" => -- des
                  -- decrement sp
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_sub16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= fetch_state;
		         when "0101" => -- txs / tys
					   if pre_byte = "00011000" then
						  -- tys
					     left_ctrl  <= iy_left;
					   else
						  -- txs
					     left_ctrl  <= ix_left;
					   end if;
		            right_ctrl <= one_right;
						alu_ctrl   <= alu_sub16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
					   iy_ctrl    <= latch_iy;
						sp_ctrl    <= load_sp;
						next_state <= fetch_state;
		         when "0110" => -- psha
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= psha_state;
		         when "0111" => -- pshb
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= pshb_state;
		         when "1000" => -- pulxy
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= pulxy_hi_state;
		         when "1001" => -- rts
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
                  iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= rts_hi_state;
		         when "1010" => -- abx / aby
					   if pre_byte = "00011000" then
					     left_ctrl  <= iy_left;
						  ix_ctrl    <= latch_ix;
                    iy_ctrl    <= load_iy;
					   else
					     left_ctrl  <= ix_left;
						  ix_ctrl    <= load_ix;
                    iy_ctrl    <= latch_iy;
					   end if;
		            right_ctrl <= accb_right;
						alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
                  sp_ctrl    <= latch_sp;
						next_state <= fetch_state;
		         when "1011" => -- rti
                  left_ctrl  <= sp_left;
                  right_ctrl <= one_right;
                  alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
                  sp_ctrl    <= load_sp;
						next_state <= rti_cc_state;
		         when "1100" => -- pshxy
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= pshxy_lo_state;
		         when "1101" => -- mul
		            left_ctrl  <= acca_left;
		            right_ctrl <= accb_right;
						alu_ctrl   <= alu_add16;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= mul_state;
		         when "1110" => -- wai
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= int_pcl_state;
		         when "1111" => -- swi
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= int_pcl_state;
		         when others =>
		            left_ctrl  <= sp_left;
		            right_ctrl <= zero_right;
						alu_ctrl   <= alu_nop;
					   cc_ctrl    <= latch_cc;
						ix_ctrl    <= latch_ix;
						iy_ctrl    <= latch_iy;
						sp_ctrl    <= latch_sp;
						next_state <= fetch_state;
		         end case;
				 --
				 -- Accumulator A Single operand
				 -- source = Acc A dest = Acc A
				 -- Do not advance PC
				 --
	          when "0100" => -- acca single op
               ea_ctrl    <= latch_ea;
				   md_ctrl    <= latch_md;
				   op_ctrl    <= latch_op;
               accb_ctrl  <= latch_accb;
               pc_ctrl    <= latch_pc;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
		         left_ctrl  <= acca_left;
	            case op_code(3 downto 0) is
		         when "0000" => -- neg
					  right_ctrl <= zero_right;
					  alu_ctrl   <= alu_neg;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
 	            when "0011" => -- com
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_com;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "0100" => -- lsr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_lsr8;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "0110" => -- ror
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_ror8;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "0111" => -- asr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_asr8;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "1000" => -- asl
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_asl8;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "1001" => -- rol
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_rol8;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "1010" => -- dec
		           right_ctrl <= one_right;
					  alu_ctrl   <= alu_dec;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "1011" => -- undefined
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  acca_ctrl  <= latch_acca;
					  cc_ctrl    <= latch_cc;
		         when "1100" => -- inc
		           right_ctrl <= one_right;
					  alu_ctrl   <= alu_inc;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when "1101" => -- tst
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_st8;
					  acca_ctrl  <= latch_acca;
					  cc_ctrl    <= load_cc;
		         when "1110" => -- jmp
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  acca_ctrl  <= latch_acca;
					  cc_ctrl    <= latch_cc;
		         when "1111" => -- clr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_clr;
					  acca_ctrl  <= load_acca;
					  cc_ctrl    <= load_cc;
		         when others =>
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  acca_ctrl  <= latch_acca;
					  cc_ctrl    <= latch_cc;
		         end case;
				   next_state <= fetch_state;
				 --
				 -- single operand acc b
				 -- Do not advance PC
				 --
	          when "0101" =>
               ea_ctrl    <= latch_ea;
				   md_ctrl    <= latch_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
               pc_ctrl    <= latch_pc;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
		         left_ctrl  <= accb_left;
	            case op_code(3 downto 0) is
		         when "0000" => -- neg
					  right_ctrl <= zero_right;
					  alu_ctrl   <= alu_neg;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
 	            when "0011" => -- com
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_com;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "0100" => -- lsr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_lsr8;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "0110" => -- ror
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_ror8;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "0111" => -- asr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_asr8;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "1000" => -- asl
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_asl8;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "1001" => -- rol
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_rol8;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "1010" => -- dec
		           right_ctrl <= one_right;
					  alu_ctrl   <= alu_dec;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "1011" => -- undefined
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  accb_ctrl  <= latch_accb;
					  cc_ctrl    <= latch_cc;
		         when "1100" => -- inc
		           right_ctrl <= one_right;
					  alu_ctrl   <= alu_inc;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when "1101" => -- tst
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_st8;
					  accb_ctrl  <= latch_accb;
					  cc_ctrl    <= load_cc;
		         when "1110" => -- jmp
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  accb_ctrl  <= latch_accb;
					  cc_ctrl    <= latch_cc;
		         when "1111" => -- clr
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_clr;
					  accb_ctrl  <= load_accb;
					  cc_ctrl    <= load_cc;
		         when others =>
		           right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
					  accb_ctrl  <= latch_accb;
					  cc_ctrl    <= latch_cc;
		         end case;
				   next_state <= fetch_state;
				 --
				 -- Single operand indexed
				 -- Two byte instruction so advance PC
				 -- EA should hold index offset
				 --
	          when "0110" => -- indexed single op
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc 
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= indexed_state;
             --
				 -- Single operand extended addressing
				 -- three byte instruction so advance the PC
				 -- Low order EA holds high order address
				 --
	          when "0111" => -- extended single op
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= extended_state;

	          when "1000" => -- acca immediate
               ea_ctrl    <= fetch_first_ea;	-- for BSR
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					cc_ctrl    <= latch_cc;
					case op_code(3 downto 0) is
               when "0011" | -- subd #
					     "1100" | -- cpx / cpy #
					     "1110" => -- lds #
				     -- increment the pc
				     md_ctrl    <= fetch_first_md;
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 pc_ctrl    <= load_pc;
					  next_state <= immediate16_state;
					when "1101" => -- bsr
				     -- increment the pc
				     md_ctrl    <= fetch_first_md;
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 pc_ctrl    <= load_pc;
					  next_state <= bsr_state;
					when "1111" => -- egdx /egdy
					  -- idle pc
                 left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 pc_ctrl    <= latch_pc;
				     md_ctrl    <= load_md;
					  next_state <= exchange_state;
					when others =>
				     md_ctrl    <= fetch_first_md;
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 pc_ctrl    <= load_pc;
				     next_state <= fetch_state;
               end case;

	          when "1001" => -- acca direct
               ea_ctrl    <= fetch_first_ea;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               pc_ctrl    <= incr_pc;
					case op_code(3 downto 0) is
					when "0111" =>  -- staa direct
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st8;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
				     next_state <= write8_state;
					when "1111" => -- sts direct
                 left_ctrl  <= sp_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
				     next_state <= write16_state;
					when "1101" => -- jsr direct
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_nop;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= fetch_first_md;
					  next_state <= jsr_state;
					when others =>
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_nop;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= fetch_first_md;
				     next_state <= read8_state;
               end case;

	          when "1010" => -- acca indexed
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= indexed_state;

             when "1011" => -- acca extended
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= extended_state;

	          when "1100" => -- accb immediate
               ea_ctrl    <= latch_ea;
				   md_ctrl    <= fetch_first_md;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
					case op_code(3 downto 0) is
               when "0011" | -- addd #
					     "1100" | -- ldd #
					     "1110" => -- ldx # / ldy #
				     op_ctrl    <= latch_op;
					  next_state <= immediate16_state;
					when "1101" => -- indexed Y pre-byte $CD
				     op_ctrl    <= fetch_op;
					  next_state <= decode_state;
					when others =>
				     op_ctrl    <= latch_op;
				     next_state <= fetch_state;
               end case;

	          when "1101" => -- accb direct
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
               pc_ctrl    <= incr_pc;
					case op_code(3 downto 0) is
					when "0111" =>  -- stab direct
                 left_ctrl  <= accb_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st8;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
				     next_state <= write8_state;
					when "1101" => -- std direct
                 left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
					  next_state <= write16_state;
					when "1111" => -- stx / sty direct
					  if( pre_byte = "00011000" ) or (pre_byte = "00011010" ) then
					    left_ctrl  <= iy_left;
                 else
                   left_ctrl  <= ix_left;
                 end if;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
				     next_state <= write16_state;
					when others =>
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_nop;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= fetch_first_md;
				     next_state <= read8_state;
               end case;

	          when "1110" => -- accb indexed
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= indexed_state;

             when "1111" => -- accb extended
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- increment the pc
               left_ctrl  <= pc_left;
               right_ctrl <= one_right;
               alu_ctrl   <= alu_add16;
					cc_ctrl    <= latch_cc;
               pc_ctrl    <= load_pc;
				   next_state <= extended_state;

	          when others =>
               ea_ctrl    <= fetch_first_ea;
				   md_ctrl    <= fetch_first_md;
				   op_ctrl    <= latch_op;
               acca_ctrl  <= latch_acca;
					accb_ctrl  <= latch_accb;
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= latch_iy;
				   sp_ctrl    <= latch_sp;
					-- idle the pc
               left_ctrl  <= pc_left;
               right_ctrl <= zero_right;
               alu_ctrl   <= alu_nop;
  					cc_ctrl    <= latch_cc;
               pc_ctrl    <= latch_pc;
 		         next_state <= fetch_state;
             end case;

			  when immediate16_state =>
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
				 iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
				 pre_ctrl   <= latch_pre;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
             ea_ctrl    <= latch_ea;
				 -- increment pc
             left_ctrl  <= pc_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             pc_ctrl    <= load_pc;
				 -- fetch next immediate byte
			    md_ctrl    <= fetch_next_md;
             addr_ctrl  <= fetch_ad;
             dout_ctrl  <= md_lo_dout;
				 next_state <= fetch_state;
           --
			  -- ea holds 8 bit index offet
			  -- calculate the effective memory address
			  -- using the alu
			  --
           when indexed_state =>
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
				 ix_ctrl    <= latch_ix;
			    iy_ctrl    <= latch_iy;
				 -- idle bus.
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= md_lo_dout;
				 -- add 8 bit ea to ix or iy
				 if(( pre_byte = "00011000") or (pre_byte = "11001101")) then
				   ea_ctrl    <= add_iy_ea;
				 else
				   ea_ctrl    <= add_ix_ea;
				 end if;
				 case op_code(7 downto 4) is
				 when "0001" => -- BSET, BCLR, BRSET, BRCLR
			      left_ctrl  <= acca_left;
				   right_ctrl <= zero_right;
				   alu_ctrl   <= alu_nop;
               cc_ctrl    <= latch_cc;
               md_ctrl    <= latch_md;
	            case op_code(3 downto 0) is
					when "1100" |  -- BSET
				   	  "1101" |  -- BCLR
						  "1110" |  -- BRSET
						  "1111" => -- BRCLR
                 next_state <= read8_state;
               when others =>
					  next_state <= fetch_state;
               end case;
				 when "0110" => -- single op indexed
	            case op_code(3 downto 0) is
		         when "1011" => -- undefined
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= fetch_state;
		         when "1110" => -- jmp
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= jmp_state;
					when "1111" => -- clr
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
--				     alu_ctrl   <= alu_st8;
				     alu_ctrl   <= alu_clr;	-- 13 Jan 2004 /sashz
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
					  next_state <= write8_state;
		         when others =>
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= read8_state;
		         end case;
	          when "1010" => -- acca indexed
				   case op_code(3 downto 0) is
					when "0111" =>  -- staa
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_st8;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
				     next_state <= write8_state;
					when "1101" => -- jsr
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= jsr_state;
					when "1111" => -- sts
			        left_ctrl  <= sp_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
				     next_state <= write16_state;
					when others =>
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= read8_state;
					end case;
	          when "1110" => -- accb indexed
				   case op_code(3 downto 0) is
					when "0111" =>  -- stab direct
			        left_ctrl  <= accb_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_st8;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
				     next_state <= write8_state;
					when "1101" => -- std direct
			        left_ctrl  <= accd_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
					  next_state <= write16_state;
					when "1111" => -- stx / sty direct
					  if( pre_byte = "00011000" ) or (pre_byte = "00011010" ) then
					    left_ctrl  <= iy_left;
                 else
                   left_ctrl  <= ix_left;
                 end if;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
					  cc_ctrl    <= latch_cc;
				     md_ctrl    <= load_md;
				     next_state <= write16_state;
					when others =>
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= latch_md;
					  next_state <= read8_state;
					end case;
			    when others =>
			      left_ctrl  <= acca_left;
				   right_ctrl <= zero_right;
				   alu_ctrl   <= alu_nop;
               cc_ctrl    <= latch_cc;
               md_ctrl    <= latch_md;
					next_state <= fetch_state;
			    end case;
           --
			  -- ea holds 8 bit index offet
			  -- calculate the effective memory address
			  -- using the alu
			  --
           --
			  -- ea holds the low byte of the absolute address
			  -- Move ea low byte into ea high byte
			  -- load new ea low byte to for absolute 16 bit address
			  -- advance the program counter
			  --
			  when extended_state => -- fetch ea low byte
               acca_ctrl  <= latch_acca;
               accb_ctrl  <= latch_accb;
               ix_ctrl    <= latch_ix;
               iy_ctrl    <= latch_iy;
               sp_ctrl    <= latch_sp;
               iv_ctrl    <= latch_iv;
				   count_ctrl <= reset_count;
			      op_ctrl    <= latch_op;
				   pre_ctrl   <= latch_pre;
					-- increment pc
               pc_ctrl    <= incr_pc;
					-- fetch next effective address bytes
					ea_ctrl    <= fetch_next_ea;
               addr_ctrl  <= fetch_ad;
					dout_ctrl  <= md_lo_dout;
					-- work out the next state
				   case op_code(7 downto 4) is
				   when "0111" => -- single op extended
	              case op_code(3 downto 0) is
		           when "1011" => -- undefined
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= fetch_state;
		           when "1110" => -- jmp
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= jmp_state;
		           when "1111" => -- clr
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
--				       alu_ctrl   <= alu_ld8;
				       alu_ctrl   <= alu_clr;		-- 13 Jan 2004 /sashz
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
					    next_state <= write8_state;
		           when others =>
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= read8_state;
		           end case;
	            when "1011" => -- acca extended
				     case op_code(3 downto 0) is
					  when "0111" =>  -- staa
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_st8;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
				       next_state <= write8_state;
					  when "1101" => -- jsr
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= jsr_state;
					  when "1111" => -- sts
			          left_ctrl  <= sp_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_st16;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
				       next_state <= write16_state;
					  when others =>
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= read8_state;
					  end case;
	            when "1111" => -- accb extended
				     case op_code(3 downto 0) is
					  when "0111" =>  -- stab
			          left_ctrl  <= accb_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_st8;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
				       next_state <= write8_state;
					  when "1101" => -- std
			          left_ctrl  <= accd_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_st16;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
					    next_state <= write16_state;
					  when "1111" => -- stx / sty
					    if(( pre_byte = "00011000" ) or ( pre_byte = "00011010" )) then
					      left_ctrl <= iy_left;
					    else
			            left_ctrl <= ix_left;
					    end if;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_st16;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= load_md;
				       next_state <= write16_state;
					  when others =>
			          left_ctrl  <= acca_left;
				       right_ctrl <= zero_right;
				       alu_ctrl   <= alu_nop;
                   cc_ctrl    <= latch_cc;
                   md_ctrl    <= latch_md;
					    next_state <= read8_state;
					  end case;
			      when others =>
                 md_ctrl    <= latch_md;
			        left_ctrl  <= acca_left;
				     right_ctrl <= zero_right;
				     alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
					  next_state <= fetch_state;
			      end case;
           --
			  -- here if ea holds low byte (direct page)
			  -- can enter here from extended addressing
			  -- read memory location
			  -- note that reads may be 8 or 16 bits
			  --
			  when read8_state => -- read data
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
				 -- read first data byte from ea
				 md_ctrl    <= fetch_first_md;
             addr_ctrl  <= read_ad;
				 dout_ctrl  <= md_lo_dout;
			    case op_code(7 downto 4) is
				   when "0001" => -- bset / bclr / brset / brclr
 					  left_ctrl  <= pc_left;
					  right_ctrl <= one_right;
					  alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
					  ea_ctrl    <= latch_ea;
                 pc_ctrl    <= load_pc;
					  next_state <= bitmask_state;
					when "0110" | "0111" => -- single operand
 					  left_ctrl  <= ea_left;
					  right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
					  ea_ctrl    <= latch_ea;
                 pc_ctrl    <= latch_pc;
					  next_state <= execute_state;
	            when "1001" | "1010" | "1011" => -- acca
                 pc_ctrl    <= latch_pc;
				     case op_code(3 downto 0) is
					    when "0011" |  -- subd / cpd
					         "1110" |  -- lds
					         "1100" => -- cpx / cpy
				         -- increment the effective address in case of 16 bit load
 					      left_ctrl  <= ea_left;
					      right_ctrl <= one_right;
					      alu_ctrl   <= alu_add16;
                     cc_ctrl    <= latch_cc;
					      ea_ctrl    <= load_ea;
					      next_state <= read16_state;
					    when others =>
 					      left_ctrl  <= ea_left;
					      right_ctrl <= zero_right;
					      alu_ctrl   <= alu_nop;
                     cc_ctrl    <= latch_cc;
					      ea_ctrl    <= latch_ea;
					      next_state <= fetch_state;
					  end case;
	            when "1101" | "1110" | "1111" => -- accb
                 pc_ctrl    <= latch_pc;
				     case op_code(3 downto 0) is
					    when "0011" |  -- addd
					         "1100" |  -- ldd
					         "1110" => -- ldx / ldy
				         -- increment the effective address in case of 16 bit load
 					      left_ctrl  <= ea_left;
					      right_ctrl <= one_right;
					      alu_ctrl   <= alu_add16;
                     cc_ctrl    <= latch_cc;
					      ea_ctrl    <= load_ea;
					      next_state <= read16_state;
					    when others =>
 					      left_ctrl  <= ea_left;
					      right_ctrl <= zero_right;
					      alu_ctrl   <= alu_nop;
                     cc_ctrl    <= latch_cc;
					      ea_ctrl    <= latch_ea;
					      next_state <= fetch_state;
					  end case;
					when others =>
 					  left_ctrl  <= ea_left;
					  right_ctrl <= zero_right;
					  alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
					  ea_ctrl    <= latch_ea;
                 pc_ctrl    <= latch_pc;
					  next_state <= fetch_state;
			    end case;

			  when read16_state => -- read second data byte from ea
                 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
			    -- idle the effective address
             left_ctrl  <= ea_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
             ea_ctrl    <= latch_ea;
			    -- read the low byte of the 16 bit data
				 md_ctrl    <= fetch_next_md;
             addr_ctrl  <= read_ad;
             dout_ctrl  <= md_lo_dout;
			    next_state <= fetch_state;

			  --
			  -- exchange registers
			  -- at this point md holds accd
			  -- transfer X or Y to accd
			  --
			  when exchange_state => -- md holds accd
             -- default
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 md_ctrl    <= latch_md;
			    -- transfer x or y to accd
			    if pre_byte = "00011000" then
					left_ctrl  <= iy_left;
				 else
               left_ctrl  <= ix_left;
			    end if;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_st16;
             cc_ctrl    <= latch_cc;
             acca_ctrl  <= load_hi_acca;
             accb_ctrl  <= load_accb;
			    -- idle the address bus
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= md_lo_dout;
			    next_state <= fetch_state;

			   when bitmask_state => -- fetch bit mask from next op
                 -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 ea_ctrl    <= latch_ea;
				     md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
					  -- addvance the pc
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
                 pc_ctrl    <= load_pc;
					  -- read the bit mask into the pre byte register
				     pre_ctrl   <= fetch_pre;
                 addr_ctrl  <= fetch_ad;
                 dout_ctrl  <= md_lo_dout;
					  case op_code is
					  when "00010010" | "00011110" => -- brset
					    next_state <= brset_state;
					  when "00010011" | "00011111" => -- brclr
					    next_state <= brclr_state;
					  when "00010100" | "00011100" => -- bset
						 next_state <= execute_state;
					  when "00010101" | "00011101" => -- bclr
						 next_state <= execute_state;
					  when others =>
					    next_state <= fetch_state;
					  end case;

			   when brclr_state => -- fetch the branch offset
                 -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
				     md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
					  -- advance the pc
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
                 pc_ctrl    <= load_pc;
					  -- fetch the branch offset
                 addr_ctrl  <= fetch_ad;
                 ea_ctrl    <= fetch_first_ea;
                 dout_ctrl  <= md_lo_dout;
					  if (pre_byte and md(7 downto 0) ) = "00000000" then
						   next_state <= branch_state;
					  else
						   next_state <= fetch_state;
					  end if;

			   when brset_state => -- fetch the branch offset
                 -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
				     md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
					  -- advance the pc
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
                 pc_ctrl    <= load_pc;
					  -- fetch the branch offset
                 addr_ctrl  <= fetch_ad;
                 ea_ctrl    <= fetch_first_ea;
                 dout_ctrl  <= md_lo_dout;
					  if (pre_byte and md(7 downto 0) ) = "00000000" then
						   next_state <= fetch_state;
					  else
						   next_state <= branch_state;
					  end if;


				when jmp_state =>
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- load PC with effective address
                 left_ctrl  <= pc_left;
					  right_ctrl <= ea_right;
				     alu_ctrl   <= alu_ld16;
                 cc_ctrl    <= latch_cc;
					  pc_ctrl    <= load_pc;
					  -- idle the bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
                 next_state <= fetch_state;

				when jsr_state => -- JSR
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 -- decrement sp
                 left_ctrl  <= sp_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_sub16;
                 cc_ctrl    <= latch_cc;
                 sp_ctrl    <= load_sp;
					  -- write pc low
                 addr_ctrl  <= push_ad;
					  dout_ctrl  <= pc_lo_dout; 
                 next_state <= jsr1_state;

				when jsr1_state => -- JSR
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 pc_ctrl    <= latch_pc;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 -- decrement sp
                 left_ctrl  <= sp_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_sub16;
                 cc_ctrl    <= latch_cc;
                 sp_ctrl    <= load_sp;
					  -- write pc hi
                 addr_ctrl  <= push_ad;
					  dout_ctrl  <= pc_hi_dout; 
                 next_state <= jmp_state;

				when branch_state => -- Bcc
				     -- default registers
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- calculate signed branch
					  left_ctrl  <= pc_left;
					  right_ctrl <= sexea_right; -- right must be sign extended effective address
				     alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
					  pc_ctrl    <= load_pc;
					  -- idle the bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
                 next_state <= fetch_state;

				when bsr_state => -- BSR
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 pc_ctrl    <= latch_pc;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 -- decrement sp
                 left_ctrl  <= sp_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_sub16;
                 cc_ctrl    <= latch_cc;
                 sp_ctrl    <= load_sp;
					  -- write pc low
                 addr_ctrl  <= push_ad;
					  dout_ctrl  <= pc_lo_dout; 
                 next_state <= bsr1_state;

				when bsr1_state => -- BSR
				     -- default registers
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 pc_ctrl    <= latch_pc;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 -- decrement sp
                 left_ctrl  <= sp_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_sub16;
                 cc_ctrl    <= latch_cc;
                 sp_ctrl    <= load_sp;
					  -- write pc hi
                 addr_ctrl  <= push_ad;
					  dout_ctrl  <= pc_hi_dout; 
                 next_state <= branch_state;

				 when rts_hi_state => -- RTS
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 pc_ctrl    <= latch_pc;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- increment the sp
                 left_ctrl  <= sp_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 cc_ctrl    <= latch_cc;
                 sp_ctrl    <= load_sp;
                 -- read pc hi
					  pc_ctrl    <= pull_hi_pc;
                 addr_ctrl  <= pull_ad;
                 dout_ctrl  <= pc_hi_dout;
                 next_state <= rts_lo_state;

				when rts_lo_state => -- RTS1
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 md_ctrl    <= latch_md;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- idle the ALU
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_nop;
                 cc_ctrl    <= latch_cc;
					  -- read pc low
					  pc_ctrl    <= pull_lo_pc;
                 addr_ctrl  <= pull_ad;
                 dout_ctrl  <= pc_lo_dout;
                 next_state <= fetch_state;

				 when mul_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- move acca to md
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 md_ctrl    <= load_md;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= mulea_state;

				 when mulea_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 md_ctrl    <= latch_md;
					  -- move accb to ea
                 left_ctrl  <= accb_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 cc_ctrl    <= latch_cc;
                 ea_ctrl    <= load_ea;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= muld_state;

				 when muld_state =>
				     -- default
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- clear accd
                 left_ctrl  <= acca_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_ld8;
                 cc_ctrl    <= latch_cc;
                 acca_ctrl  <= load_hi_acca;
                 accb_ctrl  <= load_accb;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= mul0_state;

				 when mul0_state =>
				     -- default
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= inc_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- if ea bit(count) set, add accd to md
                 left_ctrl  <= accd_left;
                 right_ctrl <= md_right;
                 alu_ctrl   <= alu_add16;
					  if ea_bit = '1' then
                   cc_ctrl    <= load_cc;
                   acca_ctrl  <= load_hi_acca;
                   accb_ctrl  <= load_accb;
					  else
                   cc_ctrl    <= latch_cc;
                   acca_ctrl  <= latch_acca;
                   accb_ctrl  <= latch_accb;
					  end if;
                 md_ctrl    <= shiftl_md;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
					  if count = "0111" then
					    next_state <= fetch_state;
					  else
				       next_state <= mul0_state;
					  end if;

				 --
				 -- Integer division
				 -- ACCD = numerator
				 -- EA = denominator
				 -- IX = quotient
				 -- 
				 -- For integer divide, re-arrange registers
				 -- IX = ACCD = dividend low word
				 -- ACCD = 0 = dividend 
				 --
				 when idiv_state =>
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= reset_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- transfer ACCD to IX
                 left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_st16;
                 cc_ctrl    <= load_cc;
                 ix_ctrl    <= load_ix;  --- quotient / dividend
                 acca_ctrl  <= reset_acca;
                 accb_ctrl  <= reset_accb;
 					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= div1_state;


				 --
				 -- Common integer divide
				 -- ACCD = Dividend high word
				 -- IX = Dividend low word / Quotient
				 -- EA = Divisor
				 -- MD = Temp for subtraction
				 --
				 -- Test for divide
				 -- MD = ACCD - EA
				 --
				 when div1_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= latch_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
					  -- subtract denominator from numerator
                 left_ctrl  <= accd_left;
                 right_ctrl <= ea_right;
                 alu_ctrl   <= alu_sub16;
                 cc_ctrl    <= load_cc;
                 md_ctrl    <= load_md; -- md = temporary result
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= div2_state;

				 --
				 -- shift carry into quotient
				 -- IX = IX << 1 + Carry
				 -- next state dependant on carry from previous state
				 --
				 when div2_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= inc_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= load_md;
					  -- rotate carry into quotient
                 left_ctrl  <= ix_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_rol16;
                 cc_ctrl    <= load_cc;
                 ix_ctrl    <= load_ix;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
					  if cc(CBIT) = '1' then
				       next_state <= div3_state;
					  else
					    next_state <= div4_state;
					  end if;

				 --
				 -- hear if Carry Set from subtract
				 -- ACCD = ACCD << 1 + Carry
				 --
				 when div3_state =>
				     -- default
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= latch_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- shift numerator left
                 left_ctrl  <= accd_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_rol16;
                 cc_ctrl    <= load_cc;
                 acca_ctrl  <= load_hi_acca;
                 accb_ctrl  <= load_accb;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
					  if count = "10000" then
					    next_state <= div5_state;
					  else
				       next_state <= div1_state;
					  end if;
				 --
				 -- hear if Carry Clear from subtract
				 -- ACCD = MD << 1 + Carry
				 --
				 when div4_state =>
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= latch_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- numerator = Subtraction rotated left
                 left_ctrl  <= md_left;
                 right_ctrl <= zero_right;
                 alu_ctrl   <= alu_rol16;
                 cc_ctrl    <= load_cc;
                 acca_ctrl  <= load_hi_acca;
                 accb_ctrl  <= load_accb;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
					  if count = "10000" then
					    next_state <= div5_state;
					  else
				       next_state <= div1_state;
					  end if;

				 --
				 -- invert quotient in IX
				 -- IX = COM( IX )
				 --
				 when div5_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 pc_ctrl    <= latch_pc;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= latch_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- complement quotient
                 left_ctrl  <= ix_left;
                 right_ctrl <= ea_right;
                 alu_ctrl   <= alu_com;
                 cc_ctrl    <= load_cc;
                 ix_ctrl    <= load_ix;
					  -- idle bus
                 addr_ctrl  <= idle_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= fetch_state;

				 --
				 -- Spin the Program counter
				 --
				 when spin_state =>
				     -- default
                 acca_ctrl  <= latch_acca;
                 accb_ctrl  <= latch_accb;
                 ix_ctrl    <= latch_ix;
                 iy_ctrl    <= latch_iy;
                 sp_ctrl    <= latch_sp;
                 iv_ctrl    <= latch_iv;
				     count_ctrl <= latch_count;
			        op_ctrl    <= latch_op;
				     pre_ctrl   <= latch_pre;
                 ea_ctrl    <= latch_ea;
                 md_ctrl    <= latch_md;
					  -- complement quotient
                 left_ctrl  <= pc_left;
                 right_ctrl <= one_right;
                 alu_ctrl   <= alu_add16;
                 pc_ctrl    <= load_pc;
                 cc_ctrl    <= latch_cc;
					  -- idle bus
                 addr_ctrl  <= fetch_ad;
                 dout_ctrl  <= md_lo_dout;
				     next_state <= spin_state;

             --
				 -- Execute cycle is performed by
				 -- single operand indexed and extended instructions
				 -- and bit operators.
				 --
			    when execute_state => -- execute
				   -- default
			      op_ctrl    <= latch_op;
				   pre_ctrl   <= latch_pre;
				   count_ctrl <= reset_count;
					acca_ctrl   <= latch_acca;
               accb_ctrl   <= latch_accb;
               ix_ctrl     <= latch_ix;
               iy_ctrl     <= latch_iy;
               sp_ctrl     <= latch_sp;
               pc_ctrl     <= latch_pc;
               iv_ctrl     <= latch_iv;
               ea_ctrl     <= latch_ea;
					  -- idle the bus
               addr_ctrl   <= idle_ad;
               dout_ctrl   <= md_lo_dout;
			      case op_code(7 downto 4) is
					when "0001" => -- bit operators come here
					  case op_code(3 downto 0) is
					  when "0100" | "1100" => -- bset
					      -- OR bit
                     left_ctrl  <= md_left;
					      right_ctrl <= pre_right;
					      alu_ctrl   <= alu_bset;
					      cc_ctrl    <= load_cc;
                     md_ctrl    <= load_md;
				         next_state <= write8_state;
					  when "0101" | "1101" => -- bclr
					      -- AND bit
                     left_ctrl  <= md_left;
					      right_ctrl <= pre_right;
					      alu_ctrl   <= alu_bclr;
					      cc_ctrl    <= load_cc;
                     md_ctrl    <= load_md;
				         next_state <= write8_state;
					  when others =>
					      -- idle ALU
                     left_ctrl  <= md_left;
					      right_ctrl <= pre_right;
					      alu_ctrl   <= alu_nop;
					      cc_ctrl    <= latch_cc;
                     md_ctrl    <= latch_md;
				         next_state <= fetch_state;
					  end case;

	            when "0110" | -- indexed single op
	                 "0111" => -- extended single op
	              case op_code(3 downto 0) is
		           when "0000" => -- neg
                   left_ctrl  <= md_left;
					    right_ctrl <= zero_right;
					    alu_ctrl   <= alu_neg;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
 	              when "0011" => -- com
                   left_ctrl  <= md_left;
		             right_ctrl <= zero_right;
					    alu_ctrl   <= alu_com;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "0100" => -- lsr
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_lsr8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "0110" => -- ror
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_ror8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "0111" => -- asr
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_asr8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "1000" => -- asl
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_asl8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "1001" => -- rol
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_rol8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "1010" => -- dec
                   left_ctrl  <= md_left;
		             right_ctrl <= one_right;
					    alu_ctrl   <= alu_dec;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "1011" => -- undefined
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_nop;
					    cc_ctrl    <= latch_cc;
				       md_ctrl    <= latch_md;
				       next_state <= fetch_state;
		           when "1100" => -- inc
                   left_ctrl  <= md_left;
		             right_ctrl <= one_right;
					    alu_ctrl   <= alu_inc;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when "1101" => -- tst
                   left_ctrl  <= md_left;
		             right_ctrl <= zero_right;
					    alu_ctrl   <= alu_st8;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= latch_md;
				       next_state <= fetch_state;
		           when "1110" => -- jmp
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_nop;
					    cc_ctrl    <= latch_cc;
				       md_ctrl    <= latch_md;
				       next_state <= fetch_state;
		           when "1111" => -- clr
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_clr;
					    cc_ctrl    <= load_cc;
				       md_ctrl    <= load_md;
				       next_state <= write8_state;
		           when others =>
                   left_ctrl  <= md_left;
						 right_ctrl <= zero_right;
					    alu_ctrl   <= alu_nop;
					    cc_ctrl    <= latch_cc;
				       md_ctrl    <= latch_md;
				       next_state <= fetch_state;
		           end case;
 
	            when others =>
					  left_ctrl   <= accd_left;
					  right_ctrl  <= md_right;
					  alu_ctrl    <= alu_nop;
					  cc_ctrl     <= latch_cc;
                 md_ctrl     <= latch_md;
		           next_state  <= fetch_state;
               end case;
           --
			  -- 16 bit Write state
			  -- write high byte of ALU output.
			  -- EA hold address of memory to write to
			  -- Advance the effective address in ALU
			  --
			  when write16_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
				 -- increment the effective address
				 left_ctrl  <= ea_left;
				 right_ctrl <= one_right;
				 alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
			    ea_ctrl    <= load_ea;
 				 -- write the ALU hi byte to ea
             addr_ctrl  <= write_ad;
             dout_ctrl  <= md_hi_dout;
				 next_state <= write8_state;
           --
			  -- 8 bit write
			  -- Write low 8 bits of ALU output
			  --
			  when write8_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- idle the ALU
             left_ctrl  <= acca_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
				 -- write ALU low byte output
             addr_ctrl  <= write_ad;
             dout_ctrl  <= md_lo_dout;
				 next_state <= fetch_state;

			  when psha_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write acca
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= acca_dout; 
             next_state <= fetch_state;

			  when pula_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- idle sp
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= latch_sp;
				 -- read acca
				 acca_ctrl  <= pull_acca;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= acca_dout;
             next_state <= fetch_state;

			  when pshb_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write accb
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= accb_dout; 
             next_state <= fetch_state;

			  when pulb_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- idle sp
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= latch_sp;
				 -- read accb
				 accb_ctrl  <= pull_accb;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= accb_dout;
             next_state <= fetch_state;

			  when pshxy_lo_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write ix low
             addr_ctrl  <= push_ad;
				 if pre_byte = "00011000" then
			      dout_ctrl  <= iy_lo_dout;
 				 else
			      dout_ctrl  <= ix_lo_dout;
 				 end if;
             next_state <= pshxy_hi_state;

			  when pshxy_hi_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write ix / iy hi
             addr_ctrl  <= push_ad;
				 if pre_byte = "00011000" then
			      dout_ctrl  <= iy_hi_dout;
 				 else
			      dout_ctrl  <= ix_hi_dout;
 				 end if;
             next_state <= fetch_state;

		  	  when pulxy_hi_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- pull ix hi
				 if pre_byte = "00011000" then
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= pull_hi_iy;
               dout_ctrl  <= iy_hi_dout;
 				 else
				   ix_ctrl    <= pull_hi_ix;
				   iy_ctrl    <= latch_iy;
               dout_ctrl  <= ix_hi_dout;
 				 end if;
             addr_ctrl  <= pull_ad;
             next_state <= pulxy_lo_state;

		  	  when pulxy_lo_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- idle sp
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= latch_sp;
				 -- read ix low
				 if pre_byte = "00011000" then
				   ix_ctrl    <= latch_ix;
				   iy_ctrl    <= pull_lo_iy;
               dout_ctrl  <= iy_lo_dout;
 				 else
				   ix_ctrl    <= pull_lo_ix;
				   iy_ctrl    <= latch_iy;
               dout_ctrl  <= ix_lo_dout;
 				 end if;
             addr_ctrl  <= pull_ad;
             next_state <= fetch_state;

           --
			  -- return from interrupt
			  -- enter here from bogus interrupts
			  --
			  when rti_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             sp_ctrl    <= load_sp;
				 -- idle address bus
             cc_ctrl    <= latch_cc;
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= cc_dout;
             next_state <= rti_cc_state;

			  when rti_cc_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             sp_ctrl    <= load_sp;
				 -- read cc
             cc_ctrl    <= pull_cc;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= cc_dout;
             next_state <= rti_accb_state;

			  when rti_accb_state =>
				 -- default registers
             acca_ctrl  <= latch_acca;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read accb
				 accb_ctrl  <= pull_accb;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= accb_dout;
             next_state <= rti_acca_state;

			  when rti_acca_state =>
				 -- default registers
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read acca
				 acca_ctrl  <= pull_acca;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= acca_dout;
             next_state <= rti_ixh_state;

			  when rti_ixh_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read ix hi
				 ix_ctrl    <= pull_hi_ix;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= ix_hi_dout;
             next_state <= rti_ixl_state;

			  when rti_ixl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read ix low
				 ix_ctrl    <= pull_lo_ix;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= ix_lo_dout;
             next_state <= rti_iyh_state;

			  when rti_iyh_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read iy hi
				 iy_ctrl    <= pull_hi_iy;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= iy_hi_dout;
             next_state <= rti_iyl_state;

			  when rti_iyl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- read iy low
				 iy_ctrl    <= pull_lo_iy;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= iy_lo_dout;
             next_state <= rti_pch_state;

			  when rti_pch_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
	          -- increment sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_add16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- pull pc hi
				 pc_ctrl    <= pull_hi_pc;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= pc_hi_dout;
             next_state <= rti_pcl_state;

			  when rti_pcl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- idle sp
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= latch_sp;
	          -- pull pc low
				 pc_ctrl    <= pull_lo_pc;
             addr_ctrl  <= pull_ad;
             dout_ctrl  <= pc_lo_dout;
             next_state <= fetch_state;

			  --
			  -- here on interrupt
			  -- iv register hold interrupt type
			  --
			  when int_pcl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write pc low
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= pc_lo_dout; 
             next_state <= int_pch_state;

			  when int_pch_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write pc hi
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= pc_hi_dout; 
             next_state <= int_iyl_state;

			  when int_iyl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write iy low
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= iy_lo_dout; 
             next_state <= int_iyh_state;

			  when int_iyh_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write iy hi
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= iy_hi_dout; 
             next_state <= int_ixl_state;

			  when int_ixl_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write ix low
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= ix_lo_dout; 
             next_state <= int_ixh_state;

			  when int_ixh_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write ix hi
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= ix_hi_dout; 
             next_state <= int_acca_state;

			  when int_acca_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write acca
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= acca_dout; 
             next_state <= int_accb_state;


			  when int_accb_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write accb
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= accb_dout; 
             next_state <= int_cc_state;

			  when int_cc_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- decrement sp
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_sub16;
             cc_ctrl    <= latch_cc;
             sp_ctrl    <= load_sp;
				 -- write cc
             addr_ctrl  <= push_ad;
			    dout_ctrl  <= cc_dout;
				 --
			    -- XIRQ is level sensitive
				 --
			    if (xirq = '1') and (cc(XBIT) = '0') then
		  			iv_ctrl    <= xirq_iv;
			      next_state <= int_maskx_state;
			    else
					--
					-- IRQ is level sensitive
					--
				    if (irq = '1') and (cc(IBIT) = '0') then
						iv_ctrl    <= irq_iv;
						next_state <= int_maski_state;
				    elsif (irq_ext3 = '1') and (cc(IBIT) = '0') then
						iv_ctrl    <= ext3_iv;
						next_state <= int_maski_state;
				    elsif (irq_ext2 = '1') and (cc(IBIT) = '0') then
						iv_ctrl    <= ext2_iv;
						next_state <= int_maski_state;
				    elsif (irq_ext1 = '1') and (cc(IBIT) = '0') then
						iv_ctrl    <= ext1_iv;
						next_state <= int_maski_state;
				    elsif (irq_ext0 = '1') and (cc(IBIT) = '0') then
						iv_ctrl    <= ext0_iv;
						next_state <= int_maski_state;
				    else
					case op_code is
					when "00111110" => -- WAI (wait for interrupt)
					    iv_ctrl    <= latch_iv;
					    next_state <= int_wai_state;
					when "00111111" => -- SWI (Software interrupt)
					    iv_ctrl    <= swi_iv;
					    next_state <= vect_hi_state;
					when others => -- bogus interrupt (return)
					    iv_ctrl    <= latch_iv;
					    next_state <= rti_state;
					end case;
				    end if;
			    end if;

			  when int_wai_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
				 count_ctrl <= reset_count;
             md_ctrl    <= latch_md;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
             -- enable interrupts
             left_ctrl  <= sp_left;
             right_ctrl <= one_right;
             alu_ctrl   <= alu_cli;
             cc_ctrl    <= load_cc;
             sp_ctrl    <= latch_sp;
				 -- idle bus
             addr_ctrl  <= idle_ad;
			    dout_ctrl  <= cc_dout; 
			    --
				 -- XIRQ is level sensitive
				 --
			    if (xirq = '1') and (cc(XBIT) = '0') then
		  			iv_ctrl    <= xirq_iv;
			      next_state <= int_maskx_state;
			    else
					--
					-- IRQ is level sensitive
					--
				if (irq = '1') and (cc(IBIT) = '0') then
				    iv_ctrl    <= irq_iv;
				    next_state <= int_maski_state;
				elsif (irq_ext3 = '1') and (cc(IBIT) = '0') then
				    iv_ctrl    <= ext3_iv;
				    next_state <= int_maski_state;
				elsif (irq_ext2 = '1') and (cc(IBIT) = '0') then
				    iv_ctrl    <= ext2_iv;
				    next_state <= int_maski_state;
				elsif (irq_ext1 = '1') and (cc(IBIT) = '0') then
				    iv_ctrl    <= ext1_iv;
				    next_state <= int_maski_state;
				elsif (irq_ext0 = '1') and (cc(IBIT) = '0') then
				    iv_ctrl    <= ext0_iv;
				    next_state <= int_maski_state;
				else
				    iv_ctrl    <= latch_iv;
				    next_state <= int_wai_state;
				end if;
			    end if;

			  when int_maskx_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- Mask IRQ
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
			    alu_ctrl   <= alu_sex;
				 cc_ctrl    <= load_cc;
             sp_ctrl    <= latch_sp;
				 -- idle bus cycle
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= md_lo_dout;
             next_state <= vect_hi_state;

			  when int_maski_state =>
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- Mask IRQ
             left_ctrl  <= sp_left;
             right_ctrl <= zero_right;
			    alu_ctrl   <= alu_sei;
				 cc_ctrl    <= load_cc;
             sp_ctrl    <= latch_sp;
				 -- idle bus cycle
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= md_lo_dout;
             next_state <= vect_hi_state;

			  when others => -- halt on undefine states
				 -- default
             acca_ctrl  <= latch_acca;
             accb_ctrl  <= latch_accb;
             ix_ctrl    <= latch_ix;
             iy_ctrl    <= latch_iy;
             sp_ctrl    <= latch_sp;
             pc_ctrl    <= latch_pc;
             md_ctrl    <= latch_md;
             iv_ctrl    <= latch_iv;
				 count_ctrl <= reset_count;
			    op_ctrl    <= latch_op;
				 pre_ctrl   <= latch_pre;
             ea_ctrl    <= latch_ea;
				 -- do nothing in ALU
             left_ctrl  <= acca_left;
             right_ctrl <= zero_right;
             alu_ctrl   <= alu_nop;
             cc_ctrl    <= latch_cc;
				 -- idle bus cycle
             addr_ctrl  <= idle_ad;
             dout_ctrl  <= md_lo_dout;
			    next_state <= halt_state;
		  end case;
end process;

--------------------------------
--
-- state machine
--
--------------------------------

change_state: process( clk, rst, state )
begin
  if rst = '1' then
 	 state <= reset_state;
  elsif clk'event and clk = '0' then
    state <= next_state;
  end if;
end process;
	-- output
	
end;
	
