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

	Source code beautified by beautify.pl on 2019-12-31 14:28:30	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "K_SS_GLOBALS.4gl" 

GLOBALS "KL1_GLOBALS.4gl" 



MAIN 
	DEFINE msgresp LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("KL1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * INTO pr_ssparms.* FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("K",9114,"") 
		#9114 Subscription parameters NOT found
		SLEEP 2 
		EXIT program 
	END IF 
	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL create_table("invoicedetl","t_invoicedetl","","N") 
	CREATE temp TABLE t_label(cust_code CHAR(8), 
	ship_code CHAR(8), 
	name_text CHAR(40), 
	sub_num INTEGER, 
	sub_line_num INTEGER, 
	part_code CHAR(15), 
	ware_code CHAR(3), 
	pr_issue_qty FLOAT, 
	issue_num INTEGER, 
	rev_num integer) WITH no LOG 
	CREATE INDEX t_label_key ON t_label(sub_num) 
	CREATE INDEX t2_label_key ON t_label(part_code, 
	name_text, 
	cust_code, 
	ship_code, 
	issue_num) 
	CREATE temp TABLE pcode(state_code CHAR(1),post_code CHAR(4)) WITH no LOG 
	CREATE INDEX t_post_key ON pcode(state_code,post_code) 
	OPEN WINDOW k136 at 4,4 WITH FORM "K136" 
	attribute(border) 
	MENU " Subscription labels" 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Report" " Create Issue report" 
			LET pr_label_format = "R" 
			IF sub_criteria() THEN 
				CALL select_subs(1) 
			END IF 
			NEXT option "PRINT MANAGER" 
		COMMAND "Labels" " Create Labels & invoices" 
			IF label_format() THEN 
				IF sub_criteria() THEN 
					IF pr_label_format = "R" THEN 
						CALL select_subs(1) 
					ELSE 
					CALL select_subs(2) 
				END IF 
			END IF 
		END IF 
		NEXT option "PRINT MANAGER" 

		ON ACTION "PRINT MANAGER" 
			#COMMAND KEY ("P",f11) "Print" " Print Update/Issue Reports"
			CALL run_prog("URS","","","","") 

		COMMAND KEY("E",interrupt)"Exit" " RETURN TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END MAIN 


FUNCTION label_format() { allows user TO SELECT the LABEL format} 
	DEFINE msgresp LIKE language.yes_flag 
	LET pr_label_format = NULL 
	MENU "Label format" 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Printer" "Creates labels FOR printer" 
			LET pr_label_format = "P" 
			EXIT MENU 
		COMMAND "Data" "Creates data file FOR label production" 
			LET pr_label_format = "D" 
			EXIT MENU 
		COMMAND "Preview" "Create a REPORT of labels that would be generated" 
			LET pr_label_format = "R" 
			EXIT MENU 
		COMMAND "Exit" "Do NOT create labels" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	IF pr_label_format IS NULL THEN 
		RETURN false 
	ELSE 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION sub_criteria() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_substype RECORD LIKE substype.* 

	CLEAR FORM 
	LET pr_issue_date = today 
	LET pr_back_ind = "Y" 
	LET msgresp = kandoomsg("K","1001","") 
	###-1001 Enter search criteria ESC TO continue
	INPUT BY NAME pr_subhead.sub_type_code, 
	pr_issue_date, 
	pr_issue_num, 
	pr_back_ind, 
	pr_run_type WITHOUT DEFAULTS 

		ON KEY (control-b) 
			CASE 
				WHEN infield(sub_type_code) 
					LET pr_temp_text = show_substype(glob_rec_kandoouser.cmpy_code,"1=1") 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_subhead.sub_type_code = pr_temp_text clipped 
					END IF 
					NEXT FIELD sub_type_code 
			END CASE 
		AFTER FIELD sub_type_code 
			IF pr_subhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD sub_type_code 
			END IF 
			SELECT * INTO pr_substype.* FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subhead.sub_type_code 
			IF status = 0 THEN 
				DISPLAY pr_substype.desc_text TO sub_text 

			ELSE 
			LET msgresp = kandoomsg("U",9105,"") 
			NEXT FIELD sub_type_code 
		END IF 
		AFTER FIELD pr_issue_date 
			IF pr_issue_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD pr_issue_date 
			END IF 
		AFTER FIELD pr_run_type 
			IF pr_run_type IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD pr_run_type 
			END IF 
		AFTER FIELD pr_issue_num 
			IF pr_issue_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pr_issue_num 
			END IF 
			IF pr_issue_num <= 0 THEN 
				LET msgresp = kandoomsg("I",9085,"") 
				#9085 Must enter value greater than 0
				NEXT FIELD pr_issue_num 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
			IF pr_subhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD sub_type_code 
			END IF 
			SELECT * INTO pr_substype.* FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subhead.sub_type_code 
			IF status = 0 THEN 
				DISPLAY pr_substype.desc_text TO sub_text 

			ELSE 
			LET msgresp = kandoomsg("U",9105,"") 
			NEXT FIELD sub_type_code 
		END IF 
		IF pr_issue_date IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			NEXT FIELD issue_date 
		END IF 
		IF pr_issue_num <= 0 THEN 
			LET msgresp = kandoomsg("I",9085,"") 
			NEXT FIELD pr_issue_num 
		END IF 
		IF pr_run_type IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			NEXT FIELD pr_run_type 
		END IF 
	END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET pr_sub_type = pr_subhead.sub_type_code 
	IF pr_back_ind = "Y" THEN 
		LET where1_text = "issue_num <= ",pr_issue_num 
	ELSE 
	LET where1_text = "issue_num = ",pr_issue_num 
END IF 
CONSTRUCT BY NAME where2_text ON part_code, 
ware_code 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	AFTER CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END CONSTRUCT 
IF fgl_lastkey() = fgl_keyval("accept") THEN 
	LET where3_text = "1=1" 
	RETURN true 
END IF 
CONSTRUCT BY NAME where3_text ON customer.type_code, 
customer.state_code 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

END CONSTRUCT 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN false 
END IF 
RETURN true 
END FUNCTION 


FUNCTION select_subs(pr_mode)
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_substype RECORD LIKE substype.*, 
	pr_mode,label_cnt,sub_cnt SMALLINT, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_subissues RECORD LIKE subissues.*, 
	pr_rowid INTEGER, 
	pr_customership RECORD LIKE customership.*, 
	pr_name_text LIKE customership.name_text, 
	pr_label_1 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_2 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_3 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_issue_qty FLOAT, 
	pr_rep_date CHAR(6), 
	pr_form_date CHAR(8), 
	pr_output CHAR(40), 
	pr_output1 CHAR(40), 
	pr_output2 CHAR(40), 
	pr_sub_qty FLOAT, 
	f INTEGER, 
	pr_part_ind CHAR(1), 
	runner CHAR(50), 
	i,ret_code SMALLINT, 
	pr_dir CHAR(60) 

	LET rpt_date = today 
	LET rpt_time = time 
	DELETE FROM pcode WHERE 1=1 
	DELETE FROM t_label WHERE 1=1 
	LET print_feeder = true 
	SELECT * INTO pr_substype.* FROM substype 
	WHERE type_code = pr_sub_type 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF where3_text IS NULL THEN 
		LET where3_text = "1=1" 
	END IF 
	LET query_text = " SELECT subhead.* ", 
	" FROM subhead,customer", 
	" WHERE subhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subhead.sub_type_code = '",pr_sub_type,"' ", 
	" AND subhead.status_ind in ('U','P') ", 
	" AND subhead.start_date <= '",pr_issue_date,"' ", 
	" AND subhead.end_date >= '",pr_issue_date,"' ", 
	" AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subhead.cust_code = customer.cust_code ", 
	" AND ",where3_text clipped 
	PREPARE s_subhead FROM query_text 
	DECLARE c_subhead CURSOR WITH HOLD FOR s_subhead 
	IF where2_text IS NULL THEN 
		LET where2_text = "1=1" 
	END IF 
	LET query_text = " SELECT * FROM subdetl ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND sub_num = ?", 
	" AND status_ind <> '4' ", 
	" AND sub_qty > issue_qty ", 
	" AND ",where2_text clipped 
	PREPARE s_subdetl FROM query_text 
	DECLARE c_subdetl CURSOR FOR s_subdetl 
	LET query_text = " SELECT * FROM subschedule ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND sub_num = ? ", 
	" AND sub_line_num = ? ", 
	" AND sched_date <= '",pr_issue_date,"' ", 
	" AND sched_qty > issue_qty ", 
	" AND ",where1_text clipped 
	PREPARE s_subschedule FROM query_text 
	DECLARE c_subschedule CURSOR FOR s_subschedule 
	CASE 
		WHEN pr_substype.format_ind = "1" 
			LET pr_dir = pr_ssparms.format1_text 
			LET pr_desc = pr_ssparms.format1_desc 
			LET pr_line1 = pr_ssparms.f1_line1_text 
			LET pr_line2 = pr_ssparms.f1_line2_text 
		WHEN pr_substype.format_ind = "2" 
			LET pr_dir = pr_ssparms.format2_text 
			LET pr_desc = pr_ssparms.format2_desc 
			LET pr_line1 = pr_ssparms.f2_line1_text 
			LET pr_line2 = pr_ssparms.f2_line2_text 
		WHEN pr_substype.format_ind = "3" 
			LET pr_dir = pr_ssparms.format3_text 
			LET pr_desc = pr_ssparms.format3_desc 
			LET pr_line1 = pr_ssparms.f3_line1_text 
			LET pr_line2 = pr_ssparms.f3_line2_text 
		OTHERWISE 
			LET msgresp = kandoomsg("K",9115,"") 
			#9115 Invalid label FORMAT
			RETURN 
	END CASE 
	IF pr_label_format != "R" THEN 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("KL1-EXCEP","KL1_rpt_list_excep","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KL1_rpt_list_excep TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------



	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("KL1-INVOICE","KL1_rpt_list_invoice","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KL1_rpt_list_invoice TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


		LET pr_form_date = today USING 'dd/mm/yy' 
		LET pr_rep_date = pr_form_date[7,8],pr_form_date[4,5],pr_form_date[1,2] 

{
		LET pr_output = pr_dir clipped,"/",pr_rep_date clipped,".", 
		downshift(pr_run_type[1,3] clipped) 

		FOR f = 1 TO 20 
			LET runner = " [ -s ",pr_output clipped," ] " 
			RUN runner 
			RETURNING ret_code 
			IF ret_code THEN 
				EXIT FOR 
			END IF 
			IF f > 19 THEN 
				ERROR "Unable TO create unique file " 
				RETURN 
			END IF 
			LET pr_output = pr_dir clipped,"/",pr_rep_date clipped, 
			f USING "<<" clipped, 
			".", downshift(pr_run_type[1,3] clipped) 
		END FOR 
}
		LET label_cnt = 0 
		INITIALIZE pr_label_1.* TO NULL 
		INITIALIZE pr_label_2.* TO NULL 
		INITIALIZE pr_label_3.* TO NULL 
		IF pr_label_format = "P" THEN
		 
#			START REPORT KL1_rpt_list_sub_label TO pr_output

			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start("KL1-SUB-LABEL","KL1_rpt_list_sub_label","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	
			START REPORT KL1_rpt_list_sub_label TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------
			 
		ELSE 
#		START REPORT KL1_rpt_list_data_label TO pr_output
			#------------------------------------------------------------
			LET l_rpt_idx = rpt_start("KL1-DATA-LABEL","KL1_rpt_list_data_label","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	
			START REPORT KL1_rpt_list_data_label TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------ 
	END IF 
END IF { IF pr_label_format != "R" } 

OPEN WINDOW wkl1 at 10,15 WITH 2 ROWS, 50 COLUMNS 
attribute(border) 

DISPLAY "Customer: " at 1,3 
DISPLAY "Product : " at 2,3 
FOREACH c_subhead INTO pr_subhead.* 
	LET pr_sub_qty = 0 
	INITIALIZE pr_customership.* TO NULL 
	SELECT * INTO pr_customership.* FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subhead.cust_code 
	AND ship_code = pr_subhead.ship_code 
	IF pr_customership.name_text IS NULL THEN 
		SELECT name_text INTO pr_name_text FROM customer 
		WHERE cust_code = pr_subhead.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != notfound THEN 
			LET pr_customership.name_text = pr_name_text 
		END IF 
	END IF 
	DISPLAY pr_subhead.cust_code at 1,12 
	OPEN c_subdetl USING pr_subhead.sub_num 
	FOREACH c_subdetl INTO pr_subdetl.* 
		DISPLAY pr_subdetl.part_code at 2,12 
		SELECT * INTO pr_subproduct.* FROM subproduct 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_subdetl.part_code 
		AND type_code = pr_subhead.sub_type_code 
		AND linetype_ind = "1" 
		IF status = notfound THEN 
			CONTINUE FOREACH 
		END IF 
		OPEN c_subschedule USING pr_subhead.sub_num,pr_subdetl.sub_line_num 
		FOREACH c_subschedule INTO pr_subschedule.* 
			LET pr_issue_qty = pr_subschedule.sched_qty 
			- pr_subschedule.issue_qty 
			IF pr_issue_qty = 0 THEN 
				CONTINUE FOREACH 
			END IF 
			LET pr_sub_qty = pr_sub_qty + pr_issue_qty 
			INSERT INTO t_label VALUES (pr_subhead.cust_code, 
			pr_subhead.ship_code, 
			pr_customership.name_text, 
			pr_subhead.sub_num, 
			pr_subdetl.sub_line_num, 
			pr_subdetl.part_code, 
			pr_subdetl.ware_code, 
			pr_issue_qty, 
			pr_subschedule.issue_num, 
			pr_subhead.rev_num) 
			IF pr_label_format != "R" THEN 
				FOR sub_cnt = 1 TO pr_issue_qty 
					IF label_cnt = 3 THEN 
						IF pr_label_format = "P" THEN 
							OUTPUT TO REPORT KL1_rpt_list_sub_label(pr_back_ind,pr_label_1.*, 
							pr_label_2.*, pr_label_3.*) 
						ELSE 
						OUTPUT TO REPORT KL1_rpt_list_data_label(pr_back_ind,pr_label_1.*, 
						pr_label_2.*, pr_label_3.*) 
					END IF 
					INITIALIZE pr_label_1.* TO NULL 
					INITIALIZE pr_label_2.* TO NULL 
					INITIALIZE pr_label_3.* TO NULL 
					LET label_cnt = 0 
				END IF 
				LET label_cnt = label_cnt + 1 
				LET pr_pcode.state_code = pr_customership.post_code[1,1] 
				LET pr_pcode.post_code = pr_customership.post_code 
				USING "&###" 
				INSERT INTO pcode VALUES (pr_pcode.state_code, 
				pr_pcode.post_code) 
				CASE 
					WHEN label_cnt = 1 
						CALL format_label(pr_customership.*) 
						RETURNING pr_label_1.* 
					WHEN label_cnt = 2 
						CALL format_label(pr_customership.*) 
						RETURNING pr_label_2.* 
					WHEN label_cnt = 3 
						CALL format_label(pr_customership.*) 
						RETURNING pr_label_3.* 
				END CASE 
			END FOR 
		END IF {pr_label_format != "R" } 
	END FOREACH 
END FOREACH 
IF pr_sub_qty = 0 THEN 
	CONTINUE FOREACH 
END IF 
IF pr_mode = 2 THEN 
	IF update_issue() THEN 
	END IF 
END IF 
END FOREACH 
IF pr_label_format != "R" THEN 
IF pr_label_format = "P" THEN 
	OUTPUT TO REPORT KL1_rpt_list_sub_label(pr_back_ind,pr_label_1.*, 
	pr_label_2.*, pr_label_3.*) 
ELSE 
OUTPUT TO REPORT KL1_rpt_list_data_label(pr_back_ind,pr_label_1.*, 
pr_label_2.*, pr_label_3.*) 
END IF 
INITIALIZE pr_label_1.* TO NULL 
INITIALIZE pr_label_2.* TO NULL 
INITIALIZE pr_label_3.* TO NULL 
LET label_cnt = 0 
END IF 
IF pr_mode = 2 THEN 
IF where2_text[1] = "p" THEN 
LET pr_part_ind = "Y" 
END IF 
FOR i = 1 TO length(where2_text) 
IF where2_text[i,i+8] = "ware_code" THEN 
	IF pr_part_ind = "Y" THEN 
		LET where2_text = where2_text[1,i-5] 
	ELSE 
	LET where2_text = "1=1" 
END IF 
EXIT FOR 
END IF 
END FOR 
LET query_text = " SELECT rowid,* FROM subissues ", 
" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
" AND type_code = '",pr_sub_type,"' ", 
" AND start_date <= '",pr_issue_date,"' ", 
" AND end_date >= '",pr_issue_date,"' ", 
" AND plan_iss_date <= '",pr_issue_date,"' ", 
" AND ",where2_text clipped, 
" AND ",where1_text clipped 
PREPARE s_subissues FROM query_text 
DECLARE c_subissues CURSOR FOR s_subissues 
FOREACH c_subissues INTO pr_rowid,pr_subissues.* 
IF pr_subissues.act_iss_date IS NULL THEN 
LET pr_subissues.act_iss_date = pr_issue_date 
END IF 
IF pr_back_ind <> "Y" THEN 
LET pr_subissues.last_issue_num = pr_issue_num 
END IF 
UPDATE subissues 
SET act_iss_date = pr_subissues.act_iss_date, 
last_issue_num = pr_subissues.last_issue_num 
WHERE rowid = pr_rowid 
END FOREACH 
END IF 
IF pr_label_format != "R" THEN 
IF pr_label_format = "P" THEN 


	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_sub_label
	CALL rpt_finish("KL1_rpt_list_sub_label")
	#------------------------------------------------------------
ELSE 
	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_data_label
	CALL rpt_finish("KL1_rpt_list_data_label")
	#------------------------------------------------------------

END IF 

	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_excep
	CALL rpt_finish("KL1_rpt_list_excep")
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_invoice
	CALL rpt_finish("KL1_rpt_list_invoice")
	#------------------------------------------------------------

{PRINT post code REPORT}

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("KL1-PO-CODE","KL1_rpt_list_po_code","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KL1_rpt_list_po_code TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------



DECLARE p_curs CURSOR FOR 
SELECT state_code, post_code, count(*) FROM pcode 
GROUP BY 1,2 
ORDER BY 1,2 
	FOREACH p_curs INTO pr_pcode.*

		#--------------------------------------------------------- 
		OUTPUT TO REPORT KL1_rpt_list_po_code(l_rpt_idx,pr_pcode.*) 
		#---------------------------------------------------------
	END FOREACH
	

	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_po_code
	CALL rpt_finish("KL1_rpt_list_po_code")
	#------------------------------------------------------------	 
END IF 


{PRINT customer sub REPORT}
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("KL1-CUST","KL1_rpt_list_cust","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KL1_rpt_list_cust TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------


DECLARE q_curs CURSOR FOR 
SELECT * FROM t_label 
ORDER BY 6,3,1,2, 9 
FOREACH q_curs INTO pr_label.* 

	#------------------------------------------------------------

	OUTPUT TO REPORT KL1_rpt_list_cust(l_rpt_idx,pr_back_ind,pr_label.*) 
	#------------------------------------------------------------

END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT KL1_rpt_list_cust
	CALL rpt_finish("KL1_rpt_list_cust")
	#------------------------------------------------------------


CLOSE WINDOW wkl1 
END FUNCTION 


FUNCTION format_label(pr_customership) 
	DEFINE 
	pr_customership RECORD LIKE customership.*, 
	pr_label RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	a SMALLINT 

	LET pr_label.sort_key = pr_customership.post_code USING "&&&&" 
	IF pr_label.sort_key IS NULL 
	OR length(pr_label.sort_key) = 0 THEN 
		LET pr_label.sort_key = "0000" 
	END IF 
	LET pr_label.line1 = pr_line1 clipped 
	LET pr_label.line2 = pr_line2 clipped," ", 
	pr_customership.cust_code, " ", pr_run_type 
	LET pr_label.line3 = pr_customership.name_text 
	LET pr_label.line4 = pr_customership.addr_text 
	IF pr_customership.addr2_text IS NULL THEN 
		IF pr_customership.country_code IS NULL THEN --@db-patch_2020_10_04--
			LET pr_label.line5 = pr_customership.city_text clipped, " ", 
			pr_customership.state_code, " ", 
			pr_customership.post_code clipped 
		ELSE 
		LET pr_label.line5 = pr_customership.city_text clipped, " ", 
		pr_customership.state_code 
		LET pr_label.line6 = pr_customership.country_code clipped, " ", --@db-patch_2020_10_04--
		pr_customership.post_code clipped 
	END IF 
ELSE 
LET pr_label.line5 = pr_customership.addr2_text 
IF pr_customership.country_code IS NULL THEN --@db-patch_2020_10_04--
	LET pr_label.line6 = pr_customership.city_text clipped, " ", 
	pr_customership.state_code, " ", 
	pr_customership.post_code clipped 
ELSE 
LET pr_label.line6 = pr_customership.city_text clipped, " ", 
pr_customership.state_code 
LET pr_label.line7 = pr_customership.country_code clipped, " ", --@db-patch_2020_10_04--
pr_customership.post_code clipped 
END IF 
END IF 
{replace " with ' AND , with space}
FOR a = 1 TO length(pr_label.line1) 
IF pr_label.line1[a] = "\"" THEN 
LET pr_label.line1[a] = "'" 
END IF 
IF pr_label.line1[a] = "," THEN 
LET pr_label.line1[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line2) 
IF pr_label.line2[a] = "\"" THEN 
LET pr_label.line2[a] = "'" 
END IF 
IF pr_label.line2[a] = "," THEN 
LET pr_label.line2[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line3) 
IF pr_label.line3[a] = "\"" THEN 
LET pr_label.line3[a] = "'" 
END IF 
IF pr_label.line3[a] = "," THEN 
LET pr_label.line3[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line4) 
IF pr_label.line4[a] = "\"" THEN 
LET pr_label.line4[a] = "'" 
END IF 
IF pr_label.line4[a] = "," THEN 
LET pr_label.line4[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line5) 
IF pr_label.line5[a] = "\"" THEN 
LET pr_label.line5[a] = "'" 
END IF 
IF pr_label.line5[a] = "," THEN 
LET pr_label.line5[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line6) 
IF pr_label.line6[a] = "\"" THEN 
LET pr_label.line6[a] = "'" 
END IF 
IF pr_label.line6[a] = "," THEN 
LET pr_label.line6[a] = " " 
END IF 
END FOR 
FOR a = 1 TO length(pr_label.line7) 
IF pr_label.line7[a] = "\"" THEN 
LET pr_label.line7[a] = "'" 
END IF 
IF pr_label.line7[a] = "," THEN 
LET pr_label.line7[a] = " " 
END IF 
END FOR 
IF length(pr_label.line7) > 0 THEN 
RETURN pr_label.* 
ELSE 
LET pr_label.line7 = pr_label.line6 
LET pr_label.line6 = pr_label.line5 
LET pr_label.line5 = pr_label.line4 
LET pr_label.line4 = pr_label.line3 
LET pr_label.line3 = pr_label.line2 
LET pr_label.line2 = " " 
RETURN pr_label.* 
END IF 
END FUNCTION 


REPORT KL1_rpt_list_sub_label(p_rpt_idx,pr_back_ind,pr_label_1, pr_label_2, pr_label_3) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_back_ind CHAR(1), 
	pr_label_1 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_2 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_3 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	i SMALLINT 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 7 
	FORMAT 
		ON EVERY ROW 
			IF print_feeder THEN 
				FOR i = 1 TO 3 
					PRINT COLUMN 1, "1", 
					COLUMN 2, "******************************************* ", 
					"******************************************* ", 
					"******************************************* ", 
					ascii(13) 
					PRINT COLUMN 1, " ", 
					COLUMN 2, "* * ", 
					"* * ", 
					"* * ", 
					ascii(13) 
					PRINT COLUMN 1, " ", 
					COLUMN 2, "* * ", 
					"* * ", 
					"* * ", 
					ascii(13) 
					IF pr_back_ind = "Y" THEN 
						PRINT COLUMN 1, " ", 
						COLUMN 2, "* ",pr_desc clipped, 
						" ", pr_run_type clipped, " USER LABELS ", 
						COLUMN 44, "*", 
						COLUMN 46, " ", 
						COLUMN 47, "* ",pr_desc clipped, 
						" ",pr_run_type clipped, " USER LABELS ", 
						COLUMN 89, "*", 
						COLUMN 91, " ", 
						COLUMN 92, "* ",pr_desc clipped, 
						" ",pr_run_type clipped, " USER LABELS ", 
						COLUMN 134, "* ", 
						ascii(13) 
					ELSE 
					PRINT COLUMN 1, " ", 
					COLUMN 2, "* ",pr_desc clipped, 
					" ",pr_run_type clipped, " UPDATE USER LABELS ", 
					COLUMN 44, "*", 
					COLUMN 46, " ", 
					COLUMN 47, "* ",pr_desc clipped, 
					" ",pr_run_type clipped, " UPDATE USER LABELS ", 
					COLUMN 89, "*", 
					COLUMN 91, " ", 
					COLUMN 92, "* ",pr_desc clipped, 
					" ",pr_run_type clipped, " UPDATE USER LABELS ", 
					COLUMN 134, "* ", 
					ascii(13) 
				END IF 
				PRINT COLUMN 1, " ", 
				COLUMN 2, "* * ", 
				"* * ", 
				"* * ", 
				ascii(13) 
				PRINT COLUMN 1, " ", 
				COLUMN 2, "* * ", 
				"* * ", 
				"* * ", 
				ascii(13) 
				PRINT COLUMN 1, " ", 
				COLUMN 2, "* ", today USING "DD/MM/YY", " ",time, 
				COLUMN 44, "*", 
				COLUMN 46, " ", 
				COLUMN 47, "* ", today USING "DD/MM/YY", " ",time, 
				COLUMN 89, "*", 
				COLUMN 91, " ", 
				COLUMN 92, "* ", today USING "DD/MM/YY", " ",time, 
				COLUMN 134, "* ", 
				ascii(13) 
				PRINT COLUMN 1, " ", 
				COLUMN 2, "******************************************* ", 
				"******************************************* ", 
				"******************************************* ", 
				ascii(13) 
			END FOR 
			LET print_feeder = false 
		END IF 
		{PRINT labels 3 across }
		PRINT COLUMN 1, "1", 
		COLUMN 2, pr_label_1.line1, 
		COLUMN 47, pr_label_2.line1, 
		COLUMN 92, pr_label_3.line1, 
		ascii(13) 
		PRINT COLUMN 1, " ", 
		COLUMN 2, pr_label_1.line2, 
		COLUMN 47, pr_label_2.line2, 
		COLUMN 92, pr_label_3.line2, 
		ascii(13) 
		PRINT COLUMN 1, " ", 
		COLUMN 2, pr_label_1.line3, 
		COLUMN 47, pr_label_2.line3, 
		COLUMN 92, pr_label_3.line3, 
		ascii(13) 
		PRINT COLUMN 1, " ", 
		COLUMN 2, pr_label_1.line4, 
		COLUMN 47, pr_label_2.line4, 
		COLUMN 92, pr_label_3.line4, 
		ascii(13) 
		PRINT COLUMN 1, " ", 
		COLUMN 2, pr_label_1.line5, 
		COLUMN 47, pr_label_2.line5, 
		COLUMN 92, pr_label_3.line5, 
		ascii(13) 
		PRINT COLUMN 1, " ", 
		COLUMN 2, pr_label_1.line6, 
		COLUMN 47, pr_label_2.line6, 
		COLUMN 92, pr_label_3.line6, 
		ascii(13) 
		PRINT COLUMN 1, "0", 
		COLUMN 2, pr_label_1.line7, 
		COLUMN 47, pr_label_2.line7, 
		COLUMN 92, pr_label_3.line7, 
		ascii(13) 
END REPORT 


REPORT KL1_rpt_list_data_label(p_rpt_idx,pr_back_ind,pr_label_1, pr_label_2, pr_label_3) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_back_ind CHAR(1), 
	pr_label_1 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_2 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	pr_label_3 RECORD 
		sort_key CHAR(4), 
		line1 CHAR(45), 
		line2 CHAR(45), 
		line3 CHAR(45), 
		line4 CHAR(45), 
		line5 CHAR(45), 
		line6 CHAR(45), 
		line7 CHAR(45) 
	END RECORD, 
	i SMALLINT, 
	line CHAR(45) 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 1 
	FORMAT 
		ON EVERY ROW 
			IF print_feeder THEN 
				FOR i = 1 TO 3 
					PRINT "\""; 
					PRINT "++++"; 
					PRINT "\",\""; 
					PRINT "******************************************* \",\""; 
					PRINT "* * \",\""; 
					PRINT "* * \",\""; 
					IF pr_back_ind = "Y" THEN 
						LET line = "* ",pr_desc clipped, 
						" ",pr_run_type clipped, " USER LABELS " 
						PRINT line[1,42], "* \",\""; 
					ELSE 
					LET line = "* ",pr_desc clipped, 
					" ",pr_run_type clipped, " UPDATE USER LABELS " 
					PRINT line[1,42], "* \",\""; 
				END IF 
				PRINT "* * \",\""; 
				LET line = "* ", today USING "DD/MM/YY", " ",time 
				PRINT line[1,42], "* \",\""; 
				PRINT "******************************************* \"", ascii(13) 
			END FOR 
			LET print_feeder = false 
		END IF 
		{PRINT 3 labels }
		IF pr_label_1.sort_key IS NOT NULL THEN 
			PRINT "\"", pr_label_1.sort_key; 
			PRINT "\",\""; 
			PRINT pr_label_1.line1 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line2 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line3 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line4 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line5 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line6 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_1.line7 clipped; 
			PRINT "\""; 
			PRINT ascii(13) 
		END IF 
		IF pr_label_2.sort_key IS NOT NULL THEN 
			PRINT "\"", pr_label_2.sort_key; 
			PRINT "\",\""; 
			PRINT pr_label_2.line1 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line2 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line3 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line4 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line5 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line6 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_2.line7 clipped; 
			PRINT "\""; 
			PRINT ascii(13) 
		END IF 
		IF pr_label_3.sort_key IS NOT NULL THEN 
			PRINT "\"", pr_label_3.sort_key; 
			PRINT "\",\""; 
			PRINT pr_label_3.line1 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line2 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line3 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line4 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line5 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line6 clipped; 
			PRINT "\",\""; 
			PRINT pr_label_3.line7 clipped; 
			PRINT "\""; 
			PRINT ascii(13) 
		END IF 
END REPORT 


REPORT KL1_rpt_list_po_code(p_rpt_idx,pr_pcode) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_pcode RECORD 
		state_code CHAR(1), 
		post_code CHAR(4), 
		rec_cnt INTEGER 
	END RECORD, 
	rpt_note, line1, line2 CHAR(132), 
	offset1, offset2 SMALLINT 

	OUTPUT 
	left margin 1 
	ORDER external BY pr_pcode.state_code, 
	pr_pcode.post_code 
	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = " Mailing Label Post Code List - ", pr_run_type clipped 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 
			PRINT COLUMN 1, rpt_date , 
			COLUMN offset1, line1 clipped, 
			COLUMN 50, "Page:", pageno USING "####" 
			PRINT COLUMN 1,rpt_time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "------------------------------", 
			"------------------------------" 
			SKIP 1 LINES 
		AFTER GROUP OF pr_pcode.state_code 
			SKIP 1 line 
			PRINT COLUMN 30, "----------" 
			PRINT COLUMN 20, "State: ", pr_pcode.state_code, 
			COLUMN 30, GROUP sum(pr_pcode.rec_cnt) USING "##########" 
			SKIP 2 LINES 
		ON EVERY ROW 
			PRINT COLUMN 20, pr_pcode.post_code USING "####", 
			COLUMN 30, pr_pcode.rec_cnt USING "##########" 
		ON LAST ROW 
			LET rpt_pageno = pageno 
			SKIP 2 LINES 
			PRINT COLUMN 10, "Report total:", 
			COLUMN 30, sum(pr_pcode.rec_cnt) USING "##########" 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KL1 *****" 
END REPORT 


REPORT KL1_rpt_list_cust(p_rpt_idx,pr_lab_type,pr_label) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_lab_type CHAR(1), 
	pr_label RECORD 
		cust_code CHAR(8), 
		ship_code CHAR(8), 
		name_text CHAR(40), 
		sub_num INTEGER, 
		sub_line_num INTEGER, 
		part_code CHAR(15), 
		ware_code CHAR(3), 
		pr_issue_qty FLOAT, 
		issue_num INTEGER, 
		rev_num INTEGER 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(132), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	--left margin 0 
	ORDER external BY pr_label.part_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 		

			CASE 
				WHEN (pr_lab_type = "Y") 
					LET rpt_note = " New Subscribers Listing (Menu - kl1)" 
				WHEN (pr_lab_type = "N") 
					LET rpt_note = "Issue ", pr_issue_num USING "#&", 
					" Update Listing (Menu - kl1)" 
				OTHERWISE 
					LET rpt_note = " Customer Label Listing (Menu - kl1)" 
			END CASE 

			IF pr_label_format = "R" THEN 
				LET rpt_note = rpt_note clipped , " - Preview " 
			END IF 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 		

			PRINT COLUMN 1, "Customer", 
			COLUMN 12, "Name", 
			COLUMN 50, "Shipping", 
			COLUMN 60, "Subs", 
			COLUMN 70, "Issue" 
			PRINT COLUMN 3, "Code", 
			COLUMN 52, "Code", 
			COLUMN 60, "Quantity", 
			COLUMN 70, "Number" 
			PRINT COLUMN 1, "--------------------------------------------------", 
			"------------------------------" 
		BEFORE GROUP OF pr_label.part_code 
			SKIP TO top OF PAGE 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_label.part_code 
			PRINT COLUMN 1, "Product:" , pr_label.part_code, 
			COLUMN 25, pr_product.desc_text 
			PRINT COLUMN 25, pr_product.desc2_text 
			SKIP 1 LINES 
		ON EVERY ROW 
			PRINT COLUMN 1, pr_label.cust_code, 
			COLUMN 12, pr_label.name_text clipped, 
			COLUMN 50, pr_label.ship_code, 
			COLUMN 60, pr_label.pr_issue_qty USING "####&", 
			COLUMN 70, pr_label.issue_num USING "####&" 
		AFTER GROUP OF pr_label.part_code 
			SKIP 1 LINES 
			PRINT COLUMN 20, " Total ", pr_label.part_code clipped, " labels:", 
			COLUMN 58, GROUP sum(pr_label.pr_issue_qty) USING "######&" 
		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 40, "-------------------------------------------" 
			PRINT COLUMN 20, " Total labels:", 
			COLUMN 58, sum(pr_label.pr_issue_qty) USING "######&" 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 

