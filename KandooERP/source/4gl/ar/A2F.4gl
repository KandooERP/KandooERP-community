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
# common/inhdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A2F_GLOBALS.4gl" 
############################################################
# MAIN
#
# allows the user TO Scan Customer Invoices in  Purchase Code ORDER
############################################################
MAIN 
	DEFINE l_arg_inv_num LIKE invoicehead.inv_num  #passed by program arg/url
	DEFER interrupt 
	DEFER quit 
		
	CALL setModuleId("A2F") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	#with invalid cust id, it will always return with an error... sooo I comment it for now huho . 
	--IF get_url_cust_code() IS NOT NULL THEN
	LET l_arg_inv_num = get_url_invoice_number()
	IF db_invoicehead_pk_exists(UI_ON,NULL,l_arg_inv_num) THEN  
		CALL inv_story(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, l_arg_inv_num)  --??? what IS this (glob_rec_kandoouser.cmpy_code,cust,invnum)  --original was: CALL inv_story(1, 1, 1)
	ELSE
		CALL A2F_scan_invoice()	
 	END IF
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION db_invoice_get_datasource(p_filter)
#
#
############################################################
FUNCTION db_invoice_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_query_text CHAR(400)
	DEFINE l_where_text CHAR(200)
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD --array[320] OF RECORD huho 
		inv_num LIKE invoicehead.inv_num,
		cust_code LIKE invoicehead.cust_code,
		inv_date LIKE invoicehead.inv_date,
		year_num LIKE invoicehead.year_num,
		period_num LIKE invoicehead.period_num,
		total_amt LIKE invoicehead.total_amt,
		paid_amt LIKE invoicehead.paid_amt,
		purchase_code LIKE invoicehead.purchase_code,
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 
	DEFINE l_idx SMALLINT

--	WHENEVER ERROR CONTINUE 
--	CURRENT WINDOW IS a209c 
--	IF status < 0 OR status = 9220 THEN --error - WINDOW was NOT OPEN 
--		OPEN WINDOW A209c with FORM "A209_construct" 
--		CALL windecoration_a("A209_construct") 
--		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
--	END IF 
--	WHENEVER ERROR stop 

	IF p_filter THEN
		OPEN WINDOW A209c with FORM "A209_construct" 
		CALL windecoration_a("A209_construct") 

		# HuHo 07.09.2018 - can't understand for what these where useful... commented/collapsed them.
		MESSAGE kandoomsg2("U",1001,"") 		#1001 Enter Selection Criteria; OK TO Continue
		CONSTRUCT BY NAME l_where_text ON 
			purchase_code, 
			inv_num, 
			inv_date, 
			year_num, 
			period_num, 
			total_amt, 
			paid_amt, 
			posted_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A2F","construct-invoice") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
--	WHENEVER ERROR CONTINUE 
--	CURRENT WINDOW IS a209 
--	IF status < 0 OR status = 9220 THEN --error - WINDOW was NOT OPEN 
--		OPEN WINDOW A209 with FORM "A209" 
--		CALL windecoration_a("A209") 
--		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
--	END IF 
--	WHENEVER ERROR stop 
	
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF
		
		CLOSE WINDOW A209c
		 
	ELSE
	
		LET l_where_text = " 1=1 "
	END IF #End of IF p_filter
	
	MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching Database; Please Wait
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY inv_num " --,purchase_code"
 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 

	LET l_idx = 0 
	FOREACH c_invoice INTO glob_rec_invoicehead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].cust_code = glob_rec_invoicehead.cust_code 
		LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
		LET l_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
		LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_invoicehead[l_idx].posted_flag = glob_rec_invoicehead.posted_flag 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	IF l_idx = 0 THEN 
		CALL l_arr_rec_invoicehead.clear() 
	END IF 

	RETURN l_arr_rec_invoicehead
END FUNCTION
############################################################
# END FUNCTION db_invoice_get_datasource(p_filter)
############################################################


