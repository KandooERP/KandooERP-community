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

# Allow entry & edit of Recurring Vouchers

#Thsi file IS used as GLOBALS file FROM P71f.err
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl"
GLOBALS "../ap/P71_GLOBALS.4gl"

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_glparms RECORD LIKE glparms.*

############################################################
# MAIN
#
#
############################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("P71") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT * INTO modu_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL create_table("recurdetl","t_recurdetl","","N") 

	OPEN WINDOW p190 with FORM "P190" 
	CALL windecoration_p("P190") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_vouch() 
		CALL scan_vouch() 
	END WHILE 
	
	# DROP TABLE
	DROP TABLE t_recurdetl 

	CLOSE WINDOW P190 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION select_vouch()
#
#
############################################################
FUNCTION select_vouch() 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text STRING 

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON 
		recur_code, 
		desc_text, 
		vend_code, 
		last_vouch_date, 
		next_vouch_date, 
		hold_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P71","construct-recurhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE kandoomsg2("P",1002,"")	#1002 Searching Database;  Please wait.
		LET l_query_text = 
			"SELECT * FROM recurhead ", 
			"WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 1,2" 
		
		PREPARE s_recurhead FROM l_query_text 
		DECLARE c_recurhead CURSOR FOR s_recurhead 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_vouch()
############################################################


