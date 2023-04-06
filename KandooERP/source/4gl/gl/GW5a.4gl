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
GLOBALS "../gl/GW5_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_to_line_id SMALLINT 

############################################################
# FUNCTION GW5_rpt_def_rpthdr()
#
# #     This module contains the functions TO produce the
#     the definitions REPORT.
############################################################
FUNCTION GW5_rpt_def_rpthdr() 
	DEFINE l_rpt_idx SMALLINT  
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"GW5_rpt_list_def","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GW5_rpt_list_def TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	#---------------------------------------------------------
	OUTPUT TO REPORT GW5_rpt_list_def(l_rpt_idx,glob_rec_rpthead.*, "HEADER") 
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT GW5_rpt_list_def
	CALL rpt_finish("GW5_rpt_list_def")
	#------------------------------------------------------------

END FUNCTION 


############################################################
# FUNCTION GW5_rpt_def_rptcol()
#
#
############################################################
FUNCTION GW5_rpt_def_rptcol() 
	DEFINE l_rpt_idx SMALLINT  
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"GW5_rpt_list_def","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GW5_rpt_list_def TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	#DISPLAY " Reporting on Report Column : " TO lblabel1 -- 1,2 
	
	#---------------------------------------------------------
	OUTPUT TO REPORT GW5_rpt_list_def(l_rpt_idx,glob_rec_rpthead.*, "COLUMN") 
	#---------------------------------------------------------
	
	#------------------------------------------------------------
	FINISH REPORT GW5_rpt_list_def
	CALL rpt_finish("GW5_rpt_list_def")
	#------------------------------------------------------------
END FUNCTION 


############################################################
# FUNCTION GW5_rpt_def_rptline()
#
#
############################################################
FUNCTION GW5_rpt_def_rptline() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rpt_idx SMALLINT
	
	OPEN WINDOW g529 with FORM "G529" 
	CALL windecoration_g("G529") 

	LET glob_from_line_id = 0 
	LET modu_to_line_id = 2000 
	LET int_flag = false 
	LET quit_flag = false 

	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	INPUT glob_from_line_id, modu_to_line_id 
	WITHOUT DEFAULTS 
	FROM from_line_id, to_line_id 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW5a","inp-from_line_id") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	CLOSE WINDOW g529 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	ELSE 


  
		#"GL Reportwriter Line Definitions"
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"GW5_rpt_list_def","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GW5_rpt_list_def TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		#------------------------------------------------------------
	
		#---------------------------------------------------------
		OUTPUT TO REPORT GW5_rpt_list_def(l_rpt_idx,glob_rec_rpthead.*, "LINE") 
		#---------------------------------------------------------
	
		#------------------------------------------------------------
		FINISH REPORT GW5_rpt_list_def
		CALL rpt_finish("GW5_rpt_list_def")
		#------------------------------------------------------------

	END IF 

END FUNCTION 


############################################################
# FUNCTION column_desc(p_col_uid, p_line)
#
#
############################################################
FUNCTION column_desc(p_col_uid, p_line) 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE p_line INTEGER 
	DEFINE l_rptcoldesc RECORD LIKE rptcoldesc.* 

	# SELECT COLUMN descripton line 1
	SELECT col_desc INTO l_rptcoldesc.col_desc FROM rptcoldesc 
	WHERE col_uid = p_col_uid 
	AND seq_num = p_line 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	RETURN l_rptcoldesc.col_desc 
END FUNCTION 



############################################################
# FUNCTION date_type(p_type)
#
# FUNCTION TO RETURN the type of year OR period number.
#     eg. Offset OR Specific.
############################################################
FUNCTION date_type(p_type) 
	DEFINE p_type LIKE colitemdetl.year_type 

	IF p_type = glob_rec_mrwparms.offset_type THEN 
		RETURN "Offset" 
	ELSE 
		RETURN "Specific" 
	END IF 
END FUNCTION 



