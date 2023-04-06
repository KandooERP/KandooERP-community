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


# Purpose - Department Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pv_acct_code CHAR(18), 

	pr_mfgdept RECORD 
		dept_code LIKE mfgdept.dept_code, 
		desc_text LIKE mfgdept.desc_text, 
		wip_acct_code LIKE mfgdept.wip_acct_code 
	END RECORD, 

	pa_mfgdept array[100] OF RECORD 
		dept_code LIKE mfgdept.dept_code, 
		desc_text LIKE mfgdept.desc_text, 
		wip_acct_code LIKE mfgdept.wip_acct_code 
	END RECORD, 

	idx SMALLINT, 
	id_flag SMALLINT, 
	scrn SMALLINT, 
	cnt SMALLINT, 
	cnt1 SMALLINT, 
	err_flag SMALLINT 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("MZ4") -- albo 
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
		CLOSE WINDOW mz4 
	END WHILE 

END MAIN 



FUNCTION get_query() 

	DEFINE 
	where_part CHAR(512), 
	query_text CHAR(512) 

	OPEN WINDOW mz4 with FORM "M114" 
	CALL  windecoration_m("M114") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "Enter criteria FOR selection - ESC TO begin search "

	CONSTRUCT BY NAME where_part 
	ON dept_code, desc_text, wip_acct_code 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		MESSAGE "" 
		RETURN 
	END IF 

	LET msgresp = kandoomsg("M",1525,"") 
	# MESSAGE " Please wait ... "

	LET query_text = "SELECT dept_code, desc_text, wip_acct_code ", 
	"FROM mfgdept WHERE ", 
	"mfgdept.cmpy_code = \"", glob_rec_kandoouser.cmpy_code clipped, "\" AND ", 
	where_part clipped, 
	"ORDER BY dept_code" 

	PREPARE statement_1 FROM query_text 
	DECLARE mfgdept_set CURSOR FOR statement_1 

	LET idx = 0 
	FOREACH mfgdept_set INTO pr_mfgdept.* 
		IF idx >= 80 THEN 
			LET msgresp = kandoomsg("M",9699,"") 
			# ERROR " The first 80 rows have been selected "
			EXIT FOREACH 
		END IF 
		LET idx = idx + 1 
		LET pa_mfgdept[idx].dept_code = pr_mfgdept.dept_code 
		LET pa_mfgdept[idx].desc_text = pr_mfgdept.desc_text 
		LET pa_mfgdept[idx].wip_acct_code = pr_mfgdept.wip_acct_code 
	END FOREACH 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("M",9700,"") 
		# ERROR " No department satisfied the query criteria "
	END IF 

	CALL set_count(idx) 

END FUNCTION 



