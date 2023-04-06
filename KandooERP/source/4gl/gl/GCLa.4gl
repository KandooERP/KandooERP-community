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

###############################################################################
#
#                      NAB Interface file LEGEND
#
###############################################################################
#
#  rec_type SMALLINT,               01                 -  File Header
#  trans1_text CHAR(4),             Recipient of file
#  trans2_text CHAR(30),
#  trans3_text CHAR(70),
#  trans4_text CHAR(5),             File Creation Time -  FORMAT hh:mm
#  trans_date DATE,                 File Creation Date -  FORMAT dd/mm/yy
#  trans1_num INTEGER,
#  trans1_amt DECIMAL(16,2),
#  trans2_num INTEGER,
#  trans2_amt DECIMAL(16,2),
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,
#  trans4_amt DECIMAL(16,2),
#  trans5_num INTEGER,
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2)
#
###############################################################################
#
#  rec_type SMALLINT,               02                 -  Group Header
#  trans1_text CHAR(4),             Recipient of file
#  trans2_text CHAR(30),            Originator of file / Bank Group Code
#  trans3_text CHAR(70),
#  trans4_text CHAR(5),
#  trans_date DATE,                 Statement Date     -  FORMAT dd/mm/yy
#  trans1_num INTEGER,
#  trans1_amt DECIMAL(16,2),
#  trans2_num INTEGER,
#  trans2_amt DECIMAL(16,2),
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,
#  trans4_amt DECIMAL(16,2),
#  trans5_num INTEGER,
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2)
#
###############################################################################
#
#  rec_type SMALLINT,               03                 -  Account Identifier
#  trans1_text CHAR(4),             Bank Currency Code
#  trans2_text CHAR(30),            Account Number AT the Bank
#  trans3_text CHAR(70),            MSGS ie (Acct on file, Acct already loaded
#                                            Stmt out of seq etc.)
#  trans4_text CHAR(5),
#  trans_date DATE,
#  trans1_num INTEGER,              Transaction Number(Closing Balance)
#  trans1_amt DECIMAL(16,2),        Closing Balance Amount
#  trans2_num INTEGER,              Transaction Number(Total Debits)
#  trans2_amt DECIMAL(16,2),        Total Debits Amount
#  trans3_num INTEGER,              Transaction Number(Total Debits Count)
#  trans3_amt DECIMAL(16,2),        Total Debits Count
#  trans4_num INTEGER,              Transaction Number(Total Credits)
#  trans4_amt DECIMAL(16,2),        Total Credits Amount
#  trans5_num INTEGER,              Transaction Number(Total Credits Count)
#  trans5_amt DECIMAL(16,2),        Total Credits Count
#  trans6_num INTEGER,              Transaction Number(Unposted Credit Interest)
#  trans6_amt DECIMAL(16,2),        Unposted Credit Interest
#  trans7_num INTEGER,              Transaction Number(Uposted Debit Interest)
#  trans7_amt DECIMAL(16,2),        Unposted Debit Interest
#  trans8_num INTEGER,              Transaction Number(Overdraft Limit)
#  trans8_amt DECIMAL(16,2),        Overdraft limit
#  trans9_num INTEGER,              Transaction Number(Avail Overdraft Limit)
#  trans9_amt DECIMAL(16,2)         Available Overdraft Limit
#  trans10_num INTEGER,             Transaction Number(Debit Interest Rate)
#  trans10_amt DECIMAL(16,2),       Effective Debit Interest Rate
#  trans11_num INTEGER,             Transaction Number(Credit Interest Rate)
#  trans11_amt DECIMAL(16,2),       Effective Credit Interest Rate
#  trans12_num INTEGER,             Transaction Number(State Govt Duty)
#  trans12_amt DECIMAL(16,2),       Accrued State Govt Duty
#  trans13_num INTEGER,             Transaction Number(Govt Credit Tax)
#  trans13_amt DECIMAL(16,2),       Accrued Govt Credit Tax
#  trans14_num INTEGER,             Transaction Number(Govt Debit Tax)
#  trans14_amt DECIMAL(16,2),       Accrued Govt Debit Tax
#
###############################################################################
#
#  rec_type SMALLINT,               16                 -  Account Detail
#  trans1_text CHAR(4),             Trans Type (ie. CH BD PA)
#  trans2_text CHAR(30),            Reference Number (ie. FOR Cheques etc)
#  trans3_text CHAR(70),            Comment Text OR used FOR DISPLAY of error
#                                      msgs (ie. Cheque Not found etc)
#  trans4_text CHAR(5),             Reconciliation Indicator (ie. 'Y' OR 'N')
#  trans_date DATE,
#  trans1_num INTEGER,              Transaction Number(ie. FOR 'CH' = 475 etc)
#  trans1_amt DECIMAL(16,2),        Transaction Amount
#  trans2_num INTEGER,
#  trans2_amt DECIMAL(16,2),
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,
#  trans4_amt DECIMAL(16,2),
#  trans5_num INTEGER,
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2)
#
###############################################################################
#
#  rec_type SMALLINT,               49                 -  Account Trailer
#  trans1_text CHAR(4),
#  trans2_text CHAR(30),
#  trans3_text CHAR(70),            Used FOR DISPLAY of any error conditions
#  trans4_text CHAR(5),
#  trans_date DATE,
#  trans1_num INTEGER,
#  trans1_amt DECIMAL(16,2),        Account Hash Total  - GROUP ONE (Total A)
#  trans2_num INTEGER,
#  trans2_amt DECIMAL(16,2),        GCL.4gl  Accum Total FOR Comparison - GRP 1
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,
#  trans4_amt DECIMAL(16,2),
#  trans5_num INTEGER,
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),         Account Hash Total  - GROUP TWO (Total B)
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2),
#
###############################################################################
#
#  rec_type SMALLINT,               98                 -  Group Trailer
#  trans1_text CHAR(4),
#  trans2_text CHAR(30),
#  trans3_text CHAR(70),            Used FOR DISPLAY of any error conditions
#  trans4_text CHAR(5),
#  trans_date DATE,
#  trans1_num INTEGER,              No of Accts in Group  -  Hash Total
#  trans1_amt DECIMAL(16,2),        Group Hash Total Amount - GROUP ONE
#  trans2_num INTEGER,              GCL.4gl  Accumulated No of Accts in Group
#  trans2_amt DECIMAL(16,2),        GCL.4gl  Accumulated Group Total  -GRP 1
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,
#  trans4_amt DECIMAL(16,2),
#  trans5_num INTEGER,
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),        Group Hash Total Amount - GROUP TWO
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2)
#
###############################################################################
#
#  rec_type SMALLINT,               99                 -  File Trailer
#  trans1_text CHAR(4),
#  trans2_text CHAR(30),
#  trans3_text CHAR(70),            Used FOR DISPLAY of any error conditions
#  trans4_text CHAR(5),
#  trans_date DATE,
#  trans1_num INTEGER,              No of Groups in file  -  Hash Total
#  trans1_amt DECIMAL(16,2),        File Hash Total Amount
#  trans2_num INTEGER,              No of rows in file    -  Hash Total
#  trans2_amt DECIMAL(16,2),
#  trans3_num INTEGER,
#  trans3_amt DECIMAL(16,2),
#  trans4_num INTEGER,              GCL.4gl  Accumulated No of Groups in file
#  trans4_amt DECIMAL(16,2),        GCL.4gl  Accumulated File Total Amount
#  trans5_num INTEGER,              GCL.4gl  Accumulated No of rows in file
#  trans5_amt DECIMAL(16,2),
#  trans6_num INTEGER,
#  trans6_amt DECIMAL(16,2),        Group2?
#  trans7_num INTEGER,
#  trans7_amt DECIMAL(16,2),
#  trans8_num INTEGER,
#  trans8_amt DECIMAL(16,2),
#  trans9_num INTEGER,
#  trans9_amt DECIMAL(16,2)
#
###############################################################################

