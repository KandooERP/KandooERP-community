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
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 
###########################################################################
# MAIN 
#
# Purpose - Automatic Billing - Contracts
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("JA6") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS INPUT wrap 


	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 

	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT * 
	INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",5101,"") 
		#5101 Accounts Receivable Parameters Not Setup;  Refer Menu AZP.
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	CREATE temp TABLE tempbill 
	( 
	trans_invoice_flag CHAR(1), 
	trans_date DATE NOT null, 
	var_code SMALLINT NOT null, 
	activity_code CHAR(8) NOT null, 
	seq_num INTEGER, 
	line_num SMALLINT, 
	trans_type_ind CHAR(2), 
	trans_source_num INTEGER, 
	trans_source_text CHAR(8), 
	trans_amt money(16,2), # \ 
	trans_qty DECIMAL(15,3), # - total OF transaction 
	charge_amt money(16,2), # / 
	apply_qty DECIMAL(15,3), # \ 
	apply_amt DECIMAL(16,2), # - this invoice line 
	apply_cos_amt DECIMAL(16,2), # / 
	desc_text CHAR(40), # -who PUT this FIELD here?? 
	prev_apply_qty DECIMAL(15,3), # \ 
	prev_apply_amt DECIMAL(16,2), # - previous invoice LINES 
	prev_apply_cos_amt DECIMAL(16,2),# / 
	allocation_ind CHAR(1) 
	) with no LOG 

	CREATE unique INDEX tempbill ON tempbill(var_code, 
	activity_code, 
	line_num, 
	seq_num) 

	IF num_args() > 0 THEN 
		LET sel_contract_text = "SELECT unique contracthead.contract_code ", 
		"FROM contracthead, contractdetl ", 
		"WHERE contracthead.contract_code = \"", arg_val(1), "\" ", 
		"AND contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND contracthead.cmpy_code = contractdetl.cmpy_code ", 
		"AND contracthead.contract_code = contractdetl.contract_code" 

		LET sel_inv1_text = "SELECT contracthead.*, contractdetl.* ", 
		"FROM contracthead, contractdetl WHERE ", 
		"AND contracthead.cmpy_code = ", glob_rec_kandoouser.cmpy_code," AND " 

		LET sel_inv2_text = " contracthead.cmpy_code = ", 
		"contractdetl.cmpy_code AND ", 
		"contracthead.contract_code = contractdetl.contract_code ", 
		"ORDER BY contractdetl.type_code, ", 
		"contractdetl.job_code, ", 
		"contractdetl.ship_code " 
		CALL auto_bill() 
	ELSE 
		OPEN WINDOW wja00 with FORM "JA00" -- alch kd-747 
		CALL winDecoration_j("JA00") -- alch kd-747 
		DISPLAY BY NAME pr_jmparms.cntrhd_prmpt_text 
		MENU " Automatic Billing" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","JA6","menu-automatic_billing-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Header" " SELECT Contracts FOR Automatic Billing" 
				CALL head_cur() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT option "Header" 
				ELSE 
					CALL auto_bill() 
				END IF 

			COMMAND TRAN_TYPE_JOB_JOB " SELECT Jobs FOR Automatic Billing" 
				CALL job_cur() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT option TRAN_TYPE_JOB_JOB 
				ELSE 
					CALL auto_bill() 
				END IF 

			COMMAND "Inventory" " SELECT Inventory FOR Automatic Billing" 
				CALL invent_cur() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT option "Inventory" 
				ELSE 
					CALL auto_bill() 
				END IF 

			COMMAND "General" " SELECT General Description FOR Automatic Billing" 
				CALL gen_cur() 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT option "General" 
				ELSE 
					CALL auto_bill() 
				END IF 

			COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 

		CLOSE WINDOW wja00 

	END IF 

END MAIN 
###########################################################################
# END MAIN 
###########################################################################