############################################################
# FUNCTION scan_vouch()
#
#
############################################################
FUNCTION scan_vouch() 
	DEFINE l_rec_rechead RECORD LIKE recurhead.* 
	DEFINE l_arr_rec_recurhead DYNAMIC ARRAY OF #ARRAY[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			recur_code LIKE recurhead.recur_code, 
			desc_text LIKE recurhead.desc_text, 
			vend_code LIKE recurhead.vend_code, 
			last_vouch_date LIKE recurhead.last_vouch_date, 
			next_vouch_date LIKE recurhead.next_vouch_date, 
			hold_code LIKE recurhead.hold_code 
		END RECORD 
	DEFINE l_dist_amt LIKE recurhead.dist_amt 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_rowid INTEGER 
	DEFINE l_del_cnt SMALLINT 
	DEFINE idx SMALLINT

		LET idx = 0 
		LET l_del_cnt = 0 
		FOREACH c_recurhead INTO glob_rec_recurhead.* 
			LET idx = idx + 1 
			CALL set_arr(glob_rec_recurhead.*) RETURNING l_arr_rec_recurhead[idx].* 
			IF idx = 100 THEN 
				ERROR kandoomsg2("P",1030,100)			#1030  First 100 Recurring Vouchers selected.
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF idx = 0 THEN 
			ERROR kandoomsg2("P",9051,"")		#9051  No recurring vouchers satisfied selection criteria.
			LET idx = 1 
			INITIALIZE l_arr_rec_recurhead[idx].* TO NULL 
		END IF 
		MESSAGE kandoomsg2("P",1035,"") 	#1035 Recurring Vouchers;  F1 TO Add;  F2 TO Delete;  ENTER TO Edit.
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		CALL set_count(idx) 

		DISPLAY ARRAY l_arr_rec_recurhead TO sr_recurhead.* 
		#INPUT ARRAY l_arr_rec_recurhead WITHOUT DEFAULTS FROM sr_recurhead.*

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","P6A","inp-arr-recurhead-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				#      BEFORE FIELD scroll_flag
				LET idx = arr_curr() 
				#         LET scrn = scr_line()
				LET l_scroll_flag = l_arr_rec_recurhead[idx].scroll_flag 
				#         DISPLAY l_arr_rec_recurhead[idx].*
				#              TO sr_recurhead[scrn].*

			AFTER ROW 
				#      AFTER FIELD scroll_flag
				LET l_arr_rec_recurhead[idx].scroll_flag = l_scroll_flag 
				#        IF fgl_lastkey() = fgl_keyval("down") THEN
				#           IF arr_curr() = arr_count() THEN
				#              ERROR kandoomsg2("P",9001,"")			#              #9001 There are no more rows in the direction ...
				#              NEXT FIELD scroll_flag
				#           ELSE
				#              IF l_arr_rec_recurhead[idx+1].recur_code IS NULL THEN
				#                 ERROR kandoomsg2("P",9001,"")			#                 #9001 There are no more rows in the direction ...
				#                 NEXT FIELD scroll_flag
				#              END IF
				#           END IF
				#        END IF

			ON ACTION ("EDIT","ACCEPT") 
				#BEFORE FIELD recur_code
				IF l_arr_rec_recurhead[idx].recur_code IS NOT NULL THEN 

					OPEN WINDOW p191 with FORM "P191" 
					CALL windecoration_p("P191") 

					CALL init_recurhead(l_arr_rec_recurhead[idx].recur_code) 
					WHILE edit_recurvch() 

						MENU " Recurring Voucher" 
							BEFORE MENU 
								IF glob_rec_recurhead.run_num = 0 THEN 
									HIDE option "History" 
								ELSE 
									IF glob_rec_recurhead.max_run_num <= glob_rec_recurhead.run_num THEN 
										HIDE option "Schedule" 
									END IF 
								END IF 


								CALL publish_toolbar("kandoo","P71","menu-rec_voucher-1") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 


								
							ON ACTION "Save" #COMMAND "Save" " Save recurring voucher TO database"
								SELECT sum(dist_amt) INTO l_dist_amt 
								FROM t_recurdetl 
								IF l_dist_amt IS NULL THEN 
									LET l_dist_amt = 0 
								END IF 
								IF l_dist_amt > glob_rec_recurhead.total_amt THEN 
									ERROR kandoomsg2("P",1047,"") 									#1047 Dist amount must NOT exceed the voucher amount
								ELSE 
									LET l_rowid = update_db() 
									EXIT MENU 
								END IF 

								
							ON ACTION "Distribute" #COMMAND "Distribute" " Enter account distribution lines"
								CALL distribute(glob_rec_recurhead.*) 

								
							ON ACTION "History" #COMMAND "History" " View payments made TO date"
								CALL P71_history(glob_rec_kandoouser.cmpy_code,glob_rec_recurhead.*) 

								
							ON ACTION "Schedule" #COMMAND "Schedule" " View voucher generation schedule"
								CALL schedule(glob_rec_kandoouser.cmpy_code,glob_rec_recurhead.*) 

								
							ON ACTION "Schedule" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
								LET quit_flag = true 
								EXIT MENU 


						END MENU 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
						ELSE 
							EXIT WHILE 
						END IF 

					END WHILE 

					CLOSE WINDOW P191 

					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 

					SELECT * INTO l_rec_rechead.* 
					FROM recurhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND recur_code = l_arr_rec_recurhead[idx].recur_code 
					CALL set_arr(l_rec_rechead.*) RETURNING l_arr_rec_recurhead[idx].* 
				END IF 
				#NEXT FIELD scroll_flag

			ON ACTION "Add" 
				#      BEFORE INSERT
				#         IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN
				#            CLEAR sr_recurhead[scrn].*
				#            NEXT FIELD scroll_flag #informix bug
				#         END IF
				LET l_rowid = 0 

				OPEN WINDOW p191 with FORM "P191" 
				CALL windecoration_p("P191") 

				CALL init_recurhead("") 
				WHILE edit_recurvch() 



					MENU " Recurring Voucher" 
						BEFORE MENU 
							IF glob_rec_recurhead.max_run_num <= glob_rec_recurhead.run_num THEN 
								HIDE option "Schedule" 
							END IF 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","P71","menu-rec_voucher-1") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

							
						ON ACTION "Save" #COMMAND "Save" " Commit recurring voucher TO database"
							SELECT sum(dist_amt) INTO l_dist_amt 
							FROM t_recurdetl 
							IF l_dist_amt IS NULL THEN 
								LET l_dist_amt = 0 
							END IF 
							IF l_dist_amt > glob_rec_recurhead.total_amt THEN 
								ERROR kandoomsg2("P",1047,"") 								#1047 Dist amount must NOT exceed the voucher amount
							ELSE 
								LET l_rowid = update_db() 
								EXIT MENU 
							END IF 

							
						ON ACTION "Distribute" #COMMAND "Distribute" " Enter account distribution lines"
							CALL distribute(glob_rec_recurhead.*) 

							
						ON ACTION "Schedule" #COMMAND "Schedule" " View voucher generation schedule"
							CALL schedule(glob_rec_kandoouser.cmpy_code,glob_rec_recurhead.*) 

							
						ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
							LET quit_flag = true 

							EXIT MENU 


					END MENU 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
					ELSE 
						EXIT WHILE 
					END IF 
				END WHILE 

				CLOSE WINDOW p191 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF l_rowid THEN 
					SELECT * INTO l_rec_rechead.* 
					FROM recurhead 
					WHERE rowid = l_rowid 
					CALL set_arr(l_rec_rechead.*) RETURNING l_arr_rec_recurhead[idx].* 
				ELSE 
					FOR idx = arr_curr() TO arr_count() 
						LET l_arr_rec_recurhead[idx].* = l_arr_rec_recurhead[idx+1].* 
						#               IF scrn <= 15 THEN
						#                  IF l_arr_rec_recurhead[idx].recur_code IS NULL THEN
						#                     LET l_arr_rec_recurhead[idx].last_vouch_date = ""
						#                     LET l_arr_rec_recurhead[idx].next_vouch_date = ""
						#                  END IF
						#                  DISPLAY l_arr_rec_recurhead[idx].*
						#                       TO sr_recurhead[scrn].*
						#
						#                  LET scrn = scrn + 1
						#               END IF
					END FOR 
					INITIALIZE l_arr_rec_recurhead[idx].* TO NULL 
				END IF 
				#NEXT FIELD scroll_flag

			ON KEY (F2) --delete 
				IF l_arr_rec_recurhead[idx].recur_code IS NOT NULL THEN 

					LET l_del_cnt = 1 
					IF kandoomsg("P",1032,l_del_cnt) = "Y" THEN 
						#1032 Confirm TO Delete l_del_cnt Recurring Voucher(s)? (Y/N)
						DELETE FROM recurhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND recur_code = l_arr_rec_recurhead[idx].recur_code 
					END IF 
				END IF 


				#   IF l_arr_rec_recurhead[idx].scroll_flag IS NULL THEN
				#      LET l_arr_rec_recurhead[idx].scroll_flag = "*"
				#      LET l_del_cnt = l_del_cnt + 1
				#   ELSE
				#      LET l_arr_rec_recurhead[idx].scroll_flag = NULL
				#      LET l_del_cnt = l_del_cnt - 1
				#   END IF
				#END IF
				#NEXT FIELD scroll_flag

				#      AFTER ROW
				#         DISPLAY l_arr_rec_recurhead[idx].*
				#              TO sr_recurhead[scrn].*


		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			#      IF l_del_cnt > 0 THEN
			#         IF kandoomsg("P",1032,l_del_cnt) = "Y" THEN
			#            #1032 Confirm TO Delete l_del_cnt Recurring Voucher(s)? (Y/N)
			#            FOR idx = 1 TO arr_count()
			#               IF l_arr_rec_recurhead[idx].scroll_flag = "*" THEN
			#                  DELETE FROM recurhead
			#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                     AND recur_code = l_arr_rec_recurhead[idx].recur_code
			#               END IF
			#            END FOR
			#         END IF
			#      END IF
		END IF 
