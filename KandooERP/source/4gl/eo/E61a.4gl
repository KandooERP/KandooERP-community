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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E61_GLOBALS.4gl"
################################################################################
# FUNCTION edit_header(p_offer_code)
#
# E61a - Maintainence program FOR Sales Order Special Offers
################################################################################
FUNCTION edit_header(p_offer_code) 
	DEFINE p_offer_code LIKE offersale.offer_code 
--	DEFINE l_rec_offerprod RECORD LIKE offerprod.* 
--	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
--	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_save_date DATE 
	DEFINE l_seqnum SMALLINT 
	DEFINE i SMALLINT 

	MESSAGE kandoomsg2("E",1002,"") #1002 Searching database - please wait"
	IF glob_rec_offersale.desc_text IS NULL THEN 

		## Adding a new entry without using a clone
		LET glob_rec_offersale.start_date = mdy((month(today+30)), 1, year(today+30)) 
		LET glob_rec_offersale.end_date = mdy((month(glob_rec_offersale.start_date+32)),1,year(glob_rec_offersale.start_date+32)) - 1
		 
		LET glob_rec_offersale.bonus_check_per = 0 
		LET glob_rec_offersale.bonus_check_amt = 0 
		LET glob_rec_offersale.disc_check_per = 0 
		LET glob_rec_offersale.disc_per = 0 
		LET glob_rec_offersale.checkrule_ind = "1" 
		LET glob_rec_offersale.disc_rule_ind = "1" 
		LET glob_rec_offersale.checktype_ind = "1" 
		LET glob_rec_offersale.prodline_disc_flag = "N" 
		LET glob_rec_offersale.grp_disc_flag = "N" 
		LET glob_rec_offersale.auto_prod_flag = "N" 
		LET glob_rec_offersale.min_sold_amt = 0 
		LET glob_rec_offersale.min_order_amt = 0 
	END IF 

	MESSAGE kandoomsg2("E",1010,"") 	#Edit Special Offer Details - ESC TO Continue"
	INPUT BY NAME 
		glob_rec_offersale.offer_code, 
		glob_rec_offersale.desc_text, 
		glob_rec_offersale.start_date, 
		glob_rec_offersale.end_date, 
		glob_rec_offersale.bonus_check_per, 
		glob_rec_offersale.bonus_check_amt, 
		glob_rec_offersale.disc_check_per, 
		glob_rec_offersale.disc_per, 
		glob_rec_offersale.checkrule_ind, 
		glob_rec_offersale.disc_rule_ind, 
		glob_rec_offersale.checktype_ind, 
		glob_rec_offersale.prodline_disc_flag, 
		glob_rec_offersale.grp_disc_flag, 
		glob_rec_offersale.auto_prod_flag, 
		glob_rec_offersale.min_sold_amt, 
		glob_rec_offersale.min_order_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E61a","inp-pa_offersale") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD offer_code
			IF p_offer_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD offer_code 
			IF glob_rec_offersale.offer_code IS NULL THEN 
				ERROR kandoomsg2("E",9000,"") 
				NEXT FIELD offer_code 
			ELSE 
				SELECT unique 1 FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = glob_rec_offersale.offer_code 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("E",6010,"") 			#" Warning: Sales Offer Number already exists "
				END IF 
			END IF 

		BEFORE FIELD start_date 
			LET l_save_date = glob_rec_offersale.start_date 

		AFTER FIELD start_date 
			IF glob_rec_offersale.start_date IS NULL THEN 
				ERROR kandoomsg2("E",9012,"") 			#9012" Special Offer commencement date must be Entered"
				LET glob_rec_offersale.start_date = l_save_date 
				NEXT FIELD start_date 
			ELSE 
				IF l_save_date != glob_rec_offersale.start_date THEN 
					LET glob_rec_offersale.end_date = 
					mdy(month(glob_rec_offersale.start_date+32), 1, 
					year(glob_rec_offersale.start_date+32)) - 1 
					DISPLAY BY NAME glob_rec_offersale.start_date 

				END IF 
			END IF 

		AFTER FIELD end_date 
			IF glob_rec_offersale.end_date IS NULL THEN 
				ERROR kandoomsg2("E",9013,"") 		#9013" Special Offer finish date must be Entered"
				LET glob_rec_offersale.end_date = 
				mdy(month(glob_rec_offersale.start_date+32), 1, 
				year(glob_rec_offersale.start_date+32)) - 1 
				NEXT FIELD end_date 
			END IF 
			LET l_seqnum = 4 

		BEFORE FIELD bonus_check_per 
			IF glob_rec_offersale.bonus_check_amt > 0 THEN 
				LET glob_rec_offersale.bonus_check_per = 0 
				IF l_seqnum < 5 THEN 
					NEXT FIELD bonus_check_amt 
				ELSE 
					NEXT FIELD end_date 
				END IF 
			END IF 

		AFTER FIELD bonus_check_per 
			LET l_seqnum = 5 
			CASE 
				WHEN glob_rec_offersale.bonus_check_per IS NULL 
					LET glob_rec_offersale.bonus_check_per = 0 
					ERROR kandoomsg2("E",9040,"") 			#9040 Bonus check percentage must be between 0 AND 100
					NEXT FIELD bonus_check_per 
				WHEN glob_rec_offersale.bonus_check_per < 0 
					LET glob_rec_offersale.bonus_check_per = 0 
					ERROR kandoomsg2("E",9040,"") 			#9040 Bonus check percentage must be between 0 AND 100
					NEXT FIELD bonus_check_per 
				WHEN glob_rec_offersale.bonus_check_per > 100 
					LET glob_rec_offersale.bonus_check_per = 100 
					ERROR kandoomsg2("E",9040,"") 			#9040 Bonus check percentage must be between 0 AND 100
					NEXT FIELD bonus_check_per 
			END CASE 

		BEFORE FIELD bonus_check_amt 
			IF glob_rec_offersale.bonus_check_per > 0 THEN 
				LET glob_rec_offersale.bonus_check_amt = 0 
				IF l_seqnum < 6 THEN 
					NEXT FIELD disc_check_per 
				ELSE 
					NEXT FIELD bonus_check_per 
				END IF 
			END IF 

		AFTER FIELD bonus_check_amt 
			LET l_seqnum = 6 
			CASE 
				WHEN glob_rec_offersale.bonus_check_amt IS NULL 
					LET glob_rec_offersale.bonus_check_amt = 0 
					ERROR kandoomsg2("E",9123,"") 		#9123 Bonus check amount must be positive
					NEXT FIELD bonus_check_amt 
				WHEN glob_rec_offersale.bonus_check_amt < 0 
					LET glob_rec_offersale.bonus_check_amt = 0 
					ERROR kandoomsg2("E",9123,"") 		#9123 Bonus check amount must be positive
					NEXT FIELD bonus_check_amt 
			END CASE 

		AFTER FIELD disc_check_per 
			LET l_seqnum = 7 
			CASE 
				WHEN glob_rec_offersale.disc_check_per IS NULL 
					LET glob_rec_offersale.disc_check_per = 0 
					ERROR kandoomsg2("E",9125,"") 		#9125 Discount check percentage must be entered
					NEXT FIELD disc_check_per 
				WHEN glob_rec_offersale.disc_check_per < 0 
					LET glob_rec_offersale.disc_check_per = 0 
					ERROR kandoomsg2("E",9042,"") 		#9042 Discount check percentage must be between 0 AND 100
					NEXT FIELD disc_check_per 
				WHEN glob_rec_offersale.disc_check_per > 100 
					LET glob_rec_offersale.disc_check_per = 100 
					ERROR kandoomsg2("E",9042,"") 		#9042 Discount check percentage must be between 0 AND 100
					NEXT FIELD disc_check_per 
			END CASE 

		AFTER FIELD disc_per 
			LET l_seqnum = 8 
			IF glob_rec_offersale.disc_per IS NULL THEN 
				ERROR kandoomsg2("E",9126,"") 		#9126 Discount percentage must be entered
				NEXT FIELD disc_per 
			END IF 
			IF glob_rec_offersale.disc_per < 0 
			OR glob_rec_offersale.disc_per > 100 THEN 
				ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
				NEXT FIELD disc_per 
			END IF 

		AFTER FIELD min_sold_amt 
			IF glob_rec_offersale.min_sold_amt IS NULL THEN 
				ERROR kandoomsg2("E",9014,"") 	#9014" Minimum Sold Amount must be Entered "
				NEXT FIELD min_sold_amt 
			ELSE 
				IF glob_rec_offersale.min_order_amt IS NULL 
				OR glob_rec_offersale.min_order_amt = 0 THEN 
					LET glob_rec_offersale.min_order_amt=glob_rec_offersale.min_sold_amt 
					DISPLAY BY NAME glob_rec_offersale.min_order_amt 

				END IF 
			END IF 

		AFTER FIELD prodline_disc_flag 
			IF glob_rec_offersale.prodline_disc_flag = no_flag THEN 
				SELECT unique 1 FROM t_proddisc 
				IF status = 0 THEN 
					LET glob_rec_offersale.prodline_disc_flag = yes_flag 
					ERROR kandoomsg2("E",7046,"") 		#7046" Product Line Discount Entries Exist "
					NEXT FIELD prodline_disc_flag 
				END IF 
			END IF 

		AFTER FIELD auto_prod_flag 
			IF glob_rec_offersale.auto_prod_flag = no_flag THEN 
				SELECT unique 1 FROM t_offerauto 
				IF status = 0 THEN 
					ERROR kandoomsg2("E",7013,"") 		#7013" Auto product insertion entries exist "
					LET glob_rec_offersale.auto_prod_flag = yes_flag 
					NEXT FIELD auto_prod_flag 
				END IF 
			END IF 

		AFTER FIELD min_order_amt 
			IF glob_rec_offersale.min_order_amt IS NULL THEN 
				ERROR kandoomsg2("E",9015,"") 			#9015" Minimum Order Amount must be Entered "
				LET glob_rec_offersale.min_order_amt = glob_rec_offersale.min_sold_amt 
				NEXT FIELD min_order_amt 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_offer_code IS NULL THEN 
					SELECT unique 1 FROM offersale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = glob_rec_offersale.offer_code 
					IF sqlca.sqlcode = 0 THEN 
						ERROR kandoomsg2("E",9016,"") 			#9016" Sales Offer Number already exists - Try Another"
						NEXT FIELD offer_code 
					END IF 
				END IF 
				IF glob_rec_offersale.end_date < glob_rec_offersale.start_date THEN 
					ERROR kandoomsg2("E",9017,"") 				#9017" Finishing date preceeds commencement date "
					LET glob_rec_offersale.end_date = 
					mdy(month(glob_rec_offersale.start_date+32), 1, 
					year(glob_rec_offersale.start_date+32)) - 1 
					NEXT FIELD end_date 
				END IF 
				IF glob_rec_offersale.disc_check_per IS NULL THEN 
					ERROR kandoomsg2("E",9125,"") 		#9125 Discount check percentage must be entered
					NEXT FIELD disc_check_per 
				END IF 
				IF glob_rec_offersale.disc_per IS NULL THEN 
					ERROR kandoomsg2("E",9126,"") 		#9126 Discount percentage must be entered
					NEXT FIELD disc_per 
				END IF 
			END IF 

	END INPUT 
	---------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION