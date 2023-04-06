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

###########################################################################
# \brief module U1T allows the User TO tailor the system
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
# record used in the INPUT ARRAY
DEFINE t_rec_kandoooption TYPE AS RECORD
	module_code LIKE kandoooption.module_code, 
	feature_code LIKE kandoooption.feature_code, 
	feature_text LIKE kandoooption.feature_text, 
	feature_ind LIKE kandoooption.feature_ind 
END RECORD

DEFINE t_prykey_kandoooption TYPE AS RECORD	
	module_code LIKE kandoooption.module_code, 
	feature_code LIKE kandoooption.feature_code, 
	cmpy_code LIKE kandoooption.cmpy_code
END RECORD 

DEFINE t_rec_action TYPE AS RECORD
	action_type CHAR(1)
END RECORD


###########################################################################
# MAIN
#
#
###########################################################################
FUNCTION U1T_main ()
	DEFINE number_of_errors SMALLINT
	DEFINE l_arr_rec_kandoooption_prykey DYNAMIC ARRAY OF t_prykey_kandoooption		# primary key array
	DEFINE l_arr_rec_kandoooption DYNAMIC ARRAY OF t_rec_kandoooption		# input data array
	DEFINE l_arr_rec_kandoooption_action DYNAMIC ARRAY OF t_rec_action				# status of each element 

	DEFER INTERRUPT
	DEFER QUIT

	OPEN WINDOW U209 with FORM "U209" 
	CALL windecoration_u("U209") 

	MENU "Manage Kandoo Options"
		BEFORE MENU
			HIDE OPTION "Edit Selection"
		COMMAND "Construct Selection"
			CALL construct_dataset_kandoooption() 
			RETURNING l_arr_rec_kandoooption,l_arr_rec_kandoooption_prykey,l_arr_rec_kandoooption_action
			IF ( l_arr_rec_kandoooption.GetSize() > 0 ) THEN
				SHOW OPTION "Edit Selection"
				CALL scan_dataset_pick_action_kandoooption(l_arr_rec_kandoooption,l_arr_rec_kandoooption_prykey,l_arr_rec_kandoooption_action)
				RETURNING number_of_errors
			ELSE
				ERROR "No rows found, please check your selection"
				NEXT OPTION "Edit Selection"
			END IF
				
		COMMAND "Edit Selection"
			CALL scan_dataset_pick_action_kandoooption(l_arr_rec_kandoooption,l_arr_rec_kandoooption_prykey,l_arr_rec_kandoooption_action)
			RETURNING number_of_errors

		COMMAND "Exit"
			EXIT program
	END MENU
		
END FUNCTION 
###########################################################################
# END MAIN
###########################################################################


###################################################################
# FUNCTION construct_dataset_kandoooption()
#
#
###################################################################
FUNCTION construct_dataset_kandoooption() 
	DEFINE l_formname CHAR(15) 
	DEFINE l_msgresp CHAR(1) 
	DEFINE l_feature_ind CHAR(1) 
	DEFINE l_save_feature_ind CHAR(1) 
	DEFINE l_rec_kandoooption RECORD LIKE kandoooption.* 
	DEFINE l_arr_rec_kandoooption_prykey DYNAMIC ARRAY OF t_prykey_kandoooption		# primary key array
	DEFINE l_arr_rec_kandoooption DYNAMIC ARRAY OF t_rec_kandoooption		# input data array
	DEFINE l_arr_rec_kandoooption_action DYNAMIC ARRAY OF t_rec_action				# status of each element 
	DEFINE l_rec_kandoooption_bkp t_rec_kandoooption    # backup current element
	DEFINE l_idx,l_arr_curr,l_scr_line SMALLINT 
	DEFINE l_cumulated_error_num  INTEGER   # sum of all sqlca.sqlcode in the array: if negative -> rollback
	DEFINE query_text STRING
	DEFINE where_clause STRING
	DEFINE crs_arr_kandoooption CURSOR
 
	CONSTRUCT BY NAME where_clause ON 	module_code,
		feature_code,
		feature_text,
		feature_ind

	LET query_text =
		" SELECT module_code, ",
		" feature_code, ",
		" feature_text, ",
		" feature_ind, ",
		" module_code, ",
		" feature_code, ",
		" cmpy_code, ",
		" '=' ",
		" FROM kandoooption ",
		" WHERE cmpy_code = ? ",
		" AND ",where_clause clipped,
		" ORDER BY module_code, feature_code "
	
	IF NOT int_flag THEN
		CALL crs_arr_kandoooption.Declare(query_text)
		CALL crs_arr_kandoooption.Open(glob_rec_kandoouser.cmpy_code)
		
		CALL l_arr_rec_kandoooption.Clear()
		CALL l_arr_rec_kandoooption_prykey.Clear()
		CALL l_arr_rec_kandoooption_action.Clear()
		
		LET l_idx = 1 
		WHILE crs_arr_kandoooption.FetchNext(l_arr_rec_kandoooption[l_idx].*,l_arr_rec_kandoooption_prykey[l_idx].*,l_arr_rec_kandoooption_action[l_idx].*) = 0
			LET l_idx = l_idx + 1 
		END WHILE

		# DELETE last element which is empty
		CALL l_arr_rec_kandoooption.DeleteElement(l_idx)
		CALL l_arr_rec_kandoooption_prykey.DeleteElement(l_idx)
		CALL l_arr_rec_kandoooption_action.DeleteElement(l_idx)
	ELSE
		LET int_flag = false
	END IF 

	RETURN l_arr_rec_kandoooption,l_arr_rec_kandoooption_prykey,l_arr_rec_kandoooption_action
