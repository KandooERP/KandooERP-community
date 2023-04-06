#Group Code
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

	Source code beautified by beautify.pl on 2020-01-03 11:19:27	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ7_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_stnd_grp RECORD LIKE stnd_grp.* 
--DEFINE modu_arr_rec_group array[100] OF
DEFINE modu_arr_rec_group DYNAMIC ARRAY OF 
RECORD 
	group_code LIKE stnd_grp.group_code, 
	desc_text LIKE stnd_grp.desc_text 
END RECORD 
--DEFINE l_counter SMALLINT 
--DEFINE l_idx SMALLINT 

--DEFINE cnt SMALLINT 
--DEFINE err_flag SMALLINT 
--DEFINE domore CHAR(1) 
--DEFINE gv_menu_path CHAR(3) 


#############################################################################
# MAIN
#
#
#############################################################################
MAIN 
	DEFINE l_withquery SMALLINT 
	DEFINE l_program CHAR(25) 

	CALL setModuleId("AZ7") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	#WHENEVER ERROR CONTINUE
	#OPTIONS INSERT KEY F1
	#OPTIONS DELETE KEY F36
	#WHENEVER ERROR STOP
	{
	   LET domore = "Y"
	   WHILE domore = "Y"
	      OPEN WINDOW wA922 WITH FORM "A922"
				CALL windecoration_a("A922")

	      CALL doit()
	      CLOSE WINDOW wA922
	   END WHILE

	   }




	OPEN WINDOW wa922 with FORM "A922" 
	CALL windecoration_a("A922") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_salesperson_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	WHILE select_stnd_grp(l_withquery) 
		LET l_withquery = scan_stnd_grp() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW wa922 



END MAIN 




