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

	Source code beautified by beautify.pl on 2020-01-03 10:36:53	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 


# Purpose : Fixed Asset Master Details Addition/Enquiry

GLOBALS 
	DEFINE 
	famast_trn RECORD LIKE famast.*, 
	ans CHAR(1), 
	counter SMALLINT, 
	where_text CHAR(600), 
	query_text CHAR(700), 
	not_found SMALLINT, 
	exist SMALLINT, 
	auto_flag SMALLINT, 
	try_again CHAR(1), 
	err_message CHAR(60), 
	add_success_flag SMALLINT, 
	pr_vendor RECORD LIKE vendor.*, 
	display_asset LIKE famast.asset_code, 
	array_rec array[300] OF RECORD 
		asset_code LIKE famast.asset_code, 
		add_on_code LIKE famast.add_on_code, 
		desc_text LIKE famast.desc_text, 
		orig_setup_date LIKE famast.orig_setup_date 
	END RECORD, 
	runner CHAR(80) 

END GLOBALS 

MAIN 
	DEFINE 
	re_display_flag CHAR(1) 

	#Initial UI Init
	CALL setModuleId("F11") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPTIONS 
	MESSAGE line FIRST 
	#
	# WHILE Loop till they either SELECT an asset TO UPDATE, OR add one
	#
	LET re_display_flag = "N" 
	WHILE true 
		OPEN WINDOW w_f11 with FORM "F128" -- alch kd-757 
		CALL  windecoration_f("F128") -- alch kd-757 

		MESSAGE "Enter selection criteria - press ", 
		"ESC TO begin search" 

		#
		# Get the user selection by constructing
		#
		CONSTRUCT BY NAME query_text ON 
		famast.asset_code, 
		famast.add_on_code, 
		famast.desc_text, 
		famast.orig_setup_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F11","const-query_text-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		#
		# IF DEL pressed, EXIT PROGRAM
		#
		IF int_flag != 0 OR 
		quit_flag != 0 
		THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW w_f11 
			EXIT program 
		END IF 

		LET where_text = "SELECT * FROM famast WHERE ", 
		"cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" AND ", 
		query_text clipped, " ORDER BY asset_code, add_on_code" 

		PREPARE sql1 FROM where_text 
		DECLARE curs_qry CURSOR FOR sql1 

		CALL load_array() 
		IF not_found = 1 THEN 
			MESSAGE " No current assets - please add first asset" 
			SLEEP 2 
			CALL add_fn() 
			CALL load_array() 
		END IF 
		#
		# Now DISPLAY them AND choose either add, delete OR UPDATE
		#
		WHILE true 
			INITIALIZE famast_trn.* TO NULL 
			INITIALIZE pr_vendor.* TO NULL 
			DISPLAY ARRAY array_rec TO s_famast.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","F11","display-arr-famast") 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
				ON KEY (f9) 
					LET re_display_flag = "Y" 
					EXIT DISPLAY 
				ON KEY (f1) 
					LET add_success_flag = 0 
					CALL add_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (control-m) 
					LET counter = arr_curr() 
					SELECT * 
					INTO famast_trn.* 
					FROM famast 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = array_rec[counter].asset_code 
					AND add_on_code = array_rec[counter].add_on_code 
					CALL edit_fn() 
					CALL load_array() 
					EXIT DISPLAY 
				ON KEY (f2) 
					LET counter = arr_curr() 
					SELECT * 
					INTO famast_trn.* 
					FROM famast 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = array_rec[counter].asset_code 
					AND add_on_code = array_rec[counter].add_on_code 
					SELECT unique 1 
					FROM faaudit 
					WHERE asset_code = famast_trn.asset_code 
					AND add_on_code = famast_trn.add_on_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg('F',8000,famast_trn.asset_code) 
						#8000 Ok TO delete asset ?
						IF msgresp = 'Y' THEN 
							CALL delete_fn() 
							CALL load_array() 
						END IF 
					ELSE 
						ERROR "Asset transactions exist - delete NOT allowed" 
					END IF 
					EXIT DISPLAY 
				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END DISPLAY 

			IF int_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT WHILE 
			END IF 
			IF re_display_flag = "Y" THEN 
				LET re_display_flag = "N" 
				EXIT WHILE 
			END IF 
		END WHILE 

		CLOSE WINDOW w_f11 
	END WHILE 

