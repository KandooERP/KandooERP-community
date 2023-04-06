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
############################################################
# COA Maintenance
#
# module GZ1 allows the user TO maintain a general ledger Chart of Accounts
#
############################################################


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULEL Scope Variables
############################################################
DEFINE modu_arr_rec_coa DYNAMIC ARRAY OF RECORD 
	acct_code LIKE coa.acct_code,
	desc_text LIKE coa.desc_text,
	type_ind LIKE coa.type_ind,
	is_nominalcode LIKE coa.is_nominalcode
END RECORD 
--	DEFINE modu_rec_glparms    RECORD LIKE glparms.*
DEFINE modu_rec_account RECORD LIKE account.* 
DEFINE modu_rec_groupinfo RECORD LIKE groupinfo.* 
DEFINE modu_rec_uom RECORD LIKE uom.* 

####################################################################
# MAIN
#
# COA Maintenance
# module GZ1 allows the user TO maintain a general ledger Chart of Accounts
####################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GZ1") 
	CALL ui_init(0) #initial ui init 


	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module #KD-2129

	CALL scan_coa_rows_tree()

	CLOSE WINDOW G122 
END MAIN 
####################################################################
# END MAIN
####################################################################


####################################################################
# FUNCTION build_coa_query()
#
#
####################################################################
FUNCTION build_coa_query() 
	DEFINE l_where_text CHAR(1024) 
	DEFINE l_query_text CHAR(1024) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
		acct_code, 
		desc_text, 
		type_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZ1","coaQuery") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	MESSAGE kandoomsg2("U",1002,"") #1002 Searching database; Please wait.
	LET l_query_text = 
		"SELECT * FROM coa ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ", l_where_text clipped, " ", 
		"ORDER BY acct_code" 
	PREPARE coaer FROM l_query_text 
	DECLARE coacurs CURSOR FOR coaer 

	RETURN true 
END FUNCTION 
####################################################################
# END FUNCTION build_coa_query()
####################################################################


####################################################################
# FUNCTION get_query_filter()
#
#
####################################################################
FUNCTION get_query_filter() 
	DEFINE l_where_text CHAR(1024) 
	DEFINE l_query_text CHAR(1024) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
		acct_code, 
		desc_text, 
		type_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZ1","coaQuery") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag THEN 
		LET int_flag = false 
		RETURN " 1=1 " 
	ELSE 
		RETURN l_where_text 
	END IF 

END FUNCTION 
####################################################################
# END FUNCTION get_query_filter()
####################################################################


####################################################################
# FUNCTION scan_coa_rows()
#
#
####################################################################
FUNCTION scan_coa_rows() 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_old_limit_amt LIKE fundsapproved.limit_amt 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_select DYNAMIC ARRAY OF LIKE coa.acct_code 
	DEFINE l_arr_idx SMALLINT 
	DEFINE l_msgstr STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_del_count SMALLINT 
	DEFINE l_arr_rec_coa DYNAMIC ARRAY OF RECORD 
		acct_code LIKE coa.acct_code,
		desc_text LIKE coa.desc_text,
		type_ind LIKE coa.type_ind,
		is_nominalcode LIKE coa.is_nominalcode
	END RECORD

	OPEN WINDOW G122 with FORM "G122" 
	CALL windecoration_g("G122") 

	CALL l_arr_rec_coa.clear() 
	CALL db_coa_get_arr_rec_short(null) RETURNING l_arr_rec_coa 

	#INPUT ARRAY l_arr_rec_coa WITHOUT DEFAULTS FROM sr_coa.* ATTRIBUTES(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_coa TO sr_coa.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZ1","coaList") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_coa.clear() 
			CALL db_coa_get_arr_rec_short(get_query_filter()) RETURNING l_arr_rec_coa 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","DOUBLECLICK") 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 

				IF l_arr_rec_coa[l_idx].acct_code IS NOT NULL THEN 
					CALL coa_edit(l_arr_rec_coa[l_idx].acct_code) 
					CALL l_arr_rec_coa.clear() 
					CALL db_coa_get_arr_rec_short(null) RETURNING l_arr_rec_coa 
				END IF 

			END IF 

{
		For now disable this part which is totally out of the law!!!!
		If you happen to see such source code please report to ericv@kandoo.org

		ON ACTION "DELETE" #on KEY (F2) 			##### What ???????????????? Anyone finds this piece and rejects Kandoo immediately!!!
			CALL l_arr_select.clear() 
			FOR l_arr_idx = 1 TO arr_count() 
				IF dialog.isRowSelected("sr_coa",l_arr_idx) THEN 
					IF check_account(l_arr_rec_coa[l_arr_idx].acct_code) THEN # !!! checking IF account can be removed !!! 
						CALL l_arr_select.append(l_arr_rec_coa[l_arr_idx].acct_code) 
					ELSE CONTINUE DISPLAY 
					END IF 
				END IF 
			END FOR 
			LET l_del_count = l_arr_select.getlength() 

			LET l_msgstr = "Are you sure you want TO delete ", trim(l_del_count)," accounts (COA) ?\nThis operation may have a serious impact on your ERP system\n and should only be done, if you are 100% sure !" 
			IF promptTF("Delete COA Accounts",l_msgStr,TRUE) THEN 
				WHENEVER ERROR stop 
				BEGIN WORK 
					FOR l_arr_idx = 1 TO l_arr_select.getlength() 
						# The sequence of tables from which data is removed must take into account the relationship between the Primary Keys and Foreign Keys.
						# First followed by tables with Foreign Key, then followed by tables with Primary Key.

						DELETE FROM accounthist 
						WHERE acct_code = l_arr_select[l_arr_idx] AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 

						DELETE FROM accountledger 
						WHERE acct_code = l_arr_select[l_arr_idx] AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 

						DELETE FROM account 
						WHERE acct_code = l_arr_select[l_arr_idx] AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 

						SELECT limit_amt INTO l_old_limit_amt FROM fundsapproved 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						acct_code = l_arr_select[l_arr_idx] 

						INSERT INTO fundaudit VALUES (glob_rec_kandoouser.cmpy_code, 
						l_arr_select[l_arr_idx], 
						l_old_limit_amt, 
						0, 
						today, 
						glob_rec_kandoouser.sign_on_code) 

						DELETE FROM fundsapproved 
						WHERE acct_code = l_arr_select[l_arr_idx] AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 

						DELETE FROM coa 
						WHERE acct_code = l_arr_select[l_arr_idx] AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 

					END FOR 
				COMMIT WORK 
				WHENEVER ERROR stop 
				CALL l_arr_rec_coa.clear() 
				CALL db_coa_get_arr_rec_short(null) RETURNING l_arr_rec_coa 

				IF l_del_count = 1 
				THEN LET l_msgstr = trim(l_del_count), " account out of ", trim(l_arr_select.getlength()), " was successfully removed.\n Press OK to refresh." 
				ELSE LET l_msgstr = trim(l_del_count), " accounts out of ", trim(l_arr_select.getlength()), " were successfully removed.\n Press OK to refresh." 
				END IF 
				CALL msgContinue("",l_msgStr) 
				--            MESSAGE l_msgStr
			END IF 
			CALL l_arr_select.clear() 
}

		ON ACTION "Approved Funds" 
			LET l_idx = arr_curr() 
			IF l_arr_rec_coa[l_idx].acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_fundsapproved.* FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_arr_rec_coa[l_idx].acct_code 
				
				LET l_update_flag = false 
				
				CALL edit_new_capitalaccountbudget(
					l_rec_fundsapproved.*, 
					l_arr_rec_coa[l_idx].acct_code, 
					l_arr_rec_coa[l_idx].desc_text, 
					l_arr_rec_coa[l_idx].type_ind) 
				RETURNING 
					l_rec_fundsapproved.*, 
					l_update_flag 
				
				IF l_update_flag = true THEN 
					IF promptTF("Save and exit.","Do you want to save data ?",TRUE)	THEN 

						WHENEVER ERROR stop
					 
						BEGIN WORK 
							CALL update_cab(l_rec_fundsapproved.*) 
						COMMIT WORK 
	
						WHENEVER ERROR stop 
						
						MESSAGE kandoomsg2("G",1083,"") #1083 F1 TO Add;  F2 TO Delete;  F10 Approved Funds; ENTER ...
					END IF 
				END IF 
				INITIALIZE l_rec_fundsapproved.* TO NULL 
			END IF 

		ON ACTION "NEW" 
			CALL coa_new(null) 
			CALL l_arr_rec_coa.clear() 
			CALL db_coa_get_arr_rec_short(null) RETURNING l_arr_rec_coa 

	END DISPLAY 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 	# scan_coa_rows() 
####################################################################
# END FUNCTION scan_coa_rows()
####################################################################


####################################################################
# FUNCTION scan_coa_rows_tree()
# This function displays the chart of account in tree form (coa's hierarchy)
#
####################################################################
FUNCTION scan_coa_rows_tree() 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_old_limit_amt LIKE fundsapproved.limit_amt 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_select DYNAMIC ARRAY OF LIKE coa.acct_code 
	DEFINE l_arr_idx SMALLINT 
	DEFINE l_msgstr STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_del_count SMALLINT 
	DEFINE p_display_mode CHAR(4)
	DEFINE l_arr_rec_coa_tree DYNAMIC ARRAY OF RECORD # t_rec_coa_for_tree
		description NCHAR(120),
		id LIKE coa.acct_code,
		parentid LIKE coa.parentid
	END RECORD

	OPEN WINDOW G122 with FORM "G122_tree"
	 
	CALL windecoration_g("G122") 

	CALL l_arr_rec_coa_tree.clear() 
	CALL db_coa_get_arr_tree () RETURNING l_arr_rec_coa_tree

	#INPUT ARRAY l_arr_rec_coa_tree WITHOUT DEFAULTS FROM sr_coa.* ATTRIBUTES(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_coa_tree TO sr_coa_tree.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZ1","coaList") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			--CALL l_arr_rec_coa_tree.clear() 
			--CALL db_coa_get_arr_tree() RETURNING l_arr_rec_coa_tree 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","DOUBLECLICK") 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 

				IF l_arr_rec_coa_tree[l_idx].id IS NOT NULL THEN 
					CALL coa_edit(l_arr_rec_coa_tree[l_idx].id) 
					# Read the array again (refresh)
					--CALL l_arr_rec_coa_tree.clear() 
					--CALL db_coa_get_arr_tree(null) RETURNING l_arr_rec_coa_tree 
				END IF 

			END IF 

		ON ACTION "Approved Funds" 
			LET l_idx = arr_curr() 

			IF l_arr_rec_coa_tree[l_idx].id IS NOT NULL THEN 
				SELECT * INTO l_rec_fundsapproved.* 
				FROM fundsapproved 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_arr_rec_coa_tree[l_idx].id 

				LET l_update_flag = false 
				{
				CALL edit_new_capitalaccountbudget(l_rec_fundsapproved.*, l_arr_rec_coa_tree[l_idx].id, 
				l_arr_rec_coa_tree[l_idx].desc_text, l_arr_rec_coa_tree[l_idx].type_ind) 
				RETURNING l_rec_fundsapproved.*, l_update_flag
} 
				IF l_update_flag = true THEN 
					IF promptTF("Save and exit.","Do you want to save data ?",TRUE) THEN 
					
						WHENEVER ERROR stop 
						
						BEGIN WORK 
							CALL update_cab(l_rec_fundsapproved.*) 
						COMMIT WORK 
						
						WHENEVER ERROR stop 
						
						MESSAGE kandoomsg2("G",1083,"") #1083 F1 TO Add;  F2 TO Delete;  F10 Approved Funds; ENTER ...
					END IF 
				END IF

				INITIALIZE l_rec_fundsapproved.* TO NULL 
			END IF 

		ON ACTION "NEW" 
			CALL coa_new(null) 
			CALL l_arr_rec_coa_tree.clear() 
			CALL db_coa_get_arr_tree() RETURNING l_arr_rec_coa_tree 

	END DISPLAY 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 	# scan_coa_rows_tree() 
####################################################################
# END FUNCTION scan_coa_rows_tree()
####################################################################


####################################################################
# FUNCTION check_account(p_account_code)
#
#
####################################################################
FUNCTION check_account(p_account_code) 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msgstr VARCHAR(255) 

	SELECT count(*) INTO cnt FROM accountledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_account_code 
	
	IF cnt > 0 THEN 
		ERROR kandoomsg2("G",9002,"") #9002 " Account has Activity, no delete/change allowed"
		LET l_msgstr = "Account ",p_account_code CLIPPED," has Activity; No delete/change allowed." 
		ERROR l_msgstr 
		RETURN false 
	END IF 

	DECLARE accntcurs CURSOR FOR 
	SELECT * FROM account 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_account_code 
	OPEN accntcurs 
	FETCH accntcurs INTO modu_rec_account.* 
	
	IF status <> NOTFOUND THEN 
		IF modu_rec_account.open_amt IS NULL THEN 
			LET modu_rec_account.open_amt = 0 
		END IF 
		IF modu_rec_account.debit_amt IS NULL THEN 
			LET modu_rec_account.debit_amt = 0 
		END IF 
		IF modu_rec_account.credit_amt IS NULL THEN 
			LET modu_rec_account.credit_amt = 0 
		END IF 
		IF modu_rec_account.bal_amt IS NULL THEN 
			LET modu_rec_account.bal_amt = 0 
		END IF 
		IF modu_rec_account.stats_qty IS NULL THEN 
			LET modu_rec_account.stats_qty = 0 
		END IF 
		IF modu_rec_account.budg1_amt IS NULL THEN 
			LET modu_rec_account.budg1_amt = 0 
		END IF 
		IF modu_rec_account.budg2_amt IS NULL THEN 
			LET modu_rec_account.budg2_amt = 0 
		END IF 
		IF modu_rec_account.budg3_amt IS NULL THEN 
			LET modu_rec_account.budg3_amt = 0 
		END IF 
		IF modu_rec_account.budg4_amt IS NULL THEN 
			LET modu_rec_account.budg4_amt = 0 
		END IF 
		IF modu_rec_account.budg5_amt IS NULL THEN 
			LET modu_rec_account.budg5_amt = 0 
		END IF 
		IF modu_rec_account.budg6_amt IS NULL THEN 
			LET modu_rec_account.budg6_amt = 0 
		END IF 
		IF modu_rec_account.ytd_pre_close_amt IS NULL THEN 
			LET modu_rec_account.ytd_pre_close_amt = 0 
		END IF 

		IF 
			modu_rec_account.open_amt <> 0 OR 
			modu_rec_account.debit_amt <> 0 OR 
			modu_rec_account.credit_amt <> 0 OR 
			modu_rec_account.bal_amt <> 0 OR 
			modu_rec_account.stats_qty <> 0 OR 
			modu_rec_account.budg1_amt <> 0 OR 
			modu_rec_account.budg2_amt <> 0 OR 
			modu_rec_account.budg3_amt <> 0 OR 
			modu_rec_account.budg4_amt <> 0 OR 
			modu_rec_account.budg5_amt <> 0 OR 
			modu_rec_account.budg6_amt <> 0 OR 
			modu_rec_account.ytd_pre_close_amt <> 0 THEN 

			ERROR kandoomsg2("G",9002,"")	#9002 Account has activity, no delete/change allowed.
			LET l_msgstr = "Account ",p_account_code CLIPPED," has Activity; No delete/change allowed." 
			ERROR l_msgstr 
			RETURN false 
		END IF 
	END IF 

	SELECT count(*) 
	INTO cnt 
	FROM fundsapproved 
	WHERE acct_code = p_account_code 
	AND	cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND limit_amt > 0
	 
	IF cnt > 0 THEN 
		ERROR kandoomsg2("U",9938,p_account_code) #modu_arr_rec_coa[l_idx].acct_code		#9938 Account cannot be deleted as capital budget amount IS > 0.
		LET l_msgstr = "Account ",p_account_code CLIPPED," cannot be deleted as Approved Funds limit is greater than 0." 
		ERROR l_msgstr 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
####################################################################
# FUNCTION check_account(p_account_code)
####################################################################


