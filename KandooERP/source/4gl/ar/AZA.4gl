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

	Source code beautified by beautify.pl on 2020-01-03 11:19:28	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZA_GLOBALS.4gl"  

############################################################
# Module Scope Variables
############################################################
DEFINE err_message CHAR(60) 

######################################################################
# MAIN
#
# \brief module AZA.4gl  - Modified Sales Area Maintainence Facility
######################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	#Initial UI Init
	CALL setModuleId("AZA") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW wa603 with FORM "A603" 
	CALL windecoration_a("A603") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_salearea_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	WHILE select_area(l_withquery) 
		LET l_withquery = scan_area() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW wa603 
END MAIN 


######################################################################
# FUNCTION select_area()
#
#
######################################################################
FUNCTION select_area(p_withquery) 
	DEFINE p_withquery SMALLINT 

	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(400) 

	IF p_withquery = 1 THEN 

		CLEAR FORM 

		MESSAGE kandoomsg2("A",1001,"") 		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON area_code,desc_text 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZA","construct-area") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	MESSAGE kandoomsg2("A",1002,"") 	#1002 Searching database - pls wait
	LET l_query_text = "SELECT * FROM salearea ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY area_code" 
	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea CURSOR FOR s_salearea 

	RETURN 1 

END FUNCTION 



######################################################################
# FUNCTION scan_area()
#
#
######################################################################
FUNCTION scan_area() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF --array[100] OF RECORD 
		RECORD #huho removed due TO change FROM INPUT TO DISPLAY ARRAY l_scroll_flag CHAR(1), 
			area_code LIKE salearea.area_code, 
			desc_text LIKE salearea.desc_text 
		END RECORD 

		DEFINE l_idx SMALLINT #,scrn 
		DEFINE l_del_qty SMALLINT #,scrn 
		DEFINE l_rowid INTEGER 

		#LET l_idx = 0

		CALL l_arr_rec_salearea.clear() 
		FOREACH c_salearea INTO l_rec_salearea.* 
			#  LET l_idx = l_idx + 1
			CALL l_arr_rec_salearea.append([l_rec_salearea.area_code, l_rec_salearea.desc_text]) 



			#   LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code
			#   LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
			#   IF l_idx = 100 THEN
			#      ERROR kandoomsg2("A",9013,l_idx)
			#      #9013 " First ??? entries Selected Only"
			#      EXIT FOREACH
			#   END IF
		END FOREACH 

		LET l_idx = l_arr_rec_salearea.getsize() 
		IF l_idx = 0 THEN 
			ERROR kandoomsg2("A",9086,"") 			#9086" No entries satisfied selection criteria "
		END IF 

		#OPTIONS INSERT KEY F1
		#        DELETE KEY F36
		CALL set_count(l_idx) 
		MESSAGE kandoomsg2("A",1003,"") 		#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
		#huho INPUT ARRAY l_arr_rec_salearea WITHOUT DEFAULTS FROM sr_salearea.*
		DISPLAY ARRAY l_arr_rec_salearea TO sr_salearea.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","AZA","inp-arr-salearea") 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION "FILTER" 
				RETURN true 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

				#BEFORE FIELD scroll_flag
				#   LET l_idx = arr_curr()
				#   LET scrn = scr_line()
				#   LET l_scroll_flag = l_arr_rec_salearea[l_idx].scroll_flag
				#   DISPLAY l_arr_rec_salearea[l_idx].* TO sr_salearea[scrn].*

				#AFTER FIELD scroll_flag
				#LET l_arr_rec_salearea[l_idx].scroll_flag = l_scroll_flag
				#DISPLAY l_arr_rec_salearea[l_idx].scroll_flag TO sr_salearea[scrn].scroll_flag

				#  IF fgl_lastkey() = fgl_keyval("down") THEN
				#     IF l_arr_rec_salearea[l_idx+1].area_code IS NULL
				#     OR arr_curr() >= arr_count() THEN
				#        LET l_msgresp=kandoomsg("A",9001,"")
				#        #9001 There no more rows...
				#        NEXT FIELD scroll_flag
				#     END IF
				#  END IF

			ON ACTION ("EDIT","doubleClick","ACCEPT") 
				IF l_arr_rec_salearea[l_idx].area_code IS NOT NULL THEN 
					IF edit_salearea(l_arr_rec_salearea[l_idx].area_code) THEN 
						SELECT * INTO l_rec_salearea.* FROM salearea 
						WHERE area_code = l_arr_rec_salearea[l_idx].area_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 

						LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code 
						LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text 
					END IF 
				END IF 

				#need this FOR toolbarManager
				CALL set_toolbar("kandoo","AZA","inp-arr-salearea") 
				RETURN 0 

				#BEFORE FIELD area_code
				#   IF l_arr_rec_salearea[l_idx].area_code IS NOT NULL THEN
				#      IF edit_salearea(l_arr_rec_salearea[l_idx].area_code) THEN
				#         SELECT * INTO l_rec_salearea.* FROM salearea
				#          WHERE area_code = l_arr_rec_salearea[l_idx].area_code
				#            AND cmpy_code = glob_rec_kandoouser.cmpy_code
				#         LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code
				#         LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
				#      END IF
				#   END IF
				#   NEXT FIELD scroll_flag

				#huho

			ON ACTION "New" 

				#      BEFORE INSERT
				#     IF scrn > 0 THEN
				LET l_rec_salearea.* = edit_salearea("") 
				SELECT * INTO l_rec_salearea.* FROM salearea 
				WHERE cmpy_code = l_rec_salearea.cmpy_code 
				AND area_code = l_rec_salearea.area_code 
				IF status = NOTFOUND THEN 
					ERROR "Record could NOT be created/modfied" 
				ELSE 
					CALL l_arr_rec_salearea.append([l_rec_salearea.area_code, l_rec_salearea.desc_text]) 
					#LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code
					#LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
				END IF 
				#need this FOR toolbarManager
				CALL set_toolbar("kandoo","AZA","inp-arr-salearea") 
				RETURN 0 

				#          IF STATUS = NOTFOUND THEN
				#FOR l_idx = arr_curr() TO arr_count()
				#   LET l_arr_rec_salearea[l_idx].* = l_arr_rec_salearea[l_idx+1].*
				# IF scrn <= 12 THEN
				#    DISPLAY l_arr_rec_salearea[l_idx].* TO sr_salearea[scrn].*
				#
				#    LET scrn = scrn + 1
				# END IF
				#END FOR
				#INITIALIZE l_arr_rec_salearea[l_idx].* TO NULL
				#         ELSE
				#           LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code
				#          LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
				#      END IF
				#           NEXT FIELD scroll_flag
				#    END IF

			ON ACTION "DELETE" 
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_salearea.getSize()) THEN 
					LET l_del_qty = 1 
					IF kandoomsg("A",8001,l_del_qty) = "Y" THEN #8001 Confirmation TO delete del_cnt Sales Area
						DELETE FROM salearea 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND area_code = l_arr_rec_salearea[l_idx].area_code 
					END IF 
					
					IF status <> 0 THEN 
						ERROR "Could NOT delete record" 
					ELSE 
						CALL l_arr_rec_salearea.delete(l_idx) 
					END IF 
				END IF 

				RETURN 0 

				--END INPUT
		END DISPLAY 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 2 --exit 
		END IF 


		{   --huho no more of this multipe delete sh..t
		   IF int_flag OR quit_flag THEN
		      LET int_flag = FALSE
		      LET quit_flag = FALSE
		   ELSE
		      IF del_cnt > 0 THEN
		         IF kandoomsg("A",8001,del_cnt) = "Y" THEN
		#8001 Confirmation TO delete del_cnt Sales Area
		            FOR l_idx = 1 TO arr_count()
		               IF l_arr_rec_salearea[l_idx].scroll_flag IS NOT NULL THEN
		                  IF area_deleteable(l_arr_rec_salearea[l_idx].area_code) THEN
		                     DELETE FROM salearea
		                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                        AND area_code = l_arr_rec_salearea[l_idx].area_code
		                  ELSE
		                     LET l_msgresp=kandoomsg("A",7011,l_arr_rec_salearea[l_idx].area_code)
		#7011 ??? sales area has been assigned territorys
		                  END IF
		               END IF
		            END FOR
		         END IF
		      END IF
		   END IF
		}
