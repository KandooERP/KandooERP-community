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
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ2_GLOBALS.4gl"  
############################################################
# Module Scope Variables
############################################################

#################################################################################
# FUNCTION AZ2_main()
#
# AZ2 maintains term codes
#################################################################################
FUNCTION AZ2_main() 
	DEFINE l_withquery SMALLINT #0=no query 1=query 2=exit 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AZ2") 

	CALL payment_methods() 

	OPEN WINDOW A102 with FORM "A102" 
	CALL windecoration_a("A102") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL AZ2_scan_term() 
--	WHILE db_term_get_datasource(l_withquery) 
--		LET l_withquery = AZ2_scan_term() 
--		IF l_withquery = 2 OR int_flag THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 

	CLOSE WINDOW A102 
END FUNCTION 
#################################################################################
# END FUNCTION AZ2_main()
#################################################################################


#################################################################################
# FUNCTION db_term_get_datasource(p_filter)
#
#
#################################################################################
FUNCTION db_term_get_datasource(p_filter) 
	DEFINE p_filter boolean
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_arr_rec_term DYNAMIC ARRAY OF 
	RECORD 
		term_code LIKE term.term_code, 
		desc_text LIKE term.desc_text 
	END RECORD 

	DEFINE l_idx SMALLINT 

	IF p_filter THEN

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"")	#1001 Enter selection criteria - ESC TO continue
		CONSTRUCT BY NAME l_where_text ON 
			term_code, 
			desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ2","construct-term") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 	
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 
	
	MESSAGE kandoomsg2("A",1002,"") #1002 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM term ", 
		"WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"term_code" 
	PREPARE s_term FROM l_query_text 
	DECLARE c_term CURSOR FOR s_term 
	
	LET l_idx = 0 
	FOREACH c_term INTO l_rec_term.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_term[l_idx].term_code = l_rec_term.term_code 
		LET l_arr_rec_term[l_idx].desc_text = l_rec_term.desc_text

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9100,"") 	#9087 " No payment terms satisfied the selection criteria"
	END IF 	

	RETURN l_arr_rec_term
END FUNCTION 
#################################################################################
# END FUNCTION db_term_get_datasource()
#################################################################################


#################################################################################
# FUNCTION AZ2_scan_term()
#
#
#################################################################################
FUNCTION AZ2_scan_term() 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_arr_rec_term DYNAMIC ARRAY OF 
	RECORD 
		term_code LIKE term.term_code, 
		desc_text LIKE term.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_term_get_count() > 1000 THEN 
		CALL db_term_get_datasource(TRUE) RETURNING l_arr_rec_term
	ELSE
		CALL db_term_get_datasource(FALSE) RETURNING l_arr_rec_term 
	END IF 
	
 
	MESSAGE kandoomsg2("A",1003,"") # "F1 TO add, RETURN on line TO change, F2 TO delete"
	DISPLAY ARRAY l_arr_rec_term TO sr_term.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZ2","inp-arr-term") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_term.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_term.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER"
			CALL l_arr_rec_term.clear()
			CALL db_term_get_datasource(TRUE) RETURNING l_arr_rec_term 

		ON ACTION "REFRESH"
			CALL windecoration_a("A102") 
			CALL l_arr_rec_term.clear()
			CALL db_term_get_datasource(FALSE) RETURNING l_arr_rec_term 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","doubleClick") --edit
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_term.getSize()) THEN
				IF term_edit(l_arr_rec_term[l_idx].term_code) = 0 THEN 
--					CALL db_term_get_arr_rec_short(null) RETURNING l_arr_rec_term
					CALL l_arr_rec_term.clear()
					CALL db_term_get_datasource(FALSE) RETURNING l_arr_rec_term 
				END IF 
			END IF
			
		ON ACTION "ADD" 
			IF term_new() = 0 THEN 
