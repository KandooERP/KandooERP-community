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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P92_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
# get the vouchers that have been split TO PPSCLEAR, THEN get the
# other vouchers AND PRINT the totals etc

GLOBALS 
	DEFINE glob_e_date DATE 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P92") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

--	LET gross_total = 0 
--	LET tax_total = 0 
	CALL doit() 
	CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 

END MAIN 


############################################################
# FUNCTION doit()
#
#
############################################################
FUNCTION doit() 
	DEFINE l_rec_r_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_s_voucher RECORD LIKE voucher.*
	DEFINE l_rpt_output CHAR(60)
	DEFINE l_monther SMALLINT 
	DEFINE l_yearer SMALLINT 

	LABEL month_label: 
	LET l_monther = fgl_winprompt(5,5, "PPS TO show which month (1-12)", "1", 25, 0) 

	IF l_monther < 1 
	OR l_monther > 12 
	THEN 
		GOTO month_label 
	END IF 

	LABEL yearer_label: 
	LET l_yearer = fgl_winprompt(5,5, "PPS year", "1", 25, 0) 


	IF l_yearer < 1990 
	OR l_yearer > 2000 
	THEN 
		GOTO yearer_label 
	END IF 

	LET glob_e_date = mdy(l_monther, 1, l_yearer) 

	# grab those vouchers that have been paid AND are SET TO Y
	# combine those with PPS payments AND SET all TO P
	# get all the vouchers first

	DECLARE curs_1 CURSOR FOR 
	SELECT * 
	INTO l_rec_r_voucher.* 
	FROM voucher 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = "PPSCLEAR" 
	AND jm_post_flag = "Y" 
	ORDER BY vend_code 

	CALL upd_rms(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandoouser.security_ind, 90, "P92", "AP PPS Slips") 
	RETURNING l_rpt_output 

	BEGIN WORK 
		START REPORT p92_list TO l_rpt_output 

		FOREACH curs_1 

			SELECT * 
			INTO l_rec_s_voucher.* 
			FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_rec_r_voucher.split_from_num 

			# check IF fully paid
			IF l_rec_s_voucher.total_amt = l_rec_s_voucher.paid_amt 
			THEN 

				OUTPUT TO REPORT p92_list(l_rec_r_voucher.*, l_rec_s_voucher.* ) 

				UPDATE voucher SET jm_post_flag = "P" 
				WHERE cmpy_code = l_rec_r_voucher.cmpy_code 
				AND vend_code = l_rec_r_voucher.vend_code 
				AND vouch_code = l_rec_r_voucher.vouch_code 

			END IF 


		END FOREACH 

		FINISH REPORT p92_list 

END FUNCTION 




############################################################
# REPORT P92_list(p_rec_r_voucher, p_rec_s_voucher )
#
#
############################################################
REPORT p92_list(p_rec_r_voucher,p_rec_s_voucher) 
	DEFINE p_rec_r_voucher RECORD LIKE voucher.*
	DEFINE p_rec_s_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_contractor RECORD LIKE contractor.*
	DEFINE l_gross_total MONEY(16,2) 
	DEFINE l_tax_total MONEY(16,2)
	DEFINE l_day INTEGER 
	DEFINE l_month INTEGER
	DEFINE l_year INTEGER	
	DEFINE l_date DATE 

	OUTPUT 
	PAGE length 22 
	top margin 0 
	left margin 0 
	bottom margin 0 

	FORMAT 

		FIRST PAGE HEADER

			LET l_gross_total = 0		
			LET l_tax_total = 0

		ON EVERY ROW 

			LET l_gross_total = l_gross_total + p_rec_r_voucher.total_amt + p_rec_s_voucher.total_amt 
			LET l_tax_total = l_tax_total + p_rec_r_voucher.total_amt 

		AFTER GROUP OF p_rec_r_voucher.vend_code 

			SELECT * 
			INTO l_rec_contractor.* 
			FROM contractor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_s_voucher.vend_code 

			SELECT * 
			INTO glob_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_s_voucher.vend_code 

			PRINT COLUMN 8, glob_rec_vendor.name_text 
			PRINT COLUMN 8, glob_rec_vendor.addr1_text, 
			COLUMN 50, l_rec_contractor.tax_no_text USING "### ### ###" 
			PRINT COLUMN 8, glob_rec_vendor.city_text clipped, " ", glob_rec_vendor.post_code 
			SKIP 1 LINES 
			IF l_rec_contractor.var_exp_date > today THEN 
				PRINT COLUMN 50, l_rec_contractor.variation_text 
				PRINT COLUMN 30, l_rec_contractor.tax_rate_qty USING "##.##%" 
				PRINT COLUMN 45, l_rec_contractor.var_exp_date 
			ELSE 
				SKIP 3 LINES 
			END IF 
			SKIP 5 LINES 
			PRINT COLUMN 3, glob_e_date USING "mmm,yy", 
			COLUMN 17, l_gross_total USING "------.&&", 
			COLUMN 36, glob_rec_company.com1_text USING "### ### ###", 
			COLUMN 52, l_tax_total USING "-------" 
			PRINT COLUMN 8, glob_rec_company.name_text 
			PRINT COLUMN 8, glob_rec_company.addr1_text, 
			" XXX XXX XXX" 
			PRINT COLUMN 8, glob_rec_company.addr2_text 
			SKIP 1 LINES 

			# Work out the date FOR the forms

			LET l_day = day(glob_e_date) 
			LET l_month = month(glob_e_date) 
			LET l_year = year(glob_e_date) 
			LET l_month = l_month + 1 
			CASE 
				WHEN l_month = 2 
					IF l_day > 28 THEN 
						LET l_day = 1 
					END IF 
				WHEN l_month = 9 OR l_month = 4 OR 
					l_month = 6 OR l_month = 11 
					IF l_day > 30 THEN 
						LET l_day = 30 
					END IF 
			END CASE 

			# IF month IS 13 THEN LET month = Jan AND increment year

			IF l_month = 13 THEN 
				LET l_month = 1 
				LET l_year = l_year + 1 
			END IF 

			# the following data must evaluate TO a valid date OR you get
			# conversion errors.
			LET l_date = mdy(l_month, l_day, l_year) 

			IF l_date < today THEN 
				PRINT COLUMN 53, l_date USING "dd mm yy" 
			ELSE 
				PRINT COLUMN 53, today USING "dd mm yy" 
			END IF 

			SKIP 3 LINES 

			SKIP TO top OF PAGE 

END REPORT 


