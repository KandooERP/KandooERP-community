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
###########################################################################

###########################################################################
# Requires
# common/inhdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A26_GLOBALS.4gl" 
############################################################
# FUNCTION A26_main()
#
# allows the user TO Scan Customer Invoices
############################################################
FUNCTION A26_main() 
	DEFER INTERRUPT 
	DEFER QUIT 
	
	CALL setModuleId("A26") 

	LET glob_ref_text = glob_temp_text 
	LET glob_func_type = "View Invoice" 

	IF (get_url_company_code() IS null) AND (get_url_invoice_number() IS null) THEN 
		LET glob_cmpy_code = get_url_company_code() 
		LET glob_inv_num = get_url_invoice_number() 
		SELECT cust_code INTO glob_cust_code 
		FROM invoicehead 
		WHERE cmpy_code = glob_cmpy_code 
		AND inv_num = glob_inv_num 
		CALL disc_per_head(glob_cmpy_code, glob_cust_code, glob_inv_num) 
	ELSE 
		LET glob_ans = "Y" 
		WHILE glob_ans = "Y" 
			CALL scan_customer() 
			LET glob_ans = "Y" 
			CLOSE WINDOW A135 --i don't LIKE this closing windows outside OF the OPEN WINDOW scope.. 
		END WHILE 
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION A26_main()
############################################################


#########################################################################
# FUNCTION scan_customer()
#
#
#########################################################################
FUNCTION scan_customer() 
	
	INITIALIZE glob_rec_customer.* TO NULL 
	IF glob_cnt > 0 THEN 
		LET glob_i = 1 
		FOR glob_i = glob_i TO glob_cnt 
			INITIALIZE glob_arr_rec_nametext[glob_i].* TO NULL 
		END FOR 
	END IF 
	LET glob_name_text = NULL 

	OPEN WINDOW A135 with FORM "A135" 
	CALL windecoration_a("A135") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DISPLAY BY NAME glob_rec_arparms.inv_ref2a_text, glob_rec_arparms.inv_ref2b_text 
	
	MESSAGE kandoomsg2("U",1020,"Invoice") #1020 Enter Invoice Details; OK TO Continue.
	INPUT BY NAME glob_rec_invoicehead.cust_code, glob_rec_invoicehead.inv_num
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A26","inp-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
					LET glob_rec_invoicehead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_invoicehead.cust_code 
					NEXT FIELD cust_code 

		AFTER FIELD cust_code 
			IF glob_rec_invoicehead.cust_code IS NOT NULL THEN 
				SELECT * INTO glob_rec_customer.* FROM customer 
				WHERE cust_code = glob_rec_invoicehead.cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF STATUS = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD cust_code 
				END IF 
			END IF 
			IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
				LET glob_corp_cust = TRUE 
				
			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.corp_cust_code) RETURNING glob_rec_customer.* 