END FUNCTION 
############################################################
# END FUNCTION scan_vouch()
############################################################


############################################################
# FUNCTION edit_recurvch()
#
#
############################################################
FUNCTION edit_recurvch() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_ref_num LIKE vendorinvs.inv_text 
	DEFINE l_recur_code LIKE recurhead.recur_code 
	DEFINE l_vend_code LIKE recurhead.vend_code 
	DEFINE l_temp_text CHAR(30) 
	DEFINE x SMALLINT

	IF glob_rec_recurhead.recur_code IS NULL THEN 
		LET glob_rec_recurhead.int_num = 1 
		LET glob_rec_recurhead.next_vouch_date = today 
		LET glob_rec_recurhead.start_date = today 
		LET glob_rec_recurhead.rev_num = 0 
		LET glob_rec_recurhead.rev_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_recurhead.rev_date = today 
	ELSE 
		SELECT * INTO l_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_recurhead.vend_code 

		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = glob_rec_recurhead.term_code 

		SELECT * INTO l_rec_holdpay.* 
		FROM holdpay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = glob_rec_recurhead.hold_code 

		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = glob_rec_recurhead.tax_code 
		
		LET l_temp_text=kandooword("recurhead.int_ind",glob_rec_recurhead.int_ind) 

		DISPLAY BY NAME 
			l_rec_vendor.name_text, 
			glob_rec_recurhead.end_date, 
			l_rec_holdpay.hold_text 

		DISPLAY BY NAME glob_rec_recurhead.curr_code 
		attribute(green) 
		
		DISPLAY 
			l_temp_text , 
			l_rec_term.desc_text, 
			l_rec_tax.desc_text 
		TO 
			kandooword.response_text, 
			term.desc_text, 
			tax.desc_text 

	END IF 
	
	DISPLAY BY NAME 
		glob_rec_recurhead.start_date, 
		glob_rec_recurhead.rev_num, 
		glob_rec_recurhead.rev_code, 
		glob_rec_recurhead.rev_date 

	MESSAGE kandoomsg2("P",1031,"")	#1031 Enter recurring voucher details;  OK TO Continue.
	INPUT BY NAME 
		glob_rec_recurhead.recur_code, 
		glob_rec_recurhead.desc_text, 
		glob_rec_recurhead.vend_code, 
		glob_rec_recurhead.group_text, 
		glob_rec_recurhead.int_ind, 
		glob_rec_recurhead.int_num, 
		glob_rec_recurhead.max_run_num, 
		glob_rec_recurhead.next_vouch_date, 
		glob_rec_recurhead.total_amt, 
		glob_rec_recurhead.conv_qty, 
		glob_rec_recurhead.inv_text, 
		glob_rec_recurhead.term_code, 
		glob_rec_recurhead.hold_code, 
		glob_rec_recurhead.tax_code, 
		glob_rec_recurhead.com1_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P71","inp-recurhead-1") 
			LET l_recur_code = glob_rec_recurhead.recur_code 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield(vend_code) 
			LET l_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,glob_rec_recurhead.vend_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_recurhead.vend_code = l_temp_text 
				NEXT FIELD vend_code 
			END IF 

		ON KEY (control-b) infield(int_ind) 
			LET l_temp_text = show_inttype() 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_recurhead.int_ind = l_temp_text 
				NEXT FIELD int_ind 
			END IF 

		ON KEY (control-b) infield(term_code) 
			LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_recurhead.term_code = l_temp_text 
				NEXT FIELD term_code 
			END IF 

		ON KEY (control-b) infield(hold_code) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_recurhead.hold_code = l_temp_text 
				NEXT FIELD hold_code 
			END IF 

		ON KEY (control-b) infield(tax_code) 
			LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_recurhead.tax_code = l_temp_text 
				NEXT FIELD tax_code 
			END IF 

		BEFORE FIELD recur_code 
			SELECT unique 1 
			FROM recurhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND recur_code = l_recur_code 
			IF sqlca.sqlcode = 0 THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD recur_code 
			IF glob_rec_recurhead.recur_code IS NULL THEN 
				ERROR kandoomsg2("P",1020,"") 			#1020 Recurring Voucher Code must be entered.
				NEXT FIELD recur_code 
			ELSE 
				SELECT unique 1 FROM recurhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND recur_code = glob_rec_recurhead.recur_code 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("P",1021,"") 				#1021 Recurring Voucher Code already exists
					NEXT FIELD recur_code 
				ELSE 
					IF l_recur_code IS NULL THEN 
						LET glob_rec_recurhead.inv_text = glob_rec_recurhead.recur_code 
						DISPLAY BY NAME glob_rec_recurhead.inv_text 

					END IF 
				END IF 
			END IF 

		BEFORE FIELD vend_code 
			LET l_vend_code = glob_rec_recurhead.vend_code 
			IF glob_rec_recurhead.run_num > 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD desc_text 
				ELSE 
					NEXT FIELD group_text 
				END IF 
			END IF 

		AFTER FIELD vend_code 
			IF glob_rec_recurhead.vend_code IS NULL THEN 
				ERROR kandoomsg2("P",1022,"")			#1022 Vendor Code must be entered
				NEXT FIELD vend_code 
			END IF 
			SELECT unique 1 FROM bank 
			WHERE bank_code = glob_rec_recurhead.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status <> NOTFOUND THEN 
				ERROR kandoomsg2("P",9090,"")			#9090 Recurring vouchers NOT allowed FOR Sundry Vendor/s
				NEXT FIELD vend_code 
			END IF 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_recurhead.vend_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR kandoomsg2("P",9105,"")	#9105 Vendor NOT found - try window
				NEXT FIELD vend_code 
			ELSE 
				DISPLAY BY NAME l_rec_vendor.name_text 

				IF glob_rec_recurhead.vend_code != l_vend_code OR l_vend_code IS NULL THEN 
					
					DELETE FROM t_recurdetl 
					
					LET glob_rec_recurhead.term_code = l_rec_vendor.term_code 
					LET glob_rec_recurhead.hold_code = l_rec_vendor.hold_code 
					LET glob_rec_recurhead.tax_code = l_rec_vendor.tax_code 
					LET glob_rec_recurhead.curr_code = l_rec_vendor.currency_code 
					LET glob_rec_recurhead.conv_qty = get_conv_rate( 
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_recurhead.curr_code, 
						today, 
						"B") 
					
					DISPLAY BY NAME 
						glob_rec_recurhead.term_code, 
						glob_rec_recurhead.hold_code, 
						glob_rec_recurhead.tax_code, 
						glob_rec_recurhead.conv_qty 

					DISPLAY BY NAME glob_rec_recurhead.curr_code	attribute(green) 

					SELECT * INTO l_rec_term.* 
					FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = glob_rec_recurhead.term_code 

					SELECT * INTO l_rec_holdpay.* 
					FROM holdpay 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = glob_rec_recurhead.hold_code 

					SELECT * INTO l_rec_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = glob_rec_recurhead.tax_code 
					DISPLAY BY NAME l_rec_holdpay.hold_text 

					DISPLAY 
						l_rec_term.desc_text, 
						l_rec_tax.desc_text 
					TO 
						term.desc_text, 
						tax.desc_text 

				END IF 
			END IF 

		AFTER FIELD int_ind 
			IF glob_rec_recurhead.int_ind IS NULL THEN 
				ERROR kandoomsg2("P",1023,"")	#1023 Interval Indicator must be entered
				NEXT FIELD int_ind 
			END IF 
			
			LET l_temp_text=kandooword("recurhead.int_ind",glob_rec_recurhead.int_ind) 
			
			DISPLAY l_temp_text TO kandooword.response_text 

			IF glob_rec_recurhead.int_ind = "6" THEN 
				LET glob_rec_recurhead.term_code = enter_term(glob_rec_recurhead.term_code) 
				
				IF glob_rec_recurhead.term_code IS NULL THEN 
					ERROR kandoomsg2("P",1024,"")					#1024 Terms must be entered
					NEXT FIELD int_ind 
				ELSE 
					SELECT * INTO l_rec_term.* 
					FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = glob_rec_recurhead.term_code 
					DISPLAY BY NAME l_rec_term.term_code 

					DISPLAY l_rec_term.desc_text TO term.desc_text 

				END IF 
			END IF 
			LET glob_rec_recurhead.end_date = generate_int( glob_rec_recurhead.*, 
			(glob_rec_recurhead.max_run_num-glob_rec_recurhead.run_num)) 
			DISPLAY BY NAME glob_rec_recurhead.end_date 

		AFTER FIELD int_num 
			IF glob_rec_recurhead.int_num IS NULL THEN 
				ERROR kandoomsg2("P",1027,"")			#1027 Voucher Interval must be entered
				NEXT FIELD int_num 
			ELSE 
				IF glob_rec_recurhead.int_num <= 0 THEN 
					ERROR kandoomsg2("P",1029,"")				#1029 Voucher Interval must be greater than zero
					NEXT FIELD int_num 
				ELSE 
					LET glob_rec_recurhead.end_date = generate_int( glob_rec_recurhead.*, 
					(glob_rec_recurhead.max_run_num-glob_rec_recurhead.run_num)) 
					DISPLAY BY NAME glob_rec_recurhead.end_date 

				END IF 
			END IF 

		AFTER FIELD max_run_num 
			CASE 
				WHEN glob_rec_recurhead.max_run_num IS NULL 
					LET glob_rec_recurhead.max_run_num = 999 
					DISPLAY BY NAME glob_rec_recurhead.max_run_num 

				WHEN glob_rec_recurhead.max_run_num <= 0 
					ERROR kandoomsg2("P",1028,"")		#1028 No. of vouchers must be greater than zero
					NEXT FIELD max_run_num 
				
				WHEN glob_rec_recurhead.max_run_num <= glob_rec_recurhead.run_num 
					ERROR kandoomsg2("P",1045,glob_rec_recurhead.run_num)		#1045 ??? vouchers have already been raised
					LET glob_rec_recurhead.next_vouch_date = glob_rec_recurhead.last_vouch_date 
					DISPLAY BY NAME glob_rec_recurhead.next_vouch_date 

				WHEN glob_rec_recurhead.next_vouch_date <= glob_rec_recurhead.last_vouch_date 
					LET glob_rec_recurhead.next_vouch_date=generate_int(glob_rec_recurhead.*,2) 
					DISPLAY BY NAME glob_rec_recurhead.next_vouch_date 

			END CASE 
			
			LET glob_rec_recurhead.end_date = generate_int( 
				glob_rec_recurhead.*, 
				(glob_rec_recurhead.max_run_num-glob_rec_recurhead.run_num)) 
			
			DISPLAY BY NAME glob_rec_recurhead.end_date 

		AFTER FIELD next_vouch_date 
			IF glob_rec_recurhead.next_vouch_date IS NULL THEN 
				ERROR kandoomsg2("P",1025,"")	#1025 Next Voucher Date must be entered
				LET glob_rec_recurhead.next_vouch_date = today 
				NEXT FIELD next_vouch_date 
			END IF 
			
			IF glob_rec_recurhead.next_vouch_date > (today + 30) THEN 
				LET l_temp_text = glob_rec_recurhead.next_vouch_date USING "dd/mm/yyyy" 
				ERROR kandoomsg2("U",9523,l_temp_text) 
			END IF 
			IF glob_rec_recurhead.run_num = 0 THEN 
				LET glob_rec_recurhead.start_date = glob_rec_recurhead.next_vouch_date 
			ELSE 
				IF glob_rec_recurhead.max_run_num <= glob_rec_recurhead.run_num THEN 
					LET glob_rec_recurhead.next_vouch_date = glob_rec_recurhead.last_vouch_date 
					DISPLAY BY NAME glob_rec_recurhead.next_vouch_date 

				ELSE 
					IF glob_rec_recurhead.next_vouch_date <= glob_rec_recurhead.last_vouch_date THEN 
						ERROR kandoomsg2("P",1046,"") #1046 Voucher already raised on OR prior TO this date
						LET glob_rec_recurhead.end_date = NULL 
						
						DISPLAY BY NAME glob_rec_recurhead.end_date 

						NEXT FIELD next_vouch_date 
					END IF 
				END IF 
			END IF 

			LET glob_rec_recurhead.end_date = generate_int( 
				glob_rec_recurhead.*, 
				(glob_rec_recurhead.max_run_num-glob_rec_recurhead.run_num)) 
			
			DISPLAY BY NAME 
				glob_rec_recurhead.start_date, 
				glob_rec_recurhead.end_date 

		AFTER FIELD total_amt 
			CASE 
				WHEN glob_rec_recurhead.total_amt IS NULL 
					ERROR kandoomsg2("P",1026,"")				#1026 Transaction amount must be entered
					NEXT FIELD total_amt 
				WHEN glob_rec_recurhead.total_amt < 0 
					ERROR kandoomsg2("P",9019,"") 			#9019 Transaction amount must NOT be negative
					NEXT FIELD total_amt 
				WHEN glob_rec_recurhead.total_amt = 0 
					ERROR kandoomsg2("P",7015,"") 		#7015 Voucher total amount IS zero
			END CASE 

		BEFORE FIELD conv_qty 
			IF modu_rec_glparms.base_currency_code = l_rec_vendor.currency_code THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD total_amt 
				ELSE 
					NEXT FIELD inv_text 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF glob_rec_recurhead.conv_qty IS NOT NULL THEN 
				IF glob_rec_recurhead.conv_qty <= 0 THEN 
					ERROR kandoomsg2("P",9012,"") 			#9012 Exchange rate must be greater than zero
					NEXT FIELD conv_qty 
				END IF 
			END IF 

		AFTER FIELD inv_text 
			IF glob_rec_recurhead.inv_text IS NOT NULL THEN 

				LET l_temp_text = glob_rec_recurhead.inv_text clipped, ".", #p4gl: p71.4gl, line 705: parse ERROR 
					(glob_rec_recurhead.run_num + 1) USING "&&&" 

				SELECT unique 1 
				FROM vendorinvs 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_recurhead.vend_code 
				AND inv_text = l_temp_text 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("P",9023,"") 
					#9023 Vendor Invoice Number already exists
					NEXT FIELD inv_text 
				END IF 
			END IF 

		BEFORE FIELD term_code 
			IF glob_rec_recurhead.int_ind = "6" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD inv_text 
				ELSE 
					NEXT FIELD hold_code 
				END IF 
			END IF 

		AFTER FIELD term_code 
			CLEAR term.desc_text 
			IF glob_rec_recurhead.term_code IS NOT NULL THEN 
				SELECT * INTO l_rec_term.* 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_recurhead.term_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("P",9025,"")				#9025 Term Code NOT found - try window
					NEXT FIELD term_code 
				ELSE 
					DISPLAY l_rec_term.desc_text 
					TO term.desc_text 

				END IF 
			END IF 

		AFTER FIELD hold_code 
			CLEAR hold_text 
			IF glob_rec_recurhead.hold_code IS NOT NULL THEN 
				SELECT * INTO l_rec_holdpay.* 
				FROM holdpay 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_recurhead.hold_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("P",9026,"")		#9026 Hold Payment code NOT found - try window
					NEXT FIELD hold_code 
				ELSE 
					DISPLAY BY NAME l_rec_holdpay.hold_text 

				END IF 
			END IF 

		AFTER FIELD tax_code 
			CLEAR tax.desc_text 
			IF glob_rec_recurhead.tax_code IS NOT NULL THEN 
				SELECT * INTO l_rec_tax.* 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_recurhead.tax_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("P",9106,"")		#9106 Tax Code NOT found - try window
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text 
					TO tax.desc_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_recurhead.vend_code IS NULL THEN 
					ERROR kandoomsg2("P",1022,"") 		#1022 Vendor code must be entered
					NEXT FIELD vend_code 
				END IF 
				
				IF glob_rec_recurhead.int_ind IS NULL THEN 
					ERROR kandoomsg2("P",1023,"") 	#1024 Interval Indicator must be entered
					NEXT FIELD int_ind 
				END IF 
				
				IF glob_rec_recurhead.max_run_num IS NULL THEN 
					LET glob_rec_recurhead.max_run_num = 999 
				END IF 
				
				IF glob_rec_recurhead.total_amt IS NULL THEN 
					ERROR kandoomsg2("P",1026,"") 	#1026 Transaction amount must be entered
					NEXT FIELD total_amt 
				END IF 
				
				SELECT unique 1 FROM bank 
				WHERE bank_code = glob_rec_recurhead.vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status <> NOTFOUND THEN 
					ERROR kandoomsg2("P",9090,"") 		#9090 Recurring vouchers NOT allowed FOR Sundry Vendor/s
					NEXT FIELD vend_code 
				END IF 
				
				SELECT * INTO l_rec_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_recurhead.vend_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("P",9014,"")		#P9014 Logic Error - Vendor Does NOT exist
					NEXT FIELD vend_code 
				ELSE 
				
					IF glob_rec_recurhead.term_code IS NULL THEN 
						LET glob_rec_recurhead.term_code = l_rec_vendor.term_code 
					END IF 
				
					IF glob_rec_recurhead.hold_code IS NULL THEN 
						LET glob_rec_recurhead.hold_code = l_rec_vendor.hold_code 
					END IF 
				
					IF glob_rec_recurhead.tax_code IS NULL THEN 
						LET glob_rec_recurhead.tax_code = l_rec_vendor.tax_code 
					END IF 
				END IF 
			END IF 


	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION edit_recurvch()
