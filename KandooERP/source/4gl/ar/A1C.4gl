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
# Requires
# common/crhdwind.4gl
# common/cashwind.4gl
# common/inhdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A1C_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
GLOBALS 
	DEFINE modu_start_date DATE 
	DEFINE modu_end_date DATE 
END GLOBALS 
########################################################
# FUNCTION A1C_main()
#
# A1C
# allows the user TO scan the daily Receivable activity
# AND TO review the Audit Trail
########################################################
FUNCTION A1C_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A1C") 

	LET modu_start_date = today - 30 units day 
	LET modu_end_date = today 

	OPEN WINDOW A116 with FORM "A116" 
	CALL windecoration_a("A116") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE enter_dates() 
		CALL scan_audit() 
		CLEAR FORM 
	END WHILE 

	CLOSE WINDOW A116
	 
END FUNCTION
########################################################
# END FUNCTION A1C_main()
########################################################


########################################################
# FUNCTION enter_dates()
#
#
########################################################
FUNCTION enter_dates() 

	MESSAGE kandoomsg2("A",1017,"") 	#1017 Enter Date Range FOR audit selection - ESC TO continue

	#--------------------------------
	INPUT 
		modu_start_date,
		modu_end_date WITHOUT DEFAULTS 
	FROM
		start_date,
		end_date ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A1C","inp-date") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_end_date < modu_start_date THEN 
					ERROR kandoomsg2("A",9095,"") 		#9095 END date must be greater OR equal TO start date "
					NEXT FIELD end_date 
				END IF 
			END IF 

	END INPUT 
	#--------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
########################################################
# END FUNCTION enter_dates()
########################################################


########################################################
# FUNCTION db_araudit_get_datasource(p_filter)
#
#
########################################################
FUNCTION db_araudit_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arr_rec_araudit DYNAMIC ARRAY OF RECORD
		scroll_flag CHAR(1), 
		tran_date LIKE araudit.tran_date, 
		cust_code LIKE araudit.cust_code, 
		seq_num LIKE araudit.seq_num, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		currency_code LIKE customer.currency_code, 
		tran_amt LIKE araudit.tran_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter selection criteria - ESC TO continue
		CONSTRUCT BY NAME l_where_text ON 
			tran_date, 
			cust_code, 
			seq_num, 
			tran_type_ind, 
			source_num, 
			tran_text, 
			currency_code, 
			tran_amt 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A1C","construct-araudit") 
	
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

	MESSAGE kandoomsg2("U",1002,"") #1002 Searching Database; Please Wait.

	IF modu_start_date IS NOT NULL 
	AND modu_end_date IS NOT NULL THEN 
		LET l_query_text = 
			"SELECT * ", 
			"FROM araudit ", 
			"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
			"AND tran_date >= \"", modu_start_date, "\" ", 
			"AND tran_date <= \"", modu_end_date, "\" ", 
			"AND ", l_where_text clipped, " ", 
			"ORDER BY tran_date, cust_code, seq_num" 
	ELSE 
		LET l_query_text = 
			"SELECT * ", 
			"FROM araudit ", 
			"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
			"AND ", l_where_text clipped, " ", 
			"ORDER BY tran_date, cust_code, seq_num" 
	END IF 

	PREPARE s_araudit FROM l_query_text 
	DECLARE c_araudit CURSOR FOR s_araudit 

	LET l_idx = 0 
	FOREACH c_araudit INTO l_rec_araudit.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_araudit[l_idx].scroll_flag = NULL 
		LET l_arr_rec_araudit[l_idx].tran_date = l_rec_araudit.tran_date 
		LET l_arr_rec_araudit[l_idx].cust_code = l_rec_araudit.cust_code 
		LET l_arr_rec_araudit[l_idx].seq_num = l_rec_araudit.seq_num 
		LET l_arr_rec_araudit[l_idx].tran_type_ind = l_rec_araudit.tran_type_ind 
		LET l_arr_rec_araudit[l_idx].source_num = l_rec_araudit.source_num 
		LET l_arr_rec_araudit[l_idx].tran_text = l_rec_araudit.tran_text 
		LET l_arr_rec_araudit[l_idx].tran_amt = l_rec_araudit.tran_amt 
		LET l_arr_rec_araudit[l_idx].currency_code = l_rec_araudit.currency_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 


	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9097,"") 		#9097 No audits satisfied selection criteria
	END IF 

	RETURN l_arr_rec_araudit 
END FUNCTION 
########################################################
# END FUNCTION db_araudit_get_datasource(p_filter)
########################################################


########################################################
# FUNCTION scan_audit()
#
#
########################################################
FUNCTION scan_audit() 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_arr_rec_araudit DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		tran_date LIKE araudit.tran_date, 
		cust_code LIKE araudit.cust_code, 
		seq_num LIKE araudit.seq_num, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		currency_code LIKE customer.currency_code, 
		tran_amt LIKE araudit.tran_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL l_arr_rec_araudit.clear()
	CALL db_araudit_get_datasource(FALSE) RETURNING l_arr_rec_araudit

	MESSAGE kandoomsg2("A",1007,"") #1007 F3/F4 TO page forward backward RETURN on line TO View
	DISPLAY ARRAY l_arr_rec_araudit TO sr_araudit.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A1C","inp-arr-araudit") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("View",NOT l_arr_rec_araudit.getSize())			
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_araudit.clear()
			CALL db_araudit_get_datasource(TRUE) RETURNING l_arr_rec_araudit

		BEFORE ROW  
			LET l_idx = arr_curr() 

		ON ACTION ("View","DOUBLECLICK","ACCEPT") 
			CASE l_arr_rec_araudit[l_idx].tran_type_ind 
				WHEN TRAN_TYPE_INVOICE_IN 
					CALL disc_per_head(glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_araudit[l_idx].cust_code, 
					l_arr_rec_araudit[l_idx].source_num) 
 
				WHEN TRAN_TYPE_RECEIPT_CA 
					CALL cash_disp(glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_araudit[l_idx].cust_code, 
					l_arr_rec_araudit[l_idx].source_num) 
 
				WHEN TRAN_TYPE_CREDIT_CR 
					CALL cr_disp_head(glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_araudit[l_idx].cust_code, 
					l_arr_rec_araudit[l_idx].source_num) 
 
			END CASE 

	END DISPLAY 
	#----------------------------------

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
########################################################
# END FUNCTION scan_audit()
########################################################