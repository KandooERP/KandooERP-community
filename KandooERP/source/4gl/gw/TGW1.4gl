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

	Source code beautified by beautify.pl on 2020-01-03 10:10:00	$Id: $
}



#as GLOBALS FROM TGW1a

# This module contains the global declarations AND main
# functions FOR the Report processing functions.

{

create table rptargs
   (
    job_id                   serial NOT NULL,
    cmpy_code                CHAR(2) NOT NULL,
    glob_rec_kandoouser.sign_on_code                     CHAR(40),
    run_opt                  CHAR(1),
    entry_criteria           CHAR(60),
    segment_criteria         CHAR(500),
    active_flag              CHAR(1),
    rptgrp_desc              CHAR(60)
   );

create unique index ix0_rptargs on rptargs
    (job_id,
     cmpy_code);


}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW1_GLOBALS.4gl" 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE l_counter INTEGER 

	CALL setModuleId("TGW1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 

	# There are two phases TO running this program.  The first, involving user
	# interaction, IS TO SELECT those reports that are TO be RUN, AND TO enter
	# the RUN-time criteria.  This sets up the argument VALUES.  The second
	# phase IS TO do the REPORT processing, as specified by the arg parameters.

	INITIALIZE gr_entry_criteria.* TO NULL 
	INITIALIZE gr_rptargs.* TO NULL 

	LET gv_num_args = num_args() 

	IF gv_num_args > 0 THEN 
		CALL process_rpt() 
		EXIT program 
	END IF 

	OPEN WINDOW g570 with FORM "TG570" 
	CALL windecoration_t("TG570") -- albo kd-768 

	LET gv_aborted = false 

	MENU "Management Reports" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW1","menu-Management_Reports-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "RUN REPORT" #COMMAND "Run Report" "Report selection" 
			CALL TGW1_select_rpts(0) 
			IF run_reports() THEN 

				NEXT option "Print Manager" 
			END IF 

		ON ACTION "GROUP REPORT RUN" #COMMAND "Group Report Run" "Run a predefined group of MW reports" 
			CALL TGW1_select_rpts(1) 
			IF run_reports() THEN 

				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager" #COMMAND "Print" "Print OR View using RMS"
			CALL run_prog("URS", "", "", "", "") 
			NEXT option "Exit" 

		ON ACTION "CANCEL" #COMMAND KEY (E,interrupt) "Exit" "Exit TO Menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW g570 
	EXIT program 

END MAIN 



#######################################################################
# FUNCTION run_reports()
#
#
#######################################################################
FUNCTION run_reports() 
	DEFINE l_runner CHAR(100) 
	DEFINE l_date_text CHAR(8) 

	CLEAR FORM 
	CASE 
		WHEN gv_aborted 
			CALL finish_up() 

		WHEN NOT gv_selected 
			CALL finish_up() 

		OTHERWISE 
			#         OPEN WINDOW G500
			#              AT 2,3
			#              WITH FORM "TG500"
			#              ATTRIBUTE(border)

			CALL start_up() 
			CALL get_rtime_criteria() 
			IF gv_aborted THEN 
				INITIALIZE gr_entry_criteria.* TO NULL 
				CALL finish_up() 
			ELSE 
				SELECT * 
				INTO gr_rptargs.* 
				FROM rptargs 
				WHERE job_id = gv_job_id 

				LET gr_rptargs.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET gr_rptargs.whom = glob_rec_kandoouser.sign_on_code #simply guessed whom 
				LET gr_rptargs.run_opt = gr_entry_criteria.run_opt 

				LET gr_rptargs.entry_criteria[1,2] 
				= gr_entry_criteria.cmpy_code 
				LET gr_rptargs.entry_criteria[3,6] 
				= gr_entry_criteria.year_num 
				LET gr_rptargs.entry_criteria[7,10] 
				= gr_entry_criteria.period_num 
				LET gr_rptargs.entry_criteria[11,11] 
				= gr_entry_criteria.col_hdr_per_page 
				LET gr_rptargs.entry_criteria[12,12] 
				= gr_entry_criteria.std_head_per_page 
				LET gr_rptargs.entry_criteria[13,13] 
				= gr_entry_criteria.worksheet_rpt 
				LET gr_rptargs.entry_criteria[14] 
				= gr_entry_criteria.desc_type 
				LET gr_rptargs.entry_criteria[15,24] 
				= gr_entry_criteria.rpt_date 
				LET gr_rptargs.entry_criteria[25,27] 
				= gr_entry_criteria.curr_slct 
				LET gr_rptargs.entry_criteria[28,30] 
				= gr_entry_criteria.conv_curr 
				LET gr_rptargs.entry_criteria[31,35] 
				= gr_entry_criteria.base_lit 
				LET gr_rptargs.entry_criteria[36] 
				= gr_entry_criteria.conv_flag 
				LET gr_rptargs.entry_criteria[37] 
				= gr_entry_criteria.use_end_date 
				LET gr_rptargs.entry_criteria[38,54] 
				= gr_entry_criteria.conv_qty 

				LET gr_rptargs.segment_criteria = gv_segment_criteria 

				#The following field IS only used by TGWS, which handles queue/night-queue stuff
				LET gr_rptargs.active_flag = "W" 

				UPDATE rptargs 
				SET * = gr_rptargs.* 
				WHERE job_id = gv_job_id 

				CASE 
					WHEN gr_entry_criteria.run_opt = "I" 
						CALL process_rpt() 
						IF gv_aborted THEN 
							CALL finish_up() 
						ELSE 
							RETURN 1 
						END IF 

					WHEN gr_entry_criteria.run_opt = "i" #background 

						#           LET l_runner = "fglgo ../prog/TGW1.4gi ",
						# specific mod FOR users TO each have their
						#own background error file
						#                gv_job_id, "  > errfile 2>&1 &"
						#                           gv_job_id, "  > $HOME/errfile 2>&1 &"
						#           RUN l_runner
						#Changed back TO old way as there IS a bug in run_prog which stop
						#this running in back ground.
						#      CALL run_prog("TGW1", gv_job_id, " > $HOME/errfile ", "2>&1 ", "&",
						#                     "", "", "", "", "", "")
						LET l_runner = "fglgo ../prog/TGW1.4gi ", 
						gv_job_id, " > $HOME/errfile 2>&1 &" 
						RUN l_runner 



					WHEN gr_entry_criteria.run_opt = "T" 
						CALL get_runtime() 
						RETURNING l_date_text 
						INITIALIZE l_runner TO NULL 
						LET l_runner = "echo fglgo TGW1.4gi ", 
						gr_rptargs.job_id, 
						" | AT -t ",l_date_text, 
						" > /dev/NULL 2>&1 " 

						RUN l_runner WITHOUT waiting 

						#Cron job will take care of Q AND N

				END CASE 
			END IF 

			#         CLOSE WINDOW G500
			OPTIONS MESSAGE line LAST 
			CASE 
				WHEN gr_entry_criteria.run_opt = "i" 
					#MESSAGE "Report job sent TO background processing"
					LET msgresp = kandoomsg("G",1600,"TO background processing ") 
				WHEN gr_entry_criteria.run_opt = "T" 
					#MESSAGE "Report job sent"
					LET msgresp = kandoomsg("G",1600," ") 
				WHEN gr_entry_criteria.run_opt = "N" 
					#MESSAGE "Report job sent TO night queue"
					LET msgresp = kandoomsg("G",1600,"TO night queue ") 
				WHEN gr_entry_criteria.run_opt = "Q" 
					#MESSAGE "Report job sent TO daytime queue"
					LET msgresp = kandoomsg("G",1600,"TO daytime queue ") 
			END CASE 
			OPTIONS MESSAGE line 2 
	END CASE 

	RETURN 0 

END FUNCTION -- run_reports 



#######################################################################
# FUNCTION TGW1_select_rpts(l_report_group)
#
#
#######################################################################
FUNCTION TGW1_select_rpts(l_report_group) 
	DEFINE l_where_part nvarchar(500) 
	DEFINE l_query_text nvarchar(500) 
	DEFINE l_reselect SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_arr_rec_rptslect DYNAMIC ARRAY OF # array[200] OF RECORD 
		RECORD 
			slectd CHAR(1), 
			rpt_id LIKE rpthead.rpt_id, 
			rpt_text LIKE rpthead.rpt_text, 
			acct_grp LIKE rpthead.acct_grp, 
			print_code LIKE printcodes.print_code 
		END RECORD 
		DEFINE l_rmsparm_rw_printer LIKE rmsparm.rw_print_text 
		DEFINE l_print_code LIKE printcodes.print_code 
		DEFINE l_report_group SMALLINT 

		CLEAR FORM 

		SELECT rw_print_text 
		INTO l_rmsparm_rw_printer 
		FROM rmsparm 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET gr_rptargs.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET gr_rptargs.job_id = 0 
		INSERT INTO rptargs VALUES (gr_rptargs.*) 
		LET gv_job_id = sqlca.sqlerrd[2] 

		WHILE true 
			LET l_reselect = false 

			INITIALIZE gr_rpthead_group.* TO NULL 

			IF NOT l_report_group THEN 

				#MESSAGE "Enter selection criteria - ACC TO begin search"
				#  ATTRIBUTE(yellow)
				LET msgresp = kandoomsg("U",1001," ") 

				CONSTRUCT BY NAME l_where_part ON rpthead.rpt_id, 
				rpthead.rpt_text, 
				rpthead.acct_grp 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","TGW1","construct-rpthead-1") -- albo kd-515 

					ON ACTION "WEB-HELP" -- albo kd-378 
						CALL onlinehelp(getmoduleid(),null) 

				END CONSTRUCT 

				LET l_query_text = " SELECT * FROM rpthead", 
				" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", "AND ", 
				l_where_part clipped, 
				" ORDER BY rpt_id" 
			ELSE 

				CALL get_report_group() 
				UPDATE rptargs SET rptgrp_desc = gr_rpthead_group.rptgrp_desc2 
				WHERE job_id = gv_job_id 

				LET l_query_text = " SELECT rpthead.* FROM rpthead, rpthead_struct", 
				" WHERE rpthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND rpthead.cmpy_code = rpthead_struct.cmpy_code ", 
				" AND rpthead.rpt_id = rpthead_struct.rpt_id ", 
				" AND rpthead_struct.rptgrp_id = '", 
				gr_rpthead_group.rptgrp_id clipped, 
				"' ORDER BY rpthead.rpt_id" 
			END IF 
			#
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET gv_aborted = true 
				EXIT WHILE 
			END IF 

			PREPARE rpthd FROM l_query_text 
			DECLARE rpthd_curs CURSOR FOR rpthd 

			LET l_idx = 0 

			FOREACH rpthd_curs INTO gr_rpthead.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_rptslect[l_idx].slectd = "*" 
				LET l_arr_rec_rptslect[l_idx].rpt_id = gr_rpthead.rpt_id 
				LET l_arr_rec_rptslect[l_idx].rpt_text = gr_rpthead.rpt_text 
				LET l_arr_rec_rptslect[l_idx].acct_grp = gr_rpthead.acct_grp 
				LET l_arr_rec_rptslect[l_idx].print_code = l_rmsparm_rw_printer 

			END FOREACH 

			INITIALIZE gr_rpthead.* TO NULL 

			IF l_idx = 0 THEN 
				ERROR "No reports satisfy the query criteria" attribute(yellow) 
				CONTINUE WHILE 
			END IF 

			LET l_cnt = l_idx 

			#MESSAGE "Report Selection - F7 SELECT/Unselect REPORT, ",
			#        "F9 Re-SELECT, ACC TO accept"
			LET msgresp = kandoomsg("G",1601," ") 

			INPUT ARRAY l_arr_rec_rptslect WITHOUT DEFAULTS FROM sa_rptslect.* ATTRIBUTE() 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","TGW1","input-arr-l_arr_rec_rptslect-1") -- albo kd-515 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_scrn = scr_line() 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						LET gv_aborted = true 
						EXIT INPUT 
					END IF 

				ON ACTION "WEB-HELP" -- albo kd-378 
					CALL onlinehelp(getmoduleid(),null) 

				ON KEY (accept) 
					EXIT INPUT 

				ON KEY (F9) 
					LET l_reselect = true 
					EXIT INPUT 

				ON KEY (F7) 
					IF infield(slectd) THEN 
						IF l_arr_rec_rptslect[l_idx].slectd IS NULL 
						OR l_arr_rec_rptslect[l_idx].slectd = " " THEN 
							LET l_arr_rec_rptslect[l_idx].slectd = "*" 
						ELSE 
							LET l_arr_rec_rptslect[l_idx].slectd = "" 
						END IF 
						DISPLAY l_arr_rec_rptslect[l_idx].slectd 
						TO sa_rptslect[l_scrn].slectd 
					ELSE 
						ERROR "" 
					END IF 

				ON ACTION "LOOKUP" infield(print_code)  
						LET l_print_code = show_print(glob_rec_kandoouser.cmpy_code) 
						IF l_print_code IS NOT NULL THEN 
							LET l_arr_rec_rptslect[l_idx].print_code = l_print_code 
							DISPLAY l_arr_rec_rptslect[l_idx].print_code 
							TO sa_rptslect[l_scrn].print_code 
						END IF 


				BEFORE FIELD rpt_id 
					NEXT FIELD print_code 

				AFTER FIELD slectd 
					IF l_arr_rec_rptslect[l_idx].slectd NOT matches "[* ]" THEN 
						ERROR "Selected flag must be * OR blank" 
						NEXT FIELD slectd 
					END IF 

					IF l_arr_rec_rptslect[l_idx].slectd IS NULL 
					OR l_arr_rec_rptslect[l_idx].slectd = " " THEN 
						LET l_arr_rec_rptslect[l_idx].print_code = "" 
						DISPLAY l_arr_rec_rptslect[l_idx].print_code 
						TO sa_rptslect[l_scrn].print_code 
					END IF 

					IF fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD slectd 
					END IF 

				AFTER FIELD print_code 
					IF l_arr_rec_rptslect[l_idx].print_code IS NOT NULL THEN 
						SELECT * FROM printcodes 
						WHERE print_code = l_arr_rec_rptslect[l_idx].print_code 
						IF status = notfound THEN 
							ERROR "Printer does NOT exist" 
							NEXT FIELD print_code 
						END IF 
					END IF 

					IF fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD print_code 
					END IF 

				AFTER ROW 
					IF l_cnt <= l_cnt THEN 
						DISPLAY l_arr_rec_rptslect[l_idx].* TO sa_rptslect[l_scrn].* 

					END IF 

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET gv_aborted = true 
				EXIT WHILE 
			END IF 

			IF l_reselect <> true THEN 
				EXIT WHILE 
			END IF 

			#   CLEAR FORM

		END WHILE 

		IF gv_aborted THEN 
			RETURN 
		END IF 

		LET gv_selected = false 

		FOR l_idx = 1 TO l_arr_rec_rptslect.getSize() 
			IF l_arr_rec_rptslect[l_idx].rpt_id IS NULL THEN 
				EXIT FOR 
			END IF 

			IF l_arr_rec_rptslect[l_idx].slectd IS NOT NULL 
			AND l_arr_rec_rptslect[l_idx].slectd <> " " THEN 
				LET gv_selected = true 
				LET gr_rptslect.job_id = gv_job_id 
				LET gr_rptslect.rpt_id = l_arr_rec_rptslect[l_idx].rpt_id 
				LET gr_rptslect.print_code = l_arr_rec_rptslect[l_idx].print_code 
				INSERT INTO rptslect VALUES (gr_rptslect.*) 
			END IF 
		END FOR 

 
END FUNCTION 


#######################################################################
# FUNCTION start_up()
#
#
#######################################################################
FUNCTION start_up() 

	INITIALIZE gr_entry_criteria.* TO NULL 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, 
	mdy (month(today), 1, year(today) ) -1) 
	RETURNING gr_entry_criteria.year_num, 
	gr_entry_criteria.period_num 

	LET gr_entry_criteria.rpt_date = today 
	LET gr_entry_criteria.col_hdr_per_page = "Y" 
	LET gr_entry_criteria.std_head_per_page = "Y" 
	LET gr_entry_criteria.desc_type = "B" 
END FUNCTION 



#######################################################################
# FUNCTION finish_up()
#
#
#######################################################################
FUNCTION finish_up() 

	CASE 
		WHEN gv_aborted OR int_flag OR quit_flag 
			ERROR "Management REPORT process aborted" 
			INITIALIZE gr_entry_criteria.* TO NULL 

		WHEN NOT gv_selected 
			ERROR "No records selected" 

		OTHERWISE 
			#MESSAGE "Management REPORT process complete"
			LET msgresp = kandoomsg("G",1602," ") 
			SLEEP 1 
	END CASE 

	LET int_flag = false 
	LET quit_flag = false 
	LET gv_aborted = false 

	WHENEVER ERROR CONTINUE 
	DELETE FROM rptargs 
	WHERE job_id = gv_job_id 
	DELETE FROM rptslect 
	WHERE job_id = gv_job_id 
	DELETE FROM tempcoa 
	WHENEVER ERROR stop 

END FUNCTION 



#######################################################################
# FUNCTION get_runtime()
#
#
#######################################################################
FUNCTION get_runtime() 
	DEFINE l_rec_fr_date 
	RECORD 
		month_text DECIMAL(2,0), 
		day_text DECIMAL(2,0), 
		hour_text DECIMAL(2,0), 
		mins_text DECIMAL(2,0) 
	END RECORD 
	DEFINE l_date_text CHAR(8) 

	OPTIONS INPUT wrap 

	OPEN WINDOW g571 with FORM "TG571" 
	CALL windecoration_t("TG571") -- albo kd-768 

	#DISPLAY "Enter details, ACC TO accept " AT 1,1 ATTRIBUTE(yellow)
	LET msgresp = kandoomsg("U",1525," ") 
	DISPLAY "Please enter day AND time TO RUN REPORT" at 2,1 

	LET l_rec_fr_date.month_text = month(today) 
	LET l_rec_fr_date.day_text = day(today) 

	INPUT BY NAME l_rec_fr_date.* WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW1","input-l_rec_fr_date-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	CLOSE WINDOW g571 

	OPTIONS INPUT no wrap 

	LET l_date_text = l_rec_fr_date.month_text USING "&&", 
	l_rec_fr_date.day_text USING "&&", 
	l_rec_fr_date.hour_text USING "&&", 
	l_rec_fr_date.mins_text USING "&&" 

	RETURN l_date_text 

