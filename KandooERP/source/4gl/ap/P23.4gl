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
	DEFINE glob_err_message CHAR(50) #we may can drop this
END GLOBALS 

############################################################
# Module Scope Variables
############################################################
DEFINE modu_vtot LIKE voucher.total_amt 

############################################################
# MAIN
#
# \brief module P23 allows the user TO search FOR unapproved vouchers on
#             selected info THEN TO approve those vouchers
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("P23") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW P146 with FORM "P146" 
	CALL windecoration_p("P146") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_voucher() 

	#  #if the the table has more than 1000 rows, force a query TO filter data
	#	IF db_voucher_get_count() > 1000 THEN
	#		LET l_withQuery = TRUE
	#	END IF

	#   WHILE doit(l_withQuery)
	#		LET l_withQuery = scan_voucher()
	#		IF l_withQuery = 2 OR int_flag THEN
	#			EXIT WHILE
	#		END IF
	#	END WHILE


	CLOSE WINDOW P146 
END MAIN 
############################################################
# MAIN
############################################################


############################################################
# FUNCTION db_voucher_select(p_withQuery)
#
#
############################################################
FUNCTION db_voucher_select(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_ve_vc_pn_vd_ec_ed_ta_with_scrollflag 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_sel_text CHAR(500) 
	DEFINE l_where_part CHAR(500) 
	DEFINE l_kandoooption LIKE kandoooption.feature_ind 
	DEFINE l_order_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME l_where_part ON 
			vend_code, 
			vouch_code, 
			po_num, 
			vouch_date, 
			entry_code, 
			entry_date, 
			total_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P23","construct-vendor-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_part = "1=1" 
		END IF 

	ELSE 
		LET l_where_part = "1=1" 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"") 
	LET l_kandoooption = get_kandoooption_feature_state("AP","DO") 

	IF l_kandoooption = "1" THEN 
		LET l_order_text = "ORDER BY vend_code " 
	END IF 

	IF l_kandoooption = "2" THEN 
		LET l_order_text = "ORDER BY vouch_code " 
	END IF 

	LET l_sel_text = 
		"SELECT * FROM voucher ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND approved_code = 'N' ", 
		"AND ", l_where_part clipped, " ", l_order_text clipped 

	PREPARE getpord FROM l_sel_text 
	DECLARE c_pord CURSOR FOR getpord 

	LET l_idx = 0 
	FOREACH c_pord INTO l_rec_voucher.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_voucher[l_idx].vend_code = l_rec_voucher.vend_code 
		LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_rec_voucher[l_idx].po_num = l_rec_voucher.po_num 
		LET l_arr_rec_voucher[l_idx].entry_code = l_rec_voucher.entry_code 
		LET l_arr_rec_voucher[l_idx].vouch_date = l_rec_voucher.vouch_date 
		LET l_arr_rec_voucher[l_idx].entry_date = l_rec_voucher.entry_date 
		LET l_arr_rec_voucher[l_idx].total_amt = l_rec_voucher.total_amt 

		LET modu_vtot = modu_vtot + l_rec_voucher.total_amt 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF

	END FOREACH 

	RETURN l_arr_rec_voucher 
END FUNCTION 
############################################################
# END FUNCTION db_voucher_select(p_withQuery)
############################################################