# \brief module GCLa  Loads bank statement details directly FROM an interface
#               file provided by N.A.B. Transactions will also
#               be reconciled WHERE sufficient information exists.
#

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCL_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_stmthead RECORD LIKE bankstatement.* 


############################################################
# FUNCTION nab_stmt_load(p_type_code)
#
#
############################################################
FUNCTION nab_stmt_load(p_type_code) 
	DEFINE p_type_code LIKE banktype.type_code 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_banktype RECORD LIKE banktype.* 
	DEFINE l_stmt_line char(512) 
	DEFINE l_rec_output	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_rpt_output char(50) 
	DEFINE l_rec_type SMALLINT 
	DEFINE l_prev_rec_type SMALLINT 
	DEFINE l_valid_sequence SMALLINT 
	DEFINE l_tot_grps INTEGER 
	DEFINE l_tot_accts INTEGER 
	DEFINE l_file_tot_amt decimal(16,2) 
	DEFINE l_grp_tot_amt decimal(16,2) 
	DEFINE l_acct_tot_amt decimal(16,2) 
	DEFINE l_file_tot2_amt decimal(16,2) 
	DEFINE l_grp_tot2_amt decimal(16,2) 
	DEFINE l_acct_tot2_amt decimal(16,2) 


	LET l_prev_rec_type = NULL 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("GCL-A","GCL_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GCL_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GCL_rpt_list")].sel_text
	#------------------------------------------------------------



