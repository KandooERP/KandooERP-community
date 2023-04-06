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
# \brief module PR6 AP Reporting on GL distribution
# This program reports on all AP transactions FOR the nominated period
# (posted AND unposted) by account code - including balancing postings
# as calculated by jourprint

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS 
	DEFINE glob_rec_bal RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text 
	END RECORD 
	DEFINE glob_arr_period DYNAMIC ARRAY OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD 
	DEFINE glob_rec_period RECORD LIKE period.* 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_rec_docdata RECORD 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		tran_date DATE, 
		currency_code LIKE batchdetl.currency_code, 
		conv_qty LIKE batchdetl.conv_qty 
	END RECORD 
	DEFINE glob_rec_detldata RECORD 
		post_acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		debit_amt LIKE batchdetl.debit_amt, 
		credit_amt LIKE batchdetl.credit_amt 
	END RECORD 
	DEFINE glob_rec_current RECORD 
		vend_type LIKE vendor.type_code, 
		pay_acct_code LIKE apparms.pay_acct_code, 
		disc_acct_code LIKE apparms.disc_acct_code, 
		exch_acct_code LIKE apparms.exch_acct_code, 
		bal_acct_code LIKE apparms.pay_acct_code, 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		disc_amt LIKE debithead.disc_amt, 
		post_flag LIKE voucher.post_flag, 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		ref_num LIKE batchdetl.ref_num, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE batchdetl.currency_code, 
		exch_ref_code LIKE exchangevar.ref_code 
	END RECORD 
	DEFINE glob_prev_vend_type LIKE vendor.type_code
	DEFINE glob_query_text STRING -- CHAR(2200) 
	DEFINE glob_sel_text CHAR(2200)
	DEFINE glob_where_part STRING -- CHAR(2048) 
	DEFINE glob_type CHAR(4)
	DEFINE glob_fisc_year SMALLINT 
	DEFINE glob_tempper SMALLINT
	DEFINE glob_select_option CHAR(1) 
	DEFINE idx SMALLINT
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_file_name CHAR(30)

	#Initial UI Init
	CALL setModuleId("PR6") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET glob_type = "FULL" 

	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE parm_code = "1"
	#   AND cmpy_code = glob_rec_kandoouser.cmpy_code
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp = kandoomsg("A",5002,"")
	#   #5002 AP Parameters Not Set Up;  Refer Menu AZP.
	#   EXIT PROGRAM
	#END IF

--	CALL rpt_rmsreps_set_page_size(132,NULL) 
--	LET glob_rpt_time = time 
--	LET l_file_name = "rpt", glob_rpt_time 

	CREATE temp TABLE posttemp 
	( 
	ref_num INTEGER, 
	ref_text CHAR(10), 
	post_acct_code CHAR(18), 
	desc_text CHAR(40), 
	debit_amt money(14,2), 
	credit_amt money(14,2), 
	base_debit_amt money(14,2), 
	base_credit_amt money(14,2), 
	currency_code CHAR(3), 
	conv_qty FLOAT, 
	tran_date DATE, 
	post_flag CHAR(1), 
	pay_acct_code CHAR(18) ) with no LOG 

	OPEN WINDOW P159 with FORM "P159" 
	CALL windecoration_p("P159") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 


	#################
	IF PR6_rpt_query() THEN 
		CALL PR6_rpt_process() --process/generate REPORT 
		IF int_flag = 0 THEN 
			IF fgl_winbutton("Print", "Do you want TO OPEN the PRINT manager? (URS)", "Yes", "Yes|No", "exclamation", 1) = "Yes" THEN 
				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			END IF 
		ELSE 
			LET int_flag = true 
		END IF 

		#IF fgl_winbutton("Print", "Do you want TO close this module?", "Yes", "Yes|No", "exclamation", 1) = "Yes" THEN
		#	EXIT MENU
		#END IF

	END IF 

	################
	{
	  MENU " Post"

			BEFORE MENU
				CALL publish_toolbar("kandoo","PR6","menu-post-1")

			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)

				ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

	      ON ACTION "Print Manager"
	      COMMAND "Report" " SELECT criteria AND PRINT REPORT"
	         IF PR6_rpt_query() THEN
						CALL PR6_rpt_process()  --process/generate REPORT
						IF int_flag = 0 THEN
							IF fgl_winbutton("Print", "Do you want TO OPEN the PRINT manager? (URS)", "Yes", "Yes|No", "exclamation", 1) = "Yes" THEN
								CALL run_prog("URS","","","","")
							END IF
						ELSE
							LET int_flag = TRUE
						END IF

	#IF fgl_winbutton("Print", "Do you want TO close this module?", "Yes", "Yes|No", "exclamation", 1) = "Yes" THEN
	#	EXIT MENU
	#END IF

	         END IF
	#NEXT OPTION "Print Manager"



	      ON ACTION "Print Manager"
	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
	         CALL run_prog("URS","","","","")
	         NEXT OPTION "Exit"

	      COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
	         EXIT MENU



	   END MENU
	}
	CLOSE WINDOW p159 
