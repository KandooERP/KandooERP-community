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
GLOBALS "../gl/GGR_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_structure RECORD LIKE structure.*
	DEFINE modu_rec_coa RECORD LIKE coa.*
	DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE modu_rec_glsumdiv RECORD LIKE glsumdiv.*
	DEFINE modu_rec_glsummary RECORD LIKE glsummary.* 
	DEFINE modu_rec_glsumblock RECORD LIKE glsumblock.* 
	DEFINE modu_rec_data RECORD 
		cmpy_code LIKE accounthist.cmpy_code, 
		chart LIKE accounthist.acct_code, 
		acct_desc LIKE coa.desc_text, 
		block_code LIKE glsumblock.block_code, 
		block_desc LIKE glsumblock.desc_text, 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		summary_code LIKE glsummary.summary_code, 
		summary_desc LIKE glsummary.desc_text, 
		print_order LIKE glsummary.print_order, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD
	DEFINE modu_idx SMALLINT
	DEFINE modu_i SMALLINT
	 
	DEFINE modu_line1 CHAR(80)
	DEFINE modu_line2 CHAR(80)
	DEFINE modu_line3 CHAR(80)
	DEFINE modu_line4 CHAR(80)
	 
	DEFINE modu_query_text CHAR(200) 
	DEFINE modu_where_text CHAR(200) 
	DEFINE modu_arr_rec_temp array[4] OF RECORD 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE modu_rec_temp RECORD 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE modu_line_total DECIMAL(16,2) 
	DEFINE modu_arr_column array[9] OF RECORD 
		desc_text LIKE glsumdiv.desc_text 
	END RECORD 


############################################################
# FUNCTION GGR_main()
#
# GGR.4gl GL Segment Summary Report
############################################################
FUNCTION GGR_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("GGR") 

	CREATE temp TABLE summary (cmpy_code CHAR(2), 
	chart CHAR(18), 
	acct_desc CHAR(30), 
	block_code CHAR(4), 
	block_desc CHAR(40), 
	total_code CHAR(1), 
	total_seq SMALLINT, 
	summary_code CHAR(4), 
	summary_desc CHAR(40), 
	print_order SMALLINT, 
	l_col1_amt DECIMAL(14,2), 
	l_col2_amt DECIMAL(14,2), 
	l_col3_amt DECIMAL(14,2), 
	l_col4_amt DECIMAL(14,2), 
	l_col5_amt DECIMAL(14,2), 
	l_col6_amt DECIMAL(14,2), 
	l_col7_amt DECIMAL(14,2), 
	l_col8_amt DECIMAL(14,2), 
	l_col9_amt DECIMAL(14,2)) 

	OPEN WINDOW G212 with FORM "G212" 
	CALL windecoration_g("G212") 

	MENU "GL Summary Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GGR","menu-gl-summary-REPORT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 		#COMMAND "Run Report" " SELECT Criteria AND Print Report"
			IF GGR_rpt_query() THEN 
			END IF 

		ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" 		#COMMAND KEY (interrupt, "E") "Exit" " Exit TO Menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G212 
END FUNCTION 


