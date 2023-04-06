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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K47 allows the user TO Scan Customers credits FOR edit

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 


FUNCTION cred_select() 
	DEFINE 
	pa_credithead array[250] OF RECORD 
		cred_num LIKE credithead.cred_num, 
		cred_text LIKE credithead.cred_text, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD, 
	sel_ok SMALLINT, 
	pt_credithead RECORD LIKE credithead.* 


	OPEN WINDOW wa122 
	at 2,3 WITH FORM "A122" 
	attribute(border, white, MESSAGE line first) 

	LABEL cust_attempt: 
	LET sel_ok = 0 
	INPUT BY NAME pt_credithead.cust_code, 
	pt_credithead.cred_num 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (cust_code) 
					LET pt_credithead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pt_credithead.cust_code 

					NEXT FIELD cust_code 
			END CASE 

		BEFORE FIELD cust_code 

			IF display_cred_num = "Y" THEN 
				MESSAGE "Successful edit of credit note number", temp_cred_num 
				attribute(yellow) 
				LET display_cred_num = "N" 
			ELSE 
			MESSAGE " Enter Customer Code FOR beginning of scan" 
			attribute (yellow) 
		END IF 

		AFTER FIELD cust_code 

			SELECT * 
			INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pt_credithead.cust_code 

			IF status = notfound 
			THEN 
				ERROR "Customer NOT found, try window" 
				NEXT FIELD cust_code 
			END IF 

			DISPLAY BY NAME pr_customer.name_text, 
			pr_customer.currency_code 
			attribute (green) 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET ans = "N" 
		CLOSE WINDOW wa122 
		RETURN 
	END IF 
	IF pt_credithead.cred_num IS NULL 
	THEN 
		LET pt_credithead.cred_num = 0 
	END IF 

	DECLARE c_cust CURSOR FOR 
	SELECT * 
	INTO pr_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pt_credithead.cust_code 
	AND cred_num >= pt_credithead.cred_num 
	AND cred_ind = "7" 
	ORDER BY cred_num 

	LET idx = 0 
	FOREACH c_cust 
		LET idx = idx + 1 
		LET pa_credithead[idx].cred_num = pr_credithead.cred_num 
		LET pa_credithead[idx].cred_text = pr_credithead.cred_text 
		LET pa_credithead[idx].cred_date = pr_credithead.cred_date 
		LET pa_credithead[idx].year_num = pr_credithead.year_num 
		LET pa_credithead[idx].period_num = pr_credithead.period_num 
		LET pa_credithead[idx].total_amt = pr_credithead.total_amt 
		LET pa_credithead[idx].appl_amt = pr_credithead.appl_amt 
		LET pa_credithead[idx].posted_flag = pr_credithead.posted_flag 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 
	THEN 
		MESSAGE " No credits found FOR customer " 
		attribute(yellow) 
		SLEEP 3 
		GOTO cust_attempt 
	END IF 
	CALL set_count (idx) 

	MESSAGE "" 
	MESSAGE " RETURN on line TO edit credit" 
	attribute (yellow) 

	INPUT ARRAY pa_credithead WITHOUT DEFAULTS FROM sr_credithead.* 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_credithead.cred_num = pa_credithead[idx].cred_num 
			LET pr_credithead.cred_text = pa_credithead[idx].cred_text 
			LET pr_credithead.cred_date = pa_credithead[idx].cred_date 
			LET pr_credithead.year_num = pa_credithead[idx].year_num 
			LET pr_credithead.period_num = pa_credithead[idx].period_num 
			LET pr_credithead.total_amt = pa_credithead[idx].total_amt 
			LET pr_credithead.appl_amt = pa_credithead[idx].appl_amt 
			LET pr_credithead.posted_flag = pa_credithead[idx].posted_flag 
			LET id_flag = 0 
			IF idx > arr_count() THEN 
				ERROR "There are no more credits in the direction you are going" 
			END IF 
		BEFORE FIELD cred_text 
			SELECT * 
			INTO pr_credithead.* 
			FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pt_credithead.cust_code 
			AND cred_num = pa_credithead[idx].cred_num 
			IF (status = notfound) 
			THEN 
				ERROR "Sorry cannot find this customers credit" 
				SLEEP 3 
				NEXT FIELD cred_num 
			END IF 
			IF pr_credithead.posted_flag = "Y" 
			THEN 
				ERROR "Sorry cannot edit posted credits - raise invoice instead" 
				SLEEP 4 
				NEXT FIELD cred_num 
			END IF 
			SELECT * 
			INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_credithead.cust_code 
			IF (status = notfound) 
			THEN 
				ERROR "Customer missing on live credit" 
				CALL errorlog("A57a - customer missing on live credit") 
				SLEEP 5 
				LET goon = "N" 
				RETURN 
			END IF 
			LET sel_ok = 1 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET ans = "N" 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 
	IF sel_ok != 1 
	THEN 
		GOTO cust_attempt 
	END IF 
	LET first_time = 1 
	CLOSE WINDOW wa122 
END FUNCTION 