END MAIN 


############################################################
# FUNCTION PR6_rpt_query()
#
#
############################################################
FUNCTION PR6_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"")	# "Enter selection - ESC TO search"
	CLEAR FORM 
	CONSTRUCT BY NAME l_where_text ON year_num, 
	period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR6","construct-period-1") 

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
		LET glob_sel_text = 
		"SELECT unique year_num, period_num ", 
		"FROM period WHERE cmpy_code = \"",trim(glob_rec_kandoouser.cmpy_code),"\" AND ", 
		trim(glob_where_part), " ", 
		"ORDER BY year_num, period_num " 
		LET glob_where_part = l_where_text
		RETURN l_where_text
	END IF 
END FUNCTION 


############################################################
# FUNCTION PR6_rpt_process()
#
#
############################################################
FUNCTION PR6_rpt_process() 
--DEFINE l_msgresp LIKE language.yes_flag 

	PREPARE getper FROM glob_sel_text 
	DECLARE c_per CURSOR FOR getper 

	
	LET idx = 0 
	FOREACH c_per INTO glob_rec_period.year_num, glob_rec_period.period_num 
		LET idx = idx + 1 
		LET glob_arr_period[idx].year_num = glob_rec_period.year_num 
		LET glob_arr_period[idx].period_num = glob_rec_period.period_num 
	END FOREACH 

	MESSAGE kandoomsg2("A",1038,"") 	#1038 Enter TO Print;  OK TO Continue.
	INPUT ARRAY glob_arr_period WITHOUT DEFAULTS FROM sr_period.* ATTRIBUTE(UNBUFFERED) 
		BEFORE ROW 
			LET idx = arr_curr() 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PR6","inp-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "ACCEPT" 
			LET glob_tempper = glob_arr_period[idx].period_num 
			LET glob_fisc_year = glob_arr_period[idx].year_num 
			CALL PR6_menu_post_2() 
			EXIT INPUT 

		BEFORE FIELD period_num 
			IF int_flag OR quit_flag THEN 
				LET quit_flag = false 
				LET int_flag = false 
			ELSE 
				LET glob_tempper = glob_arr_period[idx].period_num 
				LET glob_fisc_year = glob_arr_period[idx].year_num 
				CALL PR6_menu_post_2() 
				EXIT INPUT 
			END IF 
			        MENU " Post Report"
								BEFORE MENU
									CALL publish_toolbar("kandoo","PR6","menu-post-2")

								ON ACTION "WEB-HELP"
									CALL onlineHelp(getModuleId(),NULL)

									ON ACTION "actToolbarManager"
								 	CALL setupToolbar()

			           COMMAND "All" " Print all items FOR year/period"
			              LET glob_select_option = "A"
			              EXIT MENU

			           COMMAND "Unposted" " Print unposted items FOR year/period"
			              LET glob_select_option = "U"
			              EXIT MENU

			           COMMAND KEY(interrupt, "E")
			              EXIT MENU


			        END MENU

			            IF int_flag OR quit_flag THEN
			               LET int_flag = FALSE
			               LET quit_flag = FALSE
			            ELSE
			               MESSAGE "Report being generated - please wait"
			               CALL PR6_report_ap()
			               MESSAGE "Report printed - Year: ",glob_arr_period[idx].year_num,
			                               " Period: ",glob_arr_period[idx].period_num
			               sleep 3
			            END IF
			# EXIT INPUT

			#END IF

			#AFTER ROW
			#   DISPLAY glob_arr_period[idx].* TO sr_period[scrn].*


	END INPUT 

END FUNCTION 


