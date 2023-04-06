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
#This file IS used as GLOBALS FROM U12a.4gl, AND Informix AND Querix don't like
#nestiong of GLOBALS files...
#######################################################################
# GLOBAL Scope Variables
#######################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/U12_GLOBALS.4gl" 

#######################################################################
# MAIN
#
# Purpose - kandoouser Table Maintainence Program
#           Adds,Deletes AND Maintains kandoousers
#
#######################################################################
MAIN 
	DEFINE l_msg_str STRING 
	
	CALL setModuleId("U12") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 
	{
	#This module must only be used by Administrators with MAX / Z security level
		IF glob_rec_kandoouser.user_role_code != "A" THEN
			LET l_msg_str = "Permission Denied! Contact your Kandoo Administrator\n\nYour user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has the got user role ", trim(glob_rec_kandoouser.user_role_code), " which is insufficient to operate this module!"
			CALL fgl_winmessage("Insufficient rights",l_msg_str,"ERROR")
			EXIT PROGRAM
		END IF

		IF glob_rec_kandoouser.security_ind != "Z" THEN
			LET l_msg_str = "Your user account ", trim(glob_rec_kandoouser.sign_on_code),"/", trim(glob_rec_kandoouser.name_text), " has got the security level ", trim(glob_rec_kandoouser.security_ind), " which is insufficient to operate this module!"
			CALL fgl_winmessage("Insufficient rights",l_msg_str,"ERROR")
			EXIT PROGRAM
		END IF
	}

	OPEN WINDOW U121 with FORM "U121" 
	CALL windecoration_u("U121") 

	CALL scan_user() 

	CLOSE WINDOW U121 
END MAIN 
#######################################################################
# MAIN
#######################################################################


#######################################################################
# FUNCTION select_user()
#
#
#######################################################################
FUNCTION select_user(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_kandoouser DYNAMIC ARRAY OF t_rec_kandoouser_sc_nt_si_am 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN 
		CLEAR FORM 

		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			sign_on_code, 
			name_text, 
			acct_mask_code, 
			security_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U12","construct-kandoouser") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM kandoouser ", 
		"WHERE ", l_where_text clipped, " ", 
		"ORDER BY sign_on_code" 

	PREPARE s_rec_kandoouser FROM l_query_text 
	DECLARE c_rec_kandoouser CURSOR FOR s_rec_kandoouser 

	LET l_idx = 0 
	FOREACH c_rec_kandoouser INTO l_rec_kandoouser.* 
		LET l_idx = l_idx + 1 
		#LET glob_arr_rec_kandoouser[l_idx].scroll_flag = NULL
		LET l_arr_rec_kandoouser[l_idx].sign_on_code = l_rec_kandoouser.sign_on_code 
		LET l_arr_rec_kandoouser[l_idx].name_text = l_rec_kandoouser.name_text 
		LET l_arr_rec_kandoouser[l_idx].security_ind = l_rec_kandoouser.security_ind 
		LET l_arr_rec_kandoouser[l_idx].acct_mask_code = l_rec_kandoouser.acct_mask_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) 

	RETURN l_arr_rec_kandoouser 
END FUNCTION 
#######################################################################
# END FUNCTION select_user()
#######################################################################