####################################################################
# FUNCTION coa_new(p_account_code)
#
# New GL-COA existing record
####################################################################
FUNCTION coa_new(p_account_code) 
	DEFINE p_account_code LIKE account.acct_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_a_structure RECORD LIKE structure.* 
	DEFINE l_return_coa LIKE account.acct_code 
	DEFINE l_winds_text CHAR(80) 
	DEFINE l_ender INTEGER 
	DEFINE l_start_pos INTEGER 
	DEFINE l_length_str INTEGER 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_tax_desc_text LIKE tax.desc_text 
	DEFINE l_parent_name LIKE coa.desc_text
	DEFINE l_status INTEGER
	DEFINE cnt INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_coa.* TO NULL 
	INITIALIZE l_rec_structure.* TO NULL 
	INITIALIZE l_rec_a_structure.* TO NULL 

	SELECT count(*) INTO cnt FROM structure 
	WHERE structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND structure.start_num <> 0 
	IF cnt = 0 THEN -- CHECK IF there IS data in the 'structure' TABLE 
		CALL msgError("","The Account Structure has not been entered.\nUse the GZ3 program to enter the Account Structure.\n Press OK to continue.") 
		RETURN 
	END IF 

	SELECT structure.* INTO l_rec_structure.* FROM structure 
	WHERE structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND structure.start_num = 0 

	IF status = NOTFOUND THEN 
		DECLARE coa_curs CURSOR FOR 
		SELECT * INTO l_rec_a_structure.* FROM structure 
		WHERE structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
		ORDER BY structure.start_num 

		LET l_rec_structure.default_text = " " 
		LET l_ender = 0 

		FOREACH coa_curs 
			LET l_start_pos = l_rec_a_structure.start_num 
			LET l_length_str = l_rec_a_structure.length_num 

			IF l_ender <> 0 THEN 
				LET l_rec_structure.default_text = 
					l_rec_structure.default_text[1,l_start_pos-1], 
					l_rec_a_structure.default_text[1,l_length_str] 
			ELSE 
				LET l_rec_structure.default_text = l_rec_a_structure.default_text[1,l_length_str] 

				IF l_rec_structure.default_text IS NULL THEN 
					LET l_rec_structure.default_text = " " 
				END IF 
			END IF 

			LET l_ender = l_ender + l_rec_a_structure.length_num 

		END FOREACH 

		LET l_rec_structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_structure.start_num = 0 
		LET l_rec_structure.length_num = l_ender 
		LET l_rec_structure.desc_text = "Default Code" 
		LET l_rec_structure.default_text = l_rec_structure.default_text 
		LET l_rec_structure.type_ind = "D" 

		INSERT INTO structure VALUES (l_rec_structure.*) 

	END IF 

	LET l_rec_coa.acct_code = l_rec_structure.default_text 

	OPEN WINDOW G146 with FORM "G146" 
	CALL windecoration_g("G146") --populate WINDOW FORM elements 

	MESSAGE kandoomsg2("G",1084,"")	#1084 Enter Account Details;  F10 Approved Funds;  OK TO Continue.
	DISPLAY BY NAME l_rec_coa.acct_code thru l_rec_coa.tax_code 

	#Convert comboBox to TextField via dynamic morphing function
	CALL Convert_ComboBox_To_TextField("acct_code")

	INPUT BY NAME 
		l_rec_coa.acct_code, 
		l_rec_coa.desc_text,
		l_rec_coa.is_nominalcode,
		l_rec_coa.parentid, 
		l_rec_coa.type_ind, 
		l_rec_coa.start_year_num, 
		l_rec_coa.start_period_num, 
		l_rec_coa.end_year_num, 
		l_rec_coa.end_period_num, 
		l_rec_coa.group_code, 
		l_rec_coa.analy_req_flag, 
		l_rec_coa.analy_prompt_text, 
		l_rec_coa.qty_flag, 
		l_rec_coa.uom_code, 
		l_rec_coa.tax_code WITHOUT DEFAULTS attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ1","coaEdit") 

			LET l_rec_coa.qty_flag = "N" 
			LET l_rec_coa.analy_req_flag = "N" 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(group_code) 
			LET l_winds_text = show_groupinfo(glob_rec_kandoouser.cmpy_code) 
			
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.group_code = l_winds_text 
				
				DISPLAY BY NAME l_rec_coa.group_code 

				SELECT desc_text INTO modu_rec_groupinfo.desc_text 
				FROM groupinfo 
				WHERE group_code = l_rec_coa.group_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				CALL g552_display_groupinfo_desc_text(modu_rec_groupinfo.desc_text) 

			END IF 
			
			NEXT FIELD group_code 

		ON ACTION "LOOKUP" infield (uom_code) 
			LET l_winds_text = show_uom(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.uom_code = l_winds_text 
				
				DISPLAY BY NAME l_rec_coa.uom_code 

				SELECT desc_text INTO modu_rec_uom.desc_text FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = l_rec_coa.uom_code 
				CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 

			END IF 
			NEXT FIELD uom_code 

		ON ACTION "LOOKUP" infield(tax_code) 
			LET l_winds_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.tax_code = l_winds_text 
				SELECT desc_text INTO l_tax_desc_text FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_coa.tax_code 
				IF status = NOTFOUND THEN 
					LET l_tax_desc_text = "" 
				END IF 
				
				CALL g552_display_tax_desc_text(l_tax_desc_text) 

			END IF 
			NEXT FIELD tax_code 

		ON ACTION "Approved Funds" 
			IF l_rec_coa.acct_code != l_rec_structure.default_text THEN 
				LET l_update_flag = false 
				CALL edit_new_capitalaccountbudget(
					l_rec_fundsapproved.*, 
					l_rec_coa.acct_code, 
					l_rec_coa.desc_text, 
					l_rec_coa.type_ind) 
				RETURNING 
					l_rec_fundsapproved.*, 
					l_update_flag 
			END IF 

		AFTER FIELD acct_code 
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("G",9032,"") #9032 " Account Code must NOT be entered"
				NEXT FIELD acct_code 
			END IF 
			
			LET l_return_coa = add_acct_code(glob_rec_kandoouser.cmpy_code, l_rec_coa.acct_code) 
			
			IF l_return_coa != "zzzzzzzzzzzzzzzzzz" THEN #huho 17.06.2019 ???? what IS this ? ooohh nooooo... seems TO be the data IF the coa RECORD already exists 
				LET l_rec_coa.acct_code = l_return_coa 
				DISPLAY l_rec_coa.acct_code TO acct_code 
				NEXT FIELD desc_text 
			ELSE 
				NEXT FIELD acct_code 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_coa.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9101,"") #9101 " Description must be entered  "
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD parentid
			IF l_rec_coa.parentid IS NULL THEN
				# Suggest a parent id : remove all trailing zeroes and remove the last char on the right
				LET l_rec_coa.parentid =  l_rec_coa.acct_code 
				LET l_rec_coa.parentid = util.REGEX.replace(l_rec_coa.parentid,/0+$/,"")
				LET l_rec_coa.parentid = util.REGEX.replace(l_rec_coa.parentid,/.$/,"") 
			END IF
			
		AFTER FIELD parentid
			IF l_rec_coa.parentid IS NULL THEN
				ERROR "Are you sure this account has no parent"
			ELSE	
				CALL coa_get_account_name(l_rec_coa.parentid) RETURNING l_status,l_parent_name
				IF l_status = NOTFOUND THEN
					ERROR "Parent ID not found, please input again"
					NEXT FIELD parentid
				ELSE
					DISPLAY l_parent_name TO parent_name
				END IF
			END IF

		AFTER FIELD type_ind 
			IF l_rec_coa.type_ind NOT matches "[ALIEN]" OR l_rec_coa.type_ind IS NULL THEN 
				ERROR kandoomsg2("G",9003,"") 			#9003 " Type Indicator must be A,L,I,E,N "
				NEXT FIELD type_ind 
			END IF 

		AFTER FIELD start_year_num 
			IF l_rec_coa.start_year_num < 1988 THEN 
				ERROR kandoomsg2("G",9102,"") 			#9102 " Must AT least be 1988"
				NEXT FIELD start_year_num 
			END IF 

		AFTER FIELD start_period_num 
			IF l_rec_coa.start_period_num <= 0 THEN 
				ERROR kandoomsg2("G",9025,"Period") 			#9025 " Periods must be > 0 "
				NEXT FIELD start_period_num 
			END IF 

		AFTER FIELD end_year_num 
			IF l_rec_coa.end_year_num < l_rec_coa.start_year_num THEN 
				ERROR kandoomsg2("G",9093,"") 			#9093 " Must AT least be = TO starting year number "
				NEXT FIELD end_year_num 
			END IF 

		AFTER FIELD end_period_num 
			IF l_rec_coa.end_period_num <= 0 THEN 
				ERROR kandoomsg2("G",9025,"Period") 		#9025 " Periods must be > 0 "
				NEXT FIELD end_period_num 
			END IF 
			IF l_rec_coa.end_year_num = l_rec_coa.start_year_num 
			AND l_rec_coa.end_period_num < l_rec_coa.start_period_num THEN 
				ERROR kandoomsg2("W",9117,"") 			#9117 " Start Date must be earlier than END Date."
				NEXT FIELD start_year_num 
			END IF 

		AFTER FIELD group_code 
			IF l_rec_coa.group_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_groupinfo.* FROM groupinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = l_rec_coa.group_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9226,"") 				#9226 " RECORD NOT found "
					NEXT FIELD group_code 
				ELSE 
					CALL g552_display_groupinfo_desc_text(modu_rec_groupinfo.desc_text) 
				END IF 
			ELSE 
				CLEAR groupinfo.desc_text 
			END IF 

		AFTER FIELD analy_req_flag 
			IF l_rec_coa.analy_req_flag NOT matches "[YN]" OR l_rec_coa.analy_req_flag IS NULL THEN 
				ERROR kandoomsg2("E",9175,"") 			#9175 " Response must be Y OR N"
				NEXT FIELD analy_req_flag 
			END IF 

		AFTER FIELD qty_flag 
			IF l_rec_coa.qty_flag NOT matches "[YN]" OR l_rec_coa.qty_flag IS NULL THEN 
				ERROR kandoomsg2("E",9175,"") 			#9175 " Response must be Y OR N"
				NEXT FIELD qty_flag 
			ELSE
				IF l_rec_coa.qty_flag = "N" THEN 
					IF l_rec_coa.uom_code IS NOT NULL THEN 
						LET l_rec_coa.uom_code = NULL 
						LET modu_rec_uom.desc_text = NULL 
				
						DISPLAY l_rec_coa.uom_code TO coa.uom_code 
				
						CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
				
					END IF 
				END IF 
			END IF 
			{
			      BEFORE FIELD uom_code
			         IF l_rec_coa.qty_flag = "N"
			         THEN CALL DIALOG.SetFieldActive("coa.uom_code", FALSE)
			         ELSE CALL DIALOG.SetFieldActive("coa.uom_code", TRUE)
			         END IF
			}
		AFTER FIELD uom_code 
			IF l_rec_coa.qty_flag = "Y" THEN 
				IF l_rec_coa.uom_code IS NOT NULL THEN 
					SELECT desc_text 
					INTO modu_rec_uom.desc_text 
					FROM uom 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND uom_code = l_rec_coa.uom_code 
					IF status = NOTFOUND THEN 
						CALL g552_display_uom_desc_text(null) 
						ERROR kandoomsg2("U",9111,"Unit of Measure") #9111 " The Unit of Measure does NOT exist "
						NEXT FIELD uom_code 
					ELSE 
						CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
					END IF 
				ELSE 
					ERROR "Value must be entered" 
					NEXT FIELD uom_code 
				END IF 

			ELSE 

				IF l_rec_coa.uom_code IS NOT NULL THEN 
					LET l_rec_coa.uom_code = NULL 
					LET modu_rec_uom.desc_text = NULL 
					
					DISPLAY l_rec_coa.uom_code TO coa.uom_code 
					
					CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
				END IF 
			END IF 

		AFTER FIELD tax_code 
			IF l_rec_coa.tax_code IS NOT NULL THEN 
				SELECT desc_text INTO l_tax_desc_text FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_coa.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9130,"") #9130 Tax code does NOT exist; Try Window.
					NEXT FIELD tax_code 
				END IF 
				
				CALL g552_display_tax_desc_text(l_tax_desc_text) 

				IF NOT valid_tax_usage(glob_rec_kandoouser.cmpy_code, l_rec_coa.tax_code, "6", "Y") THEN 
					NEXT FIELD tax_code 
				END IF 
			ELSE 
				CLEAR tax.desc_text 
			END IF 

		AFTER INPUT 
			IF get_debug() = true THEN 
				DISPLAY "int_flag=",int_flag 
				DISPLAY "quit_flag=",quit_flag 
				DISPLAY "field_touched(coa.*)",field_touched(coa.*) 
			END IF 

			IF int_flag = 1 OR quit_flag = 1 THEN # "Cancel" ACTION activated 
				IF field_touched(coa.*) <> 0 OR l_update_flag = true 
				THEN #check, IF anything has changed... 
					IF promptTF("Exit ?","Do you want to exit ?\nAll changes will be lost !",TRUE) THEN 
						EXIT INPUT 
					ELSE
						LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				
				ELSE 
					EXIT INPUT 
				END IF
				 
			ELSE # "Apply" ACTION activated 
				IF field_touched(coa.*) <> 0 OR l_update_flag = true THEN #check, IF anything has changed... 
					IF promptTF("Save and exit.","Do you want to save data ?",TRUE) THEN 
						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = l_rec_coa.acct_code 
						IF status != NOTFOUND THEN #check, IF RECORD with this acct_code already exists 
							ERROR kandoomsg2("U",9104,"") 			#9104 " RECORD already exists "
							NEXT FIELD acct_code 
						END IF 

						IF l_rec_coa.desc_text IS NULL THEN 
							ERROR kandoomsg2("A",9101,"") 			#9101 " Description must be entered  "
							NEXT FIELD desc_text 
						END IF 

						IF l_rec_coa.type_ind NOT matches "[ALIEN]" OR l_rec_coa.type_ind IS NULL THEN 
							ERROR kandoomsg2("G",9003,"") 			#9003 " Type Indicator must be A,L,I,E,N "
							NEXT FIELD type_ind 
						END IF 

						IF l_rec_coa.start_year_num < 1988 OR l_rec_coa.start_year_num IS NULL THEN 
							ERROR kandoomsg2("G",9102,"") 			#9102 " Must AT least be 1988"
							NEXT FIELD start_year_num 
						END IF 

						IF l_rec_coa.start_period_num <= 0 OR l_rec_coa.start_period_num IS NULL THEN 
							ERROR kandoomsg2("G",9025,"Period") #9025 " Periods must be > 0 "
							NEXT FIELD start_period_num 
						END IF 

						IF l_rec_coa.end_year_num < 1988 OR l_rec_coa.end_year_num IS NULL THEN 
							ERROR kandoomsg2("G",9102,"") 		#9102 " Must AT least be 1988"
							NEXT FIELD end_year_num 
						END IF 

						IF l_rec_coa.end_period_num <= 0 OR l_rec_coa.end_period_num IS NULL THEN 
							ERROR kandoomsg2("G",9025,"Period") 		#9025 " Periods must be > 0 "
							NEXT FIELD end_period_num 
						END IF 

						IF l_rec_coa.end_year_num < l_rec_coa.start_year_num THEN 
							ERROR kandoomsg2("G",9093,"") 			#9093 " Must AT least be = TO starting year number "
							NEXT FIELD end_year_num 
						END IF 

						IF l_rec_coa.end_year_num = l_rec_coa.start_year_num AND l_rec_coa.end_period_num < l_rec_coa.start_period_num THEN 
							ERROR kandoomsg2("W",9117,"") 		#9117 " Start Date must be earlier than END Date."
							NEXT FIELD start_year_num 
						END IF 

						IF l_rec_coa.analy_req_flag NOT matches "[YN]" OR l_rec_coa.analy_req_flag IS NULL THEN 
							ERROR kandoomsg2("E",9175,"") #9175 " Response must be Y OR N"
							NEXT FIELD analy_req_flag 
						END IF 

						IF l_rec_coa.qty_flag NOT matches "[YN]" OR l_rec_coa.qty_flag IS NULL THEN 
							ERROR kandoomsg2("E",9175,"") 	#9175 " Response must be Y OR N"
							NEXT FIELD qty_flag 
						END IF 

						IF l_rec_coa.qty_flag = "Y" THEN 
							IF l_rec_coa.uom_code IS NOT NULL THEN 
								SELECT desc_text INTO modu_rec_uom.desc_text FROM uom 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND uom_code = l_rec_coa.uom_code 
								IF status = NOTFOUND THEN 
									ERROR kandoomsg2("U",9111,"Unit of Measure") 		#9111 " The Unit of Measure does NOT exist "
									NEXT FIELD uom_code 
								END IF 

								CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
							ELSE 
								ERROR "Value must be entered" 
								NEXT FIELD uom_code 
							END IF 
						
						ELSE 
							# Null out the UOM code as the programs that use this
							# field assume the code either has a UOM code
							# OR IS NULL (depending obviously on the quantity flag).
							IF l_rec_coa.uom_code IS NOT NULL THEN 
								LET l_rec_coa.uom_code = NULL 
								LET modu_rec_uom.desc_text = NULL 
						
								DISPLAY l_rec_coa.uom_code TO coa.uom_code 
								CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
							END IF 
						END IF 

						IF l_rec_coa.tax_code IS NOT NULL THEN 
							IF NOT valid_tax_usage(glob_rec_kandoouser.cmpy_code, l_rec_coa.tax_code, "6", "Y") THEN 
								NEXT FIELD tax_code 
							END IF 
						END IF 

						LET l_rec_coa.cmpy_code = glob_rec_kandoouser.cmpy_code 

						ERROR kandoomsg2("U",1005,"") 	#1005 Updating database; Please wait.
						
						WHENEVER ERROR stop 
						
						BEGIN WORK 
							INSERT INTO coa VALUES (l_rec_coa.*) 
							
							IF l_update_flag = true THEN 
								CALL update_cab(l_rec_fundsapproved.*) 
							END IF 
						
						COMMIT WORK 
						
						WHENEVER ERROR stop 
						
						-- CALL msgContinue("","Data has been saved.\n Press OK to continue.")
						EXIT INPUT 
					
					ELSE
					 
						LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				
				ELSE 
					EXIT INPUT 
				END IF
				 
			END IF 

	END INPUT 

	CLOSE WINDOW G146 

	RETURN true 
