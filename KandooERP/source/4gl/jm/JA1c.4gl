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

	Source code beautified by beautify.pl on 2020-01-02 19:48:16	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JA1c - Contract add
# Purpose - FUNCTION TO calculate contract invoice dates - WHEN adding.
#           FUNCTION TO retrieve contract invoice dates - WHEN editing.
#           FUNCTION TO DISPLAY AND edit contract invoice dates.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 



FUNCTION calc_inv_dates() 

	DEFINE fa_days array[12] OF SMALLINT, 
	fv_units SMALLINT, 
	fv_save_day SMALLINT, 
	fv_mnth SMALLINT, 
	fv_inv_date LIKE contracthead.start_date 

	# first fill ARRAY with days in months FOR the year
	LET fa_days[1] = 31 
	LET fa_days[2] = 28 
	LET fa_days[3] = 31 
	LET fa_days[4] = 30 
	LET fa_days[5] = 31 
	LET fa_days[6] = 30 
	LET fa_days[7] = 31 
	LET fa_days[8] = 31 
	LET fa_days[9] = 30 
	LET fa_days[10] = 31 
	LET fa_days[11] = 30 
	LET fa_days[12] = 31 

	LET fv_units = 1 * pr_contracthead.bill_int_ind 
	LET fv_inv_date = pr_contracthead.start_date 
	LET fv_save_day = day(fv_inv_date) 






	IF pr_contracthead.bill_type_code = "E" THEN 
		LET fv_inv_date = mdy(month(fv_inv_date), "28", 
		year(fv_inv_date)) 

		IF month(fv_inv_date) = 2 THEN 
			IF check_leap_year(fv_inv_date) THEN 
				LET fv_inv_date = mdy(month(fv_inv_date), "29", 
				year(fv_inv_date)) 
			END IF 
		ELSE 
			LET fv_mnth = month(fv_inv_date) 
			LET fv_inv_date = mdy(month(fv_inv_date), 
			fa_days[fv_mnth], 
			year(fv_inv_date)) 
		END IF 
	END IF 

	# DEFAULT THE FIRST INVOICE DATE AS THE STARTING DATE
	LET idx = 1 
	LET pa_dates[idx].invoice_date = fv_inv_date 
	LET pa_dates[idx].inv_num = NULL 
	LET pa_contractdate[idx].invoice_date = fv_inv_date 
	LET pa_contractdate[idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pa_contractdate[idx].contract_code = pr_contracthead.contract_code 

	WHILE true 


		CASE 
			WHEN pr_contracthead.bill_type_code = "D" 
				LET fv_inv_date = fv_inv_date + fv_units units day 

			WHEN pr_contracthead.bill_type_code = "W" 
				LET fv_inv_date = fv_inv_date + (fv_units * 7) units day 

			WHEN pr_contracthead.bill_type_code = "M" 
				LET fv_inv_date = mdy(month(fv_inv_date),"28",year(fv_inv_date)) 
				LET fv_inv_date = fv_inv_date + fv_units units month 

				IF month(fv_inv_date) = 2 AND 
				fv_save_day > 28 THEN 
					IF check_leap_year(fv_inv_date) THEN 
						LET fv_inv_date = mdy(month(fv_inv_date), "29", 
						year(fv_inv_date)) 
					ELSE 
						LET fv_inv_date = mdy(month(fv_inv_date), "28", 
						year(fv_inv_date)) 
					END IF 
				ELSE 
					LET fv_inv_date = mdy(month(fv_inv_date), fv_save_day, 
					year(fv_inv_date)) 
				END IF 

			WHEN pr_contracthead.bill_type_code = "E" 
				LET fv_inv_date = mdy(month(fv_inv_date), "28", 
				year(fv_inv_date)) 
				LET fv_inv_date = fv_inv_date + fv_units units month 

				IF month(fv_inv_date) = 2 THEN 
					IF check_leap_year(fv_inv_date) THEN 
						LET fv_inv_date = mdy(month(fv_inv_date), "29", 
						year(fv_inv_date)) 
					END IF 
				ELSE 
					LET fv_mnth = month(fv_inv_date) 
					LET fv_inv_date = mdy(month(fv_inv_date), 
					fa_days[fv_mnth], 
					year(fv_inv_date)) 
				END IF 

			WHEN pr_contracthead.bill_type_code = "A" 
				LET fv_inv_date = fv_inv_date + fv_units units year 

		END CASE 

		IF fv_inv_date > pr_contracthead.end_date THEN 

			EXIT WHILE 
		END IF 

		LET idx = idx + 1 
		LET pa_dates[idx].invoice_date = fv_inv_date 
		LET pa_dates[idx].inv_num = NULL 
		LET pa_contractdate[idx].invoice_date = fv_inv_date 
		LET pa_contractdate[idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pa_contractdate[idx].contract_code = pr_contracthead.contract_code 




	END WHILE 

END FUNCTION 



FUNCTION check_leap_year(fv_date) 

	DEFINE fv_work_dec DECIMAL(5,2), 
	fv_work_char6 CHAR(6), 
	fv_check_leap_year SMALLINT, 
	fv_date DATE 

	LET fv_work_dec = year(fv_date) / 4 
	LET fv_work_char6 = fv_work_dec 
	LET fv_check_leap_year = fv_work_char6[5,6] 

	IF fv_check_leap_year = 0 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 


FUNCTION get_inv_dates() 

	DECLARE s_curs2 CURSOR FOR 
	SELECT * 
	FROM contractdate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND contract_code = pr_contracthead.contract_code 
	ORDER BY invoice_date 

	LET idx = 0 
	FOREACH s_curs2 INTO pr_contractdate.* 
		LET idx = idx + 1 
		LET pa_dates[idx].invoice_date = pr_contractdate.invoice_date 

		IF pr_contractdate.inv_num = 0 THEN 
			LET pa_dates[idx].inv_num = NULL 
		ELSE 
			LET pa_dates[idx].inv_num = pr_contractdate.inv_num 
		END IF 

		LET pa_dates[idx].invoice_total_amt = pr_contractdate.invoice_total_amt 

		SELECT inv_ind 
		INTO pa_dates[idx].inv_ind 
		FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = pr_contractdate.inv_num 

		CASE pa_dates[idx].inv_ind 
			WHEN "D" 
				LET pa_dates[idx].inv_ind = "Contrac" 

			WHEN "3" 
				LET pa_dates[idx].inv_ind = TRAN_TYPE_JOB_JOB 

			WHEN "1" 
				LET pa_dates[idx].inv_ind = "Gen/Inv" 

			OTHERWISE 
				LET pa_dates[idx].inv_ind = NULL 
		END CASE 

		LET pa_contractdate[idx].* = pr_contractdate.* 

	END FOREACH 

END FUNCTION 



FUNCTION disp_inv_dates() 

	DEFINE fv_array_flag SMALLINT, 
	fv_return_flag SMALLINT, 
	fv_err SMALLINT, 
	fv_x SMALLINT 
	OPEN WINDOW wja01 with FORM "JA01" -- alch kd-747 
	CALL winDecoration_j("JA01") -- alch kd-747 
	LET msgresp = kandoomsg("A",1008,"") 
	# Esc TO Continue, Del TO Exit
	CALL set_count(idx) 
	LET fv_array_flag = true 
	WHILE fv_array_flag 

		INPUT ARRAY pa_dates WITHOUT DEFAULTS FROM sr_cont_dates.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JA1c","input_arr-pa_dates-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET arr_size = arr_count() 
				LET ps_dates[idx].* = pa_dates[idx].* 

			ON KEY (accept) 
				LET fv_array_flag = false 
				LET pv_invdte_cnt = arr_count() 
				LET fv_return_flag = true 
				EXIT INPUT 

			BEFORE FIELD invoice_total_amt 
				NEXT FIELD invoice_date 

			AFTER FIELD invoice_date 
				IF pa_dates[idx].invoice_date IS NOT NULL THEN 
					IF (pa_dates[idx].invoice_date != 
					ps_dates[idx].invoice_date) OR 
					(ps_dates[idx].invoice_date IS null) 
					THEN 
						IF (pr_contracthead.last_billed_date IS NOT NULL AND 
						pa_dates[idx].invoice_date <= 
						pr_contracthead.last_billed_date) OR 
						(pa_dates[idx].invoice_total_amt IS NOT null) 
						THEN 
							LET msgresp = kandoomsg("A",3527,"") 
							# Invoices have already been issued
							LET pa_dates[idx].* = ps_dates[idx].* 
							NEXT FIELD invoice_date 
						END IF 

						IF (pa_dates[idx].invoice_date < 
						pr_contracthead.start_date) OR 
						(pa_dates[idx].invoice_date > 
						pr_contracthead.end_date) 
						THEN 
							LET msgresp = kandoomsg("A",3539,"") 
							# Invoice date must be within Contract start
							# AND END dates
							NEXT FIELD invoice_date 
						END IF 

						LET fv_err = false 
						LET fv_x = 0 
						FOR fv_x = 1 TO arr_size 
							IF fv_x != idx THEN 
								IF pa_dates[fv_x].invoice_date = 
								pa_dates[idx].invoice_date THEN 
									LET msgresp = kandoomsg("A",3528,"") 
									# An invoice has already been scheduled
									# FOR this date
									LET fv_err = true 
									EXIT FOR 
								END IF 
							END IF 
						END FOR 
						IF fv_err THEN 
							NEXT FIELD invoice_date 
						END IF 
						LET pa_contractdate[idx].invoice_date = 
						pa_dates[idx].invoice_date 
					END IF 
				END IF 


			BEFORE DELETE 
				IF pr_contracthead.last_billed_date IS NOT NULL AND 
				pa_dates[idx].invoice_date <= 
				pr_contracthead.last_billed_date THEN 
					LET msgresp = kandoomsg("A",3527,"") 
					# Invoices have already been issued up TO this date
					EXIT INPUT 
				END IF 
				IF pa_dates[idx].invoice_total_amt IS NOT NULL AND 
				pa_dates[idx].invoice_total_amt != 0 THEN 
					LET msgresp = kandoomsg("A",3529,"") 
					# Invoice has already been issued - cannot be zapped
					EXIT INPUT 
				END IF 

			AFTER DELETE 
				# ARRAY pa_contractdate must be kept in sync with SCREEN
				# ARRAY WHEN a row IS deleted

				LET fv_x = 0 
				LET arr_size = arr_count() 
				FOR fv_x = idx TO arr_size 
					LET pa_contractdate[fv_x].inv_num = 
					pa_contractdate[fv_x + 1].inv_num 
					LET pa_contractdate[fv_x].invoice_date = 
					pa_dates[fv_x].invoice_date 
					LET pa_contractdate[fv_x].invoice_total_amt = 
					pa_dates[fv_x].invoice_total_amt 
				END FOR 
				INITIALIZE pa_contractdate[fv_x + 1].* TO NULL 

			AFTER INSERT 
				# ARRAY pa_contractdate must be kept in sync with SCREEN
				# ARRAY WHEN a row IS inserted

				LET fv_x = 0 
				LET arr_size = arr_count() 
				FOR fv_x = arr_size TO idx step -1 
					IF fv_x > idx THEN 
						LET pa_contractdate[fv_x].inv_num = 
						pa_contractdate[fv_x -1].inv_num 
					END IF 
					LET pa_contractdate[fv_x].invoice_date = 
					pa_dates[fv_x].invoice_date 
					LET pa_contractdate[fv_x].invoice_total_amt = 
					pa_dates[fv_x].invoice_total_amt 
				END FOR 

			AFTER INPUT 
				LET fv_array_flag = false 
				IF int_flag OR quit_flag THEN 
					LET pv_invdte_cnt = 0 
					LET fv_return_flag = false 
				ELSE 
					LET pv_invdte_cnt = arr_count() 
					LET fv_return_flag = true 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	END WHILE 

	CLOSE WINDOW wja01 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

	RETURN fv_return_flag 

END FUNCTION 
