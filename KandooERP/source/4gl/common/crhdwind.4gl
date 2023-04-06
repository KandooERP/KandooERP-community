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
# common/creddetl.4gl
###########################################################################

# FUNCTION cr_disp_head displays creditor header details with the
# option of carrying on AND looking AT line details

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


##########################################################################
# FUNCTION cr_disp_head(p_cmpy, p_cust, p_crednum)
##########################################################################
FUNCTION cr_disp_head(p_cmpy,p_cust,p_crednum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_crednum LIKE credithead.cred_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_arparms RECORD 
					credit_ref1_text LIKE arparms.credit_ref1_text 
			 END RECORD 
	DEFINE l_temp_text CHAR(32) 
	DEFINE l_ref_text LIKE arparms.credit_ref1_text 

	SELECT * INTO l_rec_credithead.* FROM credithead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND cred_num = p_crednum 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",7076,p_crednum) 
		#7076 Logic Error: Credit Note XXXX does NOT exist
		RETURN 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE customer.cust_code = p_cust 
	AND customer.cmpy_code = p_cmpy 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9067,p_cust) 
		#7076 Logic Error: Customer XXXX does NOT exist
		RETURN 
	END IF 

	SELECT credit_ref1_text INTO l_rec_arparms.credit_ref1_text FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	LET l_temp_text = l_rec_arparms.credit_ref1_text clipped, "................" 
	LET l_ref_text = l_temp_text 

	OPEN WINDOW A121 with FORM "A121" 
	CALL windecoration_a("A121") 

	DISPLAY l_ref_text TO credit_ref1_text 

	DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

	IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
		SELECT name_text INTO l_name_text FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_credithead.org_cust_code 
		DISPLAY l_name_text TO formonly.org_name_text 

	END IF 

	DISPLAY BY NAME l_rec_credithead.cust_code, 
	l_rec_credithead.org_cust_code, 
	l_rec_customer.name_text, 
	l_rec_credithead.cred_num, 
	l_rec_credithead.goods_amt, 
	l_rec_credithead.hand_amt, 
	l_rec_credithead.freight_amt, 
	l_rec_credithead.tax_amt, 
	l_rec_credithead.total_amt, 
	l_rec_credithead.disc_amt, 
	l_rec_credithead.appl_amt, 
	l_rec_credithead.entry_code, 
	l_rec_credithead.entry_date, 
	l_rec_credithead.cred_text, 
	l_rec_credithead.cred_date, 
	l_rec_credithead.year_num, 
	l_rec_credithead.period_num, 
	l_rec_credithead.posted_flag, 
	l_rec_credithead.on_state_flag, 
	l_rec_credithead.cred_ind, 
	l_rec_credithead.com1_text, 
	l_rec_credithead.rev_date, 
	l_rec_credithead.com2_text, 
	l_rec_credithead.rev_num 

	CALL credit_details(p_cmpy,l_rec_credithead.cred_num) 

	CLOSE WINDOW A121 

	LET int_flag = false 
	LET quit_flag = false 
	RETURN 
END FUNCTION 