--				CALL db_term_get_arr_rec_short(null) RETURNING l_arr_rec_term 
				CALL l_arr_rec_term.clear()
				CALL db_term_get_datasource(FALSE) RETURNING l_arr_rec_term 
			END IF 

		ON ACTION "DELETE"
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_term.getSize()) THEN
				IF term_delete(l_arr_rec_term[l_idx].term_code) THEN 
					DELETE FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = l_arr_rec_term[l_idx].term_code 
					
					DELETE FROM termdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = l_arr_rec_term[l_idx].term_code 
				END IF 
				CALL l_arr_rec_term.clear()
				CALL db_term_get_datasource(FALSE) RETURNING l_arr_rec_term 
			END IF
	END DISPLAY 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	END IF 
END FUNCTION 
#################################################################################
# END FUNCTION AZ2_scan_term()
#################################################################################


#################################################################################
# FUNCTION term_new()
#
# RETURN l_ret
#################################################################################
FUNCTION term_new() 
	DEFINE l_ret SMALLINT 
	DEFINE l_rec_term RECORD LIKE term.* 

	OPEN WINDOW A617 with FORM "A617" 
	CALL windecoration_a("A617") 
	CALL term_rec_new_input() RETURNING l_rec_term.* 
	IF l_rec_term.term_code IS NOT NULL THEN 
		LET l_ret = 0 
		CALL db_term_insert(l_rec_term.*) 
		CALL term_manage(l_rec_term.term_code) 
	END IF 
	CLOSE WINDOW A617 

	RETURN l_ret 
END FUNCTION 
#################################################################################
# END FUNCTION term_new()
#################################################################################


#################################################################################
# FUNCTION term_edit()
#
# RETURN l_ret
#################################################################################
FUNCTION term_edit(p_term_code) 
	DEFINE p_term_code LIKE term.term_code 
	DEFINE l_ret SMALLINT 

	OPEN WINDOW A617 with FORM "A617" 
	CALL windecoration_a("A617") 

	LET l_ret = -1 

	IF db_term_pk_exists(p_term_code) THEN #we NEED a valid RECORD TO be able TO edit it 
		LET l_ret = term_manage(p_term_code) 
	END IF 
	CLOSE WINDOW A617 

	RETURN l_ret 
END FUNCTION 
#################################################################################
# END FUNCTION term_edit()
#################################################################################