##################################################################
# FUNCTION select_stnd_grp(p_withquery)
#
#
##################################################################
FUNCTION select_stnd_grp(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(400) 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON group_code, desc_text 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ7","construct-stnd_grp") 

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

	#	ERROR kandoomsg2("A",1002,"")	#1002 Searching database - please wait
	#	LET l_query_text = "SELECT * FROM stnd_grp ",
	#                        "WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
	#                          "AND ",l_where_text clipped," ",
	#                        "ORDER BY 1,2"
	#	PREPARE s_stnd_grp FROM l_query_text
	#	DECLARE c_stnd_grp CURSOR FOR s_stnd_grp


	LET l_query_text = "SELECT * ", 
	"FROM stnd_grp ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY group_code " 

	PREPARE grp_sel FROM l_query_text 
	DECLARE grp_curs CURSOR FOR grp_sel 


	RETURN 1 

END FUNCTION 






#############################################################################
# FUNCTION doit()
#
#
#############################################################################
FUNCTION scan_stnd_grp() #doit() 
	DEFINE save_id LIKE stnd_grp.group_code 
	DEFINE save_desc LIKE stnd_grp.desc_text 
	DEFINE l_answer CHAR(1) 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	DEFINE cnt SMALLINT 
	DEFINE l_idx_cnt SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_query_text CHAR(200) 
	DEFINE l_where_text CHAR(100) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_id_flag SMALLINT
	 	
	{
	   SELECT count(*)
	      INTO cnt
	      FROM stnd_grp
	      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

	   IF cnt > 0 THEN
	       MESSAGE "Enter Selection Criteria - ESC TO Continue" --ATTRIBUTE (YELLOW)

	       CONSTRUCT BY NAME l_where_text on group_code, desc_text


			BEFORE CONSTRUCT
				CALL publish_toolbar("kandoo","AZ7","construct-stnd_grp")

			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)

			ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

		END CONSTRUCT

	       IF int_flag OR quit_flag THEN
	           LET int_flag = FALSE
	           LET quit_flag = FALSE
	           EXIT PROGRAM
	       END IF

	       LET l_query_text = "SELECT * ",
	                        "FROM stnd_grp ",
	                        "WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
	                        "AND ",l_where_text clipped," ",
	                        "ORDER BY group_code "

	       PREPARE grp_sel FROM l_query_text
	       DECLARE grp_curs CURSOR FOR grp_sel

	}
	LET l_idx = 0 
	FOREACH grp_curs INTO modu_rec_stnd_grp.* 
		LET l_idx = l_idx + 1 
		LET modu_arr_rec_group[l_idx].group_code = modu_rec_stnd_grp.group_code 
		LET modu_arr_rec_group[l_idx].desc_text = modu_rec_stnd_grp.desc_text 
		IF l_idx > 100 THEN 
			ERROR " Only 1st 100 group codes selected" 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(l_idx) 
	LET l_idx_cnt = arr_count() 
	#END IF

	MESSAGE "F1 - TO add, F2 - TO delete, RETURN TO edit line" --attribute (YELLOW) 
	CALL displayUsage("F1 - TO add, F2 - TO delete, RETURN TO edit line") 

	INPUT ARRAY modu_arr_rec_group WITHOUT DEFAULTS FROM sr_group.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7","inp-arr-group") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET modu_rec_stnd_grp.group_code = modu_arr_rec_group[l_idx].group_code 
			LET modu_rec_stnd_grp.desc_text = modu_arr_rec_group[l_idx].desc_text 
			LET l_id_flag = 0 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		AFTER FIELD group_code 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				ERROR kandoomsg2("U",9001,"") 				#9001 There are no more rows in the direction you are going.
				NEXT FIELD group_code 
			END IF 

		ON KEY (F2) --delete 
			IF modu_arr_rec_group[l_idx].group_code IS NOT NULL THEN 
				CALL ar_check_del(l_idx) 
			END IF 
			LET l_idx = arr_curr() 
			RETURN 0 

		BEFORE FIELD desc_text 
			IF modu_arr_rec_group[l_idx].group_code IS NOT NULL THEN 
				SELECT stnd_grp.* 
				INTO modu_rec_stnd_grp.* 
				FROM stnd_grp 
				WHERE group_code = modu_arr_rec_group[l_idx].group_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET save_id = modu_rec_stnd_grp.group_code 
				LET save_desc = modu_rec_stnd_grp.desc_text 
			END IF 

		AFTER FIELD desc_text 
			IF modu_arr_rec_group[l_idx].desc_text IS NULL OR 
			modu_arr_rec_group[l_idx].desc_text = " " THEN 
				ERROR "A description must be entered FOR this group" 
				NEXT FIELD desc_text 
			END IF 

			IF modu_arr_rec_group[l_idx].group_code IS NOT NULL THEN 
				LET modu_rec_stnd_grp.group_code = modu_arr_rec_group[l_idx].group_code 
				LET modu_rec_stnd_grp.desc_text = modu_arr_rec_group[l_idx].desc_text 
				LET modu_rec_stnd_grp.cmpy_code = glob_rec_kandoouser.cmpy_code 

				UPDATE stnd_grp 
				SET * = modu_rec_stnd_grp.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = save_id 

				#LET modu_arr_rec_group[l_idx].group_code = modu_rec_stnd_grp.group_code
				#LET modu_arr_rec_group[l_idx].desc_text = modu_rec_stnd_grp.desc_text
				#DISPLAY modu_arr_rec_group[l_idx].* TO sr_group[scrn].*
				NEXT FIELD group_code 
			END IF 

		BEFORE INSERT 
			IF l_id_flag = 0 THEN 
				CALL addor() 
				CALL publish_toolbar("kandoo","AZ7","inp-arr-group") 
				IF int_flag OR quit_flag THEN 
					FOR i = l_idx TO arr_count() 
						LET modu_arr_rec_group[i].* = modu_arr_rec_group[i+1].* 
					END FOR 
					INITIALIZE modu_arr_rec_group[i+1].* TO NULL 
					LET j = l_idx 
					#FOR i = scrn TO 5
					#   DISPLAY modu_arr_rec_group[j].* TO sr_group[i].*
					#   LET j = j + 1
					#END FOR
					LET int_flag = 0 
					LET quit_flag = 0 
				ELSE 
					LET modu_arr_rec_group[l_idx].group_code = modu_rec_stnd_grp.group_code 
					LET modu_arr_rec_group[l_idx].desc_text = modu_rec_stnd_grp.desc_text 
					#DISPLAY modu_arr_rec_group[l_idx].* TO sr_group[scrn].*
				END IF 
			END IF 

		AFTER DELETE 
			IF modu_arr_rec_group[l_idx].group_code IS NOT NULL THEN 
				CALL ar_check_del(l_idx) 
			END IF 

			RETURN 0 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
				LET int_flag = 0 
				LET quit_flag = 0 

				RETURN 2 
			END IF 

	END INPUT 

