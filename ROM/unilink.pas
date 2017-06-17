(******************************************************
*						      *
*	      РЕДАКТОР СВЯЗИ ОБ'ЕКТНыХ МОДУЛЕЙ        *
*		       UniLINK			      *
*						      *
*	       18.07.1989 г.   17.10	V.1.1	      *
*	       (c) 1989 Leonid Curak		      *
*******************************************************)

(*
	     Описание типов
*)
   CONST  maxd=2000;		       { длина массива BUF }
	  maxt=15000;		       { длина нассива TABT }

   TYPE   name	 = array[1..16] of byte;

	  tmods  = record	       { структура таблицы модулей TMOD }
	       hand  :byte;	       { номер файла }
	       nmod  :longint;	       { позиция в файле }
	       sizec :integer;	       { размер кода }
	       ykpb  :integer;	       { указатель таблицы PUBL }
	       ykext :integer;	       { указатель таблицы EXT }
	       namem :array[1..8] of char; { имя модуля }
	   end;

	  tvmods = record	       { структура таблицы используемых модулей}
	       nom   :integer;	       { ссылка на таблицу TMOD }
	       bas   :integer;	       { база модуля }
	   end;

	  texs	 = record	       { структура таблицы EXT }
	       namext:name;	       { имя точки ЕХТ }
	       adr   :integer;	       { значение точки }
	       tip   :byte;	       { тип точки }
	   end;

	  tmodt  = array[1..256] of tmods;
	  tvmodt = array[1..256] of tvmods;
	  textt  = array[1..1000] of texs;

(*
	    Описание переменных
*)
   VAR	  tabt			  : array[1..maxt] of byte; { буфер точек ЕХТ и PUBL }
	  buf			  : array[1..maxd] of byte; { буфер чтения/записи }
	  rfile 		  : array[1..32] of file;   { указатели файлов чтения }
	  nam_mod		  : array[1..32] of string[40]; { имена файлов чтения }
	  mnm			  : name;
	  digits		  : array[1..16] of char;   { перекодировка }

	  tmod			  : tmodt;
	  tvmod 		  : tvmodt;
	  tex			  : textt;

	  adrzs,adrzm		  : byte;
	  flt,fls,fltp,flni,flv   : boolean;
	  wfile,pfile		  : file;
	  fprin 		  : text;
	  namfr,namfw,namfp,par   : string[40];
	  nfprin,namf		  : string;
	  pozf			  : longint;

	  kmodl,kmod,dlpb,dlext   : integer;
	  ktrel,sizect,sizev,kfm  : integer;
	  indm,indt,nmodt,kmoda   : integer;
	  i,i1,i2,it,ip,ir,znt	  : integer;
	  inex,kpb,kext,tbas,klrel: integer;

(*
	   ПРОЦЕДУРы
*)

(*
      Процедура пропуска файла
*)
  procedure FCON( var kps:integer);
   var jj :integer;
   begin
    repeat
     if kps<maxd then
       jj:=kps
      else
       jj:=maxd;
     kps:=kps-jj;
     BLOCKREAD(rfile[i],buf,jj);
    until kps=0;
   end;

(*
	     Процедура обработки модуля на 1 проходе
*)
  procedure MODUL;

   var j  :integer;

   begin
    kpb:=buf[5]*256+buf[6];	     { колич. (.) PUBL }
    kext:=buf[7]*256+buf[8];	     { колич. (.) EXT }
    dlpb:=kpb*20;
    dlext:=kext*20;
    sizect:=buf[9]*256+buf[10];      { размер кода }
(*
	Заполнение элемента таблицы TMOD
*)
    tmod[indm].hand:=i; 	     { номер файла }
    tmod[indm].nmod:=pozf;	     { позиция модуля в файле }
    tmod[indm].ykpb:=indt;
    tmod[indm].sizec:=sizect;	     { размер модуля }
    for j:=1 to 8 do		     { имя модуля }
      tmod[indm].namem[j]:=chr(mnm[j]);

