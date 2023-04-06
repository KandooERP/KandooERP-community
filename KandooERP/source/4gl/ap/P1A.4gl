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
	Source code beautified by beautify.pl on 2020-01-03 13:41:18	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/../ap/P_AP_P1_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
#DEFINE glob_rec_vendor RECORD LIKE vendor.*
#DEFINE l_rec_vendorhist RECORD LIKE vendorhist.*
#DEFINE l_rec_t_vendorhist RECORD LIKE vendorhist.*
#DEFINE l_arr_rec_vendorhist DYNAMIC ARRAY OF
#	RECORD --huho array[900] of record
#    vend_code LIKE vendorhist.vend_code,
#    year_num LIKE vendorhist.year_num,
#    period_num LIKE vendorhist.period_num,
#    purchase_amt LIKE vendorhist.purchase_amt,
#    payment_amt LIKE vendorhist.payment_amt,
#    debit_amt LIKE vendorhist.debit_amt
#	END RECORD
#DEFINE idx SMALLINT
#DEFINE id_flag SMALLINT
#DEFINE cnt SMALLINT
#DEFINE glob_err_flag SMALLINT

#DEFINE l_msgresp CHAR(2)


#huho 14.03.2019    pr_rec_kandoouser RECORD LIKE kandoouser.*,
#DEFINE l_query_text CHAR(400)
#DEFINE l_where_part CHAR(400)

#DEFINE l_passed_cmpy LIKE company.cmpy_code #huho removed 7.5.2019
#DEFINE pr_passed_vend LIKE vendor.vend_code #huho removed 7.5.2019

############################################################
# MAIN
#
# \brief module P1A allows the user TO view vendor history info
############################################################
MAIN 
	DEFINE l_showall BOOLEAN 
	DEFINE l_msg STRING 
	DEFINE l_vend_code LIKE vendor.vend_code 
	DEFINE l_passed_cmpy LIKE company.cmpy_code 
	#Initial UI Init
	CALL setModuleId("P1A") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp107 with FORM "P107" 
	CALL winDecoration_p("P107") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	IF get_url_vendor_code() IS NOT NULL THEN 
		LET l_vend_code = get_url_vendor_code() 
	ELSE 
		IF get_url_company_code() IS NOT NULL THEN 
			LET glob_err_flag = P1A_history(NULL) 
			LET l_passed_cmpy = get_url_company_code() 
		END IF 
	END IF 

	#LET l_passed_cmpy = getCurrentUser_cmpy_code()

	--		IF l_vend_code IS NULL THEN
	--      #LET l_passed_cmpy = arg_val(1)
	--      LET l_vend_code = arg_val(2)
	--      #LET glob_err_flag = P1A_history() #huho can NOT see glob_err_flag used here ? commment
	--		END IF



	IF NOT db_vendor_pk_exists(UI_OFF,l_vend_code) THEN 
		LET l_showall = TRUE 
	END IF 

	IF l_showall THEN 
		IF db_vendorhist_get_count() = 0 THEN 
			LET l_msg = "There IS no vendor history available\n(for any vendor)" 
			CALL fgl_winmessage("Vendor History",l_msg, "info") 
		ELSE 
			WHILE P1A_history(NULL) 
			END WHILE 
		END IF 
	ELSE 
		IF db_vendorhist_get_vendor_count(l_vend_code) = 0 THEN 
			LET l_msg = "There are no entries in the vendor history for vendor ", trim(l_vend_code), " available" 
			CALL fgl_winmessage("Vendor History",l_msg, "info") 
		ELSE 
			CALL P1A_history(l_vend_code) 
		END IF 
	END IF 

	CLOSE WINDOW wp107 
END MAIN 



