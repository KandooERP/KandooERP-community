{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 14:28:51	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GS6 Copies the COA TO a different company

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	--DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
END GLOBALS 


#############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_coa RECORD LIKE coa.*
	DEFINE modu_bacct LIKE account.acct_code
	DEFINE modu_eacct LIKE account.acct_code
	DEFINE modu_bcomp CHAR(2) 
	DEFINE modu_ecomp CHAR(2) 
	DEFINE modu_err_flag CHAR(1) 
	DEFINE modu_doit CHAR(1) 


#############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GS6") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	LET modu_doit = "Y" 
	WHILE modu_doit = "Y" 
		CALL get_info() 
		LET modu_doit = "Y" 
	END WHILE 
END MAIN 


#############################################################
# FUNCTION get_info() 
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_msg_ans CHAR(1)
	
	OPEN WINDOW getinfo with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	MESSAGE " MAX COA Company Copier " 

	LET modu_err_flag = "Y" 
	WHILE modu_err_flag = "Y" 
		LET modu_err_flag = "N" 
		LET modu_bcomp = fgl_winprompt(5,5, "Source company", "", 25, 0) 

		IF modu_bcomp IS NULL THEN 
			EXIT PROGRAM 

		ELSE 
			SELECT name_text #check IF company exists 
			FROM company 
			WHERE cmpy_code = modu_bcomp 
			IF status = NOTFOUND THEN 
				LET l_msg_ans = kandoomsg("U",9502,"") 
				LET modu_err_flag = "Y" 
			END IF 
		END IF 
	END WHILE 

	LET modu_err_flag = "Y" 
	WHILE modu_err_flag = "Y" 
		LET modu_err_flag = "N" 
		LET modu_ecomp = fgl_winprompt(5,5, "Target company", "", 25, 0) 

		IF modu_ecomp IS NULL THEN 
			EXIT PROGRAM 

		ELSE 
			SELECT name_text 
			FROM company 
			WHERE cmpy_code = modu_ecomp 
			IF status = NOTFOUND THEN 
				LET l_msg_ans = kandoomsg("U",9502,"") 
				LET modu_err_flag = "Y" 
			END IF 
		END IF 
	END WHILE 

	LET modu_bacct = fgl_winprompt(5,5, "Beginning account", "", 25, 0) 

	IF modu_bacct IS NULL THEN 
		LET modu_bacct = " " 
	END IF 


	LET modu_eacct = fgl_winprompt(5,5, "Ending account", "", 25, 0) 

	IF modu_eacct IS NULL THEN 
		LET modu_eacct = "zzzzzzzzzzzzzzzzzz" 
	END IF 

	CLOSE WINDOW getinfo 

	DECLARE acctcurs CURSOR FOR 
	SELECT coa.* 
	INTO modu_rec_coa.* 
	FROM coa 
	WHERE acct_code between modu_bacct AND modu_eacct 
	AND cmpy_code = modu_bcomp 

	OPEN WINDOW ww01 with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	FOREACH acctcurs 


		LET modu_rec_coa.cmpy_code = modu_ecomp 

		SELECT acct_code 
		FROM coa 
		WHERE cmpy_code = modu_ecomp 
		AND acct_code = modu_rec_coa.acct_code 

		IF status = NOTFOUND THEN 
			DISPLAY " Account: ", modu_rec_coa.acct_code 
			at 2,10 
			INSERT INTO coa VALUES (modu_rec_coa.*) 
		ELSE 
			LET l_msg_ans = kandoomsg("G",9501,modu_rec_coa.acct_code) 
		END IF 
	END FOREACH
	 
	CLOSE WINDOW ww01
	 
END FUNCTION