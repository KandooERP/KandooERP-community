--DATABASE KANDOODB
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS
	DEFINE glRecCompany_orig RECORD LIKE company.*
	DEFINE glRecKandoouser_orig RECORD LIKE kandoouser.*
	DEFINE glRecArparms_orig RECORD LIKE arparms.*
	DEFINE glRecApparms_orig RECORD LIKE apparms.*
	DEFINE glRecArparmext_orig RECORD LIKE arparmext.*
END GLOBALS