############################################################


############################################################
# FUNCTION enter_term(p_term_code)
#
#
############################################################
FUNCTION enter_term(p_term_code) 
	DEFINE p_term_code LIKE term.term_code 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_temp_text CHAR(30) 

	LET l_rec_term.term_code = p_term_code 

	OPEN WINDOW P195 with FORM "P195" 
	CALL windecoration_p("P195") 

	MESSAGE kandoomsg2("P",1033,"")#1033 Enter Terms
	INPUT BY NAME l_rec_term.term_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P71","inp-term_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) infield(term_code) 
			LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_term.term_code = l_temp_text 
				NEXT FIELD term_code 
			END IF 

		BEFORE FIELD term_code 
			CLEAR desc_text 

			SELECT desc_text INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_term.term_code 

			IF sqlca.sqlcode = 0 THEN 
				DISPLAY BY NAME l_rec_term.desc_text 
			END IF 

		AFTER FIELD term_code 
			IF l_rec_term.term_code IS NULL THEN 
				ERROR kandoomsg2("P",1024,"")		#1024 Terms must be entered
				NEXT FIELD term_code 
			ELSE 
				SELECT * FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = l_rec_term.term_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("P",9025,"")		#9025 Term Code NOT found - try window
					NEXT FIELD term_code 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW P195 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_term_code 
	ELSE 
		RETURN l_rec_term.term_code 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION enter_term(p_term_code)
