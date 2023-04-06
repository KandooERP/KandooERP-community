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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#################################################################################
# FUNCTION show_hold(p_cmpy_code)
#
#        stopwind.4gl - show_hold
#                       window FUNCTION that finds holdpay records
#                       returns hold_code
# p4gl registered FUNCTION, but NOT the parameter!
#################################################################################
FUNCTION show_hold(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_arr_rec_holdpay DYNAMIC ARRAY OF 
		RECORD 
			hold_code LIKE holdpay.hold_code, 
			hold_text LIKE holdpay.hold_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	#OPTIONS INSERT KEY F36,
	#        DELETE KEY F36

	OPEN WINDOW p139 with FORM "P139" 
	CALL windecoration_p("P139") 

	WHILE TRUE 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON hold_code, 
		hold_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","stopwind","construct-holdpay") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_holdpay.hold_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM holdpay ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY hold_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_holdpay FROM l_query_text 
		DECLARE c_holdpay CURSOR FOR s_holdpay 

		CALL l_arr_rec_holdpay.clear() 
		LET l_idx = 0 
		FOREACH c_holdpay INTO l_rec_holdpay.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_holdpay[l_idx].hold_code = l_rec_holdpay.hold_code 
			LET l_arr_rec_holdpay[l_idx].hold_text = l_rec_holdpay.hold_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_holdpay[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 

		INPUT ARRAY l_arr_rec_holdpay WITHOUT DEFAULTS FROM sr_holdpay.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","stopwind","input-arr-holdpay") 


			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#IF l_arr_rec_holdpay[l_idx].hold_code IS NOT NULL THEN
				#   DISPLAY l_arr_rec_holdpay[l_idx].* TO sr_holdpay[scrn].*
				#
				#END IF
				NEXT FIELD hold_code 

			ON KEY (F10) 
				CALL run_prog("PZ3","","","","") 
				NEXT FIELD hold_code 

			AFTER FIELD hold_code 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD hold_code 
				END IF 

			BEFORE FIELD hold_text 
				LET l_rec_holdpay.hold_code = l_arr_rec_holdpay[l_idx].hold_code 
				EXIT INPUT 
				#AFTER ROW
				#   DISPLAY l_arr_rec_holdpay[l_idx].* TO sr_holdpay[scrn].*

			AFTER INPUT 
				LET l_rec_holdpay.hold_code = l_arr_rec_holdpay[l_idx].hold_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW p139 

	RETURN l_rec_holdpay.hold_code 
END FUNCTION 
