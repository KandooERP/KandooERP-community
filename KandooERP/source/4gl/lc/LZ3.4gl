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
# \brief module LZ3 - Maintain Shipment Type Codes

GLOBALS 
	DEFINE pr_shiptype RECORD LIKE shiptype.* 
	DEFINE pt_shiptype RECORD 
		ship_type_code LIKE shiptype.ship_type_code, 
		desc_text LIKE shiptype.desc_text 
	END RECORD 
	DEFINE pa_shiptype DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			ship_type_code LIKE shiptype.ship_type_code, 
			desc_text LIKE shiptype.desc_text 
		END RECORD 
		DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
		DEFINE idx SMALLINT 
		DEFINE id_flag SMALLINT 
		DEFINE cnt SMALLINT 
		DEFINE err_flag SMALLINT 

		DEFINE query_text CHAR(500) 
		DEFINE sel_text CHAR(500) 

END GLOBALS 

FUNCTION db_shiptype_filter_list_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_shiptype RECORD 
		ship_type_code LIKE shiptype.ship_type_code, 
		desc_text LIKE shiptype.desc_text 
	END RECORD 
	DEFINE l_arr_rec_shiptype DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			ship_type_code LIKE shiptype.ship_type_code, 
			desc_text LIKE shiptype.desc_text 
		END RECORD 
		DEFINE l_idx SMALLINT 

		IF p_filter THEN 
			MESSAGE " Enter criteria - press ESC" attribute (yellow) 
			CONSTRUCT query_text 
			ON ship_type_code, desc_text 
			FROM sr_shiptype[1].* 

				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET query_text = " 1=1 " 
			END IF 


		ELSE 
			LET query_text = " 1=1 " 
		END IF 

		LET sel_text = "SELECT ship_type_code, desc_text ", 
		" FROM shiptype WHERE ", 
		query_text clipped, 
		" AND cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
		" ORDER BY ship_type_code " 



		PREPARE shiptypeer FROM sel_text 
		DECLARE shiptype_cur CURSOR FOR shiptypeer 

		LET l_idx = 0 
		FOREACH shiptype_cur INTO l_rec_shiptype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_shiptype[l_idx].ship_type_code = l_rec_shiptype.ship_type_code 
			LET l_arr_rec_shiptype[l_idx].desc_text = l_rec_shiptype.desc_text 
			#         IF l_idx > 400 THEN
			#            ERROR "Only first 400 selected"
			#            EXIT FOREACH
			#         END IF
		END FOREACH 

		IF l_idx = 0 THEN 
			MESSAGE "No Shipment type code satisfies query" attribute (yellow) 
		END IF 

		RETURN l_arr_rec_shiptype 
END FUNCTION 


MAIN 

	#Initial UI Init
	CALL setModuleId("LZ3") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	LET pr_shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW wl133 with FORM "L133" 
	CALL windecoration_l("L133") -- albo kd-763 

	WHILE true 

		CALL db_shiptype_filter_list_datasource(false) RETURNING pa_shiptype 
		#      CALL set_count(idx)
		MESSAGE " F1 TO add, RETURN TO change, F2 TO delete" 
		attribute (yellow) 

		INPUT ARRAY pa_shiptype WITHOUT DEFAULTS FROM sr_shiptype.* attributes(UNBUFFERED, auto append = false, append ROW = false) 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "FILTER" 
				CALL db_shiptype_filter_list_datasource(true) RETURNING pa_shiptype 

			BEFORE ROW 
				LET idx = arr_curr() 
				#            LET scrn = scr_line()
				LET pr_shiptype.ship_type_code = pa_shiptype[idx].ship_type_code 
				LET pr_shiptype.desc_text = pa_shiptype[idx].desc_text 
				LET id_flag = 0 

			ON KEY (control-e) 
				LET pa_shiptype[idx].ship_type_code = pr_shiptype.ship_type_code 
				LET pa_shiptype[idx].desc_text = pr_shiptype.desc_text 
				#            DISPLAY pa_shiptype[idx].* TO sr_shiptype[scrn].*
				NEXT FIELD ship_type_code 

			BEFORE INSERT 
				INITIALIZE pr_shiptype.* TO NULL 

			AFTER INSERT 
				IF (pa_shiptype[idx].ship_type_code != pr_shiptype.ship_type_code IS null) THEN 
					SELECT count(*) INTO cnt FROM shiptype 
					WHERE ship_type_code = pa_shiptype[idx].ship_type_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (cnt != 0) THEN 
						ERROR "The Shipment type code must be unique " 
						NEXT FIELD ship_type_code 
					END IF 
				END IF 
				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 
				LET pr_shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (pa_shiptype[idx].ship_type_code IS NOT null) THEN 
					INSERT INTO shiptype VALUES (pr_shiptype.cmpy_code, 
					pa_shiptype[idx].ship_type_code, 
					pa_shiptype[idx].desc_text) 
				END IF 
			AFTER DELETE 
				LET id_flag = -1 
				DELETE FROM shiptype 
				WHERE ship_type_code = pr_shiptype.ship_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AFTER ROW 
				IF (pa_shiptype[idx].ship_type_code IS NULL 
				AND pa_shiptype[idx].desc_text IS null) THEN 
					LET id_flag = -1 
				END IF 
				IF (id_flag = 0 
				AND ((pr_shiptype.ship_type_code IS NULL 
				AND pa_shiptype[idx].ship_type_code IS NOT null) 
				OR (pr_shiptype.ship_type_code IS NOT NULL 
				AND pa_shiptype[idx].ship_type_code IS null) 
				OR (pr_shiptype.desc_text IS NULL 
				AND pa_shiptype[idx].desc_text IS NOT null) 
				OR (pr_shiptype.desc_text IS NOT NULL 
				AND pa_shiptype[idx].desc_text IS null) 
				OR (pr_shiptype.ship_type_code != pa_shiptype[idx].ship_type_code ) 
				OR (pr_shiptype.desc_text != pa_shiptype[idx].desc_text))) THEN 
					UPDATE shiptype SET 
					shiptype.desc_text = pa_shiptype[idx].desc_text 
					WHERE ship_type_code = pr_shiptype.ship_type_code AND 
					cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
				IF (id_flag = 0 
				AND (pa_shiptype[idx].ship_type_code IS NOT NULL 
				AND pr_shiptype.ship_type_code IS null)) THEN 
					WHENEVER ERROR CONTINUE 
					LET pr_shiptype.cmpy_code = glob_rec_kandoouser.cmpy_code 
					INSERT INTO shiptype VALUES (pr_shiptype.cmpy_code, 
					pa_shiptype[idx].ship_type_code, 
					pa_shiptype[idx].desc_text) 
					IF (status < 0) THEN 
						ERROR "An error has occurred - enter information again" 
						INITIALIZE pa_shiptype[idx].* TO NULL 
						#                   CLEAR sr_shiptype[scrn].*
					END IF 
					WHENEVER ERROR stop 
				END IF 
				#         ON KEY (control-w)
				#            CALL kandoohelp("")

		END INPUT 

		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT WHILE 
			#      ELSE
			#         EXIT WHILE
		END IF 
	END WHILE 

	CLOSE WINDOW wl133 

END MAIN 