END FUNCTION 
####################################################################
# END FUNCTION coa_new(p_account_code)
####################################################################


####################################################################
# FUNCTION coa_edit(p_account_code)
#
#
####################################################################
FUNCTION coa_edit(p_account_code) 
	DEFINE p_account_code LIKE account.acct_code 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_old_limit_amt LIKE fundaudit.old_limit_amt 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_tax_desc_text LIKE tax.desc_text 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_status INTEGER 
	DEFINE l_parent_name LIKE coa.desc_text

	IF p_account_code IS NULL THEN 
		RETURN 
	ELSE 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = p_account_code 
		IF status = NOTFOUND THEN 
			ERROR kandoomsg2("I",9226,"") #9226 " RECORD NOT found "
			RETURN 
		END IF 
	END IF 

	OPEN WINDOW G146 with FORM "G146" 
	CALL windecoration_g("G146") --populate WINDOW FORM elements 

	MESSAGE kandoomsg2("G",1084,"") #1084 Enter Account Details;  F10 Approved Funds;  OK TO Continue.
	# IF this acct_code is a nominal account, we should attached accounts
	IF l_rec_coa.is_nominalcode = true THEN
		IF l_rec_coa.uom_code IS NOT NULL THEN 
			SELECT desc_text INTO modu_rec_uom.desc_text 
			FROM uom 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND uom_code = l_rec_coa.uom_code 
			IF not(status = NOTFOUND) THEN 
				CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
			END IF 
		END IF 

		IF l_rec_coa.group_code IS NOT NULL THEN 
			SELECT desc_text INTO modu_rec_groupinfo.desc_text 
			FROM groupinfo 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND group_code = l_rec_coa.group_code 
			IF not(status = NOTFOUND) THEN 
				CALL g552_display_groupinfo_desc_text(modu_rec_groupinfo.desc_text) 
			END IF 
		END IF 
		CALL coa_get_account_name(l_rec_coa.parentid) RETURNING l_status,l_parent_name
		IF l_rec_coa.tax_code IS NOT NULL THEN 
			SELECT desc_text INTO l_tax_desc_text 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = l_rec_coa.tax_code 
			IF status != NOTFOUND THEN 
				CALL g552_display_tax_desc_text(l_tax_desc_text) 
			END IF 
		END IF 
	END IF

	# TODO: sometimes acct_code display is wrong
	DISPLAY BY NAME l_rec_coa.acct_code,
		l_rec_coa.desc_text, 
		l_rec_coa.is_nominalcode,
		l_rec_coa.parentid,
		l_rec_coa.type_ind, 
		l_rec_coa.start_year_num, 
		l_rec_coa.start_period_num, 
		l_rec_coa.end_year_num, 
		l_rec_coa.end_period_num, 
		l_rec_coa.group_code, 
		l_rec_coa.analy_req_flag, 
		l_rec_coa.analy_prompt_text, 
		l_rec_coa.qty_flag, 
		l_rec_coa.uom_code, 
		l_rec_coa.tax_code
	 DISPLAY l_parent_name TO parent_name

	INPUT BY NAME 
		l_rec_coa.desc_text, 
		l_rec_coa.is_nominalcode,
		l_rec_coa.parentid,
		l_rec_coa.type_ind, 
		l_rec_coa.start_year_num, 
		l_rec_coa.start_period_num, 
		l_rec_coa.end_year_num, 
		l_rec_coa.end_period_num, 
		l_rec_coa.group_code, 
		l_rec_coa.analy_req_flag, 
		l_rec_coa.analy_prompt_text, 
		l_rec_coa.qty_flag, 
		l_rec_coa.uom_code, 
		l_rec_coa.tax_code WITHOUT DEFAULTS attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ1","coa4") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(group_code) 
			LET l_winds_text = show_groupinfo(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.group_code = l_winds_text 
				DISPLAY BY NAME l_rec_coa.group_code 

				SELECT desc_text INTO modu_rec_groupinfo.desc_text 
				FROM groupinfo 
				WHERE group_code = l_rec_coa.group_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL g552_display_groupinfo_desc_text(modu_rec_groupinfo.desc_text) 

			END IF 
			NEXT FIELD group_code 

		ON ACTION "LOOKUP" infield (uom_code) 
			LET l_winds_text = show_uom(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.uom_code = l_winds_text 
				DISPLAY BY NAME l_rec_coa.uom_code 

				SELECT desc_text INTO modu_rec_uom.desc_text FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = l_rec_coa.uom_code 
				CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 

			END IF 
			NEXT FIELD uom_code 

		ON ACTION "LOOKUP" infield(tax_code) 
			LET l_winds_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_coa.tax_code = l_winds_text 
				SELECT desc_text INTO l_tax_desc_text FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_coa.tax_code 
				IF status = NOTFOUND THEN 
					LET l_tax_desc_text = "" 
				END IF 

				CALL g552_display_tax_desc_text(l_tax_desc_text) 

			END IF 
			NEXT FIELD tax_code 

		ON ACTION "Approved Funds" 
			SELECT * INTO l_rec_fundsapproved.* 
			FROM fundsapproved 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_account_code 
			LET l_update_flag = false 

			CALL edit_new_capitalaccountbudget(
				l_rec_fundsapproved.*, 
				l_rec_coa.acct_code, 
				l_rec_coa.desc_text, 
				l_rec_coa.type_ind) 
			RETURNING 
				l_rec_fundsapproved.*, 
				l_update_flag 

		AFTER FIELD desc_text 
			IF l_rec_coa.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9101,"")	#9101 " Description must be entered  "
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD parentid
			IF l_rec_coa.parentid IS NULL THEN
				# Suggest a parent id : remove all trailing zeroes and remove one figure
				LET l_rec_coa.parentid =  l_rec_coa.acct_code 
				LET l_rec_coa.parentid = util.REGEX.replace(l_rec_coa.parentid,/0+$/,"")
				LET l_rec_coa.parentid = util.REGEX.replace(l_rec_coa.parentid,/.$/,"") 
			END IF

		ON CHANGE parentid
			CALL coa_get_account_name(l_rec_coa.parentid) RETURNING l_status,l_parent_name
			IF l_status = NOTFOUND THEN
				ERROR "Parent ID not found, please input again"
				NEXT FIELD parentid
			ELSE
				DISPLAY l_parent_name TO parent_name
			END IF
			
		AFTER FIELD type_ind 
			IF l_rec_coa.type_ind NOT matches "[ALIEN]" OR l_rec_coa.type_ind IS NULL THEN 
				ERROR kandoomsg2("G",9003,"") #9003 " Type Indicator must be A,L,I,E,N "
				NEXT FIELD type_ind 
			END IF 

		AFTER FIELD start_year_num 
			IF l_rec_coa.start_year_num < 1988 THEN 
				ERROR kandoomsg2("G",9102,"") #9102 " Must AT least be 1988"
				NEXT FIELD start_year_num 
			END IF 

		AFTER FIELD start_period_num 
			IF l_rec_coa.start_period_num <= 0 THEN 
				ERROR kandoomsg2("G",9025,"Period") 	#9025 " Periods must be > 0 "
				NEXT FIELD start_period_num 
			END IF 

		AFTER FIELD end_year_num 
			IF l_rec_coa.end_year_num < l_rec_coa.start_year_num THEN 
				ERROR kandoomsg2("G",9093,"") #9093 " Must AT least be = TO starting year number "
				NEXT FIELD end_year_num 
			END IF 

		AFTER FIELD end_period_num 
			IF l_rec_coa.end_period_num <= 0 THEN 
				ERROR kandoomsg2("G",9025,"Period") #9025 " Periods must be > 0 "
				NEXT FIELD end_period_num 
			END IF 
			IF l_rec_coa.end_year_num = l_rec_coa.start_year_num 
			AND l_rec_coa.end_period_num < l_rec_coa.start_period_num THEN 
				ERROR kandoomsg2("W",9117,"") #9117 " Start Date must be earlier than END Date."
				NEXT FIELD start_year_num 
			END IF 

		AFTER FIELD group_code 
			IF l_rec_coa.group_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_groupinfo.* FROM groupinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = l_rec_coa.group_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("I",9226,"") #9226 " RECORD NOT found "
					NEXT FIELD group_code 
				ELSE 
					CALL g552_display_groupinfo_desc_text(modu_rec_groupinfo.desc_text) 
				END IF 
			ELSE 
				CLEAR groupinfo.desc_text 
			END IF 

		AFTER FIELD analy_req_flag 
			IF l_rec_coa.analy_req_flag NOT matches "[YN]" OR l_rec_coa.analy_req_flag IS NULL THEN 
				ERROR kandoomsg2("E",9175,"") #9175 " Response must be Y OR N"
				NEXT FIELD analy_req_flag 
			END IF 

		AFTER FIELD qty_flag 
			IF l_rec_coa.qty_flag NOT matches "[YN]" OR l_rec_coa.qty_flag IS NULL THEN 
				ERROR kandoomsg2("E",9175,"") #9175 " Response must be Y OR N"
				NEXT FIELD qty_flag 
			ELSE 
				IF l_rec_coa.qty_flag = "N" THEN 
					IF l_rec_coa.uom_code IS NOT NULL THEN 
						LET l_rec_coa.uom_code = NULL 
						LET modu_rec_uom.desc_text = NULL
						 
						DISPLAY l_rec_coa.uom_code TO coa.uom_code
						 
						CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
					END IF 
				END IF 
			END IF 
			{
			      BEFORE FIELD uom_code
			         IF l_rec_coa.qty_flag = "N"
			         THEN CALL DIALOG.SetFieldActive("coa.uom_code", FALSE)
			         ELSE CALL DIALOG.SetFieldActive("coa.uom_code", TRUE)
			         END IF
			}
		AFTER FIELD uom_code 
			IF l_rec_coa.qty_flag = "Y" THEN 
				IF l_rec_coa.uom_code IS NOT NULL THEN 
					SELECT desc_text INTO modu_rec_uom.desc_text FROM uom 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND uom_code = l_rec_coa.uom_code 

					IF status = NOTFOUND THEN 
						CALL g552_display_uom_desc_text(null) 
						ERROR kandoomsg2("U",9111,"Unit of Measure") 	#9111 " The Unit of Measure does NOT exist "
						NEXT FIELD uom_code 

					ELSE 
						CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
					END IF 

				ELSE 
					ERROR "Value must be entered" 
					NEXT FIELD uom_code 
				END IF 
			ELSE 
				IF l_rec_coa.uom_code IS NOT NULL THEN 
					LET l_rec_coa.uom_code = NULL 
					LET modu_rec_uom.desc_text = NULL 
					
					DISPLAY l_rec_coa.uom_code TO coa.uom_code 
					CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
				END IF 
			END IF 

		AFTER FIELD tax_code 
			IF l_rec_coa.tax_code IS NOT NULL THEN 
				SELECT desc_text INTO l_tax_desc_text FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_coa.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9130,"") #9130 Tax code does NOT exist; Try Window.
					NEXT FIELD tax_code 
				END IF 
				
				CALL g552_display_tax_desc_text(l_tax_desc_text) 

				IF NOT valid_tax_usage(glob_rec_kandoouser.cmpy_code, l_rec_coa.tax_code, "6", "Y") THEN 
					NEXT FIELD tax_code 
				END IF 
			ELSE 
				CLEAR tax.desc_text 
			END IF 

		AFTER INPUT 
			IF get_debug() = true THEN 
				DISPLAY "int_flag=",int_flag 
				DISPLAY "quit_flag=",quit_flag 
				DISPLAY "field_touched(coa.*)",field_touched(coa.*) 
			END IF 

			IF int_flag = 1 OR quit_flag = 1 
			THEN # "Cancel" ACTION activated 
				IF field_touched(coa.*) <> 0 OR l_update_flag = true 
				THEN #check, IF anything has changed... 
					IF promptTF("Exit ?","Do you want to exit ?\nAll changes will be lost !",TRUE) 
					THEN EXIT INPUT 
					ELSE LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				ELSE 
					EXIT INPUT 
				END IF 
			
			ELSE # "Apply" ACTION activated 

				IF field_touched(coa.*) <> 0 OR l_update_flag = true THEN #check, IF anything has changed... 
					IF promptTF("Save and exit.","Do you want to save data ?",TRUE) THEN
						IF l_rec_coa.desc_text IS NULL THEN 
							ERROR kandoomsg2("A",9101,"") #9101 " Description must be entered  "
							NEXT FIELD desc_text 
						END IF 

						IF l_rec_coa.type_ind NOT matches "[ALIEN]" OR l_rec_coa.type_ind IS NULL THEN 
							ERROR kandoomsg2("G",9003,"") #9003 " Type Indicator must be A,L,I,E,N "
							NEXT FIELD type_ind 
						END IF 
	
						IF l_rec_coa.start_year_num < 1988 OR l_rec_coa.start_year_num IS NULL THEN 
							ERROR kandoomsg2("G",9102,"") #9102 " Must AT least be 1988"
							NEXT FIELD start_year_num 
						END IF 
	
						IF l_rec_coa.start_period_num <= 0 OR l_rec_coa.start_period_num IS NULL THEN 
							ERROR kandoomsg2("G",9025,"Period") #9025 " Periods must be > 0 "
							NEXT FIELD start_period_num 
						END IF 
	
						IF l_rec_coa.end_year_num < 1988 OR l_rec_coa.end_year_num IS NULL THEN 
							ERROR kandoomsg2("G",9102,"") #9102 " Must AT least be 1988"
							NEXT FIELD end_year_num 
						END IF 
	
						IF l_rec_coa.end_period_num <= 0 OR l_rec_coa.end_period_num IS NULL THEN 
							ERROR kandoomsg2("G",9025,"Period") #9025 " Periods must be > 0 "
							NEXT FIELD end_period_num 
						END IF 
	
						IF l_rec_coa.end_year_num < l_rec_coa.start_year_num THEN 
							ERROR kandoomsg2("G",9093,"") #9093 " Must AT least be = TO starting year number "
							NEXT FIELD end_year_num 
						END IF 
	
						IF l_rec_coa.end_year_num = l_rec_coa.start_year_num AND l_rec_coa.end_period_num < l_rec_coa.start_period_num THEN 
							ERROR kandoomsg2("W",9117,"") #9117 " Start Date must be earlier than END Date."
							NEXT FIELD start_year_num 
						END IF 
	
						IF l_rec_coa.analy_req_flag NOT matches "[YN]" OR l_rec_coa.analy_req_flag IS NULL THEN 
							ERROR kandoomsg2("E",9175,"") #9175 " Response must be Y OR N"
							NEXT FIELD analy_req_flag 
						END IF 
	
						IF l_rec_coa.qty_flag NOT matches "[YN]" OR l_rec_coa.qty_flag IS NULL THEN 
							ERROR kandoomsg2("E",9175,"") #9175 " Response must be Y OR N"
							NEXT FIELD qty_flag 
						END IF 
	
						IF l_rec_coa.qty_flag = "Y" THEN 
							IF l_rec_coa.uom_code IS NOT NULL THEN 
								SELECT desc_text INTO modu_rec_uom.desc_text FROM uom 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND uom_code = l_rec_coa.uom_code 
								IF status = NOTFOUND THEN 
									ERROR kandoomsg2("U",9111,"Unit of Measure") #9111 " The Unit of Measure does NOT exist "
									NEXT FIELD uom_code 
								END IF 
								
								CALL g552_display_uom_desc_text(modu_rec_uom.desc_text)
								 
							ELSE 
								ERROR "Value must be entered" 
								NEXT FIELD uom_code 
							END IF
							 
						ELSE
						 
							# Null out the UOM code as the programs that use this
							# field assume the code either has a UOM code
							# OR IS NULL (depending obviously on the quantity flag).
							IF l_rec_coa.uom_code IS NOT NULL THEN 
								LET l_rec_coa.uom_code = NULL 
								LET modu_rec_uom.desc_text = NULL 
								
								DISPLAY l_rec_coa.uom_code TO coa.uom_code 
								
								CALL g552_display_uom_desc_text(modu_rec_uom.desc_text) 
							END IF 
						END IF 
	
						IF l_rec_coa.tax_code IS NOT NULL THEN 
							IF NOT valid_tax_usage(glob_rec_kandoouser.cmpy_code, l_rec_coa.tax_code, "6", "Y") THEN 
								NEXT FIELD tax_code 
							END IF 
						END IF 
	
						ERROR kandoomsg2("U",1005,"") 	#1005 Updating database; Please wait.
						
						WHENEVER ERROR CONTINUE 
						
						BEGIN WORK 
						
							UPDATE coa SET coa.* = l_rec_coa.* 
							WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND coa.acct_code = l_rec_coa.acct_code 
							
							IF l_update_flag = true THEN 
								CALL update_cab(l_rec_fundsapproved.*) 
							END IF 
						
						COMMIT WORK 
						
						WHENEVER ERROR CALL kandoo_sql_errors_handler 
						
						--                        CALL msgContinue("","Data has been saved.\n Press OK to continue.")
						EXIT INPUT
						 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				
				ELSE 
					EXIT INPUT 
				END IF 
		END IF 

	END INPUT 

	LET quit_flag = false 
	LET int_flag = false 

	CLOSE WINDOW G146 
