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

	Source code beautified by beautify.pl on 2020-01-02 17:31:17	$Id: $
}


# Purpose - BOR Add - Parent product & Item type entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M14_GLOBALS.4gl" 


FUNCTION parent_input() 

	DEFINE 
	fv_display_text CHAR (30), 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.part_code, 
	fv_config_ind LIKE prodmfg.config_ind, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fv_desc_text LIKE product.desc_text, 
	fv_part_type_ind LIKE prodmfg.part_type_ind 


	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "ESC TO Accept - DEL TO Exit"

		INPUT fv_parent_part_code FROM parent_part_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD parent_part_code 
				IF fv_parent_part_code IS NULL THEN 
					LET msgresp = kandoomsg("M",9507,"") 
					# ERROR "Parent product must be entered"
					NEXT FIELD parent_part_code 
				END IF 

				SELECT desc_text 
				INTO fv_desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fv_parent_part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9511,"") 
					#ERROR "This product does NOT exist in the database-Try Win"
					NEXT FIELD parent_part_code 
				END IF 

				SELECT part_type_ind, config_ind, man_uom_code 
				INTO fv_part_type_ind, fv_config_ind, fv_man_uom_code 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fv_parent_part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9569,"") 
					# ERROR "This product IS NOT SET up as a manufacturing prod"
					NEXT FIELD parent_part_code 
				END IF 

				IF fv_part_type_ind = "R" THEN 
					LET msgresp = kandoomsg("M",9570,"") 
					# ERROR "This IS a purchased product AND cannot be a parent"
					NEXT FIELD parent_part_code 
				END IF 

				IF fv_part_type_ind = "G" 
				AND fv_config_ind = "Y" THEN 
					LET msgresp = kandoomsg("M",9571,"") 
					#ERROR "This IS configurable product AND cannot be a parent"
					NEXT FIELD parent_part_code 
				END IF 

				SELECT unique parent_part_code 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_parent_part_code 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("M",9572,"") 
					# ERROR "This product IS already a parent in the BOR"
					NEXT FIELD parent_part_code 
				END IF 

				DISPLAY fv_desc_text, fv_man_uom_code 
				TO desc_text, man_uom_code 

			ON KEY (control-b) 
				CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "MGP") RETURNING fv_part_code 

				IF fv_part_code IS NOT NULL THEN 
					LET fv_parent_part_code = fv_part_code 
					NEXT FIELD parent_part_code 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		CALL bor_add(fv_parent_part_code, fv_desc_text) 

		IF NOT pv_cont THEN 
			CONTINUE WHILE 
		END IF 

		DISPLAY "" at 3,1 

		IF pv_seq_cnt = 0 THEN 
			LET fv_display_text = kandooword("No BOR was added","M01") 
			DISPLAY fv_display_text at 4,2 

		ELSE 
			LET fv_display_text = kandooword("BOR added","M02") 
			DISPLAY fv_display_text at 4,2 

		END IF 

		CALL kandoomenu("M",163) RETURNING pr_menunames.* 
		MENU pr_menunames.menu_text # add 
			COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # CONTINUE 
				EXIT MENU 

			COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text # EXIT 
				LET pv_cont = false 
				EXIT MENU 

			COMMAND KEY (interrupt) 
				LET pv_cont = false 
				EXIT MENU 
		END MENU 

		--        CLOSE WINDOW w2_M14a      -- albo  KD-762

		IF pv_cont THEN 
			CONTINUE WHILE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

END FUNCTION 