############################################################
# FUNCTION col_desc(p_line_uid, p_col_uid)
#
# FUNCTION TO RETURN the COLUMN desciption text.
############################################################
FUNCTION col_desc(p_line_uid, p_col_uid) 
	DEFINE p_line_uid LIKE rptline.line_uid 
	DEFINE p_col_uid LIKE rptcol.col_uid 
	DEFINE l_line_desc LIKE descline.line_desc 

	SELECT line_desc INTO l_line_desc FROM descline 
	WHERE line_uid = p_line_uid 
	AND col_uid = p_col_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	RETURN l_line_desc 
END FUNCTION 



############################################################
# FUNCTION accum_id(fv_line_uid)
#
# FUNCTION TO RETURN the Accumulator Id.
############################################################
FUNCTION accum_id(fv_line_uid) 
	DEFINE fv_line_uid LIKE rptline.line_uid 
	DEFINE fv_accum_id LIKE saveline.accum_id 

	#SELECT the accumulator number
	SELECT saveline.accum_id INTO fv_accum_id FROM saveline 
	WHERE line_uid = fv_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF fv_accum_id = 0 THEN 
		LET fv_accum_id = NULL 
	END IF 

	RETURN fv_accum_id 

END FUNCTION 


############################################################
# REPORT GW5_rpt_list_def(l_rec_rpthead, l_section)
#
#
############################################################
REPORT GW5_rpt_list_def(p_rpt_idx,l_rec_rpthead, l_section)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE l_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE l_rec_rptcol RECORD LIKE rptcol.* 
	DEFINE l_rec_rptline RECORD LIKE rptline.* 

	DEFINE l_rec_rptpos RECORD LIKE rptpos.* 
	DEFINE l_rec_rpttype RECORD LIKE rpttype.* 
	DEFINE l_rec_rndcode RECORD LIKE rndcode.* 
	DEFINE l_rec_signcode RECORD LIKE signcode.* 

	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.* 
	DEFINE l_rec_colitem RECORD LIKE colitem.* 
	DEFINE l_rec_colitemdetl RECORD LIKE colitemdetl.* 
	DEFINE l_rec_colitemcolid RECORD LIKE colitemcolid.* 
	DEFINE l_rec_colitemval RECORD LIKE colitemval.* 
	DEFINE l_rec_rptcolaa RECORD LIKE rptcolaa.* 
	DEFINE l_rec_segline RECORD LIKE segline.* 
	DEFINE l_rec_gllinedetl RECORD LIKE gllinedetl.* 
	DEFINE l_rec_calcline RECORD LIKE calcline.* 

	DEFINE l_time CHAR(8) 
	DEFINE l_section CHAR(10) 
	DEFINE l_kandoousername LIKE kandoouser.name_text 
	DEFINE l_maxcompany LIKE company.name_text 
	--	DEFINE l_desc_text         LIKE warehouse.desc_text
	DEFINE l_item_type LIKE mrwitem.item_type 
	DEFINE l_line_desc LIKE descline.line_desc 
	--	DEFINE l_accum_id          LIKE saveline.accum_id
	DEFINE l_txttype_desc LIKE txttype.txttype_desc 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_line1 CHAR(80) 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_glprn_line SMALLINT 
	DEFINE l_calprn_line SMALLINT 
	DEFINE l_extprn_line SMALLINT 
	DEFINE l_prn_line SMALLINT 
	DEFINE l_counter SMALLINT 

	DEFINE l_rec_extline RECORD 
		col_id LIKE rptcol.col_id, 
		ext_cmpy_code LIKE extline.ext_cmpy_code, 
		ext_rpt_id LIKE extline.ext_rpt_id, 
		ext_col_uid LIKE rptcol.col_uid, 
		ext_accum_id LIKE extline.ext_accum_id 
	END RECORD 

	OUTPUT 
	left margin 0 
	top margin 0 

	FORMAT 

		PAGE HEADER 
			LET l_time = time 

			SELECT name_text INTO l_kandoousername FROM kandoouser 
			WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

			SELECT name_text INTO l_maxcompany FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			SKIP 1 line 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			CASE 
				WHEN l_section = "HEADER" 
					PRINT "Header Definitions "; 
				WHEN l_section = "COLUMN" 
					PRINT "Column Definitions "; 
				WHEN l_section = "LINE" 
					PRINT "Line Definitions "; 
			END CASE 

			FOR l_counter = 1 TO 109 
				PRINT "-"; 
			END FOR 

			SKIP 2 LINES 


		ON EVERY ROW 

			#+-----------------------------------------------------------+
			#|  Header Definitions.                                      |
			#+-----------------------------------------------------------+
			CASE 
				WHEN l_section = "HEADER" 

					DISPLAY l_rec_rpthead.rpt_id at 1,32 

					PRINT COLUMN 01, "Report Id....: ", l_rec_rpthead.rpt_id, 
					COLUMN 30, l_rec_rpthead.rpt_text 

					PRINT COLUMN 01, "Descripton...:", 
					COLUMN 30, l_rec_rpthead.rpt_desc1 
					PRINT COLUMN 30, l_rec_rpthead.rpt_desc2 

					# Description Position.
					SELECT * INTO l_rec_rptpos.* FROM rptpos 
					WHERE rptpos_id = l_rec_rpthead.rpt_desc_position 

					PRINT COLUMN 04, "Position......:", 
					COLUMN 34, l_rec_rptpos.rptpos_desc 

					PRINT COLUMN 04, "Column Header.:"; 
					IF l_rec_rpthead.col_hdr_per_page = "Y" THEN 
						PRINT COLUMN 34, "On every page" 
					ELSE 
						PRINT COLUMN 34, "First page only" 
					END IF 

					PRINT COLUMN 04, "Report Header.:"; 
					IF l_rec_rpthead.std_head_per_page = "Y" THEN 
						PRINT COLUMN 34, "On every page" 
					ELSE 
						PRINT COLUMN 34, "First page only" 
					END IF 

					# Report Type.
					SELECT * INTO l_rec_rpttype.* FROM rpttype 
					WHERE rpttype_id = l_rec_rpthead.rpt_type 

					PRINT 
					PRINT COLUMN 04, "Type..........:", 
					COLUMN 34, l_rec_rpttype.rpttype_desc 

					# Report Rounding Code.
					SELECT * INTO l_rec_rndcode.* FROM rndcode 
					WHERE rnd_code = l_rec_rpthead.rnd_code 

					PRINT COLUMN 04, "Rounding......:", 
					COLUMN 34, l_rec_rndcode.rnd_desc 

					# Report sign code.
					SELECT * INTO l_rec_signcode.* FROM signcode 
					WHERE sign_code = l_rec_rpthead.sign_code 

					PRINT COLUMN 04, "Sign Code.....:", 
					COLUMN 34, l_rec_signcode.sign_desc 

					PRINT COLUMN 04, "Amount Format.:", glob_rec_rpthead.amt_picture 


					#+-----------------------------------------------------------+
					#|     Column Definitions.                                   |
					#+-----------------------------------------------------------+
				WHEN l_section = "COLUMN" 
					PRINT COLUMN 01, "Report Id....: ", l_rec_rpthead.rpt_id, 
					COLUMN 30, l_rec_rpthead.rpt_text 
					PRINT 

					DECLARE col_curs CURSOR FOR 
					SELECT * 
					FROM rptcol 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rpt_id = l_rec_rpthead.rpt_id 
					ORDER BY col_id 

					DECLARE colitem_curs CURSOR FOR 
					SELECT * FROM colitem 
					WHERE col_uid = l_rec_rptcol.col_uid 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					ORDER BY seq_num 

					FOREACH col_curs INTO l_rec_rptcol.* 
						DISPLAY l_rec_rptcol.col_id at 1,32 

						PRINT COLUMN 01, "Column...........: ", 
						l_rec_rptcol.col_id USING "<<<<<<" 
						PRINT COLUMN 04, "Descripton....: ", 
						column_desc(l_rec_rptcol.col_uid, 1) 
						IF column_desc(l_rec_rptcol.col_uid, 2) IS NOT NULL THEN 
							PRINT COLUMN 20, column_desc(l_rec_rptcol.col_uid, 2) 
						END IF 
						IF column_desc(l_rec_rptcol.col_uid, 3) IS NOT NULL THEN 
							PRINT COLUMN 20, column_desc(l_rec_rptcol.col_uid, 3) 
						END IF 
						PRINT COLUMN 04, "Width.........: ", 
						l_rec_rptcol.width USING "<<<<<&" 
						PRINT COLUMN 04, "Amount Format.: ", l_rec_rptcol.amt_picture 

						#Check FOR any analysis across records.
						IF glob_rec_rpthead.rpt_type = glob_rec_mrwparms.analacross_type THEN 
							DECLARE colaa_curs CURSOR FOR 
							SELECT * FROM rptcolaa 
							WHERE col_uid = l_rec_rptcol.col_uid 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							ORDER BY start_num 

							FOREACH colaa_curs INTO l_rec_rptcolaa.* 
								PRINT COLUMN 04, "Analysis Start: ", 
								l_rec_rptcolaa.start_num USING "<<&", 
								COLUMN 30,"Flex Clause....:", 
								l_rec_rptcolaa.flex_clause 
							END FOREACH 
							PRINT 
						END IF 

						PRINT COLUMN 04, "Column Item...: "; 

						FOREACH colitem_curs INTO l_rec_colitem.* 

							#Get the item_type FROM mrwitem table.
							SELECT mrwitem.* INTO l_rec_mrwitem.* FROM mrwitem 
							WHERE item_id = l_rec_colitem.col_item 

							PRINT COLUMN 20, l_rec_colitem.item_operator; 

							CASE 
								WHEN glob_rec_mrwparms.time_item_type = l_rec_mrwitem.item_type 
									#SELECT colitemdetl details.
									SELECT * INTO l_rec_colitemdetl.* FROM colitemdetl 
									WHERE col_uid = l_rec_rptcol.col_uid 
									AND seq_num = l_rec_colitem.seq_num 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									PRINT COLUMN 22, l_rec_mrwitem.item_desc, 
									COLUMN 58, "Year: ", 
									l_rec_colitemdetl.year_num USING "-<<&", 
									COLUMN 70, date_type( l_rec_colitemdetl.year_type ), 
									COLUMN 85, "Period: ", 
									l_rec_colitemdetl.period_num USING "-<<&", 
									COLUMN 98, date_type( l_rec_colitemdetl.period_type ) 

								WHEN glob_rec_mrwparms.column_item_type = l_rec_mrwitem.item_type 
									#SELECT colitemcolid details.
									SELECT * INTO l_rec_colitemcolid.* FROM colitemcolid 
									WHERE col_uid = l_rec_rptcol.col_uid 
									AND seq_num = l_rec_colitem.seq_num 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									PRINT COLUMN 22, "Column....: ", 
									l_rec_colitemcolid.id_col_id USING "-<<&" 

								WHEN glob_rec_mrwparms.value_item_type = l_rec_mrwitem.item_type 
									#SELECT colitemval details.
									SELECT * INTO l_rec_colitemval.* FROM colitemval 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND rpt_id = l_rec_rptcol.rpt_id 
									AND col_uid = l_rec_rptcol.col_id 
									AND seq_num = l_rec_colitem.seq_num 

									PRINT COLUMN 22, "Constant Value.....: ", 
									l_rec_colitemval.item_value 
									USING "--------&.&&" 
								OTHERWISE 
									PRINT COLUMN 22, l_rec_mrwitem.item_desc 
							END CASE 
						END FOREACH 
						SKIP 1 line 
					END FOREACH 

					#+-----------------------------------------------------------+
					#|     Line Definitions.                                     |
					#+-----------------------------------------------------------+
				WHEN l_section = "LINE" 

					PRINT COLUMN 01, "Report Id....: ", l_rec_rpthead.rpt_id, 
					COLUMN 30, l_rec_rpthead.rpt_text 
					PRINT 

					PRINT COLUMN 01, "Line", 
					COLUMN 09, "Line", 
					COLUMN 20, "Description / Chart Clause", 
					COLUMN 80, "Accumulator", 
					COLUMN 94, "Page", 
					COLUMN 102, "Drop" 
					PRINT COLUMN 01, "Number", 
					COLUMN 09, "Type", 
					COLUMN 94, "Break", 
					COLUMN 102, "Lines" 

					FOR l_counter = 1 TO 128 
						PRINT "-"; 
					END FOR 

					SKIP 1 line 

					DECLARE line_curs CURSOR FOR 
					SELECT * FROM rptline 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rpt_id = l_rec_rpthead.rpt_id 
					AND line_id between glob_from_line_id AND modu_to_line_id 
					ORDER BY line_id 

					#Only SELECT the description AND gl COLUMN lines FOR printing.
					DECLARE line_col_curs CURSOR FOR 
					SELECT colitem.*, mrwitem.item_type 
					FROM colitem, mrwitem 
					WHERE colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND colitem.rpt_id = l_rec_rpthead.rpt_id 
					AND mrwitem.item_id = colitem.col_item 
					AND ( mrwitem.item_type = glob_rec_mrwparms.time_item_type 
					OR mrwitem.item_type = glob_rec_mrwparms.constant_item_type ) 

					FOREACH line_curs INTO l_rec_rptline.* 
						DISPLAY l_rec_rptline.line_id at 1,32 

						LET l_glprn_line = true 
						LET l_calprn_line = true 
						LET l_extprn_line = true 
						LET l_prn_line = true 

						PRINT COLUMN 02, l_rec_rptline.line_id USING "<<<<", 
						COLUMN 10, l_rec_rptline.line_type; 

						FOREACH line_col_curs INTO l_rec_colitem.*, l_item_type 

							CASE 
							# Underline
								WHEN l_rec_rptline.line_type = glob_rec_mrwparms.under_line_type 
									SELECT txttype.txttype_desc INTO l_txttype_desc 
									FROM txtline, txttype 
									WHERE txtline.line_uid = l_rec_rptline.line_uid 
									AND txttype.txttype_id = txtline.txt_type 
									AND txtline.cmpy_code = glob_rec_kandoouser.cmpy_code 

									PRINT COLUMN 18, l_txttype_desc clipped, 
									COLUMN 96, l_rec_rptline.page_break_follow, 
									COLUMN 99, l_rec_rptline.drop_lines 
									EXIT FOREACH 

									# Text line
								WHEN l_rec_rptline.line_type = glob_rec_mrwparms.text_line_type 
									LET l_line_desc = col_desc(l_rec_rptline.line_uid, 
									l_rec_colitem.col_uid) 

									IF l_line_desc IS NOT NULL THEN 
										PRINT COLUMN 18, l_line_desc; 
									END IF 

									IF l_prn_line THEN 
										PRINT COLUMN 79, accum_id(l_rec_rptline.line_uid), 
										COLUMN 96, l_rec_rptline.page_break_follow, 
										COLUMN 99, l_rec_rptline.drop_lines 
										LET l_prn_line = false 
									ELSE 
										IF l_line_desc IS NOT NULL THEN 
											SKIP 1 line 
										END IF 
									END IF 

									# Description COLUMN
								WHEN l_item_type = glob_rec_mrwparms.constant_item_type 
									LET l_line_desc = col_desc(l_rec_rptline.line_uid, 
									l_rec_colitem.col_uid) 

									IF l_line_desc IS NOT NULL THEN 
										PRINT COLUMN 18, l_line_desc; 
									END IF 

									IF l_prn_line THEN 
										PRINT COLUMN 79, accum_id(l_rec_rptline.line_uid), 
										COLUMN 96, l_rec_rptline.page_break_follow, 
										COLUMN 99, l_rec_rptline.drop_lines 
										LET l_prn_line = false 
									ELSE 
										IF l_line_desc IS NOT NULL THEN 
											SKIP 1 line 
										END IF 
									END IF 


									# Calculation
								WHEN l_rec_rptline.line_type = glob_rec_mrwparms.calc_line_type 
									DECLARE calc_curs CURSOR FOR 
									SELECT * FROM calcline 
									WHERE line_uid = l_rec_rptline.line_uid 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									ORDER BY seq_num 

									IF l_calprn_line THEN 
										FOREACH calc_curs INTO l_rec_calcline.* 
											PRINT COLUMN 18, l_rec_calcline.operator, 
											COLUMN 20, "Accum. Id: ", 
											l_rec_calcline.accum_id USING "<<<<"; 

											IF l_prn_line THEN 
												PRINT COLUMN 79, accum_id(l_rec_rptline.line_uid), 
												COLUMN 96, l_rec_rptline.page_break_follow, 
												COLUMN 99, l_rec_rptline.drop_lines 
												LET l_prn_line = false 
											ELSE 
												SKIP 1 line 
											END IF 
										END FOREACH 
										LET l_calprn_line = false 
									END IF 


									# External line
								WHEN l_rec_rptline.line_type = glob_rec_mrwparms.ext_link_line_type 

									DECLARE ext_curs CURSOR FOR 
									SELECT rptcol.col_id, 
									extline.ext_cmpy_code, 
									extline.ext_rpt_id, 
									extline.ext_col_uid, 
									extline.ext_accum_id 
									FROM extline, rptcol 
									WHERE extline.line_uid = l_rec_rptline.line_uid 
									AND rptcol.col_uid = extline.col_uid 
									AND rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND extline.cmpy_code = glob_rec_kandoouser.cmpy_code 
									ORDER BY rptcol.col_id 

									IF l_extprn_line THEN 
										FOREACH ext_curs INTO l_rec_extline.* 
											PRINT COLUMN 18, "Col: ", 
											l_rec_extline.col_id USING "<<&", 
											" = Ext: ", 
											COLUMN 30, l_rec_extline.ext_cmpy_code, 
											COLUMN 38, l_rec_extline.ext_rpt_id; 

											SELECT col_id INTO l_col_id FROM rptcol 
											WHERE col_uid = l_rec_extline.ext_col_uid 
											AND cmpy_code = glob_rec_kandoouser.cmpy_code 

											PRINT COLUMN 50, "Col:",l_col_id USING "<<&", 
											COLUMN 66, "Accum: ",l_rec_extline.ext_accum_id 
											USING "<<<&"; 

											IF l_prn_line THEN 
												PRINT COLUMN 79, accum_id(l_rec_rptline.line_uid), 
												COLUMN 96, l_rec_rptline.page_break_follow, 
												COLUMN 99, l_rec_rptline.drop_lines 
												LET l_prn_line = false 
											ELSE 
												SKIP 1 line 
											END IF 
										END FOREACH 
										LET l_extprn_line = false 
									END IF 

									# GL line
								WHEN glob_rec_mrwparms.time_item_type = l_item_type 
									DECLARE gldetl_curs CURSOR FOR 
									SELECT * FROM gllinedetl 
									WHERE line_uid = l_rec_rptline.line_uid 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									ORDER BY seq_num 

									IF l_glprn_line THEN 
										FOREACH gldetl_curs INTO l_rec_gllinedetl.* 
											PRINT COLUMN 10, "Chart:", 
											COLUMN 18, l_rec_gllinedetl.operator, 
											COLUMN 20, l_rec_gllinedetl.chart_clause; 

											IF l_prn_line THEN 
												PRINT COLUMN 79, accum_id(l_rec_rptline.line_id), 
												COLUMN 96, l_rec_rptline.page_break_follow, 
												COLUMN 99, l_rec_rptline.drop_lines 
												LET l_prn_line = false 
											ELSE 
												SKIP 1 line 
											END IF 
										END FOREACH 
										LET l_glprn_line = false 
									END IF 


								OTHERWISE 
									CONTINUE FOREACH 

							END CASE 

						END FOREACH 
						#Check FOR any analysis down records.
						IF glob_rec_rpthead.rpt_type = glob_rec_mrwparms.analdown_type THEN 
							DECLARE seg_curs CURSOR FOR 
							SELECT * FROM segline 
							WHERE line_uid = l_rec_rptline.line_uid 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							ORDER BY start_num 

							FOREACH seg_curs INTO l_rec_segline.* 
								PRINT COLUMN 10, "Analysis: ", 
								l_rec_segline.start_num USING "<<&", 
								COLUMN 30,l_rec_segline.flex_clause 
							END FOREACH 
						END IF 
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
