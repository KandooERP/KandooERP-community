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

	Source code beautified by beautify.pl on 2020-01-03 09:12:49	$Id: $
}



#
# 	Product Group Maintenance
#
#   IZG.4gl - Maintenance Program FOR product groups.
#
#    Important Note: prodgrp.min_month_amt = "Minimum Statistics Amount"
#                    prodgrp.min_quart_amt = "Minimum Distribution Amount"
#                    prodgrp.min_year_amt = This Column Is Not Used. SP 5/4/94
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

DEFINE t_arr_prodgrp TYPE AS RECORD 
	prodgrp_code LIKE prodgrp.prodgrp_code, 
	prodgrp_desc LIKE prodgrp.desc_text, 
	maingrp_code LIKE prodgrp.maingrp_code, 
	maingrp_desc LIKE maingrp.desc_text,
	dept_code LIKE prodgrp.dept_code, 
	dept_desc LIKE proddept.desc_text
END RECORD 

DEFINE t_prodgrp_prykey TYPE AS RECORD
	cmpy_code LIKE prodgrp.cmpy_code,
	prodgrp_code LIKE prodgrp.prodgrp_code, 
	maingrp_code LIKE prodgrp.maingrp_code,
	dept_code LIKE prodgrp.dept_code
END RECORD
####################################################################
# IZG_main
#
####################################################################
FUNCTION IZG_main()
	DEFINE nb_elements INTEGER 
	DEFINE l_arr_prodgrp DYNAMIC ARRAY OF t_arr_prodgrp
	DEFINE l_arr_prodgrp_prykey DYNAMIC ARRAY OF t_prodgrp_prykey
	OPEN WINDOW i605 with FORM "I605" 
	 CALL windecoration_i("I605") 

	CALL construct_dataset_prodgrp() RETURNING nb_elements,l_arr_prodgrp,l_arr_prodgrp_prykey
	CALL scan_dataset_pick_action_prodgrp(l_arr_prodgrp,l_arr_prodgrp_prykey) 

	CLOSE WINDOW i605 
END FUNCTION # IZG_main 


####################################################################
# FUNCTION construct_dataset_prodgrp()
# This function performs a QBE on product group, executes the SELECT for given criteria
# and returns number of elements found and array of elements
####################################################################
FUNCTION construct_dataset_prodgrp() 
	DEFINE query_text STRING
	DEFINE where_text STRING
	DEFINE crs_list_prodgrp CURSOR
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_prodgrp DYNAMIC ARRAY OF t_arr_prodgrp
	DEFINE l_arr_prodgrp_prykey DYNAMIC ARRAY OF t_prodgrp_prykey
	DEFINE idx INTEGER
	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text 
	ON 	prodgrp_code,
	prodgrp.desc_text,
	maingrp_code, 
	maindgrp.desc_text,
	dept_code,
	proddept.desc_text

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZG","construct-prodgrp") 
			CALL Dialog.SetFieldActive("maingrp.desc_text",TRUE)
			CALL Dialog.SetFieldActive("proddept.desc_text",TRUE)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER CONSTRUCT
			CALL Dialog.SetFieldActive("maingrp.desc_text",FALSE)
			CALL Dialog.SetFieldActive("proddept.desc_text",FALSE)
	END CONSTRUCT 

	CALL l_arr_prodgrp.Clear()
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 0,l_arr_prodgrp 
	END IF

	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	LET query_text = "SELECT g.prodgrp_code,g.desc_text, ", 
	" g.maingrp_code,m.desc_text,",
	" g.dept_code, d.desc_text, ",
	" g.cmpy_code,",	# adding primary key for prykey array
	" g.prodgrp_code,",
	" g.maingrp_code,",
	" g.dept_code ",
	"FROM prodgrp g,",
	" maingrp m, " ,
	"proddept d ",
	"WHERE g.cmpy_code = ? ",
	" AND ",where_text clipped," ", 
	" AND g.cmpy_code = m.cmpy_code ",
	" AND g.maingrp_code = m.maingrp_code ",
	" AND g.dept_code = m.dept_code ",
	" AND m.cmpy_code = d.cmpy_code ",
	" AND m.dept_code = d.dept_code ",
	"ORDER BY g.dept_code,",
	" g.maingrp_code,",
	"g.prodgrp_code"

	CALL crs_list_prodgrp.Declare(query_text)
	CALL crs_list_prodgrp.Open(glob_rec_kandoouser.cmpy_code)
	CALL l_arr_prodgrp.Clear()
	CALL l_arr_prodgrp_prykey.Clear()
	LET idx = 1 

	WHILE crs_list_prodgrp.FetchNext(
		l_arr_prodgrp[idx].prodgrp_code,
		l_arr_prodgrp[idx].prodgrp_desc,
		l_arr_prodgrp[idx].maingrp_code,
		l_arr_prodgrp[idx].maingrp_desc,
		l_arr_prodgrp[idx].dept_code,
		l_arr_prodgrp[idx].dept_desc,
		l_arr_prodgrp_prykey[idx].cmpy_code,
		l_arr_prodgrp_prykey[idx].prodgrp_code,
		l_arr_prodgrp_prykey[idx].maingrp_code,
		l_arr_prodgrp_prykey[idx].dept_code
		) = 0
		LET idx = idx + 1 
	END WHILE 

	# idx is one element ahead, delete last empty element
	CALL l_arr_prodgrp.DeleteElement(idx)
	LET idx = l_arr_prodgrp.GetSize()

	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9023,"") 
		#9023" No Main Product Groups Satsified Selection Criteria "
	END IF 

	RETURN idx,l_arr_prodgrp,l_arr_prodgrp_prykey
