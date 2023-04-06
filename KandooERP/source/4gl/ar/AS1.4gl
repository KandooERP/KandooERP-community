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
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_inv_text NCHAR(400) #where selector for invoice
--DEFINE modu_cred_text NCHAR(400) #where selector for credit
#########################################################################
# FUNCTION AS1_main()
#
# \brief module AS1 - Print invoices / credit notes
#########################################################################
FUNCTION AS1_main()
	DEFINE l_where_text STRING
	DEFINE l_inv_text NCHAR(400) #where selector for invoice
	DEFINE l_cred_text NCHAR(400) #where selector for credit

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CALL setModuleId("AS1") 

	#---------------------------------------------------------------
	#Read Arguments if we have received invoice or credit note code
	#This would bypass the user query construct	 
	LET l_inv_text = get_url_invoice_text() 
	LET l_cred_text = get_url_credit_text() 

	IF (l_inv_text IS NOT null) OR (l_cred_text IS NOT null) THEN #if at least one arg IS specified 
		#You can only have a credit or invoice selector, not both 
		IF l_inv_text IS NOT NULL THEN 
			LET l_cred_text = NULL

			CALL set_url_credit_text(NULL)

			LET l_where_text = " AND invoicehead.inv_num = ", trim(l_inv_text), " "
			LET glob_rec_rpt_selector.ref1_text = l_inv_text					 
		END IF 

		IF l_cred_text IS NOT NULL THEN 
			LET l_inv_text = NULL

			CALL set_url_invoice_text(NULL) 

			LET l_where_text = " AND credithead.cred_num = ", trim(l_cred_text), " "
			LET glob_rec_rpt_selector.ref2_text = l_cred_text 
		END IF 

		CALL AS1_rpt_process_invoice_credit(l_where_text)
--		IF --AS1_rpt_process_invoice_credit(l_where_text) = TRUE THEN --print invoice
--			MESSAGE "Generated Invoice:",  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].file_text 
--			SLEEP 2
--			EXIT PROGRAM
--		ELSE
--			ERROR "Could not generate Invoice: ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS1_rpt_list_invoice_credit")].file_text 
--			EXIT PROGRAM 
--		END IF 
	--      IF (l_inv_text IS NOT NULL OR length(l_inv_text) > 0)
	--      OR (l_cred_text IS NOT NULL OR length(l_cred_text) > 0) THEN
	--         IF l_inv_text IS NOT NULL OR length(l_inv_text) > 0 THEN
	--            LET l_cred_text = NULL
	--         END IF
	--         IF l_cred_text IS NOT NULL OR length(l_cred_text) > 0 THEN
	--            LET l_inv_text = NULL
	--         END IF
	--         LET glob_rec_rmsreps.file_text =
	--             --AS1_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_inv_text,l_cred_text,FALSE,l_printer)  --PRINT invoice
	--         EXIT PROGRAM
	--      END IF
	--   END IF

	ELSE #NO invoice or credit_text URL arguments ->specify report criteria via user interaction
	
		OPEN WINDOW A635 with FORM "A635" 
		CALL windecoration_a("A635") 
	
		MENU " Document Print" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","AS1","menu-document-PRINT") 
				IF NOT AS1_rpt_process_invoice_credit(AS1_rpt_query()) THEN
					EXIT PROGRAM
				END IF
				
				CALL rpt_rmsreps_reset(NULL)
				{
				CALL AS1_rpt_query() RETURNING l_inv_text,l_cred_text
				IF (l_inv_text IS NOT NULL AND l_cred_text IS NOT NULL) AND int_flag = FALSE THEN  
					# may no longer required --LET l_printer = get_print(glob_rec_kandoouser.cmpy_code, l_printer)
					--CALL AS1_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_inv_text,l_cred_text,FALSE,l_printer) --print invoice 
				END IF 
	}
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "Run Report" #COMMAND "Run Report" " Generate documents FOR printing"
				CALL AS1_rpt_process_invoice_credit(AS1_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
				{
				CALL AS1_rpt_query() RETURNING l_inv_text,l_cred_text
				IF (l_inv_text IS NOT NULL AND l_cred_text IS NOT NULL) AND int_flag = FALSE THEN  
					# may no longer required --LET l_printer = get_print(glob_rec_kandoouser.cmpy_code, l_printer)
					--CALL AS1_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_inv_text,l_cred_text,FALSE,l_printer) --print invoice 
				END IF 
				}
			ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
		
			ON ACTION "Exit" #COMMAND "Exit" " Exit TO menus"
				EXIT MENU 
	
		END MENU 
	
		CLOSE WINDOW A635
	END IF 
