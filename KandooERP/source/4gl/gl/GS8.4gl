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
# \brief module GS8 Allows mass changes of organisational codes

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"

############################################################
# MODULE Scope Variables
############################################################
--	DEFINE modu_rec_coa RECORD LIKE coa.*
	DEFINE modu_rec_structure RECORD LIKE structure.* 
	DEFINE modu_ans CHAR(1)
	DEFINE modu_lengther SMALLINT
	DEFINE modu_to_year SMALLINT
	DEFINE modu_to_period SMALLINT
	DEFINE modu_close_year SMALLINT
	DEFINE modu_close_period SMALLINT
	DEFINE modu_counter SMALLINT
	DEFINE modu_check_code LIKE account.acct_code
	DEFINE modu_bacct LIKE account.acct_code
--	DEFINE modu_eacct LIKE account.acct_code
--	DEFINE modu_match_code LIKE coa.group_code
--	DEFINE modu_to_group LIKE coa.group_code
	DEFINE modu_doit CHAR(1)
############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GS8") 
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


############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_tmpmsg STRING 

	OPEN WINDOW getinfo with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	MESSAGE " MAX Close Date Changer " 

	ERROR " Use ? as wild characters e.g BRIS-????-??? " 

	SELECT * 
	INTO modu_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = 0 

	MESSAGE " Structure Default ", "<",modu_rec_structure.default_text , ">" 

	LET modu_bacct = fgl_winprompt(5,5, "Account Matches", "", 25, 0) 
	IF modu_bacct IS NULL THEN 
		EXIT PROGRAM 
	END IF 

	MESSAGE "Account Matches :", modu_bacct 
	DISPLAY " Account Matches : ", modu_bacct at 2,1 

	# this just takes out blanks AT the end
	LET modu_lengther = length(modu_bacct) 
	IF length(modu_bacct) = 18 
	THEN 
	ELSE 
		LET modu_bacct = modu_bacct [1,modu_lengther] , "*" 
	END IF 

	WHILE true 
		LET modu_close_year = fgl_winprompt(5,5, "WHERE Close Year =", "", 25, 0) 

		IF modu_close_year IS NULL THEN 
			LET modu_close_year = 0 
			SELECT count(*) 
			INTO modu_counter 
			FROM coa 
			WHERE acct_code matches modu_bacct 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			LET modu_close_period = fgl_winprompt(5,5, "WHERE Close Period =", "", 25, 0) 

			IF modu_close_period IS NULL THEN 
				LET modu_close_period = 0 
				SELECT count(*) 
				INTO modu_counter 
				FROM coa 
				WHERE acct_code matches modu_bacct 
				AND end_year_num = modu_close_year 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				SELECT count(*) 
				INTO modu_counter 
				FROM coa 
				WHERE acct_code matches modu_bacct 
				AND end_year_num = modu_close_year 
				AND end_period_num = modu_close_period 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
		END IF 
		
		IF modu_counter = 0 THEN 
			ERROR "No matches, retry" 
		ELSE 
			EXIT WHILE 
		END IF
		 
	END WHILE 

	LABEL nextgo: 
	LET modu_to_year = fgl_winprompt(5,5, "TO Close Year", "", 25, 0) 

	IF modu_to_year < 1988	THEN 
		ERROR " Close year must be > 1988 " 
		GOTO nextgo 
	END IF 

	LET modu_to_period = fgl_winprompt(5,5, "TO Close Period", "", 25, 0) 


	LET l_tmpmsg = "Copying ", modu_counter USING "<<<<", " accounts, continue?:" 
	LET modu_ans = promptYN("Copying",l_tmpmsg,"Y") 
	LET modu_ans = upshift(modu_ans)
	 
	IF modu_ans != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	CLOSE WINDOW getinfo 
	DISPLAY " Updating........ " at 15,10 

	IF modu_close_year = 0	THEN 
		UPDATE coa 
		SET end_year_num = modu_to_year, 
		end_period_num = modu_to_period 
		WHERE acct_code matches modu_bacct 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
		IF modu_close_period = 0	THEN 
			UPDATE coa 
			SET end_year_num = modu_to_year, 
			end_period_num = modu_to_period 
			WHERE acct_code matches modu_bacct 
			AND end_year_num = modu_close_year 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			UPDATE coa 
			SET end_year_num = modu_to_year, 
			end_period_num = modu_to_period 
			WHERE acct_code matches modu_bacct 
			AND end_year_num = modu_close_year 
			AND end_period_num = modu_close_period 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
	END IF 

	DISPLAY " Update completed " at 15,10 

END FUNCTION