
/************************************************/
/*						*/
/*		small-c compiler		*/
/*						*/
/*		  by Ron Cain			*/
/*						*/
/************************************************/

/* with minor mods by RDK */

#define BANNER  "Small-C V1.2 Compiler"

#define VERSION "for MC6801/HD6303"

#define AUTHOR  "by Alexander Chukov <sash@pdaXrom.org>, 2017"

#define LINE    "Based on sources by Ron Cain."


/*
#asm
	DB	'SMALL-C COMPILER V.1.2 DOS--CP/M CROSS COMPILER',0
#endasm
 */

/*	Define system dependent parameters	*/

/*	Stand-alone definitions			*/

/* INCLUDE THE LIBRARY TO COMPILE THE COMPILER (RDK) */

/* #include smallc.lib */ /* small-c library included in source now */

/* IN DOS USE THE SMALL-C OBJ LIBRARY RATHER THAN IN-LINE ASSEMBLER */

#define NULL 0
#define eol 10 /* was 13 */

/*	UNIX definitions (if not stand-alone)	*/

/* #include "stdio.h"  /* was <stdio.h> */

/* #define eol 10	*/

/*	Define the symbol table parameters	*/

#define	symsiz	16
#define	symtbsz	5760		/* 360 records */
#define numglbs 300
#define	startglb symtab
#define	endglb	startglb+numglbs*symsiz
#define	startloc endglb+symsiz
#define	endloc	symtab+symtbsz-symsiz

/*	Define symbol table entry format	*/

#define	name	0
#define	ident	11
#define	type	12
#define	storage	13
#define	offset	14

/*	System wide name size (for symbols)	*/

#define	namesize 11
#define namemax  10

/*	Define possible entries for "ident"	*/

#define	variable 1
#define	array	2
#define	pointer	3
#define	function 4

/*	Define possible entries for "type"	*/

#define	cchar	1
#define	cint	2

/* possible entries for storage */

#define PUBLIC  1
#define AUTO    2
#define EXTERN  3

#define STATIC  4
#define LSTATIC 5
#define DEFAUTO 6

/*	Define possible entries for "storage"	*/

#define	stkloc	2

/*	Define the "while" statement queue	*/

#define	wqtabsz	300
#define	wqsiz	4
#define	wqmax	wq+wqtabsz-wqsiz

/*	Define entry offsets in while queue	*/

#define	wqsym	0
#define	wqsp	1
#define	wqloop	2
#define	wqlab	3

/*	Define the literal pool			*/

#define	litabsz	8000
#define	litmax	litabsz-1

/*	Define the input line			*/

#define	linesize 80
#define	linemax	linesize-1
#define	mpmax	linemax

/*	Define the macro (define) pool		*/

#define	macqsize 3000
#define	macmax	macqsize-1

/*	Define statement types (tokens)		*/

#define	stif	1
#define	stwhile	2
#define	streturn 3
#define	stbreak	4
#define	stcont	5
#define	stasm	6
#define	stexp	7
#define STDO 8
#define STFOR 9
#define STSWITCH 10
/* #define STGOTO 11 */
#define STCASE 12
#define STDEF 13
/* #define STLABEL 14 */

/* Define how to carve up a name too long for the assembler */

#define asmpref	7
#define asmsuff	7

/*	Now reserve some storage words		*/

char	symtab[symtbsz];	/* symbol table */
char	*glbptr,*locptr;		/* ptrs to next entries */

int	wq[wqtabsz];		/* while queue */
int	*wqptr;			/* ptr to next entry */

char	litq[litabsz];		/* literal pool */
int	litptr;			/* ptr to next entry */

char	macq[macqsize];		/* macro string buffer */
int	macptr;			/* and its index */

char	line[linesize];		/* parsing buffer */
char	mline[linesize];	/* temp macro buffer */
int	lptr,mptr;		/* ptrs into each */

/*	Misc storage	*/

int	nxtlab,		/* next avail label # */
	litlab,		/* label # assigned to literal pool */
	Zsp,		/* compiler relative stk ptr */
	argstk,		/* function arg counter */
	argscnt,	/* function arg sp */
	ncmp,		/* # open compound statements */
	errcnt,		/* # errors in compilation */
	errstop,	/* stop on error			gtf 7/17/80 */
	opcodebug,	/* show opcodes in output file */
	eof,		/* set non-zero on final input eof */
	input,		/* iob # for input file */
	output,		/* iob # for output file (if any) */
	input2,		/* iob # for "include" file */
	glbflag,	/* non-zero if internal globals */
	ctext,		/* non-zero to intermix c-source */
	cmode,		/* non-zero while parsing c-code */
			/* zero when passing assembly code */
	optabi,		/* optimization for argument sizes (strong */
			/* casting for function args) */
	binout,		/* non relative code, for cmd/rom files */
	lastst,		/* last executed statement type */
	mainflg,	/* output is to be first asm file	gtf 4/9/80 */
	saveout,	/* holds output ptr when diverted to console	   */
			/*					gtf 7/16/80 */
	fnstart,	/* line# of start of current fn.	gtf 7/2/80 */
	lineno,		/* line# in current file		gtf 7/2/80 */
	infunc,		/* "inside function" flag		gtf 7/2/80 */
	savestart,	/* copy of fnstart "	"		gtf 7/16/80 */
	saveline,	/* copy of lineno  "	"		gtf 7/16/80 */
	saveinfn;	/* copy of infunc  "	"		gtf 7/16/80 */

char   *currfn,		/* ptr to symtab entry for current fn.	gtf 7/17/80 */
       *savecurr;	/* copy of currfn for #include		gtf 7/17/80 */
char	quote[2];	/* literal string for '"' */
char	*cptr;		/* work ptr to any char buffer */
int	*iptr;		/* work ptr to any int buffer */

int argcs;
char **argvs;     /* statig argc and argv */

/*	>>>>> start cc1 <<<<<<		*/

/*					*/
/*	Compiler begins execution here	*/
/*					*/
main(argc, argv)
int argc;
char *argv[];
{
	argcs=argc;
	argvs=argv;
	glbptr=startglb;	/* clear global symbols */
	locptr=startloc;	/* clear local symbols */
	wqptr=wq;		/* clear while queue */
	macptr=		/* clear the macro pool */
	litptr=		/* clear literal pool */
  	Zsp =		/* stack ptr (relative) */
	errcnt=		/* no errors */
	errstop=	/* keep going after an error		gtf 7/17/80 */
	eof=		/* not eof yet */
	input=		/* no input file */
	input2=		/* or include file */
	output=		/* no open units */
	saveout=	/* no diverted output */
	ncmp=		/* no open compound states */
	lastst=		/* no last statement yet */
	mainflg=	/* not first file to asm 		gtf 4/9/80 */
	fnstart=	/* current "function" started at line 0 gtf 7/2/80 */
	lineno=		/* no lines read from file		gtf 7/2/80 */
	infunc=		/* not in function now			gtf 7/2/80 */
	quote[1]=
	0;		/*  ...all set to zero.... */
	quote[0]='"';		/* fake a quote literal */
	currfn=NULL;	/* no function yet			gtf 7/2/80 */
	cmode=1;	/* enable preprocessing */
	/*				*/
	/*	compiler body		*/
	/*				*/
	ask();			/* get user options */
	header();		/* intro code */
	parse(); 		/* process ALL input */
	dumplits();		/* then dump literal pool */
	dumpglbs();		/* and all static memory */
	trailer();		/* follow-up code */
	closeout();		/* close the output (if any) */
	errorsummary();		/* summarize errors (on console!) */
	if ((ncmp != 0) | (errcnt != 0)) return 1;
	else return 0;			/* then exit to system */
}

/*					*/
/*	Abort compilation		*/
/*		gtf 7/17/80		*/
zabort()
{
	if(input2)
		endinclude();
	if(input)
		fclose(input);
	closeout();
	toconsole();
	pl("Compilation aborted.");  nl();
	exit(1);
/* end zabort */}

