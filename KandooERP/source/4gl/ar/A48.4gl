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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A48_GLOBALS.4gl" 

############################################################
# MAIN
#
# allows the user TO scan non fully applied memos AND THEN
# apply those memos
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("A48") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A123 with FORM "A123" 
	CALL windecoration_a("A123") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL select_cred() 

	CLOSE WINDOW A123 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION db_credithead_get_datasource(p_filter)
#
#
############################################################
FUNCTION db_credithead_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_idx SMALLINT
	DEFINE l_query_text CHAR (900) 
	DEFINE l_where_text CHAR (900) 

	IF p_filter THEN	
		CLEAR FORM 
		
		MESSAGE kandoomsg2("U",1001,"") 		#1001 Enter Selection Criteria - OK TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cred_num, 
			cust_code, 
			cred_date, 
			year_num, 
			period_num, 
			total_amt, 
			appl_amt, 
			posted_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A48","construct-credithead") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF

		LET l_query_text = 
			"SELECT * FROM credithead ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
			"AND appl_amt != total_amt ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY cred_num" 
		
	MESSAGE kandoomsg2("U",1002,"")#1002 Searching Database
	PREPARE s_credhd FROM l_query_text 
	DECLARE c_credhd CURSOR FOR s_credhd 
	LET l_idx = 0 
	
	FOREACH c_credhd INTO glob_rec_credithead.* 
		LET l_idx = l_idx + 1 
		LET glob_arr_rec_credithead[l_idx].cred_num = glob_rec_credithead.cred_num 
		LET glob_arr_rec_credithead[l_idx].cust_code = glob_rec_credithead.cust_code 
		LET glob_arr_rec_credithead[l_idx].cred_date = glob_rec_credithead.cred_date 
		LET glob_arr_rec_credithead[l_idx].year_num = glob_rec_credithead.year_num 
		LET glob_arr_rec_credithead[l_idx].period_num = glob_rec_credithead.period_num 
		LET glob_arr_rec_credithead[l_idx].total_amt = glob_rec_credithead.total_amt 
		LET glob_arr_rec_credithead[l_idx].appl_amt = glob_rec_credithead.appl_amt 
		LET glob_arr_rec_credithead[l_idx].posted_flag = glob_rec_credithead.posted_flag 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected
		RETURN true 
	END IF

END FUNCTION
############################################################
# END FUNCTION db_credithead_get_datasource(p_filter)
############################################################


############################################################
# FUNCTION select_cred()
#
#
############################################################
FUNCTION select_cred() 
	DEFINE l_idx SMALLINT
	DEFINE l_orig_cred_num LIKE credithead.cred_num 

	CALL db_credithead_get_datasource(FALSE)
	 
	OPTIONS INSERT KEY f35 
	OPTIONS DELETE KEY f36 
	
	MESSAGE kandoomsg2("A",1092,"") #1092 MESSAGE " RETURN on line TO Apply Credit - F5 Customer Inquiry"
	--INPUT ARRAY glob_arr_rec_credithead WITHOUT DEFAULTS FROM sr_credithead.* ATTRIBUTE(UNBUFFERED) 
	DISPLAY ARRAY glob_arr_rec_credithead TO sr_credithead.* ATTRIBUTE(UNBUFFERED)	
		BEFORE DISPLAY
			CALL publish_toolbar("kandoo","A48","inp-arr-credithead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL glob_arr_rec_credithead.clear()
			CALL db_credithead_get_datasource(TRUE)

		ON ACTION "REFRESH"
			CALL windecoration_a("A123")
			CALL glob_arr_rec_credithead.clear()
			CALL db_credithead_get_datasource(FALSE)

		ON ACTION "Customer Details"	
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_arr_rec_credithead[l_idx].cust_code) --customer details 

		ON ACTION ("ACCEPT","DOUBLECLICK")	
			LET glob_arr_rec_credithead[l_idx].cred_num = l_orig_cred_num 

			IF glob_arr_rec_credithead[l_idx].cred_num > 0 THEN  
				CALL cred_appl(glob_arr_rec_credithead[l_idx].cred_num, glob_rec_kandoouser.sign_on_code) 
				SELECT appl_amt INTO glob_arr_rec_credithead[l_idx].appl_amt FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_arr_rec_credithead[l_idx].cust_code 
				AND cred_num = glob_arr_rec_credithead[l_idx].cred_num 
			END IF 
			CALL db_credithead_get_datasource(FALSE)

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_orig_cred_num = glob_arr_rec_credithead[l_idx].cred_num 

	END DISPLAY 
	
	LET int_flag = false 
	LET quit_flag = false 
	
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION select_cred()
############################################################