###########################################################################
# FUNCTION head_cur() 
#
# Purpose - Automatic Billing - Contracts
###########################################################################
FUNCTION head_cur() 
	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE "Enter selection criteria - ESC TO continue"
	CONSTRUCT BY NAME query_text ON 
	contracthead.contract_code, 
	contracthead.desc_text, 
	contracthead.cust_code, 
	contracthead.user1_text, 
	contracthead.last_billed_date, 
	contracthead.bill_type_code, 
	contracthead.bill_int_ind, 
	contracthead.start_date, 
	contracthead.end_date, 
	contracthead.entry_code, 
	contracthead.entry_date, 
	contracthead.contract_value_amt, 
	contracthead.sale_code, 
	contracthead.comm1_text, 
	contracthead.comm2_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA6","const-contract_code-4") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET sel_contract_text = "SELECT unique contracthead.contract_code, ", 
	"contracthead.status_code ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " ", 
	"AND contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 

	"contractdetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' AND ", 
	"contracthead.contract_code = contractdetl.contract_code" 

	LET sel_inv1_text = "SELECT contracthead.*, contractdetl.* ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND " 

	LET sel_inv2_text = " contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 

	"contractdetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' AND ", 
	"contracthead.contract_code = contractdetl.contract_code ", 
	"ORDER BY contractdetl.type_code, ", 
	"contractdetl.job_code, ", 
	"contractdetl.ship_code " 

END FUNCTION 
###########################################################################
# END FUNCTION head_cur() 
###########################################################################


###########################################################################
# FUNCTION job_cur()
#
# Purpose - Automatic Billing - Contracts
###########################################################################
FUNCTION job_cur() 
	OPEN WINDOW wja03 with FORM "JA03" -- alch kd-747 
	CALL winDecoration_j("JA03") -- alch kd-747 

	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE "Enter selection criteria - ESC TO continue"

	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 

	CONSTRUCT BY NAME query_text ON 
	contractdetl.ship_code, 
	contractdetl.user1_text, 
	contractdetl.user2_text, 
	contractdetl.job_code, 
	contractdetl.var_code, 
	contractdetl.activity_code, 
	contractdetl.desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA6","const-ship_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET sel_contract_text = "SELECT unique contracthead.contract_code, ", 
	"contracthead.status_code ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND ", 
	"contractdetl.type_code = \"J\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code ", 
	"AND contracthead.status_code = \"A\" ", 
	"AND contractdetl.status_code = \"A\" " 

	LET sel_inv1_text = "SELECT contracthead.*, contractdetl.* ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, 
	"AND contracthead.status_code = \"A\" ", 
	"AND contractdetl.status_code = \"A\" AND " 

	LET sel_inv2_text = " contractdetl.type_code = \"J\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code ", 
	"AND contracthead.status_code = \"A\" ", 
	"AND contractdetl.status_code = \"A\" ", 
	"ORDER BY contractdetl.type_code, ", 
	"contractdetl.job_code, ", 
	"contractdetl.ship_code " 


	CLOSE WINDOW wja03 

END FUNCTION 
###########################################################################
# END FUNCTION job_cur()
###########################################################################


###########################################################################
# FUNCTION invent_cur()
#
# 
###########################################################################
FUNCTION invent_cur() 
	OPEN WINDOW wja04 with FORM "JA04" -- alch kd-747 
	CALL winDecoration_j("JA04") -- alch kd-747 
	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE "Enter selection criteria - ESC TO continue"

	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 
	CONSTRUCT BY NAME query_text ON 
	contractdetl.ship_code, 
	contractdetl.user1_text, 
	contractdetl.user2_text, 
	contractdetl.part_code, 
	contractdetl.desc_text, 
	contractdetl.bill_qty, 
	contractdetl.bill_price 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA6","const-ship_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET sel_contract_text = "SELECT unique contracthead.contract_code, ", 
	"contracthead.status_code ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND ", 
	"contractdetl.type_code = \"I\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code" 

	LET sel_inv1_text = "SELECT contracthead.*, contractdetl.* ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND " 

	LET sel_inv2_text = "contractdetl.type_code = \"I\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code ", 
	"ORDER BY contractdetl.type_code, ", 
	"contractdetl.job_code, ", 
	"contractdetl.ship_code " 

	CLOSE WINDOW wja04 

END FUNCTION 
###########################################################################
# END FUNCTION invent_cur()
###########################################################################