/*					*/
/*	Process all input text		*/
/*					*/
/* At this level, only static declarations, */
/*	defines, includes, and function */
/*	definitions are legal...	*/
parse()
{
	while (eof==0) {		/* do until no more input */
		if (amatch("extern", 6))
		    dodcls(EXTERN);
		else if (amatch("static", 6))
		    dodcls(STATIC);
		else if (dodcls(PUBLIC));
//		if(amatch("char",4)){declglb(cchar);ns();}
//		else if(amatch("int",3)){declglb(cint);ns();}
		else if(match("#asm"))
		    doasm();
		else if(match("#include"))
		    doinclude();
		else if(match("#define"))
		    addmac();
		else newfunc();
		blanks();	/* force eof if pending */
	}
}

dodcls(stclass)
int stclass;
{
    blanks();
    if (amatch("char", 4))
        declglb(cchar, stclass);
    else if (amatch("int", 3))
        declglb(cint, stclass);
    else if (stclass == PUBLIC)
        return (0);
    else
        declglb(cint, stclass);
    ns();
    return (1);
}

/*					*/
/*	Dump the literal pool		*/
/*					*/
dumplits()
	{int j,k;
	if (litptr==0) return;	/* if nothing there, exit...*/
	printlabel(litlab);	/* print literal label */
	k=0;			/* init an index... */
	while (k<litptr)	/* 	to loop with */
		{defbyte();	/* pseudo-op to define byte */
		j=10;		/* max bytes per line */
		while(j--)
			{outdec((litq[k++]&127));
			if ((j==0) | (k>=litptr))
				{nl();		/* need <cr> */
				break;
				}
			outbyte(',');	/* separate bytes */
			}
		}
	}
/*					*/
/*	Dump all static variables	*/
/*					*/
dumpglbs() {
	int j;
	if(glbflag==0)return;	/* don't if user said no */
	cptr=startglb;
	while (cptr < glbptr) {
		defpublic(cptr);
		if (cptr[ident] != function) {
		    if (cptr[storage] != EXTERN) {
			/* do if anything but function */
			outname(cptr); /* col(); */
				/* output name as label... */
			defstorage();	/* define storage */
			j=((cptr[offset]&255)+
				((cptr[offset+1]&255)<<8));
					/* calc # bytes */
			if((cptr[type]==cint)|
				(cptr[ident]==pointer))
				j=j+j;
			outdec(j);	/* need that many */
			nl();
		    }
		}
		cptr=cptr+symsiz;
	}
}
/*					*/
/*	Report errors for user		*/
/*					*/
errorsummary()
	{
	/* see if anything left hanging... */
	if (ncmp) error("missing closing bracket");
		/* open compound statement ... */
	nl();
	outstr("There were ");
	outdec(errcnt);	/* total # errors */
	outstr(" errors in compilation.");
	nl();
	}
/*					*/
/*	Get options from user		*/
/*					*/
ask()
	{
	int i;
	char *argptr;
	int k,num[1];
	kill();			/* clear input line */
	outbyte(12);		/* clear the screen */
	nl();nl();		/* print banner */
	pl(LINE);
	pl(BANNER);
	pl(AUTHOR);
	pl(VERSION);
	pl(LINE);
	nl();nl();
	glbflag=1;	/* define globals */
	mainflg=1;	/* first file to assembler */
	nxtlab =0;	/* start numbers at lowest possible */
	ctext=0;		/* assume no */
	errstop=0;
	opcodebug = 0;
	optabi = 0;
	binout = 0;

	i = 0;
	while (--argcs) {
		argptr=argvs[++i];
		if(*argptr == '-') {
			if (*++argptr == 'o') {
				argcs--;
				if((output=fopen(argvs[++i],"w"))==NULL) {
					error("output file errrpt");
					exit(1);
				} else continue;
			} else if (*argptr == 'f') {
				if (*++argptr == 'c') {
				    ctext = 1;
				    continue;
				} else if (*argptr == 'p') {
				    errstop = 1;
				    continue;
				} else if (*argptr == 'o') {
				    opcodebug = 1;
				    continue;
				} else if (*argptr == 'b') {
				    binout = 1;
				    continue;
				}
			} else if (*argptr == 'O') {
				if (*++argptr == 'a') {
				    if ((argptr[1] == 'b') & (argptr[2] == 'i')) {
					optabi = 1;
					continue;
				    }
				}
			}
			error("unknown option!");
			exit(1);
		} else {
			if((input=fopen(argptr,"r"))==NULL) {
				error("input file error!");
				exit(1);
			} else newfile();
		}
	}

	if (input == 0) {
		error("No input file!\n");
		exit(1);
	}

	if (output == 0) {
		if((output = fopen("out.asm", "w")) == NULL) {
			error("output file errrpt");
			exit(1);
		}
	}

	litlab=getlabel();	/* first label=literal pool */ 
	kill();			/* erase line */
}

/*					*/
/*	Reset line count, etc.		*/
/*			gtf 7/16/80	*/
newfile()
{
	lineno  = 0;	/* no lines read */
	fnstart = 0;	/* no fn. start yet. */
	currfn  = NULL;	/* because no fn. yet */
	infunc  = 0;	/* therefore not in fn. */
/* end newfile */}

/*					*/
/*	Open an include file		*/
/*					*/
doinclude()
{
	blanks();	/* skip over to name */

	toconsole();					/* gtf 7/16/80 */
	outstr("#include "); outstr(line+lptr); nl();
	tofile();

	if(input2)					/* gtf 7/16/80 */
		error("Cannot nest include files");
	else if((input2=fopen(line+lptr,"r"))==NULL)
		{input2=0;
		error("Open failure on include file");
		}
	else {	saveline = lineno;
		savecurr = currfn;
		saveinfn = infunc;
		savestart= fnstart;
		newfile();
		}
	kill();		/* clear rest of line */
			/* so next read will come from */
			/* new file (if open */
}

/*					*/
/*	Close an include file		*/
/*			gtf 7/16/80	*/
endinclude()
{
	toconsole();
	outstr("#end include"); nl();
	tofile();

	input2  = 0;
	lineno  = saveline;
	currfn  = savecurr;
	infunc  = saveinfn;
	fnstart = savestart;
/* end endinclude */}

/*					*/
/*	Close the output file		*/
/*					*/
closeout()
{
	tofile();	/* if diverted, return to file */
	if(output)fclose(output); /* if open, close it */
	output=0;		/* mark as closed */
}
/*					*/
/*	Declare a static variable	*/
/*	  (i.e. define for use)		*/
/*					*/
/* makes an entry in the symbol table so subsequent */
/*  references can call symbol by name	*/
declglb(typ, stor)		/* typ is cchar or cint */
	int typ,
	    stor;
{	
	int k,j;
	char sname[namesize];
	while(1) {
		while(1) {
			if(endst())return;	/* do line */
			k=1;		/* assume 1 element */
			if(match("*"))	/* pointer ? */
				j=pointer;	/* yes */
			else j=variable; /* no */
			if (symname(sname)==0) /* name ok? */
				illname(); /* no... */
			if(findglb(sname)) /* already there? */
				multidef(sname);
			if(match("()"))  j = function;
			else if (match("[")) {		/* array? */
				k=needsub();	/* get size */
				if((k != 0) | (stor == EXTERN)) j=array;	/* !0=array */
				else j=pointer; /* 0=ptr */
			}
			if (stor == EXTERN) {
				defextern();
				outname(sname);
				nl();
			}
			addglb(sname, j, typ, k, stor); /* add symbol */
			break;
		}
		if (match(",")==0) return; /* more? */
	}
}
/*					*/
/*	Declare local variables		*/
/*	(i.e. define for use)		*/
/*					*/
/* works just like "declglb" but modifies machine stack */
/*	and adds symbol table entry with appropriate */
/*	stack offset to find it again			*/
declloc(typ)		/* typ is cchar or cint */
	int typ;
	{
	int k,j;char sname[namesize];
	while(1)
		{while(1)
			{if(endst())return;
			if(match("*"))
				j=pointer;
				else j=variable;
			if (symname(sname)==0)
				illname();
			if(findloc(sname))
				multidef(sname);
			if (match("["))
				{k=needsub();
				if(k)
					{j=array;
					if(typ==cint)k=k+k;
					}
				else
					{j=pointer;
					k=2;
					}
				}
			else
				if((typ==cchar)
					&(j!=pointer))
					k=1;else k=2;
			/* change machine stack */
			Zsp=modstk(Zsp-k);
			addloc(sname,j,typ,Zsp);
			break;
			}
		if (match(",")==0) return;
		}
	}
/*	>>>>>> start of cc2 <<<<<<<<	*/