--	DISPLAY "Loading Account - " TO lblabel1 

	DECLARE c_stmtload SCROLL CURSOR FOR 
	SELECT * FROM t_stmtload 
	OPEN c_stmtload 

	WHILE true 
		FETCH NEXT c_stmtload INTO l_stmt_line 
		WHENEVER ERROR GOTO num_error 
		LET l_rec_type = l_stmt_line[1,2] 
		WHENEVER ERROR stop 
		GOTO end_error 
		LABEL num_error: 
		MESSAGE " ** Invalid file FORMAT - Refer ",trim(get_settings_logFile()) 
		SLEEP 2 
		DELETE FROM t_stmthead 
		EXIT WHILE 
		LABEL end_error: 
		IF l_rec_type = 88 THEN 
			#Unexpected RECORD type found in load sequence OR Badly formatted text
			#Program assumes 88 follows 03 OR 16 only.
			#Put out msgs TO REPORT but continue processing - Not a serious error
			LET glob_tot_rows = glob_tot_rows + 1 
			INITIALIZE l_rec_output.* TO NULL 
			LET l_rec_output.rec_type = 0 
			LET l_rec_output.trans3_text = 
			"Unexpected Continuation RECORD (88) OR Too many delimiters - line no. ", glob_tot_rows USING "<<<<<<<<" 
			#---------------------------------------------------------			
			OUTPUT TO REPORT GCL_rpt_list(l_rpt_idx,l_rec_output.*) 
			#---------------------------------------------------------			
			CONTINUE WHILE 
		END IF 
		LET l_valid_sequence = valid_seq(l_rec_type,l_prev_rec_type) 
		IF NOT l_valid_sequence THEN 
			INITIALIZE l_rec_output.* TO NULL 
			LET l_rec_output.rec_type = 0 
			LET l_rec_output.trans3_text = "Invalid BAI sequence - RECORD type ", 
			l_rec_type USING "&&", " loaded AFTER ", 
			l_prev_rec_type USING "&&", 
			" - line no. ", glob_tot_rows USING "<<<<<<<<" 
			#---------------------------------------------------------			
			OUTPUT TO REPORT GCL_rpt_list(l_rpt_idx,l_rec_output.*) 
			#---------------------------------------------------------			


			CALL msgContinue("Invalid BAI sequence","Invalid bai sequence - process Aborted") 
			#DISPLAY "Invalid BAI sequence - Process Aborted" TO lbLabel1
			#sleep 10

			DELETE FROM t_stmthead 
			EXIT WHILE 
		END IF 

		LET l_prev_rec_type = l_rec_type 

		CASE l_rec_type 
			WHEN 01 
				CALL unstr_file_head(l_stmt_line) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = 1 
				LET l_tot_grps = 0 
				LET l_file_tot_amt = 0 
				LET l_file_tot2_amt = 0 
				LET glob_pagehead_date = l_rec_output.trans_date 
				LET glob_pagehead_time = l_rec_output.trans4_text 
				LET glob_pagehead_recv = l_rec_output.trans1_text 
				CONTINUE WHILE 
			WHEN 02 
				CALL unstr_grp_head(l_stmt_line) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_tot_grps = l_tot_grps + 1 
				LET l_tot_accts = 0 
				LET l_grp_tot_amt = 0 
				LET l_grp_tot2_amt = 0 
				LET glob_stmt_date = l_rec_output.trans_date 
				LET glob_pagehead_group = l_rec_output.trans2_text 
				CONTINUE WHILE 
			WHEN 03 
				CALL unstr_acct_head(l_stmt_line) 
				RETURNING l_rec_output.* 
				DISPLAY "" TO lblabel1b 
				DISPLAY l_rec_output.trans2_text TO lblabel1b 

				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_tot_accts = l_tot_accts + 1 
				LET l_acct_tot_amt = l_rec_output.trans1_amt 
				+ l_rec_output.trans2_amt 
				+ l_rec_output.trans3_amt 
				+ l_rec_output.trans4_amt 
				+ l_rec_output.trans5_amt 
				+ l_rec_output.trans6_amt 
				+ l_rec_output.trans7_amt 
				+ l_rec_output.trans8_amt 
				+ l_rec_output.trans9_amt 
				+ l_rec_output.trans10_amt 
				+ l_rec_output.trans11_amt 
				+ l_rec_output.trans12_amt 
				+ l_rec_output.trans13_amt 
				+ l_rec_output.trans14_amt 
				LET l_acct_tot2_amt = l_rec_output.trans1_amt 
				+ l_rec_output.trans2_amt 
				+ l_rec_output.trans3_amt 
				+ l_rec_output.trans4_amt 
				+ l_rec_output.trans5_amt 
				+ l_rec_output.trans6_amt 
				+ l_rec_output.trans7_amt 
				+ l_rec_output.trans8_amt 
				+ l_rec_output.trans9_amt 
			WHEN 16 
				CALL unstr_acct_detl(l_stmt_line,p_type_code) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_acct_tot_amt = l_acct_tot_amt 
				+ l_rec_output.trans1_amt 
				LET l_acct_tot2_amt = l_acct_tot2_amt 
				+ l_rec_output.trans1_amt 
			WHEN 49 
				CALL unstr_acct_trail(l_stmt_line) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_grp_tot_amt = l_grp_tot_amt 
				+ l_acct_tot_amt 
				LET l_grp_tot2_amt = l_grp_tot2_amt 
				+ l_acct_tot2_amt 
				LET l_rec_output.trans2_amt = l_acct_tot_amt 
				LET l_rec_output.trans7_amt = l_acct_tot2_amt 
				IF l_rec_output.trans1_amt != l_acct_tot_amt THEN 
					LET l_rec_output.trans3_text = 
					"*** Computed total does NOT equal Account total - i" 
				END IF 
				IF l_rec_output.trans6_amt != l_acct_tot2_amt THEN 
					LET l_rec_output.trans3_text = 
					"*** Computed total does NOT equal Account total - ii" 
				END IF 
			WHEN 98 
				CALL unstr_grp_trail(l_stmt_line) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = glob_tot_rows + 1 
				LET l_file_tot_amt = l_file_tot_amt 
				+ l_grp_tot_amt 
				LET l_file_tot2_amt = l_file_tot2_amt 
				+ l_grp_tot2_amt 
				LET l_rec_output.trans2_amt = l_grp_tot_amt 
				LET l_rec_output.trans7_amt = l_grp_tot2_amt 
				LET l_rec_output.trans2_num = l_tot_accts 
				IF l_rec_output.trans1_amt != l_grp_tot_amt 
				OR l_rec_output.trans6_amt != l_grp_tot2_amt 
				OR l_rec_output.trans1_num != l_tot_accts THEN 
					LET l_rec_output.trans3_text = 
					"*** Computed total does NOT equal Group total" 
				ELSE 
					LET l_rec_output.trans3_text = 
					" *** Bank Group IS in balance" 
				END IF 
			WHEN 99 
				CALL unstr_file_trail(l_stmt_line) 
				RETURNING l_rec_output.* 
				LET glob_tot_rows = glob_tot_rows + 1 
				IF l_rec_output.trans1_amt != l_file_tot_amt 
				OR l_rec_output.trans6_amt != l_file_tot2_amt 
				OR l_rec_output.trans1_num != l_tot_grps 
				OR l_rec_output.trans2_num != glob_tot_rows THEN 
					LET l_rec_output.trans4_amt = l_file_tot_amt 
					LET l_rec_output.trans7_amt = l_file_tot2_amt 
					LET l_rec_output.trans4_num = l_tot_grps 
					LET l_rec_output.trans5_num = glob_tot_rows 
					LET l_rec_output.trans3_text = 
					"*** Computed total does NOT equal File total" 
					#---------------------------------------------------------			
					OUTPUT TO REPORT GCL_rpt_list(l_rpt_idx,l_rec_output.*) 
					#---------------------------------------------------------			



					ERROR "Errors detected" 
					CALL msgContinue("Errors Detected","Errors Detected") 
					#DISPLAY "" AT 1,1
					#DISPLAY "Errors Detected" AT 1,12
					#sleep 5
					DELETE FROM t_stmthead 
				END IF 
				#There should NEVER be anything AFTER #99 records
				FETCH NEXT c_stmtload INTO l_stmt_line 
				IF status != NOTFOUND THEN 
					ERROR "Error detected" 
					CALL msgContinue("Errors Detected","Errors Detected") 
					#DISPLAY "" AT 1,1
					#DISPLAY "Error Detected" AT 1,12
					CALL errorlog("GCL - TWO File Headers****************** ") 
					#sleep 5
					DELETE FROM t_stmthead 
				END IF 
				EXIT WHILE 
		END CASE 

		#---------------------------------------------------------			
		OUTPUT TO REPORT GCL_rpt_list(l_rpt_idx,l_rec_output.*) 
		#---------------------------------------------------------			

	END WHILE 



	#------------------------------------------------------------
	FINISH REPORT GCL_rpt_list
	CALL rpt_finish("GCL_rpt_list")
	#------------------------------------------------------------
	 
END FUNCTION 



############################################################
# FUNCTION unstr_file_head(p_stmt_line)
#
#
############################################################
FUNCTION unstr_file_head(p_stmt_line) 
	DEFINE p_stmt_line STRING --char(512) 
	DEFINE l_rec_output RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_date char(6) 
	DEFINE l_time char(5) 

	#Rectype 01
	#Header has fixed no of columns with fixed length
	INITIALIZE l_rec_output.* TO NULL 
	LET l_rec_output.rec_type = p_stmt_line[1,2] 
	LET l_rec_output.trans1_text = p_stmt_line[5,8] 
	LET l_date[1,2] = p_stmt_line[14,15] 
	LET l_date[3,4] = p_stmt_line[12,13] 
	LET l_date[5,6] = p_stmt_line[10,11] 
	LET l_rec_output.trans_date = l_date 
	LET l_time[1,2] = p_stmt_line[17,18] 
	LET l_time[3] = ":" 
	LET l_time[4,5] = p_stmt_line[19,20] 
	LET l_rec_output.trans4_text = l_time 
	RETURN l_rec_output.* 
END FUNCTION 


############################################################
# FUNCTION unstr_grp_head(p_stmt_line)
#
#
############################################################
FUNCTION unstr_grp_head(p_stmt_line) 
	DEFINE p_stmt_line char(512) 
	DEFINE l_rec_output RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_date char(6) 
	DEFINE l_temp_date char(6) 

	#Rectype 02
	INITIALIZE l_rec_output.* TO NULL 
	LET l_rec_output.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output.trans1_text = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output.trans2_text = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_temp_date = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_date[1,2] = l_temp_date[5,6] 
	LET l_date[3,4] = l_temp_date[3,4] 
	LET l_date[5,6] = l_temp_date[1,2] 
	LET l_rec_output.trans_date = l_date 

	RETURN l_rec_output.* 
END FUNCTION 