END MAIN 

#--------------------------------------------------------------------------#

FUNCTION delete_fn() 
	#
	# this code IS here as a fail-safe - cause of original
	#          AR NOT adequately explained by use of F2 key (ie. too many assets
	#          deleted) so put this here TO trap any other means by which
	#          the delete could be triggered
	#
	DEFINE 
	pr_tran_count INTEGER 

	SELECT count(*) 
	INTO pr_tran_count 
	FROM faaudit 
	WHERE asset_code = famast_trn.asset_code 
	AND add_on_code = famast_trn.add_on_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_tran_count IS NULL THEN 
		LET pr_tran_count = 0 
	END IF 
	IF pr_tran_count > 0 THEN 
		ERROR "Asset transactions exist - delete NOT allowed" 
	ELSE 
		DELETE FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = famast_trn.asset_code 
		AND add_on_code = famast_trn.add_on_code 
	END IF 

END FUNCTION 

#--------------------------------------------------------------------------#

FUNCTION add_fn() 
	DEFINE end_flag SMALLINT, 
	cont_flag SMALLINT, 
	keep_on_flag CHAR(1), 
	field_no SMALLINT 

	OPEN WINDOW w_f111 with FORM "F129" -- alch kd-757 
	CALL  windecoration_f("F129") -- alch kd-757 
	MESSAGE 
	"Edit the data THEN press ESC OR press DEL TO EXIT" 

		LET keep_on_flag = "Y" 
		INITIALIZE famast_trn.* TO NULL 
		WHILE keep_on_flag = "Y" 
			LET keep_on_flag = "N" 
			WHILE true 
				IF add_success_flag = 1 
				THEN 
					MESSAGE "Asset ID: ", display_asset clipped, 
					" successfully added" 
				ELSE 
					MESSAGE "ESC enter data - DEL TO EXIT" 
				END IF 
				LET add_success_flag = 0 
				LET end_flag = 0 

				DISPLAY " " TO name_text 
				DISPLAY "" TO orig_cost_amt 
				INPUT BY NAME 
				#famast_trn.asset_code,
				famast_trn.desc_text, 
				famast_trn.faresp_code, 
				famast_trn.tag_text, 
				famast_trn.orig_setup_date, 
				famast_trn.asset_serial_text, 
				famast_trn.acquist_code, 
				famast_trn.acquist_date, 
				famast_trn.orig_po_num, 
				famast_trn.cgt_index_per, 
				famast_trn.vend_code, 
				famast_trn.currency_code, 
				famast_trn.orig_fcost_amt, 
				famast_trn.operate_date, 
				famast_trn.start_year_num, 
				famast_trn.start_period_num, 
				famast_trn.user1_code, 
				famast_trn.user1_amt, 
				famast_trn.user2_code, 
				famast_trn.user2_amt, 
				famast_trn.user3_code, 
				famast_trn.user3_amt, 
				famast_trn.user1_qty 
				WITHOUT DEFAULTS 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","F11","inp-famast-1") -- alch kd-504 
					ON ACTION "LOOKUP" infield(vend_code) #ON KEY (control-b) infield(vend_code) 
						LET famast_trn.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,famast_trn.vend_code) 
						DISPLAY BY NAME famast_trn.vend_code 


					ON ACTION "LOOKUP" infield(currency_code) #ON KEY (control-b) infield(currency_code) 
						LET famast_trn.currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME famast_trn.currency_code 


					ON ACTION "LOOKUP" infield (faresp_code) #ON KEY (control-b) infield (faresp_code) 
						LET famast_trn.faresp_code = lookup_resp(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME famast_trn.faresp_code 

						NEXT FIELD faresp_code 


					ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) infield(desc_text) 

						LET famast_trn.desc_text = 
						sys_noter(glob_rec_kandoouser.cmpy_code,famast_trn.desc_text) 
						DISPLAY famast_trn.desc_text TO 
						famast.desc_text 

						NEXT FIELD desc_text 



					AFTER FIELD faresp_code 
						IF famast_trn.faresp_code IS NULL THEN 
							ERROR "Responsibility code must be entered" 
							NEXT FIELD faresp_code 
						ELSE 
							SELECT * 
							FROM faresp 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND faresp_code = famast_trn.faresp_code 
							IF status THEN 
								ERROR "Responsibility code does NOT exist" 
								NEXT FIELD faresp_code 
							END IF 
						END IF 

					BEFORE FIELD orig_setup_date 
						LET famast_trn.orig_setup_date = today 
						DISPLAY BY NAME famast_trn.orig_setup_date 

					BEFORE FIELD operate_date 
						LET famast_trn.operate_date = today 
						DISPLAY BY NAME famast_trn.operate_date 

					BEFORE FIELD acquist_date 
						LET famast_trn.acquist_date = today 
						DISPLAY BY NAME famast_trn.acquist_date 


					AFTER FIELD operate_date 
						IF famast_trn.start_year_num IS NULL OR 
						famast_trn.start_period_num IS NULL THEN 
							CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,famast_trn.operate_date) 
							RETURNING famast_trn.start_year_num, 
							famast_trn.start_period_num 
							DISPLAY BY NAME famast_trn.start_year_num, 
							famast_trn.start_period_num 
						END IF 



					AFTER FIELD acquist_code 
						IF famast_trn.acquist_code IS NULL THEN 
							ERROR "Acquisition code must be entered" 
							NEXT FIELD acquist_code 
						ELSE 
							IF famast_trn.acquist_code NOT matches "[LP]" THEN 
								ERROR "Acquisition code must be L OR P" 
								NEXT FIELD acquist_code 
							END IF 
						END IF 
						LET field_no = 10 

					AFTER FIELD vend_code 
						IF famast_trn.vend_code IS NOT NULL THEN 
							IF val_vend() THEN 
								NEXT FIELD vend_code 
							ELSE 
								LET famast_trn.currency_code = pr_vendor.currency_code 
								DISPLAY BY NAME famast_trn.currency_code 

								DISPLAY BY NAME pr_vendor.name_text 
							END IF 
						END IF 

						IF famast_trn.orig_fcost_amt IS NOT NULL THEN 
							LET famast_trn.orig_cost_amt = 
							conv_currency(famast_trn.orig_fcost_amt, 

							glob_rec_kandoouser.cmpy_code, 
							famast_trn.currency_code, 
							"F", 
							famast_trn.orig_setup_date, 
							"B") 
							DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 
						END IF 
						LET field_no = 15 


					BEFORE FIELD currency_code 
						IF famast_trn.vend_code IS NOT NULL THEN 
							IF field_no > 20 THEN 
								NEXT FIELD vend_code 
							ELSE 
								NEXT FIELD orig_fcost_amt 
							END IF 
						END IF 


					AFTER FIELD currency_code 
						LET field_no = 30 
						IF famast_trn.currency_code IS NULL THEN 
							ERROR "Currency must be entered" 
							NEXT FIELD currency_code 
						ELSE 
							SELECT currency_code 
							FROM currency 
							WHERE currency_code = famast_trn.currency_code 
							IF status THEN 
								ERROR "Currency NOT found - try window" 
								NEXT FIELD currency_code 
							END IF 
						END IF 

						LET famast_trn.orig_cost_amt = 
						conv_currency(famast_trn.orig_fcost_amt, 

						glob_rec_kandoouser.cmpy_code, 
						famast_trn.currency_code, 
						"F", 
						famast_trn.orig_setup_date, 
						"B") 
						DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 


					AFTER FIELD orig_fcost_amt 
						LET field_no = 40 
						LET famast_trn.orig_cost_amt = 
						conv_currency(famast_trn.orig_fcost_amt, 

						glob_rec_kandoouser.cmpy_code, 
						famast_trn.currency_code, 
						"F", 
						famast_trn.orig_setup_date, 
						"B") 
						DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 

					ON KEY (control-w) 
						CALL kandoohelp("") 
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
				END INPUT 

				IF int_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					CALL confirm_cont(keep_on_flag) RETURNING keep_on_flag 
					EXIT WHILE 
				ELSE 
					IF keep_on_flag = "N" THEN 
						OPEN WINDOW wf154 with FORM "F154" -- alch kd-757 
						CALL  windecoration_f("F154") -- alch kd-757 
						INPUT BY NAME famast_trn.asset_code 
							BEFORE INPUT 
								CALL publish_toolbar("kandoo","F11","inp-famast_trn-1") -- alch kd-504 
							ON KEY (f7) 
								IF infield(asset_code) THEN 
									LET cont_flag = 0 
									CALL next_asset(cont_flag) RETURNING cont_flag 
									IF cont_flag = 1 THEN 
										EXIT INPUT 
									ELSE 
										DISPLAY BY NAME famast_trn.asset_code 
										EXIT INPUT 
									END IF 
								END IF 
							AFTER FIELD asset_code 
								IF val_asset() = 1 THEN 
									NEXT FIELD asset_code 
								END IF 
							ON KEY (control-w) 
								CALL kandoohelp("") 
							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
						END INPUT 
						IF int_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							CLOSE WINDOW wf154 
							EXIT WHILE 
						END IF 
						IF cont_flag = 1 THEN 
							CLOSE WINDOW wf154 
							CLOSE WINDOW w_f111 
							EXIT program 
						ELSE 
							LET famast_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
							GOTO bypass 
							LABEL recovery: 
							LET try_again = error_recover(err_message, status) 
							IF try_again != "Y" THEN 
								EXIT program 
							END IF 
							LABEL bypass: 
							WHENEVER ERROR GOTO recovery 

							BEGIN WORK 

								LET err_message = "F11 - New Asset Insert" 

								LET famast_trn.add_on_code = "0" 

								INSERT INTO famast VALUES (famast_trn.*) 

							COMMIT WORK 

							LET add_success_flag = 1 

							WHENEVER ERROR stop 

							LET display_asset = famast_trn.asset_code 
							CLOSE WINDOW wf154 
							CALL run_prog("FBD",famast_trn.asset_code, 
							famast_trn.add_on_code,"","") 
							INITIALIZE famast_trn.* TO NULL 
						END IF 
					END IF 
				END IF 
			END WHILE 
		END WHILE 
		CLOSE WINDOW w_f111 
