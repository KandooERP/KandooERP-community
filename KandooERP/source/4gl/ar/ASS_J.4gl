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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASS_J_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_err_message CHAR(40)
--DEFINE modu_winds_text CHAR(40)
DEFINE modu_start_date DATE 
DEFINE modu_end_date DATE 
#DEFINE modu_where_text CHAR(600) 
#DEFINE modu_query_text CHAR(600) 
DEFINE modu_rec_jmj_impresttran RECORD LIKE jmj_impresttran.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
####################################################################
# FUNCTION ASS_J_main()
#
#
####################################################################
FUNCTION ASS_J_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		
	CALL setModuleId("ASS") 

	OPEN WINDOW A649 with FORM "A649" 
	CALL windecoration_a("A649") 

	MENU " Extract " 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","ASS_J","menu-extract") 
			CALL ASS_J_update_trans(ASS_J_select_trans())
			CALL rpt_rmsreps_reset(NULL)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" #COMMAND "Query" " Enter Search Criteria" --key ("Q",f17) 
				CALL ASS_J_update_trans(ASS_J_select_trans())
				CALL rpt_rmsreps_reset(NULL) 
 
		ON ACTION "CANCEL" # COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

END FUNCTION 



####################################################################
# FUNCTION ASS_J_select_trans()
#
#
####################################################################
FUNCTION ASS_J_select_trans() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	
	LET modu_start_date = mdy(month(today),1,year(today)) 
	IF month(today) = 12 THEN 
		LET modu_end_date = mdy(12,31,year(today)) 
	ELSE 
		LET modu_end_date = mdy(month(today) + 1,1,year(today)) - 1 
	END IF 
	LET l_msgresp = kandoomsg("A",1074,"") 
	#1074 Enter start & END dates FOR extraction
	INPUT modu_start_date, modu_end_date WITHOUT DEFAULTS 
	FROM start_date, end_date


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASS","inp-date") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD start_date 
			IF modu_start_date IS NULL THEN 
				LET l_msgresp = kandoomsg("A",3550,"") 
				#3550 start date must be entered
				NEXT FIELD start_date 
			END IF 
		AFTER FIELD end_date 
			IF modu_end_date IS NULL THEN 
				LET l_msgresp = kandoomsg("A",3550,"") 
				#3550 END date must be entered
				NEXT FIELD end_date 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF modu_start_date IS NULL THEN 
					LET l_msgresp = kandoomsg("A",3550,"") 
					#3550 start date must be entered
					NEXT FIELD start_date 
				END IF 
				IF modu_end_date IS NULL THEN 
					LET l_msgresp = kandoomsg("A",3550,"") 
					#3550 END date must be entered
					NEXT FIELD end_date 
				END IF 
				IF modu_start_date > modu_end_date THEN 
					LET l_msgresp = kandoomsg("A",9095,"") 
					#9095 start date must be less than END date
					NEXT FIELD start_date 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_msgresp = kandoomsg("A",1001,"") 
	#1001 Enter criteria esc TO continue

	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.type_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ASS","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF 


END FUNCTION 


