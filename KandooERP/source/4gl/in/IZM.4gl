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

	Source code beautified by beautify.pl on 2020-01-03 09:12:50	$Id: $
}





#	Main Product Group Maintenance
#
#	IZM.4gl - Maintainence Program FOR main product groups.
#
#	Important Note:
#	maingrp.min_month_amt = "Minimum Statistics Amount"
# maingrp.min_quart_amt = "Minimum Distribution Amount"
# maingrp.min_year_amt = This Column Is Not Used. SP 5/4/94
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
--GLOBALS "IZM_GLOBALS.4gl" 

DEFINE t_arr_maingrp TYPE AS RECORD 
	maingrp_code LIKE maingrp.maingrp_code, 
	maingrp_desc LIKE maingrp.desc_text, 
	dept_code LIKE maingrp.dept_code, 
	dept_desc LIKE proddept.desc_text
END RECORD 

DEFINE t_maingrp_prykey TYPE AS RECORD
	cmpy_code LIKE maingrp.cmpy_code,
	maingrp_code LIKE maingrp.maingrp_code, 
	dept_code LIKE maingrp.dept_code
END RECORD

####################################################################
# MAIN
#
#
####################################################################
FUNCTION IZM_main()
	DEFINE l_filter boolean 
	DEFINE l_arr_maingrp DYNAMIC ARRAY OF t_arr_maingrp 
	DEFINE l_arr_maingrp_prykey DYNAMIC ARRAY OF t_maingrp_prykey 
	DEFINE l_maingrp_prykey t_maingrp_prykey
	DEFINE nb_elements INTEGER
	
	#Initial UI Init
	CALL setModuleId("IZM") 
	CALL ui_init(0) 

	OPEN WINDOW wi603 with FORM "I603" 
	DISPLAY glob_rec_company.cmpy_code,glob_rec_company.name_text 
	TO hdr_cmpy_code,hdr_cmpy_name
	 CALL windecoration_i("I603") 

	CALL construct_dataset_maingrp() RETURNING nb_elements,l_arr_maingrp,l_arr_maingrp_prykey
	CALL scan_dataset_pick_action_maingrp(l_arr_maingrp,l_arr_maingrp_prykey) 

	LET int_flag = false 
	CLOSE WINDOW wi603 

END FUNCTION # IZM_main 

