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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E72_GLOBALS.4gl"
###########################################################################
# FUNCTION scan_customer(p_cmpy,p_cond_code)
#
# E72b - Inquiry program FOR Sales Conditions Customer Scan
###########################################################################
FUNCTION scan_customer(p_cmpy,p_cond_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cond_code LIKE condsale.cond_code	
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		cond_code LIKE customer.cond_code 
	END RECORD 
	DEFINE l_where_text char(200) 
	DEFINE l_query_text char(300) 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW E134 with FORM "E134" 
	 CALL windecoration_e("E134") -- albo kd-755 

	CLEAR FORM 
	ERROR kandoomsg2("E",1001,"") #" Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	cond_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E72b","construct-cust_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF not(int_flag OR quit_flag) THEN 
		ERROR kandoomsg2("E",1002,"") #1002 " Searching database - please wait "
		LET l_query_text = "SELECT cust_code,", 
		"name_text,", 
		"cond_code ", 
		"FROM customer ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text clipped," ", 
		"AND cond_code = \"",p_cond_code,"\" ", 
		"ORDER BY cust_code" 
		PREPARE s_condcust FROM l_query_text 
		DECLARE c_condcust cursor FOR s_condcust
		 
		LET l_idx = 1 
		FOREACH c_condcust INTO l_arr_rec_customer[l_idx].cust_code, 
			l_arr_rec_customer[l_idx].name_text, 
			l_arr_rec_customer[l_idx].cond_code 
			LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
			LET l_idx = l_idx + 1 
		END FOREACH 
		
		IF l_idx = 0 THEN 
			ERROR kandoomsg2("E",9044,"") 		#9044 No Customers Satisfied Selection Criteria "
		END IF 
		
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 

		MESSAGE kandoomsg2("E",1008,"") 		#1008 F3/F4 TO Page Fwd/Bwd - ESC TO Continue
		--INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* 
		DISPLAY ARRAY l_arr_rec_customer TO sr_customer.*
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","E72b","input-arr-l_arr_rec_customer-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW --FIELD scroll_flag 
				LET l_idx = arr_curr() 
				 
		END DISPLAY 

	END IF 
	
	CLOSE WINDOW E134 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE
	 
END FUNCTION