############################################################
# FUNCTION scan_voucher()
#
#
############################################################
FUNCTION scan_voucher() 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_ve_vc_pn_vd_ec_ed_ta_with_scrollflag 
	#	array[820] OF
	#		RECORD
	#			scroll_flag CHAR(1),
	#			vend_code LIKE voucher.vend_code,
	#			vouch_code LIKE voucher.vouch_code,
	#			po_num LIKE voucher.po_num,
	#			vouch_date LIKE voucher.vouch_date,
	#			entry_code LIKE voucher.entry_code,
	#			entry_date LIKE voucher.entry_date,
	#			total_amt LIKE voucher.total_amt
	#     END RECORD
	DEFINE l_atot LIKE voucher.total_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_vcnt SMALLINT 
	DEFINE l_acnt SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE h SMALLINT 
	#DEFINE l_err_flag SMALLINT
	#DEFINE modu_vtot LIKE voucher.total_amt #???

	IF db_voucher_get_count_approved('N') > get_settings_maxListArraySizeSwitch() THEN
		CALL db_voucher_select(false) RETURNING l_arr_rec_voucher 	#for none-approved vouchers, we do not need to count prior
	END IF 
 
	LET l_vcnt= 0 
	LET modu_vtot= 0 
	LET l_acnt= 0 
	LET l_atot= 0 

	LET l_msgresp = kandoomsg("P",1079,"") 
	LET l_vcnt = l_idx 

	IF modu_vtot IS NULL THEN		#best TO show zero so user will notice rather than NULL
		LET modu_vtot = l_arr_rec_voucher.getlength() 
	END IF 

	DISPLAY l_vcnt TO vcnt 
	DISPLAY modu_vtot TO vtot 
	DISPLAY l_acnt TO acnt 
	DISPLAY l_atot TO atot 

	#INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* ATTRIBUTES(unbuffered, append row = false, auto append = false,delete row = false)
	DISPLAY ARRAY l_arr_rec_voucher TO sr_voucher.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			--CALL fgl_dialog_setkeylabel("F5","Voucher Summary") 
			CALL fgl_dialog_setkeylabel("F8","Calc. Total") 
			CALL publish_toolbar("kandoo","P23","inp-arr-voucher-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_arr_rec_voucher[l_idx].scroll_flag = l_scroll_flag 

		AFTER ROW 
			LET l_arr_rec_voucher[l_idx].scroll_flag = l_scroll_flag 

			#		   LET scrn = scr_line()

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_voucher.clear() -- alch remove AFTER lyc-4793 fix 
			CALL db_voucher_select(true) RETURNING l_arr_rec_voucher 

			--		ON CHANGE scroll_flag
			--			IF l_arr_rec_voucher[l_idx].scroll_flag = "*" THEN
			--				LET

		ON ACTION "Approve" 
			LET l_idx = arr_curr() 
			LET l_acnt = 0 
			FOR i = 1 TO l_arr_rec_voucher.getlength() 
				IF l_arr_rec_voucher[i].scroll_flag = "*" AND l_arr_rec_voucher[l_idx].vend_code IS NOT NULL THEN 
					LET l_acnt = l_acnt+1 
				END IF 
			END FOR 

			IF l_acnt = 0 THEN #if no ROWS are marked, use/mark CURRENT ROW 
				IF l_arr_rec_voucher[l_idx].vend_code IS NOT NULL THEN 
					LET l_arr_rec_voucher[l_idx].scroll_flag = "*" 
					LET l_acnt = 1 
				END IF 
			END IF 

			--------------------------------------------------------------
			IF l_acnt < 1 THEN #we NEED at least one selection 
				CALL fgl_winmessage("No Vouchers found","There are no none-approved vouchers!","info") 
			ELSE 
				BEGIN WORK 
					FOR l_idx = 1 TO l_arr_rec_voucher.getlength() 
						IF l_arr_rec_voucher[l_idx].vend_code IS NOT NULL AND l_arr_rec_voucher[l_idx].scroll_flag = "*" THEN 
							UPDATE voucher 
							SET approved_by_code = 
							l_rec_voucher.approved_by_code, 
							approved_code = "Y", 
							approved_date = today 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND vend_code = l_arr_rec_voucher[l_idx].vend_code 
							AND vouch_code = l_arr_rec_voucher[l_idx].vouch_code 
						END IF 
					END FOR 
				COMMIT WORK 

				#ask FOR authority
				OPEN WINDOW P516 with FORM "P516" 
				CALL windecoration_p("P516") 

				INPUT BY NAME l_rec_voucher.approved_by_code 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","P23","inp-voucher-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					AFTER FIELD approved_by_code 
						IF l_rec_voucher.approved_by_code IS NULL THEN 
							LET l_msgresp = kandoomsg("U",9102,"") 						#9102 Value must be entered
							NEXT FIELD approved_by_code 
						END IF 

				END INPUT 

				IF (int_flag OR quit_flag) OR l_rec_voucher.approved_by_code IS NULL THEN 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 

				CLOSE WINDOW P516 
			END IF 

			CALL db_voucher_select(false) RETURNING l_arr_rec_voucher 

			#     BEFORE FIELD scroll_flag
			#        LET l_scroll_flag = l_arr_rec_voucher[l_idx].scroll_flag
			#         DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*

			#      AFTER FIELD scroll_flag
			#         LET l_arr_rec_voucher[l_idx].scroll_flag = l_scroll_flag
			#         IF fgl_lastkey() = fgl_keyval("nextpage") THEN
			#            IF l_arr_rec_voucher[l_idx+11].vend_code IS NULL THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               #9001 No more rows in this direction
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() = arr_count() THEN
			#            LET l_msgresp = kandoomsg("W",9001,"")
			#            #9001 No more Rows in direction
			#            NEXT FIELD scroll_flag
			#         END IF
		ON ACTION ("DOUBLECLICK","Voucher Summary") ATTRIBUTES(ACCELERATOR="F5")
		--ON KEY (F5) 
			IF l_arr_rec_voucher.getlength() < 1 THEN 
				ERROR "No vouchers found" 
			ELSE 
				IF l_arr_rec_voucher[l_idx].vouch_code IS NOT NULL THEN 
					CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, l_arr_rec_voucher[l_idx].vouch_code) 
				END IF 
			END IF 

		ON KEY (F8) 
			IF l_arr_rec_voucher.getlength() < 1 THEN 
				ERROR "No vouchers found" 
			ELSE 
				IF l_arr_rec_voucher[l_idx].vouch_code IS NOT NULL THEN 
					IF l_arr_rec_voucher[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_voucher[l_idx].scroll_flag = "*" 
						LET l_acnt = l_acnt + 1 
						LET l_atot = l_atot + l_arr_rec_voucher[l_idx].total_amt 
					ELSE 
						LET l_arr_rec_voucher[l_idx].scroll_flag = NULL 
						LET l_acnt = l_acnt - 1 
						LET l_atot = l_atot - l_arr_rec_voucher[l_idx].total_amt 
					END IF 
					#           DISPLAY l_arr_rec_voucher[l_idx].scroll_flag TO sr_voucher[scrn].scroll_flag

					DISPLAY l_acnt,l_atot TO acnt,atot 

				END IF 
				#         NEXT FIELD scroll_flag
			END IF 
			
		ON KEY (F10) #toggle all selectors 
			FOR i = 1 TO arr_count() 
				IF l_arr_rec_voucher[l_idx].vouch_code IS NOT NULL THEN 
					IF l_arr_rec_voucher[i].scroll_flag IS NULL THEN 
						LET l_arr_rec_voucher[i].scroll_flag = "*" 
						LET l_acnt = l_acnt + 1 
						LET l_atot = l_atot + l_arr_rec_voucher[i].total_amt 
					ELSE 
						LET l_arr_rec_voucher[i].scroll_flag = NULL 
						LET l_acnt = l_acnt - 1 
						LET l_atot = l_atot - l_arr_rec_voucher[i].total_amt 
					END IF 
				END IF 
			END FOR 
		
			DISPLAY l_acnt TO acnt 
			DISPLAY l_atot TO atot

			#         LET h = arr_curr()
			#         LET x = scr_line()
			#         LET j = 11 - x
			#         LET y = (h - x) + 1
			#         LET scrn = 1
			#         FOR i = y TO (y + 12)
			#            IF i <= arr_count() THEN
			#               IF scrn <= 11 THEN
			#                  DISPLAY l_arr_rec_voucher[i].scroll_flag TO
			#                          sr_voucher[scrn].scroll_flag
			#
			#                  LET scrn = scrn + 1
			#               END IF
			#            END IF
			#         END FOR
			#			DISPLAY BY NAME l_acnt,l_atot

			#         LET scrn = scr_line()
			#         NEXT FIELD scroll_flag

			#      BEFORE FIELD vend_code
			#         NEXT FIELD scroll_flag

			#      AFTER ROW
			#         DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*

	END DISPLAY #end DISPLAY ARRAY 
	-----------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	END IF 
	{
		ELSE
			IF l_acnt > 0 THEN
	#ask FOR authority
				OPTIONS form line 1
				OPEN WINDOW P516 WITH FORM "P516"
				CALL windecoration_p("P516")


		INPUT BY NAME l_rec_voucher.approved_by_code

			BEFORE INPUT
				CALL publish_toolbar("kandoo","P23","inp-voucher-1")

			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)

			ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

	            AFTER FIELD approved_by_code
	               IF l_rec_voucher.approved_by_code IS NULL THEN
	                  LET l_msgresp = kandoomsg("U",9102,"")
	#9102 Value must be entered
	                  NEXT FIELD approved_by_code
	               END IF

	            END INPUT
	            IF (int_flag OR quit_flag)
	            OR l_rec_voucher.approved_by_code IS NULL THEN
	               LET int_flag = FALSE
	               LET quit_flag = FALSE
	               CLOSE WINDOW P516
	               OPTIONS form line 3
	               NEXT FIELD scroll_flag
	            END IF
	            CLOSE WINDOW P516

	         END IF
	      END IF
	   END INPUT
	}
	#   IF int_flag OR quit_flag THEN
	#      LET int_flag = FALSE
	#      LET quit_flag = FALSE
	#   ELSE
	#      LET l_msgresp = kandoomsg("U",1005,"")

	#      GOTO bypass
	#label recovery:
	#         LET try_again = error_recover(glob_err_message, STATUS)
	#         IF try_again != "Y" THEN
	#            EXIT PROGRAM
	#         END IF
	#
	#label bypass:
	#      WHENEVER ERROR GOTO recovery
	#      IF l_acnt > 0 THEN
	#         BEGIN WORK
	#         FOR l_idx = 1 TO arr_count()
	#            IF  l_arr_rec_voucher[l_idx].vend_code IS NOT NULL
	#            AND l_arr_rec_voucher[l_idx].scroll_flag = "*" THEN
	#               UPDATE voucher
	#                 SET approved_by_code = l_rec_voucher.approved_by_code,
	#                     approved_code = "Y",
	#                     approved_date = today
	#                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#                    AND vend_code = l_arr_rec_voucher[l_idx].vend_code
	#                    AND vouch_code = l_arr_rec_voucher[l_idx].vouch_code
	#            END IF
	#         END FOR
	#         COMMIT WORK
	#      END IF
	#   END IF

	#	IF int_flag OR quit_flag THEN
	#		LET int_flag = FALSE
	#		LET quit_flag = FALSE
	#		RETURN 2
	#	END IF

END FUNCTION 
############################################################
# END FUNCTION scan_voucher()
############################################################