/*					*/
/*	Get required array size		*/
/*					*/
/* invoked when declared variable is followed by "[" */
/*	this routine makes subscript the absolute */
/*	size of the array. */
needsub()
	{
	int num[1];
	if(match("]"))return 0;	/* null size */
	if (number(num)==0)	/* go after a number */
		{error("must be constant");	/* it isn't */
		num[0]=1;		/* so force one */
		}
	if (num[0]<0)
		{error("negative size illegal");
		num[0]=(-num[0]);
		}
	needbrack("]");		/* force single dimension */
	return num[0];		/* and return size */
	}
/*					*/
/*	Begin a function		*/
/*					*/
/* Called from "parse" this routine tries to make a function */
/*	out of what follows.	*/
newfunc()
{
	char *argsptr;
	char n[namesize];	/* ptr => currfn,  gtf 7/16/80 */
	if (symname(n)==0)
		{error("illegal function or declaration");
		kill();	/* invalidate line */
		return;
		}
	fnstart=lineno;		/* remember where fn began	gtf 7/2/80 */
	infunc=1;		/* note, in function now.	gtf 7/16/80 */
	if(currfn=findglb(n))	/* already in symbol table ? */
		{if(currfn[ident]!=function)multidef(n);
			/* already variable by that name */
		else if(currfn[offset]==function)multidef(n);
			/* already function by that name */
		else currfn[offset]=function;
			/* otherwise we have what was earlier*/
			/*  assumed to be a function */
		}
	/* if not in table, define as a function now */
	else currfn=addglb(n, function, cint, function, PUBLIC);

	toconsole();					/* gtf 7/16/80 */
	outstr("====== "); outstr(currfn+name); outstr("()"); nl();
	tofile();

	/* we had better see open paren for args... */
	if(match("(")==0)error("missing open paren");
	outname(n);
	outasm(" proc");
	nl();	/* print function name */
	argstk=0;		/* init arg count */
	while(match(")")==0) {
		/* then count args */
		/* any legal name bumps arg count */
		if (symname(n)) argstk=argstk + 1;
		else {
			error("illegal argument name");
			junk();
		}
		blanks();
		/* if not closing paren, should be comma */
		if(streq(line+lptr,")")==0) {
			if(match(",")==0) error("expected comma");
		}
		if(endst())break;
	}

	locptr=startloc;	/* "clear" local symbol table*/
	Zsp=0;			/* preset stack ptr */

	argscnt = 0;

	while(argstk) {
		/* now let user declare what types of things */
		/*	those arguments were */
		if (amatch("char",4)) {
			getarg(cchar);
			ns();
		} else if (amatch("int",3)) {
			getarg(cint);
			ns();
		} else {
			error("wrong number args");
			break;
		}
	}

	argsptr = locptr - symsiz;

	/* skip function return address */
	argstk = 2;
	argscnt = argscnt + 2;

	/* Fix local table args offsets */
	 while (argstk != argscnt) {
		if ((argsptr[ident] == variable) & (argsptr[type] == cchar) & (optabi == 0)) {
		    argstk = argstk + 1;
		}
		argsptr[offset]     = argstk & 255;
		argsptr[offset + 1] = argstk >> 8;
		if ((argsptr[ident] == variable) & (argsptr[type] == cchar)) {
		    fprintf(output, "; -- CHAR\t+%d\n", argstk);
		    argstk = argstk + 1;
		} else {
		    fprintf(output, "; -- INT\t+%d\n", argstk);
		    argstk = argstk + 2;
		}
		argsptr = argsptr - symsiz;
	}

	if(statement()!=streturn) /* do a statement, but if */
				/* it's a return, skip */
				/* cleaning up the stack */
	{
		modstk(0);
		zret();
	}
	Zsp=0;			/* reset stack ptr again */
	locptr=startloc;	/* deallocate all locals */
	infunc=0;		/* not in fn. any more		gtf 7/2/80 */
	ol("endp");
}

/*					*/
/*	Declare argument types		*/
/*					*/
/* called from "newfunc" this routine adds an entry in the */
/*	local symbol table for each named argument */
getarg(t)		/* t = cchar or cint */
	int t;
{
	char n[namesize],c;
	int j;

	while(1) {
		if (argstk==0) return;	/* no more args */
		if (match("*")) j=pointer;
		else j=variable;
		if(symname(n)==0) illname();
		if(findloc(n)) multidef(n);
		if(match("["))	/* pointer ? */
		/* it is a pointer, so skip all */
		/* stuff between "[]" */
		{
		    while(inbyte()!=']')
			if(endst())break;
			    j=pointer;
			/* add entry as pointer */
		}
		addloc(n,j,t,argstk << 1); /* argstk is not used now */

		if ((t == cchar) & (j == variable) & (optabi != 0)) argscnt = argscnt + 1;
		else argscnt = argscnt + 2;

		argstk = argstk - 1;	/* cnt down */
		if(endst()) return;
		if(match(",")==0) error("expected comma");
	}
}

/*					*/
/*	Statement parser		*/
/*					*/
/* called whenever syntax requires	*/
/*	a statement. 			 */
/*  this routine performs that statement */
/*  and returns a number telling which one */
statement()
{
        /* NOTE (RDK) --- On DOS there is no CPM function so just try */
        /* commenting it out for the first test compilation to see if */
        /* the compiler basic framework works OK in the DOS environment */
	/* if(cpm(11,0) & 1)	/* check for ctrl-C gtf 7/17/80 */
		/* if(getchar()==3) */
			/* zabort(); */

	if ((ch()==0) & (eof)) return;
	else if(match("{")) 		compound();
	else if(amatch("char",4))	{ declloc(cchar);ns(); }
	else if(amatch("int",3))	{ declloc(cint);ns();  }
	else if(amatch("if",2))		{ doif();lastst=stif; }
	else if(amatch("do",2))		{ dodo();ns();lastst=STDO; }
	else if(amatch("for",3))	{ dofor();lastst=STFOR; }
	else if(amatch("while",5))	{ dowhile();lastst=stwhile; }
	else if(amatch("return",6))	{ doreturn();ns();lastst=streturn; }
	else if(amatch("break",5))	{ dobreak();ns();lastst=stbreak; }
	else if(amatch("continue",8))	{ docont();ns();lastst=stcont; }
	else if(match(";"));
	else if(match("#asm"))		{ doasm();lastst=stasm; }
	/* if nothing else, assume it's an expression */
	else { expression();ns();lastst=stexp; }
	return lastst;
}
/*					*/
/*	Semicolon enforcer		*/
/*					*/
/* called whenever syntax requires a semicolon */
ns()	{if(match(";")==0)error("missing semicolon");}
/*					*/
/*	Compound statement		*/
/*					*/
/* allow any number of statements to fall between "{}" */
compound()
	{
	++ncmp;		/* new level open */
	while (match("}")==0) statement(); /* do one */
	--ncmp;		/* close current level */
	}

dodo() {
	int wq[wqsiz], wqtop;
	wq[wqsym]=locptr;	/* record local level */
	wq[wqsp]=Zsp;		/* and stk ptr */
	wqtop=getlabel();	/* and top label */
	wq[wqloop]=getlabel();	/* and looping label */
	wq[wqlab]=getlabel();	/* and exit label */
	addwhile(wq);		/* add entry to queue */
				/* (for "break" statement) */
	printlabel(wqtop); nl();
	statement();
	Zsp = modstk(wq[wqsp]);	/* zap local vars: 9/25/80 gtf */
	needbrack("while");
	printlabel(wq[wqloop]); nl();
	test(wq[wqlab],1);
	jump(wqtop);
	printlabel(wq[wqlab]); nl();
	delwhile();
}

dofor() {
	int wq[wqsiz], wqtop, wqfor;
	wq[wqsym]=locptr;	/* record local level */
	wq[wqsp]=Zsp;		/* and stk ptr */
	wqtop=getlabel();	/* and top label */
	wq[wqloop]=getlabel();	/* and looping label */
	wqfor=getlabel();	/* label for for */
	wq[wqlab]=getlabel();	/* and exit label */
	addwhile(wq);		/* add entry to queue */
				/* (for "break" statement) */
	needbrack("(");
	if (match(";") == 0) {
		doexpression();
		ns();
	}
	printlabel(wqtop); nl();
	if (match(";") == 0) {
		test(wq[wqlab], 0);
		ns();
	}
	jump(wqfor);
	printlabel(wq[wqloop]); nl();
	if (match(")") == 0) {
		doexpression();
		needbrack(")");
	}
	jump(wqtop);
	printlabel(wqfor); nl();
	statement();
	Zsp = modstk(wq[wqsp]);	/* zap local vars: 9/25/80 gtf */
	jump(wq[wqloop]);
	printlabel(wq[wqlab]); nl();
	delwhile();
}