####################################################################
# FUNCTION input_prodgrp(l_rec_prodgrp_code)
#
#
####################################################################
FUNCTION input_maingrp(p_maingrp_prykey) 
	DEFINE l_rec_maingrp_code LIKE maingrp.maingrp_code 
	DEFINE l_rec_maingrp RECORD LIKE maingrp.* 
	DEFINE p_maingrp_prykey t_maingrp_prykey
	DEFINE l_temp_code CHAR(20) 
	DEFINE l_maingrp_desc LIKE maingrp.desc_text 
	DEFINE l_proddept_desc LIKE proddept.desc_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_input_mode CHAR(5)
	DEFINE l_status INTEGER

	OPEN WINDOW i604 with FORM "I604" 
	 CALL windecoration_i("I604") 
	DISPLAY glob_rec_company.cmpy_code TO hdr_cmpy_code
	DISPLAY glob_rec_company.name_text TO hdr_cmpy_name

	SELECT maingrp.* INTO l_rec_maingrp.* 
	FROM maingrp 
	WHERE cmpy_code = p_maingrp_prykey.cmpy_code
	AND maingrp_code = p_maingrp_prykey.maingrp_code 
	AND dept_code = p_maingrp_prykey.dept_code 

	IF sqlca.sqlcode =  0 THEN 
		# maingrp exists, this is "EDIT"
		LET l_input_mode = "EDIT"
		
		CALL db_get_desc_proddept(l_rec_maingrp.cmpy_code,l_rec_maingrp.dept_code)
		RETURNING l_proddept_desc,l_status 

		CALL db_get_desc_maingrp(l_rec_maingrp.cmpy_code,l_rec_maingrp.dept_code,l_rec_maingrp.maingrp_code)
		RETURNING  l_rec_maingrp.desc_text,l_status
		
		CALL db_get_desc_proddept(l_rec_maingrp.cmpy_code,l_rec_maingrp.dept_code)
		RETURNING  l_proddept_desc,l_status

		DISPLAY l_rec_maingrp.desc_text,l_proddept_desc
		TO maingrp.desc_text,proddept_desc

	ELSE
		LET l_input_mode = "ADD"
		LET l_rec_maingrp.cmpy_code = glob_rec_kandoouser.cmpy_code
	END IF 

	INPUT BY NAME l_rec_maingrp.dept_code,
	l_rec_maingrp.maingrp_code, 
	l_rec_maingrp.desc_text, 
	l_rec_maingrp.min_month_amt, 
	l_rec_maingrp.min_quart_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZG","input-l_rec_maingrp") 
			IF l_input_mode = "EDIT" THEN	
				CALL Dialog.setFieldActive("maingrp_code",FALSE) 
			ELSE
				CALL Dialog.setFieldActive("maingrp_code",TRUE) 
			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield(maingrp_code) 
					LET l_temp_code = show_maingrp(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_code IS NOT NULL THEN 
						LET l_rec_maingrp.maingrp_code = l_temp_code 
						DISPLAY BY NAME l_rec_maingrp.maingrp_code 

					END IF 
			END CASE 

		# Replaced by setfield disable when in edit/not create mode
		AFTER FIELD dept_code 
			CLEAR l_proddept_desc 
			IF l_rec_maingrp.dept_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9015,"") 
				#9015" Product Main Group must be Entered "
				NEXT FIELD dept_code 
			ELSE 
				CALL db_get_desc_proddept(l_rec_maingrp.cmpy_code,l_rec_maingrp.dept_code)
				RETURNING l_proddept_desc,l_status 
 
				IF l_status = 0 THEN 
					LET l_msgresp = kandoomsg("I",9012,"") 
					#9012" Product Main Group does NOT exist Try Window
					NEXT FIELD dept_code 
				ELSE 
					DISPLAY l_proddept_desc TO proddept_desc
				END IF 
			END IF 

		AFTER FIELD maingrp_code    
			CLEAR l_maingrp_desc 
			IF l_rec_maingrp.maingrp_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9015,"") 
				#9015" Product Main Group must be Entered "
				NEXT FIELD maingrp_code 
			ELSE 
				IF check_prykey_exists_maingrp (l_rec_maingrp.cmpy_code,l_rec_maingrp.dept_code,l_rec_maingrp.maingrp_code) THEN
					LET l_msgresp = kandoomsg("I",9012,"") 
					#9012" Product Main Group does NOT exist Try Window
					NEXT FIELD maingrp_code 
				END IF 
			END IF 

		AFTER FIELD min_month_amt 
			IF l_rec_maingrp.min_month_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Amount must be entered
				LET l_rec_maingrp.min_month_amt = 0 
				NEXT FIELD min_month_amt 
			ELSE 
				IF l_rec_maingrp.min_month_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Amount must be entered
					LET l_rec_maingrp.min_month_amt = 0 
					NEXT FIELD min_month_amt 
				END IF 
			END IF 

		AFTER FIELD min_quart_amt 
			IF l_rec_maingrp.min_quart_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Amount must be entered
				LET l_rec_maingrp.min_quart_amt = 0 
				NEXT FIELD min_quart_amt 
			ELSE 
				IF l_rec_maingrp.min_quart_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Amount must be entered
					LET l_rec_maingrp.min_quart_amt = 0 
					NEXT FIELD min_quart_amt 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
			{
				IF l_rec_maingrp_code IS NULL THEN 
					SELECT * FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_rec_maingrp.maingrp_code 
					IF sqlca.sqlcode =  0 THEN 
						LET l_msgresp = kandoomsg("I",9026,"") 
						#9026" Product Group already exists - Please Re Enter "
						NEXT FIELD maingrp_code 
					END IF 
				END IF 

				IF l_rec_maingrp.maingrp_code IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9015,"") 
					#9015" Product Main Group must be Entered "
					NEXT FIELD maingrp_code 
				ELSE 
					SELECT desc_text 
					INTO l_maingrp_desc 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_rec_maingrp.maingrp_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("I",9012,"") 
						#9012" Product Main Group does NOT exist Try Window
						NEXT FIELD maingrp_code 
					END IF 
				END IF 

				IF l_rec_maingrp.min_month_amt IS NULL THEN 
					LET l_rec_maingrp.min_month_amt = 0 
				END IF 

				IF l_rec_maingrp.min_quart_amt IS NULL THEN 
					LET l_rec_maingrp.min_quart_amt = 0 
				END IF 
			}
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	--------------------------------------------

	CLOSE WINDOW I604

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN FALSE,NULL,NULL,NULL 
	ELSE 
		-- IF l_rec_maingrp_code IS NULL THEN 
		CASE 
			WHEN l_input_mode = "ADD"
				LET l_rec_maingrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				INSERT INTO maingrp VALUES (l_rec_maingrp.*) 
				IF sqlca.sqlcode = 0 THEN	
					RETURN TRUE,
					l_rec_maingrp.cmpy_code,l_rec_maingrp.maingrp_code,l_rec_maingrp.dept_code
				ELSE	
					RETURN FALSE,NULL,NULL,NULL
				END IF			
			WHEN l_input_mode = "EDIT"
				UPDATE maingrp 
				SET maingrp.* = l_rec_maingrp.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_rec_maingrp.maingrp_code 
				AND maingrp_code = l_rec_maingrp.maingrp_code
				and dept_code = l_rec_maingrp.dept_code
				IF sqlca.sqlcode = 0 THEN	
					RETURN TRUE,
					l_rec_maingrp.cmpy_code,l_rec_maingrp.maingrp_code,l_rec_maingrp.dept_code
				ELSE	
					RETURN FALSE,NULL,NULL,NULL
				END IF			

			{
			IF sqlca.sqlerrd[3] THEN 
				# wow !!!!!!! Sorry, no way!
				{
				UPDATE product 
				SET maingrp_code = l_rec_maingrp.maingrp_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_rec_maingrp_code 
				RETURN true 
			ELSE 
				RETURN false 

			END IF 
			}
		END CASE 
	END IF 
END FUNCTION  # input_maingrp



####################################################################
# FUNCTION select_main(p_filter)
#
#
####################################################################


####################################################################
# FUNCTION scan_main()
#
#
####################################################################




FUNCTION construct_dataset_maingrp() 
	DEFINE query_text STRING
	DEFINE where_text STRING
	DEFINE crs_list_maingrp CURSOR
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_maingrp DYNAMIC ARRAY OF t_arr_maingrp
	DEFINE l_arr_maingrp_prykey DYNAMIC ARRAY OF t_maingrp_prykey
	DEFINE idx INTEGER
	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text 
	ON 	maingrp_code,
	maingrp.desc_text,
	maingrp_code, 
	maindgrp.desc_text,
	dept_code,
	proddept.desc_text

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZG","construct-maingrp") 
			CALL Dialog.SetFieldActive("proddept.desc_text",TRUE)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER CONSTRUCT
			CALL Dialog.SetFieldActive("proddept.desc_text",FALSE)
	END CONSTRUCT 

	CALL l_arr_maingrp.Clear()
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 0,l_arr_maingrp 
	END IF

	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	LET query_text = "SELECT m.maingrp_code,m.desc_text, ", 
	" m.dept_code, d.desc_text, ",
	" m.cmpy_code,",	# adding primary key for prykey array
	" m.maingrp_code,",
	" m.dept_code ",
	"FROM maingrp m, " ,
	"proddept d ",
	"WHERE m.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND ",where_text clipped," ", 
	" AND m.cmpy_code = d.cmpy_code ",
	" AND m.dept_code = d.dept_code ",
	"ORDER BY m.dept_code,",
	" m.maingrp_code"

	CALL crs_list_maingrp.Declare(query_text)
	CALL crs_list_maingrp.Open()
	CALL l_arr_maingrp.Clear()
	CALL l_arr_maingrp_prykey.Clear()
	LET idx = 1 

	WHILE crs_list_maingrp.FetchNext(
		l_arr_maingrp[idx].maingrp_code,
		l_arr_maingrp[idx].maingrp_desc,
		l_arr_maingrp[idx].dept_code,
		l_arr_maingrp[idx].dept_desc,
		l_arr_maingrp_prykey[idx].cmpy_code,
		l_arr_maingrp_prykey[idx].maingrp_code,
		l_arr_maingrp_prykey[idx].dept_code
		) = 0
		LET idx = idx + 1 
	END WHILE 

	# idx is one element ahead, delete last empty element
	CALL l_arr_maingrp.DeleteElement(idx)
	CALL l_arr_maingrp_prykey.DeleteElement(idx)
	LET idx = l_arr_maingrp.GetSize()

	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9023,"") 
		#9023" No Main Product Groups Satsified Selection Criteria "
	END IF 

	RETURN idx,l_arr_maingrp,l_arr_maingrp_prykey