FUNCTION get_info() 

	DEFINE 
	fv_error SMALLINT 


	WHILE true 
		LET fv_error = false 
		LET msgresp = kandoomsg("M",1526,"") 
		# MESSAGE " F1 TO add, RETURN TO change, F2 TO delete"

		INPUT ARRAY pa_mfgdept WITHOUT DEFAULTS FROM sr_mfgdept.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_mfgdept.dept_code = pa_mfgdept[idx].dept_code 
				LET pr_mfgdept.desc_text = pa_mfgdept[idx].desc_text 
				LET pr_mfgdept.wip_acct_code = pa_mfgdept[idx].wip_acct_code 
				LET id_flag = 0 

			BEFORE INSERT 
				INITIALIZE pr_mfgdept.* TO NULL 

			AFTER FIELD dept_code 
				IF (pa_mfgdept[idx].dept_code IS null) THEN 
					IF (pa_mfgdept[idx].desc_text IS NOT null) THEN 
						LET msgresp = kandoomsg("M",9682,"") 
						#  ERROR " Department Code must be entered "
						NEXT FIELD dept_code 
					END IF 
				ELSE 
					IF (pa_mfgdept[idx].dept_code != pr_mfgdept.dept_code 
					OR pr_mfgdept.dept_code IS null) THEN 
						SELECT unique count(*) 
						INTO cnt 
						FROM mfgdept 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND dept_code = pa_mfgdept[idx].dept_code 

						IF (cnt != 0) THEN 
							LET msgresp = kandoomsg("M",9701,"") 
							# ERROR "Department Code must be unique"
							NEXT FIELD dept_code 
						END IF 
					END IF 
				END IF 

			AFTER FIELD desc_text 
				IF pa_mfgdept[idx].desc_text IS NULL THEN 
					# ERROR " You must enter a description "
					NEXT FIELD desc_text 
				END IF 

			AFTER FIELD wip_acct_code 
				IF pa_mfgdept[idx].wip_acct_code IS NOT NULL THEN 
					SELECT acct_code 
					FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = pa_mfgdept[idx].wip_acct_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9702,"") 
						# ERROR " Work In Progress Account NOT found"
						NEXT FIELD wip_acct_code 
					END IF 

				END IF 

			ON KEY (control-b) 
				LET pv_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 

				IF pv_acct_code IS NOT NULL THEN 
					LET pa_mfgdept[idx].wip_acct_code = pv_acct_code 
					DISPLAY BY NAME pa_mfgdept[idx].wip_acct_code 

				END IF 

			AFTER INSERT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 

				IF (pa_mfgdept[idx].dept_code IS NOT null) THEN 
					WHENEVER ERROR CONTINUE 

					INSERT INTO mfgdept 
					VALUES (glob_rec_kandoouser.cmpy_code, pa_mfgdept[idx].*, today, glob_rec_kandoouser.sign_on_code, "MZ4") 

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
					CLEAR sr_mfgdept[scrn].* 
					LET err_flag = 0 
				END IF 

			BEFORE DELETE 
				SELECT unique count(*) 
				INTO cnt1 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = pr_mfgdept.dept_code 

				IF (cnt1 != 0) THEN 
					LET msgresp = kandoomsg("M",9704,"") 
					# ERROR "Cannot delete - Department linked TO Work Centres"
					LET id_flag = 0 
					LET err_flag = -1 
					LET idx = idx + 1 
					LET fv_error = true 
					EXIT INPUT 
				ELSE 
					LET id_flag = -1 

					DELETE 
					FROM mfgdept 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dept_code = pr_mfgdept.dept_code 
				END IF 

			AFTER ROW 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF (pa_mfgdept[idx].dept_code IS NULL 
				AND pa_mfgdept[idx].desc_text IS null) THEN 
					LET id_flag = -1 
				END IF 

				IF ((err_flag = 0 
				AND id_flag = 0) 
				AND ((pr_mfgdept.dept_code != pa_mfgdept[idx].dept_code) 
				OR (pr_mfgdept.dept_code = pa_mfgdept[idx].dept_code))) THEN 

					UPDATE mfgdept 
					SET mfgdept.cmpy_code = glob_rec_kandoouser.cmpy_code, 
					mfgdept.dept_code = pa_mfgdept[idx].dept_code, 
					mfgdept.desc_text = pa_mfgdept[idx].desc_text, 
					mfgdept.wip_acct_code 
					= pa_mfgdept[idx].wip_acct_code, 
					mfgdept.last_change_date = today, 
					mfgdept.last_user_text = glob_rec_kandoouser.sign_on_code, 
					mfgdept.last_program_text = "MZ4" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dept_code = pr_mfgdept.dept_code 
				END IF 

				IF (err_flag = 0 
				AND id_flag = 0 
				AND (pa_mfgdept[idx].dept_code IS NOT NULL 
				AND pr_mfgdept.desc_text IS null)) THEN 

					WHENEVER ERROR CONTINUE 
					INSERT INTO mfgdept 
					VALUES (glob_rec_kandoouser.cmpy_code, pa_mfgdept[idx].*, today, glob_rec_kandoouser.sign_on_code, "MZ4") 

					IF status < 0 THEN 
						# ERROR "An error has occurred, enter information again"
						INITIALIZE pa_mfgdept[idx].* TO NULL 
						CLEAR sr_mfgdept[scrn].* 
					END IF 
					WHENEVER ERROR stop 
				END IF 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		IF NOT fv_error THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

END FUNCTION 
