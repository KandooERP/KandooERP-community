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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/U11_GLOBALS.4gl"  

#To test p4gl FOR ignoring of MAIN FUNCTION REPORT blocks in included file:
#GLOBALS '../utility/U12.4gl'


 
############################################################
# MODULE Scope Variables
############################################################
#FOR Doc4GL testing: - works, but does NOT RECORD variable type?
--DEFINE test_module_var SMALLINT 

#######################################################################
# FUNCTION U11_main() 
#
#
#######################################################################
FUNCTION U11_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("U11") 

	IF glob_rec_kandoouser.sign_on_code = "admin" THEN
		CALL fgl_winmessage("Error","The kandoo System Administrator can only work with/as company 99","ERROR")
		EXIT PROGRAM
	END IF

	SELECT * 
	INTO glob_rec_kandoouser_edit.* 
	FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

	OPEN WINDOW G130 with FORM "G130" 
	CALL windecoration_g("G130") 

	CALL scan_company() 
	
	CLOSE WINDOW G130 

END FUNCTION 
#######################################################################
# END FUNCTION U11_main() 
#######################################################################
{
> Currently the STATUS of the tags IS:

                    Loaded       generated
                                HTML    JSP
>   @file -         *           n/a     n/a
>   @process -      *           *       *       (FOR MODULE)
>   	@process -  ?           -       -       (FOR FUNCTION)
>   @param -        *           *       *
>   @RETURN -       *           *       *
>   @todo -         *           *       *
>   @table -        *           *       only on summary WHEN SQL found - @table NOT working!
>   @author -       *           *       -
>   @revision -     *           -       -       (alias FOR @version)
>   @deprecated -   *           -       -
>   @since          *           *       -
>   @form           ?           -       -
>   @see            ?           -       -
TOTAL=12

BUG: coloumn NOT removed FROM tags Author: : AND Since: :

See list of DoxyGen/JavaDoc standard tags at:
	http://www.stack.nl/~dimitri/doxygen/commands.html
}


#######################################################################
# FUNCTION a_testing_doc4gl(l_dummy1, l_dummy2)
#
# ??? I'm Hubert, the superMan and would like to delete this funciton
# @eric, am I allowed to remove/delte this function ?
#######################################################################
FUNCTION a_testing_doc4gl(l_dummy1, l_dummy2) 
	DEFINE l_dummy1 SMALLINT 
	DEFINE l_dummy2 SMALLINT 

	MESSAGE"this IS a dummy FUNCTION FOR testing doc4gl parser, AND it's NOT used anywhere\why is this here ? for what reason ?" 

	SELECT * FROM select_table 
	DELETE FROM delete_table 
	UPDATE update_table SET x=1 
	INSERT INTO insert_table VALUES (1) 


	{

	SELECT * FROM p4gl_function
	WHERE function_name = "a_testing_doc4gl"
		id_package        .
		module_name       U11.4gl
		function_name     a_testing_doc4gl
		function_type     F
		deprecated        Y
		author             original
		since              1.2.3
		comments            Doc4GL testing FUNCTION. Used TO test documentation tags.
		instructions_num
		sql_num

	SELECT               *  FROM               p4gl_fun_todo
	WHERE p4gl_fun_todo.function_name = "a_testing_doc4gl"
		item_num       0
		comments        This IS a todo testing comments

	SELECT               *  FROM               p4gl_fun_return
	WHERE p4gl_fun_return.function_name = "a_testing_doc4gl"
		item_num       0
		var_name
		data_type
		comments        Description of the returned variable(s)

	SELECT               *  FROM               p4gl_fun_parameter
	WHERE                 function_name = "a_testing_doc4gl"
		item_num       0
		var_name       l_dummy1
		data_type      CHAR (20)
		comments        Description of the first parameter variable

		item_num       1
		var_name       l_dummy2
		data_type      SMALLINT
		comments        Description of the second parameter variable

	SELECT               *  FROM               p4gl_table_usage
	WHERE                 function_name = "a_testing_doc4gl"
		id_table_usage  18466
		table_name      kandoouser                                    <<<<<< WRONG
		operation       S                                          <<<<<< WRONG
		owner           root
		tabname         kandoouser                                    <<<<<< WRONG

	SELECT               *  FROM               p4gl_fun_process
	WHERE                 function_name = "a_testing_doc4gl"
		id_process     COMMON

	SELECT               *  FROM               p4gl_globals_usage
	WHERE                 function_name = "a_testing_doc4gl"
	    (no rows)
	SELECT               *  FROM               p4gl_function_call
	WHERE                 function_name = "a_testing_doc4gl"
	    (no rows)
	SELECT               *  FROM               p4gl_form_usage
	WHERE                 function_name = "a_testing_doc4gl"
	    (no rows)
	}


