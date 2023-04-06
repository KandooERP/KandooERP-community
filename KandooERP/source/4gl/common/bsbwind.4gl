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

#######################################################################
# FUNCTION db_bic_get_datasource(p_filter)
#
#
#######################################################################
FUNCTION db_bic_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_bic RECORD LIKE bic.* 
	DEFINE l_arr_rec_bic DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bic_code LIKE bic.bic_code, 
		desc_text LIKE bic.desc_text, 
		post_code LIKE bic.post_code, 
		bank_ref LIKE bic.bank_ref 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING --CHAR(2200) 
	DEFINE l_where_text STRING --CHAR(2048) 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			bic_code, 
			desc_text, 
			post_code, 
			bank_ref 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","bicwind","construct-bic") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_bic.bic_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE	
		LET l_where_text = " 1=1 "
	END IF

	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"

	LET l_query_text = "SELECT * FROM bic ", 
	"WHERE ", l_where_text clipped," ", 
	"ORDER BY bic_code" 

	WHENEVER ERROR CONTINUE 

	PREPARE s_bic FROM l_query_text 
	DECLARE c_bic CURSOR FOR s_bic 
	LET l_idx = 0 
	FOREACH c_bic INTO l_rec_bic.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_bic[l_idx].bic_code = l_rec_bic.bic_code 
		LET l_arr_rec_bic[l_idx].desc_text = l_rec_bic.desc_text 
		LET l_arr_rec_bic[l_idx].post_code = l_rec_bic.post_code 
		LET l_arr_rec_bic[l_idx].bank_ref = l_rec_bic.bank_ref

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	ERROR kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected

	RETURN l_arr_rec_bic
END FUNCTION 
#######################################################################
# END FUNCTION db_bic_get_datasource(p_filter)
#######################################################################


#######################################################################
# FUNCTION show_bic()
#
#    bicwind.4gl - bic_code
#                  Window FUNCTION FOR finding a bic record
#                  FUNCTION will RETURN bic_code TO calling program
#######################################################################
FUNCTION show_bic() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_bic RECORD LIKE bic.* 
	DEFINE l_arr_rec_bic DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bic_code LIKE bic.bic_code, 
		desc_text LIKE bic.desc_text, 
		post_code LIKE bic.post_code, 
		bank_ref LIKE bic.bank_ref 
	END RECORD 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW G536 with FORM "G536" 
	CALL windecoration_g("G536") 

	CALL db_bic_get_datasource(FALSE) RETURNING l_arr_rec_bic

	MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT
	DISPLAY ARRAY l_arr_rec_bic TO sr_bic.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","bicwind","input-arr-bic") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_bic.bic_code = l_arr_rec_bic[l_idx].bic_code

		AFTER ROW
			#nothing

		AFTER DISPLAY 
			#nothing

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
			
		ON ACTION "FILTER"
			CALL l_arr_rec_bic.clear()
			CALL db_bic_get_datasource(FALSE) RETURNING l_arr_rec_bic 

		ON ACTION "REFRESH"
			CALL windecoration_g("G536") 
			CALL l_arr_rec_bic.clear()
			CALL db_bic_get_datasource(FALSE) RETURNING l_arr_rec_bic 

		ON ACTION "GZU-BANK BRANCH MAINT" --ON KEY (F10) 
			CALL run_prog("GZU","","","","") 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW G536 

	RETURN l_rec_bic.bic_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_bic()
#######################################################################