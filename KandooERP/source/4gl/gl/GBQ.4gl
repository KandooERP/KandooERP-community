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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GBQ_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_sl_id LIKE kandoouser.sign_on_code
DEFINE modu_passed_desc LIKE batchdetl.desc_text
DEFINE modu_jour_num LIKE batchhead.jour_num
DEFINE modu_jour_code LIKE batchhead.jour_code
DEFINE modu_acct_code LIKE batchdetl.acct_code
DEFINE modu_jour_date LIKE batchhead.jour_date
DEFINE modu_glob_ware LIKE invoicedetl.ware_code
--DEFINE glob_rec_arparms RECORD LIKE arparms.*
DEFINE modu_rec_journal RECORD LIKE journal.*
DEFINE modu_rec_period RECORD LIKE period.*
DEFINE modu_rec_customer RECORD LIKE customer.*
DEFINE modu_rec_invoicehead RECORD LIKE invoicehead.*
DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.*
DEFINE modu_rec_invrates RECORD LIKE invrates.*
DEFINE modu_rec_warehouse RECORD LIKE warehouse.*
DEFINE modu_rec_creditrates RECORD LIKE creditrates.*
DEFINE modu_rec_ordrates RECORD LIKE ordrates.*
DEFINE modu_rec_credithead RECORD LIKE credithead.*
DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.*
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.*
--DEFINE modu_rec_customertype RECORD LIKE customertype.*
DEFINE modu_rec_bal RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text 
END RECORD 
DEFINE modu_arr_rec_period array[400] OF RECORD 
	scroll_flag CHAR(1), 
	jour_num LIKE batchhead.jour_num, 
	year_num SMALLINT, 
	period_num SMALLINT, 
	jour_code CHAR(3), 
	jour_date DATE 
END RECORD 
DEFINE modu_all_ok SMALLINT
DEFINE modu_i SMALLINT
DEFINE modu_idx SMALLINT
DEFINE modu_mask LIKE warehouse.acct_mask_code
DEFINE modu_prev_cust_type LIKE customer.type_code
DEFINE modu_rec_docdata RECORD 
	ref_num LIKE batchdetl.ref_num, 
	ref_text LIKE batchdetl.ref_text, 
	tran_date DATE, 
	currency_code LIKE batchdetl.currency_code, 
	conv_qty LIKE batchdetl.conv_qty 
END RECORD 
DEFINE modu_rec_detldata RECORD 
	post_acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	debit_amt LIKE batchdetl.debit_amt, 
	credit_amt LIKE batchdetl.credit_amt 
END RECORD
DEFINE modu_rec_ratedata RECORD 
	ship_qty LIKE invoicedetl.ship_qty, 
	line_num LIKE invoicedetl.line_num, 
	ware_code LIKE invoicedetl.ware_code 
END RECORD 
DEFINE modu_tmp_desc CHAR(40)
DEFINE modu_ord_num INTEGER
DEFINE modu_ord_ind CHAR(1)
DEFINE modu_rec_detltax RECORD 
	tax_code LIKE invoicedetl.tax_code, 
	ext_tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 
DEFINE modu_rec_taxtemp RECORD 
	tax_acct_code LIKE batchdetl.acct_code, 
	tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 
DEFINE modu_rec_carttemp RECORD 
	acct_code CHAR(18), 
	cart_amt MONEY 
END RECORD 
DEFINE modu_rec_labrtemp RECORD 
	acct_code CHAR(18), 
	labr_amt MONEY 
END RECORD 
DEFINE modu_rec_current RECORD 
	cust_type LIKE customer.type_code, 
	ar_acct_code LIKE arparms.ar_acct_code, 
	freight_acct_code LIKE arparms.freight_acct_code, 
	lab_acct_code LIKE arparms.lab_acct_code, 
	labr_acct_code LIKE mbparms.labour_acct_code, 
	tax_acct_code LIKE arparms.tax_acct_code, 
	disc_acct_code LIKE arparms.disc_acct_code, 
	exch_acct_code LIKE arparms.exch_acct_code, 
	bal_acct_code LIKE arparms.ar_acct_code, 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	freight_amt LIKE invoicehead.freight_amt, 
	freight_tax_code LIKE invoicehead.freight_tax_code, 
	freight_tax_amt LIKE invoicehead.freight_tax_amt, 
	hand_amt LIKE invoicehead.hand_amt, 
	hand_tax_code LIKE invoicehead.hand_tax_code, 
	hand_tax_amt LIKE invoicehead.hand_tax_amt, 
	disc_amt LIKE invoicehead.disc_amt, 
	jour_code LIKE batchhead.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	ref_num LIKE batchdetl.ref_num, 
	base_debit_amt LIKE batchdetl.debit_amt, 
	base_credit_amt LIKE batchdetl.credit_amt, 
	currency_code LIKE currency.currency_code, 
	exch_ref_code LIKE exchangevar.ref_code 
END RECORD 
DEFINE modu_selection_text CHAR(1200)
DEFINE modu_select_text CHAR(1200)
DEFINE modu_err_message CHAR(80)
DEFINE modu_inv_num LIKE invoicehead.inv_num
DEFINE modu_cash_num LIKE cashreceipt.cash_num
DEFINE modu_cred_num LIKE credithead.cred_num
--DEFINE modu_ans CHAR(1)
DEFINE modu_tmp_poststatus RECORD LIKE poststatus.*
DEFINE modu_stat_code LIKE poststatus.status_code
--DEFINE glob_in_trans SMALLINT
DEFINE modu_post_status LIKE poststatus.status_code
--DEFINE glob_posted_journal LIKE batchhead.jour_num
DEFINE modu_tran_type1_ind LIKE exchangevar.tran_type1_ind
DEFINE modu_ref1_num LIKE exchangevar.ref1_num
DEFINE modu_tran_type2_ind LIKE exchangevar.tran_type2_ind
DEFINE modu_ref2_num LIKE exchangevar.ref2_num
DEFINE modu_exchangevar RECORD LIKE exchangevar.*
--DEFINE modu_tmp_text CHAR(8)
DEFINE modu_conv_qty LIKE invoicehead.conv_qty
DEFINE modu_sv_conv_qty LIKE invoicehead.conv_qty
 
############################################################
# MODULE Scope Variables FROM intfjour.4gl
############################################################
DEFINE modu_batchhead RECORD LIKE batchhead.*
DEFINE modu_prob_found SMALLINT 

############################################################
# IN GBQ_rpt_process GBQ_rpt_process(GBQ_rpt_query()) ->
# 1. START REPORT 
#
# 2. call invoice() do all the invoice history updates AND postings 
#		-> IF glob_rec_arparms.detail_to_gl_flag = "Y/N" -> create_summ_batches() OR create_gl_batches()
# 	-> CALL intfjour2() OUTPUT REPORT
# 3. call credit()  do all the credit history updates AND postings 
#		-> IF glob_rec_arparms.detail_to_gl_flag = "Y/N" -> create_summ_batches() OR create_gl_batches()
# 	-> CALL intfjour2() OUTPUT REPORT
# 4. CALL receipt() do all the receipts history updates AND postings 
#		-> IF glob_rec_arparms.detail_to_gl_flag = "Y/N" -> create_summ_batches() OR create_gl_batches()
# 	-> CALL intfjour2() OUTPUT REPORT
# 5. CALL exch_var() IF glob_rec_arparms.gl_flag = "Y" post exchange variances only IF post TO GL required
#		-> IF glob_rec_arparms.detail_to_gl_flag = "Y/N" -> create_summ_batches() OR create_gl_batches()
# 	-> CALL intfjour2() OUTPUT REPORT
# 
# 6. FINISH REPORT
#
# Info FUNCTION create_summ_batches() and FUNCTION create_gl_batches()
# CALL intfjour2() for OUTPUT REPORT
#
############################################################

############################################################
# FUNCTION GBQ_main()
#
# #  This program (GBQ.4gl, intfjour.4gl) provides a drill down of
#  summary batch TO show source details of summarised batch line.
# \brief module Logic IS a copy of AS7 AND jourintf that duplicates a detailed
#  posting FOR the selected batch TO temporary tables.
############################################################
FUNCTION GBQ_main() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GBQ")

	SELECT * INTO glob_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode != 0 THEN 
		CALL fgl_winmessage("AR Parameters Not Set Up",kandoomsg2("A",7005,""),"ERROR") 
		#7005 AR Parameters Not Set Up;  Refer Menu AZP.
		EXIT PROGRAM 
	END IF 

	LET modu_sl_id = "AR" 
	CALL create_table("batchhead","t_batchhead","","N") 
	--   CALL create_table("batchdetl","t_batchdetl","","N") #changed to normal table
	CALL create_table("postinvhead","t_postinvhead","","N") 
	CALL create_table("postcredhead","t_postcredhead","","N") 
	CALL create_table("postcashrcpt","t_postcashrcpt","","N") 
	CALL create_table("postexchvar","t_postexchvar","","N") 
	
	LET modu_all_ok = 1 
	
	LET glob_rec_arparms.detail_to_gl_flag = "Y" 

	CREATE temp TABLE posttemp(ref_num INTEGER, 
	ref_text CHAR(10), 
	post_acct_code CHAR(18), 
	desc_text CHAR(40), 
	debit_amt DECIMAL(16,2), 
	credit_amt DECIMAL(16,2), 
	base_debit_amt DECIMAL(16,2), 
	base_credit_amt DECIMAL(16,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	stats_qty DECIMAL(15,3), 
	ar_acct_code CHAR(18) ) with no LOG 

	CREATE INDEX posttemp_idx1 ON posttemp(ar_acct_code) 

	CREATE temp TABLE taxtemp(tax_acct_code CHAR(18), 
	tax_amt DECIMAL(16,2)) with no LOG 

	CREATE temp TABLE carttemp(acct_code CHAR(18), 
	cart_amt DECIMAL(16,2)) with no LOG 

	CREATE temp TABLE labrtemp(acct_code CHAR(18), 
	labr_amt DECIMAL(16,2)) with no LOG 

	CREATE temp TABLE posterrors(textline CHAR(80)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW G547 with FORM "G547" 
			CALL windecoration_g("G547") 

			MENU "AR Drill Down" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GBQ","menu-ar-drill-down") 
					CALL GBQ_rpt_process(GBQ_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 	#COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL GBQ_rpt_process(GBQ_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR View REPORT using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT PROGRAM 

			END MENU 
			CLOSE WINDOW G547 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GBQ_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G547 with FORM "G547" 
			CALL windecoration_g("G547") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GBQ_rpt_query()) #save where clause in env 
			CLOSE WINDOW G547 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GBQ_rpt_process(get_url_sel_text())
	END CASE 
		
END FUNCTION 


############################################################
# FUNCTION GBQ_rpt_query()
#
#
############################################################
FUNCTION GBQ_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_tmp_year LIKE period.year_num
	DEFINE l_tmp_period LIKE period.period_num 
--	DEFINE l_again SMALLINT

	DEFINE l_where2_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue "
	CLEAR SCREEN
	CONSTRUCT BY NAME l_where_text ON jour_num, 
	year_num, 
	period_num 
	
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GBQ","construct-jour") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN true 
	END IF 
	
	
	LET l_query_text = "SELECT unique jour_num, ", 
	"year_num, ", 
	"period_num, ", 
	"jour_code, ", 
	"jour_date ", 
	"FROM batchhead ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND entry_code = 'AR' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY jour_num, year_num, period_num " 
	PREPARE q_period FROM l_query_text 
	DECLARE c_period CURSOR FOR q_period 
	
	CALL modu_arr_rec_period.clear()
	LET modu_idx = 0 
	FOREACH c_period INTO modu_jour_num, 
		modu_rec_period.year_num, 
		modu_rec_period.period_num, 
		modu_jour_code,modu_jour_date 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_period[modu_idx].jour_num = modu_jour_num 
		LET modu_arr_rec_period[modu_idx].year_num = modu_rec_period.year_num 
		LET modu_arr_rec_period[modu_idx].period_num = modu_rec_period.period_num 
		LET modu_arr_rec_period[modu_idx].jour_code = modu_jour_code 
		LET modu_arr_rec_period[modu_idx].jour_date = modu_jour_date 
	END FOREACH 
	
	IF modu_idx = 0 THEN 
		ERROR kandoomsg2("A",3512,"") 	# 3512 "You must SELECT a VALID year AND period"
		RETURN false 
	END IF 
	
	MESSAGE kandoomsg2("U",9113,modu_idx) #U9113 modu_idx records selected
	CALL set_count(modu_idx) 
	MESSAGE kandoomsg2("G",1056,"") #1056 "RETURN on line TO generate REPORT"
--	LET l_again = false 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	
	DIALOG ATTRIBUTE(UNBUFFERED)
		#input only to select ONE row to select batches
		#INPUT ARRAY modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* attributes(append row = false, insert row = false, delete row = false, auto append = false) 
		DISPLAY ARRAY modu_arr_rec_period TO sr_period.*  
	
--			BEFORE INPUT 
--				CALL publish_toolbar("kandoo","GBQ","inp-period") 
	
--			ON ACTION "WEB-HELP" 
--				CALL onlinehelp(getmoduleid(),null) 
	
--			ON ACTION "actToolbarManager" 
	--			CALL setuptoolbar() 
	
			BEFORE ROW 
				LET modu_idx = arr_curr() 
				LET modu_arr_rec_period[modu_idx].scroll_flag = "*"
				LET modu_jour_num = modu_arr_rec_period[modu_idx].jour_num 
				LET glob_fisc_period = modu_arr_rec_period[modu_idx].period_num 
				LET glob_fisc_year = modu_arr_rec_period[modu_idx].year_num 
	
				#LET scrn = scr_line()
				#DISPLAY modu_arr_rec_period[modu_idx].* TO sr_period[scrn].*
	
				AFTER ROW
				LET modu_arr_rec_period[modu_idx].scroll_flag = NULL
	
--		AFTER FIELD scroll_flag 
--			IF arr_curr() >= arr_count() 
--			AND fgl_lastkey() = fgl_keyval("down") THEN 
--				ERROR kandoomsg2("U",9001,"") # 3513 "No more rows in the direction you are going"
--				NEXT FIELD scroll_flag 
--			END IF 
--
--		ON ACTION ("DOUBLECLICK","ACCEPT")
--		BEFORE FIELD jour_num 
--			LET modu_acct_code = NULL 
--			MESSAGE kandoomsg2("G",1057,"") 
	
--			LET modu_jour_num = modu_arr_rec_period[modu_idx].jour_num 
--			LET glob_fisc_period = modu_arr_rec_period[modu_idx].period_num 
--			LET glob_fisc_year = modu_arr_rec_period[modu_idx].year_num 
	
	
				#?what a xxx code ...
	
				#temp hack ??
--??			IF report1(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,0) THEN 
					# report1 was a common funcition to START REPORT GBQ_rpt_list
#				INITIALIZE glob_rec_rmsreps.sel_text TO NULL 
--				LET glob_rec_rpt_selector.ref1_num = modu_jour_num --USING "&&&&&&&&&&" 
--				LET glob_rec_rpt_selector.ref2_num = glob_fisc_period --USING "&&"
--				LET glob_rec_rpt_selector.ref3_num = glob_fisc_year --USING "&&&&" 
--				LET glob_rec_rpt_selector.ref4_num = modu_jour_code clipped 
--				LET glob_rec_rpt_selector.ref1_date = modu_jour_date --USING "dd/mm/yy" 
--				IF modu_acct_code IS NOT NULL THEN 
--					LET glob_rec_rpt_selector.ref1_text =	modu_acct_code clipped				 
--				END IF			
					
					
{				
				LET l_where3_text[1,10] = modu_jour_num USING "&&&&&&&&&&" 
				LET l_where3_text.sel_text[12,15] = glob_fisc_period USING "&&" 
				LET l_where3_text.sel_text[17,21] = glob_fisc_year USING "&&&&" 
				LET l_where3_text.sel_text[23,26] = modu_jour_code clipped 
				LET l_where3_text.sel_text[28,38] = modu_jour_date USING "dd/mm/yy" 
				IF modu_acct_code IS NOT NULL THEN 
					LET l_where3_text.sel_text[40,58] = modu_acct_code clipped 
				END IF 
}
		
{
				IF glob_rec_rmsreps.exec_ind = "1" THEN 
					CALL GBQ_rpt_process() 
					MESSAGE kandoomsg2("G",1056,"") 
				ELSE 
					UPDATE rmsreps 
					SET sel_text = glob_rec_rmsreps.sel_text 
					WHERE report_code = glob_rec_rmsreps.report_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					CALL exec_report() 
				END IF 
}
--			ELSE 
--				RETURN false 
--			END IF 
{
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			NEXT FIELD scroll_flag 
}
		END DISPLAY  #Screen Array INPUT

		#----------------------------------
		# INPUT GL Account select criteria
		INPUT modu_acct_code FROM batchdetl.acct_code 

--			BEFORE INPUT 
--				CALL publish_toolbar("kandoo","GBQ","inp-acct_code") 

--			ON ACTION "WEB-HELP" 
--				CALL onlinehelp(getmoduleid(),null) 

--			ON ACTION "actToolbarManager" 
--				CALL setuptoolbar() 

		END INPUT #4gl-account input

		ON ACTION "ACCEPT"
			LET quit_flag = false 
			LET int_flag = false 		
			ACCEPT DIALOG
			
		ON ACTION "CANCEL"
			LET quit_flag = true 
			LET int_flag = true 		
			EXIT DIALOG

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE DIALOG
			CALL publish_toolbar("kandoo","GBQ","inp-acct_code")
			CALL publish_toolbar("kandoo","GBQ","inp-period") 
			 
		AFTER DIALOG
--			LET modu_jour_num = modu_arr_rec_period[modu_idx].jour_num 
--			LET glob_fisc_period = modu_arr_rec_period[modu_idx].period_num 
--			LET glob_fisc_year = modu_arr_rec_period[modu_idx].year_num 
	
			LET glob_rec_rpt_selector.ref1_num = modu_jour_num --USING "&&&&&&&&&&" 
			LET glob_rec_rpt_selector.ref2_num = glob_fisc_period --USING "&&"
			LET glob_rec_rpt_selector.ref3_num = glob_fisc_year --USING "&&&&" 
			LET glob_rec_rpt_selector.ref4_num = modu_jour_code clipped 
			LET glob_rec_rpt_selector.ref1_date = modu_jour_date --USING "dd/mm/yy" 
			IF modu_acct_code IS NOT NULL THEN 
				LET glob_rec_rpt_selector.ref1_text =	modu_acct_code clipped				 
			END IF			
		

	END DIALOG

--	IF int_flag OR quit_flag THEN 
--		LET quit_flag = false 
--		LET int_flag = false 
--		RETURN NULL 
--	END IF 
	
--	IF l_again THEN 
--		RETURN NULL 
--	ELSE 
--		RETURN l_where_text 
--	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 	
END FUNCTION 


############################################################
# FUNCTION GBQ_rpt_process()  
#
############################################################
# IF this IS a properly configured online site (ie correct # locks
# THEN they may wish TO run one big transaction. In which CASE
# poststatus.online_ind = "Y". Just TO be flexible you may also
# run the program in the 'old' lock table mode. This will still use
# the post tables but will allow single glob_rec_kandoouser.cmpy_code sites TO ensure
# absolute integrity of data.
############################################################
FUNCTION GBQ_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
--	DEFINE l_msgresp LIKE language.yes_flag 



	DELETE FROM t_postinvhead WHERE 1=1 
	DELETE FROM t_postcredhead WHERE 1=1 
	DELETE FROM t_postcashrcpt WHERE 1=1 
	DELETE FROM t_postexchvar WHERE 1=1 
	DELETE FROM t_batchhead WHERE 1=1 
	DELETE FROM t_batchdetl WHERE username = glob_rec_kandoouser.sign_on_code AND program_id = glob_rec_prog.module_id
	DELETE FROM posttemp WHERE 1=1 
	DELETE FROM carttemp WHERE 1=1 
	DELETE FROM labrtemp WHERE 1=1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GBQ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GBQ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].sel_text
	
	#------------------------------------------------------------
	IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = "2" THEN
	
	
		LET modu_jour_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref1_num  
		LET glob_fisc_period = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref2_num 
		LET glob_fisc_year = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref3_num 
		LET modu_jour_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref4_num 
		LET modu_jour_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref1_date 
		LET modu_acct_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].ref1_text 