FUNCTION bor_add(fv_parent_part_code, fv_desc_text) 

	DEFINE 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_scrn SMALLINT, 
	fv_arr_size SMALLINT, 
	fv_seq_max SMALLINT, 
	fv_seq_num SMALLINT, 
	fv_seq_cnt SMALLINT, 
	fv_image SMALLINT, 
	fv_runner CHAR(105), 
	fv_display_text CHAR (30), 
	fv_desc_text LIKE product.desc_text, 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_image_part_code LIKE bor.parent_part_code, 
	fv_type_ind LIKE bor.type_ind, 
	fv_config_ind LIKE prodmfg.config_ind, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_cogs_cost_tot LIKE prodmfg.cogs_cost_amt, 

	fa_bor array[500] OF RECORD LIKE bor.*, 

	fa_bor_child array[500] OF RECORD 
		type_ind LIKE bor.type_ind, 
		part_code LIKE bor.part_code, 
		desc_text LIKE product.desc_text, 
		required_qty LIKE bor.required_qty, 
		sequence_num LIKE bor.sequence_num 
	END RECORD 


	DISPLAY fv_parent_part_code, fv_desc_text 
	TO parent_part_code, desc_text 

	LET msgresp = kandoomsg("M",1512,"") 
	# MESSAGE "RETURN TO Add/Edit, F6 Add BOR, F9 Image BOR,ESC Accept,DEL Exit"

	SELECT min_ord_qty 
	INTO pv_min_ord_qty 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_parent_part_code 

	IF pv_min_ord_qty IS NULL 
	OR pv_min_ord_qty = 0 THEN 
		LET pv_min_ord_qty = 1 
	END IF 

	LET fv_seq_max = 0 
	LET fv_cnt = 0 

	WHILE true 
		LET fv_image = false 
		CALL set_count(fv_cnt) 

		INPUT ARRAY fa_bor_child WITHOUT DEFAULTS 
		FROM sr_bor_child.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 
				LET fv_arr_size = arr_count() 

			BEFORE INSERT 
				LET fv_arr_size = arr_count() 

			BEFORE FIELD type_ind 
				IF fv_idx > 1 AND fa_bor_child[fv_idx].type_ind IS NULL THEN 
					LET fa_bor_child[fv_idx].type_ind = 
					fa_bor_child[fv_idx - 1].type_ind 
					#DISPLAY fa_bor_child[fv_idx].type_ind
					#    TO  sr_bor_child[fv_scrn].type_ind
				END IF 

			AFTER FIELD type_ind 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					IF fa_bor_child[fv_idx].type_ind IS NULL THEN 
						IF fgl_lastkey() != fgl_keyval("up") 
						OR fv_idx < fv_arr_size 
						OR (fv_idx = fv_arr_size 
						AND fa_bor_child[fv_idx].sequence_num IS NOT null) THEN 
							LET msgresp = kandoomsg("M",9573,"") 
							# ERROR "Item type must be entered"
							NEXT FIELD type_ind 
						END IF 
					ELSE 
						IF fa_bor_child[fv_idx].type_ind NOT matches "[CISWUB]" 
						THEN 
							LET msgresp = kandoomsg("M",9574,"") 
							# ERROR "Invalid item type"
							NEXT FIELD type_ind 
						END IF 

						IF fa_bor_child[fv_idx].sequence_num IS NULL THEN 
							LET msgresp = kandoomsg("M",9575,"") 
							# ERROR "Item details must be entered first"
							NEXT FIELD type_ind 
						END IF 
					END IF 
				END IF 

			BEFORE DELETE 
				IF fa_bor_child[fv_idx].sequence_num IS NOT NULL THEN 
					LET fv_seq_num = fa_bor_child[fv_idx].sequence_num 
					INITIALIZE fa_bor[fv_seq_num].* TO NULL 
				END IF 

			ON KEY (RETURN) 
				LET fv_type_ind = get_fldbuf(sr_bor_child.type_ind) 

				IF fv_type_ind matches "[CISWUB]" THEN 
					INITIALIZE pr_bor TO NULL 

					IF fa_bor_child[fv_idx].sequence_num IS NOT NULL 
					AND fa_bor_child[fv_idx].sequence_num != 0 THEN 
						IF fv_type_ind != fa_bor_child[fv_idx].type_ind THEN 
							LET msgresp = kandoomsg("M",9577,"") 
							# ERROR "Item type cannot be changed"
							NEXT FIELD type_ind 
						END IF 

						LET fv_seq_num = fa_bor_child[fv_idx].sequence_num 
						LET pr_bor.* = fa_bor[fv_seq_num].* 
					ELSE 
						LET pr_bor.type_ind = fv_type_ind 
					END IF 

					CASE fv_type_ind 
						WHEN "C" 
							LET pr_bor.desc_text = 
							fa_bor_child[fv_idx].desc_text 
							CALL component_input(fv_parent_part_code) 

						WHEN "B" 
							LET pr_bor.desc_text = 
							fa_bor_child[fv_idx].desc_text 
							CALL component_input(fv_parent_part_code) 

						WHEN "I" 
							CALL instruct_input() 

						WHEN "S" 
							CALL cost_input() 

						WHEN "W" 
							CALL workcentre_input() 

						WHEN "U" 
							CALL setup_input() 
					END CASE 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						INITIALIZE pr_bor TO NULL 
					ELSE 
						LET fa_bor_child[fv_idx].desc_text = pr_bor.desc_text 

						IF pr_bor.type_ind != "U" THEN 
							LET fa_bor_child[fv_idx].required_qty = 
							pr_bor.required_qty 
						END IF 

						IF pr_bor.type_ind matches "[CB]" THEN 
							LET pr_bor.desc_text = NULL 
							LET fa_bor_child[fv_idx].part_code = 
							pr_bor.part_code 
						END IF 

						IF fa_bor_child[fv_idx].sequence_num IS NULL 
						OR fa_bor_child[fv_idx].sequence_num = 0 THEN 
							LET fv_seq_max = fv_seq_max + 1 
							LET pr_bor.sequence_num = fv_seq_max 
							LET fa_bor[fv_seq_max].* = pr_bor.* 
							LET fa_bor_child[fv_idx].type_ind = pr_bor.type_ind 
							LET fa_bor_child[fv_idx].sequence_num = 
							pr_bor.sequence_num 

							CASE pr_bor.type_ind 
								WHEN "I" 
									LET fa_bor_child[fv_idx].part_code = 
									kandooword("INSTRUCTION", "M14") 
								WHEN "S" 
									LET fa_bor_child[fv_idx].part_code = 
									kandooword("COST", "M15") 
								WHEN "W" 
									LET fa_bor_child[fv_idx].part_code = 
									pr_bor.work_centre_code 
								WHEN "U" 
									LET fa_bor_child[fv_idx].part_code = 
									kandooword("SET UP", "M17") 
							END CASE 
						ELSE 
							LET fa_bor[fv_seq_num].* = pr_bor.* 
						END IF 

						DISPLAY fa_bor_child[fv_idx].* 
						TO sr_bor_child[fv_scrn].* 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("M",9574,"") 
					# ERROR "Invalid item type"
				END IF 

			ON KEY (f6) 
				IF fa_bor_child[fv_idx].type_ind NOT matches "[CB]" 
				OR fa_bor_child[fv_idx].type_ind IS NULL 
				OR fa_bor_child[fv_idx].sequence_num IS NULL THEN 
					NEXT FIELD type_ind 
				END IF 

				SELECT part_type_ind, config_ind 
				INTO fv_part_type_ind, fv_config_ind 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_bor_child[fv_idx].part_code 

				IF fv_part_type_ind = "R" THEN 
					LET msgresp = kandoomsg("M",9578,"") 
					# ERROR "This purchased product AND cannot have a BOR"
					NEXT FIELD type_ind 
				END IF 

				IF fv_part_type_ind = "G" 
				AND fv_config_ind = "Y" THEN 
					LET msgresp = kandoomsg("M",9579,"") 
					# ERROR "This configurable product AND cannot have a BOR"
					NEXT FIELD type_ind 
				END IF 

				SELECT unique parent_part_code 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fa_bor_child[fv_idx].part_code 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("M",9580,"") 
					# ERROR "This product already has a Bill of Resource"
					NEXT FIELD type_ind 
				END IF 

				LET msgresp = kandoomsg("M",4501,"") 
				# prompt "Current changes will be saved before going down TO"
				#        "the next level - Do you wish TO continue (Y/N)?"

				IF msgresp = "N" THEN 
					LET msgresp = kandoomsg("M",1512,"") 
					#MESSAGE"RETURN TO Add/Edit,F6 Add BOR,F9 Image BOR,ESC,DEL"
					NEXT FIELD type_ind 
				END IF 

				GOTO bypass 

				LABEL recovery: 
				LET err_continue = error_recover(err_message, status) 
				IF err_continue != "Y" THEN 
					EXIT program 
				END IF 

				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 

				BEGIN WORK 

					LET err_message = "M14a - DELETE FROM bor failed" 

					DELETE FROM bor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parent_part_code = fv_parent_part_code 

					LET pv_seq_cnt = 0 
					LET pv_wgted_cost_tot = 0 
					LET pv_est_cost_tot = 0 
					LET pv_act_cost_tot = 0 
					LET pv_list_price_tot = 0 

					FOR fv_cnt = 1 TO fv_arr_size 
						IF fa_bor_child[fv_cnt].sequence_num IS NULL 
						OR fa_bor_child[fv_cnt].sequence_num = 0 THEN 
							CONTINUE FOR 
						END IF 

						LET fv_seq_num = fa_bor_child[fv_cnt].sequence_num 
						CALL update_tables(fa_bor[fv_seq_num].*,fv_parent_part_code) 
					END FOR 

					LET pv_wgted_cost_tot = pv_wgted_cost_tot / pv_min_ord_qty 
					LET pv_est_cost_tot = pv_est_cost_tot / pv_min_ord_qty 
					LET pv_act_cost_tot = pv_act_cost_tot / pv_min_ord_qty 
					LET pv_list_price_tot = pv_list_price_tot / pv_min_ord_qty 

					CASE 
						WHEN pr_inparms.cost_ind matches "[WF]" 
							LET fv_cogs_cost_tot = pv_wgted_cost_tot 

						WHEN pr_inparms.cost_ind = "S" 
							LET fv_cogs_cost_tot = pv_est_cost_tot 

						WHEN pr_inparms.cost_ind = "L" 
							LET fv_cogs_cost_tot = pv_act_cost_tot 
					END CASE 

					LET err_message = "M14a - Update of prodmfg failed" 

					UPDATE prodmfg 
					SET est_cost_amt = pv_est_cost_tot, 
					wgted_cost_amt = pv_wgted_cost_tot, 
					act_cost_amt = pv_act_cost_tot, 
					cogs_cost_amt = fv_cogs_cost_tot, 
					list_price_amt = pv_list_price_tot, 
					last_change_date = today, 
					last_user_text = glob_rec_kandoouser.sign_on_code, 
					last_program_text = "M14" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fv_parent_part_code 

				COMMIT WORK 
				WHENEVER ERROR stop 
				CALL run_prog("M14", fa_bor_child[fv_idx].part_code, 
				fa_bor_child[fv_idx].desc_text, "", "") 

				LET msgresp = kandoomsg("M",1512,"") 
				# MESSAGE "RETURN TO Add/Edit, F6 Add BOR, F9 Image BOR,ESC,DEL"

			ON KEY (f9) 
				CALL bor_image(glob_rec_kandoouser.cmpy_code) RETURNING fv_image_part_code 

				IF fv_image_part_code IS NULL THEN 
					NEXT FIELD type_ind 
				END IF 

				LET fv_image = true 
				CLEAR sr_bor_child.* 
				INITIALIZE fa_bor_child, fa_bor TO NULL 
				LET fv_seq_max = 0 

				DECLARE c_child CURSOR FOR 
				SELECT * 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_image_part_code 
				ORDER BY sequence_num 

				LET fv_cnt = 0 

				FOREACH c_child INTO pr_bor.* 
					IF pr_bor.type_ind matches "[CB]" THEN 
						IF pr_bor.part_code = fv_parent_part_code THEN 
							CONTINUE FOREACH 
						END IF 

						LET pv_bor_flag = false 
						CALL bor_check(fv_parent_part_code) 

						IF pv_bor_flag THEN 
							CONTINUE FOREACH 
						END IF 
					END IF 

					IF pr_bor.type_ind = "B" THEN 
						LET pr_bor.required_qty = - (pr_bor.required_qty) 
					END IF 

					LET fv_cnt = fv_cnt + 1 
					LET fv_seq_max = pr_bor.sequence_num 
					LET fa_bor[fv_seq_max].* = pr_bor.* 
					LET fa_bor_child[fv_cnt].type_ind = pr_bor.type_ind 
					LET fa_bor_child[fv_cnt].sequence_num = pr_bor.sequence_num 
					LET fa_bor_child[fv_cnt].desc_text = pr_bor.desc_text 
					LET fa_bor_child[fv_cnt].required_qty = pr_bor.required_qty 

					CASE pr_bor.type_ind 
						WHEN "I" 
							LET fa_bor_child[fv_cnt].part_code = 
							kandooword("INSTRUCTION", "M14") 
						WHEN "S" 
							LET fa_bor_child[fv_cnt].part_code = 
							kandooword("COST", "M15") 
						WHEN "W" 
							LET fa_bor_child[fv_cnt].part_code = 
							pr_bor.work_centre_code 
						WHEN "U" 
							LET fa_bor_child[fv_cnt].part_code = 
							kandooword("SET UP", "M17") 
						OTHERWISE 
							LET fa_bor_child[fv_cnt].part_code = 
							pr_bor.part_code 

							SELECT desc_text 
							INTO fa_bor_child[fv_cnt].desc_text 
							FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_bor.part_code 
					END CASE 

					IF fv_cnt = 500 THEN 
						LET msgresp = kandoomsg("M",9509,"") 
						# ERROR "Only the first 2000 items were imaged"
						EXIT FOREACH 
					END IF 
				END FOREACH 

				EXIT INPUT 

		END INPUT 

		IF NOT fv_image THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET pv_cont = false 
		RETURN 
	END IF 
	{
	    OPEN WINDOW w2_M14a AT 8,13 with 4 rows, 51 columns      -- albo  KD-762
	        attributes (border, white)
	}
	LET fv_display_text = kandooword("Creating BOR","M06") 
	DISPLAY fv_display_text at 3,2 


	GOTO bypass1 

	LABEL recovery1: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 

	BEGIN WORK 

		LET err_message = "M14a - DELETE FROM bor failed" 

		DELETE FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fv_parent_part_code 

		LET pv_seq_cnt = 0 
		LET pv_wgted_cost_tot = 0 
		LET pv_est_cost_tot = 0 
		LET pv_act_cost_tot = 0 
		LET pv_list_price_tot = 0 

		FOR fv_cnt = 1 TO fv_arr_size 
			IF fa_bor_child[fv_cnt].sequence_num IS NULL 
			OR fa_bor_child[fv_cnt].sequence_num = 0 THEN 
				CONTINUE FOR 
			END IF 

			LET fv_seq_num = fa_bor_child[fv_cnt].sequence_num 
			CALL update_tables(fa_bor[fv_seq_num].*, fv_parent_part_code) 
		END FOR 

		LET pv_wgted_cost_tot = pv_wgted_cost_tot / pv_min_ord_qty 
		LET pv_est_cost_tot = pv_est_cost_tot / pv_min_ord_qty 
		LET pv_act_cost_tot = pv_act_cost_tot / pv_min_ord_qty 
		LET pv_list_price_tot = pv_list_price_tot / pv_min_ord_qty 

		CASE 
			WHEN pr_inparms.cost_ind matches "[WF]" 
				LET fv_cogs_cost_tot = pv_wgted_cost_tot 

			WHEN pr_inparms.cost_ind = "S" 
				LET fv_cogs_cost_tot = pv_est_cost_tot 

			WHEN pr_inparms.cost_ind = "L" 
				LET fv_cogs_cost_tot = pv_act_cost_tot 
		END CASE 

		LET err_message = "M14a - Update of prodmfg failed" 

		UPDATE prodmfg 
		SET est_cost_amt = pv_est_cost_tot, 
		wgted_cost_amt = pv_wgted_cost_tot, 
		act_cost_amt = pv_act_cost_tot, 
		cogs_cost_amt = fv_cogs_cost_tot, 
		list_price_amt = pv_list_price_tot, 
		last_change_date = today, 
		last_user_text = glob_rec_kandoouser.sign_on_code, 
		last_program_text = "M14" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_parent_part_code 

	COMMIT WORK 
	WHENEVER ERROR stop 

	LET pv_cont = true 

