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

	Source code beautified by beautify.pl on 2020-01-02 19:48:07	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J38a, close/invoice a job

GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J38_GLOBALS.4gl" 


FUNCTION show_jobs( ) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	fv_reselect, 
	fv_done SMALLINT, 
	runner CHAR(100), 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	cnt SMALLINT, 
	query_text CHAR(200) 
	OPEN WINDOW wj307 with FORM "J307" -- alch kd-747 
	CALL winDecoration_j("J307") -- alch kd-747 
	LET fv_done = true 
	WHILE fv_done 
		IF fv_reselect OR pa_job[1].job_code IS NULL THEN 
			CLEAR FORM 
			# MESSAGE " Enter criteria - press ESC     Del - TO Exit"
			# attribute (yellow)
			LET msgresp = kandoomsg("U",1001," ") 
			CONSTRUCT query_text ON 
			job_code, 
			title_text, 
			type_code, 
			resp_code, 
			bill_way_ind 
			FROM 
			sr_job[1].job_code, 
			sr_job[1].title_text, 
			sr_job[1].type_code, 
			sr_job[1].resp_code, 
			sr_job[1].bill_way_ind 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","J38a","const-job_code-1") -- alch kd-506 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
			LET sel_text = 
			"SELECT job_code, ", 
			"title_text, ", 
			"type_code, ", 
			"resp_code, ", 
			"bill_way_ind , ' '", 
			" FROM job WHERE ", 
			query_text clipped, 
			" AND ", 
			"cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
			" AND locked_ind > \"0\" ", 
			" AND act_end_date IS NULL ", 
			" ORDER BY job_code" 
			LET fv_reselect = false 
			LET cnt = NULL 
		END IF 
		PREPARE job FROM sel_text 
		DECLARE jobcurs CURSOR FOR job 
		OPEN jobcurs 
		LET fv_idx = 1 
		FOREACH jobcurs INTO pa_job[fv_idx].* 
			LET fv_idx = fv_idx + 1 
			IF fv_idx > 50 THEN 
				# MESSAGE " First 50 only selected "
				#   attribute (yellow)
				LET msgresp = kandoomsg("J",1527," ") 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		CLOSE jobcurs 
		LET fv_idx = fv_idx -1 
		IF fv_idx > 0 THEN 
			# MESSAGE "Move CURSOR TO code AND press RETURN,",
			#        " F9 re-SELECT, F10 Print " attribute (yellow)
			LET msgresp = kandoomsg("J",1525," ") 
		ELSE 

			# MESSAGE "No jobs satisfy criteria, F9 TO Re-SELECT, F10 TO Print"
			#              attribute (yellow)
			LET msgresp = kandoomsg("J",1526," ") 

		END IF 
		CALL set_count(fv_idx) 
		INPUT ARRAY pa_job WITHOUT DEFAULTS FROM sr_job.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J38a","input_arr-pa_job-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (F9) 
				LET fv_reselect = true 
				EXIT INPUT 

			ON ACTION "Print Manager" 
				#ON KEY(F10)
				CALL run_prog("URS","","","","") 
			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 
				IF fv_idx < cnt THEN 
					IF pa_job[fv_idx].job_code IS NOT NULL THEN 
						NEXT FIELD nextfield 
					END IF 
				END IF 
				LET cnt = NULL 


			BEFORE FIELD title_text 
				IF invoice_job(pa_job[fv_idx].job_code) THEN 
					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pa_job[fv_idx].job_code 
					LET cnt = fv_idx 
					LET fv_done = false 
					LET fv_reselect = false 
					EXIT INPUT 
				END IF 
				NEXT FIELD job_code 

			BEFORE FIELD type_code 
				NEXT FIELD job_code 

			BEFORE FIELD resp_code 
				NEXT FIELD job_code 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wj307 
		RETURN false 
	END IF 

	LET fv_idx = arr_curr() 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW wj307 
	RETURN true 

END FUNCTION 

