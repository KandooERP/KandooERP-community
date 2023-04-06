#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fglsys.h"
#include "fglapi.h"
#include "fgifunc.h"
#define BUFSIZE 1025
#define DEBUG 1
/* took this fix from Gertjan - comitted on 24.02.2019*/
/* this module ontains the interface for regular C functions to informix 4GL*/

/* prototypes */
int fgl_get_strings ();

// fgl_get_strings simulates the unix 'strings' command
// inbound: filename, minimum length to consider a string,maximum strings number to return

int fgl_get_strings (int numargs) {
	int minlength;
	int maxreturn;
	int ch;
	int idx=0;
	int jdx=0;
	int prevch=0;
	int doprint=0;
	int stringlength=0;
	int stringsnumber=0;
	int instring=0;
	char* outstring;
	int len=0;
	int debug=0;
	char thestring[BUFSIZE];
	char infilename[BUFSIZE];
	char* infile;

	popint(&maxreturn);
	popint(&minlength);
	minlength--;
	popquote(infilename,BUFSIZE);
 	len=strlen(infilename);
 	idx=0;
 	// right trim blanks on the filename
 	do {
 		idx++;
 	}  	while (infilename[idx] != ' ') ;
  	infilename[idx]='\0';
#ifdef DEBUG
  		FILE * outHandle = fopen("C:\\TEMP\\std.out","w");
  		if (outHandle) {
  			fprintf (outHandle,"out:%s:%d:%d\n",infilename,minlength,maxreturn);
  			fprintf (outHandle,"out:length before===%d length after=%d\n",&len,strlen(infilename));
  			strcpy(thestring,"CouldOpenTheFile!");
  		} else {
  			strcpy(thestring,"CouldNotOpenTheFile");
  		}
#endif
	FILE * inHandle = fopen(infilename, "rb");

	if ( !inHandle) {
#ifdef DEBUG
	fprintf (outHandle,"No, Could NOT open file %s\n",infilename);
#endif
		strcat(thestring,"inFileinotfound");
	} else {
#ifdef DEBUG
			fprintf (outHandle,"Yes, Could open file %s\n",infilename);
#endif
		stringsnumber=0;
		idx=0;
		while ( (ch = fgetc(inHandle)) != EOF && stringsnumber < maxreturn) {
			if ( ch > 32 && ch < 127) {
				instring++;
				outstring[idx++]=ch;
#ifdef DEBUG
					fprintf (outHandle,"%c",ch);
					fflush(outHandle);
#endif
			} else {
				if ( idx > minlength) {
					stringsnumber++;
					if ( stringsnumber < maxreturn ) {
						outstring[idx]='\n';
					} else {
						outstring[idx]='\0';
					}
#ifdef DEBUG
						fprintf (outHandle,"\none string:%s:\n",outstring);
						fflush(outHandle);
#endif
				}
				instring=0;
				idx=0;
			}
			prevch=ch;
		}
#ifdef DEBUG
			fprintf (outHandle,"result: %s\n",outstring);
#endif
		fclose(inHandle);
	}
#ifdef DEBUG
	fclose(outHandle);
#endif
	//retquote(outstring,BUFSIZE);
	retquote(outstring);
	return 1 ;
}


cfunc_t usrcfuncs[] =
    {
    "fgl_get_strings",fgl_get_strings,1,
	{ 0, 0, 0 },
    };