############################################################
# FUNCTION unstr_acct_head(p_stmt_line)
#
#
############################################################
FUNCTION unstr_acct_head(p_stmt_line) 
	DEFINE p_stmt_line STRING --char(512)
 
	DEFINE l_temp_line STRING --char(512) 
	DEFINE l_rec_output_rec RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_kandoo_sheet_num SMALLINT
	DEFINE l_start_pos SMALLINT
	DEFINE l_end_pos SMALLINT
	DEFINE l_comma_cnt SMALLINT
	DEFINE l_date,l_temp_date char(6) 
	DEFINE l_arr_header array[14] OF RECORD 
		trans_num INTEGER, 
		trans_amt decimal(16,2) 
	END RECORD 
	DEFINE l_last_pos SMALLINT 
	DEFINE l_expect_trans_num SMALLINT 
	DEFINE l_next_field SMALLINT 

	#Rectype 03
	INITIALIZE l_rec_output_rec.* TO NULL 
	LET l_rec_output_rec.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output_rec.trans2_text = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output_rec.trans1_text = p_stmt_line[l_start_pos,l_end_pos] 
	##
	## major restructure required.  Previous file layout had a
	## maximum of one type 88 (continuation) AFTER a type 03 AND the line
	## break was always AFTER a transaction amount.  New layout (as per
	## test sample) can have many continuation lines AND the break can occur
	## AFTER any field (number OR amount).  New code assumes that the
	## account number AND currency code will always fit on the 03 record
	## AND that there are exactly 14 pairs of transaction number AND amount
	## fields on the 03 AND the following 88 records.  The program unstrings
	## the transactions AND amounts, reading new records each time the last
	## field on the current RECORD IS encountered.  Unstringing stops either
	## WHEN all 14 pairs of fields have been read OR the next RECORD IS NOT
	## a continuation record.  IF the program does NOT read the expected
	## number of transaction/amount fields, the CURSOR IS repositioned on
	## the last RECORD processed, TO force a FORMAT sequence error.
	##

	INITIALIZE l_arr_header[14].* TO NULL 
	LET l_next_field = 1 
	LET l_expect_trans_num = true 
	LET l_last_pos = length(p_stmt_line) - 1 
	LET l_start_pos = l_end_pos + 2 

	WHILE (true) 
		WHILE (l_start_pos < l_last_pos) # unstring until END OF line 
			IF l_next_field > 14 THEN 
				## this should never happen (unless the FORMAT changes)
				EXIT WHILE 
			END IF 
			LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
			IF l_expect_trans_num THEN 
				LET l_arr_header[l_next_field].trans_num = 
				p_stmt_line[l_start_pos,l_end_pos] 
				LET l_expect_trans_num = false 
				LET l_start_pos = l_end_pos + 2 
			ELSE 
				IF p_stmt_line[l_end_pos] = "-" THEN 
					LET l_arr_header[l_next_field].trans_amt = 
					p_stmt_line[l_start_pos,l_end_pos-1] 
					LET l_arr_header[l_next_field].trans_amt = 
					l_arr_header[l_next_field].trans_amt / -100 
				ELSE 
					LET l_arr_header[l_next_field].trans_amt = 
					p_stmt_line[l_start_pos,l_end_pos] 
					LET l_arr_header[l_next_field].trans_amt = 
					l_arr_header[l_next_field].trans_amt / 100 
				END IF 
				LET l_expect_trans_num = true 
				LET l_start_pos = l_end_pos + 2 
				LET l_next_field = l_next_field + 1 
			END IF 
		END WHILE 
		IF l_next_field > 14 THEN 
			EXIT WHILE ## LAST OF the account HEADER fields has been read 
		END IF 
		# read the next RECORD FOR the remaining header fields
		FETCH NEXT c_stmtload INTO l_temp_line 
		IF l_temp_line[1,2] = '88' THEN 
			LET p_stmt_line = l_temp_line 
			LET glob_tot_rows = glob_tot_rows + 1 
			LET l_last_pos = length(p_stmt_line) - 1 
			LET l_start_pos = 4 
		ELSE 
			FETCH previous c_stmtload INTO l_temp_line 
			EXIT WHILE 
		END IF 
	END WHILE 
	
	LET l_rec_output_rec.trans1_num = l_arr_header[1].trans_num 
	LET l_rec_output_rec.trans1_amt = l_arr_header[1].trans_amt 
	LET l_rec_output_rec.trans2_num = l_arr_header[2].trans_num 
	LET l_rec_output_rec.trans2_amt = l_arr_header[2].trans_amt 
	LET l_rec_output_rec.trans3_num = l_arr_header[3].trans_num 
	LET l_rec_output_rec.trans3_amt = l_arr_header[3].trans_amt 
	LET l_rec_output_rec.trans4_num = l_arr_header[4].trans_num 
	LET l_rec_output_rec.trans4_amt = l_arr_header[4].trans_amt 
	LET l_rec_output_rec.trans5_num = l_arr_header[5].trans_num 
	LET l_rec_output_rec.trans5_amt = l_arr_header[5].trans_amt 
	LET l_rec_output_rec.trans6_num = l_arr_header[6].trans_num 
	LET l_rec_output_rec.trans6_amt = l_arr_header[6].trans_amt 
	LET l_rec_output_rec.trans7_num = l_arr_header[7].trans_num 
	LET l_rec_output_rec.trans7_amt = l_arr_header[7].trans_amt 
	LET l_rec_output_rec.trans8_num = l_arr_header[8].trans_num 
	LET l_rec_output_rec.trans8_amt = l_arr_header[8].trans_amt 
	LET l_rec_output_rec.trans9_num = l_arr_header[9].trans_num 
	LET l_rec_output_rec.trans9_amt = l_arr_header[9].trans_amt 
	LET l_rec_output_rec.trans10_num = l_arr_header[10].trans_num 
	LET l_rec_output_rec.trans10_amt = l_arr_header[10].trans_amt 
	LET l_rec_output_rec.trans11_num = l_arr_header[11].trans_num 
	LET l_rec_output_rec.trans11_amt = l_arr_header[11].trans_amt 
	LET l_rec_output_rec.trans12_num = l_arr_header[12].trans_num 
	LET l_rec_output_rec.trans12_amt = l_arr_header[12].trans_amt 
	LET l_rec_output_rec.trans13_num = l_arr_header[13].trans_num 
	LET l_rec_output_rec.trans13_amt = l_arr_header[13].trans_amt 
	LET l_rec_output_rec.trans14_num = l_arr_header[14].trans_num 
	LET l_rec_output_rec.trans14_amt = l_arr_header[14].trans_amt 

	INITIALIZE modu_rec_stmthead.* TO NULL 
	LET glob_bank_code = NULL 
	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND iban = l_rec_output_rec.trans2_text 
	AND currency_code = l_rec_output_rec.trans1_text 

	IF status = NOTFOUND THEN 
		LET l_rec_output_rec.trans3_text = "** Not on File **" 
	ELSE 
		LET glob_bank_code = l_rec_bank.bank_code 
		SELECT unique 1 FROM bankstatement 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_bank_code 
		AND tran_date = glob_stmt_date 
		AND entry_type_code = "SH" 
		IF status != NOTFOUND THEN 
			LET glob_bank_code = NULL 
			LET l_rec_output_rec.trans3_text = "** Already Loaded **" 
		ELSE 
			LET l_kandoo_sheet_num = NULL 
			SELECT max(sheet_num) INTO l_kandoo_sheet_num FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_bank_code 
			AND entry_type_code = "SH" 
			IF l_kandoo_sheet_num IS NULL THEN 
				LET modu_rec_stmthead.sheet_num = 1 
			ELSE 
				SELECT tran_date INTO modu_rec_stmthead.tran_date FROM bankstatement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_bank_code 
				AND entry_type_code = "SH" 
				AND sheet_num = l_kandoo_sheet_num 
				AND seq_num = 0 
				IF modu_rec_stmthead.tran_date > glob_stmt_date THEN 
					LET glob_bank_code = NULL 
					LET l_rec_output_rec.trans3_text = "* Stmt Date out of sequence *" 
				ELSE 
					LET modu_rec_stmthead.sheet_num = l_kandoo_sheet_num + 1 
				END IF 
			END IF 
		END IF 
	END IF 

	IF glob_bank_code IS NOT NULL THEN 
		LET modu_rec_stmthead.bank_code = glob_bank_code 
		LET modu_rec_stmthead.seq_num = 0 
		LET modu_rec_stmthead.entry_type_code = "SH" 
		LET modu_rec_stmthead.bank_currency_code = l_rec_bank.currency_code 
		LET modu_rec_stmthead.acct_code = l_rec_bank.acct_code 
		LET modu_rec_stmthead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			l_rec_bank.currency_code, 
			glob_stmt_date, 
			CASH_EXCHANGE_BUY)
			 
		LET modu_rec_stmthead.tran_date = glob_stmt_date 
		LET modu_rec_stmthead.tran_amt = l_rec_output_rec.trans1_amt 
		LET modu_rec_stmthead.desc_text = "Statement header" 
		LET modu_rec_stmthead.doc_num = 0 
		##
		## This next line should be changed IF a site ever wishes TO use
		## multi-company with the NAB statement load.(refer Westpac FOR eg)
		LET modu_rec_stmthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		##
		INSERT INTO t_stmthead VALUES (modu_rec_stmthead.*) 
	END IF 

	## Reset the CURSOR one line back IF fewer THEN the expected
	## number of header fields was read.  This will force a sequence
	## error AND suppress the statement load FOR the account
	IF l_next_field <= 14 THEN 
		FETCH previous c_stmtload INTO l_temp_line 
	END IF 
	RETURN l_rec_output_rec.* 
