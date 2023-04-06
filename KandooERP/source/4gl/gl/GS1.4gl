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
DEFINE modu_rec_period RECORD LIKE period.* 
--DEFINE l_rec_structure RECORD LIKE structure.* 
DEFINE modu_rec_reporthead RECORD LIKE reporthead.* 
DEFINE modu_rec_reportdetl RECORD LIKE reportdetl.* 
DEFINE modu_rec_account RECORD LIKE account.* 
DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
DEFINE modu_rec_accountcur RECORD LIKE accountcur.* 
DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.* 
DEFINE modu_rec_saved_values RECORD 
	saved_num INTEGER, 
	saved_amt money(15,2) 
END RECORD

DEFINE modu_seg_length LIKE structure.length_num 
--	DEFINE modu_select_cmpy CHAR(2) 
--DEFINE modu_q1_text CHAR(500) 
-- DEFINE modu_query_text CHAR(900) 
DEFINE modu_runner CHAR(900) #huho - this has TO go... 
DEFINE modu_rep_wid SMALLINT
-- DEFINE modu_where_part CHAR(1200) 
DEFINE modu_line CHAR(360) 
--	DEFINE modu_rpt_name CHAR(60) 
--	DEFINE modu_show_name CHAR(48) 
DEFINE modu_line_amt money(15,2) 

DEFINE modu_rec_linebuild RECORD 
	column_num SMALLINT, 
	label_text CHAR(20), 
	print_amt DECIMAL(15,2), 
	col_info CHAR(1) 
END RECORD
-- DEFINE	modu_rep_name CHAR(7)
DEFINE modu_segment_text CHAR(50)
DEFINE modu_rpt_note LIKE rmsreps.report_text

DEFINE modu_tot_cb money(15,2)
DEFINE modu_tot_a1 money(15,2)
 
DEFINE modu_tot_a2 money(15,2)
DEFINE modu_tot_a3 money(15,2)
DEFINE modu_tot_a4 money(15,2)
 
DEFINE modu_tot_pa money(15,2) 
DEFINE modu_tot_p1 money(15,2) 

DEFINE modu_tot_p2 money(15,2)
DEFINE modu_tot_p3 money(15,2)
DEFINE modu_tot_p4 money(15,2)

DEFINE modu_tot_yp money(15,2)
DEFINE modu_tot_y1 money(15,2)

DEFINE modu_tot_y2 money(15,2)
DEFINE modu_tot_y3 money(15,2)
DEFINE modu_tot_y4 money(15,2)

DEFINE modu_tot_a5 money(15,2)
DEFINE modu_tot_a6 money(15,2)

DEFINE modu_tot_p5 money(15,2)
DEFINE modu_tot_p6 money(15,2)
DEFINE modu_tot_y5 money(15,2)


DEFINE modu_tot_y6 money(15,2)
DEFINE modu_tot_ps money(15,2)
DEFINE modu_tot_ys money(15,2)
 
DEFINE modu_tot_yr money(15,2)
DEFINE modu_tot_pr money(15,2)
 
DEFINE modu_last_start LIKE account.acct_code 
DEFINE modu_last_end LIKE account.acct_code 
DEFINE modu_start_acct LIKE account.acct_code 

DEFINE modu_end_acct LIKE account.acct_code
--	DEFINE modu_select_acct LIKE account.acct_code

DEFINE modu_last_flex_code LIKE reportdetl.flex_code 
DEFINE modu_retcode INTEGER
DEFINE modu_start_save INTEGER
DEFINE modu_end_save INTEGER
 
DEFINE modu_msgresp CHAR(1)
--DEFINE modu_night_shift CHAR(1)
--DEFINE modu_background CHAR(1)

DEFINE modu_displays CHAR(1)
DEFINE modu_zero_suppress CHAR(1)
 
DEFINE modu_sign CHAR(1)
DEFINE modu_repeat CHAR(1)
DEFINE modu_acct_type CHAR(1)

DEFINE modu_life_type CHAR(1)
DEFINE modu_curr_type CHAR(1)
 
DEFINE modu_lengther SMALLINT 
DEFINE modu_startpos SMALLINT 
DEFINE modu_endpos SMALLINT 

--	DEFINE modu_idx SMALLINT
	DEFINE modu_old_sa SMALLINT

	DEFINE modu_dropit SMALLINT
	DEFINE modu_old_sn SMALLINT

	DEFINE modu_save_year SMALLINT 
	DEFINE modu_col SMALLINT 
	DEFINE modu_nogo SMALLINT 

	DEFINE modu_save_per SMALLINT 
	DEFINE modu_dum_per SMALLINT 
	DEFINE modu_counter SMALLINT 

	DEFINE modu_rpt_year SMALLINT
	DEFINE modu_show_per SMALLINT
	DEFINE modu_rpt_per SMALLINT
 	DEFINE modu_rpt_date DATE
		
	DEFINE modu_period SMALLINT
	DEFINE modu_pagenumb SMALLINT
	DEFINE modu_len SMALLINT
	 
--	DEFINE modu_numargs SMALLINT	 
DEFINE modu_thisdate DATE
--	DEFINE glob_show_date DATE

DEFINE modu_tempstr CHAR(30) 
DEFINE modu_high_ref DECIMAL(5,2) 
DEFINE modu_errmsg CHAR(50)
DEFINE i SMALLINT
	 