############################################################


############################################################
# FUNCTION show_inttype()
#
#
############################################################
FUNCTION show_inttype() 
	DEFINE l_arr_int_ind ARRAY[7] OF RECORD 
		scroll_flag CHAR(1), 
		option_num LIKE recurhead.int_ind, 
		option_text CHAR(30) 
	END RECORD
	DEFINE idx SMALLINT

	FOR idx = 1 TO 7 
		LET l_arr_int_ind[idx].scroll_flag = NULL 
		IF idx < 5 THEN 
			LET l_arr_int_ind[idx].option_num = idx 
			LET l_arr_int_ind[idx].option_text = kandooword("recurhead.int_ind", idx) 
		ELSE 
			LET l_arr_int_ind[idx].option_num = idx + 1 
			LET l_arr_int_ind[idx].option_text = kandooword("recurhead.int_ind", (idx+1)) 
		END IF 
	END FOR 

	OPEN WINDOW p196 with FORM "P196" 
	CALL windecoration_p("P196") 
	MESSAGE kandoomsg2("P",1034,"")	#1034 RETURN on line TO SELECT - ESC TO Continue

	CALL set_count(idx-1) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	DISPLAY ARRAY l_arr_int_ind TO sr_int_ind.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P71","display-arr-int_ind") 

		BEFORE ROW 
			LET idx = arr_curr() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (tab) 
			EXIT DISPLAY 

		ON KEY (RETURN) 
			EXIT DISPLAY 

	END DISPLAY 

	#	LET idx = arr_curr()  #really ? I did not know, you could to this outside of a display/input ARRAY. Either way, I'll move it to BEFORE ROW

	CLOSE WINDOW p196 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN ("") 
	ELSE 
		RETURN l_arr_int_ind[idx].option_num 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION show_inttype()