/*					*/
/*		"if" statement		*/
/*					*/
doif()
{
	int flev,fsp,flab1,flab2;
	flev=locptr;			/* record current local level */
	fsp=Zsp;			/* record current stk ptr */
	flab1=getlabel();		/* get label for false branch */
	test(flab1, 1);			/* get expression, and branch false */
	statement();			/* if true, do a statement */
	Zsp=modstk(fsp);		/* then clean up the stack */
	locptr=flev;			/* and deallocate any locals */
	if (amatch("else",4)==0) {	/* if...else ? */
		/* simple "if"...print false label */
		printlabel(flab1); nl(); /* col();nl(); */
		return;			/* and exit */
	}
	/* an "if...else" statement. */
	jump(flab2=getlabel());		/* jump around false code */
	printlabel(flab1); nl();	/* col();nl() */;	/* print false label */
	statement();			/* and do "else" clause */
	Zsp=modstk(fsp);		/* then clean up stk ptr */
	locptr=flev;			/* and deallocate locals */
	printlabel(flab2); nl();	/* col();nl(); */	/* print true label */
}

/*					*/
/*	"while" statement		*/
/*					*/
dowhile()
{
	int wq[wqsiz];		/* allocate local queue */
	wq[wqsym]=locptr;	/* record local level */
	wq[wqsp]=Zsp;		/* and stk ptr */
	wq[wqloop]=getlabel();	/* and looping label */
	wq[wqlab]=getlabel();	/* and exit label */
	addwhile(wq);		/* add entry to queue */
				/* (for "break" statement) */
	printlabel(wq[wqloop]); nl(); /*col();nl(); loop label */
	test(wq[wqlab], 1);	/* see if true */
	statement();		/* if so, do a statement */
	Zsp = modstk(wq[wqsp]);	/* zap local vars: 9/25/80 gtf */
	jump(wq[wqloop]);	/* loop to label */
	printlabel(wq[wqlab]); nl();  /* col();nl(); exit label */
	locptr=wq[wqsym];	/* deallocate locals */
	delwhile();		/* delete queue entry */
}

/*					*/
/*	"return" statement		*/
/*					*/
doreturn()
	{
	/* if not end of statement, get an expression */
	if(endst()==0)expression();
	modstk(0);	/* clean up stk */
	zret();		/* and exit function */
	}
/*					*/
/*	"break" statement		*/
/*					*/
dobreak()
	{
	int *ptr;
	/* see if any "whiles" are open */
	if ((ptr=readwhile())==0) return;	/* no */
	modstk((ptr[wqsp]));	/* else clean up stk ptr */
	jump(ptr[wqlab]);	/* jump to exit label */
	}
/*					*/
/*	"continue" statement		*/
/*					*/
docont()
	{
	int *ptr;
	/* see if any "whiles" are open */
	if ((ptr=readwhile())==0) return;	/* no */
	modstk((ptr[wqsp]));	/* else clean up stk ptr */
	jump(ptr[wqloop]);	/* jump to loop label */
	}
/*					*/
/*	"asm" pseudo-statement		*/
/*					*/
/* enters mode where assembly language statement are */
/*	passed intact through parser	*/
doasm()
	{
	cmode=0;		/* mark mode as "asm" */
	while (1)
		{_inline();	/* get and print lines */
		if (match("#endasm")) break;	/* until... */
		if(eof)break;
		outstr(line);
		nl();
		}
	kill();		/* invalidate line */
	cmode=1;		/* then back to parse level */
	}
/*	>>>>> start of cc3 <<<<<<<<<	*/

/*					*/
/*	Perform a function call		*/
/*					*/
/* called from heir11, this routine will either call */
/*	the named function, or if the supplied ptr is */
/*	zero, will call the contents of HL		*/
callfunction(ptr)
	char *ptr;	/* symbol table entry (or 0) */
{
	int cargs;
	int nargs;
	nargs = 0;
	cargs = 1;

	blanks();	/* already saw open paren */

	if(ptr==0)zpush();	/* calling HL */

	while(streq(line+lptr,")")==0) {
		int t;
		if(endst())break;
		t = expression();	/* get an argument */
		if(ptr==0)swapstk(); /* don't push addr */

		if ((t == cchar) & (optabi != 0)) {
			zpushchar();
			nargs=nargs+1;	/* count args*2 */
		} else {
			zpush();	/* push argument */
			nargs=nargs+2;	/* count args*2 */
		}
		if (match(",")==0) break;
		cargs = cargs + 1;
	}
	needbrack(")");
	setargsize(nargs);
	if(ptr)zcall(ptr);
	else callstk();
	Zsp=modstk(Zsp+nargs);	/* clean up arguments */
}

junk()
{	if(an(inbyte()))
		while(an(ch()))gch();
	else while(an(ch())==0)
		{if(ch()==0)break;
		gch();
		}
	blanks();
}
endst()
{	blanks();
	return ((streq(line+lptr,";")|(ch()==0)));
}
illname()
{	error("illegal symbol name");junk();}
multidef(sname)
	char *sname;
{	error("already defined");
	comment();
	outstr(sname);nl();
}
needbrack(str)
	char *str;
{	if (match(str)==0)
		{error("missing bracket");
		comment();outstr(str);nl();
		}
}
needlval()
{	error("must be lvalue");
}
findglb(sname)
	char *sname;
{	char *ptr;
	ptr=startglb;
	while(ptr!=glbptr)
		{if(astreq(sname,ptr,namemax))return ptr;
		ptr=ptr+symsiz;
		}
	return 0;
}
findloc(sname)
	char *sname;
{	char *ptr;
	ptr=startloc;
	while(ptr!=locptr)
		{if(astreq(sname,ptr,namemax))return ptr;
		ptr=ptr+symsiz;
		}
	return 0;
}
addglb(sname, id, typ, value, stor)
	char *sname,id,typ;
	int value,
	    stor;
{
	char *ptr;
	if(cptr=findglb(sname)) return cptr;
	if(glbptr>=endglb) {
		error("global symbol table overflow");
		return 0;
	}
	cptr=ptr=glbptr;
	while(an(*ptr++ = *sname++));	/* copy name */
	cptr[ident]=id;
	cptr[type]=typ;
	cptr[storage]=stor;
	cptr[offset]=value;
	cptr[offset+1]=value>>8;
	glbptr=glbptr+symsiz;
	return cptr;
}
addloc(sname,id,typ,value)
	char *sname,id,typ;
	int value;
{	char *ptr;
	if(cptr=findloc(sname))return cptr;
	if(locptr>=endloc)
		{error("local symbol table overflow");
		return 0;
		}
	cptr=ptr=locptr;
	while(an(*ptr++ = *sname++));	/* copy name */
	cptr[ident]=id;
	cptr[type]=typ;
	cptr[storage]=stkloc;
	cptr[offset]=value;
	cptr[offset+1]=value>>8;
	locptr=locptr+symsiz;
	return cptr;
}
/* Test if next input string is legal symbol name */
symname(sname)
	char *sname;
{	int k;char c;
	blanks();
	if(alpha(ch())==0)return 0;
	k=0;
	while(an(ch()))sname[k++]=gch();
	sname[k]=0;
	return 1;
	}
/* Return next avail internal label number */
getlabel()
{	return(++nxtlab);
}
/* Print specified number as label */
printlabel(label)
	int label;
{
	outasm("cc");
	outdec(label);
}
/* Test if given character is alpha */
alpha(c)
	char c;
{	c=c&127;
	return(((c>='a')&(c<='z'))|
		((c>='A')&(c<='Z'))|
		(c=='_'));
}
/* Test if given character is numeric */
numeric(c)
	char c;
{	c=c&127;
	return((c>='0')&(c<='9'));
}
/* Test if given character is alphanumeric */
an(c)
	char c;
{	return((alpha(c))|(numeric(c)));
}
/* Print a carriage return and a string only to console */
pl(str)
	char *str;
{	int k;
	k=0;
	putchar(eol);
	while(str[k])putchar(str[k++]);
}
addwhile(ptr)
	int ptr[];
 {
	int k;
	if (wqptr==wqmax)
		{error("too many active whiles");return;}
	k=0;
	while (k<wqsiz)
		{*wqptr++ = ptr[k++];}
}
delwhile()
	{if(readwhile()) wqptr=wqptr-wqsiz;
	}