###########################################################################
# FUNCTION gen_cur()
#
# 
###########################################################################
FUNCTION gen_cur() 
	OPEN WINDOW wja05 with FORM "JA05" -- alch kd-747 
	CALL winDecoration_j("JA05") -- alch kd-747 
	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE "Enter selection criteria - ESC TO continue"
	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 
	CONSTRUCT BY NAME query_text ON 
	contractdetl.ship_code, 
	contractdetl.user1_text, 
	contractdetl.user2_text, 
	contractdetl.desc_text, 
	contractdetl.bill_qty, 
	contractdetl.bill_price, 
	contractdetl.revenue_acct_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA6","const-ship_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET sel_contract_text = "SELECT unique contracthead.contract_code, ", 
	"contracthead.status_code ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND ", 
	"contractdetl.type_code = \"G\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code" 

	LET sel_inv1_text = "SELECT contracthead.*, contractdetl.* ", 
	"FROM contracthead, contractdetl ", 
	"WHERE ", query_text clipped, " AND " 

	LET sel_inv2_text = "contractdetl.type_code = \"G\" AND ", 
	"contracthead.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"contracthead.cmpy_code = contractdetl.cmpy_code AND ", 
	"contracthead.contract_code = contractdetl.contract_code ", 
	"ORDER BY contractdetl.type_code, ", 
	"contractdetl.job_code, ", 
	"contractdetl.ship_code " 

	CLOSE WINDOW wja05 

END FUNCTION 
###########################################################################
# FUNCTION gen_cur()
#
# 
###########################################################################