{	 
		LET modu_jour_num = glob_rec_rmsreps.sel_text[1,10] 
		LET glob_fisc_period = glob_rec_rmsreps.sel_text[12,15] 
		LET glob_fisc_year = glob_rec_rmsreps.sel_text[17,21] 
		LET modu_jour_code = glob_rec_rmsreps.sel_text[23,24] 
		LET modu_jour_date = glob_rec_rmsreps.sel_text[28,38] 
		LET modu_acct_code = glob_rec_rmsreps.sel_text[40,58] 
}
		IF modu_acct_code = " " THEN 
			INITIALIZE modu_acct_code TO NULL 
		END IF 
	END IF
	#------------------------------------- 
	# Check that the journals are present
	LET modu_err_message = " Journal Verify "
	 
	SELECT * INTO modu_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = glob_rec_arparms.cash_jour_code 
	IF status = NOTFOUND THEN 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
			MESSAGE kandoomsg2("G",9062,"Cash") 
		END IF 
		sleep 2 
		EXIT PROGRAM 
	END IF

	# !!! This block is a 100% duplicate from above ??? why	 
	SELECT * INTO modu_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = glob_rec_arparms.sales_jour_code 
	IF status = NOTFOUND THEN 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
			MESSAGE kandoomsg2("G",9062,"Sales") 
		END IF 
		sleep 2 
		EXIT PROGRAM 
	END IF
	#end of duplicate
 
 	#-------------------------------
	# CALL invoice()
	# do all the invoice history updates AND postings
	CALL invoice(l_rpt_idx) 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW w1_rpt 
		RETURN 
	END IF
	 
 	#-------------------------------
	# CALL credit()
	# do all the credit history updates AND postings
	CALL credit(l_rpt_idx) 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW w1_rpt 
		RETURN 
	END IF
	 
 	#-------------------------------
	# CALL receipt(l_rpt_idx)
	# do all the receipts history updates AND postings
	CALL receipt(l_rpt_idx) 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW w1_rpt 
		RETURN 
	END IF

 	#-------------------------------
	# CALL exch_var(l_rpt_idx)  	 
	# post exchange variances only IF post TO GL required
	IF glob_rec_arparms.gl_flag = "Y" THEN 
		CALL exch_var(l_rpt_idx) 
	END IF
	 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW w1_rpt 
		RETURN 
	END IF
	 
	#------------------------------------------------------------
	FINISH REPORT GBQ_rpt_list
	CALL rpt_finish("GBQ_rpt_list")
	#------------------------------------------------------------
	 
END FUNCTION 
############################################################
# FUNCTION build_mask(p_override) 
#
#
############################################################
FUNCTION build_mask(p_override) 
	DEFINE p_override, acct_code LIKE account.acct_code 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_i SMALLINT 
	DEFINE l_j SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_mtype SMALLINT 
	
	DECLARE struct_cur CURSOR FOR 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num > 0 

	FOREACH struct_cur 
		LET l_i = l_rec_structure.start_num 
		LET l_j = l_rec_structure.length_num 
		
		CASE 
			WHEN l_rec_structure.type_ind = "F" 
				LET acct_code[l_i,l_i+l_j-1] = l_rec_structure.default_text 
			OTHERWISE 
				LET l_mtype = mask_type(modu_mask[l_i,l_i+l_j-1], l_j) 
				CASE 
					WHEN l_mtype = 1 
						LET acct_code[l_i,l_i+l_j-1] = modu_mask[l_i,l_i+l_j-1] 
					WHEN l_mtype = 0 
						LET acct_code[l_i,l_i+l_j-1] = p_override[l_i,l_i+l_j-1] 
					OTHERWISE 
						LET l_mtype = mask_type(p_override[l_i,l_i+l_j-1], l_j) 
						CASE 
							WHEN l_mtype = 1 
								LET acct_code[l_i,l_i+l_j-1] = p_override[l_i,l_i+l_j-1] 
							OTHERWISE 
								LET acct_code[l_i,l_i+l_j-1] = modu_mask[l_i,l_i+l_j-1] 
						END CASE 
				END CASE 
		END CASE 
	END FOREACH
	 
	RETURN (acct_code) 
END FUNCTION 


############################################################
# FUNCTION mask_type(p_seg_code, p_len)
#
#
############################################################
FUNCTION mask_type(p_seg_code, p_len) 
	DEFINE p_seg_code LIKE account.acct_code 
	DEFINE p_len SMALLINT 
	DEFINE l_blank SMALLINT 
	DEFINE l_question_mark SMALLINT 
	DEFINE l_idx SMALLINT 

	LET l_blank = true 
	LET l_question_mark = true 

	IF p_seg_code IS NULL THEN 
		RETURN (0) 
	END IF 

	FOR l_idx = 1 TO p_len 
		IF p_seg_code[l_idx, l_idx] != " " THEN 
			LET l_blank = false 
		END IF 
		IF p_seg_code[l_idx, l_idx] != "?" THEN 
			LET l_question_mark = false 
		END IF 
	END FOR 

	#RETURN
	IF l_blank THEN 
		RETURN (0) 
	END IF 
	IF l_question_mark THEN 
		RETURN (2) 
	END IF 
	RETURN (1) 
END FUNCTION 


############################################################
# FUNCTION get_cust_accts() 
#
#
############################################################
FUNCTION get_cust_accts() 
	DEFINE l_freight_acct_code LIKE customertype.freight_acct_code 
	DEFINE l_ord_ind LIKE ordhead.ord_ind 
	DEFINE l_rma_num LIKE credithead.rma_num 

	# Receivables control, handling, freight, tax (FOR NULL tax codes) AND
	# discount posting accounts determined by customer type unless NULL

	LET l_ord_ind = NULL 
	
	SELECT ar_acct_code, 
	freight_acct_code, 
	lab_acct_code, 
	tax_acct_code, 
	disc_acct_code, 
	exch_acct_code 
	INTO modu_rec_current.ar_acct_code, 
	modu_rec_current.freight_acct_code, 
	modu_rec_current.lab_acct_code, 
	modu_rec_current.tax_acct_code, 
	modu_rec_current.disc_acct_code, 
	modu_rec_current.exch_acct_code 
	FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = modu_rec_current.cust_type 

	IF status = NOTFOUND THEN 
		LET modu_rec_current.ar_acct_code = NULL 
		LET modu_rec_current.freight_acct_code = NULL 
		LET modu_rec_current.lab_acct_code = NULL 
		LET modu_rec_current.tax_acct_code = NULL 
		LET modu_rec_current.disc_acct_code = NULL 
		LET modu_rec_current.exch_acct_code = NULL 
	ELSE 
		IF modu_rec_current.tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
			SELECT ord_num INTO modu_ord_num FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = modu_rec_docdata.ref_num 
			IF status != NOTFOUND THEN 
				SELECT ord_ind INTO l_ord_ind FROM ordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = modu_ord_num 
				IF status = NOTFOUND THEN 
					LET l_ord_ind = NULL 
				END IF 
			END IF 
		ELSE 
			IF modu_rec_current.tran_type_ind = TRAN_TYPE_CREDIT_CR THEN 
				SELECT rma_num INTO l_rma_num FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = modu_rec_docdata.ref_num 
				IF status != NOTFOUND THEN 
					SELECT ord_ind INTO l_ord_ind FROM ordhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_rma_num 
					IF status = NOTFOUND THEN 
						LET l_ord_ind = NULL 
					END IF 
				END IF 
			END IF 
		END IF 
		IF l_ord_ind matches '[6-9]' 
		AND l_ord_ind IS NOT NULL THEN 
			CALL get_ordacct(glob_rec_kandoouser.cmpy_code,"customertype","freight_acct_code", 
			modu_rec_current.cust_type,l_ord_ind) 
			RETURNING l_freight_acct_code 
			IF l_freight_acct_code IS NOT NULL THEN 
				LET modu_rec_current.freight_acct_code = l_freight_acct_code 
			END IF 
		END IF 
	END IF 

	SELECT labour_acct_code INTO modu_rec_current.labr_acct_code 
	FROM mbparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_current.labr_acct_code = glob_rec_arparms.lab_acct_code 
	END IF 

	IF modu_rec_current.ar_acct_code IS NULL THEN 
		LET modu_rec_current.ar_acct_code = glob_rec_arparms.ar_acct_code 
	END IF 	
	
	IF modu_rec_current.freight_acct_code IS NULL THEN 
		IF l_ord_ind matches '[6-9]' THEN 
			CALL get_ordacct(glob_rec_kandoouser.cmpy_code,"arparms","freight_acct_code", 
			"AZP",l_ord_ind) 
			RETURNING modu_rec_current.freight_acct_code 
		END IF 
		IF modu_rec_current.freight_acct_code IS NULL THEN 
			LET modu_rec_current.freight_acct_code = glob_rec_arparms.freight_acct_code 
		END IF 
	END IF 
	
	IF modu_rec_current.lab_acct_code IS NULL THEN 
		LET modu_rec_current.lab_acct_code = glob_rec_arparms.lab_acct_code 
	END IF 
	IF modu_rec_current.tax_acct_code IS NULL THEN 
		LET modu_rec_current.tax_acct_code = glob_rec_arparms.tax_acct_code 
	END IF 
	IF modu_rec_current.disc_acct_code IS NULL THEN 
		LET modu_rec_current.disc_acct_code = glob_rec_arparms.disc_acct_code 
	END IF 
	IF modu_rec_current.exch_acct_code IS NULL THEN 
		LET modu_rec_current.exch_acct_code = glob_rec_arparms.exch_acct_code 
	END IF 
	LET modu_prev_cust_type = modu_rec_current.cust_type 

