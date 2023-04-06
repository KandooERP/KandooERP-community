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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAM_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################ 
DEFINE modu_rec_criteria RECORD 
	order_ind CHAR(1), 
	age_date DATE 
END RECORD 
DEFINE modu_seg_text CHAR(500)
DEFINE modu_continue_flag SMALLINT
DEFINE modu_rec_save RECORD
	ftype LIKE customertype.type_code, 
	htype LIKE customertype.type_code,
	find LIKE ordhead.ord_ind, 
	hind LIKE ordhead.ord_ind, 
	facct LIKE coa.acct_code, 
	hacct LIKE coa.acct_code 
END RECORD 
	DEFINE x1 SMALLINT 
	DEFINE x2 SMALLINT 
	DEFINE y1 SMALLINT 
	DEFINE y2 SMALLINT 
 
#####################################################################
# FUNCTION AAM_main()
#
# Summary Account Aging
#           Page Break on GL Segments
#           Report Order Dynamic
#           Aging Date IS as entered but IS balance as run date.
#####################################################################
FUNCTION AAM_main()
	DEFINE l_curr_date DATE 

	IF NOT fgl_find_table("f_document") THEN	
		CREATE temp TABLE f_document (line_acct_code CHAR(18), 
		segment1 CHAR(18), 
		segment2 CHAR(18), 
		trans_type CHAR(2), 
		trans_num INTEGER, 
		trans_date DATE, 
		trans_ref CHAR(20), 
		days_num INTEGER, 
		curr_code CHAR(3), 
		conv_qty FLOAT, 
		total_amt money(12,2), 
		unpaid_amt money(12,2), 
		curr_amt money(12,2), 
		over1_amt money(12,2), 
		over30_amt money(12,2), 
		over60_amt money(12,2), 
		over90_amt money(12,2)) with no LOG 
	END IF
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A235 with FORM "A235" 
			CALL windecoration_a("A235") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date 
			DISPLAY today TO curr_date

			MENU " Debtors Funds Employed Report " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAM","menu-debtors-funds-rep")
					CALL rpt_rmsreps_reset(NULL) 
					CALL AAM_rpt_process(AAM_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report"	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("f_document") THEN
						DELETE FROM f_document WHERE "1=1"
					END IF					
					
					CALL AAM_rpt_process(AAM_rpt_query())

				ON ACTION "Print"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog ("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW A235 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAM_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A235 with FORM "A235" 
			CALL windecoration_a("A235") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAM_rpt_query()) #save where clause in env 
			CLOSE WINDOW A235 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAM_rpt_process(get_url_sel_text())
	END CASE 

	IF fgl_find_table("f_document") THEN
		DROP TABLE f_document
	END IF
	
END FUNCTION
#####################################################################
# END FUNCTION AAM_main()
#####################################################################


#####################################################################
# FUNCTION AAM_rpt_query()
#
#
#####################################################################
FUNCTION AAM_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_age_ind CHAR(1)
	DEFINE l_seq_no SMALLINT 
	
	CLEAR FORM 
	DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date 
	DISPLAY TODAY TO curr_date

	LET l_age_ind = "1" 
	LET modu_rec_criteria.age_date = NULL 
	
	MESSAGE kandoomsg2("A",1034,"") 	#1034 Enter REPORT parameters - ESC TO Continue
	INPUT l_age_ind,	modu_rec_criteria.age_date WITHOUT DEFAULTS FROM 
	age_ind,	age_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAM","inp-rep-param") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_ind 
			CASE l_age_ind 
				WHEN "1" 
					LET modu_rec_criteria.age_date = glob_rec_arparms.cust_age_date 
				WHEN "2" 
					LET modu_rec_criteria.age_date = today 
				WHEN "3" 
					IF modu_rec_criteria.age_date IS NULL THEN 
						LET modu_rec_criteria.age_date = today 
					END IF 
			END CASE 
			LET l_seq_no = 1 

		BEFORE FIELD age_date 
			IF l_age_ind != "3" THEN 
				IF l_seq_no = 1 THEN 
				ELSE 
					NEXT FIELD age_ind 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON c.cust_code, 
	c.name_text, 
	c.addr1_text, 
	c.addr2_text, 
	c.city_text, 
	c.state_code, 
	c.post_code, 
	c.country_code, 
--@db-patch_2020_10_04--	c.country_text, 
	c.currency_code, 
	c.curr_amt, 
	c.over1_amt, 
	c.over30_amt, 
	c.over60_amt, 
	c.over90_amt, 
	c.bal_amt, 
	c.hold_code, 
	c.type_code, 
	c.sale_code, 
	c.territory_code, 
	c.contact_text, 
	c.tele_text, 
	c.mobile_phone,	
	c.fax_text, 
	c.email

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAM","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
	
	# get gl selection criterion
	LET glob_rec_rpt_selector.sel_text = l_where_text 
	LET glob_rec_rpt_selector.ref1_date = modu_rec_criteria.age_date 

	CALL fgl_winmessage("huho - segment code issue","huho - segment code issue","info") 

	LET glob_rec_rpt_selector.sel_text[1500,2000] = segment_con(glob_rec_kandoouser.cmpy_code,"invoicedetl") 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 
	
END FUNCTION 
#####################################################################
# END FUNCTION AAM_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAM_rpt_process(p_where_text)
#
#
#####################################################################
FUNCTION AAM_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_document RECORD 
		line_acct_code LIKE invoicedetl.line_acct_code, 
		segment1 LIKE coa.acct_code, 
		segment2 LIKE coa.acct_code, 
		trans_type LIKE araudit.tran_type_ind, 
		trans_num LIKE invoicehead.inv_num, 
		trans_date LIKE invoicehead.inv_date, 
		trans_ref LIKE invoicehead.purchase_code, 
		days_num INTEGER, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_amt LIKE invoicehead.total_amt, 
		unpaid_amt LIKE invoicehead.paid_amt, 
		curr_amt LIKE customer.curr_amt, 
		over1_amt LIKE customer.over1_amt, 
		over30_amt LIKE customer.over30_amt, 
		over60_amt LIKE customer.over60_amt, 
		over90_amt LIKE customer.over90_amt 
	END RECORD
	--DEFINE l_rec_customer RECORD LIKE customer.*
	--DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	--DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_invheadext RECORD LIKE invheadext.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_creditheadext RECORD LIKE creditheadext.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_query_text CHAR(2000)
	DEFINE l_order_text CHAR(20)
	DEFINE l_type_code LIKE customertype.type_code
	DEFINE l_ware_code LIKE warehouse.ware_code
	DEFINE l_mask LIKE warehouse.acct_mask_code
	DEFINE l_unpaid_per FLOAT 

	DEFINE i SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAM_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAM_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

		
--	LET modu_rec_criteria.age_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 
	CALL set_aging(glob_rec_kandoouser.cmpy_code,glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date) 
	LET modu_seg_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text[1500,2000] 
--	LET glob_rec_rmsreps.sel_text[1500,2000] = " " 
	LET modu_rec_save.ftype = "zz" 
	LET modu_rec_save.htype = "zz" 
	LET modu_rec_save.find = -1 
	LET modu_rec_save.hind = -1 

	FOR i = 1 TO length(modu_seg_text) step 1 
		IF modu_seg_text[i, i+10] = "invoicedetl" THEN 
			LET modu_seg_text[i,i+10] = " i" 
		END IF 
	END FOR 

	# need TO do something about GL segments
	DECLARE x_curs CURSOR FOR 
	SELECT * INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num > 0 
	AND (type_ind = "S" OR type_ind = "L") 
	ORDER BY start_num 

	OPEN x_curs 
	FETCH x_curs INTO l_rec_structure.* 

	LET x1 = l_rec_structure.start_num 
	LET y1 = l_rec_structure.start_num + l_rec_structure.length_num -1 

	FETCH NEXT x_curs INTO l_rec_structure.* 

	IF status = NOTFOUND THEN 
		LET x2 = x1 
		LET y2 = y1 
	ELSE 
		LET x2 = l_rec_structure.start_num 
		LET y2 = l_rec_structure.start_num + l_rec_structure.length_num -1 
	END IF 

	## program requires five cursors
	## 1. invoices
	LET l_query_text ="SELECT i.*, c.type_code, l_x.* ", 
	"FROM invoicehead i,customer c,outer invheadext l_x ", 
	"WHERE i.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND c.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND l_x.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND i.cust_code = c.cust_code ", 
	"AND i.inv_num = l_x.inv_num ", 
	"AND (i.paid_amt != i.total_amt OR i.paid_amt IS NULL) ", 
	"AND i.total_amt <> 0 ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAM_rpt_list")].sel_text clipped, " " 

	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 

	## 2. invoicedetl
	LET l_query_text = "SELECT * FROM invoicedetl i ", 
	"WHERE i.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND i.inv_num = ? ", 
	" ", modu_seg_text, " " 

	PREPARE s_dinvoice FROM l_query_text 
	DECLARE c_dinvoice CURSOR FOR s_dinvoice 

	## 3. credits
	LET l_query_text ="SELECT i.*, c.type_code, l_x.* ", 
	" FROM credithead i, customer c, outer creditheadext l_x ", 
	"WHERE i.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND c.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND l_x.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND i.cust_code = c.cust_code ", 
	"AND i.cred_num = l_x.credit_num ", 
	"AND i.total_amt <> 0 ", 
	"AND (i.appl_amt != i.total_amt OR i.appl_amt IS NULL) ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAM_rpt_list")].sel_text clipped, " " 

	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	## 4. creditdetl
	LET l_query_text = "SELECT * FROM creditdetl i ", 
	"WHERE i.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND i.cred_num = ? ", 
	" ", modu_seg_text, " " 
	PREPARE s_dcredit FROM l_query_text 
	DECLARE c_dcredit CURSOR FOR s_dcredit 

	## 5. cashreceipts
	LET l_query_text ="SELECT i.*, c.type_code FROM cashreceipt i, customer c ", 
	"WHERE i.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND c.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND i.cust_code = c.cust_code ", 
	"AND i.cash_amt <> 0 ", 
	"AND (i.applied_amt != i.cash_amt OR i.applied_amt IS NULL) ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAM_rpt_list")].sel_text clipped, " " 
	PREPARE s_cash FROM l_query_text 
	DECLARE c_cash CURSOR FOR s_cash 

	DELETE FROM f_document WHERE 1=1 
	LET modu_continue_flag = true 

	OPEN c_invoice 
	FOREACH c_invoice INTO l_rec_invoicehead.*, l_type_code, l_rec_invheadext.*
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_invoicehead.inv_num,NULL,l_rpt_idx) THEN
			LET modu_continue_flag = false 
			EXIT FOREACH 
		END IF  

		#common TO all invoice lines
		LET l_rec_document.trans_type = TRAN_TYPE_INVOICE_IN 
		LET l_rec_document.trans_num = l_rec_invoicehead.inv_num 
		LET l_rec_document.trans_date = l_rec_invoicehead.inv_date 
		LET l_rec_document.trans_ref = l_rec_invoicehead.purchase_code 
		LET l_rec_document.days_num = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
		LET l_rec_document.curr_code = l_rec_invoicehead.currency_code 
		LET l_rec_document.conv_qty = l_rec_invoicehead.conv_qty 

		IF l_rec_invoicehead.paid_amt IS NULL THEN 
			LET l_rec_invoicehead.paid_amt = 0 
		END IF 

		LET l_unpaid_per = (l_rec_invoicehead.total_amt - 
		l_rec_invoicehead.paid_amt) /	l_rec_invoicehead.total_amt 

		# do something about freight & handling
		DECLARE c_ware CURSOR FOR 
		SELECT ware_code FROM invoicedetl 
		WHERE inv_num = l_rec_invoicehead.inv_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		OPEN c_ware 
		FETCH c_ware INTO l_ware_code 
		CLOSE c_ware 

		IF l_ware_code IS NOT NULL THEN 
			SELECT acct_mask_code INTO l_mask 
			FROM warehouse 
			WHERE ware_code = l_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
			LET l_mask = "??????????????????" 
		END IF 

		IF (l_rec_invoicehead.freight_amt + l_rec_invoicehead.freight_tax_amt) > 0 THEN 
			LET l_rec_document.line_acct_code = get_freight_acct(glob_rec_kandoouser.cmpy_code, 
			l_type_code, 
			l_rec_invheadext.ord_ind) 
			LET l_rec_document.line_acct_code = build_mask(glob_rec_kandoouser.cmpy_code, l_mask, 
			l_rec_document.line_acct_code) 

			CALL fgl_winmessage("huho - flexcode","FlexCode needs sorting","info") 


			LET l_rec_document.segment1 = l_rec_document.line_acct_code[x1,y1] 
			LET l_rec_document.segment2 = l_rec_document.line_acct_code[x2,y2] 
			IF l_rec_document.segment1 IS NULL THEN 
				LET l_rec_document.segment1 = "zz" # unknown 
				LET l_rec_document.segment2 = "za" # unknown 
			END IF 
			LET l_rec_document.trans_amt = l_rec_invoicehead.freight_amt + 
			l_rec_invoicehead.freight_tax_amt 
			LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
			INSERT INTO f_document VALUES (l_rec_document.*) 
		END IF 

		IF (l_rec_invoicehead.hand_amt + l_rec_invoicehead.hand_tax_amt) > 0 THEN 
			LET l_rec_document.line_acct_code = get_hand_acct(glob_rec_kandoouser.cmpy_code, 
			l_type_code, 
			l_rec_invheadext.ord_ind) 
			LET l_rec_document.line_acct_code = build_mask(glob_rec_kandoouser.cmpy_code, l_mask, 
			l_rec_document.line_acct_code) 
			LET l_rec_document.segment1 = l_rec_document.line_acct_code[x1,y1] 
			LET l_rec_document.segment2 = l_rec_document.line_acct_code[x2,y2] 
			IF l_rec_document.segment1 IS NULL THEN 
				LET l_rec_document.segment1 = "zz" # unknown 
				LET l_rec_document.segment2 = "za" # unknown 
			END IF 
			LET l_rec_document.trans_amt = l_rec_invoicehead.hand_amt +	l_rec_invoicehead.hand_tax_amt 
			LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
			INSERT INTO f_document VALUES (l_rec_document.*) 
		END IF 

		OPEN c_dinvoice USING l_rec_invoicehead.inv_num 

		FOREACH c_dinvoice INTO l_rec_invoicedetl.* 
			LET l_rec_document.line_acct_code = l_rec_invoicedetl.line_acct_code 
			LET l_rec_document.segment1 = l_rec_invoicedetl.line_acct_code[x1,y1] 
			LET l_rec_document.segment2 = l_rec_invoicedetl.line_acct_code[x2,y2] 
			IF l_rec_document.segment1 IS NULL THEN 
				LET l_rec_document.segment1 = "zz" # unknown 
				LET l_rec_document.segment2 = "za" # unknown 
			END IF 
			LET l_rec_document.trans_amt = l_rec_invoicedetl.line_total_amt 
			LET l_rec_document.unpaid_amt = l_rec_invoicedetl.line_total_amt * l_unpaid_per 
			INSERT INTO f_document VALUES (l_rec_document.*) 

		END FOREACH 

	END FOREACH 

	IF modu_continue_flag THEN 
		OPEN c_credit 
		FOREACH c_credit INTO l_rec_credithead.*, l_type_code, l_rec_creditheadext.* 
			IF NOT rpt_int_flag_handler2("Credit:",l_rec_credithead.cred_num,NULL,l_rpt_idx) THEN
				LET modu_continue_flag = false 
				EXIT FOREACH 
			END IF  
			
			LET l_rec_document.trans_type = TRAN_TYPE_CREDIT_CR 
			LET l_rec_document.trans_num = l_rec_credithead.cred_num 
			LET l_rec_document.trans_date = l_rec_credithead.cred_date 
			LET l_rec_document.trans_ref = l_rec_credithead.cred_text 
			LET l_rec_document.days_num = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
			LET l_rec_document.curr_code = l_rec_credithead.currency_code 
			LET l_rec_document.conv_qty = l_rec_credithead.conv_qty 
			IF l_rec_credithead.appl_amt IS NULL THEN 
				LET l_rec_credithead.appl_amt = 0 
			END IF 
			LET l_unpaid_per = (l_rec_credithead.total_amt - l_rec_credithead.appl_amt) / l_rec_credithead.total_amt 

			# do something about freight & handling
			DECLARE cc_ware CURSOR FOR 
			SELECT ware_code FROM creditdetl 
			WHERE cred_num = l_rec_credithead.cred_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			OPEN cc_ware 
			FETCH cc_ware INTO l_ware_code 
			CLOSE cc_ware 

			IF l_ware_code IS NOT NULL THEN 
				SELECT acct_mask_code INTO l_mask 
				FROM warehouse 
				WHERE ware_code = l_ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				LET l_mask = "??????????????????" 
			END IF 

			IF (l_rec_credithead.freight_amt + l_rec_credithead.freight_tax_amt) > 0 THEN 
				LET l_rec_document.line_acct_code = get_freight_acct(glob_rec_kandoouser.cmpy_code, 
				l_type_code, 
				l_rec_creditheadext.ord_ind) 
				LET l_rec_document.line_acct_code = build_mask(glob_rec_kandoouser.cmpy_code, l_mask, 
				l_rec_document.line_acct_code) 
				LET l_rec_document.segment1 = l_rec_document.line_acct_code[x1,y1] 
				LET l_rec_document.segment2 = l_rec_document.line_acct_code[x2,y2] 
				IF l_rec_document.segment1 IS NULL THEN 
					LET l_rec_document.segment1 = "zz" # unknown 
					LET l_rec_document.segment2 = "zb" # unknown 
				END IF 
				LET l_rec_document.trans_amt = 0 - (l_rec_credithead.freight_amt + 
				l_rec_credithead.freight_tax_amt) 
				LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
				INSERT INTO f_document VALUES (l_rec_document.*) 
			END IF 

			IF (l_rec_credithead.hand_amt + l_rec_credithead.hand_tax_amt) > 0 THEN 
				LET l_rec_document.line_acct_code = get_hand_acct(glob_rec_kandoouser.cmpy_code, 
				l_type_code, 
				l_rec_creditheadext.ord_ind) 
				LET l_rec_document.line_acct_code = build_mask(glob_rec_kandoouser.cmpy_code, l_mask, 
				l_rec_document.line_acct_code) 
				LET l_rec_document.segment1 = l_rec_document.line_acct_code[x1,y1] 
				LET l_rec_document.segment2 = l_rec_document.line_acct_code[x2,y2] 
				IF l_rec_document.segment1 IS NULL THEN 
					LET l_rec_document.segment1 = "zz" # unknown 
					LET l_rec_document.segment2 = "zb" # unknown 
				END IF 
				LET l_rec_document.trans_amt = 0 - (l_rec_credithead.hand_amt + 
				l_rec_credithead.hand_tax_amt) 
				LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
				INSERT INTO f_document VALUES (l_rec_document.*) 
			END IF 

			OPEN c_dcredit USING l_rec_credithead.cred_num 

			FOREACH c_dcredit INTO l_rec_creditdetl.* 
				LET l_rec_document.line_acct_code = l_rec_creditdetl.line_acct_code 
				LET l_rec_document.segment1 = l_rec_creditdetl.line_acct_code[x1,y1] 
				LET l_rec_document.segment2 = l_rec_creditdetl.line_acct_code[x2,y2] 
				IF l_rec_document.segment1 IS NULL THEN 
					LET l_rec_document.segment1 = "zz" # unknown 
					LET l_rec_document.segment2 = "zb" # unknown 
				END IF 
				LET l_rec_document.trans_amt = 0 - l_rec_creditdetl.line_total_amt 
				LET l_rec_document.unpaid_amt = 0 - (l_rec_creditdetl.line_total_amt * 				l_unpaid_per) 
				INSERT INTO f_document VALUES (l_rec_document.*) 
			END FOREACH 

		END FOREACH 

	END IF 

	IF modu_continue_flag THEN 
		FOREACH c_cash INTO l_rec_cashreceipt.*, l_type_code 
			IF NOT rpt_int_flag_handler2("Cashreceipt:",l_rec_cashreceipt.cash_num,NULL,l_rpt_idx) THEN
				LET modu_continue_flag = false 
				EXIT FOREACH 
			END IF 			
			LET l_rec_document.line_acct_code = " " 
			LET l_rec_document.segment1 = "zz" # unknown 
			LET l_rec_document.segment2 = "zc" 
			LET l_rec_document.trans_type = TRAN_TYPE_RECEIPT_CA 
			LET l_rec_document.trans_num = l_rec_cashreceipt.cash_num 
			LET l_rec_document.trans_date = l_rec_cashreceipt.cash_date 
			LET l_rec_document.trans_ref = l_rec_cashreceipt.cheque_text 
			LET l_rec_document.days_num = get_age_bucket(TRAN_TYPE_RECEIPT_CA, 
			l_rec_cashreceipt.cash_date) 
			LET l_rec_document.curr_code = l_rec_cashreceipt.currency_code 
			LET l_rec_document.conv_qty = l_rec_cashreceipt.conv_qty 
			LET l_rec_document.trans_amt = 0 - l_rec_cashreceipt.cash_amt 
			IF l_rec_cashreceipt.applied_amt IS NULL THEN 
				LET l_rec_cashreceipt.applied_amt = 0 
			END IF 
			LET l_rec_document.unpaid_amt = 0 - (l_rec_cashreceipt.cash_amt 			- l_rec_cashreceipt.applied_amt) 
			INSERT INTO f_document VALUES (l_rec_document.*) 
		END FOREACH 
	END IF 

	IF modu_continue_flag THEN 
		LET l_query_text = "SELECT * FROM f_document i ", 
		"WHERE 1=1 ", modu_seg_text, " ", 
		" ORDER BY segment1, segment2 " 
		PREPARE s_fdocument FROM l_query_text 
		DECLARE c_fdocument CURSOR FOR s_fdocument 
		FOREACH c_fdocument INTO l_rec_document.* 
			IF NOT rpt_int_flag_handler2("Segment:",l_rec_document.segment1,l_rec_document.segment2,l_rpt_idx) THEN
				LET modu_continue_flag = false 
				EXIT FOREACH 
			END IF 	
			LET l_rec_document.curr_amt = 0 
			LET l_rec_document.over1_amt = 0 
			LET l_rec_document.over30_amt = 0 
			LET l_rec_document.over60_amt = 0 
			LET l_rec_document.over90_amt = 0 
			CASE 
				WHEN l_rec_document.days_num > 90 
					LET l_rec_document.over90_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 60 
					LET l_rec_document.over60_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 30 
					LET l_rec_document.over30_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 0 
					LET l_rec_document.over1_amt = l_rec_document.unpaid_amt 
				OTHERWISE 
					LET l_rec_document.curr_amt = l_rec_document.unpaid_amt 
			END CASE 

		#---------------------------------------------------------
		OUTPUT TO REPORT AAM_rpt_list(l_rpt_idx,l_rec_document.*) 
		IF NOT rpt_int_flag_handler2("Invoice:",l_rec_document.line_acct_code, l_rec_document.segment1,l_rpt_idx) THEN
			LET modu_continue_flag = false 
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
		END FOREACH 
	END IF 
	 
	#------------------------------------------------------------
	FINISH REPORT AAM_rpt_list
	CALL rpt_finish("AAM_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 
#####################################################################
# END FUNCTION AAM_rpt_process(p_where_text)
#####################################################################


#####################################################################
# REPORT AAM_rpt_list(p_rpt_idx,p_rec_document)
#
#
#####################################################################
REPORT AAM_rpt_list(p_rpt_idx,p_rec_document) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_document RECORD 
		line_acct_code LIKE invoicedetl.line_acct_code, 
		segment1 LIKE coa.acct_code, 
		segment2 LIKE coa.acct_code, 
		trans_type LIKE araudit.tran_type_ind, 
		trans_num LIKE invoicehead.inv_num, 
		trans_date LIKE invoicehead.inv_date, 
		trans_ref LIKE invoicehead.purchase_code, 
		days_num INTEGER, 
		curr_code LIKE invoicehead.currency_code, 
		conv_qty LIKE invoicehead.conv_qty, 
		trans_amt LIKE invoicehead.total_amt, 
		unpaid_amt LIKE invoicehead.paid_amt, 
		curr_amt LIKE customer.curr_amt, 
		over1_amt LIKE customer.over1_amt, 
		over30_amt LIKE customer.over30_amt, 
		over60_amt LIKE customer.over60_amt, 
		over90_amt LIKE customer.over90_amt 
	END RECORD
	DEFINE l_rec_validflex RECORD LIKE validflex.*
--	DEFINE l_arr_line array[4] OF CHAR(132)
	DEFINE l_cust_age_date DATE
	--DEFINE l_idx_num SMALLINT
	DEFINE l_overdue_per FLOAT
	DEFINE l_x SMALLINT 

	OUTPUT 
--	left margin 0 

	ORDER external BY p_rec_document.segment1, 
	p_rec_document.segment2 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text
			 
			PRINT COLUMN 2, "Aging Date:", 
			COLUMN 14, modu_rec_criteria.age_date USING "dd/mm/yyyy";
			 
			PRINT glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_document.segment1 
			IF p_rec_document.segment1 = "zz" THEN 
				PRINT COLUMN 06, "UNASSIGNED TRANSACTIONS" 
			ELSE 
				SELECT * INTO l_rec_validflex.* 
				FROM validflex 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = x1 
				AND flex_code = p_rec_document.segment1 
				IF status = NOTFOUND THEN 
					LET l_rec_validflex.desc_text = "** UNKNOWN ** " 
				END IF 
				PRINT COLUMN 01, p_rec_document.segment1 clipped, 
				COLUMN 04, "-", 
				COLUMN 06, l_rec_validflex.desc_text 
			END IF 

		BEFORE GROUP OF p_rec_document.segment2 
			NEED 2 LINES 
			CASE p_rec_document.segment2 
				WHEN "za" 
					PRINT COLUMN 11, "INVOICES" 
				WHEN "zb" 
					PRINT COLUMN 11, "CREDITS" 
				WHEN "zc" 
					PRINT COLUMN 11, "CASHRECEIPTS" 
				OTHERWISE 
					SELECT * INTO l_rec_validflex.* 
					FROM validflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND start_num = x2 
					AND flex_code = p_rec_document.segment2 
					IF status = NOTFOUND THEN 
						LET l_rec_validflex.desc_text = "** UNKNOWN ** " 
					END IF 
					PRINT COLUMN 05, p_rec_document.segment2 clipped, 
					COLUMN 09, "-", 
					COLUMN 11, l_rec_validflex.desc_text 
			END CASE 

		AFTER GROUP OF p_rec_document.segment2 
			PRINT COLUMN 37, GROUP sum(p_rec_document.unpaid_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 53, GROUP sum(p_rec_document.curr_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 69, GROUP sum(p_rec_document.over1_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 85, GROUP sum(p_rec_document.over30_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 101,group sum(p_rec_document.over60_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&", 
			COLUMN 117,group sum(p_rec_document.over90_amt/ 
			p_rec_document.conv_qty) USING "-----,--&.&&" 

		AFTER GROUP OF p_rec_document.segment1 
			NEED 4 LINES 
			PRINT COLUMN 35, "----------------------------------------", 
			"----------------------------------------", 
			"--------------" 
			PRINT COLUMN 01, "Total ", 
			COLUMN 07, p_rec_document.segment1 clipped 
			PRINT COLUMN 35, GROUP sum(p_rec_document.unpaid_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 51, GROUP sum(p_rec_document.curr_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 67, GROUP sum(p_rec_document.over1_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 83, GROUP sum(p_rec_document.over30_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 99,group sum(p_rec_document.over60_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 115,group sum(p_rec_document.over90_amt 
			/p_rec_document.conv_qty) USING "---,---,--&.&&" 
			SKIP 1 line 

		ON LAST ROW 
 
			NEED 6 LINES 
			SKIP 1 line 
			PRINT COLUMN 01, "Report Totals: ", " ",glob_rec_glparms.base_currency_code," ", 
			COLUMN 35, sum(p_rec_document.unpaid_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 51, sum(p_rec_document.curr_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 67, sum(p_rec_document.over1_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 83, sum(p_rec_document.over30_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 99, sum(p_rec_document.over60_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 115,sum(p_rec_document.over90_amt /p_rec_document.conv_qty) USING "---,---,--&.&&" 
			PRINT COLUMN 35, "========================================", 
			"========================================", 
			"==============" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno			
			
END REPORT
#####################################################################
# END REPORT AAM_rpt_list(p_rpt_idx,p_rec_document)
#####################################################################


#####################################################################
# FUNCTION get_freight_acct(p_cmpy_code, p_type_code, p_ord_ind)
#
#
#####################################################################
FUNCTION get_freight_acct(p_cmpy_code, p_type_code, p_ord_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_type_code LIKE customertype.type_code
	DEFINE p_ord_ind LIKE ordhead.ord_ind
	DEFINE l_freight_acct LIKE coa.acct_code 

	IF p_type_code != modu_rec_save.ftype 
	OR p_type_code IS NULL 
	OR modu_rec_save.ftype IS NULL 
	OR p_ord_ind != modu_rec_save.find 
	OR (p_ord_ind IS NOT NULL 
	AND modu_rec_save.find IS null) 
	OR (p_ord_ind IS NOT NULL 
	AND modu_rec_save.find IS null) THEN 
		SELECT freight_acct_code 
		INTO l_freight_acct 
		FROM customertype 
		WHERE cmpy_code = p_cmpy_code 
		AND type_code = p_type_code 

		IF status = NOTFOUND THEN 
			LET l_freight_acct = glob_rec_arparms.freight_acct_code 
		ELSE 

			IF p_ord_ind matches '[6-9]' 
			AND p_ord_ind IS NOT NULL THEN 
				# Should only get ORDER type indicator account if
				# currently processing Invoices OR Credits.
				CALL get_ordacct(p_cmpy_code,"customertype","freight_acct_code", 
				"AZP",p_ord_ind) 
				RETURNING l_freight_acct 
				IF l_freight_acct IS NULL THEN 
					LET l_freight_acct = glob_rec_arparms.freight_acct_code 
				END IF 
			ELSE 
				LET l_freight_acct = glob_rec_arparms.freight_acct_code 
			END IF 
		END IF 

		LET modu_rec_save.facct = l_freight_acct 
	END IF 

	RETURN modu_rec_save.facct 
END FUNCTION 
#####################################################################
# END FUNCTION get_freight_acct(p_cmpy_code, p_type_code, p_ord_ind)
#####################################################################


#####################################################################
# FUNCTION get_hand_acct(p_cmpy_code, p_type_code, p_ord_ind)
#
#
#####################################################################
FUNCTION get_hand_acct(p_cmpy_code, p_type_code, p_ord_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_type_code LIKE customertype.type_code
	DEFINE p_ord_ind LIKE ordhead.ord_ind
	DEFINE l_hand_acct LIKE coa.acct_code 

	IF p_type_code != modu_rec_save.htype 
	OR p_type_code IS NULL 
	OR modu_rec_save.htype IS NULL 
	OR p_ord_ind != modu_rec_save.hind 
	OR (p_ord_ind IS NOT NULL 
	AND modu_rec_save.hind IS null) 
	OR (p_ord_ind IS NOT NULL 
	AND modu_rec_save.hind IS null) THEN 
		SELECT lab_acct_code 
		INTO l_hand_acct 
		FROM customertype 
		WHERE cmpy_code = p_cmpy_code 
		AND type_code = p_type_code 

		IF status = NOTFOUND THEN 
			LET l_hand_acct = glob_rec_arparms.lab_acct_code 
		ELSE 
			IF p_ord_ind matches '[6-9]' 
			AND p_ord_ind IS NOT NULL THEN 
			
				# Should only get ORDER type indicator account if
				# currently processing Invoices OR Credits.
				CALL get_ordacct(p_cmpy_code,"customertype","lab_acct_code","AZP",p_ord_ind) RETURNING l_hand_acct 
				IF l_hand_acct IS NULL THEN 
					LET l_hand_acct = glob_rec_arparms.lab_acct_code 
				END IF 
			ELSE 
				LET l_hand_acct = glob_rec_arparms.lab_acct_code 
			END IF 
		END IF 
		LET modu_rec_save.hacct = l_hand_acct 
	END IF 

	RETURN modu_rec_save.hacct 
END FUNCTION
#####################################################################
# END FUNCTION get_hand_acct(p_cmpy_code, p_type_code, p_ord_ind)
#####################################################################