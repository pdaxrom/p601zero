 (************************************************************)
(*							    *)
(*	      Программа создания и корректировки	    *)
(*		  библиотеки об'ектных модулей              *)
(*			 Version 1.02			    *)
(*		  (c) 19.VII.1989 Leonid Curak		    *)
(*							    *)
(************************************************************)

 PROGRAM LIBR;
(*
	 Описание типов и переменных
*)

 CONST MAXD=10000;	 (*  Количество элементов в рабочем массиве *)

 TYPE	ARBF = array[1..MAXD] OF BYTE;
	ARB  = ARRAY[1..8] OF BYTE;
	tmod = record
	    kom      : byte;
	    nam_mod  : string[40];
	    name_mod : arb;
	  end;
	tmk  = array[1..32] of tmod;

 VAR IP,I,IC,KMOD,KMODN,DLM,DLS,IND	 :INTEGER;
     IT,IM,j,jj,kmm 			 :INTEGER;
     FLPR,FLIG,FS			 :BOOLEAN;
     CH 				 :CHAR;
     BUF				 :ARBF;
     LIB_NAM,LIB_NMP,NAM_PRN,PAR 	 :STRING[80];
     STRN				 :STRING[80];
     KD,koma 				 :BYTE;
     NAME_MODT				 :ARB;
     RFILE,MFILE,WFILE			 :FILE; 	(* FILES *)
     PFILE				 :TEXT;
     DLF				 :LONGINT;
     digits				 : array[0..15] of char;
     moda				 : tmk;

(*
		   Подпрограммы
*)
  FUNCTION PRHEX(I:  BYTE) : STRING;

  BEGIN
    PRHEX := DIGITS[I DIV 16] +  DIGITS[I MOD 16];
  END; { PRHEX }


(*
     Процедура выделения имени модуля из имени файла
*)
   procedure MODNAM(nam:string; var mnmd:arb);

    var j,ii,k,kk : integer;
	ch	  : char;

    begin

     ii:=1;
     k:=LENGTH(nam);		{ длина строки }
     j:=1;

     repeat
       ch:=nam[ii];
       ii:=ii+1;
       kk:=POS(ch,':\.');       { один из спец. символов? }
       if kk=0 then
	 begin
	  mnmd[j]:=ORD(UPCASE(ch));  { перекодировка в большие буквы }
	  j:=j+1;
	 end
	else
	 if kk<>3 then j:=1;
     until (kk=3) or (ii>k);
     if j<16 then		 { дополнение пробелами }
       for k:=j to 16 do
	 mnmd[k]:=$20
   end; 	       { PROC MODNAM }

(*
       Обработка одного модуля

  Вход:    FRD	- файл чтения
	   FWR	- файл записи
	   FZP	- флаг записи
	   FPR	- флаг печати
*)
 PROCEDURE ZMODA(VAR FRD,FWR:FILE;NAM_T: ARB; FZP,FPR:BOOLEAN);
  VAR  KPB,KEXT,DLPB,DLEXT,DL:INTEGER;
 begin

  STRN:=' ';
  FOR I:=1 TO 8 DO
    BEGIN
      CH:=CHR(NAM_T[I]);
      STRN:=STRN+CH;
    END;
  IF FPR THEN	       (* Печать заголовка модуля *)
(*
	      БЛОК ПЕЧАТИ имени модуля
*)
     WRITELN(PFILE,'   МОДУЛЬ',STRN);

  BLOCKREAD(FRD,BUF,32);	   (*  Чтение шапки модуля*)
  IF (BUF[1]<>$5A) OR (BUF[2]<>$A5) THEN
    WRITELN(' LIB  Модуль ',strn,' не объектный')
   ELSE
    BEGIN
     IF FZP THEN BLOCKWRITE(FWR,BUF,32);  (*  Запись заголовка модуля *)
     KPB:=BUF[5]*256+BUF[6];	    (*	Количество точек PUBLIC *)
     KEXT:=BUF[7]*256+BUF[8];	    (*	Количество точек EXT	*)
     DLPB:=KPB*20;		    (*	Количество байт в PUBLIC*)
     DLEXT:=KEXT*20;		    (*	Количество байт в EXT	*)
     BLOCKREAD(FRD,BUF,DLPB);		 (*  Чтение области PUBLIC   *)
     IF DLPB<>0 THEN
      BEGIN
       IF FZP THEN BLOCKWRITE(FWR,BUF,DLPB); (*  Запись области PUBLIC	 *)
       IF FPR THEN	    (* Печать таблицы входных точек *)
	BEGIN
	 WRITELN(PFILE,' ');
	 WRITELN(PFILE,'      ТАБЛИЦА ВХОДНЫХ ТОЧЕК ');
	 WRITELN(PFILE,' ');
	 IND:=0;
	 FOR I:=1 TO KPB DO
	  BEGIN
	   STRN:=' ';
	   FOR IP:=1 TO 16 DO
	    BEGIN
	     STRN:=STRN+CHR(BUF[IND+IP]);
(*	       STRN:=CONCAT(STRN,CH);*)
	    END;
	   STRN:=STRN+'  ';
	   IF BUF[IND+19]=0 THEN CH:='R' ELSE CH:='C';
	   STRN:=STRN+CH+' ';
	   STRN:=STRN+PRHEX(BUF[IND+17]);
	   STRN:=STRN+PRHEX(BUF[IND+18]);
	   WRITELN(PFILE,STRN);
	   IND:=IND+20;
	  END;
	  WRITELN(PFILE);
	END
      END;
     IF DLEXT<>0 THEN
      BEGIN
       BLOCKREAD(FRD,BUF,DLEXT);	   (*  Чтение области EXT   *)
       IF FZP THEN BLOCKWRITE(FWR,BUF,DLEXT); (*  Запись области EXT   *)
       IF FPR THEN	    (* Печать таблицы внешних точек *)
	BEGIN
	 WRITELN(PFILE);
	 WRITELN(PFILE,'      ТАБЛИЦА ВНЕШНИХ ТОЧЕК ');
	 WRITELN(PFILE);
	 IND:=0;
	 FOR I:=1 TO KEXT DO
	  BEGIN
	   STRN:=' ';
	   FOR IP:=1 TO 16 DO
	    BEGIN
	     STRN:=STRN+CHR(BUF[IND+IP]);
{	      STRN:=CONCAT(STRN,CH);}
	    END;
	    WRITELN(PFILE,STRN);
	    IND:=IND+20;
	  END;
	END;
      END;
     DLF:=DLF-DLPB-DLEXT-32;	   (* Остаток файла в байтах *)
(*
	     Перекачка тела модуля
*)
     REPEAT
       IF DLF<MAXD THEN        (*  Вычисление длины очередного модуля *)
	 DL:=DLF
	ELSE
	 DL:=MAXD;
       DLF:=DLF-DL;
       BLOCKREAD(FRD,BUF,DL);
       IF FZP THEN BLOCKWRITE(FWR,BUF,DL);
     UNTIL DLF=0
    END
  END;	      (*  END  ZMODA *)

(*
      ПРОЦЕДУРА ЧТЕНИЯ ДЛИНЫ МОДУЛЯ
*)
   PROCEDURE RDDL(VAR FRD:FILE);
    BEGIN
     DLF:=0;
     BLOCKREAD(FRD,BUF,4);
     FOR IT:=1 TO 4 DO
      BEGIN
       DLF:=DLF*256+BUF[IT];
      END;
    END;

(*
     ПРОЦЕДУРА ПЕЧАТИ ЗАГОЛОВКА БИБЛИОТЕКИ
*)
  PROCEDURE PRZAG;
   BEGIN
    WRITELN(PFILE,'            БИБЛИОТЕКА ',LIB_NAM);
    WRITELN(PFILE);
    WRITELN(PFILE);
    WRITELN(PFILE,'   В БИБЛИОТЕКЕ ',KMODN,' МОДУЛЕЙ');
   END;

(*
      ПРОЦЕДУРА ПРЕОБРАЗОВАНИЯ ДЛИНЫ
*)
   PROCEDURE DLINA(VAR FRD:FILE);
    VAR DLF1	     :LONGINT;
    BEGIN
     DLF:=FILESIZE(FRD);
     DLF1:=DLF;
     FOR IT:=1 TO 4 DO
      BEGIN
       BUF[5-IT]:=DLF1 MOD 256;
       DLF1:=DLF1 DIV 256;
      END;
     END;


 PROCEDURE ERRPAR;
 BEGIN
 WRITELN('ERROR in Parameters');
 writeln('usage: UniLIB LibName [command] [/ListFile]');
 writeln('  command: <symbol>ModuleName, where symbol is');
 writeln('             + add ModuleName to the library');
 writeln('             - remove ModuleName from the library');
 writeln('             * extract ModuleName without removing it');
 writeln('             -+ or +- replace ModuleName in library');
 writeln('             -* or *- extract ModuleName and remove it');
 HALT;
 END;

(*
     Блок разбора параметров
*)
 BEGIN
  writeln('UniLIB Version 1.00. (c) 1989 "ТРИАДА".');

  digits:= '0123456789ABCDEF';
  IP:=PARAMCOUNT;	     (*    Количество параметров  *)
  IF IP<1 THEN ERRPAR;	      (*    Ошибка в параметрах    *)
  LIB_NAM:=PARAMSTR(1);        (* Первый параметр (имя LIB) *)
  I:=POS('.',LIB_NAM);         (*   Номер точки в строке    *)
  IF I=0 THEN BEGIN	       (*  Имя без расширения	    *)
    LIB_NAM:=LIB_NAM+'.LIB';   (* Подсоединить расширение*)
    I:=POS('.',LIB_NAM)         (*   Номер точки в строке    *)
  END;
(*
     Получить имена промежуточного файла и файла типа BAC
*)
  LIB_NMP:=COPY(LIB_NAM,1,I);
  LIB_NMP:=LIB_NMP+'$LB';       (* промежуточный файл *)
  FLPR:=FALSE;			  (* Флаг печати *)
  j:=0;
  kmm:=0;
  koma:= 0;
(*
      Разбор остальных параметров
*)
  FOR I:=2 TO IP DO BEGIN
    PAR:=PARAMSTR(I);		   (* Очередной параметр *)
    CH:=PAR[1]; 	     (* CH=COPY(PAR,1,1) - первый символ *)
(*
       Проверка на команду и перекодировка: 1-*, 2-+,4--.
*)
    IC:=POS(CH,'*+ -/');
    IF IC=0 THEN ERRPAR;	 (* Ошибка в параметрах *)
    IF IC=5 THEN BEGIN		  (* Доп.команда: /P - печать*)
      NAM_PRN:= PAR;
      DELETE(NAM_PRN,1,1);
      FLPR:=TRUE
      END
     ELSE BEGIN 		   (* Команда работы с модулем *)
      j:=j+1;			   { номер параметра }
      moda[j].kom:=IC;			   (* Код команды *)
      IT:=1;			   (* Количество символов в команде *)
      CH:=PAR[2];	       (* CH=COPY(PAR,2,1) - второй символ *)
      IC:=POS(CH,'*+ -');      (* Проверка и перекодировка команды *)
      IF IC=3 THEN ERRPAR;
      IF IC<>0 THEN BEGIN	(* Продолжение команды *)
	IT:=2;
	moda[j].kom:=moda[j].kom+IC;		(* Код команды *)
	IF moda[j].KOM=3 THEN ERRPAR    (* +* - недопустимая команда *)
      END;
      IF moda[j].KOM=2 THEN 		 (* Команда вставки + *)
        kmm:=kmm+1		 (* HOBOE *)
       ELSE
        IF (moda[j].KOM=4) OR (moda[j].KOM=5) THEN	 (* Команда удаления *)
          kmm:=kmm-1;		 (* HOBOE *)
      koma:=koma or moda[j].kom;
      DELETE(par,1,IT); (* Оставить только им модуля *)
      IF POS('.',par) = 0 THEN
      	par:=par+'.OBJ';    (* Подсоединить расширение *)
      moda[j].NAM_MOD:= PAR;
(*
	Получить имя модуля в массиве байт - NAME_MOD
*)
      FOR IP:=1 TO 8 DO
	moda[j].NAME_MOD[IP]:=$20;
      MODNAM(par,moda[j].NAME_MOD);
    END       (*  IF *)
  END;	      (* FOR *)
  FLIG:= (koma >= 2) and (j <>0);  (* Флаг редактирования библиотеки*)
(*
	 Блок начальной установки и открытия файлов
*)
  IF NOT FLPR THEN NAM_PRN:='CON';
  FLPR:=TRUE;
  ASSIGN(PFILE,NAM_PRN);		(* OPEN FILE PRINT *)
  REWRITE(PFILE);
  IF IORESULT<>0 THEN BEGIN	(*  ошибка *)
    WRITELN(' ERROR DISK ',NAM_PRN);
    WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
    HALT(1)
   END;

  ASSIGN(RFILE,LIB_NAM);
  {$I-}
  RESET(RFILE,1);	  (* Открыть файл библиотеки *)
  IF IORESULT<>0 THEN BEGIN	(* Нет библиотеки или ошибка *)
    IF koma <> 2  THEN errpar;
{      WRITELN(' ERROR DISK ',LIB_NAM);
      WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
      HALT(1)
    END; }
    ASSIGN(WFILE,LIB_NAM);
    REWRITE(WFILE,1);
    IF IORESULT<>0 THEN BEGIN	  (*  ошибка *)
      WRITELN(' ERROR DISK ',LIB_NAM);
      CLOSE(PFILE);
      WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
      HALT(1)
    END;

(*
       Создание новой библиотеки
*)
    KMODN:=kmm;
    PRZAG;
    BUF[1]:=$0B;		  (* Создание фапки библиотеки *)
    BUF[2]:=$B0;
    FOR I:=3 TO 32 DO  BUF[I]:=0;
    BUF[6]:=kmm;			 (* Количество модулей *)
    BLOCKWRITE(WFILE,BUF,32);	      (* Запись заголовка библиотеки *)

    for jj:=1 to j do
      begin

       ASSIGN(MFILE,moda[jj].NAM_MOD);
       RESET(MFILE,1);		  (* Открыть файл модуля *)
       IF IORESULT<>0 THEN BEGIN	  (*  ошибка *)
         WRITELN(' ERROR DISK ',moda[jj].NAM_MOD);
         WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
         CLOSE(WFILE);
         ERASE(WFILE);
         CLOSE(PFILE);
         HALT(1);
       END;
  {$I+}
       BLOCKWRITE(WFILE,moda[jj].NAME_MOD,8);      (* Заголовок модуля - имя модуля *)
(*
	Получить длину файла MFILE и записать в BUF[1..4]
*)
       DLINA(MFILE);
       BLOCKWRITE(WFILE,BUF,4);	     (* Заголовок модуля - длина *)
       ZMODA(MFILE,WFILE,moda[jj].NAME_MOD,TRUE,FLPR); (* Переписать модуль *)
       CLOSE(MFILE);
      end;
    CLOSE(WFILE);
    CLOSE(PFILE);
    WRITELN(' LIB  КОНЕЦ РАБОТЫ');
    HALT(0)		  (* HOPMA *)
  END;
(*
       Работа с библиотекой
*)

  BLOCKREAD(RFILE,BUF,32);		  (* Прочитать заголовок библиотеки *)
  IF (BUF[1]<>$0B) OR (BUF[2]<>$B0) THEN BEGIN
    WRITELN('ФАЙЛ - ',LIB_NAM,' НЕ БИБЛИОТЕКА');
    CLOSE (RFILE);
    CLOSE (PFILE);
    WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
    HALT(2)
  END;
  if flig then
   begin
    ASSIGN(WFILE,LIB_NMP);
    REWRITE(WFILE,1);
   end;
  KMOD:=BUF[5]*256+BUF[6];	 (* Количество модулей в библиотеке *)
  kmodn:=kmod+kmm;
  PRZAG;
  BUF[5]:=KMODN DIV 256;
  BUF[6]:=KMODN MOD 256;
  IF FLIG THEN BLOCKWRITE(WFILE,BUF,32);	 (* Запись заголовка библиотеки *)
(*
	Цикл по модулям библиотеки (поиск заданного имени)
*)
  FOR IM:=1 TO KMOD DO
  BEGIN
    BLOCKREAD (RFILE,NAME_MODT,8);	(* Имя очередного модуля *)
    if j=0 then fs:=false
     else
      begin
       jj:=0;
       repeat
	 jj:=jj+1;

	 i:=1;
	 repeat 	  (* Цикл сравнения *)
	   fs:= moda[jj].NAME_MOD[I]=NAME_MODT[I];
	   i:=i+1;
	 until (i>8) or not fs;

       until (jj=j) or fs;
      end;
    IF FS THEN BEGIN		  (* Нашли заданный модуль *)
      CASE moda[jj].KOM OF
       1:			 (* Команда выбора '*'   *)
	BEGIN
	 ASSIGN(MFILE,moda[jj].NAM_MOD);
	 REWRITE(MFILE,1);  (* Создать файл модуля *)
	 IF IORESULT<>0 THEN BEGIN     (*  ошибка *)
	   CLOSE (RFILE);
	   CLOSE (PFILE);
	   WRITELN(' ERROR DISK ',moda[jj].NAM_MOD);
	   WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
	   HALT(1)
	 END;
	 RDDL(RFILE);	     (* Прочитать и преобразовать длину модуля *)
	 ZMODA(RFILE,MFILE,NAME_MODT,TRUE,FLPR); (* Запись модуля *)
	 CLOSE(MFILE);
	END;
       2:			  (* Команда вставки '+'  *)
	BEGIN
	 WRITELN(' МОДУЛЬ ',moda[jj].nam_mod,' В БИБЛИОТЕКЕ ЕСТЬ ');
{	  ERASE(WFILE);
	 CLOSE(WFILE);		  (* Уничтожить промежуточный файл *)
	 FLIG:=FALSE   }
	END;
       4:			   (* Команда удаления - *)
	BEGIN
	 RDDL(RFILE);
	 ZMODA(RFILE,WFILE,NAME_MODT,FALSE,FALSE); (* Пропуск модуля *)
	END;
       5:			   (* Команда удаления и выбора *-  *)
	BEGIN
	 ASSIGN(MFILE,moda[jj].NAM_MOD);
	 REWRITE(MFILE,1);	 (* Открыть файл модуля *)
	 IF IORESULT<>0 THEN BEGIN     (*  ошибка *)
	   WRITELN(' ERROR DISK ',moda[jj].NAM_MOD);
	   CLOSE (PFILE);
	   CLOSE (WFILE);
	   ERASE (WFILE);
	   CLOSE (RFILE);
	   WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
	   HALT(1)
	 END;
(*   модуля в библиотеке *)
	 RDDL(RFILE);	     (* Прочитать и преобразовать длину модуля *)
	 ZMODA(RFILE,MFILE,NAME_MODT,TRUE,FALSE);
	 CLOSE(MFILE)
	END;
       6:			    (* Команда замены *)
	BEGIN
	 ASSIGN(MFILE,moda[jj].NAM_MOD);
	 RESET(MFILE,1);	       (* Открыть файл модуля *)
	 IF IORESULT<>0 THEN BEGIN     (*  ошибка *)
	   WRITELN(' ERROR DISK ',moda[jj].NAM_MOD);
	   CLOSE (PFILE);
	   CLOSE (WFILE);
	   ERASE (WFILE);
	   CLOSE (RFILE);
	   WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
	   HALT(1)
	 END;
(*	 Получить дилину файла	*)
	 DLINA(MFILE);	(*DLF:=FILESIZE(MFILE);*)
	 BLOCKWRITE(WFILE,NAME_MODT,8);     (* Запись имени модуля *)
	 BLOCKWRITE(WFILE,BUF,4);	    (* Запись длины модуля *)
	 ZMODA(MFILE,WFILE,NAME_MODT,TRUE,FLPR); (* Запись модуля *)
	 CLOSE(MFILE);
(*
    Переписать модуль из библиотеки в файл
*)
	 RDDL(RFILE);	(* Прочитать и преобразовать длину модуля *)
	 ZMODA(RFILE,MFILE,NAME_MODT,FALSE,FALSE); (* Пропуск модуля *)
	END
       END   (* CASE *)
      END
(*
	    Не совпадают имена модулей
*)
     ELSE  BEGIN
      RDDL(RFILE);		(*  Чтение длины *)
      IF FLIG THEN BEGIN	   (* Запись ведется? *)
	BLOCKWRITE(WFILE,NAME_MODT,8);	   (* Запись имени модуля *)
	BLOCKWRITE(WFILE,BUF,4) 	  (* Запись длины модуля *)
      END;
      ZMODA(RFILE,WFILE,NAME_MODT,FLIG,FLPR)  (* Запись модуля *)
    END     (* IF *)
  END;	    (* FOR Все модули просмотрели *)
  if j<>0 then
    for jj:=1 to j do
     begin

      IF moda[jj].KOM=2 THEN BEGIN		 (*  Команда вставки *)
	ASSIGN(MFILE,moda[jj].NAM_MOD);
	RESET(MFILE,1);       (* Открыть файл модуля *)
	IF IORESULT<>0 THEN BEGIN     (*  ошибка *)
	  WRITELN(' ERROR DISK ',moda[jj].NAM_MOD);
	  CLOSE (PFILE);
	  CLOSE (WFILE);
	  ERASE (WFILE);
	  CLOSE (RFILE);
	  WRITELN(' LIB  АВАРИЙНОЕ ЗАВЕРШЕНИЕ');
	  HALT(1)
	END;
(*	 Получить дилину файла	*)
	DLINA(MFILE);
	BLOCKWRITE(WFILE,moda[jj].NAME_MOD,8);	     (* Запись имени модуля *)
	BLOCKWRITE(WFILE,BUF,4);	   (* Запись длины модуля *)
	ZMODA(MFILE,WFILE,moda[jj].NAME_MOD,TRUE,FLPR); (* Запись модуля *)
	CLOSE(MFILE)
      end;
     END;
  IF FLIG THEN BEGIN
(*    Переименовать файл RFILE B .BLI  *)
    CLOSE(RFILE);
    ERASE(RFILE);
    CLOSE(WFILE);
    RENAME(WFILE, LIB_NAM);

(*    Переименовать файл WFILE B .LIB  *)
    END
   ELSE
    CLOSE(RFILE);
    CLOSE(PFILE);
(*
     КОНЕЦ РАБОТЫ
*)
  WRITELN (' LIB  КОНЕЦ РАБОТЫ ');
 END.
