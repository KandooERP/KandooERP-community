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
# FUNCTION invext_select(p_cmpy)
#
# A hot FUNCTION KEY that IS used FOR extended
# selection criteria in cash/credit application
# screens which will allow the user TO enter
# invoice details FOR QBE
###########################################################################
FUNCTION invext_select(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_where_text CHAR(510) 
	DEFINE l_where1_text CHAR(800) 
	DEFINE l_temp_text CHAR(32) 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	SELECT inv_ref1_text 
	INTO l_ref_text 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	
	LET l_temp_text = l_ref_text clipped,"................" 
	LET l_ref_text = l_temp_text 

	OPEN WINDOW A192 with FORM "A192" 
	CALL windecoration_a("A192")

	DISPLAY l_ref_text TO arparms.inv_ref1_text 
	ERROR kandoomsg2("A",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where1_text ON 
		cust_code, 
		org_cust_code, 
		inv_num, 
		inv_ind, 
		ord_num, 
		job_code, 
		goods_amt, 
		tax_amt, 
		hand_amt, 
		freight_amt, 
		total_amt, 
		paid_amt, 
		inv_date, 
		due_date, 
		disc_date, 
		paid_date, 
		disc_amt, 
		disc_taken_amt, 
		year_num, 
		period_num, 
		posted_flag, 
		on_state_flag, 
		ref_num, 
		purchase_code, 
		sale_code, 
		entry_code, 
		entry_date, 
		rev_date, 
		rev_num, 
		com1_text, 
		com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","invextfunc","construct-invoicedetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	CLOSE WINDOW A192 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL 
	END IF 
	
	IF length(l_where1_text) > 512 THEN 
		LET l_where_text = "1=1" 
		ERROR kandoomsg2("A",9075,"") 		#9075 "Invalid Search Criteria "
	ELSE 
		LET l_where_text = l_where1_text 
	END IF 

	RETURN l_where_text 
END FUNCTION 
###########################################################################
# END FUNCTION invext_select(p_cmpy)
###########################################################################