############################################################
# FUNCTION A2F_scan_invoice()
#
#
############################################################
FUNCTION A2F_scan_invoice() 
	DEFINE l_purchase_code LIKE invoicehead.purchase_code
	DEFINE l_num_selected SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD --array[320] OF RECORD huho 
		inv_num LIKE invoicehead.inv_num,
		cust_code LIKE invoicehead.cust_code,
		inv_date LIKE invoicehead.inv_date,
		year_num LIKE invoicehead.year_num,
		period_num LIKE invoicehead.period_num,
		total_amt LIKE invoicehead.total_amt,
		paid_amt LIKE invoicehead.paid_amt,
		purchase_code LIKE invoicehead.purchase_code,
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 

	OPEN WINDOW A209 WITH FORM "A209"
	CALL windecoration_a("A209")
	CALL displaymoduletitle(NULL)  --first form of the module get's the title


  DISPLAY BY NAME glob_rec_arparms.inv_ref1_text,
	                   glob_rec_arparms.inv_ref2a_text,
	                   glob_rec_arparms.inv_ref2b_text


	CALL db_invoice_get_datasource(FALSE) RETURNING l_arr_rec_invoicehead


	MESSAGE kandoomsg2("I",1300,"")	#1300 "ENTER on line TO view details"
	DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A2F","inp-arr-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "FILTER"
			CALL l_arr_rec_invoicehead.clear()
			CALL db_invoice_get_datasource(TRUE) RETURNING l_arr_rec_invoicehead

		ON ACTION "REFRESH"
			CALL l_arr_rec_invoicehead.clear()
			CALL db_invoice_get_datasource(FALSE) RETURNING l_arr_rec_invoicehead
		
		ON ACTION "STORY"
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicehead.getSize()) THEN
				CALL inv_story(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, l_arr_rec_invoicehead[l_idx].inv_num)
			END IF		

		BEFORE ROW 
			LET l_idx = arr_curr()			
			LET l_purchase_code = l_arr_rec_invoicehead[l_idx].purchase_code 

		ON ACTION "ACCEPT" 
			#AFTER FIELD purchase_code
			#   IF fgl_lastkey() = fgl_keyval("down")
			#   AND arr_curr() >= arr_count() THEN
			#       ERROR kandoomsg2("U",9001,"")      #9001 There no more rows...
			#       NEXT FIELD purchase_code
			#   END IF
			#   IF fgl_lastkey() = fgl_keyval("down") THEN
			#      IF l_arr_rec_invoicehead[l_idx+1].purchase_code IS NULL THEN
			#        ERROR kandoomsg2("U",9001,"")  #9001 There no more rows...
			#        NEXT FIELD purchase_code
			#      END IF
			#   END IF
			#   IF fgl_lastkey() = fgl_keyval("nextpage")
			#   AND l_arr_rec_invoicehead[l_idx+10].purchase_code IS NULL THEN
			#      ERROR kandoomsg2("U",9001,"")
			#      #9001 No more rows in this direction
			#      NEXT FIELD purchase_code
			#   END IF
			
			#BEFORE FIELD inv_num
			
			CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.* 
			
			--SELECT * INTO glob_rec_invoicehead.* 
			--FROM invoicehead 
			--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			--AND inv_num = l_arr_rec_invoicehead[l_idx].inv_num 
			IF glob_rec_invoicehead.inv_num IS NULL OR glob_rec_invoicehead.inv_num = 0 THEN 
				CALL disc_per_head(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_invoicehead.cust_code, 
					glob_rec_invoicehead.inv_num) 
			END IF 
			IF l_arr_rec_invoicehead[l_idx].purchase_code != l_purchase_code THEN 
				LET l_arr_rec_invoicehead[l_idx].purchase_code = l_purchase_code 
			END IF 

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false
	
	CLOSE WINDOW A209 
	
	IF (l_idx > 0) AND (l_idx < l_arr_rec_invoicehead.getSize()) THEN
		RETURN l_arr_rec_invoicehead[l_idx].purchase_code
	ELSE
		RETURN NULL
	END IF 
END FUNCTION
##################################1111111111111111##########################
# END FUNCTION A2F_scan_invoice()
############################################################