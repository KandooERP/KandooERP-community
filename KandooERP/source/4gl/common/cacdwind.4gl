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
# common/invqwind.4gl
# common/inhdwind.4gl
###########################################################################

# FUNCTION disp_cash_app displays the cash applied
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_wa152 SMALLINT 
END GLOBALS 


######################################################################################
# FUNCTION disp_cash_app(p_cmpy, p_cust, p_recp_num)
######################################################################################
FUNCTION disp_cash_app(p_cmpy, p_cust, p_recp_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_recp_num LIKE cashreceipt.cash_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_arr_invoicepay DYNAMIC ARRAY OF RECORD 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF glob_wa152 < 1 THEN 
		LET glob_wa152 = glob_wa152 + 1 
		CALL open_window( 'A152', glob_wa152 ) 
	ELSE 
		LET l_msgresp = kandoomsg("U",9917,"") 
		#9917 Window IS already OPEN
		RETURN 
	END IF 

	SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND cash_num = p_recp_num 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9137,"") 
		#9137 Logic Error: Cash Receipt Not Found
		SLEEP 3 
		EXIT program 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_cashreceipt.cust_code 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9067,l_rec_cashreceipt.cust_code) 
		#9067 Logic Error: Customer XXXX does NOT exist
		SLEEP 3 
		EXIT program 
	END IF 

	DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

	LET l_rec_invoicepay.cust_code = l_rec_cashreceipt.cust_code 
	LET l_rec_invoicepay.ref_num = l_rec_cashreceipt.cash_num 

	DISPLAY BY NAME l_rec_cashreceipt.cust_code, 
	l_rec_customer.name_text, 
	l_rec_cashreceipt.cash_num, 
	l_rec_cashreceipt.cash_amt, 
	l_rec_cashreceipt.applied_amt, 
	l_rec_cashreceipt.cash_date 

	DECLARE c_dist CURSOR FOR 
	SELECT * INTO l_rec_invoicepay.* FROM invoicepay 
	WHERE invoicepay.cmpy_code = p_cmpy 
	AND invoicepay.cust_code = l_rec_cashreceipt.cust_code 
	AND invoicepay.ref_num = l_rec_cashreceipt.cash_num 
	AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
	ORDER BY cust_code, ref_num, appl_num 

	LET l_idx = 0 
	FOREACH c_dist 
		LET l_idx = l_idx + 1 
		LET l_arr_invoicepay[l_idx].appl_num = l_rec_invoicepay.appl_num 
		LET l_arr_invoicepay[l_idx].inv_num = l_rec_invoicepay.inv_num 
		LET l_arr_invoicepay[l_idx].apply_num = l_rec_invoicepay.apply_num 
		LET l_arr_invoicepay[l_idx].pay_date = l_rec_invoicepay.pay_date 
		LET l_arr_invoicepay[l_idx].pay_amt = l_rec_invoicepay.pay_amt 
		LET l_arr_invoicepay[l_idx].disc_amt = l_rec_invoicepay.disc_amt 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1007,"") 
	#1007 F3/F4 TO Page Fwd/Bwd - RETURN on line TO view

	#INPUT ARRAY l_arr_invoicepay WITHOUT DEFAULTS FROM sr_invoicepay.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_invoicepay TO sr_invoicepay.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cacdwind","input-arr-invoicepay") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT l_arr_invoicepay.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_invoicepay.getSize())
						
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#### modif ericv init #AFTER FIELD inv_num
			#   --#IF fgl_lastkey() = fgl_keyval("accept")
			#   --#AND fgl_fglgui() THEN
			#   --#   NEXT FIELD apply_num
			#   --#END IF

		ON ACTION ("doubleClick","Edit") 
			#BEFORE FIELD apply_num
			IF l_idx > 0 THEN 
				CALL disc_per_head(p_cmpy, 
				l_rec_cashreceipt.cust_code, 
				l_arr_invoicepay[l_idx].inv_num) 
				#NEXT FIELD inv_num
			END IF 


	END DISPLAY 
	###################################
	LET int_flag = false 
	LET quit_flag = false 

	CALL close_win( 'a152', glob_wa152 ) 

	LET glob_wa152 = glob_wa152 - 1 

END FUNCTION 


