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
GLOBALS "../eo/E71_GLOBALS.4gl"
###########################################################################
# E71d - Maintainence program FOR Sales Conditions Customer add/remove.
###########################################################################
################################################################################
# FUNCTION db_customer_t_table_get_datasource(p_filter)
#
#
################################################################################
FUNCTION db_customer_t_table_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		cond_code LIKE customer.cond_code 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_idx SMALLINT  

	SELECT unique 1 FROM t_condcust 
	IF status = NOTFOUND THEN 
		MESSAGE kandoomsg2("E",1002,"") #1002 " Searching database - please wait "

		INSERT INTO t_condcust 
		SELECT 
			cust_code, 
			name_text, 
			cond_code, 
			cond_code 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code IS NULL 
		AND delete_flag = "N" 
	END IF 


	IF p_filter THEN
		CLEAR FORM 
	
		MESSAGE kandoomsg2("E",1001,"") #" Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			name_text, 
			cond_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E71d","construct-condcust") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	 
	MESSAGE kandoomsg2("E",1002,"") #1002 " Searching database - please wait "
	LET l_query_text = "SELECT cust_code,", 
	"name_text,", 
	"cond_code ", 
	"FROM t_condcust ", 
	"WHERE ",l_where_text clipped," ", 
	"ORDER BY cust_code" 
	PREPARE s_condcust FROM l_query_text 
	DECLARE c_condcust cursor FOR s_condcust 

	LET l_idx = 1 
	FOREACH c_condcust INTO l_arr_rec_customer[l_idx].cust_code, 
			l_arr_rec_customer[l_idx].name_text, 
			l_arr_rec_customer[l_idx].cond_code 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	 
		LET l_idx = l_idx + 1 
	END FOREACH 
	
	IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN 
		CALL l_arr_rec_customer.delete(l_idx)
	END IF
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9044,"")	#9044 No Customers Satisfied Selection Criteria "
	END IF 

	RETURN l_arr_rec_customer 

END FUNCTION 
################################################################################
# END FUNCTION db_customer_t_table_get_datasource(p_filter)
################################################################################

################################################################################
# FUNCTION scan_customer_event_manager(p_size)
#
#
################################################################################
FUNCTION scan_customer_event_manager(p_size,p_cond_code)
	DEFINE p_size SMALLINT
	DEFINE p_cond_code STRING

	IF p_size = 0 THEN
		CALL dialog.setActionHidden("ADD",    TRUE)
		CALL dialog.setActionHidden("DELETE", TRUE)
	ELSE
		IF p_cond_code IS NULL THEN 
			CALL dialog.setActionHidden("ADD",    TRUE)
			CALL dialog.setActionHidden("DELETE", FALSE)
		ELSE
			CALL dialog.setActionHidden("ADD",    FALSE)
			CALL dialog.setActionHidden("DELETE", TRUE)
		END IF
	END IF
	
	CALL dialog.setActionHidden("ADD",    NOT p_size)
	CALL dialog.setActionHidden("DELETE", NOT p_size)
END FUNCTION
################################################################################
# END FUNCTION scan_customer_event_manager(p_size)
################################################################################

################################################################################
# FUNCTION scan_customer()
#
#
################################################################################
FUNCTION scan_customer() 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		cond_code LIKE customer.cond_code 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_idx SMALLINT  
 
	CALL db_customer_t_table_get_datasource(FALSE) RETURNING l_arr_rec_customer
	#Note: ADD = Add a condition, NOT add/insert a new row...
	MESSAGE kandoomsg2("E",1012,"") #1012 "RETURN TO Include Condition - F2 TO Remove Condition "
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E71d","inp-arr-l_arr_rec_customer")
			-- ACCEPT = Confirm input --CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("ADD",    TRUE)
			CALL dialog.setActionHidden("DELETE", TRUE)
 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL db_customer_t_table_get_datasource(TRUE) RETURNING l_arr_rec_customer
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code)
			
		ON ACTION "REFRESH"
			CALL l_arr_rec_customer.clear()
			CALL db_customer_t_table_get_datasource(FALSE) RETURNING l_arr_rec_customer
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code)

		ON ACTION "ADD" --BEFORE FIELD cust_code #?what is this ???? 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN 
				IF l_arr_rec_customer[l_idx].cond_code = glob_rec_condsale.cond_code THEN 
					SELECT old_cond_code 
					INTO l_arr_rec_customer[l_idx].cond_code 
					FROM t_condcust 
					WHERE cust_code = l_arr_rec_customer[l_idx].cust_code 
				ELSE 
					LET l_arr_rec_customer[l_idx].cond_code = glob_rec_condsale.cond_code 
				END IF 
			END IF 
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code) 

--		ON ACTION "Toggle" #include/exclude condition  ????? action link via next field
--			NEXT FIELD cust_code 

		ON ACTION "DELETE" --ON KEY (f2) --remove condition / set it to NULL
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN 
				LET l_arr_rec_customer[l_idx].cond_code = null
			END IF 
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code)

		ON ACTION "TOGGLE" --BEFORE FIELD cust_code #?what is this ???? 
			IF l_arr_rec_customer[l_idx].cust_code IS NOT NULL THEN 
				IF l_arr_rec_customer[l_idx].cond_code = glob_rec_condsale.cond_code THEN 
					SELECT old_cond_code 
					INTO l_arr_rec_customer[l_idx].cond_code 
					FROM t_condcust 
					WHERE cust_code = l_arr_rec_customer[l_idx].cust_code 
				ELSE 
					LET l_arr_rec_customer[l_idx].cond_code = glob_rec_condsale.cond_code 
				END IF 
			END IF 
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code) 
			
		BEFORE ROW --FIELD scroll_flag 
			LET l_idx = arr_curr()
			CALL scan_customer_event_manager(l_arr_rec_customer.getSize(),l_arr_rec_customer[l_idx].cond_code)
			
	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		FOR l_idx = 1 TO l_arr_rec_customer.getSize() 
			IF l_arr_rec_customer[l_idx].cust_code IS NOT NULL THEN 
				UPDATE t_condcust 
				SET cond_code = l_arr_rec_customer[l_idx].cond_code 
				WHERE cust_code = l_arr_rec_customer[l_idx].cust_code 
			END IF 
		END FOR 
	END IF 

END FUNCTION
################################################################################
# END FUNCTION scan_customer()
################################################################################