(*
	Запись таблицы PUBL
*)
    tabt[indt]:=buf[5];
    tabt[indt+1]:=buf[6];	      { количество (.) PUBL }
    indt:=indt+2;
    if dlpb<>0 then
      begin
       BLOCKREAD(rfile[i],buf,dlpb);   { чтение PUBL }
       for j:=1 to dlpb do
	begin
	 tabt[indt]:=buf[j];
	 indt:=indt+1;
	end;
      end
     else			       {нет PUBL поместим точку запуска }
      if buf[15]*256+buf[16]<>0 then
       begin
	tabt[indt-1]:=1;
	for j:=1 to 16 do
	 begin
	  tabt[indt]:=mnm[j];
	  indt:=indt+1;
	 end;
	tabt[indt]:=buf[15];
	tabt[indt+1]:=buf[16];
	tabt[indt+2]:=0;
	tabt[indt+3]:=0;
	indt:=indt+4;
       end;

(*
	 Запись таблицы EXT
*)
    tmod[indm].ykext:=indt;
    tabt[indt]:=HI(kext);
    tabt[indt+1]:=LO(kext);	  { количество (.) EXT }
    indt:=indt+2;
    if dlext<>0 then
      begin
       BLOCKREAD(rfile[i],buf,dlext);	{ чтение EXT }
       for j:=1 to dlext do
	begin
	 tabt[indt]:=buf[j];
	 indt:=indt+1;
	end;
      end;

(*
    Пропуск до конца модуля
*)
    FCON(sizect);		     { пропустить код }
    BLOCKREAD(rfile[i],buf,2);	     { количество (.) REL }
    j:=(buf[1]*256+buf[2])*5+1;      { длина REL + признак конца REL }
    FCON(j);			     { пропустить REL }
    indm:=indm+1;		     { увеличить количество модулей }
   end; 	 { PROC MODUL }


(*
     Процедура выделения имени модуля из имени файла
*)
   procedure MODNAM(nam:string; var mnmd:name);

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
	  mnmd[j]:=ORD(UPCASE(ch));
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
	 Процедура первода в шестнадцатиричное символьное представление
*)
  procedure SHEST( kod,nm:integer);
   var j,kk : integer;

   begin
    kk:=kod;
    for j:=0 to 3 do
     begin
      par[nm+4-j]:=digits[kk mod 16+1];
      kk:=kk div 16;
     end;
   end; 	  { PROC SHEST }

(*
	      Процедура записи таблицы ЕХТ модуля в общую таблицу ТЕХ
*)
  procedure ZEXT;

   var kex,jp,je,jk,jt :integer;
       fle	       :boolean;

   begin
    jp:=tmod[indm].ykext;	   { указатель таблицы модуля }
    kex:=tabt[jp]*256+tabt[jp+1];  { количество (.) EXT }
    jp:=jp+1;
    if kex<>0 then
     begin
      for it:=1 to kex do	   { поиск уже записаной точки }
       begin
	fle:=false;
	if kext<>0 then
	 begin
	  jk:=1;

	  repeat
	    je:=1;

	    repeat
	      fle:=tabt[ip+je-1]=tex[jk].namext[je]; { сравнение имен }
	      je:=je+1;
	    until (je>16) or not fle;

	    jk:=jk+1;
	  until (jk>kext) or fle;
	 end;
	if not fle then 	    { такой точки нет, поместим в таблицу }
	 begin
	  kext:=kext+1; 	    { увеличить количество точек }
	  for je:=1 to 16 do
	    tex[kext].namext[je]:=tabt[jp+je];
	  tex[kext].tip:=$ff;	    { признак неопределенной точки }
	 end;
	jp:=jp+20;		    { переход к новой точке }
       end
     end;
   end; 	{ PROC	ZEXT }

