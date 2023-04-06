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

	Source code beautified by beautify.pl on 2020-01-03 09:12:19	$Id: $
}




# Purpose - Product Addition
#           This program allows the user TO enter new inventory products
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
-- No Globals GLOBALS "I11_GLOBALS.4gl" 

# DEFINE module variables
--DEFINE pr_product RECORD LIKE product.*
DEFINE yes_flag,no_flag CHAR(1)
--DEFINE glob_rec_company RECORD LIKE company.*
--DEFINE glob_rec_inparms RECORD LIKE inparms.*
DEFINE cb_maingrp_code ui.ComboBox
DEFINE cb_prodgrp_code ui.ComboBox
DEFINE cb_part_code ui.ComboBox

FUNCTION I11_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

##########################################################################################
# MAIN
#
#
##########################################################################################
FUNCTION I11_main() 
	DEFINE runner CHAR(90) 
	DEFINE x SMALLINT
	DEFINE y SMALLINT
	DEFINE msgresp LIKE language.yes_flag
	DEFINE l_run_arg STRING 
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_operation_status SMALLINT

	LET yes_flag = xlate_from("Y") 
	LET no_flag = xlate_from("N") 

	SELECT * INTO glob_rec_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",5003,"") 
		#5003 Company NOT SET up - Refer System Administrator
		# Wow! Noone will see that message!!!
		EXIT program 
	END IF 

	SELECT * INTO glob_rec_inparms.* 
	FROM inparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = notfound THEN 
		--LET msgresp = kandoomsg("I",5002,"") 
		CALL fgl_winmessage("Inventory Parameters missing",kandoomsg2("I",5002,""),"ERROR") 
		#5002 In Parameters NOT SET up - Refer Menu IZP
		# FIXME: re-enable exit program when OK
		--EXIT program 
	END IF 
	LET x = 50 

	# ericv: Not sure about what is this supposed to do...
	IF glob_rec_inparms.ref1_text IS NOT NULL OR glob_rec_inparms.ref2_text IS NOT NULL 
	OR glob_rec_inparms.ref3_text IS NOT NULL OR glob_rec_inparms.ref4_text IS NOT NULL 
	OR glob_rec_inparms.ref5_text IS NOT NULL OR glob_rec_inparms.ref6_text IS NOT NULL 
	OR glob_rec_inparms.ref7_text IS NOT NULL OR glob_rec_inparms.ref8_text IS NOT NULL THEN 
		LET x = x + 12 
	END IF 

	IF glob_rec_company.module_text[5] = "E" THEN 
		LET x = x + 14 
	END IF 
	LET y = (80-x)/2 

	OPEN WINDOW i626 with FORM "I626" 
	 CALL windecoration_i("I626") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE TRUE

		MENU " Inventory" 
			BEFORE MENU 
				IF glob_rec_inparms.ref1_text IS NOT NULL 
				OR glob_rec_inparms.ref2_text IS NOT NULL 
				OR glob_rec_inparms.ref3_text IS NOT NULL 
				OR glob_rec_inparms.ref4_text IS NOT NULL 
				OR glob_rec_inparms.ref5_text IS NOT NULL 
				OR glob_rec_inparms.ref6_text IS NOT NULL 
				OR glob_rec_inparms.ref7_text IS NOT NULL 
				OR glob_rec_inparms.ref8_text IS NOT NULL THEN 
					SHOW option "Report Code" 
				ELSE 
					HIDE option "Report Code" 
				END IF 
				IF glob_rec_company.module_text[5] = "E" THEN 
					SHOW option "Turnover" 
				ELSE 
					HIDE option "Turnover" 
				END IF 
				HIDE option "Turnover" 
				HIDE option "Report Code" 
				HIDE OPTION "Stock"
				HIDE OPTION "Dimensions"
				HIDE OPTION "Save"



				CALL publish_toolbar("kandoo","I11","menu-Inventory") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "REFRESH" 
				 CALL windecoration_i("I626") 
			
			ON ACTION "Add"
				HIDE OPTION "Save","Report Code","Turnover","Stock","Dimensions"
				CALL input_product_main_details(MODE_CLASSIC_ADD,NULL) RETURNING l_operation_status,l_rec_product.*
				SHOW OPTION "Report Code","Turnover","Stock","Dimensions"

			ON ACTION ("Stock") 
				#COMMAND "Stock"
				#       " Add purchasing AND stocking details"
				CALL input_product_purchase_detail(l_rec_product.part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
				--NEXT option "Save" 

			ON ACTION ("Report Code")
				#COMMAND "Reporting"
				#        " Add reporting code VALUES TO the product"
				CALL input_product_report_codes(l_rec_product.part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
				

			ON ACTION "Turnover" 
				#COMMAND "Turnover"
				#        " Add statistical VALUES TO the product"
				CALL input_product_statistic_amts(l_rec_product.part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*

			ON ACTION "Dimensions" 
				#COMMAND "Dimensions"
				#        " Add dimension quantities TO the product"
				CALL input_product_dimensions(l_rec_product.part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*

			ON ACTION "Save" 
				#      " Save new product details "
				CALL insert_product(l_rec_product.*) RETURNING l_operation_status
				IF l_operation_status = 1 THEN 
					MENU " Add " 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","I11","menu-add") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON ACTION "Warehouse" 
							#COMMAND "Warehouse" " Add product STATUS TO Warehouse"
							LET l_run_arg = "PRODUCT_PART_CODE=", trim(l_rec_product.part_code)
							CALL run_prog("I16",l_run_arg,"","","") 

						ON ACTION "Information" 
							#COMMAND "Information" " Add product information"
							CALL input_prodinfo(l_rec_product.part_code) RETURNING l_operation_status

						ON ACTION "Exit" 
							#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO entry SCREEN"
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 
					END MENU 

					INITIALIZE l_rec_product.* TO NULL 
					CLEAR FORM
				ELSE
					ERROR "INSERT of that product HAS FAILED!"
				END IF 
				HIDE OPTION "Save","Report Code","Turnover","Stock","Dimensions"
				EXIT MENU 

			ON ACTION "Exit" 
				#COMMAND KEY(interrupt,"E")"Exit" " Edit product details"
				LET int_flag = false 
				LET quit_flag = false 
				EXIT PROGRAM 

		END MENU 
		
		#CLOSE WINDOW w1_I11
		#CLEAR FORM
	END WHILE 
	CLOSE WINDOW i626 
END FUNCTION  # I11_main 


{
FUNCTION initalize_rec_product(p_mode,p_rec_product)
	DEFINE p_mode CHAR(5)
	DEFINE p_rec_product RECORD LIKE product.*
	IF p_mode = "ADD" THEN 
		LET p_rec_product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET p_rec_product.weight_qty = 0 
		LET p_rec_product.cubic_qty = 0 
		LET p_rec_product.area_qty = 0 
		LET p_rec_product.length_qty = 0 
		LET p_rec_product.pack_qty = 0 
		LET p_rec_product.target_turn_qty = 0 
		LET p_rec_product.stock_turn_qty = 0 
		LET p_rec_product.stock_days_num = 0 
		LET p_rec_product.pur_stk_con_qty = 0 
		LET p_rec_product.dg_code = NULL 
		LET p_rec_product.stk_sel_con_qty = 0 
		LET p_rec_product.outer_qty = 1 
		LET p_rec_product.outer_sur_per = 0 
		LET p_rec_product.min_ord_qty = 0 
		LET p_rec_product.days_lead_num = 0 
		LET p_rec_product.days_warr_num = 0 
		LET p_rec_product.min_month_amt = 0 
		LET p_rec_product.min_quart_amt = 0 
		LET p_rec_product.min_year_amt = 0 
		LET p_rec_product.serial_flag = no_flag 
		LET p_rec_product.total_tax_flag = yes_flag 
		LET p_rec_product.back_order_flag = yes_flag 
		LET p_rec_product.disc_allow_flag = yes_flag 
		LET p_rec_product.bonus_allow_flag = yes_flag 
		LET p_rec_product.trade_in_flag = no_flag 
		LET p_rec_product.price_inv_flag = yes_flag 
		LET p_rec_product.status_ind = "1" 
		LET p_rec_product.status_date = today 
		LET p_rec_product.setup_date = today 
		LET p_rec_product.last_calc_date = today 
	ELSE
	END IF 
	RETURN p_rec_product.*
END FUNCTION	# initalize_rec_product
}
