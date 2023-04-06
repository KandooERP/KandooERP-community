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
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRC_GLOBALS.4gl" 
GLOBALS 
--	DEFINE glob_rec_apparms RECORD LIKE apparms.*
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_period RECORD LIKE period.*
	DEFINE modu_rec_accounthist RECORD LIKE accounthist.*
--	DEFINE modu_find1 CHAR(1) 
--	DEFINE modu_find2 CHAR(1) 
--	DEFINE modu_find3 CHAR(1) 
--	DEFINE modu_find4 CHAR(1) 
	DEFINE modu_no_data INTEGER 
	DEFINE modu_word CHAR(800) 
	DEFINE modu_x SMALLINT 
	DEFINE modu_y SMALLINT 
	DEFINE modu_msgresp CHAR(1)	 
	DEFINE modu_find_data CHAR(1) 
	DEFINE modu_year_num LIKE period.year_num 
	DEFINE modu_period_num LIKE period.period_num 
	DEFINE modu_acct_code LIKE coa.acct_code 
	DEFINE modu_start_date DATE 
	DEFINE modu_end_date DATE 
	DEFINE modu_report_total SMALLINT 
	DEFINE modu_do_period_total SMALLINT 
	DEFINE modu_totaller1 DECIMAL(16,2) 
	DEFINE modu_totaller2 DECIMAL(16,2) 
	DEFINE modu_totaller3 DECIMAL(16,2) 
--	DEFINE modu_totaller4 DECIMAL(16,2) 

--	DEFINE modu_totaller5 DECIMAL(16,2) 
--	DEFINE modu_totaller6 DECIMAL(16,2) 
--	DEFINE modu_totaller7 DECIMAL(16,2) 
--	DEFINE modu_totaller8 DECIMAL(16,2) 
	DEFINE modu_prob_mess CHAR(30)
#	DEFINE modu_where_part CHAR(800)
#	DEFINE modu_where_part1 CHAR(800)
#	DEFINE modu_where_part2 CHAR(800)
#	DEFINE modu_query_text CHAR(800)
#	DEFINE modu_subsid_query1 CHAR(800) #l_query_text
#	DEFINE modu_subsid_query2 CHAR(800)
#	DEFINE modu_subsid_query3 CHAR(800)
#	DEFINE modu_subsid_query4 CHAR(800)
#	DEFINE modu_query_text2 CHAR(1500)
#	DEFINE modu_query_text3 CHAR(800)
--	DEFINE modu_query_text4 CHAR(500)
	DEFINE modu_rec_hold RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		acct_code LIKE accounthist.acct_code, 
		level_type CHAR(3), 
		invoice_un DECIMAL(16,2), 
		invoice_post DECIMAL(16,2), 
		credit_un DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		cash_un DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		disc_un DECIMAL(16,2), 
		disc_post DECIMAL(16,2), 
		exp_un DECIMAL(16,2), 
		exp_post DECIMAL(16,2), 
		period_total DECIMAL(16,2) 
	END RECORD
############################################################
# FUNCTION GRC_main()
#
# GRC  AR Subsidiary TO GL reconciliation REPORT
############################################################
FUNCTION GRC_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GRC") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G151 with FORM "G151" 
			CALL windecoration_g("G151") 
		
			MENU " Subsidiary Reconciliation Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRC","menu-subsidiary-recon-REPORT") 
					IF GRC_rpt_process(GRC_rpt_query()) THEN 
						IF fgl_find_table("grc_hold") THEN
							DROP TABLE grc_hold 
						END IF
					END IF
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Run" " SELECT Criteria AND Print Report"
					IF GRC_rpt_process(GRC_rpt_query()) THEN 
						IF fgl_find_table("grc_hold") THEN
							DROP TABLE grc_hold 
						END IF
					END IF 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO Menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G151 

 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G151 with FORM "G151" 
			CALL windecoration_g("G151") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRC_rpt_query()) #save where clause in env 
			CLOSE WINDOW G151 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRC_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


############################################################
# FUNCTION GRC_rpt_query()
#
#
############################################################
FUNCTION GRC_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON ar_acct_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GRC","construct-acct") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.sel_text = l_where_text 
	END IF 

	CONSTRUCT BY NAME l_where2_text ON year_num, 
	period_num, 
	post_date 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GRC","construct-year") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		LET glob_rec_rpt_selector.sel_option1 = l_where2_text
		RETURN l_where_text
	END IF 

END FUNCTION



