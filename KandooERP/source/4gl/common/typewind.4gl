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

	Source code beautified by beautify.pl on 2020-01-02 10:35:38	$Id: $
}



#         typewind.4gl - show_type
#                        window FUNCTION TO find jobtype record
#                        returns type_code
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_type(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_jobtype RECORD LIKE jobtype.* 
	DEFINE l_arr_jobtype ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE jobtype.type_code, 
		type_text LIKE jobtype.type_text, 
		bill_acct_code LIKE jobtype.bill_acct_code 
	END RECORD
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW j106 with FORM "J106" 
	CALL windecoration_j("J106") 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON type_code, 
		type_text, 
		bill_acct_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","typewind","construct-jobtype") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_jobtype.type_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM jobtype ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY type_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_jobtype FROM l_query_text 
		DECLARE c_jobtype CURSOR FOR s_jobtype 
		LET l_idx = 0 
		FOREACH c_jobtype INTO l_rec_jobtype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_jobtype[l_idx].type_code = l_rec_jobtype.type_code 
			LET l_arr_jobtype[l_idx].type_text = l_rec_jobtype.type_text 
			LET l_arr_jobtype[l_idx].bill_acct_code = l_rec_jobtype.bill_acct_code 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_jobtype[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_jobtype WITHOUT DEFAULTS FROM sr_jobtype.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","typewind","input-arr-jobtype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_jobtype[l_idx].type_code IS NOT NULL THEN 
					DISPLAY l_arr_jobtype[l_idx].* TO sr_jobtype[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			ON KEY (F10) 
				CALL run_prog("JZ4","","","","") 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_jobtype[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD type_code 
				LET l_rec_jobtype.type_code = l_arr_jobtype[l_idx].type_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_jobtype[l_idx].* TO sr_jobtype[l_scrn].* 

			AFTER INPUT 
				LET l_rec_jobtype.type_code = l_arr_jobtype[l_idx].type_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j106 
	RETURN l_rec_jobtype.type_code 
END FUNCTION 