END FUNCTION 

#--------------------------------------------------------------------------#
# FUNCTION:  edit_fn()
# Edit a particular asset's details
#
#--------------------------------------------------------------------------#

FUNCTION edit_fn() 
	DEFINE 
	keep_on_flag CHAR(1), 
	field_no SMALLINT 

	OPEN WINDOW w_f111 with FORM "F129" -- alch kd-757 
	CALL  windecoration_f("F129") -- alch kd-757 

	MESSAGE "Edit the data THEN press ESC OR press DEL TO EXIT" 




		SELECT * 
		INTO pr_vendor.* 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = famast_trn.vend_code 
		DISPLAY BY NAME pr_vendor.name_text 

		LET keep_on_flag = "Y" 
		WHILE (keep_on_flag = "Y") 
			LET keep_on_flag = "N" 
			INPUT BY NAME famast_trn.desc_text, 
			famast_trn.add_on_code, 
			famast_trn.faresp_code, 
			famast_trn.tag_text, 
			famast_trn.orig_setup_date, 
			famast_trn.asset_serial_text, 
			famast_trn.acquist_code, 
			famast_trn.acquist_date, 
			famast_trn.orig_po_num, 
			famast_trn.cgt_index_per, 
			famast_trn.vend_code, 
			famast_trn.currency_code, 
			famast_trn.orig_fcost_amt, 
			famast_trn.orig_cost_amt, 
			famast_trn.operate_date, 
			famast_trn.start_year_num, 
			famast_trn.start_period_num, 
			famast_trn.user1_code, 
			famast_trn.user1_amt, 
			famast_trn.user2_code, 
			famast_trn.user2_amt, 
			famast_trn.user3_code, 
			famast_trn.user3_amt, 
			famast_trn.user1_qty 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","F11","inp-famast_trn-2") -- alch kd-504 

				ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) infield(desc_text) 
					LET famast_trn.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,famast_trn.desc_text) 
					DISPLAY famast_trn.desc_text TO 
					famast.desc_text 

					NEXT FIELD desc_text 


				ON KEY (control-b)infield(vend_code) 
					LET famast_trn.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,famast_trn.vend_code) 
					DISPLAY BY NAME famast_trn.vend_code 


				ON KEY (control-b) infield(currency_code) 
					LET famast_trn.currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME famast_trn.currency_code 


				ON KEY (control-b) infield (faresp_code) 
					LET famast_trn.faresp_code = lookup_resp(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME famast_trn.faresp_code 

					NEXT FIELD faresp_code 




				AFTER FIELD faresp_code 
					IF famast_trn.faresp_code IS NULL THEN 
						ERROR "Responsibility code must be entered" 
						NEXT FIELD faresp_code 
					ELSE 
						SELECT * 
						FROM faresp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND faresp_code = famast_trn.faresp_code 
						IF status THEN 
							ERROR "Responsibility code does NOT exist" 
							NEXT FIELD faresp_code 
						END IF 
					END IF 


				AFTER FIELD acquist_code 
					IF famast_trn.acquist_code IS NULL THEN 
						ERROR "Acquisition code must be entered" 
						NEXT FIELD acquist_code 
					ELSE 
						IF famast_trn.acquist_code NOT matches "[LP]" THEN 
							ERROR "Acquisition code must be L OR P" 
							NEXT FIELD acquist_code 
						END IF 
					END IF 

				AFTER FIELD cgt_index_per 
					LET field_no = 10 

				AFTER FIELD vend_code 
					IF famast_trn.vend_code IS NOT NULL THEN 
						IF val_vend() THEN 
							NEXT FIELD vend_code 

						ELSE 
							LET famast_trn.currency_code = pr_vendor.currency_code 
							DISPLAY BY NAME famast_trn.currency_code 

							DISPLAY BY NAME pr_vendor.name_text 

							IF famast_trn.orig_fcost_amt IS NOT NULL THEN 
								LET famast_trn.orig_cost_amt = 
								conv_currency(famast_trn.orig_fcost_amt, 

								glob_rec_kandoouser.cmpy_code, 
								famast_trn.currency_code, 
								"F", 
								famast_trn.orig_setup_date, 
								"B") 
								DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 
							END IF 
						END IF 
						IF field_no = 10 THEN 
							LET field_no = 20 
							NEXT FIELD orig_fcost_amt 
						END IF 
					END IF 

					IF famast_trn.orig_fcost_amt IS NOT NULL THEN 
						LET famast_trn.orig_cost_amt = 
						conv_currency(famast_trn.orig_fcost_amt, 

						glob_rec_kandoouser.cmpy_code, 
						famast_trn.currency_code, 
						"F", 
						famast_trn.orig_setup_date, 
						"B") 
						DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 
					END IF 



				BEFORE FIELD currency_code 
					IF famast_trn.vend_code IS NOT NULL THEN 
						IF field_no > 30 THEN 
							NEXT FIELD vend_code 
						ELSE 
							NEXT FIELD orig_fcost_amt 
						END IF 
					END IF 


				AFTER FIELD currency_code 
					LET field_no = 30 
					IF famast_trn.currency_code IS NULL THEN 
						ERROR "Currency must be entered" 
						NEXT FIELD currency_code 
					ELSE 
						SELECT currency_code 
						FROM currency 
						WHERE currency_code = famast_trn.currency_code 
						IF status THEN 
							ERROR "Currency NOT found - try window" 
							NEXT FIELD currency_code 
						END IF 
					END IF 

					LET famast_trn.orig_cost_amt = 
					conv_currency(famast_trn.orig_fcost_amt, 

					glob_rec_kandoouser.cmpy_code, 
					famast_trn.currency_code, 
					"F", 
					famast_trn.orig_setup_date, 
					"B") 
					DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 


					# don't allow entry TO orig_fcost_amt IF this asset has been posted
					# TO the fastatus table
				BEFORE FIELD orig_fcost_amt 
					DECLARE stat_curs CURSOR FOR 
					SELECT * 
					FROM fastatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = famast_trn.asset_code 
					AND add_on_code = famast_trn.add_on_code 
					OPEN stat_curs 
					FETCH stat_curs 
					IF NOT status THEN 
						IF field_no > 30 THEN 
							IF famast_trn.vend_code IS NULL THEN 
								NEXT FIELD currency_code 
							ELSE 
								LET field_no = 20 
								NEXT FIELD vend_code 
							END IF 
						ELSE 
							NEXT FIELD operate_date 
						END IF 
					END IF 


				AFTER FIELD orig_fcost_amt 
					LET field_no = 40 
					LET famast_trn.orig_cost_amt = 
					conv_currency(famast_trn.orig_fcost_amt, 

					glob_rec_kandoouser.cmpy_code, 
					famast_trn.currency_code, 
					"F", 
					famast_trn.orig_setup_date, 
					"B") 
					DISPLAY famast_trn.orig_cost_amt TO orig_cost_amt 

				AFTER FIELD operate_date 

					IF famast_trn.start_year_num IS NULL OR 
					famast_trn.start_period_num IS NULL THEN 
						CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,famast_trn.operate_date) 
						RETURNING famast_trn.start_year_num, 
						famast_trn.start_period_num 
						DISPLAY BY NAME famast_trn.start_year_num, 
						famast_trn.start_period_num 
					END IF 
					LET field_no = 50 

				ON KEY (control-w) 
					CALL kandoohelp("") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
			END INPUT 

			IF int_flag THEN 
				LET int_flag = 0 
				LET quit_flag = false 
				CALL confirm_cont(keep_on_flag) RETURNING keep_on_flag 
			ELSE 
				LET famast_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 
				GOTO bypass2 
				LABEL recovery2: 
				LET try_again = error_recover(err_message, status) 
				IF try_again != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass2: 
				WHENEVER ERROR GOTO recovery2 
				BEGIN WORK 
					LET err_message = "F11 - Asset Update" 
					UPDATE famast 
					SET famast.* = famast_trn.* WHERE 
					cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					asset_code = famast_trn.asset_code AND 
					add_on_code = famast_trn.add_on_code 
				COMMIT WORK 
				MESSAGE "Asset ID: ", famast_trn.asset_code clipped, 
				" successfully updated" 
				SLEEP 2 
				WHENEVER ERROR stop 
			END IF 
		END WHILE 

		CLOSE WINDOW w_f111 

