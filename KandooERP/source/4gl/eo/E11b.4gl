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
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"

###########################################################################
# FUNCTION pay_detail()
#
#
###########################################################################
FUNCTION pay_detail() 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	IF glob_rec_orderhead.cond_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO l_rec_condsale.desc_text 
		FROM condsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = glob_rec_orderhead.cond_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",9055,"") #9055 Sales Condition does NOT exist - Try Window"
			LET glob_rec_sales_order_parameter.paydetl_flag = "Y" 
			LET l_rec_condsale.desc_text = "**********" 
		END IF 
	END IF 

	SELECT desc_text 
	INTO l_rec_term.desc_text 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_orderhead.term_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		ERROR kandoomsg2("E",9056,"") #9056" Payment Terms do NOT exist - try window"
		LET glob_rec_sales_order_parameter.paydetl_flag = "Y" 
		LET l_rec_term.desc_text = "**********" 
	END IF 

	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_orderhead.tax_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		ERROR kandoomsg2("E",9057,"") #9057" Taxation Code do NOT exist "
		LET glob_rec_sales_order_parameter.paydetl_flag = "Y" 
		LET l_rec_tax.desc_text = "**********" 
	END IF 
	
	IF glob_rec_orderhead.conv_qty IS NULL OR glob_rec_orderhead.conv_qty = 0 THEN 
		LET glob_rec_orderhead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_orderhead.currency_code, 
			glob_rec_orderhead.order_date,
			CASH_EXCHANGE_SELL) 
	END IF 

	IF glob_rec_sales_order_parameter.paydetl_flag = "Y" THEN 
		OPEN WINDOW E112 with FORM "E112" 
		 CALL windecoration_e("E112") -- albo kd-755 
		MESSAGE kandoomsg2("E",1016,"") 	#1016 Enter Payment Details - F8 Customer Inquiry - F9 Credit Details

		DISPLAY l_rec_condsale.desc_text TO condsale.desc_text 
		DISPLAY l_rec_term.desc_text TO term.desc_text 
		DISPLAY l_rec_tax.desc_text TO tax.desc_text 

		DISPLAY BY NAME glob_rec_orderhead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

		INPUT BY NAME 
			glob_rec_orderhead.cond_code, 
			glob_rec_orderhead.term_code, 
			glob_rec_orderhead.tax_code, 
			glob_rec_orderhead.conv_qty 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11b","input-glob_rec_orderhead-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()

			ON ACTION "LOOKUP" infield(cond_code) 
						LET glob_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
						IF glob_temp_text IS NOT NULL THEN 
							LET glob_rec_orderhead.cond_code = glob_temp_text 
						END IF 
						NEXT FIELD cond_code 
						
			ON ACTION "LOOKUP" infield(term_code) 
						LET glob_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
						IF glob_temp_text IS NOT NULL THEN 
							LET glob_rec_orderhead.term_code = glob_temp_text 
						END IF 
						NEXT FIELD term_code 
						
			ON ACTION "LOOKUP" infield(tax_code) 
						LET glob_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
						IF glob_temp_text IS NOT NULL THEN 
							LET glob_rec_orderhead.tax_code = glob_temp_text 
						END IF 
						NEXT FIELD tax_code 
 

			ON ACTION "DETAILS" --ON KEY (f8) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) --customer details / customer invoice submenu 

			ON ACTION "PAYMENT DETAILS" --KEY (f9) 
				CALL view_cust(glob_rec_orderhead.cust_code) 

			AFTER FIELD cond_code 
				CLEAR condsale.desc_text 
				IF glob_rec_orderhead.cond_code IS NULL THEN 
					IF glob_rec_customer.cond_code IS NOT NULL THEN 
						
						IF kandoomsg("E",8011,"") = "Y" THEN #8011 Condition NOT Entered. Use Cust's Condition.Y/N
							LET glob_rec_orderhead.cond_code = glob_rec_customer.cond_code 
							NEXT FIELD cond_code 
						END IF 
					END IF 

				ELSE 

					SELECT desc_text 
					INTO l_rec_condsale.desc_text 
					FROM condsale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cond_code = glob_rec_orderhead.cond_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9055,"") 		#9055" Sales cond do NOT exist "
						NEXT FIELD cond_code 
					ELSE 
						DISPLAY l_rec_condsale.desc_text TO condsale.desc_text 

						IF glob_rec_customer.inv_level_ind != "L" THEN 
							ERROR kandoomsg2("E",7031,"") #7031 Warning: In Nominating a sales condition customer prices will NOT be AT normal pricing level
        		END IF 
					END IF 
				END IF 

			AFTER FIELD term_code 
				CLEAR term.desc_text 
				IF glob_rec_orderhead.term_code IS NULL THEN 
					ERROR kandoomsg2("E",9058,"") 		#9058" Payment Term must be Entered"
					LET glob_rec_orderhead.term_code = glob_rec_customer.term_code 
					NEXT FIELD term_code 
				ELSE 
					SELECT * INTO l_rec_term.* 
					FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = glob_rec_orderhead.term_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9056,"") 		#9056" Sales Conditions does NOT exist "
						NEXT FIELD term_code 
					ELSE 
						DISPLAY l_rec_term.desc_text TO term.desc_text
					END IF 
				END IF 

			AFTER FIELD tax_code 
				CLEAR tax.desc_text 
				IF glob_rec_orderhead.tax_code IS NULL THEN 
					ERROR kandoomsg2("E",9059,"") 	#9059" Taxation Code must be Entered"
					LET glob_rec_orderhead.tax_code = glob_rec_customer.tax_code 
					NEXT FIELD tax_code 
				ELSE 
					SELECT * INTO l_rec_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = glob_rec_orderhead.tax_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9057,"") 				#9057" Taxation Code do NOT exist "
						NEXT FIELD tax_code 
					ELSE 
						DISPLAY l_rec_tax.desc_text TO tax.desc_text
					END IF 
				END IF 

			BEFORE FIELD conv_qty 
				IF glob_rec_sales_order_parameter.base_curr_code = glob_rec_orderhead.currency_code THEN 
					LET glob_rec_orderhead.conv_qty = 1.0 
					DISPLAY BY NAME glob_rec_orderhead.conv_qty 
				END IF 

			AFTER FIELD conv_qty 
				IF glob_rec_orderhead.conv_qty IS NULL OR glob_rec_orderhead.conv_qty = 0 THEN 
					ERROR kandoomsg2("E",9060,"") 		#9060" Currency Exchange Rate must have a value "
					LET glob_rec_orderhead.conv_qty = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_orderhead.currency_code,	
						glob_rec_orderhead.order_date,
						CASH_EXCHANGE_SELL) 
					NEXT FIELD conv_qty 
				END IF 
				
				IF glob_rec_orderhead.conv_qty < 0 THEN 
					ERROR kandoomsg2("E",9061,"") 		#9061 " Exchange Rate must be greater than zero "
					NEXT FIELD conv_qty 
				END IF 
				
				IF glob_rec_orderhead.conv_qty != get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_orderhead.currency_code,	
					glob_rec_orderhead.order_date,
					CASH_EXCHANGE_SELL) THEN 
					
					IF kandoomsg("E",8012,"") = "Y"	THEN		#8012 Exchange Rate IS NOT current. Do you wish TO Update.Y/N
						LET glob_rec_orderhead.conv_qty =	get_conv_rate(
							glob_rec_kandoouser.cmpy_code,
							glob_rec_orderhead.currency_code, 
							glob_rec_orderhead.order_date,
							CASH_EXCHANGE_SELL) 
						NEXT FIELD conv_qty 
					END IF 
				END IF 
				
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					SELECT unique 1 FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = glob_rec_orderhead.term_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9056,"") 				#9056 Payment Terms do NOT exist try window
						NEXT FIELD term_code 
					END IF 
					
					SELECT * INTO l_rec_tax.* FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = glob_rec_orderhead.tax_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9057,"") 		#9057" Taxation Code do NOT exist "
						NEXT FIELD tax_code 
					ELSE 
						IF l_rec_tax.calc_method_flag = "X" THEN 
							
							IF (glob_rec_customer.last_mail_date < glob_rec_orderhead.order_date) 
							OR (glob_rec_customer.last_mail_date IS null) 
							OR (glob_rec_customer.tax_num_text IS null) THEN 
								IF glob_rec_orderhead.tax_cert_text IS NULL THEN 
									LET glob_rec_orderhead.tax_cert_text = enter_exempt_num(glob_rec_kandoouser.cmpy_code,	glob_rec_orderhead.tax_code, glob_rec_customer.tax_num_text) 
								ELSE 
									LET glob_rec_orderhead.tax_cert_text = enter_exempt_num(glob_rec_kandoouser.cmpy_code,	glob_rec_orderhead.tax_code, glob_rec_orderhead.tax_cert_text) 
								END IF								
							END IF 
							
						END IF 
					END IF 
				END IF 

		END INPUT 
		
		CLOSE WINDOW E112 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION pay_detail() 