END FUNCTION  # construct_dataset_prodgrp


####################################################################
# FUNCTION scan_dataset_pick_action_prodgrp()
#
#
####################################################################
FUNCTION scan_dataset_pick_action_prodgrp(p_arr_prodgrp,p_arr_prodgrp_prykey) 
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE p_arr_prodgrp DYNAMIC ARRAY OF t_arr_prodgrp 
	DEFINE p_arr_prodgrp_prykey DYNAMIC ARRAY OF t_prodgrp_prykey 
	DEFINE l_prodgrp_prykey t_prodgrp_prykey
	DEFINE l_idx,scrn,del_cnt SMALLINT 
	DEFINE l_status SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN TO Edit "
	DISPLAY ARRAY p_arr_prodgrp TO sr_prodgrp.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY p_arr_prodgrp WITHOUT DEFAULTS FROM sr_prodgrp.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZG","input-arr-p_arr_prodgrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","ACCEPT") 
			IF p_arr_prodgrp[l_idx].prodgrp_code IS NOT NULL THEN 
				CALL input_prodgrp(MODE_CLASSIC_EDIT,p_arr_prodgrp_prykey[l_idx].*) RETURNING l_status
					{
					SELECT desc_text, 

					maingrp_code 
					INTO p_arr_prodgrp[l_idx].desc_text, 
					p_arr_prodgrp[l_idx].maingrp_code 
					FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = p_arr_prodgrp[l_idx].prodgrp_code 
					} 
			END IF 

		ON ACTION "Add" 
			CALL input_prodgrp ("ADD",l_prodgrp_prykey.*) RETURNING l_prodgrp_prykey.*,l_status
			SELECT prodgrp_code, 
			desc_text, 
			maingrp_code 
			INTO p_arr_prodgrp[l_idx].prodgrp_code, 
			p_arr_prodgrp[l_idx].desc_text, 
			p_arr_prodgrp[l_idx].maingrp_code 
			FROM prodgrp 
			WHERE cmpy_code = l_prodgrp_prykey.cmpy_code
				AND prodgrp_code = l_prodgrp_prykey.prodgrp_code
				AND maingrp_code = l_prodgrp_prykey.maingrp_code
				AND dept_code = l_prodgrp_prykey.dept_code

		ON ACTION "DELETE" 
			IF p_arr_prodgrp[l_idx].prodgrp_code IS NOT NULL THEN 
				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_arr_prodgrp[l_idx].prodgrp_code 
				IF sqlca.sqlcode= 0 THEN 
					LET l_msgresp = kandoomsg("I",7011,p_arr_prodgrp[l_idx].prodgrp_code) 
					#7011 Product Group assigned TO Product, No Deletion
				ELSE 
					LET del_cnt = 1 
					LET l_msgresp = kandoomsg("I",8002,del_cnt) 
					#8002 Confirm TO Delete ",del_cnt,"Product Groups(s)? (Y/N)"
					IF l_msgresp = "Y" THEN 
						#                     DELETE FROM prodgrp
						#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
						#                          AND prodgrp_code = p_arr_prodgrp[l_idx].prodgrp_code
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
		#               IF p_arr_prodgrp[l_idx].scroll_flag = "*" THEN
		#                  SELECT unique 1 FROM product
		#                     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                       AND prodgrp_code = p_arr_prodgrp[l_idx].prodgrp_code
		#                  IF sqlca.sqlcode= 0 THEN
		#                     LET l_msgresp = kandoomsg("I",7011,p_arr_prodgrp[l_idx].prodgrp_code)
		#                     #7011 Product Group assigned TO Products, No Deletion
		#                  ELSE
		#                     DELETE FROM prodgrp
		#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                          AND prodgrp_code = p_arr_prodgrp[l_idx].prodgrp_code
		#                  END IF
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 
END FUNCTION 



