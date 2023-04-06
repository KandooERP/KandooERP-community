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
# module L11e - Get shipment summation information
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../lc/L_LC_GLOBALS.4gl" 
GLOBALS "../lc/L11_GLOBALS.4gl" 


###########################################################################
# FUNCTION summup()
#
#
###########################################################################
FUNCTION summup() 

	OPEN WINDOW wl104 with FORM "L104" 
	CALL windecoration_l("L104") 

	DISPLAY BY NAME 
		pr_shiphead.vend_code, 
		pr_vendor.name_text, 
		pr_shiphead.ship_code, 
		pr_shiphead.ship_type_code, 
		pr_shiphead.eta_curr_date, 
		pr_shiphead.fob_ent_cost_amt, 
		pr_shiphead.curr_code, 
		pr_shiphead.duty_ent_amt, 
		pr_shiphead.ant_fob_amt, 
		pr_shiphead.ant_duty_amt, 
		pr_shiphead.entry_code, 
		pr_shiphead.entry_date 

	LET ret_flag = 0 

	INPUT BY NAME 
		pr_shiphead.bl_awb_text, 
		pr_shiphead.lc_ref_text, 
		pr_shiphead.container_text, 
		pr_shiphead.case_num, 
		pr_shiphead.com1_text, 
		pr_shiphead.com2_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

	END INPUT 

	CLOSE WINDOW wl104 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION summup()
###########################################################################


###########################################################################
# FUNCTION handle_updates()
#
#
###########################################################################
FUNCTION handle_updates() 
	DEFINE pr_retry CHAR(1) 
	{
	   OPEN WINDOW word AT 13,12 with 4 rows, 50 columns        -- albo  KD-761
	      ATTRIBUTE(border,white,menu line 3)
	}
	MENU " Shipment Review" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Save" " Save Shipment Details" 
			CALL write_ship() 
			IF noerror = 1 THEN 

				FOR i = 1 TO arr_size 
					INITIALIZE st_shipdetl[i].* TO NULL 
				END FOR 
				# MESSAGE out shipment number
				LET temp_ship_code = pr_shiphead.ship_code 
				LET restart = true 
			ELSE 
				EXIT program 
			END IF 

			LET pr_retry = 'N' 
			CALL do_voucher() 

			MENU " Shipment Entry" 
				ON ACTION "WEB-HELP" -- albo kd-375 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Shipment" " Create another Shipment" 
					EXIT MENU 

				COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					LET ans = 'N' 
					EXIT MENU 

			END MENU 

			EXIT MENU 

		COMMAND KEY(interrupt,"R") "Review" 
			" Go back AND edit the current shipment" 
			EXIT MENU 

	END MENU 
	--   CLOSE WINDOW word       -- albo  KD-761
	RETURN pr_retry 
END FUNCTION 
###########################################################################
# FUNCTION handle_updates()
###########################################################################


###########################################################################
# FUNCTION do_voucher()
#
#
###########################################################################
FUNCTION do_voucher() 
	DEFINE pr_vouch_amt LIKE shiphead.ant_fob_amt 

	IF f_type = 'O' THEN 
		MESSAGE kandoomsg2("L","1005" ,pr_shiphead.ship_code) 		#1005 Successfull generation of Shipment "
	ELSE 
		MESSAGE kandoomsg2("L","1008" ,pr_shiphead.ship_code) 		#1008 Successfull Edit of Shipment "
	END IF 

	IF pr_shiphead.fob_ent_cost_amt = pr_shiphead.ant_fob_amt 
	AND pr_shiphead.ant_fob_amt != pr_shiphead.fob_curr_cost_amt THEN 
		# continue on
	ELSE 
		RETURN 
	END IF 

	MENU " Shipment Entry" 
		BEFORE MENU 
			LET pr_vouch_amt = pr_shiphead.ant_fob_amt 
			- pr_shiphead.fob_curr_cost_amt 
			IF pr_vouch_amt < 0 THEN 
				HIDE option "Voucher" 
			ELSE 
				HIDE option "Debit" 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Voucher" " Create a Voucher FOR this Shipment" 
			CALL create_vouch_or_deb(pr_vouch_amt) 
			EXIT MENU 

		COMMAND "Debit" " Create a Debit FOR this Shipment" 
			CALL create_vouch_or_deb(pr_vouch_amt) 
			EXIT MENU 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

END FUNCTION 
###########################################################################
# END FUNCTION do_voucher()
###########################################################################


