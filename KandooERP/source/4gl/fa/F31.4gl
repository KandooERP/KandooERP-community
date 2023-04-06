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

	Source code beautified by beautify.pl on 2020-01-03 10:36:55	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose    :   Book Maintenance

GLOBALS 
	DEFINE batch_numeric INTEGER 
	DEFINE program_name CHAR(40) 
	DEFINE screen_no CHAR(6) 
	DEFINE fabook_trn RECORD LIKE fabook.* 
	DEFINE ans CHAR(1) 
	DEFINE the_rowid INTEGER 
	DEFINE flag CHAR(1) 
	DEFINE counter SMALLINT 
	DEFINE switch_char CHAR(1) 
	DEFINE where_text CHAR(200) 
	DEFINE query_text CHAR(250) 
	DEFINE exist INTEGER 
	DEFINE not_found INTEGER 
	DEFINE try_again CHAR(1) 
	DEFINE err_message CHAR(60) 
	DEFINE array_rec ARRAY [200] OF 
	RECORD 
		book_code LIKE fabook.book_code, 
		book_text LIKE fabook.book_text 
	END RECORD 
	DEFINE array_rec2 ARRAY [200] OF 
	RECORD 
		depr_period_flag LIKE fabook.depr_period_flag, 
		curr_period_num LIKE fabook.curr_period_num, 
		curr_year_num LIKE fabook.curr_year_num, 
		gl_output_flag LIKE fabook.gl_output_flag, 
		curr_per_depn_flag LIKE fabook.curr_per_depn_flag, 
		book_for_tax_flag LIKE fabook.book_for_tax_flag 


	END RECORD, 

	scrn SMALLINT, 
	pr_book_code LIKE fabook.book_code, 
	del_book SMALLINT 
END GLOBALS 

MAIN 

	OPTIONS MESSAGE line FIRST 

	#Initial UI Init
	CALL setModuleId("F31") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET program_name = "Book Table" 
	LET screen_no = "F31" 

	OPEN WINDOW win_main with FORM "F114" -- alch kd-757 
	CALL  windecoration_f("F114") -- alch kd-757 

	WHILE true 

		CLEAR FORM 

		MESSAGE "Enter selection criteria - press ", 
		"ESC TO begin search" 

		CONSTRUCT BY NAME query_text ON fabook.book_code, 
		fabook.book_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F31","const-fabook_book_code-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			EXIT program 
		END IF 

		LET where_text = "SELECT * FROM fabook WHERE ", 
		"cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
		query_text clipped, "ORDER BY book_code" 
		PREPARE statement1 FROM where_text 
		DECLARE curs_qry SCROLL CURSOR FOR statement1 

		CALL load_array() 
		INPUT ARRAY array_rec WITHOUT DEFAULTS FROM screen_rec.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F31","inp_arr-load_array-1") -- alch kd-504 
			BEFORE INSERT 
				IF add_fn() THEN 
					LET array_rec[counter].book_code = fabook_trn.book_code 
					LET array_rec[counter].book_text = fabook_trn.book_text 
					DISPLAY array_rec[counter].book_code TO screen_rec[scrn].book_code 
					DISPLAY array_rec[counter].book_text TO screen_rec[scrn].book_text 
				END IF 
			ON KEY (control-m) 
				IF array_rec[counter].book_code IS NOT NULL THEN 
					LET fabook_trn.book_code = array_rec[counter].book_code 
					LET fabook_trn.book_text = array_rec[counter].book_text 
					LET fabook_trn.depr_period_flag = 
					array_rec2[counter].depr_period_flag 
					LET fabook_trn.curr_period_num = 
					array_rec2[counter].curr_period_num 
					LET fabook_trn.curr_year_num = 
					array_rec2[counter].curr_year_num 
					LET fabook_trn.gl_output_flag = 
					array_rec2[counter].gl_output_flag 
					LET fabook_trn.curr_per_depn_flag = 
					array_rec2[counter].curr_per_depn_flag 
					LET fabook_trn.book_for_tax_flag = 
					array_rec2[counter].book_for_tax_flag 



					CALL edit_fn() 
				END IF 



			BEFORE ROW 
				LET counter = arr_curr() 
				LET scrn = scr_line() 
				LET pr_book_code = array_rec[counter].book_code 

			BEFORE DELETE 
				LET del_book = true 
				DECLARE del_curs CURSOR FOR 
				SELECT * 
				FROM faaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = array_rec[counter].book_code 
				OPEN del_curs 
				FETCH del_curs 
				IF NOT status THEN 
					ERROR "Transactions exist - cannot delete book!" 
					LET del_book = false 
					NEXT FIELD book_code 
				END IF 

			AFTER DELETE 

				IF del_book THEN 
					LET fabook_trn.book_code = array_rec[counter].book_code 
					LET fabook_trn.book_text = array_rec[counter].book_text 
					LET fabook_trn.depr_period_flag = 
					array_rec2[counter].depr_period_flag 
					LET fabook_trn.curr_period_num = 
					array_rec2[counter].curr_period_num 
					LET fabook_trn.curr_year_num = 
					array_rec2[counter].curr_year_num 
					LET fabook_trn.gl_output_flag = 
					array_rec2[counter].gl_output_flag 
					LET fabook_trn.curr_per_depn_flag = 
					array_rec2[counter].curr_per_depn_flag 
					LET fabook_trn.book_for_tax_flag = 
					array_rec2[counter].book_for_tax_flag 
					--                    LET ans = fprompt("Are you sure you want TO delete (Y/N)") -- albo
					LET ans = promptYN("","Are you sure you want TO delete (Y/N)","Y") -- albo 
					IF ans matches "[Yy]" THEN 
						DELETE FROM fabook 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND book_code = array_rec[counter].book_code 
						IF status THEN 
							ERROR "Delete NOT sucessful" 
							SLEEP 1 
						ELSE 
							MESSAGE "Book ",array_rec[counter].book_code 
							clipped," DELETED" 
						END IF 
					ELSE 
						MESSAGE "Book ",array_rec[counter].book_code clipped, 
						" NOT DELETED - ESC TO reselect" 
					END IF 
				ELSE 
					MESSAGE "Book ",pr_book_code clipped, 
					" NOT DELETED - ESC TO reselect" 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		IF int_flag THEN 
			LET int_flag = false 
		END IF 

	END WHILE 

	CLOSE WINDOW win_main 

END MAIN 

FUNCTION add_fn() 
	DEFINE 
	not_valid, 
	end_flag SMALLINT 

	INITIALIZE fabook_trn.* TO NULL 

	OPEN WINDOW win_add with FORM "F115" -- alch kd-757 
	CALL  windecoration_f("F115") -- alch kd-757 

	LET end_flag = 0 
	MESSAGE "ESC TO enter data - DEL TO EXIT" 

	INPUT BY NAME fabook_trn.book_code thru fabook_trn.book_for_tax_flag 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","?31","inp-fabook_trn-1") -- alch kd-504 
		AFTER FIELD book_code 
			IF fabook_trn.book_code IS NOT NULL THEN 
				SELECT book_code 
				FROM fabook 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = fabook_trn.book_code 
				IF NOT status THEN 
					ERROR "Book already exists" 
					SLEEP 1 
					NEXT FIELD book_code 
				END IF 
			END IF 


		AFTER FIELD curr_year_num 
			# this needs TO be changed TO "FA" as soon
			# as period table etc IS ready
			CALL valid_period(glob_rec_kandoouser.cmpy_code,fabook_trn.curr_year_num, 
			fabook_trn.curr_period_num,"GL") 
			RETURNING fabook_trn.curr_year_num, 
			fabook_trn.curr_period_num, 
			not_valid 

			IF not_valid THEN 
				NEXT FIELD curr_period_num 
			END IF 


		ON KEY (interrupt) 
			LET int_flag = false 
			LET end_flag = 1 
			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 


	IF end_flag = 1 THEN 
		CLOSE WINDOW win_add 
		RETURN false 
	END IF 

	LET fabook_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF end_flag = 0 THEN 
		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F31-Book Insert" 
			INSERT INTO fabook 
			VALUES (fabook_trn.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 

	CLOSE WINDOW win_add 

	RETURN true 

END FUNCTION 

FUNCTION load_array() 

	DEFINE look_rec RECORD LIKE fabook.* 


	LET flag = "N" 
	LET exist = false 

	LET counter = 0 
	FOREACH curs_qry INTO look_rec.* 
		LET exist = true 
		LET counter = counter + 1 
		LET array_rec[counter].book_code = look_rec.book_code 
		LET array_rec[counter].book_text = look_rec.book_text 

		LET array_rec2[counter].depr_period_flag = look_rec.depr_period_flag 
		LET array_rec2[counter].curr_period_num = look_rec.curr_period_num 
		LET array_rec2[counter].curr_year_num = look_rec.curr_year_num 
		LET array_rec2[counter].gl_output_flag = look_rec.gl_output_flag 
		LET array_rec2[counter].curr_per_depn_flag = look_rec.curr_per_depn_flag 
		LET array_rec2[counter].book_for_tax_flag = look_rec.book_for_tax_flag 


	END FOREACH 

	LET not_found = 0 
	IF NOT exist THEN 
		LET not_found = 1 
	END IF 

	MESSAGE "F1 TO add, RETURN on line TO change, F2 TO delete" 

	CALL set_count(counter) 

END FUNCTION 

FUNCTION edit_fn() 

	DEFINE 
	not_valid SMALLINT 

	OPEN WINDOW win_add with FORM "F115" -- alch kd-757 
	CALL  windecoration_f("F115") -- alch kd-757 
	DISPLAY BY NAME fabook_trn.book_code thru fabook_trn.book_for_tax_flag 
	MESSAGE " Edit the data THEN press ESC OR press DEL TO EXIT" 
		INPUT BY NAME fabook_trn.depr_period_flag thru fabook_trn.book_for_tax_flag 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F31","inp-fabook_trn-2") -- alch kd-504 
			AFTER FIELD curr_year_num 
				# this needs TO be changed TO "FA" as soon
				# as period table etc IS ready
				CALL valid_period(glob_rec_kandoouser.cmpy_code,fabook_trn.curr_year_num, 
				fabook_trn.curr_period_num,"GL") 
				RETURNING fabook_trn.curr_year_num, 
				fabook_trn.curr_period_num, 
				not_valid 
				IF not_valid THEN 
					NEXT FIELD curr_period_num 
				END IF 


			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 

		IF int_flag THEN 
			LET int_flag = false 
			CLOSE WINDOW win_add 
			RETURN 
		END IF 

		LET fabook_trn.cmpy_code = glob_rec_kandoouser.cmpy_code 

		GOTO bypass 
		LABEL recovery: 
		LET try_again = error_recover(err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "F31 - Book Update" 
			WHILE true 
				UPDATE fabook 
				SET fabook.* = fabook_trn.* 
				WHERE fabook.book_code = array_rec[counter].book_code 
				AND fabook.book_text = array_rec[counter].book_text 
				AND fabook.cmpy_code = glob_rec_kandoouser.cmpy_code 
				EXIT WHILE 
			END WHILE 
		COMMIT WORK 
		WHENEVER ERROR stop 


		LET array_rec2[counter].depr_period_flag = fabook_trn.depr_period_flag 
		LET array_rec2[counter].curr_period_num = fabook_trn.curr_period_num 
		LET array_rec2[counter].curr_year_num = fabook_trn.curr_year_num 
		LET array_rec2[counter].gl_output_flag = fabook_trn.gl_output_flag 
		LET array_rec2[counter].curr_per_depn_flag = fabook_trn.curr_per_depn_flag 
		LET array_rec2[counter].book_for_tax_flag = fabook_trn.book_for_tax_flag 



		INITIALIZE fabook_trn.* TO NULL 

		CLOSE WINDOW win_add 

END FUNCTION 


FUNCTION error_screen() 
	DEFINE error_text STRING 
	DEFINE msgstr STRING 

	# Check FOR errors you do NOT wish TO trap
	IF status = -246 THEN 
		RETURN 
	END IF 

	LET error_text = err_get(status) 

	LET msgstr = "The following Error hsa occured!\n" 
	LET msgstr = msgstr, "Please call your EDP Center TO log this error\n" 
	LET msgstr = msgstr, trim(error_text), "\n" 

	CALL fgl_winmessage("Error",msgStr,"error") #huho 

END FUNCTION 

FUNCTION fprompt(fv_prompt) 

	DEFINE 
	fv_prompt CHAR(40), 
	fv_ans CHAR(1) 

	#    OPEN WINDOW wprompt AT 5,3 with 1 rows, 45 columns attribute (border)

	PROMPT fv_prompt FOR CHAR fv_ans 
	BEFORE PROMPT 
		CALL publish_toolbar("kandoo","F31","prom-fv_prompt-1") -- alch kd-504 
	ON ACTION "WEB-HELP" 
		CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END PROMPT 

		#    CLOSE WINDOW wprompt

		RETURN fv_ans 

END FUNCTION 
