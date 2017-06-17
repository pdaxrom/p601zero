{$A-,B-,E-,F-,I-,N-,O-,R-,S+,V-,D-,L-}




(* Виж п░о╢ед│░а Def_Space, около ░ед 1200. *)

{ В║п░о▒║▓ е дали expression ▓░┐бва да вдига HasLabel ако види '*' }



(***************************************************
 *	  6800 Cross assembler			   *
 *	Version 2.09 09-Jul-1989		   *
 *						   *
 *	(C) Copyright 1988 Ivo Nenov		   *
 *	    Copyright 1988 Orlin Shopov 	   *
 *	    With a little help from his friend YGP *
 ***************************************************)

{$R-,I-,V-}
program asm6800;
(**) uses crt; { да пи╕ем по-б║░зо }

  const
    MaxIncl = 8;
    C_OPEN = 1; 		   (* Can't open source file *)
    I_MODE = 2; 		   (* Illegal addr. mode *)
    G_SYNT = 3; 		   (* General syntax error *)
    C_OPEN_LST = 4;		   (* Can't open listing file *)
    OUT_RADIX = 5;		   (* Digit out of radix *)
    TOO_LARGE_NUM =6;		   (* Integer overflow *)
    ILL_LAB = 7;		   (* Illegal name *)
    REDEF = 8;			   (* Redefinition of symbol *)
    EXP_EXPR = 9;		   (* Expected expression *)
    ILL_CHAR = 10;		   (* Illegal character in text *)
    C_BRACKED = 12;		   (* Exp. close bracked *)
    NO_MEM = 13;		   (* There is no memory available *)
    OUT_OVERFL = 14;		   (* Output buf. overflow *)
    BRANCH_OUT = 15;		   (* Branch out of range -128..+127 *)
    OBJ_ERR = 16;		   (* Error writing obj. file *)
    NOT_FOUND = 17;		   (* Undefined identifier *)
    C_OPEN_SRC = 18;		   (* Can't open source file *)
    EXP_CONST = 19;		   (* Expected constant expression *)
    BAD_ORG = 20;		   (* ORG inside SECTION *)
    ILL_SIZE = 21;		   (* Illegal size of operand *)
    EXP_CLOSE_QUOTE = 22;	   (* Expected close quote *)
    BAD_RADIX = 23;		   (* Bad radix specified *)
    NESTING_ERR = 24;		   (* Proc nesting error *)
    PASS_ERR = 25;		   (* Error betwen passes *)
    NO_SEC = 26;		   (* SECTION without ENDS *)
    NO_ENDS = 27;		   (* Missing ENDS *)
(**)IncNested = 28;		   (* include files too nested*)
(**)c_open_inc = 29;		   (* Can't open include file *)
(**)FnameExpect = 30;		   (* Include file name expected *)
(**)UserBreak = 31;		   (* UserBreak error *)
(**)EndExpect = 32;		   (* UnExpected END *)
    INV_ORG = 33;		   (* ORG not allowed in relative_mode *)
    ILL_CSUM = 34;		   (* CSUM inside dummy or duplicated *)

  const NInstructions = 138; { MC6800 + alias + MC6803 }
  type
    addr_modes = (impl, imm, zp, absolut, index, rel);
    instr = record
	      mnemonic: string[4];
	      large: boolean;	{ large operand (2 bytes), example LDX #$2000 }
	      code: array [addr_modes] of byte;   { 0 - not implemented }
	    end;
    instr_array = array [0..NInstructions] of instr;
    instr_ptr = ^instr_array;

    ref_type = (one_word, high_byte, low_byte, rel_ref);

    label_ptr = ^label_desc;
    label_desc = record
		   name: string[15];
		   l, r: label_ptr;
		   offset: word;
		   kind: byte;		 { bit 0  - proc, bit 1  - found, bit 2  - equ }
		   constant: boolean;
		   parent: label_ptr;
		   locals: label_ptr;
		 end;

    expr_op = ( no_op, add, sub, mul, divide, module, bitor, bitand, bitxor );

    obj_buff = array[0..32767] of byte;
    obj_buff_ptr = ^obj_buff;

    offset_buff = array[0..32767] of byte;
    offset_buff_ptr = ^offset_buff;



  const
    instr_def:	instr_array =

     (* 	mnem	     large	   impl #    zp   abs  indXrel *)
(    (mnemonic:'ABA'  ;large:false  ;code:( $1B, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ABX'  ;large:false  ;code:( $3A, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'ADCA' ;large:false  ;code:( 0  , $89, $99, $B9, $A9, 0  ) ) ,
     (mnemonic:'ADCB' ;large:false  ;code:( 0  , $C9, $D9, $F9, $E9, 0  ) ) ,
     (mnemonic:'ADDA' ;large:false  ;code:( 0  , $8B, $9B, $BB, $AB, 0  ) ) ,
     (mnemonic:'ADDB' ;large:false  ;code:( 0  , $CB, $DB, $FB, $EB, 0  ) ) ,
     (mnemonic:'ADDD' ;large:true   ;code:( 0  , $C3, $D3, $F3, $E3, 0  ) ) , { 6803 }
     (mnemonic:'ANDA' ;large:false  ;code:( 0  , $84, $94, $B4, $A4, 0  ) ) ,
     (mnemonic:'ANDB' ;large:false  ;code:( 0  , $C4, $D4, $F4, $E4, 0  ) ) ,
     (mnemonic:'ASL'  ;large:false  ;code:( 0  , 0  , 0  , $78, $68, 0  ) ) ,
     (mnemonic:'ASLA' ;large:false  ;code:( $48, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ASLB' ;large:false  ;code:( $58, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ASLD' ;large:false  ;code:( $05, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'ASR'  ;large:false  ;code:( 0  , 0  , 0  , $77, $67, 0  ) ) ,
     (mnemonic:'ASRA' ;large:false  ;code:( $47, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ASRB' ;large:false  ;code:( $57, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'BCC'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $24) ) ,
     (mnemonic:'BCS'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $25) ) ,
     (mnemonic:'BEQ'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $27) ) ,
     (mnemonic:'BGE'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2C) ) ,
     (mnemonic:'BGT'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2E) ) ,
     (mnemonic:'BHI'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $22) ) ,
     (mnemonic:'BHS'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $24) ) , { 6803 }
     (mnemonic:'BITA' ;large:false  ;code:( 0  , $85, $95, $B5, $A5, 0  ) ) ,
     (mnemonic:'BITB' ;large:false  ;code:( 0  , $C5, $D5, $F5, $E5, 0  ) ) ,
     (mnemonic:'BLE'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2F) ) ,
     (mnemonic:'BLO'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $25) ) , { 6803 }
     (mnemonic:'BLS'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $23) ) ,
     (mnemonic:'BLT'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2D) ) ,
     (mnemonic:'BMI'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2B) ) ,
     (mnemonic:'BNE'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $26) ) ,
     (mnemonic:'BPL'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $2A) ) ,
     (mnemonic:'BRA'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $20) ) ,
     (mnemonic:'BRN'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $21) ) , { 6803 }
     (mnemonic:'BSR'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $8D) ) ,
     (mnemonic:'BVC'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $28) ) ,
     (mnemonic:'BVS'  ;large:false  ;code:( 0  , 0  , 0  , 0  , 0  , $29) ) ,
     (mnemonic:'CBA'  ;large:false  ;code:( $11, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CLC'  ;large:false  ;code:( $C , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CLI'  ;large:false  ;code:( $E , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CLR'  ;large:false  ;code:( 0  , 0  , 0  , $7F, $6F, 0  ) ) ,
     (mnemonic:'CLRA' ;large:false  ;code:( $4F, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CLRB' ;large:false  ;code:( $5F, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CLV'  ;large:false  ;code:( $A , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CMPA' ;large:false  ;code:( 0  , $81, $91, $B1, $A1, 0  ) ) ,
     (mnemonic:'CMPB' ;large:false  ;code:( 0  , $C1, $D1, $F1, $E1, 0  ) ) ,
     (mnemonic:'COM'  ;large:false  ;code:( 0  , 0  , 0  , $73, $63, 0  ) ) ,
     (mnemonic:'COMA' ;large:false  ;code:( $43, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'COMB' ;large:false  ;code:( $53, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'CPX'  ;large:true   ;code:( 0  , $8C, $9C, $BC, $AC, 0  ) ) ,
     (mnemonic:'DAA'  ;large:false  ;code:( $19, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'DEC'  ;large:false  ;code:( 0  , 0  , 0  , $7A, $6A, 0  ) ) ,
     (mnemonic:'DECA' ;large:false  ;code:( $4A, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'DECB' ;large:false  ;code:( $5A, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'DES'  ;large:false  ;code:( $34, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'DEX'  ;large:false  ;code:( $09, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'EORA' ;large:false  ;code:( 0  , $88, $98, $B8, $A8, 0  ) ) ,
     (mnemonic:'EORB' ;large:false  ;code:( 0  , $C8, $D8, $F8, $E8, 0  ) ) ,
     (mnemonic:'INC'  ;large:false  ;code:( 0  , 0  , 0  , $7C, $6C, 0  ) ) ,
     (mnemonic:'INCA' ;large:false  ;code:( $4C, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'INCB' ;large:false  ;code:( $5C, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'INS'  ;large:false  ;code:( $31, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'INT'  ;large:false  ;code:( 0  , 0  , $3F, 0  , 0  , 0  ) ) ,
     (mnemonic:'INX'  ;large:false  ;code:( $08, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'JMP'  ;large:false  ;code:( 0  , 0  , 0  , $7E, $6E, 0  ) ) ,
     (mnemonic:'JSR'  ;large:false  ;code:( 0  , 0  , $9D, $BD, $AD, 0  ) ) , { 6803 - +direct }
(**) (mnemonic:'LDA'  ;large:false  ;code:( 0  , $86, $96, $B6, $A6, 0  ) ) ,
     (mnemonic:'LDAA' ;large:false  ;code:( 0  , $86, $96, $B6, $A6, 0  ) ) ,
     (mnemonic:'LDAB' ;large:false  ;code:( 0  , $C6, $D6, $F6, $E6, 0  ) ) ,
(**) (mnemonic:'LDB'  ;large:false  ;code:( 0  , $C6, $D6, $F6, $E6, 0  ) ) ,
     (mnemonic:'LDD'  ;large:true   ;code:( 0  , $CC, $DC, $FC, $EC, 0  ) ) , { 6803 }
     (mnemonic:'LDS'  ;large:true   ;code:( 0  , $8E, $9E, $BE, $AE, 0  ) ) ,
     (mnemonic:'LDX'  ;large:true   ;code:( 0  , $CE, $DE, $FE, $EE, 0  ) ) ,
     (mnemonic:'LSL'  ;large:false  ;code:( 0  , 0  , 0  , $78, $68, 0  ) ) ,
     (mnemonic:'LSLA' ;large:false  ;code:( $48, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'LSLB' ;large:false  ;code:( $58, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'LSLD' ;large:false  ;code:( $05, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'LSR'  ;large:false  ;code:( 0  , 0  , 0  , $74, $64, 0  ) ) ,
     (mnemonic:'LSRA' ;large:false  ;code:( $44, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'LSRB' ;large:false  ;code:( $54, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'LSRD' ;large:false  ;code:( $04, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'MUL'  ;large:false  ;code:( $3D, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
{ (**) (mnemonic:'NBA'  ;large:false  ;code:( $14, 0  , 0  , 0  , 0  , 0  ) ) , }
     (mnemonic:'NEG'  ;large:false  ;code:( 0  , 0  , 0  , $70, $60, 0  ) ) ,
     (mnemonic:'NEGA' ;large:false  ;code:( $40, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'NEGB' ;large:false  ;code:( $50, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'NOP'  ;large:false  ;code:( $01, 0  , 0  , 0  , 0  , 0  ) ) ,
{ (**) (mnemonic:'OBA'  ;large:false  ;code:( $1a, 0  , 0  , 0  , 0  , 0  ) ) , }
(**) (mnemonic:'ORA'  ;large:false  ;code:( 0  , $8A, $9A, $BA, $AA, 0  ) ) ,
     (mnemonic:'ORAA' ;large:false  ;code:( 0  , $8A, $9A, $BA, $AA, 0  ) ) ,
     (mnemonic:'ORAB' ;large:false  ;code:( 0  , $CA, $DA, $FA, $EA, 0  ) ) ,
(**) (mnemonic:'ORB'  ;large:false  ;code:( 0  , $CA, $DA, $FA, $EA, 0  ) ) ,
(**) (mnemonic:'PHA'  ;large:false  ;code:( $36, 0  , 0  , 0  , 0  , 0  ) ) ,
(**) (mnemonic:'PHB'  ;large:false  ;code:( $37, 0  , 0  , 0  , 0  , 0  ) ) ,
(**) (mnemonic:'PLA'  ;large:false  ;code:( $32, 0  , 0  , 0  , 0  , 0  ) ) ,
(**) (mnemonic:'PLB'  ;large:false  ;code:( $33, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'PSHA' ;large:false  ;code:( $36, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'PSHB' ;large:false  ;code:( $37, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'PSHX' ;large:false  ;code:( $3C, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'PULA' ;large:false  ;code:( $32, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'PULB' ;large:false  ;code:( $33, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'PULX' ;large:false  ;code:( $38, 0  , 0  , 0  , 0  , 0  ) ) , { 6803 }
     (mnemonic:'ROL'  ;large:false  ;code:( 0  , 0  , 0  , $79, $69, 0  ) ) ,
     (mnemonic:'ROLA' ;large:false  ;code:( $49, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ROLB' ;large:false  ;code:( $59, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'ROR'  ;large:false  ;code:( 0  , 0  , 0  , $76, $66, 0  ) ) ,
     (mnemonic:'RORA' ;large:false  ;code:( $46, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'RORB' ;large:false  ;code:( $56, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'RTI'  ;large:false  ;code:( $3B, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'RTS'  ;large:false  ;code:( $39, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'SBA'  ;large:false  ;code:( $10, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'SBCA' ;large:false  ;code:( 0  , $82, $92, $B2, $A2, 0  ) ) ,
     (mnemonic:'SBCB' ;large:false  ;code:( 0  , $C2, $D2, $F2, $E2, 0  ) ) ,
     (mnemonic:'SEC'  ;large:false  ;code:( $D , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'SEI'  ;large:false  ;code:( $F , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'SEV'  ;large:false  ;code:( $B , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'SLP'  ;large:false  ;code:( $1A, 0  , 0  , 0  , 0  , 0  ) ) , { 6303 }
(**) (mnemonic:'STA'  ;large:false  ;code:( 0  , 0  , $97, $B7, $A7, 0  ) ) ,
     (mnemonic:'STAA' ;large:false  ;code:( 0  , 0  , $97, $B7, $A7, 0  ) ) ,
     (mnemonic:'STAB' ;large:false  ;code:( 0  , 0  , $D7, $F7, $E7, 0  ) ) ,
(**) (mnemonic:'STB'  ;large:false  ;code:( 0  , 0  , $D7, $F7, $E7, 0  ) ) ,
     (mnemonic:'STD'  ;large:false  ;code:( 0  , 0  , $DD, $FD, $ED, 0  ) ) , { 6803 }
     (mnemonic:'STS'  ;large:false  ;code:( 0  , 0  , $9F, $BF, $AF, 0  ) ) ,
     (mnemonic:'STX'  ;large:false  ;code:( 0  , 0  , $DF, $FF, $EF, 0  ) ) ,
     (mnemonic:'SUBA' ;large:false  ;code:( 0  , $80, $90, $B0, $A0, 0  ) ) ,
     (mnemonic:'SUBB' ;large:false  ;code:( 0  , $C0, $D0, $F0, $E0, 0  ) ) ,
     (mnemonic:'SUBD' ;large:true   ;code:( 0  , $83, $93, $B3, $A3, 0  ) ) , { 6803 }
     (mnemonic:'SWI'  ;large:false  ;code:( $3F, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TAB'  ;large:false  ;code:( $16, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TAP'  ;large:false  ;code:( $6 , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TBA'  ;large:false  ;code:( $17, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TPA'  ;large:false  ;code:( $7 , 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TST'  ;large:false  ;code:( 0  , 0  , 0  , $7D, $6D, 0  ) ) ,
     (mnemonic:'TSTA' ;large:false  ;code:( $4D, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TSTB' ;large:false  ;code:( $5D, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TSX'  ;large:false  ;code:( $30, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'TXS'  ;large:false  ;code:( $35, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'WAI'  ;large:false  ;code:( $3E, 0  , 0  , 0  , 0  , 0  ) ) ,
     (mnemonic:'XGDX' ;large:false  ;code:( $18, 0  , 0  , 0  , 0  , 0  ) ) , { 6303 }
(**) (mnemonic:'XORA' ;large:false  ;code:( 0  , $88, $98, $B8, $A8, 0  ) ) ,
(**) (mnemonic:'XORB' ;large:false  ;code:( 0  , $C8, $D8, $F8, $E8, 0  ) ) );


  var
    instructions: instr_array;
    radix: integer;

    lind, cind, ipc, star, dummy_addr, offset_ind, csum_offset: word;
    entry_point: word;
    out_buff: obj_buff_ptr;
    offsets: offset_buff_ptr;

    line_buff: string[255];
    line:array[0..255]of char;
    f_parent: label_desc;
    buff_over, end_found: boolean;
    generated, not_dummy, gen_list, relative_mode: boolean;
    pass2, org_found, csum_found: boolean;

    data: word; 		{ next_sym variables }
    dta_type: ref_type;
    character: char;
    this_label: label_ptr;
    alpha,
    redef_ident,
    undef_ident: string[15];
    UsrBrk_data: string[15];

    errfile, has_lst: boolean;
    StdErr, StdOut: text;
    lst: text;

(* Include ┤илове▓е ▒а една гол┐ма к░║пка и ако ▒е оп░ав┐▓ ▓░┐бва да ▒е оп░ав┐▓ доб░е *)
(**)IncLevel: byte;	{ на кое ниво на вложено▒▓ в include ┤иле }
(**)Total_c: longint;	{ об╣о линий }
(**)IncLines: array [0..MaxIncl] of word; { б░ой линий в include file-▓о }
(**)inc_fname: array [0..MaxIncl] of string[31]; { име▓о на include ┤иле▓о }
(**)obj_fname: string[31];

(**)incld: array [0..MaxIncl] of text;	{ ▒амо▓о ┤иле за include-ване }

    ins_p: integer;
    mode: addr_modes;

    errors: array[0..9] of byte;
    err_levels: array[0..9] of byte;
    n_errors, n_warns: integer;
    l_errors: 0..9;
    has_error: boolean;

    MayCon, NotCon, has_label: boolean;
    NotTruncating, TruncList, DontPrint: boolean;

    digits: array[0..15] of char;
    directives: array[0..17] of string[11];


  function get_errtxt(e_no: integer):  string;
  begin
  case e_no of
    C_OPEN:	      get_errtxt:= 'Can''t open source file';
    I_MODE:	      get_errtxt:= 'Illegal addr. mode';
    G_SYNT:	      get_errtxt:= 'General syntax error';
    C_OPEN_LST:       get_errtxt:= 'Can''t open listing file';
    OUT_RADIX:	      get_errtxt:= 'Digit out of radix';
    TOO_LARGE_NUM:    get_errtxt:= 'Integer overflow';
    ILL_LAB:	      get_errtxt:= 'Illegal name';
    REDEF:	      get_errtxt:= 'Redefinition of symbol <' + redef_ident +'>';
    EXP_EXPR:	      get_errtxt:= 'Expected expression';
    ILL_CHAR:	      get_errtxt:= 'Illegal character in text';
    C_BRACKED:	      get_errtxt:= 'Exp. close bracked';
    NO_MEM:	      get_errtxt:= 'There is no memory available';
    OUT_OVERFL:       get_errtxt:= 'Output buf. overflow';
    BRANCH_OUT:       get_errtxt:= 'Branch out of range';
    OBJ_ERR:	      get_errtxt:= 'Error writing obj. file';
    NOT_FOUND:	      get_errtxt:= 'Undefined identifier <' + undef_ident +'>';
    C_OPEN_SRC:       get_errtxt:= 'Can''t open source file';
    EXP_CONST:	      get_errtxt:= 'Expected constant expression';
    ILL_SIZE:	      get_errtxt:= 'Illegal size of operand';
    EXP_CLOSE_QUOTE:  get_errtxt:= 'Expected close quote';
    BAD_RADIX:	      get_errtxt:= 'Bad radix specified';
    NESTING_ERR:      get_errtxt:= 'Proc nesting error';
    PASS_ERR:	      get_errtxt:= 'Error betwen passes';
    NO_SEC:	      get_errtxt:= 'ENDS without SECTION';
    NO_ENDS:	      get_errtxt:= 'Missing ENDS';
    BAD_ORG:	      get_errtxt:= 'ORG inside SECTION';
    INV_ORG:	      get_errtxt:= 'ORG not allowed in relative mode';
    ILL_CSUM:	      get_errtxt:= 'Improper use of CHECKSUM directive';
(**)IncNested:	      get_errtxt:= 'Include files too nested';
(**)c_open_inc:       get_errtxt:= 'Can''t open include file';
(**)FnameExpect:      get_errtxt:= 'Include file name expected';
(**)UserBreak:	      get_errtxt:= 'User error = ' + UsrBrk_data;
(**)EndExpect:	      get_errtxt:= 'Unexpected directive END';

    end; { case }
  end;

  procedure draw_err(e_no, e_lvl: integer);
    var s: string[20];
  begin
  s:= ',  Error: ';
  if e_lvl > 1 then s:= ',  Warning: ';
  if NotCon
    then begin write(#13);
	 if not errfile then rewrite(StdErr);
	 errfile:= true;
	 writeln(StdErr, inc_fname[IncLevel], '(', IncLines[IncLevel], ')',
			  s, get_errtxt(e_no), '.');
	 writeln(StdOut, inc_fname[IncLevel], '(', IncLines[IncLevel], ')',
			  s, get_errtxt(e_no), '.');
	 write(#13, inc_fname[IncLevel], '(', IncLines[IncLevel], ')'#13);
	 end;
  if has_lst (* and gen_list *)
    then writeln(lst, inc_fname[IncLevel], '(', IncLines[IncLevel], ')',
		      s, get_errtxt(e_no), '.');
  end; { draw_err }

  procedure error(e_no, level: integer); { 0 - fatal, 1 - Severe, 2 - Warning }
  begin
  if level = 0
    then begin writeln; { Fatal errors reported directly to console }
	 if Inc_Fname[0] <> '' (* има ли изоб╣о н┐к║кво име? *)
	   then write(inc_fname[IncLevel], '(', IncLines[IncLevel], ')');
	 write('Fatal Error: ', get_errtxt(e_no), '.');
	 halt(2);
	 end;
  if (l_errors < 10) and ((errors[l_errors-1] <>  e_no) or (l_errors = 0))
    then begin errors[l_errors]:= e_no; err_levels[l_errors]:= level;
	 if level = 1
	   then inc(n_errors)
	   else inc(n_warns);
	 inc(l_errors);
	 end;
  end; { error }

  procedure display_err;
    var i: integer;
  begin
  for i:= 0 to l_errors-1 do draw_err(errors[i], err_levels[i]);
  end; { display_err }

  procedure init;
    var skip: boolean;
	i, argc: integer;
	s, base, lst_name: string[31];

    procedure upstr(var s: string);
      var i: integer;
    begin
    while (length(s) > 0) and (s[1]=' ') do delete(s, 1, 1);
    i:= 0;
    while i < length(s) do
      begin inc(i);
      s[i]:= upcase(s[i]);
      end;
    end; { UpStr }

  begin
  writeln;
  writeln('6803 Cross Assembler.             Version 2.10');
  writeln('Software Research and Development Lab.,  Sofia');
  writeln('Copyright (C) Ivo Nenov 1988-89');
  writeln('          (C) O.Shopov  1988-89 Eagle software');
  writeln('          (C) G.Petrov  1988-89 YGP');
  writeln('          (C) A.Chukov  2012-16 Madisa Technology');
  writeln;
  errfile:= false;
  Assign(StdOut, ''); rewrite(StdOut);
  Inc_Fname[0]:= ''; IncLines[0]:= 0; IncLevel:= 0;
  instructions:= instr_def;
  has_lst:= false;
  relative_mode:= false;
  org_found:= false;
  csum_found := false;
  argc:= paramcount;
  cind:= 0; buff_over:= false; ipc:= 0; entry_point:= 0;
  offset_ind:= 16;    { start writing offsets from 16-th byte}
  n_errors:= 0; n_warns:= 0; end_found:= false; not_dummy:= true; gen_list:= true;
  digits:= '0123456789ABCDEF';
  directives[0]:= '=';
  directives[1]:= 'CHECKSUM';
  directives[2]:= 'DB';
  directives[3]:= 'DS';
  directives[4]:= 'DW';
  directives[5]:= 'END';
  directives[6]:= 'ENDP';
  directives[7]:= 'ENDS';
  directives[8]:= 'EQU';
  directives[9]:= 'ERROR';
  directives[10]:= 'GLOBAL';
  directives[11]:= 'INCLUDE';
  directives[12]:= 'LIST';
  directives[13]:= 'ORG';
  directives[14]:= 'PROC';
  directives[15]:= 'RADIX';
  directives[16]:= 'SECTION';
  directives[17]:= 'TRUNC';
  radix:= 10;
  new(out_buff);
  new(offsets);

  f_parent.kind:= 3;
  f_parent.parent:= nil;
  f_parent.locals:= nil;


  if argc <> 0 then
    s:= paramstr(argc);
    if (( pos('-',s) <> 0 ) or ( pos('/',s) <> 0) ) then
      begin
      dec(argc);
      if ((pos('R',s) <> 0) or (pos('r',s) <> 0))
	then relative_mode:= true;
      end;

  if argc < 1 then
    begin
    write('Source filename [.ASM]: ');
    readln(s);
    end
  else s:= paramstr(1);
{  upstr(s); }
  i:= pos(';', s); skip:= i<>0;
  if skip then s[0]:= chr(i-1);
  base:= s;
  i:= pos('.', base);
  if i <> 0 then base[0]:= chr(i-1)	    { this should be i-1 rather than i, Eagle }
  else s:= concat(s, '.ASM');
  assign(incld[0], s); reset(incld[0]);
  inc_fname[0]:= s;
  if ioresult<>0 then error(c_open_src, 0);
  if relative_mode
    then obj_fname:= concat(base, '.PGM')
    else obj_fname:= concat(base, '.CMD');
  Assign(StdErr, base + '.ERR');
(*  if errfile then rewrite(StdErr); *)
  if skip then exit;

  if argc < 2
    then begin write('Listing filename [.LST]: ');
	 readln(s);
	 end
    else s:= paramstr(2);
{  upstr(s); }
  i:= pos(';', s); skip:= i<>0;
  if skip then s[0]:= chr(i-1);
  if length(s)<>0 then
    begin
    if pos('.',s) = 0 then s:= concat(s, '.LST');
    assign(lst, s); rewrite(lst);
    MayCon:= s = 'CON.';
    if ioresult = 0 then has_lst:= true
    else error(c_open_lst, 2);
    end;
  if skip then exit;

  if argc < 3 then
    begin
    if relative_mode then
      write('Object filename [', base,'.PGM]: ')
    else
      write('Object filename [', base,'.CMD]: ');
    readln(s); { upstr(s); }
    end
  else s:= paramstr(3);
  i:= pos(';', s); skip:= i<>0;
  if skip then s[0]:= chr(i-1);
  if s<>'' then
    begin
    if pos('.', s) = 0 then
      if relative_mode then
	s:= concat(s, '.PGM')
      else
	s:= concat(s, '.CMD');
    obj_fname:= s;
    end;
  end; { init }


  procedure prhex(i:  byte);
  begin
  if has_lst and gen_list
    then write(lst, digits[i div 16], digits[i mod 16]);
  end; { prhex }

  function get_line: boolean;
    label GetAgain;
    var ok: boolean;
	b:  byte;
    begin
    lind:= 0;
(**)GetAgain:
(**)ok:= not eof(incld[IncLevel]);
(**)if not ok then
(**)  if IncLevel > 0
(**)	then begin Close(incld[IncLevel]);
(**)	     if NotCon then
(**)	       writeln(#13, inc_fname[IncLevel], '(',inclines[IncLevel],').');
(**)	     dec(Inclevel);
(**)	     if NotCon then
(**)	       write(#13, inc_fname[IncLevel], '(',inclines[IncLevel],')');
(**)	     goto GetAgain; { Ша м║ извин┐ва▓е ам║ м║ м║░зи да ми▒л┐ YGP }
(**)	     end;
(**)if ok
(**)  then begin readln(incld[IncLevel], line_buff);
(**)	   inc(inclines[inclevel]);
(**)	   if (inclines[inclevel] mod 16 = 0) and NotCon
(**)	     then write(#13, inc_fname[IncLevel], '(', inclines[IncLevel], ')');
(**)	   ok:= IOresult = 0;
(**)	   end;
    if ok then
      begin
(**)  inc(total_c);
(**)  (* См┐▓ам ╖е ▓ези ▓░и ░еда ░або▓┐▓ много по-е┤ек▓ивно YGP *)
(**)  for b:= 1 to length(line_buff) do
(**)	line[pred(b)]:= UpCase(line_buff[b]);
(**)  line[length(line_buff)]:= #0;
(**)  (*
      i:= length(line_buff);
      move(line_buff[1], line, length(line_buff));
      line[i]:= chr(0);
      i:= 0;
      while line[i] <> chr(0) do
	begin
	line[i]:= upcase(line[i]);
	inc(i);
	end;
      *)
      end;
    get_line:= ok and (not end_found);
    end; { get_line }


  procedure get_alpha;
    var
      i: integer;
    begin
    i:= 1;
    repeat
	if i<16 then alpha[i]:= line[lind];
	inc(lind); inc(i);
    until ((line[lind] > '9') or (line[lind] < '0'))  and
	  ((line[lind] > 'Z') or (line[lind] < 'A')) and (line[lind] <> '_');
    alpha[0]:= chr(i-1);
    end;

  procedure get_number(base: integer);
    var
      i, j: integer;

    function scan_digit(c: char): integer;
      var
	i: integer;
      begin
      i:= 0;
      while (digits[i]<>c) and (i<16) do inc(i);
      scan_digit:= i;
      end;

    begin
    data:= 0; j:= 0;
    i:= scan_digit(line[lind]);
    while i < 16 do
      begin
      inc(lind);
      j:= data;
      data:= data*base;
      if i >= base then error(OUT_RADIX, 2)
      else data:= data + i;
      if (data div base) <> j then error(TOO_LARGE_NUM, 2);
      i:= scan_digit(line[lind]);
      end;
    end;

  function look: boolean;
    var
      i: integer;
    begin
    i:= lind;
    while (line[i] <= ' ') and (line[i] <> chr(0)) do inc(i);
    look:= (line[i] <> chr(0)) and (line[i] <> ';') ;
    end;



  function get_sym: byte;   {  0 - eoln
			       1 - string (alpha)
			       2 - char (character)
			       3 - number (data) }
    begin
    get_sym:= 0;
    while (line[lind] <= ' ') and (line[lind] <> chr(0)) do inc(lind);

    if ((line[lind] >= 'A') and (line[lind] <= 'Z')) or (line[lind] = '_') then
      begin
      get_alpha;
      if alpha <> 'X' then get_sym:= 1
      else
	begin
	character:= 'X'; get_sym:= 2;
	end;
      exit;
      end;
    if (line[lind] >= '0') and (line[lind] <= '9') then
      begin
      get_number(radix); get_sym:= 3;
      exit;
      end;
    if line[lind] = '$' then
      begin
      inc(lind); get_number(16);
      get_sym:= 3; exit;
      end;
    if line[lind] = '%' then
      begin
      inc(lind); get_number(2);
      get_sym:= 3; exit;
      end;
    if line[lind] = '@' then
      begin
      inc(lind); get_number(8);
      get_sym:= 3; exit;
      end;
    if (line[lind] = chr(0)) or (line[lind] = ';') then
      begin
      get_sym:= 0; exit;
      end;
    character:= line[lind]; inc(lind);
    if (character = '''') and (line[lind+1] = '''') then
      begin
      data:= ord(line_buff[lind+1]); inc(lind, 2);
      get_sym:= 3; exit;
      end;
    if character = '=' then
      begin
      alpha:= '='; get_sym:= 1;
      end
    else get_sym:= 2;
    end;


  function bsearch(x: string; var  a; n:integer): integer;
    type
      s_arr = array[0..200] of string[11];
    var
      i, j, c: integer;
    begin
    i:= 0; j:= n-1;
    repeat c:= (i + j) div 2;
      if x <= s_arr(a)[c] then j:= c - 1;
      if x >= s_arr(a)[c] then i:= c + 1;
    until i > j;
    if i > j+1 then bsearch:= c
    else bsearch:= -1;
    end;

  function treesearch(root: label_ptr; s: string; var l: label_ptr): boolean;
    var
      p: label_ptr;
    begin
    if root = nil then
      begin
      l:= nil; treesearch:= false;
      exit;
      end;
    while (root <> nil) and (root^.name <> s) do
      begin
      p:= root;
      if s > root^.name then root:= root^.l
      else root:= root^.r;
      end;
    if root <> nil then
      begin
      treesearch:= true;
      l:= root;
      end
    else
      begin
      treesearch:= false;
      l:= p;
      end;
    end;


  procedure pass(p: label_ptr);
    var
      sym: shortint;
      new_proc, endp_found: boolean;

    function find_label(s: string; var l: label_ptr): boolean;
      var
	l1, p1: label_ptr;
      begin
      p1:= p;
      while p1 <> nil do
	begin
	if treesearch(p1^.locals, s, l) then
	  begin
	  find_label:= true; exit;
	  end;
	p1:= p1^.parent;
	end;
      find_label:= false;
      if treesearch(p^.locals, s, l) then;
      end;

    function get_label: label_ptr;
      var
	l, l1: label_ptr;
	sym: byte;
      begin
      if (line[0] <= ' ') or (line[0] = ';') then
	begin
	get_label:= nil;
	exit;
	end;

      lind:= 0;
      if get_sym <> 1 then
	begin
	error(ill_lab, 1);
	get_label:= nil;
	exit;
	end;
      if pass2 then
	begin
	if not find_label(alpha, l) then error(PASS_ERR, 0);
(**)	if ((l^.kind and $80) <> 0) (*and
	   ((l^.kind and 4) = 0)    *)
(**)	  then begin redef_ident:= alpha;
	       error(REDEF, 1 + ord((l^.kind and 4) <> 0 ));
	       end;
	l^.kind:= l^.kind or $80;
	get_label:= l; exit;
	end;
      if treesearch(f_parent.locals, alpha, l) then
	begin
	if l^.kind and 2 = 0 then
	  begin
	  l^.offset:= ipc;
	  l^.kind:= l^.kind or 2; l^.constant:= false;
	  get_label:= l; exit;
	  end;
	end;
      if (get_sym = 1) and ((alpha = '=') or (alpha = 'EQU')) then
	begin
	lind:= 0; sym:= get_sym;
	if treesearch(f_parent.locals, alpha, l) then
	  begin
	  if (l^.kind and 4) <> 0 then get_label:= l
	  else
	    begin
	    get_label:= nil; redef_ident:= alpha; error(REDEF, 1);
	    end;
	  exit;
	  end
	else
	  begin
	  new(l1); l1^.kind:= 6;
	  l1^.name:= alpha; l1^.parent:= addr(f_parent);
	  l1^.locals:= nil; l1^.constant:= false;
	  l1^.l:= nil; l1^.r:= nil;
	  if l<>nil then
	    if alpha > l^.name then l^.l:= l1
	    else l^.r:= l1
	  else
	    f_parent.locals:= l1;
	  get_label:= l1; exit;
	  end;
	end;
      lind:= 0; sym:= get_sym;
      if not treesearch(p^.locals, alpha, l) then
	begin
	l1:= l; new(l);
	l^.name:= alpha;
	l^.parent:= p; l^.locals:= nil;
	l^.l:= nil; l^.r:= nil;
	l^.offset:= ipc;
	l^.kind:= 2; l^.constant:= false;
	if l1 <> nil then
	  begin
	  if alpha > l1^.name then l1^.l:= l
	  else l1^.r:= l
	  end
	else
	  p^.locals:= l;
	end
      else begin redef_ident:= alpha; error(redef, 1); end;
      get_label:= l;
      end;




    procedure expression;
      var
	l, r: word;
	op, old_op: expr_op;

      function get_val(var res: word): expr_op;
	var
	  sym, prefix: byte;
	  i: word;
	  op: expr_op;
	  l: label_ptr;

	begin
	sym:= get_sym;
	if sym = 0 then
	  begin
	  error(EXP_EXPR, 1);
	  res:= 0; get_val:= no_op;
	  exit;
	  end;
	i:= 0; prefix:= 0;
	if sym = 2 then
	  begin
	  if character = '-' then
	    begin prefix:= 1;
	    sym:= get_sym;
	    end
	  else if character = '!' then
	    begin prefix:= 2;
	    sym:= get_sym;
	    end
	  else if character = '*' then
	    begin
	    i:= star; data:= star;
	    has_label:= relative_mode;
	    end
	  else if character = '(' then
	    begin
	    expression; i:= data;
	    if line[lind] = ')' then inc(lind)
	    else error(C_BRACKED, 1);
	    end
	  else error(ILL_CHAR, 1);
	  end;
	if sym = 1 then     { string }
	  begin
	  has_label:= true; i:= 1;
	  if find_label(alpha, l) then
	    begin
	    i:= l^.offset; has_label:= not l^.constant;
	    end
	  else
	    if pass2 then begin error(NOT_FOUND, 1); undef_ident := alpha; end
	  end
	else i:= data;

	op:= no_op; sym:= get_sym;
	if sym <> 0 then
	  begin
	  if sym = 2 then
	    begin
	    if character = '+' then op:= add
	    else if character = '-' then op:= sub
	    else if character = '*' then op:= mul
	    else if character = '/' then op:= divide
	    else if character = '%' then op:= module
	    else if character = '&' then op:= bitand
	    else if character = '|' then op:= bitor
	    else if character = '^' then op:= bitxor
	    else dec(lind);
	    end
	  else error(ILL_CHAR, 1);
	  end;
	if prefix <> 0 then
	  begin
	  if prefix = 1 then i:= -i;
	  if prefix = 2 then i:= not(i);
	  end;
	res:= i; get_val:= op;
	end;

      function get_operand(var res: word): expr_op;
	var
	  l, r: word;
	  op, old_op: expr_op;
	begin
	op:= get_val(l);
	while op >= mul do
	  begin
	  old_op:= op;
	  op:= get_val(r);
	  case old_op of
	      mul:    l:= l * r;
	      divide: l:= l div r;
	      module: l:= l mod r;
	      bitor:  l:= l or r;
	      bitand: l:= l and r;
	      bitxor: l:= l xor r;
	    end;  { case }
	  end;	 { while }
	res:= l;
	get_operand:= op;
	end;

      begin
      data:= 0;
      if not look then
	begin
	error(EXP_EXPR, 1);
	data:= 0; exit;
	end;
      op:= get_operand(l);
      while op <> no_op do
	begin
	old_op:= op;
	op:= get_operand(r);
	if old_op = add then l:= l + r
	else l:= l - r;
	end; { while }
      data:= l;
      end;


    function get_mode: addr_modes;
      var
	sym, old_lind: byte;
	short: boolean;
      begin
      data:= 0; old_lind:= lind; has_label:= false;

      sym:= get_sym;
      if sym = 0 then begin
	get_mode:= impl; exit;
	end;
      if sym = 2 then		    { char  }
	begin
	if character = '#' then
	  begin
	  old_lind:= lind; sym:= get_sym;
	  if sym = 0 then
	    begin
	    error(exp_expr, 1);
	    get_mode:= imm; exit;
	    end;
	  if (sym = 2) and (character = '/') then dta_type:= high_byte
	  else
	    begin
	    dta_type:= low_byte;
	    lind:= old_lind;
	    end;
	  if instructions[ins_p].large then dta_type:= one_word;
	  expression;
	  if look then error(ill_char, 1);
	  get_mode:= imm; exit;
	  end;
	if character = 'X' then
	  begin
	  dta_type:= low_byte; old_lind:= lind;
	  sym:= get_sym;
	  if sym = 0 then
	    begin
	    get_mode:= index; exit;
	    end;
	  if (sym = 2) and (character = ',') then expression;
	  if look then error(ill_char, 1);
	  get_mode:= index; exit;
	  end;
	end;	 { if sym = 2 }
      lind:= old_lind;
      short:= false;
      if (get_sym = 1) and (alpha = 'SHORT') then short:= true
      else lind:= old_lind;
      expression;
      sym:= get_sym;
      if (sym = 2) and (character = ',') then
	begin
	if (get_sym = 2) and (character = 'X') then
	  begin
	  dta_type:= low_byte;
	  get_mode:= index; exit;
	  end
	end;
      if sym <> 0 then error(ILL_CHAR,1);
      if instructions[ins_p].code[rel] <> 0 then
	begin
	dta_type:= rel_ref;
	get_mode:= rel;
	end
      else
	begin
	if (short or (not has_label and (hi(data) = 0)) )
		       and (instructions[ins_p].code[zp] <> 0) then
	  begin
	  dta_type:= low_byte;
	  get_mode:= zp;
	  end
	else
	  begin
	  dta_type:= one_word;
	  get_mode:= absolut;
	  end;
	end;
      end;


    procedure gen(i: integer);
      begin
      if not_dummy then
	begin
	if pass2 and (not buff_over) then
	  begin
	  buff_over:= cind >= 32767;
	  if buff_over then error(OUT_OVERFL, 1);
	  out_buff^[cind]:= i and $FF;
	  end;
	if has_lst and pass2 and gen_list and NotTruncating
	  then begin prhex(i and $FF); write(lst, ' '); end;
	inc(cind);
	end;
      inc(ipc);
      end;

    procedure gen_offset;
      begin
      if not_dummy then
	 begin
	 buff_over:= offset_ind >= 32766;
	 if buff_over then error(OUT_OVERFL, 1);

	 offsets^[offset_ind]:= cind div 256;
	 inc(offset_ind);
	 offsets^[offset_ind]:= cind and $FF;
	 inc(offset_ind);
	 end;
      end;

    procedure generat;
      var
	i: integer;

      begin
      generated:= not_dummy;
      if has_lst and pass2 and gen_list
	then write(lst, ' ':2);
      gen(instructions[ins_p].code[mode]);
      if mode = impl then
	begin
	if has_lst and gen_list and pass2
	  then write(lst, #9);
	end
      else
	begin
	case dta_type of
	    low_byte: begin
		      gen(data and $FF);
		      if has_lst and gen_list and pass2
			then write(lst, ' ': 7);
		      end;
	    high_byte: begin
		       if pass2 and relative_mode and has_label then gen_offset;
		       gen(data div 256);
		       if has_lst and gen_list and pass2
			 then write(lst, ' ': 7);
		       end;
	    one_word:begin
		     if pass2 and relative_mode and has_label then gen_offset;
		     gen(data div 256); gen(data and $FF);
		     end;
	    rel_ref: begin
		     if pass2 then
		       begin
		       i:= data - (ipc + 1);
		       if abs(i) > 127 then error(branch_out, 1);
		       gen(i);
		       if has_lst and gen_list and pass2
			 then begin write(lst, '  (');
			      prhex(Hi(data)); prhex(Lo(data));
			      write(lst, ')');
			      end;
		       end
		     else gen(0);
		     end;
	  end;
	end;
      end;



    procedure accept_direct;
      var d_ind, b_generated: integer;

      procedure org;
	begin
	org_found:= org_found or not_dummy;
	if relative_mode and not_dummy then error (inv_org, 1)
	else
	  begin
	  has_label:= false; expression;
	  if not has_label then  { number }
	    begin

(*		*** YGP ***
Ми▒л┐ ╖е не е ╡│баво да ▒е заб░ан┐ва ▓акава ░або▓а ка▓о:
		org	* + 10
Мака░ ╖е за▒ега аз ли╖но не го използ│вам.
*)

	    ipc:= data;
	    if get_sym <> 0 then error(ill_char, 1);
	    end
	  else error(exp_const ,1);
	  if not not_dummy then error(bad_org, 2);
	  end;
	end;

      procedure new_radix;
	begin
	has_label:= false; expression;
	if not has_label then  { number }
	  begin
	  if (data <= 16) and (data > 1) then radix:= data
	  else error(BAD_RADIX, 1);
	  end
	else error(exp_const ,1);
	end;

      procedure gen_b(b: byte);
	begin
	if has_lst and gen_list and pass2 and (b_generated <> 0) and
(***)	   ((b_generated mod 4) = 0) and not_dummy then
	  begin
	  if b_generated = 4
	    then begin write(lst, #9, line_buff);
		 DontPrint:= true;
		 NotTruncating:= not TruncList;
		 end;
	  if NotTruncating
	    then begin writeln(lst);
		 write(lst, #9' ');
		 prhex(Hi(ipc)); prhex(lo(ipc));
		 write(lst, ' ':2);
		 end;
	  end;
	gen(b); inc(b_generated);
	end;

      procedure check_sum;
	var
	  end_def: boolean;
	  sym, old_lind, i: byte;
	  term: char;

	begin
	if (csum_found and not pass2) or not not_dummy then
	  begin
	  error (ill_csum, 1);
	  end
	else
	  begin
	  b_generated:= 0; generated:= not_dummy;
	  if has_lst and gen_list and pass2 and not_dummy
	    then write(lst, ' ':2);

	  csum_offset := cind;
	  gen_b($FF);
	  csum_found := true;
	  end;
	end;

      procedure def_byte;
	var
	  end_def: boolean;
	  sym, old_lind, i: byte;
	  term: char;

	begin
	has_label := false;				{ patch 223.89 Eagle }
	b_generated:= 0; generated:= not_dummy;
	if has_lst and gen_list and pass2 and not_dummy
	  then write(lst, ' ':2);
	repeat
	  old_lind:= lind; sym:= get_sym; term:= character;
	  if (sym = 2) and ((term = '"') or (term = '''')) then
	    begin
	    i:= lind+1;
	    while (line_buff[i] <> term) and (line_buff[i] <> chr(0)) do
	      begin
	      gen_b(ord(line_buff[i])); inc(i);
	      end;
	    lind:= i-1;
	    if line[lind] = chr(0) then error(EXP_CLOSE_QUOTE, 1)
	    else inc(lind);
	    end
	  else
	    begin
	    lind:= old_lind;
	    expression;
	    gen_b(lo(data));
	    if hi(data) <> 0 then error(ILL_SIZE, 1);
	    end;
	  sym:= get_sym;
	  end_def:= (sym <> 2) or (character <> ',');
	  if (sym<>0) and end_def then error(ILL_CHAR, 1);
	until end_def;
	end;

      procedure def_word;
	var
	  end_def: boolean;
	  sym: byte;
	begin
	has_label := false;				{ patch 223.89 Eagle }
	b_generated:= 0; generated:= not_dummy;
	if has_lst and gen_list and pass2 and  not_dummy
	  then write(lst, ' ':2);
	repeat
	  expression;
	  if pass2 and relative_mode and has_label then gen_offset;
	  gen_b(hi(data)); gen_b(lo(data));
	  sym:= get_sym;
	  end_def:= (sym <> 2) or (character <> ',');
	  if (sym<>0) and end_def then error(ILL_CHAR, 1);
	until end_def;
	end;

      procedure def_space;

	var
	  nb: word;
	  sym: byte;
	  has_fill: boolean;
	begin
	has_fill:= false;
	has_label:= false; expression; nb:= data;


(****************************************************)
(****** if has_label then error(EXP_CONST, 1); ******)
(****************************************************)

(*	if has_label then error(EXP_CONST, 1); *)

{patch} if ( (this_label <> nil) and (not not_dummy) ) then
{patch} 	      this_label^.constant:= not has_label;
	generated:= not_dummy; data:= 0;
	sym:= get_sym;
	if (sym = 2) and (character = ',') then
	  begin
	  expression; has_fill:= true;
	  end
	else if sym <> 0 then error(ILL_CHAR, 1);
	if has_lst and gen_list and pass2 and not_dummy then
	  begin
	  write(lst, ' ':2); prhex(hi(nb)); prhex(lo(nb));
	  write(lst, '[');
	  if has_fill then prhex(lo(data))
	  else write(lst,'??');
	  write(lst,']    ');
	  end;
	has_fill:= has_lst; has_lst:= false;
	while nb > 0 do
	  begin
	  gen(lo(data)); dec(nb);
	  end;
	has_lst:= has_fill;
	end;

      procedure end_direct;
	var
	  l: label_ptr;
      begin
      if IncLevel > 0
	then error(EndExpect, 2)
	else end_found:= true;
      if get_sym = 1 then	{Alpha}
	if treesearch(f_parent.locals, alpha, l) then
	  entry_point:= l^.offset;
      end; { end_direct }

      procedure end_proc;
      begin
      endp_found:= true;
      end;

      procedure proc;
	begin
	if this_label = nil then error(G_SYNT, 1)
	else
	  begin
	  this_label^.kind:= 3;
	  new_proc:= true;
	  end;
	end;

      procedure globals;
	var
	  sym: byte;
	  end_glb: boolean;
	  l, l1: label_ptr;
	begin
	repeat
	  sym:= get_sym; end_glb:= (sym <> 1);
	  if (not end_glb) and (not pass2) then
	    begin
	    if treesearch(f_parent.locals, alpha, l)
	      then begin redef_ident:= alpha; error(REDEF, 1) end
	    else
	      begin
	      new(l1);
	      l1^.name:= alpha;
	      l1^.locals:= nil;
	      l1^.l:= nil; l1^.r:= nil;
	      l1^.kind:= 0;
	      if l <> nil then
		if alpha > l^.name then l^.l:= l1
		else l^.r:= l1
	      else f_parent.locals:= l1;
	      end;
	    end;
	  sym:= get_sym;
	  end_glb:= end_glb or (sym <> 2) or (character <> ',');
	until end_glb;
	if sym <> 0 then error(ILL_CHAR, 1);
	end;

      procedure equ;
	begin
	if this_label <> nil then
	  begin
	  has_label:= false; expression;
	  this_label^.offset:= data;
	  this_label^.constant:= not has_label;
	  if has_lst and gen_list and pass2 (* and  not_dummy *)
	    then begin write(lst, '  (');
		 prhex(Hi(data)); prhex(lo(data));
		 write(lst, ')'#9);
		 end;
(***)	  generated:= true;
	  end;
	end;

      procedure section;
	begin
	has_label:= false; expression;
	if not has_label then  { number }
	  begin
	  if not_dummy then
	    begin
	    not_dummy:= false; dummy_addr:= ipc;
	    end;
	  ipc:= data;
	  if get_sym <> 0 then error(ill_char, 1);
	  end
	else error(exp_const ,1);
	end;

      procedure ends;
	begin
	if not_dummy then error(no_sec, 1)
	else
	  begin
	  not_dummy:= true; ipc:= dummy_addr;
	  if  get_sym <> 0 then error(ill_char, 1);
	  end;
	end;

      procedure list_on_of;
	begin
	if get_sym <> 1 then  error(ill_char, 1);
	if alpha = 'ON' then
	  begin
	  line_buff:= '';
	  gen_list:= true;
	  end
	else if alpha = 'OFF' then
	  begin
	  if has_lst and pass2 and gen_list
	    then writeln(lst, #9#9#9, line_buff);
	  gen_list:= false;
	  end
	else error(ill_char, 1);
	NotCon:= not (has_lst and MayCon and gen_list);
	end;

      procedure truncOnOff;
	begin
	if get_sym <> 1 then  error(ill_char, 1);
	if (alpha = 'ON') or (alpha = 'OFF')
	  then TruncList:= alpha = 'ON'
	  else error(ill_char, 1);
	end;

(**)  procedure Include;
	  var Fname: string[31];
	begin
	if Inclevel = MaxIncl
	  then error(IncNested, 0);
	while (line[lind] <= ' ') and (line[lind] <> chr(0)) do inc(lind);
	fname:= ''; (* ▓│к ▒ко░о▒▓▓а не е ▒║╣е▒▓вена а п║к ме м║░зи *)
	while (line[lind] > ' ') and
	      (line[lind] <= #127) and
	      (line[lind] <> chr(0)) do
	  begin fname:= fname + line[lind];
	  inc(lind);
	  end;
	if fname = '' then error(FnameExpect, 0);
	inc(Inclevel); inc_fname[IncLevel]:= fname;
	assign(incld[IncLevel], fname);
	reset(incld[IncLevel]);
	if ioresult <> 0
	  then begin writeln(#10#13, inc_fname[IncLevel]);
	       error(c_open_inc, 0);
	       end;
	if NotCon then begin write(#13,inc_fname[IncLevel]); clreol; end;
	inclines[IncLevel]:= 0;
	end; { Include }

      procedure ErrDirective;
	  var
	  end_def: boolean;
	  sym: byte;
	begin
	if not pass2 then exit;
	expression;
	if has_lst and gen_list and pass2
	  then begin write(lst, '  (');
	       prhex(Hi(data)); prhex(Lo(data));
	       write(lst, ')'#9);
	       end;
	if data <> 0
	  then begin str(data, UsrBrk_data);
	       error(UserBreak, 1);
	       end;
	sym:= get_sym;
	if (sym <> 0) then error(ILL_CHAR, 1);
(***)	generated:= true;
	end; { ErrDirective }

      begin
      b_generated:= 0;
      d_ind:= bsearch(alpha, directives, 17);
      if d_ind < 0 then
	begin
	error(g_synt, 1);
	exit;
	end;
      case d_ind of
	0: equ;
	1: check_sum;
	2: def_byte;
	3: def_space;
	4: def_word;
	5: end_direct;
	6: end_proc;
	7: ends;
	8: equ;
(**)	9: ErrDirective;
       10: globals;
(**)   11: include;
       12: list_on_of;
       13: org;
       14: proc;
       15: new_radix;
       16: section;
       17: truncOnOff;
	end;  { case }
     if has_lst and gen_list and pass2 and not DontPrint and
	((b_generated mod 4 = 1)  or (b_generated mod 4 = 2))
       then write(lst, #9 (*' ': 7*));
      end;

    begin
    endp_found:= false; new_proc:= false;
    while not endp_found and get_line do
      begin
      star:= ipc;
      l_errors:= 0; generated:= false;
      if has_lst and gen_list and pass2 then
	begin
(**)	case Inclevel of
(**)	   0: write(lst, '  ', IncLines[0]:5, ' ':2);
(**)	   1: write(lst, ' >', IncLines[1]:5, ' ':2);
(**)	   2: write(lst, '>>', IncLines[2]:5, ' ':2);
(**)	   else write(lst, IncLevel, '>', IncLines[IncLevel]:5, ' ':2);
	end;
	prhex(hi(ipc)); prhex(lo(ipc));
	end;
      this_label:= get_label; DontPrint:= false; NotTruncating:= true;
      sym:= get_sym;
      if sym = 1 then
	begin
	ins_p:= bsearch(alpha, instructions, NInstructions+1);
	if ins_p >= 0 then
	  begin
	  mode:= get_mode;  { set data and large }
	  if instructions[ins_p].code[mode] <>0 then generat
	  else error(i_mode,1);
	  end
	else accept_direct;
	end
      else if sym<>0 then error(ILL_CHAR, 1);
      if has_lst and gen_list and pass2 then
	if DontPrint then writeln(lst)
	  else begin
	       if not generated
		 then write(lst, ' ':13);
	       writeln(lst, #9, line_buff);
	       end;
      display_err;
      if new_proc then
	begin
	new_proc:= false;
	pass(this_label);
	end;
      end; { while }
    if endp_found then
      begin
      if p^.parent = nil then
	begin
	draw_err(NESTING_ERR, 1); inc(n_errors);
	end;
      exit;
      end;
    if p^.parent <> nil then
      begin
      draw_err(NESTING_ERR, 1); inc(n_errors);
      end;
    end;

  procedure make_header;
    begin
      offsets^[0]:= $A5;		       {magic}
      offsets^[1]:= $5A;		       {magic}
      offsets^[2]:= (offset_ind div 2 - 8) div 256; {number of relative items}
      offsets^[3]:= (offset_ind div 2 - 8) and 255; {number of relative items}
      offsets^[4]:= offset_ind div 256;        {offset in object_file of object_code}
      offsets^[5]:= offset_ind and 255;        {offset in object_file of object_code}
      offsets^[6]:= cind div 256;	       {length of object_code}
      offsets^[7]:= cind and 255;	       {length of object_code}
      offsets^[8]:= hi(entry_point);	       {entry offset in object_code}
      offsets^[9]:= lo(entry_point);	       {entry offset in object_code}
      offsets^[10]:= 0; 		       {reserved}
      offsets^[11]:= 0; 		       {reserved}
      offsets^[12]:= 0; 		       {reserved}
      offsets^[13]:= 0; 		       {reserved}
      offsets^[14]:= 0; 		       {reserved}
      offsets^[15]:= 0; 		       {reserved}
    end;

  procedure write_file;
    var
      csum: byte;
      i: word;
      f: file;
    begin
    if csum_found then
      begin
      csum := 0;
      for i:= 0 to cind-1 do csum := csum + out_buff^[i];
      out_buff^[csum_offset] := csum xor $FF;
      end;
    assign(f, obj_fname);
    rewrite(f, 1);
    if ioresult<>0 then error(obj_err, 0);
    if relative_mode then
      begin
      blockwrite(f, offsets^, offset_ind);
      if ioresult<>0 then error(obj_err, 0);
      end;
    blockwrite(f, out_buff^, cind);
    if ioresult<>0 then error(obj_err, 0);
    close(f);
    end;

  begin
  init; NotCon:= true; { п░и п║░ви┐ па▒ ╣е пи╕ем }
  TruncList:= true;
  pass2:= false;
(**)writeln(' --- Pass 1 --- ');
(**)write(Inc_fname[0]);
(**)Inclevel:= 0; IncLines[0]:= 0;
  pass(addr(f_parent));
  writeln(#13,Inc_fname[0] , '(', inclines[0], ').');
  if not not_dummy then error(no_ends, 1);
  pass2:= true; has_error:= n_errors <> 0;
  radix:= 10; inclines[0]:= 0;
(**)total_c:= 0;
  cind:= 0; ipc:= 0; n_errors:= 0; n_warns:= 0; end_found:= false; not_dummy:= true;
  gen_list:= true;
  if (not org_found) and (not relative_mode) then
     begin
     relative_mode:= true;
     obj_fname[0]:= chr(pos('.',obj_fname));
     obj_fname:= concat(obj_fname, 'PGM');
     end;
(**)Inclevel:= 0; NotCon:= not (has_lst and MayCon);
(**)writeln(#10#13' --- Pass 2 ---');
(**)if NotCon then
(**)  write(inc_fname[0]);
  reset(incld[0]); TruncList:= true;
  pass(addr(f_parent));
  if NotCon then
    writeln(#13, inc_fname[0], '(', inclines[0], ').');
  if relative_mode then make_header;
  if (not has_error) and (n_errors = 0) then write_file;
  if has_lst then close(lst);
  writeln;
  writeln(total_c:5, ' Lines assembled');
  writeln(cind:5, ' Bytes code'#13#10);
  writeln(n_warns:5, ' Warning errors');
  writeln(n_errors:5, ' Severe  errors');
  if errfile then Close(StdErr) else erase(StdErr);
  Close(StdOut);
  if n_errors <> 0
    then halt(2);
  if n_warns <> 0
    then halt(1);
  end.