END FUNCTION 


############################################################
# FUNCTION create_gl_batches(p_rpt_idx)
#
#
############################################################
FUNCTION create_gl_batches(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #report index
	DEFINE ps_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD
	DEFINE l_posted_some SMALLINT 
	DEFINE l_count_rec INTEGER 
--	DEFINE l_msgresp LIKE language.yes_flag 

	# batch posting details according TO receivables control account AND
	# currency code (ie. all entries FOR the same currency AND
	# control/balancing account in one batch)
	DECLARE p_curs CURSOR FOR 
	SELECT unique posttemp.ar_acct_code, 
	posttemp.currency_code 
	FROM posttemp 
	LET l_posted_some = false 
	FOREACH p_curs INTO modu_rec_current.bal_acct_code, 
		modu_rec_current.currency_code 
		IF int_flag OR quit_flag THEN
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_credit_amt < 0 OR posttemp.base_debit_amt > 0) 
		AND posttemp.currency_code = modu_rec_current.currency_code
		 
		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_selection_text = " SELECT ", "\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" posttemp.ref_num, ", 
			" posttemp.ref_text, ", 
			" posttemp.post_acct_code, ", 
			" posttemp.desc_text, ", 
			" posttemp.debit_amt, ", 
			" posttemp.credit_amt, ", 
			" posttemp.base_debit_amt, ", 
			" posttemp.base_credit_amt, ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" posttemp.stats_qty ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND (posttemp.base_credit_amt < 0 ", 
			" OR posttemp.base_debit_amt > 0) ", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"" 


			#OUTPUT 1.1 TO REPORT in/from FUNCTION create_gl_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange			
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code)
			 
			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
					#              "posted."
				END IF 
			END IF 
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY GL batches as created
		END IF 
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_debit_amt < 0 OR posttemp.base_credit_amt > 0) 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code # kc 27/2/96 
			LET modu_selection_text = " SELECT ", "\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" posttemp.ref_num, ", 
			" posttemp.ref_text, ", 
			" posttemp.post_acct_code, ", 
			" posttemp.desc_text, ", 
			" posttemp.debit_amt, ", 
			" posttemp.credit_amt, ", 
			" posttemp.base_debit_amt, ", 
			" posttemp.base_credit_amt, ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" posttemp.stats_qty ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND (posttemp.base_debit_amt < 0 ", 
			" OR posttemp.base_credit_amt > 0) ", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"" 
			
			#OUTPUT 1.2 TO REPORT in/from FUNCTION create_gl_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange				
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code) 
			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
					#              "posted."
				END IF 
			END IF 
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			#check FOR -ve journal number - indicates an error in posting account
			#within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY GL batches as created
		END IF
		 
		# Do a third pass TO pick up statistics only batches
		# in CASE it IS implemented in the future
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND (posttemp.base_debit_amt = 0 AND posttemp.base_credit_amt = 0) 
		AND posttemp.stats_qty <> 0 
		AND posttemp.currency_code = modu_rec_current.currency_code 

		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_selection_text = " SELECT ", "\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" posttemp.ref_num, ", 
			" posttemp.ref_text, ", 
			" posttemp.post_acct_code, ", 
			" posttemp.desc_text, ", 
			" posttemp.debit_amt, ", 
			" posttemp.credit_amt, ", 
			" posttemp.base_debit_amt, ", 
			" posttemp.base_credit_amt, ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" posttemp.stats_qty ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND (posttemp.base_debit_amt = 0 ", 
			" AND posttemp.base_credit_amt = 0) ", 
			" AND posttemp.stats_qty <> 0 ", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"" 

			#OUTPUT 1.3 TO REPORT in/from FUNCTION create_gl_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange				
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code) 
			IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 DISPLAY "No entries FOR type ",modu_rec_current.tran_type_ind,
					#              "posted."
				END IF 
			END IF 
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			#check FOR -ve journal number - indicates an error in posting account
			#within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY GL batches as created
		END IF 
	END FOREACH 
END FUNCTION 


############################################################
# FUNCTION create_summ_batches(p_rpt_idx) 
#
#
############################################################
FUNCTION create_summ_batches(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_rec_s_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty 
	END RECORD
	DEFINE l_posted_some SMALLINT 
	DEFINE l_count_rec INTEGER 
	DEFINE l_upd_sel_text CHAR(500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	# batch posting details according TO receivables control account,
	# AND currency code but with one summary entry per
	# posting account/date combination
	DECLARE s_curs CURSOR FOR 
	SELECT unique posttemp.ar_acct_code, 
	posttemp.currency_code, 
	posttemp.conv_qty 
	FROM posttemp 
	LET l_posted_some = false 
	
	FOREACH s_curs INTO modu_rec_current.bal_acct_code, 
		modu_rec_current.currency_code, 
		modu_conv_qty 
		#
		# Check that there are details TO post before entering intfjour, OTHERWISE
		# the batch number IS allocated AND unused
		#
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_credit_amt < 0 OR posttemp.base_debit_amt > 0)
		 
		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_selection_text = " SELECT ","\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" 0, ", 
			" \"Summary\", ", 
			" posttemp.post_acct_code, ", 
			" \"", modu_passed_desc clipped, "\",", 
			" sum(posttemp.debit_amt), ", 
			" sum(posttemp.credit_amt), ", 
			" sum(posttemp.base_debit_amt), ", 
			" sum(posttemp.base_credit_amt), ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" sum(posttemp.stats_qty) ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND (posttemp.base_credit_amt < 0 ", 
			" OR posttemp.base_debit_amt > 0) ", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" group by posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.post_acct_code, posttemp.tran_date" 

			#OUTPUT 2.1 TO REPORT in/from FUNCTION create_summ_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange				
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code) 
			
			IF modu_rec_current.jour_num = 0 THEN 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
					#      "posted."
				END IF 
			END IF 
			LET l_upd_sel_text = "SELECT ref_num, ref_text ", 
			"FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND (posttemp.base_credit_amt < 0 ", 
			" OR posttemp.base_debit_amt > 0) ", 
			" AND posttemp.conv_qty = ",modu_conv_qty 
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY each batch number as created
		END IF
		 
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_credit_amt > 0 OR posttemp.base_debit_amt < 0)
		 
		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_selection_text = " SELECT ","\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" 0, ", 
			" \"Summary\", ", 
			" posttemp.post_acct_code, ", 
			" \"", modu_passed_desc clipped, "\",", 
			" sum(posttemp.debit_amt), ", 
			" sum(posttemp.credit_amt), ", 
			" sum(posttemp.base_debit_amt), ", 
			" sum(posttemp.base_credit_amt), ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" sum(posttemp.stats_qty) ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND (posttemp.base_debit_amt < 0 ", 
			" OR posttemp.base_credit_amt > 0) ", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" group by posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.post_acct_code, posttemp.tran_date" 

			#OUTPUT 2.2 TO REPORT in/from FUNCTION create_summ_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange				
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code) 
			
			IF modu_rec_current.jour_num = 0 THEN 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
					#      "posted."
				END IF 
			END IF 
			
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
			# DISPLAY each batch number as created
		END IF
		 
		#
		# Now do Statistics
		SELECT count(*) INTO l_count_rec FROM posttemp 
		WHERE posttemp.ar_acct_code = modu_rec_current.bal_acct_code 
		AND posttemp.currency_code = modu_rec_current.currency_code 
		AND posttemp.conv_qty = modu_conv_qty 
		AND (posttemp.base_debit_amt = 0 AND posttemp.base_credit_amt = 0) 
		AND posttemp.stats_qty <> 0 
		
		IF l_count_rec IS NULL OR l_count_rec = 0 THEN 
		ELSE 
			LET l_posted_some = true 
			LET modu_rec_bal.acct_code = modu_rec_current.bal_acct_code 
			LET modu_selection_text = " SELECT ","\"", modu_rec_current.tran_type_ind clipped, "\",", 
			" 0, ", 
			" \"Summary\", ", 
			" posttemp.post_acct_code, ", 
			" \"", modu_passed_desc clipped, "\",", 
			" sum(posttemp.debit_amt), ", 
			" sum(posttemp.credit_amt), ", 
			" sum(posttemp.base_debit_amt), ", 
			" sum(posttemp.base_credit_amt), ", 
			" posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.tran_date, ", 
			" sum(posttemp.stats_qty) ", 
			" FROM posttemp ", 
			" WHERE posttemp.ar_acct_code = ", 
			"\"", modu_rec_bal.acct_code clipped, "\"", 
			" AND posttemp.currency_code = \"", 
			modu_rec_current.currency_code, "\"", 
			" AND posttemp.conv_qty = ",modu_conv_qty, 
			" AND (posttemp.base_debit_amt = 0 ", 
			"AND posttemp.base_credit_amt = 0)", 
			" AND posttemp.stats_qty <> 0", 
			" group by posttemp.currency_code, ", 
			" posttemp.conv_qty, ", 
			" posttemp.post_acct_code, posttemp.tran_date" 

			#OUTPUT 2.3 TO REPORT in/from FUNCTION create_summ_batches()
			#This is some special common function to output to report BUT ONY used by GBQ ??? sooo strange				
			LET modu_rec_current.jour_num = intfjour2(p_rpt_idx,
			modu_selection_text, 
			glob_rec_kandoouser.cmpy_code, 
			modu_sl_id, 
			modu_rec_bal.*, 
			glob_fisc_period, 
			glob_fisc_year, 
			modu_rec_current.jour_code, 
			"A", 
			modu_rec_current.currency_code, 
			"AR", 
			modu_jour_num, 
			modu_acct_code)
			 
			IF modu_rec_current.jour_num = 0 THEN 
				IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
					ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
					SLEEP 1 
					# 3500 "No entries FOR type ",modu_rec_current.tran_type_ind,
					#      "posted."
				END IF 
			END IF
			 
			IF glob_posted_journal IS NOT NULL THEN 
				LET glob_posted_journal = NULL 
			END IF 
			# check FOR -ve journal number - indicates an error in posting account
			# within the GL batch
			IF modu_rec_current.jour_num < 0 THEN 
				LET modu_all_ok = 0 
			END IF 
		END IF 
	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION invoice()  