--				SELECT * INTO glob_rec_customer.* FROM customer 
--				WHERE cust_code = glob_rec_customer.corp_cust_code 
--				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
--				IF STATUS = NOTFOUND THEN 
			IF glob_rec_customer.cust_code IS NULL THEN
					ERROR kandoomsg2("A",9121,"") #9121 "Originating customer code NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 
			ELSE 
				LET glob_corp_cust = FALSE 
			END IF 

		BEFORE FIELD inv_num 
			IF glob_rec_invoicehead.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF glob_rec_invoicehead.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 
			# Swap the Customer codes around TO DISPLAY TO the SCREEN
			IF glob_corp_cust THEN 
				DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 
				DISPLAY glob_rec_invoicehead.cust_code TO invoicehead.org_cust_code 
				DISPLAY glob_rec_customer.corp_cust_code TO invoicehead.cust_code 
				DISPLAY glob_rec_customer.name_text TO customer.name_text 
			ELSE 
				DISPLAY BY NAME glob_rec_customer.name_text 
			END IF 

	END INPUT 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		EXIT PROGRAM 
	END IF 
	IF glob_rec_invoicehead.inv_num IS NULL THEN 
		LET glob_rec_invoicehead.inv_num = 0 
	END IF 

	DISPLAY BY NAME glob_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

	IF glob_corp_cust THEN 
		LET glob_rec_invoicehead.cust_code = glob_rec_customer.cust_code 
	END IF 
	
	DECLARE c_cust CURSOR FOR 
	SELECT * INTO glob_rec_invoicehead.* FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_invoicehead.cust_code 
	AND inv_num >= glob_rec_invoicehead.inv_num 
	ORDER BY inv_num 
	LET glob_idx = 0 

	FOREACH c_cust 
		IF glob_corp_cust THEN 
			IF glob_rec_invoicehead.org_cust_code IS NULL OR glob_rec_invoicehead.org_cust_code != glob_rec_customer.cust_code THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		
		LET glob_idx = glob_idx + 1 
		LET glob_arr_rec_invoicehead[glob_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET glob_arr_rec_invoicehead[glob_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET glob_arr_rec_invoicehead[glob_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET glob_arr_rec_invoicehead[glob_idx].year_num = glob_rec_invoicehead.year_num 
		LET glob_arr_rec_invoicehead[glob_idx].period_num = glob_rec_invoicehead.period_num 
		LET glob_arr_rec_invoicehead[glob_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET glob_arr_rec_invoicehead[glob_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET glob_arr_rec_invoicehead[glob_idx].posted_flag = glob_rec_invoicehead.posted_flag 

		# DISPLAY originating customer code AND name TO SCREEN
		SELECT customer.name_text INTO glob_t_name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.org_cust_code 
		IF NOT STATUS THEN 
			LET glob_arr_rec_nametext[glob_idx].name_text = glob_t_name_text 
			LET glob_arr_rec_nametext[glob_idx].cust_code = glob_rec_invoicehead.org_cust_code 
		ELSE 
			LET glob_arr_rec_nametext[glob_idx].name_text = NULL 
			LET glob_arr_rec_nametext[glob_idx].cust_code = NULL 
		END IF 
		
		IF glob_idx = 300 THEN 
			MESSAGE kandoomsg2("U",6100,glob_idx) #6100 "First glob_idx records selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,glob_idx) #9113 glob_idx records selected
	SLEEP 1
	
	MESSAGE kandoomsg2("I",1300,"") #1300 "ENTER on line TO view details"
	#INPUT ARRAY glob_arr_rec_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY glob_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A26","inp-arr-invoicehead")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
 			CALL dialog.setActionHidden("EDIT",NOT glob_arr_rec_invoicehead.getSize())
 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			LET glob_cnt = arr_count() 
			#LET scrn = scr_line()
			LET glob_rec_invoicehead.inv_num = glob_arr_rec_invoicehead[glob_idx].inv_num 
			LET glob_rec_invoicehead.purchase_code = glob_arr_rec_invoicehead[glob_idx].purchase_code 
			LET glob_rec_invoicehead.inv_date = glob_arr_rec_invoicehead[glob_idx].inv_date 
			LET glob_rec_invoicehead.year_num = glob_arr_rec_invoicehead[glob_idx].year_num 
			LET glob_rec_invoicehead.period_num = glob_arr_rec_invoicehead[glob_idx].period_num 
			LET glob_rec_invoicehead.total_amt = glob_arr_rec_invoicehead[glob_idx].total_amt 
			LET glob_rec_invoicehead.paid_amt = glob_arr_rec_invoicehead[glob_idx].paid_amt 
			LET glob_rec_invoicehead.posted_flag = glob_arr_rec_invoicehead[glob_idx].posted_flag 
			
			DISPLAY glob_arr_rec_nametext[glob_idx].name_text TO formonly.org_name_text 
			DISPLAY glob_arr_rec_nametext[glob_idx].cust_code TO invoicehead.org_cust_code 

			#      AFTER FIELD inv_num
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#             ERROR kandoomsg2("U",9001,"")            #9001 There no more rows...
			#             NEXT FIELD inv_num
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF glob_arr_rec_invoicehead[glob_idx+1].inv_num IS NULL THEN
			#              ERROR kandoomsg2("U",9001,"")#              #9001 There no more rows...
			#              NEXT FIELD inv_num
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("nextpage")
			#         AND (glob_arr_rec_invoicehead[glob_idx+10].inv_num IS NULL
			#             OR glob_arr_rec_invoicehead[glob_idx+10].inv_num = 0) THEN
			#            ERROR kandoomsg2("U",9001,"")#            #9001 No more rows in this direction
			#            NEXT FIELD inv_num
			#         END IF
		#ON ACTION ("EDIT","ACCEPT") 
		ON ACTION ("EDIT","doubleClick")
			IF glob_rec_invoicehead.inv_num = 0 
			OR glob_rec_invoicehead.inv_num IS NULL THEN 
				CALL fgl_winmessage("Invalid invoice number","Invoice number IS invalid (0)","error") 
			END IF 

			SELECT cust_code INTO glob_cust_code 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
			
			CALL disc_per_head(
				glob_rec_kandoouser.cmpy_code, 
				glob_cust_code, 
				glob_rec_invoicehead.inv_num ) 

			#      BEFORE FIELD purchase_code
			#         IF glob_rec_invoicehead.inv_num = 0
			#         OR glob_rec_invoicehead.inv_num IS NULL THEN
			#            NEXT FIELD inv_num
			#         END IF
			#
			#         SELECT cust_code INTO glob_cust_code
			#           FROM invoicehead
			#          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#            AND inv_num = glob_rec_invoicehead.inv_num
			#         CALL disc_per_head( glob_rec_kandoouser.cmpy_code,
			#                             glob_cust_code,
			#                             glob_rec_invoicehead.inv_num )
			#         NEXT FIELD inv_num

	END DISPLAY 
	#####################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	
END FUNCTION
#########################################################################
# END FUNCTION scan_customer()
######################################################################### 