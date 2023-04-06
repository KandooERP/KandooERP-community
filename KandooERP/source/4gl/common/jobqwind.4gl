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

	Source code beautified by beautify.pl on 2020-01-02 10:35:16	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - jobqwind.4gl
#
# Purpose - Job Inquiry with following OPTIONS
#           1. General Details
#           2. Profitability
#           3. Detailed Description
#           4. Activities
#           5. Job Ledger
#           6. Financial
#
#
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
--	glob_rec_company RECORD LIKE company.*, 
	glob_rec_customer RECORD LIKE customer.*, 
	glob_rec_jobvars RECORD LIKE jobvars.*, 
	glob_rec_job RECORD LIKE job.* 
END GLOBALS 

FUNCTION job_detail_inquiry(p_cmpy,p_job_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_job_code LIKE invoicehead.job_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_arr_jobmenu ARRAY[20] OF RECORD 
				scroll_flag CHAR(1), 
				option_num CHAR(1), 
				option_text CHAR(30) 
			 END RECORD 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 
	DEFINE l_runner CHAR(60) 
	DEFINE l_idx  SMALLINT
	DEFINE l_scrn SMALLINT 
	DEFINE i  SMALLINT

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 
	SELECT * INTO l_rec_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("G",5010,"") 
		#9107 JM Parameters NOT SET up - Refer menu JZP
		RETURN 
	END IF 
	OPEN WINDOW j136 with FORM "J136" 
	CALL windecoration_j("J136") -- albo kd-767 

	SELECT * INTO glob_rec_job.* 
	FROM job 
	WHERE cmpy_code = p_cmpy 
	AND job_code = p_job_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",7048,p_job_code) 
		#7048 Logic Error: Invoice does NOT exist
		RETURN 
	ELSE 
		CALL db_customer_get_rec(UI_OFF,glob_rec_job.cust_code) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* 
--		FROM customer 
--		WHERE cmpy_code = p_cmpy 
--		AND cust_code =  

		FOR i = 1 TO 9 
			CASE i 
				WHEN "1" ## general details 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "1" 
					LET l_arr_jobmenu[l_idx].option_text = "General Details" 
				WHEN "2" ## profitability 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "2" 
					LET l_arr_jobmenu[l_idx].option_text = "Profitability" 
				WHEN "3" ## detailed description 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "3" 
					LET l_arr_jobmenu[l_idx].option_text = "Detailed Description" 
				WHEN "4" ## activities 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "4" 
					LET l_arr_jobmenu[l_idx].option_text = "Activities" 
				WHEN "5" ## job ledger 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "5" 
					LET l_arr_jobmenu[l_idx].option_text = "Job Ledger" 
				WHEN "6" ## financial 
					LET l_idx = l_idx + 1 
					LET l_arr_jobmenu[l_idx].option_num = "6" 
					LET l_arr_jobmenu[l_idx].option_text = "Financial" 
			END CASE 
		END FOR 
		DISPLAY BY NAME glob_rec_job.job_code, 
		glob_rec_job.title_text 

		CALL set_count(l_idx) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET l_msgresp=kandoomsg("A",1030,"") 
		#A1030 RETURN TO SELECT Option
		INPUT ARRAY l_arr_jobmenu WITHOUT DEFAULTS FROM sr_jobmenu.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobqwind","input-arr-jobmenu") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				DISPLAY l_arr_jobmenu[l_idx].* 
				TO sr_jobmenu[l_scrn].* 

			AFTER FIELD scroll_flag 
				--#IF fgl_lastkey() = fgl_keyval("accept")
				--#AND fgl_fglgui() THEN
				--#NEXT FIELD option_num
				--#END IF
				IF l_arr_jobmenu[l_idx].scroll_flag IS NULL THEN 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() = arr_count() THEN 
						LET l_msgresp=kandoomsg("A",9001,"") 
						#A9001 No more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			BEFORE FIELD option_num 
				IF l_arr_jobmenu[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_jobmenu[l_idx].scroll_flag = l_arr_jobmenu[l_idx].option_num 
				ELSE 
					LET i = 1 
					WHILE (l_arr_jobmenu[l_idx].scroll_flag IS NOT null) 
						IF l_arr_jobmenu[i].option_num IS NULL THEN 
							LET l_arr_jobmenu[l_idx].scroll_flag = NULL 
						ELSE 
							IF l_arr_jobmenu[l_idx].scroll_flag= 
							l_arr_jobmenu[i].option_num THEN 
								EXIT WHILE 
							END IF 
						END IF 
						LET i = i + 1 
					END WHILE 
				END IF 
				CASE l_arr_jobmenu[l_idx].scroll_flag 
					WHEN "1" 
						IF getmoduleid() = "J12" THEN 
							CURRENT WINDOW IS j131 
							LET l_msgresp = kandoomsg("U",2,"") 
							CURRENT WINDOW IS j136 
						ELSE 
							CALL run_prog("J12",glob_rec_job.job_code,"","","") 
						END IF 
					WHEN "2" 
						CALL job_profitability() 
					WHEN "3" 
						CALL disp_job_desc() 
					WHEN "4" 
						CALL scan_vars() 
					WHEN "5" 
						LET l_runner = " jobledger.job_code = '", 
						glob_rec_job.job_code CLIPPED, "'" 
						CALL run_prog("J15",l_runner,"","","") 
					WHEN "6" 
						CALL display_fin() 
				END CASE 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				LET l_arr_jobmenu[l_idx].scroll_flag = NULL 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY l_arr_jobmenu[l_idx].* 
				TO sr_jobmenu[l_scrn].* 


		END INPUT 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j136 
END FUNCTION 

FUNCTION display_fin() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	OPEN WINDOW j103 with FORM "J103" 
	CALL windecoration_j("J103") -- albo kd-767 

	DISPLAY BY NAME 
	glob_rec_job.bill_way_ind, 
	glob_rec_job.bill_when_ind, 
	glob_rec_job.bill_issue_ind 

	CASE (glob_rec_job.bill_way_ind) 
		WHEN "C" 
			DISPLAY "Cost Plus", 
			glob_rec_job.markup_per 
			TO bill_way_text, 
			markup_per 

		WHEN "F" 
			DISPLAY "Fixed Cost " 
			TO bill_way_text 

		WHEN "T" 
			DISPLAY "Time & Materials" 
			TO bill_way_text 

		WHEN "R" 
			DISPLAY "Recurring" 
			TO bill_way_text 

	END CASE 
	CASE (glob_rec_job.bill_when_ind) 
		WHEN "1" 
			DISPLAY "Daily" 
			TO bill_when_text 

	END CASE 
	CASE (glob_rec_job.bill_issue_ind) 
		WHEN "1" 
			DISPLAY "Summary" 
			TO bill_issue_text 

		WHEN "2" 
			DISPLAY "Detailed" 
			TO bill_issue_text 

	END CASE 
	DISPLAY BY NAME 
	glob_rec_job.acct_code, 
	glob_rec_job.wip_acct_code, 
	glob_rec_job.cos_acct_code 

	SELECT coa.* 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_company.cmpy_code 
	AND coa.acct_code = glob_rec_job.acct_code 
	IF status != notfound THEN 
		DISPLAY l_rec_coa.desc_text TO coa.desc_text 

	END IF 
	SELECT coa.* 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_company.cmpy_code 
	AND coa.acct_code = glob_rec_job.wip_acct_code 
	IF status != notfound THEN 
		DISPLAY l_rec_coa.desc_text TO wip_desc_text 

	END IF 
	SELECT coa.* 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_company.cmpy_code 
	AND coa.acct_code = glob_rec_job.cos_acct_code 
	IF status != notfound THEN 
		DISPLAY l_rec_coa.desc_text TO cos_desc_text 

	END IF 
	LET l_msgresp = kandoomsg("U",2,"") 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j103 
END FUNCTION 


FUNCTION job_profitability() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_est_cost_amt LIKE activity.est_cost_amt 
	DEFINE l_est_bill_amt LIKE activity.est_bill_amt 
	DEFINE l_bdgt_bill_amt LIKE activity.bdgt_bill_amt 
	DEFINE l_bdgt_cost_amt LIKE activity.bdgt_cost_amt 
	DEFINE l_act_bill_amt LIKE activity.act_bill_amt 
	DEFINE l_act_cost_amt LIKE activity.act_cost_amt 
	DEFINE l_job_code LIKE activity.job_code 
	DEFINE l_est_profit DECIMAL(16,2) 
	DEFINE l_bdgt_profit DECIMAL(16,2) 
	DEFINE l_act_profit DECIMAL(16,2) 

	OPEN WINDOW j306 with FORM "J306" 
	CALL windecoration_j("J306") -- albo kd-767 

	SELECT job_code, 
	SUM(est_bill_amt), 
	SUM(bdgt_bill_amt), 
	SUM(act_bill_amt), 
	SUM(est_cost_amt), 
	SUM(bdgt_cost_amt), 
	SUM(act_cost_amt) 
	INTO l_job_code, 
	l_est_bill_amt, 
	l_bdgt_bill_amt, 
	l_act_bill_amt, 
	l_est_cost_amt, 
	l_bdgt_cost_amt, 
	l_act_cost_amt 
	FROM activity 
	WHERE cmpy_code = glob_rec_company.cmpy_code 
	AND job_code = glob_rec_job.job_code 
	GROUP BY job_code 

	LET l_est_profit = l_est_bill_amt - l_est_cost_amt 
	LET l_bdgt_profit = l_bdgt_bill_amt - l_bdgt_cost_amt 
	LET l_act_profit = l_act_bill_amt - l_act_cost_amt 


	DISPLAY glob_rec_job.job_code, 
	glob_rec_job.title_text, 
	l_est_bill_amt, 
	l_bdgt_bill_amt, 
	l_act_bill_amt, 
	l_est_cost_amt, 
	l_bdgt_cost_amt, 
	l_act_cost_amt, 
	l_est_profit, 
	l_bdgt_profit, 
	l_act_profit 
	TO job_code, 
	title_text, 
	est_bill_amt, 
	bdgt_bill_amt, 
	act_bill_amt, 
	est_cost_amt, 
	bdgt_cost_amt, 
	act_cost_amt, 
	est_profit, 
	bdgt_profit, 
	act_profit 


	LET l_msgresp = kandoomsg("U",2,"") 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j306 
END FUNCTION 


FUNCTION disp_job_desc() 
	DEFINE l_rec_job_desc RECORD LIKE job_desc.* 
	DEFINE l_arr_job_desc ARRAY[100] OF LIKE job_desc.desc_text 
	DEFINE l_cnt SMALLINT

	DECLARE c_2 CURSOR FOR 
	SELECT * FROM job_desc 
	WHERE cmpy_code = glob_rec_company.cmpy_code 
	AND job_code = glob_rec_job.job_code 
	ORDER BY seq_num 
	LET l_cnt = 0 
	FOREACH c_2 INTO l_rec_job_desc.* 
		LET l_cnt = l_cnt + 1 
		LET l_arr_job_desc[l_cnt] = l_rec_job_desc.desc_text 
	END FOREACH 
	CALL set_count(l_cnt) 

	OPEN WINDOW j101 with FORM "J101" 
	CALL windecoration_j("J101") 

	DISPLAY BY NAME glob_rec_job.job_code, 
	glob_rec_job.title_text 

	DISPLAY ARRAY l_arr_job_desc TO sr_job_desc.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","jobqwind","display-arr-job_desc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j101 
END FUNCTION 

FUNCTION scan_vars() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_jobvars ARRAY[100] OF RECORD 
				scroll_flag CHAR(1), 
				var_code LIKE jobvars.var_code, 
				title_text LIKE jobvars.title_text, 
				appro_date LIKE jobvars.appro_date 
			 END RECORD 
	DEFINE l_cnt INTEGER 
	DEFINE l_idx INTEGER
	DEFINE l_scrn INTEGER	
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200)

	SELECT count(*) INTO l_cnt FROM jobvars 
	WHERE cmpy_code = glob_rec_company.cmpy_code 
	AND job_code = glob_rec_job.job_code 
	IF l_cnt = 0 THEN 
		LET glob_rec_jobvars.var_code = 0 
		CALL scan_acts() 
		RETURN 
	END IF 
	OPEN WINDOW j119 with FORM "J119" 
	CALL windecoration_j("J119") -- albo kd-767 

	WHILE not(int_flag OR quit_flag) 
		CLEAR FORM 
		DISPLAY glob_rec_job.job_code, 
		glob_rec_job.title_text 
		TO job.job_code, 
		job_title_text 

		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON jobvars.var_code, 
		jobvars.title_text, 
		jobvars.appro_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobqwind","construct-jobvars") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1001 Searching Database;  Please wait.
		LET l_query_text = 
		"SELECT var_code, ", 
		"title_text, ", 
		"appro_date ", 
		"FROM jobvars ", 
		"WHERE cmpy_code = '",glob_rec_company.cmpy_code,"' ", 
		"AND jobvars.job_code = '", glob_rec_job.job_code,"' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY var_code" 
		LET l_idx = 1 
		LET l_arr_jobvars[l_idx].var_code = 0 
		LET l_arr_jobvars[l_idx].title_text = "Original Job" 
		LET l_arr_jobvars[l_idx].appro_date = NULL 
		PREPARE s_jobvars FROM l_query_text 
		DECLARE c_jobvars CURSOR FOR s_jobvars 
		FOREACH c_jobvars INTO glob_rec_jobvars.var_code, 
			glob_rec_jobvars.title_text, 
			glob_rec_jobvars.appro_date 
			LET l_idx = l_idx + 1 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",9100,l_idx) 
				#9100 First 100 records selected only.
				EXIT FOREACH 
			END IF 
			LET l_arr_jobvars[l_idx].var_code = glob_rec_jobvars.var_code 
			LET l_arr_jobvars[l_idx].title_text = glob_rec_jobvars.title_text 
			LET l_arr_jobvars[l_idx].appro_date = glob_rec_jobvars.appro_date 
		END FOREACH 
		CLOSE c_jobvars 

		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("J",1551,"") 
		#1551 Press ENTER TO SELECT variation.
		INPUT ARRAY l_arr_jobvars WITHOUT DEFAULTS FROM sr_jobvars.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobqwind","input-arr-jobvars") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				DISPLAY l_arr_jobvars[l_idx].* TO sr_jobvars[l_scrn].* 

			AFTER ROW 
				DISPLAY l_arr_jobvars[l_idx].* TO sr_jobvars[l_scrn].* 
			BEFORE FIELD scroll_flag 
				LET glob_rec_jobvars.var_code = l_arr_jobvars[l_idx].var_code 
			AFTER FIELD scroll_flag 
				--#IF fgl_lastkey() = fgl_keyval("accept")
				--#AND fgl_fglgui() THEN
				--#   NEXT FIELD var_code
				--#END IF
				LET l_arr_jobvars[l_idx].var_code = glob_rec_jobvars.var_code 
				DISPLAY l_arr_jobvars[l_idx].var_code 
				TO sr_jobvars[l_scrn].var_code 

				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD var_code 
				LET l_idx = arr_curr() 
				LET glob_rec_jobvars.var_code = l_arr_jobvars[l_idx].var_code 
				CALL scan_acts() 
				NEXT FIELD scroll_flag 

		END INPUT 
	END WHILE 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j119 
END FUNCTION 


FUNCTION scan_acts() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_arr_activity ARRAY[50] OF RECORD 
		activity_code LIKE activity.activity_code, 
		title_text LIKE activity.title_text, 
		resp_code LIKE activity.resp_code, 
		sort_text LIKE activity.sort_text, 
		est_end_date LIKE activity.est_end_date 
	END RECORD 
	DEFINE l_cnt INTEGER
	DEFINE l_idx INTEGER
	DEFINE l_scrn INTEGER		 
	DEFINE l_runner CHAR(200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 

	OPEN WINDOW j118 with FORM "J118" 
	CALL windecoration_j("J118") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		DISPLAY glob_rec_job.cust_code, 
		glob_rec_customer.name_text, 
		glob_rec_job.job_code, 
		glob_rec_job.title_text, 
		glob_rec_jobvars.var_code 
		TO job.cust_code, 
		customer.name_text, 
		job.job_code, 
		job.title_text, 
		activity.var_code 

		CONSTRUCT l_where_text ON activity.activity_code, 
		activity.title_text, 
		activity.resp_code, 
		activity.sort_text, 
		activity.est_end_date 
		FROM sr_activity[1].* 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jobqwind","construct-activity") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database;  Please wait.
		LET l_query_text = 
		"SELECT * FROM activity WHERE ", 
		" cmpy_code = \"", glob_rec_company.cmpy_code, "\"", 
		" AND activity.job_code = \"", glob_rec_job.job_code, "\"", 
		" AND activity.var_code = ", glob_rec_jobvars.var_code, " AND ", 
		l_where_text CLIPPED, 
		" ORDER BY sort_text, activity_code " 
		PREPARE act_query FROM l_query_text 
		DECLARE c_act CURSOR FOR act_query 
		LET l_cnt = 0 
		FOREACH c_act INTO l_rec_activity.* 
			LET l_cnt = l_cnt + 1 
			LET l_arr_activity[l_cnt].activity_code = l_rec_activity.activity_code 
			LET l_arr_activity[l_cnt].title_text = l_rec_activity.title_text 
			LET l_arr_activity[l_cnt].resp_code = l_rec_activity.resp_code 
			LET l_arr_activity[l_cnt].sort_text = l_rec_activity.sort_text 
			LET l_arr_activity[l_cnt].est_end_date = l_rec_activity.est_end_date 
			IF l_cnt = 50 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF l_cnt = 0 THEN 
			LET l_msgresp = kandoomsg("U",1021,"") 
			#1021 No entries satisfied selection criteria.
			SLEEP 3 
			CONTINUE WHILE 
		END IF 
		WHENEVER ERROR CONTINUE 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("J",1552,"") 
		#1552 Press ENTER TO SELECT activity.
		CALL set_count(l_cnt) 
		INPUT ARRAY l_arr_activity WITHOUT DEFAULTS FROM sr_activity.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","jobqwind","input-arr-activity") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_idx > arr_count() THEN 
					ERROR "No Further Activities FOR this Job" 
					LET l_rec_activity.activity_code = NULL 
					NEXT FIELD activity_code 
				ELSE 
					LET l_rec_activity.activity_code = 
					l_arr_activity[l_idx].activity_code 
					DISPLAY l_arr_activity[l_idx].* 
					TO sr_activity[l_scrn].* 

				END IF 
			AFTER FIELD activity_code 
				LET l_arr_activity[l_idx].activity_code = 
				l_rec_activity.activity_code 
				DISPLAY l_arr_activity[l_idx].* 
				TO sr_activity[l_scrn].* 

			BEFORE FIELD title_text 
				IF l_arr_activity[l_idx].activity_code IS NOT NULL THEN 
					LET l_idx = arr_curr() 
					LET l_runner = "job.job_code = '", 
					glob_rec_job.job_code CLIPPED,"' ", 
					" AND activity.var_code = '", 
					glob_rec_jobvars.var_code, "' ", 
					" AND activity.activity_code = '", 
					l_arr_activity[l_idx].activity_code CLIPPED, "' " 
					CALL run_prog("J52",l_runner,"","","") 
				END IF 
				NEXT FIELD activity_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j118 
END FUNCTION 