###########################################################################
# FUNCTION create_vouch_or_deb(pr_vouch_amt)
#
#
###########################################################################
FUNCTION create_vouch_or_deb(pr_vouch_amt) 
	DEFINE pr_shipcosttype RECORD LIKE shipcosttype.* 
	DEFINE pr_vouch_amt LIKE voucher.total_amt 
	DEFINE pr_new_vouch_amt LIKE voucher.total_amt 
	DEFINE pr_conv_rate LIKE voucher.conv_qty 
	DEFINE pr_failed_it SMALLINT 
	DEFINE pr_date, pr_date_sto DATE 

	OPEN WINDOW l169 with FORM "L169" 
	CALL windecoration_l("L169") -- albo kd-761 

	LET pr_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_date) 
	RETURNING 
		pr_shiphead.year_num, 
		pr_shiphead.period_num 

	IF pr_shiphead.curr_code = pr_vendor.currency_code THEN 
		LET pr_new_vouch_amt = pr_vouch_amt 
		LET pr_voucher.conv_qty = pr_shiphead.conversion_qty 
	ELSE 
		# convert FROM base(shipment) TO vendor
		LET pr_new_vouch_amt = conv_currency(
			pr_vouch_amt, 
			pr_shiphead.cmpy_code, 
			pr_vendor.currency_code, 
			"T", 
			today, 
			"B") 
		LET pr_voucher.conv_qty = pr_new_vouch_amt / pr_vouch_amt 
	END IF 

	DISPLAY pr_new_vouch_amt TO goods_amt 


	INPUT 
		pr_date, 
		pr_shiphead.year_num, 
		pr_shiphead.period_num WITHOUT DEFAULTS 
	FROM 
		pr_date, 
		year_num, 
		period_num 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD pr_date 
			LET pr_date_sto = pr_date 

		AFTER FIELD pr_date 
			IF pr_date IS NULL THEN 
				LET pr_date = today 
				NEXT FIELD pr_date 
			END IF 

		BEFORE FIELD year_num 
			IF pr_date != pr_date_sto THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_date) 
				RETURNING 
					pr_shiphead.year_num, 
					pr_shiphead.period_num 
				
				DISPLAY pr_shiphead.year_num TO year_num
				DISPLAY pr_shiphead.period_num TO period_num 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
			IF pr_date IS NULL THEN 
				LET pr_date = today 
				NEXT FIELD pr_date 
			END IF 
			
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				pr_shiphead.year_num, 
				pr_shiphead.period_num,
				"AP") 
			RETURNING 
				pr_shiphead.year_num, 
				pr_shiphead.period_num, 
				pr_failed_it 
			
			IF pr_failed_it THEN 
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	CLOSE WINDOW l169 
	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	SELECT * INTO pr_shipcosttype.* 
	FROM shipcosttype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cost_type_code = 'FOB' 
	IF status = notfound THEN 
		DECLARE c_costtype CURSOR FOR 
		SELECT cost_type_code 
		FROM shipcosttype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_ind = '1' 

		OPEN c_costtype 
		FETCH c_costtype INTO pr_shipcosttype.* 
		CLOSE c_costtype 

		IF status = notfound THEN 
			ERROR kandoomsg2("L", 5001, "")		#U5001 "No Free On Board Shipment Cost Types exist.  Use LZ4.
			EXIT program 
		END IF 
	END IF 
	
	IF pr_vouch_amt < 0 THEN # CREATE debit 
		CALL input_debit( pr_shipcosttype.*, pr_new_vouch_amt, pr_date ) 
	ELSE 
		CALL input_voucher(pr_shipcosttype.*, pr_new_vouch_amt, pr_date ) 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION create_vouch_or_deb(pr_vouch_amt)
###########################################################################