readwhile()
 {
	if (wqptr==wq){error("no active whiles");return 0;}
	else return (wqptr-wqsiz);
 }
ch()
{	return(line[lptr]&127);
}
nch()
{	if(ch()==0)return 0;
		else return(line[lptr+1]&127);
}
gch()
{	if(ch()==0)return 0;
		else return(line[lptr++]&127);
}
kill()
{	lptr=0;
	line[lptr]=0;
}
inbyte()
{
	while(ch()==0)
		{if (eof) return 0;
		_inline();
		preprocess();
		}
	return gch();
}
inchar()
{
	if(ch()==0)_inline();
	if(eof)return 0;
	return(gch());
}
_inline()
{
	int k,unit;
	while(1)
		{if (input==0) eof=1;
		if(eof)return;
		if((unit=input2)==0)unit=input;
		kill();
		while((k=getc(unit))>0)
			{if((k==eol)|(lptr>=linemax))break;
			line[lptr++]=k;
			}
		line[lptr]=0;	/* append null */
		lineno++;	/* read one more line		gtf 7/2/80 */
		if(k<=0)
			{fclose(unit);
			if(input2)endinclude();		/* gtf 7/16/80 */
				else input=0;
			}
		if(lptr)
			{if((ctext)&(cmode))
				{comment();
				outstr(line);
				nl();
				}
			lptr=0;
			return;
			}
		}
}
/*	>>>>>> start of cc4 <<<<<<<	*/

keepch(c)
	char c;
{	mline[mptr]=c;
	if(mptr<mpmax)mptr++;
	return c;
}
preprocess()
{	int k;
	char c,sname[namesize];
	if(cmode==0)return;
	mptr=lptr=0;
	while(ch())
		{if((ch()==' ')|(ch()==9))
			{keepch(' ');
			while((ch()==' ')|
				(ch()==9))
				gch();
			}
		else if(ch()=='"')
			{keepch(ch());
			gch();
			while(ch()!='"')
				{if(ch()==0)
				  {error("missing quote");
				  break;
				  }
				keepch(gch());
				}
			gch();
			keepch('"');
			}
		else if(ch()==39)
			{keepch(39);
			gch();
			while(ch()!=39)
				{if(ch()==0)
				  {error("missing apostrophe");
				  break;
				  }
				keepch(gch());
				}
			gch();
			keepch(39);
			}
		else if((ch()=='/')&(nch()=='*'))
			{inchar();inchar();
			while(((ch()=='*')&
				(nch()=='/'))==0)
				{if(ch()==0)_inline();
					else inchar();
				if(eof)break;
				}
			inchar();inchar();
			}
		else if(alpha(ch()))	/* from an(): 9/22/80 gtf */
			{k=0;
			while(an(ch()))
				{if(k<namemax)sname[k++]=ch();
				gch();
				}
			sname[k]=0;
			if(k=findmac(sname))
				while(c=macq[k++])
					keepch(c);
			else
				{k=0;
				while(c=sname[k++])
					keepch(c);
				}
			}
		else keepch(gch());
		}
	keepch(0);
	if(mptr>=mpmax)error("line too long");
	lptr=mptr=0;
	while(line[lptr++]=mline[mptr++]);
	lptr=0;
	}
addmac()
{	char sname[namesize];
	int k;
	if(symname(sname)==0)
		{illname();
		kill();
		return;
		}
	k=0;
	while(putmac(sname[k++]));
	while(ch()==' ' | ch()==9) gch();
	while(putmac(gch()));
	if(macptr>=macmax)error("macro table full");
	}
putmac(c)
	char c;
{	macq[macptr]=c;
	if(macptr<macmax)macptr++;
	return c;
}
findmac(sname)
	char *sname;
{	int k;
	k=0;
	while(k<macptr)
		{if(astreq(sname,macq+k,namemax))
			{while(macq[k++]);
			return k;
			}
		while(macq[k++]);
		while(macq[k++]);
		}
	return 0;
}
/* direct output to console		gtf 7/16/80 */
toconsole()
{
	saveout = output;
	output = 0;
/* end toconsole */}

/* direct output back to file		gtf 7/16/80 */
tofile()
{
	if(saveout)
		output = saveout;
	saveout = 0;
/* end tofile */}

outbyte(c)
	char c;
{
	if(c==0)return 0;
	if(output)
		{if((putc(c,output))<=0)
			{closeout();
			error("Output file error");
			zabort();			/* gtf 7/17/80 */
			}
		}
	else putchar(c);
	return c;
}
outstr(ptr)
	char ptr[];
 {
	int k;
	k=0;
	while(outbyte(ptr[k++]));
 }

/* write text destined for the assembler to read */
/* (i.e. stuff not in comments)			*/
/*  gtf  6/26/80 */
outasm(ptr)
char *ptr;
{
	while(outbyte(raise(*ptr++)));
/* end outasm */}

nl()
	{outbyte(eol);}
tab()
	{outbyte(9);}
col()
	{outbyte(58);}
bell()				/* gtf 7/16/80 */
	{outbyte(7);}
/*				replaced 7/2/80 gtf
 * error(ptr)
 *	char ptr[];
 * {
 *	int k;
 *	comment();outstr(line);nl();comment();
 *	k=0;
 *	while(k<lptr)
 *		{if(line[k]==9) tab();
 *			else outbyte(' ');
 *		++k;
 *		}
 *	outbyte('^');
 *	nl();comment();outstr("******  ");
 *	outstr(ptr);
 *	outstr("  ******");
 *	nl();
 *	++errcnt;
 * }
 */

error(ptr)
char ptr[];
{	int k;
	char junk[81];

	toconsole();
	bell();
	outstr("Line "); outdec(lineno); outstr(", ");
	if(infunc==0)
		outbyte('(');
	if(currfn==NULL)
		outstr("start of file");
	else	outstr(currfn+name);
	if(infunc==0)
		outbyte(')');
	outstr(" + ");
	outdec(lineno-fnstart);
	outstr(": ");  outstr(ptr);  nl();

	outstr(line); nl();

	k=0;	/* skip to error position */
	while(k<lptr){
		if(line[k++]==9)
			tab();
		else	outbyte(' ');
		}
	outbyte('^');  nl();
	++errcnt;

	if(errstop){
		pl("Continue (Y,n,g) ? ");
		gets(junk);		
		k=junk[0];
		if((k=='N') | (k=='n'))
			zabort();
		if((k=='G') | (k=='g'))
			errstop=0;
		}
	tofile();
/* end error */}

ol(ptr)
	char ptr[];
{
	ot(ptr);
	nl();
}
ot(ptr)
	char ptr[];
{
	tab();
	outasm(ptr);
}
streq(str1,str2)
	char str1[],str2[];
 {
	int k;
	k=0;
	while (str2[k])
		{if ((str1[k])!=(str2[k])) return 0;
		k++;
		}
	return k;
 }
astreq(str1,str2,len)
	char str1[],str2[];int len;
 {
	int k;
	k=0;
	while (k<len)
		{if ((str1[k])!=(str2[k]))break;
		if(str1[k]==0)break;
		if(str2[k]==0)break;
		k++;
		}
	if (an(str1[k]))return 0;
	if (an(str2[k]))return 0;
	return k;
 }
match(lit)
	char *lit;
{
	int k;
	blanks();
	if (k=streq(line+lptr,lit))
		{lptr=lptr+k;
		return 1;
		}
 	return 0;
}
amatch(lit,len)
	char *lit;int len;
 {
	int k;
	blanks();
	if (k=astreq(line+lptr,lit,len))
		{lptr=lptr+k;
		while(an(ch())) inbyte();
		return 1;
		}
	return 0;
 }
blanks() {
	while(1)
		{while(ch()==0)
			{_inline();
			preprocess();
			if(eof)break;
			}
		if(ch()==' ')gch();
		else if(ch()==9)gch();
		else return;
		}
}

