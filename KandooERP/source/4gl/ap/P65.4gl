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
# \brief module P65 allows the user TO view debit information

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P65_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

GLOBALS 
	DEFINE 
	glob_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_num LIKE debithead.debit_num, 
		dist_amt LIKE debithead.dist_amt, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		disc_amt LIKE debithead.disc_amt, 
		conv_qty LIKE debithead.conv_qty, 
		entry_code LIKE debithead.entry_code, 
		entry_date LIKE debithead.entry_date, 
		debit_text LIKE debithead.debit_text, 
		debit_date LIKE debithead.debit_date, 
		year_num LIKE debithead.year_num, 
		period_num LIKE debithead.period_num, 
		post_flag LIKE debithead.post_flag, 
		jour_num LIKE debithead.jour_num, 
		com1_text LIKE debithead.com1_text, 
		com2_text LIKE debithead.com2_text, 
		batch_num LIKE debithead.batch_num 
	END RECORD 
END GLOBALS 


############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P65") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p112 with FORM "P112" 
	CALL windecoration_p("P112") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL query() 
	CLOSE WINDOW p112 
END MAIN 


FUNCTION select_them() 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_url_query_where_text() IS NOT NULL THEN
	--IF num_args() > 0 THEN 
		### Allows prog TO run with certain criteria
		LET l_where_part = get_url_query_where_text() -- arg_val(1)
	ELSE 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("P",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_part ON debithead.vend_code, 
		vendor.name_text, 
		debithead.debit_num, 
		debithead.batch_num, 
		vendor.currency_code, 
		debithead.total_amt, 
		debithead.dist_amt, 
		debithead.apply_amt, 
		debithead.disc_amt, 
		debithead.year_num, 
		debithead.period_num, 
		debithead.post_flag, 
		debithead.jour_num, 
		debithead.conv_qty, 
		debithead.debit_date, 
		debithead.debit_text, 
		debithead.entry_code, 
		debithead.entry_date, 
		debithead.com1_text, 
		debithead.com2_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P65","construct-debithead-1") 

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
	END IF 
	LET l_query_text = 
	"SELECT debithead.vend_code,vendor.name_text,vendor.currency_code, ", 
	"debithead.debit_num, ", 
	"debithead.dist_amt, debithead.total_amt, ", 
	"debithead.apply_amt, debithead.disc_amt, ", 
	"debithead.conv_qty, ", 
	"debithead.entry_code, debithead.entry_date, ", 
	"debithead.debit_text, debithead.debit_date, ", 
	"debithead.year_num, debithead.period_num, ", 
	"debithead.post_flag, debithead.jour_num, ", 
	"debithead.com1_text, debithead.com2_text, ", 
	"debithead.batch_num ", 
	"FROM debithead , vendor ", 
	"WHERE vendor.vend_code = debithead.vend_code AND ", 
	" debithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" vendor.cmpy_code = debithead.cmpy_code AND ", 
	l_where_part clipped, 
	" ORDER BY debithead.vend_code, debithead.debit_num " 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE statement_1 FROM l_query_text 
	DECLARE debithead_set SCROLL CURSOR FOR statement_1 
	OPEN debithead_set 
	FETCH debithead_set INTO glob_rec_debithead.* 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9044,"") 
		#9044 No entries satisfied selection criteria
		RETURN false 
	ELSE 
		CALL show_it() 
		RETURN true 
	END IF 
	WHENEVER ERROR stop 
	OPTIONS SQL interrupt off 
END FUNCTION 


FUNCTION query() 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Debits" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Detail" 
			HIDE option "First" 
			HIDE option "Last" 
			IF get_url_query_where_text() IS NOT NULL THEN
			--IF num_args() > 0 THEN 
				IF select_them() THEN 
					SHOW option "Detail" 
				END IF 
			END IF 

			CALL publish_toolbar("kandoo","P65","menu-debits-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Query" " Enter selection criteria FOR Debits" 
			IF select_them() THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected debit" 
			FETCH NEXT debithead_set INTO glob_rec_debithead.* 
			IF status <> NOTFOUND THEN 
				CALL show_it() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9157,"") 
				#9157 You have reached the END of the entries selected"
				NEXT option "Previous" 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previously selected batch" 
			FETCH previous debithead_set INTO glob_rec_debithead.* 
			IF status <> NOTFOUND THEN 
				CALL show_it() 
			ELSE 
				LET l_msgresp = kandoomsg("G",9156,"") 
				#9156 You have reached the start of the entries selected"
				NEXT option "Next" 
			END IF 

		COMMAND KEY ("D",f20) "Detail" " View batch details" 

			MENU " Debit Details" 

				BEFORE MENU 
					IF glob_rec_debithead.dist_amt <= 0 THEN 
						HIDE option "Distribution" 
					END IF 
					SELECT unique 1 FROM wholdtax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_vend_code = glob_rec_debithead.vend_code 
					AND tax_tran_type = "2" 
					AND tax_ref_num = glob_rec_debithead.debit_num 
					IF status = NOTFOUND THEN 
						HIDE option "Tax Trans" 
					END IF 



					CALL publish_toolbar("kandoo","P65","menu-debit_details") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				COMMAND "Distribution" " View debit distributions" 
					CALL disp_debit_dis(glob_rec_kandoouser.cmpy_code, glob_rec_debithead.debit_num) 
				COMMAND "Tax Trans" " View associated tax transactions" 
					CALL dispwtax(glob_rec_kandoouser.cmpy_code, 
					glob_rec_debithead.vend_code, 
					"2", 
					glob_rec_debithead.debit_num) 
				COMMAND KEY(interrupt,"E") "Exit" " Exit FROM Details" 
					EXIT MENU 

			END MENU 
		COMMAND KEY ("F",f18) "First" " DISPLAY first batch in the selected list" 
			FETCH FIRST debithead_set INTO glob_rec_debithead.* 
			CALL show_it() 
			NEXT option "Next" 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last batch in the selected list" 
			FETCH LAST debithead_set INTO glob_rec_debithead.* 
			CALL show_it() 
			NEXT option "Previous" 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu" 
			EXIT MENU 

	END MENU 
END FUNCTION 


FUNCTION show_it() 
	DISPLAY BY NAME glob_rec_debithead.vend_code, 
	glob_rec_debithead.name_text, 
	glob_rec_debithead.debit_num, 
	glob_rec_debithead.batch_num, 
	glob_rec_debithead.dist_amt, 
	glob_rec_debithead.total_amt, 
	glob_rec_debithead.apply_amt, 
	glob_rec_debithead.disc_amt, 
	glob_rec_debithead.entry_code, 
	glob_rec_debithead.entry_date, 
	glob_rec_debithead.debit_text, 
	glob_rec_debithead.debit_date, 
	glob_rec_debithead.year_num, 
	glob_rec_debithead.period_num, 
	glob_rec_debithead.post_flag, 
	glob_rec_debithead.conv_qty, 
	glob_rec_debithead.jour_num, 
	glob_rec_debithead.com1_text, 
	glob_rec_debithead.com2_text 

	DISPLAY BY NAME glob_rec_debithead.currency_code 
	attribute (green) 
END FUNCTION 