END FUNCTION 


############################################################
# FUNCTION unstr_acct_detl(p_stmt_line,p_type_code)
#
#
############################################################
FUNCTION unstr_acct_detl(p_stmt_line,p_type_code) 
	DEFINE p_stmt_line char(512) 
	DEFINE p_type_code LIKE banktype.type_code 
	DEFINE l_temp_line char(512) 
	DEFINE l_output_rec RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_comma_cnt SMALLINT 
	DEFINE l_date char(6) 
	DEFINE l_temp_date char(6) 

	#Rectype 16
	INITIALIZE l_output_rec.* TO NULL 
	LET l_output_rec.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_output_rec.trans1_num = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_end_pos] = "-" THEN 
		LET l_output_rec.trans1_amt = p_stmt_line[l_start_pos,l_end_pos-1] 
		LET l_output_rec.trans1_amt = l_output_rec.trans1_amt / -100 
	ELSE 
		LET l_output_rec.trans1_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_output_rec.trans1_amt = l_output_rec.trans1_amt / 100 
	END IF 
	#
	#Get Transaction Type
	LET l_output_rec.trans1_text = get_trans_type(l_output_rec.trans1_num, 
	p_type_code) 
	#
	#Reference IS optional OR possibly an 88 RECORD type follows...
	LET l_start_pos = l_end_pos + 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF l_end_pos >= l_start_pos THEN 
		LET l_output_rec.trans2_text = p_stmt_line[l_start_pos,l_end_pos] 
	END IF 
	#
	#Description IS optional OR possibly an 88 RECORD type follows...
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF l_end_pos >= l_start_pos THEN 
		LET l_output_rec.trans3_text = p_stmt_line[l_start_pos,l_end_pos] 
	END IF 
	#
	#Attempt Reconciliations
	LET l_output_rec.trans4_text = "N" 
	IF glob_bank_code IS NOT NULL THEN 
		LET modu_rec_stmthead.doc_num = 0 
		LET modu_rec_stmthead.ref_code = NULL 
		LET modu_rec_stmthead.desc_text = NULL 
		IF l_output_rec.trans1_text[1,2] = "CH" THEN 
			CALL recon_cheques(l_output_rec.*) 
			RETURNING modu_rec_stmthead.doc_num, 
			modu_rec_stmthead.ref_code, 
			l_output_rec.* 
			IF l_output_rec.trans3_text[1,30] IS NULL THEN 
				LET l_output_rec.trans4_text = "Y" 
			END IF 
		END IF 
		IF l_output_rec.trans1_text[1,2] = "BD" THEN 
			CALL recon_deposits(l_output_rec.*) 
			RETURNING modu_rec_stmthead.doc_num, 
			l_output_rec.* 
			IF l_output_rec.trans3_text[1,30] IS NULL THEN 
				LET l_output_rec.trans4_text = "Y" 
			END IF 
		END IF 
		LET modu_rec_stmthead.seq_num = modu_rec_stmthead.seq_num + 1 
		LET modu_rec_stmthead.entry_type_code = l_output_rec.trans1_text[1,2] 
		LET modu_rec_stmthead.tran_amt = l_output_rec.trans1_amt 
		LET modu_rec_stmthead.desc_text = l_output_rec.trans3_text[1,30] 
		##
		## This next line should be changed IF a site ever wishes TO use
		## multi-company with the NAB statement load.(refer Westpac FOR eg)
		LET modu_rec_stmthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		##
		INSERT INTO t_stmthead VALUES (modu_rec_stmthead.*) 
	END IF 
	#
	#Check FOR RECORD type 88
	#Allow FOR multiple 88's AND do NOT validate contents
	WHILE true 
		FETCH NEXT c_stmtload INTO l_temp_line 
		IF l_temp_line[1,2] != 88 THEN 
			FETCH previous c_stmtload INTO l_temp_line 
			RETURN l_output_rec.* 
		END IF 
		LET glob_tot_rows = glob_tot_rows + 1 
	END WHILE 
	RETURN l_output_rec.* 
END FUNCTION 



############################################################
# FUNCTION get_trans_type(p_trans_code_num,p_type_code)
#
#
############################################################
FUNCTION get_trans_type(p_trans_code_num,p_type_code) 
	DEFINE p_trans_code_num char(10) 
	DEFINE p_type_code LIKE banktypedetl.type_code 
	DEFINE l_trans_type char(2) 

	SELECT max_ref_code INTO l_trans_type FROM banktypedetl 
	WHERE type_code = p_type_code 
	AND bank_ref_code = p_trans_code_num 
	IF status = NOTFOUND THEN 
		LET l_trans_type = "**" 
	END IF 
	RETURN l_trans_type 
