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

	Source code beautified by beautify.pl on 2020-01-02 18:38:37	$Id: $
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
# \brief module LZ2 - Maintain Shipment Status Codes


GLOBALS 

	DEFINE pr_shipstatus RECORD LIKE shipstatus.* 
	DEFINE pa_shipstatus DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			ship_status_code LIKE shipstatus.ship_status_code, 
			desc_text LIKE shipstatus.desc_text 
		END RECORD 
		DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
		DEFINE idx SMALLINT 
		DEFINE id_flag SMALLINT 
		DEFINE cnt SMALLINT 
		DEFINE err_flag SMALLINT 

END GLOBALS 




MAIN 
	#Initial UI Init
	CALL setModuleId("LZ2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET pr_shipstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE shipstatus_cur CURSOR FOR 
	SELECT * INTO pr_shipstatus.* FROM shipstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY ship_status_code 

	LET idx = 0 
	FOREACH shipstatus_cur 
		LET idx = idx + 1 
		LET pa_shipstatus[idx].ship_status_code = pr_shipstatus.ship_status_code 
		LET pa_shipstatus[idx].desc_text = pr_shipstatus.desc_text 

	END FOREACH 
	#      CALL set_count(idx)


	OPEN WINDOW l115 with FORM "L115" 
	CALL windecoration_l("L115") -- albo kd-763 
	LET msgresp = kandoomsg("U",1004,"") 
	#1004 F1 TO Add;  F2 TO Delete;  ENTER on Line TO Edit.

	WHILE true 

		INPUT ARRAY pa_shipstatus WITHOUT DEFAULTS FROM sr_shipstatus.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				#         LET scrn = scr_line()
				LET pr_shipstatus.ship_status_code = pa_shipstatus[idx].ship_status_code 
				LET pr_shipstatus.desc_text = pa_shipstatus[idx].desc_text 
				LET id_flag = 0 

			ON KEY (control-e) 
				LET pa_shipstatus[idx].ship_status_code = pr_shipstatus.ship_status_code 
				LET pa_shipstatus[idx].desc_text = pr_shipstatus.desc_text 

				#         DISPLAY pa_shipstatus[idx].* TO sr_shipstatus[scrn].*

				NEXT FIELD ship_status_code 

				#        BEFORE FIELD ship_status_code
				#           DISPLAY pa_shipstatus[idx].* TO sr_shipstatus[scrn].*

			AFTER FIELD ship_status_code 
				#           IF fgl_lastkey() = fgl_keyval("down")
				#           AND arr_curr() >= arr_count() THEN
				#              LET msgresp = kandoomsg("U",9001,"")
				#              #9001 There are no more rows in the direction you are going.
				#              NEXT FIELD ship_status_code
				#           END IF
				#           IF fgl_lastkey() = fgl_keyval("down")
				#           AND pa_shipstatus[idx+1].ship_status_code IS NULL THEN
				#              LET msgresp = kandoomsg("U",9001,"")
				#              #9001 There are no more rows in the direction you are going.
				#              NEXT FIELD ship_status_code
				#           END IF
				IF (pa_shipstatus[idx].ship_status_code != 
				pr_shipstatus.ship_status_code IS null) THEN 
					SELECT count(*) INTO cnt FROM shipstatus 
					WHERE ship_status_code = pa_shipstatus[idx].ship_status_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (cnt != 0) THEN 
						LET msgresp = kandoomsg("L",9022,"") 
						#9022 Status code must be unique.
						NEXT FIELD ship_status_code 
					END IF 
				END IF 

			BEFORE INSERT 
				INITIALIZE pr_shipstatus.* TO NULL 
			AFTER INSERT 
				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 
				LET pr_shipstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF pa_shipstatus[idx].ship_status_code IS NOT NULL THEN 
					INSERT INTO shipstatus VALUES (pr_shipstatus.cmpy_code, 
					pa_shipstatus[idx].ship_status_code, 
					pa_shipstatus[idx].desc_text) 
				END IF 

			AFTER DELETE 
				LET id_flag = -1 
				DELETE FROM shipstatus 
				WHERE ship_status_code = pr_shipstatus.ship_status_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			AFTER ROW 
				#                DISPLAY pa_shipstatus[idx].* TO sr_shipstatus[scrn].*

				IF (pa_shipstatus[idx].ship_status_code IS NULL 
				AND pa_shipstatus[idx].desc_text IS null) THEN 
					LET id_flag = -1 
				END IF 

				IF (id_flag = 0 
				AND ((pr_shipstatus.ship_status_code IS NULL AND 
				pa_shipstatus[idx].ship_status_code IS NOT null) 
				OR (pr_shipstatus.ship_status_code IS NOT NULL 
				AND pa_shipstatus[idx].ship_status_code IS null) 
				OR (pr_shipstatus.desc_text IS NULL 
				AND pa_shipstatus[idx].desc_text IS NOT null) 
				OR (pr_shipstatus.desc_text IS NOT NULL 
				AND pa_shipstatus[idx].desc_text IS null) 
				OR (pr_shipstatus.ship_status_code != pa_shipstatus[idx].ship_status_code ) 
				OR (pr_shipstatus.desc_text != pa_shipstatus[idx].desc_text))) THEN 

					UPDATE shipstatus SET 
					shipstatus.desc_text = pa_shipstatus[idx].desc_text 
					WHERE ship_status_code = pr_shipstatus.ship_status_code AND 
					cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 

				IF (id_flag = 0 
				AND (pa_shipstatus[idx].ship_status_code IS NOT NULL 
				AND pr_shipstatus.ship_status_code IS null)) THEN 
					WHENEVER ERROR CONTINUE 
					LET pr_shipstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
					INSERT INTO shipstatus VALUES (pr_shipstatus.cmpy_code, 
					pa_shipstatus[idx].ship_status_code, 
					pa_shipstatus[idx].desc_text) 
					IF (status < 0) THEN 
						LET msgresp = kandoomsg("L",9003,"") 
						#9003 An error has occurred;  Enter the information again.
						#                     INITIALIZE pa_shipstatus[idx].* TO NULL
						#               CLEAR sr_shipstatus[scrn].*
					END IF 
					WHENEVER ERROR stop 
				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF pa_shipstatus[idx].ship_status_code IS NULL THEN 
						FOR idx = arr_curr() TO arr_count() 
							LET pa_shipstatus[idx].* = pa_shipstatus[idx+1].* 
							IF arr_curr() = arr_count() THEN 
								INITIALIZE pa_shipstatus[idx].* TO NULL 
								EXIT FOR 
							END IF 
							#                        IF scrn <= 8 THEN
							#                           DISPLAY pa_shipstatus[idx].* TO
							#                                   sr_shipstatus[scrn].*
							#
							#                           LET scrn = scrn + 1
							#                        END IF
						END FOR 
						NEXT FIELD ship_status_code 
					END IF 
				END IF 
				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

	END WHILE 
	CLOSE WINDOW l115 
END MAIN 
