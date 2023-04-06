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

	Source code beautified by beautify.pl on 2020-01-02 19:48:19	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module VA7 (JA7 !!!) Contract Invoice Adjustments
#  The contract invoice register can be altered (add/delete rows)
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_tentinvhead RECORD LIKE tentinvhead.*, 
	ps_tentinvhead RECORD LIKE tentinvhead.*, 
	pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_desc_text LIKE contracthead.desc_text, 
	pa_tentinvhead array[1500] OF RECORD 
		line_ind CHAR(1), 
		inv_num LIKE tentinvhead.inv_num, 
		contract_code LIKE tentinvhead.contract_code, 
		desc_text LIKE contracthead.desc_text, 
		total_amt LIKE tentinvhead.total_amt 
	END RECORD, 
	pa_tentinvdetl array[500] OF RECORD 
		inv_num LIKE tentinvdetl.inv_num, 
		contract_code LIKE tentinvhead.contract_code, 
		line_total_amt LIKE tentinvdetl.line_total_amt 
	END RECORD, 
	run_total_amt DECIMAL(14,2), 
	didx, 
	idx, 
	scrn SMALLINT, 
	cnt SMALLINT, 
	runner CHAR(100), 
	func_type CHAR(15), 
	pv_delete_flag CHAR(1), 
	pv_insert_flag CHAR(1) 

END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("JA7") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW ja11 with FORM "JA11" -- alch kd-747 
	CALL winDecoration_j("JA11") -- alch kd-747 
	WHILE get_info() 
	END WHILE 
	CLOSE WINDOW ja11 
END MAIN 



