#General Ledger Parameters G133
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

###########################################################################
# \brief module GZP  - General Ledger Parameters
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_rec_currency RECORD LIKE currency.* 
	#DEFINE glob_err_flag                  SMALLINT #may be not used ???
	DEFINE glob_cnter INTEGER 
	DEFINE glob_chart_count INTEGER 
	DEFINE glob_msgresp CHAR(1) 
	DEFINE glob_domore CHAR(1) 
	DEFINE glob_ans CHAR(1) 

END GLOBALS 
###########################################################################
# FUNCTION GZP_whenever_sqlerror ()
#
#
###########################################################################
FUNCTION GZP_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
###########################################################################
# END FUNCTION GZP_whenever_sqlerror ()
###########################################################################

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	CALL setModuleId("GZP") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_g_gl() #init g/gl general ledger module #KD-2128


	OPEN WINDOW g133 with FORM "G133" 
	CALL windecoration_g("G133") 

	MENU " Parameters" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GZP","menu") 
			IF disp_parm() THEN 
				HIDE option "NEW" 
			ELSE 
				HIDE option "EDIT" 
			END IF 
			#HuHo I hate this menu structure.. Let's NOT show this option - can access it via edit
			#COMMAND "Display" " DISPLAY Parameters"
			#   IF budgets("D") THEN
			#   END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NEW" 
			#COMMAND "ADD" " Add Parameters"
			CALL add_parm() 
			IF disp_parm() THEN 
				HIDE option "NEW" 
				SHOW option "EDIT" 
			END IF 

		ON ACTION "EDIT" 
			#COMMAND "EDIT" "Change Parameters"

			MENU "EDIT" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GZP","menu-edit") 
					
				ON ACTION ("EDIT") --parameter #COMMAND "Parameters" "Change Parameters" 
					IF NOT change_parm() THEN 
						IF disp_parm() THEN 
						END IF 
						EXIT MENU 
					END IF 
					
				ON ACTION ("BUDGETS") #COMMAND "Budgets" "Change Budget Parameters" 
					IF NOT budgets("C") THEN 
						EXIT MENU 
					END IF 

				ON ACTION CANCEL		#COMMAND KEY(interrupt,"E") "Exit" "RETURN TO menu"
					EXIT MENU 

			END MENU 

		ON ACTION "Exit"		#COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus"
			EXIT PROGRAM 

	END MENU 

	CLOSE WINDOW G133 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION add_parm()
