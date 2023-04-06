{
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:29	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P47 allows the user TO Scan Client cheques THEN edit
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 

############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P47") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp133 at 2,3 with FORM "P133" 
	CALL windecoration_p("P133") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_vend() 

	CLOSE WINDOW wp133 
END MAIN 



############################################################
# FUNCTION db_cheque_get_datasource(p_filter)
#
# RETURN l_arr_cheque,l_arr_cheque_info
############################################################
FUNCTION db_cheque_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_arr_cheque DYNAMIC ARRAY OF RECORD 
				scroll_flag CHAR(1), 
				vend_code LIKE cheque.vend_code, 
				bank_code LIKE cheque.bank_code, 
				cheq_code LIKE cheque.cheq_code, 
				net_pay_amt LIKE cheque.net_pay_amt, 
				cheq_date LIKE cheque.cheq_date, 
				pay_meth_ind LIKE cheque.pay_meth_ind 
	END RECORD 
	DEFINE l_arr_cheque_info DYNAMIC ARRAY OF RECORD
				pay_amt LIKE cheque.pay_amt, 
				apply_amt LIKE cheque.apply_amt, 
				com3_text LIKE cheque.com3_text, 
				post_flag LIKE cheque.post_flag, 
				year_num LIKE cheque.year_num, 
				period_num LIKE cheque.period_num 
	END RECORD 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	IF p_filter THEN
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria; OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON cheque.vend_code, 
		cheque.bank_code, 
		cheque.cheq_code, 
		cheque.net_pay_amt, 
		cheque.cheq_date, 
		cheque.pay_meth_ind, 
		cheque.pay_amt, 
		cheque.apply_amt, 
		cheque.com3_text, 
		cheque.post_flag, 
		cheque.year_num, 
		cheque.period_num 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P47","construct-cheque-1") 
	
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

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait.
	LET l_query_text = "SELECT * FROM cheque ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cheq_code != 0 ", 
	" AND cheq_code IS NOT NULL ", 
	" AND pay_meth_ind = '1' ", 
	" AND ",l_where_text clipped," ", 
	" ORDER BY cheq_code" 
	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque
	 
	LET idx = 0 
	FOREACH c_cheque INTO l_rec_cheque.* 
		LET idx = idx + 1 
		LET l_arr_cheque[idx].vend_code = l_rec_cheque.vend_code 
		LET l_arr_cheque[idx].bank_code = l_rec_cheque.bank_code 
		LET l_arr_cheque[idx].cheq_code = l_rec_cheque.cheq_code 
		LET l_arr_cheque[idx].net_pay_amt = l_rec_cheque.net_pay_amt 
		LET l_arr_cheque[idx].cheq_date = l_rec_cheque.cheq_date 
		LET l_arr_cheque[idx].pay_meth_ind = l_rec_cheque.pay_meth_ind 
		LET l_arr_cheque_info[idx].pay_amt = l_rec_cheque.pay_amt 
		LET l_arr_cheque_info[idx].apply_amt = l_rec_cheque.apply_amt 
		LET l_arr_cheque_info[idx].com3_text = l_rec_cheque.com3_text 
		LET l_arr_cheque_info[idx].post_flag = l_rec_cheque.post_flag 
		LET l_arr_cheque_info[idx].year_num = l_rec_cheque.year_num 
		LET l_arr_cheque_info[idx].period_num = l_rec_cheque.period_num 
	END FOREACH
	 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected

	RETURN l_arr_cheque,l_arr_cheque_info
END FUNCTION

############################################################
# FUNCTION scan_vend()
#
#
############################################################
FUNCTION scan_vend() 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_arr_cheque DYNAMIC ARRAY OF RECORD 
				scroll_flag CHAR(1), 
				vend_code LIKE cheque.vend_code, 
				bank_code LIKE cheque.bank_code, 
				cheq_code LIKE cheque.cheq_code, 
				net_pay_amt LIKE cheque.net_pay_amt, 
				cheq_date LIKE cheque.cheq_date, 
				pay_meth_ind LIKE cheque.pay_meth_ind 
	END RECORD 
	DEFINE l_arr_cheque_info DYNAMIC ARRAY OF RECORD
				pay_amt LIKE cheque.pay_amt, 
				apply_amt LIKE cheque.apply_amt, 
				com3_text LIKE cheque.com3_text, 
				post_flag LIKE cheque.post_flag, 
				year_num LIKE cheque.year_num, 
				period_num LIKE cheque.period_num 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT
	DEFINE i SMALLINT
	DEFINE j SMALLINT

	CALL db_cheque_get_datasource(FALSE) RETURNING l_arr_cheque,l_arr_cheque_info
	
	LET l_msgresp = kandoomsg("P",1044,"") #1044 ENTER on line TO EDIT
	
	DISPLAY ARRAY l_arr_cheque TO sr_cheque.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P47","inp-arr-cheque-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_cheque.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_cheque.getSize())

		BEFORE ROW 
			LET idx = arr_curr() 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_cheque.clear()
			CALL l_arr_cheque_info.clear()
			CALL db_cheque_get_datasource(TRUE) RETURNING l_arr_cheque,l_arr_cheque_info

			DISPLAY BY NAME 
				l_arr_cheque_info[idx].pay_amt, 
				l_arr_cheque_info[idx].apply_amt, 
				l_arr_cheque_info[idx].com3_text, 
				l_arr_cheque_info[idx].post_flag, 
				l_arr_cheque_info[idx].year_num, 
				l_arr_cheque_info[idx].period_num 

		ON ACTION ("ACCEPT","DOUBLECLICK")
			IF l_arr_cheque[idx].cheq_code IS NULL OR l_arr_cheque[idx].cheq_code = 0 THEN 
			ELSE 
				SELECT * INTO l_rec_bank.* FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_arr_cheque[idx].bank_code 
				
				CALL input_cheque(glob_rec_kandoouser.cmpy_code, l_rec_bank.acct_code, l_arr_cheque[idx].cheq_code) 
				
				SELECT * 
				INTO l_rec_cheque.* 
				FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_arr_cheque[idx].bank_code 
				AND cheq_code = l_arr_cheque[idx].cheq_code 
				AND cheq_code != 0 
				AND cheq_code IS NOT NULL 
				AND vend_code = l_arr_cheque[idx].vend_code 
				AND pay_meth_ind = "1"
				 
				LET l_arr_cheque[idx].vend_code = l_rec_cheque.vend_code 
				LET l_arr_cheque[idx].bank_code = l_rec_cheque.bank_code 
				LET l_arr_cheque[idx].cheq_code = l_rec_cheque.cheq_code 
				LET l_arr_cheque[idx].net_pay_amt = l_rec_cheque.net_pay_amt 
				LET l_arr_cheque[idx].cheq_date = l_rec_cheque.cheq_date 
				LET l_arr_cheque[idx].pay_meth_ind = l_rec_cheque.pay_meth_ind 
				LET l_arr_cheque_info[idx].pay_amt = l_rec_cheque.pay_amt 
				LET l_arr_cheque_info[idx].apply_amt = l_rec_cheque.apply_amt 
				LET l_arr_cheque_info[idx].com3_text = l_rec_cheque.com3_text 
				LET l_arr_cheque_info[idx].post_flag = l_rec_cheque.post_flag 
				LET l_arr_cheque_info[idx].year_num = l_rec_cheque.year_num 
				LET l_arr_cheque_info[idx].period_num = l_rec_cheque.period_num 

				DISPLAY BY NAME 
					l_arr_cheque_info[idx].pay_amt, 
					l_arr_cheque_info[idx].apply_amt, 
					l_arr_cheque_info[idx].com3_text, 
					l_arr_cheque_info[idx].post_flag, 
					l_arr_cheque_info[idx].year_num, 
					l_arr_cheque_info[idx].period_num 

			END IF 
--			NEXT FIELD scroll_flag 

	END DISPLAY

	IF int_flag THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION