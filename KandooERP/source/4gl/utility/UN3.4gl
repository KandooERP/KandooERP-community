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

	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}



#
#   UN3 - Notes Transfer allows the user TO transfer customer notes
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("UN3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u532 with FORM "U532" 
	CALL windecoration_u("U532") 

	MENU " Note Information" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","UN3","menu-note_information") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "UPDATE" " Enter selection FOR note transfer " 
			CALL update_note() 
			NEXT option "Exit" 
		COMMAND KEY (interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW u532 
END MAIN 

FUNCTION update_note() 
	DEFINE 
	pr_notes RECORD LIKE notes.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_customernote RECORD LIKE customernote.*, 
	pr_kandoo_note_num DECIMAL(5,2), 
	winds_text CHAR(40), 
	err_message CHAR(40), 
	pr_note_count SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 

	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria
	INPUT BY NAME pr_notes.note_code, 
	pr_customer.cust_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","UN3","input-notes") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			CASE 
				WHEN infield(cust_code) 
					LET winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_customer.cust_code = winds_text 
						DISPLAY BY NAME pr_customer.cust_code 

					END IF 
			END CASE 

		AFTER FIELD note_code 
			IF pr_notes.note_code IS NULL THEN 
				LET l_msgresp = kandoomsg("H",9007,"") 
				#9007 Note code must be entered
				NEXT FIELD note_code 
			ELSE 
				LET pr_note_count = 0 
				SELECT count(*) INTO pr_note_count FROM notes 
				WHERE note_code = pr_notes.note_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF pr_note_count IS NULL 
				OR pr_note_count <= 0 THEN 
					LET l_msgresp = kandoomsg("H",9008,"") 
					#9008 Must be valid note code
					NEXT FIELD note_code 
				END IF 
			END IF 
		AFTER FIELD cust_code 
			IF pr_customer.cust_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9024,"") 
				#9024 Customer code must be entered
				NEXT FIELD cust_code 
			ELSE 
				SELECT * INTO pr_customer.* FROM customer 
				WHERE cust_code = pr_customer.cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9009,"") 
					#9009 Must be a valid customer - Try window
					NEXT FIELD cust_code 
				ELSE 
					DISPLAY BY NAME pr_customer.name_text 

				END IF 
			END IF 
		AFTER INPUT 
			IF NOT (quit_flag OR int_flag) THEN 
				IF pr_notes.note_code IS NULL THEN 
					LET l_msgresp = kandoomsg("H",9007,"") 
					#9007 Note code must be entered
					NEXT FIELD note_code 
				ELSE 
					LET pr_note_count = 0 
					SELECT count(*) INTO pr_note_count FROM notes 
					WHERE note_code = pr_notes.note_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF pr_note_count IS NULL 
					OR pr_note_count <= 0 THEN 
						LET l_msgresp = kandoomsg("H",9008,"") 
						#9008 Must be valid note code
						NEXT FIELD note_code 
					END IF 
				END IF 
				IF pr_customer.cust_code IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9024,"") 
					#9024 Customer code must be entered
					NEXT FIELD cust_code 
				ELSE 
					SELECT * INTO pr_customer.* FROM customer 
					WHERE cust_code = pr_customer.cust_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",9009,"") 
						#9009 Must be a valid customer - Try window
						NEXT FIELD cust_code 
					ELSE 
						DISPLAY BY NAME pr_customer.name_text 

					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating database - Please wait
	DECLARE c_notes CURSOR FOR 
	SELECT * FROM notes 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND note_code = pr_notes.note_code 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		SELECT max(note_num) INTO pr_kandoo_note_num FROM customernote 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.cust_code 
		AND note_date = today 
		IF pr_kandoo_note_num IS NULL THEN 
			LET pr_kandoo_note_num = 0 
		END IF 
		FOREACH c_notes INTO pr_notes.* 
			LET pr_customernote.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_customernote.cust_code = pr_customer.cust_code 
			LET pr_customernote.note_date = today 
			LET pr_kandoo_note_num = pr_kandoo_note_num + 1 
			LET pr_customernote.note_num = pr_kandoo_note_num 
			LET pr_customernote.note_text = pr_notes.note_text 
			INSERT INTO customernote VALUES (pr_customernote.*) 
		END FOREACH 
	COMMIT WORK 
	RETURN 
END FUNCTION