############################################################
# FUNCTION GRC_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GRC_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_where2_text STRING # = glob_rec_rpt_selector.sel_option1 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_status SMALLINT #ABBORT/CANCEL status (2) original code

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GRC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GRC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRC_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_where2_text = glob_rec_rpt_selector.sel_option1 


	# SET up temporary table FOR speed...........

	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE grc_hold (year_num SMALLINT, 
	period_num SMALLINT, 
	acct_code CHAR(18), 
	level_type CHAR(3), 
	invoice_un DECIMAL(16,2), 
	invoice_post DECIMAL(16,2), 
	credit_un DECIMAL(16,2), 
	credit_post DECIMAL(16,2), 
	cash_un DECIMAL(16,2), 
	cash_post DECIMAL(16,2), 
	disc_un DECIMAL(16,2), 
	disc_post DECIMAL(16,2), 
	exp_un DECIMAL(16,2), 
	exp_post DECIMAL(16,2), 
	period_total DECIMAL(16,2)) 
	CREATE INDEX hold_ind ON grc_hold (year_num, 
	period_num, 
	acct_code, 
	level_type) 
	WHENEVER ERROR stop 
	
	LET l_query_text = 
	"SELECT ar_acct_code ", 
	"FROM customertype ", 
	"WHERE customertype.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRC_rpt_list")].sel_text clipped, " ",  
	" union ", 
	"SELECT ar_acct_code ", 
	"FROM arparms ", 
	"WHERE arparms.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" arparms.parm_code = 1 AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRC_rpt_list")].sel_text clipped 
	
	LET l_query_text = l_query_text clipped, 	" ORDER BY 1" 

	PREPARE s_controlacct FROM l_query_text 
	DECLARE c_controlacct CURSOR FOR s_controlacct 

	LET modu_do_period_total = 0 

	#
	# now INTO Accounts Receivable
	#
	FOREACH c_controlacct INTO modu_acct_code 
		LET modu_do_period_total = modu_do_period_total + 1 
		#DISPLAY "Accounts Receivable " at 1,10 
		#DISPLAY " Account Code: ", modu_acct_code TO lblabel2 -- 2,10 

		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET modu_msgresp=kandoomsg("U",9501,"") 
				LET l_status = 1 
				EXIT FOREACH 
			END IF 
		END IF 
		CALL GRC_rpt_get_subsidiary(l_where2_text) 
		CALL GRC_rpt_get_batches(l_where2_text) 
		CALL GRC_rpt_get_net_accounts(l_where2_text) 
	END FOREACH 

	#CLOSE WINDOW disp_info 

	IF l_status != 1 THEN 
		CALL GRC_rpt_add_zero_period() 

		DECLARE c_hold CURSOR FOR 
		SELECT year_num, period_num, acct_code, level_type 
		FROM grc_hold 
		GROUP BY year_num, period_num, acct_code, level_type 
		ORDER BY year_num, period_num, acct_code, level_type 

		LET modu_no_data = false 
		LET modu_report_total = 0 

		FOREACH c_hold INTO modu_rec_hold.* 
			LET modu_no_data = true 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRC_rpt_list(l_rpt_idx,modu_rec_hold.*)  
			IF NOT rpt_int_flag_handler2("",NULL, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 

		IF NOT modu_no_data THEN 
			INITIALIZE modu_rec_hold.* TO NULL 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRC_rpt_list(l_rpt_idx,modu_rec_hold.*)  
			#---------------------------------------------------------			 
		END IF 

		#------------------------------------------------------------
		FINISH REPORT GRC_rpt_list
		CALL rpt_finish("GRC_rpt_list")
		#------------------------------------------------------------
	END IF 
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 


############################################################
# FUNCTION GRC_rpt_get_subsidiary()
#
#
############################################################
FUNCTION GRC_rpt_get_subsidiary(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_sub_query_text STRING
	DEFINE l_rec_query_temp1 RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		post_flag CHAR(1), 
		value_amt DECIMAL(16,2), 
		disc_amt DECIMAL(16,2) 
	END RECORD
	 
	LET l_query_text = 
	"SELECT year_num, ", 
	"period_num, ", 
	"posted_flag, ", 
	"sum(total_amt / conv_qty) ", 
	"FROM invoicehead, ", 
	"customer, ", 
	"customertype ", 
	"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"conv_qty != 0 AND ", 

	"customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cust_code = invoicehead.cust_code AND ", 

	"customertype.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customertype.type_code = customer.type_code AND ", 
	"customertype.ar_acct_code matches \"",modu_acct_code,"\" AND ", 

	p_where_text CLIPPED #modu_where_part1 clipped 
	LET l_query_text = l_query_text clipped, 
	" group by 1, 2, 3 ", 
	" ORDER BY 1, 2 " 


	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_invoice INTO l_rec_query_temp1.* 

		IF l_rec_query_temp1.value_amt IS NULL THEN 
			LET l_rec_query_temp1.value_amt = 0 
		END IF 

		IF l_rec_query_temp1.post_flag = "modu_y" THEN 
			LET modu_rec_hold.invoice_post = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.invoice_un = 0 
		ELSE 
			LET modu_rec_hold.invoice_un = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.invoice_post = 0 
		END IF 

		LET modu_rec_hold.year_num = l_rec_query_temp1.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp1.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "1" 
		LET modu_rec_hold.credit_post = 0 
		LET modu_rec_hold.credit_un = 0 
		LET modu_rec_hold.cash_post = 0 
		LET modu_rec_hold.cash_un = 0 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.exp_post = 0 
		LET modu_rec_hold.exp_un = 0 
		LET modu_rec_hold.period_total = 0 

		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 
	END FOREACH 


	LET l_sub_query_text = 
	"SELECT year_num, ", 
	"period_num, ", 
	"posted_flag, ", 
	"sum(total_amt / conv_qty) ", 
	"FROM credithead, ", 
	"customer, ", 
	"customertype ", 
	"WHERE credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"conv_qty != 0 AND ", 

	"customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cust_code = credithead.cust_code AND ", 

	"customertype.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customertype.type_code = customer.type_code AND ", 
	"customertype.ar_acct_code matches \"",modu_acct_code,"\" AND ", 
	p_where_text clipped
	 
	LET l_sub_query_text = l_sub_query_text clipped, 
	" group by year_num, period_num, posted_flag ", 
	" ORDER BY year_num, period_num " 

	PREPARE s_credit FROM l_sub_query_text 
	DECLARE c_credit CURSOR FOR s_credit 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_credit INTO l_rec_query_temp1.* 

		IF l_rec_query_temp1.value_amt IS NULL THEN 
			LET l_rec_query_temp1.value_amt = 0 
		END IF 

		IF l_rec_query_temp1.post_flag = "modu_y" THEN 
			LET modu_rec_hold.credit_post = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.credit_un = 0 
		ELSE 
			LET modu_rec_hold.credit_un = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.credit_post = 0 
		END IF 

		LET modu_rec_hold.year_num = l_rec_query_temp1.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp1.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "1" 
		LET modu_rec_hold.invoice_post = 0 
		LET modu_rec_hold.invoice_un = 0 
		LET modu_rec_hold.cash_post = 0 
		LET modu_rec_hold.cash_un = 0 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.exp_post = 0 
		LET modu_rec_hold.exp_un = 0 
		LET modu_rec_hold.period_total = 0 

		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 
	END FOREACH 



	LET l_sub_query_text = 
	"SELECT year_num, ", 
	"period_num, ", 
	"posted_flag, ", 
	"sum(cash_amt / conv_qty), ", 
	"sum(disc_amt / conv_qty) ", 
	"FROM cashreceipt, ", 
	"customer, ", 
	"customertype ", 
	"WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"conv_qty != 0 AND ", 

	"customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cust_code = cashreceipt.cust_code AND ", 

	"customertype.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customertype.type_code = customer.type_code AND ", 
	"customertype.ar_acct_code matches \"",modu_acct_code,"\" AND ", 
	p_where_text clipped 

	LET l_sub_query_text = l_sub_query_text clipped, 
	" group by year_num, period_num, posted_flag ", 
	" ORDER BY year_num, period_num " 

	PREPARE s_cashreceipt FROM l_sub_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_cashreceipt INTO l_rec_query_temp1.* 

		IF l_rec_query_temp1.value_amt IS NULL THEN 
			LET l_rec_query_temp1.value_amt = 0 
		END IF 

		IF l_rec_query_temp1.post_flag = "modu_y" THEN 
			LET modu_rec_hold.cash_post = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.disc_post = l_rec_query_temp1.disc_amt 
			LET modu_rec_hold.cash_un = 0 
			LET modu_rec_hold.disc_un = 0 
		ELSE 
			LET modu_rec_hold.cash_un = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.disc_un = l_rec_query_temp1.disc_amt 
			LET modu_rec_hold.cash_post = 0 
			LET modu_rec_hold.disc_post = 0 
		END IF 
		LET modu_rec_hold.year_num = l_rec_query_temp1.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp1.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "1" 
		LET modu_rec_hold.invoice_post = 0 
		LET modu_rec_hold.invoice_un = 0 
		LET modu_rec_hold.credit_post = 0 
		LET modu_rec_hold.credit_un = 0 
		LET modu_rec_hold.exp_post = 0 
		LET modu_rec_hold.exp_un = 0 
		LET modu_rec_hold.period_total = 0 

		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 
	END FOREACH 


	LET l_sub_query_text = 
	"SELECT year_num, ", 
	"period_num, ", 
	"posted_flag, ", 
	"sum(exchangevar_amt) ", 
	"FROM exchangevar, ", 
	"customer, ", 
	"customertype ", 
	"WHERE exchangevar.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"exchangevar.source_ind = \"A\" AND ", 

	"customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cust_code = exchangevar.ref_code AND ", 

	"customertype.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customertype.type_code = customer.type_code AND ", 
	"customertype.ar_acct_code matches \"",modu_acct_code,"\" AND ", 

	p_where_text clipped 
	LET l_sub_query_text = l_sub_query_text clipped, 
	" group by year_num, period_num, posted_flag ", 
	" ORDER BY year_num, period_num " 

	PREPARE s_exchangevar FROM l_sub_query_text 
	DECLARE c_exchangevar CURSOR FOR s_exchangevar 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_exchangevar INTO l_rec_query_temp1.* 

		IF l_rec_query_temp1.post_flag = "modu_y" THEN 
			LET modu_rec_hold.exp_post = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.exp_un = 0 
		ELSE 
			LET modu_rec_hold.exp_un = l_rec_query_temp1.value_amt 
			LET modu_rec_hold.exp_post = 0 
		END IF 

		LET modu_rec_hold.year_num = l_rec_query_temp1.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp1.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "1" 
		LET modu_rec_hold.invoice_post = 0 
		LET modu_rec_hold.invoice_un = 0 
		LET modu_rec_hold.credit_post = 0 
		LET modu_rec_hold.credit_un = 0 
		LET modu_rec_hold.cash_post = 0 
		LET modu_rec_hold.cash_un = 0 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.period_total = 0 

		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 

	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION GRC_rpt_get_batches()
#
#
############################################################
FUNCTION GRC_rpt_get_batches(p_where2_text) 
	DEFINE p_where2_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_query_temp2 RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		credit_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		post_flag CHAR(1), 
		tran_type_ind CHAR(3), 
		source_ind CHAR(1) 
	END RECORD 


	LET modu_word = "" 
	#LET p_where2_text = modu_where_part1 
	LET modu_y = length(p_where2_text) 
	FOR modu_x = 1 TO (modu_y - 9) 
		IF p_where2_text[modu_x,(modu_x+8)] = "post_date" THEN 
			LET p_where2_text[modu_x,(modu_x+3)] = "jour" 
		END IF 
	END FOR 

	LET l_query_text = 
	"SELECT year_num, period_num, ", 
	"sum(batchdetl.credit_amt), sum(batchdetl.debit_amt), ", 
	"post_flag, tran_type_ind, source_ind ", 
	"FROM batchdetl, batchhead ", 
	"WHERE batchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"batchhead.source_ind = \"A\" AND ", 
	"batchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"batchhead.jour_num = batchdetl.jour_num AND ", 
	"batchhead.jour_code = batchdetl.jour_code AND ", 
	"batchdetl.tran_type_ind in (\"CR\", \"IN\", \"CA\", \"EXA\") AND ", 
	"batchdetl.acct_code matches \"",modu_acct_code,"\" AND ", 
	p_where2_text clipped 
	
	LET l_query_text = l_query_text clipped, 
	" group by year_num, period_num, post_flag, tran_type_ind, source_ind ", 
	" ORDER BY year_num, period_num " 

	PREPARE s_batches FROM l_query_text 
	DECLARE c_batches CURSOR FOR s_batches 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_batches INTO l_rec_query_temp2.* 

		IF l_rec_query_temp2.credit_amt IS NULL THEN 
			LET l_rec_query_temp2.credit_amt = 0 
		END IF 

		IF l_rec_query_temp2.debit_amt IS NULL THEN 
			LET l_rec_query_temp2.debit_amt = 0 
		END IF 

		IF l_rec_query_temp2.tran_type_ind = TRAN_TYPE_CREDIT_CR THEN 
			IF l_rec_query_temp2.post_flag = "modu_y" THEN 
				LET modu_rec_hold.credit_post = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			ELSE 
				LET modu_rec_hold.credit_un = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			END IF 
		END IF 

		IF l_rec_query_temp2.tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
			IF l_rec_query_temp2.post_flag = "modu_y" THEN 
				LET modu_rec_hold.invoice_post = 
				l_rec_query_temp2.debit_amt - l_rec_query_temp2.credit_amt 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			ELSE 
				LET modu_rec_hold.invoice_un = 
				l_rec_query_temp2.debit_amt - l_rec_query_temp2.credit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			END IF 
		END IF 

		IF l_rec_query_temp2.tran_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
			IF l_rec_query_temp2.post_flag = "modu_y" THEN 
				LET modu_rec_hold.cash_post = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			ELSE 
				LET modu_rec_hold.cash_un = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.exp_post = 0 
				LET modu_rec_hold.exp_un = 0 
			END IF 
		END IF 

		IF l_rec_query_temp2.tran_type_ind = "EXA" THEN 
			IF l_rec_query_temp2.post_flag = "modu_y" THEN 
				LET modu_rec_hold.exp_post = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_un = 0 
			ELSE 
				LET modu_rec_hold.exp_un = 
				l_rec_query_temp2.credit_amt - l_rec_query_temp2.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.invoice_un = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.credit_un = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.cash_un = 0 
				LET modu_rec_hold.exp_post = 0 
			END IF 
		END IF 

		LET modu_rec_hold.year_num = l_rec_query_temp2.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp2.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "2" 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.period_total = 0 
		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 

	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION GRC_rpt_get_net_accounts(p_where2_text)
#
#
############################################################
FUNCTION GRC_rpt_get_net_accounts(p_where2_text) 
	DEFINE p_where2_text STRING
	DEFINE l_query_text3 STRING
	DEFINE l_rec_query_temp3 RECORD 
		year_num CHAR(4), 
		period_num CHAR(2), 
		credit_amt DECIMAL(16,2), 
		debit_amt DECIMAL(16,2), 
		tran_type_ind CHAR(3) 
	END RECORD 

	LET modu_word = "" 
	LET modu_y = length(p_where2_text) 
	FOR modu_x = 1 TO (modu_y - 9) 
		IF p_where2_text[modu_x,(modu_x+8)] = "jour_date" THEN 
			LET p_where2_text[modu_x,(modu_x+3)] = "tran" 
		END IF 
	END FOR 

	LET l_query_text3 = 
	"SELECT year_num, period_num, ", 
	"sum(credit_amt), sum(debit_amt), tran_type_ind ", 
	"FROM accountledger ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"tran_type_ind in (\"CR\", \"IN\", \"CA\", \"EXA\") AND ", 
	"acct_code matches \"",modu_acct_code,"\" AND ", 
	p_where2_text clipped 
	LET l_query_text3 = l_query_text3 clipped, 
	" group by year_num, period_num, tran_type_ind ", 
	" ORDER BY year_num, period_num " 

	PREPARE s_accounts FROM l_query_text3 
	DECLARE c_accounts CURSOR FOR s_accounts 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_accounts INTO l_rec_query_temp3.* 

		IF l_rec_query_temp3.credit_amt IS NULL THEN 
			LET l_rec_query_temp3.credit_amt = 0 
		END IF 

		IF l_rec_query_temp3.debit_amt IS NULL THEN 
			LET l_rec_query_temp3.debit_amt = 0 
		END IF 

		CASE 
			WHEN l_rec_query_temp3.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				LET modu_rec_hold.credit_post = 
				l_rec_query_temp3.credit_amt - l_rec_query_temp3.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.exp_post = 0 

			WHEN l_rec_query_temp3.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				LET modu_rec_hold.invoice_post = 
				l_rec_query_temp3.debit_amt - l_rec_query_temp3.credit_amt 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.cash_post = 0 
				LET modu_rec_hold.exp_post = 0 

			WHEN l_rec_query_temp3.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				LET modu_rec_hold.cash_post = 
				l_rec_query_temp3.credit_amt - l_rec_query_temp3.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.exp_post = 0 

			WHEN l_rec_query_temp3.tran_type_ind = "EXA" 
				LET modu_rec_hold.exp_post = 
				l_rec_query_temp3.credit_amt - l_rec_query_temp3.debit_amt 
				LET modu_rec_hold.invoice_post = 0 
				LET modu_rec_hold.credit_post = 0 
				LET modu_rec_hold.cash_post = 0 

		END CASE 

		LET modu_rec_hold.year_num = l_rec_query_temp3.year_num 
		LET modu_rec_hold.period_num = l_rec_query_temp3.period_num 
		LET modu_rec_hold.acct_code = modu_acct_code 
		LET modu_rec_hold.level_type = "3" 
		LET modu_rec_hold.invoice_un = 0 
		LET modu_rec_hold.credit_un = 0 
		LET modu_rec_hold.cash_un = 0 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.exp_un = 0 
		LET modu_rec_hold.period_total = 0 
		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 

	END FOREACH 


END FUNCTION 


############################################################
# FUNCTION GRC_rpt_add_zero_period()
#
#
############################################################
FUNCTION GRC_rpt_add_zero_period() 
	DEFINE l_year_num LIKE period.year_num 
	DEFINE l_cnt SMALLINT
	DEFINE l_period_num LIKE period.period_num 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_level_type SMALLINT 

	DECLARE c_zeroperiod CURSOR FOR 

	SELECT unique year_num, 
	period_num, 
	acct_code 
	FROM grc_hold 

	INITIALIZE modu_rec_hold.* TO NULL 
	FOREACH c_zeroperiod INTO l_year_num, 
		l_period_num, 
		l_acct_code 

		# Get all account history period auctuals FOR each
		# Unique Year & Period  AND acct_code
		SELECT sum(pre_close_amt) 
		INTO modu_rec_hold.period_total 
		FROM accounthist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = l_year_num 
		AND period_num = l_period_num 
		AND acct_code matches l_acct_code 

		IF modu_rec_hold.period_total IS NULL THEN 
			LET modu_rec_hold.period_total = 0 
		END IF 

		LET modu_rec_hold.year_num = l_year_num 
		LET modu_rec_hold.period_num = l_period_num 
		LET modu_rec_hold.acct_code = l_acct_code 
		LET modu_rec_hold.level_type = "0" 
		LET modu_rec_hold.invoice_post = 0 
		LET modu_rec_hold.invoice_un = 0 
		LET modu_rec_hold.credit_post = 0 
		LET modu_rec_hold.credit_un = 0 
		LET modu_rec_hold.cash_post = 0 
		LET modu_rec_hold.cash_un = 0 
		LET modu_rec_hold.disc_post = 0 
		LET modu_rec_hold.disc_un = 0 
		LET modu_rec_hold.exp_post = 0 
		LET modu_rec_hold.exp_un = 0 
		INSERT INTO grc_hold VALUES (modu_rec_hold.*) 


		# Fill in zero row FOR blank Year & period data.

		FOR l_level_type = 1 TO 3 
			WHENEVER ERROR CONTINUE 

			IF l_level_type = 1 THEN 
				LET modu_rec_hold.level_type = "1" 
			END IF 

			IF l_level_type = 2 THEN 
				LET modu_rec_hold.level_type = "2" 
			END IF 

			IF l_level_type = 3 THEN 
				LET modu_rec_hold.level_type = "3" 
			END IF 

			LET modu_rec_hold.year_num = l_year_num 
			LET modu_rec_hold.period_num = l_period_num 
			LET modu_rec_hold.acct_code = l_acct_code 
			LET modu_rec_hold.invoice_post = 0 
			LET modu_rec_hold.invoice_un = 0 
			LET modu_rec_hold.credit_post = 0 
			LET modu_rec_hold.credit_un = 0 
			LET modu_rec_hold.cash_post = 0 
			LET modu_rec_hold.cash_un = 0 
			LET modu_rec_hold.disc_post = 0 
			LET modu_rec_hold.disc_un = 0 
			LET modu_rec_hold.exp_post = 0 
			LET modu_rec_hold.exp_un = 0 
			LET modu_rec_hold.period_total = 0 
			INSERT INTO grc_hold VALUES (modu_rec_hold.*) 

			WHENEVER ERROR stop 
		END FOR 
	END FOREACH 
END FUNCTION 



############################################################
# REPORT GRC_rpt_list(p_rpt_idx,p_rec_out) 
#
#
############################################################
REPORT GRC_rpt_list(p_rpt_idx,p_rec_out) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_out RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		acct_code LIKE accounthist.acct_code, 
		level_type CHAR(3), 
		invoice_un DECIMAL(16,2), 
		invoice_post DECIMAL(16,2), 
		credit_un DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		cash_un DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		disc_un DECIMAL(16,2), 
		disc_post DECIMAL(16,2), 
		exp_un DECIMAL(16,2), 
		exp_post DECIMAL(16,2), 
		period_total DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_out1 RECORD 
		invoice_post DECIMAL(16,2), 
		invoice_un DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		credit_un DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		cash_un DECIMAL(16,2), 
		disc_post DECIMAL(16,2), 
		disc_un DECIMAL(16,2), 
		exp_post DECIMAL(16,2), 
		exp_un DECIMAL(16,2) 
	END RECORD
	DEFINE l_rec_out2 RECORD 
		invoice_post DECIMAL(16,2), 
		invoice_un DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		credit_un DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		cash_un DECIMAL(16,2), 
		exp_post DECIMAL(16,2), 
		exp_un DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_out3 RECORD 
		invoice_post DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		exp_post DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_len INTEGER 
	DEFINE s INTEGER 
	DEFINE l_period_total DECIMAL(16,2)
--	DEFINE l_rev_exp_post DECIMAL(16,2)
--	DEFINE l_rev_exp_un DECIMAL(16,2) 

	OUTPUT 

	left margin 0 

	ORDER external BY p_rec_out.year_num, p_rec_out.period_num, 
	p_rec_out.acct_code, p_rec_out.level_type 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, "All VALUES in Base Currency ", 18 spaces,	"GL/Subsidiary Reconciliation (Menu GRC)" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT 
			COLUMN 1, "Year", 
			COLUMN 6, "Period", 
			COLUMN 23, "Invoices", 
			COLUMN 40, "Credits", 
			COLUMN 50, "Cash Receipts", 
			COLUMN 70, "Discounts", 
			COLUMN 87, "Exchange", 
			COLUMN 102, "Net Value", 
			COLUMN 116, "Action Required" 

			PRINT 
			COLUMN 87, "Variance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_out.period_num 
			IF modu_no_data THEN 
				LET modu_report_total = modu_report_total + 1 
				PRINT COLUMN 1, p_rec_out.year_num USING "###&", " ", 
				p_rec_out.period_num USING "##&" 
			END IF 

		BEFORE GROUP OF p_rec_out.acct_code 
			IF modu_no_data THEN 
				PRINT COLUMN 1, " Account Code ", p_rec_out.acct_code 
			END IF 


		AFTER GROUP OF p_rec_out.level_type 

			IF modu_no_data THEN 
				IF p_rec_out.level_type = "1" THEN 

					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(disc_post), sum(disc_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out1.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND acct_code = p_rec_out.acct_code 
					AND level_type = "1" 

					IF l_rec_out1.invoice_un != 0 
					OR l_rec_out1.credit_un != 0 
					OR l_rec_out1.cash_un != 0 
					OR l_rec_out1.disc_un != 0 
					OR l_rec_out1.exp_un != 0 
					THEN 
						LET modu_prob_mess = "** Post using AS7 **" 
					END IF 

					PRINT COLUMN 3, "Subsidiary Ledger" 
					PRINT COLUMN 6, "Posted ", 
					COLUMN 16, l_rec_out1.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted ", 
					COLUMN 16, l_rec_out1.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_un USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_un USING "----,---,--&.&&", 
					COLUMN 113, modu_prob_mess 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 64, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					LET modu_totaller1 = (l_rec_out1.invoice_post + l_rec_out1.invoice_un) 
					- (l_rec_out1.credit_post + l_rec_out1.credit_un 
					+ l_rec_out1.cash_post + l_rec_out1.cash_un 
					+ l_rec_out1.disc_post + l_rec_out1.disc_un 
					+ l_rec_out1.exp_post + l_rec_out1.exp_un) 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out1.invoice_post + l_rec_out1.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post + l_rec_out1.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post + l_rec_out1.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post + l_rec_out1.disc_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post + l_rec_out1.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller1 USING "----,---,--&.&&" 
					SKIP 1 line 
				END IF 

				IF p_rec_out.level_type = "2" THEN 

					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out2.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND acct_code = p_rec_out.acct_code 
					AND level_type = "2" 

					LET modu_prob_mess = " " 
					IF l_rec_out2.invoice_un != 0 
					OR l_rec_out2.credit_un != 0 
					OR l_rec_out2.cash_un != 0 
					OR l_rec_out2.exp_un != 0 
					THEN 
						LET modu_prob_mess = "** Post using GP2 **" 
					END IF 

					PRINT COLUMN 3, "Net GL Batches" 
					PRINT COLUMN 6, "Posted ", 
					COLUMN 16, l_rec_out2.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted ", 
					COLUMN 16, l_rec_out2.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_un USING "----,---,--&.&&", 
					COLUMN 113, modu_prob_mess 

					LET modu_prob_mess = " " 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					LET modu_totaller2 = (l_rec_out2.invoice_post + l_rec_out2.invoice_un) 
					- (l_rec_out2.credit_un + l_rec_out2.credit_post 
					+ l_rec_out2.cash_un + l_rec_out2.cash_post 
					+ l_rec_out2.exp_post + l_rec_out2.exp_un ) 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out2.invoice_post + l_rec_out2.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post + l_rec_out2.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post + l_rec_out2.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post + l_rec_out2.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller2 USING "----,---,--&.&&" 
					SKIP 1 line 
				END IF 

				IF p_rec_out.level_type = "3" THEN 

					SELECT sum(invoice_post), sum(credit_post), sum(cash_post), 
					sum(exp_post) 
					INTO l_rec_out3.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND acct_code = p_rec_out.acct_code 
					AND level_type = "3" 

					PRINT COLUMN 3, "Net Account" 
					PRINT COLUMN 6, "Posted ", 
					COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					LET modu_totaller3 = (l_rec_out3.invoice_post) 
					- (l_rec_out3.credit_post + l_rec_out3.cash_post 
					+ l_rec_out3.exp_post ) 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller3 USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 
					SKIP 1 line 
				END IF 
			END IF 

		AFTER GROUP OF p_rec_out.acct_code 
			IF modu_no_data THEN 
				SELECT sum(period_total) 
				INTO l_period_total 
				FROM grc_hold 
				WHERE year_num = p_rec_out.year_num 
				AND period_num = p_rec_out.period_num 
				AND acct_code matches p_rec_out.acct_code 

				IF l_period_total IS NULL THEN 
					LET l_period_total = 0 
				END IF 

				PRINT COLUMN 63, "Account History Period Actuals : ", 
				l_period_total USING "----,---,--&.&&" 
				IF modu_period_num IS NULL AND 
				modu_year_num IS NULL THEN 
					SKIP 1 line 
					PRINT COLUMN 63, "*** Note Account History Period Actuals are FOR ENTIRE Period" 
					PRINT COLUMN 63, " ** Account Code selection IS FOR a Date Range ***" 
					SKIP 1 line 
				END IF 
			END IF 

		AFTER GROUP OF p_rec_out.period_num 
			IF modu_no_data THEN 
				IF modu_do_period_total > 1 THEN 
					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(disc_post), sum(disc_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out1.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND level_type = "1" 

					LET modu_totaller1 = (l_rec_out1.invoice_post + l_rec_out1.invoice_un) 
					- (l_rec_out1.credit_post + l_rec_out1.credit_un 
					+ l_rec_out1.cash_post + l_rec_out1.cash_un 
					+ l_rec_out1.disc_post + l_rec_out1.disc_un 
					+ l_rec_out1.exp_post + l_rec_out1.exp_un) 

					SKIP 1 line 
					PRINT COLUMN 1, "Total Period ", p_rec_out.year_num USING "####", " ", 
					p_rec_out.period_num USING "##" 
					PRINT COLUMN 3, "Subsidiary Ledger" 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out1.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted ", 
					COLUMN 16, l_rec_out1.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_un USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_un USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 64, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out1.invoice_post + l_rec_out1.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post + l_rec_out1.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post + l_rec_out1.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post + l_rec_out1.disc_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post + l_rec_out1.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller1 USING "----,---,--&.&&" 

					SKIP 1 line 
					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out2.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND level_type = "2" 

					PRINT COLUMN 3, "Net GL Batches" 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out2.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted", 
					COLUMN 16, l_rec_out2.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_un USING "----,---,--&.&&" 

					LET modu_totaller2 = (l_rec_out2.invoice_post + l_rec_out2.invoice_un) 
					- (l_rec_out2.credit_un + l_rec_out2.credit_post 
					+ l_rec_out2.cash_un + l_rec_out2.cash_post 
					+ l_rec_out2.exp_post + l_rec_out2.exp_un ) 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out2.invoice_post + l_rec_out2.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post + l_rec_out2.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post + l_rec_out2.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post + l_rec_out2.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller2 USING "----,---,--&.&&" 

					SKIP 1 line 
					SELECT sum(invoice_post), sum(credit_post), sum(cash_post), 
					sum(exp_post) 
					INTO l_rec_out3.* 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 
					AND level_type = "3" 

					PRINT COLUMN 3, "Net Account " 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					LET modu_totaller3 = (l_rec_out3.invoice_post) 
					- (l_rec_out3.credit_post + l_rec_out3.cash_post 
					+ l_rec_out3.exp_post ) 

					PRINT COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller3 USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					SKIP 1 line 
					SELECT sum(period_total) 
					INTO l_period_total 
					FROM grc_hold 
					WHERE year_num = p_rec_out.year_num 
					AND period_num = p_rec_out.period_num 

					IF l_period_total IS NULL THEN 
						LET l_period_total = 0 
					END IF 

					PRINT COLUMN 63, "Account History Period Actuals : ", 
					l_period_total USING "----,---,--&.&&" 

					IF modu_period_num IS NULL AND 
					modu_year_num IS NULL THEN 
						SKIP 1 line 
						PRINT COLUMN 63, "*** Note Account History Period Actuals are FOR ENTIRE Period" 
						PRINT COLUMN 63, "*** Account Code selection IS FOR a Date Range ***" 
						SKIP 1 line 
					END IF 
				END IF 
			END IF 

		ON LAST ROW 
			IF modu_report_total > 1 THEN 
				IF modu_no_data THEN 
					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(disc_post), sum(disc_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out1.* 
					FROM grc_hold 
					WHERE level_type = "1" 

					LET modu_totaller1 = (l_rec_out1.invoice_post + l_rec_out1.invoice_un) 
					- (l_rec_out1.credit_post + l_rec_out1.credit_un 
					+ l_rec_out1.cash_post + l_rec_out1.cash_un 
					+ l_rec_out1.disc_post + l_rec_out1.disc_un 
					+ l_rec_out1.exp_post + l_rec_out1.exp_un) 

					SKIP 1 line 
					PRINT COLUMN 1, "Report Totals" 
					PRINT COLUMN 3, "Subsidiary Ledger" 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out1.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted ", 
					COLUMN 16, l_rec_out1.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_un USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_un USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 64, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out1.invoice_post + l_rec_out1.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out1.credit_post + l_rec_out1.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out1.cash_post + l_rec_out1.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 64, l_rec_out1.disc_post + l_rec_out1.disc_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out1.exp_post + l_rec_out1.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller1 USING "----,---,--&.&&" 

					SKIP 1 line 
					SELECT sum(invoice_post), sum(invoice_un), 
					sum(credit_post), sum(credit_un), 
					sum(cash_post), sum(cash_un), 
					sum(exp_post), sum(exp_un) 
					INTO l_rec_out2.* 
					FROM grc_hold 
					WHERE level_type = "2" 

					PRINT COLUMN 3, "Net GL Batches" 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out2.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, "Unposted", 
					COLUMN 16, l_rec_out2.invoice_un USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_un USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_un USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_un USING "----,---,--&.&&" 

					LET modu_totaller2 = (l_rec_out2.invoice_post + l_rec_out2.invoice_un) 
					- (l_rec_out2.credit_un + l_rec_out2.credit_post 
					+ l_rec_out2.cash_un + l_rec_out2.cash_post 
					+ l_rec_out2.exp_post + l_rec_out2.exp_un ) 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					PRINT COLUMN 6, "Totals ", 
					COLUMN 16, l_rec_out2.invoice_post + l_rec_out2.invoice_un 
					USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out2.credit_post + l_rec_out2.credit_un 
					USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out2.cash_post + l_rec_out2.cash_un 
					USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out2.exp_post + l_rec_out2.exp_un 
					USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller2 USING "----,---,--&.&&" 

					SKIP 1 line 
					SELECT sum(invoice_post), sum(credit_post), sum(cash_post), 
					sum(exp_post) 
					INTO l_rec_out3.* 
					FROM grc_hold 
					WHERE level_type = "3" 

					PRINT COLUMN 3, "Net Account " 
					PRINT COLUMN 6, "Posted", 
					COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					LET modu_totaller3 = (l_rec_out3.invoice_post) 
					- (l_rec_out3.credit_post + l_rec_out3.cash_post 
					+ l_rec_out3.exp_post ) 

					PRINT COLUMN 16, l_rec_out3.invoice_post USING "----,---,--&.&&", 
					COLUMN 32, l_rec_out3.credit_post USING "----,---,--&.&&", 
					COLUMN 48, l_rec_out3.cash_post USING "----,---,--&.&&", 
					COLUMN 80, l_rec_out3.exp_post USING "----,---,--&.&&", 
					COLUMN 96, modu_totaller3 USING "----,---,--&.&&" 

					PRINT COLUMN 6, " ", 
					COLUMN 16, "===============", 
					COLUMN 32, "===============", 
					COLUMN 48, "===============", 
					COLUMN 80, "===============", 
					COLUMN 96, "===============" 

					SKIP 1 line 
					SELECT sum(period_total) 
					INTO l_period_total 
					FROM grc_hold 

					IF l_period_total IS NULL THEN 
						LET l_period_total = 0 
					END IF 

					PRINT COLUMN 63, "Account History Period Actuals : ", 
					l_period_total USING "----,---,--&.&&" 

					IF modu_period_num IS NULL AND 
					modu_year_num IS NULL THEN 
						SKIP 1 line 
						PRINT COLUMN 63, "*** Note Account History Period Actuals are FOR ENTIRE Period" 
						PRINT COLUMN 63, "*** Account Code selection IS FOR a Date Range ***" 
						SKIP 1 line 
					END IF 
				END IF 
			END IF 



			IF NOT modu_no_data THEN 
				SKIP 1 line 
				PRINT COLUMN 1, " No data met the selection criteria entered." 
			ELSE 
				SKIP TO top OF PAGE 
			END IF 
			SKIP 1 line 

			PRINT COLUMN 1, "Selection criteria: " 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_option1 clipped wordwrap right margin 100				
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT