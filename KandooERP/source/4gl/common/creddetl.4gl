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

	Source code beautified by beautify.pl on 2020-01-02 10:35:09	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


################################################################################
# FUNCTION credit_details(p_cmpy,p_cred_num)
################################################################################
FUNCTION credit_details(p_cmpy,p_cred_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cred_num INTEGER
	DEFINE l_arr_credmenu ARRAY[20] OF RECORD 
					scroll_flag CHAR(1), 
					option_num CHAR(1), 
					option_text CHAR(30) 
				END RECORD 
	DEFINE l_idx INTEGER
	DEFINE l_msgresp CHAR (1) 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_run_arg STRING #for forming the RUN url argument 
	DEFINE i INTEGER

	SELECT * INTO l_rec_credithead.* FROM credithead 
	WHERE cred_num = p_cred_num 
	AND cmpy_code = p_cmpy 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE l_rec_credithead.cust_code = cust_code 
	AND cmpy_code = p_cmpy 

	FOR i = 1 TO 9 
		CASE i 
			WHEN "1" ## general details 
				LET l_idx = l_idx + 1 
				LET l_arr_credmenu[l_idx].option_num = "1" 
				LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'1') 
			WHEN "2" ## entry info 
				LET l_idx = l_idx + 1 
				LET l_arr_credmenu[l_idx].option_num = "2" 
				LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'2') 
			WHEN "3" ## line items 
				LET l_idx = l_idx + 1 
				LET l_arr_credmenu[l_idx].option_num = "3" 
				LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'3') 
			WHEN "4" ## customer notes 
				LET l_idx = l_idx + 1 
				LET l_arr_credmenu[l_idx].option_num = "4" 
				LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'4') 
			WHEN "6" ## credit applications 
				LET l_idx = l_idx + 1 
				LET l_arr_credmenu[l_idx].option_num = "6" 
				LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'6') 
			WHEN "7" ## shipping details 
				SELECT 1 FROM credheadaddr 
				WHERE cred_num = p_cred_num 
				AND cmpy_code = p_cmpy 
				IF status != notfound THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_credmenu[l_idx].option_num = "7" 
					LET l_arr_credmenu[l_idx].option_text = kandooword("creddetl",'7') 
				END IF 
		END CASE 
	END FOR 

	OPEN WINDOW A214 with FORM "A214" 
	CALL windecoration_a("A214") 

	DISPLAY l_rec_credithead.cred_num TO cred_num
	DISPLAY l_rec_credithead.cust_code TO cust_code
	DISPLAY l_rec_customer.name_text TO customer.name_text 

	CALL set_count(l_idx) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET l_msgresp=kandoomsg("A",1030,"") 
	#A1030 RETURN TO SELECT Option

	#INPUT ARRAY l_arr_credmenu WITHOUT DEFAULTS FROM sr_credmenu.*  ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_credmenu TO sr_credmenu.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","creddetl","input-arr-credmenu") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_credmenu[l_idx].*
			#     TO sr_credmenu[scrn].*

			#AFTER FIELD scroll_flag
			#   --#IF fgl_lastkey() = fgl_keyval("accept")
			#   --#AND fgl_fglgui() THEN
			#   --#   NEXT FIELD option_num
			#   --#END IF
			#      IF l_arr_credmenu[l_idx].scroll_flag IS NULL THEN
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() = arr_count() THEN
			#            LET l_msgresp=kandoomsg("U",9001,"")
			#            #A9001 No more rows in the direction ...
			#            NEXT FIELD scroll_flag
			#         END IF
			#      END IF

		ON ACTION ("View","DoubleClick") 
			#BEFORE FIELD option_num
			IF l_arr_credmenu[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_credmenu[l_idx].scroll_flag = l_arr_credmenu[l_idx].option_num 
			ELSE 
				LET i = 1 
				WHILE (l_arr_credmenu[i].scroll_flag IS NOT null) 
					IF l_arr_credmenu[i].option_num IS NULL THEN 
						LET l_arr_credmenu[l_idx].scroll_flag = NULL 
					ELSE 
						IF l_arr_credmenu[l_idx].scroll_flag= 
						l_arr_credmenu[i].option_num THEN 
							EXIT WHILE 
						END IF 
					END IF 
					LET i = i + 1 
				END WHILE 
			END IF 

			CASE l_arr_credmenu[l_idx].scroll_flag 
				WHEN "1" 
					CALL show_credit_details(p_cmpy, 
					l_rec_credithead.*) 
				WHEN "2" 
					CALL show_cred_entry(p_cmpy, 
					l_rec_credithead.cred_num) 
				WHEN "3" 
					CALL linecshow(p_cmpy,l_rec_credithead.cust_code, 
					l_rec_credithead.cred_num,"") 
				WHEN "4" 
					LET l_run_arg = "CUSTOMER_CODE=", trim(l_rec_credithead.cust_code) 
					CALL run_prog("A13",l_run_arg,"","","") #customer notes filter 

				WHEN "6" 
					CALL show_applications(p_cmpy, l_rec_credithead.cred_num) 
				WHEN "7" 
					CALL display_job_address(p_cmpy,l_rec_credithead.cred_num) 
			END CASE 

			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

			LET l_arr_credmenu[l_idx].scroll_flag = NULL 
			#NEXT FIELD scroll_flag

			#AFTER ROW
			#   DISPLAY l_arr_credmenu[l_idx].* TO sr_credmenu[scrn].*


	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW A214 
END FUNCTION 


################################################################################
# FUNCTION show_credit_details(p_cmpy,p_credithead)
################################################################################
FUNCTION show_credit_details(p_cmpy,p_credithead) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_credithead RECORD LIKE credithead.*
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,p_credithead.sale_code) RETURNING l_rec_salesperson.*

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE p_cmpy = cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cust_code = p_credithead.cust_code 
	AND p_cmpy = cmpy_code 

	OPEN WINDOW wa121 with FORM "A121" 
	CALL windecoration_a("A121") 

	DISPLAY BY NAME l_rec_customer.cust_code, 
	l_rec_customer.name_text, 
	p_credithead.org_cust_code, 
	p_credithead.cred_num, 
	p_credithead.goods_amt, 
	p_credithead.hand_amt, 
	p_credithead.freight_amt, 
	p_credithead.tax_amt, 
	p_credithead.total_amt, 
	p_credithead.appl_amt, 
	p_credithead.disc_amt, 
	p_credithead.cred_text, 
	p_credithead.cred_date, 
	p_credithead.sale_code, 
	p_credithead.on_state_flag, 
	p_credithead.year_num, 
	p_credithead.period_num, 
	p_credithead.posted_flag, 
	p_credithead.cred_ind, 
	p_credithead.entry_code, 
	p_credithead.entry_date, 
	p_credithead.com1_text, 
	p_credithead.com2_text, 
	p_credithead.rev_date, 
	p_credithead.rev_num 

	DISPLAY l_rec_salesperson.name_text 
	TO salesperson.name_text 

	DISPLAY BY NAME p_credithead.currency_code 
	attribute(green) 

	DISPLAY BY NAME l_rec_arparms.credit_ref1_text 
	attribute(white) 

	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	CLOSE WINDOW wa121 