FUNCTION invoice_job( fv_job_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE fv_job_code LIKE job.job_code, 
	pv_comp_per LIKE job.est_comp_per, 
	fr_job RECORD LIKE job.*, 
	pv_resp CHAR(1), 
	pr_exit SMALLINT 


	SELECT * 
	INTO fr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 

	IF status != 0 THEN 
		#ERROR "Could NOT access Job information" ATTRIBUTE(red,reverse)
		LET msgresp = kandoomsg("J",9564," ") 
		RETURN false 
	END IF 

	LET pv_comp_per = 100 
	OPEN WINDOW wj308 with FORM "J308" -- alch kd-747 
	CALL winDecoration_j("J308") -- alch kd-747 
	WHILE pv_comp_per = 100 

		LET pv_comp_per = fr_job.est_comp_per 

		INPUT pv_comp_per WITHOUT DEFAULTS FROM est_comp_per 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J38a","input-pv_comp_per-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

		END INPUT 

		IF pv_comp_per > 100 THEN 
			LET pv_comp_per = 100 
		END IF 

		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW wj308 
			RETURN false 
		END IF 

		IF pv_comp_per = 100 THEN 
			LET pv_resp = kandoomsg("J",1528," ") 
			#prompt "Is the Job Complete (Y/N)" FOR CHAR pv_resp
			IF int_flag THEN 
				LET int_flag = false 
				LET pv_resp = "N" 
			END IF 
			LET pv_resp = upshift(pv_resp) 
			IF pv_resp = "Y" THEN 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW wj308 

	IF pv_comp_per = 100 THEN 
		IF fr_job.bill_way_ind = "F" THEN 
			UPDATE job SET act_end_date = today, 
			finish_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = fv_job_code 

			UPDATE activity SET act_end_date = today, 
			finish_flag = "Y" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = fv_job_code 

			#PROMPT "Job Closed - Hit ENTER key TO continue" FOR pv_resp
			LET msgresp = kandoomsg("J",1529," ") 

			LET pv_resp = "N" 

		ELSE 

			IF no_outstand_invs( fv_job_code ) THEN 

				UPDATE job SET act_end_date = today, 
				finish_flag = "Y" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = fv_job_code 

				UPDATE activity SET act_end_date = today, 
				finish_flag = "Y" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = fv_job_code 

				#PROMPT "Job Closed - Hit ENTER key TO continue" FOR pv_resp
				LET msgresp = kandoomsg("J",1529," ") 

				LET pv_resp = "N" 

			ELSE 
				#ERROR "Invoices are outstanding - cannot complete Job"
				#    ATTRIBUTE(reverse,red)
				LET msgresp = kandoomsg("J",9565," ") 
			END IF 
		END IF 
	END IF 

	UPDATE activity 
	SET est_comp_per = pv_comp_per 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 
	AND (est_comp_per < pv_comp_per OR est_comp_per IS NULL ) 

	UPDATE job 
	SET est_comp_per = pv_comp_per 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 
	AND (est_comp_per < pv_comp_per OR est_comp_per IS NULL ) 

	RETURN true 
END FUNCTION 



FUNCTION no_outstand_invs( fv_job_code ) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE fr_job RECORD LIKE job.*, 
	fr_purchdetl RECORD LIKE purchdetl.*, 
	fv_err_text CHAR(100), 
	fv_err_1 CHAR(10), 
	fv_err_2 CHAR(10), 
	fv_err_3 CHAR(20), 
	fv_job_code LIKE job.job_code, 
	fv_ok, 
	fv_reselect SMALLINT, 
	fv_ordered, 
	fv_received LIKE poaudit.order_qty 


	SELECT * 
	INTO fr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fv_job_code 

	IF status !=0 THEN 
		#ERROR "Job does NOT exist" ATTRIBUTE(reverse,red)
		LET msgresp = kandoomsg("J",9558," ") 
		RETURN false 
	END IF 

	# MESSAGE "Checking FOR outstanding purchase orders..."
	LET msgresp = kandoomsg("J",1530," ") 

	LET fv_ok = true 

	DECLARE cjob_pur CURSOR FOR 
	SELECT * 
	FROM purchdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = fr_job.job_code 

	FOREACH cjob_pur INTO fr_purchdetl.* 

		LET fv_ordered = 0 
		LET fv_received = 0 

		SELECT sum(order_qty),sum(received_qty) 
		INTO fv_ordered,fv_received 
		FROM poaudit 
		WHERE cmpy_code = fr_purchdetl.cmpy_code 
		AND po_num = fr_purchdetl.order_num 
		AND line_num = fr_purchdetl.line_num 

		IF fv_ordered > fv_received THEN 

			LET fv_err_text = "Purchase Order ", 
			fr_purchdetl.order_num USING "<<<<<<<&"," line # ", 
			fr_purchdetl.line_num USING "<<&"," IS NOT fully receipted" 

			LET fv_err_1 = kandooword("Purchase Order", "1") 
			LET fv_err_2 = kandooword("Line No.", "1") 
			LET fv_err_3 = kandooword("Not fully Receipted", "1") 
			LET fv_err_text = fv_err_1 clipped, 
			fr_purchdetl.order_num USING "<<<<<<<&", fv_err_2 clipped, 
			fr_purchdetl.line_num USING "<<&", fv_err_3 clipped 
			ERROR fv_err_text clipped attribute(reverse,red) 
			SLEEP 1 
			LET fv_ok = false 
			EXIT FOREACH 
		END IF 

	END FOREACH 

	RETURN fv_ok 

END FUNCTION 