END FUNCTION # construct_dataset_kandoooption	
###################################################################
# END FUNCTION construct_dataset_kandoooption()
###################################################################


###################################################################
# FUNCTION scan_dataset_pick_action_kandoooption(p_arr_rec_kandoooption,p_arr_rec_kandoooption_prykey,p_arr_rec_kandoooption_action)
#
#
###################################################################
FUNCTION scan_dataset_pick_action_kandoooption(p_arr_rec_kandoooption,p_arr_rec_kandoooption_prykey,p_arr_rec_kandoooption_action)
	DEFINE p_arr_rec_kandoooption DYNAMIC ARRAY OF t_rec_kandoooption		# input data array
	DEFINE p_arr_rec_kandoooption_prykey DYNAMIC ARRAY OF t_prykey_kandoooption		# primary key array
	DEFINE p_arr_rec_kandoooption_action DYNAMIC ARRAY OF t_rec_action				# status of each element 
	DEFINE l_rec_kandoooption_bkp t_rec_kandoooption    # backup current element
	DEFINE l_idx,l_arr_curr,l_scr_line SMALLINT 
	DEFINE l_cumulated_error_num,successful_ops  INTEGER   # sum of all sqlca.sqlcode in the array: if negative -> rollback
	DEFINE l_msgresp CHAR(1)

	MESSAGE kandoomsg2("U",1514,"") #1514 Enter System Tailoring Responses; F10 Usage information.

	INPUT ARRAY p_arr_rec_kandoooption WITHOUT DEFAULTS FROM sr_kandoooption.* attributes(UNBUFFERED,insert ROW = true, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1T","input-arr-kandoooption") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "Toggle Value"
			CASE 
				WHEN p_arr_rec_kandoooption[l_arr_curr].feature_ind = "Y"
					LET p_arr_rec_kandoooption[l_arr_curr].feature_ind = "N"
				WHEN p_arr_rec_kandoooption[l_arr_curr].feature_ind = "N"
					LET p_arr_rec_kandoooption[l_arr_curr].feature_ind = "Y"
			END CASE

			DISPLAY p_arr_rec_kandoooption[l_arr_curr].feature_ind TO sr_kandoooption[l_scr_line].feature_ind 

		BEFORE ROW 
			LET l_arr_curr = arr_curr() 
			LET l_scr_line = scr_line()
			LET l_rec_kandoooption_bkp.* = p_arr_rec_kandoooption[l_arr_curr].* # save the current element
			# reset 3 first fields to disabled
			CALL Dialog.setFieldActive("sr_kandoooption.module_code",FALSE)
			CALL Dialog.setFieldActive("sr_kandoooption.feature_code",FALSE)
			CALL Dialog.setFieldActive("sr_kandoooption.feature_text",FALSE)

		BEFORE INSERT 
			# push down prykey and action elements
			CALL p_arr_rec_kandoooption_prykey.insert(l_arr_curr)
			CALL p_arr_rec_kandoooption_action.insert(l_arr_curr)
			# initialize insert row
			INITIALIZE p_arr_rec_kandoooption[l_arr_curr].* TO NULL 
			LET  p_arr_rec_kandoooption_action[l_arr_curr].action_type = "I"   # this will be an INSERT
			# All the fields become editable for insert and append
			CALL Dialog.setFieldActive("sr_kandoooption.module_code",TRUE)
			CALL Dialog.setFieldActive("sr_kandoooption.feature_code",TRUE)
			CALL Dialog.setFieldActive("sr_kandoooption.feature_text",TRUE)
			CALL Dialog.setFieldActive("sr_kandoooption.feature_ind",TRUE)


		--ON ACTION "SETTINGS"  > changed by "TOGGLE VALUE"
			--CALL Dialog.setFieldActive("sr_kandoooption.feature_ind",TRUE)
		AFTER FIELD feature_text
			IF p_arr_rec_kandoooption[l_arr_curr].feature_text IS NULL THEN
				ERROR "Please input a meaningul description "
				NEXT FIELD feature_text
			END IF

		AFTER FIELD feature_ind
			IF p_arr_rec_kandoooption[l_arr_curr].feature_ind NOT MATCHES "[YN]" THEN
				ERROR "Please enter a valid value (Y/N)"
				NEXT FIELD feature_ind
			END IF

		ON CHANGE feature_ind
			IF p_arr_rec_kandoooption_action[l_arr_curr].action_type <> "I" THEN
				LET p_arr_rec_kandoooption_action[l_arr_curr].action_type = "U"	# update
			END IF

		AFTER INSERT
			# Check if PRYKEY exists
			IF check_prykey_exists_kandoooption(p_arr_rec_kandoooption[l_arr_curr].module_code,p_arr_rec_kandoooption[l_arr_curr].feature_code) THEN
				ERROR "This option code already exist, please enter other values"
				NEXT FIELD module_code
			ELSE
				LET p_arr_rec_kandoooption_action[l_arr_curr].action_type = "I"
				LET p_arr_rec_kandoooption_prykey[l_arr_curr].cmpy_code = glob_rec_kandoouser.cmpy_code
				LET p_arr_rec_kandoooption_prykey[l_arr_curr].module_code = p_arr_rec_kandoooption[l_arr_curr].module_code 
				LET p_arr_rec_kandoooption_prykey[l_arr_curr].feature_code = p_arr_rec_kandoooption[l_arr_curr].feature_code

			END IF
			
		AFTER ROW 
			MESSAGE kandoomsg2("U",1514,"") #?? Really.. this can't be right

	END INPUT #---------------------------------------------------------------------- 
	
	IF int_flag OR quit_flag THEN 		# FIXME: int_flag does not seem to be working ????
		LET int_flag = false 
		LET quit_flag = false 
		RETURN -1   # We give up and leave as is 
	END IF
 	
 	BEGIN WORK
 	
	LET l_cumulated_error_num = 0 	# add sqlca.sqlcode of each operation, if sum is negative -> rollback
	LET successful_ops = 0 
	
	FOR l_idx = 1 TO p_arr_rec_kandoooption.GetSize()
		WHENEVER SQLERROR CONTINUE
		CASE
			WHEN p_arr_rec_kandoooption_action[l_idx].action_type = "I"
				INSERT INTO kandoooption VALUES (
					glob_rec_kandoouser.cmpy_code,
					p_arr_rec_kandoooption[l_idx].module_code,
					p_arr_rec_kandoooption[l_idx].feature_code,
					p_arr_rec_kandoooption[l_idx].feature_text,
					p_arr_rec_kandoooption[l_idx].feature_ind	)
				IF sqlca.sqlcode < 0 THEN
					ERROR "Insert kandoooption failed"
				ELSE
					LET successful_ops = successful_ops + 1
				END IF
				
				LET l_cumulated_error_num = l_cumulated_error_num + sqlca.sqlcode
			
			WHEN p_arr_rec_kandoooption_action[l_idx].action_type = "U"
				UPDATE kandoooption 
				SET feature_ind = p_arr_rec_kandoooption[l_idx].feature_ind 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = p_arr_rec_kandoooption_prykey[l_idx].module_code 
				AND feature_code = p_arr_rec_kandoooption_prykey[l_idx].feature_code
				IF sqlca.sqlcode < 0 THEN
					ERROR "Update kandoooption failed"
				ELSE
					LET successful_ops = successful_ops + 1
				END IF
				LET l_cumulated_error_num = l_cumulated_error_num + sqlca.sqlcode

			OTHERWISE
				-- do nothing
		END CASE
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END FOR
	 
	IF l_cumulated_error_num < 0 THEN	
		ERROR "Updating options failed, cancelling operation"
		ROLLBACK WORK
	ELSE
		IF successful_ops > 0 THEN
			ERROR "Options update successful!"
		END IF
		COMMIT WORK
	END IF
	
	RETURN l_cumulated_error_num
END FUNCTION 	# scan_dataset_pick_action_kandoooption
###################################################################
# END FUNCTION scan_dataset_pick_action_kandoooption(p_arr_rec_kandoooption,p_arr_rec_kandoooption_prykey,p_arr_rec_kandoooption_action)
###################################################################


###################################################################
# FUNCTION check_prykey_exists_kandoooption(p_module_code,p_feature_code)
#
# FUNCTION check_prykey_exists_kandoooption: checks whether the primary key exists
# inbound: cmpy_code and module_code
# outbound: boolean true if exists, false if not exists
###################################################################
FUNCTION check_prykey_exists_kandoooption(p_module_code,p_feature_code)
DEFINE p_module_code LIKE kandoooption.module_code
DEFINE p_feature_code LIKE kandoooption.feature_code
DEFINE prykey_exists BOOLEAN

# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = 'f'
	SELECT 't'
	INTO prykey_exists
	FROM kandoooption
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND module_code = p_module_code
		AND feature_code = p_feature_code

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_kandoooption()
###################################################################
# END FUNCTION check_prykey_exists_kandoooption(p_module_code,p_feature_code)
###################################################################