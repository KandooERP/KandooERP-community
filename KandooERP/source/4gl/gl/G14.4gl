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

	Source code beautified by beautify.pl on 2020-01-03 14:28:28	Source code beautified by beautify.pl on 2019-11-01 09:53:16	$Id: $
}



# COA Inquiry program

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("G14") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g146 with FORM "G146" 
	CALL windecoration_g("G146-G14") --populate WINDOW FORM elements 

	CALL query() 
	CLOSE WINDOW g146 
END MAIN 


############################################################
# FUNCTION select_account()
#
#
############################################################
FUNCTION select_account() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON acct_code, 
	desc_text, 
	type_ind, 
	start_year_num, 
	start_period_num, 
	end_year_num, 
	end_period_num, 
	group_code, 
	analy_req_flag, 
	analy_prompt_text, 
	qty_flag, 
	uom_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G14","construct-account") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please wait.
	LET l_query_text = "SELECT * FROM coa ", 
	"WHERE ", l_where_text clipped, 
	"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"ORDER BY acct_code" 
	PREPARE s_coa FROM l_query_text 
	DECLARE c_coa SCROLL CURSOR FOR s_coa 
	OPEN c_coa 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION query()
#
#
############################################################
FUNCTION query() 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_year SMALLINT 
	DEFINE l_period SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " COA inquiry" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G14","menu-coa-inquiry") 

			SHOW option "Query" 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Detail" 
			HIDE option "Approved" 
			HIDE option "First" 
			HIDE option "Last" 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "actToolbarManager" 

			#COMMAND "Query" " Enter Selection Criteria FOR account"
		ON ACTION "Query" 
			INITIALIZE l_rec_coa.* TO NULL 
			IF select_account() THEN 
				FETCH FIRST c_coa INTO l_rec_coa.* 
				IF status = NOTFOUND THEN 
					CLEAR FORM 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Detail" 
					HIDE option "Last" 
					HIDE option "Approved" 
					NEXT option "Query" 
				ELSE 
					CALL disp_coa(l_rec_coa.*) 
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "Detail" 
					SHOW option "First" 
					SHOW option "Last" 
					SELECT unique(1) FROM fundsapproved 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = l_rec_coa.acct_code 
					IF status = NOTFOUND THEN 
						HIDE option "Approved" 
					ELSE 
						SHOW option "Approved" 
					END IF 
					NEXT option "Next" 
				END IF 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Detail" 
				HIDE option "Approved" 
				HIDE option "Last" 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " DISPLAY next selected account"
			FETCH NEXT c_coa INTO l_rec_coa.* 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9157,"") 
				#9933 You have reached the END of the entries selected.
			ELSE 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_coa(l_rec_coa.*) 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected work request"
			FETCH previous c_coa INTO l_rec_coa.* 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9932 You have reached the start of the entries selected.
			ELSE 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_coa(l_rec_coa.*) 
			END IF 

		ON ACTION "Detail" 
			#COMMAND KEY ("D",f20) "Detail" " DISPLAY account ledger details"
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING l_year, l_period 
			CALL ac_detl_scan(glob_rec_kandoouser.cmpy_code, 
			l_rec_coa.acct_code, 
			l_year, 
			l_period, 
			0) 

		ON ACTION "Approved" 
			#COMMAND "Approved" " View Approved Funds details"
			IF disp_cab(glob_rec_kandoouser.cmpy_code, l_rec_coa.acct_code) THEN 
			END IF 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " DISPLAY first account in the selected list"
			FETCH FIRST c_coa INTO l_rec_coa.* 
			IF status != NOTFOUND THEN 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_coa(l_rec_coa.*) 
				NEXT option "Next" 
			END IF 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" " DISPLAY last account in the selected list"
			FETCH LAST c_coa INTO l_rec_coa.* 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected"
			ELSE 
				SELECT unique(1) FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				IF status = NOTFOUND THEN 
					HIDE option "Approved" 
				ELSE 
					SHOW option "Approved" 
				END IF 
				CALL disp_coa(l_rec_coa.*) 
			END IF 
			NEXT option "Previous" 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus"
			EXIT MENU 

			#      COMMAND KEY (control-w)   --help
			#         CALL kandoohelp("")
	END MENU 
END FUNCTION 


############################################################
# FUNCTION disp_coa(p_rec_coa)
#
#
############################################################
FUNCTION disp_coa(p_rec_coa) 
	DEFINE p_rec_coa RECORD LIKE coa.* 

	DISPLAY BY NAME p_rec_coa.acct_code, 
	p_rec_coa.desc_text, 
	p_rec_coa.type_ind, 
	p_rec_coa.start_year_num, 
	p_rec_coa.start_period_num, 
	p_rec_coa.end_year_num, 
	p_rec_coa.end_period_num, 
	p_rec_coa.group_code, 
	p_rec_coa.analy_req_flag, 
	p_rec_coa.analy_prompt_text, 
	p_rec_coa.qty_flag, 
	p_rec_coa.uom_code 

END FUNCTION 