outdec (number)
int	number;
{
	int	k, zs;
	char	c;

	if (number == -32768) {
		outstr ("-32768");
		return;
	}
	zs = 0;
	k = 10000;
	if (number < 0) {
		number = (-number);
		outbyte ('-');
	}
	while (k >= 1) {
		c = number / k + '0';
		if ((c != '0' | (k == 1) | zs)) {
			zs = 1;
			outbyte (c);
		}
		number = number % k;
		k = k / 10;
	}
}

/* return the length of a string */
/* gtf 4/8/80 */
strlen(s)
char *s;
{	char *t;

	t = s;
	while(*s) s++;
	return(s-t);
/* end strlen */}

/* convert lower case to upper */
/* gtf 6/26/80 */
raise(c)
char c;
{
	if((c>='a') & (c<='z'))
		c = c - 'a' + 'A';
	return(c);
/* end raise */}

/* ------------------------------------------------------------- */

/*	>>>>>>> start of cc5 <<<<<<<	*/

/* as of 5/5/81 rj */

casting()
{
	int k;

	if (k = streq(line + lptr, "(")) {
		if ((streq(line + lptr + k, "int") != 0) |
		    (streq(line + lptr + k, "char") != 0)) {
			match("(");
			if (match("int")) {
				needbrack(")");
				return cint;
			} else	if (match("char")) {
				needbrack(")");
				return cchar;
			}
		}
	}
	return -1;
}

doexpression()
{
 char *before, *start;
 while(1) {
  expression();
  if(ch() != ',') break;
  inbyte();
 }
}

expression()
{
	int lval[2];
	int cast;

	cast = casting();

	if(heir1(lval))rvalue(lval);

	if (cast != -1) lval[1] = cast;

	return lval[1];
}

heir1(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir2(lval);
	if (match("=")) {
		if(k==0) {
			needlval();
			return 0;
		}
		if (lval[1]) zpush();
		if(heir1(lval2)) rvalue(lval2);
		store(lval);
		return 0;
	}
	return k;
}

heir2(lval)
	int lval[];
{	int k,lval2[2];
	k=heir3(lval);
	blanks();
	if(ch()!='|')return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("|"))
			{zpush();
			if(heir3(lval2)) rvalue(lval2);
			zpop();
			zor();
			}
		else return 0;
		}
}
heir3(lval)
	int lval[];
{	int k,lval2[2];
	k=heir4(lval);
	blanks();
	if(ch()!='^')return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("^"))
			{zpush();
			if(heir4(lval2))rvalue(lval2);
			zpop();
			zxor();
			}
		else return 0;
		}
}
heir4(lval)
	int lval[];
{	int k,lval2[2];
	k=heir5(lval);
	blanks();
	if(ch()!='&')return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("&"))
			{zpush();
			if(heir5(lval2))rvalue(lval2);
			zpop();
			zand();
			}
		else return 0;
		}
}
heir5(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir6(lval);
	blanks();
	if((streq(line+lptr,"==")==0)&
		(streq(line+lptr,"!=")==0))return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("=="))
			{zpush();
			if(heir6(lval2))rvalue(lval2);
			zpop();
			zeq();
			}
		else if (match("!="))
			{zpush();
			if(heir6(lval2))rvalue(lval2);
			zpop();
			zne();
			}
		else return 0;
		}
}
heir6(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir7(lval);
	blanks();
	if((streq(line+lptr,"<")==0)&
		(streq(line+lptr,">")==0)&
		(streq(line+lptr,"<=")==0)&
		(streq(line+lptr,">=")==0))return k;
		if(streq(line+lptr,">>"))return k;
		if(streq(line+lptr,"<<"))return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("<="))
			{zpush();
			if(heir7(lval2))rvalue(lval2);
			zpop();
			if(cptr=lval[0])
				if(cptr[ident]==pointer)
				{ule();
				continue;
				}
			if(cptr=lval2[0])
				if(cptr[ident]==pointer)
				{ule();
				continue;
				}
			zle();
			}
		else if (match(">="))
			{zpush();
			if(heir7(lval2))rvalue(lval2);
			zpop();
			if(cptr=lval[0])
				if(cptr[ident]==pointer)
				{uge();
				continue;
				}
			if(cptr=lval2[0])
				if(cptr[ident]==pointer)
				{uge();
				continue;
				}
			zge();
			}
		else if((streq(line+lptr,"<"))&
			(streq(line+lptr,"<<")==0))
			{inbyte();
			zpush();
			if(heir7(lval2))rvalue(lval2);
			zpop();
			if(cptr=lval[0])
				if(cptr[ident]==pointer)
				{ult();
				continue;
				}
			if(cptr=lval2[0])
				if(cptr[ident]==pointer)
				{ult();
				continue;
				}
			zlt();
			}
		else if((streq(line+lptr,">"))&
			(streq(line+lptr,">>")==0))
			{inbyte();
			zpush();
			if(heir7(lval2))rvalue(lval2);
			zpop();
			if(cptr=lval[0])
				if(cptr[ident]==pointer)
				{ugt();
				continue;
				}
			if(cptr=lval2[0])
				if(cptr[ident]==pointer)
				{ugt();
				continue;
				}
			zgt();
			}
		else return 0;
		}
}
/*	>>>>>> start of cc6 <<<<<<	*/

heir7(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir8(lval);
	blanks();
	if((streq(line+lptr,">>")==0)&
		(streq(line+lptr,"<<")==0))return k;
	if(k)rvalue(lval);
	while(1)
		{if (match(">>"))
			{zpush();
			if(heir8(lval2))rvalue(lval2);
			zpop();
			asr();
			}
		else if (match("<<"))
			{zpush();
			if(heir8(lval2))rvalue(lval2);
			zpop();
			asl();
			}
		else return 0;
		}
}
heir8(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir9(lval);
	blanks();
	if((ch()!='+')&(ch()!='-'))return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("+"))
			{zpush();
			if(heir9(lval2))rvalue(lval2);
			if(cptr=lval[0])
				if((cptr[ident]==pointer)&
				(cptr[type]==cint))
				doublereg();
			zpop();
			zadd();
			}
		else if (match("-"))
			{zpush();
			if(heir9(lval2))rvalue(lval2);
			if(cptr=lval[0])
				if((cptr[ident]==pointer)&
				(cptr[type]==cint))
				doublereg();
			zpop();
			zsub();
			}
		else return 0;
		}
}
heir9(lval)
	int lval[];
{
	int k,lval2[2];
	k=heir10(lval);
	blanks();
	if((ch()!='*')&(ch()!='/')&
		(ch()!='%'))return k;
	if(k)rvalue(lval);
	while(1)
		{if (match("*"))
			{zpush();
			if(heir9(lval2))rvalue(lval2);
			zpop();
			mult();
			}
		else if (match("/"))
			{zpush();
			if(heir10(lval2))rvalue(lval2);
			zpop();
			div();
			}
		else if (match("%"))
			{zpush();
			if(heir10(lval2))rvalue(lval2);
			zpop();
			zmod();
			}
		else return 0;
		}
}
heir10(lval)
	int lval[];
{
	int k;
	char *ptr;
	if (match("~")) {
		k=heir10(lval);
		if(k) rvalue(lval);
		com();
		return 0;
	} else if (match("++"))
		{if((k=heir10(lval))==0)
			{needlval();
			return 0;
			}
		if(lval[1])zpush();
		rvalue(lval);
		inc();
		ptr=lval[0];
		if((ptr[ident]==pointer)&
			(ptr[type]==cint))
				inc();
		store(lval);
		return 0;
		}
	else if(match("--"))
		{if((k=heir10(lval))==0)
			{needlval();
			return 0;
			}
		if(lval[1])zpush();
		rvalue(lval);
		dec();
		ptr=lval[0];
		if((ptr[ident]==pointer)&
			(ptr[type]==cint))
				dec();
		store(lval);
		return 0;
		}
	else if (match("-"))
		{k=heir10(lval);
		if (k) rvalue(lval);
		neg();
		return 0;
		}
	else if(match("*"))
		{k=heir10(lval);
		if(k)rvalue(lval);
		lval[1]=cint;
		if(ptr=lval[0])lval[1]=ptr[type];
		lval[0]=0;
		return 1;
		}
	else if(match("&"))
		{k=heir10(lval);
		if(k==0)
			{error("illegal address");
			return 0;
			}
		else if(lval[1])return 0;
		else
			{immed();
			outname(ptr=lval[0]);
			nl();
			lval[1]=ptr[type];
			return 0;
			}
		}
	else 
		{k=heir11(lval);
		if(match("++"))
			{if(k==0)
				{needlval();
				return 0;
				}
			if(lval[1])zpush();
			rvalue(lval);
			inc();
			ptr=lval[0];
			if((ptr[ident]==pointer)&
				(ptr[type]==cint))
					inc();
			store(lval);
			dec();
			if((ptr[ident]==pointer)&
				(ptr[type]==cint))
				dec();
			return 0;
			}
		else if(match("--"))
			{if(k==0)
				{needlval();
				return 0;
				}
			if(lval[1])zpush();
			rvalue(lval);
			dec();
			ptr=lval[0];
			if((ptr[ident]==pointer)&
				(ptr[type]==cint))
					dec();
			store(lval);
			inc();
			if((ptr[ident]==pointer)&
				(ptr[type]==cint))
				inc();
			return 0;
			}
		else return k;
		}
	}
