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
GLOBALS "../common/postfunc_GLOBALS.4gl" 

# DEFINE module cursors and prepares
DEFINE prp_update_poststatus_error PREPARED
DEFINE prp_update_poststatus_reset PREPARED
DEFINE prp_update_poststatus_ok PREPARED

############################################################
# FUNCTION postupd(p_rollit,p_err_status,p_mod_code)
#
#
############################################################
FUNCTION update_poststatus(p_rollit,p_err_status,p_mod_code) 
	DEFINE p_rollit SMALLINT 
	DEFINE p_err_status INTEGER 
	DEFINE p_mod_code CHAR(2) 
	DEFINE l_arr_rec_errors DYNAMIC ARRAY OF CHAR(80) #array[10] OF CHAR(80) 
	DEFINE l_num_lines SMALLINT 
	DEFINE l_want_error SMALLINT 
	DEFINE l_load_file CHAR(40) 
	DEFINE l_query_statement STRING

	DEFER QUIT 
	DEFER INTERRUPT 
	IF prp_update_poststatus_error.GetStatement() IS NULL THEN
		LET l_query_statement = "UPDATE poststatus ",
		" SET status_code = 99, ",
		" status_text = ? ,",
		" status_time =  ?, ",
		" jour_num = ?, ",
		" post_year_num = ?,",
		" post_period_num = ?,",
		" error_text = ?, ",
		" error_time = ?, ",
		" error1_text = ?,",
		" error2_text = ?,",
		" error3_text = ?,",  
		" error4_text = ?, ",
		" user_code = ?,",
		" post_running_flag = 'N', ",
		" error_msg = ? ",
		" WHERE cmpy_code = ? ",
		" AND module_code = ? "
			
		CALL prp_update_poststatus_error.Prepare(l_query_statement)
	
		LET l_query_statement = "UPDATE poststatus ",
		" SET status_code = ?,",
		" status_text = ?,",  
		" status_time = ?, ", 
		" jour_num = ?,", 
		" user_code = ?,", 
		" post_year_num = ?,",
		" post_period_num = ? ",
		" WHERE cmpy_code = ? ",
		" AND module_code = ? "
		
		CALL prp_update_poststatus_ok.Prepare(l_query_statement)

		LET l_query_statement = "UPDATE poststatus ",
		" SET error_status = 0, ",
		" error_text = ' ', ",
		" error_time = NULL, ",
		" error1_text = ' ', ",
		" error2_text = ' ', ",
		" error3_text = ' ', ",
		" error4_text = ' ' ",
		" WHERE cmpy_code = ? ",
		" AND module_code = ? "
		CALL prp_update_poststatus_reset.Prepare(l_query_statement)
	END IF
	
	IF get_debug() THEN 
		DISPLAY "#### FUNCTION postupd(", trim(p_rollit),"/", trim(p_err_status),"/", trim(p_mod_code),"/" 
	END IF 

	IF p_rollit THEN {an ERROR has occurred} 

		DELETE FROM posterrors WHERE 1=1 
		LET glob_rec_poststatus.error1_text = " " 
		LET glob_rec_poststatus.error2_text = " " 
		LET glob_rec_poststatus.error3_text = " " 
		LET glob_rec_poststatus.error4_text = " " 
		{

		        LET l_load_file = "postlog.",p_mod_code
		        load FROM l_load_file INSERT INTO posterrors
		        DECLARE error_curs CURSOR FOR
		        SELECT * FROM posterrors

		        OPEN error_curs

		        LET l_num_lines = 1
		        LET l_want_error = FALSE
		        WHILE(TRUE)
		            IF l_num_lines > 10 THEN
		                EXIT WHILE
		            END IF
		            FETCH error_curs INTO l_arr_rec_errors[l_num_lines]
		            IF STATUS THEN
		                EXIT WHILE
		            END IF
		            IF check_word("Date:",l_arr_rec_errors[l_num_lines]) THEN
		                IF l_num_lines != 1 THEN
		                    IF l_want_error THEN
		                        EXIT WHILE
		                    ELSE
		                        LET l_num_lines = 1
		                        continue WHILE
		                    END IF
		                END IF
		            END IF
		            IF check_word("number -",l_arr_rec_errors[l_num_lines]) THEN
		                LET l_want_error = TRUE
		            END IF
		            LET l_num_lines = l_num_lines + 1
		        END WHILE

		        LET glob_rec_poststatus.error1_text = l_arr_rec_errors[1]
		        LET glob_rec_poststatus.error2_text = l_arr_rec_errors[2]
		        LET glob_rec_poststatus.error3_text = l_arr_rec_errors[3]
		        LET glob_rec_poststatus.error4_text = l_arr_rec_errors[4]
		}
		IF glob_in_trans THEN 
			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) ,"!!!! ROLLBACK WORK !!!!" 
			END IF 
			ROLLBACK WORK 
		ELSE 

			IF get_debug() THEN 
				DISPLAY "glob_in_trans = ",trim(glob_in_trans) 
			END IF 
		END IF 
		# IF we have a one transaction post THEN IF error_recover has
		# been called it will rollback the last UPDATE of STATUS so
		# we need TO re-UPDATE the STATUS etc
		IF NOT glob_one_trans THEN 
			LET glob_rec_poststatus.error_status = p_err_status 
			LET glob_rec_poststatus.error_text = glob_err_text 
			LET glob_rec_poststatus.error_time = CURRENT year TO second 

			IF get_debug() THEN 
				DISPLAY "UPDATE poststatus ***************************************" 
			END IF 

			UPDATE poststatus SET error_status = glob_rec_poststatus.error_status, 
				error_text = glob_rec_poststatus.error_text, 
				error_time = glob_rec_poststatus.error_time, 
				error1_text = glob_rec_poststatus.error1_text, 
				error2_text = glob_rec_poststatus.error2_text, 
				error3_text = glob_rec_poststatus.error3_text, 
				error4_text = glob_rec_poststatus.error4_text, 
				user_code = glob_rec_kandoouser.sign_on_code, 
				post_running_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = p_mod_code 
			CALL disp_poststatus(p_mod_code) 
			EXIT program 
		ELSE 
			LET glob_rec_poststatus.error_status = p_err_status 
			LET glob_rec_poststatus.error_text = glob_err_text 
			LET glob_rec_poststatus.error_time = CURRENT year TO second 
			LET glob_rec_poststatus.status_code = glob_st_code 
			LET glob_rec_poststatus.status_text = glob_post_text 
			LET glob_rec_poststatus.status_time = CURRENT year TO second 
			LET glob_rec_poststatus.user_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_poststatus.post_year_num = glob_fisc_year 
			LET glob_rec_poststatus.post_period_num = glob_fisc_period 
			# UPDATE as usual except FOR STATUS code which returns TO 99
			# because the transaction IS rolled back !. We store the other
			# info as support reference FOR one transaction sites.

			IF get_debug() THEN 
				DISPLAY "UPDATE poststatus SET status_code = 99" 
			END IF 
			CALL prp_update_poststatus_error.Execute(glob_rec_poststatus.status_text, 
			glob_rec_poststatus.status_time,
			glob_posted_journal, 
			glob_rec_poststatus.post_year_num, 
			glob_rec_poststatus.post_period_num,
			glob_rec_poststatus.error_text, 
			glob_rec_poststatus.error_time, 
			glob_rec_poststatus.error1_text, 
			glob_rec_poststatus.error2_text, 
			glob_rec_poststatus.error3_text,
			glob_rec_poststatus.error4_text, 
			glob_rec_kandoouser.sign_on_code, 
			glob_rec_poststatus.error_msg,
			glob_rec_kandoouser.cmpy_code,
			p_mod_code 
			 )
			CALL disp_poststatus(p_mod_code) 
			EXIT program 
		END IF 
	ELSE 
		LET glob_rec_poststatus.status_code = glob_st_code 
		LET glob_rec_poststatus.status_text = glob_post_text 
		LET glob_rec_poststatus.status_time = CURRENT year TO second 
		LET glob_rec_poststatus.user_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_poststatus.post_year_num = glob_fisc_year 
		LET glob_rec_poststatus.post_period_num = glob_fisc_period 

		IF get_debug() THEN 
			DISPLAY "UPDATE poststatus SET status_code = ", trim(glob_rec_poststatus.status_code) 
		END IF 

		CALL prp_update_poststatus_ok.Execute(
		glob_rec_poststatus.status_code, 
		glob_rec_poststatus.status_text,
		glob_rec_poststatus.status_time,
		glob_posted_journal, 
		glob_rec_poststatus.user_code, 
		glob_rec_poststatus.post_year_num, 
		glob_rec_poststatus.post_period_num ,
		glob_rec_kandoouser.cmpy_code ,
		p_mod_code
		) 


		IF glob_st_code = 99 THEN 
			CALL prp_update_poststatus_reset.Execute(glob_rec_kandoouser.cmpy_code,p_mod_code )
		END IF 
	END IF 

	IF get_debug() THEN 
		DISPLAY "#### END FUNCTION postupd(", trim(p_rollit),"/", trim(p_err_status),"/", trim(p_mod_code),"/" 
	END IF 
