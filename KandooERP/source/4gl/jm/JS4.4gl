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
# \brief module JS4 - Print invoices / credit notes
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JS_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JS4_GLOBALS.4gl"
GLOBALS 
	DEFINE inv_text CHAR(400) 
	DEFINE cred_text CHAR(400) 
END GLOBALS 

MAIN 
	DEFINE 
	pr_output CHAR(50), 
	pr_arparms RECORD LIKE arparms.*, 
	pr_printer LIKE printcodes.print_code 

	#Initial UI Init
	CALL setModuleId("JS4") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",5002,"") 	#5002 AR Parameters NOT SET up - refer Menu AZP "
		EXIT program 
	END IF
	 
	SELECT rmsparm.inv_print_text INTO pr_printer FROM rmsparm 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("E",5008,"") 	#5008 Print Parameters NOT SET up
		EXIT program 
	END IF 
	
	IF num_args() > 0 THEN 
		LET inv_text = arg_val(1) 
		LET cred_text = arg_val(2) 
		IF (inv_text IS NOT NULL OR length(inv_text) > 0) 
		OR (cred_text IS NOT NULL OR length(cred_text) > 0) THEN 
			IF inv_text IS NOT NULL OR length(inv_text) > 0 THEN 
				LET cred_text = NULL 
			END IF 
			IF cred_text IS NOT NULL OR length(cred_text) > 0 THEN 
				LET inv_text = NULL 
			END IF 
			LET pr_output = 
			JS4_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,inv_text,cred_text,FALSE) --print invoice 
			EXIT program 
		END IF 
	END IF 
	OPEN WINDOW A635 with FORM "A635" -- alch kd-747 
	CALL winDecoration_a("A635") -- alch kd-747 
	MENU " Document Print" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JS4","menu-document_print-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Run Report" " Generate documents FOR printing" 
			IF sel_criteria() THEN 
				IF kandoomsg("E",8019,"") = 'Y' THEN 
					LET pr_output = 
					JS4_rpt_process_invoice_credit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,inv_text,cred_text,TRUE) --print invoice 
					NEXT option "Print Manager" 
				END IF 
			END IF 
		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 
		COMMAND "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW A635 
END MAIN 



FUNCTION sel_criteria() 
	DEFINE 
	pr_select RECORD 
		inv_flag CHAR(1), 
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
	LET pr_select.inv_flag = "N" 
	LET pr_select.inv_start_num = NULL 
	LET pr_select.inv_last_num = NULL 
	LET pr_select.inv_start_date = NULL 
	LET pr_select.inv_last_date = NULL 
	LET pr_select.inv_start_cust = NULL 
	LET pr_select.inv_last_cust = NULL 
	LET pr_select.inv_prev_prnt_ind = NULL 
	LET pr_select.inv_ind = NULL 
	LET pr_select.cred_flag = "N" 
	LET pr_select.cred_start_num = NULL 
	LET pr_select.cred_last_num = NULL 
	LET pr_select.cred_start_date = NULL 
	LET pr_select.cred_last_date = NULL 
	LET pr_select.cred_start_cust = NULL 
	LET pr_select.cred_last_cust = NULL 
	LET pr_select.cred_prev_prnt_ind = NULL 
	LET pr_select.cred_ind = NULL 
	INPUT BY NAME pr_select.* WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JS4","input-pr_select-1") -- alch kd-506 

		AFTER FIELD inv_flag 
			IF pr_select.inv_flag = "Y" THEN 
				NEXT FIELD NEXT 
			ELSE 
				NEXT FIELD cred_flag 
			END IF 
		AFTER FIELD cred_flag 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				IF pr_select.inv_flag = "Y" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD inv_flag 
				END IF 
			END IF 
		BEFORE FIELD cred_start_num 
			IF pr_select.cred_flag = "N" THEN 
				NEXT FIELD previous 
			END IF 
		AFTER INPUT 
			IF pr_select.inv_start_num > pr_select.inv_last_num THEN 
				LET msgresp = kandoomsg("E",9176,"") 
				#9176 Beginning document IS greater than ending document
				NEXT FIELD inv_start_num 
			END IF 
			IF pr_select.cred_start_num > pr_select.cred_last_num THEN 
				LET msgresp = kandoomsg("E",9176,"") 
				#9176 Beginning document IS greater than ending document
				NEXT FIELD cred_start_num 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET inv_text = NULL 
		IF pr_select.inv_flag = "Y" THEN 
			LET inv_text = "1=1" 
			IF pr_select.inv_start_num IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.inv_num>='", 
				pr_select.inv_start_num USING "&<<<<<<<","'" 
			END IF 
			IF pr_select.inv_last_num IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.inv_num<='", 
				pr_select.inv_last_num USING "&<<<<<<<","'" 
			END IF 
			IF pr_select.inv_start_cust IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.cust_code>='",pr_select.inv_start_cust,"'" 
			END IF 
			IF pr_select.inv_last_cust IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.cust_code<='",pr_select.inv_last_cust,"'" 
			END IF 
			IF pr_select.inv_start_date IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.inv_date>='",pr_select.inv_start_date,"'" 
			END IF 
			IF pr_select.inv_last_date IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.inv_date<='",pr_select.inv_last_date,"'" 
			END IF 
			IF pr_select.inv_prev_prnt_ind = "N" THEN 
				LET inv_text = inv_text clipped," AND invoicehead.printed_num<='1'" 
			END IF 
			IF pr_select.inv_ind IS NOT NULL THEN 
				LET inv_text = inv_text clipped," ", 
				"AND invoicehead.inv_ind='",pr_select.inv_ind,"'" 
			END IF 
		END IF 
		LET cred_text = NULL 
		IF pr_select.cred_flag = "Y" THEN 
			LET cred_text = "1=1" 
			IF pr_select.cred_start_num IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cred_num>='", 
				pr_select.cred_start_num USING "&<<<<<<<","'" 
			END IF 
			IF pr_select.cred_last_num IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cred_num<='", 
				pr_select.cred_last_num USING "&<<<<<<<","'" 
			END IF 
			IF pr_select.cred_start_cust IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cust_code>='",pr_select.cred_start_cust,"'" 
			END IF 
			IF pr_select.cred_last_cust IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cust_code<='",pr_select.cred_last_cust,"'" 
			END IF 
			IF pr_select.cred_start_date IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cred_date>='",pr_select.cred_start_date,"'" 
			END IF 
			IF pr_select.cred_last_date IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cred_date<='",pr_select.cred_last_date,"'" 
			END IF 
			IF pr_select.cred_prev_prnt_ind = "N" THEN 
				LET cred_text = cred_text clipped," AND credithead.printed_num<='1'" 
			END IF 
			IF pr_select.cred_ind IS NOT NULL THEN 
				LET cred_text = cred_text clipped," ", 
				"AND credithead.cred_ind='",pr_select.cred_ind,"'" 
			END IF 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 