END FUNCTION 


#######################################################################
# FUNCTION scan_company()
#
#
#######################################################################
FUNCTION scan_company() 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_kandoousercmpy RECORD LIKE kandoousercmpy.* 
	DEFINE l_arr_rec_company DYNAMIC ARRAY OF t_rec_company_c_n_c_c_t_t_a_c_m #t_rec_company_c_n_c_t 
	#	DEFINE l_arr_rec_company array[200] of record
	#         cmpy_code LIKE company.cmpy_code,
	#         name_text LIKE company.name_text,
	#         city_text LIKE company.city_text,
	#         tele_text LIKE company.tele_text
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_temp_text CHAR(80) 
	DEFINE l_msgstr STRING 
	
	DECLARE c_company CURSOR FOR 
	SELECT company.* 
	FROM company, kandoousercmpy 
	WHERE kandoousercmpy.cmpy_code = company.cmpy_code 
	AND kandoousercmpy.sign_on_code = glob_rec_kandoouser.sign_on_code 

	LET l_idx = 0 
	FOREACH c_company INTO l_rec_company.* #note, we changed the FORM ! 
		LET l_idx = l_idx + 1 

		LET l_arr_rec_company[l_idx].cmpy_code = l_rec_company.cmpy_code 
		LET l_arr_rec_company[l_idx].name_text = l_rec_company.name_text 
		LET l_arr_rec_company[l_idx].country_code = l_rec_company.country_code 
		LET l_arr_rec_company[l_idx].city_text = l_rec_company.city_text 
		LET l_arr_rec_company[l_idx].tele_text = l_rec_company.tele_text 

		LET l_arr_rec_company[l_idx].tax_text = l_rec_company.tax_text 
		LET l_arr_rec_company[l_idx].vat_code = l_rec_company.vat_code 
		LET l_arr_rec_company[l_idx].curr_code = l_rec_company.curr_code 
		LET l_arr_rec_company[l_idx].module_text = l_rec_company.module_text 
	END FOREACH 

	IF l_arr_rec_company.getlength() = 0 THEN 
		ERROR kandoomsg2("U",9101,"") 
	ELSE 
		MESSAGE kandoomsg2("U",1023,"") #U1023 " RETURN on line TO change company"
		CALL display_current_user() #currently logged in user details 

		DISPLAY ARRAY l_arr_rec_company TO sr_company.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","U11","input-company") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_idx > 0 THEN 
					LET l_rec_company.cmpy_code = l_arr_rec_company[l_idx].cmpy_code 
				END IF 

			ON ACTION ("DOUBLECLICK","ACCEPT") 
				IF l_rec_company.cmpy_code = glob_rec_company.cmpy_code THEN
					CALL fgl_winmessage("N/A","You are already using this company as your default company","info")
				ELSE
				
					IF l_rec_company.cmpy_code IS NOT NULL THEN 
						LET l_temp_text = " ",glob_rec_kandoouser_edit.name_text clipped," TO ", 
						l_arr_rec_company[l_idx].name_text 
	
						IF kandoomsg("U",8014,l_temp_text) = "Y" THEN 
	
							SELECT * INTO l_rec_kandoousercmpy.* FROM kandoousercmpy 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND sign_on_code = glob_rec_kandoouser.sign_on_code 
							IF status = notfound THEN 
								ERROR kandoomsg2("U",7031,"")			#7031 User has NOT been SET up FOR this company
								#                      NEXT FIELD cmpy_code
							END IF 
	
							UPDATE kandoouser 
							SET cmpy_code = l_rec_company.cmpy_code, 
							acct_mask_code = l_rec_kandoousercmpy.acct_mask_code 
							WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
							IF sqlca.sqlerrd[3] = 1 THEN 
								LET glob_rec_kandoouser_edit.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_msgstr = "User ", trim(glob_rec_kandoouser.sign_on_code), " was assigned to this company ", trim(l_rec_company.cmpy_code), "\n IMPORTANT!\nPlease exit KandooERP mow and re-start the program NOW" 
								CALL fgl_winmessage("Company Assgned",l_msgStr,"info") 
							ELSE 
	
								LET glob_rec_kandoouser_edit.cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_msgstr = "Could not assign user ", trim(glob_rec_kandoouser.sign_on_code), " to this company ", trim(l_rec_company.cmpy_code) 
								CALL fgl_winmessage("Error",l_msgStr,"error") 
							END IF 
	
							CALL display_current_user() #currently logged in user details 
						END IF 
					END IF 
				END IF

		END DISPLAY 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
