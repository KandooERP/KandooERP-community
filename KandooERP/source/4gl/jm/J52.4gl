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

	Source code beautified by beautify.pl on 2020-01-02 19:48:09	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J5_GLOBALS.4gl" 


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J52.4gl    Inquire on an activity

DEFINE 
pr_menunames RECORD LIKE menunames.*, 
exist SMALLINT 

MAIN 
	#Initial UI Init
	CALL setModuleId("J52") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7002,0) 
		#ERROR " Must SET up JM Parameters first in JZP"
		#sleep 5
		EXIT program 
	END IF 
	OPEN WINDOW j160 with FORM "J160" -- alch kd-747 
	CALL winDecoration_j("J160") -- alch kd-747 
	IF num_args() > 0 THEN 
		WHILE select_activity() 
			CALL display_activity() 
			CALL query() 
		END WHILE 
	ELSE 
		CALL query() 
	END IF 
	CLOSE WINDOW j160 
END MAIN 


FUNCTION select_activity() 
	DEFINE 
	where_text1, 
	query_text CHAR(1200) 

	WHILE true 
		IF num_args() > 0 THEN 
			LET where_text1 = arg_val(1) 
		ELSE 
			CLEAR FORM 
			LET msgresp = kandoomsg("U",1001,"") 
			#1001 Enter Selection Criteria;  OK TO Continue.
			CONSTRUCT where_text1 ON 
			activity.job_code, 
			job.title_text, 
			activity.var_code, 
			activity.activity_code, 
			activity.title_text, 
			customer.cust_code, 
			customer.name_text, 
			activity.est_start_date, 
			activity.est_end_date, 
			activity.act_start_date, 
			activity.act_end_date, 
			activity.sort_text, 
			activity.locked_ind, 
			activity.priority_ind, 
			activity.finish_flag, 
			activity.unit_code, 
			activity.resp_code, 
			activity.report_text, 
			activity.retain_per, 
			activity.retain_amt 
			FROM 
			activity.job_code, 
			job.title_text, 
			activity.var_code, 
			activity.activity_code, 
			activity.title_text, 
			customer.cust_code, 
			customer.name_text, 
			activity.est_start_date, 
			activity.est_end_date, 
			activity.act_start_date, 
			activity.act_end_date, 
			activity.sort_text, 
			activity.locked_ind, 
			activity.priority_ind, 
			activity.finish_flag, 
			activity.unit_code, 
			activity.resp_code, 
			activity.report_text, 
			activity.retain_per, 
			activity.retain_amt 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","J52","const-activity_job_code-2") -- alch kd-506 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		LET query_text = 
		"SELECT job.*,", 
		"customer.*,", 
		"activity.* ", 
		"FROM job,", 
		"activity,", 
		"customer ", 
		"WHERE ",where_text1 clipped," ", 
		"AND activity.job_code = job.job_code ", 
		"AND job.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND customer.cust_code = job.cust_code ", 
		"AND customer.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND activity.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND (job.acct_code matches \"",pr_user_scan_code,"\" ", 
		"OR job.locked_ind <= \"1\")" 
		PREPARE q_1 FROM query_text 
		DECLARE q_2 SCROLL CURSOR FOR q_1 
		OPEN q_2 
		FETCH q_2 INTO pr_job.*, 
		pr_customer.*, 
		pr_activity.* 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("J",9646,0) 
			#ERROR " No Activities Selected - Re SELECT"
			LET exist = false 
		ELSE 
			LET exist = true 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN true 
END FUNCTION 


