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

# \brief module A49 scans the cash receipts FOR receipts NOT fully applied

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A49_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_ans LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("A49") 
	CALL ui_init(0) 


	DEFER interrupt 
	DEFER quit 
	CALL authenticate(getmoduleid()) 
--	LET l_ans = "Y" 
--	WHILE l_ans = "Y" 
		CALL doit() 
 
--	END WHILE 
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
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF RECORD 
		cred_num LIKE credithead.cred_num, 
		cust_code LIKE credithead.cust_code , 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD	
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_idx SMALLINT
	DEFINE l_sel_text CHAR(900)
	DEFINE l_where_credit CHAR(900)
	
	IF p_filter THEN
		MESSAGE " Enter selection criteria AND press ESC TO begin search" attribute (yellow) 
	
		CONSTRUCT BY NAME l_where_credit ON 
			cred_num, 
			cust_code, 
			cred_date, 
			year_num, 
			period_num, 
			total_amt, 
			posted_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A49","construct-credithead") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 

		IF int_flag != 0 
		OR quit_flag != 0 THEN 
			LET l_where_credit = " 1=1 " 
		END IF 

	ELSE
		LET l_where_credit = " 1=1 "
	END IF

	LET l_sel_text = 
		"SELECT * ", 
		"FROM credithead WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
		" AND appl_amt <> 0 ", 
		" AND ", l_where_credit clipped, 
		" ORDER BY cred_num " 

	PREPARE getcredit FROM l_sel_text 
	DECLARE c_cred CURSOR FOR getcredit 
	OPEN c_cred 

	LET l_idx = 0 
	FOREACH c_cred INTO l_rec_credithead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
		LET l_arr_rec_credithead[l_idx].cust_code = l_rec_credithead.cust_code 
		LET l_arr_rec_credithead[l_idx].cred_date = l_rec_credithead.cred_date 
		LET l_arr_rec_credithead[l_idx].year_num = l_rec_credithead.year_num 
		LET l_arr_rec_credithead[l_idx].period_num = l_rec_credithead.period_num 
		LET l_arr_rec_credithead[l_idx].total_amt = l_rec_credithead.total_amt 
		LET l_arr_rec_credithead[l_idx].appl_amt = l_rec_credithead.appl_amt 
		LET l_arr_rec_credithead[l_idx].posted_flag = l_rec_credithead.posted_flag

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	RETURN l_arr_rec_credithead	
END FUNCTION	
############################################################
# END FUNCTION db_credithead_get_datasource(p_filter)
############################################################


############################################################
# FUNCTION doit() 
#
#
############################################################
FUNCTION doit()
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF RECORD 
		cred_num LIKE credithead.cred_num, 
		cust_code LIKE credithead.cust_code , 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD
	DEFINE l_idx SMALLINT
	
	OPEN WINDOW A123 with FORM "A123" 
	CALL windecoration_a("A123") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL db_credithead_get_datasource(FALSE) RETURNING l_arr_rec_credithead


	#   MESSAGE ""
	MESSAGE " RETURN on line TO unapply credit " attribute (yellow) 

#	INPUT ARRAY l_arr_rec_credithead WITHOUT DEFAULTS FROM sr_credithead.* ATTRIBUTE(UNBUFFERED) 
	DISPLAY ARRAY l_arr_rec_credithead TO sr_credithead.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A49","inp-arr-credithead") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_credithead.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_rec_credithead.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_credithead.clear()
			CALL db_credithead_get_datasource(TRUE) RETURNING l_arr_rec_credithead
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_credithead.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_rec_credithead.getSize())
					
		ON ACTION "REFRESH"
			CALL windecoration_a("A123")
			CALL l_arr_rec_credithead.clear()
			CALL db_credithead_get_datasource(FALSE) RETURNING l_arr_rec_credithead
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_credithead.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_rec_credithead.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("ACCEPT","DOUBLECLICK")
		--BEFORE FIELD cust_code 
			IF l_arr_rec_credithead[l_idx].appl_amt <> 0 THEN 
				IF kandoomsg("A",8024,l_arr_rec_credithead[l_idx].cred_num) = "Y" THEN 
					#8020 Confirm TO unappply credit ???
					ERROR kandoomsg2("A",1002,"") 			#1002 Searching database please wait

					CALL unapply_credit_from_invoice_receipt(glob_rec_kandoouser.cmpy_code, l_arr_rec_credithead[l_idx].cust_code, 
					l_arr_rec_credithead[l_idx].cred_num, glob_rec_kandoouser.sign_on_code) 

					SELECT appl_amt INTO l_arr_rec_credithead[l_idx].appl_amt FROM credithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cred_num = l_arr_rec_credithead[l_idx].cred_num 
					--LET l_arr_rec_credithead[l_idx].appl_amt = l_rec_credithead.appl_amt 
				END IF 
			END IF 
 
			MESSAGE " RETURN on line TO unapply credit " attribute (yellow) 
			NEXT FIELD cred_num 


	END DISPLAY 

	LET int_flag = 0 
	LET quit_flag = 0
	
	CLOSE WINDOW A123 

END FUNCTION
############################################################
# END FUNCTION doit() 
############################################################