############################################################


###########################################################################
# FUNCTION commission() 
#
#
###########################################################################
FUNCTION commission() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_arr_rec_saleshare DYNAMIC ARRAY OF RECORD 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		share_per LIKE saleshare.share_per 
	END RECORD 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_scr SMALLINT
	DEFINE l_total_per FLOAT 
	DEFINE i SMALLINT

	OPEN WINDOW E109 with FORM "E109" 
	CALL windecoration_e("E109")  

	IF glob_rec_orderhead.sales_code IS NOT NULL THEN 
		SELECT name_text 
		INTO l_rec_salesperson.name_text 
		FROM salesperson 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = glob_rec_orderhead.sales_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",9050,"") 		#9050" Salesperson code does NOT exist "
			LET l_rec_salesperson.name_text = "**********" 
		END IF 
	END IF 

	IF glob_rec_orderhead.territory_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO l_rec_territory.desc_text 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = glob_rec_orderhead.territory_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ERROR kandoomsg2("E",9063,"") 		#9063" Sales Territory does NOT exist Try Window
			LET l_rec_territory.desc_text = "**********" 
		END IF 
	END IF 

	LET i = 1 
	LET l_idx = 0 
	LET l_total_per = 0 
	SELECT unique 1 FROM t_saleshare 
	IF sqlca.sqlcode = NOTFOUND THEN 
		INSERT INTO t_saleshare 
		SELECT * 
		FROM saleshare 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = glob_rec_orderhead.order_num 
	END IF 

	DECLARE c_saleshare cursor FOR 
	SELECT sale_code,share_per FROM t_saleshare 
	
	CALL l_arr_rec_saleshare.CLEAR()
	FOREACH c_saleshare INTO l_arr_rec_saleshare[i].sale_code, 
		l_arr_rec_saleshare[i].share_per 
		SELECT name_text 
		INTO l_arr_rec_saleshare[i].name_text 
		FROM salesperson 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_arr_rec_saleshare[i].sale_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_arr_rec_saleshare[i].name_text = "**********" 
		END IF 
		LET l_total_per = l_total_per + l_arr_rec_saleshare[i].share_per 
		LET l_idx = l_idx + 1 
		IF l_idx <= 4 THEN 
			DISPLAY l_arr_rec_saleshare[l_idx].* 
			TO sr_saleshare[l_idx].* 
		END IF 
		LET i = i + 1 
		DISPLAY l_total_per TO total_per
	END FOREACH 

	MESSAGE kandoomsg2("E",1023,"") #1023 Enter Sales Commission Details - ESC TO Continue

	WHILE TRUE 
		CLEAR FORM
		OPTIONS INPUT NO WRAP
		INPUT BY NAME 
			glob_rec_orderhead.sales_code,
			glob_rec_orderhead.territory_code	WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11b","input-glob_rec_orderhead-2") -- albo kd-502 
				DISPLAY glob_rec_orderhead.sales_code TO orderhead.sales_code 
				DISPLAY l_rec_salesperson.name_text TO formonly.sale_text 
				DISPLAY glob_rec_orderhead.territory_code TO orderhead.territory_code 
				DISPLAY l_rec_territory.desc_text TO territory.desc_text

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
			
			ON ACTION "LOOKUP" infield(sales_code)  
					LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.sales_code = glob_temp_text 
						NEXT FIELD sales_code 
					END IF 
					
			ON ACTION "LOOKUP" infield(territory_code)  
					LET glob_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
					IF glob_temp_text IS NOT NULL THEN 
						LET glob_rec_orderhead.territory_code = glob_temp_text 
						NEXT FIELD territory_code 
					END IF 
				
			ON CHANGE sales_code
				SELECT name_text, terri_code 
				INTO l_rec_salesperson.name_text,l_rec_salesperson.terri_code 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = glob_rec_orderhead.sales_code 
				IF sqlca.sqlcode = NOTFOUND THEN 						
					ERROR kandoomsg2("E",9050,"") #9050" Salesperson code does NOT exist "
					NEXT FIELD sales_code 
				ELSE 
					IF glob_rec_orderhead.territory_code IS NULL THEN 
						LET glob_rec_orderhead.territory_code = l_rec_salesperson.terri_code 
					END IF 
					DISPLAY l_rec_salesperson.name_text TO sale_text 
					DISPLAY glob_rec_orderhead.territory_code TO  territory_code 
				END IF

			ON CHANGE territory_code
				SELECT desc_text 
				INTO l_rec_territory.desc_text 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = glob_rec_orderhead.territory_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("E",9063,"") 				#9063" sales territory code does NOT exist "
					NEXT FIELD territory_code 
				ELSE 
					DISPLAY BY NAME l_rec_territory.desc_text 
				END IF 

			AFTER FIELD sales_code 
				CLEAR sale_text 
				IF glob_rec_orderhead.sales_code IS NULL THEN 
					ERROR kandoomsg2("E",9062,"") 				#9062" Must enter sales person"
					NEXT FIELD sales_code 
				ELSE 
					SELECT name_text, terri_code 
					INTO l_rec_salesperson.name_text,	l_rec_salesperson.terri_code 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = glob_rec_orderhead.sales_code 
					IF sqlca.sqlcode = NOTFOUND THEN 						
						ERROR kandoomsg2("E",9050,"") #9050" Salesperson code does NOT exist "
						NEXT FIELD sales_code 
					ELSE 
						IF glob_rec_orderhead.territory_code IS NULL THEN 
							LET glob_rec_orderhead.territory_code = l_rec_salesperson.terri_code 
						END IF 

						DISPLAY l_rec_salesperson.name_text TO sale_text 
						DISPLAY glob_rec_orderhead.territory_code TO  territory_code 
					END IF 
				END IF 

			AFTER FIELD territory_code 
				CLEAR desc_text 
				IF glob_rec_orderhead.territory_code IS NULL THEN 
					ERROR kandoomsg2("E",9064,"") 			#9064" Must enter territory "
					NEXT FIELD territory_code 
				ELSE 
					SELECT desc_text 
					INTO l_rec_territory.desc_text 
					FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terr_code = glob_rec_orderhead.territory_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9063,"") 				#9063" sales territory code does NOT exist "
						NEXT FIELD territory_code 
					ELSE 
						DISPLAY BY NAME l_rec_territory.desc_text 
					END IF 
				END IF 

			AFTER INPUT 
				IF NOT(int_flag OR quit_flag)then 
					SELECT desc_text 
					INTO l_rec_territory.desc_text 
					FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terr_code = glob_rec_orderhead.territory_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						ERROR kandoomsg2("E",9063,"") 		#9063" sales territory code does NOT exist "
						NEXT FIELD territory_code 
					END IF 
				END IF 

		END INPUT 
		OPTIONS INPUT WRAP

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		IF l_idx = 0 THEN 
			LET l_arr_rec_saleshare[1].sale_code = glob_rec_orderhead.sales_code 
			LET l_arr_rec_saleshare[1].name_text = l_rec_salesperson.name_text 
			LET l_arr_rec_saleshare[1].share_per = 100 
			INSERT INTO t_saleshare VALUES (glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.order_num,glob_rec_orderhead.sales_code,100) 
		END IF 

		INPUT ARRAY l_arr_rec_saleshare WITHOUT DEFAULTS FROM sr_saleshare.* ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, AUTO APPEND = FALSE)
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11b","input-l_arr_rec_saleshare-1")  
{ -- albo
			BEFORE FIELD share_per 
				IF l_arr_rec_saleshare[l_idx].share_per IS NULL	OR l_arr_rec_saleshare[l_idx].share_per = 0 THEN 
					LET l_arr_rec_saleshare[l_idx].share_per = 100 - l_total_per 
				END IF 
}
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
			 								
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "LOOKUP" infield(sale_code) 
					LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					IF glob_temp_text IS NOT NULL THEN 
						LET l_arr_rec_saleshare[l_idx].sale_code = glob_temp_text 
						NEXT FIELD sale_code 
					END IF 

			ON CHANGE sale_code
				LET l_idx = arr_curr()
				LET l_scr = scr_line()
				SELECT name_text 
				INTO l_arr_rec_saleshare[l_idx].name_text 
				FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_arr_rec_saleshare[l_idx].sale_code 
				IF STATUS = NOTFOUND THEN
					NEXT FIELD sale_code
				ELSE 
					DISPLAY l_arr_rec_saleshare[l_idx].name_text TO sr_saleshare[l_scr].name_text
				END IF 

			AFTER FIELD sale_code 
				LET l_idx = arr_curr()
				LET l_scr = scr_line()
				IF glob_rec_orderhead.sales_code IS NOT NULL THEN
					FOR i = 1 TO l_arr_rec_saleshare.getSize() 
						IF l_arr_rec_saleshare[i].sale_code = l_arr_rec_saleshare[l_idx].sale_code 
						AND l_arr_rec_saleshare[i].sale_code IS NOT NULL THEN 
							IF i != l_idx THEN 
								ERROR kandoomsg2("E",9066,"") 			#9066" This salesperson already has a share"
								NEXT FIELD sale_code 
							END IF 
						END IF 
					END FOR 

					SELECT name_text 
					INTO l_arr_rec_saleshare[l_idx].name_text 
					FROM salesperson 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sale_code = l_arr_rec_saleshare[l_idx].sale_code 
					IF STATUS = NOTFOUND THEN
						NEXT FIELD sale_code
					ELSE 
						DISPLAY l_arr_rec_saleshare[l_idx].name_text TO sr_saleshare[l_scr].name_text
					END IF 
				END IF 
				
			AFTER FIELD share_per 
				LET l_idx = arr_curr()
				IF l_arr_rec_saleshare[l_idx].share_per < 0 THEN 
					ERROR kandoomsg2("E",9067,"") 	#9067" Saleperson percentage must NOT be less than zero"
					NEXT FIELD share_per 
				END IF 

				IF l_arr_rec_saleshare[l_idx].share_per > 100 THEN 
					ERROR kandoomsg2("E",9068,"") 	#9068" Saleperson percentage must NOT exceed 100 percent"
					NEXT FIELD share_per 
				END IF 

			AFTER ROW 
				LET l_idx = arr_curr()
				IF l_arr_rec_saleshare[l_idx].sale_code IS NOT NULL THEN 
					IF l_arr_rec_saleshare[l_idx].share_per IS NULL THEN 
						LET l_arr_rec_saleshare[l_idx].share_per = 0 
					END IF 
				ELSE 
					LET l_arr_rec_saleshare[l_idx].share_per = "" 
				END IF 
				LET l_total_per = 0 
				FOR i = 1 TO arr_count() 
					IF l_arr_rec_saleshare[i].share_per IS NOT NULL THEN 
						LET l_total_per = l_total_per + l_arr_rec_saleshare[i].share_per 
					END IF 
				END FOR 
				IF l_total_per > 100 THEN 
					ERROR kandoomsg2("E",9178,"") 				#9178 Total Percentage must NOT exceed 100"
					NEXT FIELD share_per 
				END IF 
				DISPLAY l_total_per TO total_per

			AFTER INPUT 
				IF NOT(int_flag OR quit_flag) THEN 
					IF l_total_per = 100 THEN 
						DELETE FROM t_saleshare 
						FOR i = 1 TO arr_count() 
							IF l_arr_rec_saleshare[i].sale_code IS NOT NULL	AND l_arr_rec_saleshare[i].share_per > 0 THEN 
								INSERT INTO t_saleshare 
								VALUES (
									glob_rec_kandoouser.cmpy_code, 
									glob_rec_orderhead.order_num, 
									l_arr_rec_saleshare[i].sale_code, 
									l_arr_rec_saleshare[i].share_per) 
							END IF 
						END FOR 
					ELSE 
						ERROR kandoomsg2("E",9065,"") 				#9065" Total Percentage must equal 100"
						NEXT FIELD sale_code 
					END IF 
				END IF 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW E109 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		DELETE FROM t_saleshare WHERE 1=1 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION commission() 
