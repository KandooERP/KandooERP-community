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
GLOBALS "../ar/A5_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A51_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
#MODULE Scope Variables
#DEFINE l_rec_customer RECORD LIKE customer.*,
--DEFINE l_doit CHAR(1) 
--DEFINE l_ans CHAR(1) 
--DEFINE l_w_amount money(12,2) 
--DEFINE l_due_am INTEGER
--DEFINE l_prom_am INTEGER
 
--DEFINE l_bcust LIKE customer.cust_code 
--DEFINE l_ecust LIKE customer.cust_code 


#########################################################
# MAIN
#
# controls collection calls on overdue debtors
#########################################################
MAIN 
	DEFINE l_doit CHAR(1)
	DEFINE l_ans CHAR(1)
	DEFINE l_w_amount money(12,2)
	DEFINE l_due_am INTEGER
	DEFINE l_prom_am INTEGER
	 
	DEFINE l_bcust LIKE customer.cust_code 
	DEFINE l_ecust LIKE customer.cust_code 	
	DEFINE l_hubert STRING
	
	#Initial UI Init
	CALL setModuleId("A51") 
	CALL ui_init(0) 

	DEFER interrupt 
	DEFER quit 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	LET l_doit = "Y" 
	WHILE l_doit = "Y" 

		OPEN WINDOW Agewind with FORM "A051h" #attribute(border) 
		CALL windecoration_a("A051h") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

--	CONSTRUCT BY NAME l_hubert ON due_am, prom_am, bcust, ecust, w_amount
--	DISPLAY l_hubert

		INPUT l_due_am, l_prom_am,l_bcust,l_ecust, l_w_amount WITHOUT DEFAULTS 
		FROM due_am, prom_am, bcust, ecust, w_amount ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A51","inp-collection-calls") 	

			ON CHANGE bcust
				DISPLAY db_customer_get_name_text(UI_OFF,l_bcust) TO bcust_name_text
	
			ON CHANGE ecust
				DISPLAY db_customer_get_name_text(UI_OFF,l_ecust) TO ecust_name_text

			AFTER INPUT
				IF l_due_am IS NULL THEN
					MESSAGE "Max Collection - Days amnesty on due date:"
					NEXT FIELD due_amt
				END IF 
				IF l_prom_am IS NULL THEN
					MESSAGE "Max Collection - Days amnesty on promised date: "
					NEXT FIELD prom_am
				END IF 
				IF l_bcust IS NULL THEN
					# ? LET l_bcust = " " 
					MESSAGE "Enter beginning customer:" 
					NEXT FIELD bcust
				END IF 
				IF l_ecust IS NULL THEN
					# ? LET l_ecust = "zzzzzzzz"
					MESSAGE "Enter ending customer:" 
					NEXT FIELD ecust
				END IF 

				IF l_w_amount IS NULL THEN
					LET l_w_amount = 0 
					#MESSAGE "Owing over what amount?:" 
					NEXT FIELD w_amount
				END IF 
 	
		END INPUT

{

		INPUT l_due_am WITHOUT DEFAULTS FROM due_am #add huho 
		MESSAGE "Max Collection - Days amnesty on due date:" 
		IF l_due_am IS NULL THEN 
			LET l_due_am = 0 
		END IF 

		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 

		INPUT l_prom_am WITHOUT DEFAULTS FROM prom_am  #add huho 
		MESSAGE "Max Collection - Days amnesty on promised date: " 

		IF l_prom_am IS NULL THEN 
			LET l_prom_am = 0 
		END IF 

		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 

		INPUT l_bcust WITHOUT DEFAULTS FROM bcust #add huho 
		MESSAGE "Enter beginning customer:" 

		LET l_bcust = upshift(l_bcust) 
		IF l_bcust IS NULL THEN 
			LET l_bcust = " " 
		END IF 


		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 

		INPUT l_ecust  WITHOUT DEFAULTS FROM ecust #add huho 
		MESSAGE "Enter ending customer:" 

		LET l_ecust = upshift(l_ecust) 
		IF l_ecust IS NULL THEN 
			LET l_ecust = "zzzzzzzz" 
		END IF 


		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 

		INPUT l_w_amount WITHOUT DEFAULTS FROM w_amount #add huho 
		MESSAGE "Owing over what amount?:" 

		IF l_w_amount IS NULL THEN 
			LET l_w_amount = 0 
		END IF 


		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 

		INPUT l_ans WITHOUT DEFAULTS FROM ans #add huho
 
		MESSAGE "Start selection (y/n)?:" 

		LET l_ans = upshift(l_ans) 
		IF l_ans IS NULL THEN 
			LET l_ans = "Y" 
		END IF 

		IF int_flag != 0 
		OR quit_flag != 0 
		THEN 
			EXIT PROGRAM 
		END IF 
}

		IF l_ans != "Y" 
		THEN
			CALL fgl_winmessage("Abort","Program aborted by User","info") 
			EXIT PROGRAM 
		END IF 


		CLOSE WINDOW Agewind 

		CALL call_clnts( l_due_am, l_prom_am, l_bcust, l_ecust, l_w_amount) 

		CLOSE WINDOW wa619 

	END WHILE
	 
