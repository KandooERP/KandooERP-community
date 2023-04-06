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

	Source code beautified by beautify.pl on 2020-01-03 09:12:46	$Id: $
}




# IZ1 allows the user TO enter AND maintain product categories


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "IZ1_GLOBALS.4gl" 

DEFINE t_arr_category TYPE AS RECORD 
	cat_code LIKE category.cat_code, 
	desc_text LIKE category.desc_text,
	sale_acct_code LIKE category.sale_acct_code
END RECORD 

DEFINE t_category_prykey TYPE AS RECORD
	cmpy_code LIKE prodgrp.cmpy_code,
	cat_code LIKE category.cat_code
END RECORD

DEFINE t_arr_action TYPE AS RECORD
	ACTION CHAR(1)
END RECORD

DEFINE t_rec_category TYPE AS RECORD LIKE category.*

DEFINE t_rec_sale_accounts  TYPE AS RECORD #pr_sale_accounts 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_cogs_accounts TYPE AS RECORD #pr_cogs_accounts  
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_int_rev_accts TYPE AS RECORD #pr_int_rev_accts 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_int_cogs_accts TYPE AS RECORD #pr_int_cogs_accts  
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_f_sale_accounts  TYPE AS RECORD  #pf_sale_accounts 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_f_cogs_accounts TYPE AS RECORD #pf_cogs_accounts  
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_f_int_rev_accts TYPE AS RECORD#pf_int_rev_accts 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD
DEFINE t_rec_f_int_cogs_accts TYPE AS RECORD #pf_int_cogs_accts 
	def_acct_code LIKE coa.acct_code, 
	ord6_acct_code LIKE coa.acct_code, 
	ord7_acct_code LIKE coa.acct_code, 
	ord8_acct_code LIKE coa.acct_code, 
	ord9_acct_code LIKE coa.acct_code 
END RECORD


DEFINE crs_list_category CURSOR  # w define this cursor as module because it may be reused
DEFINE p_delete_orderaccounts PREPARED
DEFINE p_update_orderaccounts PREPARED
DEFINE p_insert_orderaccounts PREPARED
DEFINE p_insert_category PREPARED
DEFINE p_update_category PREPARED
DEFINE p_delete_category PREPARED


FUNCTION IZ1_main()
	DEFINE nb_elements INTEGER 
	DEFINE l_arr_rec_category DYNAMIC ARRAY OF t_arr_category
	DEFINE l_arr_category_prykey DYNAMIC ARRAY OF t_category_prykey
	DEFINE l_arr_category_action DYNAMIC ARRAY OF t_arr_action
	OPEN WINDOW wi136 with FORM "I136" 
	 CALL windecoration_i("I136") 
	 CALL windecoration_i("I135")		# Since the edit form is called many time, windecoration only ONCE!
	CALL prepare_cursors_IZ1()	# declare and prepare all necessary cursors
	MENU
		COMMAND "Browse categories"
			CALL construct_dataset_category(TRUE) RETURNING nb_elements,l_arr_rec_category,l_arr_category_prykey,l_arr_category_action
			CALL scan_dataset_pick_action_category(l_arr_rec_category,l_arr_category_prykey,l_arr_category_action) 
		COMMAND "Exit"
			EXIT MENU
	END MENU

	LET int_flag = false 
	CLOSE WINDOW wi136 
END FUNCTION # IZ1_main 

