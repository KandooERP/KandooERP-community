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
#   carrwind.4gl - show_carrier
#                  Window FUNCTION FOR finding a Carrier record
#                  FUNCTION will RETURN carrier_code TO calling program
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"   

############################################################
# FUNCTION show_carrier(p_cmpy,p_filter_text)
#
#
############################################################
FUNCTION show_carrier(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300) 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_pr_carrier RECORD LIKE carrier.* 
	DEFINE l_arr_carrier DYNAMIC ARRAY OF RECORD
		scroll_flag CHAR(1), 
		carrier_code LIKE carrier.carrier_code, 
		name_text LIKE carrier.name_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = notfound THEN 
		ERROR kandoomsg2("U",5100,"") 	#5003 Company NOT SET up - Refer System Administrator
		RETURN "" 
	END IF 

	IF l_rec_company.module_text[5] != "E" THEN 
		ERROR kandoomsg2("E",9177,"")	#9177 Carrier lookup NOT available
		RETURN "" 
	END IF 

	OPEN WINDOW e169 with FORM "E169" 
	CALL windecoration_e("E169") -- albo kd-755 

	WHILE true 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON carrier_code, name_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","carrwind","construct-carrier") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_pr_carrier.carrier_code = NULL 
			EXIT WHILE 
		END IF 
		
		MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"

		LET l_query_text = "SELECT * FROM carrier ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text clipped," ", 
		"AND ",p_filter_text clipped," ", 
		"ORDER BY carrier_code" 

		PREPARE s_carrier FROM l_query_text 
		DECLARE c_carrier CURSOR FOR s_carrier 

		LET l_idx = 0 
		FOREACH c_carrier INTO l_rec_pr_carrier.* 
			LET l_idx = l_idx + 1 
			LET l_arr_carrier[l_idx].carrier_code = l_rec_pr_carrier.carrier_code 
			LET l_arr_carrier[l_idx].name_text = l_rec_pr_carrier.name_text 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)		#U9113 l_idx records selected

		
		MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"
		INPUT ARRAY l_arr_carrier WITHOUT DEFAULTS FROM sr_carrier.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","carrwind","input-arr-carrier") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 

			ON ACTION "CARRIER MAINTENANCE" --ON KEY (F10) 
				CALL run_prog("EZ4","","","","") 
				NEXT FIELD scroll_flag 

			BEFORE FIELD carrier_code 
				LET l_rec_pr_carrier.carrier_code = l_arr_carrier[l_idx].carrier_code 
				EXIT INPUT 

			AFTER INPUT 
				LET l_rec_pr_carrier.carrier_code = l_arr_carrier[l_idx].carrier_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW E169 

	RETURN l_rec_pr_carrier.carrier_code 
END FUNCTION 
############################################################
# END FUNCTION show_carrier(p_cmpy,p_filter_text)
############################################################