(*
	  Процедура открытия файла чтения
*)
  procedure OPENR(var nf:string; ii:integer);

   var jf : integer;
{$i-}
    begin
     ASSIGN(rfile[ii],nf);
     RESET(rfile[ii],1);
     if ioresult <> 0 then
      begin
       WRITELN(' LINK  ERROR FILE ',nf);
       if ii<>1 then
	 for jf:=1 to ii-1 do	     { закрытие открытых файлоб чтения }
	   CLOSE(rfile[jf]);
       HALT(2);
     end;
    end;	{ PROC	OPENR }
{$i+}

(*
       Процедура ошибки в модуле
*)
  procedure ERRMOD;
   var jf : integer;

   begin
    WRITELN('LINK  Файл ',namf,' не объектный модуль ');
    for jf:=1 to i do	     { закрытие открытых файлов чтения }
      CLOSE(rfile[jf]);
    HALT(2);
   end; 	 { PROC ERRMOD }

(*
       Процедура ошибки в файле
*)
  procedure ERRDISK(j : integer; nf : string);
   var jf : integer;

   begin
     WRITELN(' LINK  ERROR FILE ',nf);
     for jf:=1 to kfm do	{ закрытие открытых файлов чтения }
       CLOSE(rfile[jf]);
     if j>1 then
      begin
       ERASE(wfile);
       CLOSE(wfile);
      end;
      ERASE(fprin);
      CLOSE(fprin);
      HALT(2);
   end; 	   { PROC  ERRDISK }

(*
	 Ошибка в параметрах
*)
  procedure ERRPAR;

   begin
    WRITELN(' LINK ошибка в параметрах ');

    writeln('usage: UniLink MainModule [Modules] [/L<ListFile>] [/P]');
    WRITELN('       /P - параметр выравнивания на границу $100 байт.');
    HALT(4);
   end; 	   { PROC ERRPAR }

(*
    Неопределенный идентификатор
*)
  procedure ERRNI;

   var stp : string[17];
       ji  : integer;

   begin
    stp:=' ';
    for ji:=1 to 16 do
      stp:=stp + char(tex[inex].namext[ji]);
    WRITELN(' Идентификатор ',stp,' неопределен.');
    flni:=true;
   end;

(*
	 НАЧАЛО РАБОТ

	  Блок разбора параметров
*)

begin
  writeln('UniLINK. Version 1.01. (c) 1989 "ТРИАДА".');
  digits:='0123456789ABCDEF';      { инициализация перекодировки }
  nfprin:=' ';
  ip:=PARAMCOUNT;		   { количество параметров }
  if ip<1 then ERRPAR;
  kfm:=0;
  flv:=false;			   { не выравнивать }
  for i:=1 to ip do		   { цикл разбора параметров }
   begin
    par:=PARAMSTR(i);		   { очередной параметр }
    if par[1] = '/' then
(*	задание файла печати	     *)
       if UPCASE(par[2])='P' then
	 flv:=true		   { устанавить выравнивание }
	else
	 if UPCASE(par[2])='L' then
	   begin
	    nfprin:=par;
	    DELETE(nfprin,1,2);
	   end
	  else
	   ERRPAR
     else
      begin
       kfm:=kfm+1;		   { новый модуль }
       it:=POS('.',par);           { ecть раcширение? }
       if it=0 then		   { нет }
	 par:=par+'.OBJ';
       nam_mod[kfm]:=par;
      end;
   end;
  if nfprin=' ' then
    nfprin:='CON';
  if kfm=0 then ERRPAR;

(*
      Первый проход  LINK
*)
  indm:=1;				  { индекс массива точек TABT }
  indt:=1;				  { индекс таблицы модулей TMOD }

  for i:=1 to kfm do			  { цикл по файлам }
   begin
    namf:=nam_mod[i];			  { имя очередного файла }
    OPENR(namf,i);			  { открыть файл }
(*    nmodt:=0; 			{ текущий номер модуля в библиотеке}*)
    pozf:=0;				  { позиция начала файла }
    BLOCKREAD(rfile[i],buf,32); 	  { чтение заголовка }

    MODNAM(namf,mnm);			  { выделить имя модуля из имени файла }
    if (buf[1]=$0b) and (buf[2]=$b0) then
      begin