FUNCTION query() 
	DEFINE 
	pr_menunames RECORD LIKE menunames.* 

	LET exist = false 
	MENU " Activity" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J52","menu-act-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Search FOR activities " 
			IF num_args() = 0 THEN 
				IF select_activity() THEN 
					CALL display_activity() 
					#ELSE
					#EXIT MENU
				END IF 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected activity" 
			IF NOT exist THEN # the code that checks FOR an existing 
				NEXT option "Query"# selection IS only here until inquiry 
			ELSE # programs GO straight TO query option 
				FETCH NEXT q_2 INTO pr_job.*, 
				pr_customer.*, 
				pr_activity.* 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9006,0) 
					#error"This IS the Last of the Activities Selected"
				ELSE 
					CALL display_activity() 
				END IF 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected activity" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH previous q_2 INTO pr_job.*, 
				pr_customer.*, 
				pr_activity.* 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9007,0) 
					#ERROR " This IS the First of the Activities Selected"
				ELSE 
					CALL display_activity() 
				END IF 
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View activity details" 
			CALL act_inquiry() 
			LET int_flag = false 
			LET quit_flag = false 
			NEXT option "Next" 
		COMMAND KEY ("F",f18) "First" " DISPLAY first activity in the selected list" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH FIRST q_2 INTO pr_job.*, 
				pr_customer.*, 
				pr_activity.* 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9008,0) 
					#ERROR " This IS the First of the Activities Selected"
				ELSE 
					CALL display_activity() 
					NEXT option "Next" 
				END IF 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last activity in the selected list" 
			IF NOT exist THEN 
				NEXT option "Query" 
			ELSE 
				FETCH LAST q_2 INTO pr_job.*, 
				pr_customer.*, 
				pr_activity.* 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9009,0) 
					#error"This IS the Last of the Activities Selected"
					NEXT option "Previous" 
				ELSE 
					CALL display_activity() 
				END IF 
			END IF 
		COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
			LET quit_flag = true 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_activity() 
	DEFINE 
	cnt SMALLINT 

	DECLARE c_2 CURSOR FOR 
	SELECT act_desc.* 
	FROM act_desc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_activity.job_code 
	AND activity_code = pr_activity.activity_code 
	ORDER BY seq_num 
	LET act_desc_cnt = 0 
	FOREACH c_2 INTO pr_act_desc.* 
		LET act_desc_cnt = act_desc_cnt + 1 
		LET pa_act_desc[act_desc_cnt] = pr_act_desc.desc_text 
	END FOREACH 
	FOR cnt = (act_desc_cnt + 1) TO 100 
		INITIALIZE pa_act_desc[cnt] TO NULL 
	END FOR 
	CALL display_details() 
END FUNCTION 

FUNCTION act_inquiry() 
	DEFINE 
	pr_menunames RECORD LIKE menunames.* 

	MENU " Activity Inquiry" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J52","menu-act_inquiry-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Financials" " Activity Financials" 
			CALL disp_act_fin() 
		COMMAND "Ledger" " Activity Ledger" 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
			MENU " Ledger Inquiry" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","J52","menu-ledger_inquiry-1") -- alch kd-506 
				COMMAND "Cost" " Cost transactions " 
					CALL ledger_inq("C") 
				COMMAND "Sales" " Sales transactions " 
					CALL ledger_inq("S") 
				COMMAND KEY (interrupt,"E") "Exit" " Exit FROM ledger inquiry" 
					EXIT MENU 
				COMMAND KEY (control-w) 
					CALL kandoohelp("") 
			END MENU 
			LET int_flag = false 
			LET quit_flag = false 
		COMMAND "Description" " DISPLAY detailed activity description " 
			CALL disp_act_desc() 
		COMMAND KEY (interrupt, "E") "Exit" " Exit FROM activity inquiry" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 



FUNCTION ledger() 
	DEFINE 
	pr_menunames RECORD LIKE menunames.* 

	MENU " Ledger Inquiry" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J52","menu-ledger_inquiry-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Cost" " Cost transactions" 
			CALL ledger_inq("C") 
		COMMAND "Sales" " Sales transactions" 
			CALL ledger_inq("S") 
		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION # ledger 



FUNCTION ledger_inq(inq_ind) 
	DEFINE 
	runner CHAR(100), 
	inq_ind CHAR(1) 
	IF inq_ind = "C" THEN 
		CALL run_prog("J18", 
		pr_activity.job_code, 
		pr_activity.activity_code, 
		pr_activity.var_code,"") 
	ELSE 
		CALL run_prog("J37", 
		pr_activity.job_code, 
		pr_activity.activity_code, 
		pr_activity.var_code,"") 
	END IF 
END FUNCTION 


FUNCTION disp_act_desc() 
	OPEN WINDOW j109 with FORM "J109" -- alch kd-747 
	CALL winDecoration_j("J109") -- alch kd-747 
	DISPLAY BY NAME 
	pr_activity.job_code, 
	pr_job.title_text, 
	pr_activity.activity_code, 
	pr_activity.var_code, 
	pr_activity.title_text 

	CALL set_count(act_desc_cnt) 

	DISPLAY ARRAY pa_act_desc TO sr_act_desc.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J52","display-arr-act_desc") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 

	CLOSE WINDOW j109 
END FUNCTION 


FUNCTION disp_act_fin() 
	OPEN WINDOW j105 with FORM "J105" -- alch kd-747 
	CALL winDecoration_j("J105") -- alch kd-747 
	CALL display_financials() 
	CALL eventsuspend()#let msgresp = kandoomsg("U",1,"") 
	#2 Any Key TO Continue.
	CLOSE WINDOW j105 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
