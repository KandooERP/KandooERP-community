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

# \brief module G31 - % Based recurring journal disbursement Maintenance

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G31_GLOBALS.4gl" 

###########################################################################
# FUNCTION G31_main()
#
#
###########################################################################
FUNCTION G31_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("G31") 

	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",5007,"")	#5007" General Ledger Parameters Not Set Up - Refer Menu GZP "
		CALL fgl_winmessage("#5007 - General Ledger Parameters Not Set Up",kandoomsg2("G",5007,""),"ERROR")
		EXIT PROGRAM 
	END IF 
	
	CALL create_table("disbdetl","t_disbdetl","","N") 

	OPEN WINDOW G459 with FORM "G459" 
	CALL windecoration_g("G459") 

	CALL scan_disb() 
	
	CLOSE WINDOW G459
	 
END FUNCTION
###########################################################################
# END FUNCTION G31_main()
###########################################################################


############################################################
# FUNCTION db_disbhead_get_datasource(p_filter) 
#
#
############################################################
FUNCTION db_disbhead_get_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_disbhead RECORD LIKE disbhead.*
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			disb_code LIKE disbhead.disb_code, 
			desc_text LIKE disbhead.desc_text, 
			group_code LIKE disbhead.group_code, 
			acct_code LIKE disbhead.acct_code, 
			type_ind LIKE disbhead.type_ind 
		END RECORD 

	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 

	IF NOT p_filter THEN 
		LET l_where_text = " 1=1 " 
	ELSE 
		CLEAR FORM 
		MESSAGE kandoomsg2("G",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			disb_code, 
			desc_text, 
			group_code, 
			acct_code, 
			type_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G31","construct-disb") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("G",1002,"")		#1002 " Searching database - please wait "
	LET l_query_text = 
		"SELECT * FROM disbhead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_disbhead FROM l_query_text 
	DECLARE c_disbhead CURSOR FOR s_disbhead 

	LET l_idx = 0 
	FOREACH c_disbhead INTO l_rec_disbhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_disbhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_disbhead[l_idx].disb_code = l_rec_disbhead.disb_code 
		LET l_arr_rec_disbhead[l_idx].desc_text = l_rec_disbhead.desc_text 
		LET l_arr_rec_disbhead[l_idx].group_code = l_rec_disbhead.group_code 
		LET l_arr_rec_disbhead[l_idx].acct_code = l_rec_disbhead.acct_code 
		LET l_arr_rec_disbhead[l_idx].type_ind = l_rec_disbhead.type_ind 
		
--			IF l_idx = 200 THEN
--			   ERROR kandoomsg2("G",9035,l_idx)  #9035" First 200 Journal Disbursements Selected Only "
--			   EXIT FOREACH
--			END IF
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		MESSAGE kandoomsg2("G",9036,"")		#9036 No Journal Disbursements Selected
		LET l_idx = 1 
	END IF 

	RETURN l_arr_rec_disbhead 
END FUNCTION 
############################################################
# END FUNCTION select_disb()
############################################################


############################################################
# FUNCTION scan_disb()
#
#
############################################################
FUNCTION scan_disb() 
	DEFINE l_arr_rec_disbhead DYNAMIC ARRAY OF --array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			disb_code LIKE disbhead.disb_code, 
			desc_text LIKE disbhead.desc_text, 
			group_code LIKE disbhead.group_code, 
			acct_code LIKE disbhead.acct_code, 
			type_ind LIKE disbhead.type_ind 
		END RECORD 
		--DEFINE glob_scrn_size SMALLINT, ## Constant = size of G459 SCREEN array # huho
		DEFINE l_scroll_flag CHAR(1) 
		DEFINE l_del_cnt SMALLINT 
		DEFINE l_idx SMALLINT 
		DEFINE l_i SMALLINT 
		DEFINE l_j SMALLINT 
		DEFINE l_ans CHAR(1) 

		#LET glob_scrn_size = 14

		--	IF l_idx = 0 THEN
		--		ERROR kandoomsg2("G",9036,"")	#9036 No Journal Disbursements Selected
		--		LET l_idx = 1
		--	END IF


		CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 

		LET l_del_cnt = 0 
		--	OPTIONS DELETE KEY F36
		MESSAGE kandoomsg2("G",1021,l_idx)		#1021 Disbursement - F1 TO Add - F2 TO Delete - RETURN TO Edit"
		#INPUT ARRAY l_arr_rec_disbhead WITHOUT DEFAULTS FROM sr_disbhead.* attributes(UNBUFFERED, DELETE ROW = false, auto append = false, insert row = false, append row = false) 
		DISPLAY ARRAY l_arr_rec_disbhead TO sr_disbhead.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","G31","input-arr-disbhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER" 
				CALL db_disbhead_get_datasource(true) RETURNING l_arr_rec_disbhead 

			ON ACTION "REFRESH" 
				CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
--			BEFORE FIELD scroll_flag 
				#IF l_arr_rec_disbhead[l_idx].disb_code IS NOT NULL THEN
				#   DISPLAY l_arr_rec_disbhead[l_idx].*
				#        TO sr_disbhead[scrn].*
				#
				#END IF
--				LET l_scroll_flag = l_arr_rec_disbhead[l_idx].scroll_flag 

				--      AFTER FIELD scroll_flag
				--         IF fgl_lastkey() = fgl_keyval("down") THEN
				--            IF arr_curr() = arr_count() THEN
				--               ERROR kandoomsg2("G",9001,"")      #9001 There are no more rows in the direction ...
				--               NEXT FIELD scroll_flag
				--            ELSE
				--               IF l_arr_rec_disbhead[l_idx+1].disb_code IS NULL THEN
				--                  ERROR kandoomsg2("G",9001,"")      #9001 There are no more rows in the direction ...
				--                  NEXT FIELD scroll_flag
				--               END IF
				--            END IF
				--         END IF

			#EDIT --------------------------------------------------------------------------------------------------
			ON ACTION ("ACCEPT","EDIT") 


				OPEN WINDOW G458 with FORM "G458" 
				CALL windecoration_g("G458") 

				IF edit_disb(l_arr_rec_disbhead[l_idx].disb_code) THEN 
					CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 

					MESSAGE "Please choose your OPTIONS" 

					MENU " Disbursements" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","G31","menu-disbursements") 

							IF glob_rec_disbhead.type_ind = DISBURSE_TYPE_TRANS_AMOUNT_3 THEN 
								HIDE option "History" 
							END IF 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON ACTION "Save" 						#COMMAND "Save" "Save changes TO disbursement"
							CALL update_disb() 
							SELECT 
								desc_text, 
								group_code, 
								acct_code, 
								type_ind 
							INTO 
								l_arr_rec_disbhead[l_idx].desc_text, 
								l_arr_rec_disbhead[l_idx].group_code, 
								l_arr_rec_disbhead[l_idx].acct_code, 
								l_arr_rec_disbhead[l_idx].type_ind 
							FROM disbhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND disb_code = l_arr_rec_disbhead[l_idx].disb_code 
							EXIT MENU 

						ON ACTION "History"							#COMMAND "History" "View last journal run information"
							CALL view_history(l_arr_rec_disbhead[l_idx].disb_code) 

						ON ACTION "Exit" 						#COMMAND KEY(interrupt,"E")"Exit" "Exit AND discard changes"
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

					END MENU 

				END IF 

				CLOSE WINDOW G458
				CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 
				--NEXT FIELD scroll_flag 

{
			BEFORE FIELD disb_code 

				OPEN WINDOW G458 with FORM "G458" 
				CALL windecoration_g("G458") 

				IF edit_disb(l_arr_rec_disbhead[l_idx].disb_code) THEN 


					MENU " Disbursements" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","G31","menu-disbursements") 

							IF glob_rec_disbhead.type_ind = DISBURSE_TYPE_TRANS_AMOUNT_3 THEN 
								HIDE option "History" 
							END IF 


						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						COMMAND "Save" "Save changes TO disbursement" 
							CALL update_disb() 
							SELECT 
								desc_text, 
								group_code, 
								acct_code, 
								type_ind 
							INTO 
								l_arr_rec_disbhead[l_idx].desc_text, 
								l_arr_rec_disbhead[l_idx].group_code, 
								l_arr_rec_disbhead[l_idx].acct_code, 
								l_arr_rec_disbhead[l_idx].type_ind 
							FROM disbhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND disb_code = l_arr_rec_disbhead[l_idx].disb_code 
							EXIT MENU 

						COMMAND "History" "View last journal run information" 
							CALL view_history(l_arr_rec_disbhead[l_idx].disb_code) 

						COMMAND KEY(interrupt,"E")"Exit" "Exit AND discard changes" 
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

							--               COMMAND KEY (control-w)  --help
							--                  CALL kandoohelp("")

					END MENU 


				END IF 

				CLOSE WINDOW G458 
				NEXT FIELD scroll_flag 
}
			# ADD / NEW -----------------------------------------------------
			ON ACTION "ADD" #add new disbursement set --BEFORE INSERT 

				OPEN WINDOW G458 with FORM "G458" 
				CALL windecoration_g("G458") 

				IF edit_disb("") THEN 
					CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead

					MENU "Disbursements" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","G31","menu-disbursements2") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						COMMAND "SAVE" "Save changes TO Disbursement" 
							CALL update_disb() 
							LET l_arr_rec_disbhead[l_idx].disb_code = glob_rec_disbhead.disb_code 
							EXIT MENU 

						COMMAND KEY(interrupt,"E")"Exit" "Modify disbursement details" 
							LET l_arr_rec_disbhead[l_idx].disb_code = NULL 
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

					END MENU 


				END IF 

				CLOSE WINDOW G458 

				SELECT 
					desc_text, 
					group_code, 
					acct_code, 
					type_ind 
				INTO 
					l_arr_rec_disbhead[l_idx].desc_text, 
					l_arr_rec_disbhead[l_idx].group_code, 
					l_arr_rec_disbhead[l_idx].acct_code, 
					l_arr_rec_disbhead[l_idx].type_ind 
				FROM disbhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND disb_code = l_arr_rec_disbhead[l_idx].disb_code 

				IF status = NOTFOUND THEN 
					FOR l_i = l_idx TO arr_count() 
						LET l_arr_rec_disbhead[l_i].* = l_arr_rec_disbhead[l_i+1].* 
						INITIALIZE l_arr_rec_disbhead[l_i+1].* TO NULL 
						#LET l_j = scrn+l_i-l_idx
						#IF l_j <= glob_scrn_size THEN
						#   DISPLAY l_arr_rec_disbhead[l_i].*
						#        TO sr_disbhead[l_j].*
						#
						#END IF
					END FOR 
				END IF
				CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 
				--NEXT FIELD scroll_flag 

			#DELETE
			ON ACTION "DELETE" --ON KEY (F2) --multi line DELETE 
				IF l_arr_rec_disbhead[l_idx].disb_code IS NOT NULL THEN 
					IF l_arr_rec_disbhead[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_disbhead[l_idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					ELSE 
						LET l_arr_rec_disbhead[l_idx].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
					END IF 
				END IF
				CALL db_disbhead_get_datasource(false) RETURNING l_arr_rec_disbhead 
				--NEXT FIELD scroll_flag 

		END DISPLAY 
		# END DISPLAY ----------------------------------------------------------------------

		IF not(int_flag OR quit_flag) THEN 
			IF l_del_cnt > 0 THEN 
				IF kandoomsg("G",8010,l_del_cnt) = "Y" THEN 
					#8010 Confirmation TO Delete 999 Disbursments
					FOR l_i = 1 TO arr_count() 
						IF l_arr_rec_disbhead[l_i].scroll_flag = "*" THEN 
							DELETE FROM disbhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND disb_code = l_arr_rec_disbhead[l_i].disb_code 
							DELETE FROM disbdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND disb_code = l_arr_rec_disbhead[l_i].disb_code 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 
############################################################
# END FUNCTION scan_disb()
############################################################


############################################################
# FUNCTION edit_disb(p_disb_code)
#
#
############################################################
FUNCTION edit_disb(p_disb_code) 
	DEFINE p_disb_code LIKE disbhead.disb_code 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	--DEFINE  glob_scrn_size SMALLINT,  ## Constant = size of SCREEN ARRAY in G458  #huho: this makes me cry
	DEFINE l_arr_rec_disbdetl DYNAMIC ARRAY OF -- array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			acct_code LIKE disbdetl.acct_code, 
			desc_text LIKE disbdetl.desc_text, 
			analysis_text LIKE disbdetl.analysis_text, 
			disb_qty LIKE disbdetl.disb_qty 
		END RECORD 
		DEFINE l_temp_text CHAR(20) 
		DEFINE l_line_num SMALLINT 
		DEFINE l_i SMALLINT 
		DEFINE l_idx SMALLINT 
		DEFINE l_cash_book CHAR(1) 

		IF glob_rec_glparms.cash_book_flag = "Y" THEN 
			LET l_cash_book = "1" 
		ELSE 
			LET l_cash_book = "2" 
		END IF 

		MESSAGE kandoomsg2("G",1002,"")		#1002 " Searching database - please wait "
		LET l_idx = 0 
		#LET glob_scrn_size = 6 ## SCREEN ARRAY of G458

		#------------------------
		DELETE FROM t_disbdetl 

		IF p_disb_code IS NULL THEN 
			INITIALIZE glob_rec_disbhead.* TO NULL 
			LET glob_rec_disbhead.type_ind = DISBURSE_TYPE_CLOSING_BALANCE_1
			LET glob_rec_disbhead.cmpy_code = glob_rec_company.cmpy_code
			LET glob_rec_disbhead.entry_code = glob_rec_kandoouser.sign_on_code
			LET glob_rec_disbhead.entry_date = TODAY
			--LET glob_rec_disbhead.period_num = ????
			--LET glob_rec_disbhead.year_num = ????
			
		ELSE 
			SELECT * INTO glob_rec_disbhead.* 
			FROM disbhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND disb_code = p_disb_code 
			
			IF glob_rec_disbhead.jour_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO l_rec_journal.desc_text 
				FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_disbhead.jour_code 
				IF status = NOTFOUND THEN 
					LET l_rec_journal.desc_text = "**********" 
				END IF 

				DISPLAY l_rec_journal.desc_text TO journal.desc_text 

			END IF 

			DECLARE c_disbdetl CURSOR FOR 
			SELECT * FROM disbdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND disb_code = glob_rec_disbhead.disb_code 
			ORDER BY 1,2,3 
			
			LET glob_rec_disbhead.disb_qty = 0 

			FOREACH c_disbdetl INTO l_rec_disbdetl.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_disbdetl[l_idx].acct_code = l_rec_disbdetl.acct_code 
				LET l_arr_rec_disbdetl[l_idx].desc_text = l_rec_disbdetl.desc_text 
				LET l_arr_rec_disbdetl[l_idx].analysis_text = l_rec_disbdetl.analysis_text 
				LET l_arr_rec_disbdetl[l_idx].disb_qty = l_rec_disbdetl.disb_qty 
				#IF l_idx <= glob_scrn_size THEN
				#   DISPLAY l_arr_rec_disbdetl[l_idx].*
				#        TO sr_disbdetl[l_idx].*
				#
				#END IF
--				IF l_idx = 200 THEN 
--					EXIT FOREACH 
--				END IF 

				LET glob_rec_disbhead.disb_qty = glob_rec_disbhead.disb_qty	+ l_rec_disbdetl.disb_qty 
			END FOREACH 
			
			LET l_line_num = l_idx 
			DISPLAY BY NAME 
				glob_rec_disbhead.disb_code, 
				glob_rec_disbhead.type_ind, 
				glob_rec_disbhead.jour_code, 
				glob_rec_disbhead.acct_code, 
				glob_rec_disbhead.com1_text, 
				glob_rec_disbhead.total_qty, 
				glob_rec_disbhead.disb_qty, 
				glob_rec_disbhead.uom_code 

		END IF 


		#---------------------------------------------------------------------------------
		WHILE true
			DISPLAY ARRAY l_arr_rec_disbdetl TO sr_disbdetl.* WITHOUT SCROLL 
			MESSAGE kandoomsg2("G",1023,l_idx)		#1023 Enter Disbursement - ESC TO Continue
			INPUT BY NAME 
				glob_rec_disbhead.disb_code, 
				glob_rec_disbhead.desc_text, 
				glob_rec_disbhead.group_code, 
				glob_rec_disbhead.type_ind, 
				glob_rec_disbhead.acct_code, 
				glob_rec_disbhead.dr_cr_ind, #Disburse Credit,Debit or Both
				glob_rec_disbhead.jour_code, 
				glob_rec_disbhead.com1_text, 
				glob_rec_disbhead.uom_code, 
				glob_rec_disbhead.total_qty WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","G31","input-disbhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION "LOOKUP" infield (jour_code) 
					LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_disbhead.jour_code = l_temp_text 
						NEXT FIELD jour_code 
					END IF 

				ON ACTION "LOOKUP" infield (acct_code) 
					LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_disbhead.acct_code = l_temp_text 
						NEXT FIELD acct_code 
					END IF 

				ON ACTION "LOOKUP" infield (uom_code) 
					LET l_temp_text = show_uom(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET glob_rec_disbhead.uom_code = l_temp_text 
						NEXT FIELD uom_code 
					END IF 

				BEFORE FIELD disb_code 
					IF p_disb_code IS NOT NULL THEN 
						NEXT FIELD desc_text 
					END IF 

				AFTER FIELD disb_code 
					IF glob_rec_disbhead.disb_code IS NULL THEN 
						NEXT FIELD disb_code 
					ELSE 
						SELECT unique 1 FROM disbhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND disb_code = glob_rec_disbhead.disb_code 
						IF status = 0 THEN 
							ERROR kandoomsg2("G",9039,"")	#9039" Disbursement code exists."
						END IF 
					END IF #hmmm only a message ?
					
				BEFORE FIELD jour_code 
					IF glob_rec_disbhead.type_ind = DISBURSE_TYPE_TRANS_AMOUNT_3 THEN 
						
						LET glob_rec_disbhead.jour_code = NULL 
						
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD dr_cr_ind ##Disburse Credit,Debit or Both
						ELSE 
							NEXT FIELD com1_text 
						END IF 
					ELSE 
						IF glob_rec_disbhead.jour_code IS NULL THEN 
							LET glob_rec_disbhead.jour_code = glob_rec_glparms.gj_code 
						END IF 
					END IF 
					
				AFTER FIELD jour_code 
					CLEAR journal.desc_text 
					
					SELECT desc_text 
					INTO l_rec_journal.desc_text 
					FROM journal 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND jour_code = glob_rec_disbhead.jour_code 
					AND gl_flag = "Y" 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("G",9029,"")	#9029" Journal code does NOT exist - Try Window "
						NEXT FIELD jour_code 
					ELSE 
						DISPLAY l_rec_journal.desc_text TO journal.desc_text 

					END IF 

				AFTER FIELD acct_code 
					IF glob_rec_disbhead.acct_code IS NULL THEN 
						IF glob_rec_disbhead.type_ind != DISBURSE_TYPE_TRANS_AMOUNT_3 THEN 
							ERROR kandoomsg2("G",9032,"")		#9032 account code must be entered
							NEXT FIELD acct_code 
						END IF 
					ELSE 
						SELECT 1 FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = glob_rec_disbhead.acct_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("G",9112,"")		#9112 account code does NOT exist - Try Window "
							NEXT FIELD acct_code 
						END IF 

						IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_disbhead.acct_code,l_cash_book,"") THEN 
							NEXT FIELD acct_code 
						END IF 
					END IF 

				AFTER FIELD total_qty 
					IF glob_rec_disbhead.total_qty IS NULL THEN 
						ERROR kandoomsg2("G",9025,"") 
						LET glob_rec_disbhead.total_qty = 0 
						NEXT FIELD total_qty 
					ELSE 
						IF not(glob_rec_disbhead.total_qty > 0) THEN 
							ERROR kandoomsg2("G",9025,"")	#9025 Must be Greater than zero
							LET glob_rec_disbhead.total_qty = 0 
							NEXT FIELD total_qty 
						END IF 
					END IF 

				AFTER FIELD uom_code 
					IF glob_rec_disbhead.uom_code IS NOT NULL THEN 
						SELECT uom_code FROM uom 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND uom_code = glob_rec_disbhead.uom_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("G",9037,"")	#9037 " UOM code does NOT exist - Try Window "
							NEXT FIELD uom_code 
						END IF 
					END IF 

				AFTER INPUT 
					IF NOT (int_flag OR quit_flag) THEN 
						IF glob_rec_disbhead.type_ind != DISBURSE_TYPE_TRANS_AMOUNT_3 THEN 
							SELECT unique 1 FROM journal 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND jour_code = glob_rec_disbhead.jour_code 
							AND gl_flag = "Y" 
							IF status = NOTFOUND THEN 
								ERROR kandoomsg2("G",9029,"")				#9029" Journal code does NOT exist - Try Window "
								NEXT FIELD jour_code 
							END IF 

							SELECT 1 FROM coa 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND acct_code = glob_rec_disbhead.acct_code 
							IF status = NOTFOUND THEN 
								ERROR kandoomsg2("G",9112,"")							#9112 account code does NOT exist - Try Window "
								NEXT FIELD acct_code 
							END IF 
						END IF 

						IF glob_rec_disbhead.total_qty IS NULL THEN 
							ERROR kandoomsg2("G",9025,"") 
							LET glob_rec_disbhead.total_qty = 0 
							NEXT FIELD total_qty 
						ELSE 
							IF glob_rec_disbhead.total_qty <= 0 THEN 
								ERROR kandoomsg2("G",9025,"") 							#9025 Must be Greater than zero
								LET glob_rec_disbhead.total_qty = 0 
								NEXT FIELD total_qty 
							END IF 
						END IF 
					END IF 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			ELSE 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
				--CALL set_count(l_line_num) 
				MESSAGE kandoomsg2("G",1022,"")	#1022 Disbursement Lines - F1 Add F2 Delete
				INPUT ARRAY l_arr_rec_disbdetl WITHOUT DEFAULTS FROM sr_disbdetl.* attributes (UNBUFFERED, auto append = false, insert row = false) 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","G31","input-arr-disbdetl") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					BEFORE ROW 
						LET l_idx = arr_curr() 
						#LET scrn = scr_line()
						NEXT FIELD scroll_flag 

					ON ACTION "LOOKUP" infield (acct_code) 
						LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
						IF l_temp_text IS NOT NULL THEN 
							LET l_arr_rec_disbdetl[l_idx].acct_code = l_temp_text 
							NEXT FIELD acct_code 
						END IF 


					BEFORE FIELD acct_code 
						LET l_rec_disbdetl.acct_code = l_arr_rec_disbdetl[l_idx].acct_code 

					AFTER FIELD acct_code 
						IF fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							NEXT FIELD desc_text 
						END IF 

					BEFORE FIELD desc_text 
						IF l_arr_rec_disbdetl[l_idx].acct_code IS NULL THEN 
							NEXT FIELD acct_code 
						ELSE 
							SELECT * INTO l_rec_coa.* 
							FROM coa 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND acct_code = l_arr_rec_disbdetl[l_idx].acct_code 
							IF status = NOTFOUND THEN 
								ERROR kandoomsg2("G",9112,"") 					#9112 account code does NOT exist - Try Window "
								NEXT FIELD acct_code 
							END IF 

							IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_arr_rec_disbdetl[l_idx].acct_code, l_cash_book,"") THEN 
								NEXT FIELD acct_code 
							END IF 

							## Change desc only on change of accoiunt
							IF l_rec_disbdetl.acct_code IS NULL 
							OR l_arr_rec_disbdetl[l_idx].desc_text IS NULL 
							OR l_rec_disbdetl.acct_code != l_arr_rec_disbdetl[l_idx].acct_code THEN 
								LET l_arr_rec_disbdetl[l_idx].desc_text = l_rec_coa.desc_text 
							END IF 
						END IF 

						#DISPLAY l_arr_rec_disbdetl[l_idx].*     TO sr_disbdetl[scrn].*

					AFTER FIELD analysis_text 
						IF l_arr_rec_disbdetl[l_idx].analysis_text IS NULL AND l_rec_coa.analy_req_flag = "Y" THEN 
							ERROR kandoomsg2("G",9051,"") 
							NEXT FIELD analysis_text 
						END IF 

					BEFORE FIELD disb_qty 
						IF l_arr_rec_disbdetl[l_idx].disb_qty IS NULL THEN 
							LET l_arr_rec_disbdetl[l_idx].disb_qty = glob_rec_disbhead.total_qty - glob_rec_disbhead.disb_qty 
						END IF 

					BEFORE INSERT 
						NEXT FIELD acct_code 

					AFTER ROW 
						IF not(int_flag OR quit_flag) THEN 
							IF l_arr_rec_disbdetl[l_idx].acct_code IS NOT NULL THEN 
								IF l_arr_rec_disbdetl[l_idx].disb_qty IS NULL THEN 
									LET l_arr_rec_disbdetl[l_idx].disb_qty = 0 
								END IF 
							END IF 

							LET glob_rec_disbhead.disb_qty = 0 

							FOR l_i = 1 TO l_arr_rec_disbdetl.getSize() --arr_count() 
								IF l_arr_rec_disbdetl[l_i].disb_qty IS NOT NULL THEN 
									LET glob_rec_disbhead.disb_qty = glob_rec_disbhead.disb_qty	+ l_arr_rec_disbdetl[l_i].disb_qty 
								END IF 

							END FOR 

							DISPLAY BY NAME glob_rec_disbhead.disb_qty 

							IF glob_rec_disbhead.disb_qty > glob_rec_disbhead.total_qty THEN 
								ERROR kandoomsg2("G",9038,"")	#9038 Disbursed quantity exceeds disbursement total"
							END IF 

						END IF 

					AFTER INPUT 
						IF not(int_flag OR quit_flag) THEN 
							LET glob_rec_disbhead.disb_qty = 0 

							FOR l_i = 1 TO l_arr_rec_disbdetl.getSize() --arr_count() 
								IF l_arr_rec_disbdetl[l_i].disb_qty IS NOT NULL THEN 
									LET glob_rec_disbhead.disb_qty = glob_rec_disbhead.disb_qty	+ l_arr_rec_disbdetl[l_i].disb_qty 
								END IF 

								IF l_arr_rec_disbdetl[l_i].acct_code IS NOT NULL THEN 
									LET l_rec_disbdetl.line_num = l_i 
									LET l_rec_disbdetl.acct_code = l_arr_rec_disbdetl[l_i].acct_code 
									LET l_rec_disbdetl.desc_text = l_arr_rec_disbdetl[l_i].desc_text 
									LET l_rec_disbdetl.analysis_text = l_arr_rec_disbdetl[l_i].analysis_text 
									LET l_rec_disbdetl.disb_qty = l_arr_rec_disbdetl[l_i].disb_qty 

									#insert into temp table ----------------------------------------------------
									INSERT INTO t_disbdetl VALUES (l_rec_disbdetl.*) 
								END IF 

							END FOR 

							IF glob_rec_disbhead.disb_qty > glob_rec_disbhead.total_qty THEN 
								ERROR kandoomsg2("G",9038,"")	#9038 Disbursed quantity exceeds disbursement total"
								DELETE FROM t_disbdetl 
								NEXT FIELD acct_code 
							END IF 
							#DISPLAY BY NAME glob_rec_disbhead.disb_qty

						END IF 

						--            ON KEY (control-w)  --help
						--               CALL kandoohelp("")

				END INPUT 

			END IF 

			IF int_flag OR quit_flag THEN 
				LET quit_flag = false 
				LET int_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		OPTIONS DELETE KEY f36 
		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
END FUNCTION 
############################################################
# END FUNCTION edit_disb(p_disb_code)
############################################################


############################################################
# FUNCTION update_disb()
#
#
############################################################
FUNCTION update_disb() 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 

	MESSAGE kandoomsg2("G",1005,"") #1005 " Updating database - please wait "
	--GOTO bypass 
	--LABEL recovery: 
	
--	IF error_recover(l_err_message, status) != "Y" THEN 
--		RETURN 
--	END IF 
	
	--LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
		LET l_err_message = " G31 - Journal Disbursement Maintenance" 
		--LET glob_rec_disbhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		#-------------------
		DELETE FROM disbdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND disb_code = glob_rec_disbhead.disb_code 
		
		DECLARE c_t_disbdetl CURSOR FOR 
		SELECT * #SELECT rowid,* 
		FROM t_disbdetl 
		WHERE acct_code IS NOT NULL 
		AND disb_qty IS NOT NULL 
		AND disb_qty != 0 
		ORDER BY 1,2,3,4 
		
		LET l_idx = 0 
		LET glob_rec_disbhead.disb_qty = 0 

		FOREACH c_t_disbdetl INTO l_rec_disbdetl.* #FOREACH c_t_disbdetl INTO l_rowid,	l_rec_disbdetl.* 
			LET l_idx = l_idx + 1 
			LET l_rec_disbdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_disbdetl.line_num = l_idx 
			LET l_rec_disbdetl.disb_code = glob_rec_disbhead.disb_code 
			LET glob_rec_disbhead.disb_qty = glob_rec_disbhead.disb_qty + l_rec_disbdetl.disb_qty 
			
			INSERT INTO disbdetl VALUES (l_rec_disbdetl.*) 
		END FOREACH 

		IF db_disbhead_pk_exists(UI_OFF,MODE_INSERT,glob_rec_disbhead.disb_code) THEN
			UPDATE disbhead 
			SET * = glob_rec_disbhead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND disb_code = glob_rec_disbhead.disb_code 
		ELSE
				INSERT INTO disbhead VALUES (glob_rec_disbhead.*)
		END IF
		
		IF sqlca.sqlcode != 0 THEN #sqlca.sqlerrd[3] = 0 THEN 
			LET glob_rec_disbhead.last_date = NULL 
			LET glob_rec_disbhead.last_jour_num = NULL 
			LET glob_rec_disbhead.period_num = NULL 
			LET glob_rec_disbhead.year_num = NULL 
			LET glob_rec_disbhead.run_num = 0 
			LET glob_rec_disbhead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_disbhead.entry_date = today 
			
			INSERT INTO disbhead VALUES (glob_rec_disbhead.*) 
		END IF 
	
	COMMIT WORK
	#---------------------------------- 
--	WHENEVER ERROR stop 

END FUNCTION 
############################################################
# END FUNCTION update_disb()
############################################################


############################################################
# FUNCTION view_history(p_disb_code)
#
#
############################################################
FUNCTION view_history(p_disb_code) 
	DEFINE p_disb_code LIKE disbhead.disb_code 
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_period_text CHAR(8) 

	SELECT * INTO l_rec_disbhead.* 
	FROM disbhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND disb_code = p_disb_code 
	IF status = 0 THEN 

		OPEN WINDOW g460 with FORM "G460" 
		CALL windecoration_g("G460") 

		SELECT * INTO l_rec_batchhead.* 
		FROM batchhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_num = l_rec_disbhead.last_jour_num 
		IF status = NOTFOUND THEN 
			LET l_rec_batchhead.jour_code = NULL 
			LET l_rec_batchhead.jour_num = NULL 
			LET l_rec_batchhead.credit_amt = NULL 
			LET l_rec_batchhead.debit_amt = NULL 
			LET l_rec_disbhead.last_date = NULL 
		ELSE 
			LET l_period_text = l_rec_disbhead.year_num USING "####","/", 
			l_rec_disbhead.period_num USING "<<<" 
		END IF 

		DISPLAY 
			l_rec_disbhead.disb_code, 
			l_rec_disbhead.desc_text, 
			l_rec_disbhead.last_date, 
			l_rec_disbhead.run_num, 
			l_rec_disbhead.entry_date, 
			l_rec_batchhead.jour_code, 
			l_rec_batchhead.jour_num, 
			l_period_text, 
			l_rec_batchhead.credit_amt, 
			l_rec_batchhead.debit_amt, 
			l_rec_batchhead.post_flag 
		TO 
			disb_code, 
			desc_text, 
			last_date, 
			run_num, 
			entry_date, 
			jour_code, 
			jour_num, 
			period_text, 
			batchhead.credit_amt, 
			debit_amt, 
			post_flag 

		DISPLAY l_rec_batchhead.entry_code TO batchhead.entry_code
		DISPLAY l_rec_disbhead.entry_code TO disbhead.entry_code 

		CALL eventsuspend() # MESSAGE kandoomsg2("U",1,"") 
		CLOSE WINDOW G460 
	END IF 

END FUNCTION
############################################################
# END FUNCTION view_history(p_disb_code)
############################################################