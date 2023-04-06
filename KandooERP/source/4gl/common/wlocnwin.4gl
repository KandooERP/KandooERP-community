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

	Source code beautified by beautify.pl on 2020-01-02 10:35:42	$Id: $
}



#         wlocnwin.4gl - show_wlocn
#                        window FUNCTION FOR finding warehouse records
#                        returns ware_code
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_wlocn(p_cmpy)
#
# window FUNCTION FOR finding warehouse records
# returns ware_code
############################################################
FUNCTION show_wlocn(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_warehouse DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			ware_code LIKE warehouse.ware_code, 
			desc_text LIKE warehouse.desc_text, 
			city_text LIKE warehouse.city_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING #char(200) 
	DEFINE l_where_text STRING #char(100) 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW w103 with FORM "W103" 
		CALL windecoration_w("W103") 

		WHILE TRUE 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON ware_code, 
			desc_text, 
			city_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","wlocnwin","construct-warehouse") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rec_warehouse.ware_code = NULL 
				EXIT WHILE 
			END IF 
			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 Search Database - please wait
			LET l_query_text = "SELECT * FROM warehouse ", 
			"WHERE cmpy_code = '",p_cmpy,"' ", 
			"AND ", l_where_text CLIPPED, " ", 
			"ORDER BY ware_code" 
			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 
			PREPARE s_warehouse FROM l_query_text 
			DECLARE c_warehouse CURSOR FOR s_warehouse 

			LET l_idx = 0 
			FOREACH c_warehouse INTO l_rec_warehouse.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_warehouse[l_idx].ware_code = l_rec_warehouse.ware_code 
				LET l_arr_rec_warehouse[l_idx].desc_text = l_rec_warehouse.desc_text 
				LET l_arr_rec_warehouse[l_idx].city_text = l_rec_warehouse.city_text 
				IF l_idx = 100 THEN 
					LET l_msgresp = kandoomsg("U",6100,l_idx) 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			LET l_msgresp = kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_warehouse[1].* TO NULL 
			END IF 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET l_msgresp = kandoomsg("U",1006,"") 

			#1006 " ESC on line TO SELECT - F10 TO Add
			CALL set_count(l_idx) 

			INPUT ARRAY l_arr_rec_warehouse WITHOUT DEFAULTS FROM sr_warehouse.* ATTRIBUTE(UNBUFFERED) 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","wlocnwin","input-arr-warehouse") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					#            LET scrn = scr_line()
					#            IF l_arr_rec_warehouse[l_idx].ware_code IS NOT NULL THEN
					#               DISPLAY l_arr_rec_warehouse[l_idx].* TO sr_warehouse[scrn].*
					#
					#            END IF
					NEXT FIELD scroll_flag 

				AFTER FIELD scroll_flag 
					LET l_arr_rec_warehouse[l_idx].scroll_flag = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD ware_code 
					IF l_idx > 0 THEN 
						LET l_rec_warehouse.ware_code = l_arr_rec_warehouse[l_idx].ware_code 
						EXIT INPUT 
					END IF 

				ON KEY (F10) 
					CALL run_prog("IZ3","","","","") 

					#         AFTER ROW
					#            DISPLAY l_arr_rec_warehouse[l_idx].* TO sr_warehouse[scrn].*

				AFTER INPUT 
					IF l_idx > 0 THEN 
						LET l_rec_warehouse.ware_code = l_arr_rec_warehouse[l_idx].ware_code 
					END IF 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW w103 

		RETURN l_rec_warehouse.ware_code 
END FUNCTION 