####################################################################
# FUNCTION whs_category_get_datasource(p_filter)
#
# QUERY / CONSTRUCT for catetory
####################################################################
FUNCTION construct_dataset_category(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_arr_rec_category DYNAMIC ARRAY OF t_arr_category
	DEFINE l_arr_category_prykey DYNAMIC ARRAY OF t_category_prykey
	DEFINE l_arr_category_action DYNAMIC ARRAY OF t_arr_action
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_curr SMALLINT
--	DEFINE crs_list_category CURSOR

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.

		CONSTRUCT BY NAME l_where_text 
		ON cat_code, 
		desc_text, 
		sale_acct_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IZ1","construct-category") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1 = 1 " 
		END IF 
		LET l_query_text = "SELECT cat_code,desc_text,sale_acct_code,cmpy_code,cat_code,'=' FROM category ", 
		"WHERE cmpy_code = ? ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cat_code" 
		CALL crs_list_category.Declare(l_query_text)
	ELSE 
		LET l_where_text = " 1 = 1 " 
	END IF 


	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait
--	LET l_query_text = "SELECT cat_code,desc_text,sale_acct_code,cmpy_code,cat_code,'=' FROM category ", 
--	"WHERE cmpy_code = ? ", 
--	"AND ",l_where_text clipped," ", 
--	"ORDER BY cat_code" 

--	CALL crs_list_category.Declare(l_query_text)
	CALL crs_list_category.Open (glob_rec_kandoouser.cmpy_code)
	
	LET l_idx = 1
	WHILE  crs_list_category.FetchNext(l_arr_rec_category[l_idx].*,l_arr_category_prykey[l_idx].*,l_arr_category_action[l_idx].*) = 0
		LET l_idx = l_idx + 1 
	END WHILE
	CALL l_arr_rec_category.DeleteElement(l_idx)
	CALL l_arr_category_prykey.DeleteElement(l_idx)
	CALL l_arr_category_action.DeleteElement(l_idx)

	RETURN l_arr_rec_category.GetSize(),l_arr_rec_category,l_arr_category_prykey,l_arr_category_action

END FUNCTION  # construct_dataset_category

FUNCTION scan_dataset_pick_action_category(p_arr_rec_category,p_arr_category_prykey,p_arr_category_action)
	DEFINE p_arr_rec_category DYNAMIC ARRAY OF t_arr_category
	DEFINE p_arr_category_prykey DYNAMIC ARRAY OF t_category_prykey
	DEFINE p_arr_category_action DYNAMIC ARRAY OF t_arr_action
	DEFINE l_rec_category t_rec_category
	DEFINE l_rec_category_prykey t_category_prykey
	DEFINE l_status INTEGER
	DEFINE l_arr_curr SMALLINT
	DEFINE l_msgresp STRING
	DEFINE l_del_cnt INTEGER
	DEFINE nb_elements INTEGER

	DISPLAY ARRAY p_arr_rec_category TO sr_category.* 
		BEFORE DISPLAY 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL publish_toolbar("kandoo","IZ1","disp-arr-category") 

		BEFORE ROW 
			LET l_arr_curr = arr_curr() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

{
		FIXME: We 'll see later both options ...
		ericv
		ON ACTION "FILTER" 
			CALL p_arr_rec_category.clear() 
			CALL construct_dataset_category(true) RETURNING p_arr_rec_category 

		ON ACTION "REFRESH" 
			 CALL windecoration_i("I136") 
			CALL p_arr_rec_category.clear() 
			CALL whs_category_get_datasource(false) RETURNING p_arr_rec_category 
}
		ON ACTION "Add"  
			INITIALIZE p_arr_category_prykey[l_arr_curr].* TO NULL
			CALL input_category(MODE_CLASSIC_ADD,p_arr_category_prykey[l_arr_curr].*) RETURNING l_rec_category.*,p_arr_category_prykey[l_arr_curr].*
			DISPLAY p_arr_rec_category[l_arr_curr].cat_code,p_arr_rec_category[l_arr_curr].desc_text,p_arr_rec_category[l_arr_curr].sale_acct_code 
			TO sr_category[l_arr_curr].cat_code,sr_category[l_arr_curr].desc_text,sr_category[l_arr_curr].sale_acct_code
			CALL construct_dataset_category(FALSE) RETURNING nb_elements,p_arr_rec_category,p_arr_category_prykey,p_arr_category_action   # refresh
			
		
		ON ACTION ("ACCEPT",MODE_CLASSIC_EDIT) 
			LET l_msgresp = kandoomsg("U",1001,"") 
			CALL input_category(MODE_CLASSIC_EDIT,p_arr_category_prykey[l_arr_curr].*) RETURNING l_rec_category.*,p_arr_category_prykey[l_arr_curr].*
			DISPLAY p_arr_rec_category[l_arr_curr].cat_code,p_arr_rec_category[l_arr_curr].desc_text,p_arr_rec_category[l_arr_curr].sale_acct_code 
			TO sr_category[l_arr_curr].cat_code,sr_category[l_arr_curr].desc_text,sr_category[l_arr_curr].sale_acct_code
			CALL construct_dataset_category(FALSE) RETURNING nb_elements,p_arr_rec_category,p_arr_category_prykey,p_arr_category_action   # refresh

--		ON ACTION "Save" # Save has been placed in the input functions ericv 20201218 
 
		ON ACTION "Pricing" 
			#COMMAND "Pricing" " Enter category pricing details"
			CALL input_category_pricing(p_arr_category_prykey[l_arr_curr].*) RETURNING l_rec_category.* 

		ON ACTION DELETE 
			CALL input_category("SUPPR",p_arr_category_prykey[l_arr_curr].*) RETURNING l_rec_category.*,p_arr_category_prykey[l_arr_curr].*
			CALL construct_dataset_category(FALSE) RETURNING nb_elements,p_arr_rec_category,p_arr_category_prykey,p_arr_category_action   # refresh

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
			LET quit_flag = true 
			--EXIT MENU 
			LET p_arr_rec_category[l_arr_curr].cat_code = l_rec_category.cat_code 
			LET p_arr_rec_category[l_arr_curr].desc_text = l_rec_category.desc_text 
			LET p_arr_rec_category[l_arr_curr].sale_acct_code = l_rec_category.sale_acct_code 

	END DISPLAY 
	--------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

END FUNCTION	# scan_dataset_pick_action_category


####################################################################
# FUNCTION input_category()
#
#
####################################################################
FUNCTION input_category(p_mode,p_category_prykey) 
	DEFINE p_mode CHAR(5)
	DEFINE p_category_prykey t_category_prykey
	DEFINE l_rec_category RECORD LIKE category.*
	DEFINE l_rec_category_bkup RECORD LIKE category.*  # backup record to be restored in case of int_flag
	DEFINE l_cat_code LIKE category.cat_code 
	DEFINE l_sale_acct_name LIKE coa.desc_text 
	DEFINE l_cogs_acct_name  LIKE coa.desc_text 
	DEFINE l_stock_acct_name LIKE coa.desc_text 
	DEFINE l_adj_acct_name LIKE coa.desc_text 
	DEFINE l_int_rev_acct_name LIKE coa.desc_text 
	DEFINE l_int_cogs_acct_name  LIKE coa.desc_text 
	DEFINE l_maxbrick_flag CHAR(1) 
	DEFINE l_exit_flag CHAR(1) 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_sale_first_flag SMALLINT # FIRST time entry OF sale ORDER accounts. 
	DEFINE l_cogs_first_flag SMALLINT 
	DEFINE l_int_rev_flag SMALLINT 
	DEFINE l_int_cogs_flag SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_lastkey SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_status INTEGER
	DEFINE input_again_flag BOOLEAN
	DEFINE l_rec_sale_accounts t_rec_sale_accounts  
	DEFINE l_rec_cogs_accounts t_rec_cogs_accounts   
	DEFINE l_rec_int_rev_accts t_rec_int_rev_accts 
	DEFINE l_rec_int_cogs_accts t_rec_int_cogs_accts   
	DEFINE l_rec_f_sale_accounts t_rec_f_sale_accounts 
	DEFINE l_rec_f_cogs_accounts t_rec_f_cogs_accounts   
	DEFINE l_rec_f_int_rev_accts t_rec_f_int_rev_accts 
	DEFINE l_rec_f_int_cogs_accts t_rec_f_int_cogs_accts
	
	OPEN WINDOW i135 with FORM "I135_textfield"    # form with accounts as textfields 
	--OPEN WINDOW i135 with FORM "I135"				# form with accounts as comboboxes for test purpose
	 CALL windecoration_i("I135") 					# no good to repeat everytime this function is called, placed in Main
	
	CASE 
		WHEN p_mode = MODE_CLASSIC_EDIT OR p_mode = "SUPPR"
			# Read the full record then display
			CALL category_get_full_record(p_category_prykey.cat_code) RETURNING l_status,l_rec_category.* 
			LET l_rec_category_bkup.* = l_rec_category.*	# save the original, to be restore if int_flag
			DISPLAY BY NAME l_rec_category.desc_text,l_rec_category.sale_acct_code,
				l_rec_category.cogs_acct_code,
				l_rec_category.stock_acct_code,
				l_rec_category.adj_acct_code,
				l_rec_category.int_rev_acct_code,
				l_rec_category.int_cogs_acct_code
				
			CALL coa_get_account_name(l_rec_category.sale_acct_code) RETURNING l_status,l_sale_acct_name
			DISPLAY l_sale_acct_name TO sale_acct_name 

			CALL coa_get_account_name(l_rec_category.cogs_acct_code) RETURNING l_status,l_cogs_acct_name
			DISPLAY l_cogs_acct_name TO cogs_acct_name 

			CALL coa_get_account_name(l_rec_category.stock_acct_code) RETURNING l_status,l_stock_acct_name
			DISPLAY l_stock_acct_name TO stock_acct_name 

			CALL coa_get_account_name(l_rec_category.adj_acct_code)  RETURNING l_status,l_adj_acct_name
			DISPLAY l_adj_acct_name TO adj_acct_name 

			CALL coa_get_account_name(l_rec_category.int_rev_acct_code) RETURNING l_status,l_int_rev_acct_name
			DISPLAY l_int_rev_acct_name TO int_rev_acct_name 
			CALL coa_get_account_name(l_rec_category.int_cogs_acct_code) RETURNING l_status,l_int_cogs_acct_name
			DISPLAY l_int_cogs_acct_name  TO int_cogs_acct_name  
			
			DISPLAY BY NAME l_rec_category.cat_code 

		WHEN p_mode = MODE_CLASSIC_ADD
			INITIALIZE l_rec_category.* TO NULL 
	END CASE

	IF p_mode = "SUPPR" THEN		# Suppression: just display, ask if sure then delete and return
		LET l_msgresp = kandoomsg("I",8005,1) 
		#8005 Confirm TO Delete ",l_del_cnt," category(s)? (Y/N)"
		IF l_msgresp = "Y" THEN 
			CALL update_insert_delete_category_orderaccounts("SUPPR",p_category_prykey,l_rec_category,l_rec_sale_accounts,l_rec_cogs_accounts,l_rec_int_rev_accts,l_rec_int_cogs_accts)  RETURNING l_status
			RETURN l_rec_category.*,p_category_prykey.*
		ELSE
			RETURN l_rec_category.*,p_category_prykey.*
		END IF
	END IF
	
	# Find out if we are in "maxbrick" mode ....
	SELECT module_text INTO l_temp_text FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF l_temp_text[23] != "W" THEN 
		LET l_maxbrick_flag = false 
	ELSE 
		LET l_maxbrick_flag = true 
	END IF 

	LET l_sale_first_flag = true 
	LET l_cogs_first_flag = true 
	LET l_int_rev_flag = true 
	LET l_int_cogs_flag = true 

	INITIALIZE l_rec_sale_accounts.* TO NULL 
	INITIALIZE l_rec_f_sale_accounts.* TO NULL 
	INITIALIZE l_rec_cogs_accounts.* TO NULL 
	INITIALIZE l_rec_f_cogs_accounts.* TO NULL 
	INITIALIZE l_rec_int_rev_accts.* TO NULL 
	INITIALIZE l_rec_f_int_rev_accts.* TO NULL 
	INITIALIZE l_rec_int_cogs_accts.* TO NULL 
	INITIALIZE l_rec_f_int_cogs_accts.* TO NULL 

	INPUT BY NAME l_rec_category.cat_code, 
		l_rec_category.desc_text, 
		l_rec_category.sale_acct_code, 
		l_rec_category.cogs_acct_code, 
		l_rec_category.stock_acct_code, 
		l_rec_category.adj_acct_code, 
		l_rec_category.int_rev_acct_code, 
		l_rec_category.int_cogs_acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			IF p_mode = MODE_CLASSIC_EDIT THEN
				# We do not touch primary key in EDIT mode
				CALL Dialog.setFieldActive("cat_code",FALSE)
			ELSE
				CALL Dialog.setFieldActive("cat_code",TRUE)
			END IF
			# in maxbrick_flag mode, those fields are not touched
			# FIXME: see if we don't hide them
			IF l_maxbrick_flag = false THEN
				CALL Dialog.setFieldActive("int_rev_acct_code",FALSE)
				CALL Dialog.setFieldActive("int_cogs_acct_code",FALSE)
			END IF

			CALL publish_toolbar("kandoo","IZ2","input-category") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(sale_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.sale_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.sale_acct_code 
			END IF 
			NEXT FIELD sale_acct_code 

		ON ACTION "LOOKUP" infield(cogs_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.cogs_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.cogs_acct_code 
			END IF 
			NEXT FIELD cogs_acct_code 

		ON ACTION "LOOKUP" infield(stock_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.stock_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.stock_acct_code 
			END IF 
			NEXT FIELD stock_acct_code 

		ON ACTION "LOOKUP" infield(adj_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.adj_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.adj_acct_code 
			END IF 
			NEXT FIELD adj_acct_code 

		ON ACTION "LOOKUP" infield(int_rev_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.int_rev_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.int_rev_acct_code 
			END IF 
			NEXT FIELD int_rev_acct_code 

		ON ACTION "LOOKUP" infield(int_cogs_acct_code)
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_category.int_cogs_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_category.int_cogs_acct_code 
			END IF 
			NEXT FIELD int_cogs_acct_code 

		AFTER FIELD cat_code 
			IF p_mode = MODE_CLASSIC_ADD THEN
				# added this IF because AFTER FIELD remains active even though the field is disabled
				IF l_rec_category.cat_code IS NULL THEN 
					LET l_msgresp = kandoomsg("I",9038,"") 
					#9038 Category Code must be entered.
					NEXT FIELD cat_code 
				ELSE 
					# since cat_code field is not active for EDIT mode, no need to test
					IF check_prykey_exists_category(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code) THEN
						LET l_msgresp = kandoomsg("I",9093,"") 
						#9093 Category already exists - Please Re-enter
						NEXT FIELD cat_code 
					END IF 
				END IF 
			END IF

		AFTER FIELD desc_text 
			IF l_rec_category.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9000,"") 
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD sale_acct_code 
			IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
				LET l_rec_f_sale_accounts.* = l_rec_sale_accounts.* 
				LET l_rec_sale_accounts.def_acct_code = l_rec_category.sale_acct_code 
				CALL enter_ordacct(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code,"category","sale_acct_code",l_rec_sale_accounts.*,l_sale_first_flag) 
				RETURNING l_exit_flag, l_rec_sale_accounts.* 
				IF NOT l_exit_flag THEN 
					IF (l_rec_category.sale_acct_code != l_rec_sale_accounts.def_acct_code) OR l_rec_category.sale_acct_code IS NULL THEN 
						LET l_rec_category.sale_acct_code = l_rec_sale_accounts.def_acct_code 
						SELECT desc_text INTO l_sale_acct_name FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND coa.acct_code = l_rec_category.sale_acct_code 
						DISPLAY l_rec_category.sale_acct_code TO category.sale_acct_code 
						DISPLAY l_sale_acct_name TO sale_acct_name 
					END IF 
					LET l_sale_first_flag = false 
				ELSE 
					# User has cancelled entries
					LET l_rec_sale_accounts.* = l_rec_f_sale_accounts.* 
				END IF 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD sale_acct_code 
			CALL coa_get_account_name(l_rec_category.sale_acct_code) RETURNING l_status,l_sale_acct_name 
			IF l_status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("I",9203,"") 
				#9203 Sales account does NOT exist
				NEXT FIELD sale_acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.sale_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD sale_acct_code 
				END IF 
				DISPLAY l_sale_acct_name TO sale_acct_name 

			END IF 

		BEFORE FIELD cogs_acct_code 
			IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
				LET l_rec_f_cogs_accounts.* = l_rec_cogs_accounts.* 
				LET l_rec_cogs_accounts.def_acct_code = l_rec_category.cogs_acct_code 
				CALL enter_ordacct(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code,"category","cogs_acct_code",l_rec_cogs_accounts.*,l_cogs_first_flag) 
				RETURNING l_exit_flag, l_rec_cogs_accounts.* 
				
				IF NOT l_exit_flag THEN 
					IF (l_rec_category.cogs_acct_code != l_rec_cogs_accounts.def_acct_code) OR l_rec_category.cogs_acct_code IS NULL THEN 
						LET l_rec_category.cogs_acct_code = l_rec_cogs_accounts.def_acct_code 
						CALL coa_get_account_name(l_rec_category.cogs_acct_code) RETURNING l_status,l_cogs_acct_name 
						DISPLAY l_rec_category.cogs_acct_code, l_cogs_acct_name 
						TO category.cogs_acct_code, cogs_acct_name 
					END IF 
					LET l_cogs_first_flag = false 
				ELSE 
					# User has cancelled entries
					LET l_rec_cogs_accounts.* = l_rec_f_cogs_accounts.* 
				END IF 
			END IF 

		AFTER FIELD cogs_acct_code 
			CALL coa_get_account_name(l_rec_category.cogs_acct_code) RETURNING l_status,l_cogs_acct_name  
			IF l_status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("I",9204,"") 
				#9204 Cost of goods account does NOT exist
				NEXT FIELD cogs_acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.cogs_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD cogs_acct_code 
				END IF 
				DISPLAY l_cogs_acct_name TO cogs_acct_name 

			END IF 

		AFTER FIELD stock_acct_code 
			CALL coa_get_account_name(l_rec_category.stock_acct_code) RETURNING l_status,l_stock_acct_name  
			IF l_status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("I",9205,"") 
				#9205 Inventory account does NOT exist
				NEXT FIELD stock_acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.stock_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
					NEXT FIELD stock_acct_code 
				END IF 
				DISPLAY l_stock_acct_name TO stock_acct_name 

			END IF 

		AFTER FIELD adj_acct_code 
			CALL coa_get_account_name(l_rec_category.adj_acct_code) RETURNING l_status,l_adj_acct_name  
			IF l_status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("I",9206,"") 
				#9206 Adjustment account does NOT exist
				NEXT FIELD adj_acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.adj_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD adj_acct_code 
				END IF 
				DISPLAY l_adj_acct_name TO adj_acct_name 

			END IF 

		BEFORE FIELD int_rev_acct_code 
			IF l_maxbrick_flag THEN 
				IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
					LET l_rec_f_int_rev_accts.* = l_rec_int_rev_accts.* 
					LET l_rec_int_rev_accts.def_acct_code 
					= l_rec_category.int_rev_acct_code 
					CALL enter_ordacct(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code,"category", "int_rev_acct_code",l_rec_int_rev_accts.*, l_int_rev_flag) 
					RETURNING l_exit_flag, l_rec_int_rev_accts.* 
					IF NOT l_exit_flag THEN 
						IF (l_rec_category.int_rev_acct_code != l_rec_int_rev_accts.def_acct_code) OR l_rec_category.int_rev_acct_code IS NULL THEN 
							LET l_rec_category.int_rev_acct_code = l_rec_int_rev_accts.def_acct_code 
							CALL coa_get_account_name(l_rec_category.int_rev_acct_code) RETURNING l_status,l_int_rev_acct_name  
							DISPLAY l_rec_category.int_rev_acct_code, l_int_rev_acct_name 
							TO category.int_rev_acct_code, int_rev_acct_name 
						END IF 
						LET l_int_rev_flag = false 
					ELSE 
						# User has cancelled entries
						LET l_rec_int_rev_accts.* = l_rec_f_int_rev_accts.* 
					END IF 
				END IF 
			END IF

		AFTER FIELD int_rev_acct_code 
			IF l_maxbrick_flag THEN 
				CALL coa_get_account_name(l_rec_category.int_rev_acct_code) RETURNING l_status,l_int_rev_acct_name  
				IF l_status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("I",9561,"") 
					#9561 Inventory revenue account does NOT exist.
					NEXT FIELD int_rev_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.int_rev_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD int_rev_acct_code 
				END IF 
				DISPLAY l_int_rev_acct_name TO int_rev_acct_name 
			END IF

		BEFORE FIELD int_cogs_acct_code 
			IF l_maxbrick_flag THEN 
				IF get_kandoooption_feature_state("WO","TA") = "Y" THEN 
					IF l_lastkey = 0 THEN 
						LET l_lastkey = fgl_lastkey() 
					END IF 
					LET l_rec_f_int_cogs_accts.* = l_rec_int_cogs_accts.* 
					LET l_rec_int_cogs_accts.def_acct_code = l_rec_category.int_cogs_acct_code 
					CALL enter_ordacct(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code,"category", "int_cogs_acct_code",l_rec_int_cogs_accts.*,l_int_cogs_flag) 
					RETURNING l_exit_flag, l_rec_int_cogs_accts.* 
					IF NOT l_exit_flag THEN 
						IF (l_rec_category.int_cogs_acct_code != l_rec_int_cogs_accts.def_acct_code) OR l_rec_category.int_cogs_acct_code IS NULL THEN 
							LET l_rec_category.int_cogs_acct_code = l_rec_int_cogs_accts.def_acct_code 
							CALL coa_get_account_name(l_rec_category.int_cogs_acct_code) RETURNING l_status,l_int_cogs_acct_name  
						END IF 
						LET l_int_cogs_flag = false 
					ELSE 
						# User has cancelled entries
						LET l_rec_int_cogs_accts.* = l_rec_f_int_cogs_accts.* 
						LET int_flag = true 
					END IF 
					DISPLAY l_rec_category.int_cogs_acct_code, l_int_cogs_acct_name 
					TO category.int_cogs_acct_code, int_cogs_acct_name  

					IF l_rec_category.int_rev_acct_code IS NULL AND NOT int_flag THEN 
						LET l_msgresp=kandoomsg("I",9561,"") 
						#9561 Inventory revenue account does NOT exist.
						NEXT FIELD int_rev_acct_code 
					END IF 
				END IF 
			END IF

		AFTER FIELD int_cogs_acct_code 
			IF l_maxbrick_flag THEN 
				CALL coa_get_account_name(l_rec_category.int_cogs_acct_code) RETURNING l_status,l_int_cogs_acct_name  
				IF l_status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("I",9562,"") 
					#9562 Internal Cost of goods account does NOT exist.
					NEXT FIELD int_cogs_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_category.int_cogs_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD int_cogs_acct_code 
				END IF 

				DISPLAY l_rec_category.int_cogs_acct_code,l_int_cogs_acct_name  
				TO category.int_cogs_acct_code,int_cogs_acct_name  
			END IF

		AFTER INPUT 
			CASE
				WHEN NOT (int_flag OR quit_flag OR input_again_flag) # Let us commit input and update data
					LET p_category_prykey.cmpy_code = l_rec_category.cmpy_code
					LET p_category_prykey.cat_code = l_rec_category.cat_code
					CALL update_insert_delete_category_orderaccounts(p_mode,p_category_prykey,l_rec_category,l_rec_sale_accounts,l_rec_cogs_accounts,l_rec_int_rev_accts,l_rec_int_cogs_accts) RETURNING l_status

					IF l_status = 0 THEN
						ERROR "This category has been set up successfully"
					ELSE
						ERROR "An Error occurred while setting up this category"
					END IF
					LET input_again_flag = FALSE
					EXIT INPUT
					
				WHEN (int_flag OR quit_flag	) # Cancel this entry and forget this input
					LET int_flag = false 
					LET quit_flag = false 
					LET l_rec_category.* = l_rec_category_bkup.*
					LET p_category_prykey.cmpy_code = l_rec_category_bkup.cmpy_code
					LET p_category_prykey.cat_code = l_rec_category_bkup.cat_code
					LET input_again_flag = FALSE
					EXIT INPUT 
				
				WHEN input_again_flag = TRUE 
						# INPUT AGAIN
			END CASE

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW i135 
	RETURN l_rec_category.*,p_category_prykey.*
 
END FUNCTION  # input_category


####################################################################
# FUNCTION input_category_pricing( p_rec_category )
#
#
####################################################################
FUNCTION input_category_pricing( p_category_prykey) 
	DEFINE p_category_prykey t_category_prykey 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_category_bkup RECORD LIKE category.*    # backup record in case of cancel
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_status INTEGER
	DEFINE input_again_flag BOOLEAN
	DEFINE l_rec_sale_accounts t_rec_sale_accounts  
	DEFINE l_rec_cogs_accounts t_rec_cogs_accounts   
	DEFINE l_rec_int_rev_accts t_rec_int_rev_accts 
	DEFINE l_rec_int_cogs_accts t_rec_int_cogs_accts   


	LET l_rec_category_bkup.* = l_rec_category.* 		# backup the initial record

	OPEN WINDOW i139 with FORM "I139" 
	 CALL windecoration_i("I139") 
	
	CALL category_get_full_record(p_category_prykey.cat_code) RETURNING l_status,l_rec_category.* 
	LET l_rec_category_bkup.* = l_rec_category.*	# save the original, to be restore if int_flag

	DISPLAY BY NAME l_rec_category.cat_code, 
	l_rec_category.desc_text 

	INPUT BY NAME l_rec_category.cost_list_ind, 
		l_rec_category.std_cost_mrkup_per, 
		l_rec_category.price1_ind, 
		l_rec_category.price1_per, 
		l_rec_category.price2_ind, 
		l_rec_category.price2_per, 
		l_rec_category.price3_ind, 
		l_rec_category.price3_per, 
		l_rec_category.price4_ind, 
		l_rec_category.price4_per, 
		l_rec_category.price5_ind, 
		l_rec_category.price5_per, 
		l_rec_category.price6_ind, 
		l_rec_category.price6_per, 
		l_rec_category.price7_ind, 
		l_rec_category.price7_per, 
		l_rec_category.price8_ind, 
		l_rec_category.price8_per, 
		l_rec_category.price9_ind, 
		l_rec_category.price9_per, 
		l_rec_category.oth_cost_fact_per, 
		l_rec_category.def_cost_ind, 
		l_rec_category.rounding_factor, 
		l_rec_category.rounding_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ1","input-category") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD cost_list_ind 
			IF l_rec_category.cost_list_ind = 'L' THEN 
				LET l_msgresp=kandoomsg("I",9202,"") 
				#9202 List price source indicator cannot be a FUNCTION of itself
				NEXT FIELD cost_list_ind 
			END IF 
		AFTER FIELD std_cost_mrkup_per 
			#
			# FUNCTION valid_level() used TO reduce duplication of code
			#
			IF NOT valid_level( l_rec_category.std_cost_mrkup_per,l_rec_category.cost_list_ind ) THEN 
				NEXT FIELD cost_list_ind 
			END IF 

		AFTER FIELD price1_per 
			IF NOT valid_level(l_rec_category.price1_per,l_rec_category.price1_ind) THEN 
				NEXT FIELD price1_ind 
			END IF 

		AFTER FIELD price2_per 
			IF NOT valid_level(l_rec_category.price2_per,l_rec_category.price2_ind) THEN 
				NEXT FIELD price2_ind 
			END IF 

		AFTER FIELD price3_per 
			IF NOT valid_level(l_rec_category.price3_per,l_rec_category.price3_ind) THEN 
				NEXT FIELD price3_ind 
			END IF 

		AFTER FIELD price4_per 
			IF NOT valid_level(l_rec_category.price4_per,l_rec_category.price4_ind) THEN 
				NEXT FIELD price4_ind 
			END IF 

		AFTER FIELD price5_per 
			IF NOT valid_level(l_rec_category.price5_per,l_rec_category.price5_ind) THEN 
				NEXT FIELD price5_ind 
			END IF 

		AFTER FIELD price6_per 
			IF NOT valid_level(l_rec_category.price6_per,l_rec_category.price6_ind) THEN 
				NEXT FIELD price6_ind 
			END IF 

		AFTER FIELD price7_per 
			IF NOT valid_level(l_rec_category.price7_per,l_rec_category.price7_ind) THEN 
				NEXT FIELD price7_ind 
			END IF 

		AFTER FIELD price8_per 
			IF NOT valid_level(l_rec_category.price8_per,l_rec_category.price8_ind) THEN 
				NEXT FIELD price8_ind 
			END IF 

		AFTER FIELD price9_per 
			IF NOT valid_level(l_rec_category.price9_per,l_rec_category.price9_ind) THEN 
				NEXT FIELD price9_ind 
			END IF 

		AFTER FIELD oth_cost_fact_per 
			IF l_rec_category.oth_cost_fact_per IS NULL THEN 
				LET l_rec_category.oth_cost_fact_per = 0 
				DISPLAY BY NAME l_rec_category.oth_cost_fact_per 

			END IF 

		AFTER FIELD rounding_factor 
			IF l_rec_category.rounding_factor IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				# Value must be entered.
				NEXT FIELD rounding_factor 
			END IF 
			IF l_rec_category.rounding_factor < 0.0001 OR l_rec_category.rounding_factor > 1.0 THEN 
				LET l_msgresp = kandoomsg("I",9541,"") 
				#Rounding factor must be between 0.0001 AND 1.
				NEXT FIELD rounding_factor 
			END IF 

		AFTER FIELD rounding_ind 
			IF l_rec_category.rounding_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				# Value must be entered.
				NEXT FIELD rounding_ind 
			END IF 
			IF l_rec_category.rounding_ind NOT matches "[012]" THEN 
				LET l_msgresp = kandoomsg("I",9540,"") 
				# The rounding indicator must be either 0,1 OR 2.
				NEXT FIELD rounding_ind 
			END IF 

		AFTER INPUT 
			CASE
				WHEN NOT (int_flag OR quit_flag OR input_again_flag) # Let us commit input and update data
					LET p_category_prykey.cmpy_code = l_rec_category.cmpy_code
					LET p_category_prykey.cat_code = l_rec_category.cat_code
					CALL update_insert_delete_category_orderaccounts(MODE_CLASSIC_EDIT,p_category_prykey,l_rec_category,l_rec_sale_accounts,l_rec_cogs_accounts,l_rec_int_rev_accts,l_rec_int_cogs_accts)  RETURNING l_status

					IF l_status = 0 THEN
						ERROR "This category has been set up successfully"
					ELSE
						ERROR "An Error occurred while setting up this category"
					END IF
					LET input_again_flag = FALSE
					EXIT INPUT
					
				WHEN (int_flag OR quit_flag	) # Cancel this entry and forget this input
					LET int_flag = false 
					LET quit_flag = false 
					LET l_rec_category.* = l_rec_category_bkup.*
					LET p_category_prykey.cmpy_code = l_rec_category_bkup.cmpy_code
					LET p_category_prykey.cat_code = l_rec_category_bkup.cat_code
					LET input_again_flag = FALSE
					EXIT INPUT 
				
				WHEN input_again_flag = TRUE 
						# INPUT AGAIN
			END CASE

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	CLOSE WINDOW i139 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN l_rec_category_bkup.* 
	ELSE 
		RETURN l_rec_category.* 
	END IF 

END FUNCTION 	# input_category_pricing

####################################################################
# FUNCTION update_insert_delete_category_orderaccounts( p_rec_category )
#
# FIXME: Investigate about p_rec_sale_accounts,p_rec_cogs_accounts,p_rec_int_rev_accts,p_rec_int_cogs_accts to be inbound params here
####################################################################
FUNCTION update_insert_delete_category_orderaccounts(p_mode,p_category_prykey,p_rec_category,p_rec_sale_accounts,p_rec_cogs_accounts,p_rec_int_rev_accts,p_rec_int_cogs_accts) 
	DEFINE p_mode CHAR(5)
	DEFINE p_rec_category RECORD LIKE category.* 
	DEFINE p_category_prykey t_category_prykey
	DEFINE p_rec_orderaccounts RECORD LIKE orderaccounts.* 
	DEFINE p_rec_sale_accounts t_rec_sale_accounts  
	DEFINE p_rec_cogs_accounts t_rec_cogs_accounts   
	DEFINE p_rec_int_rev_accts t_rec_int_rev_accts 
	DEFINE p_rec_int_cogs_accts t_rec_int_cogs_accts   
	DEFINE p_rec_f_sale_accounts t_rec_f_sale_accounts 
	DEFINE p_rec_f_cogs_accounts t_rec_f_cogs_accounts   
	DEFINE p_rec_f_int_rev_accts t_rec_f_int_rev_accts 
	DEFINE p_rec_f_int_cogs_accts t_rec_f_int_cogs_accts
	--DEFINE l_rowid INTEGER 
	DEFINE l_query_text CHAR(100) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_counter SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET p_rec_category.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating database;  Please wait.

	BEGIN WORK
	CASE
		WHEN p_mode = MODE_CLASSIC_EDIT OR p_mode = MODE_CLASSIC_ADD 
			IF p_rec_sale_accounts.def_acct_code IS NOT NULL THEN 
				LET l_err_message = "IZ1 - Updating Order Accounts FOR Sales" 
				LET p_rec_orderaccounts.ref_code = p_rec_category.cat_code 
				LET p_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET p_rec_orderaccounts.table_name = "category" 
				LET p_rec_orderaccounts.column_name = "sale_acct_code" 
				FOR l_counter = 6 TO 9 
					CASE l_counter 
						WHEN "6" 
							LET p_rec_orderaccounts.acct_code = p_rec_sale_accounts.ord6_acct_code 
						WHEN "7" 
							LET p_rec_orderaccounts.acct_code = p_rec_sale_accounts.ord7_acct_code 
						WHEN "8" 
							LET p_rec_orderaccounts.acct_code = p_rec_sale_accounts.ord8_acct_code 
						WHEN "9" 
							LET p_rec_orderaccounts.acct_code = p_rec_sale_accounts.ord9_acct_code 
					END CASE 

					IF p_rec_orderaccounts.acct_code IS NULL THEN 
						CALL p_delete_orderaccounts.Execute(p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_category.cat_code,l_counter,glob_rec_kandoouser.cmpy_code)
						{
						DELETE FROM orderaccounts 
						WHERE table_name = p_rec_orderaccounts.table_name 
						AND column_name = p_rec_orderaccounts.column_name 
						AND ref_code = p_rec_category.cat_code 
						AND ord_ind = l_counter 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						} 
						CONTINUE FOR 
					END IF 

					CALL p_update_orderaccounts.Execute(p_rec_orderaccounts.acct_code,p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
					{
					UPDATE orderaccounts 
					SET acct_code = p_rec_orderaccounts.acct_code 
					WHERE table_name = p_rec_orderaccounts.table_name 
					AND column_name = p_rec_orderaccounts.column_name 
					AND ref_code = p_rec_orderaccounts.ref_code 
					AND ord_ind = l_counter 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
					} 
					IF sqlca.sqlerrd[3] = 0 THEN	# Attempt direct update, if no row updated => insert 
						LET p_rec_orderaccounts.ord_ind = l_counter 
						CALL p_insert_orderaccounts.Execute(p_rec_orderaccounts.*)
						-- INSERT INTO orderaccounts VALUES (p_rec_orderaccounts.*) 
					END IF 
				END FOR 

				LET l_err_message = "IZ1 - Updating Order Accounts FOR COGS" 
				LET p_rec_orderaccounts.ref_code = p_rec_category.cat_code 
				LET p_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET p_rec_orderaccounts.table_name = "category" 
				LET p_rec_orderaccounts.column_name = "cogs_acct_code" 

				FOR l_counter = 6 TO 9 
					CASE l_counter 
						WHEN "6" 
							LET p_rec_orderaccounts.acct_code = p_rec_cogs_accounts.ord6_acct_code 
						WHEN "7" 
							LET p_rec_orderaccounts.acct_code = p_rec_cogs_accounts.ord7_acct_code 
						WHEN "8" 
							LET p_rec_orderaccounts.acct_code = p_rec_cogs_accounts.ord8_acct_code 
						WHEN "9" 
							LET p_rec_orderaccounts.acct_code = p_rec_cogs_accounts.ord9_acct_code 
					END CASE 

					IF p_rec_orderaccounts.acct_code IS NULL THEN
						CALL p_delete_orderaccounts.Execute(p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
						{ 
						DELETE FROM orderaccounts 
						WHERE table_name = p_rec_orderaccounts.table_name 
						AND column_name = p_rec_orderaccounts.column_name 
						AND ref_code = p_rec_orderaccounts.ref_code 
						AND ord_ind = l_counter 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						} 
						CONTINUE FOR 
					END IF 

					CALL p_update_orderaccounts.Execute(p_rec_orderaccounts.acct_code,p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
					{
					UPDATE orderaccounts 
					SET acct_code = p_rec_orderaccounts.acct_code 
					WHERE table_name = p_rec_orderaccounts.table_name 
					AND column_name = p_rec_orderaccounts.column_name 
					AND ref_code = p_rec_orderaccounts.ref_code 
					AND ord_ind = l_counter 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
					} 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET p_rec_orderaccounts.ord_ind = l_counter
						CALL p_insert_orderaccounts.Execute(p_rec_orderaccounts.*) 
						-- INSERT INTO orderaccounts VALUES (p_rec_orderaccounts.*) 
					END IF 
				END FOR 

				LET l_err_message = "IZ1 - Updating Order Accts FOR Internal Revenue" 
				LET p_rec_orderaccounts.ref_code = p_rec_category.cat_code 
				LET p_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET p_rec_orderaccounts.table_name = "category" 
				LET p_rec_orderaccounts.column_name = "int_rev_acct_code" 

				FOR l_counter = 6 TO 9 
					CASE l_counter 
						WHEN "6" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_rev_accts.ord6_acct_code 
						WHEN "7" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_rev_accts.ord7_acct_code 
						WHEN "8" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_rev_accts.ord8_acct_code 
						WHEN "9" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_rev_accts.ord9_acct_code 
					END CASE 
					IF p_rec_orderaccounts.acct_code IS NULL THEN 
						CALL p_delete_orderaccounts.Execute(p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
						{
						DELETE FROM orderaccounts 
						WHERE table_name = p_rec_orderaccounts.table_name 
						AND column_name = p_rec_orderaccounts.column_name 
						AND ref_code = p_rec_orderaccounts.ref_code 
						AND ord_ind = l_counter 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						} 
						CONTINUE FOR 
					END IF 
					CALL p_update_orderaccounts.Execute(p_rec_orderaccounts.acct_code,p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
					{
					UPDATE orderaccounts 
					SET acct_code = p_rec_orderaccounts.acct_code 
					WHERE table_name = p_rec_orderaccounts.table_name 
					AND column_name = p_rec_orderaccounts.column_name 
					AND ref_code = p_rec_orderaccounts.ref_code 
					AND ord_ind = l_counter 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
					} 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET p_rec_orderaccounts.ord_ind = l_counter
						CALL p_insert_orderaccounts.Execute(p_rec_orderaccounts.*) 
						-- INSERT INTO orderaccounts VALUES (p_rec_orderaccounts.*) 
					END IF 
				END FOR 

				LET l_err_message = "IZ1 - Updating Order Accts FOR Internal COGS" 
				LET p_rec_orderaccounts.ref_code = p_rec_category.cat_code 
				LET p_rec_orderaccounts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET p_rec_orderaccounts.table_name = "category" 
				LET p_rec_orderaccounts.column_name = "int_cogs_acct_code" 

				FOR l_counter = 6 TO 9 
					CASE l_counter 
						WHEN "6" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_cogs_accts.ord6_acct_code 
						WHEN "7" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_cogs_accts.ord7_acct_code 
						WHEN "8" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_cogs_accts.ord8_acct_code 
						WHEN "9" 
							LET p_rec_orderaccounts.acct_code = p_rec_int_cogs_accts.ord9_acct_code 
					END CASE 
					IF p_rec_orderaccounts.acct_code IS NULL THEN
						CALL p_delete_orderaccounts.Execute(p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code) 
						{
						DELETE FROM orderaccounts 
						WHERE table_name = p_rec_orderaccounts.table_name 
						AND column_name = p_rec_orderaccounts.column_name 
						AND ref_code = p_rec_orderaccounts.ref_code 
						AND ord_ind = l_counter 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						} 
						CONTINUE FOR 
					END IF 
					CALL p_update_orderaccounts.Execute(p_rec_orderaccounts.acct_code,p_rec_orderaccounts.table_name,p_rec_orderaccounts.column_name,p_rec_orderaccounts.ref_code,l_counter,glob_rec_kandoouser.cmpy_code)
					{
					UPDATE orderaccounts 
					SET acct_code = p_rec_orderaccounts.acct_code 
					WHERE table_name = p_rec_orderaccounts.table_name 
					AND column_name = p_rec_orderaccounts.column_name 
					AND ref_code = p_rec_orderaccounts.ref_code 
					AND ord_ind = l_counter 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
					} 
					IF sqlca.sqlerrd[3] = 0 THEN 
						LET p_rec_orderaccounts.ord_ind = l_counter 
						INSERT INTO orderaccounts VALUES (p_rec_orderaccounts.*) 
					END IF 
				END FOR 
			END IF 
			CASE
				WHEN p_mode = MODE_CLASSIC_EDIT
					LET l_err_message = "IZ1 - Error Updating Category ",p_rec_category.cat_code 
					CALL p_update_category.Execute(p_rec_category.*,p_category_prykey.cmpy_code,p_category_prykey.cat_code)
					IF sqlca.sqlcode = 0 THEN 
						ERROR "Category has been updated successfully!"
						COMMIT WORK
					ELSE
						ERROR "Category update FAILED with ERROR!"
						ROLLBACK WORK
					END IF
				WHEN p_mode = MODE_CLASSIC_ADD
					CALL p_insert_category.Execute(p_rec_category.*)
					IF sqlca.sqlcode = 0 THEN 
						ERROR "Category has been inserted successfully!"
						COMMIT WORK
					ELSE
						ERROR "Category insert FAILED with ERROR!"
						ROLLBACK WORK
					END IF
			END CASE 

		WHEN p_mode = "SUPPR"
			CALL p_delete_category.Execute(p_category_prykey.cmpy_code,p_category_prykey.cat_code)
			IF sqlca.sqlcode = -692  THEN		# the category is already used, Cancel deletion
				ROLLBACK WORK
				# 7029 Product category assigned TO a product. No Deletion
			ELSE
				-- CALL p_delete_orderaccounts.Execute(l_rec_orderaccounts.table_name,p_category_prykey.cmpy_code,p_category_prykey.cat_code)
				CALL p_delete_orderaccounts.Execute("category",p_category_prykey.cmpy_code,p_category_prykey.cat_code)
				IF sqlca.sqlcode = 0 THEN
					ERROR "Category deleted successfully"
					COMMIT WORK
				ELSE   
					ERROR "Category delete FAILED!"
					ROLLBACK WORK
				END IF
			END IF 
	END CASE

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	RETURN sqlca.sqlcode,p_category_prykey.* 
END FUNCTION 	#  update_insert_delete_category_orderaccounts

FUNCTION prepare_cursors_IZ1()
	DEFINE l_query_stmt STRING
	IF p_insert_category.GetName() IS NULL THEN
		# cursors and prepared have not been done, we do them ONCE
			# prepare insert, delete and update statements
			LET l_query_stmt = "DELETE FROM orderaccounts ",
			" WHERE table_name = ?",
			" AND column_name = ? ",
			" AND ref_code = ? ",
			" AND ord_ind = ? ",
			" AND cmpy_code = ?"
			CALL p_delete_orderaccounts.Prepare(l_query_stmt)
		
			LET l_query_stmt = "UPDATE orderaccounts ",
			" SET acct_code = ? ",
			" WHERE table_name = ? " ,
			" AND column_name = ? ",
			" AND ref_code = ? ", 
			" AND ord_ind = ? ",
			" AND cmpy_code = ? "
			CALL p_update_orderaccounts.Prepare(l_query_stmt)
		
			LET l_query_stmt = "INSERT INTO orderaccounts VALUES (?,?,?,?,?,?) "
			CALL p_insert_orderaccounts.Prepare(l_query_stmt)
			
			LET l_query_stmt = "DELETE FROM orderaccounts ",
			" WHERE table_name = ? ", 
			" AND cmpy_code = ? ",
			" AND ref_code =  ? " 
			CALL p_delete_orderaccounts.Prepare(l_query_stmt)
		
			LET l_query_stmt = " UPDATE category SET * = (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ",
			" WHERE cmpy_code = ? ",
			" AND cat_code = ? "
			CALL p_update_category.Prepare(l_query_stmt)
		
			LET l_query_stmt = " INSERT INTO category VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? )"
			CALL p_insert_category.Prepare(l_query_stmt)
			
			LET l_query_stmt = "DELETE FROM category ", 
			" WHERE cmpy_code = ? ",
			" AND cat_code = ? "
			CALL p_delete_category.Prepare(l_query_stmt)
	END IF
END FUNCTION # prepare_cursors_IZ1()
####################################################################
# FUNCTION valid_level( p_price_per, p_price_ind )
#
#
# valid_level() ensures that either  - both type & markup are NOT entered
#                                OR  - both type & markup are entered
#
#
####################################################################
FUNCTION valid_level( p_price_per, p_price_ind ) 
	DEFINE p_price_per LIKE category.price1_per 
	DEFINE p_price_ind LIKE category.price1_ind 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF ( p_price_per IS NULL AND p_price_ind IS NOT NULL ) 
	OR ( p_price_ind IS NULL AND p_price_per IS NOT NULL ) THEN 
		LET l_msgresp=kandoomsg("I",9207,"") 
		#9207 Source indicator AND markup must both be entered
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 

####################################################################
# FUNCTION scan_cat() FUNCTION IS DEPRECATED, replaced by construct_dataset_categor
#
####################################################################
{
FUNCTION scan_cat() 
	DEFINE l_rec_orderaccounts RECORD LIKE orderaccounts.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_arr_rec_category DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cat_code LIKE category.cat_code, 
		desc_text LIKE category.desc_text, 
		sale_acct_code LIKE category.sale_acct_code 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_rowid INTEGER 
	DEFINE l_arr_curr SMALLINT --scrn, 
	DEFINE l_arr_count SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 

	DEFINE l_msgresp LIKE language.yes_flag 
	
	   LET l_idx = 0
	   FOREACH c_category INTO l_rec_category.*
	      LET l_idx = l_idx + 1
	      LET l_arr_rec_category[l_idx].scroll_flag    = NULL
	      LET l_arr_rec_category[l_idx].cat_code       = l_rec_category.cat_code
	      LET l_arr_rec_category[l_idx].desc_text      = l_rec_category.desc_text
	      LET l_arr_rec_category[l_idx].sale_acct_code = l_rec_category.sale_acct_code
	      IF l_idx = 300 THEN
	         LET l_msgresp=kandoomsg("U",6100,l_idx)
	         EXIT FOREACH
	      END IF
	   END FOREACH

	   LET l_msgresp = kandoomsg("U",9113,l_idx)
	   IF l_idx = 0 THEN
	      LET l_idx = 1
	      INITIALIZE l_arr_rec_category[l_idx].* TO NULL
	   END IF

	#   OPTIONS INSERT KEY F1,
	#           DELETE KEY F36

	   CALL set_count(l_idx)
	   LET l_msgresp = kandoomsg("I",1003,"")
	# "F1 TO add, RETURN on line TO change, F2 TO delete"
	

	CALL whs_category_get_datasource(false) RETURNING l_arr_rec_category 

	DISPLAY ARRAY l_arr_rec_category TO sr_category.* 
		BEFORE DISPLAY 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL publish_toolbar("kandoo","IZ1","disp-arr-category") 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_arr_curr = arr_curr() 


			--			ON ACTION "FILTER_old"
			--				RETURN TRUE

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_category.clear() 
			CALL whs_category_get_datasource(true) RETURNING l_arr_rec_category 

		ON ACTION "REFRESH" 
			 CALL windecoration_i("I136") 
			CALL l_arr_rec_category.clear() 
			CALL whs_category_get_datasource(false) RETURNING l_arr_rec_category 

		ON ACTION ("ACCEPT",MODE_CLASSIC_EDIT) 
			#BEFORE FIELD cat_code
			IF l_arr_rec_category[l_idx].cat_code IS NOT NULL THEN 

				OPEN WINDOW i135 with FORM "I135" 
				 CALL windecoration_i("I135") 

				LET l_msgresp = kandoomsg("U",1001,"") 
				CALL category_get_full_record(l_arr_rec_category[l_idx].cat_code) RETURNING l_rec_category.* 
				#            SELECT * INTO l_rec_category.*
				#              FROM category
				#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#               AND cat_code  = l_arr_rec_category[l_idx].cat_code
				WHILE input_category() 


					#      BEFORE FIELD cat_code
					#         IF l_arr_rec_category[l_idx].cat_code IS NOT NULL THEN
					#
					#            OPEN WINDOW I135 WITH FORM "I135"
					#         		 CALL windecoration_i("I135")
					#
					#            LET l_msgresp = kandoomsg("U",1001,"")
					#            SELECT * INTO l_rec_category.*
					#              FROM category
					#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					#               AND cat_code  = l_arr_rec_category[l_idx].cat_code
					#            WHILE input_category()
					#

					--------------------------------------------------------------------------------
					MENU " Category" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","IZ1","menu-category") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 


						ON ACTION "Save" 
							#COMMAND "Save" " Save category TO database"
							--LET l_rowid = update_insert_delete_category_orderaccounts(l_rec_category.*) 
							EXIT MENU 

						ON ACTION "Pricing" 
							#COMMAND "Pricing" " Enter category pricing details"
							CALL input_category_pricing(l_rec_category.*) 
							RETURNING l_rec_category.* 
							NEXT option "Save" 

						ON ACTION "Exit" 
							#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
							LET quit_flag = true 
							EXIT MENU 

						COMMAND KEY (control-w) 
							CALL kandoohelp("") 

					END MENU 
					-------------------------------------------------------------------

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
					ELSE 
						EXIT WHILE 
					END IF 
				END WHILE 
				---------------------------------------------------

				CLOSE WINDOW i135 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 

				SELECT * INTO l_rec_category.* 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_arr_rec_category[l_idx].cat_code 
				LET l_arr_rec_category[l_idx].cat_code = l_rec_category.cat_code 
				LET l_arr_rec_category[l_idx].desc_text = l_rec_category.desc_text 
				LET l_arr_rec_category[l_idx].sale_acct_code = l_rec_category.sale_acct_code 
			END IF 
			# NEXT FIELD scroll_flag

			CALL l_arr_rec_category.clear() 
			CALL whs_category_get_datasource(false) RETURNING l_arr_rec_category 

		ON ACTION "Add" 
			LET l_rowid = 0 

			OPEN WINDOW i135 with FORM "I135" 
			 CALL windecoration_i("I135") 

			LET l_msgresp = kandoomsg("U",1001,"") 

			INITIALIZE l_rec_category.* TO NULL 

			WHILE input_category() 


				#      BEFORE INSERT
				#         #IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN
				#         #   CLEAR sr_category[scrn].*
				#         #   NEXT FIELD scroll_flag #informix bug
				#         #END IF
				#         LET l_rowid = 0
				#
				#         OPEN WINDOW I135 WITH FORM "I135"
				#					 CALL windecoration_i("I135")
				#
				#         LET l_msgresp = kandoomsg("U",1001,"")
				#
				#         INITIALIZE l_rec_category.* TO NULL
				#
				#         WHILE input_category()

				#            OPEN WINDOW w1 AT 13,24 with 2 rows,40 columns
				#               ATTRIBUTE(border)


				-----------------------------------------------------------------
				MENU " Category" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","IZ1","menu-category2") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					ON ACTION "Save" 
						#COMMAND "Save" " Save category TO database"
						--LET l_rowid = update_insert_delete_category_orderaccounts(l_rec_category.*) 
						EXIT MENU 

					ON ACTION "Pricing" 
						#COMMAND "Pricing" " Enter category pricing details"
						CALL input_category_pricing(l_rec_category.*) 
						RETURNING l_rec_category.* 
						NEXT option "Save" 

					ON ACTION "Exit" 
						#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO previous SCREEN"
						LET quit_flag = true 
						EXIT MENU 

					COMMAND KEY (control-w) 
						CALL kandoohelp("") 

				END MENU 
				---------------------------------------------------

				#            CLOSE WINDOW w1

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			----------------------------------------

			CLOSE WINDOW i135 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF l_rowid THEN 
				SELECT * INTO l_rec_category.* 
				FROM category 
				WHERE rowid = l_rowid 
				LET l_arr_rec_category[l_idx].cat_code = l_rec_category.cat_code 
				LET l_arr_rec_category[l_idx].desc_text = l_rec_category.desc_text 
				LET l_arr_rec_category[l_idx].sale_acct_code = l_rec_category.sale_acct_code 
			ELSE 
				# Informix Bug - the arr_count() becomes 100 AFTER coming out of
				#     a control-b FUNCTION in input_category causing the
				#     program TO crash AND it needs TO use I136 arr_curr
				#     rather than control-b (G123) arr_curr()

				FOR l_idx = l_arr_curr TO l_arr_count 
					LET l_arr_rec_category[l_idx].* = l_arr_rec_category[l_idx+1].* 
					#IF scrn <= 14 THEN
					#   DISPLAY l_arr_rec_category[l_idx].*
					#        TO sr_category[scrn].*
					#
					#   LET scrn = scrn + 1
					#END IF
				END FOR 

				INITIALIZE l_arr_rec_category[l_idx].* TO NULL 
			END IF 
			#NEXT FIELD scroll_flag
			CALL l_arr_rec_category.clear() 
			CALL whs_category_get_datasource(false) RETURNING l_arr_rec_category 


		ON ACTION DELETE 
			IF l_arr_rec_category[l_idx].cat_code IS NOT NULL THEN 
				#check IF products with this category exist
				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_arr_rec_category[l_idx].cat_code 

				IF sqlca.sqlcode = NOTFOUND THEN 


					LET l_del_cnt = 1 
					LET l_msgresp = kandoomsg("I",8005,l_del_cnt) 
					#8005 Confirm TO Delete ",l_del_cnt," category(s)? (Y/N)"
					IF l_msgresp = "Y" THEN 

						GOTO bypass 
						LABEL recovery: 

						IF error_recover(l_err_message, status) != "Y" THEN 
							RETURN 
						END IF 

						LABEL bypass: 
						WHENEVER ERROR GOTO recovery 

						BEGIN WORK 

							LET l_rec_orderaccounts.table_name = "category" 
							LET l_msgresp = kandoomsg("U",1005,"") 
							#1005 Updating Database;  Please wait.

							#FOR l_idx = 1 TO arr_count()
							#IF l_arr_rec_category[l_idx].scroll_flag = "*" THEN
							SELECT unique 1 
							FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cat_code = l_arr_rec_category[l_idx].cat_code 

							IF sqlca.sqlcode = NOTFOUND THEN 
								DELETE FROM category 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cat_code = l_arr_rec_category[l_idx].cat_code 
								DELETE FROM orderaccounts 
								WHERE table_name = l_rec_orderaccounts.table_name 
								AND ref_code = l_arr_rec_category[l_idx].cat_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							ELSE 
								LET l_msgresp = kandoomsg("I",7029,l_arr_rec_category[l_idx].desc_text) 
								# 7029 Product category assigned TO a product. No Deletion
							END IF 

							#END IF
							#END FOR

						COMMIT WORK 

						WHENEVER ERROR stop 
					END IF 
				END IF 

			ELSE 
				LET l_msgresp = kandoomsg("I",7029,l_arr_rec_category[l_idx].desc_text) 
				# 7029 Product category assigned TO a product. No Deletion
				LET l_arr_rec_category[l_idx].scroll_flag = NULL 
			END IF 

			CALL l_arr_rec_category.clear() 
			CALL whs_category_get_datasource(false) RETURNING l_arr_rec_category 
			#           END IF



			#      ON KEY(F2)	--DELETE / Set delete marker *
			#         IF l_arr_rec_category[l_idx].cat_code IS NOT NULL THEN
			#            IF l_arr_rec_category[l_idx].scroll_flag IS NULL THEN
			#            		#check IF products with this category exist
			#               SELECT unique 1
			#                 FROM product
			#                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                  AND cat_code = l_arr_rec_category[l_idx].cat_code
			#               IF sqlca.sqlcode = NOTFOUND THEN
			#                  LET l_arr_rec_category[l_idx].scroll_flag = "*"
			#                  LET l_del_cnt = l_del_cnt + 1
			#               ELSE
			#                  LET l_msgresp = kandoomsg("I",7029,l_arr_rec_category[l_idx].desc_text)
			#                  # 7029 Product category assigned TO a product. No Deletion
			#                  LET l_arr_rec_category[l_idx].scroll_flag = NULL
			#                  LET l_del_cnt = l_del_cnt - 1
			#                  IF l_del_cnt < 0 THEN
			#                     LET l_del_cnt = 0
			#                  END IF
			#               END IF
			#            ELSE
			#               IF l_arr_rec_category[l_idx].scroll_flag = "*" THEN
			#                  LET l_arr_rec_category[l_idx].scroll_flag = NULL
			#                  LET l_del_cnt = l_del_cnt - 1
			#               END IF
			#            END IF
			#         END IF
			#
			#         NEXT FIELD scroll_flag

			#AFTER ROW
			#    DISPLAY l_arr_rec_category[l_idx].*
			#         TO sr_category[scrn].*

			--      ON KEY (control-w)
			--         CALL kandoohelp("")

	END DISPLAY 
	--------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
		#   ELSE
		#      IF l_del_cnt > 0 THEN
		#         LET l_msgresp = kandoomsg("I",8005,l_del_cnt)
		#         #8005 Confirm TO Delete ",l_del_cnt," category(s)? (Y/N)"
		#         IF l_msgresp = "Y" THEN
		#            GOTO bypass
		#            label recovery:
		#               IF error_recover(l_err_message, STATUS) != "Y" THEN
		#                  RETURN
		#               END IF
		#            label bypass:
		#            WHENEVER ERROR GOTO recovery
		#
		#            BEGIN WORK
		#            LET l_rec_orderaccounts.table_name = "category"
		#            LET l_msgresp = kandoomsg("U",1005,"")
		#            #1005 Updating Database;  Please wait.
		#
		#            FOR l_idx = 1 TO arr_count()
		#               IF l_arr_rec_category[l_idx].scroll_flag = "*" THEN
		#                  SELECT unique 1
		#                    FROM product
		#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                     AND cat_code = l_arr_rec_category[l_idx].cat_code
		#                  IF sqlca.sqlcode = NOTFOUND THEN
		#                     DELETE FROM category
		#                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                        AND cat_code = l_arr_rec_category[l_idx].cat_code
		#                     DELETE FROM orderaccounts
		#                      WHERE table_name = l_rec_orderaccounts.table_name
		#                        AND ref_code = l_arr_rec_category[l_idx].cat_code
		#                        AND cmpy_code = glob_rec_kandoouser.cmpy_code
		#                  ELSE
		#                     LET l_msgresp = kandoomsg("I",7029,l_arr_rec_category[l_idx].desc_text)
		#                     # 7029 Product category assigned TO a product. No Deletion
		#                  END IF
		#               END IF
		#            END FOR
		#            COMMIT WORK
		#
		#            WHENEVER ERROR STOP
		#         END IF
		#      END IF

	END IF 
END FUNCTION 	# scan_cat
}