###########################################################################
# FUNCTION input_voucher(pr_shipcosttype, pr_new_vouch_amt, pr_date)
#
#
###########################################################################
FUNCTION input_voucher(pr_shipcosttype, pr_new_vouch_amt, pr_date) 
	DEFINE 
	pr_shipcosttype RECORD LIKE shipcosttype.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	#pr_vouchpayee RECORD LIKE vouchpayee.*, 
	pr_term RECORD LIKE term.*, 
	pr_vouch_code LIKE voucherdist.vouch_code, 
	pr_new_vouch_amt LIKE voucher.total_amt, 
	pr_date DATE 

	LET pr_voucher.vend_code = pr_vendor.vend_code 
	LET pr_voucher.term_code = pr_vendor.term_code 
	LET pr_voucher.tax_code = pr_vendor.tax_code 
	LET pr_voucher.currency_code = pr_vendor.currency_code 
	LET pr_voucher.sales_text = pr_vendor.contact_text 
	LET pr_voucher.hold_code = pr_vendor.hold_code 

	LET pr_vendor.last_vouc_date = NULL 
	LET pr_voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_voucher.po_num = NULL 
	LET pr_voucher.vouch_date = pr_date 
	LET pr_voucher.year_num = pr_shiphead.year_num 
	LET pr_voucher.period_num = pr_shiphead.period_num 
	LET pr_voucher.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_voucher.entry_date = today 
	LET pr_voucher.goods_amt = pr_new_vouch_amt 
	LET pr_voucher.tax_amt = 0 
	LET pr_voucher.total_amt = pr_new_vouch_amt 
	LET pr_voucher.paid_amt = 0 
	LET pr_voucher.dist_qty = 0 
	LET pr_voucher.dist_amt = 0 # SET in p29f 
	LET pr_voucher.taken_disc_amt = 0 

	SELECT * INTO pr_term.* FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_voucher.term_code 

	IF status = notfound THEN 
		LET pr_voucher.due_date = NULL 
		LET pr_voucher.disc_date = NULL 
		LET pr_voucher.poss_disc_amt = 0 
	ELSE 
		CALL get_due_and_discount_date(pr_term.*,pr_date) 
		RETURNING 
			pr_voucher.due_date, 
			pr_voucher.disc_date 
		
		IF pr_term.disc_day_num > 0 THEN 
			LET pr_voucher.poss_disc_amt = pr_voucher.total_amt	* pr_term.disc_per / 100 
		ELSE 
			LET pr_voucher.poss_disc_amt = 0 
		END IF 
	END IF 
	
	LET pr_voucher.paid_date = NULL 
	LET pr_voucher.post_flag = "N" 
	LET pr_voucher.paid_amt = 0 
	LET pr_voucher.post_date = NULL 
	LET pr_voucher.pay_seq_num = 0 
	LET pr_voucher.line_num = 0 
	LET pr_voucher.approved_code = NULL 
	LET pr_voucher.withhold_tax_ind = NULL 
	LET pr_voucher.source_ind = "1" 

	INITIALIZE pr_voucherdist.* TO NULL 

	LET pr_voucherdist.job_code = pr_shiphead.ship_code 
	
	IF pr_shipcosttype.acct_code IS NULL THEN 
		LET pr_voucherdist.acct_code = pr_smparms.git_acct_code 
	ELSE 
		LET pr_voucherdist.acct_code = pr_shipcosttype.acct_code 
	END IF
	 
	LET pr_voucherdist.desc_text = pr_voucherdist.job_code clipped, ' ', pr_shipcosttype.desc_text 
	LET pr_voucherdist.dist_amt = pr_new_vouch_amt 
	LET pr_voucherdist.analysis_text = NULL 
	LET pr_voucherdist.dist_qty = 0 
	LET pr_voucherdist.res_code = pr_shipcosttype.cost_type_code 
	LET pr_voucherdist.type_ind = "S" 
	
	IF pr_voucherdist.dist_qty IS NULL THEN 
		LET pr_voucherdist.dist_qty = 0 
	END IF
	 
	LET pr_voucherdist.po_num = '' 
	LET pr_voucherdist.po_line_num = '' 
	LET pr_voucherdist.trans_qty = 0 
	LET pr_voucherdist.charge_amt = 0 
	
	SELECT max(line_num) INTO pr_voucher.line_num 
	FROM t_voucherdist 
	
	IF pr_voucher.line_num IS NULL THEN 
		LET pr_voucher.line_num = 1 
	ELSE 
		LET pr_voucher.line_num = pr_voucher.line_num + 1 
	END IF 
	
	LET pr_voucherdist.vouch_code = pr_voucher.vouch_code 
	LET pr_voucherdist.line_num = pr_voucher.line_num 

	INSERT INTO t_voucherdist VALUES (pr_voucherdist.*) 
#HuHO: Linker error; I have no idea where this function should be located and if it was removed, renamed, moved etcl...
	LET pr_vouch_code = update_database(
		glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		"1", 
		pr_voucher.*) #, 
		#pr_vouchpayee.*) #seems vouchpayee is passed without reason ( is never used on either side
		 
	DELETE FROM t_voucherdist WHERE 1 = 1 

	IF pr_vouch_code > 0 THEN 
		MESSAGE kandoomsg2("L",1006,pr_vouch_code) #1006 Successfull generation of Voucher xxxx"
	ELSE 
		ERROR kandoomsg2("L",1009,'')	#1009" Error detected during creation of Voucher
		CALL fgl_winmessage("#1009 Error","#1009 Error detected during creation of Voucher","ERROR") 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION input_voucher(pr_shipcosttype, pr_new_vouch_amt, pr_date)
