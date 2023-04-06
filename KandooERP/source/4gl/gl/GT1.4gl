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
GLOBALS 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GT1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	#   SELECT * INTO glob_rec_company.*
	#     FROM company
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

	OPEN WINDOW g559 with FORM "G559" 
	CALL windecoration_g("G559") 

	#   WHILE select_tax()
	CALL scan_tax() 
	#   END WHILE
	CLOSE WINDOW G559 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION db_tax_filter_datasource(p_filter)
#
#
############################################################
FUNCTION db_tax_filter_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF t_rec_tax_tc_dt_cm_tp_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN 

		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			tax_code, 
			desc_text, 
			calc_method_flag, 
			tax_per 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GT1","construct-tax") 

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
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp=kandoomsg("U",1002,"")#1002 Searching database - pls wait

	LET l_query_text = 
		"SELECT * FROM tax ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY tax_code" 
	PREPARE s_tax FROM l_query_text 
	DECLARE c_tax CURSOR FOR s_tax 


	LET l_idx = 0 
	FOREACH c_tax INTO l_rec_tax.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code 
		LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text 
		LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag 
		LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per 

		--IF l_idx = 100 THEN 
		--	LET l_msgresp = kandoomsg("U",6100,l_idx) 
		--	EXIT FOREACH			
		--END IF 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_tax.getLength()) 

	RETURN l_arr_rec_tax 
END FUNCTION 
############################################################
# END FUNCTION db_tax_filter_datasource(p_filter)
############################################################