END FUNCTION 



############################################################
# FUNCTION unstr_acct_trail(p_stmt_line)
#
#
############################################################
FUNCTION unstr_acct_trail(p_stmt_line) 
	DEFINE p_stmt_line char(512) 
	DEFINE l_rec_output	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 

	#Rectype 49
	INITIALIZE l_rec_output.* TO NULL 
	LET l_rec_output.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_start_pos] = "-" THEN 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos+1,l_end_pos] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / -100 
	ELSE 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / 100 
	END IF 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_start_pos] = "-" THEN 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos+1,l_end_pos] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / -100 
	ELSE 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / 100 
	END IF 
	RETURN l_rec_output.* 
END FUNCTION 


############################################################
# FUNCTION unstr_grp_trail(p_stmt_line)
#
#
############################################################
FUNCTION unstr_grp_trail(p_stmt_line) 
	DEFINE p_stmt_line char(512) 
	DEFINE l_rec_output 
	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 

	#Rectype 98
	INITIALIZE l_rec_output.* TO NULL 
	LET l_rec_output.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_end_pos] = "-" THEN 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos,l_end_pos-1] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / -100 
	ELSE 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / 100 
	END IF 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output.trans1_num = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_end_pos] = "-" THEN 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos,l_end_pos-1] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / -100 
	ELSE 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / 100 
	END IF 
	RETURN l_rec_output.* 
END FUNCTION 


############################################################
# FUNCTION unstr_file_trail(p_stmt_line)
#
#
############################################################
FUNCTION unstr_file_trail(p_stmt_line) 
	DEFINE p_stmt_line char(512) 
	DEFINE l_rec_output 
	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 

	#Rectype 99
	INITIALIZE l_rec_output.* TO NULL 
	LET l_rec_output.rec_type = p_stmt_line[1,2] 
	LET l_start_pos = 4 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_end_pos] = "-" THEN 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos,l_end_pos-1] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / -100 
	ELSE 
		LET l_rec_output.trans1_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans1_amt = l_rec_output.trans1_amt / 100 
	END IF 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output.trans1_num = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	LET l_rec_output.trans2_num = p_stmt_line[l_start_pos,l_end_pos] 
	LET l_start_pos = l_end_pos + 2 
	LET l_end_pos = unstring(l_start_pos,p_stmt_line) 
	IF p_stmt_line[l_end_pos] = "-" THEN 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos,l_end_pos-1] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / -100 
	ELSE 
		LET l_rec_output.trans6_amt = p_stmt_line[l_start_pos,l_end_pos] 
		LET l_rec_output.trans6_amt = l_rec_output.trans6_amt / 100 
	END IF 
	RETURN l_rec_output.* 
END FUNCTION 


############################################################
# FUNCTION unstring(p_start_pos,p_stmt_line)
#
#
############################################################
FUNCTION unstring(p_start_pos,p_stmt_line) 
	DEFINE p_start_pos SMALLINT 
	DEFINE p_stmt_line char(512) 
	DEFINE i SMALLINT 
	DEFINE l_line_length SMALLINT 
	DEFINE l_char_cnt SMALLINT 

	LET l_char_cnt = 0 
	LET l_line_length = length(p_stmt_line) 
	FOR i = p_start_pos TO l_line_length 
		IF p_stmt_line[i] = "," 
		OR p_stmt_line[i] = "/" THEN 
			EXIT FOR 
		ELSE 
			LET l_char_cnt = l_char_cnt + 1 
		END IF 
	END FOR 
	LET l_char_cnt = l_char_cnt 
	+ p_start_pos 
	- 1 
	RETURN l_char_cnt 
END FUNCTION 


############################################################
# FUNCTION unstring2(p_start_pos,p_stmt_line)
#
#
############################################################
FUNCTION unstring2(p_start_pos,p_stmt_line) 
	DEFINE p_start_pos SMALLINT 
	DEFINE p_stmt_line char(512) 
	DEFINE l_i SMALLINT 
	DEFINE l_line_length SMALLINT 
	DEFINE l_char_cnt SMALLINT 


	LET l_char_cnt = 0 
	LET l_line_length = length(p_stmt_line) 
	FOR l_i = p_start_pos TO l_line_length 
		IF p_stmt_line[l_i] = "," THEN 
			EXIT FOR 
		ELSE 
			LET l_char_cnt = l_char_cnt + 1 
		END IF 
	END FOR 
	LET l_char_cnt = l_char_cnt 
	+ p_start_pos 
	- 1 
	RETURN l_char_cnt 
END FUNCTION 


############################################################
# FUNCTION count_commas(p_start_pos,p_temp_line)
#
#
############################################################
FUNCTION count_commas(p_start_pos,p_temp_line) 
	DEFINE p_start_pos SMALLINT 
	DEFINE p_temp_line char(512) 
	DEFINE l_i SMALLINT 
	DEFINE l_comma_cnt SMALLINT 

	LET l_comma_cnt = 0 
	FOR l_i = p_start_pos TO length(p_temp_line) 
		IF p_temp_line[l_i] = "," THEN 
			LET l_comma_cnt = l_comma_cnt + 1 
		END IF 
	END FOR 

	RETURN l_comma_cnt 
END FUNCTION 


############################################################
# FUNCTION valid_seq(p_rec_type, p_prev_rec_type)
#
#
############################################################
FUNCTION valid_seq(p_rec_type, p_prev_rec_type) 
	DEFINE p_rec_type SMALLINT 
	DEFINE p_prev_rec_type SMALLINT 
	DEFINE l_valid_ind SMALLINT 

	CASE p_rec_type 
		WHEN 01 
			IF p_prev_rec_type IS NULL THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 02 
			IF p_prev_rec_type = 01 
			OR p_prev_rec_type = 98 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 03 
			IF p_prev_rec_type = 02 
			OR p_prev_rec_type = 49 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 16 
			IF p_prev_rec_type = 03 
			OR p_prev_rec_type = 16 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 49 
			IF p_prev_rec_type = 03 
			OR p_prev_rec_type = 16 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 98 
			IF p_prev_rec_type = 49 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
		WHEN 99 
			IF p_prev_rec_type = 98 THEN 
				LET l_valid_ind = true 
			ELSE 
				LET l_valid_ind = false 
			END IF 
	END CASE 
	RETURN l_valid_ind 
END FUNCTION 