FUNCTION get_info() 
	DEFINE 
	cnt SMALLINT, 
	query_text CHAR(1000), 
	where_text CHAR(500) 

	CLEAR FORM 
	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON 
	tentinvhead.inv_num, 
	tentinvhead.contract_code, 
	contracthead.desc_text, 
	tentinvhead.total_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA7","const-inv_num-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET query_text = "SELECT tentinvhead.inv_num, ", 
	"tentinvhead.contract_code, ", 
	"contracthead.desc_text, ", 
	"tentinvhead.total_amt ", 
	"FROM tentinvhead, ", 
	"contracthead ", 
	"WHERE contracthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND contracthead.cmpy_code = tentinvhead.cmpy_code ", 
	"AND tentinvhead.contract_code = contracthead.contract_code ", 
	"AND ",where_text clipped," ", 
	"ORDER BY tentinvhead.contract_code,", 
	"tentinvhead.inv_num, ", 
	"contracthead.desc_text " 

	PREPARE s_tent FROM query_text 
	DECLARE c_tent CURSOR FOR s_tent 

	LET idx = 0 
	LET run_total_amt = 0 

	FOREACH c_tent INTO pr_tentinvhead.inv_num, 
		pr_tentinvhead.contract_code, 
		pr_contracthead.desc_text, 
		pr_tentinvhead.total_amt 

		LET idx = idx + 1 

		IF idx > 1500 THEN 
			LET msgresp = kandoomsg("A",9533,"") 
			# ERROR "Only first 1500 records selected"
			EXIT FOREACH 
		END IF 

		LET run_total_amt = run_total_amt + pr_tentinvhead.total_amt 
		LET pa_tentinvhead[idx].inv_num = pr_tentinvhead.inv_num 
		LET pa_tentinvhead[idx].contract_code = pr_tentinvhead.contract_code 
		LET pa_tentinvhead[idx].desc_text = pr_contracthead.desc_text 
		LET pa_tentinvhead[idx].total_amt = pr_tentinvhead.total_amt 
	END FOREACH 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("A",9534,"") 
		# ERROR "No tentative invoices were selected"
		RETURN true 
	END IF 

	CALL set_count(idx) 

	WHILE true 
		LET pv_delete_flag = true 
		LET pv_insert_flag = false 


		LET msgresp = kandoomsg("U",1003,"") 
		# MESSAGE "F1 TO Add, F2 TO Delete, RETURN TO view - DEL TO Exit"

		INPUT ARRAY pa_tentinvhead WITHOUT DEFAULTS FROM sr_contracthead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","JA7","input_arr-pa_tentinvhead-1") -- alch kd-506 

			BEFORE ROW 
				LET scrn = scr_line() 
				LET idx = arr_curr() 
				LET pr_tentinvhead.inv_num = pa_tentinvhead[idx].inv_num 
				LET pr_tentinvhead.contract_code = pa_tentinvhead[idx].contract_code 
				LET pr_contracthead.desc_text = pa_tentinvhead[idx].desc_text 
				LET pr_tentinvhead.total_amt = pa_tentinvhead[idx].total_amt 
				DISPLAY BY NAME run_total_amt 

				IF pa_tentinvhead[idx].contract_code IS NULL THEN 
					LET pv_insert_flag = true 
				END IF 

			ON KEY (RETURN) 
				IF pa_tentinvhead[idx].contract_code IS NULL THEN 
					LET msgresp = kandoomsg("A",3546,"") 
					# ERROR "A Contract code must be entered"
				ELSE 
					CALL display_detail() 
				END IF 

			BEFORE FIELD line_ind 
				NEXT FIELD contract_code 

			BEFORE FIELD inv_num 
				NEXT FIELD contract_code 

			AFTER FIELD contract_code 
				IF pa_tentinvhead[idx].inv_num IS NOT NULL AND 
				(pr_tentinvhead.contract_code != 
				pa_tentinvhead[idx].contract_code OR 
				pa_tentinvhead[idx].contract_code IS null) THEN 
					LET msgresp = kandoomsg("A",9537,"") 
					# ERROR "This line cannot be changed"
					LET pa_tentinvhead[idx].contract_code = 
					pr_tentinvhead.contract_code 
					DISPLAY BY NAME pa_tentinvhead[idx].contract_code 
					NEXT FIELD contract_code 
				END IF 

				IF pa_tentinvhead[idx].contract_code IS NULL THEN 
					IF idx = arr_count() AND 
					fgl_lastkey() = fgl_keyval("up") THEN 
						LET pv_insert_flag = false 
					ELSE 
						LET msgresp = kandoomsg("A",3546,"") 
						# ERROR "A Contract code must be entered"
						NEXT FIELD contract_code 
					END IF 
				ELSE 
					SELECT * 
					FROM contracthead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pa_tentinvhead[idx].contract_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("A",9536,"") 
						# ERROR "Contract code does NOT exist"
						LET pr_tentinvhead.contract_code = 
						pa_tentinvhead[idx].contract_code 
						NEXT FIELD contract_code 
					END IF 

					IF pr_tentinvhead.contract_code != 
					pa_tentinvhead[idx].contract_code AND 
					pa_tentinvhead[idx].inv_num IS NULL THEN 
						LET pv_insert_flag = true 
					END IF 

					LET cnt = 0 

					IF pv_insert_flag THEN 
						SELECT count(*) 
						INTO cnt 
						FROM tentinvhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND contract_code = pa_tentinvhead[idx].contract_code 

						IF cnt > 0 THEN 
							LET msgresp = kandoomsg("A",9538,"") 
							# ERROR "There IS already a tentative invoice FOR this
							#        contract"
							LET pv_insert_flag = false 
							LET pr_tentinvhead.contract_code = 
							pa_tentinvhead[idx].contract_code 
							NEXT FIELD contract_code 
						ELSE 

							CALL run_prog("JA6", 
							pa_tentinvhead[idx].contract_code, 
							"","","") 
							SELECT * 
							FROM tentinvhead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND contract_code = 
							pa_tentinvhead[idx].contract_code 

							IF status = notfound THEN 
								LET msgresp = kandoomsg("A",9529,"") 
								# ERROR "No tentative invoices were created"
								LET pv_insert_flag = false 
								LET pr_tentinvhead.contract_code = 
								pa_tentinvhead[idx].contract_code 
								NEXT FIELD contract_code 
							ELSE 
								LET pv_delete_flag = false 
								LET pv_insert_flag = false 
								EXIT INPUT 
							END IF 
						END IF 
					ELSE 
						IF idx = arr_count() AND 
						pa_tentinvhead[idx].inv_num IS NULL AND 
						fgl_keyval("down") = fgl_lastkey() THEN 
							NEXT FIELD contract_code 
						END IF 
					END IF 
				END IF 

			BEFORE FIELD desc_text 
				NEXT FIELD contract_code 

			BEFORE DELETE 
				LET msgresp = kandoomsg("G",9601,"") 
				# prompt "Are you sure?"

				IF msgresp = "Y" THEN 
					LET run_total_amt = run_total_amt - pa_tentinvhead[idx].total_amt 

					DELETE FROM tentinvhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					inv_num = pa_tentinvhead[idx].inv_num AND 
					contract_code = pa_tentinvhead[idx].contract_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("A",9535,"") 
						# ERROR "Cannot find tentative invoice header"
					ELSE 
						DELETE FROM tentinvdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						inv_num = pa_tentinvhead[idx].inv_num 
					END IF 

					DISPLAY BY NAME run_total_amt 


					LET msgresp = kandoomsg("U",1003,"") 
					# MESSAGE "F1 TO Add, F2 TO Delete, RETURN TO view - DEL TO Exit"
				ELSE 
					LET pv_delete_flag = false 
					EXIT INPUT 
				END IF 

			BEFORE INSERT 
				INITIALIZE pa_tentinvhead[idx].contract_code TO NULL 
				LET pv_insert_flag = true 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF pv_delete_flag = true THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN true 
		END IF 

	END WHILE 

END FUNCTION 