############################################################
# FUNCTION P1A_history(p_vend_code)
#
#
############################################################
FUNCTION P1A_history(p_vend_code) 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_query_text CHAR(400) 
	DEFINE l_where_part CHAR(400) 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_vendorhist RECORD LIKE vendorhist.* 
	DEFINE l_rec_t_vendorhist RECORD LIKE vendorhist.* 
	DEFINE l_arr_rec_vendorhist DYNAMIC ARRAY OF RECORD --huho array[900] OF RECORD 
		vend_code LIKE vendorhist.vend_code, 
		year_num LIKE vendorhist.year_num, 
		period_num LIKE vendorhist.period_num, 
		purchase_amt LIKE vendorhist.purchase_amt, 
		payment_amt LIKE vendorhist.payment_amt, 
		debit_amt LIKE vendorhist.debit_amt 
	END RECORD 

	CLEAR FORM 

	IF p_vend_code IS NULL THEN #huho changed TO vendor (not company) 

		MESSAGE "Enter Criteria FOR Selection AND press ESC" 
		#attribute (yellow)

		CONSTRUCT BY NAME l_where_part ON vendorhist.vend_code, 
		vendorhist.year_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P1A","construct-vendorhist-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (vend_code) 
				LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,null) 
				DISPLAY BY NAME glob_rec_vendor.vend_code 
				NEXT FIELD vendorhist.year_num 


		END CONSTRUCT 


		LET l_query_text = " SELECT * FROM vendorhist ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" AND ", 
		l_where_part clipped, 
		" ORDER BY vend_code, year_num, period_num" 
	ELSE 
		LET l_query_text = "SELECT * FROM vendorhist ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND vend_code = '",p_vend_code CLIPPED,"' ", 
		" ORDER BY vend_code, year_num, period_num" 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN FALSE 
	END IF 

	PREPARE choice FROM l_query_text 
	DECLARE c_hist CURSOR FOR choice 
	LET l_idx = 0 

	CALL l_arr_rec_vendorhist.clear() 
	FOREACH c_hist INTO l_rec_vendorhist.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_vendorhist[l_idx].vend_code = l_rec_vendorhist.vend_code 
		LET l_arr_rec_vendorhist[l_idx].year_num = l_rec_vendorhist.year_num 
		LET l_arr_rec_vendorhist[l_idx].period_num = l_rec_vendorhist.period_num 
		LET l_arr_rec_vendorhist[l_idx].purchase_amt = l_rec_vendorhist.purchase_amt 
		LET l_arr_rec_vendorhist[l_idx].payment_amt = l_rec_vendorhist.payment_amt 
		LET l_arr_rec_vendorhist[l_idx].debit_amt = l_rec_vendorhist.debit_amt 

		#IF l_idx = 900 THEN
		#   ERROR " Only first 900 selected "
		#   EXIT FOREACH
		#END IF

	END FOREACH 

	IF l_idx < 1 THEN 
		ERROR "No Data found which fullfil your query selection criteria" 
	ELSE 
		MESSAGE " Select line TO view corresponding history detail" #attribute (yellow) 
	END IF 

	DISPLAY ARRAY l_arr_rec_vendorhist TO sr_vendorhist.* -- WITHOUT DEFAULTS FROM sr_vendorhist.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P1A","inp-arr-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_vendorhist.vend_code = l_arr_rec_vendorhist[l_idx].vend_code 
			LET l_rec_vendorhist.year_num = l_arr_rec_vendorhist[l_idx].year_num 
			LET l_rec_vendorhist.period_num = l_arr_rec_vendorhist[l_idx].period_num 
			LET l_rec_vendorhist.purchase_amt = l_arr_rec_vendorhist[l_idx].purchase_amt 
			LET l_rec_vendorhist.payment_amt = l_arr_rec_vendorhist[l_idx].payment_amt 
			LET l_rec_vendorhist.debit_amt = l_arr_rec_vendorhist[l_idx].debit_amt 
			#LET id_flag = 0  #huho what should this do OR keep ? I can't see it used anywhere.. comment it for now
			#NEXT FIELD year_num

		ON ACTION "ACCEPT" 
			#BEFORE FIELD period_num
			#NOT TO be used on empty/new row
			IF l_idx > 0 THEN #huho 
				IF l_arr_rec_vendorhist[l_idx].vend_code IS NOT NULL THEN 
					CALL disp_vm_hist(glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_vendorhist[l_idx].vend_code, 
					l_arr_rec_vendorhist[l_idx].year_num, 
					l_arr_rec_vendorhist[l_idx].period_num) 
					#NEXT FIELD year_num
				END IF 
			END IF 

	END DISPLAY 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

	RETURN TRUE 
END FUNCTION 