#################################################################################
# FUNCTION term_rec_new_input(p_term_code)
#
#
#################################################################################
FUNCTION term_rec_new_input() 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_old_day_num LIKE term.due_day_num 
	DEFINE l_help_text LIKE kandooword.response_text 
	DEFINE l_temp_text CHAR(20) 

	#Create new record
	LET l_rec_term.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_term.day_date_ind = "D" 
	LET l_rec_term.due_day_num = 1 

	#-----------------------------------------------------------------------------------------------------


	# 1018 Enter Payment Term Details - ESC TO Continue
	INPUT BY NAME 
		l_rec_term.term_code, 
		l_rec_term.desc_text, 
		l_rec_term.day_date_ind, 
		l_rec_term.due_day_num	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ2","inp-term") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(day_date_ind) 
			LET l_temp_text = show_payment_methods() 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_term.day_date_ind = l_temp_text 
				CALL payment_desc(l_rec_term.day_date_ind) 
				NEXT FIELD day_date_ind 
			END IF 

		AFTER FIELD term_code 
			IF db_term_term_code_validate(l_rec_term.term_code,"notNull","N") <> 0 THEN 
				NEXT FIELD term_code 
			END IF 

		AFTER FIELD desc_text 
			IF db_term_desc_text_validate(l_rec_term.desc_text,"notNull","N") <> 0 THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD day_date_ind 
			IF db_term_due_day_num_validate(l_rec_term.due_day_num,"notNull","N") <> 0 THEN 
				CASE db_term_due_day_num_with_day_date_ind_validate(l_rec_term.due_day_num,l_rec_term.day_date_ind,"notNull","N") 
					WHEN 0 #correct 
						CALL payment_desc(l_rec_term.day_date_ind) 
					WHEN -1 # =null OR < 0 
						LET l_rec_term.due_day_num = l_old_day_num # must enter a value 
						NEXT FIELD due_day_num 
					WHEN -2 # =0 
						LET l_rec_term.due_day_num = 1 # DATE must be between 1 AND 31 
						NEXT FIELD due_day_num 
					WHEN -2 # >31 
						LET l_rec_term.due_day_num = 31 # DATE must be between 1 AND 31 
						NEXT FIELD due_day_num 
					OTHERWISE 
						NEXT FIELD due_day_num 
						ERROR "Invalid Value - Only 1-31 IS valid" 
				END CASE 
			END IF 

		BEFORE FIELD due_day_num 
			LET l_help_text = kandooword("term.due_day_num",l_rec_term.day_date_ind) 
			MESSAGE l_help_text 

		AFTER FIELD due_day_num 
			IF db_term_due_day_num_validate(l_rec_term.due_day_num,"notNull","N") <> 0 THEN 
				CASE db_term_due_day_num_with_day_date_ind_validate(l_rec_term.due_day_num,l_rec_term.day_date_ind,"notNull","N") 
					WHEN 0 #correct 
						CALL payment_desc(l_rec_term.day_date_ind) 
					WHEN -1 # =null OR < 0 
						LET l_rec_term.due_day_num = l_old_day_num # must enter a value 
						NEXT FIELD due_day_num 
					WHEN -2 # =0 
						LET l_rec_term.due_day_num = 1 # DATE must be between 1 AND 31 
						NEXT FIELD due_day_num 
					WHEN -2 # >31 
						LET l_rec_term.due_day_num = 31 # DATE must be between 1 AND 31 
						NEXT FIELD due_day_num 
					OTHERWISE 
						NEXT FIELD due_day_num 
						ERROR "Invalid Value - Only 1-31 IS valid" 
				END CASE 
			END IF 

	END INPUT 
	# ------------------------------------------------------------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		MESSAGE "Term Entry aborted" 
		RETURN NULL 
	ELSE 
		RETURN l_rec_term.* 
	END IF 
END FUNCTION 
#################################################################################
# END FUNCTION term_rec_new_input(p_term_code)
#################################################################################


