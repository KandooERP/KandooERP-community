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
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.*
	DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE modu_rec_bdimport RECORD 
		cmpy_code CHAR(2), #company id 
		jour_code CHAR(3), #journal type 
		jour_num INTEGER, #batch number 
		seq_num INTEGER, #sequence number 
		tran_type_ind CHAR(3), #transaction type 
		analysis_text CHAR(16), #analysis text entered 
		tran_date DATE, #date 
		ref_text CHAR(10), #reference OR source id 
		ref_num INTEGER, #reference document 
		acct_code CHAR(18), #account code can join coa_key 
		desc_text CHAR(30), #description 
		debit_amt DECIMAL(12,2), #debit amount 
		credit_amt DECIMAL(12,2), #credit amount 
		currency_code CHAR(3), #item currency code 
		conv_qty FLOAT, #currency conversion rate 
		for_debit_amt DECIMAL(14,2), #foreign currency debit val 
		for_credit_amt DECIMAL(14,2), #foreign currency credit val 
		stats_qty decimal(15,3) # quantity amount IF used 
	END RECORD 
	DEFINE modu_prev_jour_num LIKE batchhead.jour_num
	DEFINE modu_prev_jour_code LIKE batchhead.jour_code
	DEFINE modu_rec_period RECORD LIKE period.*
	DEFINE modu_arr_rec_period array[310] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD
	DEFINE modu_seq_number SMALLINT
	DEFINE modu_idx SMALLINT
	DEFINE modu_sel_text CHAR(800)
	DEFINE modu_runner CHAR(800)
	DEFINE modu_where_part CHAR(800)
	DEFINE modu_err_message CHAR(60)
	DEFINE modu_query_text CHAR(900)
	DEFINE modu_msgresp CHAR(1)
	DEFINE modu_try_again CHAR(1)
	DEFINE modu_fisc_year SMALLINT 
	DEFINE modu_tempper SMALLINT 

############################################################
# FUNCTION GST_main()
#
# \brief module GST consolidates batches TO another machine, OUTPUT via RMS
############################################################
FUNCTION GST_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GST") 

	CALL GST_rpt_check_start() 
	CALL GST_rpt_get_info() 
END FUNCTION 


############################################################
# FUNCTION GST_rpt_check_start() 
#
#
############################################################
FUNCTION GST_rpt_check_start() 


	##############################
	# create a table TO load in TO
	WHENEVER ERROR CONTINUE 
	IF fgl_find_table("loaddetl") THEN
		DROP TABLE loaddetl 
	END IF		
	# next line overcomes an informix bug
	SELECT count(*) FROM glparms 
	WHENEVER ERROR stop 
	LET modu_query_text = " create table loaddetl", 
	"(cmpy_code CHAR(2),", 
	"jour_code CHAR(3), ", 
	"jour_num INTEGER, ", 
	"seq_num INTEGER, ", 
	"tran_type_ind CHAR(3),", 
	"analysis_text CHAR(16),", 
	"tran_date DATE, ", 
	"ref_text CHAR(10), ", 
	"ref_num INTEGER, ", 
	"acct_code CHAR(18),", 
	"desc_text CHAR(30), ", 
	"debit_amt DECIMAL(12,2), ", 
	"credit_amt DECIMAL(12,2),", 
	"currency_code CHAR(3),", 
	"conv_qty float,", 
	"for_debit_amt DECIMAL(14,2),", 
	"for_credit_amt DECIMAL(14,2),", 
	"stats_qty DECIMAL(15,3))" 
	PREPARE state_1 FROM modu_query_text 
	EXECUTE state_1 
END FUNCTION 