(*
     Обработка библиотеки
*)
       kmodl:=buf[5]*256+buf[6];	   { количество модулей в библиотеке }
       for i1:=1 to kmodl do		   { цикл по модулям }
	begin
	 BLOCKREAD(rfile[i],mnm,12);	   { имя модуля и длина }
	 for i2:=9 to 16 do
	   mnm[i2]:=$20;		   { дополнить имя пробелами }
	 pozf:=FILEPOS(rfile[i]);	   { позиция модуля в файле }
	 BLOCKREAD(rfile[i],buf,32);	   { заголовок модуля }
	 nmodt:=nmodt+1;		   { номер модуля }
	 MODUL; 			   { обработать модуль }
	end;
      end

     else				   { простой модуль }
      if (buf[1]=$5a) and (buf[2]=$a5) then
	MODUL
       else
	ERRMOD;
   end; 	{ Koнец 1 прохода }
   kmoda:=indm; 			   { общее количество модулей }

(*
	    Aлгоритм установки связок
*)
  kmod:=1;			  { автоматическое включение 1 модуля }
  flni:=false;			  { флаг неопределенного идентификатора }
  tvmod[1].nom:=1;
  tvmod[1].bas:=0;		  { база модуля }
  kext:=0;			  { koличество (.) EXT }
  tbas:=tmod[1].sizec;
  if flv then
    tbas:=((tbas + $ff) div $100) * $100;  { выравнивание на границу страницы }
  indm:=1;
  ZEXT; 			  { поместить блок EXT в таблицу TEX }

(*
   Определение EXT
*)
  if kext<>0 then	      { IF0 }
   begin
    inex:=1;			  { индекс EXT }

    repeat		     {REP 1 }
      indm:=0;			  { индекс модуля в TMOD }
      flt:=false;		  { флаг найденой точки }

      repeat		      {REP 2 }
	indm:=indm+1;
	ip:=tmod[indm].ykpb;	  { указатель PUBL }
	kpb:=tabt[ip]*256+tabt[ip+1];
	ip:=ip+1;
	if kpb <> 0 then
	 begin
	  i1:=1;

	  repeat		{ REP 3 }
	    i2:=1;

	    repeat		   { REP 4 }
	      flt:=tex[inex].namext[i2] = tabt[ip+i2];	 { сравнение имен }
	      i2:=i2+1;
	    until (i2>16) or not flt;	     {END REP 4 }

	    i1:=i1+1;
	    ip:=ip+20;		     { адрес следующего EXT }
	  until (i1>kpb) or flt;  { END REP 3 }
	 end;
      until (indm>kmoda) or flt; {END REP 2 }

      if not flt then ERRNI	    { неопределен EXT }
       else
	begin	      {  IF2}
(*
	 Нашли соответствие EXT - PUBL
	  INDM - номер модуля б TMOD
	 проверяем появлялся ли модуль ранее
*)
	 ip:=ip-3;		    { индекс (.) PUBL ее адреса и типа }
	 i1:=0;
	 repeat
	   i1:=i1+1;
	   flt:=tvmod[i1].nom=indm;   { есть ли модуль в TVMOD }
	 until (i1=kmod) or flt;

	 if not flt then
	  begin
(*
	 Новый модуль помещаем его в TMOD
	  и подсоединяем его ЕХТ
*)
	   kmod:=kmod+1;
	   tvmod[kmod].nom:=indm;
	   tvmod[kmod].bas:=tbas;	{ база модуля }
	   tbas:=tbas+tmod[indm].sizec;
	   if flv then			 { выровнять? }
	     tbas:=((tbas + $ff) div $100) * $100;  { выравнивание на границу страницы }
	   ZEXT;			{ подсоединить EXT }
	   i1:=kmod;
	  end;

	 if tabt[ip+2] <> 0 then	{ проверка типа }
	   tex[inex].adr:=tabt[ip]*256+tabt[ip+1]   { CONST }
	  else
	   tex[inex].adr:=tabt[ip]*256+tabt[ip+1]+tvmod[i1].bas;  { ADRES }

	 tex[inex].tip:=tabt[ip+2];	 { тип }
	end; {	 IF2 }
      inex:=inex+1;
    until inex > kext;	  { END REP 1 }
   end; 	    { END IF 0 }