############################################################


############################################################
# FUNCTION distribute(p_rec_recurhead)
#
#
############################################################
FUNCTION distribute(p_rec_recurhead) 
	DEFINE p_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE l_rec_recurdetl RECORD LIKE recurdetl.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 

	LET l_rec_voucher.cmpy_code = p_rec_recurhead.cmpy_code 
	LET l_rec_voucher.vend_code = p_rec_recurhead.vend_code 
	LET l_rec_voucher.vouch_code = NULL 
	LET l_rec_voucher.total_amt = p_rec_recurhead.total_amt 
	LET l_rec_voucher.dist_amt = p_rec_recurhead.dist_amt 
	LET l_rec_voucher.dist_qty = p_rec_recurhead.dist_qty 
	LET l_rec_voucher.line_num = p_rec_recurhead.line_num 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING l_rec_voucher.year_num, 
	l_rec_voucher.period_num 

	IF p_rec_recurhead.tax_code IS NULL THEN 
		SELECT tax_code INTO l_rec_voucher.tax_code 
		FROM vendor 
		WHERE cmpy_code = p_rec_recurhead.cmpy_code 
		AND vend_code = p_rec_recurhead.vend_code 
	ELSE 
		LET l_rec_voucher.tax_code = p_rec_recurhead.tax_code 
	END IF 

	LET l_rec_voucher.currency_code = p_rec_recurhead.curr_code 
	LET l_rec_voucher.source_ind = "2" 
	LET l_rec_voucher.source_text = p_rec_recurhead.recur_code 

	CALL create_table("voucherdist","t_voucherdist","","N") 

	DECLARE c_recurdetl CURSOR FOR 
	SELECT * FROM t_recurdetl ORDER BY line_num 

	FOREACH c_recurdetl INTO l_rec_recurdetl.* 

		INITIALIZE l_rec_voucherdist.* TO NULL 

		LET l_rec_voucherdist.cmpy_code = l_rec_recurdetl.cmpy_code 
		LET l_rec_voucherdist.vend_code = p_rec_recurhead.vend_code 
		LET l_rec_voucherdist.line_num = l_rec_recurdetl.line_num 
		LET l_rec_voucherdist.type_ind = l_rec_recurdetl.type_ind 
		LET l_rec_voucherdist.acct_code = l_rec_recurdetl.acct_code 
		LET l_rec_voucherdist.desc_text = l_rec_recurdetl.desc_text 
		LET l_rec_voucherdist.dist_qty = l_rec_recurdetl.dist_qty 
		LET l_rec_voucherdist.dist_amt = l_rec_recurdetl.dist_amt 
		LET l_rec_voucherdist.analysis_text = l_rec_recurdetl.analysis_text 
		LET l_rec_voucherdist.res_code = l_rec_recurdetl.res_code 
		LET l_rec_voucherdist.job_code = l_rec_recurdetl.job_code 
		LET l_rec_voucherdist.var_code = l_rec_recurdetl.var_code 
		LET l_rec_voucherdist.act_code = l_rec_recurdetl.act_code 
		LET l_rec_voucherdist.po_num = l_rec_recurdetl.po_num 
		LET l_rec_voucherdist.po_line_num=l_rec_recurdetl.po_line_num 
		LET l_rec_voucherdist.trans_qty = l_rec_recurdetl.trans_qty 
		LET l_rec_voucherdist.cost_amt = l_rec_recurdetl.cost_amt 
		LET l_rec_voucherdist.charge_amt = l_rec_recurdetl.charge_amt 

		INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 

	END FOREACH 

	OPEN WINDOW P169 with FORM "P169" 
	CALL windecoration_p("P169") 

	IF distribute_voucher_to_accounts(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_kandoouser.sign_on_code,
		l_rec_voucher.*) THEN
		 
		# DELETE --------------------
		DELETE FROM t_recurdetl 
		
		DECLARE c_voucherdist CURSOR FOR 
		SELECT * FROM t_voucherdist 
		ORDER BY line_num 

		FOREACH c_voucherdist INTO l_rec_voucherdist.* 
			LET l_rec_recurdetl.cmpy_code = l_rec_voucherdist.cmpy_code 
			LET l_rec_recurdetl.recur_code = p_rec_recurhead.recur_code 
			LET l_rec_recurdetl.line_num = l_rec_voucherdist.line_num 
			LET l_rec_recurdetl.type_ind = l_rec_voucherdist.type_ind 
			LET l_rec_recurdetl.acct_code = l_rec_voucherdist.acct_code 
			LET l_rec_recurdetl.desc_text = l_rec_voucherdist.desc_text 
			LET l_rec_recurdetl.dist_qty = l_rec_voucherdist.dist_qty 
			LET l_rec_recurdetl.dist_amt = l_rec_voucherdist.dist_amt 
			LET l_rec_recurdetl.analysis_text = l_rec_voucherdist.analysis_text 
			LET l_rec_recurdetl.res_code = l_rec_voucherdist.res_code 
			LET l_rec_recurdetl.job_code = l_rec_voucherdist.job_code 
			LET l_rec_recurdetl.var_code = l_rec_voucherdist.var_code 
			LET l_rec_recurdetl.act_code = l_rec_voucherdist.act_code 
			LET l_rec_recurdetl.po_num = l_rec_voucherdist.po_num 
			LET l_rec_recurdetl.po_line_num = l_rec_voucherdist.po_line_num 
			LET l_rec_recurdetl.trans_qty = l_rec_voucherdist.trans_qty 
			LET l_rec_recurdetl.cost_amt = l_rec_voucherdist.cost_amt 
			LET l_rec_recurdetl.charge_amt = l_rec_voucherdist.charge_amt 
			INSERT INTO t_recurdetl VALUES (l_rec_recurdetl.*) 
		END FOREACH 

	END IF 
	DROP TABLE t_voucherdist 

	CLOSE WINDOW P169 