############################################################


###########################################################################
# FUNCTION stock_line(p_key_num,p_mode,p_in_trans)
#
#
###########################################################################
FUNCTION stock_line(p_key_num,p_mode,p_in_trans) 
	DEFINE p_key_num INTEGER 
	DEFINE p_mode char(3) 
	DEFINE p_in_trans INTEGER 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rowid INTEGER 
	DEFINE l_err_message char(60) 

	LET glob_temp_text = 
		"SELECT rowid,* FROM prodstatus ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND part_code = ? ", 
		"AND ware_code = ? ", 
		"AND stocked_flag = 'Y' " 
	PREPARE s_pdstatus FROM glob_temp_text 
	DECLARE c_pdstatus cursor FOR s_pdstatus 

	IF p_key_num IS NOT NULL THEN 
		WHENEVER ERROR GOTO recovery 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message,status) != "Y" THEN 
			CALL errorlog(l_err_message) 
			RETURN 0 #### ROLLBACK no retry 
		ELSE 
			IF p_in_trans THEN 
				RETURN -1 #### ROLLBACK try again 
			END IF 
		END IF 
		LABEL bypass: 

		IF NOT p_in_trans THEN 
			BEGIN WORK 
			END IF 
			IF p_mode = TRAN_TYPE_ORDER_ORD THEN 
				LET glob_temp_text = 
					"SELECT * FROM orderdetl ", 
					"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND order_num = '",p_key_num,"'" 
			ELSE 
				LET glob_temp_text = 
					"SELECT * FROM t_orderdetl ", 
					"WHERE line_num = '",p_key_num,"'" 
			END IF
			 
			LET glob_temp_text = 
				glob_temp_text clipped," ", 
				"AND part_code IS NOT NULL ", 
				"AND (sched_qty != 0 OR conf_qty != 0 ", 
				" OR picked_qty != 0 OR back_qty != 0)" 
			PREPARE s_orderdetl FROM glob_temp_text 
			DECLARE c_orderdetl cursor with hold FOR s_orderdetl 
			
			FOREACH c_orderdetl INTO l_rec_orderdetl.* 
				LET l_err_message = 
					"Error reserving stock FOR ", 
					" Ware: ",l_rec_orderdetl.ware_code clipped, 
					" Part: ",l_rec_orderdetl.part_code 
				OPEN c_pdstatus USING l_rec_orderdetl.part_code,l_rec_orderdetl.ware_code 
				FETCH c_pdstatus INTO l_rowid, l_rec_prodstatus.* 
				IF sqlca.sqlcode = 0 THEN 
					CASE 
						WHEN p_mode = TRAN_TYPE_INVOICE_IN 
							### picked_qty has been added TO sched_qty prior TO edit
							LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty	- l_rec_orderdetl.sched_qty	- l_rec_orderdetl.conf_qty 
							LET l_rec_prodstatus.back_qty = l_rec_prodstatus.back_qty	- l_rec_orderdetl.back_qty 
						WHEN p_mode = "OUT" 
							### picked_qty has been SET TO zero
							LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty + l_rec_orderdetl.sched_qty	+ l_rec_orderdetl.conf_qty 
							LET l_rec_prodstatus.back_qty = l_rec_prodstatus.back_qty + l_rec_orderdetl.back_qty 
						WHEN p_mode = TRAN_TYPE_ORDER_ORD 
							### picked_qty still on original ORDER IF backing out
							LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty	+ l_rec_orderdetl.sched_qty	+ l_rec_orderdetl.picked_qty + l_rec_orderdetl.conf_qty 
							LET l_rec_prodstatus.back_qty = l_rec_prodstatus.back_qty + l_rec_orderdetl.back_qty 
					END CASE 
					
					UPDATE prodstatus #update product status with the new quantities 
					SET 
						reserved_qty = l_rec_prodstatus.reserved_qty, 
						back_qty = l_rec_prodstatus.back_qty 
					WHERE rowid = l_rowid 
					WHENEVER ERROR stop 
				END IF 

			END FOREACH 

			IF NOT p_in_trans THEN 
			COMMIT WORK 
		END IF 
	END IF 

	RETURN 1 #### everything ok COMMIT WORK 
END FUNCTION 
############################################################
# END FUNCTION stock_line(p_key_num,p_mode,p_in_trans) 
############################################################