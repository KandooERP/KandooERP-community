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

	Source code beautified by beautify.pl on 2020-01-03 18:54:45	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rowid INTEGER 

###################################################################
# MAIN
#
# \file
# \brief module U52 - Street Maintenance
#
###################################################################
MAIN
	DEFINE l_msgresp LIKE language.yes_flag
	 
	#Initial UI Init
	CALL setModuleId("U52") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	OPEN WINDOW u116 with FORM "U116" 
	CALL windecoration_u("U116") 

	#   WHILE select_street()
	CALL scan_street() 
	#   END WHILE
	CLOSE WINDOW u116 
END MAIN 


###################################################################
# FUNCTION select_street(p_filter)
# RETURN l_arr_rec_street, l_arr_rec_suburb
#
# CONSTRUCT, Cursor for street
###################################################################
FUNCTION select_street(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_rec_street DYNAMIC ARRAY OF t_rec_street_st_ty_su_with_scrollflag 
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_ri_mn_rt_si_sc 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING
	DEFINE l_msgresp LIKE language.yes_flag
		 
	IF p_filter THEN 
		CLEAR FORM 
		LET modu_rowid = 0 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria;  OK TO Continue"
		CONSTRUCT BY NAME l_where_text ON street_text, 
		st_type_text, 
		suburb_text, 
		state_code, 
		post_code, 
		source_ind, 
		map_number, 
		ref_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U52","construct-street-suburb") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET modu_rowid = 0 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 " Searching database;  OK TO Continue.
	LET l_query_text = "SELECT street.rowid, street.*,suburb.* ", 
	"FROM street,suburb ", 
	"WHERE street.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND suburb.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND suburb.suburb_code = street.suburb_code ", 
	"AND ", l_where_text clipped, " ", 
	"ORDER BY street_text,st_type_text,suburb_text,state_code" 

	PREPARE s_street FROM l_query_text 
	DECLARE c_street CURSOR FOR s_street 
	LET l_idx = 0 
	FOREACH c_street INTO modu_rowid,l_rec_street.*,l_rec_suburb.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_street[l_idx].street_text = l_rec_street.street_text 
		LET l_arr_rec_street[l_idx].st_type_text = l_rec_street.st_type_text 
		LET l_arr_rec_street[l_idx].suburb_text = l_rec_suburb.suburb_text 
		LET l_arr_rec_suburb[l_idx].row_id = modu_rowid 
		LET l_arr_rec_suburb[l_idx].map_number = l_rec_street.map_number 
		LET l_arr_rec_suburb[l_idx].ref_text = l_rec_street.ref_text 
		LET l_arr_rec_suburb[l_idx].source_ind = l_rec_street.source_ind 
		LET l_arr_rec_suburb[l_idx].suburb_code = l_rec_street.suburb_code 
		#      IF l_idx = 500 THEN
		#         LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_street.getLength()) 
	#9113 l_idx records selected

	RETURN l_arr_rec_street, l_arr_rec_suburb 
END FUNCTION 


###################################################################
# FUNCTION scan_street()
# RETURN
#
# List for all streets
###################################################################
FUNCTION scan_street() 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_rec_street DYNAMIC ARRAY OF t_rec_street_st_ty_su_with_scrollflag 
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_ri_mn_rt_si_sc 
	DEFINE l_msgresp LIKE language.yes_flag
	
	#      l_arr_rec_street array[500] of record
	#         scroll_flag CHAR(1),
	#         street_text LIKE street.street_text,
	#         st_type_text LIKE street.st_type_text,
	#         suburb_text LIKE suburb.suburb_text
	#      END RECORD,

	#		array[500] OF
	#		RECORD
	#         rowid INTEGER,
	#         map_number LIKE street.map_number,
	#         ref_text LIKE street.ref_text,
	#         source_ind LIKE street.source_ind,
	#         suburb_code LIKE suburb.suburb_code
	#      END RECORD

	#cmpy_code            char(2)                                 no
	#street_text          nchar(50)                               no
	#st_type_text         nchar(10)                               no
	#suburb_code          integer                                 no
	#map_number           char(4)                                 no
	#ref_text             nchar(10)                               no
	#source_ind           char(1)

	DEFINE l_street_cnt INTEGER 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE x SMALLINT 

	DEFINE l_winds_text CHAR(40) 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE msgstr STRING 

	IF db_street_get_count() > 1000 THEN 
		CALL select_street(true) RETURNING l_arr_rec_street, l_arr_rec_suburb 
	ELSE 
		CALL select_street(false) RETURNING l_arr_rec_street, l_arr_rec_suburb 
	END IF 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	#   IF l_arr_rec_street.getLength() = 0 THEN
	#      LET l_idx = 1
	#      INITIALIZE l_arr_rec_suburb[1].* TO NULL
	#      INITIALIZE l_arr_rec_street[1].* TO NULL
	#   END IF

	WHENEVER ERROR stop 
	OPTIONS SQL interrupt off 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	#   CALL set_count(l_idx)
	LET l_msgresp = kandoomsg("W",1003,"") 

	#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	INPUT ARRAY l_arr_rec_street WITHOUT DEFAULTS FROM sr_street.* attribute(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false, INSERT ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U52","input-arr-street") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#make fields read only (except scroll flag=
		BEFORE FIELD street_text 
			NEXT FIELD scroll_flag 

		BEFORE FIELD st_type_text 
			NEXT FIELD scroll_flag 

		BEFORE FIELD suburb_text 
			NEXT FIELD scroll_flag 

			#Lookup for suburb_text (note text, not the code/FK
		ON KEY (control-b) infield (suburb_text) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_wsub(glob_rec_kandoouser.cmpy_code) 

			IF l_winds_text IS NOT NULL THEN 
				LET l_arr_rec_street[l_idx].suburb_text = l_winds_text 
				SELECT * INTO l_rec_suburb.* 
				FROM suburb 
				WHERE suburb_text = l_arr_rec_street[l_idx].suburb_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME l_rec_suburb.suburb_text 
			END IF 

			OPTIONS INSERT KEY f1 #do we NEED this ? 
			OPTIONS DELETE KEY f36 

			NEXT FIELD suburb_text 

		ON ACTION "DELETE" 

			FOR i = 1 TO l_arr_rec_street.getlength() 
				IF l_arr_rec_street[i].scroll_flag = "*" THEN 
					LET l_del_cnt = l_del_cnt +1 
				END IF 
			END FOR 
			IF l_del_cnt > 0 THEN 
				LET l_msgresp = kandoomsg("W",8002,l_del_cnt) 
				#8002 Confirm TO Delete ",l_del_cnt," Street(s)? (Y/N)"
				IF l_msgresp = "Y" THEN 
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_street[l_idx].scroll_flag = "*" THEN 
							DELETE FROM street 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND street_text = l_arr_rec_street[l_idx].street_text 
							AND st_type_text = l_arr_rec_street[l_idx].st_type_text 
							AND suburb_code = l_arr_rec_suburb[l_idx].suburb_code 
							AND map_number = l_arr_rec_suburb[l_idx].map_number 
							AND ref_text = l_arr_rec_suburb[l_idx].ref_text 
							AND source_ind = l_arr_rec_suburb[l_idx].source_ind 
						END IF 
					END FOR 

				END IF 
			ELSE #delete CURRENT ROW 
				LET msgstr = "Do you want to delete ", trim(l_arr_rec_street[l_idx].street_text), ",", trim(l_arr_rec_street[l_idx].st_type_text), "," ,trim(l_arr_rec_suburb[l_idx].suburb_code), " ?" 
				IF promptTF("Delete",msgStr,TRUE) THEN 
					#CALL fgl_winmessage("Nothing to delete","No selected rows were found to be deleted","info")
					DELETE FROM street 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND street_text = l_arr_rec_street[l_idx].street_text 
					AND st_type_text = l_arr_rec_street[l_idx].st_type_text 
					AND suburb_code = l_arr_rec_suburb[l_idx].suburb_code 
					AND map_number = l_arr_rec_suburb[l_idx].map_number 
					AND ref_text = l_arr_rec_suburb[l_idx].ref_text 
					AND source_ind = l_arr_rec_suburb[l_idx].source_ind 
				END IF 
			END IF 
			CALL select_street(false) RETURNING l_arr_rec_street, l_arr_rec_suburb 


			#      ON KEY(F2) --delete marker
			#         IF infield(scroll_flag) THEN
			#            IF l_arr_rec_street[l_idx].scroll_flag IS NULL THEN
			#               LET l_arr_rec_street[l_idx].scroll_flag = "*"
			#               LET l_del_cnt = l_del_cnt + 1
			#            ELSE
			#               LET l_arr_rec_street[l_idx].scroll_flag = NULL
			#               LET l_del_cnt = l_del_cnt - 1
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag

		BEFORE ROW 
			#      BEFORE FIELD scroll_flag
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_street[l_idx].scroll_flag 

			#FIXME: remove this usage of rowid
			SELECT street.*,suburb.* 
			INTO l_rec_street.*,l_rec_suburb.* 
			FROM street,suburb 
			WHERE street.rowid = l_arr_rec_suburb[l_idx].row_id 
			AND suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND suburb.suburb_code = street.suburb_code 

			DISPLAY BY NAME l_rec_suburb.state_code, 
			l_rec_suburb.post_code, 
			l_rec_street.map_number, 
			l_rec_street.ref_text, 
			l_rec_street.source_ind 

			#         DISPLAY l_arr_rec_street[l_idx].* TO sr_street[scrn].*

			#			AFTER ROW
			#AFTER FIELD scroll_flag
			#				LET l_arr_rec_street[l_idx].scroll_flag = l_scroll_flag
			#         DISPLAY l_arr_rec_street[l_idx].scroll_flag TO sr_street[scrn].scroll_flag

			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#            LET l_msgresp = kandoomsg("U",9001,"")
			#            #9001 There are no more rows in the direction you are going.
			#            NEXT FIELD scroll_flag
			#         END IF
		ON ACTION ("EDIT","DoubleClick") 
			#BEFORE FIELD street_text
			LET l_idx = arr_curr() 
			IF l_arr_rec_street[l_idx].street_text IS NOT NULL THEN 
				LET l_rec_street.street_text = l_arr_rec_street[l_idx].street_text 
				LET l_rec_street.st_type_text = l_arr_rec_street[l_idx].st_type_text 
				LET l_rec_street.suburb_code = l_arr_rec_suburb[l_idx].suburb_code 
				LET l_rec_street.map_number = l_arr_rec_suburb[l_idx].map_number 
				LET l_rec_street.ref_text = l_arr_rec_suburb[l_idx].ref_text 
				LET l_rec_street.source_ind = l_arr_rec_suburb[l_idx].source_ind 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 

				IF edit_street(l_arr_rec_suburb[l_idx].row_id) THEN 
					SELECT * INTO l_rec_street.* FROM street 
					WHERE rowid = l_arr_rec_suburb[l_idx].row_id 
					SELECT * INTO l_rec_suburb.* FROM suburb 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND suburb_code = l_rec_street.suburb_code 

					LET l_arr_rec_street[l_idx].street_text = l_rec_street.street_text 
					LET l_arr_rec_street[l_idx].st_type_text = l_rec_street.st_type_text 
					LET l_arr_rec_street[l_idx].suburb_text = l_rec_suburb.suburb_text 
					LET l_arr_rec_suburb[l_idx].map_number = l_rec_street.map_number 
					LET l_arr_rec_suburb[l_idx].ref_text = l_rec_street.ref_text 
					LET l_arr_rec_suburb[l_idx].source_ind = l_rec_street.source_ind 
					LET l_arr_rec_suburb[l_idx].suburb_code = l_rec_street.suburb_code 
				END IF 

			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "NEW" 
			#BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			#            LET l_curr = arr_curr()
			#            LET l_cnt = arr_count()
			#            FOR x = l_cnt TO l_idx step -1
			#               LET l_arr_rec_suburb[x+1].* = l_arr_rec_suburb[x].*
			#               IF x = l_idx THEN
			#                  INITIALIZE l_arr_rec_suburb[x].* TO NULL
			#               END IF
			#            END FOR
			LET modu_rowid = edit_street(0) 

			IF modu_rowid != 0 THEN 
				CALL select_street(false) RETURNING l_arr_rec_street, l_arr_rec_suburb 
				LET l_idx = arr_curr() 
			END IF 

			#
			#               FOR l_idx = l_curr TO l_cnt
			#                  LET l_arr_rec_street[l_idx].* = l_arr_rec_street[l_idx+1].*
			#                  LET l_arr_rec_suburb[l_idx].* = l_arr_rec_suburb[l_idx+1].*
			#                  IF scrn <= 8 THEN
			#                     DISPLAY l_arr_rec_street[l_idx].* TO sr_street[scrn].*
			#
			#                     LET scrn = scrn + 1
			#                  END IF
			#               END FOR
			#
			#               INITIALIZE l_arr_rec_street[l_idx].* TO NULL
			#               INITIALIZE l_arr_rec_suburb[l_idx].* TO NULL
			#            ELSE
			#               SELECT * INTO l_rec_street.* FROM street
			#                WHERE rowid = modu_rowid
			#               SELECT * INTO l_rec_suburb.* FROM suburb
			#                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                  AND suburb_code = l_rec_street.suburb_code
			#               LET l_arr_rec_street[l_idx].street_text = l_rec_street.street_text
			#               LET l_arr_rec_street[l_idx].st_type_text = l_rec_street.st_type_text
			#               LET l_arr_rec_street[l_idx].suburb_text = l_rec_suburb.suburb_text
			#               LET l_arr_rec_suburb[l_idx].row_id = modu_rowid
			#               LET l_arr_rec_suburb[l_idx].map_number = l_rec_street.map_number
			#               LET l_arr_rec_suburb[l_idx].ref_text = l_rec_street.ref_text
			#               LET l_arr_rec_suburb[l_idx].source_ind = l_rec_street.source_ind
			#               LET l_arr_rec_suburb[l_idx].suburb_code = l_rec_street.suburb_code
			#            END IF
			#         ELSE
			#            IF l_idx > 1 THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               #9001 There are no more rows in the direction ....
			#            END IF
			#         END IF

			#      AFTER ROW
			#         DISPLAY l_arr_rec_street[l_idx].* TO sr_street[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 
	###########################


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("W",8002,l_del_cnt) 
			#8002 Confirm TO Delete ",l_del_cnt," Street(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_street[l_idx].scroll_flag = "*" THEN 
						DELETE FROM street 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND street_text = l_arr_rec_street[l_idx].street_text 
						AND st_type_text = l_arr_rec_street[l_idx].st_type_text 
						AND suburb_code = l_arr_rec_suburb[l_idx].suburb_code 
						AND map_number = l_arr_rec_suburb[l_idx].map_number 
						AND ref_text = l_arr_rec_suburb[l_idx].ref_text 
						AND source_ind = l_arr_rec_suburb[l_idx].source_ind 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

END FUNCTION 



###################################################################
# FUNCTION edit_street(p_rowid)
# RETURN
#
# edit a streeet record
###################################################################
FUNCTION edit_street(p_rowid) 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_s_street RECORD LIKE street.* 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_s_suburb RECORD LIKE suburb.* 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_suburb_cnt INTEGER 
	DEFINE l_street_cnt INTEGER 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag
	
	INITIALIZE l_rec_street.* TO NULL 
	INITIALIZE l_rec_s_street.* TO NULL 
	INITIALIZE l_rec_suburb.* TO NULL 
	INITIALIZE l_rec_s_suburb.* TO NULL 
	IF p_rowid != 0 THEN 
		SELECT * INTO l_rec_street.* FROM street 
		WHERE rowid = p_rowid 
		LET l_rec_s_street.* = l_rec_street.* 
		SELECT * INTO l_rec_suburb.* FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = l_rec_street.suburb_code 
		LET l_rec_s_suburb.* = l_rec_suburb.* 
	ELSE 
		LET l_rec_street.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 
	OPEN WINDOW u110 with FORM "U110" 
	CALL windecoration_u("U110") 

	LET l_msgresp = kandoomsg("W",1017,"") 
	#1017 " Enter Street Details
	DISPLAY BY NAME l_rec_street.street_text, 
	l_rec_street.st_type_text, 
	l_rec_suburb.suburb_text, 
	l_rec_suburb.post_code, 
	l_rec_street.map_number, 
	l_rec_street.ref_text, 
	l_rec_street.source_ind 


	IF l_rec_street.st_type_text IS NULL OR l_rec_street.st_type_text = "" THEN 
		LET l_rec_street.st_type_text = "N/A" 
	END IF 
	IF l_rec_street.map_number IS NULL OR l_rec_street.map_number = "" THEN 
		LET l_rec_street.map_number = "N/A" 
	END IF 
	IF l_rec_street.map_number IS NULL OR l_rec_street.map_number = "" THEN 
		LET l_rec_street.map_number = "N/A" 
	END IF 
	IF l_rec_street.ref_text IS NULL OR l_rec_street.ref_text = "" THEN 
		LET l_rec_street.ref_text = "N/A" 
	END IF 

	IF l_rec_street.source_ind IS NULL OR l_rec_street.source_ind = "" THEN 
		LET l_rec_street.source_ind = "N" 
	END IF 


	INPUT BY NAME l_rec_street.street_text, 
	l_rec_street.st_type_text, 
	l_rec_suburb.suburb_text, 
	l_rec_street.map_number, 
	l_rec_street.ref_text, 
	l_rec_street.source_ind WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U52","input-street") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (suburb_text) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_wsub(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_suburb.suburb_code = l_winds_text 
				SELECT * INTO l_rec_suburb.* 
				FROM suburb 
				WHERE suburb_code = l_rec_suburb.suburb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME l_rec_suburb.suburb_text 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD suburb_text 

		BEFORE FIELD street_text 
			IF p_rowid != 0 THEN 
				NEXT FIELD map_number 
			END IF 

		AFTER FIELD street_text 
			IF l_rec_street.street_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9033,"") 
				#9033 " Street Name must be entered
				NEXT FIELD street_text 
			END IF 

		AFTER FIELD st_type_text 
			IF l_rec_street.st_type_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9034,"") 
				#9034 " Street type must be entered
				NEXT FIELD st_type_text 
			END IF 

		BEFORE FIELD suburb_text 
			IF p_rowid != 0 THEN 
				NEXT FIELD map_number 
			END IF 

		AFTER FIELD suburb_text 
			IF l_rec_suburb.suburb_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9035,"") 
				#9035 " Suburb must be entered
				NEXT FIELD suburb_text 
			ELSE 
				SELECT count(*) INTO l_suburb_cnt FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_text = l_rec_suburb.suburb_text 

				IF l_suburb_cnt = 0 THEN 
					LET l_msgresp = kandoomsg("W",9201,"") 
					#9201 " Suburb does NOT exist - Try Window
					NEXT FIELD suburb_text 

				ELSE 

					IF (l_suburb_cnt > 1) THEN 
						IF (l_rec_suburb.post_code IS null) THEN 
							LET l_rec_street.suburb_code = 
							choose_suburb(l_rec_suburb.suburb_text) 
							IF l_rec_street.suburb_code IS NOT NULL THEN 
								SELECT * INTO l_rec_suburb.* FROM suburb 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND suburb_code = l_rec_street.suburb_code 
								DISPLAY BY NAME l_rec_suburb.suburb_text, 
								l_rec_suburb.post_code 

							ELSE 
								NEXT FIELD suburb_text 
							END IF 
						END IF 

						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 

					ELSE 

						SELECT * INTO l_rec_suburb.* FROM suburb 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND suburb_text = l_rec_suburb.suburb_text 
						DISPLAY BY NAME l_rec_suburb.suburb_text, 
						l_rec_suburb.post_code 

						LET l_rec_street.suburb_code = l_rec_suburb.suburb_code 
					END IF 

					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD map_number 
			IF l_rec_street.map_number IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9036,"") 
				#9036 " Map Number must be entered
				NEXT FIELD map_number 
			END IF 

		AFTER FIELD ref_text 
			IF l_rec_street.ref_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9037,"") 
				#9037 " Map Reference must be entered
				NEXT FIELD ref_text 
			END IF 

		AFTER FIELD source_ind 
			IF l_rec_street.source_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9038,"") 
				#9038 " Map Source Indicator must be entered
				NEXT FIELD source_ind 
			END IF 

			IF l_rec_street.source_ind != "N" #note:: db uses char(1) 
			AND l_rec_street.source_ind != "1" 
			AND l_rec_street.source_ind != "2" 
			AND l_rec_street.source_ind != "3" THEN 
				LET l_msgresp = kandoomsg("W",9039,"") 
				#9039 " Source Indicator must be 1, 2, OR 3
				NEXT FIELD source_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_street.street_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9033,"") 
					#9033 " Street Name must be entered
					NEXT FIELD street_text 
				END IF 

				IF l_rec_street.st_type_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9034,"") 
					#9034 " Street type must be entered
					NEXT FIELD st_type_text 
				END IF 

				IF l_rec_suburb.suburb_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9035,"") 
					#9035 " Suburb must be entered
					NEXT FIELD suburb_text 
				END IF 
				IF l_rec_street.map_number IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9036,"") 
					#9036 " Map Number must be entered
					NEXT FIELD map_number 
				END IF 

				IF l_rec_street.ref_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9037,"") 
					#9037 " Map Reference must be entered
					NEXT FIELD ref_text 
				END IF 

				IF l_rec_street.source_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9038,"") 
					#9038 " Map Source Indicator must be entered
					NEXT FIELD source_ind 
				END IF 

				IF l_rec_street.source_ind != "N" 
				AND l_rec_street.source_ind != "1" 
				AND l_rec_street.source_ind != "2" 
				AND l_rec_street.source_ind != "3" THEN 
					LET l_msgresp = kandoomsg("W",9039,"") 
					#9039 " Source Indicator must be 1, 2, OR 3
					NEXT FIELD source_ind 
				END IF 

				IF p_rowid != 0 THEN 
					IF l_rec_street.street_text != l_rec_s_street.street_text 
					OR l_rec_street.st_type_text != l_rec_s_street.st_type_text 
					OR l_rec_street.suburb_code != l_rec_s_street.suburb_code 
					OR l_rec_street.map_number != l_rec_s_street.map_number 
					OR l_rec_street.ref_text != l_rec_s_street.ref_text 
					OR l_rec_street.source_ind != l_rec_s_street.source_ind THEN 
						SELECT count(*) INTO l_street_cnt FROM street 
						WHERE street_text = l_rec_street.street_text 
						AND st_type_text = l_rec_street.st_type_text 
						AND suburb_code = l_rec_street.suburb_code 
						AND map_number = l_rec_street.map_number 
						AND ref_text = l_rec_street.ref_text 
						AND source_ind = l_rec_street.source_ind 
						IF l_street_cnt > 0 THEN 
							LET l_msgresp = kandoomsg("W",9040,"") 
							#9040 " These Street details already exist
							NEXT FIELD map_number 
						END IF 
					END IF 
				END IF 

				IF p_rowid = 0 THEN 
					SELECT count(*) INTO l_street_cnt FROM street 
					WHERE street_text = l_rec_street.street_text 
					AND st_type_text = l_rec_street.st_type_text 
					AND suburb_code = l_rec_street.suburb_code 
					AND map_number = l_rec_street.map_number 
					AND ref_text = l_rec_street.ref_text 
					AND source_ind = l_rec_street.source_ind 
					IF l_street_cnt > 0 THEN 
						LET l_msgresp = kandoomsg("W",9040,"") 
						#9040 " These Street details already exist
						NEXT FIELD street_text 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 
	#################


	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW u110 
		RETURN false 
	END IF 

	IF p_rowid = 0 THEN 
		INSERT INTO street VALUES (l_rec_street.*) 
		CLOSE WINDOW u110 
		RETURN sqlca.sqlerrd[6] 
	ELSE 
		UPDATE street 
		SET * = l_rec_street.* 
		WHERE rowid = p_rowid 
		CLOSE WINDOW u110 
		RETURN sqlca.sqlerrd[3] 
	END IF 