###########################################################################


###########################################################################
# FUNCTION input_debit(pr_shipcosttype, pr_new_vouch_amt, pr_date)
#
#
###########################################################################
FUNCTION input_debit(pr_shipcosttype, pr_new_vouch_amt, pr_date) 
	DEFINE pr_shipcosttype RECORD LIKE shipcosttype.* 
	DEFINE pr_debitdist RECORD LIKE debitdist.* 
	DEFINE pr_term RECORD LIKE term.* 
	DEFINE pr_new_vouch_amt LIKE voucher.total_amt 
	DEFINE pr_debit_num LIKE debithead.debit_num 
	DEFINE pr_date DATE 

	LET pr_new_vouch_amt = 0 - pr_new_vouch_amt 

	LET pr_debithead.vend_code = pr_vendor.vend_code 
	LET pr_debithead.tax_code = pr_vendor.tax_code 
	LET pr_debithead.currency_code = pr_vendor.currency_code 
	LET pr_debithead.contact_text = pr_vendor.contact_text 
	LET pr_vendor.last_vouc_date = NULL 
	LET pr_debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_debithead.rma_num = NULL 
	LET pr_debithead.debit_date = pr_date 
	LET pr_debithead.year_num = pr_shiphead.year_num 
	LET pr_debithead.period_num = pr_shiphead.period_num 
	LET pr_debithead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_debithead.entry_date = today 
	LET pr_debithead.goods_amt = 0 
	LET pr_debithead.tax_amt = 0 
	LET pr_debithead.total_amt = pr_new_vouch_amt 
	LET pr_debithead.dist_qty = 0 
	LET pr_debithead.dist_amt = pr_new_vouch_amt 
	LET pr_debithead.apply_amt = 0 
	LET pr_debithead.disc_amt = 0 
	LET pr_debithead.post_date = NULL 
	LET pr_debithead.jour_num = NULL 
	LET pr_debithead.post_flag = "N" 

	INITIALIZE pr_debitdist.* TO NULL 

	LET pr_debitdist.job_code = pr_shiphead.ship_code 
	IF pr_shipcosttype.acct_code IS NULL THEN 
		LET pr_debitdist.acct_code = pr_smparms.git_acct_code 
	ELSE 
		LET pr_debitdist.acct_code = pr_shipcosttype.acct_code 
	END IF 
	
	LET pr_debitdist.desc_text = pr_debitdist.job_code clipped, ' ', pr_shipcosttype.desc_text 
	LET pr_debitdist.dist_amt = pr_new_vouch_amt 
	LET pr_debitdist.analysis_text = NULL 
	LET pr_debitdist.dist_qty = 0 
	LET pr_debitdist.res_code = pr_shipcosttype.cost_type_code 
	LET pr_debitdist.type_ind = "S" 
	
	IF pr_debitdist.dist_qty IS NULL THEN 
		LET pr_debitdist.dist_qty = 0 
	END IF 
	
	LET pr_debitdist.po_num = '' 
	LET pr_debitdist.po_line_num = '' 
	LET pr_debitdist.trans_qty = 0 
	LET pr_debitdist.charge_amt = 0 
	
	SELECT max(line_num) INTO pr_debitdist.line_num 
	FROM t_debitdist 
	IF pr_debitdist.line_num IS NULL THEN 
		LET pr_debitdist.line_num = 1 
	ELSE 
		LET pr_debitdist.line_num = pr_debitdist.line_num + 1 
	END IF 
	
	LET pr_debitdist.debit_code = pr_debithead.debit_num 
	
	INSERT INTO t_debitdist VALUES (pr_debitdist.*) 

	LET pr_debit_num = update_debit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, "1", pr_debithead.*) 

	DELETE FROM t_debitdist 
	WHERE 1 = 1 

	IF pr_debit_num > 0 THEN 
		ERROR kandoomsg2("L",1007,pr_debit_num)		#1006 Successfull generation of Debit xxxx"
	ELSE 
		ERROR kandoomsg2("L",1010,'')	#1010" Error detected during creation of Debit
		CALL fgl_winmessage("#1010 Error","#1010 Error detected during creation of Debit","ERROR")
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION input_debit(pr_shipcosttype, pr_new_vouch_amt, pr_date)
###########################################################################