#######################################################################
# FUNCTION scan_user()
#
#
#######################################################################
FUNCTION scan_user() 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CALL select_user(false) RETURNING glob_arr_rec_kandoouser 

	LET glob_idx = glob_arr_rec_kandoouser.getlength() 
	LET l_del_cnt = 0 

	MESSAGE kandoomsg2("U",9113,glob_idx) 

	MESSAGE kandoomsg2("U",1003,"") 
	DISPLAY ARRAY glob_arr_rec_kandoouser TO sr_rec_kandoouser.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY #input 
			CALL publish_toolbar("kandoo","U12","input-arr-kandoouser") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL glob_arr_rec_kandoouser.clear()
			CALL select_user(TRUE) RETURNING glob_arr_rec_kandoouser 

		ON ACTION "REFRESH"
			CALL windecoration_u("U121")  
			CALL glob_arr_rec_kandoouser.clear()
			CALL select_user(FALSE) RETURNING glob_arr_rec_kandoouser 


		ON ACTION "User Location" 
			CALL scan_userlocn(glob_rec_kandoouser_specific.*) #? 

		ON ACTION ("EDIT","ACCEPT") 
			IF glob_rec_kandoouser_specific.sign_on_code IS NOT NULL THEN 
				CALL change_menu() 
				LET glob_arr_rec_kandoouser[glob_idx].sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
				LET glob_arr_rec_kandoouser[glob_idx].name_text = glob_rec_kandoouser_specific.name_text 
				LET glob_arr_rec_kandoouser[glob_idx].security_ind = glob_rec_kandoouser_specific.security_ind 
				LET glob_arr_rec_kandoouser[glob_idx].acct_mask_code = glob_rec_kandoouser_specific.acct_mask_code 
			END IF 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			LET glob_rec_kandoouser_specific.sign_on_code = glob_arr_rec_kandoouser[glob_idx].sign_on_code 
			LET glob_rec_kandoouser_specific.name_text = glob_arr_rec_kandoouser[glob_idx].name_text 
			LET glob_rec_kandoouser_specific.security_ind = glob_arr_rec_kandoouser[glob_idx].security_ind 
			LET glob_rec_kandoouser_specific.acct_mask_code = glob_arr_rec_kandoouser[glob_idx].acct_mask_code 

			#         IF glob_idx > arr_count()
			#         AND NOT delete_flag THEN
			#            ERROR kandoomsg2("U",9001,"")
			#         END IF
			#LET delete_flag = FALSE
			#DISPLAY glob_arr_rec_kandoouser[glob_idx].* TO sr_rec_kandoouser[scrn].*

			#      BEFORE FIELD scroll_flag
			#         LET l_scroll_flag = glob_arr_rec_kandoouser[glob_idx].scroll_flag
			#         #DISPLAY glob_arr_rec_kandoouser[glob_idx].* TO sr_rec_kandoouser[scrn].*

			#      AFTER FIELD scroll_flag
			#         LET glob_arr_rec_kandoouser[glob_idx].scroll_flag = l_scroll_flag
			#         #DISPLAY glob_arr_rec_kandoouser[glob_idx].* TO sr_rec_kandoouser[scrn].*
			#
			#         IF fgl_lastkey() = fgl_keyval("nextpage") THEN
			#            IF glob_arr_rec_kandoouser[glob_idx+14].sign_on_code IS NULL THEN
			#               ERROR kandoomsg2("U",9001,"")
			#               #9001 No more rows in this direction
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF glob_arr_rec_kandoouser[glob_idx+1].sign_on_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("U",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

--		AFTER ROW 
--			LET glob_arr_rec_rec_kandoouser[glob_idx].sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
--			LET glob_arr_rec_rec_kandoouser[glob_idx].name_text = glob_rec_kandoouser_specific.name_text 
--			LET glob_arr_rec_rec_kandoouser[glob_idx].security_ind = glob_rec_kandoouser_specific.security_ind 
--			LET glob_arr_rec_rec_kandoouser[glob_idx].acct_mask_code = glob_rec_kandoouser_specific.acct_mask_code 
			#DISPLAY glob_arr_rec_rec_kandoouser[glob_idx].* TO sr_rec_kandoouser[scrn].*

			#      BEFORE FIELD sign_on_code
			#         IF glob_rec_kandoouser_specific.sign_on_code IS NOT NULL THEN
			#            CALL change_menu()
			#            LET glob_arr_rec_kandoouser[glob_idx].sign_on_code = glob_rec_kandoouser_specific.sign_on_code
			#            LET glob_arr_rec_kandoouser[glob_idx].name_text = glob_rec_kandoouser_specific.name_text
			#            LET glob_arr_rec_kandoouser[glob_idx].security_ind = glob_rec_kandoouser_specific.security_ind
			#            LET glob_arr_rec_kandoouser[glob_idx].acct_mask_code = glob_rec_kandoouser_specific.acct_mask_code
			#            #DISPLAY glob_arr_rec_kandoouser[glob_idx].* TO sr_rec_kandoouser[scrn].*
			#
			#            OPTIONS INSERT KEY F1,
			#                    DELETE KEY F36
			#         END IF
			#         NEXT FIELD scroll_flag



		ON ACTION "DELETE" 			#ON KEY(F2)  --huho delete user ? 
 			IF kandoomsg("U",8000,l_del_cnt)  = "Y" THEN 			#8000 Confirm TO Delete ",l_del_cnt," rows? (Y/N)" 
				MESSAGE kandoomsg2("U",1005,"")	#1005 Updating database; Please wait.
				CALL delete_user(glob_arr_rec_kandoouser[glob_idx].sign_on_code) 
				CALL select_user(false) RETURNING glob_arr_rec_kandoouser
			END IF 



			#         IF glob_arr_rec_kandoouser[glob_idx].scroll_flag IS NULL THEN
			#            LET glob_arr_rec_kandoouser[glob_idx].scroll_flag = "*"
			#            LET l_del_cnt = l_del_cnt + 1
			#         ELSE
			#            LET glob_arr_rec_kandoouser[glob_idx].scroll_flag = NULL
			#            LET l_del_cnt = l_del_cnt - 1
			#         END IF
			#         NEXT FIELD scroll_flag

		ON ACTION "New" 
			#BEFORE INSERT
			#  IF glob_idx < arr_count()
			#  OR (glob_idx = arr_count()
			#      AND glob_rec_kandoouser_specific.sign_on_code IS NOT NULL) THEN
			--IF glob_rec_kandoouser_specific.sign_on_code IS NOT NULL THEN 
				CALL add_user() 
				# LET glob_arr_rec_rec_kandoouser[glob_idx].scroll_flag = NULL
				CALL select_user(false) RETURNING glob_arr_rec_kandoouser
			--	LET glob_arr_rec_rec_kandoouser[glob_idx].sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
			--	LET glob_arr_rec_rec_kandoouser[glob_idx].name_text = glob_rec_kandoouser_specific.name_text 
			--	LET glob_arr_rec_rec_kandoouser[glob_idx].security_ind = glob_rec_kandoouser_specific.security_ind 
			--	LET glob_arr_rec_rec_kandoouser[glob_idx].acct_mask_code = glob_rec_kandoouser_specific.acct_mask_code 
			--	OPTIONS INSERT KEY f1, 
			--	DELETE KEY f36 
			--END IF 

			#NEXT FIELD scroll_flag

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY #input 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#   ELSE
		#      IF l_del_cnt > 0 THEN
		#         ERROR kandoomsg2("U",8000,l_del_cnt)
		#         #8000 Confirm TO Delete ",l_del_cnt," rows? (Y/N)"
		#         IF l_msgresp = "Y" THEN
		#            MESSAGE kandoomsg2("U",1005,"")
		#            #1005 Updating database; Please wait.
		#            FOR glob_idx = 1 TO arr_count()
		#               IF glob_arr_rec_kandoouser[glob_idx].scroll_flag = "*" THEN
		#                  CALL delete_user(glob_arr_rec_kandoouser[glob_idx].sign_on_code)
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION scan_user()
#######################################################################


#######################################################################
# FUNCTION change_limits(p_cmpy_code)
#
#
#######################################################################
FUNCTION change_limits(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_userlimits RECORD LIKE userlimits.* 
	#DEFINE l_rec_company RECORD LIKE company.* #not used
	DEFINE l_ins_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	INITIALIZE l_rec_userlimits.* TO NULL 
	LET l_ins_flag = 0 

	OPEN WINDOW U154 with FORM "U154" 
	CALL windecoration_u("U154") 

	MESSAGE kandoomsg2("U",1109,"")	#1109 Enter limits; OK TO Continue.
	SELECT * INTO l_rec_userlimits.* FROM userlimits 
	WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	AND cmpy_code = p_cmpy_code 

	IF status = notfound THEN 
		LET l_ins_flag = 1 
		LET l_rec_userlimits.sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
		LET l_rec_userlimits.cmpy_code = p_cmpy_code 
		LET l_rec_userlimits.price_high_per = 0 
		LET l_rec_userlimits.price_low_per = 0 
		LET l_rec_userlimits.cart_high_per = 0 
		LET l_rec_userlimits.cart_low_per = 0 
		LET l_rec_userlimits.other_high_per = 0 
		LET l_rec_userlimits.other_low_per = 0 
	END IF 

	DISPLAY BY NAME l_rec_userlimits.cmpy_code 

	INPUT BY NAME l_rec_userlimits.price_high_per, 
	l_rec_userlimits.price_low_per, 
	l_rec_userlimits.cart_high_per, 
	l_rec_userlimits.cart_low_per, 
	l_rec_userlimits.other_high_per, 
	l_rec_userlimits.other_low_per, 
	l_rec_userlimits.price_auth_ind WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12","input-userlimits") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD price_high_per 
			IF l_rec_userlimits.price_high_per < 0 THEN 
				LET l_rec_userlimits.price_high_per = 0 
				ERROR kandoomsg2("W",9180,"") 			#9180 Percentage should NOT be less than 0
				NEXT FIELD price_high_per 
			END IF 
			IF l_rec_userlimits.price_high_per IS NULL THEN 
				LET l_rec_userlimits.price_high_per = 0 
			END IF 

		AFTER FIELD price_low_per 
			IF l_rec_userlimits.price_low_per < 0 THEN 
				LET l_rec_userlimits.price_low_per = 0 
				ERROR kandoomsg2("W",9180,"") 	#9180 Percentage should NOT be less than 0
				NEXT FIELD price_low_per 
			END IF 
			IF l_rec_userlimits.price_low_per IS NULL THEN 
				LET l_rec_userlimits.price_low_per = 0 
			END IF 

		AFTER FIELD cart_high_per 
			IF l_rec_userlimits.cart_high_per < 0 THEN 
				LET l_rec_userlimits.cart_high_per = 0 
				ERROR kandoomsg2("W",9180,"")	#9180 Percentage should NOT be less than 0
				NEXT FIELD cart_high_per 
			END IF 
			IF l_rec_userlimits.cart_high_per IS NULL THEN 
				LET l_rec_userlimits.cart_high_per = 0 
			END IF 

		AFTER FIELD cart_low_per 
			IF l_rec_userlimits.cart_low_per < 0 THEN 
				LET l_rec_userlimits.cart_low_per = 0 
				ERROR kandoomsg2("W",9180,"") 			#9180 Percentage should NOT be less than 0
				NEXT FIELD cart_low_per 
			END IF 

			IF l_rec_userlimits.cart_low_per IS NULL THEN 
				LET l_rec_userlimits.cart_low_per = 0 
			END IF 

		AFTER FIELD other_high_per 
			IF l_rec_userlimits.other_high_per < 0 THEN 
				LET l_rec_userlimits.other_high_per = 0 
				ERROR kandoomsg2("W",9180,"") 			#9180 Percentage should NOT be less than 0
				NEXT FIELD other_high_per 
			END IF 
			IF l_rec_userlimits.other_high_per IS NULL THEN 
				LET l_rec_userlimits.other_high_per = 0 
			END IF 

		AFTER FIELD other_low_per 
			IF l_rec_userlimits.other_low_per < 0 THEN 
				LET l_rec_userlimits.other_low_per = 0 
				ERROR kandoomsg2("W",9180,"") 			#9180 Percentage should NOT be less than 0
				NEXT FIELD other_low_per 
			END IF 

			IF l_rec_userlimits.other_low_per IS NULL THEN 
				LET l_rec_userlimits.other_low_per = 0 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW u154 
	ELSE 
		IF l_ins_flag = 1 THEN 
			INSERT INTO userlimits VALUES (l_rec_userlimits.*) 
		ELSE 
			UPDATE userlimits 
			SET * = l_rec_userlimits.* 
			WHERE sign_on_code = l_rec_userlimits.sign_on_code 
			AND cmpy_code = l_rec_userlimits.cmpy_code 
		END IF 

		CLOSE WINDOW u154 
	END IF 

END FUNCTION 
#######################################################################
# END FUNCTION change_limits(p_cmpy_code)
#######################################################################


#######################################################################
# FUNCTION scan_userlocn()
#
#
#######################################################################
FUNCTION scan_userlocn(p_rec_kandoouser_specific) 
	DEFINE p_rec_kandoouser_specific RECORD LIKE kandoouser.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_rec_location RECORD LIKE location.* 
	DEFINE l_rec_kandoousercmpy RECORD LIKE kandoousercmpy.* 
	DEFINE l_arr_rec_userlocn DYNAMIC ARRAY OF t_rec_userlocn_cc_lc_dt_with_scrollflag 
	#	DEFINE l_arr_rec_userlocn array[100] OF
	#		RECORD
	#			scroll_flag CHAR(1),
	#			cmpy_code LIKE userlocn.cmpy_code,
	#			locn_code LIKE userlocn.locn_code,
	#			desc_text LIKE location.desc_text
	#		END RECORD
	DEFINE l_scroll_flag CHAR(1) 
	#DEFINE l_i SMALLINT    #not used
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_winds_text STRING 
--	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW U155 with FORM "U155" 
	CALL windecoration_u("U155") 

	#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER"
	#DISPLAY "see common/collwind.4gl"
	#HuHO ... there is much more wrong and missing than the reported OUTER problem...
	#.. this makes me cry
	#EXIT PROGRAM (1)

	DECLARE c_userlocn CURSOR FOR 
	SELECT 
		kandoousercmpy.cmpy_code, 
		kandoousercmpy.sign_on_code, 
		userlocn.locn_code 
		#--DISABLED      FROM kandoousercmpy, outer userlocn
		#@huho enabled it again
	FROM kandoousercmpy, userlocn 
		#WHERE kandoousercmpy.sign_on_code = glob_rec_kandoouser_specific.sign_on_code
	WHERE kandoousercmpy.sign_on_code = p_rec_kandoouser_specific.sign_on_code #glob_rec_kandoouser.sign_on_code 
	AND userlocn.cmpy_code = kandoousercmpy.cmpy_code #join 
	AND userlocn.sign_on_code = p_rec_kandoouser_specific.sign_on_code #glob_rec_kandoouser.sign_on_code 

	LET l_idx = 0 
	FOREACH c_userlocn INTO l_rec_userlocn.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_userlocn[l_idx].locn_code = l_rec_userlocn.locn_code 
		LET l_arr_rec_userlocn[l_idx].cmpy_code = l_rec_userlocn.cmpy_code 

		SELECT desc_text INTO l_arr_rec_userlocn[l_idx].desc_text FROM location 
		WHERE locn_code = l_rec_userlocn.locn_code 
		AND cmpy_code = l_rec_userlocn.cmpy_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_arr_rec_userlocn.getLength()) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("U",1518,"")	#" F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_userlocn WITHOUT DEFAULTS FROM sr_userlocn.* attribute(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12","input-arr-userlocn") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		BEFORE INSERT 
			INITIALIZE l_rec_userlocn.* TO NULL 
			INITIALIZE l_arr_rec_userlocn[l_idx].* TO NULL 
			NEXT FIELD cmpy_code --locn_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_userlocn[l_idx].scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_userlocn[l_idx].scroll_flag = l_scroll_flag 
			LET l_rec_userlocn.cmpy_code = l_arr_rec_userlocn[l_idx].cmpy_code 
			LET l_rec_userlocn.sign_on_code = p_rec_kandoouser_specific.sign_on_code 
			LET l_rec_userlocn.locn_code = l_arr_rec_userlocn[l_idx].locn_code 

			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_userlocn[l_idx+1].cmpy_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("W",9001,"")
			#
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("nextpage") THEN
			#            IF l_arr_rec_userlocn[l_idx+7].cmpy_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("W",9001,"")
			#
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		BEFORE FIELD locn_code 
			CALL comboList_location_cmpy("locn_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL, l_arr_rec_userlocn[l_idx].cmpy_code,COMBO_NULL_SPACE) 
			#   DISPLAY l_arr_rec_userlocn[l_idx].* TO sr_userlocn[scrn].*

		AFTER FIELD locn_code 
			CASE 
				WHEN get_is_screen_navigation_forward()
					--fgl_lastkey() = fgl_keyval("accept") 
					--OR fgl_lastkey() = fgl_keyval("RETURN") 
					--OR fgl_lastkey() = fgl_keyval("tab") 
					--OR fgl_lastkey() = fgl_keyval("right") 
					--OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_userlocn[l_idx].locn_code IS NOT NULL THEN 
						SELECT * INTO l_rec_location.* FROM location 
						WHERE locn_code = l_arr_rec_userlocn[l_idx].locn_code 
						AND cmpy_code = l_arr_rec_userlocn[l_idx].cmpy_code 

						IF status = notfound THEN 
							ERROR kandoomsg2("W",9144,"") 						#9144 A location NOT found - Try window
							NEXT FIELD locn_code 
						ELSE 
							LET l_arr_rec_userlocn[l_idx].desc_text = l_rec_location.desc_text 
						END IF 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							NEXT FIELD scroll_flag 
						--ELSE 
						--	NEXT FIELD scroll_flag 
						END IF 
					END IF 
				--WHEN NOT get_is_screen_navigation_forward()
					--fgl_lastkey() = fgl_keyval("left") 
					--OR fgl_lastkey() = fgl_keyval("up") 
					--
					--NEXT FIELD previous 
				--OTHERWISE 
				--	NEXT FIELD locn_code 
			END CASE 

		ON ACTION "LOOKUP" infield (locn_code) 
			LET l_winds_text = show_user_loc(l_arr_rec_userlocn[l_idx].cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_arr_rec_userlocn[l_idx].locn_code = l_winds_text clipped 
				#DISPLAY l_arr_rec_userlocn[l_idx].locn_code TO
				#  sr_userlocn[scrn].locn_code

			END IF 
			#NEXT FIELD locn_code


			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

		ON KEY (F2) infield (scroll_flag) 
			IF l_arr_rec_userlocn[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_userlocn[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_userlocn[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		#delete all user locations for this user
		DELETE FROM userlocn 
		WHERE sign_on_code = p_rec_kandoouser_specific.sign_on_code 

		FOR l_idx = 1 TO l_arr_rec_userlocn.getlength() #arr_count() 
			IF l_arr_rec_userlocn[l_idx].locn_code IS NOT NULL THEN 
				LET l_rec_userlocn.cmpy_code = l_arr_rec_userlocn[l_idx].cmpy_code 
				LET l_rec_userlocn.locn_code = l_arr_rec_userlocn[l_idx].locn_code 
				LET l_rec_userlocn.sign_on_code = p_rec_kandoouser_specific.sign_on_code 
				INSERT INTO userlocn VALUES (l_rec_userlocn.*) 
			END IF 
		END FOR 
		#insert all user locations from program array to DB	
		IF l_del_cnt > 0 THEN 
			IF kandoomsg("W",8013,l_del_cnt)  = "Y" THEN #8013 Confirm TO Delete ",l_del_cnt," User Location(s)? (Y/N)"
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_userlocn[l_idx].scroll_flag = "*" THEN 
						DELETE FROM userlocn 
						WHERE locn_code = l_arr_rec_userlocn[l_idx].locn_code 
						AND cmpy_code = l_arr_rec_userlocn[l_idx].cmpy_code 
						AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

	CLOSE WINDOW U155 
END FUNCTION 
#######################################################################
# END FUNCTION scan_userlocn()
#######################################################################


#######################################################################
# FUNCTION add_user()
#
#
#######################################################################
FUNCTION add_user() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	OPEN WINDOW U101 with FORM "U101" 
	CALL windecoration_u("U101") 

	IF glob_rec_kandoouser.sign_on_code = "admin" THEN
		#list all companies to select from...
		OPEN WINDOW w_company_selection WITH FORM "U111_CompanySelection"
		CALL windecoration_u("U111")
		 
			INPUT l_cmpy_code WITHOUT DEFAULTS FROM company.cmpy_code
				AFTER INPUT
					IF l_cmpy_code IS NULL THEN
						ERROR "You need to specify a company"

						IF int_flag THEN
							CALL fgl_winmessage("Info","User Acccount creation process canceled!\nExit Program","INFO")
							EXIT PROGRAM
						END IF

						CONTINUE INPUT

					END IF
			END INPUT 
			
			IF int_flag THEN
				CALL fgl_winmessage("Info","User Acccount creation process canceled!\nExit Program","INFO")
				EXIT PROGRAM
			END IF
		CLOSE WINDOW w_company_selection
	ELSE
		LET l_cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF
	
	MESSAGE kandoomsg2("U", 1053, "")	#1053 Enter User Details; OK TO Continue
	LET glob_rec_kandoouser_specific.sign_on_code = NULL 
	LET glob_rec_kandoouser_specific.name_text = NULL 
	LET glob_rec_kandoouser_specific.security_ind = "9" 
	LET glob_rec_kandoouser_specific.password_text = NULL 
	LET glob_rec_kandoouser_specific.cmpy_code = l_cmpy_code
	LET glob_rec_kandoouser_specific.profile_code = "MAX" 
	LET glob_rec_kandoouser_specific.language_code = "ENG" 
	LET glob_rec_kandoouser_specific.access_ind = "1" 
	LET glob_rec_kandoouser_specific.print_text = NULL 
	LET glob_rec_kandoouser_specific.acct_mask_code = NULL 
	LET glob_rec_userlocn.locn_code = NULL 
	LET glob_rec_kandoouser_specific.sign_on_date = NULL 
	LET glob_rec_kandoouser_specific.passwd_ind = "1" 
	LET glob_rec_kandoouser_specific.signature_text = NULL 
	LET glob_rec_kandoouser_specific.group_code = NULL 
	LET glob_rec_kandoouser_specific.memo_pri_ind = "1" 
	LET glob_rec_kandoouser_specific.email = NULL 

	LET glob_rec_kandoouser_specific.user_role_code = "U" 
	LET glob_rec_kandoouser_specific.menu_group_code = "1" 
	LET glob_rec_kandoouser_specific.cheque_group_code = "1" 
	LET glob_rec_kandoouser_specific.pwchdate = NULL 
	LET glob_rec_kandoouser_specific.pwchange = 0 --user IS NOT forced TO change password 

	SELECT * INTO glob_rec_specific_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 

	SELECT * INTO glob_rec_kandooprofile.* FROM kandooprofile 
	WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
	AND profile_code = glob_rec_kandoouser_specific.profile_code 

	SELECT * INTO glob_rec_specific_language.* FROM language 
	WHERE language_code = glob_rec_kandoouser_specific.language_code 

	SELECT * INTO glob_rec_userlocn.* FROM userlocn 
	WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	AND cmpy_code = glob_rec_kandoouser_specific.cmpy_code
	 
	DISPLAY glob_rec_specific_company.name_text	TO company.name_text 

	DISPLAY BY NAME 
		glob_rec_kandooprofile.profile_text, 
		glob_rec_specific_language.language_text 

	INPUT BY NAME 
		glob_rec_kandoouser_specific.sign_on_code, 
		glob_rec_kandoouser_specific.login_name, 
		glob_rec_kandoouser_specific.name_text, 
		glob_rec_kandoouser_specific.security_ind, 
		glob_rec_kandoouser_specific.passwd_ind, 
		glob_rec_kandoouser_specific.password_text, 
		glob_rec_kandoouser_specific.group_code, 
		glob_rec_kandoouser_specific.signature_text, 
		glob_rec_kandoouser_specific.cmpy_code, 
		glob_rec_kandoouser_specific.profile_code, 
		glob_rec_kandoouser_specific.language_code, 
		glob_rec_kandoouser_specific.memo_pri_ind, 
		glob_rec_kandoouser_specific.access_ind, 
		glob_rec_kandoouser_specific.print_text, 
		glob_rec_kandoouser_specific.acct_mask_code, 
		glob_rec_kandoouser_specific.email, 
		glob_rec_kandoouser_specific.user_role_code, 
		glob_rec_kandoouser_specific.cheque_group_code	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12","input-kandoouser-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD sign_on_code 
			IF glob_rec_kandoouser_specific.sign_on_code IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
			END IF
			 
			SELECT count(*) INTO glob_cnt FROM kandoouser 
			WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
			IF glob_cnt != 0 THEN 
				ERROR kandoomsg2("U",9104,"") 			#9104 Already exists
				NEXT FIELD sign_on_code 
			END IF 

		AFTER FIELD name_text 
			IF glob_rec_kandoouser_specific.name_text IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD security_ind 
			IF glob_rec_kandoouser_specific.security_ind IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD security_ind 
			END IF 

			IF glob_rec_kandoouser_specific.security_ind NOT matches "[1-9,A-Z,a-z]" THEN 
				ERROR kandoomsg2("U",9026,"") 
				NEXT FIELD security_ind 
			END IF 
		AFTER FIELD passwd_ind 
			IF glob_rec_kandoouser_specific.passwd_ind NOT matches "[0,1,2]" THEN 
				ERROR kandoomsg2("A",9075,"") 
				NEXT FIELD passwd_ind 
			END IF 
			IF glob_rec_kandoouser_specific.passwd_ind IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD passwd_ind 
			END IF 
			IF glob_rec_kandoouser_specific.passwd_ind = "1" THEN 
				NEXT FIELD password_text 
			ELSE 
				NEXT FIELD group_code 
			END IF 

		AFTER FIELD cmpy_code 
			SELECT * INTO glob_rec_specific_company.* FROM company 
			WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",9502,"") 
				NEXT FIELD cmpy_code 
			ELSE 
				CALL build_mask(glob_rec_kandoouser_specific.cmpy_code, "??????????????????", " ") 
				RETURNING glob_rec_kandoouser_specific.acct_mask_code 
				DISPLAY BY NAME glob_rec_kandoouser_specific.acct_mask_code 

				DISPLAY glob_rec_specific_company.name_text TO company.name_text 

			END IF 

		AFTER FIELD profile_code 
			IF glob_rec_kandoouser_specific.profile_code IS NULL THEN 
				LET glob_rec_kandooprofile.profile_text = "Super user profile" 
				DISPLAY BY NAME glob_rec_kandooprofile.profile_text 

			ELSE 
				SELECT * INTO glob_rec_kandooprofile.* FROM kandooprofile 
				WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
				AND profile_code = glob_rec_kandoouser_specific.profile_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9910,"") 				#9910 RECORD NOT found
					NEXT FIELD profile_code 
				ELSE 
					DISPLAY BY NAME glob_rec_kandooprofile.profile_text 

				END IF 
			END IF 

		AFTER FIELD language_code 
			SELECT * INTO glob_rec_specific_language.* FROM language 
			WHERE language_code = glob_rec_kandoouser_specific.language_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",9910,"") 				#9910 RECORD NOT found
				NEXT FIELD language_code 
			ELSE 
				DISPLAY BY NAME glob_rec_specific_language.language_text 

			END IF 

		AFTER FIELD access_ind 
			IF glob_rec_kandoouser_specific.access_ind IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD access_ind 
			END IF 
			IF glob_rec_kandoouser_specific.access_ind NOT matches "[123]" THEN 
				ERROR kandoomsg2("U",9530,"") 
				NEXT FIELD access_ind 
			END IF 

		AFTER FIELD print_text 
			IF glob_rec_kandoouser_specific.print_text IS NOT NULL THEN 
				SELECT * INTO glob_rec_printcodes.* FROM printcodes 
				WHERE print_code = glob_rec_kandoouser_specific.print_text 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9910,"") 				#9910 RECORD NOT found
					NEXT FIELD print_text 
				END IF 
			END IF 

		AFTER FIELD email 
			IF glob_rec_kandoouser_specific.email IS NOT NULL THEN 
				IF glob_rec_kandoouser_specific.email NOT matches "*@*" THEN 
					ERROR kandoomsg2("U",9947,glob_rec_kandoouser_specific.email) 				#9948 Invalid Email Address .....
					NEXT FIELD email 
				END IF 
			END IF 


		ON ACTION "LOOKUP" infield (print_text) 
			LET glob_rec_kandoouser_specific.print_text = show_print(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD print_text 


		AFTER INPUT 
			##
			## Cheque Print & KandooERP Check
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_kandoouser_specific.group_code IS NOT NULL THEN 
					IF glob_rec_kandoouser_specific.signature_text IS NOT NULL THEN 
						IF glob_rec_kandoouser_specific.password_text IS NULL THEN 
							ERROR kandoomsg2("U", 9102, "") 						#9102 Value Must be Entered
							NEXT FIELD password_text 
						END IF 
					ELSE 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value Must be Entered
						NEXT FIELD signature_text 
					END IF 
				ELSE 
					IF glob_rec_kandoouser_specific.signature_text IS NOT NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value Must be Entered
						NEXT FIELD group_code 
					ELSE 
						IF glob_rec_kandoouser_specific.password_text IS NULL THEN 
							CASE 
								WHEN glob_rec_kandoouser_specific.passwd_ind = '1' 
									ERROR kandoomsg2("U",9102,"") 								#9102 Value Must be Entered
									NEXT FIELD password_text 
							END CASE 
						ELSE 
							CASE 
								WHEN glob_rec_kandoouser_specific.passwd_ind = '2' 
									ERROR kandoomsg2("A",9075,"") 
									NEXT FIELD passwd_ind 
							END CASE 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW u101 
		LET int_flag = false 
		LET quit_flag = false 
		FOR i = glob_idx TO arr_count() 
			IF i = arr_count() THEN 
				LET glob_arr_rec_kandoouser[i].sign_on_code = NULL 
				LET glob_arr_rec_kandoouser[i].name_text = NULL 
				LET glob_arr_rec_kandoouser[i].acct_mask_code = NULL 
				LET glob_arr_rec_kandoouser[i].security_ind = NULL 
			ELSE 
				LET glob_arr_rec_kandoouser[i].sign_on_code = glob_arr_rec_kandoouser[i+1].sign_on_code 
				LET glob_arr_rec_kandoouser[i].name_text = glob_arr_rec_kandoouser[i+1].name_text 
				LET glob_arr_rec_kandoouser[i].acct_mask_code = glob_arr_rec_kandoouser[i+1].acct_mask_code 
				LET glob_arr_rec_kandoouser[i].security_ind = glob_arr_rec_kandoouser[i+1].security_ind 
			END IF 

		END FOR 

		LET glob_rec_kandoouser_specific.sign_on_code = glob_arr_rec_kandoouser[glob_idx].sign_on_code 
		LET glob_rec_kandoouser_specific.name_text = glob_arr_rec_kandoouser[glob_idx].name_text 
		LET glob_rec_kandoouser_specific.acct_mask_code = glob_arr_rec_kandoouser[glob_idx].acct_mask_code 
		LET glob_rec_kandoouser_specific.security_ind = glob_arr_rec_kandoouser[glob_idx].security_ind 

		#FOR i = 0 TO 14-scrn
		#   DISPLAY glob_arr_rec_kandoouser[glob_idx+i].* TO sr_rec_kandoouser[scrn+i].*
		#END FOR

	ELSE 
		MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database;  Please Wait.
		INSERT INTO kandoouser VALUES (glob_rec_kandoouser_specific.*) 
		#
		# HANDLE NEW SECURITY ENHANCEMENT MODIFICATIONS
		# INSERT MODULE SECURITY - DEFAULTING TO kandoouser SECURITY LEVEL
		# Only INSERT FOR the current company
		#
		DECLARE company_curs CURSOR FOR 
		SELECT cmpy_code INTO l_cmpy_code FROM company 
		WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 

		FOREACH company_curs 
			LET glob_rec_specific_kandoomodule.cmpy_code = l_cmpy_code 
			LET glob_rec_specific_kandoomodule.user_code = glob_rec_kandoouser_specific.sign_on_code 
			FOR glob_cnt = 1 TO length(glob_rec_specific_company.module_text) 
				IF glob_rec_specific_company.module_text[glob_cnt, glob_cnt] IS NOT NULL AND 
				glob_rec_specific_company.module_text[glob_cnt, glob_cnt] != " " THEN 
					LET glob_rec_specific_kandoomodule.module_code = 
					glob_rec_specific_company.module_text[glob_cnt, glob_cnt] 
					LET glob_rec_specific_kandoomodule.security_ind = glob_rec_kandoouser_specific.security_ind 
					INSERT INTO kandoomodule VALUES (glob_rec_specific_kandoomodule.*) 
				END IF 
			END FOR 
		END FOREACH 

		INITIALIZE glob_rec_kandoousercmpy.* TO NULL 



		#Dont INSERT here... Force entry via U151 so that locn_code IS
		#forced FOR those who have TO enter one.
		CALL change_cmpy_access(glob_rec_kandoouser_specific.*) 

		SELECT * INTO glob_rec_kandoouser_specific.* FROM kandoouser 
		WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
		CLOSE WINDOW U101 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION add_user()
#######################################################################


#######################################################################
# FUNCTION add_user(
#
#
#######################################################################
FUNCTION change_menu()
	DEFINE l_msgresp LIKE language.yes_flag
	 
	OPEN WINDOW u101 with FORM "U101" 
	CALL windecoration_u("U101") --populate WINDOW FORM elements 

	SELECT * INTO glob_rec_kandoouser_specific.* 
	FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 

	SELECT * INTO glob_rec_specific_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
	LET glob_rec_kandooprofile.profile_text = "Super user profile" 

	SELECT * INTO glob_rec_kandooprofile.* 
	FROM kandooprofile # 
	WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
	AND profile_code = glob_rec_kandoouser_specific.profile_code 

	SELECT * INTO glob_rec_userlocn.* 
	FROM userlocn 
	WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	AND cmpy_code = glob_rec_kandoouser_specific.cmpy_code 

	SELECT * INTO glob_rec_specific_language.* 
	FROM language 
	WHERE language_code = glob_rec_kandoouser_specific.language_code 

	SELECT * INTO glob_rec_location.* 
	FROM location 
	WHERE locn_code = glob_rec_userlocn.locn_code 
	AND cmpy_code = glob_rec_kandoouser_specific.cmpy_code 

	CALL display_details() 

	DISPLAY glob_rec_specific_company.name_text TO company.name_text 

	MENU " Update User" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","U12","menu-user_details") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "EDIT USER"		#COMMAND "User Edit" "Edit/Update user parameters"
			LET int_flag = false 
			LET quit_flag = false 
			CALL change_user() 

		ON ACTION "COMPANY ACCESS"	#COMMAND "Company Edit" "Edit/Update user company security access"
			CALL change_cmpy_access(glob_rec_kandoouser_specific.*) 
			SELECT * INTO glob_rec_kandoouser_specific.* FROM kandoouser 
			WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
			CALL display_details() 

		ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit this menu"
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW U101 

END FUNCTION {change_menu} 
#######################################################################
# END FUNCTION add_user(
#######################################################################


#######################################################################
# FUNCTION display_details()
#
#
#######################################################################
FUNCTION display_details() 

	DISPLAY BY NAME 
		glob_rec_kandoouser_specific.sign_on_code, 
		glob_rec_kandoouser_specific.login_name, 
		glob_rec_kandoouser_specific.sign_on_date, 
		glob_rec_kandooprofile.profile_text, 
		glob_rec_specific_language.language_text, 
		glob_rec_kandoouser_specific.name_text, 
		glob_rec_kandoouser_specific.security_ind, 
		glob_rec_kandoouser_specific.passwd_ind, 
		glob_rec_kandoouser_specific.group_code, 
		glob_rec_kandoouser_specific.signature_text, 
		glob_rec_kandoouser_specific.password_text, 
		glob_rec_kandoouser_specific.cmpy_code, 
		glob_rec_kandoouser_specific.profile_code, 
		glob_rec_kandoouser_specific.language_code, 
		glob_rec_kandoouser_specific.country_code, 
		glob_rec_kandoouser_specific.memo_pri_ind, 
		glob_rec_kandoouser_specific.access_ind, 
		glob_rec_kandoouser_specific.print_text, 
		glob_rec_kandoouser_specific.acct_mask_code, 
		glob_rec_kandoouser_specific.email, 
		glob_rec_kandoouser_specific.user_role_code, 
		glob_rec_kandoouser_specific.cheque_group_code, 
		glob_rec_kandoouser_specific.pwchdate, 
		glob_rec_kandoouser_specific.pwchange 

END FUNCTION 
#######################################################################
# END FUNCTION display_details()
#######################################################################


#######################################################################
# FUNCTION change_mod_access(p_cmpy_code)
#
#
#######################################################################
FUNCTION change_mod_access(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_comapny RECORD LIKE company.* 
	DEFINE l_cmpy_name_text LIKE company.name_text 
	DEFINE l_arr_rec_security DYNAMIC ARRAY OF t_rec_securitye_mc_nt_si 
	#	DEFINE l_arr_rec_security array[30] OF
	#		RECORD
	#          module_code  LIKE kandoomodule.module_code,
	#          name_text    LIKE menu1.name_text,
	#          security_ind LIKE kandoomodule.security_ind
	#		END RECORD
	DEFINE l_rec_kandoomodule RECORD LIKE kandoomodule.* 
	DEFINE l_module_text LIKE company.module_text 
	DEFINE l_security_ind LIKE kandoouser.security_ind 
	DEFINE l_user_security LIKE kandoouser.security_ind 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	SELECT module_text INTO l_module_text FROM company 
	WHERE cmpy_code = p_cmpy_code 

	IF (status=notfound) THEN 
		RETURN 
	END IF 

	LET l_idx = 0 
	FOR l_cnt = 1 TO length(l_module_text) 
		IF l_module_text[l_cnt, l_cnt] IS NOT NULL AND l_module_text[l_cnt, l_cnt] != " " THEN 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_security[l_idx].module_code = l_module_text[l_cnt,l_cnt] 

			SELECT name_text INTO l_arr_rec_security[l_idx].name_text 
			FROM menu1 
			WHERE menu1_code = l_arr_rec_security[l_idx].module_code 
			SELECT security_ind INTO l_user_security 
			FROM kandoomodule 
			WHERE cmpy_code = p_cmpy_code 
			AND user_code = glob_rec_kandoouser_specific.sign_on_code 
			AND module_code = l_arr_rec_security[l_idx].module_code 
			IF status=notfound THEN 
				LET l_arr_rec_security[l_idx].security_ind = l_security_ind 
			ELSE 
				LET l_arr_rec_security[l_idx].security_ind = l_user_security 
			END IF 

		END IF 
	END FOR 

	#   CALL set_count(l_idx)
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW U149 with FORM "U149" 
	CALL windecoration_u("U149") 

	MESSAGE kandoomsg2("U", 1108, "")	#1108 F7 account access masks;  OK TO Continue
	SELECT * INTO glob_rec_specific_company.* FROM company 
	WHERE cmpy_code = p_cmpy_code 

	IF status = 0 THEN 
		LET l_cmpy_name_text = glob_rec_specific_company.name_text 
	END IF 

	DISPLAY 
		glob_rec_kandoouser_specific.sign_on_code, 
		glob_rec_kandoouser_specific.name_text, 
		glob_rec_specific_company.cmpy_code, 
		l_cmpy_name_text 
	TO 
		kandoouser.sign_on_code, 
		kandoouser.name_text, 
		company.cmpy_code, 
		company.name_text 

	INPUT ARRAY l_arr_rec_security WITHOUT DEFAULTS FROM sr_security.* attribute(UNBUFFERED, append ROW = false, auto append = false, INSERT ROW = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U12","input-arr-security") 
			#temp huho
			#CALL fgl_dialog_setkeylabel("F7","change_mask_access")

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_security[l_idx].* TO sr_security[scrn].*

		ON ACTION "Edit Access Mask" 
			#ON KEY(F7)
			CALL change_mask_access(l_arr_rec_security[l_idx].module_code,p_cmpy_code) 

		AFTER FIELD security_ind 
			IF l_arr_rec_security[l_idx].security_ind NOT matches "[1-9,A-Z,a-z]" THEN 
				ERROR kandoomsg2("U", 9026, "") 				#9026 " Security level must be FROM 1 TO Z "
				NEXT FIELD security_ind 
			END IF 

			IF 
			( fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("down") 
			) 
			AND l_arr_rec_security[l_idx + 1].module_code IS NULL THEN 
				ERROR kandoomsg2("U", 9001, "") 			#9001 There are no more rows in the direction
				NEXT FIELD security_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_rec_kandoomodule.cmpy_code = p_cmpy_code 
		LET l_rec_kandoomodule.user_code = glob_rec_kandoouser_specific.sign_on_code 
		LET l_idx = l_arr_rec_security.getLength()
		 
		FOR l_cnt = 1 TO l_idx 
			LET l_rec_kandoomodule.module_code = l_arr_rec_security[l_cnt].module_code 
			LET l_rec_kandoomodule.security_ind = l_arr_rec_security[l_cnt].security_ind 
			IF l_arr_rec_security[l_cnt].module_code IS NULL 
			OR l_arr_rec_security[l_cnt].module_code = " " THEN 
				EXIT FOR 
			END IF 
			
			SELECT security_ind INTO l_security_ind FROM kandoomodule 
			WHERE cmpy_code = p_cmpy_code 
			AND user_code = glob_rec_kandoouser_specific.sign_on_code 
			AND module_code = l_arr_rec_security[l_cnt].module_code 

			IF (status=notfound) THEN #incase module added since user created 
				INSERT INTO kandoomodule VALUES (l_rec_kandoomodule.*) 
			ELSE 
				UPDATE kandoomodule 
				SET 
					module_code = l_arr_rec_security[l_cnt].module_code, 
					security_ind = l_arr_rec_security[l_cnt].security_ind 
				WHERE cmpy_code = p_cmpy_code 
				AND user_code = glob_rec_kandoouser_specific.sign_on_code 
				AND module_code = l_arr_rec_security[l_cnt].module_code 
			END IF 
		END FOR 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	CLOSE WINDOW U149 
END FUNCTION {change_mod_access} 
#######################################################################
# END FUNCTION change_mod_access(p_cmpy_code)
#######################################################################


#######################################################################
# FUNCTION change_user()
#
#
#######################################################################
FUNCTION change_user() 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	ERROR kandoomsg2("U", 1053, "") 	#1053 Enter User Details; OK TO Continue

	INPUT BY NAME 
		glob_rec_kandoouser_specific.login_name,
		glob_rec_kandoouser_specific.name_text, 
		glob_rec_kandoouser_specific.security_ind, 
		glob_rec_kandoouser_specific.passwd_ind, 
		glob_rec_kandoouser_specific.password_text, 
		glob_rec_kandoouser_specific.group_code, 
		glob_rec_kandoouser_specific.signature_text, 
		glob_rec_kandoouser_specific.cmpy_code, 
		glob_rec_kandoouser_specific.profile_code, 
		glob_rec_kandoouser_specific.language_code, 
		glob_rec_kandoouser_specific.country_code, 
		glob_rec_kandoouser_specific.memo_pri_ind, 
		glob_rec_kandoouser_specific.access_ind, 
		glob_rec_kandoouser_specific.print_text, 
		glob_rec_kandoouser_specific.acct_mask_code, 
		glob_rec_kandoouser_specific.email, 
		glob_rec_kandoouser_specific.user_role_code, 
		glob_rec_kandoouser_specific.cheque_group_code, 
		glob_rec_kandoouser_specific.pwchdate, 
		glob_rec_kandoouser_specific.pwchange WITHOUT DEFAULTS 

		BEFORE INPUT 
			LET l_rec_kandoouser.* = glob_rec_kandoouser_specific.* 
			CALL publish_toolbar("kandoo","U12","input-kandoouser-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD name_text 
			IF glob_rec_kandoouser_specific.name_text IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD security_ind 
			IF glob_rec_kandoouser_specific.security_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value Must be Entered
				NEXT FIELD security_ind 
			END IF 
			IF glob_rec_kandoouser_specific.security_ind NOT matches "[1-9,A-Z,a-z]" THEN 
				ERROR kandoomsg2("U",9026,"") 
				NEXT FIELD security_ind 
			END IF 

		AFTER FIELD passwd_ind 
			IF glob_rec_kandoouser_specific.passwd_ind NOT matches "[0,1,2]" THEN 
				ERROR kandoomsg2("A",9075,"") 
				NEXT FIELD passwd_ind 
			END IF 
			IF glob_rec_kandoouser_specific.passwd_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value Must be Entered
				NEXT FIELD passwd_ind 
			END IF 
			IF glob_rec_kandoouser_specific.passwd_ind = "1" THEN 
				NEXT FIELD password_text 
			ELSE 
				NEXT FIELD group_code 
			END IF 

		AFTER FIELD cmpy_code 
			SELECT * INTO glob_rec_specific_company.* FROM company 
			WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",9910,"") 			#9910 RECORD NOT found
				NEXT FIELD cmpy_code 
			ELSE 
				SELECT * INTO glob_rec_kandoousercmpy.* FROM kandoousercmpy 
				WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
				AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9047,"") 				#9047 User does NOT have access TO this company
					NEXT FIELD cmpy_code 
				ELSE 
					LET glob_rec_kandoouser_specific.acct_mask_code = glob_rec_kandoousercmpy.acct_mask_code 
				END IF 
				DISPLAY BY NAME glob_rec_kandoouser_specific.acct_mask_code 

				DISPLAY glob_rec_specific_company.name_text TO company.name_text 

			END IF 

		AFTER FIELD profile_code 
			IF glob_rec_kandoouser_specific.profile_code IS NULL THEN 
				LET glob_rec_kandooprofile.profile_text = "Super user profile" 
				DISPLAY BY NAME glob_rec_kandooprofile.profile_text 
			ELSE 
				SELECT * INTO glob_rec_kandooprofile.* FROM kandooprofile 
				WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
				AND profile_code = glob_rec_kandoouser_specific.profile_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9910,"") 				#9910 RECORD NOT found
					NEXT FIELD profile_code 
				ELSE 
					DISPLAY BY NAME glob_rec_kandooprofile.profile_text 
				END IF 
			END IF 

		AFTER FIELD language_code 
			SELECT * INTO glob_rec_specific_language.* FROM language 
			WHERE language_code = glob_rec_kandoouser_specific.language_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",9910,"") 			#9910 RECORD NOT found
				NEXT FIELD language_code 
			ELSE 
				DISPLAY BY NAME glob_rec_specific_language.language_text 

			END IF 

		AFTER FIELD access_ind 
			IF glob_rec_kandoouser_specific.access_ind IS NULL THEN 
				ERROR kandoomsg2("U", 9102, "") 			#9102 Value Must be Entered
				NEXT FIELD access_ind 
			END IF 
			IF glob_rec_kandoouser_specific.access_ind NOT matches "[123]" THEN 
				ERROR kandoomsg2("U",9530,"") 
				NEXT FIELD access_ind 
			END IF 

		AFTER FIELD print_text 
			IF glob_rec_kandoouser_specific.print_text IS NOT NULL THEN 
				SELECT * INTO glob_rec_printcodes.* FROM printcodes 
				WHERE print_code = glob_rec_kandoouser_specific.print_text 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9910,"") 				#9910 RECORD NOT found
					NEXT FIELD print_text 
				END IF 
			END IF 

		AFTER FIELD email 
			IF glob_rec_kandoouser_specific.email IS NOT NULL THEN 
				IF glob_rec_kandoouser_specific.email NOT matches "*@*" THEN 
					ERROR kandoomsg2("U",9947,glob_rec_kandoouser_specific.email) 				#9948 Invalid Email Address .....
					NEXT FIELD email 
				END IF 
			END IF 

		ON ACTION "LOOKUP" infield (print_text) 
			LET glob_rec_kandoouser_specific.print_text = show_print(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD print_text 

		AFTER INPUT 
			##
			## Cheque Print  & KandooERP Check
			##
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_kandoouser_specific.group_code IS NOT NULL THEN 
					IF glob_rec_kandoouser_specific.signature_text IS NOT NULL THEN 
						IF glob_rec_kandoouser_specific.password_text IS NULL THEN 
							ERROR kandoomsg2("U",9102,"") 
							NEXT FIELD password_text 
						END IF 
					ELSE 
						ERROR kandoomsg2("U",9102,"") 
						NEXT FIELD signature_text 
					END IF 

				ELSE 

					IF glob_rec_kandoouser_specific.signature_text IS NOT NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						NEXT FIELD group_code 
					ELSE 

						IF glob_rec_kandoouser_specific.password_text IS NULL THEN 
							CASE 
								WHEN glob_rec_kandoouser_specific.passwd_ind = '1' 
									ERROR kandoomsg2("U",9102,"") 
									NEXT FIELD password_text 
							END CASE 
						ELSE 
							CASE 
								WHEN glob_rec_kandoouser_specific.passwd_ind = '2' 
									ERROR kandoomsg2("A",9075,"") 
									NEXT FIELD password_text 
							END CASE 
						END IF 

					END IF 
				END IF 

			ELSE 

				LET glob_rec_kandoouser_specific.* = l_rec_kandoouser.* 

				DISPLAY BY NAME 
					glob_rec_kandoouser_specific.name_text, 
					glob_rec_kandoouser_specific.security_ind, 
					glob_rec_kandoouser_specific.passwd_ind, 
					glob_rec_kandoouser_specific.group_code, 
					glob_rec_kandoouser_specific.signature_text, 
					glob_rec_kandoouser_specific.password_text, 
					glob_rec_kandoouser_specific.cmpy_code, 
					glob_rec_kandoouser_specific.profile_code, 
					glob_rec_kandoouser_specific.language_code, 
					glob_rec_kandoouser_specific.access_ind, 
					glob_rec_kandoouser_specific.print_text, 
					glob_rec_kandoouser_specific.acct_mask_code 

			END IF 

	END INPUT #---------------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_kandoouser_specific.name_text = glob_arr_rec_kandoouser[glob_idx].name_text 
		LET glob_rec_kandoouser_specific.security_ind = glob_arr_rec_kandoouser[glob_idx].security_ind 

	ELSE 

		ERROR kandoomsg2("U",1005,"") 		#1005 Updating Database;  Please Wait.
		SELECT * INTO glob_rec_kandoousercmpy.* FROM kandoousercmpy 
		WHERE cmpy_code = glob_rec_kandoouser_specific.cmpy_code 
		AND sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
		#Why is the modiffied value overwritten? Docs state, I can modify the user specific account mask here - comment the next line for now HuHo 26.08.2019
		#LET glob_rec_kandoouser_specific.acct_mask_code = glob_rec_kandoousercmpy.acct_mask_code
		UPDATE kandoouser 
		SET * = glob_rec_kandoouser_specific.* 
		WHERE sign_on_code = glob_rec_kandoouser_specific.sign_on_code 
	END IF 

END FUNCTION
#######################################################################
# END FUNCTION change_user()
#######################################################################


#######################################################################
# FUNCTION delete_user(p_sign_on_code)
#
#
#######################################################################
FUNCTION delete_user(p_sign_on_code) 
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code 

	DELETE FROM kandoouser 
	WHERE sign_on_code = p_sign_on_code 

	DELETE FROM userlimits 
	WHERE sign_on_code = p_sign_on_code 

	DELETE FROM userlocn 
	WHERE sign_on_code = p_sign_on_code 

	DELETE FROM kandoomask 
	WHERE user_code = p_sign_on_code 

	DELETE FROM kandoomemoline 
	WHERE memo_num in (SELECT memo_num FROM kandoomemo 
	WHERE to_code = p_sign_on_code) 

	DELETE FROM kandoomemo 
	WHERE to_code = p_sign_on_code 

	CALL delete_user_access(p_sign_on_code) 

END FUNCTION
#######################################################################
# END FUNCTION delete_user(p_sign_on_code)
#######################################################################