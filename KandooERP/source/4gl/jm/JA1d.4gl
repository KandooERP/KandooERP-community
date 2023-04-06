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
# \brief module - JA1d - Contract add
# Purpose - FUNCTION TO DISPLAY & enter detail lines.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 


FUNCTION add_dtl_lines() 

	DEFINE fv_return_flag SMALLINT, 
	fv_array_flag SMALLINT, 
	fv_x SMALLINT, 
	fv_count SMALLINT, 
	fv_job_cnt SMALLINT, 
	fv_ans CHAR(1), 
	fv_job_total LIKE contracthead.contract_value_amt, 
	fv_gen_total LIKE contracthead.contract_value_amt, 
	fv_orig_gen_tot LIKE contracthead.contract_value_amt, 
	formname CHAR(15) 

	LET fv_orig_gen_tot = 0 

	IF NOT pv_add THEN 
		DECLARE s_curs3 CURSOR FOR 
		SELECT * 
		FROM contractdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pr_contracthead.contract_code 
		ORDER BY line_num 

		LET idx = pv_dtllne_cnt 

		FOREACH s_curs3 INTO pr_contractdetl.* 
			LET idx = idx + 1 
			LET pa_details[idx].type_code = pr_contractdetl.type_code 
			LET pa_details[idx].desc_text = pr_contractdetl.desc_text 
			LET pa_contractdetl[idx].* = pr_contractdetl.* 

			IF pr_contractdetl.bill_qty IS NOT NULL AND 
			pr_contractdetl.bill_price IS NOT NULL THEN 
				LET fv_orig_gen_tot = fv_orig_gen_tot + 
				(pr_contractdetl.bill_price * pr_contractdetl.bill_qty) 
			END IF 
		END FOREACH 
	ELSE 
		LET idx = pv_dtllne_cnt 
	END IF 
	OPEN WINDOW wja02 with FORM "JA02" -- alch kd-747 
	CALL winDecoration_j("JA02") -- alch kd-747 
	LET msgresp = kandoomsg("A",1003,"") 
	# F1 TO add, F2 TO delete, RETURN on line TO edit

	CALL set_count(idx) 

	WHILE true 
		LET fv_array_flag = false 

		INPUT ARRAY pa_details WITHOUT DEFAULTS FROM sr_cont_dtls.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JA1d","input_arr-pa_details-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET arr_size = arr_count() 
				LET scrn = scr_line() 

			ON KEY (accept) 
				LET arr_size = arr_count() 
				LET pv_ship_count = 0 

				FOR fv_count = 1 TO arr_size 
					IF pa_contractdetl[fv_count].type_code IS NOT NULL AND 
					pa_contractdetl[fv_count].ship_code IS NULL THEN 
						LET pv_ship_count = pv_ship_count + 1 
					END IF 
				END FOR 

				IF pv_ship_count > 0 THEN 
					LET msgresp = kandoomsg("A",8100,pv_ship_count) 
					# x line(s) have no shipping code AND will be deleted
					# Do you still want TO EXIT (Y/N)?

					IF msgresp = "N" THEN 
						NEXT FIELD type_code 
					END IF 
				END IF 

				LET fv_count = 0 
				FOR fv_x = 1 TO arr_size 
					IF pa_contractdetl[fv_x].ship_code IS NOT NULL THEN 
						LET fv_count = fv_count + 1 
						LET pa_cntrdtl_copy[fv_count].* = 
						pa_contractdetl[fv_x].* 
						LET pa_detls_copy[fv_count].* = 
						pa_details[fv_x].* 
					END IF 
				END FOR 

				INITIALIZE pa_contractdetl TO NULL 
				INITIALIZE pa_details TO NULL 

				FOR fv_x = 1 TO fv_count 
					LET pa_contractdetl[fv_x].* = 
					pa_cntrdtl_copy[fv_x].* 
					LET pa_details[fv_x].* = pa_detls_copy[fv_x].* 
				END FOR 

				LET arr_size = fv_count 
				LET pv_dtllne_cnt = arr_size 
				EXIT INPUT 

			ON KEY (tab) 
				LET pa_details[idx].type_code = get_fldbuf(type_code) 

				CASE pa_details[idx].type_code 
					WHEN "J" 
						IF ent_job_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					WHEN "I" 
						IF ent_inv_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					WHEN "G" 
						IF ent_gen_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					OTHERWISE 
						LET msgresp = kandoomsg("A",3530,"") 
						# Invalid line type - use J, I OR G
						NEXT FIELD type_code 
				END CASE 
			ON KEY (RETURN) 
				LET pa_details[idx].type_code = get_fldbuf(type_code) 

				CASE pa_details[idx].type_code 
					WHEN "J" 
						IF ent_job_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					WHEN "I" 
						IF ent_inv_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					WHEN "G" 
						IF ent_gen_dtls() THEN 
							CALL disp_new_dtls() 
						ELSE 
							NEXT FIELD type_code 
						END IF 
					OTHERWISE 
						LET msgresp = kandoomsg("A",3530,"") 
						# Invalid line type - use J, I OR G
						NEXT FIELD type_code 
				END CASE 

			BEFORE FIELD desc_text 
				NEXT FIELD type_code 

			AFTER FIELD type_code 
				IF pa_details[idx].type_code IS NOT NULL AND 
				pa_details[idx].type_code NOT matches "[JIG]" THEN 
					LET msgresp = kandoomsg("A",3530,"") 
					# Invalid line type - use J, I OR G
					NEXT FIELD type_code 
				END IF 

			BEFORE DELETE 
				IF pa_details[idx].type_code IS NOT NULL THEN 
					LET msgresp = kandoomsg("A",3531,"") 
					# Confirmation TO delete detail line Y/N ?
					IF msgresp = "N" THEN 
						LET fv_array_flag = true 
						EXIT INPUT 
					END IF 
				END IF 

			AFTER DELETE 

				# ARRAY pa_contractdetl must be kept in sync with SCREEN
				# ARRAY WHEN a row IS deleted

				LET arr_size = arr_count() 
				FOR fv_x = idx TO arr_size 
					LET pa_contractdetl[fv_x].* = 
					pa_contractdetl[fv_x + 1].* 
				END FOR 
				INITIALIZE pa_contractdetl[fv_x].* TO NULL 

			BEFORE INSERT 
				# ARRAY pa_contractdetl must be kept in sync with SCREEN
				# ARRAY WHEN a row IS inserted

				LET arr_size = arr_count() 
				FOR fv_x = arr_size TO idx step -1 
					IF fv_x > idx THEN 
						LET pa_contractdetl[fv_x].* = 
						pa_contractdetl[fv_x -1].* 
					ELSE 
						INITIALIZE pa_contractdetl[idx].* TO NULL 
					END IF 
				END FOR 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF fv_array_flag THEN 
			CONTINUE WHILE 
		END IF 

		IF int_flag OR quit_flag THEN 
			INITIALIZE pa_contractdetl TO NULL 
			LET fv_return_flag = false 
			EXIT WHILE 
		END IF 

		# Calculate contract total

		LET pv_contract_total = 0 
		LET fv_gen_total = 0 
		LET fv_job_cnt = 0 

		FOR fv_x = 1 TO arr_size 
			IF pa_contractdetl[fv_x].type_code = "J" THEN 
				LET fv_job_cnt = fv_job_cnt + 1 
			END IF 

			IF pa_contractdetl[fv_x].bill_qty IS NOT NULL AND 
			pa_contractdetl[fv_x].bill_price IS NOT NULL THEN 
				LET fv_gen_total = fv_gen_total + 
				(pa_contractdetl[fv_x].bill_price * 
				pa_contractdetl[fv_x].bill_qty) 
			END IF 
		END FOR 
		OPEN WINDOW wja13 with FORM "JA13" -- alch kd-747 
		CALL winDecoration_j("JA13") -- alch kd-747 
		DISPLAY fv_gen_total TO gen_total 

		IF fv_job_cnt > 0 THEN 

			LET fv_job_total = pr_contracthead.contract_value_amt 
			- fv_orig_gen_tot 
			IF fv_job_total IS NULL THEN 
				LET fv_job_total = 0 
			END IF 

			LET pv_contract_total = fv_job_total + fv_gen_total 
			DISPLAY fv_job_total TO job_total 
			DISPLAY pv_contract_total TO contract_total 

			INPUT fv_job_total WITHOUT DEFAULTS FROM job_total 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","JA1d","input-fv_job_total-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				AFTER INPUT 
					IF fv_job_total IS NULL THEN 
						LET fv_job_total = 0 
						DISPLAY fv_job_total TO job_total 
					END IF 

				ON KEY (control-w) 
					CALL kandoohelp("") 

			END INPUT 

			LET pv_contract_total = fv_job_total + fv_gen_total 
			DISPLAY pv_contract_total TO contract_total 
		ELSE 
			LET fv_job_total = 0 
			LET pv_contract_total = fv_job_total + fv_gen_total 
			DISPLAY fv_job_total TO job_total 
			DISPLAY pv_contract_total TO contract_total 
		END IF 

		LET msgresp = kandoomsg("A",3540,"") 
		# Enter Y TO Accept, N TO Reject
		CLOSE WINDOW wja13 

		IF msgresp = "Y" THEN 
			#LET pr_contracthead.job_value_amt = fv_job_total
			LET fv_return_flag = true 
			EXIT WHILE 
		END IF 

		CALL set_count(arr_size) 
	END WHILE 

	CLOSE WINDOW wja02 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

	RETURN fv_return_flag 

END FUNCTION 


FUNCTION disp_new_dtls() 

	LET pa_contractdetl[idx].* = pr_contractdetl.* 
	LET pa_details[idx].type_code = pr_contractdetl.type_code 
	LET pa_details[idx].desc_text = pr_contractdetl.desc_text 

	DISPLAY pa_details[idx].* TO sr_cont_dtls[scrn].* 

	INITIALIZE pr_contractdetl.* TO NULL 

END FUNCTION 