#################################################################################
# FUNCTION term_manage(p_term_code)
#
#
#################################################################################
FUNCTION term_manage(p_term_code) 
	DEFINE p_term_code LIKE term.term_code 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_edit_termdetl RECORD LIKE termdetl.* 

	DEFINE l_arr_rec_termdetl DYNAMIC ARRAY OF 
	RECORD 
		days_num LIKE termdetl.days_num, 
		disc_per LIKE termdetl.disc_per 
	END RECORD 
	DEFINE l_old_day_num LIKE term.due_day_num 
	DEFINE l_help_text LIKE kandooword.response_text 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_idx SMALLINT 

	LET l_old_day_num = l_rec_term.due_day_num 

	# ------------------------------------------------------------------------------------------------------
	IF p_term_code IS NOT NULL THEN 
		CALL db_term_get_rec(UI_OFF,p_term_code) RETURNING l_rec_term.* 
		CALL l_arr_rec_termdetl.clear() 
		CALL db_termdetl_get_arr_rec(p_term_code) RETURNING l_arr_rec_termdetl 
		LET l_rec_edit_termdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_edit_termdetl.term_code = l_rec_term.term_code 
	ELSE 
		CALL l_arr_rec_termdetl.delete() 
		RETURN -1 
	END IF 

	CALL payment_desc(l_rec_term.day_date_ind) 
	ERROR kandoomsg2("A",1018,"") 

	ERROR kandoomsg2("A",1049,"") 
	#We need TO do this, because the BEFORE ROW event IS NOT triggered in a display array located in a DIALOG block until the user clicks on it.
	#Also, the table could be empty

	###################################################################################################
	# BEGIN DIALOG --------------------------------------------------------------------------------------
	# --------------------------------------------------------------------------------------------------------------------------------
	DIALOG ATTRIBUTE(UNBUFFERED) 

	#1049 Settlement Discount Lines - F1 Add  F2 Delete  RETURN Edit
	#INPUT ARRAY l_arr_rec_termdetl WITHOUT DEFAULTS FROM sr_termdetl.* ATTRIBUTE(UNBUFFERED)
	# I do NOT understand, why the DIALOG.getCurrentRow("sr_termdetl") in before row returns 0
	# do you understand this ?# do you understand this ?# do you understand this ?# do you understand this ?

	# --------------------------------------------------------------------------------------------------------------------------------
		DISPLAY ARRAY l_arr_rec_termdetl TO sr_termdetl.* 
			BEFORE ROW 
				#DISPLAY "l_idx old=", l_idx
				#FOR i = 1 TO l_arr_rec_termdetl.getSize()
				#	DISPLAY l_arr_rec_termdetl[i].*
				#END FOR
				LET l_idx = DIALOG.getCurrentRow("sr_termdetl") #returned me 0 ????!!! ????? 
				#DISPLAY "l_idx new=", l_idx
	
				IF l_idx > 0 THEN 
					LET l_rec_edit_termdetl.days_num = l_arr_rec_termdetl[l_idx].days_num 
					LET l_rec_edit_termdetl.disc_per = l_arr_rec_termdetl[l_idx].disc_per 
				END IF 
	
			ON ACTION "DELETE" 
				IF l_rec_edit_termdetl.days_num IS NOT NULL THEN 
					IF NOT db_termdetl_pk_exists(l_rec_term.term_code,l_rec_edit_termdetl.days_num) THEN #check IF RECORD pk already exists 
						ERROR "Payment details for ", trim(l_rec_edit_termdetl.days_num), " does NOT exist" 
					ELSE 
						CALL db_termdetl_delete(l_rec_edit_termdetl.*) 
						CALL db_termdetl_get_arr_rec(p_term_code) RETURNING l_arr_rec_termdetl 
					END IF 
				END IF 
	
		END DISPLAY 
		# --------------------------------------------------------------------------------------------------------------------------------

		# --------------------------------------------------------------------------------------------------------------------------------
		INPUT l_rec_edit_termdetl.* WITHOUT DEFAULTS FROM sr_termdedit.* 
			AFTER FIELD edit_days_num 
				IF db_termdetl_days_num_validate(l_rec_edit_termdetl.*,"notNull","") THEN 
					NEXT FIELD edit_days_num 
				END IF 
	
			AFTER FIELD edit_disc_per 
				IF db_termdetl_disc_per_validate(l_rec_edit_termdetl.disc_per,"notNull","") THEN 
					NEXT FIELD edit_disc_per 
				ELSE #update OR insert/new 
					IF db_termdetl_pk_exists(l_rec_term.term_code,l_rec_edit_termdetl.days_num) THEN #check IF RECORD pk already exists 
						#UPDATE record
						IF db_termdetl_update(l_rec_edit_termdetl.*) = 0 THEN 
							CALL db_termdetl_get_arr_rec(p_term_code) RETURNING l_arr_rec_termdetl 
						ELSE 
							ERROR "Could NOT UPDATE record" 
						END IF 
					ELSE 
						#NEW record
						IF promptYN("New Payment Term Details","Do you want TO add a new payment term detail ?","Y") = "y" THEN 
							IF db_termdetl_insert(l_rec_edit_termdetl.*) = 0 THEN 
								CALL db_termdetl_get_arr_rec(p_term_code) RETURNING l_arr_rec_termdetl 
							ELSE 
								ERROR "Could NOT create new record" 
							END IF 
						END IF 
					END IF 
				END IF 
	
		END INPUT 
		# --------------------------------------------------------------------------------------------------------------------------------
	
		# --------------------------------------------------------------------------------------------------------------------------------
		# 1018 Enter Payment Term Details - ESC TO Continue
		INPUT BY NAME #l_rec_term.term_code, #read only 
			l_rec_term.desc_text, 
			l_rec_term.day_date_ind, 
			l_rec_term.due_day_num WITHOUT DEFAULTS 
	
	
			BEFORE INPUT 
				DISPLAY BY NAME l_rec_term.term_code 
	
			ON ACTION "LOOKUP" infield(day_date_ind) 
				LET l_temp_text = show_payment_methods() 
				IF l_temp_text IS NOT NULL THEN 
					LET l_rec_term.day_date_ind = l_temp_text 
					CALL payment_desc(l_rec_term.day_date_ind) 
					NEXT FIELD day_date_ind 
				END IF 
	
	
			AFTER FIELD desc_text 
				IF db_term_desc_text_validate(l_rec_term.desc_text,"notNull","E") THEN 
					NEXT FIELD desc_text 
				END IF 
	
			AFTER FIELD day_date_ind 
				IF db_term_day_date_ind_validate(l_rec_term.day_date_ind,"notNull","E") <> 0 THEN 
					NEXT FIELD day_date_ind 
				ELSE 
					CALL payment_desc(l_rec_term.day_date_ind) 
					IF db_term_due_day_num_validate(l_rec_term.due_day_num,"notNull","E") <> 0 THEN 
						CASE db_term_due_day_num_with_day_date_ind_validate(l_rec_term.due_day_num,l_rec_term.day_date_ind,"notNull","E") 
							WHEN 0 #correct 
	
							WHEN -1 # =null OR < 0 
								LET l_rec_term.due_day_num = l_old_day_num # must enter a value 
								NEXT FIELD due_day_num 
							WHEN -2 # =0 
								LET l_rec_term.due_day_num = 1 # DATE must be between 1 AND 31 
								NEXT FIELD due_day_num 
							WHEN -2 # >31 
								LET l_rec_term.due_day_num = 31 # DATE must be between 1 AND 31 
								NEXT FIELD due_day_num 
							OTHERWISE 
								NEXT FIELD due_day_num 
								ERROR "Invalid Value - Only 1-31 IS valid" 
						END CASE 
					END IF 
				END IF 
	
			BEFORE FIELD due_day_num 
				LET l_help_text = kandooword(l_rec_term.due_day_num,l_rec_term.day_date_ind) 
				MESSAGE l_help_text 
	
			AFTER FIELD due_day_num 
				IF db_term_due_day_num_validate(l_rec_term.due_day_num,"notNull","E") <> 0 THEN 
					CASE db_term_due_day_num_with_day_date_ind_validate(l_rec_term.due_day_num,l_rec_term.day_date_ind,"notNull","E") 
						WHEN -1 # =null OR < 0 
							LET l_rec_term.due_day_num = l_old_day_num # must enter a value 
							NEXT FIELD due_day_num 
						WHEN -2 # =0 
							LET l_rec_term.due_day_num = 1 # DATE must be between 1 AND 31 
							NEXT FIELD due_day_num 
						WHEN -2 # >31 
							LET l_rec_term.due_day_num = 31 # DATE must be between 1 AND 31 
							NEXT FIELD due_day_num 
						OTHERWISE 
							NEXT FIELD due_day_num 
							ERROR "Invalid Value - Only 1-31 IS valid" 
					END CASE 
				END IF 
	
			AFTER INPUT 
				UPDATE term 
				SET term.* = l_rec_term.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = l_rec_term.term_code 
	
				IF sqlca.sqlerrd[2] = 0 THEN 
					MESSAGE "Payment Term Update successful" 
				ELSE 
					ERROR "Payment term UPDATE failed! Error ", sqlca.sqlerrd[2] 
				END IF 
	
		END INPUT 
		# --------------------------------------------------------------------------------------------------------------------------------
	
	
	
		# DIALOG SCOPE EVENTS --------------------------------------------------------------------------------------------------------------------------------
		ON ACTION "ADD" #new RECORD 
			LET l_rec_edit_termdetl.days_num = 0 
			LET l_rec_edit_termdetl.disc_per = 0 
			LET l_rec_edit_termdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_edit_termdetl.term_code = l_rec_term.term_code 
	
			#---------------------------------------------
			INPUT l_rec_edit_termdetl.* WITHOUT DEFAULTS FROM sr_termdedit.* 
				AFTER FIELD edit_days_num 
					IF db_termdetl_days_num_validate(l_rec_edit_termdetl.*,"notNull","") THEN 
						NEXT FIELD edit_days_num 
					END IF 
	
				AFTER FIELD edit_disc_per 
					IF db_termdetl_disc_per_validate(l_rec_edit_termdetl.disc_per,"notNull","") THEN 
						NEXT FIELD edit_disc_per 
					END IF 
					IF db_termdetl_pk_exists(l_rec_edit_termdetl.term_code,l_rec_edit_termdetl.days_num) THEN #check IF RECORD pk already exists 
						NEXT FIELD edit_days_num 
					ELSE 
						EXIT INPUT 
					END IF 
	
			END INPUT 
			#---------------------------------------------
	
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				#NEW record
				IF NOT db_termdetl_pk_exists(l_rec_edit_termdetl.term_code,l_rec_edit_termdetl.days_num) THEN #check IF RECORD pk already exists 
					IF db_termdetl_insert(l_rec_edit_termdetl.*) = 0 THEN 
						CALL db_termdetl_get_arr_rec(l_rec_edit_termdetl.term_code) RETURNING l_arr_rec_termdetl 
					ELSE 
						ERROR "Could NOT create new record" 
					END IF 
				END IF 
			END IF 
			#HuHo not sure if we need this CANCEL.. data was already written...
			#		ON ACTION "CANCEL"
			#			LET int_flag = TRUE
			#			EXIT DIALOG
	
		ON ACTION "ACCEPT" 
			LET int_flag = false 
			EXIT DIALOG 
	
	
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	
		BEFORE DIALOG 
			CALL publish_toolbar("kandoo","AZ2","inp-arr-termdetl") 
			DISPLAY p_term_code TO term_code 

	END DIALOG 
	# END DIALOG --------------------------------------------------------------------------------------
	###################################################################################################


	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 