END FUNCTION 
####################################################################
# FUNCTION coa_edit(p_account_code)
####################################################################


####################################################################
# FUNCTION update_cab(p_rec_fundsapproved)
#
#
####################################################################
# FUNCTION: update_cab
# Description: Updates/inserts the data INTO tables fundsapproved AND fundaudit.
FUNCTION update_cab(p_rec_fundsapproved) 
	DEFINE p_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_old_limit_amt LIKE fundaudit.old_limit_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("U",1005,"") #1005 Updating database;  Please wait.
	IF p_rec_fundsapproved.active_flag = "Y" THEN 
		LET p_rec_fundsapproved.complete_date = NULL 
	ELSE 
		LET p_rec_fundsapproved.complete_date = today 
	END IF 
	
	SELECT fundsapproved.limit_amt INTO l_old_limit_amt FROM fundsapproved 
	WHERE fundsapproved.cmpy_code = p_rec_fundsapproved.cmpy_code 
	AND fundsapproved.acct_code = p_rec_fundsapproved.acct_code 
	IF status = NOTFOUND THEN 
		IF p_rec_fundsapproved.cmpy_code IS NOT NULL 
		AND p_rec_fundsapproved.acct_code IS NOT NULL 
		AND p_rec_fundsapproved.fund_type_ind IS NOT NULL THEN 
		
			INSERT INTO fundsapproved VALUES (p_rec_fundsapproved.*) 
			INSERT INTO fundaudit VALUES (
				p_rec_fundsapproved.cmpy_code, 
				p_rec_fundsapproved.acct_code, 
				0, 
				p_rec_fundsapproved.limit_amt, 
				p_rec_fundsapproved.entry_date, 
				p_rec_fundsapproved.entry_code) 
		END IF 

	ELSE 

		LET p_rec_fundsapproved.amend_date = today 
		LET p_rec_fundsapproved.amend_code = glob_rec_kandoouser.sign_on_code 
		UPDATE fundsapproved 
		SET fundsapproved.* = p_rec_fundsapproved.* 
		WHERE fundsapproved.cmpy_code = p_rec_fundsapproved.cmpy_code 
		AND fundsapproved.acct_code = p_rec_fundsapproved.acct_code 
		
		INSERT INTO fundaudit VALUES (
			p_rec_fundsapproved.cmpy_code, 
			p_rec_fundsapproved.acct_code, 
			l_old_limit_amt, 
			p_rec_fundsapproved.limit_amt, 
			p_rec_fundsapproved.amend_date, 
			p_rec_fundsapproved.amend_code) 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION coa_edit(p_account_code)
