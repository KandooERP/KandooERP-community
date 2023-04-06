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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 

GLOBALS 
	#DEFINE pr_temp_text CHAR(10)
	DEFINE glob_err_message CHAR(50) 
	DEFINE glob_gv_distr_amt_option CHAR(1) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P27 - Voucher Edit
#                Provides scan of vouchers NOT posted AND allows
#                edit,user IS able TO modify distributions before save
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("P27") 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET glob_gv_distr_amt_option = get_kandoooption_feature_state("AP", "DA") 
	CALL create_table("voucherdist","t_voucherdist","","Y") 

	OPEN WINDOW P123 with FORM "P123" 
	CALL windecoration_p("P123") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#  #if the the table has more than 1000 rows, force a query TO filter data
	#	IF db_voucher_get_count() > 1000 THEN
	#		LET l_withQuery = TRUE
	#	ELSE
	#		LET l_withQuery = FALSE
	#	END IF

	#	WHILE select_vouch(l_withQuery)
	#		LET l_withQuery = scan_vouch()
	#		IF l_withQuery = 2 OR int_flag THEN
	#			EXIT WHILE
	#		END IF
	#	END WHILE

	CALL scan_vouch() 

	CLOSE WINDOW p123 
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
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_kandoooption LIKE kandoooption.feature_ind 
	DEFINE l_order_text CHAR(40) 

	CLEAR FORM 

	MESSAGE kandoomsg2("P",1001,"") 	#1001 " Enter selection criteria 
	CONSTRUCT BY NAME l_where_text ON 
		vouch_code, 
		vend_code, 
		vouch_date, 
		year_num, 
		period_num, 
		total_amt, 
		dist_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P27","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = "1=1" 
	END IF 

	ERROR kandoomsg2("U",1002,"") 
	LET l_kandoooption = get_kandoooption_feature_state("AP","DO") 

	IF l_kandoooption = "1" THEN 
		LET l_order_text = "ORDER BY vend_code " 
	END IF 

	IF l_kandoooption = "2" THEN 
		LET l_order_text = "ORDER BY vouch_code " 
	END IF 

	LET l_query_text = 
		"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", l_order_text clipped 

	#		PREPARE s_voucher FROM l_query_text
	#		DECLARE c_voucher CURSOR FOR s_voucher

	RETURN l_query_text 

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
	DEFINE l_query_text CHAR(300) 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_vo_ve_da_ye_pe_ta_da_with_scrollflag 
	DEFINE l_dist_amt LIKE voucher.dist_amt 
	DEFINE l_batch_num LIKE voucher.batch_num 
	DEFINE l_fv_process_dist CHAR(1) 
	DEFINE l_acnt SMALLINT 
	DEFINE l_arr_select DYNAMIC ARRAY OF 
	RECORD 
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code 
	END RECORD 
	DEFINE l_del_count SMALLINT 
	DEFINE l_msgstr STRING 
	DEFINE l_while STRING 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE h SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE try_again CHAR(1) 
	DEFINE l_msg STRING
	DEFINE l_msgresp LIKE language.yes_flag #is required for prompt
	
	IF db_voucher_get_count() > 1000 THEN 
		LET l_query_text = select_vouch() 
		CALL db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(filter_query_select,l_query_text) RETURNING l_arr_rec_voucher 
	ELSE 
		CALL db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(filter_query_off,l_query_text) RETURNING l_arr_rec_voucher 
	END IF 

	#	LET idx = 0
	#
	#	FOREACH c_voucher INTO l_rec_voucher.*
	#		LET idx = idx + 1
	#		LET l_arr_rec_voucher[idx].vouch_code = l_rec_voucher.vouch_code
	#		LET l_arr_rec_voucher[idx].vend_code = l_rec_voucher.vend_code
	#		LET l_arr_rec_voucher[idx].vouch_date = l_rec_voucher.vouch_date
	#		LET l_arr_rec_voucher[idx].year_num = l_rec_voucher.year_num
	#		LET l_arr_rec_voucher[idx].period_num = l_rec_voucher.period_num
	#		LET l_arr_rec_voucher[idx].total_amt = l_rec_voucher.total_amt
	#		LET l_arr_rec_voucher[idx].dist_amt = l_rec_voucher.dist_amt
	#
	#		IF idx = 200 THEN
	#			ERROR kandoomsg2("P",9006,idx)	#			#P9006 First 999 Vouchers selected
	#			EXIT FOREACH
	#		END IF
	#	END FOREACH
	#
	#	CALL set_count(idx)

	IF l_arr_rec_voucher.getlength() < 1 THEN 
		LET l_msg = kandoomsg2("P",9007,"")	#9007 No Vouchers selected
		ERROR l_msg
		LET l_msg = l_msg, "\nThere are no vouchers!\nExit Program"
		CALL fgl_winmessage("No Vouchers exist",l_msg,"error") 
	ELSE 
		#		MESSAGE kandoomsg2("P",1017,"")#		#1017 RETURN on line TO Edit voucher"
		#		OPTIONS INSERT KEY F36
		#		OPTIONS DELETE KEY F36
		LET l_while = true 
		WHILE l_while 
			INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE ROW = false, INSERT ROW = false) 
			#DISPLAY ARRAY l_arr_rec_voucher TO sr_voucher.*
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P27","inp-arr-voucher-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "FILTER" 
					LET l_query_text = select_vouch() 
					CALL l_arr_rec_voucher.clear()
					 
					CALL db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(filter_query_select,l_query_text) RETURNING l_arr_rec_voucher 

					LET l_while = true 
					EXIT INPUT 
					--			ON CHANGE sr_voucher.*,l_arr_rec_voucher.*
					--				LET l_arr_rec_voucher[idx].scroll_flag = "*"

				AFTER ROW 
					IF field_touched(sr_voucher.*) THEN 
						LET l_arr_rec_voucher[idx].scroll_flag = "*" 
						#				LET l_acnt = l_acnt + 1
						CALL DIALOG.SetFieldTouched("sr_voucher.*", false) #we do this TO support multiple LINES 
					END IF 

				BEFORE ROW 
					LET idx = arr_curr() 
					#	       BEFORE FIELD scroll_flag
					#	            LET idx = arr_curr()
					#LET scrn = scr_line()
					#DISPLAY l_arr_rec_voucher[idx].*
					#     TO sr_voucher[scrn].*

					#       AFTER FIELD scroll_flag
					#            IF fgl_lastkey() = fgl_keyval("down") THEN
					#               IF arr_curr() = arr_count() THEN
					#                  ERROR kandoomsg2("P",9001,"")					#                  #9001 There are no more rows in the direction ...
					#                  NEXT FIELD scroll_flag
					#               ELSE
					#                  IF l_arr_rec_voucher[idx+1].vouch_code IS NULL THEN
					#                     ERROR kandoomsg2("P",9001,"")					#                     #9001 There are no more rows in the direction ...
					#                     NEXT FIELD scroll_flag
					#                  END IF
					#               END IF
					#            END IF

					#			ON ACTION "APPROVE" 		--ON KEY(F8)
					#				CALL l_arr_select.CLEAR()
					#				FOR idx = 1 TO arr_count()
					#					IF l_arr_rec_voucher[idx].scroll_flag = "*" THEN
					#						CALL l_arr_select.append(l_arr_rec_voucher[idx].vouch_code,l_arr_rec_voucher[idx].vend_code)
					#					END IF
					#				END FOR
					#				LET l_del_count = l_arr_select.getLength()
					#
					#				IF l_del_count > 0 THEN #scroll selector was used
					#
					#				END IF
					#
					#
					#
					#				CALL l_arr_select.CLEAR()
					#				FOR idx = 1 TO arr_count()
					#					IF dialog.isRowSelected("sr_voucher",idx) THEN
					#						CALL l_arr_select.append(l_arr_rec_voucher[idx].vouch_code,l_arr_rec_voucher[idx].vend_code)
					#					END IF
					#				END FOR
					#				LET l_del_count = l_arr_select.getLength()
					#
					#			LET l_msgStr = "Are you sure you want TO delete ", trim(l_del_count)," vouchers ?"
					#			IF promptYN("Delete Vouchers",l_msgStr,"Y") = "y" THEN
					#				FOR idx = 1 TO l_arr_select.getLength()
					#					IF db_voucher_delete(l_arr_select[idx].vouch_code, l_arr_select[idx].vend_code) <> 0 THEN
					#						ERROR "Could NOT delete Voucher ", trim(l_arr_select[idx].vouch_code), "/", trim(l_arr_select[idx].vend_code)
					#						LET l_del_count = l_del_count -1
					#					END IF
					#				END FOR
					#
					#				CALL db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(FILTER_QUERY_OFF,l_query_text) RETURNING l_arr_rec_voucher
					#				MESSAGE trim(l_del_count), " Vouchers out of ", trim(l_arr_select.getLength()), " were successfully removed"
					#			END IF
					#
					#			CALL l_arr_select.CLEAR()
					#
					#
					#
					#         IF l_arr_rec_voucher[idx].vouch_code IS NOT NULL THEN
					#            IF l_arr_rec_voucher[idx].scroll_flag IS NULL THEN
					#               LET l_arr_rec_voucher[idx].scroll_flag = "*"
					#               LET l_acnt = l_acnt + 1
					#            ELSE
					#               LET l_arr_rec_voucher[idx].scroll_flag = NULL
					#               LET l_acnt = l_acnt - 1
					#            END IF
					#            #DISPLAY l_arr_rec_voucher[idx].scroll_flag TO sr_voucher[scrn].scroll_flag
					#
					#         END IF
					#NEXT FIELD scroll_flag

					#      ON KEY(F10) #Delete ????
					#         FOR i = 1 TO arr_count()
					#            IF l_arr_rec_voucher[idx].vouch_code IS NOT NULL THEN
					#               IF l_arr_rec_voucher[i].scroll_flag IS NULL THEN
					#                  LET l_arr_rec_voucher[i].scroll_flag = "*"
					#                  LET l_acnt = l_acnt + 1
					#               ELSE
					#                  LET l_arr_rec_voucher[i].scroll_flag = NULL
					#                  LET l_acnt = l_acnt - 1
					#               END IF
					#            END IF
					#         END FOR
					#         LET h = arr_curr()
					#         LET x = scr_line()
					#         LET j = 13 - x
					#         LET y = (h - x) + 1
					#         #LET scrn = 1
					#         #FOR i = y TO (y + 12)
					#            #IF i <= arr_count() THEN
					#               #IF scrn <= 13 THEN
					#               #   DISPLAY l_arr_rec_voucher[i].scroll_flag TO
					#               #           sr_voucher[scrn].scroll_flag
					#               #
					#               #   LET scrn = scrn + 1
					#               #END IF
					#            #END IF
					#         #END FOR
					#         #LET scrn = scr_line()
					#         NEXT FIELD scroll_flag

				ON ACTION ("DOUBLECLICK","EDIT") #before FIELD vouch_code 
					LET l_batch_num = NULL 

					SELECT batch_num INTO l_batch_num FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vouch_code = l_arr_rec_voucher[idx].vouch_code 

					IF l_batch_num IS NOT NULL THEN 
						SELECT unique(1) FROM batch 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND batch_num = l_batch_num 

						IF status != NOTFOUND THEN 
							ERROR kandoomsg2("P",9556,"")	#9556 Cannot edit voucher currently out of balance.
							NEXT FIELD scroll_flag 
						END IF 
					END IF 

					OPEN WINDOW P125 with FORM "P125" 
					CALL windecoration_p("P125") 

					CALL input_voucher( 
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_kandoouser.sign_on_code, 
						l_arr_rec_voucher[idx].vend_code, 
						l_arr_rec_voucher[idx].vouch_code,"") 
					RETURNING l_rec_voucher.*, l_rec_vouchpayee.* 

					IF l_rec_voucher.vend_code IS NOT NULL THEN 

						DELETE FROM t_voucherdist 

						INSERT INTO t_voucherdist 
						SELECT * FROM voucherdist 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_rec_voucher.vend_code 
						AND vouch_code= l_rec_voucher.vouch_code 


						MENU " Vouchers" 
							BEFORE MENU 
								IF l_rec_voucher.post_flag = "Y" THEN 
									HIDE option "Distribution" 
								ELSE 
									DELETE FROM t_voucherdist 
									INSERT INTO t_voucherdist 

									SELECT * FROM voucherdist 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND vend_code = l_rec_voucher.vend_code 
									AND vouch_code= l_rec_voucher.vouch_code 
								END IF 

								CALL publish_toolbar("kandoo","P27","menu-voucher-1") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 

							COMMAND "Save" " Commit changes TO database" 
								LET l_dist_amt = NULL 
								SELECT sum(dist_amt) INTO l_dist_amt FROM t_voucherdist 

								IF l_dist_amt IS NULL THEN 
									LET l_dist_amt = 0 
								END IF 

								LET l_rec_voucher.vouch_code = update_voucher_related_tables(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"2",l_rec_voucher.*, l_rec_vouchpayee.*) 

								CASE 
									WHEN l_rec_voucher.vouch_code < 0 
										LET l_rec_voucher.vouch_code = 0 - l_rec_voucher.vouch_code 
										ERROR kandoomsg2("P",7016,l_rec_voucher.vouch_code) 										#P7016" Voucher added - error with dist lines

									WHEN l_rec_voucher.vouch_code = 0 
										ERROR kandoomsg2("P",7012,"") 										#P7012 Errors occurred during voucher add
								END CASE 

								SELECT * INTO l_rec_voucher.* 
								FROM voucher 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_rec_voucher.vend_code 
								AND vouch_code= l_arr_rec_voucher[idx].vouch_code 

								LET l_arr_rec_voucher[idx].vend_code = l_rec_voucher.vend_code 
								LET l_arr_rec_voucher[idx].vouch_date = l_rec_voucher.vouch_date 
								LET l_arr_rec_voucher[idx].year_num = l_rec_voucher.year_num 
								LET l_arr_rec_voucher[idx].period_num = l_rec_voucher.period_num 
								LET l_arr_rec_voucher[idx].total_amt = l_rec_voucher.total_amt 
								LET l_arr_rec_voucher[idx].dist_amt = l_rec_voucher.dist_amt 
								EXIT MENU 

							COMMAND "Distribution" "Edit voucher distributions" 
								OPEN WINDOW p169 with FORM "P169" 
								CALL windecoration_p("P169") 
								LET l_fv_process_dist = "Y" 

								WHILE l_fv_process_dist = "Y" 
									IF NOT distribute_voucher_to_accounts(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rec_voucher.*) THEN 
										DELETE FROM t_voucherdist 
										INSERT INTO t_voucherdist 
										SELECT * FROM voucherdist 
										WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
										AND vend_code = l_rec_voucher.vend_code 
										AND vouch_code= l_rec_voucher.vouch_code 
									ELSE 
										LET l_rec_voucher.vouch_code = update_voucher_related_tables(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"2",l_rec_voucher.*, l_rec_vouchpayee.*) 
									END IF 

									IF glob_gv_distr_amt_option = "Y" THEN 
										SELECT sum(dist_amt) 
										INTO l_rec_voucher.dist_amt 
										FROM t_voucherdist 

										IF l_rec_voucher.dist_amt IS NULL THEN 
											LET l_rec_voucher.dist_amt = 0.00 
										END IF 

										IF l_rec_voucher.dist_amt <> l_rec_voucher.total_amt THEN 
											LET l_msgresp = kandoomsg("P", 1054, "") 											#Distribution amount <> Total amount?
										END IF 
									END IF 

									IF glob_gv_distr_amt_option = "N" 
									OR l_rec_voucher.dist_amt = l_rec_voucher.total_amt 
									OR l_msgresp = "Y" THEN 
										LET l_fv_process_dist = "N" 
									END IF 
								END WHILE 
								CLOSE WINDOW P169 

							COMMAND KEY(interrupt,"E")"Exit" "Discard changes AND RETURN TO voucher scan" 
								LET int_flag = false 
								LET quit_flag = false 
								EXIT MENU 

						END MENU 

					END IF 

					CLOSE WINDOW p125 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
					NEXT FIELD scroll_flag 

				AFTER INPUT 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						RETURN 

					ELSE 
						
						LET l_acnt = 0 
						FOR i = 1 TO l_arr_rec_voucher.getlength() 
							IF l_arr_rec_voucher[i].scroll_flag = "*" THEN 
								LET l_acnt = l_acnt + 1 
							END IF 
						END FOR 
						
						IF l_acnt > 0 THEN 
							#ask FOR authority
							#					OPTIONS form line 1
							OPEN WINDOW P516 with FORM "P516" attribute(BORDER, style="center") 
							CALL windecoration_p("P516") 

							INPUT BY NAME l_rec_voucher.approved_by_code 

								BEFORE INPUT 
									CALL publish_toolbar("kandoo","P27","inp-voucher-1") 

								ON ACTION "WEB-HELP" 
									CALL onlinehelp(getmoduleid(),null) 

								ON ACTION "actToolbarManager" 
									CALL setuptoolbar() 

								AFTER FIELD approved_by_code 
									IF l_rec_voucher.approved_by_code IS NULL THEN 
										ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
										NEXT FIELD approved_by_code 
									END IF 

							END INPUT 

							IF (int_flag OR quit_flag) OR l_rec_voucher.approved_by_code IS NULL THEN 
								LET int_flag = false 
								LET quit_flag = false 

								CLOSE WINDOW P516 
								OPTIONS FORM line 3 
								NEXT FIELD scroll_flag 
							END IF 

							CLOSE WINDOW P516 
							#					OPTIONS form line 3
						END IF 

					END IF 

			END INPUT 
		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			ERROR kandoomsg2("U",1005,"") 

			GOTO bypass 
			LABEL recovery: 
			LET try_again = error_recover(glob_err_message, status) 
			IF try_again != "Y" THEN 
				EXIT PROGRAM 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			IF l_acnt > 0 THEN 
				BEGIN WORK 
					FOR idx = 1 TO l_arr_rec_voucher.getlength() # arr_count() 
						IF l_arr_rec_voucher[idx].vend_code IS NOT NULL 
						AND l_arr_rec_voucher[idx].scroll_flag = "*" THEN 
							UPDATE voucher SET 
								approved_by_code = l_rec_voucher.approved_by_code, 
								approved_code = "Y", 
								approved_date = today 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND vend_code = l_arr_rec_voucher[idx].vend_code 
							AND vouch_code = l_arr_rec_voucher[idx].vouch_code 
						END IF 
					END FOR 
				COMMIT WORK 
			END IF 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION scan_vouch()
############################################################