END FUNCTION # update_poststatus


############################################################
# FUNCTION disp_poststatus(p_mod_code)
#
#
############################################################
FUNCTION disp_poststatus(p_mod_code) 
	DEFINE p_mod_code CHAR(2) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_rec_report DYNAMIC ARRAY OF RECORD 
		label_text string, 
		value_text STRING 
	END RECORD 
	DEFINE l_file_name STRING
	DEFINE l_run STRING

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION disp_poststatus()" 
	END IF 
	ERROR "" 

	--    OPEN WINDOW show_status AT 2,3 with 15 rows, 75 columns  -- albo  KD-756
	--                            ATTRIBUTE(border, prompt line 15)

	OPEN WINDOW w_report with FORM "C101_status_report_lbl_val" 

	LET l_arr_rec_report[1].label_text = "Module Code" 
	LET l_arr_rec_report[1].value_text = trim(glob_rec_poststatus.module_code) 
	LET l_arr_rec_report[2].label_text = "Status Code" 
	LET l_arr_rec_report[2].value_text = trim(glob_rec_poststatus.status_code) 
	LET l_arr_rec_report[3].label_text = "Last User" 
	LET l_arr_rec_report[3].value_text = trim(glob_rec_poststatus.user_code) 
	LET l_arr_rec_report[4].label_text = "Status Description" 
	LET l_arr_rec_report[4].value_text = trim(glob_rec_poststatus.status_text) 
	LET l_arr_rec_report[5].label_text = "Status Date/Time" 
	LET l_arr_rec_report[5].value_text = trim(glob_rec_poststatus.status_time) 
	LET l_arr_rec_report[6].label_text = "Error Status" 
	LET l_arr_rec_report[6].value_text = trim(glob_rec_poststatus.error_status) 
	LET l_arr_rec_report[7].label_text = "Error Description" 
	LET l_arr_rec_report[7].value_text = trim(glob_rec_poststatus.error_text) 
	LET l_arr_rec_report[8].label_text = "Error Date/Time" 
	LET l_arr_rec_report[8].value_text = trim(glob_rec_poststatus.error_time) 
	LET l_arr_rec_report[9].label_text = "SQL Error line 1" 
	LET l_arr_rec_report[9].value_text = trim(glob_rec_poststatus.error1_text) 
	LET l_arr_rec_report[10].label_text = "SQL Error line 2" 
	LET l_arr_rec_report[10].value_text = trim(glob_rec_poststatus.error2_text) 
	LET l_arr_rec_report[11].label_text = "SQL Error line 3" 
	LET l_arr_rec_report[11].value_text = trim(glob_rec_poststatus.error3_text) 
	LET l_arr_rec_report[12].label_text = "SQL Error line 4" 
	LET l_arr_rec_report[12].value_text = trim(glob_rec_poststatus.error4_text) 
	LET l_arr_rec_report[13].label_text = "Extended error message"
	LET l_arr_rec_report[13].value_text = trim(glob_rec_poststatus.error_msg)
	DISPLAY ARRAY l_arr_rec_report TO sc_report.* ATTRIBUTE(UNBUFFERED) 

	CLOSE WINDOW w_report 
	#

	WHILE true 
		# 3529 "Acknowledge (Y)" FOR CHAR ans
		LET l_msgresp = kandoomsg("U",3529,"") 
		IF l_msgresp = "Y" THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	LET l_file_name = "postlog." , p_mod_code CLIPPED
	LET l_run = "cat ", get_settings_logPath_forFile(l_file_name), " >> ", trim(get_settings_logFile())
	
	RUN l_run
	--    CLOSE WINDOW show_status  -- albo  KD-756
	{
	    LET glob_runner = "cat postlog.",p_mod_code," >> ", trim(get_settings_logFile())

	    run glob_runner

	    LET glob_runner = "> postlog.",p_mod_code

	    run glob_runner
	}
END FUNCTION 


############################################################
# FUNCTION check_word(p_word,p_full_string)
#
#
############################################################
FUNCTION check_word(p_word,p_full_string) 
	DEFINE p_word CHAR(80) 
	DEFINE p_full_string CHAR(80) 
	DEFINE l_x SMALLINT 
	DEFINE l_y SMALLINT 
	DEFINE l_z SMALLINT 

	IF get_debug() THEN 
		DISPLAY "#### FUNCTION check_word" 
	END IF 

	# returns TRUE IF p_word exists in p_full_string
	# returns FALSE IF p_word NOT in p_full_string

	LET l_x = length(p_word) 
	LET l_y = length(p_full_string) 

	IF l_x < l_y THEN 
		FOR l_z = 1 TO l_y 
			IF (l_z + l_x) < l_y THEN 
				IF p_full_string[l_z,(l_z+l_x)] = p_word THEN 
					RETURN true 
				END IF 
			ELSE 
				EXIT FOR 
			END IF 
		END FOR 
	END IF 

	RETURN false 

END FUNCTION 




