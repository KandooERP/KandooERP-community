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

	Source code beautified by beautify.pl on 2020-01-02 10:35:27	$Id: $
}



#           poscwind.4gl - show_po
#                          window FUNCTION FOR finding purchhead records
#                          returns order_num

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_po(p_cmpy_code)
#
#
############################################################
FUNCTION show_po(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_purchhead 
	RECORD 
		order_num LIKE purchhead.order_num, 
		vend_code LIKE purchhead.vend_code, 
		name_text LIKE vendor.name_text 
	END RECORD 
	DEFINE l_arr_rec_purchhead DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			order_num LIKE purchhead.order_num, 
			vend_code LIKE purchhead.vend_code, 
			name_text LIKE vendor.name_text 
		END RECORD 
	DEFINE idx SMALLINT 
	DEFINE l_query_text CHAR(800) 
	DEFINE l_where_text STRING 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW r111 with FORM "R111" 
		CALL windecoration_r("R111") -- albo kd-756 

		WHILE true 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON purchhead.order_num,purchhead.vend_code,vendor.name_text 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","poscwind","construct-purchhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_purchhead.order_num = NULL 
				EXIT WHILE 
			END IF 
			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT purchhead.order_num, ", 
			"purchhead.vend_code, ", 
			"vendor.name_text ", 
			"FROM purchhead , vendor ", 
			"WHERE purchhead.cmpy_code = '",p_cmpy_code,"' ", 
			" AND vendor.cmpy_code = '",p_cmpy_code,"' ", 
			"AND vendor.vend_code = purchhead.vend_code ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY purchhead.order_num" 
			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 
			PREPARE s_purchhead FROM l_query_text 
			DECLARE c_purchhead CURSOR FOR s_purchhead 

			LET idx = 0 
			FOREACH c_purchhead INTO l_rec_purchhead.* 
				LET idx = idx + 1 
				LET l_arr_rec_purchhead[idx].order_num = l_rec_purchhead.order_num 
				LET l_arr_rec_purchhead[idx].vend_code = l_rec_purchhead.vend_code 
				LET l_arr_rec_purchhead[idx].name_text = l_rec_purchhead.name_text 
				IF idx = 100 THEN 
					LET l_msgresp = kandoomsg("U",6100,idx) 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			LET l_msgresp=kandoomsg("U",9113,idx) 
			#U9113 idx records selected
			IF idx = 0 THEN 
				LET idx = 1 
				INITIALIZE l_arr_rec_purchhead[1].* TO NULL 
			END IF 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

			LET l_msgresp = kandoomsg("U",1006,"") 
			#1006 " ESC on line TO SELECT - F10 TO Add"
			#      CALL set_count(idx)

			INPUT ARRAY l_arr_rec_purchhead WITHOUT DEFAULTS FROM sr_purchhead.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","poscwind","input-arr-purchhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				BEFORE ROW 
					LET idx = arr_curr() 
					#            LET scrn = scr_line()
					#            IF l_arr_rec_purchhead[idx].order_num IS NOT NULL THEN
					#               DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].*
					#
					#            END IF
					NEXT FIELD scroll_flag 

				ON KEY (F10) 
					CALL run_prog("R11","","","","") 
					NEXT FIELD scroll_flag 

				AFTER FIELD scroll_flag 
					LET l_arr_rec_purchhead[idx].scroll_flag = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD order_num 
					LET l_rec_purchhead.order_num = l_arr_rec_purchhead[idx].order_num 
					EXIT INPUT 

					#         AFTER ROW
					#            DISPLAY l_arr_rec_purchhead[idx].* TO sr_purchhead[scrn].*

				AFTER INPUT 
					LET l_rec_purchhead.order_num = l_arr_rec_purchhead[idx].order_num 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		CLOSE WINDOW r111 

		RETURN l_rec_purchhead.order_num 
END FUNCTION 