############################################################
# FUNCTION GGR_rpt_query()
#
#
############################################################
FUNCTION GGR_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_segment LIKE accounthist.acct_code 
	DEFINE l_chart LIKE accounthist.acct_code
	--DEFINE l_temp_amt LIKE accounthist.debit_amt 
	DEFINE l_pos_code SMALLINT
	DEFINE l_div_start_num LIKE glsumdiv.start_num
	DEFINE l_report_level LIKE glsumdiv.report_level_ind 
	DEFINE l_div_length_num SMALLINT
	DEFINE l_div_end_num SMALLINT
	DEFINE l_coa_start_num SMALLINT 
	DEFINE l_coa_end_num SMALLINT 

	DELETE FROM summary WHERE 1=1 

	SELECT unique start_num, 
	report_level_ind 
	INTO l_div_start_num, 
	l_report_level 
	FROM glsumdiv 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR","Segment locations have NOT been SET up - Add them AND retry!\nExit Program","ERROR") 
		EXIT PROGRAM 
	END IF 

	SELECT length_num 
	INTO l_div_length_num 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = l_div_start_num 
	AND type_ind = "S" 
	IF status = NOTFOUND THEN 
		ERROR "Location Segment start NOT defined in chart structure" 
		SLEEP 10 
		EXIT PROGRAM 
	END IF 
	LET l_div_end_num = l_div_start_num + l_div_length_num - 1 

	CLEAR FORM 
	MESSAGE " Enter Criteria FOR Selection - Press ESC TO Begin Report" 

	CONSTRUCT modu_where_text ON accounthist.year_num, 
	accounthist.period_num 
	FROM year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GCR","construct-accounthist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 



	SELECT * 
	INTO modu_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 
	IF status = NOTFOUND THEN 
		ERROR "Chart of Accounts have NOT been SET up - Add them AND retry" 
		SLEEP 10 
		EXIT PROGRAM 
	END IF 
	LET l_coa_start_num = modu_rec_structure.start_num 
	LET l_coa_end_num = modu_rec_structure.start_num + modu_rec_structure.length_num - 1 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"GGR_rpt_list",modu_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GGR_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------



	# Set up heading data

	LET modu_i = 0 
	DECLARE c_glsumdiv CURSOR FOR 
	SELECT pos_code, 
	desc_text 
	INTO modu_rec_glsumdiv.pos_code, 
	modu_rec_glsumdiv.desc_text 
	FROM glsumdiv 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY pos_code 

	FOREACH c_glsumdiv 
		LET modu_i = modu_i + 1 
		IF modu_i > 9 THEN 
			EXIT FOREACH 
		END IF 
		LET modu_arr_column[modu_i].desc_text = modu_rec_glsumdiv.desc_text 
	END FOREACH 
	
	LET modu_line1 = 
		today clipped, 
		10 spaces, 
		glob_rec_company.cmpy_code, 
		2 spaces, 
		glob_rec_company.name_text clipped 


	LET modu_query_text = "SELECT * ", 
	"FROM accounthist ", 
	"WHERE accounthist.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", modu_where_text clipped 
	PREPARE q_accounthist FROM modu_query_text 
	DECLARE c_accounthist CURSOR FOR q_accounthist 
	FOREACH c_accounthist INTO modu_rec_accounthist.* 
		LET l_segment = 
		modu_rec_accounthist.acct_code[l_div_start_num, l_div_end_num] 
		LET l_chart = 
		modu_rec_accounthist.acct_code[l_coa_start_num, l_coa_end_num] 

		SELECT * 
		INTO modu_rec_coa.* 
		FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = modu_rec_accounthist.acct_code 

		LET l_pos_code = NULL 
		SELECT pos_code 
		INTO l_pos_code 
		FROM glsumdiv 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND (div1_code IS NOT NULL AND div1_code = l_segment) 
		OR (div2_code IS NOT NULL AND div2_code = l_segment) 
		OR (div3_code IS NOT NULL AND div3_code = l_segment) 
		OR (div4_code IS NOT NULL AND div4_code = l_segment) 
		OR (div5_code IS NOT NULL AND div5_code = l_segment) 
		OR (div6_code IS NOT NULL AND div2_code = l_segment) 
		OR (div7_code IS NOT NULL AND div3_code = l_segment) 
		OR (div8_code IS NOT NULL AND div4_code = l_segment) 
		OR (div9_code IS NOT NULL AND div5_code = l_segment) 

		IF l_pos_code IS NOT NULL AND modu_rec_coa.group_code IS NOT NULL THEN 
			SELECT * 
			INTO modu_rec_glsumblock.* 
			FROM glsumblock 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND group_code = modu_rec_coa.group_code 
			IF status = NOTFOUND THEN 
				#force the next SELECT stmnt AND IF stmnt test TO fail
				LET modu_rec_glsumblock.summary_code = NULL 
				LET modu_rec_glsumblock.block_code = NULL 
			END IF 

			SELECT * 
			INTO modu_rec_glsummary.* 
			FROM glsummary 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND summary_code = modu_rec_glsumblock.summary_code 

			IF modu_rec_glsumblock.block_code IS NOT NULL THEN 
				LET modu_rec_data.cmpy_code = modu_rec_accounthist.cmpy_code 
				LET modu_rec_data.chart = l_chart 
				LET modu_rec_data.acct_desc = modu_rec_coa.desc_text 
				LET modu_rec_data.summary_code = modu_rec_glsummary.summary_code 
				LET modu_rec_data.summary_desc = modu_rec_glsummary.desc_text 
				LET modu_rec_data.print_order = modu_rec_glsummary.print_order 
				LET modu_rec_data.block_code = modu_rec_glsumblock.block_code 
				LET modu_rec_data.block_desc = modu_rec_glsumblock.desc_text 
				LET modu_rec_data.total_code = modu_rec_glsumblock.total_code 
				CASE modu_rec_data.total_code 
					WHEN "S" 
						LET modu_rec_data.total_seq = 1 
					WHEN "C" 
						LET modu_rec_data.total_seq = 2 
					WHEN "modu_i" 
						LET modu_rec_data.total_seq = 3 
					WHEN "E" 
						LET modu_rec_data.total_seq = 4 
				END CASE 
				LET modu_rec_data.col1_amt = 0 
				LET modu_rec_data.col2_amt = 0 
				LET modu_rec_data.col3_amt = 0 
				LET modu_rec_data.col4_amt = 0 
				LET modu_rec_data.col5_amt = 0 
				LET modu_rec_data.col6_amt = 0 
				LET modu_rec_data.col7_amt = 0 
				LET modu_rec_data.col8_amt = 0 
				LET modu_rec_data.col9_amt = 0 

				CASE l_pos_code 
					WHEN 1 
						LET modu_rec_data.col1_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 2 
						LET modu_rec_data.col2_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 3 
						LET modu_rec_data.col3_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 4 
						LET modu_rec_data.col4_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 5 
						LET modu_rec_data.col5_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 6 
						LET modu_rec_data.col6_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 7 
						LET modu_rec_data.col7_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 8 
						LET modu_rec_data.col8_amt = modu_rec_accounthist.ytd_pre_close_amt 
					WHEN 9 
						LET modu_rec_data.col9_amt = modu_rec_accounthist.ytd_pre_close_amt 
				END CASE 
				INSERT INTO summary VALUES (modu_rec_data.*) 
			END IF 
		END IF 
	END FOREACH 



	IF l_report_level = "2" OR l_report_level = "3" THEN 
		SLEEP 1 #to avoid same date/time 

	
		#------------------------------------------------------------

		LET l_rpt_idx = rpt_start("GGR-2","GGR_rpt_list2",modu_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GGR_rpt_list2 TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		#------------------------------------------------------------

	END IF 
--	DISPLAY "" at 1,2 
--	DISPLAY "Account: " at 1,2 

	DECLARE outcurs CURSOR FOR 
	SELECT * 
	INTO modu_rec_data.* 
	FROM summary 
	WHERE 1 = 1 
	ORDER BY summary.print_order, 
	summary.summary_code, 
	summary.block_code, 
	summary.chart 
	
	FOREACH outcurs 
		OUTPUT TO REPORT GGR_rpt_list (l_rpt_idx,modu_rec_data.*) 
		IF l_report_level = "2" OR 
		l_report_level = "3" THEN 
			OUTPUT TO REPORT GGR_rpt_list2 (l_rpt_idx,modu_rec_data.*) 
		END IF 
		--DISPLAY modu_rec_data.chart TO lblabel1 -- 1,11 

	END FOREACH
	 
	FINISH REPORT GGR_rpt_list
	#------------------------------------------------------------
	FINISH REPORT GGR_rpt_list
	CALL rpt_finish("GGR_rpt_list")
	#------------------------------------------------------------
	 
	IF l_report_level = "2" OR l_report_level = "3" THEN 
	#------------------------------------------------------------
	FINISH REPORT GGR_rpt_list2
	CALL rpt_finish("GGR_rpt_list2")
	#------------------------------------------------------------ 
	END IF 

	IF l_report_level = "3" THEN 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("GGR-3","GGR_rpt_list3",modu_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GGR_rpt_list3 TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

		 
		DECLARE out3curs CURSOR FOR 
		SELECT total_code, 
		total_seq, 
		sum(l_col1_amt), 
		sum(l_col2_amt), 
		sum(l_col3_amt), 
		sum(l_col4_amt), 
		sum(l_col5_amt), 
		sum(l_col6_amt), 
		sum(l_col7_amt), 
		sum(l_col8_amt), 
		sum(l_col9_amt) 
		INTO modu_rec_temp.* 
		FROM summary 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND total_code IS NOT NULL 
		GROUP BY summary.total_code, summary.total_seq 
		ORDER BY summary.total_seq 

		FOREACH out3curs 
			LET modu_idx = modu_rec_temp.total_seq 
			LET modu_arr_rec_temp[modu_idx].col1_amt = modu_rec_temp.col1_amt 
			LET modu_arr_rec_temp[modu_idx].col2_amt = modu_rec_temp.col2_amt 
			LET modu_arr_rec_temp[modu_idx].col3_amt = modu_rec_temp.col3_amt 
			LET modu_arr_rec_temp[modu_idx].col4_amt = modu_rec_temp.col4_amt 
			LET modu_arr_rec_temp[modu_idx].col5_amt = modu_rec_temp.col5_amt 
			LET modu_arr_rec_temp[modu_idx].col6_amt = modu_rec_temp.col6_amt 
			LET modu_arr_rec_temp[modu_idx].col7_amt = modu_rec_temp.col7_amt 
			LET modu_arr_rec_temp[modu_idx].col8_amt = modu_rec_temp.col8_amt 
			LET modu_arr_rec_temp[modu_idx].col9_amt = modu_rec_temp.col9_amt 
		END FOREACH 

		FOR modu_i = 1 TO 4 
			IF modu_i = 1 THEN 
				LET modu_rec_temp.total_code = "S" 
				LET modu_rec_temp.total_seq = 1 
			END IF 
			IF modu_i = 2 THEN 
				LET modu_rec_temp.total_code = "C" 
				LET modu_rec_temp.total_seq = 2 
			END IF 
			IF modu_i = 3 THEN 
				LET modu_rec_temp.total_code = "modu_i" 
				LET modu_rec_temp.total_seq = 3 
			END IF 
			IF modu_i = 4 THEN 
				LET modu_rec_temp.total_code = "E" 
				LET modu_rec_temp.total_seq = 4 
			END IF 

			IF modu_arr_rec_temp[modu_i].col1_amt IS NULL THEN 
				LET modu_rec_temp.col1_amt = 0 
				LET modu_rec_temp.col2_amt = 0 
				LET modu_rec_temp.col3_amt = 0 
				LET modu_rec_temp.col4_amt = 0 
				LET modu_rec_temp.col5_amt = 0 
				LET modu_rec_temp.col6_amt = 0 
				LET modu_rec_temp.col7_amt = 0 
				LET modu_rec_temp.col8_amt = 0 
				LET modu_rec_temp.col9_amt = 0 
				LET modu_line_total = 0 
			ELSE 
				LET modu_rec_temp.col1_amt = modu_arr_rec_temp[modu_i].col1_amt 
				LET modu_rec_temp.col2_amt = modu_arr_rec_temp[modu_i].col2_amt 
				LET modu_rec_temp.col3_amt = modu_arr_rec_temp[modu_i].col3_amt 
				LET modu_rec_temp.col4_amt = modu_arr_rec_temp[modu_i].col4_amt 
				LET modu_rec_temp.col5_amt = modu_arr_rec_temp[modu_i].col5_amt 
				LET modu_rec_temp.col6_amt = modu_arr_rec_temp[modu_i].col6_amt 
				LET modu_rec_temp.col7_amt = modu_arr_rec_temp[modu_i].col7_amt 
				LET modu_rec_temp.col8_amt = modu_arr_rec_temp[modu_i].col8_amt 
				LET modu_rec_temp.col9_amt = modu_arr_rec_temp[modu_i].col9_amt 
				LET modu_line_total = modu_rec_temp.col1_amt + 
				modu_rec_temp.col2_amt + 
				modu_rec_temp.col3_amt + 
				modu_rec_temp.col4_amt + 
				modu_rec_temp.col5_amt + 
				modu_rec_temp.col6_amt + 
				modu_rec_temp.col7_amt + 
				modu_rec_temp.col8_amt + 
				modu_rec_temp.col9_amt 
			END IF 
			OUTPUT TO REPORT GGR_rpt_list3 (l_rpt_idx,modu_rec_temp.*, modu_line_total) 
		END FOR 
	#------------------------------------------------------------
	FINISH REPORT GGR_rpt_list3
	CALL rpt_finish("GGR_rpt_list3")
	#------------------------------------------------------------
	END IF 


	RETURN true 
END FUNCTION 


############################################################
# REPORT GGR_rpt_list(p_rec_data) 
#
#
############################################################
REPORT GGR_rpt_list(p_rpt_idx,p_rec_data) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_data RECORD 
		cmpy_code LIKE accounthist.cmpy_code, 
		chart LIKE accounthist.acct_code, 
		acct_desc LIKE coa.desc_text, 
		block_code LIKE glsumblock.block_code, 
		block_desc LIKE glsumblock.desc_text, 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		summary_code LIKE glsummary.summary_code, 
		summary_desc LIKE glsummary.desc_text, 
		print_order LIKE glsummary.print_order, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE l_col1_amt DECIMAL(14,2) 
	DEFINE l_col2_amt DECIMAL(14,2) 
	DEFINE l_col3_amt DECIMAL(14,2) 
	DEFINE l_col4_amt DECIMAL(14,2) 
	DEFINE l_col5_amt DECIMAL(14,2) 
	DEFINE l_col6_amt DECIMAL(14,2) 
	DEFINE l_col7_amt DECIMAL(14,2) 
	DEFINE l_col8_amt DECIMAL(14,2) 
	DEFINE l_col9_amt DECIMAL(14,2) 
	DEFINE l_line_total DECIMAL(14,2) 

	OUTPUT 

	left margin 0 

	ORDER external BY p_rec_data.print_order, 
	p_rec_data.summary_code, 
	p_rec_data.block_code, 
	p_rec_data.chart 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		AFTER GROUP OF p_rec_data.chart 
			LET l_col1_amt = GROUP sum(p_rec_data.col1_amt) 
			LET l_col2_amt = GROUP sum(p_rec_data.col2_amt) 
			LET l_col3_amt = GROUP sum(p_rec_data.col3_amt) 
			LET l_col4_amt = GROUP sum(p_rec_data.col4_amt) 
			LET l_col5_amt = GROUP sum(p_rec_data.col5_amt) 
			LET l_col6_amt = GROUP sum(p_rec_data.col6_amt) 
			LET l_col7_amt = GROUP sum(p_rec_data.col7_amt) 
			LET l_col8_amt = GROUP sum(p_rec_data.col8_amt) 
			LET l_col9_amt = GROUP sum(p_rec_data.col9_amt) 
			IF l_col1_amt != 0 OR 
			l_col2_amt != 0 OR 
			l_col3_amt != 0 OR 
			l_col4_amt != 0 OR 
			l_col5_amt != 0 OR 
			l_col6_amt != 0 OR 
			l_col7_amt != 0 OR 
			l_col8_amt != 0 OR 
			l_col9_amt != 0 THEN 
				LET l_line_total = l_col1_amt + 
				l_col2_amt + 
				l_col3_amt + 
				l_col4_amt + 
				l_col5_amt + 
				l_col6_amt + 
				l_col7_amt + 
				l_col8_amt + 
				l_col9_amt 
				PRINT COLUMN 01, p_rec_data.acct_desc[1,30], 
				COLUMN 32, l_col1_amt USING "----------&.&&", 
				COLUMN 47, l_col2_amt USING "----------&.&&", 
				COLUMN 62, l_col3_amt USING "----------&.&&", 
				COLUMN 77, l_col4_amt USING "----------&.&&", 
				COLUMN 92, l_col5_amt USING "----------&.&&", 
				COLUMN 107, l_col6_amt USING "----------&.&&", 
				COLUMN 122, l_col7_amt USING "----------&.&&", 
				COLUMN 135, l_col8_amt USING "----------&.&&", 
				COLUMN 152, l_col9_amt USING "----------&.&&", 
				COLUMN 167, l_line_total USING "-----------&.&&" 
			END IF 

		BEFORE GROUP OF p_rec_data.block_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_data.block_code 
			NEED 3 LINES 
			SKIP 1 line 
			LET l_col1_amt = GROUP sum(p_rec_data.col1_amt) 
			LET l_col2_amt = GROUP sum(p_rec_data.col2_amt) 
			LET l_col3_amt = GROUP sum(p_rec_data.col3_amt) 
			LET l_col4_amt = GROUP sum(p_rec_data.col4_amt) 
			LET l_col5_amt = GROUP sum(p_rec_data.col5_amt) 
			LET l_col6_amt = GROUP sum(p_rec_data.col6_amt) 
			LET l_col7_amt = GROUP sum(p_rec_data.col7_amt) 
			LET l_col8_amt = GROUP sum(p_rec_data.col8_amt) 
			LET l_col9_amt = GROUP sum(p_rec_data.col9_amt) 
			LET l_line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 01, p_rec_data.block_desc[1,30], 
			COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, l_line_total USING "-----------&.&&" 


		AFTER GROUP OF p_rec_data.summary_code 
			NEED 3 LINES 
			LET l_col1_amt = GROUP sum(p_rec_data.col1_amt) 
			LET l_col2_amt = GROUP sum(p_rec_data.col2_amt) 
			LET l_col3_amt = GROUP sum(p_rec_data.col3_amt) 
			LET l_col4_amt = GROUP sum(p_rec_data.col4_amt) 
			LET l_col5_amt = GROUP sum(p_rec_data.col5_amt) 
			LET l_col6_amt = GROUP sum(p_rec_data.col6_amt) 
			LET l_col7_amt = GROUP sum(p_rec_data.col7_amt) 
			LET l_col8_amt = GROUP sum(p_rec_data.col8_amt) 
			LET l_col9_amt = GROUP sum(p_rec_data.col9_amt) 
			PRINT COLUMN 32, "--------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" ---------------" 
			LET l_line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 01, p_rec_data.summary_desc[1,30], 
			COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, l_line_total USING "-----------&.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 8 LINES 
			SKIP 3 LINES 
			LET l_col1_amt = sum(p_rec_data.col1_amt) 
			LET l_col2_amt = sum(p_rec_data.col2_amt) 
			LET l_col3_amt = sum(p_rec_data.col3_amt) 
			LET l_col4_amt = sum(p_rec_data.col4_amt) 
			LET l_col5_amt = sum(p_rec_data.col5_amt) 
			LET l_col6_amt = sum(p_rec_data.col6_amt) 
			LET l_col7_amt = sum(p_rec_data.col7_amt) 
			LET l_col8_amt = sum(p_rec_data.col8_amt) 
			LET l_col9_amt = sum(p_rec_data.col9_amt) 
			PRINT COLUMN 32, "==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ===============" 
			LET l_line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, l_line_total USING "-----------&.&&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 


############################################################
# REPORT GGR_rpt_list2(p_rec_data)  
#
#
############################################################
REPORT GGR_rpt_list2(p_rpt_idx,p_rec_data) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_data RECORD 
		cmpy_code LIKE accounthist.cmpy_code, 
		chart LIKE accounthist.acct_code, 
		acct_desc LIKE coa.desc_text, 
		block_code LIKE glsumblock.block_code, 
		block_desc LIKE glsumblock.desc_text, 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		summary_code LIKE glsummary.summary_code, 
		summary_desc LIKE glsummary.desc_text, 
		print_order LIKE glsummary.print_order, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE l_col1_amt DECIMAL(14,2) 
	DEFINE l_col2_amt DECIMAL(14,2) 
	DEFINE l_col3_amt DECIMAL(14,2) 
	DEFINE l_col4_amt DECIMAL(14,2) 
	DEFINE l_col5_amt DECIMAL(14,2) 
	DEFINE l_col6_amt DECIMAL(14,2) 
	DEFINE l_col7_amt DECIMAL(14,2) 
	DEFINE l_col8_amt DECIMAL(14,2) 
	DEFINE l_col9_amt DECIMAL(14,2) 
	DEFINE line_total DECIMAL(14,2) 

	OUTPUT 
--	left margin 0 

	ORDER external BY p_rec_data.print_order, 
	p_rec_data.summary_code, 
	p_rec_data.block_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_data.block_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_data.block_code 
			NEED 2 LINES 
			LET l_col1_amt = GROUP sum(p_rec_data.col1_amt) 
			LET l_col2_amt = GROUP sum(p_rec_data.col2_amt) 
			LET l_col3_amt = GROUP sum(p_rec_data.col3_amt) 
			LET l_col4_amt = GROUP sum(p_rec_data.col4_amt) 
			LET l_col5_amt = GROUP sum(p_rec_data.col5_amt) 
			LET l_col6_amt = GROUP sum(p_rec_data.col6_amt) 
			LET l_col7_amt = GROUP sum(p_rec_data.col7_amt) 
			LET l_col8_amt = GROUP sum(p_rec_data.col8_amt) 
			LET l_col9_amt = GROUP sum(p_rec_data.col9_amt) 
			LET line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 01, p_rec_data.block_desc[1,30], 
			COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, line_total USING "-----------&.&&" 


		AFTER GROUP OF p_rec_data.summary_code 
			NEED 3 LINES 
			LET l_col1_amt = GROUP sum(p_rec_data.col1_amt) 
			LET l_col2_amt = GROUP sum(p_rec_data.col2_amt) 
			LET l_col3_amt = GROUP sum(p_rec_data.col3_amt) 
			LET l_col4_amt = GROUP sum(p_rec_data.col4_amt) 
			LET l_col5_amt = GROUP sum(p_rec_data.col5_amt) 
			LET l_col6_amt = GROUP sum(p_rec_data.col6_amt) 
			LET l_col7_amt = GROUP sum(p_rec_data.col7_amt) 
			LET l_col8_amt = GROUP sum(p_rec_data.col8_amt) 
			LET l_col9_amt = GROUP sum(p_rec_data.col9_amt) 
			PRINT COLUMN 32, "--------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" --------------", 
			" ---------------" 
			LET line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 01, p_rec_data.summary_desc[1,30], 
			COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, line_total USING "-----------&.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 8 LINES 
			SKIP 3 LINES 
			LET l_col1_amt = sum(p_rec_data.col1_amt) 
			LET l_col2_amt = sum(p_rec_data.col2_amt) 
			LET l_col3_amt = sum(p_rec_data.col3_amt) 
			LET l_col4_amt = sum(p_rec_data.col4_amt) 
			LET l_col5_amt = sum(p_rec_data.col5_amt) 
			LET l_col6_amt = sum(p_rec_data.col6_amt) 
			LET l_col7_amt = sum(p_rec_data.col7_amt) 
			LET l_col8_amt = sum(p_rec_data.col8_amt) 
			LET l_col9_amt = sum(p_rec_data.col9_amt) 
			PRINT COLUMN 32, "==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ===============" 
			LET line_total = l_col1_amt + 
			l_col2_amt + 
			l_col3_amt + 
			l_col4_amt + 
			l_col5_amt + 
			l_col6_amt + 
			l_col7_amt + 
			l_col8_amt + 
			l_col9_amt 
			PRINT COLUMN 32, l_col1_amt USING "----------&.&&", 
			COLUMN 47, l_col2_amt USING "----------&.&&", 
			COLUMN 62, l_col3_amt USING "----------&.&&", 
			COLUMN 77, l_col4_amt USING "----------&.&&", 
			COLUMN 92, l_col5_amt USING "----------&.&&", 
			COLUMN 107, l_col6_amt USING "----------&.&&", 
			COLUMN 122, l_col7_amt USING "----------&.&&", 
			COLUMN 135, l_col8_amt USING "----------&.&&", 
			COLUMN 152, l_col9_amt USING "----------&.&&", 
			COLUMN 167, line_total USING "-----------&.&&" 

			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 


############################################################
# REPORT GGR_rpt_list3(p_rec_temp, p_line_total)   
#
#
############################################################
REPORT GGR_rpt_list3(p_rpt_idx,p_rec_temp, p_line_total)
 	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_temp RECORD 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE p_line_total DECIMAL(14,2) 

	DEFINE l_tot_amt DECIMAL(14,2) 
	DEFINE l_tot_col1 DECIMAL(14,2) 
	DEFINE l_tot_col2 DECIMAL(14,2) 
	DEFINE l_tot_col3 DECIMAL(14,2) 
	DEFINE l_tot_col4 DECIMAL(14,2) 
	DEFINE l_tot_col5 DECIMAL(14,2) 
	DEFINE l_tot_col6 DECIMAL(14,2) 
	DEFINE l_tot_col7 DECIMAL(14,2) 
	DEFINE l_tot_col8 DECIMAL(14,2) 
	DEFINE l_tot_col9 DECIMAL(14,2) 

	OUTPUT 
--	left margin 0 

	ORDER external BY p_rec_temp.total_seq 

	FORMAT 

		PAGE HEADER 
			LET l_tot_amt = 0 
			LET l_tot_col1 = 0 
			LET l_tot_col2 = 0 
			LET l_tot_col3 = 0 
			LET l_tot_col4 = 0 
			LET l_tot_col5 = 0 
			LET l_tot_col6 = 0 
			LET l_tot_col7 = 0 
			LET l_tot_col8 = 0 
			LET l_tot_col9 = 0 
			
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Description", 
			COLUMN 36, modu_arr_column[1].desc_text, 
			COLUMN 51, modu_arr_column[2].desc_text, 
			COLUMN 66, modu_arr_column[3].desc_text, 
			COLUMN 81, modu_arr_column[4].desc_text, 
			COLUMN 96, modu_arr_column[5].desc_text, 
			COLUMN 111, modu_arr_column[6].desc_text, 
			COLUMN 126, modu_arr_column[7].desc_text, 
			COLUMN 139, modu_arr_column[8].desc_text, 
			COLUMN 156, modu_arr_column[9].desc_text, 
			COLUMN 175, "Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		AFTER GROUP OF p_rec_temp.total_seq 
			IF p_rec_temp.total_seq = 1 THEN 
				SKIP 1 line 
				PRINT COLUMN 01, " Total Sales ", 
				COLUMN 32, p_rec_temp.col1_amt USING "----------&.&&", 
				COLUMN 47, p_rec_temp.col2_amt USING "----------&.&&", 
				COLUMN 62, p_rec_temp.col3_amt USING "----------&.&&", 
				COLUMN 77, p_rec_temp.col4_amt USING "----------&.&&", 
				COLUMN 92, p_rec_temp.col5_amt USING "----------&.&&", 
				COLUMN 107, p_rec_temp.col6_amt USING "----------&.&&", 
				COLUMN 122, p_rec_temp.col7_amt USING "----------&.&&", 
				COLUMN 135, p_rec_temp.col8_amt USING "----------&.&&", 
				COLUMN 152, p_rec_temp.col9_amt USING "----------&.&&", 
				COLUMN 167, p_line_total USING "-----------&.&&" 
				LET l_tot_amt = p_line_total 
				LET l_tot_col1 = p_rec_temp.col1_amt 
				LET l_tot_col2 = p_rec_temp.col2_amt 
				LET l_tot_col3 = p_rec_temp.col3_amt 
				LET l_tot_col4 = p_rec_temp.col4_amt 
				LET l_tot_col5 = p_rec_temp.col5_amt 
				LET l_tot_col6 = p_rec_temp.col6_amt 
				LET l_tot_col7 = p_rec_temp.col7_amt 
				LET l_tot_col8 = p_rec_temp.col8_amt 
				LET l_tot_col9 = p_rec_temp.col9_amt 
			END IF 


			IF p_rec_temp.total_seq = 2 THEN 
				PRINT COLUMN 01, "less Cost of Sales ", 
				COLUMN 32, p_rec_temp.col1_amt USING "----------&.&&", 
				COLUMN 47, p_rec_temp.col2_amt USING "----------&.&&", 
				COLUMN 62, p_rec_temp.col3_amt USING "----------&.&&", 
				COLUMN 77, p_rec_temp.col4_amt USING "----------&.&&", 
				COLUMN 92, p_rec_temp.col5_amt USING "----------&.&&", 
				COLUMN 107, p_rec_temp.col6_amt USING "----------&.&&", 
				COLUMN 122, p_rec_temp.col7_amt USING "----------&.&&", 
				COLUMN 135, p_rec_temp.col8_amt USING "----------&.&&", 
				COLUMN 152, p_rec_temp.col9_amt USING "----------&.&&", 
				COLUMN 167, p_line_total USING "-----------&.&&" 
				PRINT COLUMN 32, "--------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" --------------", 
				" ---------------" 
				LET l_tot_amt = l_tot_amt + p_line_total 
				LET l_tot_col1 = l_tot_col1 + p_rec_temp.col1_amt 
				LET l_tot_col2 = l_tot_col2 + p_rec_temp.col2_amt 
				LET l_tot_col3 = l_tot_col3 + p_rec_temp.col3_amt 
				LET l_tot_col4 = l_tot_col4 + p_rec_temp.col4_amt 
				LET l_tot_col5 = l_tot_col5 + p_rec_temp.col5_amt 
				LET l_tot_col6 = l_tot_col6 + p_rec_temp.col6_amt 
				LET l_tot_col7 = l_tot_col7 + p_rec_temp.col7_amt 
				LET l_tot_col8 = l_tot_col8 + p_rec_temp.col8_amt 
				LET l_tot_col9 = l_tot_col9 + p_rec_temp.col9_amt 
				PRINT COLUMN 32, l_tot_col1 USING "----------&.&&", 
				COLUMN 47, l_tot_col2 USING "----------&.&&", 
				COLUMN 62, l_tot_col3 USING "----------&.&&", 
				COLUMN 77, l_tot_col4 USING "----------&.&&", 
				COLUMN 92, l_tot_col5 USING "----------&.&&", 
				COLUMN 107, l_tot_col6 USING "----------&.&&", 
				COLUMN 122, l_tot_col7 USING "----------&.&&", 
				COLUMN 135, l_tot_col8 USING "----------&.&&", 
				COLUMN 152, l_tot_col9 USING "----------&.&&", 
				COLUMN 167, l_tot_amt USING "-----------&.&&" 
				SKIP 1 LINES 
			END IF 

			IF p_rec_temp.total_seq = 3 THEN 
				PRINT COLUMN 01, "plus Sundry Income ", 
				COLUMN 32, p_rec_temp.col1_amt USING "----------&.&&", 
				COLUMN 47, p_rec_temp.col2_amt USING "----------&.&&", 
				COLUMN 62, p_rec_temp.col3_amt USING "----------&.&&", 
				COLUMN 77, p_rec_temp.col4_amt USING "----------&.&&", 
				COLUMN 92, p_rec_temp.col5_amt USING "----------&.&&", 
				COLUMN 107, p_rec_temp.col6_amt USING "----------&.&&", 
				COLUMN 122, p_rec_temp.col7_amt USING "----------&.&&", 
				COLUMN 135, p_rec_temp.col8_amt USING "----------&.&&", 
				COLUMN 152, p_rec_temp.col9_amt USING "----------&.&&", 
				COLUMN 167, p_line_total USING "-----------&.&&" 
				LET l_tot_amt = l_tot_amt + p_line_total 
				LET l_tot_col1 = l_tot_col1 + p_rec_temp.col1_amt 
				LET l_tot_col2 = l_tot_col2 + p_rec_temp.col2_amt 
				LET l_tot_col3 = l_tot_col3 + p_rec_temp.col3_amt 
				LET l_tot_col4 = l_tot_col4 + p_rec_temp.col4_amt 
				LET l_tot_col5 = l_tot_col5 + p_rec_temp.col5_amt 
				LET l_tot_col6 = l_tot_col6 + p_rec_temp.col6_amt 
				LET l_tot_col7 = l_tot_col7 + p_rec_temp.col7_amt 
				LET l_tot_col8 = l_tot_col8 + p_rec_temp.col8_amt 
				LET l_tot_col9 = l_tot_col9 + p_rec_temp.col9_amt 
			END IF 



			IF p_rec_temp.total_seq = 4 THEN 
				PRINT COLUMN 01, "less Expenses ", 
				COLUMN 32, p_rec_temp.col1_amt USING "----------&.&&", 
				COLUMN 47, p_rec_temp.col2_amt USING "----------&.&&", 
				COLUMN 62, p_rec_temp.col3_amt USING "----------&.&&", 
				COLUMN 77, p_rec_temp.col4_amt USING "----------&.&&", 
				COLUMN 92, p_rec_temp.col5_amt USING "----------&.&&", 
				COLUMN 107, p_rec_temp.col6_amt USING "----------&.&&", 
				COLUMN 122, p_rec_temp.col7_amt USING "----------&.&&", 
				COLUMN 135, p_rec_temp.col8_amt USING "----------&.&&", 
				COLUMN 152, p_rec_temp.col9_amt USING "----------&.&&", 
				COLUMN 167, p_line_total USING "-----------&.&&" 
				LET l_tot_amt = l_tot_amt + p_line_total 
				LET l_tot_col1 = l_tot_col1 + p_rec_temp.col1_amt 
				LET l_tot_col2 = l_tot_col2 + p_rec_temp.col2_amt 
				LET l_tot_col3 = l_tot_col3 + p_rec_temp.col3_amt 
				LET l_tot_col4 = l_tot_col4 + p_rec_temp.col4_amt 
				LET l_tot_col5 = l_tot_col5 + p_rec_temp.col5_amt 
				LET l_tot_col6 = l_tot_col6 + p_rec_temp.col6_amt 
				LET l_tot_col7 = l_tot_col7 + p_rec_temp.col7_amt 
				LET l_tot_col8 = l_tot_col8 + p_rec_temp.col8_amt 
				LET l_tot_col9 = l_tot_col9 + p_rec_temp.col9_amt 
			END IF 

		ON LAST ROW 
			PRINT COLUMN 32, "==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ==============", 
			" ===============" 
			PRINT COLUMN 32, l_tot_col1 USING "----------&.&&", 
			COLUMN 47, l_tot_col2 USING "----------&.&&", 
			COLUMN 62, l_tot_col3 USING "----------&.&&", 
			COLUMN 77, l_tot_col4 USING "----------&.&&", 
			COLUMN 92, l_tot_col5 USING "----------&.&&", 
			COLUMN 107, l_tot_col6 USING "----------&.&&", 
			COLUMN 122, l_tot_col7 USING "----------&.&&", 
			COLUMN 135, l_tot_col8 USING "----------&.&&", 
			COLUMN 152, l_tot_col9 USING "----------&.&&", 
			COLUMN 167, l_tot_amt USING "-----------&.&&" 
			SKIP 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			

END REPORT