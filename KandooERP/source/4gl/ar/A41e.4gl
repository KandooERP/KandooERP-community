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

#replace old A41 with E5C modules

# \brief module A41e - Sales Order Summary Information

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

#################################################################
# MODULE scope variables
#################################################################


#################################################################
# FUNCTION credit_summary()
#
#
#################################################################
FUNCTION credit_summary() 

	SELECT unique 1 FROM t_creditdetl 
	WHERE invoice_num IS NOT NULL 
	IF status = NOTFOUND THEN 
		MESSAGE kandoomsg2("E",1067,"") 	#1067 Credit Summary Detail -  ESC TO Continue
	ELSE 
		MESSAGE kandoomsg2("E",1069,"") 	#1069 Credit Summary Detail -  F8 View Invoice Frgt & Hand
	END IF
	 
	DISPLAY BY NAME 
		glob_rec_credithead.entry_code, 
		glob_rec_credithead.entry_date, 
		glob_rec_credithead.rev_num, 
		glob_rec_credithead.rev_date	attribute(yellow) 
	
	CALL A41_credithead_disp_summ() 
	
	#----------------------------------
	INPUT BY NAME 
		glob_rec_credithead.freight_amt, 
		glob_rec_credithead.hand_amt, 
		glob_rec_credithead.com1_text, 
		glob_rec_credithead.com2_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A41e","inp-credithead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F8) 
			CALL disp_invfreight() 

		AFTER FIELD freight_amt 
			IF glob_rec_credithead.freight_amt IS NULL THEN 
				LET glob_rec_credithead.freight_amt = 0 
				NEXT FIELD freight_amt 
			END IF 
			CALL A41_credithead_disp_summ() 

		AFTER FIELD hand_amt 
			IF glob_rec_credithead.hand_amt IS NULL THEN 
				LET glob_rec_credithead.hand_amt = 0 
				NEXT FIELD hand_amt 
			END IF 
			CALL A41_credithead_disp_summ() 

	END INPUT
	#-----------------------------------
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#################################################################
# END FUNCTION credit_summary()
#################################################################


#################################################################
# FUNCTION A41_credithead_disp_summ()
#
#
#################################################################
FUNCTION A41_credithead_disp_summ() 
	DEFINE l_noninv_amt LIKE credithead.total_amt 
	DEFINE l_noninv_tax_amt LIKE credithead.total_amt 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_credithead.tax_code 

	IF l_rec_tax.freight_per IS NULL THEN 
		LET l_rec_tax.freight_per = 0 
	END IF 

	IF l_rec_tax.hand_per IS NULL THEN 
		LET l_rec_tax.hand_per = 0 
	END IF 

	LET glob_rec_credithead.freight_tax_amt = glob_rec_credithead.freight_amt * (l_rec_tax.freight_per/100) 
	LET glob_rec_credithead.hand_tax_amt = glob_rec_credithead.hand_amt * (l_rec_tax.hand_per/100) 
	
	CALL A41_credit_total_calculation_display() 
	
	LET glob_rec_credithead.total_amt = glob_rec_credithead.goods_amt 
		+ glob_rec_credithead.tax_amt 
		+ glob_rec_credithead.hand_amt 
		+ glob_rec_credithead.hand_tax_amt 
		+ glob_rec_credithead.freight_amt 
		+ glob_rec_credithead.freight_tax_amt 

	LET l_noninv_amt = glob_rec_credithead.hand_amt	+ glob_rec_credithead.freight_amt 
	LET l_noninv_tax_amt = + glob_rec_credithead.hand_tax_amt	+ glob_rec_credithead.freight_tax_amt 
	
	DISPLAY BY NAME 
		glob_rec_credithead.total_amt, 
		glob_rec_credithead.tax_amt, 
		glob_rec_credithead.hand_amt, 
		glob_rec_credithead.hand_tax_amt, 
		glob_rec_credithead.freight_amt, 
		glob_rec_credithead.freight_tax_amt 

	DISPLAY 
		l_noninv_amt, 
		l_noninv_tax_amt, 
		l_noninv_amt, 
		l_noninv_tax_amt 
	TO 
		sr_non_inv[1].*, 
		sr_non_inv[2].* 

END FUNCTION 
#################################################################
# END  FUNCTION A41_credithead_disp_summ()
#################################################################


#################################################################
# FUNCTION disp_invfreight()
#
#
#################################################################
FUNCTION disp_invfreight() 
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF #array[40] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			inv_num LIKE invoicehead.inv_num, 
			freight_amt LIKE invoicehead.freight_amt, 
			hand_amt LIKE invoicehead.hand_amt 
		END RECORD 
		DEFINE l_idx SMALLINT 

		SELECT unique 1 FROM t_creditdetl 
		WHERE invoice_num IS NOT NULL 
		IF status = 0 THEN 

			OPEN WINDOW A673 with FORM "A673" 
			CALL windecoration_a("A673") 

			MESSAGE kandoomsg2("E",1008,"")			#1008 F3/F4 TO Page

			LET l_idx = 1 

			DECLARE c_invoicehead CURSOR FOR 
			SELECT unique invoice_num FROM t_creditdetl 
			WHERE invoice_num IS NOT NULL 
			
			FOREACH c_invoicehead INTO l_arr_rec_invoicehead[l_idx].inv_num 
				SELECT 
					freight_amt, 
					hand_amt 
				INTO 
					l_arr_rec_invoicehead[l_idx].freight_amt, 
					l_arr_rec_invoicehead[l_idx].hand_amt 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_arr_rec_invoicehead[l_idx].inv_num 
				
				LET l_idx = l_idx + 1 
			END FOREACH 

			CALL set_count(l_idx-1) 

			DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","A41e","display-arr-invoicehead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END DISPLAY 

			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW A673 
		END IF 
END FUNCTION 
#################################################################
# END FUNCTION disp_invfreight()
#################################################################