############################################################
# FUNCTION GST_rpt_get_info() 
#
#
############################################################
FUNCTION GST_rpt_get_info() 

	OPEN WINDOW wg155 with FORM "G155" 
	CALL windecoration_g("G155") 

	MESSAGE kandoomsg2("G",1001,"") 	#1001 "Enter selection - ESC TO search"
	CONSTRUCT BY NAME modu_where_part ON 
	year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GST","construct-year") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	LET modu_sel_text = 
	"SELECT unique year_num, period_num ", 
	"FROM batchhead WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" consol_num IS NULL AND ", 
	modu_where_part clipped, 
	"ORDER BY year_num, period_num " 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		EXIT PROGRAM 
	END IF 
	PREPARE getper FROM modu_sel_text 
	DECLARE c_per CURSOR FOR getper 
	OPEN c_per 

	LET modu_idx = 0 
	FOREACH c_per INTO modu_rec_period.year_num, modu_rec_period.period_num 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_period[modu_idx].year_num = modu_rec_period.year_num 
		LET modu_arr_rec_period[modu_idx].period_num = modu_rec_period.period_num 
	END FOREACH 
	CALL set_count (modu_idx) 

	MESSAGE kandoomsg2("G",1078,"") 
	#1078 "Press RETURN on period TO consolidate, F5 TO view "
	INPUT ARRAY modu_arr_rec_period WITHOUT DEFAULTS FROM sr_period.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GST","inp-arr-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#LET scrn = scr_line()

			IF arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("G",9001,"") 			#9001 "No more rows in the direction you are going"
			END IF 

			#F5 the same as control-v because IBM-Informix bug under AIX
		ON ACTION "BATCH SCAN" #ON KEY (F5) 
			LET modu_sel_text = " SELECT * FROM batchhead ", 
			" WHERE cmpy_code = \\\"",glob_rec_kandoouser.cmpy_code,"\\\" ", 
			" AND year_num = ", modu_arr_rec_period[modu_idx].year_num, 
			" AND period_num = ", modu_arr_rec_period[modu_idx].period_num, 
			" AND consol_num IS NULL ", 
			" ORDER BY jour_code, jour_num " 
			LET modu_sel_text = "\"query_text=", trim(modu_sel_text), "\"" 

			CALL run_prog("G26",modu_sel_text,"","","") 

		ON ACTION "CONSOLIDATE"
			LET modu_tempper = modu_arr_rec_period[modu_idx].period_num 
			LET modu_fisc_year = modu_arr_rec_period[modu_idx].year_num 
			CALL consolidate_away() 
		
		BEFORE FIELD period_num 
			LET modu_tempper = modu_arr_rec_period[modu_idx].period_num 
			LET modu_fisc_year = modu_arr_rec_period[modu_idx].year_num 
			CALL consolidate_away() 

			NEXT FIELD year_num 

			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET quit_flag = 0 
		LET int_flag = 0 
	END IF 

	CLOSE WINDOW G155 

END FUNCTION 