/*	>>>>>> start of cc7 <<<<<<	*/

heir11(lval)
	int *lval;
{	int k;char *ptr;
	k=primary(lval);
	ptr=lval[0];
	blanks();
	if((ch()=='[')|(ch()=='('))
	while(1)
		{if(match("["))
			{if(ptr==0)
				{error("can't subscript");
				junk();
				needbrack("]");
				return 0;
				}
			else if(ptr[ident]==pointer)rvalue(lval);
			else if(ptr[ident]!=array)
				{error("can't subscript");
				k=0;
				}
			zpush();
			expression();
			needbrack("]");
			if(ptr[type]==cint)doublereg();
			zpop();
			zadd();
			lval[1]=ptr[type];
				/* 4/1/81 - after subscripting, not ptr anymore */
			lval[0]=0;
			k=1;
			}
		else if(match("("))
			{if(ptr==0)
				{callfunction(0);
				}
			else if(ptr[ident]!=function)
				{rvalue(lval);
				callfunction(0);
				}
			else callfunction(ptr);
			k=lval[0]=0;
			}
		else return k;
		}
	if(ptr==0)return k;
	if(ptr[ident]==function)
		{immed();
		outname(ptr);
		nl();
		return 0;
		}
	return k;
}
primary(lval)
	int *lval;
{	char *ptr,sname[namesize];int num[1];
	int k;
	if(match("(")) {
		k=heir1(lval);
		needbrack(")");
		return k;
	}
	if(symname(sname))
		{if(ptr=findloc(sname))
			{getloc(ptr);
			lval[0]=ptr;
			lval[1]=ptr[type];
			if(ptr[ident]==pointer)lval[1]=cint;
			if(ptr[ident]==array)return 0;
				else return 1;
			}
		if(ptr=findglb(sname))
			if(ptr[ident]!=function)
			{lval[0]=ptr;
			lval[1]=0;
			if(ptr[ident]!=array)return 1;
			immed();
			outname(ptr);
			nl();
			lval[1]=ptr[type];
			return 0;
			}
		ptr=addglb(sname, function, cint, 0, PUBLIC);
		lval[0]=ptr;
		lval[1]=0;
		return 0;
		}
	if(constant(num))
		return(lval[0]=lval[1]=0);
	else
		{error("invalid expression");
		immed();outdec(0);nl();
		junk();
		return 0;
		}
	}
store(lval)
	int *lval;
{	if (lval[1]==0)putmem(lval[0]);
	else putstk(lval[1]);
}
rvalue(lval)
	int *lval;
{	if((lval[0] != 0) & (lval[1] == 0))
		getmem(lval[0]);
		else indirect(lval[1]);
}
test(label, bracket)
	int label;
	int bracket;
{
	if (bracket) needbrack("(");
	expression();
	if (bracket) needbrack(")");
	testjump(label);
}
constant(val)
	int val[];
{	if (number(val))
		immed();
	else if (pstr(val))
		immed();
	else if (qstr(val))
		{immed();printlabel(litlab);outbyte('+');}
	else return 0;	
	outdec(val[0]);
	nl();
	return 1;
}

number (val)
int	val[];
{
	int	k, minus, base;
	char	c;

	k = minus = 1;
	while (k) {
		k = 0;
		if (match ("+"))
			k = 1;
		if (match ("-")) {
			minus = (-minus);
			k = 1;
		}
	}
	if (numeric (c = ch ()) == 0)
		return (0);
	if (match ("0x") || match ("0X"))
		while ((numeric (c = ch ()) != 0) |
		       ((c >= 'a') & (c <= 'f'))  |
		       ((c >= 'A') & (c <= 'F'))) {
			inbyte ();
			if (numeric(c)) k = k * 16 + (c - '0');
			else k = k * 16 + ((c & 07) + 9);
		}
	else {
		if (c == '0') base = 8;
		else base = 10;
		while (numeric (ch ())) {
			c = inbyte ();
			k = k * base + (c - '0');
		}
	}
	if (minus < 0)
		k = (-k);
	val[0] = k;
	return (1);
}

pstr (val)
int     val[];
{
        int     k;
        char    c;

        k = 0;
        if (match ("'") == 0)
                return (0);
        while ((c = gch ()) != 39) {
		if (c == '\\') c = spechar();
                k = (k & 255) * 256 + (c & 255);
        }
        val[0] = k;
        return (1);

}

qstr (val)
int     val[];
{
        char    c;

        if (match (quote) == 0)
                return (0);
        val[0] = litptr;
        while (ch () != '"') {
                if (ch () == 0)
                        break;
                if (litptr >= litmax) {
                        error ("string space exhausted");
                        while (match (quote) == 0)
                                if (gch () == 0)
                                        break;
                        return (1);
                }
                c = gch();
		if (c == '\\') litq[litptr++] = spechar();
                else litq[litptr++] = c;
        }
        gch ();
        litq[litptr++] = 0;
        return (1);

}

#define EOS     0
#define EOL     10
#define BKSP    8
#define CR      13
#define FFEED   12
#define TAB     9

/*
 *      decode special characters (preceeded by back slashes)
 */
spechar() {
        char c;
        c = ch();

        if      (c == 'n') c = EOL;
        else if (c == 't') c = TAB;
        else if (c == 'r') c = CR;
        else if (c == 'f') c = FFEED;
        else if (c == 'b') c = BKSP;
        else if (c == '0') c = EOS;
        else if (c == EOS) return 0;

        gch();
        return (c);

}

debug_ol(p)
char *p;
{
	if (opcodebug) {
		ol(p);
	}
}

/*	>>>>>> start of cc8 <<<<<<<	*/

/* Begin a comment line for the assembler */
comment()
{	outbyte(';');
}

/* Put out assembler info before any code is generated */
header()
{	comment();
	outstr(BANNER);
	nl();
	comment();
	outstr(VERSION);
	nl();
	comment();
	outstr(AUTHOR);
	nl();
	comment();
	nl();
	if(mainflg){		/* do stuff needed for first */
/*
		if (binout) {
		    ol("org	$100");
		    ol("jmp	QZMAIN");
		    ol("include clib.inc");
		}
 */
	}
}
/* Print any assembler stuff needed after all code */
trailer()
{	/* ol("END"); */	/*...note: commented out! */

	nl();			/* 6 May 80 rj errorsummary() now goes to console */
	comment();
	outstr(" --- End of Compilation ---");
	nl();
}
/* Print out a name such that it won't annoy the assembler */
/*	(by matching anything reserved, like opcodes.) */
/*	gtf 4/7/80 */
outname(sname)
char *sname;
{	int len, i,j;

	outasm("qz");
	len = strlen(sname);
	if(len>(asmpref+asmsuff)){
		i = asmpref;
		len = len-asmpref-asmsuff;
		while(i-- > 0)
			outbyte(raise(*sname++));
		while(len-- > 0)
			sname++;
		while(*sname)
			outbyte(raise(*sname++));
		}
	else	outasm(sname);
/* end outname */}
/* Fetch a static memory cell into the primary register */
getmem(sym)
	char *sym;
{
	debug_ol("; getmem");
	if((sym[ident]!=pointer)&(sym[type]==cchar)) {
		ot("ldab	");
		outname(sym+name);
		nl();
		callrts("ccsex");
	} else	{
		ot("ldd	");
		outname(sym+name);
		nl();
	}
}
/* Fetch the address of the specified symbol */
/*	into the primary register */
getloc(sym)
	char *sym;
{
	debug_ol("; getloc");
	immed();
	outdec(((sym[offset]) | ((sym[offset+1]) << 8)) - Zsp);
	nl();
	ol("tsx");
	zadd();
}
/* Store the primary register into the specified */
/*	static memory cell */
putmem(sym)
	char *sym;
{
	debug_ol("; putmem");
	if((sym[ident]!=pointer)&(sym[type]==cchar)) {
		ot("stab	");
		outname(sym+name);
	} else {
	    ot("std	");
	    outname(sym+name);
	}
	nl();
}
/* Store the specified object type in the primary register */
/*	at the address on the top of the stack */
putstk(typeobj)
char typeobj;
{
	debug_ol("; putstk");
	zpop();
	if (typeobj == cint) {
		ol("std	0,x");
	} else {
		ol("stab	0,x");		/* per Ron Cain: gtf 9/25/80 */
	}
}