####################################################################
# FUNCTION input_prodgrp(l_rec_prodgrp_code)
#
#
####################################################################
FUNCTION input_prodgrp(p_mode,p_prodgrp_prykey) 
	DEFINE p_mode CHAR(5)
	DEFINE p_prodgrp_prykey t_prodgrp_prykey
	DEFINE l_rec_prodgrp_code LIKE prodgrp.prodgrp_code 
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE l_temp_code CHAR(20) 
	DEFINE l_maingrp_desc LIKE maingrp.desc_text 
	DEFINE l_proddept_desc LIKE proddept.desc_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_input_mode CHAR(5)
	DEFINE l_status INTEGER

	OPEN WINDOW i606 with FORM "I606" 
	 CALL windecoration_i("I606") 

	# Try to SELECT this row: if exists mode is EDIT, else mode is ADD
	SELECT prodgrp.* INTO l_rec_prodgrp.* 
	FROM prodgrp 
	WHERE cmpy_code = p_prodgrp_prykey.cmpy_code
	AND prodgrp_code = p_prodgrp_prykey.prodgrp_code 
	AND maingrp_code = p_prodgrp_prykey.maingrp_code 
	AND dept_code = p_prodgrp_prykey.dept_code 

	IF sqlca.sqlcode= 0 THEN 
		# prodgrp exists, this is "EDIT"
		LET l_input_mode = MODE_CLASSIC_EDIT
		
		CALL db_get_desc_maingrp(l_rec_prodgrp.cmpy_code,l_rec_prodgrp.dept_code,l_rec_prodgrp.maingrp_code)
		RETURNING  l_maingrp_desc,l_status

		IF l_status = 0 THEN 
			LET l_maingrp_desc = "********"
		END IF
		DISPLAY BY NAME  l_maingrp_desc 

		CALL db_get_desc_proddept(l_rec_prodgrp.cmpy_code,l_rec_prodgrp.dept_code)
		RETURNING  l_proddept_desc,l_status

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_proddept_desc = "********" 
		END IF 
		DISPLAY BY NAME l_proddept_desc 
	ELSE
		LET l_input_mode = "ADD"
		LET l_rec_prodgrp.cmpy_code = glob_rec_kandoouser.cmpy_code
	END IF 

	INPUT BY NAME l_rec_prodgrp.dept_code,
	l_rec_prodgrp.maingrp_code, 
	l_rec_prodgrp.prodgrp_code, 
	l_rec_prodgrp.desc_text, 
	l_rec_prodgrp.min_month_amt, 
	l_rec_prodgrp.min_quart_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZG","input-l_rec_prodgrp") 
			IF l_input_mode = MODE_CLASSIC_EDIT THEN	
				CALL Dialog.setFieldActive("prodgrp_code",FALSE) 
			ELSE
				CALL Dialog.setFieldActive("prodgrp_code",TRUE) 
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
						LET l_rec_prodgrp.maingrp_code = l_temp_code 
						DISPLAY BY NAME l_rec_prodgrp.maingrp_code 

					END IF 
			END CASE 

		# Replaced by setfield disable when in edit/not create mode

		AFTER FIELD dept_code 
			CLEAR l_maingrp_desc 
			IF l_rec_prodgrp.dept_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9015,"") 
				#9015" Product Main Group must be Entered "
				NEXT FIELD dept_code 
			ELSE 
				CALL db_get_desc_proddept(l_rec_prodgrp.cmpy_code,l_rec_prodgrp.dept_code)
				RETURNING l_proddept_desc,l_status 
 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("I",9012,"") 
					#9012" Product Main Group does NOT exist Try Window
					NEXT FIELD dept_code 
				ELSE 
					DISPLAY BY NAME l_proddept_desc 

				END IF 
			END IF 

		BEFORE field maingrp_code
			CALL dyn_combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_rec_prodgrp.dept_code) 

		AFTER FIELD maingrp_code 
			CLEAR l_maingrp_desc 
			IF l_rec_prodgrp.maingrp_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9015,"") 
				#9015" Product Main Group must be Entered "
				NEXT FIELD maingrp_code 
			ELSE 
				CALL db_get_desc_maingrp(l_rec_prodgrp.cmpy_code,l_rec_prodgrp.dept_code,l_rec_prodgrp.maingrp_code)
				RETURNING l_maingrp_desc,l_status 
 
				IF l_status = 0 THEN 
					LET l_msgresp = kandoomsg("I",9012,"") 
					#9012" Product Main Group does NOT exist Try Window
					NEXT FIELD maingrp_code 
				ELSE 
					DISPLAY BY NAME l_maingrp_desc 

				END IF 
			END IF 

		AFTER FIELD prodgrp_code 
			IF l_rec_prodgrp.prodgrp_code IS NULL THEN 
				LET l_msgresp = kandoomsg("I",9014,"") 
				#9014" Product Group must be Entered "
				NEXT FIELD prodgrp_code 
			ELSE 
				IF check_prykey_exists_prodgrp (l_rec_prodgrp.cmpy_code,l_rec_prodgrp.dept_code,l_rec_prodgrp.maingrp_code,l_rec_prodgrp.prodgrp_code) THEN
					LET l_msgresp = kandoomsg("I",6011,"") 
					#6011" Warning: Product Group already exists "
					NEXT FIELD prodgrp_code 
				END IF 
			END IF 

		AFTER FIELD min_month_amt 
			IF l_rec_prodgrp.min_month_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Amount must be entered
				LET l_rec_prodgrp.min_month_amt = 0 
				NEXT FIELD min_month_amt 
			ELSE 
				IF l_rec_prodgrp.min_month_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Amount must be entered
					LET l_rec_prodgrp.min_month_amt = 0 
					NEXT FIELD min_month_amt 
				END IF 
			END IF 

		AFTER FIELD min_quart_amt 
			IF l_rec_prodgrp.min_quart_amt IS NULL THEN 
				LET l_msgresp=kandoomsg("I",9102,"") 
				#9102 Amount must be entered
				LET l_rec_prodgrp.min_quart_amt = 0 
				NEXT FIELD min_quart_amt 
			ELSE 
				IF l_rec_prodgrp.min_quart_amt < 0 THEN 
					LET l_msgresp=kandoomsg("I",9103,"") 
					#9103 Amount must be entered
					LET l_rec_prodgrp.min_quart_amt = 0 
					NEXT FIELD min_quart_amt 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
			{
				IF l_rec_prodgrp_code IS NULL THEN 
					SELECT * FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = l_rec_prodgrp.prodgrp_code 
					IF sqlca.sqlcode= 0 THEN 
						LET l_msgresp = kandoomsg("I",9026,"") 
						#9026" Product Group already exists - Please Re Enter "
						NEXT FIELD prodgrp_code 
					END IF 
				END IF 

				IF l_rec_prodgrp.maingrp_code IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9015,"") 
					#9015" Product Main Group must be Entered "
					NEXT FIELD maingrp_code 
				ELSE 
					SELECT desc_text 
					INTO l_maingrp_desc 
					FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = l_rec_prodgrp.maingrp_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("I",9012,"") 
						#9012" Product Main Group does NOT exist Try Window
						NEXT FIELD maingrp_code 
					END IF 
				END IF 

				IF l_rec_prodgrp.min_month_amt IS NULL THEN 
					LET l_rec_prodgrp.min_month_amt = 0 
				END IF 

				IF l_rec_prodgrp.min_quart_amt IS NULL THEN 
					LET l_rec_prodgrp.min_quart_amt = 0 
				END IF 
			}
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	--------------------------------------------

	CLOSE WINDOW i606 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		-- IF l_rec_prodgrp_code IS NULL THEN 
		CASE 
			WHEN l_input_mode = "ADD"
				LET l_rec_prodgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				INSERT INTO prodgrp VALUES (l_rec_prodgrp.*) 
				IF sqlca.sqlcode = 0 THEN	
					RETURN TRUE,
					l_rec_prodgrp.cmpy_code,
					l_rec_prodgrp.prodgrp_code,l_rec_prodgrp.maingrp_code,l_rec_prodgrp.dept_code
				ELSE	
					RETURN FALSE,NULL,NULL,NULL,NULL
				END IF			
			WHEN l_input_mode = MODE_CLASSIC_EDIT
				UPDATE prodgrp 
				SET prodgrp.* = l_rec_prodgrp.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_prodgrp.prodgrp_code 
				AND maingrp_code = l_rec_prodgrp.maingrp_code
				and dept_code = l_rec_prodgrp.dept_code
				IF sqlca.sqlcode = 0 THEN	
					RETURN TRUE,
					l_rec_prodgrp.cmpy_code,
					l_rec_prodgrp.prodgrp_code,l_rec_prodgrp.maingrp_code,l_rec_prodgrp.dept_code
				ELSE	
					RETURN FALSE,NULL,NULL,NULL,NULL
				END IF			

			{
			IF sqlca.sqlerrd[3] THEN 
				# wow !!!!!!! Sorry, no way!
				{
				UPDATE product 
				SET maingrp_code = l_rec_prodgrp.maingrp_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_prodgrp_code 
				RETURN true 
			ELSE 
				RETURN false 

			END IF 
			}
		END CASE 
	END IF 
END FUNCTION  # input_prodgrp