END FUNCTION 


#############################################################################################
# FUNCTION process_rpt()
#
#
#############################################################################################
FUNCTION process_rpt() 
	DEFINE l_regex util.regex #util.regex - TO HOLD the regular expression: 
	DEFINE l_match util.match_results #util.match_results - TO HOLD the search results: 

	DEFINE fv_dtls_cnt SMALLINT 
	DEFINE hold_run_opt CHAR(1) 

	IF get_argint1_set() THEN #arg provided via url OR env 
		LET gv_job_id = get_url_int1() 
	ELSE 
		IF gv_num_args > 0 THEN 
			LET gv_job_id = arg_val(1) #like rptargs.job_id 
		END IF 
	END IF 



	{

		LET l_regex = \=

		LET r = util.REGEX.l_match("Hubert = Super", l_regex)

		CALL util.REGEX.search(res, l_regex) RETURNING l_match

		IF l_match IS NOT NULL THEN
			display "no ="
		END IF

		}

	{



	util.MATCH_RESULTS - TO hold the search results:

	DEFINE l_match util.MATCH_RESULTS


	[\-]

	matches the hyphen (-) character:

	/[\-]/ -- matches "-" in "fifty-fifty"

	}


	SELECT * 
	INTO gr_rptargs.* 
	FROM rptargs 
	WHERE job_id = gv_job_id 

	IF status = notfound THEN 
		EXIT program 
	END IF 

	# Added TO keep runing option eg Interactive, back ground
	LET hold_run_opt = gr_entry_criteria.run_opt 
	INITIALIZE gr_entry_criteria.* TO NULL 
	LET gr_entry_criteria.run_opt = hold_run_opt 

	LET glob_rec_kandoouser.cmpy_code = gr_rptargs.cmpy_code 
	LET glob_rec_kandoouser.sign_on_code = gr_rptargs.whom #simply guessed whom huho -- this looks all soo wrong 
	LET gr_entry_criteria.cmpy_code = gr_rptargs.entry_criteria[1,2] 
	LET gr_entry_criteria.year_num = gr_rptargs.entry_criteria[3,6] 
	LET gr_entry_criteria.period_num = gr_rptargs.entry_criteria[7,10] 
	LET gr_entry_criteria.col_hdr_per_page = gr_rptargs.entry_criteria[11,11] 
	LET gr_entry_criteria.std_head_per_page = gr_rptargs.entry_criteria[12,12] 
	LET gr_entry_criteria.worksheet_rpt = gr_rptargs.entry_criteria[13,13] 
	LET gr_entry_criteria.desc_type = gr_rptargs.entry_criteria[14] 
	LET gr_entry_criteria.rpt_date = gr_rptargs.entry_criteria[15,24] 
	LET gr_entry_criteria.curr_slct = gr_rptargs.entry_criteria[25,27] 
	LET gr_entry_criteria.conv_curr = gr_rptargs.entry_criteria[28,30] 
	LET gr_entry_criteria.base_lit = gr_rptargs.entry_criteria[31,35] 
	LET gr_entry_criteria.conv_flag = gr_rptargs.entry_criteria[36] 
	LET gr_entry_criteria.use_end_date = gr_rptargs.entry_criteria[37] 
	LET gr_entry_criteria.conv_qty = gr_rptargs.entry_criteria[38,54] 

	IF gr_entry_criteria.curr_slct = " " THEN 
		LET gr_entry_criteria.curr_slct = NULL 
	END IF 

	IF gr_entry_criteria.conv_curr = " " THEN 
		LET gr_entry_criteria.conv_curr = NULL 
	END IF 

	LET gv_segment_criteria = gr_rptargs.segment_criteria 

	SELECT * 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET pr_glparms.use_currency_flag = "N" 
	END IF 

	SELECT curr_code 
	INTO gv_base_curr 
	FROM company 
	WHERE cmpy_code = gr_entry_criteria.cmpy_code 

	SELECT sum(length_num) 
	INTO gv_acct_length 
	FROM structure 
	WHERE cmpy_code = gr_entry_criteria.cmpy_code 

	SELECT * INTO gr_mrwparms.* 
	FROM mrwparms 

	SELECT name_text INTO gv_kandoousername 
	FROM kandoouser 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sign_on_code = glob_rec_kandoouser.sign_on_code 

	SELECT name_text INTO gv_maxcompany 
	FROM company 
	WHERE cmpy_code = gr_entry_criteria.cmpy_code 

	##Create temp tables FOR currency recording purposes
	WHENEVER ERROR CONTINUE
	IF fgl_find_table("temp_curr") THEN
		DROP TABLE temp_curr 
	END IF	 
	WHENEVER ERROR stop 

	CREATE temp TABLE temp_curr 
	( curr_code CHAR(3) ); 
	CREATE unique INDEX tempcurr_i1 ON temp_curr (curr_code); 

	IF pr_glparms.use_currency_flag = "Y" THEN 
		DECLARE curr_curs CURSOR FOR 
		SELECT unique currency_code 
		FROM accounthistcur 
		WHERE cmpy_code = gr_entry_criteria.cmpy_code 
		AND year_num = gr_entry_criteria.year_num 
		AND period_num = gr_entry_criteria.period_num 
		ORDER BY currency_code 

		FOREACH curr_curs INTO gv_curr_code 
			INSERT INTO temp_curr VALUES (gv_curr_code) 
		END FOREACH 
	ELSE 
		INSERT INTO temp_curr VALUES (gv_base_curr) 
	END IF 

	DECLARE rpt_curs CURSOR with HOLD FOR 
	SELECT * FROM rptslect 
	WHERE job_id = gr_rptargs.job_id 

	FOREACH rpt_curs INTO gr_rptslect.* 
		SELECT * 
		INTO gr_rpthead.* 
		FROM rpthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = gr_rptslect.rpt_id 
		IF status THEN 
			CONTINUE FOREACH 
		END IF 

		-- Overwrite the second description with the group description IF a
		-- group has been chosen AND it has a description (usually a date
		-- description) entered.
		IF gr_rptargs.rptgrp_desc IS NOT NULL THEN 
			LET gr_rpthead.rpt_desc2 = gr_rptargs.rptgrp_desc 
		END IF 

		SELECT * 
		INTO gr_rptcolgrp.* 
		FROM rptcolgrp 
		WHERE cmpy_code = gr_rpthead.cmpy_code 
		AND col_code = gr_rpthead.col_code 
		IF status THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO gr_rptlinegrp.* 
		FROM rptlinegrp 
		WHERE cmpy_code = gr_rpthead.cmpy_code 
		AND line_code = gr_rpthead.line_code 
		IF status THEN 
			CONTINUE FOREACH 
		END IF 

		IF gr_entry_criteria.col_hdr_per_page IS NULL 
		OR gr_entry_criteria.col_hdr_per_page = " " THEN 
			LET gr_entry_criteria.col_hdr_per_page 
			= gr_rpthead.col_hdr_per_page 
		END IF 

		IF gr_entry_criteria.std_head_per_page IS NULL 
		OR gr_entry_criteria.std_head_per_page = " " THEN 
			LET gr_entry_criteria.std_head_per_page 
			= gr_rpthead.std_head_per_page 
		END IF 

		LET gv_acct_group = gr_rpthead.acct_grp 

		IF NOT (gv_acct_group IS NULL 
		OR gv_acct_group = " ") THEN 
			#MESSAGE "Building Account group code selection ",
			#        "- please wait"
			#  ATTRIBUTE(yellow)
			LET msgresp = kandoomsg("G",1603," ") 
			CALL build_coa(gr_rpthead.cmpy_code, 
			gr_rpthead.acct_grp) 
			RETURNING fv_dtls_cnt 
			IF fv_dtls_cnt = 0 THEN 
				INITIALIZE gv_acct_group TO NULL 
			END IF 
		ELSE 
			INITIALIZE gv_acct_group TO NULL 
		END IF 

		IF gr_entry_criteria.run_opt = "I" #interactive 
		THEN 
			MESSAGE "Producing REPORT ", gr_rpthead.rpt_id clipped, 
			" ... please wait" 
			attribute(yellow) 
		END IF 
		CALL produce_rpt() 
		IF gv_aborted THEN 
			EXIT FOREACH 
		END IF 

	END FOREACH 

	WHENEVER ERROR CONTINUE 
	DELETE FROM rptargs 
	WHERE job_id = gv_job_id 
	DELETE FROM rptargs_ext 
	WHERE job_id = gv_job_id 
	DELETE FROM rptslect 
	WHERE job_id = gv_job_id 
	DELETE FROM tempcoa 
	WHENEVER ERROR stop 

END FUNCTION 
