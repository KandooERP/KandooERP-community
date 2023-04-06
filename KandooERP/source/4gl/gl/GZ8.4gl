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
#Currency Maintenance
# \brief module - GZ8
# Purpose - Currency Conversion Rates
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_arr_rec_currency DYNAMIC ARRAY OF RECORD #array[250] OF 
		currency_code LIKE currency.currency_code, 
		desc_text LIKE currency.desc_text, 
		symbol_text LIKE currency.symbol_text 
	END RECORD 
	DEFINE glob_rec_rate_exchange RECORD LIKE rate_exchange.* 
	DEFINE glob_base_curr_code LIKE glparms.base_currency_code 
	#DEFINE counter SMALLINT
	#DEFINE l_idx SMALLINT
	#DEFINE cnt  SMALLINT
	#DEFINE err_flag  SMALLINT
	#DEFINE ans CHAR(1)
END GLOBALS 

###########################################################################
# FUNCTION GZ8_main()
#
#
###########################################################################
FUNCTION GZ8_main() 

	CALL setModuleId("GZ8") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) #authenticate 
	--CALL init_g_gl() #init g/gl general ledger module # is not required for Currency Codes Maint. KD-2128
 
	CALL currency_manager() 
END FUNCTION 
###########################################################################
# END FUNCTION GZ8_main()
###########################################################################


###########################################################################
# FUNCTION do_currency_get_datasource()
#
#
###########################################################################
FUNCTION do_currency_get_datasource()
	DEFINE l_arr_rec_currency DYNAMIC ARRAY OF RECORD  
		currency_code LIKE currency.currency_code, 
		desc_text LIKE currency.desc_text, 
		symbol_text LIKE currency.symbol_text 
	END RECORD 
 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_id_flag SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 

	SELECT base_currency_code 
	INTO glob_base_curr_code 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET glob_base_curr_code = NULL 
	END IF 

	DECLARE c_currency CURSOR FOR 
	SELECT * 
	INTO l_rec_currency.* 
	FROM currency 
	ORDER BY currency_code 

	LET l_idx = 0 
	FOREACH c_currency 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_currency[l_idx].currency_code = l_rec_currency.currency_code 
		LET l_arr_rec_currency[l_idx].desc_text = l_rec_currency.desc_text 
		LET l_arr_rec_currency[l_idx].symbol_text = l_rec_currency.symbol_text 
	END FOREACH 

	RETURN l_arr_rec_currency

END FUNCTION
###########################################################################
# FUNCTION do_currency_get_datasource()
###########################################################################


###########################################################################
# FUNCTION currency_manager()
#
#
###########################################################################
FUNCTION currency_manager() 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_id_flag SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_mode SMALLINT # constant MODE_INSERT = 1 / MODE_UPDATE = 2 / mode_delete = 3 

