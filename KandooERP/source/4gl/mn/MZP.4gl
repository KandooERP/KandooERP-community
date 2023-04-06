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

	Source code beautified by beautify.pl on 2020-01-02 17:31:37	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_formname CHAR(15) 
	DEFINE glob_err_continue CHAR(1) 
	DEFINE glob_err_message CHAR(40) 
	DEFINE glob_rec_menunames RECORD LIKE menunames.* 
END GLOBALS 


############################################################
# MAIN
#
# Purpose - Manufacturing parameters setup/maintenance
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("MZP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL param_main() 

END MAIN 


############################################################
# FUNCTION param_main()
#
# FUNCTION TO DISPLAY the SCREEN AND drive the program via a menu
############################################################
FUNCTION param_main() 
	DEFINE l_data_exists SMALLINT 
	DEFINE l_fv_update SMALLINT 
	DEFINE l_rec_fr_mnparms RECORD LIKE mnparms.* 
	DEFINE l_rec_fr_mnparms1 RECORD LIKE mnparms.* 

	OPEN WINDOW w1_m118 with FORM "M118" 
	CALL  windecoration_m("M118") -- albo kd-762 

	SELECT * 
	INTO l_rec_fr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND param_code = "1" --huho fixed -> was parm_code = "1" but this COLUMN does NOT exist in db 

	IF status = notfound THEN 
		LET l_data_exists = false 
	ELSE 
		LET l_data_exists = true 
		CALL display_params(l_rec_fr_mnparms.*) 
	END IF 

	CALL kandoomenu("M", 146) RETURNING glob_rec_menunames.* 
	MENU glob_rec_menunames.menu_text # manufacturing parameters 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND glob_rec_menunames.cmd1_code glob_rec_menunames.cmd1_text # add 
			IF l_data_exists THEN 
				LET msgresp = kandoomsg("M",9725,"") 			# ERROR "The parameters FOR this company already exist"
				NEXT option glob_rec_menunames.cmd2_code # UPDATE 
			ELSE 
				CALL input_params(true, l_rec_fr_mnparms.*) 
				RETURNING l_data_exists, l_rec_fr_mnparms.* 
				NEXT option glob_rec_menunames.cmd3_code # EXIT 
			END IF 

		COMMAND glob_rec_menunames.cmd2_code glob_rec_menunames.cmd2_text # UPDATE 
			IF l_data_exists THEN 
				LET l_rec_fr_mnparms1.* = l_rec_fr_mnparms.* 
				CALL input_params(false, l_rec_fr_mnparms.*) 
				RETURNING l_fv_update, l_rec_fr_mnparms.* 

				IF NOT l_fv_update THEN 
					LET l_rec_fr_mnparms.* = l_rec_fr_mnparms1.* 
					CALL display_params(l_rec_fr_mnparms.*) 
				END IF 

				NEXT option glob_rec_menunames.cmd3_code # EXIT 
			ELSE 
				LET msgresp = kandoomsg("M",9565,"") 
				# ERROR "No parameters exist FOR this company"
				NEXT option glob_rec_menunames.cmd1_code # add 
			END IF 

		COMMAND glob_rec_menunames.cmd3_code glob_rec_menunames.cmd3_text # EXIT 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW w1_m118 

END FUNCTION 


############################################################
# FUNCTION display_params(l_rec_mnparms)
#
# FUNCTION TO DISPLAY the parameter data on the SCREEN
############################################################
FUNCTION display_params(l_rec_mnparms) 
	DEFINE l_rec_mnparms RECORD LIKE mnparms.* 

	DISPLAY BY NAME l_rec_mnparms.forecast_num, 
	l_rec_mnparms.next_order_num, 
	l_rec_mnparms.neg_issue_flag, 
	l_rec_mnparms.upd_std_flag, 
	l_rec_mnparms.upd_list_flag, 
	l_rec_mnparms.wip_acct_code, 
	l_rec_mnparms.inv_rec_acct_code, 
	l_rec_mnparms.inv_exp_acct_code, 
	l_rec_mnparms.oper_start_time, 
	l_rec_mnparms.oper_end_time, 
	l_rec_mnparms.plan_type_ind, 
	l_rec_mnparms.plan_ver_num, 
	l_rec_mnparms.disk_fmt_flag, 
	l_rec_mnparms.schedule_flag, 
	l_rec_mnparms.file_dir_text, 
	l_rec_mnparms.ref1_text, 
	l_rec_mnparms.ref1_ind, 
	l_rec_mnparms.ref2_text, 
	l_rec_mnparms.ref2_ind, 
	l_rec_mnparms.ref3_text, 
	l_rec_mnparms.ref3_ind, 
	l_rec_mnparms.ref4_text, 
	l_rec_mnparms.ref4_ind 

END FUNCTION 


############################################################
# FUNCTION input_params(p_fv_add, p_rec_mnparms)
#
# FUNCTION TO change the parameter details
############################################################
FUNCTION input_params(p_fv_add, p_rec_mnparms) 
	DEFINE p_fv_add SMALLINT 
	DEFINE p_rec_mnparms RECORD LIKE mnparms.* 

	DEFINE l_fv_dir_not_exists SMALLINT 
	DEFINE l_fv_count INTEGER 
	DEFINE l_fv_runtext CHAR(255) 
	DEFINE l_fv_acct_code LIKE coa.acct_code 
	DEFINE l_fv_ref_ind LIKE mnparms.ref1_ind 


	IF p_fv_add THEN 
		INITIALIZE p_rec_mnparms.* TO NULL 
		LET p_rec_mnparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		#        LET p_rec_mnparms.parm_code         = "1"
		LET p_rec_mnparms.param_code = "1" 
		LET p_rec_mnparms.forecast_num = 1 
		LET p_rec_mnparms.next_order_num = 1 
		LET p_rec_mnparms.oper_start_time = "00:00:00" 
		LET p_rec_mnparms.oper_end_time = "23:59:59" 
		LET p_rec_mnparms.neg_issue_flag = "N" 
		LET p_rec_mnparms.upd_std_flag = "Y" 
		LET p_rec_mnparms.upd_wgted_flag = "Y" 
		LET p_rec_mnparms.upd_list_flag = "Y" 
		LET p_rec_mnparms.plan_type_ind = "T" 
		LET p_rec_mnparms.plan_ver_num = 4 
		LET p_rec_mnparms.disk_fmt_flag = "D" 
		LET p_rec_mnparms.schedule_flag = "F" 
		LET p_rec_mnparms.file_dir_text = "/tmp" 
		LET p_rec_mnparms.ref1_ind = 5 
		LET p_rec_mnparms.ref2_ind = 5 
		LET p_rec_mnparms.ref3_ind = 5 
		LET p_rec_mnparms.ref4_ind = 5 
	END IF 

	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	INPUT BY NAME p_rec_mnparms.forecast_num, 
	p_rec_mnparms.next_order_num, 
	p_rec_mnparms.neg_issue_flag, 
	p_rec_mnparms.upd_std_flag, 
	p_rec_mnparms.upd_list_flag, 
	p_rec_mnparms.wip_acct_code, 
	p_rec_mnparms.inv_rec_acct_code, 
	p_rec_mnparms.inv_exp_acct_code, 
	p_rec_mnparms.oper_start_time, 
	p_rec_mnparms.oper_end_time, 
	p_rec_mnparms.plan_type_ind, 
	p_rec_mnparms.plan_ver_num, 
	p_rec_mnparms.schedule_flag, 
	p_rec_mnparms.disk_fmt_flag, 
	p_rec_mnparms.file_dir_text, 
	p_rec_mnparms.ref1_text, 
	p_rec_mnparms.ref1_ind, 
	p_rec_mnparms.ref2_text, 
	p_rec_mnparms.ref2_ind, 
	p_rec_mnparms.ref3_text, 
	p_rec_mnparms.ref3_ind, 
	p_rec_mnparms.ref4_text, 
	p_rec_mnparms.ref4_ind 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield(wip_acct_code) 
			LET l_fv_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 

			IF l_fv_acct_code IS NOT NULL THEN 
				LET p_rec_mnparms.wip_acct_code = l_fv_acct_code 
				DISPLAY BY NAME p_rec_mnparms.wip_acct_code 
			END IF 

		ON KEY (control-b) infield(inv_rec_acct_code) 
			LET l_fv_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 

			IF l_fv_acct_code IS NOT NULL THEN 
				LET p_rec_mnparms.inv_rec_acct_code = l_fv_acct_code 
				DISPLAY BY NAME p_rec_mnparms.inv_rec_acct_code 
			END IF 

		ON KEY (control-b) infield(inv_exp_acct_code) 
			LET l_fv_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 

			IF l_fv_acct_code IS NOT NULL THEN 
				LET p_rec_mnparms.inv_exp_acct_code = l_fv_acct_code 
				DISPLAY BY NAME p_rec_mnparms.inv_exp_acct_code 
			END IF 

		ON KEY (control-b) infield(ref1_ind) 
			LET l_fv_ref_ind = lookup_refind() 

			IF l_fv_ref_ind IS NOT NULL THEN 
				LET p_rec_mnparms.ref1_ind = l_fv_ref_ind 
				DISPLAY BY NAME p_rec_mnparms.ref1_ind 
			END IF 

		ON KEY (control-b) infield(ref2_ind) 
			LET l_fv_ref_ind = lookup_refind() 

			IF l_fv_ref_ind IS NOT NULL THEN 
				LET p_rec_mnparms.ref2_ind = l_fv_ref_ind 
				DISPLAY BY NAME p_rec_mnparms.ref2_ind 
			END IF 

		ON KEY (control-b) infield(ref3_ind) 
			LET l_fv_ref_ind = lookup_refind() 

			IF l_fv_ref_ind IS NOT NULL THEN 
				LET p_rec_mnparms.ref3_ind = l_fv_ref_ind 
				DISPLAY BY NAME p_rec_mnparms.ref3_ind 
			END IF 

		ON KEY (control-b) infield(ref4_ind) 
			LET l_fv_ref_ind = lookup_refind() 

			IF l_fv_ref_ind IS NOT NULL THEN 
				LET p_rec_mnparms.ref4_ind = l_fv_ref_ind 
				DISPLAY BY NAME p_rec_mnparms.ref4_ind 
			END IF 


		AFTER FIELD forecast_num 
			IF p_rec_mnparms.forecast_num IS NULL THEN 
				LET msgresp = kandoomsg("M", 9550, "") 
				# ERROR "Next forecast number must be entered"
				NEXT FIELD forecast_num 
			END IF 

			IF p_rec_mnparms.forecast_num <= 0 THEN 
				LET msgresp = kandoomsg("M", 9755, "") 
				# ERROR "Next forecast number must be greater than zero"
				NEXT FIELD forecast_num 
			END IF 

		AFTER FIELD next_order_num 
			IF p_rec_mnparms.next_order_num IS NULL THEN 
				LET msgresp = kandoomsg("M", 9772, "") 
				# ERROR "Next shop ORDER number must be entered"
				NEXT FIELD next_order_num 
			END IF 

			IF p_rec_mnparms.next_order_num <= 0 THEN 
				LET msgresp = kandoomsg("M", 9819,"") 
				# ERROR "Next shop ORDER number must be greater than zero"
				NEXT FIELD next_order_num 
			END IF 

			SELECT unique shop_order_num 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = p_rec_mnparms.next_order_num 

			IF status = 0 THEN 
				LET msgresp = kandoomsg("M", 9727, "") 
				# ERROR "This shop ORDER number already exists"
				NEXT FIELD next_order_num 
			END IF 

			SELECT unique count(*) 
			INTO l_fv_count 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num > p_rec_mnparms.next_order_num 

			IF l_fv_count > 0 THEN 
				LET msgresp = kandoomsg("M", 9728, "") 
				#error"There are existing shop ORDER nos. greater than this one"
				NEXT FIELD next_order_num 
			END IF 

		AFTER FIELD neg_issue_flag 
			IF p_rec_mnparms.neg_issue_flag IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "You must enter a value in this field"
				NEXT FIELD neg_issue_flag 
			END IF 

			IF p_rec_mnparms.neg_issue_flag NOT matches "[NY]" THEN 
				LET msgresp = kandoomsg("M",9731,"") 
				# ERROR "An incorrect value was entered, enter either Y OR N"
				NEXT FIELD neg_issue_flag 
			END IF 

		AFTER FIELD upd_std_flag 
			IF p_rec_mnparms.upd_std_flag IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "You must enter a value in this field"
			END IF 

			IF p_rec_mnparms.upd_std_flag NOT matches "[NY]" THEN 
				LET msgresp = kandoomsg("M",9731,"") 
				# ERROR "An incorrect value was entered, enter either Y OR N"
				NEXT FIELD upd_std_flag 
			END IF 

		AFTER FIELD upd_list_flag 
			IF p_rec_mnparms.upd_list_flag IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "You must enter a value in this field"
				NEXT FIELD upd_list_flag 
			END IF 

			IF p_rec_mnparms.upd_list_flag NOT matches "[NY]" THEN 
				LET msgresp = kandoomsg("M",9731,"") 
				# ERROR "An incorrect value was entered, enter either Y OR N"
				NEXT FIELD upd_list_flag 
			END IF 

		AFTER FIELD wip_acct_code 
			IF p_rec_mnparms.wip_acct_code IS NOT NULL THEN 
				SELECT acct_code 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = p_rec_mnparms.wip_acct_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9702,"") 
					# ERROR "Work In Progress Account NOT found"
					NEXT FIELD wip_acct_code 
				END IF 
			END IF 

		AFTER FIELD inv_rec_acct_code 
			IF p_rec_mnparms.inv_rec_acct_code IS NOT NULL THEN 
				SELECT acct_code 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = p_rec_mnparms.inv_rec_acct_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9729,"") 
					# ERROR "Inventory Receipt Account NOT found"
					NEXT FIELD inv_rec_acct_code 
				END IF 
			END IF 

		AFTER FIELD inv_exp_acct_code 
			IF p_rec_mnparms.inv_exp_acct_code IS NOT NULL THEN 
				SELECT acct_code 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = p_rec_mnparms.inv_exp_acct_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9730,"") 
					# ERROR "Inventory Expenses Account NOT found"
					NEXT FIELD inv_exp_acct_code 
				END IF 
			END IF 

		AFTER FIELD plan_type_ind 
			IF p_rec_mnparms.plan_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9732,"") 
				# ERROR "You must enter a value FOR a Planning Tool"
				NEXT FIELD plan_type_ind 
			END IF 

			IF p_rec_mnparms.plan_type_ind NOT matches "[TP]" THEN 
				LET msgresp = kandoomsg("M",9733,"") 
				# ERROR "This IS NOT an valid Planning Tool"
				NEXT FIELD plan_type_ind 
			END IF 

		AFTER FIELD plan_ver_num 
			IF p_rec_mnparms.plan_type_ind = "T" THEN 
				IF p_rec_mnparms.plan_ver_num IS NULL THEN 
					LET msgresp = kandoomsg("M",9652,"") 
					# ERROR "You must enter a value in this field"
					NEXT FIELD plan_ver_num 
				END IF 

				IF p_rec_mnparms.plan_ver_num <> 4 
				AND p_rec_mnparms.plan_ver_num <> 5 THEN 
					LET msgresp = kandoomsg("M",9734,"") 
					# ERROR "This IS NOT an existing version of Time Line(c)"
					NEXT FIELD plan_ver_num 
				END IF 
			END IF 

		AFTER FIELD schedule_flag 
			IF p_rec_mnparms.schedule_flag IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "You must enter a value in this field"
				NEXT FIELD schedule_flag 
			END IF 

			IF p_rec_mnparms.schedule_flag NOT matches "[BF]" THEN 
				LET msgresp = kandoomsg("M",9736,"") 
				#ERROR "An incorrect value was entered, enter either B OR F"
				NEXT FIELD schedule_flag 
			END IF 

		AFTER FIELD disk_fmt_flag 
			IF p_rec_mnparms.disk_fmt_flag IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "You must enter a value in this field"
				NEXT FIELD disk_fmt_flag 
			END IF 

			IF p_rec_mnparms.disk_fmt_flag NOT matches "[ADU]" THEN 
				LET msgresp = kandoomsg("M",9735,"") 
				# ERROR "An incorrect value was entered,
				# enter one of A,D, OR U"
				NEXT FIELD disk_fmt_flag 
			END IF 

		AFTER FIELD file_dir_text 
			IF p_rec_mnparms.file_dir_text IS NULL THEN 
				LET msgresp = kandoomsg("M",9737,"") 
				# ERROR "You must enter a directory in this field"
				NEXT FIELD file_dir_text 
			END IF 

			LET l_fv_runtext = "test -d ", p_rec_mnparms.file_dir_text clipped 
			RUN l_fv_runtext RETURNING l_fv_dir_not_exists 

			IF l_fv_dir_not_exists THEN 
				LET msgresp = kandoomsg("M",9738,"") 
				# ERROR "This directory does NOT exist OR IS NOT a directory"
				NEXT FIELD file_dir_text 
			END IF 

		AFTER FIELD ref1_ind 
			IF p_rec_mnparms.ref1_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9741,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD ref1_ind 
			END IF 

			IF p_rec_mnparms.ref1_text IS NOT NULL 
			AND p_rec_mnparms.ref1_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref1_ind 
			END IF 

			IF p_rec_mnparms.ref1_text IS NULL 
			AND p_rec_mnparms.ref1_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref1_ind 
			END IF 

		AFTER FIELD ref2_ind 
			IF p_rec_mnparms.ref2_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9741,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD ref2_ind 
			END IF 

			IF p_rec_mnparms.ref2_text IS NOT NULL 
			AND p_rec_mnparms.ref2_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref2_ind 
			END IF 

			IF p_rec_mnparms.ref2_text IS NULL 
			AND p_rec_mnparms.ref2_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref2_ind 
			END IF 

		AFTER FIELD ref3_ind 
			IF p_rec_mnparms.ref3_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9741,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD ref3_ind 
			END IF 

			IF p_rec_mnparms.ref3_text IS NOT NULL 
			AND p_rec_mnparms.ref3_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref3_ind 
			END IF 

			IF p_rec_mnparms.ref3_text IS NULL 
			AND p_rec_mnparms.ref3_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref3_ind 
			END IF 

		AFTER FIELD ref4_ind 
			IF p_rec_mnparms.ref4_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9741,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD ref4_ind 
			END IF 

			IF p_rec_mnparms.ref4_text IS NOT NULL 
			AND p_rec_mnparms.ref4_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref4_ind 
			END IF 

			IF p_rec_mnparms.ref4_text IS NULL 
			AND p_rec_mnparms.ref4_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref4_ind 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			LET l_fv_runtext = "test -d ", p_rec_mnparms.file_dir_text clipped 
			RUN l_fv_runtext RETURNING l_fv_dir_not_exists 

			IF l_fv_dir_not_exists THEN 
				LET msgresp = kandoomsg("M",9738,"") 
				#ERROR "The directory entered does NOT exist
				#OR IS NOT a directory"
				NEXT FIELD file_dir_text 
			END IF 

			IF p_rec_mnparms.ref1_text IS NOT NULL 
			AND p_rec_mnparms.ref1_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref1_ind 
			END IF 

			IF p_rec_mnparms.ref1_text IS NULL 
			AND p_rec_mnparms.ref1_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref1_ind 
			END IF 

			IF p_rec_mnparms.ref2_text IS NOT NULL 
			AND p_rec_mnparms.ref2_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref2_ind 
			END IF 

			IF p_rec_mnparms.ref2_text IS NULL 
			AND p_rec_mnparms.ref2_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref2_ind 
			END IF 

			IF p_rec_mnparms.ref3_text IS NOT NULL 
			AND p_rec_mnparms.ref3_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref3_ind 
			END IF 

			IF p_rec_mnparms.ref3_text IS NULL 
			AND p_rec_mnparms.ref3_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref3_ind 
			END IF 

			IF p_rec_mnparms.ref4_text IS NOT NULL 
			AND p_rec_mnparms.ref4_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("M",9739,"") 
				# ERROR "Indicator must be either 1 OR 2 "
				NEXT FIELD ref4_ind 
			END IF 

			IF p_rec_mnparms.ref4_text IS NULL 
			AND p_rec_mnparms.ref4_ind != "5" THEN 
				LET msgresp = kandoomsg("M",9740,"") 
				# ERROR "Indicator must be 5 "
				NEXT FIELD ref4_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		IF p_fv_add THEN 
			CLEAR FORM 
			LET msgresp = kandoomsg("M",9549,"") 
			# ERROR "Add Aborted"
		ELSE 
			LET msgresp = kandoomsg("M",9562,"") 
			# ERROR "Update Aborted"
		END IF 

		RETURN false, p_rec_mnparms.* 
	END IF 

	GOTO bypass 

	LABEL recovery: 
	LET glob_err_continue = error_recover(glob_err_message, status) 
	IF glob_err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		#    LET p_rec_mnparms.last_change_date  = today
		LET p_rec_mnparms.last_change = today 
		#    LET p_rec_mnparms.last_user_text    = glob_rec_kandoouser.sign_on_code
		LET p_rec_mnparms.last_user = glob_rec_kandoouser.sign_on_code 
		#    LET p_rec_mnparms.last_program_text = "MZP"
		LET p_rec_mnparms.last_program = "MZP" 

		IF p_fv_add THEN 
			LET glob_err_message = "MZP - Insert INTO mnparms failed" 

			INSERT INTO mnparms VALUES (p_rec_mnparms.*) 
		ELSE 
			LET glob_err_message = "MZP - Update of mnparms failed" 

			UPDATE mnparms 
			SET * = p_rec_mnparms.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		END IF 

	COMMIT WORK 
	WHENEVER ERROR stop 

	RETURN true, p_rec_mnparms.* 

END FUNCTION 
