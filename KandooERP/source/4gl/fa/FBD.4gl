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

	Source code beautified by beautify.pl on 2020-01-03 10:36:59	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose   :   enter depreciation method by book by asset

GLOBALS 
	DEFINE 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_fabook RECORD LIKE fabook.*, 
	pr_fadepmethod RECORD LIKE fadepmethod.*, 
	pr_fabookdep RECORD LIKE fabookdep.*, 
	pr_famast RECORD LIKE famast.*, 
	start_flag, exist SMALLINT, 
	err_message CHAR(60), 
	query_text, where_part CHAR(300), 
	try_again CHAR(1) 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("FBD") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	OPEN WINDOW wf170 with FORM "F170" -- alch kd-757 
	CALL  windecoration_f("F170") -- alch kd-757 

	CALL query() 

	CLOSE WINDOW wf170 
END MAIN 

FUNCTION select_them() 

	IF start_flag = 0 THEN 
		LET start_flag = 1 
		MESSAGE "Enter criteria FOR selection - ESC TO begin search" 
		attribute(yellow) 
		CONSTRUCT BY NAME where_part ON fabookdep.book_code, 
		fabookdep.asset_code, 
		fabookdep.add_on_code, 
		fabookdep.depn_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","FBD","const-fabookdep-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
	END IF 

	LET query_text = "SELECT * ", 
	"FROM fabookdep ", 
	"WHERE fabookdep.cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", where_part clipped, 
	"ORDER BY fabookdep.cmpy_code, fabookdep.book_code, ", 
	"fabookdep.asset_code, fabookdep.add_on_code " 

	LET exist = false 
	IF int_flag OR quit_flag THEN 
		RETURN 
	ELSE 

		PREPARE choice FROM query_text 
		DECLARE selcurs SCROLL CURSOR FOR choice 
		OPEN selcurs 

		MESSAGE " " 

		FETCH selcurs INTO pr_fabookdep.* 
		IF status <> notfound THEN 
			LET exist = true 
		END IF 
	END IF 
END FUNCTION 

FUNCTION query() 

	DEFINE 
	tmp_depr LIKE fastatus.depr_amt 

	CLEAR FORM 
	LET exist = false 
	MENU "Depr/Asset " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","FBD","menu-depr_asset-1") -- alch kd-504 

		COMMAND "Query" "Search FOR depn rates / asset" 
			LET start_flag = 0 
			CALL select_them() 
			IF exist THEN 
				CALL show_it() 
			ELSE 
				ERROR "No asset satisfied the query criteria" 
			END IF 

		COMMAND KEY ("N",f21) "Next" "DISPLAY next selected asset/rate " 
			IF exist THEN 
				FETCH NEXT selcurs INTO pr_fabookdep.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the categories selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
				attribute(red) 
			END IF 

		COMMAND KEY ("P",f19) "Prev" "DISPLAY previous selected book/asset" 
			IF exist THEN 
				FETCH previous selcurs INTO pr_fabookdep.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the books/assets selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND "Add" "Enter new book/ asset /rate details" 
			INITIALIZE pr_fabookdep.* TO NULL 
			LET pr_fabookdep.asset_code = arg_val(1) 
			LET pr_fabookdep.add_on_code = arg_val(2) 
			CALL add_fn() 

		COMMAND "Del" "Delete a book/asset/rate" 
			IF exist THEN 
				# don't allow change IF depreciation has been charged
				LET tmp_depr = 0 
				SELECT depr_amt 
				INTO tmp_depr 
				FROM fastatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_fabookdep.asset_code 
				AND add_on_code = pr_fabookdep.add_on_code 
				AND book_code = pr_fabookdep.book_code 
				IF tmp_depr != 0 THEN 
					ERROR "Cannot delete - asset has been depreciated!" 
				ELSE 
					SELECT depr_amt 
					INTO tmp_depr 
					FROM faaudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = pr_fabookdep.asset_code 
					AND add_on_code = pr_fabookdep.add_on_code 
					AND book_code = pr_fabookdep.book_code 
					AND trans_ind = "D" 
					IF tmp_depr != 0 THEN 
						ERROR "Cannot delete - asset has been depreciated!", 
						" - (post batch)" 
					ELSE 
						DELETE FROM fabookdep WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND asset_code = pr_fabookdep.asset_code 
						AND add_on_code = pr_fabookdep.add_on_code 
						AND book_code = pr_fabookdep.book_code 
						ERROR "Deleted" 
						CALL select_them() 
					END IF 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 


		COMMAND "Change" "Alter existing record" 
			IF exist THEN 
				# don't allow change IF depreciation has been charged
				LET tmp_depr = 0 
				SELECT depr_amt 
				INTO tmp_depr 
				FROM fastatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = pr_fabookdep.asset_code 
				AND add_on_code = pr_fabookdep.add_on_code 
				AND book_code = pr_fabookdep.book_code 
				IF tmp_depr != 0 THEN 
					ERROR "Cannot change - asset has been depreciated ", 
					"- Use Menu F28" 
				ELSE 
					SELECT depr_amt 
					INTO tmp_depr 
					FROM faaudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND asset_code = pr_fabookdep.asset_code 
					AND add_on_code = pr_fabookdep.add_on_code 
					AND book_code = pr_fabookdep.book_code 
					AND trans_ind = "D" 
					IF tmp_depr != 0 THEN 
						ERROR "Cannot change - asset has been depreciated!", 
						" - (post batch)" 
					ELSE 
						CALL edit_fn() 
						CALL select_them() 
					END IF 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY(interrupt, escape) "DEL TO Exit" "Exit FROM this inquiry" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END MENU 
END FUNCTION 


FUNCTION show_it() 
	DISPLAY BY NAME pr_fabookdep.book_code, 
	pr_fabookdep.asset_code, 
	pr_fabookdep.add_on_code, 
	pr_fabookdep.depn_code 

END FUNCTION 

FUNCTION add_fn() 
	DEFINE 
	add_fabookdep RECORD LIKE fabookdep.* 

	CLEAR FORM 
	LET add_fabookdep.asset_code = pr_fabookdep.asset_code 
	LET add_fabookdep.add_on_code = pr_fabookdep.add_on_code 
	INPUT BY NAME add_fabookdep.book_code, 
	add_fabookdep.asset_code, 
	add_fabookdep.add_on_code, 
	add_fabookdep.depn_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FBD","inp-add_fabookdep-1") -- alch kd-504 

				ON ACTION "LOOKUP" infield (book_code) 
					LET add_fabookdep.book_code = lookup_book(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME add_fabookdep.book_code 

					NEXT FIELD book_code 

				ON ACTION "LOOKUP" infield (asset_code) 
					#LET add_fabookdep.asset_code = lookup_famast(glob_rec_kandoouser.cmpy_code)
					CALL lookup_famast(glob_rec_kandoouser.cmpy_code) RETURNING add_fabookdep.asset_code, 
					add_fabookdep.add_on_code 
					DISPLAY BY NAME add_fabookdep.asset_code 

					DISPLAY BY NAME add_fabookdep.add_on_code 

					NEXT FIELD asset_code 

				ON ACTION "LOOKUP" infield (depn_code) 
					LET add_fabookdep.depn_code = lookup_dep_code(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME add_fabookdep.depn_code 

					NEXT FIELD depn_code 


		AFTER FIELD book_code 
			SELECT * 
			INTO pr_fabook.* 
			FROM fabook 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			book_code = add_fabookdep.book_code 

			IF status = notfound THEN 
				ERROR "Book ID NOT found - try window" 
				NEXT FIELD book_code 
			ELSE 
				NEXT FIELD asset_code 
			END IF 

		AFTER FIELD add_on_code 
			SELECT * 
			INTO pr_famast.* 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			asset_code = add_fabookdep.asset_code AND 
			add_on_code = add_fabookdep.add_on_code 

			IF status = notfound THEN 
				ERROR "Asset ID NOT found - try window" 
				NEXT FIELD asset_code 
			ELSE 
				SELECT * 
				INTO pr_fabookdep.* 
				FROM fabookdep 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				book_code = add_fabookdep.book_code AND 
				asset_code = add_fabookdep.asset_code AND 
				add_on_code = add_fabookdep.add_on_code 

				IF status = notfound THEN 
					NEXT FIELD depn_code 
				ELSE 
					ERROR "This Book/Asset/Rate combination already exists" 
					NEXT FIELD book_code 
				END IF 
			END IF 

		AFTER FIELD depn_code 
			SELECT * 
			INTO pr_fadepmethod.* 
			FROM fadepmethod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND depn_code = add_fabookdep.depn_code 

			IF status = notfound THEN 
				ERROR "Depreciation Rate ID NOT found - try window" 
				NEXT FIELD depn_code 
			ELSE 
				SELECT * 
				FROM fabookdep 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				book_code = add_fabookdep.book_code AND 
				asset_code = add_fabookdep.asset_code AND 
				add_on_code = add_fabookdep.add_on_code AND 
				depn_code = add_fabookdep.depn_code 

				IF status <> notfound THEN 
					ERROR "This Book/Asset/Rate combination already exists" 
					NEXT FIELD book_code 
				END IF 
			END IF 
			LET add_fabookdep.cmpy_code = glob_rec_kandoouser.cmpy_code 
			GOTO bypass 
			LABEL recovery: 
			LET try_again = error_recover (err_message, status) 
			IF try_again != "Y" THEN 
				EXIT program 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 
				LET err_message = "FBD - Book / rate INSERT" 
				INSERT INTO fabookdep VALUES (add_fabookdep.*) 
			COMMIT WORK 

			MESSAGE "Record successfully added" 
			SLEEP 2 
			WHENEVER ERROR stop 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 

END FUNCTION 

FUNCTION edit_fn() 
	DEFINE 
	temp_book_code LIKE fabookdep.book_code, 
	temp_asset_code LIKE fabookdep.asset_code, 
	temp_add_on_code LIKE fabookdep.add_on_code 

	LET temp_book_code = pr_fabookdep.book_code 
	LET temp_asset_code = pr_fabookdep.asset_code 
	LET temp_add_on_code = pr_fabookdep.add_on_code 

	INPUT BY NAME pr_fabookdep.book_code, 
	pr_fabookdep.asset_code, 
	pr_fabookdep.add_on_code, 
	pr_fabookdep.depn_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","FBD","inp-pr_fabookdep-2") -- alch kd-504 

				ON ACTION "LOOKUP" infield (book_code) 
					LET pr_fabookdep.book_code = lookup_book(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_fabookdep.book_code 

					NEXT FIELD book_code 

				ON ACTION "LOOKUP" infield (asset_code) 
					#LET pr_fabookdep.asset_code = lookup_famast(glob_rec_kandoouser.cmpy_code)
					CALL lookup_famast(glob_rec_kandoouser.cmpy_code) RETURNING pr_fabookdep.asset_code, 
					pr_fabookdep.add_on_code 
					DISPLAY BY NAME pr_fabookdep.asset_code 

					DISPLAY BY NAME pr_fabookdep.add_on_code 

					NEXT FIELD asset_code 

				ON ACTION "LOOKUP" infield (depn_code) 
					LET pr_fabookdep.depn_code = lookup_dep_code(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_fabookdep.depn_code 

					NEXT FIELD depn_code 



		AFTER FIELD book_code 
			SELECT * 
			INTO pr_fabook.* 
			FROM fabook 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			book_code = pr_fabookdep.book_code 

			IF status = notfound THEN 
				ERROR "Book ID NOT found - try window" 
				NEXT FIELD book_code 
			END IF 

		AFTER FIELD asset_code 
			SELECT * 
			INTO pr_famast.* 
			FROM famast 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			asset_code = pr_fabookdep.asset_code AND 
			add_on_code = pr_fabookdep.add_on_code 

			IF status = notfound THEN 
				ERROR "Asset ID NOT found - try window" 
				NEXT FIELD asset_code 
			END IF 

		AFTER FIELD depn_code 
			SELECT * 
			INTO pr_fadepmethod.* 
			FROM fadepmethod 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			depn_code = pr_fabookdep.depn_code 

			IF status = notfound THEN 
				ERROR "Depreciation code NOT found - try window" 
				NEXT FIELD depn_code 
			END IF 


		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 
			THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
			ELSE 
				SELECT * 
				INTO pr_fabook.* 
				FROM fabook 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				book_code = pr_fabookdep.book_code 

				IF status = notfound THEN 
					ERROR "Book ID NOT found - try window" 
					NEXT FIELD book_code 
				END IF 

				SELECT * 
				INTO pr_famast.* 
				FROM famast 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				asset_code = pr_famast.asset_code AND 
				add_on_code = pr_famast.add_on_code 

				IF status = notfound THEN 
					ERROR "Asset ID NOT found - try window" 
					NEXT FIELD asset_code 
				END IF 

				SELECT * 
				INTO pr_fadepmethod.* 
				FROM fadepmethod 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				depn_code = pr_fadepmethod.depn_code 

				IF status = notfound THEN 
					ERROR "Depreciation Method code NOT found - try window" 
					NEXT FIELD depn_code 
				END IF 


				LET pr_fabookdep.cmpy_code = glob_rec_kandoouser.cmpy_code 
				GOTO bypass 
				LABEL recovery: 
				LET try_again = error_recover (err_message, status) 
				IF try_again != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 

				BEGIN WORK 
					LET err_message = "FBD - Book / Depreciation UPDATE" 
					WHENEVER ERROR CONTINUE 
					UPDATE fabookdep SET * = pr_fabookdep.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					book_code = temp_book_code AND 
					asset_code = temp_asset_code AND 
					add_on_code = temp_add_on_code 
					CASE 
						WHEN status = 0 
							MESSAGE "Record successfully updated" 
							SLEEP 2 
						WHEN status = -346 
							ERROR "The rate FOR this asset already exists - RECORD NOT updated" 
							SLEEP 2 
							LET pr_fabookdep.book_code = temp_book_code 
							LET pr_fabookdep.asset_code = temp_asset_code 
							LET pr_fabookdep.add_on_code = temp_add_on_code 
							DISPLAY BY NAME pr_fabookdep.book_code, 
							pr_fabookdep.asset_code, 
							pr_fabookdep.add_on_code 
						OTHERWISE 
							GOTO recovery 
					END CASE 
					WHENEVER ERROR GOTO recovery 
				COMMIT WORK 
				WHENEVER ERROR stop 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
END FUNCTION 
