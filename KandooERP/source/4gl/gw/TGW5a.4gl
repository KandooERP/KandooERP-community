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

	Source code beautified by beautify.pl on 2020-01-03 10:10:05	$Id: $
}




#     This module contains the functions TO produce the
#     the definitions REPORT.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW5_GLOBALS.4gl" 

FUNCTION def_rpthdr() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("TGW5-H","TGW5_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT TGW5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	INITIALIZE gr_rptcolgrp.* TO NULL 
	INITIALIZE gr_rptlinegrp.* TO NULL 


	#------------------------------------------------------------
	OUTPUT TO REPORT TGW5_rpt_list(l_rpt_idx,gr_rpthead.*,gr_rptcolgrp.*,gr_rptlinegrp.*,"HEADER") 
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT TGW5_rpt_list
	CALL rpt_finish("TGW5_rpt_list")
	#------------------------------------------------------------

	IF gv_colline = "Y" OR gv_colline = "y" THEN 
		CALL column_curs() 
		CALL line_curs() 
	END IF 


END FUNCTION 


FUNCTION def_rptcolgrp() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("TGW5-C","TGW5_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT TGW5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	IF gv_colline = "N" THEN 
		INITIALIZE gr_rpthead.* TO NULL 
		INITIALIZE gr_rptlinegrp.* TO NULL 
	END IF 

 	#------------------------------------------------------------
	OUTPUT TO REPORT TGW5_rpt_list(l_rpt_idx,gr_rpthead.*,gr_rptcolgrp.*,gr_rptlinegrp.*,"COLUMN") 
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT TGW5_rpt_list
	CALL rpt_finish("TGW5_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


FUNCTION def_line_range() 

	OPEN WINDOW g578 with FORM "TG578" 
	CALL windecoration_t("TG578") -- albo kd-768 

	LET gv_from_line_id = 0 
	LET gv_to_line_id = 2000 
	LET int_flag = false 
	LET quit_flag = false 

	#MESSAGE "ACC TO accept, INT TO abort"
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT gv_from_line_id, gv_to_line_id 
	WITHOUT DEFAULTS 
	FROM from_line_id, to_line_id 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW5a","input-gv_from_line_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	CLOSE WINDOW g578 

END FUNCTION 

FUNCTION def_rptlinegrp() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		ERROR "Report aborted" 
	ELSE 

		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("TGW5-L","TGW5_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT TGW5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------

		IF gv_colline = "N" THEN 
			INITIALIZE gr_rptcolgrp.* TO NULL 
			INITIALIZE gr_rpthead.* TO NULL 
		END IF 

		#------------------------------------------------------------
		OUTPUT TO REPORT TGW5_rpt_list(l_rpt_idx,gr_rpthead.*,gr_rptcolgrp.*,gr_rptlinegrp.*,"LINE") 
		#------------------------------------------------------------

		#------------------------------------------------------------
		FINISH REPORT TGW5_rpt_list
		CALL rpt_finish("TGW5_rpt_list")
		#------------------------------------------------------------
	END IF 



END FUNCTION 


# FUNCTION TO RETURN the COLUMN description.
FUNCTION column_desc(fv_col_uid, fv_line) 

	DEFINE fr_rptcoldesc RECORD LIKE rptcoldesc.*, 
	fv_col_uid LIKE rptcol.col_uid, 
	fv_line INTEGER 

	# SELECT COLUMN description line 1
	SELECT col_desc 
	INTO fr_rptcoldesc.col_desc 
	FROM rptcoldesc 
	WHERE col_uid = fv_col_uid 
	AND seq_num = fv_line 

	RETURN fr_rptcoldesc.col_desc 

END FUNCTION 


# FUNCTION TO RETURN the type of year OR period number.
#     eg. Offset OR Specific.
FUNCTION date_type( fv_type ) 

	DEFINE fv_type LIKE colitemdetl.year_type 

	IF fv_type = gr_mrwparms.offset_type THEN 
		RETURN "Offset" 
	ELSE 
		RETURN "Specific" 
	END IF 
END FUNCTION 

# FUNCTION TO RETURN the COLUMN desciption text.
FUNCTION line_desc(fv_line_uid) 

	DEFINE fv_line_uid LIKE rptline.line_uid, 
	fv_line_desc LIKE descline.line_desc 


	SELECT line_desc 
	INTO fv_line_desc 
	FROM descline 
	WHERE line_uid = fv_line_uid 

	RETURN fv_line_desc 

END FUNCTION 

REPORT TGW5_rpt_list(p_rpt_idx,rr_rpthead,rr_rptcolgrp,rr_rptlinegrp,rv_section) #MRW
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE rr_rpthead RECORD LIKE rpthead.*, 
	rr_rptcolgrp RECORD LIKE rptcolgrp.*, 
	rr_rptlinegrp RECORD LIKE rptlinegrp.*, 
	rr_rptcol RECORD LIKE rptcol.*, 
	rr_rptline RECORD LIKE rptline.* , 
	rr_rptpos RECORD LIKE rptpos.*, 
	rr_rpttype RECORD LIKE rpttype.*, 
	rr_rndcode RECORD LIKE rndcode.*, 
	rr_signcode RECORD LIKE signcode.*, 
	rr_mrwitem RECORD LIKE mrwitem.*, 
	rr_colitem RECORD LIKE colitem.*, 
	rr_colitemdetl RECORD LIKE colitemdetl.*, 
	rr_colitemcolid RECORD LIKE colitemcolid.*, 
	rr_colitemval RECORD LIKE colitemval.*, 
	rr_rptcolaa RECORD LIKE rptcolaa.*, 
	rr_segline RECORD LIKE segline.*, 
	rr_gllinedetl RECORD LIKE gllinedetl.*, 
	rr_calchead RECORD LIKE calchead.*, 
	rr_calcline RECORD LIKE calcline.*, 
	rr_glline RECORD LIKE glline.*, 
	rr_exthead RECORD LIKE exthead.*, 
	rr_extline RECORD LIKE extline.*, 
	rv_time CHAR(8), 
	rv_section CHAR(10), 
	rv_kandoousername LIKE kandoouser.name_text, 
	rv_maxcompany LIKE company.name_text, 
	rv_desc_text LIKE warehouse.desc_text, 
	#      rv_item_type      LIKE mrwitem.item_type,
	rv_line_desc LIKE descline.line_desc, 
	rv_txttype_desc LIKE txttype.txttype_desc, 
	rv_col_id LIKE rptcol.col_id, 
	line1 CHAR(80), 
	offset1, 
	rv_first_loop, 
	rv_counter SMALLINT 

	OUTPUT 
	left margin 0 
	top margin 0 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

			LET rv_time = time 


			SELECT name_text 
			INTO rv_kandoousername 
			FROM kandoouser 
			WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

			SELECT name_text 
			INTO rv_maxcompany 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 


			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			CASE 
				WHEN rv_section = "HEADER" 
					PRINT "Header Definitions "; 
				WHEN rv_section = "COLUMN" 
					PRINT "Column Definitions "; 
				WHEN rv_section = "LINE" 
					PRINT "Line Definitions "; 
			END CASE 

			FOR rv_counter = 1 TO 112 
				PRINT "-"; 
			END FOR 

			SKIP 2 LINES 


		ON EVERY ROW 

			#+-----------------------------------------------------------+
			#|  Header Definitions.                                      |
			#+-----------------------------------------------------------+
			CASE 
				WHEN rv_section = "HEADER" 
					PRINT COLUMN 01, "Report Id........: ", rr_rpthead.rpt_id, 
					COLUMN 34, rr_rpthead.rpt_text 

					PRINT COLUMN 01, "Description......:", 
					COLUMN 34, rr_rpthead.rpt_desc1 
					PRINT COLUMN 34, rr_rpthead.rpt_desc2 

					PRINT 

					PRINT COLUMN 04, "Column Code...:", 
					COLUMN 34, rr_rpthead.col_code 
					PRINT COLUMN 04, "Line Code.....:", 
					COLUMN 34, rr_rpthead.line_code 

					SELECT * 
					INTO rr_rptpos.* 
					FROM rptpos 
					WHERE rptpos_id = rr_rpthead.rpt_desc_position 

					PRINT COLUMN 04, "Position......:", 
					COLUMN 34, rr_rptpos.rptpos_desc 

					SELECT * 
					INTO rr_rndcode.* 
					FROM rndcode 
					WHERE rnd_code = rr_rpthead.rnd_code 

					PRINT COLUMN 04, "Rounding......:", 
					COLUMN 34, rr_rndcode.rnd_desc 

					SELECT * 
					INTO rr_signcode.* 
					FROM signcode 
					WHERE sign_code = rr_rpthead.sign_code 

					PRINT COLUMN 04, "Sign Code.....:", 
					COLUMN 34, rr_signcode.sign_desc 

					PRINT COLUMN 04, "Always Print..:"; 
					IF rr_rpthead.always_print_line = "O" THEN 
						PRINT COLUMN 34, "Only PRINT non-zeros" 
					ELSE 
						PRINT COLUMN 34, "Default TO Line definition's" 
					END IF 

					PRINT COLUMN 04, "Account Grp...:", 
					COLUMN 34, rr_rpthead.acct_grp 

					PRINT COLUMN 04, "Column Header.:"; 
					IF rr_rpthead.col_hdr_per_page = "Y" THEN 
						PRINT COLUMN 34, "On every page" 
					ELSE 
						PRINT COLUMN 34, "First page only" 
					END IF 

					PRINT COLUMN 04, "Report Header.:"; 
					IF rr_rpthead.std_head_per_page = "Y" THEN 
						PRINT COLUMN 34, "On every page" 
					ELSE 
						PRINT COLUMN 34, "First page only" 
					END IF 


					#+-----------------------------------------------------------+
					#|     Column Definitions.                                   |
					#+-----------------------------------------------------------+
				WHEN rv_section = "COLUMN" 
					PRINT COLUMN 01, "Column Code.......: ", rr_rptcolgrp.col_code, 
					COLUMN 33, rr_rptcolgrp.colgrp_desc 
					PRINT 

					DECLARE col_curs CURSOR FOR 
					SELECT * 
					FROM rptcol 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND col_code = rr_rptcolgrp.col_code 
					ORDER BY col_id 

					DECLARE colitem_curs CURSOR FOR 
					SELECT * 
					FROM colitem 
					WHERE col_uid = rr_rptcol.col_uid 
					ORDER BY seq_num 

					FOREACH col_curs INTO rr_rptcol.* 
						MESSAGE "Compiling Report, please wait...", rr_rptcol.col_id 
						LET rv_first_loop = true 

						PRINT COLUMN 01, "Column............: ", 
						rr_rptcol.col_id USING "<<<<<<" 
						PRINT COLUMN 04, "Description....: ", 
						column_desc(rr_rptcol.col_uid, 1) 

						IF column_desc(rr_rptcol.col_uid, 2) IS NOT NULL THEN 
							PRINT COLUMN 21, column_desc(rr_rptcol.col_uid, 2) 
						END IF 

						IF column_desc(rr_rptcol.col_uid, 3) IS NOT NULL THEN 
							PRINT COLUMN 21, column_desc(rr_rptcol.col_uid, 3) 
						END IF 

						PRINT 

						PRINT COLUMN 04, "Width..........: ", 
						rr_rptcol.width USING "<<<<<&" 
						PRINT COLUMN 04, "Amount Format..: ", rr_rptcol.amt_picture 

						PRINT COLUMN 04, "Currency Type..: "; 
						IF rr_rptcol.curr_type = "B" THEN 
							PRINT COLUMN 21, "Base" 
						ELSE 
							PRINT COLUMN 21, "Transaction" 
						END IF 

						PRINT COLUMN 04, "Print Indicator: "; 
						IF rr_rptcol.print_flag = "Y" THEN 
							PRINT COLUMN 21, "Always PRINT COLUMN" 
						ELSE 
							PRINT COLUMN 21, "Never PRINT COLUMN" 
						END IF 

						#Check FOR any analysis across records.
						IF rr_rptcolgrp.colrptg_type = gr_mrwparms.analacross_type THEN 
							DECLARE colaa_curs CURSOR FOR 
							SELECT * 
							FROM rptcolaa 
							WHERE col_uid = rr_rptcol.col_uid 
							ORDER BY seq_num 

							FOREACH colaa_curs INTO rr_rptcolaa.* 
								IF rv_first_loop THEN 
									PRINT COLUMN 04, "Segment........: "; 
									LET rv_first_loop = false 
								END IF 
								PRINT COLUMN 21, "Start..: ", 
								COLUMN 30, rr_rptcolaa.start_num USING "<<&", 
								COLUMN 35,"Clause....:", rr_rptcolaa.flex_clause 
							END FOREACH 
						END IF 

						PRINT COLUMN 04, "Column Item...: "; 

						FOREACH colitem_curs INTO rr_colitem.* 
							#Get the item_type FROM mrwitem table.
							SELECT mrwitem.* 
							INTO rr_mrwitem.* 
							FROM mrwitem 
							WHERE item_id = rr_colitem.col_item 

							CASE 
								WHEN gr_mrwparms.time_item_type = rr_mrwitem.item_type 
									#SELECT colitemdetl details.
									SELECT * 
									INTO rr_colitemdetl.* 
									FROM colitemdetl 
									WHERE col_uid = rr_rptcol.col_uid 
									AND seq_num = rr_colitem.seq_num 

									PRINT COLUMN 21, rr_colitem.item_operator, 
									COLUMN 23, rr_mrwitem.item_desc, 
									COLUMN 59, "Year: ", 
									rr_colitemdetl.year_num USING "-<<&", 
									COLUMN 71, date_type( rr_colitemdetl.year_type ), 
									COLUMN 86, "Period: ", 
									rr_colitemdetl.period_num USING "-<<&", 
									COLUMN 99, date_type( rr_colitemdetl.period_type ) 

								WHEN gr_mrwparms.column_item_type = rr_mrwitem.item_type 
									#SELECT colitemcolid details.
									SELECT * 
									INTO rr_colitemcolid.* 
									FROM colitemcolid 
									WHERE col_uid = rr_rptcol.col_uid 
									AND seq_num = rr_colitem.seq_num 

									PRINT COLUMN 21, rr_colitem.item_operator, 
									COLUMN 23, "Column....: ", 
									rr_colitemcolid.id_col_id USING "-<<&" 

								WHEN gr_mrwparms.value_item_type = rr_mrwitem.item_type 
									#SELECT colitemval details.
									SELECT * 
									INTO rr_colitemval.* 
									FROM colitemval 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND col_code = rr_rptcol.col_code 
									AND col_uid = rr_rptcol.col_uid 
									AND seq_num = rr_colitem.seq_num 

									PRINT COLUMN 21, rr_colitem.item_operator, 
									COLUMN 23, "Constant Value.....: ", 
									rr_colitemval.item_value 
									USING "--------&.&&" 
								OTHERWISE 
									PRINT COLUMN 21, rr_mrwitem.item_desc 
							END CASE 
						END FOREACH 

						SKIP 1 line 
					END FOREACH 

					#+-----------------------------------------------------------+
					#|     Line Definitions.                                     |
					#+-----------------------------------------------------------+
				WHEN rv_section = "LINE" 
					PRINT COLUMN 01, "Line Code....: ", rr_rptlinegrp.line_code, 
					COLUMN 30, rr_rptlinegrp.linegrp_desc 
					PRINT 

					PRINT COLUMN 01, "Line", 
					COLUMN 06, "Type", 
					COLUMN 15, "Description / Chart Clause", 
					COLUMN 77, "Accum", 
					COLUMN 84, "Page", 
					COLUMN 90, "Drop", 
					COLUMN 97, "Always", 
					COLUMN 105, "Print in", 
					COLUMN 114, "Exp", 
					COLUMN 119, "Consol/" 
					PRINT COLUMN 84, "Break", 
					COLUMN 90, "Lines", 
					COLUMN 97, "Print", 
					COLUMN 105, "Offset", 
					COLUMN 114, "Sign", 
					COLUMN 119, "Detailed" 

					FOR rv_counter = 1 TO 132 
						PRINT "-"; 
					END FOR 

					SKIP 1 line 

					DECLARE line_curs CURSOR FOR 
					SELECT * 
					FROM rptline 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND line_code = rr_rptlinegrp.line_code 
					AND line_id between gv_from_line_id AND gv_to_line_id 
					ORDER BY line_id 

					FOREACH line_curs INTO rr_rptline.* 
						MESSAGE "Compiling Report, please wait...", rr_rptline.line_id 
						LET rv_first_loop = true 

						PRINT COLUMN 02, rr_rptline.line_id USING "<<<<", 
						COLUMN 06, rr_rptline.line_type; 

						CASE 
						# Underline
							WHEN rr_rptline.line_type = gr_mrwparms.under_line_type 
								SELECT txttype.txttype_desc 
								INTO rv_txttype_desc 
								FROM txtline, 
								txttype 
								WHERE txtline.line_uid = rr_rptline.line_uid 
								AND txttype.txttype_id = txtline.txt_type 

								PRINT COLUMN 15, rv_txttype_desc clipped, 
								COLUMN 86, rr_rptline.page_break_follow, 
								COLUMN 82, rr_rptline.drop_lines 

								# Text line
							WHEN rr_rptline.line_type = gr_mrwparms.text_line_type 
								LET rv_line_desc = line_desc(rr_rptline.line_uid) 

								PRINT COLUMN 15, rv_line_desc, 
								COLUMN 68, rr_rptline.accum_id, 
								COLUMN 86, rr_rptline.page_break_follow, 
								COLUMN 82, rr_rptline.drop_lines 

								# Calculation
							WHEN rr_rptline.line_type = gr_mrwparms.calc_line_type 
								SELECT * 
								INTO rr_calchead.* 
								FROM calchead 
								WHERE line_uid = rr_rptline.line_uid 

								LET rv_line_desc = line_desc(rr_rptline.line_uid) 

								PRINT COLUMN 15, rv_line_desc, 
								COLUMN 68, rr_rptline.accum_id, 
								COLUMN 86, rr_rptline.page_break_follow, 
								COLUMN 82, rr_rptline.drop_lines, 
								COLUMN 99, rr_calchead.always_print, 
								COLUMN 107, rr_calchead.print_in_offset, 
								COLUMN 115, rr_calchead.expected_sign 

								CASE 
									WHEN rr_calchead.curr_type = "B" 
										PRINT COLUMN 15, "Base amount always" 
									WHEN rr_calchead.curr_type = "T" 
										PRINT COLUMN 15, "Transaction amount always" 
								END CASE 

								DECLARE calc_curs CURSOR FOR 
								SELECT * 
								FROM calcline 
								WHERE line_uid = rr_rptline.line_uid 
								ORDER BY seq_num 

								FOREACH calc_curs INTO rr_calcline.* 
									PRINT COLUMN 15, rr_calcline.operator, 
									COLUMN 17, rr_calcline.accum_id USING "<<<<" 
								END FOREACH 


								# External line
							WHEN rr_rptline.line_type = gr_mrwparms.ext_link_line_type 
								SELECT * 
								INTO rr_exthead.* 
								FROM exthead 
								WHERE line_uid = rr_rptline.line_uid 

								LET rv_line_desc = line_desc(rr_rptline.line_uid) 

								PRINT COLUMN 15, rv_line_desc, 
								COLUMN 68, rr_rptline.accum_id, 
								COLUMN 86, rr_rptline.page_break_follow, 
								COLUMN 82, rr_rptline.drop_lines, 
								COLUMN 99, rr_exthead.always_print, 
								COLUMN 115, rr_exthead.expected_sign 

								DECLARE ext_curs CURSOR FOR 
								SELECT * 
								FROM extline 
								WHERE line_uid = rr_rptline.line_uid 
								ORDER BY ext_cmpy_code, 
								ext_line_code, 
								ext_accum_id 

								FOREACH ext_curs INTO rr_extline.* 
									PRINT COLUMN 15, "glob_rec_kandoouser.cmpy_code/Line Code:", 
									COLUMN 31, rr_extline.cmpy_code, 
									COLUMN 34, rr_extline.ext_line_code, 
									COLUMN 45, "Accum: ",rr_extline.ext_accum_id 
									USING "<<<&"; 
								END FOREACH 

								# GL line
							WHEN rr_rptline.line_type = gr_mrwparms.gl_line_type 
								SELECT * 
								INTO rr_glline.* 
								FROM glline 
								WHERE line_uid = rr_rptline.line_uid 

								LET rv_line_desc = line_desc(rr_rptline.line_uid) 

								PRINT COLUMN 15, rv_line_desc, 
								COLUMN 68, rr_rptline.accum_id, 
								COLUMN 86, rr_rptline.page_break_follow, 
								COLUMN 82, rr_rptline.drop_lines, 
								COLUMN 99, rr_glline.always_print, 
								COLUMN 107, rr_glline.print_in_offset, 
								COLUMN 115, rr_glline.expected_sign, 
								COLUMN 122, rr_glline.detl_flag 

								IF rr_glline.curr_code IS NOT NULL THEN 
									PRINT COLUMN 06, "Curr: ", 
									COLUMN 15, rr_glline.curr_code 
								END IF 

								DECLARE gldetl_curs CURSOR FOR 
								SELECT * 
								FROM gllinedetl 
								WHERE line_uid = rr_rptline.line_uid 
								ORDER BY seq_num 

								FOREACH gldetl_curs INTO rr_gllinedetl.* 
									PRINT COLUMN 06, "Chart:", 
									COLUMN 15, rr_gllinedetl.operator, 
									COLUMN 17, rr_gllinedetl.chart_clause 
								END FOREACH 

								DECLARE segline_curs CURSOR FOR 
								SELECT * 
								FROM segline 
								WHERE line_uid = rr_rptline.line_uid 
								ORDER BY seq_num 

								FOREACH segline_curs INTO rr_segline.* 
									IF rv_first_loop THEN 
										PRINT COLUMN 06, "Segment: "; 
										LET rv_first_loop = false 
									END IF 
									PRINT COLUMN 15, "Start: ", 
									COLUMN 24, rr_segline.start_num USING "<&" 
									PRINT COLUMN 15, "Clause: ", 
									COLUMN 24, rr_segline.flex_clause[1,40]; 
									IF rr_segline.flex_clause[41,60] IS NULL 
									OR rr_segline.flex_clause[41,60] = " " THEN 
										PRINT 
									ELSE 
										PRINT COLUMN 65, ".." 
									END IF 
								END FOREACH 
						END CASE 
						PRINT 
					END FOREACH 
			END CASE 

		ON LAST ROW 
			SKIP 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