####################################################################


####################################################################
# FUNCTION edit_new_capitalAccountBudget(p_rec_fundsapproved, p_acct_code, p_desc_text, p_type_ind)
# Description: Allows the user TO keep adding/modifying a Capital Account
#              Budget.
# Note:        This program does NOT INSERT/UPDATE necessary tables until
#              the user presses OK on the G146 form. (done in update_cab)
####################################################################
FUNCTION edit_new_capitalaccountbudget(p_rec_fundsapproved, p_acct_code, p_desc_text, p_type_ind) 
	DEFINE p_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE p_acct_code LIKE coa.acct_code 
	DEFINE p_desc_text LIKE coa.desc_text 
	DEFINE p_type_ind LIKE coa.type_ind 

	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_response_text LIKE kandooword.response_text 
	DEFINE l_err_message CHAR(1) 
	DEFINE l_delete_flag SMALLINT 
	DEFINE l_update_flag SMALLINT 
	DEFINE l_temp_text CHAR(3) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_rec_fundsapproved.acct_code IS NULL THEN 
		# In Add mode.
		LET l_rec_fundsapproved.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_fundsapproved.entry_date = today 
		LET l_rec_fundsapproved.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_fundsapproved.acct_code = p_acct_code 
		LET l_rec_fundsapproved.active_flag = "Y" 
		LET l_rec_fundsapproved.approval_date = today 
		LET l_rec_fundsapproved.amend_date = NULL 
	ELSE 
		# In Edit mode.
		LET l_rec_fundsapproved.* = p_rec_fundsapproved.* 
		SELECT response_text INTO l_response_text FROM kandooword 
		WHERE reference_code = l_rec_fundsapproved.fund_type_ind 
		AND reference_text = "fundsapproved.fund_type_ind" 
		IF status = NOTFOUND THEN 
			LET l_response_text = "" 
		END IF 
	END IF 

	LET l_delete_flag = false 
	LET l_update_flag = false 

	WHENEVER ERROR CONTINUE 
	CLOSE WINDOW G552 
	WHENEVER ERROR stop 

	OPEN WINDOW G552 with FORM "G552" 
	CALL windecoration_g("G552") 

	ERROR kandoomsg2("G",1085,"") #1085 Enter Approved Funds details; F2 Delete; OK TO continue.
	DISPLAY l_rec_fundsapproved.acct_code TO coa.acct_code 
	DISPLAY p_desc_text TO coa.desc_text 
	DISPLAY p_type_ind TO coa.type_ind 
	DISPLAY l_response_text TO response_text 
	DISPLAY l_rec_fundsapproved.amend_code TO fundsapproved.amend_code 
	DISPLAY l_rec_fundsapproved.amend_date TO fundsapproved.amend_date 

	INPUT BY NAME 
		l_rec_fundsapproved.fund_type_ind, 
		l_rec_fundsapproved.locn_text, 
		l_rec_fundsapproved.limit_amt, 
		l_rec_fundsapproved.approval_date, 
		l_rec_fundsapproved.capital_ref, 
		l_rec_fundsapproved.active_flag WITHOUT DEFAULTS attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ1","coa3") 

		BEFORE FIELD limit_amt 
			IF l_rec_fundsapproved.fund_type_ind != "CAP" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD locn_text 
				ELSE 
					NEXT FIELD approval_date 
				END IF 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "DELETE" #on KEY (F2) 
			IF p_rec_fundsapproved.acct_code IS NOT NULL THEN 
				ERROR kandoomsg2("G",8181,"") #8181 Confirm TO delete approved funds account details?
				IF l_msgresp = "Y" THEN 
					LET l_delete_flag = true 
					EXIT INPUT 
				END IF 
			END IF 

		ON ACTION "LOOKUP" infield(fund_type_ind) 
			LET l_temp_text = show_kandooword("fundsapproved.fund_type_ind") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_fundsapproved.fund_type_ind = l_temp_text 
			END IF 
			NEXT FIELD fund_type_ind 

		AFTER FIELD fund_type_ind 
			IF l_rec_fundsapproved.fund_type_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
				NEXT FIELD fund_type_ind 
			END IF 

			SELECT response_text INTO l_response_text FROM kandooword 
			WHERE reference_code = l_rec_fundsapproved.fund_type_ind 
			AND reference_text = "fundsapproved.fund_type_ind" 

			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9111,"Funds approval type indicator") #9111 Funds approval type indicator NOT found.
				NEXT FIELD fund_type_ind 
			ELSE 
				DISPLAY l_response_text TO response_text 
			END IF 

			IF l_rec_fundsapproved.fund_type_ind = "CAP" THEN 
				IF l_rec_fundsapproved.limit_amt IS NULL THEN 
					LET l_rec_fundsapproved.limit_amt = 0 
					DISPLAY BY NAME l_rec_fundsapproved.limit_amt 
				END IF 
			ELSE 
				LET l_rec_fundsapproved.limit_amt = NULL 
				DISPLAY BY NAME l_rec_fundsapproved.limit_amt 
			END IF 

		AFTER FIELD limit_amt 
			IF l_rec_fundsapproved.limit_amt IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				LET l_rec_fundsapproved.limit_amt = 0 
				NEXT FIELD limit_amt 
			END IF 
			
			IF l_rec_fundsapproved.limit_amt < 0 THEN 
				ERROR kandoomsg2("U",9907,"0") 		#9102 Value must be greater than OR equal TO 0.
				LET l_rec_fundsapproved.limit_amt = 0 
				NEXT FIELD limit_amt 
			END IF 

		AFTER FIELD approval_date 
			IF l_rec_fundsapproved.approval_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered.
				LET l_rec_fundsapproved.approval_date = today 
				NEXT FIELD approval_date 
			END IF 

		AFTER INPUT 
			IF int_flag = 1 OR quit_flag = 1 
			THEN # "Cancel" ACTION activated 
				IF field_touched(fundsapproved.*) <> 0 THEN #check, IF anything has changed... 
					IF promptTF("Exit ?","Do you want to exit ?\nAll changes will be lost !",TRUE) THEN 
						LET l_update_flag = false 
						EXIT INPUT 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				ELSE 
					LET l_update_flag = false 
					EXIT INPUT 
				END IF
				 
			ELSE # "Apply" ACTION activated
 
				IF field_touched(fundsapproved.*) <> 0 THEN #check, IF anything has changed... 
					IF l_rec_fundsapproved.fund_type_ind IS NULL THEN 
						ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered.
						NEXT FIELD fund_type_ind 
					END IF 
					
					IF l_rec_fundsapproved.limit_amt IS NULL AND l_rec_fundsapproved.fund_type_ind = "CAP" THEN 
						ERROR kandoomsg2("U",9102,"")#9102 Value must be entered.
						LET l_rec_fundsapproved.limit_amt = 0 
						NEXT FIELD limit_amt 
					END IF 
					
					IF l_rec_fundsapproved.approval_date IS NULL THEN 
						ERROR kandoomsg2("U",9102,"")#9102 Value must be entered.
						LET l_rec_fundsapproved.approval_date = today 
						NEXT FIELD approval_date 
					END IF 
					
					LET l_update_flag = true 
					EXIT INPUT
					 
				ELSE 
					LET l_update_flag = false 
					EXIT INPUT 
				END IF
				 
			END IF 

	END INPUT 

	IF l_delete_flag THEN 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			CLOSE WINDOW g552 
			RETURN p_rec_fundsapproved.*, false 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 

			LET l_err_message = "GZ1 - Funds Approved deletion" 
			DELETE FROM fundsapproved 
			WHERE cmpy_code = l_rec_fundsapproved.cmpy_code 
			AND acct_code = l_rec_fundsapproved.acct_code
			 
			LET l_err_message = "GZ1 - Insert Funds Audit" 
			LET l_rec_fundsapproved.amend_date = today 
			LET l_rec_fundsapproved.amend_code = glob_rec_kandoouser.sign_on_code 
			
			INSERT INTO fundaudit VALUES (
				l_rec_fundsapproved.cmpy_code, 
				l_rec_fundsapproved.acct_code, 
				l_rec_fundsapproved.limit_amt, 
				0, 
				l_rec_fundsapproved.amend_date, 
				l_rec_fundsapproved.amend_code) 

		COMMIT WORK 
		CLOSE WINDOW G552 

		INITIALIZE l_rec_fundsapproved.* TO NULL 
		RETURN l_rec_fundsapproved.*, false 
	END IF 

	RETURN l_rec_fundsapproved.*,l_update_flag 
