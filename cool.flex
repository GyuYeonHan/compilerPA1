/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int nestedLayer = 0;



%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

digit	[0-9]
object	[a-z][a-zA-Z0-9_]*	
type    [A-Z][a-zA-Z0-9_]*

%s COMMENT
%s STRING
%s STRLONG

%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

<INITIAL>"\n"		curr_lineno++;
<INITIAL>[ \r\t\v\f]+

<INITIAL>"*)"		{ cool_yylval.error_msg = "Unmatched *)"; return (ERROR); }
<INITIAL>"(*"		{ BEGIN(COMMENT); nestedLayer = 1; }
<COMMENT>"\("
<COMMENT>[^*\n(]*
<COMMENT>"\n"		curr_lineno++;
<COMMENT>"(*"		nestedLayer++;
<COMMENT>"*)"		{
			if(nestedLayer == 1) {
				nestedLayer--;
				BEGIN(INITIAL);
			} else
				nestedLayer--;
			}
<COMMENT>"*"

<INITIAL>"--"[^\n]*		

<COMMENT><<EOF>>	{ 
			cool_yylval.error_msg = "EOF in comment"; 
			BEGIN(INITIAL);
			return (ERROR);
			}

<INITIAL>{digit}+	{
			cool_yylval.symbol = inttable.add_string(yytext); 
			return (INT_CONST) ; 
			}

<INITIAL>[t][rR][uU][eE]		{ cool_yylval.boolean = 1 ; return (BOOL_CONST) ; }
<INITIAL>[f][aA][lL][sS][eE]		{ cool_yylval.boolean = 0 ; return (BOOL_CONST) ; }

<INITIAL>\" 	{ BEGIN(STRING); }

<STRING>\\[^ntbf] 	{ if(strlen(string_buf) > MAX_STR_CONST) {
				cool_yylval.error_msg = "String constant too long";
				BEGIN(STRLONG);
				return (ERROR);
			} else {
				strcat(string_buf, ++yytext); 
			}}


<STRING>[^\n\"]		{ if(strlen(string_buf) > MAX_STR_CONST) {
				cool_yylval.error_msg = "String constant too long";
				BEGIN(STRLONG);
				return (ERROR);
			} else {
				strcat(string_buf, yytext); 
			}}
<STRING>\\\n { ++curr_lineno; }

<STRING><<EOF>> {
		yylval.error_msg = "EOF in string constant";
		BEGIN(INITIAL);
		return (ERROR);
		}


<STRING>\n 	{	
		yylval.error_msg = "Unterminated string constant";
		curr_lineno++;
		BEGIN(INITIAL);
		return (ERROR);
		}

<STRING>\"	{	
		if(strlen(string_buf) > MAX_STR_CONST) {
			cool_yylval.error_msg = "String constant too long";
			BEGIN(INITIAL);
			return (ERROR);
		}
		cool_yylval.symbol = stringtable.add_string(string_buf + '\0');	
		BEGIN(INITIAL);
		strcpy(string_buf, ""); 	
		return (STR_CONST);
		}

<STRLONG>[^\"]*  { printf("yytext : %s\n", yytext); }	
<STRLONG>\"	BEGIN(INITIAL);

<INITIAL>[cC][lL][Aa][sS][sS]		{ return (CLASS) ; }
<INITIAL>[eE][lL][sS][eE]		{ return (ELSE) ; }
<INITIAL>[fF][iI]			{ return (FI) ; }
<INITIAL>[iI][fF]			{ return (IF) ; }
<INITIAL>[iI][nN]			{ return (IN) ; }
<INITIAL>[iI][nN][hH][eE][rR][iI][tT][sS]	{ return (INHERITS) ; }
<INITIAL>[lL][eE][tT]			{ return (LET) ; }
<INITIAL>[lL][oO][oO][pP]		{ return (LOOP) ; }
<INITIAL>[pP][oO][oO][lL]		{ return (POOL) ; }
<INITIAL>[tT][hH][eE][nN]		{ return (THEN) ; }
<INITIAL>[wW][hH][iI][lL][eE]		{ return (WHILE) ; }
<INITIAL>[cC][aA][sS][eE]		{ return (CASE) ; }
<INITIAL>[eE][sS][aA][cC]		{ return (ESAC) ; }
<INITIAL>[oO][fF]			{ return (OF) ; }
<INITIAL>[nN][eE][wW]			{ return (NEW) ; }
<INITIAL>[iI][sS][vV][oO][iI][dD]	{ return (ISVOID) ; }
<INITIAL>[nN][oO][tT]			{ return (NOT) ; }

<INITIAL>"=>"		{ return (DARROW) ; }
<INITIAL>"<-"		{ return (ASSIGN) ; }
<INITIAL>"<="		{ return (LE) ; }
<INITIAL>"+"		{ return '+' ; }
<INITIAL>"/"		{ return '/' ; }
<INITIAL>"-"		{ return '-' ; }
<INITIAL>"*"		{ return '*' ; }
<INITIAL>"<"		{ return '<' ; }
<INITIAL>"."		{ return '.' ; }
<INITIAL>"~"		{ return '~' ; }
<INITIAL>","		{ return ',' ; }
<INITIAL>"="		{ return '=' ; }
<INITIAL>";"		{ return ';' ; }
<INITIAL>":"		{ return ':' ; }
<INITIAL>"("		{ return '(' ; }
<INITIAL>")"		{ return ')' ; }
<INITIAL>"@"		{ return '@' ; }
<INITIAL>"{"		{ return '{' ; }
<INITIAL>"}"		{ return '}' ; }


<INITIAL>{type}		{
		cool_yylval.symbol = idtable.add_string(yytext);
		return (TYPEID);
		}

<INITIAL>{object}	{
		cool_yylval.symbol = idtable.add_string(yytext); 
		return (OBJECTID);
		}

<INITIAL>[^a-zA-Z0-9]	{ cool_yylval.error_msg = yytext; return (ERROR); }


%%
