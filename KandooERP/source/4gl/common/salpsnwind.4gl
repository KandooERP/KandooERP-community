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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}



#       salpsnwind.4gl - show_salperson
#                      window FUNCTION TO find salesperson records
#                      returns sale code
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_salperson(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_salesperson ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		terri_code LIKE salesperson.terri_code 
	END RECORD 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = p_cmpy 
	AND arparms.parm_code = "1" 
	OPEN WINDOW A160 with FORM "A160" 
	CALL windecoration_a("A160") -- albo kd-767 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"") 
		#1001 " Enter criteria - press ESC TO continue"
		CONSTRUCT BY NAME l_where_text ON sale_code, 
		name_text, 
		terri_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","salpsnwind","construct-salesperson") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_salesperson.sale_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp=kandoomsg("U",1002,"") 
		LET l_query_text = "SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED, 
		"ORDER BY sale_code" 
		LET l_idx = 0 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_salperson FROM l_query_text 
		DECLARE c_salperson CURSOR FOR s_salperson 
		FOREACH c_salperson INTO l_rec_salesperson.* 
			LET l_idx = l_idx + 1 
			LET l_arr_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
			LET l_arr_salesperson[l_idx].name_text = l_rec_salesperson.name_text 
			LET l_arr_salesperson[l_idx].terri_code= l_rec_salesperson.terri_code 

			IF l_idx = 100 THEN 
				LET l_msgresp=kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx=0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_salesperson[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("U",1006,"") 
		#U1006 "Esc on line TO SELECT - F10 TO add"
		INPUT ARRAY l_arr_salesperson WITHOUT DEFAULTS FROM sr_salesperson.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","salpsnwind","input-arr-salesperson") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) 
				CALL run_prog("AZ3","","","","") 
			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_idx <= arr_count() THEN 
					DISPLAY l_arr_salesperson[l_idx].* TO sr_salesperson[l_scrn].* 

				END IF 
			AFTER FIELD scroll_flag 
				LET l_arr_salesperson[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD sale_code 
				LET l_rec_salesperson.sale_code = l_arr_salesperson[l_idx].sale_code 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_salesperson[l_idx].* TO sr_salesperson[l_scrn].* 


		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			LET l_rec_salesperson.sale_code = l_arr_salesperson[l_idx].sale_code 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW A160 
	RETURN l_rec_salesperson.sale_code 
END FUNCTION 