END FUNCTION 



###################################################################
# FUNCTION choose_suburb(p_suburb_text)
# RETURN l_rec_suburb.suburb_code
#
# choose/select a subugb
###################################################################
FUNCTION choose_suburb(p_suburb_text) 
	DEFINE p_suburb_text LIKE suburb.suburb_text 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_st_sc_pc_with_scrollflag 
	#	DEFINE l_arr_rec_suburb array[100] OF
	#		RECORD
	#         scroll_flag CHAR(1),
	#         suburb_text LIKE suburb.suburb_text,
	#         state_code LIKE suburb.state_code,
	#         post_code LIKE suburb.post_code
	#		END RECORD
	DEFINE l_arr_rec_suburb_code DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		suburb_code LIKE suburb.suburb_code 
	END RECORD 
	DEFINE l_idx,scrn SMALLINT 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW u112 at 9,4 with FORM "U112" 
	CALL windecoration_u("U112") 


	CLEAR FORM 
	DECLARE c_suburb CURSOR FOR 
	SELECT * FROM suburb 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_text = p_suburb_text 
	ORDER BY post_code 
	LET l_idx = 0 
	FOREACH c_suburb INTO l_rec_suburb.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text 
		LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code 
		LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code 
		LET l_arr_rec_suburb_code[l_idx].suburb_code = l_rec_suburb.suburb_code 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("W",9021,l_idx) 
			#9021 First l_idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("W",9024,"") 
		#9024 No entries satsified selection criteria
		LET l_idx = 1 
		INITIALIZE l_arr_rec_suburb[1].* TO NULL 
	END IF 
	LET l_msgresp = kandoomsg("W",1006,"") 
	#1006 " ESC on line TO SELECT - F10 TO Add
	#      CALL set_count(l_idx)


	INPUT ARRAY l_arr_rec_suburb WITHOUT DEFAULTS FROM sr_suburb.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U52","input-arr-suburb") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET scrn = scr_line() 
			IF l_arr_rec_suburb[l_idx].suburb_text IS NOT NULL THEN 
				DISPLAY l_arr_rec_suburb[l_idx].* TO sr_suburb[scrn].* 

			END IF 
			NEXT FIELD scroll_flag 
		AFTER FIELD scroll_flag 
			LET l_arr_rec_suburb[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET l_msgresp = kandoomsg("W",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD suburb_text 
			LET l_rec_suburb.suburb_code = l_arr_rec_suburb_code[l_idx].suburb_code 
			EXIT INPUT 
		ON KEY (F10) 
			CALL run_prog("WZ1","","","","") 
		AFTER ROW 
			DISPLAY l_arr_rec_suburb[l_idx].* TO sr_suburb[scrn].* 

		AFTER INPUT 
			LET l_rec_suburb.suburb_code = l_arr_rec_suburb_code[l_idx].suburb_code 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_suburb.suburb_code = "" 
	END IF 

	CLOSE WINDOW u112 

	RETURN l_rec_suburb.suburb_code 
END FUNCTION 