END FUNCTION 

#--------------------------------------------------------------------------#
# FUNCTION: load_array()
# Load the ARRAY 'array_rec' with all assets based on the CURSOR 'curs_qry'
#--------------------------------------------------------------------------#
#
FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE famast.* 

	LET counter = 1 

	FOREACH curs_qry INTO look_rec.* 
		LET array_rec[counter].asset_code = look_rec.asset_code 
		LET array_rec[counter].add_on_code = look_rec.add_on_code 
		LET array_rec[counter].desc_text = look_rec.desc_text 
		LET array_rec[counter].orig_setup_date = look_rec.orig_setup_date 
		IF counter = 300 THEN 
			ERROR " Only the first 300 records selected " 
			EXIT FOREACH 
		END IF 
		LET counter = counter + 1 
		LET exist = true 
	END FOREACH 
	#must decriment counter before SET count
	LET counter = counter - 1 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 

	MESSAGE "F1 add, RETURN on line TO change, F2 delete, F9 reselect" 

	CALL set_count(counter) 

END FUNCTION 

FUNCTION vend_lookup() 

	DEFINE array_rec4 ARRAY [200] OF 
	RECORD 
		vend_code LIKE vendor.vend_code, 
		name_text CHAR(30) 
	END RECORD 

	DEFINE look_rec RECORD LIKE vendor.* 

	OPEN WINDOW win5 with FORM "F130" -- alch kd-757 
	CALL  windecoration_f("F130") -- alch kd-757 

	MESSAGE "Enter selection criteria - press ESC TO begin search" 

	CONSTRUCT BY NAME query_text ON 
	vendor.vend_code, vendor.name_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F11","const-query_text-1") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 

	LET where_text = "SELECT * FROM vendor WHERE ", 
	"cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" AND ", 
	query_text clipped, " ORDER BY vend_code" 

	PREPARE statement7 FROM where_text 
	DECLARE curs65 SCROLL CURSOR FOR statement7 

	MESSAGE "ESC choose RECORD - DEL TO EXIT" 

	LET counter = 0 
	FOREACH curs65 INTO look_rec.* 
		IF look_rec.cmpy_code = glob_rec_kandoouser.cmpy_code THEN 
			LET counter = counter + 1 
			LET array_rec4[counter].vend_code = look_rec.vend_code 
			LET array_rec4[counter].name_text = look_rec.name_text 
		END IF 
	END FOREACH 

	CALL set_count(counter) 

	DISPLAY ARRAY array_rec4 TO screen_rec.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","F11","disp_arr-array_rec4-1") -- alch kd-504 
		ON KEY (esc) 
			LET counter = arr_curr() 
			LET famast_trn.vend_code = array_rec4[counter].vend_code 
			EXIT DISPLAY 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END DISPLAY 

	CLOSE WINDOW win5 

END FUNCTION 

FUNCTION next_asset(recont_flag) 

	DEFINE 
	next_asset INTEGER, 
	recont_flag SMALLINT 

	WHILE true 
		SELECT last_asset_num 
		INTO next_asset 
		FROM faparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = notfound THEN 
			ERROR "Fixed Asset Parameters are NOT SET up - use FZP TO add" 
			SLEEP 3 
			LET recont_flag = 1 
			EXIT WHILE 
		ELSE 
			IF next_asset IS NULL THEN 
				ERROR 
				"Next asset number IS NOT SET up in parameters - see menu FZP" 
				SLEEP 3 
				LET recont_flag = 1 
				EXIT WHILE 
			END IF 
			LET next_asset = next_asset + 1 
			LET auto_flag = 1 
		END IF 

		LET famast_trn.asset_code = next_asset 

		UPDATE faparms SET last_asset_num = next_asset 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT * 
		FROM famast 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND asset_code = famast_trn.asset_code 

		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	RETURN recont_flag 

END FUNCTION 


FUNCTION val_asset() 

	SELECT * FROM famast WHERE 
	cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	asset_code = famast_trn.asset_code 

	IF status = notfound THEN 
		RETURN 0 
	ELSE 
		ERROR "Asset Code must be unique - please re-enter" 
		RETURN 1 
	END IF 

END FUNCTION 

FUNCTION val_vend() 

	SELECT * 
	INTO pr_vendor.* 
	FROM vendor WHERE 
	cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	vend_code = famast_trn.vend_code 

	IF status = notfound THEN 
		ERROR "Vendor NOT found, try window" 
		RETURN 1 
	END IF 

	RETURN 0 

END FUNCTION 

FUNCTION confirm_cont(keep_on_flag) 
	DEFINE 
	keep_on_flag CHAR(1) 


	--   prompt " Are you sure you wish TO cancel (y/n)? " -- albo
	--      FOR CHAR ans
	LET ans = promptYN(""," Are you sure you wish TO cancel (y/n)? ","Y") -- albo 
	LET ans = downshift(ans) 
	IF ans != "y" THEN 
		LET keep_on_flag = "Y" 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "N" 
	END IF 
	RETURN keep_on_flag 
END FUNCTION 