END FUNCTION 
#########################################################################
# END FUNCTION AS1_main()
#########################################################################


#########################################################################
# FUNCTION AS1_rpt_query()
#
#
#########################################################################
FUNCTION AS1_rpt_query() 
	DEFINE l_where_text STRING #joined where selectors for invoice AND credit
	DEFINE l_inv_text STRING #where selector for invoice
	DEFINE l_cred_text STRING #where selector for credit
	DEFINE l_rec_select RECORD 
		inv_flag NCHAR(1), 
		inv_start_num LIKE invoicehead.inv_num, 
		inv_last_num LIKE invoicehead.inv_num, 
		inv_start_date LIKE invoicehead.inv_date, 
		inv_last_date LIKE invoicehead.inv_date, 
		inv_start_cust LIKE invoicehead.cust_code, 
		inv_last_cust LIKE invoicehead.cust_code, 
		inv_prev_prnt_ind CHAR(1), 
		inv_ind LIKE invoicehead.inv_ind, 
		cred_flag CHAR(1), 
		cred_start_num LIKE credithead.cred_num, 
		cred_last_num LIKE credithead.cred_num, 
		cred_start_date LIKE credithead.cred_date, 
		cred_last_date LIKE credithead.cred_date, 
		cred_start_cust LIKE credithead.cust_code, 
		cred_last_cust LIKE credithead.cust_code, 
		cred_prev_prnt_ind CHAR(1), 
		cred_ind LIKE credithead.cred_ind 
	END RECORD 

	CLEAR FORM 

	LET l_rec_select.inv_flag = "N" 
	LET l_rec_select.inv_start_num = NULL 
	LET l_rec_select.inv_last_num = NULL 
	LET l_rec_select.inv_start_date = NULL 
	LET l_rec_select.inv_last_date = NULL 
	LET l_rec_select.inv_start_cust = NULL 
	LET l_rec_select.inv_last_cust = NULL 
	LET l_rec_select.inv_prev_prnt_ind = "N" #NULL 
	LET l_rec_select.inv_ind = NULL 
	LET l_rec_select.cred_flag = "N" 
	LET l_rec_select.cred_start_num = NULL 
	LET l_rec_select.cred_last_num = NULL 
	LET l_rec_select.cred_start_date = NULL 
	LET l_rec_select.cred_last_date = NULL 
	LET l_rec_select.cred_start_cust = NULL 
	LET l_rec_select.cred_last_cust = NULL 
	LET l_rec_select.cred_prev_prnt_ind = "N" #NULL 
	LET l_rec_select.cred_ind = NULL 

	INPUT BY NAME l_rec_select.* WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AS1","inp-SELECT") 

			IF l_rec_select.inv_flag IS NULL AND l_rec_select.cred_flag IS NULL THEN  #set default
				LET l_rec_select.inv_flag = "Y"
			END IF
			#Invoice Flag inv_flag
			IF l_rec_select.inv_flag = "Y" THEN
				CALL DIALOG.SetFieldActive("inv_start_num", TRUE)
				CALL DIALOG.SetFieldActive("inv_start_date", TRUE)
				CALL DIALOG.SetFieldActive("inv_start_cust", TRUE)
				CALL DIALOG.SetFieldActive("inv_prev_prnt_ind", TRUE)
				CALL DIALOG.SetFieldActive("inv_ind", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_num", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_date", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_cust", TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("inv_start_num", FALSE)
				CALL DIALOG.SetFieldActive("inv_start_date", FALSE)
				CALL DIALOG.SetFieldActive("inv_start_cust", FALSE)
				CALL DIALOG.SetFieldActive("inv_prev_prnt_ind", FALSE)
				CALL DIALOG.SetFieldActive("inv_ind", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_num", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_date", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_cust", FALSE)			
			END IF
			#Credit Flag cred_flag
			IF l_rec_select.cred_flag = "Y" THEN
				CALL DIALOG.SetFieldActive("cred_start_num", TRUE)
				CALL DIALOG.SetFieldActive("cred_start_date", TRUE)
				CALL DIALOG.SetFieldActive("cred_start_cust", TRUE)
				CALL DIALOG.SetFieldActive("cred_prev_prnt_ind", TRUE)
				CALL DIALOG.SetFieldActive("cred_ind", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_num", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_date", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_cust", TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("cred_start_num", FALSE)
				CALL DIALOG.SetFieldActive("cred_start_date", FALSE)
				CALL DIALOG.SetFieldActive("cred_start_cust", FALSE)
				CALL DIALOG.SetFieldActive("cred_prev_prnt_ind", FALSE)
				CALL DIALOG.SetFieldActive("cred_ind", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_num", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_date", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_cust", FALSE)			
			END IF							
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON CHANGE inv_flag 
			IF l_rec_select.inv_flag = "Y" THEN
				CALL DIALOG.SetFieldActive("inv_start_num", TRUE)
				CALL DIALOG.SetFieldActive("inv_start_date", TRUE)
				CALL DIALOG.SetFieldActive("inv_start_cust", TRUE)
				CALL DIALOG.SetFieldActive("inv_prev_prnt_ind", TRUE)
				CALL DIALOG.SetFieldActive("inv_ind", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_num", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_date", TRUE)
				CALL DIALOG.SetFieldActive("inv_last_cust", TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("inv_start_num", FALSE)
				CALL DIALOG.SetFieldActive("inv_start_date", FALSE)
				CALL DIALOG.SetFieldActive("inv_start_cust", FALSE)
				CALL DIALOG.SetFieldActive("inv_prev_prnt_ind", FALSE)
				CALL DIALOG.SetFieldActive("inv_ind", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_num", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_date", FALSE)
				CALL DIALOG.SetFieldActive("inv_last_cust", FALSE)			
			END IF
							 
--				NEXT FIELD NEXT 
--			ELSE 
--				NEXT FIELD cred_flag 
--			END IF 

		ON CHANGE cred_flag
			IF l_rec_select.cred_flag = "Y" THEN
				CALL DIALOG.SetFieldActive("cred_start_num", TRUE)
				CALL DIALOG.SetFieldActive("cred_start_date", TRUE)
				CALL DIALOG.SetFieldActive("cred_start_cust", TRUE)
				CALL DIALOG.SetFieldActive("cred_prev_prnt_ind", TRUE)
				CALL DIALOG.SetFieldActive("cred_ind", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_num", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_date", TRUE)
				CALL DIALOG.SetFieldActive("cred_last_cust", TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("cred_start_num", FALSE)
				CALL DIALOG.SetFieldActive("cred_start_date", FALSE)
				CALL DIALOG.SetFieldActive("cred_start_cust", FALSE)
				CALL DIALOG.SetFieldActive("cred_prev_prnt_ind", FALSE)
				CALL DIALOG.SetFieldActive("cred_ind", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_num", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_date", FALSE)
				CALL DIALOG.SetFieldActive("cred_last_cust", FALSE)			
			END IF		 
--			IF fgl_lastkey() = fgl_keyval("up") 
--			OR fgl_lastkey() = fgl_keyval("left") THEN 
--				IF l_rec_select.inv_flag = "Y" THEN 
--					NEXT FIELD previous 
--				ELSE 
--					NEXT FIELD inv_flag 
--				END IF 
--			END IF 

		BEFORE FIELD cred_start_num 
			IF l_rec_select.cred_flag = "N" THEN 
				NEXT FIELD previous 
			END IF 

		AFTER FIELD inv_start_num
			IF l_rec_select.inv_start_num IS NOT NULL AND l_rec_select.inv_start_num != 0 THEN
				IF l_rec_select.inv_last_num IS NOT NULL AND l_rec_select.inv_last_num != 0 THEN
					IF l_rec_select.inv_last_num < l_rec_select.inv_start_num THEN
						LET l_rec_select.inv_last_num = l_rec_select.inv_start_num
					END IF
				ELSE
					LET l_rec_select.inv_last_num = l_rec_select.inv_start_num
				END IF
			ELSE
				IF l_rec_select.inv_last_num IS NOT NULL AND l_rec_select.inv_last_num != 0 THEN
					LET l_rec_select.inv_last_num = NULL
				END IF
			END IF

		AFTER FIELD inv_last_num
			IF l_rec_select.inv_last_num IS NOT NULL AND l_rec_select.inv_last_num != 0 THEN
				IF l_rec_select.inv_start_num IS NOT NULL AND l_rec_select.inv_start_num != 0 THEN
					IF l_rec_select.inv_start_num > l_rec_select.inv_last_num THEN
						LET l_rec_select.inv_start_num = l_rec_select.inv_last_num
					END IF
				ELSE
					LET l_rec_select.inv_start_num = l_rec_select.inv_last_num
				END IF
			ELSE
				--IF l_rec_select.inv_start_num IS NOT NULL AND l_rec_select.inv_start_num != 0 THEN
				--	LET l_rec_select.inv_last_num = l_rec_select.inv_start_num
				--END IF
			END IF


		AFTER INPUT
			IF NOT int_flag THEN 
				IF l_rec_select.inv_flag  IS NULL THEN
					LET l_rec_select.inv_flag = "N"
				END IF
	
				IF l_rec_select.cred_flag  IS NULL THEN
					LET l_rec_select.cred_flag = "N"
				END IF
				
				IF l_rec_select.cred_flag = "N" AND l_rec_select.inv_flag = "N" THEN
					ERROR "You need to select either Print Invoices or Credits or both"
					CONTINUE INPUT
				END IF 
				
				IF l_rec_select.inv_start_num > l_rec_select.inv_last_num THEN 
					MESSAGE kandoomsg2("E",9176,"")		#9176 Beginning document IS greater than ending document
					NEXT FIELD inv_start_num 
				END IF 
	
				IF l_rec_select.cred_start_num > l_rec_select.cred_last_num THEN 
					MESSAGE kandoomsg2("E",9176,"")			#9176 Beginning document IS greater than ending document
					NEXT FIELD cred_start_num 
				END IF 
		END IF
	END INPUT 
	#-----------------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		LET l_inv_text = NULL 
		IF l_rec_select.inv_flag = "Y" THEN 
			LET l_inv_text = "1=1" 
			IF l_rec_select.inv_start_num IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ", "AND invoicehead.inv_num>='", l_rec_select.inv_start_num USING "&<<<<<<<","'" 
			END IF
			 
			IF l_rec_select.inv_last_num IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ", "AND invoicehead.inv_num<='", l_rec_select.inv_last_num USING "&<<<<<<<","'" 
			END IF
			 
			IF l_rec_select.inv_start_cust IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ", "AND invoicehead.cust_code>='",l_rec_select.inv_start_cust,"'" 
			END IF
			 
			IF l_rec_select.inv_last_cust IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ", "AND invoicehead.cust_code<='",l_rec_select.inv_last_cust,"'" 
			END IF 
			
			IF l_rec_select.inv_start_date IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ","AND invoicehead.inv_date>='",l_rec_select.inv_start_date,"'" 
			END IF 
			
			IF l_rec_select.inv_last_date IS NOT NULL THEN 
				LET l_inv_text = 	l_inv_text clipped," ", "AND invoicehead.inv_date<='",l_rec_select.inv_last_date,"'" 
			END IF 
			
			IF l_rec_select.inv_prev_prnt_ind = "N" THEN 
				LET l_inv_text = l_inv_text clipped," AND invoicehead.printed_num <= 1" 
			END IF 
			
			IF l_rec_select.inv_ind IS NOT NULL THEN 
				LET l_inv_text = l_inv_text clipped," ", "AND invoicehead.inv_ind='",l_rec_select.inv_ind,"'" 
			END IF 
		END IF 

		IF get_debug() THEN 
			DISPLAY "Debug" 
			DISPLAY "l_inv_text=", l_inv_text 
		END IF 

		LET l_cred_text = NULL 
		IF l_rec_select.cred_flag = "Y" THEN 
			LET l_cred_text = "1=1" 
			IF l_rec_select.cred_start_num IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cred_num>='", 
				l_rec_select.cred_start_num USING "&<<<<<<<","'" 
			END IF 
			IF l_rec_select.cred_last_num IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cred_num<='", 
				l_rec_select.cred_last_num USING "&<<<<<<<","'" 
			END IF 
			IF l_rec_select.cred_start_cust IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cust_code>='",l_rec_select.cred_start_cust,"'" 
			END IF 
			IF l_rec_select.cred_last_cust IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cust_code<='",l_rec_select.cred_last_cust,"'" 
			END IF 
			IF l_rec_select.cred_start_date IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cred_date>='",l_rec_select.cred_start_date,"'" 
			END IF 
			IF l_rec_select.cred_last_date IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cred_date<='",l_rec_select.cred_last_date,"'" 
			END IF 
			IF l_rec_select.cred_prev_prnt_ind = "N" THEN 
				LET l_cred_text = l_cred_text clipped," AND credithead.printed_num<='1'" 
			END IF 
			IF l_rec_select.cred_ind IS NOT NULL THEN 
				LET l_cred_text = l_cred_text clipped," ", 
				"AND credithead.cred_ind='",l_rec_select.cred_ind,"'" 
			END IF 
		END IF 

		#RETURN true
		CASE
			WHEN l_inv_text IS NULL
				LET l_where_text = l_cred_text 
			WHEN l_cred_text IS NULL
				LET l_where_text = l_inv_text 
			OTHERWISE
				LET l_where_text = trim(l_inv_text), " AND ",  trim(l_cred_text)
		END CASE
		
		LET glob_rec_rpt_selector.sel_text = l_where_text
		LET glob_rec_rpt_selector.ref1_text = l_inv_text
		LET glob_rec_rpt_selector.ref2_text = l_cred_text

		LET glob_rec_rpt_selector.ref1_ind = l_rec_select.inv_flag # "N" 
		LET glob_rec_rpt_selector.ref1_num = l_rec_select.inv_start_num #= NULL
		LET glob_rec_rpt_selector.ref2_num = l_rec_select.inv_last_num #= NULL
		LET glob_rec_rpt_selector.ref1_date = l_rec_select.inv_start_date #= NULL 
		LET glob_rec_rpt_selector.ref2_date = l_rec_select.inv_last_date #= NULL
		 
		LET glob_rec_rpt_selector.ref1_code = l_rec_select.inv_start_cust #= NULL 
		LET glob_rec_rpt_selector.ref2_code = l_rec_select.inv_last_cust# = NULL
		 
		LET glob_rec_rpt_selector.ref2_ind = l_rec_select.inv_prev_prnt_ind #= "N" #NULL 
		LET glob_rec_rpt_selector.ref3_ind = l_rec_select.inv_ind # = NULL
		LET glob_rec_rpt_selector.ref4_ind = l_rec_select.cred_flag #= "N"
		 
		LET glob_rec_rpt_selector.ref3_num = l_rec_select.cred_start_num #= NULL 
		LET glob_rec_rpt_selector.ref4_num = l_rec_select.cred_last_num #= NULL
		 
		LET glob_rec_rpt_selector.ref2_date = l_rec_select.cred_start_date #= NULL 
		LET glob_rec_rpt_selector.ref3_date = l_rec_select.cred_last_date #= NULL
		 
		LET glob_rec_rpt_selector.ref3_code = l_rec_select.cred_start_cust #= NULL 
		LET glob_rec_rpt_selector.ref4_code = l_rec_select.cred_last_cust #= NULL 
		LET glob_rec_rpt_selector.ref5_ind = l_rec_select.cred_prev_prnt_ind #= "N" #NULL 
		LET glob_rec_rpt_selector.ref5_code = l_rec_select.cred_ind #= NULL 


		RETURN l_where_text # NCHAR(400)where selector for invoice/credit

	END IF 

END FUNCTION
#########################################################################
# END FUNCTION AS1_rpt_query()
#########################################################################