(*
      Проверка флага неопределенности
*)
  if flni then			   { были неопределенные идентификаторы }
    begin			   { завершаем рпаботу }
     for i:=1 to kfm do
       CLOSE(rfile[i]);
     WRITELN('  LINK  Аварийное завершение ');
     HALT(1);
    end;
(*
      Второй проход  LINK
*)
  namfw:=nam_mod[1];	       { получаем имя рез. файла}
  i:=POS('.',namfw);           { номер точки }
  if i<>0 then DELETE(namfw,i,4); { удалить пасшерение }
  namfp:=namfw + '.$pg';         { имя пром.файла }
  namfw:=namfw + '.pgm';
(*
	Открытие результата и пром.файла.
*)
  ASSIGN(fprin,nfprin);
  REWRITE(fprin);
  if ioresult<>0 then ERRDISK(0,nfprin);
  {$i-}
  ASSIGN(wfile,namfw);
  REWRITE(wfile,1);
  if ioresult<>0 then ERRDISK(1,namfw);

  ASSIGN(pfile,namfp);
  REWRITE(pfile,1);
  if ioresult<>0 then ERRDISK(2,namfp);

  WRITELN(fprin,'           Загрузочный модуль ',namfw);
  WRITELN;
  {$i+}
  for i:=1 to 16 do		    { цикл обнуления BUF }
    buf[i]:=0;
  BLOCKWRITE(wfile,buf,16);	    { забить заголовок }
(*
       Цикл по таблице вкл. модулей TVMOD
*)
  klrel:=0;			    { количецтво точек REL }

  for i:=1 to kmod do		    { FOR1 оcновной цикл }
   begin
    i1:=tvmod[i].nom;		     { номер в TMOD }
    i2:=tmod[i1].hand;		     { номер файла }

    if FILEPOS(rfile[i2])<>tmod[i1].nmod then
      SEEK(rfile[i2],tmod[i1].nmod);  { уcтановка файла на начало модуля }

    BLOCKREAD(rfile[i2],buf,32);     { заголовок модуля }

    if i=1 then
     begin			   { запомнить адрес запуска программы }
      adrzs:=buf[15];
      adrzm:=buf[16];
     end;

    kpb:=buf[5]*256+buf[6];	     { колич. (.) PUBL }
    kext:=buf[7]*256+buf[8];	     { колич. (.) EXT }
    dlpb:=kpb*20;
    dlext:=kext*20;
    sizect:=buf[9]*256+buf[10];      { размер кода }

    if dlpb<>0 then
      BLOCKREAD(rfile[i2],buf,dlpb);	    { пропустить PUBL }

    if dlext<>0 then
      BLOCKREAD(rfile[i2],buf,dlext);
    BLOCKREAD(rfile[i2],tabt,sizect);  { прочитали код }

    sizev:=sizect;
    if flv then
      sizev:=((sizect+$ff) div $100)* $100; { выровненый код }
      if sizev<>sizect then
	for it:=sizect+1 to sizev do
	  tabt[it]:=0;			  { дополнить код нулями }

(*
       Вывод на печать имени модуля и его базы
*)
    WRITELN(fprin,'   ',tmod[i1].namem);
    par:='            ';
    SHEST(tvmod[i].bas,1);
    ir:=tvmod[i].bas+sizect-1;
    SHEST(ir,7);
    WRITELN(fprin,'          ',par);

