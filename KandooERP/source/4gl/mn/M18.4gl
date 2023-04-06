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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M1_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M18_GLOBALS.4gl"
GLOBALS 
	DEFINE formname CHAR(10) 
	DEFINE pv_bor_flag SMALLINT 
	DEFINE pv_rpt_length SMALLINT 
	DEFINE fv_cnter_rep SMALLINT 
	DEFINE pv_replaced INTEGER 
	DEFINE pv_not_replaced INTEGER 
	DEFINE fv_uom_code LIKE prodmfg.man_uom_code 
	DEFINE pv_old_item LIKE bor.parent_part_code 
	DEFINE pv_new_item LIKE bor.parent_part_code
	DEFINE pv_non_item_desc LIKE shoporddetl.desc_text 
	DEFINE pa_replace_bor array[2000] OF RECORD LIKE bor.* 
	DEFINE pr_bor RECORD LIKE bor.*
	DEFINE pr_menunames RECORD LIKE menunames.* 
END GLOBALS 
###########################################################################
# MAIN
#
# Purpose - Mass Component Replace
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("M18") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL query_replace() 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION query_replace()
#
# 
###########################################################################
FUNCTION query_replace() 
	DEFINE 
	fv_query_ok SMALLINT, 
	fv_cnter SMALLINT, 
	fv_answer CHAR(1), 
	fv_old_description LIKE product.desc_text, 
	fv_new_description LIKE product.desc_text, 

	fr_product RECORD LIKE product.*, 
	fr_bor RECORD LIKE bor.* 

	LET fv_query_ok = true 

	OPEN WINDOW w0_replace with FORM "M155" 
	CALL  windecoration_m("M155") -- albo kd-762 

	MESSAGE kandoomsg2("M",1505,"")	# MESSAGE "ESC TO Accept, DEL TO Exit"

	WHILE (true) 
		LET pv_old_item = "" 
		LET pv_new_item = "" 
		LET fv_uom_code = "" 
		LET fv_old_description = "" 
		LET fv_new_description = "" 
		DISPLAY pv_new_item TO part_code 
		DISPLAY pv_old_item TO new_item 
		DISPLAY fv_uom_code TO uom_code 
		DISPLAY fv_new_description TO new_description 
		DISPLAY fv_old_description TO old_description 

		INPUT pv_old_item, pv_new_item, fv_uom_code 
		WITHOUT DEFAULTS 
		FROM part_code, new_item, uom_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD part_code 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				SELECT part_code 
				INTO pv_old_item 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_old_item 

				IF status = notfound THEN 
					ERROR kandoomsg2("M",9520,"") # ERROR "Not a valid manufacturing product"
					LET pv_old_item = NULL 
					DISPLAY pv_old_item TO part_code 
					NEXT FIELD part_code 
				END IF 

				SELECT desc_text 
				INTO fv_old_description 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_old_item 

				IF status = notfound THEN 
					ERROR kandoomsg2("M",9511,"") # ERROR "This product does NOT exist in the database"
					LET pv_old_item = NULL 
					DISPLAY pv_old_item TO part_code 
					NEXT FIELD part_code 
				END IF 

				SELECT unique count(*) 
				INTO fv_cnter 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_old_item 

				IF fv_cnter = 0 THEN 
					ERROR kandoomsg2("M",9521,"") # ERROR "There are no BOR's with this product as a child"
					LET pv_old_item = NULL 
					DISPLAY pv_old_item TO part_code 
					NEXT FIELD part_code 
				END IF 

				DISPLAY pv_old_item TO part_code 
				DISPLAY fv_old_description TO old_description 

			AFTER FIELD new_item 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				SELECT part_code 
				INTO pv_new_item 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_new_item 

				IF status = notfound THEN 
					ERROR kandoomsg2("M",9520,"") # ERROR "Not a valid manufacturing product"
					LET pv_new_item = NULL 
					DISPLAY pv_new_item TO new_item 
					NEXT FIELD new_item 
				END IF 

				SELECT desc_text 
				INTO fv_new_description 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_new_item 

				IF status = notfound THEN 
					ERROR kandoomsg2("M",9511,"") # ERROR "This product does NOT exist in the database"
					LET pv_new_item = NULL 
					DISPLAY pv_new_item TO new_item 
					NEXT FIELD new_item 
				END IF 

				DISPLAY fv_new_description TO new_description 

				SELECT man_uom_code 
				INTO fv_uom_code 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_new_item 

				DISPLAY fv_uom_code TO uom_code 

			AFTER FIELD uom_code 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

			ON KEY (control-B) 
				CASE 
					WHEN infield(part_code) 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING pv_old_item 

						IF pv_old_item IS NULL THEN 
							NEXT FIELD part_code 
						ELSE 
							DISPLAY pv_old_item TO part_code 

							SELECT desc_text 
							INTO fv_old_description 
							FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pv_old_item 

							DISPLAY fv_old_description TO old_description 
							NEXT FIELD new_item 
						END IF 

					WHEN infield(new_item) 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING pv_new_item 

						IF pv_new_item IS NULL THEN 
							NEXT FIELD new_item 
						ELSE 
							DISPLAY pv_new_item TO new_item 

							SELECT desc_text 
							INTO fv_new_description 
							FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pv_new_item 

							DISPLAY fv_new_description TO new_description 
							NEXT FIELD uom_code 

							IF pv_old_item = pv_new_item THEN 
								ERROR kandoomsg2("M",9522,"") # ERROR "Cannot replace an item with same item"
								NEXT FIELD new_item 
							END IF 
						END IF 

					WHEN infield(uom_code) 
						LET fv_uom_code = lookup_uom(glob_rec_kandoouser.cmpy_code, pv_new_item) 
						DISPLAY fv_uom_code TO uom_code 
						EXIT INPUT 
				END CASE 
		END INPUT 

		IF (int_flag 
		OR quit_flag) THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET fv_query_ok = false 
			LET pv_old_item = NULL 
			LET pv_new_item = NULL 
			CLEAR FORM 
			EXIT WHILE 
		ELSE 
			DECLARE ureplace CURSOR FOR 
			SELECT * 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pv_old_item 
			ORDER BY parent_part_code, part_code 

			LET fv_cnter = 0 

			SELECT unique count(*) 
			INTO fv_cnter 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pv_old_item 

			IF fv_cnter > 0 THEN 
				LET fv_answer = "Y" 
				OPEN WINDOW w0_check with FORM "M156" 
				CALL  windecoration_m("M156") -- albo kd-762 

				INPUT fv_answer WITHOUT DEFAULTS FROM answer 

					ON ACTION "WEB-HELP" -- albo kd-376 
						CALL onlinehelp(getmoduleid(),null) 

				END INPUT 

				IF (int_flag 
				OR quit_flag) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET fv_query_ok = false 
					LET pv_old_item = NULL 
					LET pv_new_item = NULL 
					CLEAR FORM 
				ELSE 
					LET fv_cnter_rep = 0 
					{
					                    OPEN WINDOW w1_IB1 AT 10,10      -- albo  KD-762
					                        with 2 rows, 50 columns
					                    ATTRIBUTE(border)
					}
					--ERROR kandoomsg2("U",1506,"")	# MESSAGE "Searching database - Please stand by"
					--ERROR kandoomsg2("I",1024,"") # MESSAGE "Reporting on product"

					FOREACH ureplace INTO fr_bor.* 
						IF fr_bor.parent_part_code <> pv_new_item THEN 
							CALL bor_check(fr_bor.parent_part_code) 
							IF pv_bor_flag = false THEN 
								LET fv_cnter_rep = fv_cnter_rep + 1 
								LET pa_replace_bor[fv_cnter_rep].* = fr_bor.* 
							END IF 
						END IF 
					END FOREACH 

					ERROR kandoomsg2("U",1507,"") 	# MESSAGE "Database search IS complete"

					IF fv_answer = "Y" THEN 
						CALL replace_bor(true) 
					ELSE 
						CALL replace_bor(false) 
					END IF 
				END IF 
				CLOSE WINDOW w0_check 
			ELSE 
				ERROR kandoomsg2("M",9523,"")	# ERROR "No BOR parts TO replace"

			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW w0_replace 

	IF pv_replaced > 0 OR pv_not_replaced > 0 THEN 
		CALL run_prog("URS", "", "", "", "") -- ON ACTION "Print Manager" 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION query_replace()
###########################################################################


###########################################################################
# FUNCTION replace_bor(fp_step)
#
# 
###########################################################################
FUNCTION replace_bor(fp_step) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fr_bor RECORD LIKE bor.*, 
	fv_replace_ok SMALLINT, 
	fp_step SMALLINT, 
	fv_do_replace SMALLINT, 
	fv_local_cnt SMALLINT, 
	fv_new_start DATE, 
	fv_new_end DATE, 
	fv_old_start DATE, 
	fv_old_end DATE, 
	fv_description LIKE product.desc_text, 
	fv_par_desc LIKE product.desc_text, 
	fv_old_desc LIKE product.desc_text, 
	fv_new_desc LIKE product.desc_text, 
	fv_child_desc LIKE product.desc_text, 
	fv_answer CHAR(1), 
	fv_output CHAR(80) 

	LET fv_replace_ok = true 
	LET pv_replaced = 0 
	LET pv_not_replaced = 0 
	LET fv_local_cnt = 0 

	IF fp_step = true THEN 
		OPEN WINDOW w0_step with FORM "M157" 
		CALL  windecoration_m("M157") -- albo kd-762 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M18_rpt_list_replace","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M18_rpt_list_replace TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	BEGIN WORK 
		LET pr_bor.part_code = pv_new_item 

		SELECT desc_text 
		INTO fv_new_desc 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pv_new_item 

		WHILE fv_local_cnt < fv_cnter_rep 
			LET fv_local_cnt = fv_local_cnt + 1 
			LET fr_bor.* = pa_replace_bor[fv_local_cnt].* 
			LET fv_do_replace = true 

			IF fp_step = true THEN 
				LET fr_bor.last_change_date = today 
				LET fr_bor.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_bor.last_program_text = "M18" 

				SELECT desc_text 
				INTO fv_par_desc 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.parent_part_code 

				SELECT desc_text 
				INTO fv_old_desc 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				DISPLAY 
				fr_bor.parent_part_code, fv_par_desc, 
				fr_bor.part_code, fv_old_desc, 
				pv_new_item, fv_new_desc 
				TO parent_part_code, parent_description, 
				part_code, old_description, 
				new_item_code, new_description 

				LET fv_answer = "" 
				INPUT fv_answer WITHOUT DEFAULTS FROM answer 

					ON ACTION "WEB-HELP" -- albo kd-376 
						CALL onlinehelp(getmoduleid(),null) 

				END INPUT 

				IF (upshift(fv_answer) = "N" OR int_flag) THEN 
					ERROR kandoomsg2("M",9524,"") 				# ERROR "Item NOT replaced"
					LET fv_do_replace = false 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
			END IF 

			IF fv_do_replace THEN 
				UPDATE bor 
				SET part_code = pv_new_item 
				WHERE parent_part_code = fr_bor.parent_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sequence_num = fr_bor.sequence_num 

				UPDATE bor 
				SET bor.uom_code = fv_uom_code 
				WHERE parent_part_code = fr_bor.parent_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sequence_num = fr_bor.sequence_num 

				LET pv_replaced = pv_replaced + 1 
			ELSE 
				LET pv_not_replaced = pv_not_replaced + 1 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,
			fr_bor.parent_part_code, pv_old_item, 
			fv_old_start,fv_old_end, fr_bor.parent_part_code, 
			pv_new_item, fv_new_start, fv_new_end, 
			fv_do_replace) 
			#---------------------------------------------------------

		END WHILE 

		IF fv_replace_ok THEN 
			IF pv_not_replaced = 0 THEN 
				ERROR kandoomsg2("M",9525,"")			# ERROR "Replacement Sucessfull"
			COMMIT WORK 
			#---------------------------------------------------------
			OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,
			"","","","","","","","",TRUE) 
			#---------------------------------------------------------
		ELSE 
			ERROR pv_replaced," Replacments successful ",pv_not_replaced, 
			" Unsuccessful Replacements" attribute(red, reverse) 
			COMMIT WORK 
			#---------------------------------------------------------
			OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,
			"","","","","","","","",TRUE) 
			#---------------------------------------------------------
 
		END IF 
	ELSE 
		ERROR kandoomsg2("M",9526,"") 	# ERROR "Trouble encountered WHILE replacing items"
	
		ROLLBACK WORK 

		#---------------------------------------------------------
		OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,
		"","","","","","","","",TRUE) 
		#---------------------------------------------------------	

		LET pv_replaced = 0 
		LET pv_not_replaced = 0 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT M18_rpt_list_replace
	CALL rpt_finish("M18_rpt_list_replace")
	#------------------------------------------------------------

	IF fp_step = true THEN 
		CLOSE WINDOW w0_step 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION replace_bor(fp_step)
###########################################################################


###########################################################################
# FUNCTION bor_check(fv_part_code)
#
#
###########################################################################
FUNCTION bor_check(fv_part_code) 
	DEFINE 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.part_code, 
	fa_parent array[200] OF LIKE bor.parent_part_code, 
	fv_cnt SMALLINT, 
	fv_parent_cnt SMALLINT 

	DECLARE c_bor CURSOR FOR 
	SELECT unique parent_part_code 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_part_code 

	LET fv_parent_cnt = 0 

	FOREACH c_bor INTO fv_parent_part_code 
		LET fv_parent_cnt = fv_parent_cnt + 1 
		LET fa_parent[fv_parent_cnt] = fv_parent_part_code 

		DISPLAY fa_parent[fv_parent_cnt] at 1,27 

	END FOREACH 

	LET fv_cnt = 1 

	WHILE fv_cnt < fv_parent_cnt 
		DISPLAY fa_parent[fv_cnt] at 1,27 


		LET fv_cnt = fv_cnt + 1 

		IF pr_bor.part_code = fa_parent[fv_cnt] THEN 
			LET pv_bor_flag = true 
			EXIT WHILE 
		END IF 

		CALL bor_check(fa_parent[fv_cnt]) 

		IF pv_bor_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
END FUNCTION 
###########################################################################
# END FUNCTION bor_check(fv_part_code)
###########################################################################


###########################################################################
# REPORT M18_rpt_list_replace(rp_old_parent,rp_old_child,rp_old_start,rp_old_end,
#	rp_new_parent,rp_new_child,rp_new_start,rp_new_end, 
#	rp_replaced) 
#
#
###########################################################################
REPORT M18_rpt_list_replace(p_rpt_idx, rp_old_parent,rp_old_child,rp_old_start,rp_old_end, 
	rp_new_parent,rp_new_child,rp_new_start,rp_new_end, 
	rp_replaced) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rp_old_parent LIKE bor.parent_part_code, 
	rp_old_child LIKE bor.part_code, 
	rp_old_start LIKE bor.start_date, 
	rp_old_end LIKE bor.end_date, 
	rp_new_parent LIKE bor.parent_part_code, 
	rp_new_child LIKE bor.part_code, 
	rp_new_start LIKE bor.start_date, 
	rp_new_end LIKE bor.end_date, 
	rv_cmpy_name LIKE company.name_text, 
	rv_old_description LIKE product.desc_text, 
	rv_new_description LIKE product.desc_text, 
	rp_replaced SMALLINT, 
	rv_position SMALLINT, 
	rv_title CHAR(132) 

	OUTPUT 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 1,"Parent", 
			COLUMN 17,"Old Component", 
			COLUMN 33,"Component Description", 
			COLUMN 64,"New Component", 
			COLUMN 80,"Component Description" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 

			SELECT desc_text 
			INTO rv_old_description 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_old_child 

			SELECT desc_text 
			INTO rv_new_description 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_new_child 

			IF NOT rp_replaced THEN 
				LET rp_new_child = "*NOT REPLACED*" 
				LET rv_new_description = "" 
			END IF 

			PRINT COLUMN 1, rp_old_parent clipped, 
			COLUMN 17, rp_old_child clipped, 
			COLUMN 33, rv_old_description clipped, 
			COLUMN 64, rp_new_child clipped, 
			COLUMN 80, rv_new_description clipped; 

			PRINT 
			LET rv_old_description = "" 
			LET rv_new_description = "" 

		ON LAST ROW 
			SKIP 1 LINES 
			IF pv_replaced IS NULL THEN 
				LET pv_replaced = 0 
			END IF 

			IF pv_not_replaced IS NULL THEN 
				LET pv_not_replaced = 0 
			END IF 

			PRINT "No. of records replaced:",pv_replaced USING "<<<<<<&", 
			" No. of records NOT replaced:", 
			pv_not_replaced USING "<<<<<<&" 
			SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]

END REPORT 
###########################################################################
# END REPORT M18_rpt_list_replace(rp_old_parent,rp_old_child,rp_old_start,rp_old_end,
#	rp_new_parent,rp_new_child,rp_new_start,rp_new_end, 
#	rp_replaced) 
###########################################################################