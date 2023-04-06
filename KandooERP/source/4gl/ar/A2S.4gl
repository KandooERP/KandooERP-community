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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl" 
#This file IS used as GLOBALS file FROM A2Sf.4gl
############################################################
# MAIN 
#
# A2S  allows the user TO enter Accounts Receivable Invoices
# updating inventory, AND choose a list of customres in
# which the invoice IS TO be printed.
############################################################
MAIN 
	DEFINE l_gv_program CHAR(25) 
	DEFINE l_to_inv CHAR 

	#Initial UI Init
	CALL setModuleId("A2S") 
	CALL ui_init(0) 

	DEFER interrupt 
	DEFER quit 

	LET l_gv_program = get_baseprogname() 

	LET glob_menu_path = l_gv_program[1,3] 
	CALL authenticate(glob_menu_path) 
	CALL init_a_ar() #init a/ar module 


	LET glob_func_type = "Invoice Entry" 
	LET glob_f_type = "glob_i" 
	LET glob_first_time = 1 
	LET glob_show_inv_det = "Y" 
	LET glob_noerror = 1 
	LET glob_inc_tax = "N" 

	CREATE temp TABLE statab (company_cmpy_code CHAR(2), 
	ware nchar(3), 
	part nchar(15), 
	ship DECIMAL(12,3), 
	which nchar(3)) with no LOG 

	LET glob_ans = "Y" 
	WHILE glob_ans = "Y" 
		DELETE FROM statab WHERE 1=1 
		# INITIALIZE pr records
		INITIALIZE glob_rec_invoicehead.* TO NULL 
		LET glob_rec_invoicehead.goods_amt = 0 
		LET glob_rec_invoicehead.total_amt = 0 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = 0 
		LET glob_rec_invoicehead.paid_amt = 0 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.tax_per = 0 

		INITIALIZE glob_rec_invoicedetl.* TO NULL 
		FOR glob_i = 1 TO 300 
			INITIALIZE glob_arr_rec_taxamt[glob_i].tax_code TO NULL 
		END FOR 
		LET glob_noerror = 1 
		LET glob_goon = "Y" 
		LET glob_prmt = "Y" 

		OPEN WINDOW wa2s with FORM "A2S" 
		CALL windecoration_a("A2S") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		LABEL headlab: 
		CALL A2S_header() 
		IF glob_ans = "N" THEN 
			CALL out_stat() 
			EXIT WHILE 
		END IF 

		LABEL linelab: 
		IF (glob_ans = "Y" AND glob_goon = "Y") OR (glob_ans = "C" AND glob_goon = "Y") THEN 
			CALL lineitem() 
		END IF 

		IF glob_ans = "N" OR glob_ans = "C" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 

			IF glob_ans = "N" THEN 
				INITIALIZE glob_rec_invoicehead.* TO NULL 
				LET glob_rec_invoicehead.goods_amt = 0 
				LET glob_rec_invoicehead.total_amt = 0 
				LET glob_rec_invoicehead.hand_amt = 0 
				LET glob_rec_invoicehead.hand_tax_amt = 0 
				LET glob_rec_invoicehead.freight_amt = 0 
				LET glob_rec_invoicehead.freight_tax_amt = 0 
				LET glob_rec_invoicehead.tax_amt = 0 
				LET glob_rec_invoicehead.disc_amt = 0 
				LET glob_rec_invoicehead.paid_amt = 0 
				LET glob_rec_invoicehead.disc_taken_amt = 0 
				LET glob_rec_invoicehead.disc_per = 0 
				LET glob_rec_invoicehead.cost_amt = 0 
				LET glob_rec_invoicehead.tax_per = 0 
				LET glob_first_time = 1 

				INITIALIZE glob_rec_invoicedetl.* TO NULL 
				CALL out_stat() 

				FOR glob_idx = 1 TO glob_arr_size 
					INITIALIZE glob_arr_rec_st_invoicedetl[glob_idx].* TO NULL 
				END FOR 

				FOR glob_i = 1 TO 300 
					INITIALIZE glob_arr_rec_taxamt[glob_i].tax_code TO NULL 
				END FOR 
				LET glob_ans = "Y" 
			END IF 
			GOTO headlab 
		END IF 
		
		IF glob_ans = "Y" AND glob_goon = "Y" THEN 
			CALL summup() 
		END IF
		 
		IF glob_ans = "N" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			LET glob_ans = "C" 
			GOTO linelab 
		END IF
		 
		IF glob_ans = "Y" AND glob_goon = "Y" THEN 
			CLOSE WINDOW wa2s 
			CALL inv_cust_list() 
			RETURNING l_to_inv, glob_group_code 

			IF l_to_inv = 'Y' THEN 
				CALL cust_head(glob_group_code) 
			ELSE 
				GOTO headlab 
			END IF 

			# now do any serialisation that may be needed
			FOR glob_i = 1 TO glob_arr_size 
				IF glob_arr_rec_st_invoicedetl[glob_i].ser_flag = "Y" THEN 
					LET glob_arr_rec_st_invoicedetl[glob_i].ser_qty = 
					ser_update(glob_rec_kandoouser.cmpy_code, glob_arr_rec_st_invoicedetl[glob_i].part_code, 
					glob_arr_rec_st_invoicedetl[glob_i].ware_code, 
					glob_arr_rec_st_invoicedetl[glob_i].cust_code, 
					glob_rec_invoicehead.inv_num, 
					glob_rec_invoicehead.inv_date, 
					glob_arr_rec_st_invoicedetl[glob_i].ship_qty) 
					IF glob_arr_rec_st_invoicedetl[glob_i].ser_qty > 0 THEN 
						UPDATE invoicedetl 
						SET ser_qty = glob_arr_rec_st_invoicedetl[glob_i].ser_qty 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_arr_rec_st_invoicedetl[glob_i].cust_code 
						AND inv_num = glob_rec_invoicehead.inv_num 
						AND line_num = glob_i 
					END IF 
				END IF 
				INITIALIZE glob_arr_rec_st_invoicedetl[glob_i].* TO NULL 
			END FOR
			 
			LET glob_temp_inv_num = glob_rec_invoicehead.inv_num 
			LET glob_first_time = 1 
		END IF 
	END WHILE 
END MAIN 