####################################################################
# FUNCTION ASS_J_update_trans()
#
#
####################################################################
FUNCTION ASS_J_update_trans(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_suffix_num INTEGER 
	DEFINE l_tran_count INTEGER 
	DEFINE l_err_message CHAR(240) 
	DEFINE l_msgresp LIKE language.yes_flag 
	
	IF p_where_text IS NULL THEN
		MESSAGE "Program abort"
		RETURN FALSE
	END IF
	LET l_query_text = "SELECT cust_code FROM customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND customer.ref3_code matches '[Yy]' ", 
	" AND ",p_where_text clipped, 
	" ORDER BY cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	# Log start time of extract run TO monitor performance
	LET l_err_message = "Imprest Extract (ASS) - Started" 
	CALL errorlog(l_err_message) 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE jmj_impresttran in exclusive MODE 

		#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with INSERT CURSOR"
		#DISPLAY "see ar/ASS_J.4gl"
		#EXIT PROGRAM (1)


		DECLARE i1_impresttran CURSOR FOR 
		INSERT INTO jmj_impresttran VALUES (glob_rec_invoicehead.*) 
		OPEN i1_impresttran 
		DECLARE i2_impresttran CURSOR FOR 
		INSERT INTO jmj_impresttran VALUES (modu_rec_jmj_impresttran.*) 
		OPEN i2_impresttran 
		DELETE FROM jmj_impresttran 
		WHERE 1=1 

		--   OPEN WINDOW w1 AT 10,15  -- albo  KD-755
		--      with 2 rows, 50 columns
		--      attribute (border)
		DISPLAY "Customer: " at 2,3 

		## Scan each imprest customer in customer code ORDER AND allocate a
		## sequence number
		LET l_suffix_num = 0 
		FOREACH c_customer INTO l_cust_code 
			IF int_flag OR quit_flag THEN 
				EXIT FOREACH 
			END IF 
			DISPLAY l_cust_code at 2,14 
			LET l_tran_count = 0 
			LET l_suffix_num = l_suffix_num + 1 
			DECLARE c_invoicehead CURSOR FOR 
			SELECT invoicehead.* 
			FROM invoicehead 
			WHERE cust_code = l_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_date between modu_start_date AND modu_end_date 
			AND purchase_code = "SER" 
			FOREACH c_invoicehead INTO glob_rec_invoicehead.* 
				LET l_tran_count = l_tran_count + 1 
				LET glob_rec_invoicehead.stat_date = modu_end_date 
				LET glob_rec_invoicehead.printed_num = l_suffix_num 
				# INSERT INTO jmj_impresttran VALUES(glob_rec_invoicehead.*)
				PUT i1_impresttran 
			END FOREACH 

			DECLARE c_credithead CURSOR FOR 
			SELECT credithead.* 
			FROM credithead 
			WHERE cust_code = l_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_date between modu_start_date AND modu_end_date 
			AND cred_text = "SER" 
			FOREACH c_credithead INTO modu_rec_credithead.* 
				LET l_tran_count = l_tran_count + 1 
				INITIALIZE modu_rec_jmj_impresttran.* TO NULL 
				LET modu_rec_jmj_impresttran.cmpy_code =modu_rec_credithead.cmpy_code 
				LET modu_rec_jmj_impresttran.cust_code =modu_rec_credithead.cust_code 
				LET modu_rec_jmj_impresttran.org_cust_code =modu_rec_credithead.org_cust_code 
				LET modu_rec_jmj_impresttran.inv_num =modu_rec_credithead.cred_num 
				LET modu_rec_jmj_impresttran.ord_num =modu_rec_credithead.rma_num 
				LET modu_rec_jmj_impresttran.purchase_code =modu_rec_credithead.cred_text 
				LET modu_rec_jmj_impresttran.job_code =modu_rec_credithead.job_code 
				LET modu_rec_jmj_impresttran.inv_date =modu_rec_credithead.cred_date 
				LET modu_rec_jmj_impresttran.entry_code =modu_rec_credithead.entry_code 
				LET modu_rec_jmj_impresttran.entry_date =modu_rec_credithead.entry_date 
				LET modu_rec_jmj_impresttran.sale_code =modu_rec_credithead.sale_code 
				LET modu_rec_jmj_impresttran.disc_per = 0 
				LET modu_rec_jmj_impresttran.tax_code =modu_rec_credithead.tax_code 
				LET modu_rec_jmj_impresttran.tax_per =modu_rec_credithead.tax_per 
				LET modu_rec_jmj_impresttran.goods_amt = 0 - modu_rec_credithead.goods_amt 
				LET modu_rec_jmj_impresttran.hand_amt = 0 - modu_rec_credithead.hand_amt 
				LET modu_rec_jmj_impresttran.hand_tax_code =modu_rec_credithead.hand_tax_code 
				LET modu_rec_jmj_impresttran.hand_tax_amt = 0 - modu_rec_credithead.hand_tax_amt 
				LET modu_rec_jmj_impresttran.freight_amt = 0 - modu_rec_credithead.freight_amt 
				LET modu_rec_jmj_impresttran.freight_tax_code =modu_rec_credithead.freight_tax_code 
				LET modu_rec_jmj_impresttran.freight_tax_amt = 0 - modu_rec_credithead.freight_tax_amt 
				LET modu_rec_jmj_impresttran.tax_amt = 0 - modu_rec_credithead.tax_amt 
				LET modu_rec_jmj_impresttran.disc_amt = 0 - modu_rec_credithead.disc_amt 
				LET modu_rec_jmj_impresttran.total_amt = 0 - modu_rec_credithead.total_amt 
				LET modu_rec_jmj_impresttran.cost_amt = 0 - modu_rec_credithead.cost_amt 
				LET modu_rec_jmj_impresttran.paid_amt = 0 - modu_rec_credithead.appl_amt 
				LET modu_rec_jmj_impresttran.disc_taken_amt = 0 
				LET modu_rec_jmj_impresttran.due_date = modu_rec_credithead.cred_date 
				LET modu_rec_jmj_impresttran.disc_date =modu_rec_credithead.cred_date 
				LET modu_rec_jmj_impresttran.expected_date =modu_rec_credithead.cred_date 
				LET modu_rec_jmj_impresttran.year_num =modu_rec_credithead.year_num 
				LET modu_rec_jmj_impresttran.period_num =modu_rec_credithead.period_num 
				LET modu_rec_jmj_impresttran.on_state_flag =modu_rec_credithead.on_state_flag 
				LET modu_rec_jmj_impresttran.posted_flag =modu_rec_credithead.posted_flag 
				LET modu_rec_jmj_impresttran.seq_num =modu_rec_credithead.next_num 
				LET modu_rec_jmj_impresttran.line_num =modu_rec_credithead.line_num 
				##    LET modu_rec_jmj_impresttran.printed_num =modu_rec_credithead.printed_num
				LET modu_rec_jmj_impresttran.rev_date =modu_rec_credithead.rev_date 
				LET modu_rec_jmj_impresttran.rev_num =modu_rec_credithead.rev_num 
				LET modu_rec_jmj_impresttran.com1_text =modu_rec_credithead.com1_text 
				LET modu_rec_jmj_impresttran.com2_text =modu_rec_credithead.com2_text 
				LET modu_rec_jmj_impresttran.cost_ind =modu_rec_credithead.cost_ind 
				LET modu_rec_jmj_impresttran.currency_code =modu_rec_credithead.currency_code 
				LET modu_rec_jmj_impresttran.conv_qty =modu_rec_credithead.conv_qty 
				LET modu_rec_jmj_impresttran.inv_ind =modu_rec_credithead.cred_ind 
				LET modu_rec_jmj_impresttran.prev_paid_amt = 0 
				LET modu_rec_jmj_impresttran.acct_override_code=modu_rec_credithead.acct_override_code 
				LET modu_rec_jmj_impresttran.price_tax_flag =modu_rec_credithead.price_tax_flag 
				LET modu_rec_jmj_impresttran.invoice_to_ind =modu_rec_credithead.address_to_ind 
				LET modu_rec_jmj_impresttran.territory_code =modu_rec_credithead.territory_code 
				LET modu_rec_jmj_impresttran.mgr_code =modu_rec_credithead.mgr_code 
				LET modu_rec_jmj_impresttran.area_code =modu_rec_credithead.area_code 
				LET modu_rec_jmj_impresttran.cond_code =modu_rec_credithead.cond_code 
				LET modu_rec_jmj_impresttran.post_date =modu_rec_credithead.post_date 
				LET modu_rec_jmj_impresttran.stat_date = modu_end_date 
				LET modu_rec_jmj_impresttran.printed_num = l_suffix_num 
				PUT i2_impresttran 
			END FOREACH 
			## IF no transactions found, INSERT a blank transaction FOR this customer
			IF l_tran_count = 0 THEN 
				INITIALIZE glob_rec_invoicehead.* TO NULL 
				LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET glob_rec_invoicehead.cust_code = l_cust_code 
				LET glob_rec_invoicehead.stat_date = modu_end_date 
				LET glob_rec_invoicehead.printed_num = l_suffix_num 
				PUT i1_impresttran 
			END IF 
		END FOREACH 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			--      CLOSE WINDOW w1  -- albo  KD-755
			ROLLBACK WORK 
			LET l_err_message = "Imprest Extract (ASS) - Interrupted" 
			CALL errorlog(l_err_message) 
			RETURN 
		END IF 

		CLOSE i1_impresttran 
		CLOSE i2_impresttran 
		--   CLOSE WINDOW w1  -- albo  KD-755

	COMMIT WORK 

	LET l_err_message = "Imprest Extract (ASS) - Finished" 
	CALL errorlog(l_err_message) 

END FUNCTION 