END FUNCTION 


#############################################################################
# FUNCTION addor()
#
#
#############################################################################
FUNCTION addor() 
	DEFINE l_counter SMALLINT
	
	INITIALIZE modu_rec_stnd_grp.* TO NULL 

	DISPLAY BY NAME modu_rec_stnd_grp.group_code,
	                modu_rec_stnd_grp.desc_text


	INPUT BY NAME modu_rec_stnd_grp.group_code, modu_rec_stnd_grp.desc_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7","inp-group") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD group_code 
			SELECT count(*) 
			INTO l_counter 
			FROM stnd_grp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND group_code = modu_rec_stnd_grp.group_code 

			IF l_counter > 0 THEN 
				ERROR " Group Code already exists " 
				NEXT FIELD group_code 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
			ELSE 
				SELECT count(*) 
				INTO l_counter 
				FROM stnd_grp 
				WHERE group_code = modu_rec_stnd_grp.group_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF l_counter > 0 THEN 
					ERROR " Group Code already exists FOR this company " 
					NEXT FIELD group_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag != 0 OR 
	quit_flag != 0 THEN 
	ELSE 
		LET modu_rec_stnd_grp.cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF (modu_rec_stnd_grp.group_code IS NOT null) THEN 
			INSERT INTO stnd_grp VALUES (modu_rec_stnd_grp.*) 
		END IF 
	END IF 

END FUNCTION 


#############################################################################
# FUNCTION ar_check_del(p_idx) 
#
#
#############################################################################
FUNCTION ar_check_del(p_idx) 
	DEFINE p_idx SMALLINT

	DEFINE l_answer CHAR(1) 
	DEFINE j SMALLINT
	DEFINE i SMALLINT
	 
	LET l_answer = "n" 


	LET l_answer = promptYN("Delete","Do you wish TO delete this Group Code","Y") 


	LET l_answer = downshift(l_answer) 

	IF l_answer = "y" THEN 
		DELETE FROM stnd_grp 
		WHERE group_code = modu_arr_rec_group[p_idx].group_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET l_answer = "n" 

		LET l_answer = promptYN("Delete FROM All Customers ?","Do you wish TO delete this Group FROM all Customers ?","Y") 

		LET l_answer = downshift(l_answer) 


		IF l_answer = "y" THEN 
			DELETE FROM stnd_custgrp 
			WHERE group_code = modu_arr_rec_group[p_idx].group_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
		FOR i = p_idx TO arr_count() 
			LET modu_arr_rec_group[i].* = modu_arr_rec_group[i+1].* 
		END FOR 
		#INITIALIZE modu_arr_rec_group[i+1].* TO NULL
		#LET j = p_idx
		#FOR i = scrn TO 5
		#   DISPLAY modu_arr_rec_group[j].* TO sr_group[i].*
		#   LET j = j + 1
		#END FOR
	END IF 

	LET modu_rec_stnd_grp.group_code = modu_arr_rec_group[p_idx].group_code 
	LET modu_rec_stnd_grp.desc_text = modu_arr_rec_group[p_idx].desc_text 
--	 
	#LET scrn = scr_line()
END FUNCTION 