#
# Posting Invoices
# IF an error has occurred AND it was NOT in this part of the post THEN
# walk on by ...
############################################################
FUNCTION invoice(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index  
--	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_err_text = "Commenced invoice post" 
	LET glob_post_text = "Commenced INSERT INTO t_postinvhead" 
	
	# SELECT the invoices FOR posting AND INSERT them INTO t_postinvhead
	# table THEN UPDATE them as posted so they won't be touched by
	# anyone ELSE
	LET glob_err_text = "Invoice SELECT FOR INSERT" 
	
	DECLARE inv_curs CURSOR FOR 
	SELECT h.inv_num FROM invoicehead h 
	WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.jour_num = modu_jour_num 
	AND h.posted_flag = "Y" 

	LET glob_err_text = "Invoice FOREACH FOR INSERT" 

	FOREACH inv_curs INTO modu_inv_num 
	
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		
		SELECT * INTO modu_rec_invoicehead.* FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = modu_inv_num 

		IF modu_rec_invoicehead.currency_code IS NULL THEN 
			LET modu_rec_invoicehead.currency_code = glob_rec_glparms.base_currency_code 
			LET modu_rec_invoicehead.conv_qty = 1 
		END IF 

		IF modu_rec_invoicehead.conv_qty IS NULL THEN 
			LET modu_rec_invoicehead.conv_qty = 1 
		END IF 
		INSERT INTO t_postinvhead VALUES (modu_rec_invoicehead.*) 
	END FOREACH 

	LET glob_err_text = "Create gl batch - invoices" 

	IF glob_rec_arparms.gl_flag = "Y" THEN 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
			MESSAGE kandoomsg2("A",3504,"") #3504 "Posting Invoices..."
			sleep 2 #give to user time to read this
		END IF 
		CALL send_invoices(p_rpt_idx) 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		LET glob_post_text = "Completed invoice post" 
	END IF 

	CALL jm_cos_post(p_rpt_idx) 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	LET glob_post_text = "Commenced UPDATE jour_num FROM t_postinvhead" 
	LET glob_err_text = "Update jour_num in invoicehead" 
	LET glob_post_text = "Commenced DELETE FROM t_postinvhead" 
	LET glob_err_text = "DELETE FROM t_postinvhead" 
	DELETE FROM t_postinvhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_post_text = "Invoice posting completed correctly" 

	WHENEVER ERROR stop 

END FUNCTION 


############################################################
# FUNCTION send_invoices()
#
############################################################
FUNCTION send_invoices(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index  
	DEFINE l_cmpy_code LIKE company.cmpy_code 

	LET modu_prev_cust_type = "z" 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_debit_amt = 0 
	# SELECT all unposted invoices FOR the required period
	LET modu_select_text = "SELECT H.cmpy_code, ", 
	" H.inv_num, ", 
	" H.cust_code, ", 
	" H.inv_date, ", 
	" H.currency_code, ", 
	" H.conv_qty, ", 
	" C.type_code, ", 
	" H.freight_amt, ", 
	" H.freight_tax_code, ", 
	" H.freight_tax_amt, ", 
	" H.hand_amt, ", 
	" H.hand_tax_code, ", 
	" H.hand_tax_amt ", 
	"FROM t_postinvhead H, customer C ", 
	"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND H.posted_flag = \"Y\" ", 
	"AND H.year_num = ",glob_fisc_year," ", 
	"AND H.period_num = ",glob_fisc_period," ", 
	"AND H.cmpy_code = C.cmpy_code ", 
	"AND H.cust_code = C.cust_code ", 
	"ORDER BY H.cmpy_code, H.cust_code, H.inv_num " 
	PREPARE inv_sel FROM modu_select_text 
	DECLARE in_curs CURSOR FOR inv_sel 
	LET glob_err_text = "FOREACH INTO posttemp - invoicehead" 

	FOREACH in_curs INTO l_cmpy_code, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 

		IF modu_rec_current.cust_type != modu_prev_cust_type OR 
		(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
		(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
			CALL get_cust_accts() 
		END IF 

		# INSERT posting data FOR the Invoice freight AND handling amounts
		IF modu_rec_current.freight_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_current.freight_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.freight_amt = modu_rec_current.base_credit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			DECLARE c_ware CURSOR FOR 
			SELECT ware_code FROM invoicedetl 
			WHERE inv_num = modu_rec_docdata.ref_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			OPEN c_ware 
			FETCH c_ware INTO modu_glob_ware 
			CLOSE c_ware 

			IF modu_glob_ware IS NOT NULL THEN 
				SELECT acct_mask_code INTO modu_mask FROM warehouse 
				WHERE ware_code = modu_glob_ware 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				LET modu_mask = "??????????????????" 
			END IF 

			LET modu_rec_current.freight_acct_code = 
			build_mask(modu_rec_current.freight_acct_code) 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.freight_acct_code, # freight control account 
			modu_rec_docdata.ref_num, # invoice number 
			0, 
			modu_rec_current.freight_amt, # invoice freight amount 
			modu_rec_current.base_debit_amt, # zero FOR freight 
			modu_rec_current.base_credit_amt, # converted freight amt 
			modu_rec_docdata.currency_code, # invoice currency code 

			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_current.hand_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.hand_amt = modu_rec_current.base_credit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
			LET modu_rec_current.lab_acct_code = build_mask(modu_rec_current.lab_acct_code) 
			
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control account 
			modu_rec_docdata.ref_num, # invoice number 
			0, 
			modu_rec_current.hand_amt, # invoice handling amount 
			modu_rec_current.base_debit_amt, # zero FOR handling 
			modu_rec_current.base_credit_amt, # converted handling amt 
			modu_rec_docdata.currency_code, # invoice currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 
		
		# accumulate handling AND freight tax
		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, modu_rec_current.freight_tax_amt) 
		END IF 
		
		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, modu_rec_current.hand_tax_amt) 
		END IF 
		# create posting details FOR the line items FOR the selected invoices

		DECLARE id_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		0, 
		ext_sale_amt, 
		ship_qty, 
		line_num, 
		ware_code, 
		tax_code, 
		ext_tax_amt 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH id_curs INTO modu_rec_detldata.*, 
			modu_rec_ratedata.*, 
			modu_rec_detltax.* 
			
			IF int_flag OR quit_flag THEN 
				IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET quit_flag = true 
					RETURN 
				END IF 
			END IF 
			IF modu_rec_ratedata.ware_code IS NOT NULL THEN 
				SELECT acct_mask_code INTO modu_mask FROM warehouse 
				WHERE ware_code = modu_rec_ratedata.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				LET modu_mask = "??????????????????" 
			END IF 
			LET modu_tmp_desc = modu_rec_detldata.desc_text 
			
			SELECT * INTO modu_rec_invrates.* FROM invrates 
			WHERE rate_type = "PRP" 
			AND inv_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				LET modu_rec_detldata.credit_amt = modu_rec_ratedata.ship_qty 
				* modu_rec_invrates.unit_price_amt 
				LET modu_tmp_desc = "PRP ",modu_rec_detldata.desc_text 
			END IF 
			
			###      END Check Product Qty         ###
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_detldata.credit_amt = modu_rec_current.base_credit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
			LET modu_rec_detldata.post_acct_code = build_mask(modu_rec_detldata.post_acct_code) 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # invoice number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_tmp_desc, 
			#modu_rec_detldata.desc_text,         # Line item desc
			modu_rec_detldata.debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_detldata.credit_amt, # line item sale amount 
			modu_rec_current.base_debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
			modu_rec_current.base_credit_amt, # converted sale amount 
			modu_rec_docdata.currency_code, # invoice currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # invoice DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code, modu_rec_detltax.ext_tax_amt) 
			END IF 
			
			SELECT * INTO modu_rec_invrates.* FROM invrates 
			WHERE rate_type = "CRP" 
			AND inv_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				IF modu_rec_invrates.unit_price_amt <> 0 THEN 
					LET modu_rec_detldata.credit_amt = modu_rec_ratedata.ship_qty 
					* modu_rec_invrates.unit_price_amt 
					CALL add_cartage(modu_rec_detldata.credit_amt) 
				END IF 
			END IF 
			
			SELECT * INTO modu_rec_invrates.* FROM invrates 
			WHERE rate_type = "LRP" 
			AND inv_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				IF modu_rec_invrates.unit_price_amt <> 0 THEN 
					LET modu_rec_detldata.credit_amt = modu_rec_ratedata.ship_qty 
					* modu_rec_invrates.unit_price_amt 
					CALL add_labour(modu_rec_detldata.credit_amt) 
				END IF 
			END IF 
			
			DECLARE c_userdef CURSOR FOR 
			SELECT * INTO modu_rec_invrates.* FROM invrates 
			WHERE inv_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND rate_type NOT in ("PRP","CRP","LRP") 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			FOREACH c_userdef 
				IF modu_rec_invrates.unit_price_amt <> 0 THEN 
					LET modu_ord_num = 0 
					LET modu_ord_ind = 0 
					
					SELECT ord_num INTO modu_ord_num FROM invoicehead 
					WHERE inv_num = modu_rec_invrates.inv_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					SELECT ord_ind INTO modu_ord_ind FROM ordhead 
					WHERE order_num = modu_ord_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					SELECT rev_acct_code INTO modu_rec_ordrates.rev_acct_code 
					FROM ordrates 
					WHERE ord_ind = modu_ord_ind 
					AND rate_type_code = modu_rec_invrates.rate_type 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						LET modu_rec_ordrates.rev_acct_code = glob_rec_glparms.susp_acct_code 
					END IF 
					
					LET modu_rec_ordrates.rev_acct_code = 
					build_mask(modu_rec_ordrates.rev_acct_code) 
					LET modu_rec_detldata.credit_amt = modu_rec_ratedata.ship_qty * modu_rec_invrates.unit_price_amt 
					LET modu_tmp_desc = modu_rec_invrates.rate_type," ",modu_rec_detldata.desc_text 
					IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
						IF modu_rec_docdata.conv_qty != 0 THEN 
							LET modu_rec_current.base_credit_amt = modu_rec_detldata.credit_amt / 
							modu_rec_docdata.conv_qty 
						END IF 
					END IF 
					#IF use_currency_flag IS 'N' THEN any source documents in foreign
					#currency need TO be converted TO base, AND a base batch created.
					IF glob_rec_glparms.use_currency_flag = "N" THEN 
						LET modu_rec_detldata.credit_amt = modu_rec_current.base_credit_amt 
						LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
						LET modu_sv_conv_qty = 1 
					ELSE 
						LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
					END IF 
					
					INSERT INTO posttemp VALUES 
					(modu_rec_docdata.ref_num, # invoice number 
					modu_rec_docdata.ref_text, # customer code 
					modu_rec_ordrates.rev_acct_code, # line item gl account 
					modu_tmp_desc, # line item desc 
					modu_rec_detldata.debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
					modu_rec_detldata.credit_amt, # line item sale amount 
					modu_rec_current.base_debit_amt, # zero FOR TRAN_TYPE_INVOICE_IN 
					modu_rec_current.base_credit_amt, # converted sale amount 
					modu_rec_docdata.currency_code, # invoice currency code 
					modu_sv_conv_qty, 
					modu_rec_docdata.tran_date, # invoice DATE 
					0, # stats qty NOT yet in use 
					modu_rec_current.ar_acct_code) # ar control account 
				END IF 
				
			END FOREACH 
			
			### END check FOR user defined rates
		END FOREACH 

		# now INSERT the accumulated cartage postings
		CALL cart_postings(TRAN_TYPE_CREDIT_CR) 
		# now INSERT the accumulated labour postings
		CALL labr_postings(TRAN_TYPE_CREDIT_CR) 
		# now INSERT the accumulated tax postings
		CALL tax_postings(TRAN_TYPE_CREDIT_CR) 

	END FOREACH 

	LET modu_rec_bal.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET modu_rec_bal.desc_text = "AR Invoice Balancing Entry" 
	IF modu_post_status = 3 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
		LET modu_passed_desc = "Summary AR Invoices ",glob_fisc_year USING "<<<<", " ", 
		glob_fisc_period USING "<<" 
		CALL create_summ_batches(p_rpt_idx) 
	ELSE 
		CALL create_gl_batches(p_rpt_idx) 
	END IF 

	DELETE FROM posttemp WHERE 1=1 
	
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 
END FUNCTION 


############################################################
# FUNCTION jm_cos_post(p_rpt_idx)
#
############################################################
FUNCTION jm_cos_post(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_jm_cos_acct_code LIKE batchdetl.acct_code 
	DEFINE l_jm_wip_acct_code LIKE batchdetl.acct_code
	DEFINE l_currency_code LIKE batchdetl.currency_code
	DEFINE l_conv_qty LIKE batchdetl.conv_qty
	DEFINE l_base_amt LIKE batchdetl.debit_amt
	DEFINE l_inv_date LIKE invoicehead.inv_date
	DEFINE l_ref_text CHAR(10)
	DEFINE l_jmparms RECORD LIKE jmparms.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	# debit the activity cost of sales accounts.
	# AND credit the individual activity wip AND
	SELECT * INTO l_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		RETURN 
	END IF 

	# first debit the activity cos account.
	LET modu_err_message = "Posting Cost of Sales" 
	LET modu_rec_bal.tran_type_ind = "COS" 
	LET modu_rec_bal.desc_text = "JM COS Balancing entry " 
	LET modu_rec_current.tran_type_ind = "CO" 

	LET modu_select_text = "SELECT H.inv_num, ", 
	" D.line_num, ", 
	" D.part_code, ", 
	" A.cos_acct_code, ", 
	" A.acct_code, ", 
	" D.ext_cost_amt, ", 
	" A.title_text, ", 
	" H.currency_code, ", 
	" H.conv_qty, ", 
	" H.inv_date ", 
	"FROM postinvhead H, invoicedetl D, activity A ", 
	"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND H.posted_flag = \"Y\" ", 
	"AND H.period_num = ",glob_fisc_period," ", 
	"AND H.year_num = ",glob_fisc_year," ", 
	"AND H.inv_ind = \"3\" ", 
	"AND D.cmpy_code = H.cmpy_code ", 
	"AND D.cust_code = H.cust_code ", 
	"AND D.inv_num = H.inv_num ", 
	"AND A.cmpy_code = D.cmpy_code ", 
	"AND A.job_code = H.purchase_code ", 
	"AND A.activity_code = D.part_code ", 
	"AND A.var_code = D.ser_qty " 

	PREPARE sel_cos FROM modu_select_text 
	DECLARE jm_cos_c CURSOR FOR sel_cos 
	LET glob_err_text = "FOREACH INTO postemp - jm cos" 

	FOREACH jm_cos_c INTO modu_rec_invoicehead.inv_num, 
		modu_rec_invoicedetl.line_num, 
		modu_rec_invoicedetl.part_code, 
		l_jm_cos_acct_code, 
		l_jm_wip_acct_code, 
		modu_rec_invoicedetl.ext_cost_amt, 
		modu_rec_invoicehead.com1_text, 
		l_currency_code, 
		l_conv_qty, 
		l_inv_date 
		# note the activity name IS in batchdetl(posttemp).desc_text
		# put the invoice line number INTO batchdetl(posttemp).ref_text
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		LET l_ref_text = "Line ", modu_rec_invoicedetl.line_num USING "<<<" 

		IF modu_rec_invoicedetl.ext_cost_amt != 0 OR l_base_amt != 0 THEN 
			IF l_conv_qty IS NOT NULL THEN 
				IF l_conv_qty != 0 THEN 
					LET l_base_amt = modu_rec_invoicedetl.ext_cost_amt / l_conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_invoicedetl.ext_cost_amt = l_base_amt 
				LET l_conv_qty = 1 
				LET l_currency_code = glob_rec_glparms.base_currency_code 
			END IF 

			INSERT INTO posttemp VALUES (modu_rec_invoicehead.inv_num, 
			l_ref_text, 
			l_jm_cos_acct_code, 
			modu_rec_invoicehead.com1_text, 
			modu_rec_invoicedetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			0, 
			l_currency_code, 
			l_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 
			# Now credit the activity wip
			INSERT INTO posttemp VALUES (modu_rec_invoicehead.inv_num, 
			l_ref_text, 
			l_jm_wip_acct_code, 
			modu_rec_invoicehead.com1_text, 
			0, 
			modu_rec_invoicedetl.ext_cost_amt, 
			0, 
			l_base_amt, 
			l_currency_code, 
			l_conv_qty, 
			l_inv_date, 
			0, 
			glob_rec_glparms.susp_acct_code) 
		END IF 

	END FOREACH 
	
	CALL create_gl_batches(p_rpt_idx)
	 
	DELETE FROM posttemp WHERE 1 = 1 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF
	 
END FUNCTION 


############################################################
# FUNCTION credit(p_rpt_idx) 
# Posting Credits 
############################################################
FUNCTION credit(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_err_text = "Commenced credit post" 
	LET glob_post_text = "Commenced INSERT INTO t_postcredhead " 
	# SELECT the credits FOR posting AND INSERT them INTO t_postcredhead
	# table THEN UPDATE them as posted so they won't be touched by
	# anyone ELSE
	LET glob_err_text = "Credit SELECT FOR INSERT" 

	DECLARE credit_curs CURSOR FOR 

	SELECT h.cred_num FROM credithead h 
	WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.jour_num = modu_jour_num 
	AND h.posted_flag = "Y" 
	LET glob_err_text = "Credit FOREACH FOR INSERT" 

	FOREACH credit_curs INTO modu_cred_num 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		SELECT * INTO modu_rec_credithead.* FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = modu_cred_num 
		LET glob_err_text = "GQB - Insert INTO t_postcredhead " 
		IF modu_rec_credithead.currency_code IS NULL THEN 
			LET modu_rec_credithead.currency_code = glob_rec_glparms.base_currency_code 
			LET modu_rec_credithead.conv_qty = 1 
		END IF 
		IF modu_rec_credithead.conv_qty IS NULL THEN 
			LET modu_rec_credithead.conv_qty = 1 
		END IF 
		INSERT INTO t_postcredhead VALUES (modu_rec_credithead.*) 
	END FOREACH 

	LET glob_err_text = "Create gl batch - credits" 
	LET glob_post_text = "Create GL batch - credits" 

	IF glob_rec_arparms.gl_flag = "Y" THEN 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
			MESSAGE kandoomsg2("A",3506,"") 	#3506 "Posting Credits.........."
			sleep 2
		END IF 
		CALL send_credits(p_rpt_idx) 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
		LET glob_post_text = "Commenced credit post" 
	END IF 

	LET glob_post_text = "Commenced UPDATE jour_num FROM t_postcredhead" 
	LET glob_err_text = "DELETE FROM t_postcredhead" 
	DELETE FROM t_postcredhead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_post_text = "Credit posting completed correctly" 

	WHENEVER ERROR stop 

END FUNCTION 


############################################################
# FUNCTION send_credits(p_rpt_idx)
#
############################################################
FUNCTION send_credits(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET modu_prev_cust_type = "z" 
	LET modu_rec_current.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_current.jour_code = glob_rec_arparms.sales_jour_code 
	LET modu_rec_current.base_credit_amt = 0 
	# SELECT all unposted credits FOR the required period
	LET modu_select_text = "SELECT H.cmpy_code, ", 
	" H.cred_num, ", 
	" H.cust_code, ", 
	" H.cred_date, ", 
	" H.currency_code, ", 
	" H.conv_qty, ", 
	" C.type_code, ", 
	" H.freight_amt, ", 
	" H.freight_tax_code, ", 
	" H.freight_tax_amt, ", 
	" H.hand_amt, ", 
	" H.hand_tax_code, ", 
	" H.hand_tax_amt, ", 
	" H.disc_amt ", 
	"FROM t_postcredhead H, customer C ", 
	"WHERE H.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND H.posted_flag = \"Y\" ", 
	"AND H.year_num = ",glob_fisc_year," ", 
	"AND H.period_num = ",glob_fisc_period," ", 
	"AND H.cmpy_code = C.cmpy_code ", 
	"AND H.cust_code = C.cust_code ", 
	"ORDER BY H.cmpy_code, H.cust_code,", 
	" H.cred_num " 
	
	PREPARE sel_cred FROM modu_select_text 
	DECLARE cr_curs CURSOR FOR sel_cred 
	LET glob_err_text = "FOREACH INTO posttemp - credits" 

	FOREACH cr_curs INTO l_cmpy_code, 
		modu_rec_docdata.*, 
		modu_rec_current.cust_type, 
		modu_rec_current.freight_amt, 
		modu_rec_current.freight_tax_code, 
		modu_rec_current.freight_tax_amt, 
		modu_rec_current.hand_amt, 
		modu_rec_current.hand_tax_code, 
		modu_rec_current.hand_tax_amt, 
		modu_rec_current.disc_amt 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 
		IF modu_rec_current.cust_type != modu_prev_cust_type OR 
		(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
		(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
			CALL get_cust_accts() 
		END IF 
		
		# INSERT posting data FOR the Credit freight,
		# handling AND discount amounts
		IF modu_rec_current.freight_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_current.freight_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			DECLARE cr_ware CURSOR FOR 
			SELECT ware_code FROM creditdetl 
			WHERE cred_num = modu_rec_docdata.ref_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			OPEN cr_ware 
			FETCH cr_ware INTO modu_glob_ware 
			CLOSE cr_ware 
			IF modu_glob_ware IS NOT NULL THEN 
				SELECT acct_mask_code INTO modu_mask FROM warehouse 
				WHERE ware_code = modu_glob_ware 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				LET modu_mask = "??????????????????" 
			END IF 
			
			LET modu_rec_current.freight_acct_code = 
			build_mask(modu_rec_current.freight_acct_code) 
			
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.freight_amt = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.freight_acct_code, # freight control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.freight_amt, # credit freight amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 

		IF modu_rec_current.hand_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_current.hand_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.hand_amt = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 

			END IF 
			LET modu_rec_current.lab_acct_code = 
			build_mask(modu_rec_current.lab_acct_code) 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.lab_acct_code, # handling control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.hand_amt, # credit handling amount 
			0, 
			modu_rec_current.base_debit_amt, # converted freight amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 

		IF modu_rec_current.disc_amt IS NOT NULL AND 
		modu_rec_current.disc_amt != 0 THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_current.disc_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_current.disc_amt = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
			
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_current.disc_acct_code, # discount control acct 
			modu_rec_docdata.ref_num, # credit number 
			modu_rec_current.disc_amt, # credit discount amount 
			0, 
			modu_rec_current.base_debit_amt, # converted discount amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 
		END IF 

		# accumulate handling AND freight tax
		IF modu_rec_current.freight_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.freight_tax_code, modu_rec_current.freight_tax_amt) 
		END IF 
		IF modu_rec_current.hand_tax_amt != 0 THEN 
			CALL add_tax(modu_rec_current.hand_tax_code, modu_rec_current.hand_tax_amt) 
		END IF 

		# create posting details FOR the line items
		# FOR the selected credits
		DECLARE cd_curs CURSOR FOR 
		SELECT line_acct_code, 
		line_text, 
		ext_sales_amt, 
		0, 
		ship_qty, 
		line_num, 
		ware_code, 
		tax_code, 
		ext_tax_amt 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = modu_rec_docdata.ref_num 
		AND cust_code = modu_rec_docdata.ref_text 

		FOREACH cd_curs INTO modu_rec_detldata.*, 
			modu_rec_ratedata.*, 
			modu_rec_detltax.* 
			IF int_flag OR quit_flag THEN 
				IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET quit_flag = true 
					RETURN 
				END IF 
			END IF 

			LET modu_tmp_desc = modu_rec_detldata.desc_text 
			IF modu_rec_ratedata.ware_code IS NOT NULL THEN 
				SELECT acct_mask_code INTO modu_mask FROM warehouse 
				WHERE ware_code = modu_rec_ratedata.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				LET modu_mask = "??????????????????" 
			END IF 
			SELECT * INTO modu_rec_creditrates.* FROM creditrates 
			WHERE rate_type = "PRP" 
			AND cred_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				LET modu_rec_detldata.debit_amt = modu_rec_ratedata.ship_qty 
				* modu_rec_creditrates.unit_price_amt 
				LET modu_tmp_desc = "PRP ",modu_rec_detldata.desc_text 
			END IF 

			###      END Check Product Qty         ###
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_detldata.debit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_detldata.debit_amt = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			LET modu_rec_detldata.post_acct_code=build_mask( modu_rec_detldata.post_acct_code) 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # credit number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # line item gl account 
			modu_tmp_desc, 
			modu_rec_detldata.debit_amt, # line item sale amount 
			modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_CREDIT_CR 
			modu_rec_current.base_debit_amt, # converted amt 
			modu_rec_current.base_credit_amt, # zero FOR credits 
			modu_rec_docdata.currency_code, # credit currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # credit DATE 
			0, # stats qty NOT in use 
			modu_rec_current.ar_acct_code) # ar control account 
			IF modu_rec_detltax.ext_tax_amt != 0 THEN 
				CALL add_tax(modu_rec_detltax.tax_code,modu_rec_detltax.ext_tax_amt) 
			END IF 

			SELECT * INTO modu_rec_creditrates.* FROM creditrates 
			WHERE rate_type = "CRP" 
			AND cred_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				IF modu_rec_creditrates.unit_price_amt <> 0 THEN 
					LET modu_rec_detldata.debit_amt = modu_rec_ratedata.ship_qty 
					* modu_rec_creditrates.unit_price_amt 
					CALL add_cartage(modu_rec_detldata.debit_amt) 
				END IF 
			END IF 

			SELECT * INTO modu_rec_creditrates.* FROM creditrates 
			WHERE rate_type = "LRP" 
			AND cred_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				IF modu_rec_creditrates.unit_price_amt <> 0 THEN 
					LET modu_rec_detldata.debit_amt = modu_rec_ratedata.ship_qty 
					* modu_rec_creditrates.unit_price_amt 
					CALL add_labour(modu_rec_detldata.debit_amt) 
				END IF 
			END IF 

			DECLARE c_userdef2 CURSOR FOR 
			SELECT * INTO modu_rec_creditrates.* FROM creditrates 
			WHERE cred_num = modu_rec_docdata.ref_num 
			AND line_num = modu_rec_ratedata.line_num 
			AND rate_type NOT in ("PRP","CRP","LRP") 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			FOREACH c_userdef2 
				IF modu_rec_creditrates.unit_price_amt <> 0 THEN 
					LET modu_ord_num = 0 
					LET modu_ord_ind = 0 
					
					SELECT rma_num INTO modu_ord_num FROM credithead 
					WHERE cred_num = modu_rec_creditrates.cred_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					SELECT ord_ind INTO modu_ord_ind FROM ordhead 
					WHERE order_num = modu_ord_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					SELECT rev_acct_code INTO modu_rec_ordrates.rev_acct_code 
					FROM ordrates 
					WHERE ord_ind = modu_ord_ind 
					AND rate_type_code = modu_rec_creditrates.rate_type 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					IF status = NOTFOUND THEN 
						LET modu_rec_ordrates.rev_acct_code = glob_rec_glparms.susp_acct_code 
					END IF 
					LET modu_rec_ordrates.rev_acct_code = build_mask(modu_rec_ordrates.rev_acct_code) 
					LET modu_rec_detldata.debit_amt = modu_rec_ratedata.ship_qty * modu_rec_creditrates.unit_price_amt 
					LET modu_tmp_desc = modu_rec_creditrates.rate_type," ",modu_rec_detldata.desc_text 
					
					IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
						IF modu_rec_docdata.conv_qty != 0 THEN 
							LET modu_rec_current.base_debit_amt = modu_rec_detldata.debit_amt / 
							modu_rec_docdata.conv_qty 
						END IF 
					END IF 

					# IF use_currency_flag IS 'N' THEN any source documents in foreign
					# currency need TO be converted TO base, AND a base batch created.
					IF glob_rec_glparms.use_currency_flag = "N" THEN 
						LET modu_rec_detldata.debit_amt = modu_rec_current.base_debit_amt 
						LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
						LET modu_sv_conv_qty = 1 
					ELSE 
						LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
					END IF 
					
					INSERT INTO posttemp VALUES 
					(modu_rec_docdata.ref_num, # invoice number 
					modu_rec_docdata.ref_text, # customer code 
					modu_rec_ordrates.rev_acct_code, # line item gl account 
					modu_tmp_desc, # line item desc 
					modu_rec_detldata.debit_amt, # line item credit amount 
					modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_CREDIT_CR 
					modu_rec_current.base_debit_amt, # converted sale amount 
					modu_rec_current.base_credit_amt, # zero FOR TRAN_TYPE_CREDIT_CR 
					modu_rec_docdata.currency_code, # credit currency code 
					modu_sv_conv_qty, 
					modu_rec_docdata.tran_date, # credit DATE 
					0, # stats qty NOT yet in use 
					modu_rec_current.ar_acct_code) # ar control account 
				END IF 

			END FOREACH 

			### END check FOR user defined rates
		END FOREACH 

		# now INSERT the accumulated cartage postings
		CALL cart_postings("DR") 
		# now INSERT the accumulated labour postings
		CALL labr_postings("DR") 
		# now INSERT the accumulated tax postings
		CALL tax_postings("DR") 

	END FOREACH 

	LET modu_rec_bal.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET modu_rec_bal.desc_text = "AR Credit Balancing Entry" 
	LET glob_posted_journal = NULL 
	IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
		MESSAGE kandoomsg2("A",3506,"") #3506 "Posting Credits..."
		sleep 2
		
	END IF 
	IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
		LET modu_passed_desc = "Summary AR Credits ", 
		glob_fisc_year USING "<<<<", " ", 
		glob_fisc_period USING "<<" 
		CALL create_summ_batches(p_rpt_idx) 
	ELSE 
		CALL create_gl_batches(p_rpt_idx) 
	END IF 

	DELETE FROM posttemp WHERE 1 = 1 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 
END FUNCTION 


############################################################
# FUNCTION receipt(p_rpt_idx)
#
# Posting cash / posting receipt
############################################################
FUNCTION receipt(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_err_text = "Commenced receipt post" 
	LET glob_post_text = "Commenced INSERT INTO t_postcashrcpt " 
	# SELECT the credits FOR posting AND INSERT them INTO t_postcredhead
	# table THEN UPDATE them as posted so they won't be touched by
	# anyone ELSE
	LET glob_err_text = "Cashreceipt SELECT FOR INSERT" 
	DECLARE cash_curs CURSOR FOR 
	SELECT h.cash_num FROM cashreceipt h 
	WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND h.jour_num = modu_jour_num 
	AND h.posted_flag = "Y" 
	AND h.year_num = glob_fisc_year 
	AND h.period_num = glob_fisc_period 
	LET glob_err_text = "Cash FOREACH FOR INSERT"
	 
	FOREACH cash_curs INTO modu_cash_num
	 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF
		 
		SELECT * INTO modu_rec_cashreceipt.* FROM cashreceipt 
		WHERE cash_num = modu_cash_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_err_text = "GQB - Insert INTO t_postcashrcpt "
		 
		INSERT INTO t_postcashrcpt VALUES (modu_rec_cashreceipt.*) 
		LET glob_err_text = "GQB - cashreceipt post flag SET"
		 
	END FOREACH 

	LET glob_err_text = "Update history - credits" 
	LET glob_post_text = "Completed INSERT TO t_postcashrcpt" 
	LET glob_post_text = "Completed history post" 
	IF glob_rec_arparms.gl_flag = "Y" THEN 
		LET modu_prev_cust_type = "z" 
		LET modu_rec_current.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
		LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 
		LET modu_rec_current.base_credit_amt = 0 
		
		# SELECT all unposted cash receipts FOR the required period
		LET modu_select_text = "SELECT R.cmpy_code, ", 
		" R.cash_num, ", 
		" R.cust_code, ", 
		" R.cash_date, ", 
		" R.currency_code, ", 
		" R.conv_qty, ", 
		" C.type_code, ", 
		" R.cash_acct_code, ", 
		" R.cash_num, ", 
		" R.cash_amt, ", 
		" 0, ", 
		" R.disc_amt ", 
		"FROM t_postcashrcpt R, customer C ", 
		"WHERE R.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND R.posted_flag = \"Y\" ", 
		"AND R.year_num = ",glob_fisc_year," ", 
		"AND R.period_num = ",glob_fisc_period," ", 
		"AND R.cmpy_code = C.cmpy_code ", 
		"AND R.cust_code = C.cust_code ", 
		"ORDER BY R.cmpy_code, R.cust_code, ", 
		" R.cash_num " 

		PREPARE sel_cash FROM modu_select_text 
		DECLARE ca_curs CURSOR FOR sel_cash 
		LET glob_err_text = "FOREACH INTO posttemp - cash" 

		FOREACH ca_curs INTO l_cmpy_code, 
			modu_rec_docdata.*, 
			modu_rec_current.cust_type, 
			modu_rec_detldata.*, 
			modu_rec_current.disc_amt 
			
			IF int_flag OR quit_flag THEN 
				IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET quit_flag = true 
					RETURN 
				END IF 
			END IF 
			
			IF modu_rec_current.cust_type != modu_prev_cust_type OR 
			(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
			(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
				CALL get_cust_accts() 
			END IF 
			
			# INSERT posting data FOR the Receipt discount amount
			IF modu_rec_current.disc_amt IS NOT NULL AND modu_rec_current.disc_amt != 0 THEN 
				IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
					IF modu_rec_docdata.conv_qty != 0 THEN 
						LET modu_rec_current.base_debit_amt = modu_rec_current.disc_amt / 
						modu_rec_docdata.conv_qty 
					END IF 
				END IF 
				
				# IF use_currency_flag IS 'N' THEN any source documents in foreign
				# currency need TO be converted TO base, AND a base batch created.
				IF glob_rec_glparms.use_currency_flag = "N" THEN 
					LET modu_rec_current.disc_amt = modu_rec_current.base_debit_amt 
					LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
					LET modu_sv_conv_qty = 1 
				ELSE 
					LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
				END IF 

				INSERT INTO posttemp VALUES 
				(modu_rec_docdata.ref_num, # receipt number 
				modu_rec_docdata.ref_text, # customer code 
				modu_rec_current.disc_acct_code, # discount control acct 
				modu_rec_docdata.ref_num, # receipt number 
				modu_rec_current.disc_amt, # receipt disc amount 
				0, 
				modu_rec_current.base_debit_amt, # converted discount amt 
				modu_rec_current.base_credit_amt, # 0 FOR receipts 
				modu_rec_docdata.currency_code, # receipt currency code 
				modu_sv_conv_qty, 
				modu_rec_docdata.tran_date, # receipt DATE 
				0, # stats qty NOT in use 
				modu_rec_current.ar_acct_code) # ar control account 

			END IF 
			# create posting details FOR the selected receipts
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_detldata.debit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_detldata.debit_amt = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # receipt number 
			modu_rec_docdata.ref_text, # customer code 
			modu_rec_detldata.post_acct_code, # cash receipt gl account 
			modu_rec_detldata.desc_text, # recipt number 
			modu_rec_detldata.debit_amt, # receipt amount 
			modu_rec_detldata.credit_amt, # zero FOR TRAN_TYPE_RECEIPT_CA 
			modu_rec_current.base_debit_amt, # converted receipt amt 
			modu_rec_current.base_credit_amt, # 0 FOR receipts 
			modu_rec_docdata.currency_code, # receipt currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # receipt DATE 
			0, # stats qty NOT yet in use 
			modu_rec_current.ar_acct_code) # ar control account 

		END FOREACH 

		LET modu_rec_bal.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
		LET modu_rec_bal.desc_text = "AR Receipt Balancing Entry" 
		IF modu_post_status = 15 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
			MESSAGE kandoomsg2("A",3508,"") #3508 "Posting receipt/cash"
			sleep 2
		END IF 

		IF glob_rec_arparms.detail_to_gl_flag = "N" THEN 
			LET modu_passed_desc = "Summary AR Receipts ", 
			glob_fisc_year USING "<<<<", " ", 
			glob_fisc_period USING "<<" 
			CALL create_summ_batches(p_rpt_idx) 
		ELSE 
			CALL create_gl_batches(p_rpt_idx) 
		END IF 

		DELETE FROM posttemp WHERE 1 = 1 
		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
	END IF 

	LET glob_post_text = "Commenced UPDATE jour_num FROM t_postcashrcpt" 
	LET glob_post_text = "Commenced DELETE FROM t_postcashrcpt" 
	LET glob_err_text = "DELETE FROM t_postcashrcpt" 

	DELETE FROM t_postcashrcpt WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET glob_post_text = "Cash posting completed correctly" 
	
END FUNCTION 


############################################################
# FUNCTION exch_var(p_rpt_idx)
#
# Posting Exch Var Balancing Entry
############################################################
FUNCTION exch_var(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #report index 
	DEFINE l_rowid INTEGER 
	DEFINE l_rowid_num INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_err_text = "Commenced exchange post" 
	# SELECT the exchangevars FOR posting AND INSERT them INTO the
	# t_postexchvar table THEN UPDATE them as posted so they won't be touched
	# by anyone.
	LET glob_err_text = "Exchangevar SELECT FOR INSERT" 

	DECLARE exch_curs CURSOR FOR 
	SELECT rowid, 
	tran_type1_ind, 
	ref1_num, 
	tran_type2_ind, 
	ref2_num 
	FROM exchangevar 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_num = modu_jour_num 
	AND posted_flag = "Y" 
	AND period_num = glob_fisc_period 
	AND year_num = glob_fisc_year 
	AND source_ind = "A" 
	LET glob_err_text = "Exchangevar FOREACH FOR INSERT" 

	FOREACH exch_curs INTO l_rowid, 
		modu_tran_type1_ind, 
		modu_ref1_num, 
		modu_tran_type2_ind, 
		modu_ref2_num 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 

		WHILE (true) 
			DECLARE insert4_curs CURSOR FOR 
			SELECT * FROM exchangevar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rowid = l_rowid 
			LET glob_err_text = "Exchangevar lock FOR INSERT" 
			OPEN insert4_curs 
			FETCH insert4_curs INTO modu_exchangevar.* 
			LET modu_stat_code = status 
			IF modu_stat_code THEN 
				IF modu_stat_code = NOTFOUND THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 
			EXIT WHILE 
		END WHILE 

		LET glob_err_text = "PP1 - Post Exchangevar INSERT" 
		INSERT INTO t_postexchvar VALUES (modu_exchangevar.*, l_rowid) 
		LET glob_err_text = "PP1 - Exchangevar post flag SET" 
	END FOREACH 

	LET glob_err_text = "Create gl batch - exchangevar" 
	LET modu_prev_cust_type = "z" 
	LET modu_rec_current.tran_type_ind = "EXA" 
	LET modu_rec_current.jour_code = glob_rec_arparms.cash_jour_code 

	# INSERT posting data FOR the Receivables exchange variances
	# positive VALUES post as debits, negative VALUES as credits
	# with sign reversed
	LET modu_select_text = "SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM t_postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"Y\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt > 0 ", 
	"ORDER BY E.ref_code " 

	PREPARE exch_sel FROM modu_select_text 
	DECLARE exd_curs CURSOR FOR exch_sel 
	LET glob_err_text = "FOREACH AR (+ve) exchangevar" 

	FOREACH exd_curs INTO modu_rec_docdata.*, 
		modu_rec_current.exch_ref_code, 
		modu_rec_current.base_debit_amt, 
		modu_rec_current.cust_type 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 

		IF modu_rec_current.cust_type != modu_prev_cust_type OR 
		(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
		(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
			CALL get_cust_accts() 
		END IF 

		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # exch var ref 1 
		modu_rec_docdata.ref_text, # exch var ref 2 
		modu_rec_current.exch_acct_code, # exchange control account 
		modu_rec_current.exch_ref_code, # vendor code FOR source_ind "A" 
		0, 
		0, 
		modu_rec_current.base_debit_amt, # exch var amount IF +ve, 
		0, 
		modu_rec_docdata.currency_code, # exch var currency code 
		modu_rec_docdata.conv_qty, # exch var conversion rate 
		modu_rec_docdata.tran_date, # exch var DATE 
		0, # stats qty - NOT yet in use 
		modu_rec_current.ar_acct_code) # control account 

	END FOREACH 

	LET modu_rec_bal.tran_type_ind = "EXA" 
	LET modu_rec_bal.desc_text = " AR Exch Var Balancing Entry" 
	IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
		MESSAGE kandoomsg2("P",3506,"") 	# 3506 " Posting exch var..."
		sleep 2
	END IF 
	
	CALL create_gl_batches(p_rpt_idx) 
	
	DELETE FROM posttemp WHERE 1 = 1 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 
	
	LET modu_select_text = 
	"SELECT E.ref1_num, ", 
	" E.ref2_num, ", 
	" E.tran_date, ", 
	" E.currency_code, ", 
	" 1, ", 
	" E.ref_code, ", 
	" E.exchangevar_amt, ", 
	" C.type_code ", 
	"FROM t_postexchvar E, customer C ", 
	"WHERE E.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND E.posted_flag = \"Y\" ", 
	"AND E.year_num = ",glob_fisc_year," ", 
	"AND E.period_num = ",glob_fisc_period," ", 
	"AND E.source_ind = \"A\" ", 
	"AND E.cmpy_code = C.cmpy_code ", 
	"AND E.ref_code = C.cust_code ", 
	"AND E.exchangevar_amt < 0 ", 
	"ORDER BY E.ref_code " 

	PREPARE exc_sel FROM modu_select_text 
	DECLARE exc_curs CURSOR FOR exc_sel 
	LET glob_err_text = "FOREACH AR (-ve) exch variation" 

	FOREACH exc_curs INTO modu_rec_docdata.*, 
		modu_rec_current.exch_ref_code, 
		modu_rec_current.base_credit_amt, 
		modu_rec_current.cust_type 
		IF int_flag OR quit_flag THEN 
			IF promptTF("",kandoomsg2("U",8503,""),1)	THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET quit_flag = true 
				RETURN 
			END IF 
		END IF 

		IF modu_rec_current.cust_type != modu_prev_cust_type OR 
		(modu_rec_current.cust_type IS NULL AND modu_prev_cust_type IS NOT null) OR 
		(modu_rec_current.cust_type IS NOT NULL AND modu_prev_cust_type IS null) THEN 
			CALL get_cust_accts() 
		END IF 

		LET modu_rec_current.base_credit_amt = 0 - modu_rec_current.base_credit_amt - 0 

		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # exch var ref 1 
		modu_rec_docdata.ref_text, # exch var ref 2 
		modu_rec_current.exch_acct_code, # exchange control account 
		modu_rec_current.exch_ref_code, # vendor code FOR source_ind "A" 
		0, 
		0, 
		0, 
		modu_rec_current.base_credit_amt, # exch var amount 
		# IF -ve (sign reversed)
		modu_rec_docdata.currency_code, # exch var currency code 
		modu_rec_docdata.conv_qty, # exch var conversion rate 
		modu_rec_docdata.tran_date, # exch var DATE 
		0, # stats qty - NOT yet in use 
		modu_rec_current.ar_acct_code) # control account 
	END FOREACH 

	LET modu_rec_bal.tran_type_ind = "EXA" 
	LET modu_rec_bal.desc_text = " AR Exch Var Balancing Entry" 
	IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GBQ_rpt_list")].exec_ind = '1' THEN 
		MESSAGE kandoomsg2("P",3506,"") 
		# 3506 " Posting exch var..." AT 1,1
	END IF 
	CALL create_gl_batches(p_rpt_idx) 

	DELETE FROM t_postexchvar WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 
END FUNCTION 


############################################################
# FUNCTION add_tax(p_tax_code,	p_tax_amt)
#
############################################################
FUNCTION add_tax(p_tax_code,p_tax_amt) 
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE p_tax_amt LIKE invoicedetl.ext_tax_amt 
	DEFINE l_t_rowid SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	# Posting account IS current FOR type IF tax code IS NULL OR FROM
	# tax table (defaulting TO current) OTHERWISE

	IF p_tax_code IS NULL THEN 
		LET modu_rec_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
	ELSE 
		SELECT sell_acct_code 
		INTO modu_rec_taxtemp.tax_acct_code 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_tax_code 
		IF status = NOTFOUND THEN 
			LET modu_rec_taxtemp.tax_acct_code = NULL 
		END IF 
		IF modu_rec_taxtemp.tax_acct_code IS NULL THEN 
			LET modu_rec_taxtemp.tax_acct_code = modu_rec_current.tax_acct_code 
		END IF 
	END IF 

	# IF a total already exists FOR this account, add TO it, OTHERWISE
	# INSERT it
	SELECT rowid 
	INTO l_t_rowid 
	FROM taxtemp 
	WHERE tax_acct_code = modu_rec_taxtemp.tax_acct_code 

	IF status = NOTFOUND THEN 
		LET modu_rec_taxtemp.tax_amt = p_tax_amt 
		INSERT INTO taxtemp VALUES (modu_rec_taxtemp.*) 
	ELSE 
		UPDATE taxtemp SET tax_amt = tax_amt + p_tax_amt 
		WHERE rowid = l_t_rowid 
	END IF 

END FUNCTION 


############################################################
# FUNCTION tax_postings(p_post_type)
#
############################################################
FUNCTION tax_postings(p_post_type) 
	DEFINE p_post_type CHAR(2)
	DEFINE l_rnd_tax_amt_cr LIKE batchdetl.credit_amt 
	DEFINE l_rnd_tax_amt_dr LIKE batchdetl.debit_amt 

	DECLARE c_taxtemp CURSOR FOR 
	SELECT * INTO modu_rec_taxtemp.* FROM taxtemp 
	WHERE tax_amt != 0 

	FOREACH c_taxtemp 
		IF p_post_type = TRAN_TYPE_CREDIT_CR THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_taxtemp.tax_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_tax_amt_cr = modu_rec_taxtemp.tax_amt * 1 
			LET l_rnd_tax_amt_dr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_tax_amt_cr = modu_rec_current.base_credit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		ELSE 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_taxtemp.tax_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_tax_amt_dr = modu_rec_taxtemp.tax_amt * 1 
			LET l_rnd_tax_amt_cr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_tax_amt_dr = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		END IF 

		INSERT INTO posttemp VALUES (modu_rec_docdata.ref_num, # inv/cred number 
		modu_rec_docdata.ref_text, # customer code 
		modu_rec_taxtemp.tax_acct_code, 
		modu_rec_docdata.ref_num, # inv/cred number 
		l_rnd_tax_amt_dr, # rounded tax amount 
		l_rnd_tax_amt_cr, # this account 
		modu_rec_current.base_debit_amt,#converted tax amt 
		modu_rec_current.base_credit_amt, 
		modu_rec_docdata.currency_code,# inv/cred currency 
		modu_sv_conv_qty, 
		modu_rec_docdata.tran_date, # inv/cred DATE 
		0, # stats qty NOT yet in use 
		modu_rec_current.ar_acct_code)# ar control account 

	END FOREACH 

	DELETE FROM taxtemp WHERE 1 = 1 

END FUNCTION 


############################################################
# FUNCTION add_cartage(p_cart_amt)
#
#
############################################################
FUNCTION add_cartage(p_cart_amt) 
	DEFINE p_cart_amt LIKE invoicedetl.ext_sale_amt 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_t_rowid SMALLINT 

	# IF a total already exists FOR this account, add TO it, OTHERWISE
	# INSERT it
	LET l_acct_code = build_mask(modu_rec_current.freight_acct_code) 
	SELECT rowid INTO l_t_rowid FROM carttemp 
	WHERE acct_code = l_acct_code
	 
	IF status = NOTFOUND THEN 
		LET modu_rec_carttemp.cart_amt = p_cart_amt 
		LET modu_rec_carttemp.acct_code = l_acct_code 
		INSERT INTO carttemp VALUES (modu_rec_carttemp.*) 
	ELSE 
		UPDATE carttemp 
		SET cart_amt = cart_amt + p_cart_amt 
		WHERE rowid = l_t_rowid 
	END IF 
	
END FUNCTION 


############################################################
# FUNCTION cart_postings(p_post_type)
#
#
############################################################
FUNCTION cart_postings(p_post_type) 
	DEFINE p_post_type CHAR(2)
	DEFINE l_rnd_cart_amt_cr LIKE batchdetl.credit_amt 
	DEFINE l_rnd_cart_amt_dr LIKE batchdetl.debit_amt 

	DECLARE c_carttemp CURSOR FOR 
	SELECT * INTO modu_rec_carttemp.* FROM carttemp 
	WHERE cart_amt != 0 

	FOREACH c_carttemp 
		IF p_post_type = TRAN_TYPE_CREDIT_CR THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_carttemp.cart_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_cart_amt_cr = modu_rec_carttemp.cart_amt * 1 
			LET l_rnd_cart_amt_dr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_cart_amt_cr = modu_rec_current.base_credit_amt 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		ELSE 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_carttemp.cart_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_cart_amt_dr = modu_rec_carttemp.cart_amt * 1 
			LET l_rnd_cart_amt_cr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_cart_amt_dr = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		END IF 
		
		LET modu_tmp_desc = "CRP ",modu_rec_docdata.ref_num USING "<<<<<<<<<<" 
		
		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # inv/cred number 
		modu_rec_docdata.ref_text, # customer code 
		modu_rec_carttemp.acct_code, # tax posting account 
		modu_tmp_desc, # inv/cred number 
		l_rnd_cart_amt_dr, # rounded cart amount FOR 
		l_rnd_cart_amt_cr, # this account 
		modu_rec_current.base_debit_amt, # converted cart amt 
		modu_rec_current.base_credit_amt, # converted cart amt 
		modu_rec_docdata.currency_code, # inv/cred currency code 
		modu_sv_conv_qty, 
		modu_rec_docdata.tran_date, # inv/cred DATE 
		0, # stats qty NOT yet in use 
		modu_rec_current.ar_acct_code) # ar control account 
	END FOREACH 

	DELETE FROM carttemp WHERE 1 = 1 

END FUNCTION 


############################################################
# FUNCTION add_labour( p_labr_amt)
#
############################################################
FUNCTION add_labour(p_labr_amt) 
	DEFINE p_labr_amt LIKE invoicedetl.ext_sale_amt 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_t_rowid SMALLINT 

	# IF a total already exists FOR this account, add TO it, OTHERWISE
	# INSERT it
	LET l_acct_code = build_mask(modu_rec_current.labr_acct_code) 
	SELECT rowid INTO l_t_rowid FROM labrtemp 
	WHERE acct_code = l_acct_code
	 
	IF status = NOTFOUND THEN 
		LET modu_rec_labrtemp.labr_amt = p_labr_amt 
		LET modu_rec_labrtemp.acct_code = l_acct_code 
		INSERT INTO labrtemp VALUES (modu_rec_labrtemp.*) 
	ELSE 
		UPDATE labrtemp 
		SET labr_amt = labr_amt + p_labr_amt 
		WHERE rowid = l_t_rowid 
	END IF 
	
END FUNCTION 


############################################################
# FUNCTION labr_postings(p_post_type) 
#
############################################################
FUNCTION labr_postings(p_post_type) 
	DEFINE p_post_type CHAR(2) 
	DEFINE l_rnd_labr_amt_cr LIKE batchdetl.credit_amt 
	DEFINE l_rnd_labr_amt_dr LIKE batchdetl.debit_amt 

	DECLARE c_labrtemp CURSOR FOR 
	SELECT * INTO modu_rec_labrtemp.* FROM labrtemp 
	WHERE labr_amt != 0 
	
	FOREACH c_labrtemp 
		IF p_post_type = TRAN_TYPE_CREDIT_CR THEN 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_labrtemp.labr_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_labr_amt_cr = modu_rec_labrtemp.labr_amt * 1 
			LET l_rnd_labr_amt_dr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_labr_amt_cr = modu_rec_current.base_credit_amt 

				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		ELSE 
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_labrtemp.labr_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
			LET l_rnd_labr_amt_dr = modu_rec_labrtemp.labr_amt * 1 
			LET l_rnd_labr_amt_cr = 0 
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_rnd_labr_amt_dr = modu_rec_current.base_debit_amt 
				LET modu_rec_docdata.conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				LET modu_sv_conv_qty = 1 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		END IF 
		
		LET modu_tmp_desc = "LRP ",modu_rec_docdata.ref_num USING "<<<<<<<<<<" 
		
		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # inv/cred number 
		modu_rec_docdata.ref_text, # customer code 
		modu_rec_labrtemp.acct_code, # tax posting account 
		modu_tmp_desc, # inv/cred number 
		l_rnd_labr_amt_dr, # rounded labr amount FOR 
		l_rnd_labr_amt_cr, # this account 
		modu_rec_current.base_debit_amt, # converted labr amt 
		modu_rec_current.base_credit_amt, # converted labr amt 
		modu_rec_docdata.currency_code, # inv/cred currency code 
		modu_sv_conv_qty, 
		modu_rec_docdata.tran_date, # inv/cred DATE 
		0, # stats qty NOT yet in use 
		modu_rec_current.ar_acct_code) # ar control account 
	END FOREACH 
	
	DELETE FROM labrtemp WHERE 1 = 1 
	
END FUNCTION 



############################################################################################
# They were located in common BUT ONLY GBQ uses them
# The following 2 functions were copy/pasted from common/intfjour.4gl
# 1- intfrour2 (was intfjour())
# 2 - REPORT was rpt_list
############################################################################################


############################################################
# FUNCTION intfjour (p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)
#
# This function is a kind of a REPORT OUTPUT function which should be used by other programs.
# BUT I can only see it being called by GBQ. So, I have no idea why it's in common/shared
############################################################
FUNCTION intfjour2(p_rpt_idx,p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_sel_stmt STRING
	DEFINE p_cmpy LIKE batchhead.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE batchhead.entry_code
	DEFINE p_bal_rec RECORD 
				tran_type_ind LIKE batchdetl.tran_type_ind, 
				acct_code LIKE batchdetl.acct_code, 
				desc_text LIKE batchdetl.desc_text 
			 END RECORD
	DEFINE p_periods LIKE batchhead.period_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE p_sent_jour_code LIKE batchhead.jour_code	
	DEFINE p_source_ind LIKE batchhead.jour_code
	DEFINE p_currency_code LIKE batchhead.currency_code
	DEFINE p_mod_code CHAR(2)
	DEFINE p_jour LIKE batchhead.jour_num
	DEFINE p_acct_code LIKE batchdetl.acct_code
   DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE l_post_text CHAR(80)
	DEFINE l_err_text CHAR(80)
	DEFINE l_posted_journal LIKE batchhead.jour_num
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_data RECORD 
				tran_type_ind LIKE batchdetl.tran_type_ind, 
				ref_num LIKE batchdetl.ref_num, 
				ref_text LIKE batchdetl.ref_text, 
				acct_code LIKE batchdetl.acct_code, 
				desc_text LIKE batchdetl.desc_text, 
				for_debit_amt LIKE batchdetl.for_debit_amt, 
				for_credit_amt LIKE batchdetl.for_credit_amt, 
				base_debit_amt LIKE batchdetl.debit_amt, 
				base_credit_amt LIKE batchdetl.credit_amt, 
				currency_code LIKE currency.currency_code, 
				conv_qty LIKE rate_exchange.conv_buy_qty, 
				tran_date DATE, 
				stats_qty LIKE batchdetl.stats_qty, 
				analysis_text LIKE batchdetl.analysis_text 
			 END RECORD 
	DEFINE l_tot_for_debit LIKE batchhead.debit_amt
	DEFINE l_tot_for_credit LIKE batchhead.debit_amt
	DEFINE l_tot_base_debit LIKE batchhead.debit_amt
	DEFINE l_tot_base_credit LIKE batchhead.debit_amt 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_next_seq INTEGER 
	DEFINE l_line_count INTEGER
	DEFINE l_tmp_flag CHAR(1) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msg STRING #for messages
	#Check for valid report index
	IF p_rpt_idx < 1 OR p_rpt_idx IS NULL THEN
		LET l_msg = "FUNCTION intfjour2(p_rpt_idx,p_sel_stmt,p_cmpy,p_kandoouser_sign_on_code,p_bal_rec,p_periods,p_year_num,p_sent_jour_code,p_source_ind,p_currency_code,p_mod_code,p_jour,p_acct_code)\n"
		LET l_msg = l_msg, "Report INDEX can not be 0 or NULL", "\nFUNCTION intfjour2(p_rpt_idx=",trim(p_rpt_idx), " , p_bal_rec=", trim(p_bal_rec)," , p_periods=", trim(p_periods)," , p_year_num=", trim(p_year_num)," , p_sent_jour_code=", trim(p_sent_jour_code)," , p_source_ind", trim(p_source_ind), ")"
		CALL fgl_winmessage("Invalid Report Property #101",l_msg,"error")
		RETURN NULL
	END IF

	LET l_line_count = 0 
	LET modu_prob_found = false 
	PREPARE prep_1 FROM p_sel_stmt 
	DECLARE curs_1 CURSOR FOR prep_1 
	INITIALIZE modu_batchhead.* TO NULL 
	INITIALIZE l_rec_batchdetl.* TO NULL 
	IF l_posted_journal IS NULL THEN 
		LET l_rec_glparms.next_jour_num = 0 
		SELECT max(jour_num) INTO l_rec_glparms.next_jour_num FROM t_batchhead 
		IF l_rec_glparms.next_jour_num IS NULL 
		OR l_rec_glparms.next_jour_num = 0 THEN 
			LET l_rec_glparms.next_jour_num = 1 
		ELSE 
			LET l_rec_glparms.next_jour_num = l_rec_glparms.next_jour_num + 1 
		END IF 
		LET l_posted_journal = l_rec_glparms.next_jour_num 
		LET l_post_text = "Selected journal codes FROM glparms" 

	ELSE 
		# commenced t_batchdetl INSERT but did nay finish
		# so we must delete out what t_batchdetl AND t_batchhead it did do
		# IF the post died mid batch we double check that the batch has
		# NOT been posted somehow. IF it has THEN it needs TO be manually
		# reversed FROM the tables before repost
		SELECT post_flag 
		INTO l_tmp_flag 
		FROM t_batchhead 
		WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		IF l_tmp_flag = "Y" THEN {batch was somehow posted} 
			LET l_err_text = "Batch ",l_posted_journal USING "####", 
			" has been posted - FATAL" 
		END IF 
		DELETE FROM t_batchdetl WHERE cmpy_code = p_cmpy AND program_id = glob_rec_prog.module_id
		AND jour_num = l_posted_journal 
		AND username = glob_rec_kandoouser.sign_on_code 
		DELETE FROM t_batchhead WHERE cmpy_code = p_cmpy 
		AND jour_num = l_posted_journal 
		LET l_rec_glparms.next_jour_num = l_posted_journal 
	END IF 
	LET modu_batchhead.cmpy_code = p_cmpy 
	LET modu_batchhead.jour_code = p_sent_jour_code 
	LET modu_batchhead.jour_num = l_rec_glparms.next_jour_num 
	LET modu_batchhead.entry_code = p_kandoouser_sign_on_code 
	LET modu_batchhead.jour_date = today 
	LET modu_batchhead.year_num = p_year_num 
	LET modu_batchhead.period_num = p_periods 
	LET modu_batchhead.control_amt = 0 
	LET modu_batchhead.debit_amt = 0 
	LET modu_batchhead.credit_amt = 0 
	LET modu_batchhead.for_debit_amt = 0 
	LET modu_batchhead.for_credit_amt = 0 
	LET modu_batchhead.control_qty = 0 
	LET modu_batchhead.stats_qty = 0 
	LET modu_batchhead.currency_code = p_currency_code 
	LET modu_batchhead.source_ind = p_source_ind 
	IF l_rec_glparms.use_clear_flag = "Y" THEN 
		LET modu_batchhead.cleared_flag = "N" 
	ELSE 
		LET modu_batchhead.cleared_flag = "Y" 
	END IF 
	LET modu_batchhead.post_flag = "N" 
	LET l_tot_base_debit = 0 
	LET l_tot_base_credit = 0 
	LET l_tot_for_debit = 0 
	LET l_tot_for_credit = 0 
	LET l_next_seq = 1 
	LET l_post_text = "Commenced batch lines INSERT" 
	#IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
		#DISPLAY " Reporting on GL batch : " at 1,1attribute(yellow) 
		#DISPLAY " ", l_rec_glparms.next_jour_num at 2,1
	#END IF 
	FOREACH curs_1 INTO l_rec_data.* 
		LET modu_batchhead.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = l_rec_data.tran_type_ind 
		LET l_rec_batchdetl.tran_date = l_rec_data.tran_date 
		LET l_rec_batchdetl.ref_num = l_rec_data.ref_num 
		LET l_rec_batchdetl.ref_text = l_rec_data.ref_text 
		LET l_rec_batchdetl.acct_code = l_rec_data.acct_code 
		LET l_rec_batchdetl.desc_text = l_rec_data.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
		LET l_rec_batchdetl.conv_qty = l_rec_data.conv_qty 
		LET l_rec_batchdetl.stats_qty = l_rec_data.stats_qty 
		LET l_rec_batchdetl.analysis_text = l_rec_data.analysis_text 
		LET l_rec_batchdetl.debit_amt = 0 
		LET l_rec_batchdetl.for_debit_amt = 0 
		LET l_rec_batchdetl.credit_amt = 0 
		LET l_rec_batchdetl.for_credit_amt = 0 
		CASE 
			WHEN (l_rec_data.base_debit_amt > 0) 
				LET l_rec_batchdetl.debit_amt = l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
			WHEN (l_rec_data.base_debit_amt < 0) 
				LET l_rec_batchdetl.credit_amt = -l_rec_data.base_debit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
			WHEN (l_rec_data.base_credit_amt > 0) 
				LET l_rec_batchdetl.credit_amt = l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.debit_amt = 0 
			WHEN (l_rec_data.base_credit_amt < 0) 
				LET l_rec_batchdetl.debit_amt = - l_rec_data.base_credit_amt 
				LET l_rec_batchdetl.credit_amt = 0 
		END CASE 
		CASE 
			WHEN (l_rec_data.for_debit_amt > 0) 
				LET l_rec_batchdetl.for_debit_amt = l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_credit_amt = 0 
			WHEN (l_rec_data.for_debit_amt < 0) 
				LET l_rec_batchdetl.for_credit_amt = -l_rec_data.for_debit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 
			WHEN (l_rec_data.for_credit_amt > 0) 
				LET l_rec_batchdetl.for_credit_amt = l_rec_data.for_credit_amt 
				LET l_rec_batchdetl.for_debit_amt = 0 
			WHEN (l_rec_data.for_credit_amt < 0) 
				LET l_rec_batchdetl.for_debit_amt = - l_rec_data.for_credit_amt 

				LET l_rec_batchdetl.for_credit_amt = 0 
		END CASE 
		IF l_rec_batchdetl.debit_amt IS NULL THEN 
			LET l_rec_batchdetl.debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.credit_amt IS NULL THEN 
			LET l_rec_batchdetl.credit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_debit_amt = 0 
		END IF 
		IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
			LET l_rec_batchdetl.for_credit_amt = 0 
		END IF 
		# keep totals FOR balancing
		LET l_tot_base_debit = l_tot_base_debit + l_rec_batchdetl.debit_amt 
		LET l_tot_base_credit = l_tot_base_credit + l_rec_batchdetl.credit_amt 
		LET l_tot_for_debit = l_tot_for_debit + l_rec_batchdetl.for_debit_amt 
		LET l_tot_for_credit = l_tot_for_credit + l_rec_batchdetl.for_credit_amt 
		# increment the batch header
		LET modu_batchhead.stats_qty = modu_batchhead.stats_qty + 
		l_rec_batchdetl.stats_qty 
		LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
		l_rec_batchdetl.debit_amt 
		LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
		l_rec_batchdetl.credit_amt 
		LET modu_batchhead.for_debit_amt = modu_batchhead.for_debit_amt + 
		l_rec_batchdetl.for_debit_amt 
		LET modu_batchhead.for_credit_amt = modu_batchhead.for_credit_amt + 
		l_rec_batchdetl.for_credit_amt 
		# check that AT least one side has a value
		IF l_rec_batchdetl.debit_amt = 0 AND 
		l_rec_batchdetl.credit_amt = 0 AND 
		l_rec_batchdetl.for_debit_amt = 0 AND 
		l_rec_batchdetl.for_credit_amt = 0 AND 
		l_rec_batchdetl.stats_qty = 0 THEN 
		ELSE 
			LET l_line_count = l_line_count + 1 
			LET l_err_text = " t_batchetl INSERT (lines) - intfjour.4gl " 
--			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
--				DISPLAY " Processing : " at 1,1 	attribute(yellow) 
--				DISPLAY " : ", l_rec_batchdetl.ref_text at 1,23
--				DISPLAY " : ",l_rec_batchdetl.ref_num at 2,1 
--			END IF 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code,glob_rec_prog.module_id) 
		END IF 
		INITIALIZE l_rec_batchdetl.* TO NULL 
	END FOREACH 
	LET l_post_text = "Inserted all t_batchdetl records" 
	#  create the balancing journal detail entries
	#  IF some batch lines have been inserted
	IF l_line_count > 0 THEN 
		LET l_rec_batchdetl.ref_text = " " 
		LET l_rec_batchdetl.ref_num = 0 
		LET l_rec_batchdetl.cmpy_code = p_cmpy 
		LET l_rec_batchdetl.jour_code = p_sent_jour_code 
		LET l_rec_batchdetl.jour_num = l_rec_glparms.next_jour_num 
		LET l_rec_batchdetl.seq_num = l_next_seq 
		LET l_next_seq = l_next_seq + 1 
		LET l_rec_batchdetl.tran_type_ind = p_bal_rec.tran_type_ind 
		LET l_rec_batchdetl.tran_date = modu_batchhead.jour_date 
		LET l_rec_batchdetl.acct_code = p_bal_rec.acct_code 
		LET l_rec_batchdetl.desc_text = p_bal_rec.desc_text 
		LET l_rec_batchdetl.currency_code = p_currency_code 
		LET l_rec_batchdetl.analysis_text = "" 
		LET l_rec_batchdetl.stats_qty = 0 
		LET l_rec_batchdetl.debit_amt = 0 
		LET l_rec_batchdetl.credit_amt = 0 
		LET l_rec_batchdetl.for_debit_amt = 0 
		LET l_rec_batchdetl.for_credit_amt = 0 
		IF l_tot_base_debit > l_tot_base_credit THEN 
			LET l_rec_batchdetl.credit_amt = l_tot_base_debit - l_tot_base_credit 
		ELSE 
			LET l_rec_batchdetl.debit_amt = l_tot_base_credit - l_tot_base_debit 
		END IF 
		IF l_tot_for_debit > l_tot_for_credit THEN 
			LET l_rec_batchdetl.for_credit_amt = l_tot_for_debit - l_tot_for_credit 
		ELSE 
			LET l_rec_batchdetl.for_debit_amt = l_tot_for_credit - l_tot_for_debit 
		END IF 
		# IF balancing entry IS zero THEN dont add it TO the batch
		IF l_rec_batchdetl.credit_amt = 0 AND 
		l_rec_batchdetl.debit_amt = 0 AND 
		l_rec_batchdetl.for_credit_amt = 0 AND 
		l_rec_batchdetl.for_debit_amt = 0 AND 
		l_rec_batchdetl.stats_qty = 0 THEN 
		ELSE 
			LET l_err_text = "t_batchetl INSERT - (balancing entry)" 
			INSERT INTO t_batchdetl VALUES (l_rec_batchdetl.*, glob_rec_kandoouser.sign_on_code,glob_rec_prog.module_id) 
			#  increment the batch header
			LET modu_batchhead.debit_amt = modu_batchhead.debit_amt + 
			l_rec_batchdetl.debit_amt 
			LET modu_batchhead.credit_amt = modu_batchhead.credit_amt + 
			l_rec_batchdetl.credit_amt 
			LET modu_batchhead.for_debit_amt = 
			modu_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET modu_batchhead.for_credit_amt = 
			modu_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
			LET modu_batchhead.seq_num = l_next_seq 
		END IF 
		# INSERT batch header
		# Note: use Sell rate FOR A)ccounts Receivable, J)ob Management AND
		#       I)nventory AND Buy rate OTHERWISE
		IF l_rec_glparms.use_currency_flag = "Y" AND 
		l_rec_glparms.base_currency_code IS NOT NULL AND 
		modu_batchhead.currency_code IS NOT NULL AND 
		modu_batchhead.currency_code != l_rec_glparms.base_currency_code THEN 
			IF modu_batchhead.source_ind matches "[AJI]" THEN 
				LET modu_batchhead.rate_type_ind = "S" 
			ELSE 
				LET modu_batchhead.rate_type_ind = "B" 
			END IF 
		ELSE 
			LET modu_batchhead.rate_type_ind = " " 
		END IF 
		IF modu_batchhead.currency_code IS NULL THEN 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].exec_ind = '1' THEN 
				ERROR kandoomsg2("G",7000,modu_batchhead.jour_num)	#7000 Warning: Rate Type will be updated as NULL.
				sleep 2
			END IF 
		END IF 
		LET l_err_text = "t_batchead Insert - intfjour.4gl" 
		LET modu_batchhead.control_amt = modu_batchhead.for_debit_amt 
		LET modu_batchhead.control_qty = modu_batchhead.stats_qty 
		INSERT INTO t_batchhead VALUES (modu_batchhead.*) 
		# now write the REPORT on this batch
		IF p_acct_code IS NULL THEN 
			LET l_where_text = "1=1" 
		ELSE 
			LET l_where_text = "acct_code matches '",p_acct_code CLIPPED,"'" 
		END IF 
		LET l_query_text = " SELECT * FROM t_batchdetl ", 
		" WHERE cmpy_code = '",p_cmpy CLIPPED,"' ",  
		" AND program_id = '", glob_rec_prog.module_id CLIPPED, "' ",
		" AND jour_code = '",p_sent_jour_code CLIPPED,"' ", 
		" AND jour_num = ",l_rec_glparms.next_jour_num, " ", 
		" AND ",l_where_text CLIPPED, 
		" ORDER BY seq_num" 
		PREPARE s_detl_curs FROM l_query_text 
		DECLARE detl_curs CURSOR FOR s_detl_curs 
		SELECT company.* INTO l_rec_company.* FROM company 
		WHERE company.cmpy_code = p_cmpy 
		FOREACH detl_curs INTO l_rec_batchdetl.* 
		
			#---------------------------------------------------------
			OUTPUT TO REPORT GBQ_rpt_list(p_rpt_idx,
			p_cmpy, 
			l_rec_batchdetl.*, 
			l_rec_company.*, 
			p_sent_jour_code, 
			p_jour) 
			IF NOT rpt_int_flag_handler2("Journal Batch Print:",p_sent_jour_code,l_rec_glparms.next_jour_num,p_rpt_idx) THEN
				RETURN FALSE #??? not sure false, NULL, or something else to say, CANCEL 
			END IF 
			#---------------------------------------------------------							
		END FOREACH	 
	ELSE 
		# nothing posted
		# RETURN 0 IF no UPDATE done
		LET l_rec_glparms.next_jour_num = 0
		CALL fgl_winmessage("Nothing posted","Could not find any journal/batch data to post","INFO") 
	END IF 
	# RETURN the batch number, negative IF suspense a/c used, ELSE positive
	# this enables batch number TO be recorded on the source table
	# IF required. Needed in purchasing TO allow FOR reconcilliation
	# of summary batch posting
	IF modu_prob_found THEN 
		# suspense a/c used, RETURN NEGATIVE jour_num
		RETURN ( 0 - l_rec_glparms.next_jour_num ) 
	ELSE 
		RETURN l_rec_glparms.next_jour_num 
	END IF 
--	WHENEVER ERROR CONTINUE 
	

END FUNCTION # intfjour () 

############################################################
# REPORT GBQ_rpt_list(p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour)
#
#
############################################################
REPORT GBQ_rpt_list(p_rpt_idx,p_cmpy,p_rec_batchdetl,p_rec_company,p_sent_jour_code,p_jour) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE p_sent_jour_code LIKE batchdetl.jour_code
	DEFINE p_jour LIKE batchdetl.jour_num 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_start_period LIKE batchhead.period_num
	DEFINE l_end_period LIKE batchhead.period_num	 
	DEFINE l_start_year LIKE batchhead.year_num
	DEFINE l_end_year LIKE batchhead.year_num
	DEFINE l_coa_not_open SMALLINT
	DEFINE l_coa_not_found SMALLINT

	OUTPUT 
--	PAGE LENGTH 66 
--	LEFT MARGIN 0 
	ORDER BY p_rec_batchdetl.jour_num, 
	p_rec_batchdetl.currency_code, 
	p_rec_batchdetl.conv_qty, 
	p_rec_batchdetl.acct_code, 
	p_rec_batchdetl.tran_date 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			 
			SELECT * INTO modu_batchhead.* FROM t_batchhead 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code
			 
			PRINT COLUMN 1, "Batch: ", p_jour, " - ",p_sent_jour_code 
			PRINT COLUMN 5, "Date: ", modu_batchhead.jour_date, 
			COLUMN 25, "Posting Year: ", modu_batchhead.year_num, 
			COLUMN 50, "Period: ", modu_batchhead.period_num, 
			COLUMN 70, "FROM : ", modu_batchhead.entry_code, 
			COLUMN 87, "Source : ", modu_batchhead.source_ind, 
			COLUMN 101, "Currency : ", modu_batchhead.currency_code 
			PRINT COLUMN 5, "Comments:", 
			COLUMN 16, modu_batchhead.com1_text 
			PRINT COLUMN 5, "Comments :", 
			COLUMN 16, modu_batchhead.com2_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 1, p_rec_batchdetl.acct_code , 
			COLUMN 20, p_rec_batchdetl.tran_date 

		ON EVERY ROW 
			# now check TO see IF the coa exists, IF NOT flag it AND PRINT MESSAGE
			# OTHERWISE, IF reporting currency NOT NULL, calculate appropriate VALUES
			# check that chart number IS valid AND live
			LET l_coa_not_found = false 
			LET l_coa_not_open = false 
			SELECT start_year_num,start_period_num,end_year_num,end_period_num 
			INTO l_start_year,l_start_period,l_end_year,l_end_period 
			FROM coa 
			WHERE cmpy_code = p_rec_batchdetl.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 
			IF status THEN 
				LET l_coa_not_found = true 
			ELSE 
				# check IF account IS OPEN AND valid
				IF (((l_end_year < modu_batchhead.year_num) OR 
				(l_end_year = modu_batchhead.year_num AND 
				l_end_period < modu_batchhead.period_num)) OR 
				((l_start_year > modu_batchhead.year_num) OR 
				(l_start_year = modu_batchhead.year_num AND 
				l_start_period > modu_batchhead.period_num))) THEN 
					LET l_coa_not_open = true 
				END IF 
			END IF 
			IF l_coa_not_found OR l_coa_not_open THEN 
				LET modu_prob_found = true 
			END IF 
			PRINT COLUMN 6 , p_rec_batchdetl.tran_type_ind, 
			COLUMN 11, p_rec_batchdetl.acct_code , 
			COLUMN 30, p_rec_batchdetl.desc_text, 
			COLUMN 60, p_rec_batchdetl.debit_amt USING "-----------&.&&", 
			COLUMN 75, p_rec_batchdetl.credit_amt USING "-----------&.&&", 
			COLUMN 94, p_rec_batchdetl.ref_num USING "###########", 
			COLUMN 114, p_rec_batchdetl.ref_text 

		AFTER GROUP OF p_rec_batchdetl.tran_date 
			PRINT COLUMN 60,"-------------------------------" 
			PRINT COLUMN 60, GROUP sum(p_rec_batchdetl.debit_amt) 
			USING "-----------&.&&", 
			COLUMN 75, GROUP sum(p_rec_batchdetl.credit_amt) 
			USING "-----------&.&&" 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Totals - Base Currency :", 
			COLUMN 60, sum(p_rec_batchdetl.debit_amt) USING "-----------&.&&" 
			PRINT COLUMN 75, sum(p_rec_batchdetl.credit_amt) USING "-----------&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