END MAIN 


#########################################################
# FUNCTION db_invoicehead_customer_get_data(p_due_am, p_prom_am, p_bcust, p_ecust, p_w_amount)
#
#
#########################################################
FUNCTION db_invoicehead_customer_get_data(p_due_am, p_prom_am, p_bcust, p_ecust, p_w_amount) 
	DEFINE p_due_am INTEGER 
	DEFINE p_prom_am INTEGER 
	DEFINE p_bcust LIKE customer.cust_code
	DEFINE p_ecust LIKE customer.cust_code
	DEFINE p_w_amount money(12,2)
	DEFINE l_w_amount decimal(12,2)

	DEFINE l_rec_customer RECORD LIKE customer.* 
	--DEFINE l_rec_t_customer RECORD 
	--	cust_code LIKE customer.cust_code 
	--END RECORD
	--DEFINE l_rec_customertype RECORD LIKE customertype.*
	--DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	--DEFINE l_rec_tax RECORD LIKE tax.*
	--DEFINE l_term RECORD LIKE term.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[080] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		contact_text LIKE customer.contact_text, 
		tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_idx SMALLINT
	--DEFINE l_id_flag SMALLINT
	--DEFINE l_cnt SMALLINT
	--DEFINE l_err_flag SMALLINT
--	DEFINE l_1_baddue INTEGER
--	DEFINE l_1_overdue INTEGER
	DEFINE l_duedate DATE
	DEFINE l_expect_date DATE
--	DEFINE l_ans CHAR(1)
--	DEFINE l_isit CHAR(1)
	DEFINE l_query STRING

	LET l_duedate = today - p_due_am 
	LET l_expect_date = today - p_prom_am 
	
	LET l_w_amount = p_w_amount #don't want the currency $ symbol in the dynamic sql string

	#just a test
	--LET l_rec_customer.cmpy_code = NULL
	--LET l_rec_customer.cust_code  = NULL
	--LET l_rec_customer.name_text = NULL
	--LET l_rec_customer.contact_text = NULL 
	--LET l_rec_customer.tele_text = NULL

	LET l_query = 
	"SELECT unique customer.cmpy_code, customer.cust_code, customer.name_text, customer.contact_text, customer.tele_text ", 
	"FROM customer, invoicehead ", 
	"WHERE customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code  CLIPPED, "' ", 
	"AND customer.cust_code <= '", p_ecust CLIPPED , "' ", 
	"AND customer.cust_code >= '", p_bcust CLIPPED , "' ", 
	"AND invoicehead.paid_amt != invoicehead.total_amt " ,
	"AND ((invoicehead.total_amt - invoicehead.paid_amt) > ", l_w_amount , " ) ", 
	"AND ((invoicehead.due_date <= '",  l_duedate CLIPPED, "' ", 
	"AND invoicehead.expected_date IS null) ", 
	"OR (invoicehead.expected_date <= '", l_expect_date CLIPPED, "' ",
	"AND invoicehead.expected_date IS NOT null)) ",
	"AND invoicehead.cmpy_code = customer.cmpy_code ",
	"AND invoicehead.cust_code = customer.cust_code " 
	PREPARE pc_cust FROM l_query
	DECLARE c_cust CURSOR FOR pc_cust 

	LET l_idx = 0 
	FOREACH c_cust INTO l_rec_customer.cmpy_code, l_rec_customer.cust_code, l_rec_customer.name_text, l_rec_customer.contact_text,	l_rec_customer.tele_text 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].contact_text = l_rec_customer.contact_text 
		LET l_arr_rec_customer[l_idx].tele_text = l_rec_customer.tele_text 
	END FOREACH 
 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	MESSAGE "" 
	MESSAGE " RETURN on line FOR information OR notes" attribute (yellow) 

	RETURN l_arr_rec_customer
END FUNCTION