END FUNCTION 
############################################################
# FUNCTION distribute(p_rec_recurhead)
############################################################


############################################################
# FUNCTION set_arr(p_rec_recurhead)
#
#
############################################################
FUNCTION set_arr(p_rec_recurhead) 
	DEFINE p_rec_recurhead RECORD LIKE recurhead.* 

	RETURN 
	"", 
	p_rec_recurhead.recur_code, 
	p_rec_recurhead.desc_text, 
	p_rec_recurhead.vend_code, 
	p_rec_recurhead.last_vouch_date, 
	p_rec_recurhead.next_vouch_date, 
	p_rec_recurhead.hold_code 
END FUNCTION 
############################################################
# END FUNCTION set_arr(p_rec_recurhead)
############################################################


############################################################
# FUNCTION init_recurhead(p_recur_code)
#
#
############################################################
FUNCTION init_recurhead(p_recur_code) 
	DEFINE p_recur_code LIKE recurhead.recur_code 

	DELETE FROM t_recurdetl 

	IF p_recur_code IS NULL THEN 
	
		INITIALIZE glob_rec_recurhead.* TO NULL 
	
		LET glob_rec_recurhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_recurhead.run_num = 0 
		LET glob_rec_recurhead.line_num = 0 
		LET glob_rec_recurhead.run_date = "" 
		LET glob_rec_recurhead.last_vouch_date = "" 
	ELSE 
		SELECT * INTO glob_rec_recurhead.* 
		FROM recurhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND recur_code = p_recur_code 
		
		#--------------------------------
		INSERT INTO t_recurdetl 
		
		SELECT * FROM recurdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND recur_code = p_recur_code 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION init_recurhead(p_recur_code)
############################################################