END FUNCTION  # construct_dataset_maingrp

FUNCTION scan_dataset_pick_action_maingrp(p_arr_maingrp,p_arr_maingrp_prykey) 
	DEFINE l_rec_maingrp RECORD LIKE maingrp.* 
	DEFINE p_arr_maingrp DYNAMIC ARRAY OF t_arr_maingrp 
	DEFINE p_arr_maingrp_prykey DYNAMIC ARRAY OF t_maingrp_prykey 
	DEFINE l_maingrp_prykey t_maingrp_prykey
	DEFINE l_idx,scrn,del_cnt SMALLINT 
	DEFINE l_status SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN TO Edit "
	DISPLAY ARRAY p_arr_maingrp TO sr_maingrp.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY p_arr_maingrp WITHOUT DEFAULTS FROM sr_maingrp.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZG","input-arr-p_arr_maingrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT") 
			
			IF p_arr_maingrp[l_idx].maingrp_code IS NOT NULL THEN 
				CALL input_maingrp(p_arr_maingrp_prykey[l_idx].*)
				RETURNING l_status
					{
					SELECT desc_text, 

					maingrp_code 
					INTO p_arr_maingrp[l_idx].desc_text, 
					p_arr_maingrp[l_idx].maingrp_code 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = p_arr_maingrp[l_idx].maingrp_code 
					} 
			END IF 

		ON ACTION "Add" 
			CALL input_maingrp (l_maingrp_prykey.*) RETURNING l_maingrp_prykey.*,l_status
			SELECT maingrp_code, 
			desc_text
			INTO p_arr_maingrp[l_idx].maingrp_code, 
			p_arr_maingrp[l_idx].desc_text
			FROM maingrp 
			WHERE cmpy_code = l_maingrp_prykey.cmpy_code
				AND maingrp_code = l_maingrp_prykey.maingrp_code
				AND dept_code = l_maingrp_prykey.dept_code

		ON ACTION "DELETE" 
			IF p_arr_maingrp[l_idx].maingrp_code IS NOT NULL THEN 
				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_arr_maingrp[l_idx].maingrp_code 
				IF sqlca.sqlcode =  0 THEN 
					LET l_msgresp = kandoomsg("I",7011,p_arr_maingrp[l_idx].maingrp_code) 
					#7011 Product Group assigned TO Product, No Deletion
				ELSE 
					LET del_cnt = 1 
					LET l_msgresp = kandoomsg("I",8002,del_cnt) 
					#8002 Confirm TO Delete ",del_cnt,"Product Groups(s)? (Y/N)"
					IF l_msgresp = "Y" THEN 
						#                     DELETE FROM maingrp
						#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
						#                          AND maingrp_code = p_arr_maingrp[l_idx].maingrp_code
					END IF 
				END IF 
			END IF 



		ON KEY (control-w) 
			CALL kandoohelp("") 

	END DISPLAY 
	----------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#   ELSE
		#      IF del_cnt > 0 THEN
		#         LET l_msgresp = kandoomsg("I",8002,del_cnt)
		#         #8002 Confirm TO Delete ",del_cnt,"Product Groups(s)? (Y/N)"
		#         IF l_msgresp = "Y" THEN
		#            FOR l_idx = 1 TO arr_count()
		#               IF p_arr_maingrp[l_idx].scroll_flag = "*" THEN
		#                  SELECT unique 1 FROM product
		#                     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                       AND maingrp_code = p_arr_maingrp[l_idx].maingrp_code
		#                  IF sqlca.sqlcode =  0 THEN
		#                     LET l_msgresp = kandoomsg("I",7011,p_arr_maingrp[l_idx].maingrp_code)
		#                     #7011 Product Group assigned TO Products, No Deletion
		#                  ELSE
		#                     DELETE FROM maingrp
		#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                          AND maingrp_code = p_arr_maingrp[l_idx].maingrp_code
		#                  END IF
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 
END FUNCTION 

