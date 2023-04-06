{
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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW1_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_maxcompany LIKE company.name_text 
DEFINE modu_kandoousername LIKE kandoouser.name_text 
DEFINE modu_time CHAR(8) 
DEFINE modu_filename1 CHAR(20) 
DEFINE modu_print_ledg SMALLINT 
DEFINE modu_kandoo_columns INTEGER 
DEFINE modu_desc_pos1 INTEGER 
DEFINE modu_desc_pos2 INTEGER 
DEFINE modu_rpt_line CHAR(330) 
DEFINE modu_col_desc1 CHAR(330) 
DEFINE modu_col_desc2 CHAR(330) 
DEFINE modu_col_desc3 CHAR(330) 


############################################################
# FUNCTION produce_rpt()
#
#
############################################################
FUNCTION produce_rpt()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_consoldetl RECORD LIKE consoldetl.* 
	DEFINE l_step INTEGER 
	DEFINE l_query_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_output STRING #report output file name inc. path


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	--IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
	--	LET int_flag = false 
	--	LET quit_flag = false
	--
	--	RETURN FALSE
	--END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GW1_rpt_list_management","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GW1_rpt_list_management TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------


	LET modu_time = time 
	SELECT name_text INTO modu_kandoousername FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
	SELECT name_text INTO modu_maxcompany FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

#	LET glob_rpt_width = rpt_width() 
	LET modu_kandoo_columns = max_columns() 
	LET modu_rpt_line = rpt_line(glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GW1_rpt_list_management")].report_width_num) 

	CALL desc_positions(glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GW1_rpt_list_management")].report_width_num) 
	RETURNING modu_desc_pos1, modu_desc_pos2 

	LET modu_col_desc1 = col_hdr_desc(1) 
	LET modu_col_desc2 = col_hdr_desc(2) 
	LET modu_col_desc3 = col_hdr_desc(3) 

	SELECT * INTO glob_rec_signcode.* FROM signcode 
	WHERE sign_code = glob_rec_rpthead.sign_code 

	DECLARE rptline_curs CURSOR FOR 
	SELECT * FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	ORDER BY line_id 

	DECLARE rptcol_curs CURSOR FOR 
	SELECT * FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	ORDER BY col_id 



	LET l_rec_consolhead.consol_code = NULL 
	LET l_step = 1 

	#DISPLAY " Processing Report  ",l_step using "####" TO lbLabel2  -- 2,2
	#MESSAGE "Processing Report ",l_step USING "####" 

	IF glob_consolidations_exist THEN 
		LET l_query_text = "SELECT * FROM consolhead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",glob_consol_criteria clipped," ", 
		"ORDER BY 2" 
		PREPARE s_consolhead FROM l_query_text 
		DECLARE c_consolhead CURSOR FOR s_consolhead 
		LET l_query_text = "SELECT * FROM consoldetl ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND consol_code = ? " 
		PREPARE s_consoldetl FROM l_query_text 
		DECLARE c_consoldetl CURSOR FOR s_consoldetl 
		FOREACH c_consolhead INTO l_rec_consolhead.* 
			#			DISPLAY " Processing Consolidation Ledgers  ", l_step using "####" TO lbLabel2  -- 2,2
			#MESSAGE "Processing Consolidation Ledgers ", l_step USING "####" 
			LET l_step = l_step + 1 
			OPEN c_consoldetl USING l_rec_consolhead.consol_code 
			LET glob_range = NULL 
			FOREACH c_consoldetl INTO l_rec_consoldetl.* 
				IF glob_range IS NULL THEN 
					LET glob_range = "('", l_rec_consoldetl.flex_code clipped, "'" 
				ELSE 
					LET glob_range = glob_range clipped, ",'", 
					l_rec_consoldetl.flex_code clipped, "'" 
				END IF 
			END FOREACH 

			LET glob_range = glob_range clipped, ")" 
			# Run REPORT FOR consolidation group code
			LET modu_print_ledg = false 
			CALL build_report(l_rpt_idx,l_rec_consolhead.consol_code) 
			#
			IF glob_print_ledg = "Y" THEN 
				CLOSE c_consoldetl 
				OPEN c_consoldetl USING l_rec_consolhead.consol_code 
				FOREACH c_consoldetl INTO l_rec_consoldetl.* 
					# Run the REPORT FOR each consolidation ledger
					LET modu_print_ledg = true 
					LET glob_range = "('", l_rec_consoldetl.flex_code clipped, "')" 
					CALL build_report(l_rpt_idx,l_rec_consoldetl.flex_code) 
				END FOREACH 
			END IF 
		END FOREACH 
	ELSE 
		LET modu_print_ledg = false 
		CALL build_report(l_rpt_idx,l_rec_consolhead.consol_code) 
	END IF 


	#------------------------------------------------------------
	FINISH REPORT GW1_rpt_list_management
	CALL rpt_finish("GW1_rpt_list_management")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
			
END FUNCTION 


############################################################
# FUNCTION build_report(p_consol_code)
#
#
############################################################
FUNCTION build_report(p_rpt_idx,p_consol_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_consol_code LIKE consoldetl.flex_code 
	#DEFINE l_filename1 CHAR(20)
	DEFINE l_count SMALLINT 
	DEFINE l_pos SMALLINT 
	DEFINE l_s1 CHAR(1600) 
	DEFINE l_chart_slct LIKE gllinedetl.chart_clause 
	DEFINE l_analdown_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_clause LIKE gllinedetl.chart_clause 
	DEFINE l_chart_operator LIKE gllinedetl.operator 

	CALL clear_accum() 
	FOREACH rptline_curs INTO glob_rec_rptline.* 
		IF int_flag OR quit_flag THEN 
			EXIT FOREACH 
		END IF 
		INITIALIZE glob_rec_glline.* TO NULL 
		INITIALIZE glob_rec_calchead.* TO NULL 
		# Get the relevant line details
		CASE 
			WHEN glob_rec_rptline.line_type = glob_rec_mrwparms.gl_line_type 
				# SELECT always PRINT flag IF line IS a GL line.
				SELECT * INTO glob_rec_glline.* FROM glline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptline.rpt_id 
				AND line_uid = glob_rec_rptline.line_uid 
			WHEN glob_rec_rptline.line_type = glob_rec_mrwparms.calc_line_type 
				# SELECT always PRINT flag IF line IS a Calc. line.
				SELECT * INTO glob_rec_calchead.* FROM calchead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptline.rpt_id 
				AND line_uid = glob_rec_rptline.line_uid 
		END CASE 

		IF glob_rec_entry_criteria.detailed_rpt = "D" 
		AND glob_rec_rptline.line_type = glob_rec_mrwparms.gl_line_type THEN 
			IF glob_rec_rpthead.rpt_type = glob_rec_mrwparms.analdown_type THEN 
				LET l_analdown_clause = analdown_clause() 
			END IF 
			DECLARE gldetl_curs CURSOR FOR 
			SELECT chart_clause, operator, seq_num FROM gllinedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = glob_rec_rptline.line_uid 
			FOREACH gldetl_curs INTO l_chart_clause, l_chart_operator 
				LET l_chart_slct = build_chart( l_chart_clause ) 
				IF glob_report_type = "2" THEN 
					LET l_s1 = "SELECT unique coa.acct_code ", 
					" FROM coa, account, accounthistcur ", 
					" WHERE ", glob_entry_criteria clipped, 
					" AND account.cmpy_code = coa.cmpy_code ", 
					" AND account.acct_code = coa.acct_code " 
				ELSE 
					LET l_s1 = "SELECT unique coa.acct_code ", 
					" FROM coa, account, accounthist ", 
					" WHERE ", glob_entry_criteria clipped, 
					" AND account.cmpy_code = coa.cmpy_code ", 
					" AND account.acct_code = coa.acct_code " 
				END IF 
				IF glob_report_type = "2" THEN 
					LET l_s1 = l_s1 clipped, 
					" AND accounthistcur.cmpy_code = account.cmpy_code ", 
					" AND accounthistcur.acct_code = account.acct_code " 
				ELSE 
					LET l_s1 = l_s1 clipped, 
					" AND accounthist.cmpy_code = account.cmpy_code ", 
					" AND accounthist.acct_code = account.acct_code " 
				END IF 
				LET l_s1 = l_s1 clipped," ", l_chart_slct clipped, 
				glob_segment_criteria clipped, 
				l_analdown_clause clipped 
				IF glob_consolidations_exist THEN 
					LET l_s1 = l_s1 clipped, 
					" AND account.acct_code[",glob_start_num USING "&&",",", 
					glob_length_num USING "&&","] in ",glob_range clipped," ", 
					" ORDER BY coa.acct_code " 
				ELSE 
					LET l_s1 = l_s1 clipped, 
					" ORDER BY coa.acct_code " 
				END IF 
				PREPARE s_1 FROM l_s1 
				DECLARE acctcode_curs CURSOR FOR s_1 
				FOREACH acctcode_curs INTO glob_account_code 
					# Clear COLUMN item amounts.
					FOR l_count = 1 TO modu_kandoo_columns 
						LET glob_arr_colitem_amt[l_count] = 0 
					END FOR 
					LET l_pos = 1 
					FOREACH rptcol_curs INTO glob_rec_rptcol.* 
						
						#---------------------------------------------------------
						OUTPUT TO REPORT GW1_rpt_list_management(p_rpt_idx,
							glob_rec_rptline.*, 
							glob_rec_rptcol.*, 
							p_consol_code, 
							l_pos)  
						
						IF NOT rpt_int_flag_handler2(NULL,NULL,NULL,p_rpt_idx) THEN
							EXIT FOREACH 
						END IF 
						#---------------------------------------------------------								
						 
						LET l_pos = l_pos + glob_rec_rptcol.width 
					END FOREACH 
				END FOREACH 
			END FOREACH 
			CONTINUE FOREACH 
		END IF 

		#
		# Clear COLUMN item amounts.
		FOR l_count = 1 TO modu_kandoo_columns 
			LET glob_arr_colitem_amt[l_count] = 0 
		END FOR 
		LET l_pos = 1 
		FOREACH rptcol_curs INTO glob_rec_rptcol.* 

			#---------------------------------------------------------
			OUTPUT TO REPORT GW1_rpt_list_management(p_rpt_idx,
				glob_rec_rptline.*, 
				glob_rec_rptcol.*, 
				p_consol_code, 
				l_pos)  
			
			IF NOT rpt_int_flag_handler2(NULL,NULL,NULL,p_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	

			LET l_pos = l_pos + glob_rec_rptcol.width 
		END FOREACH 
	END FOREACH 
END FUNCTION 


############################################################
# REPORT GW1_rpt_list_management(p_rr_rptline, p_rr_rptcol, p_rv_consol_code, p_rv_pos)
#
#
############################################################
REPORT GW1_rpt_list_management(p_rpt_idx,p_rr_rptline, p_rr_rptcol, p_rv_consol_code, p_rv_pos) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rr_rptline RECORD LIKE rptline.* 
	DEFINE p_rr_rptcol RECORD LIKE rptcol.* 
	DEFINE p_rv_consol_code LIKE consoldetl.flex_code 
	DEFINE p_rv_pos SMALLINT 

	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 

	DEFINE l_gl_amt LIKE descline.line_desc 
	DEFINE l_accum_amt LIKE descline.line_desc 
	DEFINE l_external_amt LIKE descline.line_desc 
	DEFINE l_line_desc LIKE descline.line_desc 
	DEFINE l_under_line LIKE descline.line_desc 
	DEFINE l_line_detl CHAR(500) 
	DEFINE l_prn_flag SMALLINT 
	DEFINE l_non_zero SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_len INTEGER 
	DEFINE l_consol_pos INTEGER 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 
--	top margin 0 

	ORDER external BY p_rv_consol_code, 
	p_rr_rptline.line_id, 
	p_rr_rptcol.col_id 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

		BEFORE GROUP OF p_rv_consol_code 
			SKIP TO top OF PAGE 
		BEFORE GROUP OF p_rr_rptcol.col_id 
			IF p_rr_rptcol.col_id = 1 THEN 
				IF glob_rec_entry_criteria.detailed_rpt = "D" THEN 
					PRINT 
					LET l_prn_flag = true #default PRINT flag TO true. 
					LET l_non_zero = false 
				END IF 
			END IF 

		BEFORE GROUP OF p_rr_rptline.line_id 
			LET l_prn_flag = true #default PRINT flag TO true. 
			LET l_non_zero = false 
			# Number of lines TO drop.

		AFTER GROUP OF p_rr_rptline.line_id 
			IF NOT l_prn_flag THEN 
				LET p_rr_rptline.drop_lines = p_rr_rptline.drop_lines - 1 
			END IF 
			IF p_rr_rptline.page_break_follow = "Y" THEN 
				SKIP TO top OF PAGE 
			ELSE 
				FOR l_counter = 1 TO p_rr_rptline.drop_lines 
					PRINT 
				END FOR 
			END IF 

		ON EVERY ROW 
			#-----------------------------------------------------------------------------#
			# Report Header Section                                                       #
			#-----------------------------------------------------------------------------#
			IF lineno = 1 OR lineno = 0 THEN 
				IF glob_rec_rpthead.std_head_per_page = "Y" THEN 

						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
						PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

--					PRINT COLUMN 01, modu_maxcompany, 
--					COLUMN (glob_rec_rmsreps.report_width_num-20), "Date: ", today USING "ddd dd mmm yyyy" 
--					PRINT COLUMN 01, modu_kandoousername, 
--					COLUMN (glob_rec_rmsreps.report_width_num-20), "Time: ", modu_time[1,5] 
--					PRINT COLUMN (glob_rec_rmsreps.report_width_num-20), "Page No.: ", pageno USING "###" 
				END IF 
				IF glob_rec_rpthead.rpt_desc1 IS NOT NULL THEN 
					PRINT COLUMN modu_desc_pos1, glob_rec_rpthead.rpt_desc1 
				END IF 
				IF glob_rec_rpthead.rpt_desc2 IS NOT NULL THEN 
					PRINT COLUMN modu_desc_pos2, glob_rec_rpthead.rpt_desc2 
				END IF 
				IF p_rv_consol_code IS NOT NULL THEN 
					IF modu_print_ledg THEN 
						SELECT * INTO l_rec_structure.* FROM structure 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_ind = "L" 
						SELECT * INTO l_rec_validflex.* FROM validflex 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND start_num = l_rec_structure.start_num 
						AND flex_code = p_rv_consol_code 
						CASE 
							WHEN glob_rec_rpthead.rpt_desc_position = 'L' 
								LET l_consol_pos = 1 
							WHEN glob_rec_rpthead.rpt_desc_position = 'R' 
								LET l_len = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num  - 
								length(l_rec_validflex.desc_text) - 16 
								LET l_consol_pos = l_len 
							OTHERWISE 
								LET l_len = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num / 2) - 
								(length(l_rec_validflex.desc_text) / 2 ) - 8 
								LET l_consol_pos = l_len 
						END CASE 
						PRINT COLUMN l_consol_pos, "Ledger: ", 
						p_rv_consol_code clipped," ", 
						l_rec_validflex.desc_text 
					ELSE 
						SELECT * INTO l_rec_consolhead.* FROM consolhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND consol_code = p_rv_consol_code 
						CASE 
							WHEN glob_rec_rpthead.rpt_desc_position = 'L' 
								LET l_consol_pos = 1 
							WHEN glob_rec_rpthead.rpt_desc_position = 'R' 
								LET l_len = glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num - 
								length(l_rec_consolhead.desc_text) - 16 
								LET l_consol_pos = l_len 
							OTHERWISE 
								LET l_len = (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num / 2) - 
								(length(l_rec_consolhead.desc_text) / 2 ) - 8 
								LET l_consol_pos = l_len 
						END CASE 
						PRINT COLUMN l_consol_pos, "Group: ", 
						l_rec_consolhead.consol_code," ", 
						l_rec_consolhead.desc_text 
					END IF 
				END IF 

				PRINT COLUMN 01, modu_rpt_line clipped 

				IF glob_rec_rpthead.col_hdr_per_page = "Y" THEN 
					# Column description lines.  Build in FUNCTION col_hdr_desc().
					IF length( modu_col_desc1 ) > 0 THEN 
						PRINT COLUMN 01, modu_col_desc1 clipped 
					END IF 
					IF length( modu_col_desc2 ) > 0 THEN 
						PRINT COLUMN 01, modu_col_desc2 clipped 
					END IF 
					IF length( modu_col_desc3 ) > 0 THEN 
						PRINT COLUMN 01, modu_col_desc3 clipped 
					END IF 
					PRINT COLUMN 01, modu_rpt_line clipped 
				END IF 
				SKIP 1 line 
			END IF 
			#-----------------------------------------------------------------------------#
			# Main Processing Section                                                     #
			#-----------------------------------------------------------------------------#
			IF l_line_detl IS NULL THEN 
				LET l_line_detl = " " 
			END IF 

			CASE 
			#----------------------------------------------------------------------#
			# General Ledger Processing Section                                    #
			#----------------------------------------------------------------------#
				WHEN p_rr_rptline.line_type = glob_rec_mrwparms.gl_line_type 
					# Check IF GL line IS TO be printed.
					IF glob_rec_glline.always_print != "N" THEN 
						# Check IF description COLUMN
						IF desc_col(p_rr_rptcol.col_uid) THEN 
							IF p_rr_rptcol.width > 0 THEN 
								LET l_line_desc = col_desc(p_rr_rptline.line_uid, 
								p_rr_rptcol.col_uid, 
								p_rr_rptcol.width) 
								LET l_line_detl = l_line_detl[1,p_rv_pos], 
								l_line_desc clipped 
							END IF 
						ELSE 
							# Get COLUMN item amount FROM selection criteria.
							LET l_gl_amt = colitem_amt() 
							LET l_line_detl = l_line_detl[1,p_rv_pos], 
							l_gl_amt clipped 
							# Check IF GL line IS TO be printed.(O=Only PRINT Non-Zeros).
							IF glob_rec_glline.always_print = "O" THEN 
								IF NOT l_non_zero THEN 
									IF length(l_gl_amt) > 0 THEN 
										LET l_prn_flag = true 
										LET l_non_zero = true 
									ELSE 
										LET l_prn_flag = false 
									END IF 
								END IF 
							END IF 
						END IF 
					ELSE 
						# Calculate COLUMN item amount FROM selection criteria.
						LET l_gl_amt = colitem_amt() 
						LET l_prn_flag = false 
					END IF 
					#----------------------------------------------------------------------#
					# Accumulator Processing Section                                       #
					#----------------------------------------------------------------------#
				WHEN p_rr_rptline.line_type = glob_rec_mrwparms.calc_line_type 
					# Check IF Calc. line IS TO be printed.
					IF glob_rec_calchead.always_print != "N" THEN 
						# Check IF description COLUMN
						IF desc_col(p_rr_rptcol.col_uid) THEN 
							IF p_rr_rptcol.width > 0 THEN 
								LET l_line_desc = col_desc(p_rr_rptline.line_uid, 
								p_rr_rptcol.col_uid, 
								p_rr_rptcol.width) 
								LET l_line_detl = l_line_detl[1,p_rv_pos], 
								l_line_desc clipped 
							END IF 
						ELSE 
							# Print accumulators.
							LET l_accum_amt = column_accum_amt() 
							LET l_line_detl = l_line_detl[1,p_rv_pos], 
							l_accum_amt clipped 
							# Check IF GL line IS TO be printed.(O=Only PRINT Non-Zeros).
							IF glob_rec_calchead.always_print = "O" THEN 
								IF NOT l_non_zero THEN 
									IF length(l_accum_amt) > 0 THEN 
										LET l_prn_flag = true 
										LET l_non_zero = true 
									ELSE 
										LET l_prn_flag = false 
									END IF 
								END IF 
							END IF 
						END IF 
					ELSE 
						# Calculate COLUMN item amount FROM selection criteria.
						LET l_accum_amt = column_accum_amt() 
						LET l_prn_flag = false 
					END IF 
					#----------------------------------------------------------------------#
					# Underline Line Processing Section                                    #
					#----------------------------------------------------------------------#
				WHEN p_rr_rptline.line_type = glob_rec_mrwparms.under_line_type 
					# Print Underline.
					IF p_rr_rptcol.width > 0 THEN 
						LET l_under_line = under_line(p_rr_rptline.line_uid, 
						p_rr_rptcol.col_uid, 
						p_rr_rptcol.width, 
						p_rr_rptcol.amt_picture) 
						LET l_line_detl = l_line_detl[1,p_rv_pos], 
						l_under_line clipped 
					END IF 
					#----------------------------------------------------------------------#
					# Text/Title Line Processing Section                                   #
					#----------------------------------------------------------------------#
				WHEN p_rr_rptline.line_type = glob_rec_mrwparms.text_line_type 
					# Print COLUMN desciption only.
					IF p_rr_rptcol.width > 0 THEN 
						LET l_line_desc = col_desc(p_rr_rptline.line_uid, 
						p_rr_rptcol.col_uid, 
						p_rr_rptcol.width) 
						LET l_line_detl = l_line_detl[1,p_rv_pos], 
						l_line_desc clipped 
					END IF 
					#----------------------------------------------------------------------#
					# External Link Processing Section                                     #
					#----------------------------------------------------------------------#
				WHEN p_rr_rptline.line_type = glob_rec_mrwparms.ext_link_line_type 
					# Check IF description COLUMN
					IF desc_col(p_rr_rptcol.col_uid) THEN 
						IF p_rr_rptcol.width > 0 THEN 
							LET l_line_desc = col_desc(p_rr_rptline.line_uid, 
							p_rr_rptcol.col_uid, 
							p_rr_rptcol.width) 
							LET l_line_detl = l_line_detl[1,p_rv_pos], 
							l_line_desc clipped 
						END IF 
					ELSE 
						# Print external amount.
						LET l_external_amt = external_amt(p_rr_rptline.line_uid, 
						p_rr_rptcol.col_uid) 
						LET l_line_detl = l_line_detl[1,p_rv_pos], 
						l_external_amt clipped 
					END IF 
			END CASE 
			#Now Print Line.
			IF p_rr_rptcol.col_id = modu_kandoo_columns THEN 
				IF l_prn_flag THEN 
					PRINT l_line_detl clipped; 
				END IF 
				LET l_line_detl = " " 
			END IF 

		ON LAST ROW 
			SKIP TO top OF PAGE 
			IF glob_rec_rpthead.std_head_per_page = "Y" THEN 
				PRINT COLUMN 01, modu_maxcompany, 
				COLUMN (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num-20), "Date: ", today USING "ddd dd mmm yyyy" 
				PRINT COLUMN 01, modu_kandoousername, 
				COLUMN (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num-20), "Time: ", modu_time[1,5] 
				PRINT COLUMN (glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num-20), "Page No.: ", pageno USING "###" 
			END IF 
			IF glob_rec_rpthead.rpt_desc1 IS NOT NULL THEN 
				PRINT COLUMN modu_desc_pos1, glob_rec_rpthead.rpt_desc1 
			END IF 
			IF glob_rec_rpthead.rpt_desc2 IS NOT NULL THEN 
				PRINT COLUMN modu_desc_pos2, glob_rec_rpthead.rpt_desc2 
			END IF 
			PRINT COLUMN 01, modu_rpt_line clipped 

			IF glob_rec_rpthead.col_hdr_per_page = "Y" THEN 
				# Column description lines.  Build in FUNCTION col_hdr_desc().
				IF length( modu_col_desc1 ) > 0 THEN 
					PRINT COLUMN 01, modu_col_desc1 clipped 
				END IF 
				IF length( modu_col_desc2 ) > 0 THEN 
					PRINT COLUMN 01, modu_col_desc2 clipped 
				END IF 
				IF length( modu_col_desc3 ) > 0 THEN 
					PRINT COLUMN 01, modu_col_desc3 clipped 
				END IF 
				PRINT COLUMN 01, modu_rpt_line clipped 
			END IF 
			SKIP 1 line 

			#LET glob_rec_rmsreps.page_num = pageno 
			#LET glob_rpt_length = 66 
			SKIP 2 LINES 
			PRINT COLUMN 01, "Criteria: ", 
			COLUMN 14, glob_full_criteria clipped wordwrap right margin 90 
			SKIP 1 line 
			INITIALIZE l_rec_currency.* TO NULL 
			SELECT * INTO l_rec_currency.* FROM currency 
			WHERE currency_code = glob_curr_code 
			PRINT COLUMN 01, "Report Type: ", glob_report_type 
			PRINT COLUMN 01, "Currency: ", glob_curr_code, " ",l_rec_currency.desc_text 

			IF glob_report_type != "2" THEN 
				PRINT COLUMN 01, "Rate: ",glob_conv_qty USING "##&.&&&" 
			END IF 
			SKIP 3 LINES 

			IF (int_flag OR quit_flag) THEN 
				PRINT COLUMN ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num/2)-15), "---===== REPORT ABORTED =====---" 
			ELSE 
				PRINT COLUMN ((glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num/2)-15), "---===== END OF REPORT =====---" 
			END IF 

END REPORT 
