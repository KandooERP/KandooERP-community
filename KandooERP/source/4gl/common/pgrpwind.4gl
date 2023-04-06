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
# FUNCTION db_prodgrp_get_datasource(p_filter,p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION db_prodgrp_get_datasource(p_filter,p_cmpy,p_filter_text)
	DEFINE p_filter BOOLEAN #with or without construct
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE l_arr_rec_prodgrp DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		prodgrp_code LIKE prodgrp.prodgrp_code, 
		desc_text LIKE prodgrp.desc_text, 
		maingrp_code LIKE prodgrp.maingrp_code 
	END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = " 1=1 " 
	END IF 

	
	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			prodgrp_code, 
			desc_text, 
			maingrp_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","pgrpwind","construct-prodgrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_prodgrp.prodgrp_code = NULL 
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	end if 

		MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM prodgrp ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_text CLIPPED," ", 
			"ORDER BY prodgrp_code" 

		WHENEVER ERROR CONTINUE 

		PREPARE s_prodgrp FROM l_query_text 
		DECLARE c_prodgrp CURSOR FOR s_prodgrp 

		LET l_idx = 1 
		FOREACH c_prodgrp INTO l_rec_prodgrp.*
			LET l_arr_rec_prodgrp[l_idx].prodgrp_code = l_rec_prodgrp.prodgrp_code 
			LET l_arr_rec_prodgrp[l_idx].desc_text = l_rec_prodgrp.desc_text 
			LET l_arr_rec_prodgrp[l_idx].maingrp_code = l_rec_prodgrp.maingrp_code 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
			  MESSAGE kandoomsg2("U",6100,l_idx)
			  EXIT FOREACH
			END IF

			LET l_idx = l_idx + 1
			
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#9113 "l_idx records selected"
--		IF l_idx = 0 THEN
--			ERROR "No records selected" 
--			--LET l_idx = 1 
--			--INITIALIZE l_arr_rec_prodgrp[1].* TO NULL 
--		END IF 

	RETURN l_arr_rec_prodgrp
END FUNCTION
###########################################################################
# END FUNCTION db_prodgrp_get_datasource(p_filter,p_cmpy,p_filter_text)
###########################################################################

################################################################################
# FUNCTION show_prodgrp(p_cmpy,p_filter_text)
#
# show_prodgrp
#                  Window FUNCTION FOR finding prodgrp records
#                  FUNCTION will RETURN prodgrp_code TO calling program
################################################################################
FUNCTION show_prodgrp(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE l_arr_rec_prodgrp DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		prodgrp_code LIKE prodgrp.prodgrp_code, 
		desc_text LIKE prodgrp.desc_text, 
		maingrp_code LIKE prodgrp.maingrp_code 
	END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

{
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = " 1=1 " 
	END IF 

	OPEN WINDOW I601 with FORM "I601" 
	CALL windecoration_i("I601") 

	WHILE true 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			prodgrp_code, 
			desc_text, 
			maingrp_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","pgrpwind","construct-prodgrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_prodgrp.prodgrp_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM prodgrp ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY prodgrp_code" 

		WHENEVER ERROR CONTINUE 

		PREPARE s_prodgrp FROM l_query_text 
		DECLARE c_prodgrp CURSOR FOR s_prodgrp 

		LET l_idx = 0 
		FOREACH c_prodgrp INTO l_rec_prodgrp.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_prodgrp[l_idx].prodgrp_code = l_rec_prodgrp.prodgrp_code 
			LET l_arr_rec_prodgrp[l_idx].desc_text = l_rec_prodgrp.desc_text 
			LET l_arr_rec_prodgrp[l_idx].maingrp_code = l_rec_prodgrp.maingrp_code 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#9113 "l_idx records selected"
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_prodgrp[1].* TO NULL 
		END IF 
}

	
	OPEN WINDOW I601 with FORM "I601" 
	CALL windecoration_i("I601") 

	CALL db_prodgrp_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_rec_prodgrp

		MESSAGE kandoomsg2("U",1006,"") #1006 " ESC on line TO SELECT Group - F10 TO Add"
		DISPLAY ARRAY l_arr_rec_prodgrp TO sr_prodgrp.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","pgrpwind","input-arr-prodgrp") 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_prodgrp.prodgrp_code = l_arr_rec_prodgrp[l_idx].prodgrp_code

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
				
			ON ACTION "FILTER" 
				CALL l_arr_rec_prodgrp.clear()
				CALL db_prodgrp_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_rec_prodgrp
				LET l_rec_prodgrp.prodgrp_code = NULL
				
			ON ACTION "REFRESH" 
				CALL windecoration_i("I601") 
				CALL l_arr_rec_prodgrp.clear()
				CALL db_prodgrp_get_datasource(FALSE,p_cmpy,p_filter_text) RETURNING l_arr_rec_prodgrp
				LET l_rec_prodgrp.prodgrp_code = NULL
								
			ON ACTION "IZG - PRODUCT GROUP MAINTENANCE" --ON KEY (F10) --product GROUP maintenance 
				CALL run_prog("IZG","","","","") --product GROUP maintenance 

		END DISPLAY 
		-------------------------------------------------------

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
--		ELSE 
--			EXIT WHILE 
		END IF 

--	END WHILE 

	CLOSE WINDOW I601 

	RETURN l_rec_prodgrp.prodgrp_code 
END FUNCTION 
################################################################################
# END FUNCTION show_prodgrp(p_cmpy,p_filter_text)
################################################################################