END FUNCTION 




######################################################################
# FUNCTION edit_salearea(p_area_code)
#
#
######################################################################
FUNCTION edit_salearea(p_area_code) 
	DEFINE p_area_code LIKE salearea.area_code 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_sqlerrd INTEGER 

	IF p_area_code IS NOT NULL THEN 
		SELECT * INTO l_rec_salearea.* 
		FROM salearea 
		WHERE area_code = p_area_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	OPEN WINDOW A674 with FORM "A674" 
	CALL windecoration_a("A674") 


	INPUT BY NAME l_rec_salearea.area_code, 
	l_rec_salearea.desc_text, 
	l_rec_salearea.dept_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZA","inp-salearea") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD area_code 
			IF p_area_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD area_code 
			IF l_rec_salearea.area_code IS NULL THEN 
				LET l_msgresp=kandoomsg("A",9014,"") 
				#9014 " Sales Area Code must be Entered"
				NEXT FIELD area_code 
			ELSE 
				SELECT unique 1 FROM salearea 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND area_code = l_rec_salearea.area_code 
				IF status = 0 THEN 
					LET l_msgresp=kandoomsg("A",9015,"") 					#9015 " Sales Area Code already exists - Please Re Enter"
					LET l_rec_salearea.area_code = NULL 
					NEXT FIELD area_code 
				END IF 
			END IF 
		AFTER FIELD desc_text 
			IF l_rec_salearea.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9000,"") 				#9049 " Description must be entered
				NEXT FIELD desc_text 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_salearea.desc_text IS NULL THEN 
					ERROR kandoomsg2("A",9000,"") 					#9049 " Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF p_area_code IS NULL THEN 
					SELECT unique 1 FROM salearea 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND area_code = l_rec_salearea.area_code 
					IF status = 0 THEN 
						ERROR kandoomsg2("A",9015,"") 						#9015 " Sales Area Code already exists - Please Re Enter"
						NEXT FIELD area_code 
					END IF 
				END IF 
			END IF 

	END INPUT 
	CLOSE WINDOW A674 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET err_message = "AZA - Updating salearea" 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message,status) = "N" THEN 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			IF p_area_code IS NULL THEN 
				LET l_rec_salearea.cmpy_code = glob_rec_kandoouser.cmpy_code 
				INSERT INTO salearea VALUES (l_rec_salearea.*) 
				#LET l_sqlerrd = sqlca.sqlerrd[6]
			ELSE 
				UPDATE salearea 
				SET * = l_rec_salearea.* 
				WHERE area_code = l_rec_salearea.area_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				#LET l_sqlerrd = sqlca.sqlerrd[3]
			END IF 
		COMMIT WORK 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END IF 
	RETURN l_rec_salearea.* --l_sqlerrd 
END FUNCTION 

{
FUNCTION area_deleteable(p_area_code)
   DEFINE
      p_area_code LIKE salearea.area_code

   SELECT unique 1 FROM territory
    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
      AND area_code = p_area_code
   IF STATUS = NOTFOUND THEN
      RETURN TRUE
   ELSE
      RETURN FALSE
   END IF
END FUNCTION


}