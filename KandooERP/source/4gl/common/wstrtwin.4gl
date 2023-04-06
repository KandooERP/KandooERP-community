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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION show_wstreet(p_cmpy)
#
#      wstrtwin.4gl - show_wstreet
#                     window FUNCTION FOR finding street records
#                     returns pr_rowid
###########################################################################
 FUNCTION show_wstreet(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_street RECORD LIKE street.*
	DEFINE l_arr_street ARRAY[500] OF RECORD 
		scroll_flag CHAR(1), 
		street_text LIKE street.street_text, 
		st_type_text LIKE street.st_type_text, 
		suburb_text LIKE suburb.suburb_text 
	END RECORD 
	DEFINE l_arr_rowid DYNAMIC ARRAY OF RECORD 
		row_id INTEGER 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE r_rowid INTEGER

	LET r_rowid = 0 
	OPEN WINDOW U116 with FORM "U116" 
	CALL windecoration_u("U116") -- albo kd-752
 
	WHILE TRUE 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON street_text, 
		st_type_text, 
		suburb_text, 
		state_code, 
		post_code, 
		source_ind, 
		map_number, 
		ref_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wstrtwin","construct-street") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET r_rowid = 0 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")	#1002 Searching Database - please wait
		LET l_query_text = "SELECT street.rowid, street.*,suburb.* ", 
		"FROM street,suburb ", 
		"WHERE street.cmpy_code = '",p_cmpy,"' ", 
		"AND suburb.cmpy_code = '",p_cmpy,"' ", 
		"AND suburb.suburb_code = street.suburb_code ", 
		"AND ", l_where_text CLIPPED, " ", 
		"ORDER BY street_text,st_type_text,", 
		"suburb_text,state_code" 
 
		PREPARE s_street FROM l_query_text 
		DECLARE c_street CURSOR FOR s_street
		 
		LET l_idx = 0 
		FOREACH c_street INTO r_rowid,l_rec_street.*,l_rec_suburb.* 
			LET l_idx = l_idx + 1 
			LET l_arr_street[l_idx].street_text = l_rec_street.street_text 
			LET l_arr_street[l_idx].st_type_text = l_rec_street.st_type_text 
			LET l_arr_street[l_idx].suburb_text = l_rec_suburb.suburb_text 
			LET l_arr_rowid[l_idx].row_id = r_rowid 
		END FOREACH 
		MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected

		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rowid[1].* TO NULL 
			INITIALIZE l_arr_street[1].* TO NULL 
		END IF 

		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add

		INPUT ARRAY l_arr_street WITHOUT DEFAULTS FROM sr_street.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","wstrtwin","input-arr-street") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			--BEFORE FIELD scroll_flag 
				SELECT street.*,suburb.* 
				INTO l_rec_street.*,l_rec_suburb.* 
				FROM street,suburb 
				WHERE street.rowid = l_arr_rowid[l_idx].row_id 
				AND suburb.cmpy_code = p_cmpy 
				AND suburb.suburb_code = street.suburb_code 

				DISPLAY BY NAME l_rec_suburb.state_code, 
				l_rec_suburb.post_code, 
				l_rec_street.source_ind, 
				l_rec_street.map_number, 
				l_rec_street.ref_text 

				IF l_arr_street[l_idx].street_text IS NOT NULL THEN 
					DISPLAY l_arr_street[l_idx].* TO sr_street[l_scrn].* 
				END IF 

			BEFORE FIELD street_text 
				LET r_rowid = l_arr_rowid[l_idx].row_id 
				EXIT INPUT 

			ON ACTION "STREET-MAINTENANCE" --ON KEY (F10) 
				CALL run_prog("U52","","","","") 

			AFTER INPUT 
				LET r_rowid = l_arr_rowid[l_idx].row_id 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW U116 

	RETURN r_rowid 
END FUNCTION 
###########################################################################
# END FUNCTION show_wstreet(p_cmpy)
###########################################################################