END FUNCTION 



FUNCTION update_tables(fr_bor, fv_parent_part_code) 

	DEFINE fv_wgted_cost_amt LIKE prodmfg.wgted_cost_amt, 
	fv_est_cost_amt LIKE prodmfg.est_cost_amt, 
	fv_act_cost_amt LIKE prodmfg.act_cost_amt, 
	fv_list_price_amt LIKE prodmfg.list_price_amt, 
	fv_wc_tot LIKE workctrrate.rate_amt, 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_setup_qty SMALLINT, 

	fr_bor RECORD LIKE bor.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.* 


	###
	### Insert INTO bor table
	###

	LET pv_seq_cnt = pv_seq_cnt + 1 
	LET fr_bor.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET fr_bor.parent_part_code = fv_parent_part_code 
	LET fr_bor.sequence_num = pv_seq_cnt 
	LET fr_bor.last_change_date = today 
	LET fr_bor.last_user_text = glob_rec_kandoouser.sign_on_code 
	LET fr_bor.last_program_text = "M14" 

	IF fr_bor.type_ind = "B" THEN 
		LET fr_bor.required_qty = - fr_bor.required_qty 
	END IF 

	LET err_message = "M14a - Insert INTO bor failed" 

	INSERT INTO bor VALUES (fr_bor.*) 

	###
	### Calculate new unit cost of the product
	###

	CASE fr_bor.type_ind 
		WHEN "S" 
			IF fr_bor.cost_type_ind = "F" THEN 
				LET pv_wgted_cost_tot = pv_wgted_cost_tot + fr_bor.cost_amt 
				LET pv_est_cost_tot = pv_est_cost_tot + fr_bor.cost_amt 
				LET pv_act_cost_tot = pv_act_cost_tot + fr_bor.cost_amt 

				IF fr_bor.price_amt IS NOT NULL THEN 
					LET pv_list_price_tot = pv_list_price_tot + 
					fr_bor.price_amt 
				END IF 
			ELSE 
				LET pv_wgted_cost_tot = pv_wgted_cost_tot + 
				(fr_bor.cost_amt * pv_min_ord_qty) 
				LET pv_est_cost_tot = pv_est_cost_tot + 
				(fr_bor.cost_amt * pv_min_ord_qty) 
				LET pv_act_cost_tot = pv_act_cost_tot + 
				(fr_bor.cost_amt * pv_min_ord_qty) 

				IF fr_bor.price_amt IS NOT NULL THEN 
					LET pv_list_price_tot = pv_list_price_tot + 
					(fr_bor.price_amt * pv_min_ord_qty) 
				END IF 
			END IF 

		WHEN "W" 
			SELECT * 
			INTO fr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 

			SELECT sum(rate_amt) 
			INTO fr_bor.cost_amt 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 
			AND rate_ind = "V" 

			IF fr_bor.cost_amt IS NULL THEN 
				LET fr_bor.cost_amt = 0 
			END IF 

			SELECT sum(rate_amt) 
			INTO fr_bor.price_amt 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 
			AND rate_ind = "F" 

			IF fr_bor.price_amt IS NULL THEN 
				LET fr_bor.price_amt = 0 
			END IF 

			IF fr_workcentre.processing_ind = "Q" THEN 
				LET fv_wc_tot = ((fr_bor.cost_amt / fr_workcentre.time_qty) 
				* fr_bor.oper_factor_amt * pv_min_ord_qty) 
				+ fr_bor.price_amt 
			ELSE 
				LET fv_wc_tot = (fr_bor.cost_amt * fr_bor.oper_factor_amt * 
				pv_min_ord_qty) + fr_bor.price_amt 
			END IF 

			LET pv_wgted_cost_tot = pv_wgted_cost_tot + fv_wc_tot 
			LET pv_est_cost_tot = pv_est_cost_tot + fv_wc_tot 
			LET pv_act_cost_tot = pv_act_cost_tot + fv_wc_tot 
			LET pv_list_price_tot = fv_wc_tot * (1 + 
			(fr_workcentre.cost_markup_per / 100)) 

		WHEN "U" 
			IF fr_bor.cost_type_ind = "Q" THEN 
				LET fv_setup_qty = pv_min_ord_qty / fr_bor.var_amt 

				IF fv_setup_qty < 1 THEN 
					LET fv_setup_qty = 1 
				END IF 
			ELSE 
				LET fv_setup_qty = 1 
			END IF 

			LET pv_wgted_cost_tot = pv_wgted_cost_tot + (fr_bor.cost_amt * 
			fv_setup_qty) 
			LET pv_est_cost_tot = pv_est_cost_tot + (fr_bor.cost_amt * 
			fv_setup_qty) 
			LET pv_act_cost_tot = pv_act_cost_tot + (fr_bor.cost_amt * 
			fv_setup_qty) 

			IF fr_bor.price_amt IS NOT NULL THEN 
				LET pv_list_price_tot = pv_list_price_tot + 
				(fr_bor.price_amt * fv_setup_qty) 
			END IF 

		WHEN "C" 
			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			IF fr_prodmfg.part_type_ind = "R" THEN 
				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 
				AND ware_code = fr_prodmfg.def_ware_code 

				LET fv_wgted_cost_amt = fr_prodstatus.wgted_cost_amt * 
				fr_prodmfg.man_stk_con_qty 
				LET fv_est_cost_amt = fr_prodstatus.est_cost_amt * 
				fr_prodmfg.man_stk_con_qty 
				LET fv_act_cost_amt = fr_prodstatus.act_cost_amt * 
				fr_prodmfg.man_stk_con_qty 
				LET fv_list_price_amt = fr_prodstatus.list_amt * 
				fr_prodmfg.man_stk_con_qty 
			ELSE 
				IF fr_prodmfg.wgted_cost_amt IS NULL THEN 
					LET fr_prodmfg.wgted_cost_amt = 0 
				END IF 

				IF fr_prodmfg.est_cost_amt IS NULL THEN 
					LET fr_prodmfg.est_cost_amt = 0 
				END IF 

				IF fr_prodmfg.act_cost_amt IS NULL THEN 
					LET fr_prodmfg.act_cost_amt = 0 
				END IF 

				IF fr_prodmfg.list_price_amt IS NULL THEN 
					LET fr_prodmfg.list_price_amt = 0 
				END IF 

				LET fv_wgted_cost_amt = fr_prodmfg.wgted_cost_amt 
				LET fv_est_cost_amt = fr_prodmfg.est_cost_amt 
				LET fv_act_cost_amt = fr_prodmfg.act_cost_amt 
				LET fv_list_price_amt = fr_prodmfg.list_price_amt 
			END IF 

			CASE 
				WHEN fr_bor.uom_code = fr_product.pur_uom_code 
					LET fv_wgted_cost_amt = fv_wgted_cost_amt / 
					(fr_prodmfg.man_stk_con_qty / 
					fr_product.pur_stk_con_qty) 
					LET fv_est_cost_amt = fv_est_cost_amt / 
					(fr_prodmfg.man_stk_con_qty / 
					fr_product.pur_stk_con_qty) 
					LET fv_act_cost_amt = fv_act_cost_amt / 
					(fr_prodmfg.man_stk_con_qty / 
					fr_product.pur_stk_con_qty) 
					LET fv_list_price_amt = fv_list_price_amt / 
					(fr_prodmfg.man_stk_con_qty / 
					fr_product.pur_stk_con_qty) 

				WHEN fr_bor.uom_code = fr_product.stock_uom_code 
					LET fv_wgted_cost_amt = fv_wgted_cost_amt / 
					fr_prodmfg.man_stk_con_qty 
					LET fv_est_cost_amt = fv_est_cost_amt / 
					fr_prodmfg.man_stk_con_qty 
					LET fv_act_cost_amt = fv_act_cost_amt / 
					fr_prodmfg.man_stk_con_qty 
					LET fv_list_price_amt = fv_list_price_amt / 
					fr_prodmfg.man_stk_con_qty 

				WHEN fr_bor.uom_code = fr_product.sell_uom_code 
					LET fv_wgted_cost_amt = fv_wgted_cost_amt / 
					(fr_prodmfg.man_stk_con_qty * 
					fr_product.stk_sel_con_qty) 
					LET fv_est_cost_amt = fv_est_cost_amt / 
					(fr_prodmfg.man_stk_con_qty * 
					fr_product.stk_sel_con_qty) 
					LET fv_act_cost_amt = fv_act_cost_amt / 
					(fr_prodmfg.man_stk_con_qty * 
					fr_product.stk_sel_con_qty) 
					LET fv_list_price_amt = fv_list_price_amt / 
					(fr_prodmfg.man_stk_con_qty * 
					fr_product.stk_sel_con_qty) 
			END CASE 

			LET pv_wgted_cost_tot = pv_wgted_cost_tot + (fv_wgted_cost_amt * 
			fr_bor.required_qty * pv_min_ord_qty) 
			LET pv_est_cost_tot = pv_est_cost_tot + (fv_est_cost_amt * 
			fr_bor.required_qty * pv_min_ord_qty) 
			LET pv_act_cost_tot = pv_act_cost_tot + (fv_act_cost_amt * 
			fr_bor.required_qty * pv_min_ord_qty) 
			LET pv_list_price_tot = pv_list_price_tot + (fv_list_price_amt * 
			fr_bor.required_qty * pv_min_ord_qty) 
	END CASE 

END FUNCTION 
