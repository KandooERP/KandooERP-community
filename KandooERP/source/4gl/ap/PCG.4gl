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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION PCG_main()
# RETURN VOID
#
# PCG - Intersegment Payments Report
############################################################
FUNCTION PCG_main()

	CALL setModuleId("PCG") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P179 with FORM "P179" 
			CALL windecoration_p("P179") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " I/Segment Payments " 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCG","menu-i_segments-1") 
					CALL PCG_rpt_process(PCG_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL PCG_rpt_process(PCG_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P179 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCG_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P179 with FORM "P179" 
			CALL windecoration_p("P179") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCG_rpt_query()
			CALL set_url_sel_text(PCG_rpt_query()) #save where clause in env 
			CLOSE WINDOW P179

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCG_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCG_main()
############################################################


############################################################
# FUNCTION PCG_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCG_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("W",1100,"") #1100 Enter Financial Year AND Period

	CONSTRUCT BY NAME l_ret_sql_sel_text ON year_num, period_num
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCG","construct-years-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_sql_sel_text = NULL
	END IF 

	RETURN l_ret_sql_sel_text
END FUNCTION 
############################################################
# END FUNCTION PCG_rpt_query() 
############################################################

############################################################
# FUNCTION PCG_rpt_process()
# RETURN rpt_finish("PCG_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCG_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_info RECORD 
		bank_acct LIKE cheque.bank_acct_code, 
		cheque_num LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		vouch_num LIKE voucher.vouch_code, 
		vend_code LIKE vendor.vend_code, 
		acct_code LIKE account.acct_code, 
		dist_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.*
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_pay_dist DECIMAL(16,2)
	DEFINE l_start_pos SMALLINT	
	DEFINE l_end_pos SMALLINT
	DEFINE l_all_xs LIKE account.acct_code
	
	LET l_all_xs = "XXXXXXXXXXXXXXXXXX" 
	LET l_query_text = 
	"SELECT unique 1 ",
	"FROM cheque ",
	"WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND pay_amt != apply_amt ",
	"AND ", p_where_text clipped, " "

	PREPARE p_cheque FROM l_query_text
	EXECUTE p_cheque

	IF sqlca.sqlcode != NOTFOUND THEN 
		ERROR " Cheques NOT applied in this period " 
		RETURN FALSE 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCG_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCG_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCG_rpt_list")].sel_text
	#------------------------------------------------------------

--	BEGIN WORK 

	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 

	LET l_start_pos = l_rec_structure.start_num 
	LET l_end_pos = l_start_pos + l_rec_structure.length_num - 1 

	LET l_query_text = 
	"SELECT * ",
	"FROM cheque ",
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code ,"' ",
	"AND ", p_where_text CLIPPED, " "

	PREPARE s_cheque FROM l_query_text 
	DECLARE cheq_curs CURSOR FOR s_cheque 

	FOREACH cheq_curs INTO l_rec_cheque.* 

		DECLARE ca_curs CURSOR FOR 
			SELECT * 
				INTO l_rec_voucherpays.* 
				FROM voucherpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND pay_type_code = "CH" 
					AND pay_num = l_rec_cheque.cheq_code 
					AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
					AND rev_flag IS NULL 

		FOREACH ca_curs 
			#         Add up the applications that are less than this cheque apply
			#         so we take those in sequence TO our payment
			SELECT SUM(apply_amt) 
				INTO l_pay_dist 
				FROM voucherpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vouch_code = l_rec_voucherpays.vouch_code 
					AND vend_code = l_rec_voucherpays.vend_code 
					AND seq_num < l_rec_voucherpays.seq_num 
					AND rev_flag IS NULL 

			IF l_pay_dist IS NULL THEN 
				LET l_pay_dist = 0 
			END IF 

			#         OK now get the voucher AND see IF we need some of this one
			#         l_pay_dist IS the payments distributed TO other cheques

			DECLARE vo_curs CURSOR FOR 
				SELECT * 
					INTO l_rec_voucherdist.* 
					FROM voucherdist 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vouch_code = l_rec_voucherpays.vouch_code 
						AND vend_code = l_rec_voucherpays.vend_code 

			FOREACH vo_curs 
				IF l_pay_dist >= l_rec_voucherdist.dist_amt 
				AND l_pay_dist != 0 THEN 
					LET l_pay_dist = l_pay_dist - l_rec_voucherdist.dist_amt 
				ELSE 
					#             check IF apply fully reported EXIT
					IF l_rec_voucherpays.apply_amt = 0 THEN 
						EXIT FOREACH 
					END IF 
					LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.dist_amt - l_pay_dist 
					LET l_rec_voucherpays.apply_amt = l_rec_voucherpays.apply_amt - l_rec_voucherdist.dist_amt 
					IF l_rec_voucherpays.apply_amt < 0 THEN 
						LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.dist_amt + l_rec_voucherpays.apply_amt 
						LET l_rec_voucherpays.apply_amt = 0 
					END IF 
					IF l_rec_voucherdist.dist_amt > l_rec_cheque.pay_amt THEN 
						LET l_rec_info.dist_amt = l_rec_cheque.pay_amt 
					ELSE 
						LET l_rec_info.dist_amt = l_rec_voucherdist.dist_amt 
					END IF 
					LET l_rec_info.bank_acct = l_rec_cheque.bank_acct_code 
					LET l_rec_info.acct_code = l_rec_voucherdist.acct_code 
					LET l_rec_info.acct_code[l_start_pos, l_end_pos] = l_all_xs[l_start_pos, l_end_pos] 
					LET l_rec_info.cheque_num = l_rec_cheque.cheq_code 
					LET l_rec_info.vend_code = l_rec_cheque.vend_code 
					LET l_rec_info.vouch_num = l_rec_voucherdist.vouch_code 
					LET l_rec_info.pay_meth_ind = l_rec_cheque.pay_meth_ind 

					#------------------------------------------------------------
					OUTPUT TO REPORT PCG_rpt_list(rpt_rmsreps_idx_get_idx("PCG_rpt_list"), l_rec_info.*) 
					IF NOT rpt_int_flag_handler2("Voucher no: ",l_rec_voucherpays.vouch_code, l_rec_voucherpays.vend_code ,rpt_rmsreps_idx_get_idx("PCG_rpt_list")) THEN
						EXIT FOREACH 
					END IF 
					#------------------------------------------------------------

					LET l_rec_cheque.pay_amt = l_rec_cheque.pay_amt - l_rec_voucherdist.dist_amt 
					IF l_rec_cheque.pay_amt <= 0 THEN 
						EXIT FOREACH 
					END IF 

					LET l_pay_dist = 0 

				END IF 
			END FOREACH 
		END FOREACH 
	END FOREACH 

--	COMMIT WORK 

	#------------------------------------------------------------
	FINISH REPORT PCG_rpt_list
	RETURN rpt_finish("PCG_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCG_rpt_process()
############################################################

############################################################
# REPORT PCG_rpt_list(p_rpt_idx, p_rec_info) 
#
# Report Definition/Layout
############################################################
REPORT PCG_rpt_list(p_rpt_idx, p_rec_info) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_info RECORD 
		bank_acct LIKE cheque.bank_acct_code, 
		cheque_num LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		vouch_num LIKE voucher.vouch_code, 
		vend_code LIKE vendor.vend_code, 
		acct_code LIKE account.acct_code, 
		dist_amt MONEY (16,2) 
	END RECORD
	DEFINE l_pay_text CHAR(3) 
	DEFINE l_totaller MONEY(16,2) 

	OUTPUT 
		ORDER BY p_rec_info.bank_acct, p_rec_info.acct_code, 
			p_rec_info.pay_meth_ind, p_rec_info.cheque_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Cheque Number", 
			COLUMN 25, "Voucher", 
			COLUMN 45, "Vendor ", 
			COLUMN 73, "Amount " 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_info.bank_acct 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Bank Account:", p_rec_info.bank_acct 

		BEFORE GROUP OF p_rec_info.acct_code 
			NEED 4 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Account:",p_rec_info.acct_code 
			LET l_totaller = 0 

		ON EVERY ROW 
			LET l_totaller = l_totaller + p_rec_info.dist_amt 
			LET l_pay_text = NULL 
			IF p_rec_info.pay_meth_ind = "3" THEN 
				LET l_pay_text = "EFT" 
			END IF 
			PRINT COLUMN 1, p_rec_info.cheque_num USING "#########", 
			COLUMN 11, l_pay_text, 
			COLUMN 25, p_rec_info.vouch_num USING "#######", 
			COLUMN 45, p_rec_info.vend_code, 
			COLUMN 65, p_rec_info.dist_amt USING "---,---,--&.&&" 

		AFTER GROUP OF p_rec_info.acct_code 
			NEED 3 LINES 
			PRINT COLUMN 65, "--------------" 
			PRINT COLUMN 65, l_totaller USING "---,---,--&.&&" 

		ON LAST ROW 
			NEED 12 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 65, "==============" 
			PRINT COLUMN 65, SUM(p_rec_info.dist_amt) USING "---,---,--&.&&" 
			SKIP 2 line 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 