###########################################################################
# FUNCTION auto_bill()
#
# 
###########################################################################
FUNCTION auto_bill() 
	DEFINE 
	fv_delete_flag, 
	fv_cnt SMALLINT, 
	fv_entry_code LIKE tentinvhead.entry_code 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET pv_error_run = false 
	OPEN WINDOW wja12 with FORM "JA12" -- alch kd-747 
	CALL winDecoration_j("JA12") -- alch kd-747 
	LET pv_billing_type = "B" 
	LET pv_invoice_date = today 

	LET pv_billing_delete = "Y" 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pv_year_num, pv_period_num 

	LET msgresp = kandoomsg("A",1511,"") 
	# MESSAGE "ESC TO accept, DEL TO EXIT"

	INPUT BY NAME pv_billing_type, 
	pv_invoice_date, 
	pv_billing_delete, 
	pv_year_num, 
	pv_period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA6","input-pv_billing_type-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD pv_billing_type 
			IF pv_billing_type IS NULL THEN 
				LET msgresp = kandoomsg("A",9530,"") 
				# ERROR "Billing type must be entered"
				NEXT FIELD pv_billing_type 
			END IF 

		AFTER FIELD pv_invoice_date 
			IF pv_invoice_date IS NULL THEN 
				LET msgresp = kandoomsg("A",9531,"") 
				# ERROR "Invoice commencement date must be entered"
				NEXT FIELD pv_invoice_date 
			END IF 

		AFTER FIELD pv_billing_delete 
			IF pv_billing_delete IS NULL THEN 
				LET msgresp = kandoomsg("A",9532,"") 
				# ERROR "Overwrite billing flag must be entered"
				NEXT FIELD pv_billing_delete 
			END IF 

			# handle the year & period fields added
		AFTER FIELD pv_year_num 
			SELECT unique year_num 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pv_year_num 

			IF status = notfound THEN 
				#9210 Year number IS invalid
				LET msgresp = kandoomsg("E", 9210, "") 
				NEXT FIELD pv_year_num 
			END IF 

		AFTER FIELD pv_period_num 
			SELECT unique year_num 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pv_year_num 
			AND period_num = pv_period_num 
			AND ar_flag = "Y" 

			IF (status=notfound) THEN 
				#9507 "Year & Period closed OR NOT setup
				LET msgresp = kandoomsg("P", 9024, "") 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				#Do nothing
			ELSE 
				SELECT unique year_num 
				FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = pv_year_num 
				AND period_num = pv_period_num 
				AND ar_flag = "Y" 

				IF (status=notfound) THEN 
					#9507 "Year & Period closed OR NOT setup
					LET msgresp = kandoomsg("P", 9024, "") 
					NEXT FIELD pv_year_num 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW wja12 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	IF pv_billing_delete = "Y" THEN 
		LET fv_entry_code = glob_rec_kandoouser.sign_on_code 


		FOR fv_cnt = 1 TO 1488 
			IF query_text[fv_cnt, fv_cnt + 12] = "contract_code" THEN 
				LET fv_entry_code = NULL 
				EXIT FOR 
			END IF 
		END FOR 
		OPEN WINDOW wja14 with FORM "JA14" -- alch kd-747 
		CALL winDecoration_j("JA14") -- alch kd-747 
		LET msgresp = kandoomsg("A",1511,"") 
		# MESSAGE "ESC TO accept, DEL TO EXIT"


		INPUT fv_entry_code WITHOUT DEFAULTS FROM entry_code 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JA6","input-fv_entry_code-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD entry_code 
				IF fv_entry_code IS NOT NULL THEN 
					SELECT * 
					FROM kandoouser 
					WHERE sign_on_code = fv_entry_code 

					IF status = notfound THEN 
						#9200 "Unable TO find user <VALUE>
						LET msgresp = kandoomsg("U", 9200, fv_entry_code) 
						NEXT FIELD entry_code 
					END IF 

					IF NOT compare_user_access(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					fv_entry_code, 
					"A", 
					"1") 
					THEN 
						#9200 "You do NOT have access TO user <VALUE>"
						LET msgresp = kandoomsg("U", 9201, fv_entry_code) 
						NEXT FIELD entry_code 
					END IF 
				END IF 

		END INPUT 

		CLOSE WINDOW wja14 

		IF int_flag OR quit_flag THEN 
			RETURN 
		END IF 
	END IF 



	#------------------------------------------------------------	
	LET l_rpt_idx = rpt_start(getmoduleid(),"AC1_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JA6_rpt_list_autobill TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	# Cursor of all contracts FOR this request

	PREPARE s_contract FROM sel_contract_text 
	DECLARE contract_cur CURSOR with HOLD FOR s_contract 


	LET pv_cnt = 0 
	LET pv_run_total = 0 

	FOREACH contract_cur INTO pv_contract_code, pr_contracthead.status_code 

		CASE 
			WHEN pv_billing_type = "B" 

				LET sel_dat_text = "SELECT * FROM contractdate ", 
				"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
				"AND contract_code = \"", pv_contract_code, "\" ", 
				"AND inv_num IS NULL ", 
				"AND invoice_date < '", pv_invoice_date, "' ", 

				"ORDER BY invoice_date asc" 

			WHEN pv_billing_type = "F" 

				LET sel_dat_text = "SELECT * FROM contractdate ", 
				"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
				"AND contract_code = \"", pv_contract_code, "\" ", 
				"AND inv_num IS NULL ", 
				"AND invoice_date > '", pv_invoice_date, "' ", 
				"ORDER BY invoice_date asc" 

			WHEN pv_billing_type = "C" 

				LET sel_dat_text = "SELECT * FROM contractdate ", 
				"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
				"AND contract_code = \"", pv_contract_code, "\" ", 
				"AND inv_num IS NULL ", 
				"AND invoice_date = '", pv_invoice_date, "'" 

		END CASE 

		# delete details IF requested

		IF pv_billing_delete = "Y" THEN 
			DECLARE inv_delj_cur CURSOR FOR 
			SELECT * 
			FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pv_contract_code 

			FOREACH inv_delj_cur INTO pr_tentinvhead.* 
				IF fv_entry_code IS NULL THEN 
					LET fv_delete_flag = true 
				ELSE 
					IF fv_entry_code = pr_tentinvhead.entry_code THEN 
						LET fv_delete_flag = true 
					ELSE 
						LET fv_delete_flag = false 
					END IF 
				END IF 

				IF fv_delete_flag THEN 
					IF compare_user_access(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					pr_tentinvhead.entry_code, 
					"A", 
					"1") 
					THEN 
						DELETE FROM tentinvdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = pr_tentinvhead.inv_num 

						DELETE FROM tentinvhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = pr_tentinvhead.inv_num 
					END IF 
				END IF 
			END FOREACH 

			CLOSE inv_delj_cur 
		END IF 

		IF pr_contracthead.status_code != "A" THEN 
			CONTINUE FOREACH 
		END IF 

		# Cursor of all requested contract dates FOR the contract being processed

		LET sel_dat_text = sel_dat_text clipped 
		PREPARE sel_dat_text FROM sel_dat_text 

		DECLARE c_date_cur CURSOR with HOLD FOR sel_dat_text 

		FOREACH c_date_cur INTO pr_contractdate.* 


			SELECT unique inv_date 
			FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pv_contract_code 
			AND inv_date = pr_contractdate.invoice_date 

			IF status != notfound THEN 
				IF pv_billing_type = "F" THEN 
					EXIT FOREACH 
				ELSE 
					CONTINUE FOREACH 
				END IF 
			END IF 


			LET pv_error = false 




			LET pr_period.year_num = pv_year_num 
			LET pr_period.period_num = pv_period_num 

			IF pr_period.year_num IS NULL AND	pr_period.period_num IS NULL THEN 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = pr_contractdate.invoice_date,		" - Invoice date IS NOT valid"
				
				#---------------------------------------------------------
				OUTPUT TO REPORT JA6_rpt_list_autobill(l_rpt_idx,
				glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
				IF NOT rpt_int_flag_handler2("Contract:",pr_contractdate.contract_code, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------				
				 
			END IF 

			SELECT ar_flag 
			INTO pr_period.ar_flag 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = pr_period.year_num 
			AND period_num = pr_period.period_num 

			IF status = 0 AND pr_period.ar_flag = "Y" THEN 
				# do nothing
			ELSE 
				LET pv_error = true 
				LET pv_error_run = true 
				LET pv_error_text = pr_contractdate.invoice_date,	" - Accounts Receiveable NOT OPEN FOR this date" 
				#---------------------------------------------------------
				OUTPUT TO REPORT JA6_rpt_list_autobill(l_rpt_idx,
				glob_rec_kandoouser.cmpy_code, 
				pr_company.name_text, 
				pr_contractdate.contract_code, 
				pr_contractdate.inv_num, 
				pr_contractdate.invoice_date, 
				pr_contractdate.invoice_total_amt, 
				pv_error_text) 
				IF NOT rpt_int_flag_handler2("Contract:",pr_contractdate.contract_code, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------	
			END IF 

			IF pv_error = false THEN 
				CALL contract_invoice() 
			END IF 

			IF pv_billing_type = "F" THEN 
				# 1 invoice only FOR forward billing
				EXIT FOREACH 
			END IF 
		END FOREACH 

		CLOSE c_date_cur 

	END FOREACH 

	CLOSE contract_cur 

	#------------------------------------------------------------
	FINISH REPORT JA6_rpt_list_autobill
	CALL rpt_finish("JA6_rpt_list_autobill")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 


	IF pv_error_run = true THEN 
		CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
	ELSE 
		IF pv_cnt > 0 THEN 
			OPEN WINDOW JA11 with FORM "JA11" -- alch kd-747 
			CALL winDecoration_j("JA11") -- alch kd-747 
			LET msgresp = kandoomsg("A",1007,"")	# MESSAGE "F3 Fwd, F4 Bwd, RETURN TO view invoice - DEL TO Exit"
			CALL set_count(pv_cnt) 

			DISPLAY pv_run_total TO run_total_amt 
			DISPLAY ARRAY pa_tentinvrun TO sr_contracthead.*
			 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","JA6","display-arr-tentinvrun") -- alch kd-506

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (RETURN) 
					LET fv_cnt = arr_curr() 
					OPTIONS 
					INPUT no wrap 
					CALL display_detail(fv_cnt) 
					OPTIONS 
					INPUT wrap 

			END DISPLAY 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

			CLOSE WINDOW JA11 

		ELSE 
			LET msgresp = kandoomsg("J",9259,"") 
			# ERROR "No tentative invoices were created"
		END IF 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION auto_bill()
###########################################################################


###########################################################################
# FUNCTION contract_invoice()
#
# 
###########################################################################
FUNCTION contract_invoice() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET pv_invoice_present = false 
	LET pv_prev_type_code = " " 
	LET pv_curr_idx = 0 
	LET pv_job_start_idx = 0 

	#   Cursor of contract details FOR the requested date
	#   Details are in type code, job code, shipping code ORDER
	#   This allows processing in the following ORDER
	#      Inventory  }
	#      General    }  1 invoice
	#
	#      Jobs       }  1 invoice FOR each job

	LET sel_inv_text = sel_inv1_text clipped, 
	" contracthead.contract_code = \"", pv_contract_code, "\" AND ", 
	sel_inv2_text clipped 

	PREPARE sel_inv_text FROM sel_inv_text 
	DECLARE c_inv_cur CURSOR with HOLD FOR sel_inv_text 

	FOREACH c_inv_cur INTO pr_contracthead.*, pr_contractdetl.* 

		DISPLAY " Processing Contract : ", pv_contract_code clipped, 
		" dated ", pr_contractdate.invoice_date at 1,1 

		CASE 
			WHEN pr_contractdetl.type_code = "G" 
				IF pv_invoice_present = false THEN 
					CALL inv_header() 
				END IF 
				IF pv_error = false THEN 
					CALL general_invoicing() 
				END IF 

			WHEN pr_contractdetl.type_code = "I" 
				IF pv_invoice_present = false THEN 
					CALL inv_header() 
				END IF 
				IF pv_error = false THEN 
					CALL invent_invoicing() 
				END IF 

			WHEN pr_contractdetl.type_code = "J" 

				IF pr_contracthead.cons_inv_flag = "Y" THEN 
					IF pv_prev_type_code != "J" THEN 
						# first job FOR consolidated invoice
						IF pv_invoice_present = false THEN 
							CALL inv_header() 
						END IF 

						LET pv_job_start_idx = pv_curr_idx + 1 
						LET pr_tentinvhead.com2_text = "Contract : ", 
						pr_contracthead.contract_code 
					END IF 

					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_contractdetl.job_code 

					IF status = 0 THEN 
						LET pr_tentinvhead.bill_issue_ind = pr_job.bill_issue_ind 
					ELSE 
						LET pv_error = true 
						LET pv_error_run = true 
						LET pv_error_text = pr_contractdetl.job_code, " - Job NOT found" 

						#---------------------------------------------------------
						OUTPUT TO REPORT JA6_rpt_list_autobill(l_rpt_idx,
						glob_rec_kandoouser.cmpy_code, 
						pr_company.name_text, 
						pr_contractdate.contract_code, 
						pr_contractdate.inv_num, 
						pr_contractdate.invoice_date, 
						pr_contractdate.invoice_total_amt, 
						pv_error_text) 
						IF NOT rpt_int_flag_handler2("Contract:",pr_contractdate.contract_code, NULL,l_rpt_idx) THEN
							EXIT FOREACH 
						END IF 
						#---------------------------------------------------------	
					END IF 

					IF pv_error = false THEN 
						CALL job_invoicing() 
					END IF 
				ELSE 

					IF pv_invoice_present = true THEN 
						CALL commit_invoice() 
					END IF 

					CALL inv_header() 

					IF pv_error = false THEN 
						CALL job_invoicing() 

						IF pv_error = false THEN 
							LET pv_job_start_idx = 1 
							CALL job_inv_write() 
						END IF 
					END IF 
				END IF 
		END CASE 

		LET pv_prev_type_code = pr_contractdetl.type_code 
	END FOREACH 

	CLOSE c_inv_cur 


	IF pv_invoice_present = true 
	AND pv_error = false THEN 
		IF pv_prev_type_code = "J" THEN 
			CALL job_inv_write() 
		ELSE 
			CALL commit_invoice() 
		END IF 
	END IF 

END FUNCTION 
###########################################################################
# FUNCTION display_detail(fv_idx)
#
# 
###########################################################################


###########################################################################
# FUNCTION display_detail(fv_idx)
#
# 
###########################################################################
FUNCTION display_detail(fv_idx) 
	DEFINE fv_org_name_text LIKE customer.name_text 
	DEFINE fv_sp_name_text LIKE salesperson.name_text 
	DEFINE fv_idx SMALLINT
	 
	OPEN WINDOW A192 with FORM "A192" -- alch kd-747 
	CALL winDecoration_a("A192") -- alch kd-747
 
	SELECT * 
	INTO pr_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pa_tentinvrun[fv_idx].inv_num 

	DISPLAY BY NAME pr_tentinvhead.cust_code, 
	pr_tentinvhead.name_text, 
	pr_tentinvhead.org_cust_code, 
	pr_tentinvhead.inv_num, 
	pr_tentinvhead.ord_num, 
	pr_tentinvhead.currency_code, 
	pr_tentinvhead.goods_amt, 
	pr_tentinvhead.tax_amt, 
	pr_tentinvhead.hand_amt, 
	pr_tentinvhead.freight_amt, 
	pr_tentinvhead.total_amt, 
	pr_tentinvhead.paid_amt, 
	pr_tentinvhead.inv_date, 
	pr_tentinvhead.due_date, 
	pr_tentinvhead.disc_date, 
	pr_tentinvhead.paid_date, 
	pr_tentinvhead.disc_amt, 
	pr_tentinvhead.disc_taken_amt, 
	pr_tentinvhead.year_num, 
	pr_tentinvhead.period_num, 
	pr_tentinvhead.posted_flag, 
	pr_tentinvhead.entry_code, 
	pr_tentinvhead.entry_date, 
	pr_tentinvhead.sale_code, 
	pr_tentinvhead.inv_ind, 
	pr_tentinvhead.job_code, 
	pr_tentinvhead.com1_text, 
	pr_tentinvhead.com2_text, 
	pr_tentinvhead.on_state_flag, 
	pr_tentinvhead.rev_date, 
	pr_tentinvhead.rev_num 


	IF pr_tentinvhead.org_cust_code IS NOT NULL THEN 
		SELECT name_text 
		INTO fv_org_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_tentinvhead.org_cust_code 
		DISPLAY fv_org_name_text TO org_name_text 
	END IF 
	IF pr_tentinvhead.paid_date != "31/12/1899" THEN 
		DISPLAY BY NAME pr_tentinvhead.paid_date 
	END IF 
	SELECT name_text 
	INTO fv_sp_name_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = pr_tentinvhead.sale_code 

	DISPLAY fv_sp_name_text TO salesperson.name_text 

	MENU "Invoice" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA6","menu-invoice-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY ("D",f20) "Detail" "View invoice details" 
			IF pr_tentinvhead.inv_ind = "3" THEN 
				CALL tnjmlineshow(glob_rec_kandoouser.cmpy_code, 
				pr_tentinvhead.cust_code, 
				pr_tentinvhead.inv_num, 
				"View Invoice") 
				NEXT option "Exit" 
			ELSE 
				CALL ar_detail_menu() 
				NEXT option "Exit" 
			END IF 

		COMMAND "Exit" "Exit this program" 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW A192 
END FUNCTION 
###########################################################################
# FUNCTION display_detail(fv_idx)
#
# 
###########################################################################


###########################################################################
# FUNCTION ar_detail_menu()
#
# 
###########################################################################
FUNCTION ar_detail_menu() 
	DEFINE pr_option CHAR(1) 

	OPEN WINDOW wja15 with FORM "JA15" -- alch kd-747 
	CALL winDecoration_j("JA15") -- alch kd-747 

	DISPLAY BY NAME pr_tentinvhead.inv_num, 
	pr_tentinvhead.name_text 

	INPUT BY NAME pr_option WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA6","input-pr_option-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 

			CASE pr_option 
				WHEN "1" 
					CALL tnarlineshow(glob_rec_kandoouser.cmpy_code, 
					pr_tentinvhead.cust_code, 
					pr_tentinvhead.inv_num, 
					"View Invoice") 
					NEXT FIELD pr_option 

				WHEN "2" 
					CALL show_inv_entry(glob_rec_kandoouser.cmpy_code, 
					pr_tentinvhead.inv_num) 
					NEXT FIELD pr_option 

				WHEN "3" 
					CALL show_inv_ship(glob_rec_kandoouser.cmpy_code, 
					pr_tentinvhead.inv_num) 
					NEXT FIELD pr_option 

				WHEN "C" 
					IF change_invoice() THEN 
						DISPLAY BY NAME pr_tentinvhead.inv_num, 
						pr_tentinvhead.name_text 
					END IF 
					NEXT FIELD pr_option 

				WHEN "E" 
					EXIT CASE 

				OTHERWISE 
					NEXT FIELD pr_option 
			END CASE 


	END INPUT 

	CLOSE WINDOW wja15 

END FUNCTION 
###########################################################################
# END FUNCTION ar_detail_menu()
#
# 
###########################################################################


###########################################################################
# FUNCTION change_invoice()
#
# 
###########################################################################
FUNCTION change_invoice() 

	LET msgresp = kandoomsg("A",1524,"") 
	# MESSAGE "Enter new invoice number"

	INPUT BY NAME pr_tentinvhead.inv_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA6","input-pr_tentinvhead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			SELECT cust_code, name_text 
			INTO pr_tentinvhead.cust_code, pr_tentinvhead.name_text 
			FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = pr_tentinvhead.inv_num 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9524,"") 
				# ERROR "Invoice number invalid"
				NEXT FIELD inv_num 
			END IF 


	END INPUT 

	MESSAGE "" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION change_invoice()
#
# 
###########################################################################


###########################################################################
# REPORT JA6_rpt_list_autobill (p_rpt_idx,rp_cmpy,rp_cmpy_name_text,	rp_contract_code,	rp_inv_num,	rp_invoice_date,rp_invoice_amt,	rp_error_text)
#
# 
###########################################################################
REPORT JA6_rpt_list_autobill (p_rpt_idx,rp_cmpy,rp_cmpy_name_text,	rp_contract_code,	rp_inv_num,	rp_invoice_date,rp_invoice_amt,	rp_error_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	rp_cmpy LIKE company.cmpy_code, 
	rp_cmpy_name_text LIKE company.name_text, 
	rp_contract_code LIKE contractdate.contract_code, 
	rp_inv_num LIKE contractdate.inv_num, 
	rp_invoice_date LIKE contractdate.invoice_date, 
	rp_invoice_amt LIKE contractdate.invoice_total_amt, 
	rp_error_text CHAR(50) 


	OUTPUT 


	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
		
			#PRINT COLUMN 1, time, 
			#COLUMN 50, "JM Tentative Invoice Exception Report" 

			PRINT COLUMN 1, "Contract", 
			COLUMN 15, "Invoice", 
			COLUMN 25, "Invoice", 
			COLUMN 35, "Invoice", 
			COLUMN 55, "Error" 

			PRINT COLUMN 1, "Code", 
			COLUMN 15, "Number", 
			COLUMN 25, "Date", 
			COLUMN 35, "Amount", 
			COLUMN 55, "Text" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			SKIP 1 line 

		ON EVERY ROW 

			IF pr_contractdate.inv_num IS NULL THEN 
				LET pr_contractdate.inv_num = 0 
			END IF 

			IF pr_contractdate.invoice_total_amt IS NULL THEN 
				LET pr_contractdate.invoice_total_amt = 0 
			END IF 

			PRINT COLUMN 1, pr_contractdate.contract_code, 
			COLUMN 15, pr_contractdate.inv_num USING "######", 
			COLUMN 25, pr_contractdate.invoice_date USING "dd/mm/yy", 
			COLUMN 35, pr_contractdate.invoice_total_amt USING "#######.##", 
			COLUMN 50, pv_error_text 

		ON LAST ROW 

			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
###########################################################################
# END # REPORT JA6_rpt_list_autobill (p_rpt_idx,rp_cmpy,rp_cmpy_name_text,	rp_contract_code,	rp_inv_num,	rp_invoice_date,rp_invoice_amt,	rp_error_text) 
###########################################################################