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

	Source code beautified by beautify.pl on 2020-01-03 10:37:01	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module :   FZ1.4GL (menu FZG)
# Purpose   :   DISPLAY AND add GL Integration Details

GLOBALS 
	DEFINE 
	pr_glasset RECORD LIKE glasset.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_fabook RECORD LIKE fabook.*, 
	pr_facat RECORD LIKE facat.*, 
	pr_falocation RECORD LIKE falocation.*, 
	pr_coa RECORD LIKE coa.*, 
	start_flag, exist SMALLINT, 
	err_message CHAR(60), 
	query_text, 
	select_text, 
	where_part1, where_part CHAR(300), 
	try_again CHAR(1) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("FZ1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	OPEN WINDOW f144 with FORM "F144" -- alch kd-757 
	CALL  windecoration_f("F144") -- alch kd-757 

	INITIALIZE pr_glasset.* TO NULL 

	CALL query() 

	CLOSE WINDOW f144 
END MAIN 

FUNCTION select_them() 

	DEFINE 
	save_book_code LIKE glasset.book_code, 
	save_facat_code LIKE glasset.facat_code, 
	save_location_code LIKE glasset.location_code 

	IF start_flag = 0 THEN 
		LET start_flag = 1 
		OPEN WINDOW f145 with FORM "F145" -- alch kd-757 
		CALL  windecoration_f("F145") -- alch kd-757 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001  Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME where_part ON glasset.book_code, 
		glasset.facat_code, 
		glasset.location_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","FZ1","const-glasset-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		CLOSE WINDOW f145 
	END IF 

	LET query_text = "SELECT * ", 
	"FROM glasset ", 
	"WHERE glasset.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", where_part clipped," ", 
	"ORDER BY glasset.cmpy_code, ", 
	"glasset.book_code, ", 
	"glasset.facat_code,glasset.location_code" 


	LET exist = 0 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	PREPARE choice FROM query_text 
	DECLARE selcurs SCROLL CURSOR FOR choice 
	OPEN selcurs 

	MESSAGE " " 

	LET save_book_code = pr_glasset.book_code 
	LET save_facat_code = pr_glasset.facat_code 
	LET save_location_code = pr_glasset.location_code 

	WHILE (true) 
		FETCH selcurs INTO pr_glasset.* 
		IF status <> notfound THEN 
			LET exist = true 
		ELSE 
			FETCH LAST selcurs INTO pr_glasset.* 
			EXIT WHILE 
		END IF 
		IF (save_book_code = pr_glasset.book_code AND 
		save_facat_code = pr_glasset.facat_code AND 
		save_location_code = pr_glasset.location_code) OR 
		(save_book_code IS NULL OR 
		save_facat_code IS NULL OR 
		save_location_code IS null) THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CALL show_it() 

END FUNCTION 

FUNCTION query() 
	CLEAR FORM 
	LET exist = false 
	MENU " General Ledger" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","FZ1","menu-gen_ledg-1") -- alch kd-504 
		COMMAND "Query" " Search FOR books/categories" 
			LET start_flag = 0 
			CALL select_them() 
			IF exist THEN 
				CALL show_it() 
			ELSE 
				IF not(int_flag OR quit_flag) THEN 
					ERROR "No Book/Category satisfied the query criteria" 
				ELSE 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected book/category " 
			IF exist THEN 
				FETCH NEXT selcurs INTO pr_glasset.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the books/categories selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY ("P",f19) "Prev" " DISPLAY previous selected book/category" 
			IF exist THEN 
				FETCH previous selcurs INTO pr_glasset.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the books/categories selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND "Add" " Enter new book AND category details" 
			INITIALIZE pr_glasset.* TO NULL 
			IF add_fn() THEN 
				IF start_flag THEN 
					CALL select_them() 
				END IF 
			END IF 
		COMMAND "Change" " Alter existing record" 
			IF exist THEN 
				CALL edit_fn() 
				CALL select_them() 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
END FUNCTION 


FUNCTION show_it() 
	DISPLAY BY NAME pr_glasset.book_code, 
	pr_glasset.facat_code, 
	pr_glasset.location_code, 
	pr_glasset.orig_cost_code, 
	pr_glasset.depr_exp_code, 
	pr_glasset.accum_depr_code, 
	pr_glasset.cpip_acct_code, 
	pr_glasset.prof_on_sale_code, 
	pr_glasset.loss_on_sale_code, 
	pr_glasset.capital_prof_code, 
	pr_glasset.reval_res_code, 
	pr_glasset.int_plant_cl_code, 
	pr_glasset.asset_proc_code, 
	pr_glasset.approp_acct_code 

	SELECT * 
	INTO pr_fabook.* 
	FROM fabook 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND book_code = pr_glasset.book_code 

	DISPLAY BY NAME pr_fabook.book_text 

	SELECT * 
	INTO pr_facat.* 
	FROM facat 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND facat_code = pr_glasset.facat_code 

	DISPLAY BY NAME pr_facat.facat_text 

	SELECT * 
	INTO pr_falocation.* 
	FROM falocation 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND location_code = pr_glasset.location_code 

	DISPLAY BY NAME pr_falocation.location_text 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.orig_cost_code 

	DISPLAY pr_coa.desc_text TO desc1 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.depr_exp_code 

	DISPLAY pr_coa.desc_text TO desc2 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.accum_depr_code 

	DISPLAY pr_coa.desc_text TO desc3 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.cpip_acct_code 

	DISPLAY pr_coa.desc_text TO desc4 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.prof_on_sale_code 

	DISPLAY pr_coa.desc_text TO desc5 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.loss_on_sale_code 

	DISPLAY pr_coa.desc_text TO desc6 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.capital_prof_code 

	DISPLAY pr_coa.desc_text TO desc7 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.reval_res_code 

	DISPLAY pr_coa.desc_text TO desc8 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.int_plant_cl_code 

	DISPLAY pr_coa.desc_text TO desc9 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.asset_proc_code 

	DISPLAY pr_coa.desc_text TO desc10 

	SELECT * 
	INTO pr_coa.* 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = pr_glasset.approp_acct_code 

	DISPLAY pr_coa.desc_text TO desc11 

END FUNCTION 

FUNCTION add_fn() 
	DEFINE 
	add_glasset RECORD LIKE glasset.* 

	CLEAR FORM 

	LET pr_glasset.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF input_data(true) THEN 
		GOTO bypass 

		LABEL recovery: 

		LET try_again = error_recover (err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 

		LABEL bypass: 

		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 
			LET err_message = "FZ1 - GL Asset INSERT" 
			LET pr_glasset.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO glasset VALUES (pr_glasset.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
		LET msgresp = kandoomsg("U",9934,"") 
		#9934 RECORD added successfully.
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 

FUNCTION edit_fn() 

	DEFINE 
	temp_book_code LIKE glasset.book_code, 
	temp_facat_code LIKE glasset.facat_code, 
	temp_location_code LIKE glasset.location_code 

	LET temp_book_code = pr_glasset.book_code 
	LET temp_facat_code = pr_glasset.facat_code 
	LET temp_location_code = pr_glasset.location_code 

	LET pr_glasset.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF input_data(false) THEN 
		GOTO bypass 

		LABEL recovery: 

		LET try_again = error_recover (err_message, status) 
		IF try_again != "Y" THEN 
			EXIT program 
		END IF 

		LABEL bypass: 

		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 
			LET err_message = "FZ1 - GL Asset UPDATE" 
			WHENEVER ERROR CONTINUE 
			UPDATE glasset SET * = pr_glasset.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			book_code = temp_book_code AND 
			facat_code = temp_facat_code AND 
			location_code = temp_location_code 
			CASE 
				WHEN status = 0 
					LET msgresp = kandoomsg("U",9934,"") 
					#9934 RECORD added successfully.
				WHEN status = -346 
					ERROR 
					"This Book/Category already exists - RECORD NOT updated" 
					SLEEP 2 
					LET pr_glasset.book_code = temp_book_code 
					LET pr_glasset.facat_code = temp_facat_code 
					LET pr_glasset.location_code = temp_location_code 
					DISPLAY BY NAME pr_glasset.book_code, 
					pr_glasset.facat_code, 
					pr_glasset.location_code 
				OTHERWISE 
					GOTO recovery 
			END CASE 
			WHENEVER ERROR GOTO recovery 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END IF 
END FUNCTION 

FUNCTION input_data(add_flag) 

	DEFINE 
	add_flag, 
	rt_code SMALLINT, 
	temp_book_code LIKE glasset.book_code, 
	temp_facat_code LIKE glasset.facat_code, 
	temp_location_code LIKE glasset.location_code, 
	tmp_glasset RECORD LIKE glasset.*, 
	image_glasset RECORD LIKE glasset.* 

	LET temp_book_code = pr_glasset.book_code 
	LET temp_facat_code = pr_glasset.facat_code 
	LET temp_location_code = pr_glasset.location_code 

	LET rt_code = false 

	IF add_flag THEN 
		LET msgresp = kandoomsg("F",1509,"") 
		#1509 OK TO Update; F9 TO Image.
	ELSE 
		LET msgresp = kandoomsg("F",1510,"") 
		#1511 OK TO Continue.
	END IF 
	INPUT BY NAME pr_glasset.book_code, 
	pr_glasset.facat_code, 
	pr_glasset.location_code, 
	pr_glasset.orig_cost_code, 
	pr_glasset.depr_exp_code, 
	pr_glasset.accum_depr_code, 
	pr_glasset.cpip_acct_code, 
	pr_glasset.prof_on_sale_code, 
	pr_glasset.loss_on_sale_code, 
	pr_glasset.capital_prof_code, 
	pr_glasset.reval_res_code, 
	pr_glasset.int_plant_cl_code, 
	pr_glasset.asset_proc_code, 
	pr_glasset.approp_acct_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FZ1","inp-pr_glasset-1") -- alch kd-504 

				ON ACTION "LOOKUP" infield (book_code) 
					LET pr_glasset.book_code = lookup_book(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.book_code 

					NEXT FIELD book_code 

				ON ACTION "LOOKUP" infield (facat_code) 
					LET pr_glasset.facat_code = lookup_facat_code(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.facat_code 

					NEXT FIELD facat_code 

				ON ACTION "LOOKUP" infield (location_code) 
					LET pr_glasset.location_code = lookup_location(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.location_code 

					NEXT FIELD location_code 

				ON ACTION "LOOKUP" infield (orig_cost_code) 
					LET pr_glasset.orig_cost_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.orig_cost_code 

					NEXT FIELD orig_cost_code 

				ON ACTION "LOOKUP" infield (depr_exp_code) 
					LET pr_glasset.depr_exp_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.depr_exp_code 

					NEXT FIELD depr_exp_code 

				ON ACTION "LOOKUP" infield (accum_depr_code) 
					LET pr_glasset.accum_depr_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.accum_depr_code 

					NEXT FIELD accum_depr_code 

				ON ACTION "LOOKUP" infield (cpip_acct_code) 
					LET pr_glasset.cpip_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.cpip_acct_code 

					NEXT FIELD cpip_acct_code 

				ON ACTION "LOOKUP" infield (prof_on_sale_code) 
					LET pr_glasset.prof_on_sale_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.prof_on_sale_code 

					NEXT FIELD prof_on_sale_code 

				ON ACTION "LOOKUP" infield (loss_on_sale_code) 
					LET pr_glasset.loss_on_sale_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.loss_on_sale_code 

					NEXT FIELD loss_on_sale_code 

				ON ACTION "LOOKUP" infield (capital_prof_code) 
					LET pr_glasset.capital_prof_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.capital_prof_code 

					NEXT FIELD capital_prof_code 

				ON ACTION "LOOKUP" infield (reval_res_code) 
					LET pr_glasset.reval_res_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.reval_res_code 

					NEXT FIELD reval_res_code 

				ON ACTION "LOOKUP" infield (int_plant_cl_code) 
					LET pr_glasset.int_plant_cl_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.int_plant_cl_code 

					NEXT FIELD int_plant_cl_code 

				ON ACTION "LOOKUP" infield (asset_proc_code) 
					LET pr_glasset.asset_proc_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.asset_proc_code 

					NEXT FIELD asset_proc_code 

				ON ACTION "LOOKUP" infield (approp_acct_code) 
					LET pr_glasset.approp_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_glasset.approp_acct_code 

					NEXT FIELD approp_acct_code 


		ON KEY (F9) 
			IF add_flag AND (infield(book_code) OR 
			infield(facat_code) OR 
			infield(location_code)) THEN 

				CALL get_gla() RETURNING tmp_glasset.book_code, 
				tmp_glasset.facat_code, 
				tmp_glasset.location_code 

				INITIALIZE pr_glasset.* TO NULL 
				INITIALIZE image_glasset.* TO NULL 

				SELECT * 
				INTO image_glasset.* 
				FROM glasset 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = tmp_glasset.book_code 
				AND facat_code = tmp_glasset.facat_code 
				AND location_code = tmp_glasset.location_code 

				LET pr_glasset.orig_cost_code = image_glasset.orig_cost_code 
				LET pr_glasset.depr_exp_code = image_glasset.depr_exp_code 
				LET pr_glasset.accum_depr_code = image_glasset.accum_depr_code 
				LET pr_glasset.cpip_acct_code = image_glasset.cpip_acct_code 
				LET pr_glasset.prof_on_sale_code = image_glasset.prof_on_sale_code 
				LET pr_glasset.loss_on_sale_code = image_glasset.loss_on_sale_code 
				LET pr_glasset.capital_prof_code = image_glasset.capital_prof_code 
				LET pr_glasset.reval_res_code = image_glasset.reval_res_code 
				LET pr_glasset.int_plant_cl_code = image_glasset.int_plant_cl_code 
				LET pr_glasset.asset_proc_code = image_glasset.asset_proc_code 
				LET pr_glasset.approp_acct_code = image_glasset.approp_acct_code 

				DISPLAY BY NAME pr_glasset.orig_cost_code thru 
				pr_glasset.approp_acct_code 

			END IF 

		AFTER FIELD book_code 
			SELECT * 
			INTO pr_fabook.* 
			FROM fabook 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			book_code = pr_glasset.book_code 

			IF status = notfound THEN 
				ERROR "Book ID NOT found - try window" 
				NEXT FIELD book_code 
			END IF 
			DISPLAY BY NAME pr_fabook.book_text 

		AFTER FIELD facat_code 
			SELECT * 
			INTO pr_facat.* 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = pr_glasset.facat_code 

			IF status = notfound THEN 
				ERROR "Category ID NOT found - try window" 
				NEXT FIELD facat_code 
			END IF 
			DISPLAY BY NAME pr_facat.facat_text 

		AFTER FIELD location_code 
			SELECT * 
			INTO pr_falocation.* 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = pr_glasset.location_code 

			IF status = notfound THEN 
				ERROR "Location ID NOT found - try window" 
				NEXT FIELD location_code 
			ELSE 
				SELECT * 
				INTO pr_glasset.* 
				FROM glasset 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = pr_glasset.book_code AND 
				facat_code = pr_glasset.facat_code AND 
				location_code = pr_glasset.location_code 

				IF add_flag THEN 
					IF NOT status THEN 
						ERROR "This Book/Category/Location combination already exists" 
						NEXT FIELD facat_code 
					END IF 
				ELSE 
					IF not(temp_book_code = pr_glasset.book_code AND 
					temp_facat_code = pr_glasset.facat_code AND 
					temp_location_code = pr_glasset.location_code) THEN 
						IF NOT status THEN 
							ERROR 
							"This Book/Category/Location combination already exists" 
							NEXT FIELD facat_code 
						END IF 
					END IF 
				END IF 
			END IF 

			DISPLAY BY NAME pr_falocation.location_text 


		AFTER FIELD orig_cost_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.orig_cost_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD orig_cost_code 
			END IF 
			DISPLAY pr_coa.desc_text TO desc1 

		AFTER FIELD depr_exp_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.depr_exp_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD depr_exp_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc2 

		AFTER FIELD accum_depr_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.accum_depr_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD accum_depr_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc3 

		AFTER FIELD cpip_acct_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.cpip_acct_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD cpip_acct_code 
			END IF 
			DISPLAY pr_coa.desc_text TO desc4 

		AFTER FIELD prof_on_sale_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.prof_on_sale_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD prof_on_sale_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc5 

		AFTER FIELD loss_on_sale_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.loss_on_sale_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD loss_on_sale_code 

			END IF 

			DISPLAY pr_coa.desc_text TO desc6 

		AFTER FIELD capital_prof_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.capital_prof_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD capital_prof_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc7 

		AFTER FIELD reval_res_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.reval_res_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD reval_res_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc8 

		AFTER FIELD int_plant_cl_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.int_plant_cl_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD int_plant_cl_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc9 

		AFTER FIELD asset_proc_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.asset_proc_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD asset_proc_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc10 

		AFTER FIELD approp_acct_code 
			SELECT * 
			INTO pr_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			acct_code = pr_glasset.approp_acct_code 

			IF status = notfound THEN 
				ERROR "Account NOT found - try window" 
				NEXT FIELD approp_acct_code 
			END IF 

			DISPLAY pr_coa.desc_text TO desc11 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				LET rt_code = false 
			ELSE 
				SELECT * 
				INTO pr_fabook.* 
				FROM fabook 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = pr_glasset.book_code 

				IF status = notfound THEN 
					ERROR "Book ID NOT found - try window" 
					NEXT FIELD book_code 
				END IF 

				SELECT * 
				INTO pr_facat.* 
				FROM facat 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND facat_code = pr_glasset.facat_code 

				IF status = notfound THEN 
					ERROR "Category ID NOT found - try window" 
					NEXT FIELD book_code 
				END IF 

				SELECT * 
				INTO pr_falocation.* 
				FROM falocation 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND location_code = pr_glasset.location_code 

				IF status = notfound THEN 
					ERROR "Location ID NOT found - try window" 
					NEXT FIELD book_code 
				END IF 

				SELECT * 
				FROM glasset 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				book_code = pr_glasset.book_code AND 
				facat_code = pr_glasset.facat_code AND 
				location_code = pr_glasset.location_code 

				IF add_flag THEN 
					IF NOT status THEN 
						ERROR "This Book/Category/Location combination already exists" 
						NEXT FIELD facat_code 
					END IF 
				ELSE 
					IF not(temp_book_code = pr_glasset.book_code AND 
					temp_facat_code = pr_glasset.facat_code AND 
					temp_location_code = pr_glasset.location_code) THEN 
						IF NOT status THEN 
							ERROR 
							"This Book/Category/Location combination already exists" 
							NEXT FIELD facat_code 
						END IF 
					END IF 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.orig_cost_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD orig_cost_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.depr_exp_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD depr_exp_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.accum_depr_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD accum_depr_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.cpip_acct_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD cpip_acct_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.prof_on_sale_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD prof_on_sale_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.loss_on_sale_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD loss_on_sale_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.capital_prof_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD capital_prof_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.reval_res_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD reval_res_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.int_plant_cl_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD int_plant_cl_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.asset_proc_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD asset_proc_code 
				END IF 

				SELECT * 
				INTO pr_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_glasset.approp_acct_code 

				IF status = notfound THEN 
					ERROR "Account NOT found - try window" 
					NEXT FIELD approp_acct_code 
				END IF 

				LET rt_code = true 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

	RETURN rt_code 


END FUNCTION 

FUNCTION get_gla() 
	DEFINE tmp_glasset RECORD LIKE glasset.* 

	OPEN WINDOW wf145 with FORM "F145" -- alch kd-757 
	CALL  windecoration_f("F145") -- alch kd-757 
	MESSAGE "Enter details TO image" 
	attribute(yellow) 
	OPTIONS INPUT no wrap 
	INPUT BY NAME tmp_glasset.book_code, 
	tmp_glasset.facat_code, 
	tmp_glasset.location_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FZ1","inp-tmp_glasset-2") -- alch kd-504 
		AFTER FIELD book_code 
			SELECT * 
			INTO pr_fabook.* 
			FROM fabook 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND book_code = tmp_glasset.book_code 
			IF status = notfound THEN 
				ERROR "Book ID NOT found - try window" 
				NEXT FIELD book_code 
			END IF 
		AFTER FIELD facat_code 
			SELECT * 
			INTO pr_facat.* 
			FROM facat 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND facat_code = tmp_glasset.facat_code 
			IF status = notfound THEN 
				ERROR "Category ID NOT found - try window" 
				NEXT FIELD book_code 
			END IF 
		AFTER FIELD location_code 
			SELECT * 
			INTO pr_falocation.* 
			FROM falocation 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND location_code = tmp_glasset.location_code 
			IF status = notfound THEN 
				ERROR "Location ID NOT found - try window" 
				NEXT FIELD location_code 
			END IF 

				ON ACTION "LOOKUP" infield (book_code) 
					LET tmp_glasset.book_code = lookup_book(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME tmp_glasset.book_code 
					NEXT FIELD book_code 
					
				ON ACTION "LOOKUP" infield (facat_code) 
					LET tmp_glasset.facat_code = lookup_facat_code(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME tmp_glasset.facat_code 
					NEXT FIELD facat_code 
					
				ON ACTION "LOOKUP" infield (location_code) 
					LET tmp_glasset.location_code = lookup_location(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME tmp_glasset.location_code 
					NEXT FIELD location_code 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * 
				FROM glasset 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND book_code = tmp_glasset.book_code 
				AND facat_code = tmp_glasset.facat_code 
				AND location_code = tmp_glasset.location_code 
				IF status THEN 
					ERROR "GL account codes NOT found TO image" 
					NEXT FIELD book_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	CLOSE WINDOW wf145 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE tmp_glasset.* TO NULL 
	END IF 

	RETURN tmp_glasset.book_code, 
	tmp_glasset.facat_code, 
	tmp_glasset.location_code 

END FUNCTION 