END FUNCTION 
#################################################################################
# END FUNCTION term_manage(p_term_code)
#################################################################################


#################################################################################
# FUNCTION term_delete(p_term_code)
#
#
#################################################################################
FUNCTION term_delete(p_term_code) 
	DEFINE p_term_code LIKE term.term_code 

	SELECT unique 1 FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = p_term_code 
	IF sqlca.sqlcode = 0 THEN 
		ERROR kandoomsg2("A",7023,p_term_code)	#7024 Payment term appears on vendor - No Deletion Permitted
		RETURN false 
	END IF 

	SELECT unique 1 FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = p_term_code 
	IF sqlca.sqlcode = 0 THEN 
		ERROR kandoomsg2("A",7024,p_term_code)	#7024 Payment term appears on customer - No Deletion Permitted
		RETURN false 
	END IF 

	SELECT unique 1 FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = p_term_code 
	AND paid_amt != total_amt 
	IF sqlca.sqlcode = 0 THEN 
		ERROR kandoomsg2("A",7025,p_term_code)	#7024 Payment term appears on invoicehead - No Deletion Permitted
		RETURN false 
	END IF 

	SELECT unique 1 FROM voucher 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = p_term_code 
	AND paid_amt != total_amt 

	IF sqlca.sqlcode = 0 THEN 
		ERROR kandoomsg2("A",7026,p_term_code) #7024 Payment term appears on voucher - No Deletion Permitted
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
#################################################################################
# END FUNCTION term_delete(p_term_code)
#################################################################################