#########################################################
# FUNCTION call_clnts(p_due_am, p_prom_am, p_bcust, p_ecust, p_w_amount)
#
#
#########################################################
FUNCTION call_clnts(p_due_am, p_prom_am, p_bcust, p_ecust, p_w_amount) 
	DEFINE p_due_am INTEGER 
	DEFINE p_prom_am INTEGER 
	DEFINE p_bcust,p_ecust LIKE customer.cust_code
	DEFINE p_w_amount money(12,2)

	DEFINE l_rec_customer RECORD LIKE customer.* 
	--DEFINE l_rec_t_customer RECORD 
	--	cust_code LIKE customer.cust_code 
	--END RECORD
	--DEFINE l_rec_customertype RECORD LIKE customertype.*
	--DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	--DEFINE l_rec_tax RECORD LIKE tax.*
	--DEFINE l_term RECORD LIKE term.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[080] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		contact_text LIKE customer.contact_text, 
		tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_idx SMALLINT
	--DEFINE l_id_flag SMALLINT
	--DEFINE l_cnt SMALLINT
	--DEFINE l_err_flag SMALLINT
	DEFINE l_1_baddue INTEGER
	DEFINE l_1_overdue INTEGER
	DEFINE l_duedate DATE
	DEFINE l_expect_date DATE
	DEFINE l_ans CHAR(1)
	DEFINE l_isit CHAR(1)
	--DEFINE l_sel_text CHAR(200)
	--DEFINE l_query_text CHAR(200)
	#l_kandoouser_sign_on_code CHAR(9)

	CALL l_arr_rec_customer.clear()
	CALL db_invoicehead_customer_get_data(p_due_am, p_prom_am, p_bcust, p_ecust, p_w_amount) RETURNING l_arr_rec_customer

	OPEN WINDOW wa619 with FORM "A619" 
	CALL windecoration_a("A619") 
{
	LET l_duedate = today - p_due_am 
	LET l_expect_date = today - p_prom_am 

	DECLARE c_cust CURSOR FOR 
	SELECT unique customer.cmpy_code, customer.cust_code, customer.name_text, customer.contact_text, customer.tele_text 
	INTO l_rec_customer.cmpy_code, l_rec_customer.cust_code, 
	l_rec_customer.name_text, l_rec_customer.contact_text, 
	l_rec_customer.tele_text 
	FROM customer, invoicehead 
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code <= p_ecust 
	AND customer.cust_code >= p_bcust 
	AND invoicehead.paid_amt != invoicehead.total_amt 
	AND ((invoicehead.total_amt - invoicehead.paid_amt) > p_w_amount) 
	AND ((invoicehead.due_date <= l_duedate 
	AND invoicehead.expected_date IS null) 
	OR (invoicehead.expected_date <= l_expect_date 
	AND invoicehead.expected_date IS NOT null)) 
	AND invoicehead.cmpy_code = customer.cmpy_code 
	AND invoicehead.cust_code = customer.cust_code 

	LET l_idx = 0 
	FOREACH c_cust 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].contact_text = l_rec_customer.contact_text 
		LET l_arr_rec_customer[l_idx].tele_text = l_rec_customer.tele_text 

		IF l_idx > 70 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (l_idx) 
	WHENEVER ERROR stop 

	IF l_idx > 70 
	THEN 
		MESSAGE " Only first seventy selected, RETURN on line FOR information " 
		attribute(yellow) 
	ELSE 
		MESSAGE "" 
		MESSAGE " RETURN on line FOR information OR notes" 
		attribute (yellow) 
	END IF 
}
	INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* ATTRIBUTE(UNBUFFERED, APPEND ROW = FALSE, INSERT ROW = FALSE, DELETE ROW = FALSE, AUTO APPEND = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A51","inp-arr-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_customer.cust_code = l_arr_rec_customer[l_idx].cust_code 
			LET l_rec_customer.name_text = l_arr_rec_customer[l_idx].name_text 
			LET l_rec_customer.contact_text = l_arr_rec_customer[l_idx].contact_text 
			LET l_rec_customer.tele_text = l_arr_rec_customer[l_idx].tele_text 
			--LET l_id_flag = 0 

		ON ACTION ("ACCEPT","DOUBLECLICK")
		--BEFORE FIELD cust_code 
			CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.* 
--			SELECT * 
--			INTO l_rec_customer.* 
--			FROM customer 
--			WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND customer.cust_code = l_rec_customer.cust_code 

			IF l_rec_customer.cust_code IS NULL
--			IF (status = NOTFOUND) 
			THEN 
				ERROR "Customer NOT found - please re-enter" 
				CALL errorlog ("A51 - Customer NOT found") 
				NEXT FIELD scroll_flag 
			ELSE 
				LET l_1_overdue = (l_rec_customer.over1_amt + 
				l_rec_customer.over30_amt + 
				l_rec_customer.over60_amt + 
				l_rec_customer.over90_amt) 
				LET l_1_baddue = (l_rec_customer.over30_amt + 
				l_rec_customer.over60_amt + 
				l_rec_customer.over90_amt) 

				CALL coll_invo(glob_rec_kandoouser.cmpy_code, l_arr_rec_customer[l_idx].cust_code,l_1_overdue,l_1_baddue) 

				NEXT FIELD scroll_flag 
			END IF 

	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		EXIT PROGRAM 
	END IF 

END FUNCTION 