############################################################
# FUNCTION scan_tax()
#
#
############################################################
FUNCTION scan_tax() 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_arr_rec_tax DYNAMIC ARRAY OF t_rec_tax_tc_dt_cm_tp_with_scrollflag 
	#	 array[100] of record
	#         scroll_flag CHAR(1),
	#         tax_code LIKE tax.tax_code,
	#         desc_text LIKE tax.desc_text,
	#         calc_method_flag LIKE tax.calc_method_flag,
	#         tax_per LIKE tax.tax_per
	#      END RECORD
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	#   CALL set_count(l_idx)


	IF db_tax_get_count() > 1000 THEN 
		CALL db_tax_filter_datasource(true) RETURNING l_arr_rec_tax 
	ELSE 
		CALL db_tax_filter_datasource(false) RETURNING l_arr_rec_tax 
	END IF 

	LET l_msgresp = kandoomsg("U",1003,"")#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	INPUT ARRAY l_arr_rec_tax WITHOUT DEFAULTS FROM sr_tax.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GT1","inp-arr-tax1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_tax.clear() 
			CALL db_tax_filter_datasource(true) RETURNING l_arr_rec_tax 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_tax[l_idx].scroll_flag 

		ON CHANGE scroll_flag 
			LET l_scroll_flag = l_arr_rec_tax[l_idx].scroll_flag 
			IF l_arr_rec_tax[l_idx].scroll_flag = "*" THEN 
				LET l_del_cnt = l_del_cnt +1 
			ELSE --scroll_flag IS NULL 
				IF l_del_cnt > 0 THEN 
					LET l_del_cnt = l_del_cnt +1 
				END IF 
			END IF 


			#      BEFORE FIELD scroll_flag
			#         OPTIONS INSERT KEY F1,
			#                 DELETE KEY F36
			#         LET l_idx = arr_curr()
			#         #LET scrn = scr_line()
			#         LET l_scroll_flag = l_arr_rec_tax[l_idx].scroll_flag
			#         #DISPLAY l_arr_rec_tax[l_idx].* TO sr_tax[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_tax[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_tax[l_idx].scroll_flag TO sr_tax[scrn].scroll_flag

			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_tax[l_idx+1].tax_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("U",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF


		ON ACTION ("EDIT","DOUBLECLICK") 
			IF l_arr_rec_tax[l_idx].tax_code IS NOT NULL THEN 
				IF edit_tax(l_arr_rec_tax[l_idx].tax_code) THEN 
					SELECT * INTO l_rec_tax.* FROM tax 
					WHERE tax_code = l_arr_rec_tax[l_idx].tax_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code 
					LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text 
					LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag 
					LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per 
				END IF 
			END IF 
			CALL l_arr_rec_tax.clear() 
			CALL db_tax_filter_datasource(false) RETURNING l_arr_rec_tax 

			#      BEFORE FIELD tax_code
			#         IF l_arr_rec_tax[l_idx].tax_code IS NOT NULL THEN
			#            IF edit_tax(l_arr_rec_tax[l_idx].tax_code) THEN
			#               SELECT * INTO l_rec_tax.* FROM tax
			#                WHERE tax_code = l_arr_rec_tax[l_idx].tax_code
			#                  AND cmpy_code = glob_rec_kandoouser.cmpy_code
			#               LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code
			#               LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text
			#               LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag
			#               LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag

		BEFORE INSERT 
			#IF scrn > 0 THEN
			LET l_rowid = edit_tax("") 
			SELECT * INTO l_rec_tax.* FROM tax 
			WHERE rowid = l_rowid 
			IF status = NOTFOUND THEN 
				FOR l_idx = arr_curr() TO arr_count() 
					LET l_arr_rec_tax[l_idx].* = l_arr_rec_tax[l_idx+1].* 
					#IF scrn <= 10 THEN
					#   DISPLAY l_arr_rec_tax[l_idx].* TO sr_tax[scrn].*
					#
					#   LET scrn = scrn + 1
					#END IF
				END FOR 
				#INITIALIZE l_arr_rec_tax[l_idx].* TO NULL
			ELSE 
				LET l_arr_rec_tax[l_idx].tax_code = l_rec_tax.tax_code 
				LET l_arr_rec_tax[l_idx].desc_text = l_rec_tax.desc_text 
				LET l_arr_rec_tax[l_idx].calc_method_flag = l_rec_tax.calc_method_flag 
				LET l_arr_rec_tax[l_idx].tax_per = l_rec_tax.tax_per 
			END IF 
			NEXT FIELD scroll_flag 
			#END IF

		ON ACTION "DELETE_ROW" 
			IF l_del_cnt > 0 THEN 
				IF kandoomsg("U",8020,l_del_cnt) = "Y" THEN			#8001 Confirmation TO delete l_del_cnt Sales Area
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_tax[l_idx].scroll_flag IS NOT NULL THEN 
							IF NOT taxcode_used(l_arr_rec_tax[l_idx].tax_code) THEN 
								DELETE FROM tax 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND tax_code = l_arr_rec_tax[l_idx].tax_code 
							END IF 
						END IF 
					END FOR 
				END IF 
			END IF 
			CALL l_arr_rec_tax.clear() 
			CALL db_tax_filter_datasource(false) RETURNING l_arr_rec_tax 


			#      ON KEY(F2) #selector for DELETE
			#         IF l_arr_rec_tax[l_idx].scroll_flag IS NULL THEN
			#            IF NOT taxcode_used(l_arr_rec_tax[l_idx].tax_code) THEN
			#               LET l_arr_rec_tax[l_idx].scroll_flag = "*"
			#               LET l_del_cnt = l_del_cnt + 1
			#            END IF
			#            LET l_msgresp = kandoomsg("U",1003,"")
			#            #1003 F1 Add; F2 Delete; TAB TO edit line.
			#         ELSE
			#            LET l_arr_rec_tax[l_idx].scroll_flag = NULL
			#            LET l_del_cnt = l_del_cnt - 1
			#         END IF
			#         NEXT FIELD scroll_flag
			#AFTER ROW
			#   DISPLAY l_arr_rec_tax[l_idx].* TO sr_tax[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#   ELSE
		#      IF l_del_cnt > 0 THEN
		#         IF kandoomsg("U",8020,l_del_cnt) = "Y" THEN
		#            #8001 Confirmation TO delete l_del_cnt Sales Area
		#            FOR l_idx = 1 TO arr_count()
		#               IF l_arr_rec_tax[l_idx].scroll_flag IS NOT NULL THEN
		#                  IF NOT taxcode_used(l_arr_rec_tax[l_idx].tax_code) THEN
		#                     DELETE FROM tax
		#                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                        AND tax_code = l_arr_rec_tax[l_idx].tax_code
		#                  END IF
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 
END FUNCTION 
############################################################
# END FUNCTION scan_tax()
############################################################


##############################################################################
# FUNCTION edit_tax(p_tax_code)
#
# Edit AND create new
#
# Note: FUNCTION edit_tax(p_tax_code) IS also defined in AZ1.4gl HuHo
##############################################################################
FUNCTION edit_tax(p_tax_code) 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_calc_desc_text CHAR(60) 
	DEFINE l_save_method_flag CHAR(1) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_tax_code IS NOT NULL THEN 
		SELECT * INTO l_rec_tax.* FROM tax 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_save_method_flag = l_rec_tax.calc_method_flag 
	ELSE 
		LET l_rec_tax.calc_method_flag = "X" 
		LET l_save_method_flag = NULL 
		LET l_rec_tax.tax_per = 0 
		LET l_rec_tax.freight_per = 0 
		LET l_rec_tax.hand_per = 0 
		LET l_rec_tax.uplift_per = 0 
		LET l_rec_tax.start_date = today 
	END IF 
	LET l_calc_desc_text = kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) 

	#huho
	#CALL fgl_winmessage("huho: this form IS missing G560\nis more complex but needs doing\nnot sure IF this code IS actually fully implemented","info")

	OPEN WINDOW g560 with FORM "G560" 
	CALL windecoration_g("G560") 


	DISPLAY l_calc_desc_text TO calc_desc_text 

	IF p_tax_code IS NOT NULL THEN 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.sell_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO sell_desc_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.sell_ctl_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO sell_ctl_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.sell_clr_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO sell_clr_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.sell_adj_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO sell_adj_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.sadj_ctl_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO sadj_ctl_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.buy_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO buy_desc_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.buy_ctl_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO buy_ctl_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.buy_clr_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO buy_clr_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.buy_adj_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO buy_adj_text 

		END IF 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_tax.badj_ctl_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = 0 THEN 
			DISPLAY l_rec_coa.desc_text TO badj_ctl_text 

		END IF 
	END IF 

	LET l_msgresp = kandoomsg("G",1504,"")	#1504 Enter Tax details; OK TO continue.
	INPUT BY NAME 
		l_rec_tax.tax_code, 
		l_rec_tax.desc_text, 
		l_rec_tax.calc_method_flag, 
		l_rec_tax.start_date, 
		l_rec_tax.sell_acct_code, 
		l_rec_tax.sell_ctl_acct_code, 
		l_rec_tax.sell_clr_acct_code, 
		l_rec_tax.sell_adj_acct_code, 
		l_rec_tax.sadj_ctl_acct_code, 
		l_rec_tax.buy_acct_code, 
		l_rec_tax.buy_ctl_acct_code, 
		l_rec_tax.buy_clr_acct_code, 
		l_rec_tax.buy_adj_acct_code, 
		l_rec_tax.badj_ctl_acct_code, 
		l_rec_tax.tax_per, 
		l_rec_tax.freight_per, 
		l_rec_tax.hand_per, 
		l_rec_tax.uplift_per WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GT1","inp-tax2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (calc_method_flag) 
			LET glob_temp_text = show_kandooword("tax.calc_method_flag") 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.calc_method_flag = glob_temp_text 
			END IF 
			NEXT FIELD calc_method_flag 

		ON ACTION "LOOKUP" infield (sell_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sell_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD sell_acct_code 

		ON ACTION "LOOKUP" infield (sell_ctl_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sell_ctl_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD sell_ctl_acct_code 

		ON ACTION "LOOKUP" infield (sell_clr_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sell_clr_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD sell_clr_acct_code 

		ON ACTION "LOOKUP" infield (sell_adj_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sell_adj_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD sell_adj_acct_code 

		ON ACTION "LOOKUP" infield (buy_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.buy_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD buy_acct_code 

		ON ACTION "LOOKUP" infield (buy_ctl_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.buy_ctl_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD buy_ctl_acct_code 

		ON ACTION "LOOKUP" infield (buy_clr_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.buy_clr_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD buy_clr_acct_code 

		ON ACTION "LOOKUP" infield (buy_adj_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.buy_adj_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD buy_adj_acct_code 

		ON ACTION "LOOKUP" infield (sadj_ctl_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.sadj_ctl_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD sadj_ctl_acct_code 

		ON ACTION "LOOKUP" infield (badj_ctl_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_tax.badj_ctl_acct_code = glob_temp_text 
			END IF 
			NEXT FIELD badj_ctl_acct_code 

		ON ACTION "LOOKUP" infield (start_date) 
			LET l_winds_text = showdate(l_rec_tax.start_date) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_tax.start_date = l_winds_text 
			END IF 
			NEXT FIELD start_date 

		BEFORE FIELD tax_code 
			IF p_tax_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD tax_code 
			IF l_rec_tax.tax_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"")			#9102 Value must be entered.
				NEXT FIELD tax_code 
			END IF 
			SELECT unique 1 FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = l_rec_tax.tax_code 
			IF status = 0 THEN 
				LET l_msgresp=kandoomsg("U",9104,"") 	#9104 RECORD already exists.
				LET l_rec_tax.tax_code = NULL 
				NEXT FIELD tax_code 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_tax.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered.
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD tax_per 
			IF l_rec_tax.tax_per IS NOT NULL THEN 
				IF l_rec_tax.tax_per < 0 THEN 
					LET l_msgresp = kandoomsg("G",9539,"")				#9539 " percentage must be greater than OR equal TO zero"
					NEXT FIELD tax_per 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
				LET l_rec_tax.tax_per = 0 
				NEXT FIELD tax_per 
			END IF 

		AFTER FIELD sell_acct_code 
			CLEAR sell_desc_text 
			IF l_rec_tax.sell_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.sell_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 		#9105 RECORD NOT found; Try Window.
					NEXT FIELD sell_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.sell_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD sell_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO sell_desc_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
				NEXT FIELD sell_acct_code 
			END IF 

		AFTER FIELD sell_ctl_acct_code 
			CLEAR sell_ctl_text 
			IF l_rec_tax.sell_ctl_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.sell_ctl_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 			#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD sell_ctl_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.sell_ctl_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD sell_ctl_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO sell_ctl_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD sell_ctl_acct_code 
			END IF 

		AFTER FIELD sell_clr_acct_code 
			CLEAR sell_clr_text 
			IF l_rec_tax.sell_clr_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.sell_clr_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 			#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD sell_clr_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.sell_clr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD sell_clr_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO sell_clr_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered.
				NEXT FIELD sell_clr_acct_code 
			END IF 

		AFTER FIELD sell_adj_acct_code 
			CLEAR sell_adj_text 
			IF l_rec_tax.sell_adj_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.sell_adj_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"")			#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD sell_adj_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.sell_adj_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD sell_adj_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO sell_adj_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 	#Acct code must be entered
				NEXT FIELD sell_adj_acct_code 
			END IF 

		AFTER FIELD sadj_ctl_acct_code 
			CLEAR sadj_ctl_text 
			IF l_rec_tax.sadj_ctl_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.sadj_ctl_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 			#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD sadj_ctl_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.sadj_ctl_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD sadj_ctl_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO sadj_ctl_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 		#Acct code must be entered
				NEXT FIELD sadj_ctl_acct_code 
			END IF 

		AFTER FIELD buy_acct_code 
			CLEAR buy_desc_text 
			IF l_rec_tax.buy_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
				NEXT FIELD buy_acct_code 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE acct_code = l_rec_tax.buy_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("U",9105,"") 			#9105 RECORD NOT found; Try Window.
				NEXT FIELD buy_acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.buy_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD buy_acct_code 
				END IF 
				DISPLAY l_rec_coa.desc_text TO buy_desc_text 

			END IF 

		AFTER FIELD buy_ctl_acct_code 
			CLEAR buy_ctl_text 
			IF l_rec_tax.buy_ctl_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.buy_ctl_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"")		#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD buy_ctl_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.buy_ctl_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD buy_ctl_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO buy_ctl_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"")		#Acct code must be entered
				NEXT FIELD buy_ctl_acct_code 
			END IF 

		AFTER FIELD buy_clr_acct_code 
			CLEAR buy_clr_text 
			IF l_rec_tax.buy_clr_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.buy_clr_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 	#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD buy_clr_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.buy_clr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD buy_clr_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO buy_clr_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"")#Acct code must be entered
				NEXT FIELD buy_clr_acct_code 
			END IF 

		AFTER FIELD buy_adj_acct_code 
			CLEAR buy_adj_text 
			IF l_rec_tax.buy_adj_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.buy_adj_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"")	#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD buy_adj_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.buy_adj_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD buy_adj_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO buy_adj_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") #Acct code must be entered
				NEXT FIELD buy_adj_acct_code 
			END IF 

		AFTER FIELD badj_ctl_acct_code 
			CLEAR badj_ctl_text 
			IF l_rec_tax.badj_ctl_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_tax.badj_ctl_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 	#9105 " Tax Account Code-Sell NOT found, try window"
					NEXT FIELD badj_ctl_acct_code 
				ELSE 
					IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_tax.badj_ctl_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD badj_ctl_acct_code 
					END IF 
					DISPLAY l_rec_coa.desc_text TO badj_ctl_text 

				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 	#Acct code must be entered
				NEXT FIELD badj_ctl_acct_code 
			END IF 

		BEFORE FIELD start_date 
			IF l_rec_tax.start_date IS NULL THEN 
				LET l_rec_tax.start_date = today 
			END IF 

		AFTER FIELD calc_method_flag 
			IF l_rec_tax.calc_method_flag <> l_save_method_flag AND 
			l_save_method_flag IS NOT NULL THEN 
				IF taxcode_used(l_rec_tax.tax_code) THEN 
					LET l_rec_tax.calc_method_flag = l_save_method_flag 
					NEXT FIELD calc_method_flag 
				END IF 
			END IF 
			LET l_calc_desc_text = 
			kandooword("tax.calc_method_flag",l_rec_tax.calc_method_flag) 
			DISPLAY l_calc_desc_text TO calc_desc_text 

		AFTER FIELD freight_per 
			IF l_rec_tax.freight_per IS NOT NULL THEN 
				IF l_rec_tax.freight_per < 0 THEN 
					LET l_msgresp = kandoomsg("G",9539,"")		#9539 " percentage must be greater than OR equal TO zero"
					NEXT FIELD freight_per 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
				LET l_rec_tax.freight_per = 0 
				NEXT FIELD freight_per 
			END IF 

		AFTER FIELD hand_per 
			IF l_rec_tax.hand_per IS NOT NULL THEN 
				IF l_rec_tax.hand_per < 0 THEN 
					LET l_msgresp = kandoomsg("G",9539,"")		#9539 " percentage must be greater than OR equal TO zero"
					NEXT FIELD hand_per 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
				LET l_rec_tax.hand_per = 0 
				NEXT FIELD hand_per 
			END IF 

		AFTER FIELD uplift_per 
			IF l_rec_tax.uplift_per IS NOT NULL THEN 
				IF l_rec_tax.uplift_per < 0 THEN 
					LET l_msgresp = kandoomsg("G",9539,"") 
					#9539 " percentage must be greater than OR equal TO zero"
					NEXT FIELD uplift_per 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",9102,"") 			#9102 Value must be entered.
				LET l_rec_tax.uplift_per = 0 
				NEXT FIELD uplift_per 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_tax.tax_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 			#9102 Value must be entered.
					NEXT FIELD tax_code 
				END IF 
				IF l_rec_tax.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")				#9102 Value must be entered.
					NEXT FIELD desc_text 
				END IF 
				IF l_rec_tax.sell_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")		#9102 Value must be entered.
					NEXT FIELD sell_acct_code 
				END IF 
				IF l_rec_tax.sell_ctl_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
					NEXT FIELD sell_ctl_acct_code 
				END IF 
				IF l_rec_tax.sell_clr_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")		#9102 Value must be entered.
					NEXT FIELD sell_clr_acct_code 
				END IF 
				IF l_rec_tax.sell_adj_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")			#9102 Value must be entered.
					NEXT FIELD sell_adj_acct_code 
				END IF 
				IF l_rec_tax.buy_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")		#9102 Value must be entered.
					NEXT FIELD buy_acct_code 
				END IF 
				IF l_rec_tax.buy_ctl_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered.
					NEXT FIELD buy_ctl_acct_code 
				END IF 
				IF l_rec_tax.buy_clr_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
					NEXT FIELD buy_clr_acct_code 
				END IF 
				IF l_rec_tax.buy_adj_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"")	#9102 Value must be entered.
					NEXT FIELD buy_adj_acct_code 
				END IF 
				IF l_rec_tax.sadj_ctl_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
					NEXT FIELD sadj_ctl_acct_code 
				END IF 
				IF l_rec_tax.badj_ctl_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 	#9102 Value must be entered.
					NEXT FIELD badj_ctl_acct_code 
				END IF 
				IF l_rec_tax.freight_per IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
					LET l_rec_tax.freight_per = 0 
					NEXT FIELD freight_per 
				END IF 
				IF l_rec_tax.hand_per IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 			#9102 Value must be entered.
					LET l_rec_tax.hand_per = 0 
					NEXT FIELD hand_per 
				END IF 
				IF l_rec_tax.uplift_per IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 		#9102 Value must be entered.
					LET l_rec_tax.uplift_per = 0 
					NEXT FIELD uplift_per 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW g560 
		RETURN false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message,status) = "N" THEN 
			CLOSE WINDOW g560 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 

			IF p_tax_code IS NULL THEN 
				SELECT unique 1 FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_tax.tax_code 
				IF status = 0 THEN 
					LET l_msgresp=kandoomsg("U",9104,"") 				#9104 RECORD already exists.
					LET l_sqlerrd = 0 
				ELSE 
					LET l_err_message = "GT1 - Inserting Tax Record" 
					LET l_rec_tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
					INSERT INTO tax VALUES (l_rec_tax.*) 
					LET l_sqlerrd = sqlca.sqlerrd[6] 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("U",1005,"") 			#1005 Updating database; Please wait.
				LET l_err_message = "GT1 - Locking Tax Record" 
				DECLARE c_tax1 CURSOR FOR 
				SELECT * FROM tax 
				WHERE tax_code = l_rec_tax.tax_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				OPEN c_tax1 
				FETCH c_tax1 
				UPDATE tax 
				SET * = l_rec_tax.* 
				WHERE tax_code = l_rec_tax.tax_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_sqlerrd = sqlca.sqlerrd[3] 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
	CLOSE WINDOW g560 

	RETURN l_sqlerrd 
END FUNCTION 
##############################################################################
# FUNCTION edit_tax(p_tax_code)
#
# Edit AND create new
#
# Note: FUNCTION edit_tax(p_tax_code) IS also defined in AZ1.4gl HuHo
##############################################################################


############################################################
# FUNCTION taxcode_used(p_tax_code)
#
#
############################################################
FUNCTION taxcode_used(p_tax_code) 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",1505,"")# Checking Tax usage. Please Wait..
	DECLARE c_cust CURSOR FOR 
	SELECT * FROM customer 
	WHERE tax_code = p_tax_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN c_cust 
	FETCH c_cust 

	IF status = 0 THEN 
		LET l_msgresp = kandoomsg("G",9540,"Customer") 	#Tax code already used in master table ??? No changes allowed
		RETURN true 
	END IF 

	DECLARE c_invoicehead CURSOR FOR 
	SELECT h.inv_num FROM invoicehead h,invoicedetl d 
	WHERE (h.tax_code = p_tax_code OR 
	d.tax_code = p_tax_code) 
	AND h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.posted_flag = "N" 
	AND d.cmpy_code = h.cmpy_code 
	AND d.inv_num = h.inv_num 
	OPEN c_invoicehead 
	FETCH c_invoicehead 

	IF status = 0 THEN 
		LET l_msgresp = kandoomsg("G",9540,"Invoicehead/Invoicedetl")	#Tax code already used in master table ??? No changes allowed
		RETURN true 
	END IF 

	DECLARE c_credithead CURSOR FOR 
	SELECT h.cred_num FROM credithead h,creditdetl d 
	WHERE (h.tax_code = p_tax_code OR 
	d.tax_code = p_tax_code) 
	AND h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.posted_flag = "N" 
	AND d.cmpy_code = h.cmpy_code 
	AND d.cred_num = h.cred_num 
	OPEN c_credithead 
	FETCH c_credithead 

	IF status = 0 THEN 
		LET l_msgresp = kandoomsg("G",9540,"Credithead/Creditdetl")	#Tax code already used in master table ??? No changes allowed
		RETURN true 
	END IF 

	IF glob_rec_company.module_text[9] = "I" THEN 
		DECLARE c_prodstatus CURSOR FOR 
		SELECT * FROM prodstatus 
		WHERE sales_tax_code = p_tax_code 
		OR purch_tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c_prodstatus 
		FETCH c_prodstatus 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"Prodstatus") 		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[16] = "P" THEN 
		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c_vendor 
		FETCH c_vendor 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"Vendor") 		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
		DECLARE c_contractor CURSOR FOR 
		SELECT * FROM contractor 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c_contractor 
		FETCH c_contractor 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"Contractor")		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 

		DECLARE c_voucher CURSOR FOR 
		SELECT * FROM voucher 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_flag = "N" 
		OPEN c_voucher 
		FETCH c_voucher 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"Voucher")			#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 

		DECLARE c_cheque CURSOR FOR 
		SELECT * FROM cheque 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_flag = "N" 
		OPEN c_cheque 
		FETCH c_cheque 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"cheque")		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 

		DECLARE c_debithead CURSOR FOR 
		SELECT * FROM debithead 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND post_flag = "N" 
		OPEN c_debithead 
		FETCH c_debithead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"debithead")			#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[14] = "N" THEN 
		DECLARE c_reqhead CURSOR FOR 
		SELECT * FROM reqhead 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND status_ind <> "9" 
		OPEN c_reqhead 
		FETCH c_reqhead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"reqhead") 		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[18] = "R" THEN 
		DECLARE c_purchhead CURSOR FOR 
		SELECT * FROM purchhead 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND status_ind NOT in ("C","R") 
		OPEN c_purchhead 
		FETCH c_purchhead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"purchhead")	#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 
	IF glob_rec_company.module_text[5] = "E" THEN 
		DECLARE c_orderhead CURSOR FOR 
		SELECT * FROM orderhead 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND status_ind NOT in ("C","R") 
		OPEN c_orderhead 
		FETCH c_orderhead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"orderhead")		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
		DECLARE c_orderdetl CURSOR FOR 
		SELECT * FROM orderdetl 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_qty <> order_qty 
		OPEN c_orderdetl 
		FETCH c_orderdetl 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"orderdetl")	#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 
	IF glob_rec_company.module_text[17] = "Q" THEN 
		DECLARE c_quotehead CURSOR FOR 
		SELECT h.order_num FROM quotehead h,quotedetl d 
		WHERE (h.tax_code = p_tax_code OR 
		d.tax_code = p_tax_code) 
		AND h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.status_ind <> "C" 
		AND d.cmpy_code = h.cmpy_code 
		AND d.order_num = h.order_num 
		OPEN c_quotehead 
		FETCH c_quotehead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"quotehead/quotedetl")		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[23] = "W" THEN 
		DECLARE c_ordhead CURSOR FOR 
		SELECT * FROM ordhead 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND status_ind <> "C" 
		OPEN c_ordhead 
		FETCH c_ordhead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"ordhead") 	#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 

		DECLARE c_orderline CURSOR FOR 
		SELECT * FROM orderline 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_qty <> order_qty 
		OPEN c_orderline 
		FETCH c_orderline 

		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"orderline") 	#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 

		DECLARE c_ordquote CURSOR FOR 
		SELECT * FROM ordquote 
		WHERE tax_code = p_tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND status_ind NOT in ("C","R") 
		OPEN c_ordquote 
		FETCH c_ordquote 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"ordquote") 		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[12] = "S" THEN 
		DECLARE c_shiphead CURSOR FOR 
		SELECT h.ship_code FROM shiphead h,shipdetl d 
		WHERE (h.tax_code = p_tax_code OR 
		d.tax_code = p_tax_code) 
		AND h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.finalised_flag <> "Y" 
		AND d.cmpy_code = h.cmpy_code 
		AND d.ship_code = h.ship_code 
		OPEN c_shiphead 
		FETCH c_shiphead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"shiphead/shipdetl")			#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	IF glob_rec_company.module_text[19] = "S" THEN 
		DECLARE c_postranhead CURSOR FOR 
		SELECT h.tran_num FROM postranhead h,postrandetl d 
		WHERE (h.tax_code = p_tax_code OR 
		d.tax_code = p_tax_code) 
		AND h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND h.posted_flag = "N" 
		AND d.cmpy_code = h.cmpy_code 
		AND d.tran_num = h.tran_num 
		OPEN c_postranhead 
		FETCH c_postranhead 
		IF status = 0 THEN 
			LET l_msgresp = kandoomsg("G",9540,"postranhead/postrandetl")		#Tax code already used in master table ??? No changes allowed
			RETURN true 
		END IF 
	END IF 

	RETURN false 
END FUNCTION 
############################################################
# END FUNCTION taxcode_used(p_tax_code)
############################################################