############################################################
# FUNCTION PR6_menu_post_2()
#
#
############################################################
FUNCTION PR6_menu_post_2() 
	DEFINE l_buttonret STRING --button RETURN value 
	DEFINE l_tmpmsg STRING --message STRING 

	LET l_buttonret = fgl_winbutton("Print ALL OR Unposted", "Do you want TO PRINT All OR Unposted items for this year/period?", "All", "All|Unposted|None", "exclamation", 1) 

	CASE l_buttonret 
		WHEN "All" 
			LET glob_select_option = "A" 

		WHEN "Unposted" 
			LET glob_select_option = "U" 

		OTHERWISE 
			LET int_flag = true --exit, don't PRINT 
	END CASE 


	{

	        MENU " Post Report"
						BEFORE MENU
							CALL publish_toolbar("kandoo","PR6","menu-post-2")

						ON ACTION "WEB-HELP"
							CALL onlineHelp(getModuleId(),NULL)

							ON ACTION "actToolbarManager"
						 	CALL setupToolbar()

	           COMMAND "All" " Print all items FOR year/period"
	              LET glob_select_option = "A"
	              EXIT MENU

	           COMMAND "Unposted" " Print unposted items FOR year/period"
	              LET glob_select_option = "U"
	              EXIT MENU

	           COMMAND KEY(interrupt, "E")
	              EXIT MENU


	        END MENU
	}
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		#DISPLAY "" AT 2,1
		MESSAGE "Report being generated - please wait..." 
		DISPLAY "Report being generated - please wait..." TO lbinfo1 
		CALL ui.interface.refresh() 
		CALL PR6_report_ap() 
		LET l_tmpmsg = "Report printed \nYear: ",trim(glob_arr_period[idx].year_num), "\n", 
		" Period: ",trim(glob_arr_period[idx].period_num) 
		MESSAGE l_tmpmsg 

		CALL fgl_winmessage("Report printed",l_tmpmsg,"info") 
	END IF 

END FUNCTION 

############################################################
# FUNCTION PR6_report_ap()
#
#
############################################################
FUNCTION PR6_report_ap() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	BEGIN WORK 

		#------------------------------------------------------------
		#User pressed CANCEL = p_where_text IS NULL 
		--IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		--	LET int_flag = FALSE 
		--	LET quit_flag = FALSE
		--
		--	RETURN FALSE
		--END IF
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"COM_rpt_list_bdt","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT COM_rpt_list_bdt TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------


		# Check that the journals are present

		SELECT * 
		INTO glob_rec_journal.* 
		FROM journal 
		WHERE jour_code = glob_rec_apparms.pur_jour_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			ERROR "Purchases Journal NOT found" 
			SLEEP 3 
			EXIT PROGRAM 
		END IF 

		SELECT * 
		INTO glob_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_apparms.chq_jour_code 
		IF status = NOTFOUND THEN 
			ERROR " Cash Payments Journal NOT found " 
			SLEEP 3 
			EXIT PROGRAM 
		END IF 

		# do all the voucher reporting

		CALL PR6_voucher(l_rpt_idx) 

		# do all the debit reporting

		CALL PR6_debit(l_rpt_idx) 

		# do all the cheque reporting

		CALL PR6_cheque(l_rpt_idx) 

		# do all the exchange variance reporting

		CALL PR6_exch_var(l_rpt_idx) 

		#------------------------------------------------------------
		FINISH REPORT COM_rpt_list_bdt
		CALL rpt_finish("COM_rpt_list_bdt")
		#------------------------------------------------------------

	COMMIT WORK 


END FUNCTION 

############################################################
# FUNCTION PR6_get_vend_accts()
############################################################
FUNCTION PR6_get_vend_accts() 

	# Payables control, discount AND exchange variance posting accounts
	# determined by vendor glob_type. Default TO AP parameters IF NULL

	SELECT vendortype.pay_acct_code, 
	vendortype.disc_acct_code, 
	vendortype.exch_acct_code 
	INTO glob_rec_current.pay_acct_code, 
	glob_rec_current.disc_acct_code, 
	glob_rec_current.exch_acct_code 
	FROM vendortype 
	WHERE vendortype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vendortype.type_code = glob_rec_current.vend_type 

	IF status = NOTFOUND THEN 
		INITIALIZE glob_rec_current.pay_acct_code, 
		glob_rec_current.disc_acct_code, 
		glob_rec_current.exch_acct_code 
		TO NULL 
	END IF 

	IF glob_rec_current.pay_acct_code IS NULL THEN 
		LET glob_rec_current.pay_acct_code = glob_rec_apparms.pay_acct_code 
	END IF 

	IF glob_rec_current.disc_acct_code IS NULL THEN 
		LET glob_rec_current.disc_acct_code = glob_rec_apparms.disc_acct_code 
	END IF 

	IF glob_rec_current.exch_acct_code IS NULL THEN 
		LET glob_rec_current.exch_acct_code = glob_rec_apparms.exch_acct_code 
	END IF 

	LET glob_prev_vend_type = glob_rec_current.vend_type 