############################################################
# FUNCTION recon_cheques(p_rec_output)
#
#
############################################################
FUNCTION recon_cheques(p_rec_output) 
	DEFINE p_rec_output RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 

	LET p_rec_output.trans3_text = NULL 
	WHENEVER ERROR GOTO num_error 
	LET l_rec_cheque.cheq_code = p_rec_output.trans2_text[1,8] 
	WHENEVER ERROR stop 
	GOTO end_error 
	LABEL num_error: 
	LET p_rec_output.trans3_text = "Cheque Code IS NOT numeric" 
	LET l_rec_cheque.cheq_code = 0 
	WHENEVER ERROR stop 
	RETURN l_rec_cheque.doc_num,l_rec_cheque.cheq_code,p_rec_output.* 
	LABEL end_error: 
	SELECT cheque.* INTO l_rec_cheque.* FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheq_code = l_rec_cheque.cheq_code 
	AND bank_code = modu_rec_stmthead.bank_code 
	AND pay_meth_ind = "1" 

	CASE 
		WHEN status = NOTFOUND 
			LET p_rec_output.trans3_text = 
			"Cheque Code does NOT exist" 
		WHEN l_rec_cheque.currency_code != modu_rec_stmthead.bank_currency_code AND 
			modu_rec_stmthead.bank_currency_code != glob_rec_glparms.base_currency_code 
			LET p_rec_output.trans3_text = 
			"Currency of Cheque IS Invalid FOR this bank" 
		WHEN l_rec_cheque.currency_code = modu_rec_stmthead.bank_currency_code AND 
			l_rec_cheque.net_pay_amt != p_rec_output.trans1_amt 
			LET p_rec_output.trans3_text = 
			"Cheque Amount does NOT match entry" 
		WHEN l_rec_cheque.cheq_date > modu_rec_stmthead.tran_date 
			LET p_rec_output.trans3_text = 
			" Cheque No. ",l_rec_cheque.cheq_code USING "<<<<<<<<<", 
			" cannot be presented before ", 
			l_rec_cheque.cheq_date USING "dd mmm yy"," " 
		WHEN l_rec_cheque.recon_flag = "Y" 
			LET p_rec_output.trans3_text = 
			"Cheque IS already reconciled" 
		WHEN l_rec_cheque.part_recon_flag = "Y" AND 
			l_rec_cheque.rec_state_num != modu_rec_stmthead.sheet_num 
			LET p_rec_output.trans3_text = 
			"Cheque has been reconciled on Another statement" 
		WHEN l_rec_cheque.currency_code != modu_rec_stmthead.bank_currency_code AND 
			modu_rec_stmthead.bank_currency_code = glob_rec_glparms.base_currency_code 
			LET l_rec_cheque.net_pay_amt = l_rec_cheque.net_pay_amt 
			/ l_rec_cheque.conv_qty 
			IF p_rec_output.trans1_amt != l_rec_cheque.net_pay_amt THEN 
				LET p_rec_output.trans3_text = 
				"Cheque Amount IS Invalid FOR this bank" 
			END IF 
	END CASE 

	IF p_rec_output.trans3_text IS NOT NULL THEN 
		LET l_rec_cheque.doc_num = 0 
	END IF 

	RETURN l_rec_cheque.doc_num,l_rec_cheque.cheq_code,p_rec_output.* 
END FUNCTION 



############################################################
# FUNCTION recon_deposits(p_rec_output_rec)
#
#
############################################################
FUNCTION recon_deposits(p_rec_output_rec) 
	DEFINE p_rec_output_rec	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_rec_banking RECORD LIKE banking.* 

	LET p_rec_output_rec.trans3_text = NULL 
	LET l_rec_banking.doc_num = 0 
	DECLARE c1_banking CURSOR FOR 
	SELECT banking.* FROM banking 
	WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
	AND bk_acct = modu_rec_stmthead.acct_code 
	AND bk_type = "CD" 
	AND bk_bankdt = modu_rec_stmthead.tran_date 
	AND bk_cred = p_rec_output_rec.trans1_amt 
	OPEN c1_banking 
	FETCH c1_banking INTO l_rec_banking.* 
	CASE 
		WHEN status = NOTFOUND 
			LET p_rec_output_rec.trans3_text = "Bank Deposit does NOT exist" 
		WHEN l_rec_banking.bk_rec_part = "Y" 
			LET p_rec_output_rec.trans3_text = "Bank Deposit IS already reconciled" 
		WHEN l_rec_banking.bk_sh_no IS NOT NULL 
			LET p_rec_output_rec.trans3_text = "Bank Deposit IS already reconciled" 
		OTHERWISE 
			EXIT CASE 
	END CASE 
	IF p_rec_output_rec.trans3_text IS NOT NULL THEN 
		LET l_rec_banking.doc_num = 0 
	END IF 
	RETURN l_rec_banking.doc_num,p_rec_output_rec.* 
END FUNCTION 