FUNCTION display_detail() 

	DEFINE fv_org_name_text LIKE customer.name_text, 
	fv_sp_name_text LIKE salesperson.name_text 
	OPEN WINDOW wa192 with FORM "A192" -- alch kd-747 
	CALL winDecoration_a("A192") -- alch kd-747 
	SELECT * 
	INTO ps_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pa_tentinvhead[idx].inv_num 

	DISPLAY BY NAME ps_tentinvhead.cust_code, 
	ps_tentinvhead.name_text, 
	ps_tentinvhead.org_cust_code, 
	ps_tentinvhead.inv_num, 
	ps_tentinvhead.ord_num, 
	ps_tentinvhead.currency_code, 
	ps_tentinvhead.goods_amt, 
	ps_tentinvhead.tax_amt, 
	ps_tentinvhead.hand_amt, 
	ps_tentinvhead.freight_amt, 
	ps_tentinvhead.total_amt, 
	ps_tentinvhead.paid_amt, 
	ps_tentinvhead.inv_date, 
	ps_tentinvhead.due_date, 
	ps_tentinvhead.disc_date, 
	ps_tentinvhead.paid_date, 
	ps_tentinvhead.disc_amt, 
	ps_tentinvhead.disc_taken_amt, 
	ps_tentinvhead.year_num, 
	ps_tentinvhead.period_num, 
	ps_tentinvhead.posted_flag, 
	ps_tentinvhead.entry_code, 
	ps_tentinvhead.entry_date, 
	ps_tentinvhead.sale_code, 
	ps_tentinvhead.inv_ind, 
	ps_tentinvhead.job_code, 
	ps_tentinvhead.com1_text, 
	ps_tentinvhead.com2_text, 
	ps_tentinvhead.on_state_flag, 
	ps_tentinvhead.rev_date, 
	ps_tentinvhead.rev_num 


	IF ps_tentinvhead.org_cust_code IS NOT NULL THEN 
		SELECT name_text 
		INTO fv_org_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = ps_tentinvhead.org_cust_code 

		DISPLAY fv_org_name_text TO org_name_text 

	END IF 

	IF ps_tentinvhead.paid_date != "31/12/1899" THEN 
		DISPLAY BY NAME ps_tentinvhead.paid_date 

	END IF 

	SELECT name_text 
	INTO fv_sp_name_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = ps_tentinvhead.sale_code 
	DISPLAY fv_sp_name_text TO salesperson.name_text 
	MENU "Invoice" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA7","menu-invoice-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND KEY ("D",f20) "Detail" "View invoice details" 
			IF ps_tentinvhead.inv_ind = "3" THEN 
				CALL tnjmlineshow(glob_rec_kandoouser.cmpy_code, 
				ps_tentinvhead.cust_code, 
				ps_tentinvhead.inv_num, 
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
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 

	CLOSE WINDOW wa192 

END FUNCTION 



FUNCTION ar_detail_menu() 

	DEFINE 
	pr_option CHAR(1) 
	OPEN WINDOW wva15 with FORM "JA15" -- alch kd-747 
	CALL winDecoration_j("JA15") -- alch kd-747 
	DISPLAY BY NAME ps_tentinvhead.inv_num, 
	ps_tentinvhead.name_text 

	INPUT BY NAME pr_option WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA7","input-pr_option-1") -- alch kd-506 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 

			CASE pr_option 
				WHEN "1" 
					CALL tnarlineshow(glob_rec_kandoouser.cmpy_code, 
					ps_tentinvhead.cust_code, 
					ps_tentinvhead.inv_num, 
					"View Invoice") 
					NEXT FIELD pr_option 

				WHEN "2" 
					CALL show_inv_entry(glob_rec_kandoouser.cmpy_code, 
					ps_tentinvhead.inv_num) 
					NEXT FIELD pr_option 

				WHEN "3" 
					CALL show_inv_ship(glob_rec_kandoouser.cmpy_code, 
					ps_tentinvhead.inv_num) 
					NEXT FIELD pr_option 

				WHEN "C" 
					IF change_invoice() THEN 
						DISPLAY BY NAME ps_tentinvhead.inv_num, 
						ps_tentinvhead.name_text 
					END IF 
					NEXT FIELD pr_option 

				WHEN "E" 
					EXIT CASE 

				OTHERWISE 
					NEXT FIELD pr_option 
			END CASE 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wva15 

END FUNCTION 



FUNCTION change_invoice() 

	LET msgresp = kandoomsg("A",9524,"") 
	# MESSAGE "Enter new invoice number"

	INPUT BY NAME ps_tentinvhead.inv_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA7","input-ps_tentinvhead-1") -- alch kd-506 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			SELECT cust_code, name_text 
			INTO ps_tentinvhead.cust_code, ps_tentinvhead.name_text 
			FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = ps_tentinvhead.inv_num 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9524,"") 
				# ERROR "Invoice number invalid"
				NEXT FIELD inv_num 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	MESSAGE "" 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