{
	SELECT base_currency_code 
	INTO glob_base_curr_code 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET glob_base_curr_code = NULL 
	END IF 

	DECLARE c_currency CURSOR FOR 
	SELECT * 
	INTO l_rec_currency.* 
	FROM currency 
	ORDER BY currency_code 

	LET l_idx = 0 
	FOREACH c_currency 
		LET l_idx = l_idx + 1 
		LET glob_arr_rec_currency[l_idx].currency_code = l_rec_currency.currency_code 
		LET glob_arr_rec_currency[l_idx].desc_text = l_rec_currency.desc_text 
		LET glob_arr_rec_currency[l_idx].symbol_text = l_rec_currency.symbol_text 
	END FOREACH 
}
	CALL do_currency_get_datasource() RETURNING glob_arr_rec_currency
	OPEN WINDOW G132 with FORM "G132" 
	CALL windecoration_g("G132") 

	MESSAGE kandoomsg2("G",1018,"") #1018 "F1 TO add, RETURN TO change, F10 TO maintain rates"

	LET l_mode = MODE_UPDATE 
	INPUT ARRAY glob_arr_rec_currency WITHOUT DEFAULTS FROM sr_currency.* attributes(UNBUFFERED, append ROW = FALSE, auto append = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ8","currencyList") 
			IF l_mode = MODE_UPDATE THEN 
				CALL DIALOG.SetFieldActive("currency_code", FALSE) #pk=currency_code 
			ELSE 
				CALL DIALOG.SetFieldActive("currency_code", TRUE) #pk=currency_code 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#ON ACTION/KEY
		ON ACTION "EXCHANGE RATE" #KEY (F10) 
			IF glob_arr_rec_currency[l_idx].currency_code IS NOT NULL THEN 
				CALL new_rate(glob_arr_rec_currency[l_idx].currency_code, l_idx) 
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_currency.currency_code = glob_arr_rec_currency[l_idx].currency_code 
			LET l_rec_currency.desc_text = glob_arr_rec_currency[l_idx].desc_text 
			LET l_rec_currency.symbol_text = glob_arr_rec_currency[l_idx].symbol_text 
			LET l_id_flag = 0 

		BEFORE INSERT 
			INITIALIZE l_rec_currency.* TO NULL 

			LET l_mode = MODE_INSERT 
			CALL DIALOG.SetFieldActive("currency_code", TRUE) #pk=currency_code 

		AFTER INSERT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			LET l_id_flag = -1 

			IF glob_arr_rec_currency[l_idx].currency_code IS NOT NULL THEN 
				LET l_rec_currency.currency_code = glob_arr_rec_currency[l_idx].currency_code 
				LET l_rec_currency.desc_text = glob_arr_rec_currency[l_idx].desc_text 
				LET l_rec_currency.symbol_text = glob_arr_rec_currency[l_idx].symbol_text 
				SELECT count(*) INTO l_counter FROM currency 
				WHERE currency_code = l_rec_currency.currency_code 

				IF l_counter = 0 THEN 

					INSERT INTO currency 
					VALUES (
						l_rec_currency.currency_code, 
						l_rec_currency.desc_text, 
						l_rec_currency.symbol_text) 
				END IF 
			END IF 
			
			LET l_mode = MODE_UPDATE 
			CALL DIALOG.SetFieldActive("currency_code", FALSE) #pk=currency_code 


		BEFORE DELETE 
			SELECT count(*) INTO l_counter FROM rate_exchange 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND currency_code = l_rec_currency.currency_code 
			IF l_counter != 0 THEN 
				ERROR kandoomsg2("G",9130,"")	#9130 "Rates exist FOR this code - cannot delete"
				NEXT FIELD currency_code 
			END IF 

		AFTER FIELD currency_code 
			IF glob_arr_rec_currency[l_idx].currency_code IS NULL AND glob_arr_rec_currency[l_idx].desc_text IS NOT NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD currency_code 
			END IF 

			IF glob_arr_rec_currency[l_idx].currency_code != l_rec_currency.currency_code OR l_rec_currency.currency_code IS NULL THEN 
				SELECT count(*) INTO l_counter 
				FROM currency 
				WHERE currency_code = glob_arr_rec_currency[l_idx].currency_code 
				IF l_counter != 0 THEN 
					ERROR kandoomsg2("U",9104,"") #9104 This RECORD already exists
					LET glob_arr_rec_currency[l_idx].* = l_rec_currency.* 
					NEXT FIELD currency_code 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			--NEXT FIELD symbol_text 

		AFTER DELETE 
			LET l_id_flag = -1 
			SELECT count(*) INTO l_counter FROM rate_exchange 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND currency_code = l_rec_currency.currency_code 
			IF l_counter != 0 THEN 
				ERROR kandoomsg2("G",9130,"")	#9130 "Rates exist FOR this code - cannot delete"
				NEXT FIELD currency_code 
			ELSE 
			
				DELETE FROM currency 
				WHERE currency_code = l_rec_currency.currency_code
				 
			END IF 

		AFTER ROW 
			IF (glob_arr_rec_currency[l_idx].currency_code IS NULL AND glob_arr_rec_currency[l_idx].desc_text IS NULL) THEN 
				LET l_id_flag = -1 
			END IF
			 
			IF NOT int_flag THEN 
				LET l_rec_currency.* = glob_arr_rec_currency[l_idx].* 
			
				IF l_id_flag = 0 THEN 
					SELECT count(*) 
					INTO l_counter 
					FROM currency 
					WHERE currency_code = l_rec_currency.currency_code 
					IF l_counter != 0 THEN 
						UPDATE currency SET 
							desc_text = l_rec_currency.desc_text, 
							symbol_text = l_rec_currency.symbol_text 
						WHERE currency_code = l_rec_currency.currency_code
						MESSAGE "Currency Exchange Rate Updated" 
					ELSE 
						INSERT INTO currency 
						VALUES (
							l_rec_currency.currency_code, 
							l_rec_currency.desc_text, 
							l_rec_currency.symbol_text) 
						MESSAGE "Currency Exchange Rate Created"
					END IF
					
					CONTINUE INPUT #?
					NEXT FIELD currency_code #? 
				END IF 
			END IF
					
		AFTER INPUT
			IF int_flag = FALSE THEN
				CONTINUE INPUT
			END IF
	END INPUT 

	IF int_flag THEN
		LET int_flag = FALSE
	END IF
	
	CLOSE WINDOW G132 

END FUNCTION 
###########################################################################
# END FUNCTION currency_manager()
###########################################################################


###########################################################################
# FUNCTION new_rate(p_currency_code,p_idx)
#
#
###########################################################################
FUNCTION new_rate(p_currency_code,p_idx) 
	DEFINE p_currency_code LIKE currency.currency_code 
	DEFINE p_idx SMALLINT 

	DEFINE l_arr_rec_rate DYNAMIC ARRAY OF RECORD 
		start_date DATE, 
		conv_buy_qty LIKE rate_exchange.conv_buy_qty, 
		conv_sell_qty LIKE rate_exchange.conv_sell_qty, 
		conv_budg_qty LIKE rate_exchange.conv_budg_qty 
	END RECORD 
	DEFINE l_sel_text STRING --CHAR(500) 
	DEFINE l_query_text STRING --CHAR(150) 
	DEFINE f9_entered SMALLINT 
	DEFINE i INTEGER 
	DEFINE s INTEGER 
	DEFINE l_total_selected INTEGER 

	OPEN WINDOW G163 with FORM "G163" 
	CALL windecoration_g("G163") 
	DISPLAY db_glparms_get_base_currency_code(1) TO base_currency_code #Feature Request by Ali and Anna - show base currency
	DISPLAY db_currency_get_desc_text(UI_OFF,db_glparms_get_base_currency_code(1)) TO base_currency_desc_text
	CALL ui.interface.refresh() 

	DISPLAY glob_arr_rec_currency[p_idx].currency_code TO currency_code 
	DISPLAY glob_arr_rec_currency[p_idx].desc_text TO desc_text 

	# SELECT last 50 exchange rates FOR first pass
	LET l_query_text = " 1=1 " 
	LET f9_entered = FALSE 
	WHILE TRUE 
		LET l_sel_text = 
		" SELECT * ", 
			" FROM rate_exchange ", 
			" WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
			" AND currency_code = \"", p_currency_code,"\" ", 
			" AND ", l_query_text clipped, 
			" ORDER BY start_date desc" 
		PREPARE rate_scan FROM l_sel_text 
		DECLARE ex_curs CURSOR FOR rate_scan 
		LET i = 1 

		FOREACH ex_curs INTO glob_rec_rate_exchange.* 
			LET l_arr_rec_rate[i].start_date = glob_rec_rate_exchange.start_date 
			LET l_arr_rec_rate[i].conv_buy_qty = glob_rec_rate_exchange.conv_buy_qty 
			LET l_arr_rec_rate[i].conv_sell_qty = glob_rec_rate_exchange.conv_sell_qty 
			LET l_arr_rec_rate[i].conv_budg_qty = glob_rec_rate_exchange.conv_budg_qty 
			LET i = i + 1 
			IF i > 50 THEN 
				ERROR kandoomsg2("U",6100,i-1) 		#First i records selected
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET i = i - 1 
		MESSAGE kandoomsg2("U",9113,i) #i records selected
		LET l_total_selected = i 

		IF NOT (f9_entered AND l_total_selected = 0) THEN 
			MESSAGE kandoomsg2("G",1026,"")	#1026 "F1 TO add, RETURN TO change, F2 TO delete, F9 TO re-SELECT"
			--CALL set_count(i) 
			LET f9_entered = FALSE 
			OPTIONS DELETE KEY f36 

			INPUT ARRAY l_arr_rec_rate WITHOUT DEFAULTS FROM sr_rate.* attribute(UNBUFFERED, append ROW = FALSE, auto append = FALSE) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","GZ8","currencyXRList") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET i = arr_curr() 
					LET s = scr_line() 
					LET glob_rec_rate_exchange.start_date = l_arr_rec_rate[i].start_date 
					LET glob_rec_rate_exchange.conv_buy_qty = l_arr_rec_rate[i].conv_buy_qty 
					LET glob_rec_rate_exchange.conv_sell_qty = l_arr_rec_rate[i].conv_sell_qty 
					LET glob_rec_rate_exchange.conv_budg_qty = l_arr_rec_rate[i].conv_budg_qty 

					IF i <= l_total_selected THEN 
						DISPLAY l_arr_rec_rate[i].* TO sr_rate[s].* 
					END IF 
				BEFORE INSERT 
					INITIALIZE glob_rec_rate_exchange.* TO NULL 
					CALL add_rates(p_currency_code) 
					LET l_arr_rec_rate[i].start_date = glob_rec_rate_exchange.start_date 
					LET l_arr_rec_rate[i].conv_buy_qty = glob_rec_rate_exchange.conv_buy_qty 
					LET l_arr_rec_rate[i].conv_sell_qty = glob_rec_rate_exchange.conv_sell_qty 
					LET l_arr_rec_rate[i].conv_budg_qty = glob_rec_rate_exchange.conv_budg_qty 

					DISPLAY l_arr_rec_rate[i].* TO sr_rate[s].* 

					EXIT INPUT 

				ON KEY (F2) 
					CALL check_delete(p_currency_code) 
					EXIT INPUT 

				ON KEY (F9) 
					LET f9_entered = TRUE 
					EXIT INPUT 

				BEFORE FIELD conv_buy_qty 
					IF l_arr_rec_rate[i].start_date IS NOT NULL THEN 
						CALL change_rates(p_currency_code) --edit ex-rate window/function 
						LET l_arr_rec_rate[i].start_date = glob_rec_rate_exchange.start_date 
						LET l_arr_rec_rate[i].conv_buy_qty = glob_rec_rate_exchange.conv_buy_qty 
						LET l_arr_rec_rate[i].conv_sell_qty = glob_rec_rate_exchange.conv_sell_qty 
						LET l_arr_rec_rate[i].conv_budg_qty = glob_rec_rate_exchange.conv_budg_qty 
						DISPLAY l_arr_rec_rate[i].* TO sr_rate[s].* 

						EXIT INPUT 
					END IF 

				AFTER ROW 
					LET l_arr_rec_rate[i].start_date = glob_rec_rate_exchange.start_date 
					LET l_arr_rec_rate[i].conv_buy_qty = glob_rec_rate_exchange.conv_buy_qty 
					LET l_arr_rec_rate[i].conv_sell_qty = glob_rec_rate_exchange.conv_sell_qty 
					LET l_arr_rec_rate[i].conv_budg_qty = glob_rec_rate_exchange.conv_budg_qty 
					IF i <= l_total_selected THEN 
						DISPLAY l_arr_rec_rate[i].* TO sr_rate[s].* 

					END IF 
			END INPUT 

			OPTIONS DELETE KEY f2 
		END IF 

		IF f9_entered THEN 
			CLEAR FORM 
			DISPLAY glob_arr_rec_currency[p_idx].currency_code TO currency_code 
			DISPLAY glob_arr_rec_currency[p_idx].desc_text TO desc_text 

			MESSAGE kandoomsg2("G",1068,"")	#1068 "Enter start date FOR scan press ESC"

			CONSTRUCT l_query_text ON start_date FROM sr_rate[1].start_date 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GZ8","query") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	CLOSE WINDOW G163 

END FUNCTION 
###########################################################################
# END FUNCTION new_rate(p_currency_code,p_idx)
###########################################################################


###########################################################################
# FUNCTION add_rates(p_currency_code)
#
#
###########################################################################
FUNCTION add_rates(p_currency_code) 
	DEFINE p_currency_code LIKE currency.currency_code 
	DEFINE l_counter SMALLINT 

	OPEN WINDOW G191 with FORM "G191" 
	CALL windecoration_g("G191") 

	LET glob_rec_rate_exchange.start_date = today 
	
	INPUT BY NAME 
		glob_rec_rate_exchange.start_date, 
		glob_rec_rate_exchange.conv_buy_qty, 
		glob_rec_rate_exchange.conv_sell_qty, 
		glob_rec_rate_exchange.conv_budg_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ8","currencyExchRate2?") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD start_date 
			IF glob_rec_rate_exchange.start_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")		#9102 Value must be entered
				NEXT FIELD start_date 
			ELSE 
				SELECT count(*) INTO l_counter FROM rate_exchange 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND currency_code = p_currency_code 
				AND start_date = glob_rec_rate_exchange.start_date 
				IF l_counter != 0 THEN 
					ERROR kandoomsg2("G",9131,"")	#9131 "Rates already exist FOR this date - change OR delete"
					NEXT FIELD start_date 
				END IF 
			END IF 

		AFTER FIELD conv_buy_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_buy_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
					NEXT FIELD conv_buy_qty 
				
				WHEN (glob_rec_rate_exchange.conv_buy_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")		#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_buy_qty 
				
				WHEN (glob_rec_rate_exchange.conv_buy_qty != 1 AND 
					p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"") 	#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_buy_qty 
			END CASE 
			
			LET glob_rec_rate_exchange.conv_sell_qty = glob_rec_rate_exchange.conv_buy_qty 
			LET glob_rec_rate_exchange.conv_budg_qty = glob_rec_rate_exchange.conv_buy_qty 
			
			DISPLAY glob_rec_rate_exchange.conv_sell_qty TO conv_sell_qty 
			DISPLAY glob_rec_rate_exchange.conv_budg_qty TO conv_budg_qty 

		AFTER FIELD conv_sell_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_sell_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
					NEXT FIELD conv_sell_qty 
				WHEN (glob_rec_rate_exchange.conv_sell_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")	#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_sell_qty 
				WHEN (glob_rec_rate_exchange.conv_sell_qty != 1 AND	p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"") 	#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_sell_qty 
			END CASE 

		AFTER FIELD conv_budg_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_budg_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
					NEXT FIELD conv_budg_qty 
				WHEN (glob_rec_rate_exchange.conv_budg_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")				#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_budg_qty 
				WHEN (glob_rec_rate_exchange.conv_budg_qty != 1 AND 
					p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"") 		#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_budg_qty 
			END CASE 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
			IF glob_rec_rate_exchange.conv_buy_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD conv_buy_qty 
			END IF 
			
			IF glob_rec_rate_exchange.conv_sell_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD conv_sell_qty 
			END IF 
			
			IF glob_rec_rate_exchange.conv_budg_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")		#9102 Value must be entered
				NEXT FIELD conv_budg_qty 
			END IF 

	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		LET glob_rec_rate_exchange.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_rate_exchange.currency_code = p_currency_code 

		INSERT INTO rate_exchange 
		VALUES (glob_rec_rate_exchange.*) 
	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	CLOSE WINDOW G191 

END FUNCTION 
###########################################################################
# END FUNCTION add_rates(p_currency_code)
###########################################################################



###########################################################################
# FUNCTION change_rates(p_currency_code)
#
#
###########################################################################
FUNCTION change_rates(p_currency_code) 
	DEFINE p_currency_code LIKE currency.currency_code 

	OPEN WINDOW G191 with FORM "G191" attribute (border) #this WINDOW IS floating 
	CALL windecoration_g("G191") 

	DISPLAY BY NAME glob_rec_rate_exchange.start_date 

	INPUT BY NAME 
		glob_rec_rate_exchange.conv_buy_qty, 
		glob_rec_rate_exchange.conv_sell_qty, 
		glob_rec_rate_exchange.conv_budg_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ8","currencyXREdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD conv_buy_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_buy_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
					NEXT FIELD conv_buy_qty 
				WHEN (glob_rec_rate_exchange.conv_buy_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")		#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_buy_qty 
				WHEN (glob_rec_rate_exchange.conv_buy_qty != 1 AND 
					p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"")	#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_buy_qty 
			END CASE 
			
		AFTER FIELD conv_sell_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_sell_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
					NEXT FIELD conv_sell_qty 
				WHEN (glob_rec_rate_exchange.conv_sell_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")			#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_sell_qty 
				WHEN (glob_rec_rate_exchange.conv_sell_qty != 1 AND		p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"") 		#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_sell_qty 
			END CASE 
		
		AFTER FIELD conv_budg_qty 
			CASE 
				WHEN (glob_rec_rate_exchange.conv_budg_qty IS NULL) 
					ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
					NEXT FIELD conv_budg_qty 
				WHEN (glob_rec_rate_exchange.conv_budg_qty <= 0) 
					ERROR kandoomsg2("G",9025,"Exchange Rate")				#9025 "Exchange rate must be greater than 0"
					NEXT FIELD conv_budg_qty 
				WHEN (glob_rec_rate_exchange.conv_budg_qty != 1 AND 
					p_currency_code = glob_base_curr_code) 
					ERROR kandoomsg2("G",9155,"") 			#9155 "Exchange rate must be 1 FOR base currency"
					NEXT FIELD conv_budg_qty 
			END CASE 
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
			IF glob_rec_rate_exchange.conv_buy_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
				NEXT FIELD conv_buy_qty 
			END IF 
			
			IF glob_rec_rate_exchange.conv_sell_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD conv_sell_qty 
			END IF 
			
			IF glob_rec_rate_exchange.conv_budg_qty IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")		#9102 Value must be entered
				NEXT FIELD conv_budg_qty 
			END IF 

	END INPUT 
	#-------------------------------------------------------------------------------

	IF NOT (int_flag OR quit_flag) THEN 
		UPDATE rate_exchange SET 
			conv_buy_qty = glob_rec_rate_exchange.conv_buy_qty, 
			conv_sell_qty = glob_rec_rate_exchange.conv_sell_qty ,
			conv_budg_qty = glob_rec_rate_exchange.conv_budg_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND currency_code = p_currency_code 
		AND start_date = glob_rec_rate_exchange.start_date 
	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	CLOSE WINDOW G191 
END FUNCTION 
###########################################################################
# END FUNCTION change_rates(p_currency_code)
###########################################################################


###########################################################################
# FUNCTION check_delete(p_currency_code)
#
#
###########################################################################
FUNCTION check_delete(p_currency_code) 
	DEFINE p_currency_code LIKE currency.currency_code 

	IF kandoomsg("G",8028,"") = "Y" THEN  #8020 "Delete this Exchange Rate? (Y/N)"
		DELETE FROM rate_exchange 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND currency_code = p_currency_code 
		AND start_date = glob_rec_rate_exchange.start_date 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION check_delete(p_currency_code)
###########################################################################