############################################################
# FUNCTION GS1_main()
#
# Run by (no Kandoo module runs this program)
############################################################
FUNCTION GS1_main()
	DEFINE l_where_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_query_text STRING
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GS1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G121 with FORM "G121" 
			CALL windecoration_g("G121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU "Financial Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GS1","menu-invoices-customer") 
					CALL GS1_rpt_process(GS1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL GS1_rpt_process(GS1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "PRINT MANAGER" #COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW G121
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GS1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G121 with FORM "G121" 
			CALL windecoration_g("G121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GS1_rpt_query()) #save where clause in env 
			CLOSE WINDOW G121 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GS1_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION	 


############################################################
# FUNCTION GS1_rpt_query ()
#
#
############################################################
FUNCTION GS1_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	
	LET modu_rpt_date = today
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING modu_rpt_year, modu_rpt_per 

	DISPLAY modu_rpt_date TO rpt_date
	DISPLAY modu_rpt_year TO rpt_year
	DISPLAY modu_rpt_per TO rpt_per 


	INPUT modu_rec_reporthead.report_code, modu_rpt_year, modu_rpt_per, modu_rpt_date WITHOUT DEFAULTS 
	FROM report_code, rpt_year, rpt_per, rpt_date
	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GS1","inp-REPORT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(report_code) 
			LET modu_rec_reporthead.report_code = show_fin(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME modu_rec_reporthead.report_code 

			NEXT FIELD report_code 


		AFTER FIELD report_code 
			IF modu_rec_reporthead.report_code IS NULL THEN
				ERROR "Report Code must be specified"
				NEXT FIELD report_code
			END IF
			
			SELECT * 
			INTO modu_rec_reporthead.* 
			FROM reporthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND report_code = modu_rec_reporthead.report_code 
			IF status = NOTFOUND THEN 
				ERROR "Report NOT Found" --LET modu_msgresp = kandoomsg("U",9910,"") 
				#9910 " RECORD NOT found "
				NEXT FIELD report_code 
			END IF 

			DISPLAY BY NAME modu_rec_reporthead.report_code, 
			modu_rec_reporthead.desc_text 


		AFTER INPUT 
			SELECT * 
			INTO modu_rec_reporthead.* 
			FROM reporthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND report_code = modu_rec_reporthead.report_code 
			IF status = NOTFOUND THEN 
				LET modu_msgresp = kandoomsg("U",9910,"") 
				#9910 " RECORD NOT found "
				NEXT FIELD report_code 
			END IF 
			SELECT * INTO modu_rec_period.* FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND period_num = modu_rpt_per 
			AND year_num = modu_rpt_year 
			IF status = NOTFOUND THEN 
				LET modu_msgresp = kandoomsg("G",9012,"") 
				#9012 " modu_period AND Year combination NOT found"
				NEXT FIELD rpt_year 
			END IF 
			IF modu_rpt_date IS NULL THEN 
				LET modu_rpt_date = today 
			END IF 
	END INPUT 

	IF int_flag THEN
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_code = modu_rec_reporthead.report_code
		LET glob_rec_rpt_selector.ref1_num = modu_rpt_year
		LET glob_rec_rpt_selector.ref2_num = modu_rpt_per
		LET glob_rec_rpt_selector.ref1_date = modu_rpt_date
	END IF


	CONSTRUCT BY NAME l_where_text ON 
	account.cmpy_code, 
	coa.group_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GS1","construct-account") 

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

	# add on the search dimension of segments.......

	CALL segment_con(glob_rec_kandoouser.cmpy_code, "account") RETURNING l_where2_text 

	IF l_where2_text IS NOT NULL THEN
		LET l_where_text = l_where_text CLIPPED, " ", l_where2_text
	END IF

 
	CLEAR screen 
	IF promptTF("",kandoomsg2("U",8501,""),1)	THEN
		LET modu_zero_suppress = "Y"
	ELSE 
		LET modu_zero_suppress = "N" 
	END IF 
	LET glob_rec_rpt_selector.ref1_ind = modu_zero_suppress

	# test TO see IF file exists AND IS a regular file
	#huho
--	CALL fgl_winmessage("check this"," this run statement needs checking\n huho ref 1004","info") 
	--   LET modu_runner = "IF test -f ", trim(get_settings_reportPath()), "/maxnitej; THEN EXIT 0; ELSE EXIT 1; fi"
	--   run modu_runner returning modu_retcode
	--   LET modu_retcode = modu_retcode / 256 # dont really need TO do this
	# unless you want TO test FOR = 1
--	LET modu_night_shift = "N" 
	--   IF modu_retcode = 0 THEN
	--			IF promptTF("",kandoomsg2("U",1501,""),1)	THEN
	--         LET modu_night_shift = "Y"
	--      ELSE
	--         LET modu_night_shift = "N"
	--      END IF
	--   END IF
	--   IF modu_night_shift = "N" THEN
	--	IF promptTF("",kandoomsg2("U",8501,""),1)	THEN
	--			IF promptTF("",kandoomsg2("U",1502,""),1)	THEN
		--         LET modu_background = "Y"
	--      ELSE
	--         LET modu_background = "N"
	--      END IF
	--   END IF
	RETURN l_where_text
END FUNCTION # GS1_rpt_query 


############################################################
# FUNCTION GS1_rpt_process()
#
#
############################################################
FUNCTION GS1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_query_text STRING
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFER quit 
	DEFER interrupt 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GS1_rpt_list_finance","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GS1_rpt_list_finance TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	LET modu_rec_reporthead.report_code = glob_rec_rpt_selector.ref1_code 
	LET modu_rpt_year = glob_rec_rpt_selector.ref1_num 
	LET modu_rpt_per = glob_rec_rpt_selector.ref2_num 
	LET modu_rpt_date = glob_rec_rpt_selector.ref1_date 

	LET modu_line = " " 
	LET modu_last_start = "zzzzzzzzzz" 
	LET modu_last_end = "zzzzzzzzzz" 
	LET modu_last_flex_code = "zzzzzzzzzzzzzzzzzz" 

	# IF this IS run with arguments THEN get the company FROM the
	# parameters NOT FROM the last company the user was working with
	# during the day.
--	IF get_url_company_code() IS NULL THEN
	--LET modu_numargs = num_args () 
	--IF modu_numargs = 0 THEN 
--		LET modu_displays = "Y" 
--	ELSE 
--		LET glob_rec_kandoouser.cmpy_code = get_url_company_code() 
--		LET modu_displays = "N" 
--	END IF 


	--LET p_where_text = "" 

	--   SELECT * INTO glob_rec_glparms.* FROM glparms
	--      WHERE key_code = "1"
	--      AND cmpy_code = glob_rec_kandoouser.cmpy_code

	--   IF STATUS = NOTFOUND THEN
	IF NOT get_gl_setup_state() THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("G",5007,""),"ERROR") 
		EXIT PROGRAM 
	END IF 

	LET modu_counter = 0 

	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 

	LET modu_lengther = l_rec_structure.length_num 
	LET modu_startpos = l_rec_structure.start_num 
	LET modu_endpos = l_rec_structure.start_num + l_rec_structure.length_num - 1 

--	IF get_url_company_code() IS NULL THEN
	--IF modu_numargs = 0 THEN 
--		CALL GS1_rpt_query () RETURNING p_where_text
--		IF modu_night_shift IS NULL THEN 
--			EXIT PROGRAM 
--		ELSE 
--			IF modu_night_shift = "Y" THEN 
--				#CALL set_up_for_tonight () 
--				EXIT PROGRAM 
--			ELSE 
--				IF modu_background = "Y" THEN 
--					#CALL set_up_for_background () 
--					EXIT PROGRAM 
--				ELSE 
--					--LET p_where_text = p_where_text clipped, modu_q1_text 
--				END IF 
--			END IF 
--		END IF 
--	ELSE 
--		CALL set_up_from_parms(p_where_text) 
--	END IF 


	LET modu_save_year = modu_rpt_year 
	LET modu_save_per = modu_rpt_per 
	LET modu_period = modu_rpt_per 
	LET modu_high_ref = 0 
	LET modu_rec_reportdetl.end_acct_code = 0 

	CREATE temp TABLE saved_values 
	(saved_num INTEGER, 
	saved_amt money(15,2)) with no LOG 


	CREATE temp TABLE linebuild 
	(column_num SMALLINT, 
	label_text CHAR(20), 
	print_amt DECIMAL(15,2), 
	col_info CHAR(1)) with no LOG 

	IF modu_rec_reporthead.column_num > 18 THEN 
		LET modu_rec_reporthead.column_num = 18 
	END IF 
	LET modu_segment_text = NULL 


	DECLARE rptline CURSOR FOR 
	SELECT * INTO modu_rec_reportdetl.* FROM reportdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND report_code = modu_rec_reporthead.report_code 
	ORDER BY cmpy_code, report_code, line_num 


	FOREACH rptline 

		# IF the next command code has the same account range AND IS NOT a last
		# modu_period OR last year command THEN the VALUES may have already been
		# calculated.  This IS determined by the flags modu_acct_type, modu_life_type AND
		# modu_curr_type.  OTHERWISE initialise the variables AND THEN calculate.

		IF modu_rec_reportdetl.command_code = "SO" THEN 
			SELECT length_num 
			INTO modu_seg_length 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = modu_rec_reportdetl.col_num 
			IF status = NOTFOUND THEN 
				LET modu_msgresp = kandoomsg("G",9088,"") 
				#9088 "Segment Offset incorrect. Check Report Instructions"
				EXIT PROGRAM 
			END IF 

			LET modu_segment_text = 
			" AND account.acct_code[",modu_rec_reportdetl.col_num,",", 
			(modu_rec_reportdetl.col_num + modu_seg_length - 1), 
			"] matches " 
			CONTINUE FOREACH 
		END IF 
		
		IF modu_last_start != modu_rec_reportdetl.start_acct_code 
		OR modu_last_end != modu_rec_reportdetl.end_acct_code 
		OR (modu_rec_reportdetl.flex_code IS NOT NULL AND modu_last_flex_code IS null) 
		OR (modu_rec_reportdetl.flex_code IS NULL AND modu_last_flex_code IS NOT null) 
		OR (modu_rec_reportdetl.flex_code != modu_last_flex_code) 
		OR modu_rec_reportdetl.command_code = "LP" 
		OR modu_rec_reportdetl.command_code = "LY" THEN 
			LET modu_last_start = modu_rec_reportdetl.start_acct_code 
			LET modu_last_end = modu_rec_reportdetl.end_acct_code 
			LET modu_last_flex_code = modu_rec_reportdetl.flex_code 
			LET modu_acct_type = "N" 
			LET modu_life_type = "N" 
			LET modu_curr_type = "N" 
			LET modu_dropit = 0 
			LET modu_old_sn = 0 
			LET modu_old_sa = 0 
		END IF 
		
		IF (modu_rec_reportdetl.command_code = "CB" 
		OR modu_rec_reportdetl.command_code = "A1" 
		OR modu_rec_reportdetl.command_code = "A2" 
		OR modu_rec_reportdetl.command_code = "A3" 
		OR modu_rec_reportdetl.command_code = "A4" 
		OR modu_rec_reportdetl.command_code = "A5" 
		OR modu_rec_reportdetl.command_code = "A6" 
		OR modu_rec_reportdetl.command_code = "LP" 
		OR modu_rec_reportdetl.command_code = "LY" 
		OR modu_rec_reportdetl.command_code = "PA" 
		OR modu_rec_reportdetl.command_code = "PS" 
		OR modu_rec_reportdetl.command_code = "P1" 
		OR modu_rec_reportdetl.command_code = "P2" 
		OR modu_rec_reportdetl.command_code = "P3" 
		OR modu_rec_reportdetl.command_code = "P4" 
		OR modu_rec_reportdetl.command_code = "P5" 
		OR modu_rec_reportdetl.command_code = "P6" 
		OR modu_rec_reportdetl.command_code = "V1" 
		OR modu_rec_reportdetl.command_code = "V2" 
		OR modu_rec_reportdetl.command_code = "V3" 
		OR modu_rec_reportdetl.command_code = "V4" 
		OR modu_rec_reportdetl.command_code = "V5" 
		OR modu_rec_reportdetl.command_code = "V6" 
		OR modu_rec_reportdetl.command_code = "YA" 
		OR modu_rec_reportdetl.command_code = "YS" 
		OR modu_rec_reportdetl.command_code = "Y1" 
		OR modu_rec_reportdetl.command_code = "Y2" 
		OR modu_rec_reportdetl.command_code = "Y3" 
		OR modu_rec_reportdetl.command_code = "Y4" 
		OR modu_rec_reportdetl.command_code = "Y5" 
		OR modu_rec_reportdetl.command_code = "Y6" 
		OR modu_rec_reportdetl.command_code = "U1" 
		OR modu_rec_reportdetl.command_code = "U2" 
		OR modu_rec_reportdetl.command_code = "U3" 
		OR modu_rec_reportdetl.command_code = "U4" 
		OR modu_rec_reportdetl.command_code = "U5" 
		OR modu_rec_reportdetl.command_code = "U6" ) 
		AND modu_acct_type = "N" THEN 

			LET modu_start_acct = modu_rec_reportdetl.start_acct_code[1, modu_lengther] 
			LET modu_end_acct = modu_rec_reportdetl.end_acct_code[1, modu_lengther] 
			LET modu_tot_cb = 0 
			LET modu_tot_a1 = 0 
			LET modu_tot_a2 = 0 
			LET modu_tot_a3 = 0 
			LET modu_tot_a4 = 0 
			LET modu_tot_a5 = 0 
			LET modu_tot_a6 = 0 
			LET modu_tot_pa = 0 
			LET modu_tot_ps = 0 
			LET modu_tot_p1 = 0 
			LET modu_tot_p2 = 0 
			LET modu_tot_p3 = 0 
			LET modu_tot_p4 = 0 
			LET modu_tot_p5 = 0 
			LET modu_tot_p6 = 0 
			LET modu_tot_yp = 0 
			LET modu_tot_ys = 0 
			LET modu_tot_y1 = 0 
			LET modu_tot_y2 = 0 
			LET modu_tot_y3 = 0 
			LET modu_tot_y4 = 0 
			LET modu_tot_y5 = 0 
			LET modu_tot_y6 = 0 
			# LP requires modu_period TO be decremented by 1 AND by setting
			# modu_last_start TO z's ensures that the totals will be regenerated
			# FOR the next command.
			IF modu_rec_reportdetl.command_code = "LP" THEN 
				LET modu_last_start = "zzzzzzz" 
				LET modu_rpt_per = modu_period 
				CALL change_period(glob_rec_kandoouser.cmpy_code, modu_rec_account.year_num, modu_period, -1) 
				RETURNING modu_rec_account.year_num, modu_period 
			END IF 
			# LY requires the reporting year TO be decremented by 1 AND by
			# setting modu_last_start TO z's ensures that the totals will be
			# regenerated FOR the next command.
			IF modu_rec_reportdetl.command_code = "LY" THEN 
				LET modu_last_start = "zzzzzzz" 
				LET modu_rpt_year = modu_save_year - 1 
			END IF 

			# see IF group_code used , IF NOT use faster SELECT
			IF p_where_text matches "*group_code*" THEN 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT account.* ", 
					"FROM account, coa ", 
					"WHERE coa.acct_code = account.acct_code ", 
					" AND coa.cmpy_code = account.cmpy_code ", 
					" AND ", p_where_text clipped , 
					" AND account.year_num = ", modu_rpt_year , 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"", 
					modu_segment_text clipped, " \"",modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT account.* ", 
					"FROM account, coa ", 
					"WHERE coa.acct_code = account.acct_code ", 
					" AND coa.cmpy_code = account.cmpy_code ", 
					" AND ", p_where_text clipped , 
					" AND account.year_num = ", modu_rpt_year , 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"" 
				END IF 
			ELSE 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT * ", 
					"FROM account ", 
					"WHERE ", p_where_text clipped , 
					" AND account.year_num = ", modu_rpt_year , 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"", 
					modu_segment_text clipped," \"", modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT * ", 
					"FROM account ", 
					"WHERE ", p_where_text clipped , 
					" AND account.year_num = ", modu_rpt_year , 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"" 
				END IF 
			END IF
			 
			PREPARE choice FROM l_query_text 
			DECLARE acctcurs CURSOR FOR choice
			 
			FOREACH acctcurs INTO modu_rec_account.* 
				IF modu_displays = "Y" THEN 
					DISPLAY "" at 14,10 
					DISPLAY " Account: ", modu_rec_account.acct_code at 14,10 
				END IF 
				LET modu_tot_a1 = modu_tot_a1 + modu_rec_account.budg1_amt 
				LET modu_tot_a2 = modu_tot_a2 + modu_rec_account.budg2_amt 
				LET modu_tot_a3 = modu_tot_a3 + modu_rec_account.budg3_amt 
				LET modu_tot_a4 = modu_tot_a4 + modu_rec_account.budg4_amt 
				LET modu_tot_a5 = modu_tot_a5 + modu_rec_account.budg5_amt 
				LET modu_tot_a6 = modu_tot_a6 + modu_rec_account.budg6_amt
				 
				DECLARE histcurs CURSOR FOR 
				SELECT * 
				INTO modu_rec_accounthist.* 
				FROM accounthist 
				WHERE cmpy_code = modu_rec_account.cmpy_code 
				AND acct_code = modu_rec_account.acct_code 
				AND year_num = modu_rec_account.year_num 
				AND period_num <= modu_period 
				OPEN histcurs
				 
				FOREACH histcurs 
					IF modu_rec_accounthist.period_num = modu_period THEN 
						LET modu_tot_cb = modu_tot_cb + modu_rec_accounthist.close_amt 
						LET modu_tot_pa = modu_tot_pa + modu_rec_accounthist.pre_close_amt 
						LET modu_tot_ps = modu_tot_ps + modu_rec_accounthist.stats_qty 
						LET modu_tot_p1 = modu_tot_p1 + modu_rec_accounthist.budg1_amt 
						LET modu_tot_p2 = modu_tot_p2 + modu_rec_accounthist.budg2_amt 
						LET modu_tot_p3 = modu_tot_p3 + modu_rec_accounthist.budg3_amt 
						LET modu_tot_p4 = modu_tot_p4 + modu_rec_accounthist.budg4_amt 
						LET modu_tot_p5 = modu_tot_p5 + modu_rec_accounthist.budg5_amt 
						LET modu_tot_p6 = modu_tot_p6 + modu_rec_accounthist.budg6_amt 
						LET modu_tot_yp = modu_tot_yp + modu_rec_accounthist.ytd_pre_close_amt 
						LET modu_tot_y1 = modu_tot_y1 + modu_rec_accounthist.ytd_budg1_amt 
						LET modu_tot_y2 = modu_tot_y2 + modu_rec_accounthist.ytd_budg2_amt 
						LET modu_tot_y3 = modu_tot_y3 + modu_rec_accounthist.ytd_budg3_amt 
						LET modu_tot_y4 = modu_tot_y4 + modu_rec_accounthist.ytd_budg4_amt 
						LET modu_tot_y5 = modu_tot_y5 + modu_rec_accounthist.ytd_budg5_amt 
						LET modu_tot_y6 = modu_tot_y6 + modu_rec_accounthist.ytd_budg6_amt 
					END IF 
					LET modu_tot_ys = modu_tot_ys + modu_rec_accounthist.stats_qty 
				END FOREACH
				 
			END FOREACH
			 
			# Since lifetime actuals AND budgets use the same totalling variables
			# as account actuals AND budgets THEN SET the flags so that we know
			# which VALUES are currently stored.  This saves time FOR the next
			# command code IF the required VALUES have already been calculated.
			LET modu_acct_type = "Y" 
			LET modu_life_type = "N" 
		END IF 

		IF modu_rec_reportdetl.command_code = "LA" 
		OR modu_rec_reportdetl.command_code = "L1" 
		OR modu_rec_reportdetl.command_code = "L2" 
		OR modu_rec_reportdetl.command_code = "L3" 
		OR modu_rec_reportdetl.command_code = "L4" 
		OR modu_rec_reportdetl.command_code = "L5" 
		OR modu_rec_reportdetl.command_code = "L6" 
		AND modu_life_type = "N" THEN 

			LET modu_start_acct = modu_rec_reportdetl.start_acct_code[1, modu_lengther] 
			LET modu_end_acct = modu_rec_reportdetl.end_acct_code[1, modu_lengther] 
			LET modu_tot_pa = 0 
			LET modu_tot_p1 = 0 
			LET modu_tot_p2 = 0 
			LET modu_tot_p3 = 0 
			LET modu_tot_p4 = 0 
			LET modu_tot_p5 = 0 
			LET modu_tot_p6 = 0 
			# see IF group_code used , IF NOT use faster SELECT
			IF p_where_text matches "*group_code*" THEN 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT account.* ", 
					"FROM account, coa ", 
					"WHERE coa.acct_code = account.acct_code ", 
					" AND coa.cmpy_code = account.cmpy_code ", 
					" AND ", p_where_text clipped, 
					" AND account.year_num <= ", modu_rpt_year, 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"", 
					modu_segment_text clipped," \"", modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT account.* ", 
					"FROM account, coa ", 
					"WHERE coa.acct_code = account.acct_code ", 
					" AND coa.cmpy_code = account.cmpy_code ", 
					" AND ", p_where_text clipped, 
					" AND account.year_num <= ", modu_rpt_year, 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"" 
				END IF 
			ELSE 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT * ", 
					"FROM account ", 
					"WHERE ", p_where_text clipped, 
					" AND account.year_num <= ", modu_rpt_year, 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"", 
					modu_segment_text clipped," \"", modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT * ", 
					"FROM account ", 
					"WHERE ", p_where_text clipped, 
					" AND account.year_num <= ", modu_rpt_year, 
					" AND account.chart_code >= \"", modu_start_acct, "\"", 
					" AND account.chart_code <= \"", modu_end_acct, "\"" 
				END IF 
			END IF
			 
			PREPARE choice1 FROM l_query_text 
			DECLARE acc1curs CURSOR FOR choice1 
			OPEN acc1curs
			 
			FOREACH acc1curs INTO modu_rec_account.* 
				IF modu_displays = "Y" THEN 
					DISPLAY "" at 14,10 
					DISPLAY " Account: ", modu_rec_account.acct_code at 14,10 
				END IF 

				DECLARE led1curs CURSOR FOR 
				SELECT * 
				INTO modu_rec_accounthist.* 
				FROM accounthist 
				WHERE cmpy_code = modu_rec_account.cmpy_code 
				AND acct_code = modu_rec_account.acct_code 
				AND ((year_num < modu_rec_account.year_num) 
				OR (year_num = modu_rec_account.year_num 
				AND period_num <= modu_period)) 
				OPEN led1curs 

				FOREACH led1curs 
					LET modu_tot_pa = modu_tot_pa + modu_rec_accounthist.pre_close_amt 
					LET modu_tot_p1 = modu_tot_p1 + modu_rec_accounthist.budg1_amt 
					LET modu_tot_p2 = modu_tot_p2 + modu_rec_accounthist.budg2_amt 
					LET modu_tot_p3 = modu_tot_p3 + modu_rec_accounthist.budg3_amt 
					LET modu_tot_p4 = modu_tot_p4 + modu_rec_accounthist.budg4_amt 
					LET modu_tot_p5 = modu_tot_p5 + modu_rec_accounthist.budg5_amt 
					LET modu_tot_p6 = modu_tot_p6 + modu_rec_accounthist.budg6_amt 
				END FOREACH 
			END FOREACH 
			# Since lifetime actuals AND budgets use the same totalling variables
			# as account actuals AND budgets THEN SET the flags so that we know
			# which VALUES are currently stored.  This saves time FOR the next
			# command code IF the required VALUES have already been calculated.
			LET modu_life_type = "Y" 
			LET modu_acct_type = "N" 
		END IF 

		IF modu_rec_reportdetl.command_code = "PR" 
		OR modu_rec_reportdetl.command_code = "YR" 
		AND modu_curr_type = "N" THEN 

			LET modu_start_acct = modu_rec_reportdetl.start_acct_code[1, modu_lengther] 
			LET modu_end_acct = modu_rec_reportdetl.end_acct_code[1, modu_lengther] 
			LET modu_tot_pr = 0 
			LET modu_tot_yr = 0 
			# see IF group_code used , IF NOT use faster SELECT
			IF p_where_text matches "*group_code*" THEN 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT accountcur.* ", 
					"FROM accountcur, coa, account ", 
					"WHERE coa.acct_code = accountcur.acct_code ", 
					" AND coa.cmpy_code = accountcur.cmpy_code ", 
					" AND accountcur.acct_code = account.acct_code ", 
					" AND accountcur.cmpy_code = account.cmpy_code ", 
					" AND accountcur.year_num = account.year_num ", 
					" AND ", p_where_text clipped, 
					" AND accountcur.year_num = ", modu_rpt_year, 
					" AND accountcur.chart_code >= \"", 
					modu_start_acct, "\"", 
					" AND accountcur.chart_code <= \"", 
					modu_end_acct, "\"", 
					modu_segment_text clipped," \"", modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT accountcur.* ", 
					"FROM accountcur, coa, account ", 
					"WHERE coa.acct_code = accountcur.acct_code ", 
					" AND coa.cmpy_code = accountcur.cmpy_code ", 
					" AND accountcur.acct_code = account.acct_code ", 
					" AND accountcur.cmpy_code = account.cmpy_code ", 
					" AND accountcur.year_num = account.year_num ", 
					" AND ", p_where_text clipped, 
					" AND accountcur.year_num = ", modu_rpt_year, 
					" AND accountcur.chart_code >= \"", 
					modu_start_acct, "\"", 
					" AND accountcur.chart_code <= \"", 
					modu_end_acct, "\"" 
				END IF 
			ELSE 
				IF modu_rec_reportdetl.flex_code IS NOT NULL 
				AND modu_segment_text IS NOT NULL THEN 
					LET l_query_text = "SELECT accountcur.* ", 
					"FROM accountcur, account ", 
					"WHERE accountcur.acct_code = account.acct_code ", 
					" AND accountcur.cmpy_code = account.cmpy_code ", 
					" AND accountcur.year_num = account.year_num ", 
					" AND ", p_where_text clipped, 
					" AND accountcur.year_num = ", modu_rpt_year, 
					" AND accountcur.chart_code >= \"", 
					modu_start_acct, "\"", 
					" AND accountcur.chart_code <= \"", 
					modu_end_acct, "\"", 
					modu_segment_text clipped," \"", modu_rec_reportdetl.flex_code, "\"" 
				ELSE 
					LET l_query_text = "SELECT accountcur.* ", 
					"FROM accountcur, account ", 
					"WHERE accountcur.acct_code = account.acct_code ", 
					" AND accountcur.cmpy_code = account.cmpy_code ", 
					" AND accountcur.year_num = account.year_num ", 
					" AND ", p_where_text clipped, 
					" AND accountcur.year_num = ", modu_rpt_year, 
					" AND accountcur.chart_code >= \"", 
					modu_start_acct, "\"", 
					" AND accountcur.chart_code <= \"", 
					modu_end_acct, "\"" 
				END IF 
			END IF 

			PREPARE query FROM l_query_text 
			DECLARE query_set CURSOR FOR query 
			OPEN query_set 

			FOREACH query_set INTO modu_rec_accountcur.*

					 
--				IF modu_displays = "Y" THEN 
--					DISPLAY "" at 14,10 
--					DISPLAY " Account: ", modu_rec_accountcur.acct_code at 14,10 
--				END IF 
				DECLARE histquery CURSOR FOR 
				SELECT * 
				INTO modu_rec_accounthistcur.* 
				FROM accounthistcur 
				WHERE cmpy_code = modu_rec_accountcur.cmpy_code 
				AND acct_code = modu_rec_accountcur.acct_code 
				AND year_num = modu_rec_accountcur.year_num 
				AND currency_code = modu_rec_accountcur.currency_code 
				AND period_num <= modu_period 
				OPEN histquery 

				FOREACH histquery 
					IF modu_rec_accounthistcur.period_num = modu_period THEN 
						#LET modu_tot_pr = modu_tot_pr + modu_rec_accounthistcur.rept_debit_amt -
						#|
						#|      The symbol "rept_debit_amt" IS NOT an element of the RECORD "modu_rec_accounthistcur".
						#| See error number -4335.
						#                               modu_rec_accounthistcur.rept_credit_amt
						#|
						#|      The symbol "rept_credit_amt" IS NOT an element of the RECORD "modu_rec_accounthistcur".
						#| See error number -4335.
					END IF 
					#               LET modu_tot_yr = modu_tot_yr + modu_rec_accounthistcur.rept_debit_amt -
					#|
					#|      The symbol "rept_debit_amt" IS NOT an element of the RECORD "modu_rec_accounthistcur".
					#| See error number -4335.
					#                            modu_rec_accounthistcur.rept_credit_amt
					#|
					#|      The symbol "rept_credit_amt" IS NOT an element of the RECORD "modu_rec_accounthistcur".
					#| See error number -4335.
				END FOREACH 

			END FOREACH 
			# Although currency reporting uses different totalling variables TO
			# lifetime AND account, actuals AND budgets; we keep a flag SET so
			# that we can tell IF the variables need TO be regenerated due TO a
			# different account range.  Saving time recalculating the VALUES
			# on the same account range.
			LET modu_curr_type = "Y" 

		END IF 

		#--------------------------------------------------------
		IF NOT rpt_int_flag_handler2("Account:",modu_rec_accountcur.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF
		CALL do_process(l_rpt_idx) #OUTPUT TO REPORT
		#--------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GS1_rpt_list_finance
	CALL rpt_finish("GS1_rpt_list_finance")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	 
END FUNCTION 


{
############################################################
# FUNCTION set_up_for_tonight()
#
#
############################################################
FUNCTION set_up_for_tonight() 

	CALL tweek_where_part () 
	CALL fgl_winmessage("Eric!","What do you want to do with this ?","error") 
	LET modu_runner = ">> ", trim(get_settings_reportPath()), "/maxnitej", 
	" echo fglgo GS1 ", 
	modu_rec_reporthead.report_code, 
	modu_rpt_year, 
	modu_rpt_per, " ", 
	glob_rpt_date, " ", 
	glob_rec_kandoouser.cmpy_code, " ", 
	modu_zero_suppress, " \'\"", 
	modu_where_part clipped, "\"\'" 

	CALL fgl_winmessage("Eric!",modu_runner,"error") 

	# the single quote gets the echo job safely over <> | * $ AND ?
	# the double quotes (inside the single quotes) causes the modu_where_part
	# TO be one argument TO fglgo (but i think $ would be substituted)
	#

	RUN modu_runner 

END FUNCTION # set_up_for_tonight() 



{
############################################################
# FUNCTION set_up_for_background()
#
#
############################################################
FUNCTION set_up_for_background() 
	DEFINE l_runner1 CHAR(500) 

	CALL tweek_where_part () 

	LET modu_runner = "echo fglgo GS1 ", 
	modu_rec_reporthead.report_code, " ", 
	modu_rpt_year, " ", 
	modu_rpt_per, " ", 
	glob_rpt_date, " ", 
	glob_rec_kandoouser.cmpy_code, " ", 
	modu_zero_suppress, " \'", 
	modu_where_part clipped, "\'", 
	" | AT now + 1 minutes 2> gs1err" 


	# the single quote gets the echo job safely over <> | * $ AND ?
	# the double quotes (inside the single quotes) causes the modu_where_part
	# TO be one argument TO fglgo (but i think $ would be substituted)
	#

	LET l_runner1 = "echo \"",modu_runner clipped ,"\" > output1" 
	RUN l_runner1 
	RUN modu_runner WITHOUT waiting 

END FUNCTION # set_up_for_background() 

}

############################################################
# FUNCTION tweek_where_part ()
#
#
############################################################
#FUNCTION tweek_where_part () 
#	DEFINE i SMALLINT
#	# none of the parameters up TO modu_q1_text may have blanks in them,
#	# because it will throw out the parms on INPUT which are blank separated
#
#	LET modu_where_part = modu_where_part clipped, modu_q1_text 
#
#	FOR i = 1 TO 1200 
#		IF modu_where_part[i,i] = "\"" THEN 
#			LET modu_where_part[i,i] = "@" 
#		END IF 
#
#		IF modu_where_part[i,i] = "(" THEN 
#			LET modu_where_part[i,i] = "}" 
#		END IF 
#
#		IF modu_where_part[i,i] = ")" THEN 
#			         LET modu_where_part[i,i] = "{"
#			      END IF
#
#			   END FOR
#
#			END FUNCTION # tweek_where_part
#



############################################################
# FUNCTION set_up_from_parms()
#
#
############################################################
FUNCTION set_up_from_parms(p_where_text)
	DEFINE p_where_text STRING
	DEFINE n SMALLINT
	DEFINE l_runner1 CHAR(500)

   LET modu_rec_reporthead.report_code = get_url_report_code() #arg_val (1)
   LET modu_rpt_year      = get_url_fiscal_year_num() #arg_val (2)
   LET modu_rpt_per       = get_url_fiscal_period_num() #arg_val (3)
   #LET modu_rpt_date      = get_url_fiscal_date() #arg_val (4)
   LET glob_rec_kandoouser.cmpy_code = get_url_company_code()        #arg_val (5)
   LET modu_zero_suppress = get_url_zero_suppress() #arg_val (6)
   #LET modu_q1_text = ""

	LET p_where_text = get_url_query_where_text()

--   FOR n = 7 TO num_args ()
--       LET p_where_text = p_where_text clipped, " ", arg_val (n)
--   END FOR
--   FOR i = 1 TO 1200
--      IF p_where_text[i,i] = "@" THEN
--         LET p_where_text[i,i] = "\""
--      END IF
--
--      IF p_where_text[i,i] = "{" THEN
--         LET p_where_text[i,i] = "("
--      END IF
--
--      IF p_where_text[i,i] = "}" THEN
--         LET p_where_text[i,i] = ")"
--      END IF
--
--   END FOR

   LET modu_runner = p_where_text clipped
   SELECT * INTO modu_rec_reporthead.* FROM reporthead
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
         AND report_code = modu_rec_reporthead.report_code

   IF STATUS = NOTFOUND THEN
      LET modu_msgresp = kandoomsg("U",9910,"")
#9911 " Report NOT found "
   END IF

   SELECT * INTO modu_rec_period.* FROM period
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
        AND period_num = modu_rpt_per
        AND year_num = modu_rpt_year
   LET modu_displays = "N"

END FUNCTION # set_up_from_parms()



############################################################
# FUNCTION do_process(p_rpt_idx)
#
#
############################################################
FUNCTION do_process(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
   CALL check()
   CALL P1(p_rpt_idx)
   
   OUTPUT TO REPORT GS1_rpt_list_finance(p_rpt_idx,modu_rec_reportdetl.*)
   
END FUNCTION


############################################################
# FUNCTION check()
#
#
############################################################
FUNCTION check()
   LET modu_errmsg = NULL
   IF modu_rec_reportdetl.command_code = "CB"
      OR modu_rec_reportdetl.command_code = "A1"
      OR modu_rec_reportdetl.command_code = "A2"
      OR modu_rec_reportdetl.command_code = "A3"
      OR modu_rec_reportdetl.command_code = "A4"
      OR modu_rec_reportdetl.command_code = "A5"
      OR modu_rec_reportdetl.command_code = "A6"
      OR modu_rec_reportdetl.command_code = "LA"
      OR modu_rec_reportdetl.command_code = "L1"
      OR modu_rec_reportdetl.command_code = "L2"
      OR modu_rec_reportdetl.command_code = "L3"
      OR modu_rec_reportdetl.command_code = "L4"
      OR modu_rec_reportdetl.command_code = "L5"
      OR modu_rec_reportdetl.command_code = "L6"
      OR modu_rec_reportdetl.command_code = "PA"
      OR modu_rec_reportdetl.command_code = "PS"
      OR modu_rec_reportdetl.command_code = "PR"
      OR modu_rec_reportdetl.command_code = "P1"
      OR modu_rec_reportdetl.command_code = "P2"
      OR modu_rec_reportdetl.command_code = "P3"
      OR modu_rec_reportdetl.command_code = "P4"
      OR modu_rec_reportdetl.command_code = "P5"
      OR modu_rec_reportdetl.command_code = "P6"
      OR modu_rec_reportdetl.command_code = "V1"
      OR modu_rec_reportdetl.command_code = "V2"
      OR modu_rec_reportdetl.command_code = "V3"
      OR modu_rec_reportdetl.command_code = "V4"
      OR modu_rec_reportdetl.command_code = "V5"
      OR modu_rec_reportdetl.command_code = "V6"
      OR modu_rec_reportdetl.command_code = "YA"
      OR modu_rec_reportdetl.command_code = "YS"
      OR modu_rec_reportdetl.command_code = "YR"
      OR modu_rec_reportdetl.command_code = "Y1"
      OR modu_rec_reportdetl.command_code = "Y2"
      OR modu_rec_reportdetl.command_code = "Y3"
      OR modu_rec_reportdetl.command_code = "Y4"
      OR modu_rec_reportdetl.command_code = "Y5"
      OR modu_rec_reportdetl.command_code = "Y6"
      OR modu_rec_reportdetl.command_code = "U1"
      OR modu_rec_reportdetl.command_code = "U2"
      OR modu_rec_reportdetl.command_code = "U3"
      OR modu_rec_reportdetl.command_code = "U4"
      OR modu_rec_reportdetl.command_code = "U5"
      OR modu_rec_reportdetl.command_code = "U6" THEN

      IF modu_rec_reportdetl.col_num < 1
      AND modu_rec_reportdetl.skip_num > 0 THEN
         LET modu_errmsg = " Column must be 1 OR more"
         LET modu_rec_reportdetl.col_num = 1
      END IF

      IF modu_rec_reportdetl.col_num < 0
      THEN
         LET modu_errmsg = " Column must be 0 OR more"
         LET modu_rec_reportdetl.col_num = 1
      END IF

      IF modu_rec_reportdetl.col_num > modu_rec_reporthead.column_num THEN
         LET modu_errmsg = " Maximum COLUMN length exceeded"
         LET modu_rec_reportdetl.col_num = modu_rec_reporthead.column_num
      END IF

      IF modu_rec_reportdetl.sign_change_ind != "+"
         AND modu_rec_reportdetl.sign_change_ind != "-" THEN
         LET modu_errmsg = " Type code must END with '+' OR '-'"
         LET modu_rec_reportdetl.sign_change_ind = "+"
      END IF

      IF modu_rec_reportdetl.start_acct_code > modu_rec_reportdetl.end_acct_code THEN
         LET modu_errmsg = " Bad account range"
      END IF
   ELSE

      IF  modu_rec_reportdetl.command_code <> "RY"
         AND modu_rec_reportdetl.command_code <> "IY"
         AND modu_rec_reportdetl.command_code <> "LY"
         AND modu_rec_reportdetl.command_code <> "LP"
         AND modu_rec_reportdetl.command_code <> "RP"
         AND modu_rec_reportdetl.command_code <> "IP"
         AND modu_rec_reportdetl.command_code <> TRAN_TYPE_INVOICE_IN
         AND modu_rec_reportdetl.command_code <> "CC"
         AND modu_rec_reportdetl.command_code <> "%"
         AND modu_rec_reportdetl.command_code <> "DR"
         AND modu_rec_reportdetl.command_code <> "TM"
         AND modu_rec_reportdetl.command_code <> "SN"
         AND modu_rec_reportdetl.command_code <> "SA"
         AND modu_rec_reportdetl.command_code <> "LB"
         AND modu_rec_reportdetl.command_code <> "CJ"
         AND modu_rec_reportdetl.command_code <> "PG" THEN
         LET modu_errmsg = " Illegal command code"
      END IF
   END IF

   IF modu_rec_reportdetl.command_code = TRAN_TYPE_INVOICE_IN
      OR modu_rec_reportdetl.command_code = "LB" THEN
      IF modu_rec_reportdetl.col_num < 1
         AND modu_rec_reportdetl.command_code <> "LB" THEN
         LET modu_errmsg = "Column number must be one OR more"
         LET modu_rec_reportdetl.col_num = 1
      END IF

      IF modu_rec_reportdetl.col_num > modu_rec_reporthead.column_num THEN
         LET modu_errmsg = "Maximum COLUMN length exceeded"
         LET modu_rec_reportdetl.col_num = modu_rec_reporthead.column_num
      END IF
   END IF

   IF modu_rec_reportdetl.command_code = "SN"
      OR modu_rec_reportdetl.command_code = "TM" THEN
      IF modu_rec_reportdetl.col_num < 0 THEN
         LET modu_errmsg = " Column number must >= 0 "
         LET modu_rec_reportdetl.col_num = 1
      END IF
      IF modu_rec_reportdetl.col_num > modu_rec_reporthead.column_num THEN
         LET modu_errmsg = " Maximum COLUMN length exceeded"
         LET modu_rec_reportdetl.col_num = modu_rec_reporthead.column_num
      END IF

      IF modu_rec_reportdetl.sign_change_ind != "+"
         AND modu_rec_reportdetl.sign_change_ind != "-" THEN
         LET modu_errmsg = " Type code must be '+' OR '-', '+' assumed "
         LET modu_rec_reportdetl.sign_change_ind = "+"
      END IF
   END IF

   IF modu_rec_reportdetl.command_code = "SA"
   THEN
      IF modu_rec_reportdetl.col_num < 0 THEN
         LET modu_errmsg = " Column number must >= 0 "
         LET modu_rec_reportdetl.col_num = 1
      END IF
      IF modu_rec_reportdetl.col_num > modu_rec_reporthead.column_num THEN
         LET modu_errmsg = " Maximum COLUMN length exceeded"
         LET modu_rec_reportdetl.col_num = modu_rec_reporthead.column_num
      END IF

      IF modu_rec_reportdetl.sign_change_ind != "+"
         AND modu_rec_reportdetl.sign_change_ind != "-" THEN
         LET modu_errmsg = " Type code must be '+' OR '-', '+' assumed "
         LET modu_rec_reportdetl.sign_change_ind = "+"
      END IF
   END IF

   IF modu_errmsg IS NOT NULL AND modu_displays = "Y" THEN
      LET modu_errmsg = modu_errmsg clipped, "Line: ", modu_rec_reportdetl.line_num
      LET modu_msgresp = kandoomsg("U",1,modu_errmsg)
   END IF
END FUNCTION




############################################################
# FUNCTION P1()
#
#
############################################################
FUNCTION P1(p_rpt_idx)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_tmpMsg STRING

   LET modu_line_amt = 0
   LET modu_col = 0
   IF modu_rec_reportdetl.label_text = "&DATE" THEN
      LET modu_rec_reportdetl.label_text = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_date using "dd mmm yyyy"
   END IF

   IF modu_rec_reportdetl.label_text = "&SEGMENT" THEN
      SELECT desc_text
         INTO modu_rec_reportdetl.label_text
         FROM structure
         WHERE cmpy_code = modu_rec_account.cmpy_code
           AND start_num = modu_rec_reportdetl.col_num
   END IF


   IF modu_rec_reportdetl.label_text = "&COA" THEN
      SELECT desc_text
      INTO modu_rec_reportdetl.label_text
      FROM coa
      WHERE cmpy_code = modu_rec_account.cmpy_code
        AND acct_code = modu_rec_account.acct_code
   END IF

   IF modu_rec_reportdetl.label_text = "&REPORT" THEN
      LET modu_rec_reportdetl.label_text = modu_rec_reporthead.desc_text
   END IF

   IF modu_rec_reportdetl.label_text = "&NAME" THEN
      LET modu_rec_reportdetl.label_text = glob_rec_company.name_text
   END IF

   IF modu_rec_reportdetl.label_text = "&PAGE" THEN
      LET modu_rec_reportdetl.label_text = " Page: ", modu_pagenumb using "###"
   END IF

   IF modu_rec_reportdetl.command_code = "IP" THEN
      CALL change_period(glob_rec_kandoouser.cmpy_code, modu_rpt_year, modu_period, modu_rec_reportdetl.col_num)
           returning modu_rpt_year, modu_period
   END IF

   IF modu_rec_reportdetl.command_code = "IY" THEN
      LET modu_rpt_year = modu_rpt_year + modu_rec_reportdetl.col_num
   END IF

   IF modu_rec_reportdetl.command_code = "LP" THEN
      LET modu_period = modu_rpt_per
      LET modu_rec_reportdetl.command_code = "PA"
   END IF

   IF modu_rec_reportdetl.command_code = "LY" THEN
      LET modu_rpt_year = modu_save_year
      LET modu_rec_reportdetl.command_code = "YA"
   END IF

   IF modu_rec_reportdetl.command_code = "RP" THEN
      LET modu_period = modu_save_per
      LET modu_rpt_year = modu_save_year
   END IF

   IF modu_rec_reportdetl.command_code = "RY" THEN
      LET modu_rpt_year = modu_save_year
   END IF

   IF modu_rec_reportdetl.command_code = "CP" THEN
      LET modu_period = modu_save_per
   END IF


   IF modu_rec_reportdetl.command_code = TRAN_TYPE_INVOICE_IN AND modu_displays = "Y" THEN
   	LET l_tmpMsg = " Enter amount FOR ", modu_rec_reportdetl.label_text
  	 LET modu_line_amt = fgl_winprompt(5,5, l_tmpMsg, "", 25, 0)

      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "CC" THEN
      SELECT *
         INTO glob_rec_company.*
         FROM company
         WHERE cmpy_code = modu_rec_reportdetl.label_text

      IF STATUS = NOTFOUND THEN
         LET modu_msgresp = kandoomsg("g",5000,"")
         EXIT PROGRAM
      END IF
   END IF

   IF modu_rec_reportdetl.command_code = "CB" THEN
      LET modu_line_amt = modu_tot_cb
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A1" THEN
      LET modu_line_amt = modu_tot_a1
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A2" THEN
      LET modu_line_amt = modu_tot_a2
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A3" THEN
      LET modu_line_amt = modu_tot_a3
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A4" THEN
      LET modu_line_amt = modu_tot_a4
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A5" THEN
      LET modu_line_amt = modu_tot_a5
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "A6" THEN
      LET modu_line_amt = modu_tot_a6
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "PA" THEN
      LET modu_line_amt = modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "PS" THEN
      LET modu_line_amt = modu_tot_ps
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "PR" THEN
      LET modu_line_amt = modu_tot_pr
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P1" THEN
      LET modu_line_amt = modu_tot_p1
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P2" THEN
      LET modu_line_amt = modu_tot_p2
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P3" THEN
      LET modu_line_amt = modu_tot_p3
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P4" THEN
      LET modu_line_amt = modu_tot_p4
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P5" THEN
      LET modu_line_amt = modu_tot_p5
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "P6" THEN
      LET modu_line_amt = modu_tot_p6
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "LA" THEN
      LET modu_line_amt = modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L1" THEN
      LET modu_line_amt = modu_tot_p1
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L2" THEN
      LET modu_line_amt = modu_tot_p2
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L3" THEN
      LET modu_line_amt = modu_tot_p3
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L4" THEN
      LET modu_line_amt = modu_tot_p4
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L5" THEN
      LET modu_line_amt = modu_tot_p5
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "L6" THEN
      LET modu_line_amt = modu_tot_p6
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V1" THEN
      LET modu_line_amt = modu_tot_p1 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V2" THEN
      LET modu_line_amt = modu_tot_p2 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V3" THEN
      LET modu_line_amt = modu_tot_p3 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V4" THEN
      LET modu_line_amt = modu_tot_p4 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V5" THEN
      LET modu_line_amt = modu_tot_p5 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "V6" THEN
      LET modu_line_amt = modu_tot_p6 - modu_tot_pa
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "YA" THEN
      LET modu_line_amt = modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "YS" THEN
      LET modu_line_amt = modu_tot_ys
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "YR" THEN
      LET modu_line_amt = modu_tot_yr
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y1" THEN
      LET modu_line_amt = modu_tot_y1
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y2" THEN
      LET modu_line_amt = modu_tot_y2
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y3" THEN
      LET modu_line_amt = modu_tot_y3
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y4" THEN
      LET modu_line_amt = modu_tot_y4
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y5" THEN
      LET modu_line_amt = modu_tot_y5
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "Y6" THEN
      LET modu_line_amt = modu_tot_y6
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U1" THEN
      LET modu_line_amt = modu_tot_y1 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U2" THEN
      LET modu_line_amt = modu_tot_y2 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U3" THEN
      LET modu_line_amt = modu_tot_y3 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U4" THEN
      LET modu_line_amt = modu_tot_y4 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U5" THEN
      LET modu_line_amt = modu_tot_y5 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "U6" THEN
      LET modu_line_amt = modu_tot_y6 - modu_tot_yp
      LET modu_rec_reportdetl.command_code = "OK"
   END IF

   IF modu_rec_reportdetl.command_code = "SN" THEN
      LET modu_start_save = modu_rec_reportdetl.start_acct_code
      LET modu_end_save = modu_rec_reportdetl.end_acct_code
      DECLARE refcurs CURSOR FOR
         SELECT *
            INTO modu_rec_saved_values.*
            FROM saved_values
            WHERE saved_num between modu_start_save AND modu_end_save
      OPEN refcurs
      FOREACH refcurs
         IF modu_rec_reportdetl.sign_change_ind = "+" THEN
            LET modu_line_amt = modu_line_amt + modu_rec_saved_values.saved_amt
         ELSE
            LET modu_line_amt = modu_line_amt - modu_rec_saved_values.saved_amt
         END IF
      END FOREACH
      LET modu_rec_reportdetl.command_code = "OK"
      LET modu_old_sn = 1
   END IF

   IF modu_rec_reportdetl.command_code = "SA" THEN
      LET modu_start_save = modu_rec_reportdetl.start_acct_code
      LET modu_end_save = modu_rec_reportdetl.end_acct_code
      DECLARE ref1curs CURSOR FOR
         SELECT *
            INTO modu_rec_saved_values.*
            FROM saved_values
            WHERE saved_num between modu_start_save AND modu_end_save
      OPEN ref1curs
      FOREACH ref1curs
         IF modu_rec_reportdetl.sign_change_ind = "+" THEN
            LET modu_line_amt = modu_line_amt + modu_rec_saved_values.saved_amt
         ELSE
            LET modu_line_amt = modu_line_amt - modu_rec_saved_values.saved_amt
         END IF
      END FOREACH
      LET modu_rec_reportdetl.command_code = "OK"
      LET modu_old_sa = 1
   END IF


   IF modu_rec_reportdetl.command_code = "TM" THEN
      LET modu_start_save = modu_rec_reportdetl.start_acct_code
      LET modu_end_save = modu_rec_reportdetl.end_acct_code
      DECLARE ref9curs CURSOR FOR
         SELECT *
            INTO modu_rec_saved_values.*
            FROM saved_values
            WHERE saved_num between modu_start_save AND modu_end_save
      OPEN ref9curs
      FOREACH ref9curs
         IF modu_rec_reportdetl.sign_change_ind = "+" THEN
            LET modu_line_amt = modu_line_amt + modu_rec_saved_values.saved_amt
         ELSE
            LET modu_line_amt = modu_line_amt - modu_rec_saved_values.saved_amt
         END IF
      END FOREACH
      LET modu_rec_reportdetl.command_code = "NP"
   END IF

   IF modu_rec_reportdetl.command_code = "%" THEN
      LET modu_start_save = modu_rec_reportdetl.start_acct_code
      LET modu_end_save = modu_rec_reportdetl.end_acct_code
      SELECT *
         INTO modu_rec_saved_values.*
         FROM saved_values
         WHERE saved_num = modu_start_save
      LET modu_line_amt = modu_rec_saved_values.saved_amt

      SELECT *
         INTO modu_rec_saved_values.*
         FROM saved_values
         WHERE saved_num = modu_end_save

      IF modu_rec_saved_values.saved_amt = 0 THEN
         LET modu_line_amt = 0
      ELSE
         LET modu_line_amt = modu_line_amt / modu_rec_saved_values.saved_amt * 100
      END IF

      LET modu_rec_reportdetl.command_code = "OK"
      LET modu_rec_reportdetl.sign_change_ind = "%"
   END IF

END FUNCTION



############################################################
# REPORT GS1_rpt_list_finance(p_rec_reportdetl)
#
#
############################################################
REPORT GS1_rpt_list_finance(p_rpt_idx,p_rec_reportdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_reportdetl RECORD LIKE reportdetl.*
	DEFINE l_len SMALLINT
	DEFINE s SMALLINT
	DEFINE l_non_zero SMALLINT
	DEFINE l_printit CHAR(1)

   OUTPUT
   left margin 0

   FORMAT
   PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

   IF modu_rec_reporthead.page_head_flag = "Y" THEN
      PRINT COLUMN 2, "Date:", COLUMN 8, glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_date using "dd mmm yyyy",
      COLUMN modu_col, glob_rec_company.name_text,
      COLUMN l_len, pageno using "Page ###"

      PRINT COLUMN 5, "Year:    ", modu_save_year
      PRINT COLUMN 5, "modu_period: ", modu_save_per
      LET l_len = length(modu_rec_reporthead.desc_text clipped) / 2
      LET modu_col = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num / 2) - l_len

      PRINT COLUMN modu_col, modu_rec_reporthead.desc_text clipped
      skip 1 line
   ELSE
      skip 5 lines
   END IF

   ON EVERY ROW

   IF p_rec_reportdetl.skip_num IS NULL THEN LET p_rec_reportdetl.skip_num = 0 END IF
   IF p_rec_reportdetl.command_code = "OK"
      AND p_rec_reportdetl.skip_num = 0
   THEN
      IF p_rec_reportdetl.col_num > 0
      THEN
         LET modu_rec_linebuild.column_num = p_rec_reportdetl.col_num
         LET modu_rec_linebuild.label_text = p_rec_reportdetl.label_text
         LET modu_rec_linebuild.print_amt = modu_line_amt
         LET modu_rec_linebuild.col_info = p_rec_reportdetl.sign_change_ind
         IF modu_rec_linebuild.col_info  = "-"
            AND modu_old_sn = 0
            AND modu_old_sa = 0
         THEN
            LET modu_rec_linebuild.print_amt = (modu_rec_linebuild.print_amt *  -1) + 0
         END IF
         WHENEVER ERROR CONTINUE
         DELETE FROM linebuild WHERE column_num = modu_rec_linebuild.column_num
         WHENEVER ERROR STOP
         INSERT INTO linebuild  VALUES (modu_rec_linebuild.*)
      END IF
   END IF

   IF p_rec_reportdetl.command_code = "LB"
      AND p_rec_reportdetl.col_num = 0 THEN
      LET modu_dropit = p_rec_reportdetl.skip_num
      WHILE modu_dropit > 1
         skip 1 line
         LET modu_dropit = modu_dropit - 1
      END WHILE
      LET modu_rec_linebuild.column_num = 0
      WHILE modu_rec_linebuild.column_num < modu_rec_reporthead.column_num
         LET modu_rec_linebuild.column_num = modu_rec_linebuild.column_num + 1
         LET modu_rec_linebuild.label_text = p_rec_reportdetl.label_text
         LET modu_rec_linebuild.print_amt = 0
         LET modu_rec_linebuild.col_info = "L"
         LET modu_col = 20 * (modu_rec_linebuild.column_num - 1)
         IF modu_col < 0 THEN
            LET modu_col = 1
         ELSE
            LET modu_col = modu_col + 1
         END IF
         PRINT COLUMN modu_col, p_rec_reportdetl.label_text;
      END WHILE
      LET modu_col = (modu_rec_reporthead.column_num * 20)
      PRINT COLUMN modu_col, " "

   END IF



   IF p_rec_reportdetl.command_code = "DR" THEN
      LET modu_dropit = p_rec_reportdetl.skip_num
      WHILE modu_dropit > 0
         skip 1 line
         LET modu_dropit = modu_dropit - 1
      END WHILE
   END IF


   IF p_rec_reportdetl.command_code = "LB"
      AND p_rec_reportdetl.col_num > 0 THEN
      LET modu_col = 20
      LET modu_col = modu_col * (p_rec_reportdetl.col_num - 1)
      IF modu_col < 0 THEN
         LET modu_col = 1
      ELSE
         LET modu_col = modu_col + 1
      END IF

      LET modu_dropit = p_rec_reportdetl.skip_num
      IF modu_dropit = 0
      THEN
         LET modu_line[modu_col, (modu_col + 19)] = p_rec_reportdetl.label_text
      ELSE
         LET modu_line[modu_col, (modu_col + 19)] = p_rec_reportdetl.label_text
	 LET modu_rep_wid = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
         PRINT COLUMN 1, modu_line[1, modu_rep_wid]
         LET modu_line = " "
         WHILE modu_dropit > 1
            skip 1 line
            LET modu_dropit = modu_dropit - 1
         END WHILE
      END IF
   END IF

   IF p_rec_reportdetl.command_code = "CJ" THEN
      LET l_len = length(p_rec_reportdetl.label_text clipped) / 2
      LET modu_col = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num / 2) - l_len
      LET modu_dropit = p_rec_reportdetl.skip_num
      IF modu_dropit IS NULL THEN LET modu_dropit = 0 END IF
      PRINT COLUMN modu_col, p_rec_reportdetl.label_text
      WHILE modu_dropit > 1
         skip 1 line
         LET modu_dropit = modu_dropit - 1
      END WHILE
   END IF
   IF p_rec_reportdetl.command_code = "PG" THEN
      skip TO top of page
   END IF


   IF p_rec_reportdetl.command_code = "OK"
   THEN
      LET modu_rec_linebuild.column_num = p_rec_reportdetl.col_num
      LET modu_rec_linebuild.label_text = p_rec_reportdetl.label_text
      LET modu_rec_linebuild.print_amt = modu_line_amt
      LET modu_rec_linebuild.col_info = p_rec_reportdetl.sign_change_ind
      IF modu_rec_linebuild.col_info  = "-"
         AND modu_old_sn = 0
         AND modu_old_sa = 0
      THEN
         LET modu_rec_linebuild.print_amt = (modu_rec_linebuild.print_amt *  -1) + 0
      END IF
      WHENEVER ERROR CONTINUE
      DELETE FROM linebuild WHERE column_num = modu_rec_linebuild.column_num
      WHENEVER ERROR STOP

      INSERT INTO linebuild VALUES (modu_rec_linebuild.*)

      LET modu_dropit = p_rec_reportdetl.skip_num

      IF modu_dropit = 0
      THEN
      ELSE

         DECLARE do_loc CURSOR FOR
         SELECT *
         INTO modu_rec_linebuild.*
         FROM linebuild
         ORDER BY column_num asc

         FOREACH do_loc

            IF modu_rec_linebuild.label_text IS NULL
               OR modu_rec_linebuild.label_text = "  "
            THEN
            ELSE
               LET modu_col = 1
               LET modu_line[modu_col, (modu_col + 19)] = modu_rec_linebuild.label_text
            END IF
            LET modu_col = (modu_rec_linebuild.column_num - 1 ) * 20

            IF modu_col <= 0 THEN
               LET modu_col = 1
            ELSE
               LET modu_col = modu_col + 1
            END IF
            IF modu_col != 999
            THEN
               IF modu_rec_linebuild.col_info = "%" THEN
# percentages will always PRINT without modu_sign
                  LET modu_line[modu_col, (modu_col + 19)] = modu_rec_linebuild.print_amt using "#,###,###,###.&&"
               ELSE
                  LET modu_line[modu_col, (modu_col + 19)] = ac_form(glob_rec_kandoouser.cmpy_code,
                                               modu_rec_linebuild.print_amt,
                                               "A",
                                               1)
#glob_rec_glparms.style_ind)

               END IF
               IF (modu_rec_linebuild.print_amt IS NULL
                  OR modu_rec_linebuild.print_amt = 0)
                  AND modu_zero_suppress = "Y"
               THEN
               ELSE
                  LET l_non_zero = 1
               END IF
            END IF
         END FOREACH
         DELETE FROM linebuild WHERE 1=1
         INITIALIZE modu_rec_linebuild.* TO NULL

         IF modu_dropit > 0 THEN
            IF l_non_zero = 1 THEN
	       LET modu_rep_wid = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num
               PRINT COLUMN 1, modu_line[1, modu_rep_wid]
               LET l_non_zero = 0
               WHILE modu_dropit > 1
                  skip 1 line
                  LET modu_dropit = modu_dropit - 1
               END WHILE
            END IF
            LET modu_line = " "
         END IF
      END IF
   END IF

   IF p_rec_reportdetl.ref_num > 0 THEN
      LET modu_rec_saved_values.saved_amt = modu_line_amt
      LET modu_rec_saved_values.saved_num = p_rec_reportdetl.ref_num

      INSERT INTO saved_values VALUES (modu_rec_saved_values.*)
   END IF

   ON LAST ROW

      skip TO top of page
      skip 5 lines
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT