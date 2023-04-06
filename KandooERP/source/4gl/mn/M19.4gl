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
GLOBALS "../mn/M19_GLOBALS.4gl"
GLOBALS 
	DEFINE formname CHAR(10)
	DEFINE pv_bor_flag SMALLINT
	DEFINE pv_rpt_length SMALLINT
	DEFINE pv_deleted INTEGER
	DEFINE pv_not_deleted INTEGER
	DEFINE pv_old_item LIKE bor.parent_part_code
	DEFINE pv_non_item_desc LIKE shoporddetl.desc_text
	DEFINE pr_bor RECORD LIKE bor.* 
	DEFINE pr_menunames RECORD LIKE menunames.* 
END GLOBALS 
###########################################################################
# MAIN
#
# Purpose - Mass Component Delete
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("M19") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL query_delete() 
END MAIN 
###########################################################################
# END MAIN
#
# Purpose - Mass Component Delete
###########################################################################


###########################################################################
# FUNCTION query_delete()
#
# Purpose - Mass Component Delete
###########################################################################
FUNCTION query_delete() 
	DEFINE 
	fv_query_ok SMALLINT, 
	fv_cnter SMALLINT, 
	fv_answer CHAR(1), 
	fv_old_description LIKE product.desc_text 

	LET fv_query_ok = true 
	OPEN WINDOW w0_delete with FORM "M158" 
	CALL  windecoration_m("M158") -- albo kd-762 

	MESSAGE kandoomsg2("M",1505,"") 	# MESSAGE "ESC TO Accept, DEL TO Exit"

	WHILE (true) 
		LET pv_old_item = "" 
		LET fv_old_description = "" 
		DISPLAY fv_old_description TO old_description 

		INPUT pv_old_item WITHOUT DEFAULTS 
		FROM part_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD part_code 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				SELECT desc_text 
				INTO fv_old_description 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_old_item 

				IF fv_old_description IS NULL THEN 
					LET pv_old_item = NULL 
					ERROR kandoomsg2("M",9511,"") 		# ERROR "This product does NOT exist in the database"

					DISPLAY pv_old_item TO part_code 
					NEXT FIELD part_code 
				ELSE 
					DISPLAY fv_old_description TO old_description 
				END IF 

			ON KEY (control-B) 
				CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING pv_old_item 
				DISPLAY pv_old_item TO part_code 

				SELECT desc_text 
				INTO fv_old_description 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pv_old_item 

				DISPLAY fv_old_description TO old_description 
				EXIT INPUT 
		END INPUT 

		IF (int_flag 
		OR quit_flag) THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET fv_query_ok = false 
			LET pv_old_item = NULL 
			CLEAR FORM 
			EXIT WHILE 
		ELSE 
			DECLARE udelete CURSOR FOR 
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
				OPEN WINDOW w0_check with FORM "M159" 
				CALL  windecoration_m("M159") -- albo kd-762 

				INPUT fv_answer WITHOUT DEFAULTS 
				FROM answer 

					ON ACTION "WEB-HELP" -- albo kd-376 
						CALL onlinehelp(getmoduleid(),null) 

					AFTER FIELD answer 
						IF (int_flag 
						OR quit_flag) THEN 
							EXIT INPUT 
						END IF 

				END INPUT 

				IF (int_flag 
				OR quit_flag) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET fv_query_ok = false 
					LET pv_old_item = NULL 
					CLEAR FORM 
				ELSE 
					IF fv_answer = "Y" THEN 
						CALL delete_bor(true) 
					ELSE 
						CALL delete_bor(false) 
					END IF 
				END IF 
				CLOSE WINDOW w0_check 
			ELSE 
				ERROR kandoomsg2("M",9512,"") 	# ERROR "No BOR parts TO delete"
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW w0_delete 

	IF pv_deleted > 0 OR pv_not_deleted > 0 THEN 
		CALL run_prog("URS", "", "", "", "") -- ON ACTION "Print Manager" 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION query_delete()
###########################################################################


###########################################################################
# FUNCTION delete_bor(fp_step) 
#
# 
###########################################################################
FUNCTION delete_bor(fp_step) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fr_bor RECORD LIKE bor.*, 
	fv_replace_ok SMALLINT, 
	fp_step SMALLINT, 
	fv_do_replace SMALLINT, 
	fv_description LIKE product.desc_text, 
	fv_par_desc LIKE product.desc_text, 
	fv_old_desc LIKE product.desc_text, 
	fv_child_desc LIKE product.desc_text, 
	fv_answer CHAR(1), 
	fv_output CHAR(80) 

	LET fv_replace_ok = true 
	LET pv_deleted = 0 
	LET pv_not_deleted = 0 

	IF fp_step = true THEN 
		OPEN WINDOW w0_step with FORM "M160" 
		CALL  windecoration_m("M160") -- albo kd-762 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M19_rpt_list_delete","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M19_rpt_list_delete TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	BEGIN WORK 

		FOREACH udelete INTO fr_bor.* 
			LET fv_do_replace = true 

			IF fp_step = true THEN 
				LET fr_bor.last_change_date = today 
				LET fr_bor.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_bor.last_program_text = "M19" 

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
				fr_bor.part_code, fv_old_desc 
				TO parent_part_code, parent_description, 
				part_code, old_description 

				LET fv_answer = "" 
				INPUT fv_answer WITHOUT DEFAULTS 
				FROM answer 

					ON ACTION "WEB-HELP" -- albo kd-376 
						CALL onlinehelp(getmoduleid(),null) 

					AFTER FIELD answer 
						IF (int_flag 
						OR quit_flag) THEN 
							EXIT INPUT 
						END IF 

				END INPUT 

				IF (upshift(fv_answer) = "N" 
				OR int_flag 
				OR quit_flag) THEN 
					ERROR kandoomsg2("M",9513,"") 		# ERROR "Item NOT deleted"
					LET fv_do_replace = false 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
			END IF 

			IF fv_do_replace THEN 
				DELETE 
				FROM bor 
				WHERE parent_part_code = fr_bor.parent_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sequence_num = fr_bor.sequence_num 

				LET pv_deleted = pv_deleted + 1 
			ELSE 
				LET pv_not_deleted = pv_not_deleted + 1 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT M19_rpt_list_delete(l_rpt_idx,		 
			fr_bor.parent_part_code, pv_old_item, fv_do_replace) 
			#---------------------------------------------------------
 
		END FOREACH 

		IF fv_replace_ok THEN 
			IF pv_not_deleted = 0 THEN 
				ERROR kandoomsg2("M",9514,"") 			# ERROR "Deletion sucessfull"
			COMMIT WORK 

			#---------------------------------------------------------
			OUTPUT TO REPORT M19_rpt_list_delete(l_rpt_idx,		 
			"","",TRUE) 
			#---------------------------------------------------------			
			 
		ELSE 
			ERROR pv_deleted," Deletions successful ",pv_not_deleted, 
			" Unsuccessful deletions" attribute(red, reverse) 
			COMMIT WORK 

			#---------------------------------------------------------
			OUTPUT TO REPORT M19_rpt_list_delete(l_rpt_idx,		 
			"","",TRUE) 
			#---------------------------------------------------------			
 
		END IF 
	ELSE 
		ERROR kandoomsg2("M",9515,"") # error 'Trouble encountered WHILE deleting items"
		ROLLBACK WORK

		#---------------------------------------------------------
		OUTPUT TO REPORT M19_rpt_list_delete(l_rpt_idx,		 
		"","",TRUE) 
		#---------------------------------------------------------
	
		LET pv_deleted = 0 
		LET pv_not_deleted = 0 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT M19_rpt_list_delete
	CALL rpt_finish("M19_rpt_list_delete")
	#------------------------------------------------------------

	IF fp_step = true THEN 
		CLOSE WINDOW w0_step 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION delete_bor(fp_step) 
###########################################################################


###########################################################################
# REPORT M19_rpt_list_delete(rp_old_parent,rp_old_child,rp_replaced)
#
# 
###########################################################################
REPORT M19_rpt_list_delete(p_rpt_idx,rp_old_parent,rp_old_child,rp_replaced) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rp_old_parent LIKE bor.parent_part_code, 
	rp_old_child LIKE bor.part_code, 
	rv_cmpy_name LIKE company.name_text, 
	rv_old_description LIKE product.desc_text, 
	rp_replaced SMALLINT, 
	rv_position SMALLINT, 
	rv_title CHAR(132), 
	rv_status CHAR(20) 

	OUTPUT 


	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Parent", 
			COLUMN 17, "Component", 
			COLUMN 33, "Component Description", 
			COLUMN 64, "Status" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			SELECT desc_text 
			INTO rv_old_description 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rp_old_child 

			IF NOT rp_replaced THEN 
				LET rv_status = "*NOT DELETED*" 
			ELSE 
				LET rv_status = "***DELETED***" 
			END IF 

			IF rp_old_parent IS NULL 
			AND rp_old_child IS NULL THEN 
				LET rv_status = "" 
			END IF 

			PRINT COLUMN 1, rp_old_parent clipped, 
			COLUMN 17, rp_old_child clipped, 
			COLUMN 33, rv_old_description clipped, 
			COLUMN 64, rv_status clipped 

			PRINT 
			LET rv_old_description = "" 
			LET rv_status = "" 

		ON LAST ROW 
			SKIP 1 LINES 
			IF pv_deleted IS NULL THEN 
				LET pv_deleted = 0 
			END IF 

			IF pv_not_deleted IS NULL THEN 
				LET pv_not_deleted = 0 
			END IF 

			PRINT "No. of records deleted: ",pv_deleted USING "<<<<<<&", 
			" No. of records NOT deleted: ", 
			pv_not_deleted USING "<<<<<<&" 
			SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT 