#
#
###########################################################################
FUNCTION add_parm() 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 

	SELECT count(*) INTO glob_chart_count FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_rec_glparms.use_currency_flag = "N" 
	LET l_rec_glparms.control_tot_flag = "N" 
	LET l_rec_glparms.use_clear_flag = "N" 
	LET l_rec_glparms.budg1_close_flag = "N" 
	LET l_rec_glparms.budg2_close_flag = "N" 
	LET l_rec_glparms.budg3_close_flag = "N" 
	LET l_rec_glparms.budg4_close_flag = "N" 
	LET l_rec_glparms.budg5_close_flag = "N" 
	LET l_rec_glparms.budg6_close_flag = "N" 
	LET l_rec_glparms.post_susp_flag = "N" 
	LET l_rec_glparms.style_ind = 2 
	LET l_rec_glparms.last_post_date = today 
	LET l_rec_glparms.last_close_date = today 
	LET l_rec_glparms.last_update_date = today 
	LET l_rec_glparms.last_del_date = today 
	LET l_rec_glparms.cash_book_flag = "N" 

	DISPLAY BY NAME 
		l_rec_glparms.use_currency_flag, 
		l_rec_glparms.control_tot_flag, 
		l_rec_glparms.use_clear_flag, 
		l_rec_glparms.last_post_date, 
		l_rec_glparms.cash_book_flag 

	LET glob_msgresp = kandoomsg("U",1070,"")	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME 
		l_rec_glparms.next_jour_num, 
		l_rec_glparms.site_code, 
		l_rec_glparms.gj_code, 
		l_rec_glparms.rj_code, 
		l_rec_glparms.cb_code, 
		l_rec_glparms.acrl_code, 
		l_rec_glparms.rev_acrl_code, 
		l_rec_glparms.base_currency_code, 
		l_rec_glparms.use_currency_flag, 
		l_rec_glparms.control_tot_flag, 
		l_rec_glparms.use_clear_flag, 
		l_rec_glparms.style_ind, 
		l_rec_glparms.clear_acct_code, 
		l_rec_glparms.post_susp_flag, 
		l_rec_glparms.susp_acct_code, 
		l_rec_glparms.exch_acct_code, 
		l_rec_glparms.unexch_acct_code, 
		l_rec_glparms.cash_book_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZP","inp-glparms1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (gj_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.gj_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.gj_code 
			END IF 
			NEXT FIELD gj_code 

		ON ACTION "LOOKUP" infield (rj_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.rj_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.rj_code 
			END IF 
			NEXT FIELD rj_code 

		ON ACTION "LOOKUP" infield (cb_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.cb_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.cb_code 
			END IF 
			NEXT FIELD cb_code 

		ON ACTION "LOOKUP" infield (acrl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.acrl_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.acrl_code 
			END IF 
			NEXT FIELD acrl_code 

		ON ACTION "LOOKUP" infield (rev_acrl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.rev_acrl_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.rev_acrl_code 
			END IF 
			NEXT FIELD rev_acrl_code 

		ON ACTION "LOOKUP" infield (base_currency_code) 
			LET l_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.base_currency_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.base_currency_code 
			END IF 
			NEXT FIELD base_currency_code 

		ON ACTION "LOOKUP" infield (clear_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.clear_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.clear_acct_code 
			END IF 
			NEXT FIELD clear_acct_code 

		ON ACTION "LOOKUP" infield (susp_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.susp_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.susp_acct_code 
			END IF 
			NEXT FIELD susp_acct_code 

		ON ACTION "LOOKUP" infield (exch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.exch_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.exch_acct_code 
			END IF 
			NEXT FIELD exch_acct_code 

		ON ACTION "LOOKUP" infield (unexch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.unexch_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.unexch_acct_code 
			END IF 
			NEXT FIELD unexch_acct_code 

			SELECT count(*) INTO glob_chart_count FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 

		AFTER FIELD next_jour_num ## it should be noted that although 
			SELECT max(jour_num) ## this FIELD IS called next_jour_num, 
			INTO glob_cnter ## it IS in fact current_jour_num, 
			FROM batchhead ## ie,next_jour_num - 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_cnter > l_rec_glparms.next_jour_num THEN 
				LET glob_msgresp = kandoomsg("G",9608,glob_cnter)		#9608 Batch number must be greater than XXX.
				LET l_rec_glparms.next_jour_num = glob_cnter + 1 
				NEXT FIELD next_jour_num 
			END IF 

		AFTER FIELD gj_code 
			SELECT journal.desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE jour_code = l_rec_glparms.gj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " The Journal does NOT exist"
				NEXT FIELD gj_code 
			END IF 

			DISPLAY BY NAME glob_rec_journal.desc_text 

		AFTER FIELD rj_code 
			SELECT desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE jour_code = l_rec_glparms.rj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " The Journal does NOT exist"
				NEXT FIELD rj_code 
			END IF 

			DISPLAY glob_rec_journal.desc_text TO rcjdesc 

		AFTER FIELD cb_code 
			IF l_rec_glparms.cb_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.cb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = NOTFOUND) THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")			#9029 " The Journal does NOT exist"
					NEXT FIELD cb_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO cbjdesc 
			END IF 

		AFTER FIELD acrl_code 
			IF l_rec_glparms.acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")	#9029 " The Journal does NOT exist"
					NEXT FIELD acrl_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO accdesc 

			END IF 

		AFTER FIELD rev_acrl_code 
			IF l_rec_glparms.rev_acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.rev_acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")	#9029 " The Journal does NOT exist"
					NEXT FIELD rev_acrl_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO acrdesc 

			END IF 

		AFTER FIELD base_currency_code 
			IF l_rec_glparms.base_currency_code IS NULL THEN 
				LET glob_msgresp = kandoomsg("U",9102,"")		#9102 Value must be entered.
				NEXT FIELD base_currency_code 
			END IF 

			SELECT * INTO glob_rec_currency.* FROM currency 
			WHERE currency_code = l_rec_glparms.base_currency_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9505,"")	#9226 " RECORD NOT found"
				NEXT FIELD base_currency_code 
			END IF 

			DISPLAY glob_rec_currency.desc_text TO currency.desc_text 

		AFTER FIELD use_currency_flag 
			CASE 
				WHEN (l_rec_glparms.use_currency_flag = "N") #huho i think, there IS nothing we NEED do in this CASE 
					#IF fgl_lastkey() = fgl_keyval("up")  #huho 22.01.2018 why ??? I did comment this
					#OR fgl_lastkey() = fgl_keyval("left") THEN
					#      NEXT FIELD base_currency_code
					#END IF

					#   NEXT FIELD base_currency_code
				WHEN (l_rec_glparms.use_currency_flag = "Y") 
					IF l_rec_glparms.base_currency_code IS NULL THEN 
						LET glob_msgresp = kandoomsg("G",9505,"")			#9505 " Currency Code must be entered"
						NEXT FIELD base_currency_code 
					END IF 

				OTHERWISE 
					LET glob_msgresp = kandoomsg("G",9209,"")				#9209 " Must be Y OR N "
					NEXT FIELD use_currency_flag 
			END CASE 

		AFTER FIELD clear_acct_code 
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE coa.acct_code = l_rec_glparms.clear_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("U",9105,"")	#9105 RECORD NOT found. Try Window
				NEXT FIELD clear_acct_code 
			END IF 

			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_glparms.clear_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD clear_acct_code 
			END IF 

		AFTER FIELD post_susp_flag 
			CASE 
				WHEN (l_rec_glparms.post_susp_flag = "N") 
					NEXT FIELD exch_acct_code 

				WHEN (l_rec_glparms.post_susp_flag = "Y") 
					IF glob_chart_count = 0 THEN 
						LET glob_msgresp = kandoomsg("G",9210,"")	#9210 " Chart of Accounts have NOT been SET up "
						NEXT FIELD post_susp_flag 
					END IF 

				OTHERWISE 
					LET glob_msgresp = kandoomsg("G",9209,"")	#9209 " Must be Y OR N "
					NEXT FIELD post_susp_flag 
			END CASE 

		BEFORE FIELD susp_acct_code 
			IF l_rec_glparms.post_susp_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD post_susp_flag 
				ELSE 
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 

		AFTER FIELD susp_acct_code 
			IF l_rec_glparms.post_susp_flag = "Y" THEN 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.susp_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"") #9105 RECORD NOT found. Try Window
					NEXT FIELD susp_acct_code 
				END IF 
			END IF 

			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD susp_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF l_rec_glparms.exch_acct_code IS NULL THEN 
				IF l_rec_glparms.use_currency_flag = "Y" AND 
				glob_chart_count != 0 THEN 
					LET glob_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found. Try Window
					NEXT FIELD exch_acct_code 
				END IF 
			ELSE 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.exch_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")				#9105 RECORD NOT found. Try Window
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 
			
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD exch_acct_code 
			END IF 

		AFTER FIELD unexch_acct_code 
			IF l_rec_glparms.unexch_acct_code IS NULL THEN 
				IF l_rec_glparms.use_currency_flag = "Y" AND glob_chart_count != 0 THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 RECORD NOT found. Try Window
					NEXT FIELD unexch_acct_code 
				END IF 
			ELSE 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.unexch_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 RECORD NOT found. Try Window
					NEXT FIELD unexch_acct_code 
				END IF 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD unexch_acct_code 
			END IF 

		BEFORE FIELD cash_book_flag 
			IF l_rec_glparms.cb_code IS NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 
			
			SELECT max(jour_num) INTO glob_cnter FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF glob_cnter > l_rec_glparms.next_jour_num THEN 
				LET glob_msgresp = kandoomsg("G",9608,glob_cnter)			#9608 Batch number must be greater than XXX.
				LET l_rec_glparms.next_jour_num = glob_cnter + 1 
				NEXT FIELD next_jour_num 
			END IF
			 
			SELECT journal.desc_text INTO glob_rec_journal.desc_text FROM journal 
			WHERE jour_code = l_rec_glparms.gj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")			#9029 " Journal NOT found"
				NEXT FIELD gj_code 
			END IF 
			DISPLAY BY NAME glob_rec_journal.desc_text 

			SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
			WHERE jour_code = l_rec_glparms.rj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
				NEXT FIELD rj_code 
			END IF 
			
			DISPLAY glob_rec_journal.desc_text TO rcjdesc 

			IF l_rec_glparms.cb_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
				WHERE jour_code = l_rec_glparms.cb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")				#9029 " Journal NOT found"
					NEXT FIELD cb_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO cbjdesc 
			END IF 

			IF l_rec_glparms.acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
				WHERE jour_code = l_rec_glparms.acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
					NEXT FIELD acrl_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO accdesc 
			END IF 

			IF l_rec_glparms.rev_acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
				WHERE jour_code = l_rec_glparms.rev_acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")			#9029 " Journal NOT found"
					NEXT FIELD rev_acrl_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO acrdesc 
			END IF 

			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				SELECT * INTO glob_rec_currency.* FROM currency 
				WHERE currency_code = l_rec_glparms.base_currency_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9505,"Currency code")				#9505 " Currency code NOT found"
					NEXT FIELD base_currency_code 
				END IF 

				DISPLAY glob_rec_currency.desc_text TO currency.desc_text 
			END IF 

			IF l_rec_glparms.style_ind != 1 
			AND l_rec_glparms.style_ind != 2 
			AND l_rec_glparms.style_ind != 3 THEN 
				LET glob_msgresp = kandoomsg("G",9026,"1,2 OR 3")		#9026 " 1 OR 2 OR 3 must be entered"
				NEXT FIELD style_ind 
			END IF 

			IF l_rec_glparms.post_susp_flag = "Y" THEN 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.susp_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")	#9105 " RECORD NOT found, try window "
					NEXT FIELD post_susp_flag 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD post_susp_flag 
				END IF 
			END IF 

			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				IF l_rec_glparms.exch_acct_code IS NULL THEN 
					IF glob_chart_count != 0 THEN 
						LET glob_msgresp = kandoomsg("U",9105,"")		#9105 Realised Exchange Variance account must be entered
						NEXT FIELD exch_acct_code 
					END IF 

				ELSE 

					SELECT * INTO glob_rec_coa.* FROM coa 
					WHERE coa.acct_code = l_rec_glparms.exch_acct_code 
					AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found, try window "
						NEXT FIELD exch_acct_code 
					END IF 

					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD exch_acct_code 
					END IF 
				END IF 
			END IF 

			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				IF l_rec_glparms.unexch_acct_code IS NULL THEN 
					IF glob_chart_count != 0 THEN 
						LET glob_msgresp=kandoomsg("U",9105,"")	#9105 RECORD NOT found
						NEXT FIELD unexch_acct_code 
					END IF 
				ELSE 
					SELECT * INTO glob_rec_coa.* FROM coa 
					WHERE coa.acct_code = l_rec_glparms.unexch_acct_code 
					AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET glob_msgresp = kandoomsg("U",9105,"")				#9105 " RECORD NOT found, try window "
						NEXT FIELD unexch_acct_code 
					END IF 

					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD unexch_acct_code 
					END IF 
				END IF 
			END IF 

			IF l_rec_glparms.next_jour_num < 0 THEN 
				LET glob_msgresp = kandoomsg("U",9907,"zero")		#9907 Value must be greater than OR equal TO zero.
				NEXT FIELD next_jour_num 
			END IF 
			LET l_rec_glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_glparms.next_seq_num = 0 
			LET l_rec_glparms.key_code = "1" 
			INSERT INTO glparms VALUES (l_rec_glparms.*) 

	END INPUT 
END FUNCTION 
###########################################################################
# END FUNCTION add_parm()
###########################################################################


###########################################################################
# FUNCTION change_parm()
#
#
###########################################################################
FUNCTION change_parm() 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_s_glparms RECORD LIKE glparms.* 
	DEFINE l_temp_jour_num LIKE glparms.next_jour_num 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_check_flag CHAR(1) 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1"
	 
	LET l_rec_s_glparms.* = l_rec_glparms.* 
	LET glob_chart_count = 0 
	LET l_check_flag = true 

	SELECT count(*) INTO glob_chart_count FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET glob_msgresp = kandoomsg("U",1070,"") #1070 Enter Parameter details; OK TO continue.

	INPUT BY NAME 
		l_rec_glparms.next_jour_num, 
		l_rec_glparms.site_code, 
		l_rec_glparms.gj_code, 
		l_rec_glparms.rj_code, 
		l_rec_glparms.cb_code, 
		l_rec_glparms.acrl_code, 
		l_rec_glparms.rev_acrl_code, 
		l_rec_glparms.base_currency_code, 
		l_rec_glparms.use_currency_flag, 
		l_rec_glparms.control_tot_flag, 
		l_rec_glparms.use_clear_flag, 
		l_rec_glparms.style_ind, 
		l_rec_glparms.clear_acct_code, 
		l_rec_glparms.post_susp_flag, 
		l_rec_glparms.susp_acct_code, 
		l_rec_glparms.exch_acct_code, 
		l_rec_glparms.unexch_acct_code, 
		l_rec_glparms.cash_book_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZP","inp-glparms2") 


		ON ACTION "LOOKUP" infield (gj_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.gj_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.gj_code 

			END IF 
			NEXT FIELD gj_code 

		ON ACTION "LOOKUP" infield (rj_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.rj_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.rj_code 

			END IF 
			NEXT FIELD rj_code 

		ON ACTION "LOOKUP" infield (cb_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.cb_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.cb_code 

			END IF 
			NEXT FIELD cb_code 

		ON ACTION "LOOKUP" infield (acrl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.acrl_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.acrl_code 

			END IF 
			NEXT FIELD acrl_code 

		ON ACTION "LOOKUP" infield (rev_acrl_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.rev_acrl_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.rev_acrl_code 

			END IF 
			NEXT FIELD rev_acrl_code 

		ON ACTION "LOOKUP" infield (base_currency_code) 
			LET l_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.base_currency_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.base_currency_code 

			END IF 
			NEXT FIELD base_currency_code 

		ON ACTION "LOOKUP" infield (clear_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.clear_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.clear_acct_code 

			END IF 
			NEXT FIELD clear_acct_code 

		ON ACTION "LOOKUP" infield (susp_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.susp_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.susp_acct_code 

			END IF 
			NEXT FIELD susp_acct_code 

		ON ACTION "LOOKUP" infield (exch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.exch_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.exch_acct_code 

			END IF 
			NEXT FIELD exch_acct_code 

		ON ACTION "LOOKUP" infield (unexch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_glparms.unexch_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_glparms.unexch_acct_code 
			END IF 
			NEXT FIELD unexch_acct_code 

		BEFORE FIELD next_jour_num 
			LET l_temp_jour_num = l_rec_glparms.next_jour_num 

		AFTER FIELD next_jour_num 
			IF l_temp_jour_num != l_rec_glparms.next_jour_num THEN 
				SELECT max(jour_num) ## despite the NAME next_jour_num 
				INTO l_temp_jour_num ## the value in this FIELD IS fact 
				FROM batchhead ## the CURRENT journal num, 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code ## ie, (next journal num - 1) 
			END IF 

			IF l_rec_glparms.next_jour_num < l_temp_jour_num OR l_rec_glparms.next_jour_num IS NULL THEN 
				LET glob_msgresp = kandoomsg("G",9608,l_temp_jour_num)	#9608 Batch number must be greater than XXX.
				LET l_rec_glparms.next_jour_num = l_temp_jour_num 
				NEXT FIELD next_jour_num 
			END IF 

		AFTER FIELD gj_code 
			SELECT journal.desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE journal.jour_code = l_rec_glparms.gj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
				NEXT FIELD gj_code 
			END IF 

			DISPLAY BY NAME glob_rec_journal.desc_text 

		AFTER FIELD rj_code 
			SELECT journal.desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE journal.jour_code = l_rec_glparms.rj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
				NEXT FIELD rj_code 
			END IF 
			DISPLAY glob_rec_journal.desc_text TO rcjdesc 

		AFTER FIELD cb_code 
			IF l_rec_glparms.cb_code IS NOT NULL THEN 
				SELECT journal.desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE journal.jour_code = l_rec_glparms.cb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
					NEXT FIELD cb_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO cbjdesc 
			END IF 

		AFTER FIELD acrl_code 
			IF l_rec_glparms.acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
					NEXT FIELD acrl_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO accdesc 
			END IF 

		AFTER FIELD rev_acrl_code 
			IF l_rec_glparms.rev_acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.rev_acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")	#9029 " Journal NOT found"
					NEXT FIELD rev_acrl_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO acrdesc 

			END IF 

		BEFORE FIELD base_currency_code 
--			IF NOT l_check_flag THEN 
--				IF fgl_lastkey() = fgl_keyval("up") 
--				OR fgl_lastkey() = fgl_keyval("left") THEN 
--					NEXT FIELD rev_acrl_code 
--				ELSE 
--					NEXT FIELD use_currency_flag 
--				END IF 
--			ELSE 
			IF l_check_flag THEN
				SELECT UNIQUE 1 FROM batchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND currency_code = l_rec_glparms.base_currency_code 
				IF STATUS != NOTFOUND THEN 
					LET l_check_flag = false 
					NEXT FIELD use_currency_flag 
				END IF 
			END IF 

		AFTER FIELD base_currency_code 
			IF l_rec_glparms.base_currency_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
				NEXT FIELD base_currency_code 
			END IF 

			SELECT * INTO glob_rec_currency.* FROM currency 
			WHERE currency_code = l_rec_glparms.base_currency_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("U",9111,"Currency code") 
				#9111 " Currency code NOT found"
				NEXT FIELD base_currency_code 
			END IF 

			DISPLAY glob_rec_currency.desc_text TO currency.desc_text 

		AFTER FIELD use_currency_flag 
			CASE 
				WHEN (l_rec_glparms.use_currency_flag = "N") 

				WHEN (l_rec_glparms.use_currency_flag = "Y") 
					IF l_rec_glparms.base_currency_code IS NULL THEN 
						LET glob_msgresp = kandoomsg("G",9505,"")	#9505 "Currency Code must be entered"
						NEXT FIELD base_currency_code 
					END IF 

				OTHERWISE 
					LET glob_msgresp = kandoomsg("G",9209,"")	#9209 " Must be Y OR N "
					NEXT FIELD use_currency_flag 
			END CASE 

		AFTER FIELD post_susp_flag 
			CASE 
				WHEN (l_rec_glparms.post_susp_flag = "N") 
					NEXT FIELD exch_acct_code 

				WHEN (l_rec_glparms.post_susp_flag = "Y") 
					IF glob_chart_count = 0 THEN 
						LET glob_msgresp = kandoomsg("G",9210,"")		#9210 " Chart of Accounts have NOT been SET up "
						NEXT FIELD post_susp_flag 
					END IF 

				OTHERWISE 
					LET glob_msgresp = kandoomsg("G",9209,"") 		#9209 " Must be Y OR N "
					NEXT FIELD post_susp_flag 
			END CASE 

		AFTER FIELD clear_acct_code 
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE coa.acct_code = l_rec_glparms.clear_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("U",9105,"") 	#9105 RECORD NOT found. Try Window
				NEXT FIELD clear_acct_code 
			END IF 

			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_glparms.clear_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD clear_acct_code 
			END IF 

		BEFORE FIELD susp_acct_code 
			IF l_rec_glparms.post_susp_flag = "N" THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD post_susp_flag 
				ELSE 
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 

		AFTER FIELD susp_acct_code 
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE coa.acct_code = l_rec_glparms.susp_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found, try window "
				NEXT FIELD susp_acct_code 
			END IF 

			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD susp_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF l_rec_glparms.exch_acct_code IS NULL THEN 
				IF l_rec_glparms.use_currency_flag = "Y" AND glob_chart_count != 0 THEN 
					LET glob_msgresp=kandoomsg("U",9105,"")			#9105 " RECORD NOT found
					NEXT FIELD exch_acct_code 
				END IF 
			ELSE 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.exch_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 "Record NOT found, try window "
					NEXT FIELD exch_acct_code 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 

		AFTER FIELD unexch_acct_code 
			IF l_rec_glparms.unexch_acct_code IS NULL THEN 
				IF l_rec_glparms.use_currency_flag = "Y" AND glob_chart_count != 0 THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found
					NEXT FIELD unexch_acct_code 
				END IF 
			ELSE 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.unexch_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found, try window "
					NEXT FIELD unexch_acct_code 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD unexch_acct_code 
				END IF 
			END IF 

		BEFORE FIELD cash_book_flag 
			IF l_rec_glparms.cb_code IS NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			SELECT journal.desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE journal.jour_code = l_rec_glparms.gj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")		#9029 " Journal NOT found"
				NEXT FIELD gj_code 
			END IF 

			DISPLAY BY NAME glob_rec_journal.desc_text 

			SELECT journal.desc_text INTO glob_rec_journal.desc_text 
			FROM journal 
			WHERE journal.jour_code = l_rec_glparms.rj_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET glob_msgresp = kandoomsg("G",9029,"")	#9029 " Journal NOT found"
				NEXT FIELD rj_code 
			END IF 

			DISPLAY glob_rec_journal.desc_text TO rcjdesc 

			IF l_rec_glparms.cb_code IS NOT NULL THEN 
				SELECT journal.desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE journal.jour_code = l_rec_glparms.cb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")			#9029 " Journal NOT found"
					NEXT FIELD cb_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO cbjdesc 
			END IF 

			IF l_rec_glparms.acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"")			#9029 " Journal NOT found"
					NEXT FIELD acrl_code 
				END IF 

				DISPLAY glob_rec_journal.desc_text TO accdesc 
			END IF 

			IF l_rec_glparms.rev_acrl_code IS NOT NULL THEN 
				SELECT desc_text INTO glob_rec_journal.desc_text 
				FROM journal 
				WHERE jour_code = l_rec_glparms.rev_acrl_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("G",9029,"") 
					#9029 " Journal NOT found"
					NEXT FIELD rev_acrl_code 
				END IF 
				DISPLAY glob_rec_journal.desc_text TO acrdesc 
			END IF 

			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				SELECT * INTO glob_rec_currency.* FROM currency 
				WHERE currency_code = l_rec_glparms.base_currency_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9111,"Currency code")		#9111 " Currency code NOT found"
					NEXT FIELD base_currency_code 
				END IF 

				DISPLAY glob_rec_currency.desc_text TO currency.desc_text 
			END IF 

			IF l_rec_glparms.style_ind != 1 
			AND l_rec_glparms.style_ind != 2 
			AND l_rec_glparms.style_ind != 3 THEN 
				LET glob_msgresp = kandoomsg("G",9026,"1,2 OR 3")		#9026 " 1 OR 2 OR 3 must be entered"
				NEXT FIELD style_ind 
			END IF 

			IF l_rec_glparms.post_susp_flag = "Y" THEN 
				SELECT * INTO glob_rec_coa.* FROM coa 
				WHERE coa.acct_code = l_rec_glparms.susp_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found, try window "
					NEXT FIELD post_susp_flag 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD post_susp_flag 
				END IF 
			END IF 

			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				IF l_rec_glparms.exch_acct_code IS NULL THEN 
					IF glob_chart_count != 0 THEN 
						LET glob_msgresp=kandoomsg("U",9105,"") 				#9105 " RECORD NOT found
						NEXT FIELD exch_acct_code 
					END IF 
				ELSE 
					SELECT * INTO glob_rec_coa.* FROM coa 
					WHERE coa.acct_code = l_rec_glparms.exch_acct_code 
					AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET glob_msgresp = kandoomsg("U",9105,"")				#9105 " RECORD NOT found, try window "
						NEXT FIELD exch_acct_code 
					END IF 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD exch_acct_code 
					END IF 
				END IF 
			END IF 
			
			IF l_rec_glparms.use_currency_flag = "Y" THEN 
				IF l_rec_glparms.unexch_acct_code IS NULL THEN 
					IF glob_chart_count != 0 THEN 
						LET glob_msgresp=kandoomsg("U",9105,"") 					#9105 RECORD NOT found
						NEXT FIELD unexch_acct_code 
					END IF 
				ELSE 
					SELECT * INTO glob_rec_coa.* FROM coa 
					WHERE coa.acct_code = l_rec_glparms.unexch_acct_code 
					AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET glob_msgresp = kandoomsg("U",9105,"")			#9105 " RECORD NOT found, try window "
						NEXT FIELD unexch_acct_code 
					END IF 
					
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD unexch_acct_code 
					END IF
					 
				END IF 
			END IF 
			
			IF l_rec_glparms.next_jour_num < 0 THEN 
				LET glob_msgresp = kandoomsg("U",9907,"zero")				#9907 Value must be greater OR equal TO zero.
				NEXT FIELD next_jour_num 
			END IF
			 
			IF update_glparms(l_rec_glparms.*, l_rec_s_glparms.*) THEN 
				LET glob_msgresp = kandoomsg("U",1104,"General Ledger Parameters")			#1104 Successful UPDATE of ...
				RETURN true 
			ELSE 
				LET glob_msgresp = kandoomsg("U",1105,"General Ledger Parameters")				#1105 Update of ... failed
				RETURN false 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION change_parm()
###########################################################################


###########################################################################
# FUNCTION disp_parm()
#
#
###########################################################################
FUNCTION disp_parm() 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 

	CLEAR FORM 
	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	DISPLAY BY NAME 
		l_rec_glparms.next_jour_num, 
		l_rec_glparms.site_code, 
		l_rec_glparms.gj_code, 
		l_rec_glparms.rj_code, 
		l_rec_glparms.cb_code, 
		l_rec_glparms.acrl_code, 
		l_rec_glparms.rev_acrl_code, 
		l_rec_glparms.base_currency_code, 
		l_rec_glparms.cash_book_flag, 
		l_rec_glparms.use_currency_flag, 
		l_rec_glparms.control_tot_flag, 
		l_rec_glparms.use_clear_flag, 
		l_rec_glparms.style_ind, 
		l_rec_glparms.clear_acct_code, 
		l_rec_glparms.post_susp_flag, 
		l_rec_glparms.susp_acct_code, 
		l_rec_glparms.exch_acct_code, 
		l_rec_glparms.unexch_acct_code, 
		l_rec_glparms.last_post_date 

	IF l_rec_glparms.last_acrl_yr_num IS NOT NULL AND l_rec_glparms.last_acrl_yr_num != 0 THEN 
		DISPLAY BY NAME 
			l_rec_glparms.last_acrl_yr_num, 
			l_rec_glparms.last_acrl_per_num 
	END IF 

	SELECT desc_text INTO glob_rec_journal.desc_text 
	FROM journal 
	WHERE jour_code = l_rec_glparms.gj_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		DISPLAY BY NAME glob_rec_journal.desc_text 
	END IF 

	SELECT desc_text INTO glob_rec_journal.desc_text 
	FROM journal 
	WHERE jour_code = l_rec_glparms.rj_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		DISPLAY glob_rec_journal.desc_text TO rcjdesc 
	END IF 

	SELECT desc_text INTO glob_rec_journal.desc_text 
	FROM journal 
	WHERE jour_code = l_rec_glparms.cb_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		DISPLAY glob_rec_journal.desc_text TO cbjdesc 
	END IF 

	SELECT desc_text INTO glob_rec_journal.desc_text 
	FROM journal 
	WHERE jour_code = l_rec_glparms.acrl_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		DISPLAY glob_rec_journal.desc_text TO accdesc 
	END IF 

	SELECT desc_text INTO glob_rec_journal.desc_text 
	FROM journal 
	WHERE jour_code = l_rec_glparms.rev_acrl_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status != NOTFOUND THEN 
		DISPLAY glob_rec_journal.desc_text TO acrdesc 
	END IF 
	SELECT * INTO glob_rec_currency.* FROM currency 
	WHERE currency_code = l_rec_glparms.base_currency_code 

	IF status != NOTFOUND THEN 
		DISPLAY glob_rec_currency.desc_text TO currency.desc_text 
	END IF 

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION disp_parm()
###########################################################################


###########################################################################
# FUNCTION budgets(p_action_ind)
#
#
###########################################################################
FUNCTION budgets(p_action_ind) 
	DEFINE p_action_ind CHAR(1) 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_s_glparms RECORD LIKE glparms.* 
	DEFINE l_return SMALLINT 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	
	LET l_rec_s_glparms.* = l_rec_glparms.* 

	OPEN WINDOW G422 with FORM "G422" 
	CALL windecoration_g("G422") 

	IF p_action_ind != "D" THEN 
		LET glob_msgresp = kandoomsg("U",1070,"")	#1070 Enter Parameter details; OK TO continue.
	END IF 
	
	DISPLAY BY NAME 
		l_rec_glparms.budg1_text, 
		l_rec_glparms.budg1_close_flag, 
		l_rec_glparms.budg2_text, 
		l_rec_glparms.budg2_close_flag, 
		l_rec_glparms.budg3_text, 
		l_rec_glparms.budg3_close_flag, 
		l_rec_glparms.budg4_text, 
		l_rec_glparms.budg4_close_flag, 
		l_rec_glparms.budg5_text, 
		l_rec_glparms.budg5_close_flag, 
		l_rec_glparms.budg6_text, 
		l_rec_glparms.budg6_close_flag 

	IF p_action_ind = "D" THEN 
		CALL eventsuspend()#let glob_msgresp = kandoomsg("U",1,"") #1 Any key TO Continue
		LET l_return = true 
	ELSE 
		INPUT BY NAME 
			l_rec_glparms.budg1_text, 
			l_rec_glparms.budg1_close_flag, 
			l_rec_glparms.budg2_text, 
			l_rec_glparms.budg2_close_flag, 
			l_rec_glparms.budg3_text, 
			l_rec_glparms.budg3_close_flag, 
			l_rec_glparms.budg4_text, 
			l_rec_glparms.budg4_close_flag, 
			l_rec_glparms.budg5_text, 
			l_rec_glparms.budg5_close_flag, 
			l_rec_glparms.budg6_text, 
			l_rec_glparms.budg6_close_flag WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZP","inp-glparms3") 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_return = false 
				ELSE 
					IF update_glparms(l_rec_glparms.*, l_rec_s_glparms.*) THEN 
						LET glob_msgresp = kandoomsg("U",1104,"General Ledger Parameters")						#1104 Successful UPDATE of ...
						LET l_return = true 
					ELSE 
						LET glob_msgresp = kandoomsg("U",1105,"General Ledger Parameters") 					#1105 Update of ... failed
						LET l_return = false 
					END IF 
				END IF 

		END INPUT 

	END IF 

	CLOSE WINDOW g422 

	IF l_return THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION budgets(p_action_ind)
###########################################################################


###########################################################################
# FUNCTION no_glparm_changes(p_rec_glparms, p_rec_2_glparms)
#
#
###########################################################################
#
# No GL Parameter Changes FUNCTION
#
###########################################################################
FUNCTION no_glparm_changes(p_rec_glparms, p_rec_2_glparms) 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_rec_2_glparms RECORD LIKE glparms.* 

	IF ((p_rec_glparms.next_jour_num IS NULL AND 
	p_rec_2_glparms.next_jour_num IS NOT null) OR 
	(p_rec_2_glparms.next_jour_num IS NULL AND 
	p_rec_glparms.next_jour_num IS NOT null) OR 
	(p_rec_glparms.next_jour_num != p_rec_2_glparms.next_jour_num)) OR 

	####
	((p_rec_glparms.next_seq_num IS NULL AND 
	p_rec_2_glparms.next_seq_num IS NOT null) OR 
	(p_rec_2_glparms.next_seq_num IS NULL AND 
	p_rec_glparms.next_seq_num IS NOT null) OR 
	(p_rec_glparms.next_seq_num != p_rec_2_glparms.next_seq_num)) OR 

	####
	((p_rec_glparms.next_post_num IS NULL AND 
	p_rec_2_glparms.next_post_num IS NOT null) OR 
	(p_rec_2_glparms.next_post_num IS NULL AND 
	p_rec_glparms.next_post_num IS NOT null) OR 
	(p_rec_glparms.next_post_num != p_rec_2_glparms.next_post_num)) OR 

	####
	((p_rec_glparms.next_load_num IS NULL AND 
	p_rec_2_glparms.next_load_num IS NOT null) OR 
	(p_rec_2_glparms.next_load_num IS NULL AND 
	p_rec_glparms.next_load_num IS NOT null) OR 
	(p_rec_glparms.next_load_num != p_rec_2_glparms.next_load_num)) OR 

	####
	((p_rec_glparms.next_consol_num IS NULL AND 
	p_rec_2_glparms.next_consol_num IS NOT null) OR 
	(p_rec_2_glparms.next_consol_num IS NULL AND 
	p_rec_glparms.next_consol_num IS NOT null) OR 
	(p_rec_glparms.next_consol_num != p_rec_2_glparms.next_consol_num)) OR 

	####
	((p_rec_glparms.gj_code IS NULL AND 
	p_rec_2_glparms.gj_code IS NOT null) OR 
	(p_rec_2_glparms.gj_code IS NULL AND 
	p_rec_glparms.gj_code IS NOT null) OR 
	(p_rec_glparms.gj_code != p_rec_2_glparms.gj_code)) OR 

	####
	((p_rec_glparms.rj_code IS NULL AND 
	p_rec_2_glparms.rj_code IS NOT null) OR 
	(p_rec_2_glparms.rj_code IS NULL AND 
	p_rec_glparms.rj_code IS NOT null) OR 
	(p_rec_glparms.rj_code != p_rec_2_glparms.rj_code )) OR 

	####
	((p_rec_glparms.cb_code IS NULL AND 
	p_rec_2_glparms.cb_code IS NOT null) OR 
	(p_rec_2_glparms.cb_code IS NULL AND 
	p_rec_glparms.cb_code IS NOT null) OR 
	(p_rec_glparms.cb_code != p_rec_2_glparms.cb_code )) OR 

	####
	((p_rec_glparms.last_post_date IS NULL AND 
	p_rec_2_glparms.last_post_date IS NOT null) OR 
	(p_rec_2_glparms.last_post_date IS NULL AND 
	p_rec_glparms.last_post_date IS NOT null) OR 
	(p_rec_glparms.last_post_date != p_rec_2_glparms.last_post_date )) OR 

	####
	((p_rec_glparms.last_update_date IS NULL AND 
	p_rec_2_glparms.last_update_date IS NOT null) OR 
	(p_rec_2_glparms.last_update_date IS NULL AND 
	p_rec_glparms.last_update_date IS NOT null) OR 
	(p_rec_glparms.last_update_date != p_rec_2_glparms.last_update_date )) OR 

	####
	((p_rec_glparms.last_close_date IS NULL AND 
	p_rec_2_glparms.last_close_date IS NOT null) OR 
	(p_rec_2_glparms.last_close_date IS NULL AND 
	p_rec_glparms.last_close_date IS NOT null) OR 
	(p_rec_glparms.last_close_date != p_rec_2_glparms.last_close_date )) OR 

	####
	((p_rec_glparms.last_del_date IS NULL AND 
	p_rec_2_glparms.last_del_date IS NOT null) OR 
	(p_rec_2_glparms.last_del_date IS NULL AND 
	p_rec_glparms.last_del_date IS NOT null) OR 
	(p_rec_glparms.last_del_date != p_rec_2_glparms.last_del_date )) OR 

	####
	((p_rec_glparms.cash_book_flag IS NULL AND 
	p_rec_2_glparms.cash_book_flag IS NOT null) OR 
	(p_rec_2_glparms.cash_book_flag IS NULL AND 
	p_rec_glparms.cash_book_flag IS NOT null) OR 
	(p_rec_glparms.cash_book_flag!= p_rec_2_glparms.cash_book_flag)) OR 

	####
	((p_rec_glparms.post_susp_flag IS NULL AND 
	p_rec_2_glparms.post_susp_flag IS NOT null) OR 
	(p_rec_2_glparms.post_susp_flag IS NULL AND 
	p_rec_glparms.post_susp_flag IS NOT null) OR 
	(p_rec_glparms.post_susp_flag!= p_rec_2_glparms.post_susp_flag)) OR 

	####
	((p_rec_glparms.susp_acct_code IS NULL AND 
	p_rec_2_glparms.susp_acct_code IS NOT null) OR 
	(p_rec_2_glparms.susp_acct_code IS NULL AND 
	p_rec_glparms.susp_acct_code IS NOT null) OR 
	(p_rec_glparms.susp_acct_code!= p_rec_2_glparms.susp_acct_code)) OR 

	####
	((p_rec_glparms.exch_acct_code IS NULL AND 
	p_rec_2_glparms.exch_acct_code IS NOT null) OR 
	(p_rec_2_glparms.exch_acct_code IS NULL AND 
	p_rec_glparms.exch_acct_code IS NOT null) OR 
	(p_rec_glparms.exch_acct_code!= p_rec_2_glparms.exch_acct_code)) OR 

	####
	((p_rec_glparms.unexch_acct_code IS NULL AND 
	p_rec_2_glparms.unexch_acct_code IS NOT null) OR 
	(p_rec_2_glparms.unexch_acct_code IS NULL AND 
	p_rec_glparms.unexch_acct_code IS NOT null) OR 
	(p_rec_glparms.unexch_acct_code!= p_rec_2_glparms.unexch_acct_code)) OR 

	####
	((p_rec_glparms.post_total_amt IS NULL AND 
	p_rec_2_glparms.post_total_amt IS NOT null) OR 
	(p_rec_2_glparms.post_total_amt IS NULL AND 
	p_rec_glparms.post_total_amt IS NOT null) OR 
	(p_rec_glparms.post_total_amt != p_rec_2_glparms.post_total_amt)) OR 

	####
	((p_rec_glparms.control_tot_flag IS NULL AND 
	p_rec_2_glparms.control_tot_flag IS NOT null) OR 
	(p_rec_2_glparms.control_tot_flag IS NULL AND 
	p_rec_glparms.control_tot_flag IS NOT null) OR 
	(p_rec_glparms.control_tot_flag!= p_rec_2_glparms.control_tot_flag)) OR 

	####
	((p_rec_glparms.use_clear_flag IS NULL AND 
	p_rec_2_glparms.use_clear_flag IS NOT null) OR 
	(p_rec_2_glparms.use_clear_flag IS NULL AND 
	p_rec_glparms.use_clear_flag IS NOT null) OR 
	(p_rec_glparms.use_clear_flag!= p_rec_2_glparms.use_clear_flag)) OR 

	####
	((p_rec_glparms.use_currency_flag IS NULL AND 
	p_rec_2_glparms.use_currency_flag IS NOT null) OR 
	(p_rec_2_glparms.use_currency_flag IS NULL AND 
	p_rec_glparms.use_currency_flag IS NOT null) OR 
	(p_rec_glparms.use_currency_flag!= p_rec_2_glparms.use_currency_flag)) OR 

	####
	((p_rec_glparms.base_currency_code IS NULL AND 
	p_rec_2_glparms.base_currency_code IS NOT null) OR 
	(p_rec_2_glparms.base_currency_code IS NULL AND 
	p_rec_glparms.base_currency_code IS NOT null) OR 
	(p_rec_glparms.base_currency_code!= p_rec_2_glparms.base_currency_code)) OR 

	####
	((p_rec_glparms.budg1_text IS NULL AND 
	p_rec_2_glparms.budg1_text IS NOT null) OR 
	(p_rec_2_glparms.budg1_text IS NULL AND 
	p_rec_glparms.budg1_text IS NOT null) OR 
	(p_rec_glparms.budg1_text != p_rec_2_glparms.budg1_text )) OR 

	####
	((p_rec_glparms.budg1_close_flag IS NULL AND 
	p_rec_2_glparms.budg1_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg1_close_flag IS NULL AND 
	p_rec_glparms.budg1_close_flag IS NOT null) OR 
	(p_rec_glparms.budg1_close_flag != p_rec_2_glparms.budg1_close_flag )) OR 

	####
	((p_rec_glparms.budg2_text IS NULL AND 
	p_rec_2_glparms.budg2_text IS NOT null) OR 
	(p_rec_2_glparms.budg2_text IS NULL AND 
	p_rec_glparms.budg2_text IS NOT null) OR 
	(p_rec_glparms.budg2_text != p_rec_2_glparms.budg2_text )) OR 

	####
	((p_rec_glparms.budg2_close_flag IS NULL AND 
	p_rec_2_glparms.budg2_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg2_close_flag IS NULL AND 
	p_rec_glparms.budg2_close_flag IS NOT null) OR 
	(p_rec_glparms.budg2_close_flag != p_rec_2_glparms.budg2_close_flag )) OR 

	####
	((p_rec_glparms.budg3_text IS NULL AND 
	p_rec_2_glparms.budg3_text IS NOT null) OR 
	(p_rec_2_glparms.budg3_text IS NULL AND 
	p_rec_glparms.budg3_text IS NOT null) OR 
	(p_rec_glparms.budg3_text != p_rec_2_glparms.budg3_text )) OR 

	####
	((p_rec_glparms.budg3_close_flag IS NULL AND 
	p_rec_2_glparms.budg3_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg3_close_flag IS NULL AND 
	p_rec_glparms.budg3_close_flag IS NOT null) OR 
	(p_rec_glparms.budg3_close_flag != p_rec_2_glparms.budg3_close_flag )) OR 

	####
	((p_rec_glparms.budg4_text IS NULL AND 
	p_rec_2_glparms.budg4_text IS NOT null) OR 
	(p_rec_2_glparms.budg4_text IS NULL AND 
	p_rec_glparms.budg4_text IS NOT null) OR 
	(p_rec_glparms.budg4_text != p_rec_2_glparms.budg4_text )) OR 

	####
	((p_rec_glparms.budg4_close_flag IS NULL AND 
	p_rec_2_glparms.budg4_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg4_close_flag IS NULL AND 
	p_rec_glparms.budg4_close_flag IS NOT null) OR 
	(p_rec_glparms.budg4_close_flag != p_rec_2_glparms.budg4_close_flag )) OR 

	####
	((p_rec_glparms.budg5_text IS NULL AND 
	p_rec_2_glparms.budg5_text IS NOT null) OR 
	(p_rec_2_glparms.budg5_text IS NULL AND 
	p_rec_glparms.budg5_text IS NOT null) OR 
	(p_rec_glparms.budg5_text != p_rec_2_glparms.budg5_text )) OR 

	####
	((p_rec_glparms.budg5_close_flag IS NULL AND 
	p_rec_2_glparms.budg5_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg5_close_flag IS NULL AND 
	p_rec_glparms.budg5_close_flag IS NOT null) OR 
	(p_rec_glparms.budg5_close_flag != p_rec_2_glparms.budg5_close_flag )) OR 

	####
	((p_rec_glparms.budg6_text IS NULL AND 
	p_rec_2_glparms.budg6_text IS NOT null) OR 
	(p_rec_2_glparms.budg6_text IS NULL AND 
	p_rec_glparms.budg6_text IS NOT null) OR 
	(p_rec_glparms.budg6_text != p_rec_2_glparms.budg6_text )) OR 

	####
	((p_rec_glparms.budg6_close_flag IS NULL AND 
	p_rec_2_glparms.budg6_close_flag IS NOT null) OR 
	(p_rec_2_glparms.budg6_close_flag IS NULL AND 
	p_rec_glparms.budg6_close_flag IS NOT null) OR 
	(p_rec_glparms.budg6_close_flag != p_rec_2_glparms.budg6_close_flag )) OR 

	####
	((p_rec_glparms.style_ind IS NULL AND 
	p_rec_2_glparms.style_ind IS NOT null) OR 
	(p_rec_2_glparms.style_ind IS NULL AND 
	p_rec_glparms.style_ind IS NOT null) OR 
	(p_rec_glparms.style_ind != p_rec_2_glparms.style_ind )) OR 

	####
	((p_rec_glparms.site_code IS NULL AND 
	p_rec_2_glparms.site_code IS NOT null) OR 
	(p_rec_2_glparms.site_code IS NULL AND 
	p_rec_glparms.site_code IS NOT null) OR 
	(p_rec_glparms.site_code != p_rec_2_glparms.site_code )) OR 

	####
	((p_rec_glparms.acrl_code IS NULL AND 
	p_rec_2_glparms.acrl_code IS NOT null) OR 
	(p_rec_2_glparms.acrl_code IS NULL AND 
	p_rec_glparms.acrl_code IS NOT null) OR 
	(p_rec_glparms.acrl_code != p_rec_2_glparms.acrl_code )) OR 

	####
	((p_rec_glparms.rev_acrl_code IS NULL AND 
	p_rec_2_glparms.rev_acrl_code IS NOT null) OR 
	(p_rec_2_glparms.rev_acrl_code IS NULL AND 
	p_rec_glparms.rev_acrl_code IS NOT null) OR 
	(p_rec_glparms.rev_acrl_code != p_rec_2_glparms.rev_acrl_code )) OR 

	####
	((p_rec_glparms.last_acrl_yr_num IS NULL AND 
	p_rec_2_glparms.last_acrl_yr_num IS NOT null) OR 
	(p_rec_2_glparms.last_acrl_yr_num IS NULL AND 
	p_rec_glparms.last_acrl_yr_num IS NOT null) OR 
	(p_rec_glparms.last_acrl_yr_num != p_rec_2_glparms.last_acrl_yr_num )) OR 

	####
	((p_rec_glparms.last_acrl_per_num IS NULL AND 
	p_rec_2_glparms.last_acrl_per_num IS NOT null) OR 
	(p_rec_2_glparms.last_acrl_per_num IS NULL AND 
	p_rec_glparms.last_acrl_per_num IS NOT null) OR 
	(p_rec_glparms.last_acrl_per_num != p_rec_2_glparms.last_acrl_per_num )) OR 
	((p_rec_glparms.last_acrl_per_num IS NULL AND 
	p_rec_2_glparms.last_acrl_per_num IS NOT null) OR 
	(p_rec_2_glparms.last_acrl_per_num IS NULL AND 
	p_rec_glparms.last_acrl_per_num IS NOT null) OR 
	(p_rec_glparms.last_acrl_per_num != p_rec_2_glparms.last_acrl_per_num )) 
	THEN 
		### CALL kandoomsg TO indicate changes have occured TO glparms
		LET glob_msgresp = kandoomsg("G",7026,"") #7026 There has been changes made TO the General Ledger Para...
		RETURN false 
	ELSE 
		SELECT unique 1 FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		AND next_jour_num = p_rec_2_glparms.next_jour_num 
		IF status = NOTFOUND THEN 
			LET glob_msgresp = kandoomsg("G",7026,"")		#7026 There has been changes made TO the General Ledger Para...
			RETURN false 
		END IF 
	END IF 

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION no_glparm_changes(p_rec_glparms, p_rec_2_glparms)
###########################################################################


###########################################################################
# FUNCTION update_glparms(p_rec_glparms, p_rec_2_glparms)
#
#
###########################################################################
FUNCTION update_glparms(p_rec_glparms, p_rec_2_glparms) 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	DEFINE p_rec_2_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_x_glparms RECORD LIKE glparms.* 

	 
	BEGIN WORK 
		DECLARE c_glparms CURSOR FOR 
		SELECT * FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 

		OPEN c_glparms
		WHENEVER SQLERROR CONTINUE 
		FETCH c_glparms INTO l_rec_x_glparms.* 

		IF status <> 0 THEN 
			-- WHENEVER ERROR # stop bad usage of WHENEVER ERROR  
			ROLLBACK WORK 
			RETURN false 
		END IF 

		IF no_glparm_changes(l_rec_x_glparms.*, p_rec_2_glparms.*) THEN 
			UPDATE glparms 
			SET glparms.* = p_rec_glparms.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			IF status <> 0 THEN 
				-- WHENEVER ERROR stop same bad usage 
				ROLLBACK WORK 
				RETURN false 
			ELSE  
				COMMIT WORK 
				RETURN true 
			END IF 
		ELSE  
			ROLLBACK WORK 
			RETURN false 
		END IF 

END FUNCTION 
###########################################################################
# END FUNCTION update_glparms(p_rec_glparms, p_rec_2_glparms)
###########################################################################