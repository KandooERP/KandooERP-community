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

	Source code beautified by beautify.pl on 2020-01-02 18:38:36	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module LZ1 - Maintain Tariff Codes

GLOBALS 
	DEFINE pr_tariff RECORD LIKE tariff.* 
	DEFINE pt_tariff RECORD 
		tariff_code LIKE tariff.tariff_code, 
		duty_per LIKE tariff.duty_per, 
		desc_text LIKE tariff.desc_text 
	END RECORD 
	DEFINE pa_tariff DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			tariff_code LIKE tariff.tariff_code, 
			duty_per LIKE tariff.duty_per, 
			desc_text LIKE tariff.desc_text 
		END RECORD 
		DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
		DEFINE idx SMALLINT 
		DEFINE id_flag SMALLINT 

		DEFINE cnt SMALLINT 
		DEFINE err_flag SMALLINT 
		DEFINE query_text, sel_text CHAR(200) 

END GLOBALS 


FUNCTION db_tariff_filter_list(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_tariff DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			tariff_code LIKE tariff.tariff_code, 
			duty_per LIKE tariff.duty_per, 
			desc_text LIKE tariff.desc_text 
		END RECORD 
		DEFINE l_rec_tariff RECORD 
			tariff_code LIKE tariff.tariff_code, 
			duty_per LIKE tariff.duty_per, 
			desc_text LIKE tariff.desc_text 
		END RECORD 
		DEFINE l_idx SMALLINT 


		IF p_filter THEN 
			MESSAGE " Enter criteria - press ESC" attribute (yellow) 
			CONSTRUCT query_text 
			ON tariff_code, duty_per, desc_text 
			FROM sr_tariff[1].* 

				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET query_text = " 1=1 " 
			END IF 

		ELSE 
			LET query_text = " 1=1 " 
		END IF 

		LET sel_text = 
		"SELECT tariff_code, duty_per, desc_text ", 
		" FROM tariff WHERE ", 
		"cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ", 
		query_text clipped, 
		" ORDER BY tariff_code " 

		PREPARE tariffer FROM sel_text 
		DECLARE tariff_cur CURSOR FOR tariffer 

		LET l_idx = 0 
		FOREACH tariff_cur INTO l_rec_tariff.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_tariff[l_idx].tariff_code = l_rec_tariff.tariff_code 
			LET l_arr_rec_tariff[l_idx].duty_per = l_rec_tariff.duty_per 
			LET l_arr_rec_tariff[l_idx].desc_text = l_rec_tariff.desc_text 
			#         IF l_idx > 400 THEN
			#            ERROR "Only first 400 selected"
			#            EXIT FOREACH
			#         END IF
		END FOREACH 

		#      IF l_idx = 0 THEN
		#         MESSAGE "No Tariff code satisfies query" attribute (yellow)
		#         sleep 2
		#         continue WHILE
		#      END IF

		# MESSAGE "No Tariff code satisfies query" attribute (yellow)
		#sleep 2
		#EXIT WHILE
		#END WHILE

		RETURN l_arr_rec_tariff 
END FUNCTION 

MAIN 

	#Initial UI Init
	CALL setModuleId("LZ1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	LET pr_tariff.cmpy_code = glob_rec_kandoouser.cmpy_code 


	OPEN WINDOW wl114 with FORM "L114" 
	CALL windecoration_l("L114") -- albo kd-763 

	WHILE true 

		{
		      MESSAGE " Enter criteria - press ESC" attribute (yellow)
		      CONSTRUCT query_text
		         on tariff_code, duty_per, desc_text
		         FROM sr_tariff[1].*

		         ON ACTION "WEB-HELP"  -- albo  KD-375
		            CALL onlineHelp(getModuleId(),NULL)

		      END CONSTRUCT

		      IF int_flag OR quit_flag THEN
		         EXIT PROGRAM
		      END IF

		      LET sel_text =
		         "SELECT tariff_code, duty_per, desc_text ",
		         " FROM tariff WHERE ",
		         "cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ",
		         query_text clipped,
		         " ORDER BY tariff_code "

		      PREPARE tariffer FROM sel_text
		         DECLARE tariff_cur CURSOR FOR tariffer

		         LET idx = 0
		         FOREACH tariff_cur INTO pt_tariff.*
		               LET idx = idx + 1
		               LET pa_tariff[idx].tariff_code = pt_tariff.tariff_code
		               LET pa_tariff[idx].duty_per = pt_tariff.duty_per
		               LET pa_tariff[idx].desc_text = pt_tariff.desc_text
		         IF idx > 400 THEN
		            ERROR "Only first 400 selected"
		            EXIT FOREACH
		         END IF
		      END FOREACH

		      IF idx = 0 THEN
		         MESSAGE "No Tariff code satisfies query" attribute (yellow)
		         sleep 2
		         continue WHILE
		      END IF

		# MESSAGE "No Tariff code satisfies query" attribute (yellow)
		#sleep 2
		#EXIT WHILE
		#END WHILE


		      CALL set_count(idx)
		}

		CALL db_tariff_filter_list(false) RETURNING pa_tariff 

		MESSAGE " F1 TO add, RETURN TO change, F2 TO delete" 
		attribute (yellow) 

		INPUT ARRAY pa_tariff WITHOUT DEFAULTS FROM sr_tariff.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false ) 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "FILTER" 
				CALL db_tariff_filter_list(true) RETURNING pa_tariff 

			BEFORE ROW 
				LET idx = arr_curr() 
				#         LET scrn = scr_line()
				LET pr_tariff.tariff_code = pa_tariff[idx].tariff_code 
				LET pr_tariff.duty_per = pa_tariff[idx].duty_per 
				LET pr_tariff.desc_text = pa_tariff[idx].desc_text 
				LET id_flag = 0 

			ON KEY (control-e) 
				LET pa_tariff[idx].tariff_code = pr_tariff.tariff_code 
				LET pa_tariff[idx].duty_per = pr_tariff.duty_per 
				LET pa_tariff[idx].desc_text = pr_tariff.desc_text 

				#         DISPLAY pa_tariff[idx].* TO sr_tariff[scrn].*
				#         NEXT FIELD tariff_code

			AFTER FIELD tariff_code 
				IF (pa_tariff[idx].tariff_code IS null) THEN 
					IF (pa_tariff[idx].duty_per IS NOT null) THEN 
						ERROR "You must enter a Tariff code" 
						NEXT FIELD tariff_code 
					END IF 
				END IF 

			AFTER FIELD duty_per 
				IF (pa_tariff[idx].tariff_code != pr_tariff.tariff_code IS null) THEN 
					SELECT count(*) INTO cnt FROM tariff 
					WHERE tariff_code = pa_tariff[idx].tariff_code AND 
					cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (cnt != 0) THEN 
						ERROR "The Tariff code must be unique " 
						NEXT FIELD tariff_code 
					END IF 
				END IF 
				#      NEXT FIELD desc_text


			BEFORE INSERT 
				#DISPLAY "performing BEFORE INSERT"
				#sleep 3
				INITIALIZE pr_tariff.* TO NULL 
				LET pr_tariff.duty_per = 0 

			AFTER INSERT 
				#DISPLAY "performing AFTER INSERT"
				#sleep 3
				IF (pa_tariff[idx].tariff_code != pr_tariff.tariff_code IS null) THEN 
					SELECT count(*) INTO cnt FROM tariff 
					WHERE tariff_code = pa_tariff[idx].tariff_code AND 
					cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (cnt != 0) THEN 
						ERROR "The Tariff code must be unique " 
						NEXT FIELD tariff_code 
					END IF 
				END IF 
				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 
				LET pr_tariff.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF pa_tariff[idx].duty_per IS NULL THEN 
					LET pa_tariff[idx].duty_per = 0 
				END IF 
				IF (pa_tariff[idx].tariff_code IS NOT null) THEN 
					INSERT INTO tariff VALUES (pr_tariff.cmpy_code, 
					pa_tariff[idx].tariff_code, 
					pa_tariff[idx].duty_per, 
					pa_tariff[idx].desc_text) 
				END IF 

			AFTER DELETE 
				#DISPLAY "performing AFTER delete"
				#sleep 3
				LET id_flag = -1 
				DELETE FROM tariff 
				WHERE tariff_code = pr_tariff.tariff_code AND 
				cmpy_code = glob_rec_kandoouser.cmpy_code 

			AFTER ROW 
				IF (pa_tariff[idx].tariff_code IS NULL 
				AND pa_tariff[idx].duty_per IS NULL 
				AND pa_tariff[idx].desc_text IS null) THEN 
					LET id_flag = -1 
				END IF 

				IF (id_flag = 0 
				AND ((pr_tariff.tariff_code IS NULL AND 
				pa_tariff[idx].tariff_code IS NOT null) 
				OR (pr_tariff.tariff_code IS NOT NULL 
				AND pa_tariff[idx].tariff_code IS null) 
				OR (pr_tariff.desc_text IS NULL 
				AND pa_tariff[idx].desc_text IS NOT null) 
				OR (pr_tariff.desc_text IS NOT NULL 
				AND pa_tariff[idx].desc_text IS null) 
				OR (pr_tariff.duty_per IS NULL 
				AND pa_tariff[idx].duty_per IS NOT null) 
				OR (pr_tariff.duty_per IS NOT NULL 
				AND pa_tariff[idx].duty_per IS null) 
				OR (pr_tariff.tariff_code != pa_tariff[idx].tariff_code ) 
				OR (pr_tariff.duty_per != pa_tariff[idx].duty_per) 
				OR (pr_tariff.desc_text != pa_tariff[idx].desc_text))) THEN 
					IF pa_tariff[idx].duty_per IS NULL THEN LET pa_tariff[idx].duty_per = 0 END IF 
						UPDATE tariff SET 
						tariff.duty_per = pa_tariff[idx].duty_per, 
						tariff.desc_text = pa_tariff[idx].desc_text 
						WHERE tariff_code = pr_tariff.tariff_code AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 

					IF (id_flag = 0 
					AND (pa_tariff[idx].tariff_code IS NOT NULL 
					AND pr_tariff.tariff_code IS null)) THEN 
						IF pa_tariff[idx].duty_per IS NULL THEN LET pa_tariff[idx].duty_per = 0 END IF 
							WHENEVER ERROR CONTINUE 
							LET pr_tariff.cmpy_code = glob_rec_kandoouser.cmpy_code 
							INSERT INTO tariff VALUES (pr_tariff.cmpy_code, 
							pa_tariff[idx].tariff_code, 
							pa_tariff[idx].duty_per, 
							pa_tariff[idx].desc_text) 
							IF (status < 0) THEN 
								ERROR "An error has occurred - enter information again" 
								INITIALIZE pa_tariff[idx].* TO NULL 
								#                     CLEAR sr_tariff[scrn].*
							END IF 
							WHENEVER ERROR stop 
						END IF 

						#      ON KEY (control-w)
						#         CALL kandoohelp("")

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW wl114 
END MAIN 