#######################################################################
# END FUNCTION a_testing_doc4gl(l_dummy1, l_dummy2)
#######################################################################


#######################################################################
# FUNCTION display_current_user()
#
#
#######################################################################
FUNCTION display_current_user() 

	DISPLAY glob_rec_kandoouser.sign_on_code TO current_sign_on_code 
	DISPLAY glob_rec_kandoouser.name_text TO current_name_text 
	DISPLAY glob_rec_kandoouser.cmpy_code TO current_cmpy_code 
	DISPLAY db_company_get_name_text(ui_off,glob_rec_kandoouser.cmpy_code) TO current_cmpy_name 
	DISPLAY glob_rec_kandoouser.acct_mask_code TO current_account_mask_code 
END FUNCTION 
#######################################################################
# END FUNCTION display_current_user()
#######################################################################

{

#         PRINT 54 spaces  #p4gl: P34k.4gl, Line 509: parse error


#         PRINT COLUMN 10, l_temp_text clipped,  <<<< p4gl: P6A.4gl, Line 479: parse error
#               COLUMN 25, where1_text clipped wordwrap right margin x
		 PRINT where1_text right margin x

			LET l_temp_text = (pr_recurhead.run_num + 1) using "&&&"



}


{ ++++++++++++++++ FIXME - parser fails attemthis TO parse this: +++++++++

main
DEFINE
	dummy CHAR (1),
    file CHAR(2),
    smallint_val SMALLINT,
    rrr record
        dummy CHAR(1)
    END RECORD

    DISPLAY "xxx"

#    p4gl: P21.4gl, Line 97: parse error
				LET dummy = menu(dummy)

#    p4gl: P71.4gl, Line 697: parse error
				LET dummy  = dummy clipped, ".",
                               (smallint_val + 1) using "&&&"

#    p4gl: PR2.4gl, Line 106: parse error
		   CONSTRUCT BY NAME rrr.dummy on vendor.vend_code,
                                            vendor.type_code,
                                            vendor.name_text,
                                            vendor.currency_code,
                                            vendor.term_code,
                                            vendor.tax_code,
                                            voucher.year_num,
                                            voucher.period_num


#    p4gl: PSL_J.4gl, Line 1007: parse error
            prompt " Enter target file name: " FOR file

#    p4gl: PSU_J.4gl, Line 131: parse error
            CALL unload()

#    p4gl: PSV.4gl, Line 68: parse error
         CALL verify()

#    p4gl: PX3_J.4gl, Line 145: parse error

   SELECT count(unique pay_doc_num) INTO dummy FROM tentpays
      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
        AND cycle_num = pr_cycle_num
        AND status_ind = "4"


END MAIN


FUNCTION menu(dummy)
DEFINE dummy CHAR (1)

    RETURN dummy

END FUNCTION



FUNCTION unload()

END FUNCTION



FUNCTION verify()

END FUNCTION


REPORT xyz()
DEFINE dummy CHAR (1),
    x SMALLINT


FORMAT
    ON EVERY ROW

            PRINT "xxx"

#    p4gl: P34k.4gl, Line 509: parse error
				PRINT 54 spaces

#    p4gl: P6A.4gl, Line 479: parse error
				 PRINT COLUMN 25, dummy clipped wordwrap right margin x

#    p4gl: P73.4gl, Line 336: parse error
		 PRINT COLUMN 10, dummy clipped,
               COLUMN 25, dummy clipped wordwrap
                          right margin x #<<<< cause

     PRINT "03",dummy,
            dummy using "ddmmyy",
            (x * 100) using "&&&&&&&&&&&&&"


END REPORT
