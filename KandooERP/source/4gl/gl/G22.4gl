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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "G21_GLOBALS.4gl" 

############################################################
# FUNCTION G22_main()
#
# \brief module G22  allows the user TO UPDATE unposted Journal Batches
############################################################
FUNCTION G22_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("G22") 
	#   CALL create_table("batchdetl","t_batchdetl","","Y") #changed to normal table by Eric

	OPEN WINDOW g464 with FORM "G464" 
	CALL windecoration_g("G464") 

	CALL scan_jour() 

	CLOSE WINDOW G464 
END FUNCTION 
############################################################
# END FUNCTION G22_main()
############################################################


############################################################
# FUNCTION select_jour()
#
#
############################################################
FUNCTION get_datasource_jour_batchhead(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_bf_with_scrollflag 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("G",1001,"")
		CONSTRUCT BY NAME l_where_text ON 
			jour_code, 
			jour_num, 
			jour_date, 
			year_num, 
			period_num, 
			for_debit_amt, 
			for_credit_amt, 
			currency_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","G22","construct-jour") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE kandoomsg2("G",1002,"")	#1002 " Searching database - please wait "
		LET l_query_text = 
			"SELECT * FROM batchhead ", 
			"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND post_flag='N' ", 
			"AND source_ind='G' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY jour_code,jour_num" 
		PREPARE s_batchhead FROM l_query_text 
		DECLARE c_batchhead CURSOR FOR s_batchhead 
	END IF 

	LET l_idx = 0 
	FOREACH c_batchhead INTO glob_rec_batchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_batchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_batchhead[l_idx].jour_code = glob_rec_batchhead.jour_code 
		LET l_arr_rec_batchhead[l_idx].jour_num = glob_rec_batchhead.jour_num 
		LET l_arr_rec_batchhead[l_idx].jour_date = glob_rec_batchhead.jour_date 
		LET l_arr_rec_batchhead[l_idx].year_num = glob_rec_batchhead.year_num 
		LET l_arr_rec_batchhead[l_idx].period_num = glob_rec_batchhead.period_num 
		LET l_arr_rec_batchhead[l_idx].for_debit_amt = glob_rec_batchhead.for_debit_amt 
		LET l_arr_rec_batchhead[l_idx].for_credit_amt = glob_rec_batchhead.for_credit_amt 
		LET l_arr_rec_batchhead[l_idx].currency_code = glob_rec_batchhead.currency_code 

		#Note, this is not complete yet
		#Feature Request: Show within the array, if a batch is balanced or not
		#BUT balanced is not just for_debit_Amt = for_credit_amt, there are may be other factors
		#like control_tot, quantity, currency...

		#DEBUG
		#			DISPLAY "DEBUG-01-glob_rec_batchhead.stats_qty = ", trim(glob_rec_batchhead.stats_qty)
		#			DISPLAY "DEBUG-01-glob_rec_batchhead.control_qty = ", trim(glob_rec_batchhead.control_qty)

		#END DEBUG

		IF glob_rec_glparms.control_tot_flag = "N" THEN 
			#LET glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty
			CASE 
			#WHEN glob_rec_batchhead.for_debit_amt > glob_rec_batchhead.for_credit_amt
			#   LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt
			#WHEN glob_rec_batchhead.for_debit_amt < glob_rec_batchhead.for_credit_amt
			#   LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt
				OTHERWISE 
					#      LET glob_rec_batchhead.control_amt = glob_rec_batchhead.for_credit_amt
					IF glob_rec_batchhead.for_debit_amt > 0 THEN 
						LET l_arr_rec_batchhead[l_idx].balanced_flag = "Y" 
					ELSE 
						LET l_arr_rec_batchhead[l_idx].balanced_flag = "N" 
					END IF 

			END CASE 
		ELSE 
			IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt 
			AND glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.control_amt 
			AND glob_rec_batchhead.stats_qty = glob_rec_batchhead.control_qty 
			AND glob_rec_batchhead.for_debit_amt > 0 THEN 
				LET l_arr_rec_batchhead[l_idx].balanced_flag = "Y" 
			ELSE 
				LET l_arr_rec_batchhead[l_idx].balanced_flag = "N" 
			END IF 
		END IF 


		IF glob_rec_batchhead.for_debit_amt = glob_rec_batchhead.for_credit_amt 
		#AND glob_rec_batchhead.control_qty = glob_rec_batchhead.stats_qty
		#AND glob_rec_batchhead.control_amt = glob_rec_batchhead.for_debit_amt
		THEN 

			#control_tot_flag
			#use_currency_flag
			#base_currency_flag
			LET l_arr_rec_batchhead[l_idx].balanced_flag = "Y" 
		ELSE 
			LET l_arr_rec_batchhead[l_idx].balanced_flag = "N" 
		END IF 

		#      IF l_idx = 200 THEN
		#         LET msgresp=kandoomsg("G",9042,l_idx)
		#         #9035" First 200 Journal Selected Only "
		#         EXIT FOREACH
		#      END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	RETURN l_arr_rec_batchhead 
END FUNCTION 
############################################################
# END FUNCTION select_jour()
############################################################


############################################################
# FUNCTION scan_jour()
#
#
############################################################
FUNCTION scan_jour() 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_yn_pn_fda_fca_cc_bf_with_scrollflag 
	#	#array[200] of record
	#		RECORD
	#         scroll_flag CHAR(1),
	#         jour_code LIKE batchhead.jour_code,
	#         jour_num LIKE batchhead.jour_num,
	#         jour_date LIKE batchhead.jour_date,
	#         year_num LIKE batchhead.year_num,
	#         period_num LIKE batchhead.period_num,
	#         for_debit_amt LIKE batchhead.for_debit_amt,
	#         for_credit_amt LIKE batchhead.for_credit_amt,
	#         currency_code LIKE batchhead.currency_code
	#		END RECORD
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_idx SMALLINT #,scrn 


	# dataSource
	LET l_idx = db_batchhead_get_count_post_flag_source_ind("N","G") 

	CASE 
		WHEN (l_idx = 0) 
			CALL fgl_winmessage("No records found","There are no none-posted records available to edit!\nExit application","error") 
			EXIT PROGRAM 

		WHEN (l_idx < get_settings_maxListArraySizeSwitch()) 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

		WHEN (l_idx >= get_settings_maxListArraySizeSwitch()) 
			CALL get_datasource_jour_batchhead(true) RETURNING l_arr_rec_batchhead 
	END CASE 

	{
	   LET l_idx = 0
	   FOREACH c_batchhead INTO glob_rec_batchhead.*
	      LET l_idx = l_idx + 1
	      LET l_arr_rec_batchhead[l_idx].scroll_flag = NULL
	      LET l_arr_rec_batchhead[l_idx].jour_code = glob_rec_batchhead.jour_code
	      LET l_arr_rec_batchhead[l_idx].jour_num = glob_rec_batchhead.jour_num
	      LET l_arr_rec_batchhead[l_idx].jour_date = glob_rec_batchhead.jour_date
	      LET l_arr_rec_batchhead[l_idx].year_num = glob_rec_batchhead.year_num
	      LET l_arr_rec_batchhead[l_idx].period_num = glob_rec_batchhead.period_num
	      LET l_arr_rec_batchhead[l_idx].for_debit_amt = glob_rec_batchhead.for_debit_amt
	      LET l_arr_rec_batchhead[l_idx].for_credit_amt = glob_rec_batchhead.for_credit_amt
	      LET l_arr_rec_batchhead[l_idx].currency_code = glob_rec_batchhead.currency_code
	#      IF l_idx = 200 THEN
	#         LET msgresp=kandoomsg("G",9042,l_idx)
	#         #9035" First 200 Journal Selected Only "
	#         EXIT FOREACH
	#      END IF
	   END FOREACH

	   IF l_idx = 0 THEN
	      LET msgresp=kandoomsg("G",9043,"")
	#9036 No Journal Selected
	   ELSE
	      CALL set_count(l_idx)
	#      OPTIONS INSERT KEY F36,
	#              DELETE KEY F36
	      LET msgresp=kandoomsg("G",1039,"")

	#1021 Journal - RETURN TO Edit"


	}
	-----------------------------------------------------------------------------------
	#INPUT ARRAY l_arr_rec_batchhead WITHOUT DEFAULTS FROM sr_batchhead.*  ATTRIBUTES(UNBUFFERED, insert row = false, append row = false,delete row = false, auto append = false)
	DISPLAY ARRAY l_arr_rec_batchhead TO sr_batchhead_2.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G22","input-arr-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(true) RETURNING l_arr_rec_batchhead 

		ON ACTION "REFRESH" 
			CALL windecoration_g("G464") 
			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "NEW" 
			CALL run_prog("G21","","","","") #new batch 
			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 


		ON ACTION "GP2" #post journals 
			CALL run_prog("GP2","","","","") #post journals 
			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "GRA" #trial balance REPORT 
			CALL run_prog("GRA","","","","") #trial balance REPORT 
			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

			#			BEFORE FIELD scroll_flag
			#            IF l_arr_rec_batchhead[l_idx].jour_code IS NOT NULL THEN
			#               #DISPLAY l_arr_rec_batchhead[l_idx].*
			#               #     TO sr_batchhead[scrn].*
			#
			#            END IF

			#			AFTER FIELD scroll_flag
			#            IF fgl_lastkey() = fgl_keyval("down") THEN
			#               IF arr_curr() = arr_count() THEN
			#                  LET msgresp=kandoomsg("I",9001,"")
			#                  #9001 There are no more rows in the direction ...
			#                  NEXT FIELD scroll_flag
			#               ELSE
			#                  IF l_arr_rec_batchhead[l_idx+1].jour_code IS NULL THEN
			#                     LET msgresp=kandoomsg("I",9001,"")
			#                     #9001 There are no more rows in the direction ...
			#                     NEXT FIELD scroll_flag
			#                  END IF
			#               END IF
			#            END IF

		ON ACTION ("EDIT","DOUBLECLICK") 
			#			BEFORE FIELD jour_code
			--				CALL get_datasource_jour_batchhead(FALSE) RETURNING l_arr_rec_batchhead

			OPEN WINDOW g463 with FORM "G463" 
			CALL windecoration_g("G463") 

			CALL init_journal(l_arr_rec_batchhead[l_idx].jour_num) #edit batch requires the jour_num / FOR new batch this argument IS NULL 
			LET l_jour_num = NULL 

			# Header----------------------------------------------------- WHILE 1 -------
			WHILE G21_header() #WHILE G21_header(MODE_CLASSIC_EDIT)

				OPEN WINDOW G114 with FORM "G114" 
				CALL windecoration_g("G114") 

				# ROWs/Detail --------------------------------------------- WHILE 2 -------
				WHILE batch_lines_entry() 

					#Save/Cancel -------------------------------------------- MENU  --------------
					MENU " Journal" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","G22","menu-journal") 
 							CALL dialog.setActionHidden("CANCEL",TRUE) #we only have save OR discard !" (Discard is Cancel)

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON ACTION "Save" # command"Save" " Save changes TO database" 
							LET l_jour_num = g21a_write_gl_batch(MODE_CLASSIC_EDIT) 
							IF l_jour_num < 0 THEN	# Error in capital account funds available
								CALL fgl_winmessage("Could not save data","Error in capital account funds available","ERROR")
								NEXT option "Exit" 
							ELSE 
								--EXIT MENU
								EXIT WHILE 
							END IF 
							--						CALL get_datasource_jour_batchhead(FALSE) RETURNING l_arr_rec_batchhead

						ON ACTION "Discard" # command"Discard" " Discard changes TO batch" 
							--LET quit_flag = TRUE
							--LET int_flag = TRUE 
							LET l_jour_num = 0 
							--EXIT MENU 
							EXIT WHILE 
						ON ACTION "Exit" # COMMAND KEY(interrupt,"E") "Exit" " RETURN TO edit batch" 
							--LET quit_flag = TRUE
							--LET int_flag = TRUE 
							--EXIT MENU 
							EXIT WHILE
					END MENU 
					--------------------------------------------------- END MENU --------------

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false
						EXIT WHILE 
--					ELSE 
--						EXIT WHILE 
					END IF 

				END WHILE 
				--------------------------------------------------- END WHILE

				CLOSE WINDOW G114 

				IF l_jour_num IS NOT NULL THEN 
					SELECT 
						year_num, 
						period_num, 
						for_debit_amt, 
						for_credit_amt, 
						currency_code 
					INTO 
						l_arr_rec_batchhead[l_idx].year_num, 
						l_arr_rec_batchhead[l_idx].period_num, 
						l_arr_rec_batchhead[l_idx].for_debit_amt, 
						l_arr_rec_batchhead[l_idx].for_credit_amt, 
						l_arr_rec_batchhead[l_idx].currency_code 
					FROM batchhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND jour_num = glob_rec_batchhead.jour_num 
					CALL l_arr_rec_batchhead.clear() 
					CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

					EXIT WHILE 
				END IF 
			END WHILE 
			------------------------------- END WHILE

			CLOSE WINDOW G463 

			CALL l_arr_rec_batchhead.clear() 
			CALL get_datasource_jour_batchhead(false) RETURNING l_arr_rec_batchhead 

			NEXT FIELD scroll_flag 
	END DISPLAY 

	#	END IF

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
############################################################
# END FUNCTION scan_jour()
############################################################