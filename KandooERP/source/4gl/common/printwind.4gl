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

###########################################################################
#           printwind.4gl -  show_print
#                            window FUNCTION TO find printercodes records
#                            returns print_code
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"  


###########################################################################
# FUNCTION db_printcodes_show_print_filter_data_source(p_filter)
###########################################################################
FUNCTION db_printcodes_show_print_filter_data_source(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_arr_rec_printcodes DYNAMIC ARRAY OF t_rec_printcodes_pc_dt_wn_ln 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			print_code, 
			desc_text, 
			width_num, 
			length_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","printwind","construct-printcodes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_printcodes.print_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM printcodes ", 
		"WHERE ",l_where_text clipped," ", 
		"ORDER BY print_code" 

	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 

	PREPARE s_printcodes FROM l_query_text 
	DECLARE c_printcodes CURSOR FOR s_printcodes 

	LET l_idx = 0 
	FOREACH c_printcodes INTO l_rec_printcodes.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_printcodes[l_idx].print_code = l_rec_printcodes.print_code 
		LET l_arr_rec_printcodes[l_idx].desc_text = l_rec_printcodes.desc_text 
		LET l_arr_rec_printcodes[l_idx].width_num = l_rec_printcodes.width_num 
		LET l_arr_rec_printcodes[l_idx].length_num = l_rec_printcodes.length_num 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) 	#U9113 l_idx records selected

	RETURN l_arr_rec_printcodes 
END FUNCTION 
###########################################################################
# END FUNCTION db_printcodes_show_print_filter_data_source(p_filter)
###########################################################################


###################################################################
# FUNCTION show_print(p_cmpy)
#
#
###################################################################
FUNCTION show_print(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_arr_rec_printcodes DYNAMIC ARRAY OF t_rec_printcodes_pc_dt_wn_ln 
	#	DEFINE l_arr_rec_printcodes DYNAMIC ARRAY OF #array[100] of record
	#		RECORD
	#         print_code LIKE printcodes.print_code,
	#         desc_text LIKE printcodes.desc_text,
	#         width_num LIKE printcodes.width_num,
	#         length_num LIKE printcodes.length_num
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW u103 with FORM "U103" 
	CALL windecoration_u("U103") 


	CALL db_printcodes_show_print_filter_data_source(false) RETURNING l_arr_rec_printcodes 

	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_printcodes[1].* TO NULL
	#      END IF

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	MESSAGE kandoomsg2("U",1519,"") 	#1006 " ESC on line TO SELECT - RETURN TO View - F10 TO Add"

	#      CALL set_count(l_idx)
	#INPUT ARRAY l_arr_rec_printcodes WITHOUT DEFAULTS FROM sr_printcodes.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_printcodes TO sr_printcodes.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","printwind","input-arr-printcodes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_printcodes.print_code = l_arr_rec_printcodes[l_idx].print_code 

		ON ACTION "FILTER" 
			CALL db_printcodes_show_print_filter_data_source(true) RETURNING l_arr_rec_printcodes 

			#            LET scrn = scr_line()
			#            IF l_arr_rec_printcodes[l_idx].print_code IS NOT NULL THEN
			#               DISPLAY l_arr_rec_printcodes[l_idx].* TO sr_printcodes[scrn].*
			#
			#            END IF
			#            NEXT FIELD print_code

		ON KEY (F10) 
			CALL run_prog("URP","","","","") 
			CALL db_printcodes_show_print_filter_data_source(false) RETURNING l_arr_rec_printcodes 

			#         AFTER FIELD print_code
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("U",9001,"")
			#               NEXT FIELD print_code
			#            END IF

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			#         BEFORE FIELD desc_text
			CALL disp_device2(l_arr_rec_printcodes[l_idx].print_code) 
			#            NEXT FIELD print_code

			#AFTER ROW
			#   DISPLAY l_arr_rec_printcodes[l_idx].* TO sr_printcodes[scrn].*

			#         AFTER INPUT
			#            LET l_rec_printcodes.print_code = l_arr_rec_printcodes[l_idx].print_code



	END DISPLAY 
	##########################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 


	###################

	CLOSE WINDOW u103 

	RETURN l_rec_printcodes.print_code 
END FUNCTION 
###################################################################
# END FUNCTION show_print(p_cmpy)
###################################################################


###################################################################
# FUNCTION disp_device2(p_printcode)
#
#
###################################################################
FUNCTION disp_device2(p_printcode) 
	DEFINE p_printcode LIKE printcodes.print_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 

	OPEN WINDOW u102 with FORM "U102" 
	CALL windecoration_u("U102") 

	SELECT * INTO l_rec_printcodes.* 
	FROM printcodes 
	WHERE printcodes.print_code = p_printcode 
	DISPLAY BY NAME l_rec_printcodes.* 

	CALL eventsuspend()	#MESSAGE kandoomsg2("U",1,"")#1 press any key TO continue

	CLOSE WINDOW U102 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
###################################################################
# FUNCTION disp_device2(p_printcode)
###################################################################