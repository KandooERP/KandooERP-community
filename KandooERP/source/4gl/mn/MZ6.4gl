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

	Source code beautified by beautify.pl on 2020-01-02 17:31:37	$Id: $
}


# Purpose - Calendar Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 

	pr_calendar RECORD 
		cmpy_code LIKE calendar.cmpy_code, 
		calendar_date LIKE calendar.calendar_date, 
		desc_text LIKE calendar.desc_text, 
		#            available_ind    LIKE calendar.available_ind
		available_ind LIKE calendar.available_flag 
	END RECORD, 
	pa_calendar array[600] OF RECORD 
		calendar_date LIKE calendar.calendar_date, 
		desc_text LIKE calendar.desc_text, 
		#available_ind    LIKE calendar.available_ind
		available_ind LIKE calendar.available_flag 
	END RECORD, 
	idx SMALLINT, 
	id_flag SMALLINT, 
	scrn SMALLINT, 
	cnt SMALLINT, 
	err_flag SMALLINT 

END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("MZ6") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	WHILE true 
		CALL get_query() 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		CALL get_info() 
		CLOSE WINDOW m172 
	END WHILE 

END MAIN 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION get_query() 

	DEFINE 
	where_part CHAR(512), 
	query_text CHAR(512) 

	OPEN WINDOW m172 with FORM "M172" 
	CALL  windecoration_m("M172") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") # MESSAGE " Enter criteria FOR selection - ESC TO begin search "

	CONSTRUCT BY NAME where_part 
	ON calendar_date, desc_text, available_flag -- huho fixed orginal was FIELD available_ind which does NOT exist in db OR FORM 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		MESSAGE "" 
		RETURN 
	END IF 

	LET msgresp = kandoomsg("M",1525,"") # MESSAGE " Please wait ... "

	LET query_text = "SELECT * FROM calendar ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	where_part clipped, 
	" ORDER BY calendar_date" 

	PREPARE statement_1 FROM query_text 
	DECLARE calendar_set CURSOR FOR statement_1 

	LET idx = 0 
	FOREACH calendar_set INTO pr_calendar.* 
		IF idx >= 500 THEN 
			LET msgresp = kandoomsg("M",9713,"") 
			# ERROR " The first 500 rows have been selected "
			EXIT FOREACH 
		END IF 
		LET idx = idx + 1 
		LET pa_calendar[idx].calendar_date = pr_calendar.calendar_date 
		LET pa_calendar[idx].desc_text = pr_calendar.desc_text 
		LET pa_calendar[idx].available_ind = pr_calendar.available_ind 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("M",9714,"") 
		# ERROR " No calendar dates satisfied the query criteria "
	END IF 
	CALL set_count(idx) 
END FUNCTION #get_query 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION get_info() 
	LET msgresp = kandoomsg("M",1526,"") 
	# MESSAGE " F1 TO add, RETURN TO change, F2 TO delete"

	INPUT ARRAY pa_calendar WITHOUT DEFAULTS FROM sr_calendar.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_calendar.calendar_date = pa_calendar[idx].calendar_date 
			LET pr_calendar.desc_text = pa_calendar[idx].desc_text 
			LET pr_calendar.available_ind = pa_calendar[idx].available_ind 
			LET id_flag = 0 

		BEFORE INSERT 
			INITIALIZE pr_calendar.* TO NULL 

		AFTER FIELD calendar_date 
			IF (pa_calendar[idx].calendar_date IS null) THEN 
				IF (pa_calendar[idx].desc_text IS NOT null) THEN 
					LET msgresp = kandoomsg("M",9715,"") 
					# ERROR " Calendar date must be entered "
					NEXT FIELD calendar_date 
				END IF 
			ELSE 
				IF (pa_calendar[idx].calendar_date != pr_calendar.calendar_date 
				OR pr_calendar.calendar_date IS null) THEN 
					SELECT unique count(*) 
					INTO cnt 
					FROM calendar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND calendar_date = pa_calendar[idx].calendar_date 

					IF (cnt != 0) THEN 
						LET msgresp = kandoomsg("M",9716,"") 
						# ERROR "Calendar date must be unique"
						NEXT FIELD calendar_date 
					END IF 
				END IF 
			END IF 

		AFTER FIELD available_ind 
			IF pa_calendar[idx].available_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR " You must enter a response "
				NEXT FIELD available_ind 
			END IF 

		AFTER INSERT 
			IF int_flag 
			OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			LET status = 0 
			LET id_flag = -1 
			LET err_flag = 0 

			IF (pa_calendar[idx].calendar_date IS NOT null) THEN 
				WHENEVER ERROR CONTINUE 

				INSERT INTO calendar 
				VALUES (glob_rec_kandoouser.cmpy_code, pa_calendar[idx].*, today, glob_rec_kandoouser.sign_on_code, "MZ6") 

				IF (status < 0) THEN 
					LET err_flag = -1 
				END IF 
				WHENEVER ERROR stop 
			ELSE 
				LET err_flag = -1 
			END IF 

			IF (err_flag < 0) THEN 
				LET msgresp = kandoomsg("M",9703,"") 
				# ERROR " An error has occurred, enter information again"
				CLEAR sr_calendar[scrn].* 
				LET err_flag = 0 
			END IF 

		AFTER DELETE 
			LET id_flag = -1 
			DELETE FROM calendar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND calendar_date = pr_calendar.calendar_date 

		AFTER ROW 
			IF int_flag 
			OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF (pa_calendar[idx].calendar_date IS NULL 
			AND pa_calendar[idx].desc_text IS null) THEN 
				LET id_flag = -1 
			END IF 

			IF (id_flag = 0 
			AND (pr_calendar.calendar_date != pa_calendar[idx].calendar_date 
			OR pr_calendar.desc_text != pa_calendar[idx].desc_text 
			OR pr_calendar.available_ind 
			!= pa_calendar[idx].available_ind)) THEN 

				UPDATE calendar 
				SET (calendar.calendar_date, calendar.desc_text, 
				calendar.available_ind, calendar.last_change_date, 
				calendar.last_user_text, calendar.last_program_text) 
				= (pa_calendar[idx].calendar_date, 
				pa_calendar[idx].desc_text, 
				pa_calendar[idx].available_ind, 
				today, glob_rec_kandoouser.sign_on_code, "MZ6") 
				WHERE calendar_date = pr_calendar.calendar_date 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			IF (id_flag = 0 
			AND (pa_calendar[idx].calendar_date IS NOT NULL 
			AND pr_calendar.desc_text IS null)) THEN 
				WHENEVER ERROR CONTINUE 

				INSERT INTO calendar 
				VALUES (glob_rec_kandoouser.cmpy_code, pa_calendar[idx].*, today, glob_rec_kandoouser.sign_on_code, "MZ6") 

				IF (status < 0) THEN 
					LET msgresp = kandoomsg("M",9703,"") 
					# ERROR "An error has occurred, enter information again"
					INITIALIZE pa_calendar[idx].* TO NULL 
					CLEAR sr_calendar[scrn].* 
				END IF 
				WHENEVER ERROR stop 
			END IF 
	END INPUT 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