END FUNCTION 


############################################################
# FUNCTION PR6_report_gl_batches(p_rpt_idx)
#
#
############################################################
FUNCTION PR6_report_gl_batches(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_sel_stmt CHAR(2200)
	# batch posting details according TO payables control account AND
	# currency code (ie. all entries FOR the same control/balancing
	# account AND currency in one batch)

	DECLARE p_curs CURSOR FOR 
	SELECT unique posttemp.pay_acct_code, 
	posttemp.currency_code 
	FROM posttemp 

	FOREACH p_curs INTO glob_rec_current.bal_acct_code, glob_rec_current.currency_code 
		LET glob_rec_bal.acct_code = glob_rec_current.bal_acct_code 

		LET l_sel_stmt = " SELECT ", "\"", glob_rec_current.tran_type_ind clipped, "\",", 
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
		" posttemp.post_flag ", 
		" FROM posttemp ", 
		" WHERE posttemp.pay_acct_code = \"", 
		trim(glob_rec_bal.acct_code), "\"", 
		" AND posttemp.currency_code = \"", 
		trim(glob_rec_current.currency_code), "\"" 

		LET glob_rec_current.jour_num = jourprint(p_rpt_idx,
		l_sel_stmt, 
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		glob_rec_bal.*, 
		glob_tempper, 
		glob_fisc_year, 
		glob_rec_current.jour_code, 
		"P", 
		glob_rec_current.currency_code, 
		--glob_rpt_output, 
		glob_type) 

	END FOREACH 

END FUNCTION 


############################################################
# FUNCTION PR6_voucher()
#
#
############################################################
FUNCTION PR6_voucher(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	LET glob_prev_vend_type = " " 
	LET glob_rec_current.tran_type_ind = "VO" 
	LET glob_rec_current.jour_code = glob_rec_apparms.pur_jour_code 
	LET glob_rec_current.base_credit_amt = 0 

	# SELECT all distributed vouchers FOR the required period

	IF glob_select_option = "A" THEN 
		LET glob_where_part = " " 
	ELSE 
		LET glob_where_part = "AND voucher.post_flag = \"N\"" 
	END IF 

	LET glob_query_text = "SELECT voucher.vouch_code, ", 
	"voucher.vend_code, ", 
	"voucher.vouch_date, ", 
	"voucher.currency_code, ", 
	"voucher.conv_qty, ", 
	"voucher.post_flag, ", 
	"vendor.type_code ", 
	"FROM voucher, vendor ", 
	"WHERE voucher.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
	"AND voucher.year_num = ", trim(glob_fisc_year), " ", 
	"AND voucher.period_num = ", trim(glob_tempper), " ", 
	"AND voucher.total_amt = voucher.dist_amt ", 
	"AND voucher.cmpy_code = vendor.cmpy_code ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	trim(glob_where_part), " ", 
	"ORDER BY voucher.vend_code, voucher.vouch_code " 

	PREPARE statement_1 FROM glob_query_text 
	DECLARE vo_curs CURSOR FOR statement_1 

	FOREACH vo_curs INTO glob_rec_docdata.*, 
		glob_rec_current.post_flag, 
		glob_rec_current.vend_type 

		# determine the posting control accounts FOR this vendor glob_type, IF changed

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		# create posting details FOR each distribution FOR the selected vouchers

		DECLARE vd_curs CURSOR FOR 
		SELECT voucherdist.acct_code, 
		voucherdist.desc_text, 
		voucherdist.dist_amt, 
		0 
		FROM voucherdist 
		WHERE voucherdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND voucherdist.vouch_code = glob_rec_docdata.ref_num 
		AND voucherdist.vend_code = glob_rec_docdata.ref_text 

		FOREACH vd_curs INTO glob_rec_detldata.* 

			IF glob_rec_docdata.conv_qty IS NOT NULL THEN 
				IF glob_rec_docdata.conv_qty != 0 THEN 
					LET glob_rec_current.base_debit_amt = glob_rec_detldata.debit_amt / glob_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO posttemp VALUES 
			(glob_rec_docdata.ref_num, # voucher number 
			glob_rec_docdata.ref_text, # vendor code 
			glob_rec_detldata.post_acct_code, # voucher distribution account 
			glob_rec_detldata.desc_text, # voucher distribution desc 
			glob_rec_detldata.debit_amt, # voucher distribution amount 
			glob_rec_detldata.credit_amt, # zero FOR "VO" 
			glob_rec_current.base_debit_amt, # converted debit amount 
			glob_rec_detldata.credit_amt, # zero FOR "VO" 
			glob_rec_docdata.currency_code, # voucher currency code 
			glob_rec_docdata.conv_qty, # voucher currency conversion 
			glob_rec_docdata.tran_date, # voucher DATE 
			glob_rec_current.post_flag, # voucher post flag 
			glob_rec_current.pay_acct_code) # control account 

		END FOREACH 
	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "VO" 
	LET glob_rec_bal.desc_text = " AP Voucher Balancing Entry" 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

END FUNCTION 


############################################################
# FUNCTION PR6_debit(p_rpt_idx)
############################################################
FUNCTION PR6_debit(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET glob_prev_vend_type = " " 
	LET glob_rec_current.tran_type_ind = "DM" 
	LET glob_rec_current.base_debit_amt = 0 
	LET glob_rec_current.jour_code = glob_rec_apparms.pur_jour_code 

	# SELECT all distributed debits FOR the required period

	IF glob_select_option = "A" THEN 
		LET glob_where_part = " " 
	ELSE 
		LET glob_where_part = "AND debithead.post_flag = \"N\"" 
	END IF 

	LET glob_query_text = "SELECT debithead.debit_num, ", 
	"debithead.vend_code, ", 
	"debithead.debit_date, ", 
	"debithead.currency_code, ", 
	"debithead.conv_qty, ", 
	"vendor.type_code, ", 
	"debithead.disc_amt, ", 
	"debithead.post_flag ", 
	"FROM debithead, vendor ", 
	"WHERE debithead.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
	"AND debithead.year_num = ", trim(glob_fisc_year), " ", 
	"AND debithead.period_num = ", trim(glob_tempper), " ", 
	"AND debithead.total_amt = debithead.dist_amt ", 
	"AND debithead.cmpy_code = vendor.cmpy_code ", 
	"AND debithead.vend_code = vendor.vend_code ", 
	trim(glob_where_part), " ", 
	"ORDER BY debithead.vend_code, debithead.debit_num " 

	PREPARE statement_2 FROM glob_query_text 
	DECLARE dm_curs CURSOR FOR statement_2 

	FOREACH dm_curs INTO glob_rec_docdata.*, 
		glob_rec_current.vend_type, 
		glob_rec_current.disc_amt, 
		glob_rec_current.post_flag 

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		# INSERT posting data FOR the Debit discount amount

		IF glob_rec_current.disc_amt IS NOT NULL AND glob_rec_current.disc_amt != 0	THEN 

			IF glob_rec_docdata.conv_qty IS NOT NULL THEN 
				IF glob_rec_docdata.conv_qty != 0 THEN 
					LET glob_rec_current.base_credit_amt = glob_rec_current.disc_amt / glob_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO posttemp VALUES 
			(glob_rec_docdata.ref_num, # debit number 
			glob_rec_docdata.ref_text, # vendor code 
			glob_rec_current.disc_acct_code, # discount control account 
			glob_rec_docdata.ref_num, # debit number 
			0, 
			glob_rec_current.disc_amt, # debit discount amount 
			glob_rec_current.base_debit_amt, # zero FOR discounts 
			glob_rec_current.base_credit_amt, # converted credit amt 
			glob_rec_docdata.currency_code, # debit currency code 
			glob_rec_docdata.conv_qty, # debit conversion rate 
			glob_rec_docdata.tran_date, # debit DATE 
			glob_rec_current.post_flag, # debit post flag 
			glob_rec_current.pay_acct_code) # control account 

		END IF 

		# create posting details FOR the distributions FOR the selected debits

		DECLARE dd_curs CURSOR FOR 
		SELECT debitdist.acct_code, 
		debitdist.desc_text, 
		0, 
		debitdist.dist_amt 
		FROM debitdist 
		WHERE debitdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND debitdist.debit_code = glob_rec_docdata.ref_num 
		AND debitdist.vend_code = glob_rec_docdata.ref_text 

		FOREACH dd_curs INTO glob_rec_detldata.* 

			IF glob_rec_docdata.conv_qty IS NOT NULL THEN 
				IF glob_rec_docdata.conv_qty != 0 THEN 
					LET glob_rec_current.base_credit_amt = glob_rec_detldata.credit_amt / glob_rec_docdata.conv_qty 
				END IF 
			END IF 

			INSERT INTO posttemp VALUES 
			(glob_rec_docdata.ref_num, # debit number 
			glob_rec_docdata.ref_text, # vendor code 
			glob_rec_detldata.post_acct_code, # debit distribution account 
			glob_rec_detldata.desc_text, # debit distribution desc 
			glob_rec_detldata.debit_amt, # zero FOR "DM" 
			glob_rec_detldata.credit_amt, # debit distribution amount 
			glob_rec_current.base_debit_amt, # zero FOR "DM" 
			glob_rec_current.base_credit_amt, # converted distribution amt 
			glob_rec_docdata.currency_code, # debit currency code 
			glob_rec_docdata.conv_qty, # debit conversion rate 
			glob_rec_docdata.tran_date, # debit DATE 
			glob_rec_current.post_flag, # debit post flag 
			glob_rec_current.pay_acct_code) # control account 

		END FOREACH 
	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "DM" 
	LET glob_rec_bal.desc_text = " AP Debit Balancing Entry" 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

END FUNCTION 


############################################################
# FUNCTION PR6_cheque()
#
#
############################################################
FUNCTION PR6_cheque(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	LET glob_prev_vend_type = " " 
	LET glob_rec_current.tran_type_ind = "CH" 
	LET glob_rec_current.base_debit_amt = 0 
	LET glob_rec_current.jour_code = glob_rec_apparms.pur_jour_code 

	# INSERT posting data FOR the Cheque discount amount
	# discounts posted in a separate batch TO cheque payments due TO
	# differing journal codes
	# SELECT only non-zero discounts FOR posting

	IF glob_select_option = "A" THEN 
		LET glob_where_part = " " 
	ELSE 
		LET glob_where_part = "AND cheque.post_flag = \"N\"" 
	END IF 

	LET glob_query_text = "SELECT cheque.cheq_code, ", 
	"cheque.vend_code, ", 
	"cheque.cheq_date, ", 
	"cheque.currency_code, ", 
	"cheque.conv_qty, ", 
	"vendor.type_code, ", 
	"\" \", ", 
	"cheque.cheq_code, ", 
	"0, ", 
	"cheque.disc_amt, ", 
	"cheque.post_flag ", 
	"FROM cheque, vendor ", 
	"WHERE cheque.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
	"AND cheque.year_num = ", trim(glob_fisc_year), " ", 
	"AND cheque.period_num = ", trim(glob_tempper), " ", 
	"AND cheque.disc_amt IS NOT NULL ", 
	"AND cheque.disc_amt != 0 ", 
	"AND cheque.cmpy_code = vendor.cmpy_code ", 
	"AND cheque.vend_code = vendor.vend_code ", 
	trim(glob_where_part), " ", 
	"ORDER BY cheque.vend_code, cheque.cheq_code " 

	PREPARE statement_3 FROM glob_query_text 
	DECLARE cd_curs CURSOR FOR statement_3 

	FOREACH cd_curs INTO glob_rec_docdata.*, 
		glob_rec_current.vend_type, 
		glob_rec_detldata.*, 
		glob_rec_current.post_flag 

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		IF glob_rec_docdata.conv_qty IS NOT NULL THEN 
			IF glob_rec_docdata.conv_qty != 0 THEN 
				LET glob_rec_current.base_credit_amt = glob_rec_detldata.credit_amt / glob_rec_docdata.conv_qty 
			END IF 
		END IF 

		INSERT INTO posttemp VALUES 
		(glob_rec_docdata.ref_num, # cheque number 
		glob_rec_docdata.ref_text, # vendor code 
		glob_rec_current.disc_acct_code, # discount control account 
		glob_rec_docdata.ref_num, # cheque number 
		glob_rec_detldata.debit_amt, # zero FOR cheque discounts 
		glob_rec_detldata.credit_amt, # cheque discount amount 
		glob_rec_current.base_debit_amt, # zero FOR cheque discounts 
		glob_rec_current.base_credit_amt, # converted discount amount 
		glob_rec_docdata.currency_code, # cheque currency code 
		glob_rec_docdata.conv_qty, # cheque conversion rate 
		glob_rec_docdata.tran_date, # cheque DATE 
		glob_rec_current.post_flag, # cheque post flag 
		glob_rec_current.pay_acct_code) # control account 

	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "CH" 
	LET glob_rec_bal.desc_text = " AP Cheque Discount Balancing Entry" 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

	# INSERT posting data FOR the Cheque payment amounts

	LET glob_query_text = "SELECT cheque.cheq_code, ", 
	"cheque.vend_code, ", 
	"cheque.cheq_date, ", 
	"cheque.currency_code, ", 
	"cheque.conv_qty, ", 
	"vendor.type_code, ", 
	"cheque.bank_acct_code, ", 
	"cheque.cheq_code, ", 
	"0, ", 
	"cheque.net_pay_amt, ", 
	"cheque.post_flag ", 
	"FROM cheque, vendor ", 
	"WHERE cheque.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
	"AND cheque.year_num = ", trim(glob_fisc_year), " ", 
	"AND cheque.period_num = ", trim(glob_tempper), " ", 
	"AND cheque.cmpy_code = vendor.cmpy_code ", 
	"AND cheque.vend_code = vendor.vend_code ", 
	trim(glob_where_part), " ", 
	"ORDER BY cheque.vend_code, cheque.cheq_code " 

	PREPARE statement_4 FROM glob_query_text 
	DECLARE ch_curs CURSOR FOR statement_4 

	FOREACH ch_curs INTO glob_rec_docdata.*, 
		glob_rec_current.vend_type, 
		glob_rec_detldata.*, 
		glob_rec_current.post_flag 

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		IF glob_rec_docdata.conv_qty IS NOT NULL THEN 
			IF glob_rec_docdata.conv_qty != 0 THEN 
				LET glob_rec_current.base_credit_amt = glob_rec_detldata.credit_amt / glob_rec_docdata.conv_qty 
			END IF 
		END IF 

		INSERT INTO posttemp VALUES 
		(glob_rec_docdata.ref_num, # cheque number 
		glob_rec_docdata.ref_text, # vendor code 
		glob_rec_detldata.post_acct_code, # cheque bank gl account 
		glob_rec_detldata.desc_text, # cheque number 
		glob_rec_detldata.debit_amt, # zero FOR "CH" 
		glob_rec_detldata.credit_amt, # cheque payment amount 
		glob_rec_current.base_debit_amt, # zero FOR "CH" 
		glob_rec_current.base_credit_amt, # converted payment amount 
		glob_rec_docdata.currency_code, # cheque currency code 
		glob_rec_docdata.conv_qty, # cheque conversion rate 
		glob_rec_docdata.tran_date, # cheque DATE 
		glob_rec_current.post_flag, # cheque post flag 
		glob_rec_current.pay_acct_code) # control account 

	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "CH" 
	LET glob_rec_bal.desc_text = " AP Cheques Balancing Entry" 
	LET glob_rec_current.jour_code = glob_rec_apparms.chq_jour_code 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

END FUNCTION 


############################################################
# FUNCTION PR6_exch_var(p_rpt_idx)
#
#
############################################################
FUNCTION PR6_exch_var(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	LET glob_prev_vend_type = " " 
	LET glob_rec_current.tran_type_ind = "EXP" 
	LET glob_rec_current.jour_code = glob_rec_apparms.chq_jour_code 

	# INSERT posting data FOR the Payables exchange variances
	# first debits

	IF glob_select_option = "A" THEN 
		LET glob_where_part = " " 
	ELSE 
		LET glob_where_part = "AND exchangevar.posted_flag = \"N\"" 
	END IF 

	LET glob_query_text = "SELECT exchangevar.ref1_num, ", 
	"exchangevar.ref2_num, ", 
	"exchangevar.tran_date, ", 
	"exchangevar.currency_code, ", 
	"0, ", 
	"exchangevar.ref_code, ", 
	"exchangevar.exchangevar_amt, ", 
	"exchangevar.posted_flag, ", 
	"vendor.type_code ", 
	"FROM exchangevar, vendor ", 
	"WHERE exchangevar.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
	"AND exchangevar.year_num = ", trim(glob_fisc_year), " ", 
	"AND exchangevar.period_num = ", trim(glob_tempper), " ", 
	"AND exchangevar.source_ind = \"P\" ", 
	"AND exchangevar.cmpy_code = vendor.cmpy_code ", 
	"AND exchangevar.ref_code = vendor.vend_code ", 
	"AND exchangevar.exchangevar_amt > 0 ", 
	glob_where_part clipped, " ", 
	"ORDER BY exchangevar.ref_code " 

	PREPARE statement_5 FROM glob_query_text 
	DECLARE exd_curs CURSOR FOR statement_5 

	FOREACH exd_curs INTO glob_rec_docdata.*, 
		glob_rec_current.exch_ref_code, 
		glob_rec_current.base_debit_amt, 
		glob_rec_current.post_flag, 
		glob_rec_current.vend_type 

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		INSERT INTO posttemp VALUES 
		(glob_rec_docdata.ref_num, # exch var ref 1 
		glob_rec_docdata.ref_text, # exch var ref 2 
		glob_rec_current.exch_acct_code, # exchange control account 
		glob_rec_current.exch_ref_code, # vendor code FOR source_ind "P" 
		0, 
		0, 
		glob_rec_current.base_debit_amt, # exch var amount IF +ve, 
		0, 
		glob_rec_docdata.currency_code, # exch var currency code 
		glob_rec_docdata.conv_qty, # exch var conversion rate 
		glob_rec_docdata.tran_date, # exch var DATE 
		glob_rec_current.post_flag, # variance post flag 
		glob_rec_current.pay_acct_code) # control account 


	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "EXP" 
	LET glob_rec_bal.desc_text = " AP Exch Var Balancing Entry" 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

	LET glob_query_text = "SELECT exchangevar.ref1_num, ", 
	"exchangevar.ref2_num, ", 
	"exchangevar.tran_date, ", 
	"exchangevar.currency_code, ", 
	"0, ", 
	"exchangevar.ref_code, ", 
	"exchangevar.exchangevar_amt, ", 
	"exchangevar.posted_flag, ", 
	"vendor.type_code ", 
	"FROM exchangevar, vendor ", 
	"WHERE exchangevar.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND exchangevar.year_num = ", glob_fisc_year, " ", 
	"AND exchangevar.period_num = ", glob_tempper, " ", 
	"AND exchangevar.source_ind = \"P\" ", 
	"AND exchangevar.cmpy_code = vendor.cmpy_code ", 
	"AND exchangevar.ref_code = vendor.vend_code ", 
	"AND exchangevar.exchangevar_amt < 0 ", 
	glob_where_part clipped, " ", 
	"ORDER BY exchangevar.ref_code " 

	PREPARE statement_6 FROM glob_query_text 
	DECLARE exc_curs CURSOR FOR statement_6 

	FOREACH exc_curs INTO glob_rec_docdata.*, 
		glob_rec_current.exch_ref_code, 
		glob_rec_current.base_credit_amt, 
		glob_rec_current.post_flag, 
		glob_rec_current.vend_type 

		IF glob_rec_current.vend_type != glob_prev_vend_type THEN 
			CALL PR6_get_vend_accts() 
		END IF 

		LET glob_rec_current.base_credit_amt = 0 - glob_rec_current.base_credit_amt - 0 

		INSERT INTO posttemp VALUES 
		(glob_rec_docdata.ref_num, # exch var ref 1 
		glob_rec_docdata.ref_text, # exch var ref 2 
		glob_rec_current.exch_acct_code, # exchange control account 
		glob_rec_current.exch_ref_code, # vendor code FOR source_ind "P" 
		0, 
		0, 
		0, 
		glob_rec_current.base_credit_amt, # exch var amount IF -ve (sign reversed) 
		glob_rec_docdata.currency_code, # exch var currency code 
		glob_rec_docdata.conv_qty, # exch var conversion rate 
		glob_rec_docdata.tran_date, # exch var DATE 
		glob_rec_current.post_flag, # variance post flag 
		glob_rec_current.pay_acct_code) # control account 


	END FOREACH 

	LET glob_rec_bal.tran_type_ind = "EXP" 
	LET glob_rec_bal.desc_text = " AP Exch Var Balancing Entry" 

	CALL PR6_report_gl_batches(p_rpt_idx) 

	DELETE FROM posttemp WHERE 1 = 1 

END FUNCTION