(*
     Цикл по точкам REL с исправлением кода
*)
    BLOCKREAD(rfile[i2],mnm,2); 	{ чтение количества точек }
    ktrel:=mnm[1]*256+mnm[2];

    if ktrel<>0 then
      for ir:=1 to ktrel do
       begin
	fltp:=true;			  { флаг типа (.) - REL }
	BLOCKREAD(rfile[i2],mnm,5);	  { элемент REL }
	znt:=mnm[2]*256+mnm[3]; 	  { значение }

	if mnm[1] < $80 then		  { простая точка }
	  znt:=znt+tvmod[i1].bas	  { базирование точки }

	 else				  { внешняя точка }
	  begin
	   znt:=znt*20; 	      { смещение б таблице EXT с нуля }
	   inex:=0;			  { индекс TEX }
(*
	 поиск внешней точки в TEX
*)
	   repeat
	     inex:=inex+1;
	     it:=1;
	     repeat
	       flt := tex[inex].namext[it] = buf[znt+it]; { признак сравнения }
	       it:=it+1;
	     until (it > 16) or not flt;     { цикл до конца или не равно }
	   until (inex = kext) or flt;	{ цикл до конца или  равно }

	   if not flt then		   { точка не найдена }
	     begin
	      fltp:=false;		    { тип CONST }
	      znt:=0;			    { значение неопределено }
	     end
	    else			    { точка  найдена }
	     begin
	      fltp:=tex[inex].tip=0;
	      znt:=tex[inex].adr;
	     end;
	  end;	    {IF}

(*
	 Исправление кода
*)
	  it:=mnm[4]*256+mnm[5]+1;	    { смещение в коде для исправления }
	  fls:=mnm[1] and 2 = 2;		   { флаг старшего байта }
	  if ODD(mnm[1]) then		     { флаг младшего байта четность }
	    tabt[it+1]:=LO(znt);	{ исправить младший байт }
	  if fls then
	   begin
	    tabt[it]:=HI(znt);	{ исправить старший байт }

	    if fltp then		    { точка REL }
	     begin
	      it:=it+tvmod[i].bas-1;	    { смещение в загрузочном модуле }
	      mnm[1]:=HI(it);
	      mnm[2]:=LO(it);
	      klrel:=klrel+1;
	      BLOCKWRITE(wfile,mnm,2);	   { вывести очередную точку }
	     end;
	   end;
       end;	 {FOR по точкам REL }

    BLOCKWRITE(pfile,tabt,sizev);	    { вывести исправленный код }
   end;       {FOR по модулям }

(*
      Переписать код из промежуточного файла в результирующий
*)
  pozf:=0;
  SEEK(pfile,pozf);			    { установить файл в начало }
  dlpb:=tbas;				    { длина кода }
  pozf:=FILEPOS(wfile); 		    { запомнить позицию рез.файла }
  repeat
    if dlpb < maxd then it:=dlpb else it:=maxd;
    dlpb:=dlpb-it;
    BLOCKREAD(pfile,tabt,it);
    BLOCKWRITE(wfile,tabt,it);
  until dlpb = 0;
(*
	Формирование и запись заголовка
*)
  buf[1]:=$a5;
  buf[2]:=$5a;
  buf[3]:=HI(klrel);
  buf[4]:=LO(klrel);
  buf[5]:=(pozf div 256) mod 256;
  buf[6]:=pozf mod 256;
  buf[7]:=HI(tbas);
  buf[8]:=LO(tbas);
  buf[9]:=adrzs;
  buf[10]:=adrzm;

  pozf:=0;
  SEEK(wfile,pozf);			    { установить файл в начало }
  BLOCKWRITE(wfile,buf,10);
(*
       Закрытие всех файлов и завершение работы
*)
  for i:=1 to kfm do
    CLOSE(rfile[i]);
  CLOSE(wfile);
  CLOSE(pfile);
  ERASE(pfile); 
  CLOSE(fprin);
  WRITELN('   LINK  Kонец работы ');
  HALT(0);
 end.
