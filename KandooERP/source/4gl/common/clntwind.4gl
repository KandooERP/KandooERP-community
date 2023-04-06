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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

###########################################################################
# FUNCTION db_customer_filter_datasource(p_filter,p_report_ord_flag) 
#
#
###########################################################################
FUNCTION db_customer_filter_datasource(p_filter,p_report_ord_flag) 
	DEFINE p_filter boolean 
	DEFINE p_report_ord_flag LIKE arparms.report_ord_flag 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF t_rec_customer_cc_nt_tt_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter criteria - press ESC TO continue"
		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			name_text, 
			tele_text, 
			addr1_text, 
			addr2_text, 
			city_text, 
			state_code, 
			post_code, 
			country_code, 
			contact_text, 
			corp_cust_code, 
			type_code, 
			sale_code, 
			term_code, 
			tax_code, 
			vat_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","clntwind","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_customer.cust_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 


	MESSAGE kandoomsg2("U",1002,"") 

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped 

	IF p_report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY name_text" 
	END IF 

	LET l_idx = 0 
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].tele_text = l_rec_customer.tele_text 
		#		IF l_idx = 100 THEN
		#		ERROR kandoomsg2("U",6100,l_idx)
		#		EXIT FOREACH
		#		END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH
	 
	ERROR kandoomsg2("U",9113,l_idx) #9113 l_idx records selected

	RETURN l_arr_rec_customer 
END FUNCTION 
###########################################################################
# END FUNCTION db_customer_filter_datasource(p_filter,p_report_ord_flag) 
###########################################################################


#######################################################################
# FUNCTION show_clnt(p_cmpy)
#
#       clntwind.4gl - show_clnt
#                      window FUNCTION TO find customer records
#                      returns customer code
#######################################################################
FUNCTION show_clnt(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF t_rec_customer_cc_nt_tt_with_scrollflag 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_idx SMALLINT 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 

	OPEN WINDOW A107 with FORM "A107" 
	CALL windecoration_a("A107") 

	#   WHILE TRUE
	IF db_customer_get_count() > 1000 THEN 
		CALL db_customer_filter_datasource(true,l_rec_arparms.report_ord_flag) RETURNING l_arr_rec_customer 
	ELSE 
		CALL db_customer_filter_datasource(false,l_rec_arparms.report_ord_flag) RETURNING l_arr_rec_customer 
	END IF 
	-----------------

	IF l_arr_rec_customer.getlength() =0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_customer[1].* TO NULL 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	OPTIONS SQL interrupt off 

	MESSAGE kandoomsg2("U",1006,"")	#U1006 "Esc on line TO SELECT - F10 TO add"
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","clntwind.4gl","input-arr-customer") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize())			
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_customer_filter_datasource(true,l_rec_arparms.report_ord_flag) RETURNING l_arr_rec_customer 

		ON KEY (F10) 
			CALL run_prog("A11","","","","") 
			CALL comboList_customer("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL db_customer_filter_datasource(false,l_rec_arparms.report_ord_flag) RETURNING l_arr_rec_customer
			 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 
				LET l_rec_customer.cust_code = l_arr_rec_customer[l_idx].cust_code 
			END IF 

			SELECT * INTO l_rec_customer.* 
			FROM customer 
			WHERE cust_code = l_arr_rec_customer[l_idx].cust_code 
			AND cmpy_code = p_cmpy 

			DISPLAY BY NAME l_rec_customer.type_code, 
			l_rec_customer.sale_code, 
			l_rec_customer.term_code, 
			l_rec_customer.tax_code, 
			l_rec_customer.vat_code, 
			l_rec_customer.addr1_text, 
			l_rec_customer.addr2_text, 
			l_rec_customer.city_text, 
			l_rec_customer.state_code, 
			l_rec_customer.post_code, 
			l_rec_customer.country_code, 
			l_rec_customer.contact_text, 
			l_rec_customer.corp_cust_code 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_rec_customer.cust_code = l_arr_rec_customer[l_idx].cust_code 
	END IF 

	CLOSE WINDOW A107 

	RETURN l_rec_customer.cust_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_clnt(p_cmpy)
#######################################################################