############################################################
# FUNCTION consolidate_away()
#
#
############################################################
FUNCTION consolidate_away() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DECLARE upd_gl_curs CURSOR FOR 
	SELECT * 
	FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOR UPDATE OF 
	next_consol_num 

	DECLARE upd_batc_curs CURSOR FOR 
	SELECT * 
	#INTO modu_rec_batchhead.*
	FROM batchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_tempper 
	AND consol_num IS NULL 
	AND debit_amt = credit_amt 
	FOR UPDATE OF consol_num 

	--LET glob_rpt_output = "spool/uucppublic/" clipped , 
	--modu_fisc_year USING "<<<<", 
	--".", 
	--modu_tempper USING "<<<<", 
	--".", 
	--glob_rec_glparms.site_code 

	GOTO bypass 
	LABEL recovery: 
	LET modu_try_again = error_recover (modu_err_message, status) 
	IF modu_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR 
	GOTO recovery 
	BEGIN WORK 


		LOCK TABLE glparms in share MODE 
		LOCK TABLE batchhead in share MODE 

		# IF first time SET up next_post_num
		IF glob_rec_glparms.next_consol_num IS NULL THEN 
			UPDATE glparms 
			SET next_consol_num = 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			LET glob_rec_glparms.next_consol_num = 1 
		END IF 


		FOREACH upd_batc_curs INTO modu_rec_batchhead.* 
			IF status = 0 THEN 
				DISPLAY " Consolidating Journal: ", modu_rec_batchhead.jour_code	, modu_rec_batchhead.jour_num USING "<<<<" at 1,2 
				LET modu_prev_jour_num = modu_rec_batchhead.jour_num 
				LET modu_prev_jour_code = modu_rec_batchhead.jour_code 

				DECLARE detlcurs CURSOR FOR 
				SELECT * FROM batchdetl 
				WHERE jour_num = modu_rec_batchhead.jour_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = modu_rec_batchhead.jour_code 
				AND acct_code IS NOT NULL 

				FOREACH detlcurs INTO modu_rec_batchdetl.* 
					IF modu_rec_batchdetl.debit_amt IS NULL THEN 
						ERROR kandoomsg2("G",7030,modu_rec_batchdetl.jour_num) 
						#7030 Warning NULL found in batch <Batch Number> has been fixed
						LET modu_rec_batchdetl.debit_amt = 0 
					END IF 
					IF modu_rec_batchdetl.credit_amt IS NULL THEN 
						ERROR kandoomsg2("G",7030,modu_rec_batchdetl.jour_num) 
						#7030 Warning NULL found in batch <Batch Number> has been fixed
						LET modu_rec_batchdetl.credit_amt = 0 
					END IF 

					SELECT * INTO modu_rec_bdimport.* FROM loaddetl 
					WHERE acct_code = modu_rec_batchdetl.acct_code 
					IF status = NOTFOUND THEN 
						LET modu_rec_bdimport.acct_code = modu_rec_batchdetl.acct_code 
						LET modu_rec_bdimport.debit_amt = modu_rec_batchdetl.debit_amt 
						LET modu_rec_bdimport.credit_amt = modu_rec_batchdetl.credit_amt 
						INSERT INTO loaddetl VALUES (modu_rec_bdimport.*) 
					ELSE 
						UPDATE loaddetl 
						SET debit_amt = debit_amt + modu_rec_batchdetl.debit_amt, 
						credit_amt = credit_amt + modu_rec_batchdetl.credit_amt 
						WHERE acct_code = modu_rec_batchdetl.acct_code 
					END IF 
					
				END FOREACH
				 
				UPDATE batchhead 
				SET consol_num = glob_rec_glparms.next_consol_num 
				WHERE CURRENT OF upd_batc_curs 
			END IF 
		END FOREACH 

		# ok loaded up , now SET up AND write out
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"GST_rpt_list_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GST_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------


		LET modu_seq_number = 0 
		DECLARE temp_curs CURSOR FOR 
		SELECT * INTO modu_rec_bdimport.* FROM loaddetl 
		ORDER BY acct_code 
		FOREACH temp_curs 
			LET modu_seq_number = modu_seq_number + 1 
			LET modu_rec_bdimport.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET modu_rec_bdimport.jour_code = glob_rec_glparms.gj_code 
			LET modu_rec_bdimport.jour_num = 0 
			LET modu_rec_bdimport.seq_num = modu_seq_number 
			LET modu_rec_bdimport.tran_type_ind = "ADJ" 
			LET modu_rec_bdimport.analysis_text = "" 
			LET modu_rec_bdimport.tran_date = today 
			LET modu_rec_bdimport.ref_text = "FROM ", glob_rec_glparms.site_code 
			LET modu_rec_bdimport.ref_num = glob_rec_glparms.next_consol_num 
			LET modu_rec_bdimport.desc_text = "Consolidated FROM ", glob_rec_glparms.site_code 
			LET modu_rec_bdimport.currency_code = " " 
			LET modu_rec_bdimport.conv_qty = 0 
			LET modu_rec_bdimport.for_debit_amt = 0 
			LET modu_rec_bdimport.for_credit_amt = 0 
			LET modu_rec_bdimport.stats_qty = 0 
			# now write it out with | dividers

			#---------------------------------------------------------
			OUTPUT TO REPORT GST_rpt_list(l_rpt_idx,	modu_rec_bdimport.* )  
			IF NOT rpt_int_flag_handler2("Consolidation Run:",glob_rec_glparms.next_consol_num, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 			
			#----------------------------------	



		END FOREACH 
		WHENEVER ERROR CONTINUE 

	COMMIT WORK
	 
	#------------------------------------------------------------
	FINISH REPORT GST_rpt_list
	CALL rpt_finish("GST_rpt_list_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	 
END FUNCTION # post_batches 


############################################################
# REPORT GST_rpt_list(p_rec_bdimport)
#
#
############################################################
REPORT GST_rpt_list(p_rpt_idx,p_rec_bdimport) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_bdimport RECORD 
		cmpy_code CHAR(2), #company id 
		jour_code CHAR(3), #journal type 
		jour_num INTEGER, #batch number 
		seq_num INTEGER, #sequence number 
		tran_type_ind CHAR(3), #transaction type 
		analysis_text CHAR(16), #analysis text entered 
		tran_date DATE, #date 
		ref_text CHAR(10), #reference OR source id 
		ref_num INTEGER, #reference document 
		acct_code CHAR(18), #account code can join coa_key 
		desc_text CHAR(30), #description 
		debit_amt DECIMAL(12,2), #debit amount 
		credit_amt DECIMAL(12,2), #credit amount 
		currency_code CHAR(3), #item currency code 
		conv_qty FLOAT, #currency conversion rate 
		for_debit_amt DECIMAL(14,2), #foreign currency debit val 
		for_credit_amt DECIMAL(14,2), #foreign currency credit val 
		stats_qty decimal(15,3) # quantity amount IF used 
	END RECORD 


	OUTPUT 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 1 
--	left margin 0 

	ORDER external BY p_rec_bdimport.acct_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			PRINT COLUMN 1, p_rec_bdimport.cmpy_code,"|", 
			p_rec_bdimport.jour_code, "|", 
			p_rec_bdimport.jour_num, "|", 
			p_rec_bdimport.seq_num, "|", 
			p_rec_bdimport.tran_type_ind, "|", 
			p_rec_bdimport.analysis_text, "|", 
			p_rec_bdimport.tran_date, "|", 
			p_rec_bdimport.ref_text, "|", 
			p_rec_bdimport.ref_num, "|", 
			p_rec_bdimport.acct_code, "|", 
			p_rec_bdimport.desc_text, "|", 
			p_rec_bdimport.debit_amt, "|", 
			p_rec_bdimport.credit_amt, "|", 
			p_rec_bdimport.currency_code, "|", 
			p_rec_bdimport.conv_qty, "|", 
			p_rec_bdimport.for_debit_amt, "|", 
			p_rec_bdimport.for_credit_amt, "|", 
			p_rec_bdimport.stats_qty 

END REPORT