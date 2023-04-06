#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE 1025
/* this module ontains the interface for regular C functions to informix 4GL*/

/* prototypes */
int fgl_strings ();
int fgl_showparams ();

main () {
	char infile[BUFSIZE];
	char outfile[BUFSIZE];
	strcpy (infile,"I:\\Users\\BeGooden-IT\\git\\.metadata\\.plugins\\org.eclipse.core.resources\\.projects\\MaiaERP\\.location                                      ");
	strcpy (outfile,"C:\\TEMP\\std.out");
	FILE * in = fopen(infile,"r");
	if (in) {
		printf ("file could be opened: %s\n",infile);
		
	} else {
		printf ("ERROR at opening file%s\n",infile);
	}
	
	FILE * out = fopen(outfile,"w");
	if (out) {
		printf ("file could be opened: %s\n",outfile);
		fprintf (out,"We could write into the file %s\n",outfile);
		
	} else {
		printf ("ERROR at opening file%s\n",outfile);
	}
	close(in);
	close(out);
}
// fgl_strings simulates the unix 'strings' command
// inbound: filename, minimum length to consider a string,maximum strings number to return
int fgl_strings () {
	int minlength;
	int maxreturn;
	int ch;
	int idx=0;
	int prevch=0;
	int doprint=0;
	int stringlength=0;
	int stringsnumber=0;
	int instring=0;
	int len=0;
	char thestring[BUFSIZE];
	char filename[BUFSIZE];
	char* outstring;
	thestring[0]='\0';
/*
	popint(&maxreturn);
	popint(&minlength);
	popquote(filename,BUFSIZE);
*/
	len=strlen(filename);
	filename[len]='\0';

	FILE * outfile = fopen("c:\\temp\\standard.out","w");

	fprintf (outfile,"=>%s:%d:%d\n",filename,minlength,maxreturn);
	fprintf (outfile,"length=%d\n",strlen(filename));
	outstring=thestring;
	FILE * infile = fopen(filename, "rb");

	if ( !infile ) {
		strcat(outstring,"filenotfound");
	} else {
		strcat(outstring,"fileopen!");
		while ( (ch = fgetc(infile)) != EOF ) {
			if ( ch > 32 && ch < 127) {
				instring++;
				outstring[idx++]=ch;
			} else {
				if ( instring > minlength) {
					if (++stringsnumber > maxreturn) {
						outstring[idx]='\0';
					} else {
						outstring[idx]='\n';
					}
					instring=idx=0;
				}
			}
			prevch=ch;
		}
		outstring[idx]='\0';
		fclose(infile);
	}
	fprintf (outfile,"outfile is %s\n",thestring);
	fclose(outfile);
/*
	retquote(outstring);
*/
	return (1) ;
}
/*
int fgl_showparams (int numargs) {
	int minlength;
	int maxreturn;
	int ch;
	int idx=0;
	int prevch=0;
	int doprint=0;
	int stringlength=0;
	int stringsnumber=0;
	int instring=0;
	int len=0;
	char thestring[BUFSIZE];
	char filename[BUFSIZE];
	char* outstring;
	thestring[0]='\0';

	popint(&maxreturn);
	popint(&minlength);
	popquote(filename,BUFSIZE);
	len=strlen(filename);
	filename[len]='\0';

	FILE * outfile = fopen("c:\\temp\\standard.out","w");

	fprintf (outfile,"=>%s:%d:%d\n",filename,minlength,maxreturn);
	fprintf (outfile,"length=%d\n",strlen(filename));
	outstring=thestring;
	FILE * infile = fopen(filename, "rb");

	if ( !infile ) {
		strcat(outstring,"filenotfound");
	} else {
		strcat(outstring,"fileopen!");
		while ( (ch = fgetc(infile)) != EOF ) {
			if ( ch > 32 && ch < 127) {
				instring++;
				outstring[idx++]=ch;
			} else {
				if ( instring > minlength) {
					if (++stringsnumber > maxreturn) {
						outstring[idx]='\0';
					} else {
						outstring[idx]='\n';
					}
					instring=idx=0;
				}
			}
			prevch=ch;
		}
		outstring[idx]='\0';
		fclose(infile);
	}
	fprintf (outfile,"outfile is %s\n",thestring);
	fclose(outfile);

	retquote(outstring);
	return (1) ;
}*/