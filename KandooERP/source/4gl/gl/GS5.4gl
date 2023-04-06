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
# \brief module GS5 Allows mass changes of organisational codes

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_coa RECORD LIKE coa.*
DEFINE modu_rec_structure RECORD LIKE structure.*
DEFINE modu_rec_groupinfo RECORD LIKE groupinfo.*
DEFINE modu_ans CHAR(1)
DEFINE modu_group_match SMALLINT
DEFINE modu_lengther SMALLINT
DEFINE modu_counter SMALLINT	
DEFINE modu_check_code LIKE account.acct_code
DEFINE modu_bacct LIKE account.acct_code
--DEFINE modu_eacct LIKE account.acct_code	 
DEFINE modu_match_code LIKE coa.group_code
DEFINE modu_to_group LIKE coa.group_code
DEFINE modu_doit CHAR(1) 

####################################################
# MAIN
#
#
#####################################################
MAIN 

	CALL setModuleId("GS5") 
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


#####################################################
# FUNCTION get_info()
#
#
#####################################################
FUNCTION get_info() 
	DEFINE l_tmpmsg STRING 

	OPEN WINDOW getinfo with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	MESSAGE " MAX Group Changer " 

	MESSAGE " Use ? as wild characters e.g BRIS-????-??? " 

	SELECT * 
	INTO modu_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = 0 

	LET l_tmpmsg = "Structure Default ", "<",modu_rec_structure.default_text , ">" 
	DISPLAY l_tmpmsg TO lblabel1 
	MESSAGE l_tmpmsg 

	LET modu_bacct = fgl_winprompt(5,5, "Account Matches", "", 25, 0) 
	IF modu_bacct IS NULL THEN 
		EXIT PROGRAM 
	END IF 

	# this just takes out blanks AT the end
	LET modu_lengther = length(modu_bacct) 
	IF length(modu_bacct) = 18 
	THEN 
	ELSE 
		LET modu_bacct = modu_bacct [1,modu_lengther] , "*" 
	END IF 

	WHILE true 
		LET modu_match_code = fgl_winprompt(5,5, "Group Matches", "", 25, 0) 

		IF modu_match_code IS NULL THEN 
			LET modu_group_match = 0 
			SELECT count(*) 
			INTO modu_counter 
			FROM coa 
			WHERE acct_code matches modu_bacct 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		ELSE 

			SELECT count(*) 
			INTO modu_counter 
			FROM coa 
			WHERE acct_code matches modu_bacct 
			AND group_code matches modu_match_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 

		IF modu_counter = 0 THEN 
			ERROR "No matches, retry" 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	LET modu_to_group = fgl_winprompt(5,5, "TO Group Code", "", 25, 0) 

	SELECT * 
	INTO modu_rec_groupinfo.* 
	FROM groupinfo 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND group_code = modu_to_group 
	IF status = NOTFOUND 
	THEN 
		ERROR " TO group code NOT found" 
		CALL fgl_winmessage("Invalid Target Group Code","TO group code NOT found","error") 
		#sleep 9
		EXIT PROGRAM 
	END IF 

	LET l_tmpmsg = " Copying ", modu_counter USING "<<<<", " accounts\n\nContinue?" 
	LET modu_ans = promptYN("Copy",l_tmpmsg,"Y") 
	LET modu_ans = upshift(modu_ans) 

	IF modu_ans != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	CLOSE WINDOW getinfo 

	IF modu_group_match = 0 THEN 
		UPDATE coa 
		SET group_code = modu_to_group 
		WHERE acct_code matches modu_bacct 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
		UPDATE coa 
		SET group_code = modu_to_group 
		WHERE acct_code matches modu_bacct 
		AND group_code matches modu_match_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	#DISPLAY " Update completed " AT 15,10
	MESSAGE "Update completed" 

END FUNCTION