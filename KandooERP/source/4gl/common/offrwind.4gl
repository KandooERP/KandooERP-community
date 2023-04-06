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
#   offerwind.4gl - show_offer
#                   Window FUNCTION FOR finding a offersale records
#                   FUNCTION will RETURN offer_code TO calling program

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,p_filter) 
#
#
###########################################################################
FUNCTION db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,p_filter)
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_offersale DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text 
	END RECORD 
				
	#save guard
	IF p_filter_text IS NULL THEN
		LET p_filter_text = " 1=1 "
	END IF	
		
	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			offer_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","offrwind","construct-offersale") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_offersale.offer_code = NULL 
			LET l_where_text = " 1=1 "		 
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF

		MESSAGE kandoomsg("U",1002,"")		#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM offersale ", 
			"WHERE cmpy_code = \"",p_cmpy_code,"\" ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_text CLIPPED," ", 
			"ORDER BY offer_code" 
		
		WHENEVER ERROR CONTINUE 
 
		PREPARE s_offersale FROM l_query_text 
		DECLARE c_offersale CURSOR FOR s_offersale 

		LET l_idx = 0 
		FOREACH c_offersale INTO l_rec_offersale.* 
			LET l_idx = l_idx + 1 
			LET l_arr_offersale[l_idx].offer_code = l_rec_offersale.offer_code 
			LET l_arr_offersale[l_idx].desc_text = l_rec_offersale.desc_text 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF				
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)		#9113 "l_idx records selected"

		WHENEVER ERROR stop 

	RETURN l_arr_offersale
END FUNCTION
###########################################################################
# END FUNCTION db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,p_filter) 
###########################################################################


###########################################################################
# FUNCTION show_offer(p_cmpy_code,p_filter_text) 
#
#
###########################################################################
FUNCTION show_offer(p_cmpy_code,p_filter_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_arr_offersale DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 
	
	OPEN WINDOW E103 with FORM "E103" 
	CALL windecoration_e("E103")  

	CALL db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,FALSE) RETURNING l_arr_offersale

	MESSAGE kandoomsg2("U",1006,"")#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_offersale TO sr_offersale.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","offrwind","input-arr-offersale") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_offersale.getSize()) THEN
				LET l_rec_offersale.offer_code = l_arr_offersale[l_idx].offer_code
			END IF 

		AFTER DISPLAY
			LET l_idx = arr_curr() 
			IF (l_idx > 0) AND (l_idx <= l_arr_offersale.getSize()) THEN
				LET l_rec_offersale.offer_code = l_arr_offersale[l_idx].offer_code
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Special Offers Manager"	--ON KEY (F10) 
			CALL run_prog("E61","","","","") 

		ON ACTION "FILTER"
			CALL l_arr_offersale.clear()
			CALL db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,TRUE) RETURNING l_arr_offersale

		ON ACTION "REFRESH"
			CALL windecoration_e("E103")  
			CALL l_arr_offersale.clear()
			CALL db_offersale_show_offer_get_datasource(p_cmpy_code,p_filter_text,TRUE) RETURNING l_arr_offersale
			
	END DISPLAY
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	
	CLOSE WINDOW E103
	 
	RETURN l_rec_offersale.offer_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_offer(p_cmpy_code,p_filter_text) 
###########################################################################