{
	# the following functions are deprecated
	# FIXME: to be removed after QA
FUNCTION select_main(p_filter) 
	DEFINE query_text CHAR(200) 
	DEFINE where_text CHAR(100) 
	DEFINE p_filter boolean 
	DEFINE l_msgresp LIKE language.yes_flag 


	IF p_filter THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("I",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME where_text ON maingrp_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IZM","construct-maingrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 



		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET where_text = "1=1" 
		END IF 
	ELSE 
		LET where_text = "1=1" 
	END IF 

	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	LET query_text = "SELECT * FROM maingrp ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_text clipped," ", 
	"ORDER BY cmpy_code,", 
	"maingrp_code" 
	PREPARE s_maingrp FROM query_text 
	DECLARE c_maingrp CURSOR FOR s_maingrp 

	RETURN true 

END FUNCTION #  select_main

FUNCTION scan_main() 
	DEFINE pr_maingrp RECORD LIKE maingrp.* 
	DEFINE pa_maingrp DYNAMIC ARRAY OF --array[100] OF RECORD huho 9.9.2018 
	RECORD 
		#scroll_flag CHAR(1), huho
		maingrp_code LIKE maingrp.maingrp_code, 
		desc_text LIKE maingrp.desc_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE pr_rowid INTEGER 
	DEFINE pr_arr_curr, pr_arr_count, idx,del_cnt SMALLINT --,scrn 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET idx = 0 

	FOREACH c_maingrp INTO pr_maingrp.* 
		LET idx = idx + 1 
		LET pa_maingrp[idx].maingrp_code = pr_maingrp.maingrp_code 
		LET pa_maingrp[idx].desc_text = pr_maingrp.desc_text 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("I",9021,"100") 
			#9021 " First ??? Main Product Groups Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9024,"") 
		#9024" No Main Product Groups Satsified Selection Criteria "
		LET idx = 1 
	END IF 

	#  OPTIONS INSERT KEY F1,
	#           DELETE KEY F36

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("I",1003,"") 

	#" F1 TO Add - F2 TO Delete - RETURN TO Edit "
	DISPLAY ARRAY pa_maingrp TO sr_maingrp.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY pa_maingrp WITHOUT DEFAULTS FROM sr_maingrp.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZM","input-arr-pr_maingrp") 
         CALL fgl_setactionlabel("Exit", "", "", 0, FALSE) -- Deactivation of Default Action "Exit" (albo kd-2026)

		BEFORE ROW 
			LET idx = arr_curr() 
			LET pr_arr_curr = arr_curr() 
			LET pr_arr_count = arr_count() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "FILTER" 
			RETURN true 

			#      BEFORE FIELD scroll_flag
			#         LET idx = arr_curr()
			#         LET scrn = scr_line()
			#         LET pr_scroll_flag = pa_maingrp[idx].scroll_flag
			#         DISPLAY pa_maingrp[idx].*
			#              TO sr_maingrp[scrn].*

			#      AFTER FIELD scroll_flag
			#         LET pa_maingrp[idx].scroll_flag = pr_scroll_flag
			#         DISPLAY pa_maingrp[idx].scroll_flag
			#              TO sr_maingrp[scrn].scroll_flag
			#
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF arr_curr() = arr_count() THEN
			#               LET l_msgresp=kandoomsg("I",9001,"")
			#               #9001 There are no more rows in the direction ...
			#               NEXT FIELD scroll_flag
			#            ELSE
			#               IF pa_maingrp[idx+1].maingrp_code IS NULL THEN
			#                  LET l_msgresp=kandoomsg("I",9001,"")
			#                  #9001 There are no more rows in the direction ...
			#                  NEXT FIELD scroll_flag
			#               END IF
			#            END IF
			#         END IF

		ON ACTION ("ACCEPT","EDIT") 
			IF pa_maingrp[idx].maingrp_code IS NOT NULL THEN 
				IF edit_maingrp(pa_maingrp[idx].maingrp_code) THEN 
					SELECT maingrp_code, 
					desc_text 
					INTO pa_maingrp[idx].* 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = pa_maingrp[idx].maingrp_code 
				END IF 
			END IF 
			#      BEFORE FIELD maingrp_code
			#         IF pa_maingrp[idx].maingrp_code IS NOT NULL THEN
			#            IF edit_maingrp(pa_maingrp[idx].maingrp_code) THEN
			#               SELECT "",
			#                      maingrp_code,
			#                      desc_text
			#                 INTO pa_maingrp[idx].*
			#                 FROM maingrp
			#                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                  AND maingrp_code = pa_maingrp[idx].maingrp_code
			#            END IF
			#         END IF
			#         OPTIONS INSERT KEY F1,
			#                 DELETE KEY F36
			#         NEXT FIELD scroll_flag

		ON ACTION "Add" 
			LET pr_rowid = edit_maingrp("") 
			SELECT maingrp_code, 
			desc_text 
			INTO pa_maingrp[idx].maingrp_code, 
			pa_maingrp[idx].desc_text 
			FROM maingrp 
			WHERE rowid = pr_rowid 
			#
			#      BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			#            LET pr_rowid = edit_maingrp("")
			#            SELECT maingrp_code,
			#                   desc_text
			#              INTO pa_maingrp[idx].maingrp_code,
			#                   pa_maingrp[idx].desc_text
			#              FROM maingrp
			#             WHERE rowid = pr_rowid
			#            IF sqlca.sqlcode =  NOTFOUND THEN
			#               FOR idx = arr_curr() TO arr_count()
			#                  LET pa_maingrp[idx].* = pa_maingrp[idx+1].*
			#                  IF scrn <= 13 THEN
			#                     DISPLAY pa_maingrp[idx].*
			#                          TO sr_maingrp[scrn].*
			#
			#                     LET scrn = scrn + 1
			#                  END IF
			#               END FOR
			#               INITIALIZE pa_maingrp[idx].* TO NULL
			#            END IF
			#            OPTIONS INSERT KEY F1,
			#                    DELETE KEY F36
			#         ELSE
			#            IF idx > 1 THEN
			#               LET l_msgresp = kandoomsg("E",9001,"")
			#               # There are no more rows in the direction you are going "
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag


		ON ACTION "DELETE" 
			LET del_cnt = 1 
			LET l_msgresp = kandoomsg("I",8001,del_cnt) 
			#8001 Confirm TO Delete ",del_cnt,"Product Main Groups(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				#FOR idx = 1 TO arr_count()
				#IF pa_maingrp[idx].scroll_flag = "*" THEN
				SELECT unique 1 FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = pa_maingrp[idx].maingrp_code 
				IF sqlca.sqlcode =  0 THEN 
					LET l_msgresp = kandoomsg("I",7010,pa_maingrp[idx].maingrp_code) 
					#7010 Main Group assigned TO Product, No Deletion
				ELSE 
					DELETE FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = pa_maingrp[idx].maingrp_code 
				END IF 
				#END IF
				#END FOR
			END IF 
			#END IF



			#      ON KEY(F2)
			#         IF pa_maingrp[idx].maingrp_code IS NOT NULL THEN
			#            IF pa_maingrp[idx].scroll_flag IS NULL THEN
			#               SELECT unique 1 FROM prodgrp
			#                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                    AND maingrp_code = pa_maingrp[idx].maingrp_code
			#               IF sqlca.sqlcode =  0 THEN
			#                  LET l_msgresp = kandoomsg("I",7010,pa_maingrp[idx].maingrp_code)
			#                  #7010 Main Group assigned TO Product, No Deletion
			#               ELSE
			#                  LET pa_maingrp[idx].scroll_flag = "*"
			#                  LET del_cnt = del_cnt + 1
			#               END IF
			#            ELSE
			#               LET pa_maingrp[idx].scroll_flag = NULL
			#               LET del_cnt = del_cnt - 1
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag

			#ON KEY (control-w)
			#   CALL kandoohelp("")

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
			LET quit_flag = true 
			EXIT DISPLAY 

	END DISPLAY 
	-----------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

END FUNCTION # select_main
}

####################################################################
# FUNCTION edit_maingrp(pr_maingrp_code)
#
#
####################################################################
{
FUNCTION edit_maingrp(pr_maingrp_code) 
	DEFINE pr_maingrp_code LIKE maingrp.maingrp_code 
	DEFINE pr_maingrp RECORD LIKE maingrp.* 
	DEFINE pr_dept_text LIKE proddept.desc_text 
	DEFINE pr_temp_code CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW i604 with FORM "I604" 
	 CALL windecoration_i("I604") 

	SELECT maingrp.* INTO pr_maingrp.* 
	FROM maingrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND maingrp_code = pr_maingrp_code 

	IF sqlca.sqlcode =  0 THEN 
		SELECT desc_text INTO pr_dept_text 
		FROM proddept 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND dept_code = pr_maingrp.dept_code 
		AND dept_ind = 1 
		IF sqlca.sqlcode =  notfound THEN 
			LET pr_dept_text = "********" 
		END IF 
		DISPLAY BY NAME pr_dept_text 

	END IF 

	INPUT BY NAME pr_maingrp.maingrp_code, 
	pr_maingrp.desc_text, 
	pr_maingrp.dept_code, 
	pr_maingrp.min_month_amt, 
	pr_maingrp.min_quart_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZM","input-pr_maingrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD maingrp_code 
			IF pr_maingrp_code IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		ON KEY (control-b) 
			CASE 
				WHEN infield(dept_code) 
					LET pr_temp_code = "dept_ind = 1" 
					LET pr_temp_code = show_deptgrp(glob_rec_kandoouser.cmpy_code,pr_temp_code) 
					IF pr_temp_code IS NOT NULL THEN 
						LET pr_maingrp.dept_code = pr_temp_code 
						DISPLAY BY NAME pr_maingrp.dept_code 

					END IF 
			END CASE 

		AFTER FIELD maingrp_code 
			IF pr_maingrp.maingrp_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9015,"") 
				#9015" Product Main Group must be Entered "
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT * FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = pr_maingrp.maingrp_code 
				IF sqlca.sqlcode =  0 THEN 
					LET l_msgresp = kandoomsg("I",6010,"") 
					#6010" Warning: Product Main Group already exists "
				END IF 
			END IF 

		AFTER FIELD dept_code 
			CLEAR pr_dept_text 
			IF pr_maingrp.dept_code IS NOT NULL THEN 
				SELECT desc_text INTO pr_dept_text FROM proddept 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = pr_maingrp.dept_code 
				AND dept_ind = 1 
				IF sqlca.sqlcode =  notfound THEN 
					LET l_msgresp = kandoomsg("I",9124,"") 
					#9124"Incorrect department code "
					NEXT FIELD dept_code 
				ELSE 
					DISPLAY BY NAME pr_dept_text 

				END IF 
			END IF 

		AFTER FIELD min_month_amt 
			IF pr_maingrp.min_month_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Min.Amount cannot be less than zero
				LET pr_maingrp.min_month_amt = 0 
				NEXT FIELD min_month_amt 
			ELSE 
				IF pr_maingrp.min_month_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Min.Amount cannot be less than zero
					LET pr_maingrp.min_month_amt = 0 
					NEXT FIELD min_month_amt 
				END IF 
			END IF 

		AFTER FIELD min_quart_amt 
			IF pr_maingrp.min_quart_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Min.Amount cannot be less than zero
				LET pr_maingrp.min_quart_amt = 0 
				NEXT FIELD min_quart_amt 
			ELSE 
				IF pr_maingrp.min_quart_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Min.Amount cannot be less than zero
					LET pr_maingrp.min_quart_amt = 0 
					NEXT FIELD min_quart_amt 
				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_maingrp_code IS NULL THEN 
					SELECT * FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = pr_maingrp.maingrp_code 
					IF sqlca.sqlcode =  0 THEN 
						LET l_msgresp = kandoomsg("I",9025,"") 
						#9025" Product Main Group already exists - Please Re Enter "
						NEXT FIELD maingrp_code 
					END IF 
				END IF 
				IF pr_maingrp.min_month_amt IS NULL THEN 
					LET pr_maingrp.min_month_amt = 0 
				END IF 
				IF pr_maingrp.min_quart_amt IS NULL THEN 
					LET pr_maingrp.min_quart_amt = 0 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	----------------------------------------------------

	CLOSE WINDOW i604 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 

		RETURN false 

	ELSE 
		IF pr_maingrp_code IS NULL THEN 
			LET pr_maingrp.cmpy_code = glob_rec_kandoouser.cmpy_code 

			INSERT INTO maingrp VALUES (pr_maingrp.*) 
			RETURN sqlca.sqlerrd[6] 

		ELSE 
			UPDATE maingrp 
			SET maingrp.* = pr_maingrp.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND maingrp_code = pr_maingrp_code 

			RETURN sqlca.sqlerrd[3] 

		END IF 
	END IF 

END FUNCTION 
}