END FUNCTION 


################################################################################
# FUNCTION display_job_address(p_cmpy,p_cred_num)
################################################################################
FUNCTION display_job_address(p_cmpy,p_cred_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cred_num INTEGER
	DEFINE l_rec_credheadaddr RECORD LIKE credheadaddr.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_credheadaddr.* 
	FROM credheadaddr 
	WHERE cred_num = p_cred_num 
	AND p_cmpy = cmpy_code 

	OPEN WINDOW A664 with FORM "A664" 
	CALL windecoration_a("A664") 

	DISPLAY BY NAME l_rec_credheadaddr.ship_text, 
	l_rec_credheadaddr.addr1_text, 
	l_rec_credheadaddr.addr2_text, 
	l_rec_credheadaddr.city_text, 
	l_rec_credheadaddr.state_code, 
	l_rec_credheadaddr.post_code, 
	l_rec_credheadaddr.map_reference 

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW A664 

END FUNCTION 


################################################################################
# FUNCTION show_applications(p_cmpy, p_cred_num)
################################################################################
FUNCTION show_applications(p_cmpy,p_cred_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cred_num LIKE credithead.cred_num
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_arr_invoicepay ARRAY[2000] OF RECORD 
					appl_num LIKE invoicepay.appl_num, 
					inv_num LIKE invoicepay.inv_num, 
					apply_num LIKE invoicepay.apply_num, 
					pay_date LIKE invoicepay.pay_date, 
					pay_amt LIKE invoicepay.pay_amt, 
					disc_amt LIKE invoicepay.disc_amt 
			 END RECORD 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_credithead.* FROM credithead 
	WHERE cmpy_code = p_cmpy 
	AND cred_num = p_cred_num 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",7076,p_cred_num) 
		#7076 Logic Error: Credit Note Not Found
		RETURN 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_credithead.cust_code 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Customer") 
		#7001 Logic Error: Customer does NOT exist
		RETURN 
	END IF 

	OPEN WINDOW A681 with FORM "A681" 
	CALL windecoration_a("A681") 

	DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

	LET l_rec_invoicepay.cust_code = l_rec_credithead.cust_code 
	LET l_rec_invoicepay.ref_num = l_rec_credithead.cred_num 
	DISPLAY BY NAME l_rec_credithead.cust_code, 
	l_rec_customer.name_text, 
	l_rec_credithead.cred_num, 
	l_rec_credithead.total_amt, 
	l_rec_credithead.appl_amt, 
	l_rec_credithead.cred_date 



	DECLARE c_dist CURSOR FOR 
	SELECT * INTO l_rec_invoicepay.* FROM invoicepay 
	WHERE invoicepay.cmpy_code = p_cmpy 
	AND invoicepay.cust_code = l_rec_credithead.cust_code 
	AND invoicepay.ref_num = l_rec_credithead.cred_num 
	AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
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
		IF l_idx = 2000 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1008,"") 
	#1007 F3/F4 TO Page Fwd/Bwd - OK TO Continue.

	DISPLAY ARRAY l_arr_invoicepay TO sr_invoicepay.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","creddetl","display-arr-invoicepay") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW A681 

END FUNCTION 