#################################################################################
# FUNCTION show_payment_methods()
#
# #NOT sure whre this comes FROM hor how it works .. just look at l_idx.. constant 1 ?????
#################################################################################
FUNCTION show_payment_methods() 
	DEFINE l_ret_method_code LIKE term.day_date_ind 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW A624 with FORM "A624" 
	CALL windecoration_a("A624") 

	CLEAR FORM 
	LET l_idx = 11 #changed FROM 1 TO 11.. but this IS just a guess.. 1 can NOT be alright 
	MESSAGE kandoomsg2("A",1047,"") #1047 RETURN OR ESC on line TO SELECT
	CALL set_count(l_idx) 

	DISPLAY ARRAY glob_arr_rec_payment_menu TO sr_payment_method.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZ2","inp-arr-payment_menu") 

		BEFORE ROW 
			LET l_idx = DIALOG.getCurrentRow("sr_payment_method") -- arr_curr() 
			LET l_ret_method_code = glob_arr_rec_payment_menu[l_idx].option_num 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 
	# ---------------------------------------------------------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_method_code = NULL 
	END IF 

	CLOSE WINDOW A624 

	RETURN l_ret_method_code 
END FUNCTION 
#################################################################################
# END FUNCTION show_payment_methods()
#################################################################################


#################################################################################
# FUNCTION payment_methods()
#
#
#################################################################################
FUNCTION payment_methods() 
	DEFINE i SMALLINT 

	FOR i = 1 TO 11 
		CASE i 
			WHEN "1" ## cut off DATE 
				LET glob_arr_rec_payment_menu[i].option_num = "C" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","C") 
			WHEN "2" ## no. OF days TO pay 
				LET glob_arr_rec_payment_menu[i].option_num = "D" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","D") 
			WHEN "3" ## DATE OF NEXT month TO pay 
				LET glob_arr_rec_payment_menu[i].option_num = "T" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","T") 
			WHEN "4" ## working DATE OF NEXT month 
				LET glob_arr_rec_payment_menu[i].option_num = "W" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","W") 
			WHEN "5" ## due sunday 
				LET glob_arr_rec_payment_menu[i].option_num = "1" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","1") 
			WHEN "6" ## due monday 
				LET glob_arr_rec_payment_menu[i].option_num = "2" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","2") 
			WHEN "7" ## due tuesday 
				LET glob_arr_rec_payment_menu[i].option_num = "3" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","3") 
			WHEN "8" ## due wednesday 
				LET glob_arr_rec_payment_menu[i].option_num = "4" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","4") 
			WHEN "9" ## due thursday 
				LET glob_arr_rec_payment_menu[i].option_num = "5" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","5") 
			WHEN "10" ## due friday 
				LET glob_arr_rec_payment_menu[i].option_num = "6" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","6") 
			WHEN "11" ## due saturday 
				LET glob_arr_rec_payment_menu[i].option_num = "7" 
				LET glob_arr_rec_payment_menu[i].option_text= kandooword("term.day_date_ind","7") 
		END CASE 
	END FOR 

END FUNCTION 
#################################################################################
# END FUNCTION payment_methods()
#################################################################################


#################################################################################
# FUNCTION payment_desc(p_day_date_ind)
#
#
#################################################################################
FUNCTION payment_desc(p_day_date_ind) 
	DEFINE p_day_date_ind LIKE term.day_date_ind 
	DEFINE l_term_desc_text CHAR(40) 
	DEFINE l_len_num SMALLINT 
	DEFINE l_idx SMALLINT 

	IF p_day_date_ind IS NOT NULL THEN 
		LET l_term_desc_text = kandooword("term.day_date_ind",p_day_date_ind) 
		LET l_len_num = length(l_term_desc_text) 

		FOR l_idx = 1 TO (40-l_len_num) 
			LET l_term_desc_text = l_term_desc_text clipped, "." 
		END FOR 

		DISPLAY l_term_desc_text TO term_desc_text 

	END IF 

END FUNCTION 
#################################################################################
# END FUNCTION payment_desc(p_day_date_ind)
#################################################################################