############################################################
# REPORT GCL_rpt_list(p_rec_output)
#
#
############################################################
REPORT GCL_rpt_list(p_rpt_idx,p_rec_output) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_output	RECORD 
		rec_type SMALLINT, 
		trans1_text char(4), 
		trans2_text char(30), 
		trans3_text char(70), 
		trans4_text char(5), 
		trans_date DATE, 
		trans1_num INTEGER, 
		trans1_amt decimal(16,2), 
		trans2_num INTEGER, 
		trans2_amt decimal(16,2), 
		trans3_num INTEGER, 
		trans3_amt decimal(16,2), 
		trans4_num INTEGER, 
		trans4_amt decimal(16,2), 
		trans5_num INTEGER, 
		trans5_amt decimal(16,2), 
		trans6_num INTEGER, 
		trans6_amt decimal(16,2), 
		trans7_num INTEGER, 
		trans7_amt decimal(16,2), 
		trans8_num INTEGER, 
		trans8_amt decimal(16,2), 
		trans9_num INTEGER, 
		trans9_amt decimal(16,2), 
		trans10_num INTEGER, 
		trans10_amt decimal(16,2), 
		trans11_num INTEGER, 
		trans11_amt decimal(16,2), 
		trans12_num INTEGER, 
		trans12_amt decimal(16,2), 
		trans13_num INTEGER, 
		trans13_amt decimal(16,2), 
		trans14_num INTEGER, 
		trans14_amt decimal(16,2) 
	END RECORD 
	DEFINE l_cmpy_head char(80) 
	#	DEFINE l_i SMALLINT
	#	DEFINE l_x SMALLINT
	#	DEFINE l_y SMALLINT
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_head_reqd SMALLINT 

	OUTPUT 
	--left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Created - ", 
			COLUMN 12, glob_pagehead_date USING "DD MMM yyyy", 
			COLUMN 24, glob_pagehead_time, 
			COLUMN 57," Receiver Code: ", 
			COLUMN 73, glob_pagehead_recv 
			PRINT COLUMN 01,"Group - ", 
			COLUMN 12, glob_pagehead_group clipped, 
			COLUMN 57,"Statement Date: ", 
			COLUMN 73, glob_stmt_date USING "dd/mm/yy" 
			SKIP 1 line 
			LET l_head_reqd = true
			 
		ON EVERY ROW 
			CASE p_rec_output.rec_type 
				WHEN 00 
					#some sort of error has occured on previously printed line
					PRINT COLUMN 06, p_rec_output.trans3_text 
				WHEN 03 
					NEED 20 LINES #req'd TO force PAGE headings 
					PRINT COLUMN 01,"Account - ", 
					COLUMN 12, p_rec_output.trans2_text clipped, 
					COLUMN 30,"Closing Bal: ", 
					COLUMN 43, p_rec_output.trans1_amt USING "---------&.&&" 
					PRINT COLUMN 01,"Currency - ", 
					COLUMN 12, p_rec_output.trans1_text clipped, 
					COLUMN 34,"Credits: ", 
					COLUMN 43, p_rec_output.trans2_amt USING "---------&.&&", 
					COLUMN 62,"Transactions: ", 
					COLUMN 76, p_rec_output.trans3_amt USING "----&" 
					PRINT COLUMN 01,p_rec_output.trans3_text[1,30], 
					COLUMN 35,"Debits: ", 
					COLUMN 43, p_rec_output.trans4_amt USING "---------&.&&", 
					COLUMN 62,"Transactions: ", 
					COLUMN 76, p_rec_output.trans5_amt USING "----&" 
					PRINT COLUMN 01,"----------------------------------------", 
					"----------------------------------------" 
					PRINT COLUMN 01,"Type", 
					COLUMN 06,"Trans ", 
					COLUMN 16,"Amount", 
					COLUMN 23,"Reference", 
					COLUMN 33,"Rec", 
					COLUMN 37,"Text" 
					PRINT COLUMN 06,"Code" 
					PRINT COLUMN 01,"----------------------------------------", 
					"----------------------------------------" 
					LET l_head_reqd = false 
				WHEN 16 
					NEED 3 LINES 
					IF l_head_reqd THEN 
						LET l_head_reqd = false 
						PRINT COLUMN 01,"----------------------------------------", 
						"----------------------------------------" 
						PRINT COLUMN 01,"Type", 
						COLUMN 06,"Trans ", 
						COLUMN 16,"Amount", 
						COLUMN 23,"Reference", 
						COLUMN 33,"Rec", 
						COLUMN 37,"Text" 
						PRINT COLUMN 06,"Code" 
						PRINT COLUMN 01,"----------------------------------------", 
						"----------------------------------------" 
					END IF 
					PRINT COLUMN 02, p_rec_output.trans1_text clipped, 
					COLUMN 07, p_rec_output.trans1_num USING "&&&", 
					COLUMN 11, p_rec_output.trans1_amt USING "-------&.&&", 
					COLUMN 23, p_rec_output.trans2_text[1,8], 
					COLUMN 34, p_rec_output.trans4_text[1,1], 
					COLUMN 37, p_rec_output.trans3_text clipped 
				WHEN 49 
					IF p_rec_output.trans3_text IS NOT NULL THEN 
						NEED 8 LINES 
						SKIP 1 line 
						PRINT COLUMN 01, "GROUP a" 
						PRINT COLUMN 11, "Acc total:", 
						COLUMN 21, p_rec_output.trans1_amt USING "-------&.&&", 
						COLUMN 40, "Computed total:", 
						COLUMN 56, p_rec_output.trans2_amt USING "-------&.&&" 
						PRINT COLUMN 01, "GROUP b" 
						PRINT COLUMN 11, "Acc total:", 
						COLUMN 21, p_rec_output.trans6_amt USING "-------&.&&", 
						COLUMN 40, "Computed total:", 
						COLUMN 56, p_rec_output.trans7_amt USING "-------&.&&" 
						SKIP 1 line 
						PRINT COLUMN 06, p_rec_output.trans3_text 
						# => Computed total does NOT equal Account total
					END IF 
					SKIP TO top OF PAGE 
				WHEN 98 
					PRINT COLUMN 01,"----------------------------------------", 
					"----------------------------------------" 
					SKIP 5 LINES 
					PRINT COLUMN 1,"GROUP a" 
					PRINT COLUMN 8,"Bank Group Total FOR ", 
					glob_pagehead_group clipped,": ", 
					p_rec_output.trans1_amt USING "--------&.&&", 
					COLUMN 57, "No of accts:", 
					COLUMN 69, p_rec_output.trans1_num USING "####&" 
					PRINT COLUMN 8,"Bank Group Total FOR ", 
					glob_pagehead_group clipped,": ", 
					p_rec_output.trans6_amt USING "--------&.&&" 
					SKIP 1 line 
					PRINT COLUMN 1,"GROUP b" 
					PRINT COLUMN 10,"Computed Total FOR ", 
					glob_pagehead_group clipped,": ", 
					p_rec_output.trans2_amt USING "--------&.&&", 
					COLUMN 57, "No of accts:", 
					COLUMN 69, p_rec_output.trans2_num USING "####&" 
					PRINT COLUMN 10,"Computed Total FOR ", 
					glob_pagehead_group clipped,": ", 
					p_rec_output.trans7_amt USING "--------&.&&" 
					SKIP 2 line 
					PRINT COLUMN 13, p_rec_output.trans3_text 
					# => Computed total does NOT equal Group total
					# => Bank group IS in BALANCE
					SKIP 30 LINES #(req'd TO get CLOSE TO eop but NOT past it) 
				WHEN 99 
					IF p_rec_output.trans3_text IS NOT NULL THEN 
						SKIP TO top OF PAGE 
						PRINT COLUMN 01,"----------------------------------------", 
						"----------------------------------------" 
						SKIP 5 LINES 
						PRINT COLUMN 01,"Interface file total:", 
						COLUMN 22, p_rec_output.trans1_amt USING "--------&.&&", 
						COLUMN 37, "Bank groups:", 
						COLUMN 50, p_rec_output.trans1_num USING "##&", 
						COLUMN 55, "No of rows expected:", 
						COLUMN 75, p_rec_output.trans2_num USING "####&" 
						PRINT COLUMN 37, "Group b:", 
						COLUMN 50, p_rec_output.trans1_amt USING "--------&.&&" 
						SKIP 1 line 
						PRINT COLUMN 02,"Computed file total:", 
						COLUMN 22, p_rec_output.trans4_amt USING "--------&.&&", 
						COLUMN 37, "Bank groups:", 
						COLUMN 50, p_rec_output.trans4_num USING "##&", 
						COLUMN 57, "No of rows loaded:", 
						COLUMN 75, p_rec_output.trans5_num USING "####&" 
						PRINT COLUMN 37, "Group b:", 
						COLUMN 50, p_rec_output.trans7_amt USING "--------&.&&" 
						SKIP 1 line 
						PRINT COLUMN 16, p_rec_output.trans3_text 
						# => Computed total does NOT equal File total
					END IF 
			END CASE 

		ON LAST ROW 
			NEED 6 LINES 
			SKIP 4 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT