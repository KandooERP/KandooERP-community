# Vendor Notes P110
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:17	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 

############################################################
# MAIN
#
# module P13 allows the user TO enter AND maintain notes
# on each vendor by date
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("P13") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_p_ap() #init p/ap module 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	LET l_msgresp = "Y" 

	WHILE l_msgresp = "Y" 
		CALL notes(get_ku_cmpy_code()) 
		CLOSE WINDOW wp110 
		LET l_msgresp = "Y" 
	END WHILE 

END MAIN 


############################################################
# FUNCTION notes(p_cmpy)
############################################################
FUNCTION notes(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_last_date DATE 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_rec_vendor_code 
	RECORD 
		vend_code LIKE vendor.vend_code 
	END RECORD 
	DEFINE l_arr_rec_vendornote DYNAMIC ARRAY OF 
	RECORD --array[200] OF RECORD 
		note_date LIKE vendornote.note_date, 
		note_text LIKE vendornote.note_text 
	END RECORD 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendornote RECORD LIKE vendornote.* 
	DEFINE i SMALLINT

	OPTIONS INPUT NO WRAP 

	OPEN WINDOW wp110 with FORM "P110" 
	CALL windecoration_p("P110") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 


	--	CALL fgl_winmessage("@eric","This OPEN source program did NOT pass our Maia acceptance criteriad. Please re-generate this","info")
	MESSAGE " Enter Vendor ID AND Date FOR beginning of scan" 
	#attribute (yellow)
	LET l_rec_vendornote.note_date = today 

	INPUT BY NAME l_rec_vendor_code.vend_code, l_rec_vendornote.note_date WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P13","inp-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Lookup" 
			LET l_rec_vendor_code.vend_code = vendorlookup(l_rec_vendor_code.vend_code) 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET l_rec_vendor_code.vend_code = show_vend(p_cmpy,l_rec_vendor_code.vend_code) 
			DISPLAY BY NAME l_rec_vendor_code.vend_code 

			NEXT FIELD vend_code 



		AFTER FIELD vend_code 
			SELECT * 
			INTO l_rec_vendor.* 
			FROM vendor 
			WHERE vendor.cmpy_code = p_cmpy 
			AND vendor.vend_code = l_rec_vendor_code.vend_code 
			IF (status = NOTFOUND) THEN 
				ERROR "Vendor RECORD NOT found, try again" 
				NEXT FIELD vend_code 
			ELSE 
				DISPLAY BY NAME l_rec_vendor.name_text, 
				l_rec_vendor.contact_text, 
				l_rec_vendor.tele_text 

			END IF 

		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 
			THEN 
				EXIT PROGRAM 
			ELSE 
				#MESSAGE ""
				DECLARE c_note CURSOR FOR 
				SELECT * 
				INTO l_rec_vendornote.* 
				FROM vendornote 
				WHERE vendornote.cmpy_code = p_cmpy 
				AND vendornote.vend_code = l_rec_vendor_code.vend_code 
				AND vendornote.note_date >= l_rec_vendornote.note_date 
				ORDER BY vend_code, note_date 
			END IF 

			LET l_idx = 0 
			CALL l_arr_rec_vendornote.clear() 
			FOREACH c_note 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_vendornote[l_idx].note_date = l_rec_vendornote.note_date 
				LET l_arr_rec_vendornote[l_idx].note_text = l_rec_vendornote.note_text 
			END FOREACH 
			#CALL set_count(l_idx)

			DISPLAY ARRAY l_arr_rec_vendornote TO sr_vendornote.* WITHOUT SCROLL 
			END DISPLAY 

	END INPUT 
	OPTIONS INPUT WRAP
	
	MESSAGE " F1 TO add, RETURN on line TO change, ESC FOR new vendor" 
	#attribute (yellow)

	INPUT ARRAY l_arr_rec_vendornote WITHOUT DEFAULTS FROM sr_vendornote.* 
	attributes( 
	INSERT ROW = false, 
	#DELETE ROW = FALSE,
	append ROW = true, 
	auto append = TRUE, unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P13","inp-arr-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_vendornote.note_date = l_arr_rec_vendornote[l_idx].note_date 
			LET l_rec_vendornote.note_text = l_arr_rec_vendornote[l_idx].note_text 

		AFTER FIELD note_date 
			#MESSAGE ""
			IF (l_arr_rec_vendornote[l_idx].note_date IS null) THEN 
				IF (l_arr_rec_vendornote[l_idx].note_text IS NOT null) THEN 
					ERROR "You must enter a Date FOR the Note" 
				END IF 
			ELSE 
				IF (l_arr_rec_vendornote[l_idx].note_date != l_rec_vendornote.note_date 
				OR l_rec_vendornote.note_date IS null) THEN 
					SELECT count(*) 
					INTO l_cnt 
					FROM vendornote 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_vendor_code.vend_code 
					AND note_date = l_arr_rec_vendornote[l_idx].note_date 
					IF (l_cnt != 0) THEN 
						MESSAGE "Your notes will overwrite existing notes" 
					END IF 
				END IF 
			END IF 

		BEFORE INSERT 
			#ON ACTION "APPEND"
			LET l_idx = arr_curr() 
			LET l_arr_rec_vendornote[l_idx].note_date = CURRENT --today 
			#LET scrn = scr_line()
			LET l_arr_rec_vendornote[l_idx].note_date = current 
			#display
			#l_arr_rec_vendornote[l_idx].note_date
			#TO
			#sr_vendornote[scrn].note_date



		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 
			THEN 
			ELSE 
				LET l_rec_vendornote.cmpy_code = p_cmpy 
				LET l_rec_vendornote.vend_code = l_rec_vendor_code.vend_code 
				LET l_last_date = today + 100 
				FOR i = 1 TO arr_count() 
					# delete off all current notes FOR that day
					IF l_arr_rec_vendornote[i].note_date != l_last_date 
					THEN 
						DELETE FROM vendornote WHERE cmpy_code = p_cmpy 
						AND vend_code = l_rec_vendor_code.vend_code 
						AND note_date = l_arr_rec_vendornote[i].note_date 
						LET l_last_date = l_arr_rec_vendornote[i].note_date 
					END IF 
					IF (l_arr_rec_vendornote[i].note_text IS NOT null) 
					THEN 
						INSERT INTO vendornote VALUES 
						(l_rec_vendornote.cmpy_code, 
						l_rec_vendor_code.vend_code, 
						l_arr_rec_vendornote[i].note_date, 
						l_arr_rec_vendornote[i].note_text) 
					END IF 
				END FOR 
			END IF 

	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION 