/* Fetch the specified object type indirect through the */
/*	primary register into the primary register */

indirect(typeobj)
	char typeobj;
{
	if (typeobj == cint) {
	    ol("xgdx");
	    ol("ldd	0,x");
	} else {
	    ol("xgdx");
	    ol("ldab	0,x");
	    callrts("ccsex");
	}
}

/* Swap the primary and secondary registers */
swap()
{
	debug_ol("; swap");
	ol("xgdx");
}
/* Print partial instruction to get an immediate value */
/*	into the primary register */
immed()
{
	debug_ol("; immed");
	ot("ldd	#");
}
setargsize(size)
int size;
{
	debug_ol("; setargsize");
	ot("ldab	#");
	outdec(size);
	nl();
}
/* Push the primary register onto the stack */
zpush()
{
	debug_ol("; zpush");
	ol("pshb");
	ol("psha");
	Zsp=Zsp-2;
}

/* Push the primary register onto the stack */
zpushchar()
{
	debug_ol("; zpushchar");
	ol("pshb");
	Zsp=Zsp-1;
}

/* Pop the top of the stack into the secondary register */
zpop()
{
	debug_ol("; zpop");
	ol("pulx");
	Zsp=Zsp+2;
}
/* Swap the primary register and the top of the stack */
swapstk()
{
	debug_ol("; swapstk");
	ol("pulx");
	ol("xgdx");
	ol("pshx");
}
/* Call the specified subroutine name */
zcall(sname)
	char *sname;
{
	debug_ol("; zcall");
	ot("jsr	");
	outname(sname);
	nl();
}
/* Call a run-time library routine */
callrts(sname)
char *sname;
{
	debug_ol("; callrts");
	ot("jsr	rt_");
	outasm(sname);
	nl();
/*end callrts*/
}

/* Return from subroutine */
zret()
{
	debug_ol("; zret");
	ol("rts");
}
/* Perform subroutine call to value on top of stack */
callstk()
{
	debug_ol("; callstk");
	immed();
	outasm("$+5");
	nl();
	swapstk();
	ol("pshb");
	ol("psha");
	ol("rts");
	Zsp=Zsp+2; /* corrected 5 May 81 rj */
}
/* Jump to specified internal label number */
jump(label)
	int label;
{
	debug_ol("; jump");
	ot("jmp	");
	printlabel(label);
	nl();
}
/* Test the primary register and jump if false to label */
testjump(label)
	int label;
{
	debug_ol("; testjump");
	ol("tstb");
	ol("bne	*+5");
	ot("jmp	");
	printlabel(label);
	nl();
}
/* Print pseudo-op to define external */
defextern()
{
	ot("EXTERN ");
}

defpublic()
{
	if (binout) return;
	if (cptr[storage] == STATIC) return;
	if (cptr[storage] == EXTERN) return;
	ot("PUBLIC ");
	outname(cptr);
	nl();
}

/* Print pseudo-op to define a byte */
defbyte()
{
	ot("DB ");
}
/*Print pseudo-op to define storage */
defstorage()
{
	ot("DS ");
}
/* Print pseudo-op to define a word */
defword()
{
	ot("DW ");
}
/* Modify the stack pointer to the new value indicated */
modstk(newsp)
	int newsp;
{
	debug_ol("; modstk");
	int k;
	k=newsp-Zsp;
	if(k==0)return newsp;
	if(k>=0) {
		if(k<7) {
			if(k&1) {
				ol("ins");
				k--;
			}
			while(k) {
				ol("ins");
				ol("ins");
				k=k-2;
			}
			return newsp;
		}
	}
	if(k<0) {
		if(k>-7) {
			if(k&1) {
				ol("des");
				k++;
			}
			while(k) {
				ol("des");
				ol("des");
				k=k+2;
			}
			return newsp;
		}
	}

	ol("pshb");
	ol("psha");
	ot("ldd	#");
	outdec(k);
	nl();
	ol("tsx");
	ol("inx");
	ol("inx");
	zadd();
	ol("xgdx");
	ol("pula");
	ol("pulb");
	ol("txs");

	return newsp;
}
/* Double the primary register */
doublereg()
{
	debug_ol("; doublereg");
	ol("lsld");
}
/* Add the primary and secondary registers */
/*	(results in primary) */
zadd()
{
	debug_ol("; zadd");
	ol("pshx");
	ol("tsx");
	ol("addd	0,x");
	ol("pulx");
}
/* Subtract the primary register from the secondary */
/*	(results in primary) */
zsub()
{
	debug_ol("; zsub");
	ol("pshb");
	ol("psha");
	ol("xgdx");
	ol("tsx");
	ol("subd	0,x");
	ol("pulx");
}
/* Multiply the primary and secondary registers */
/*	(results in primary */
mult()
{
	callrts("ccmult");
}
/* Divide the secondary register by the primary */
/*	(quotient in primary, remainder in secondary) */
div()
{
	callrts("ccdiv");
}
/* Compute remainder (mod) of secondary register divided */
/*	by the primary */
/*	(remainder in primary, quotient in secondary) */
zmod()
{
	div();
	swap();
}
/* Inclusive 'or' the primary and the secondary registers */
/*	(results in primary) */
zor()
	{callrts("ccor");}
/* Exclusive 'or' the primary and seconday registers */
/*	(results in primary) */
zxor()
	{callrts("ccxor");}
/* 'And' the primary and secondary registers */
/*	(results in primary) */
zand()
	{callrts("ccand");}
/* Arithmetic shift right the secondary register number of */
/*	times in primary (results in primary) */
asr()
	{callrts("ccasr");}
/* Arithmetic left shift the secondary register number of */
/*	times in primary (results in primary) */
asl()
	{callrts("ccasl");}
/* Form two's complement of primary register */
neg()
	{callrts("ccneg");}
/* Form one's complement of primary register */
com()
{
	ol("comb");
	ol("coma");
	/*callrts("cccom");*/
}
/* Increment the primary register by one */
inc()
{
	debug_ol("; inc");
	ol("addd	#1");
}
/* Decrement the primary register by one */
dec()
{
	debug_ol("; dec");
	ol("subd	#1");
}

/* Following are the conditional operators */
/* They compare the secondary register against the primary */
/* and put a literal 1 in the primary if the condition is */
/* true, otherwise they clear the primary register */

/* Test for equal */
zeq()
	{callrts("cceq");}
/* Test for not equal */
zne()
	{callrts("ccne");}
/* Test for less than (signed) */
zlt()
	{callrts("cclt");}
/* Test for less than or equal to (signed) */
zle()
	{callrts("ccle");}
/* Test for greater than (signed) */
zgt()
	{callrts("ccgt");}
/* Test for greater than or equal to (signed) */
zge()
	{callrts("ccge");}
/* Test for less than (unsigned) */
ult()
	{callrts("ccult");}
/* Test for less than or equal to (unsigned) */
ule()
	{callrts("ccule");}
/* Test for greater than (unsigned) */
ugt()
	{callrts("ccugt");}
/* Test for greater than or equal to (unsigned) */
uge()
	{callrts("ccuge");}

/*	<<<<<  End of small-c compiler	>>>>>	*/