END FUNCTION 
####################################################################
# END FUNCTION edit_new_capitalAccountBudget(p_rec_fundsapproved, p_acct_code, p_desc_text, p_type_ind)
####################################################################


####################################################################
# G552_display_groupinfo_desc_text(p_desc_text)
#
#
####################################################################
FUNCTION g552_display_groupinfo_desc_text(p_desc_text) 
	DEFINE p_desc_text STRING 

	IF p_desc_text IS NULL THEN 
		CLEAR groupinfo.desc_text 
	ELSE 
		DISPLAY p_desc_text TO groupinfo.desc_text 
	END IF 
END FUNCTION 
####################################################################
# END G552_display_groupinfo_desc_text(p_desc_text)
####################################################################


####################################################################
# FUNCTION G552_display_uom_desc_text(p_desc_text)
#
#
####################################################################
FUNCTION g552_display_uom_desc_text(p_desc_text) 
	DEFINE p_desc_text STRING 

	IF p_desc_text IS NULL THEN 
		CLEAR uom.desc_text 
	ELSE 
		DISPLAY p_desc_text TO uom.desc_text 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION G552_display_uom_desc_text(p_desc_text)
####################################################################


####################################################################
# FUNCTION G552_display_tax_desc_text(p_desc_text)
#
#
####################################################################
FUNCTION g552_display_tax_desc_text(p_desc_text) 
	DEFINE p_desc_text STRING 

	IF p_desc_text IS NULL THEN 
		CLEAR tax.desc_text 
	ELSE 
		DISPLAY p_desc_text TO tax.desc_text 
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION G552_display_tax_desc_text(p_desc_text)
####################################################################