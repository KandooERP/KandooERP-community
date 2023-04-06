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

	Source code beautified by beautify.pl on 2020-01-02 09:16:01	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "Q_QE_GLOBALS.4gl" 

GLOBALS 
	DEFINE where_text CHAR(1000) 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# \brief module Q12 - Allows the user TO view Quotation Information
#######################################################################
MAIN 

	CALL setModuleId("Q12") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 


	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",7005,"") 
		#7005 AR Parms do NOT exist
		EXIT program 
	END IF 
	INITIALIZE where_text TO NULL 
	IF num_args() > 0 THEN 
		LET where_text = "quotehead.order_num = ",arg_val(1) 
	END IF 
	OPEN WINDOW q100 with FORM "Q100" -- alch kd-747 
	CALL windecoration_q("Q100") -- alch kd-747 
	CALL query() 
	CLOSE WINDOW q100 
END MAIN 


FUNCTION select_quote() 
	DEFINE 
	query_text CHAR(1500), 
	pr_order_num LIKE quotehead.order_num 

	IF where_text IS NULL THEN 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria; OK TO Continue.
		CONSTRUCT BY NAME where_text ON quotehead.cust_code, 
		customer.name_text, 
		quotehead.order_num, 
		quotehead.currency_code, 
		quotehead.goods_amt, 
		quotehead.hand_amt, 
		quotehead.freight_amt, 
		quotehead.tax_amt, 
		quotehead.total_amt, 
		quotehead.cost_amt, 
		quotehead.disc_amt, 
		quotehead.approved_by, 
		quotehead.approved_date, 
		quotehead.ord_text, 
		quotehead.quote_date, 
		quotehead.valid_date, 
		quotehead.ship_date, 
		quotehead.status_ind, 
		quotehead.entry_code, 
		quotehead.entry_date, 
		quotehead.rev_date, 
		quotehead.rev_num, 
		quotehead.com1_text, 
		quotehead.com2_text, 
		quotehead.com3_text, 
		quotehead.com4_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","Q12","const-cust_code-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait.
	LET query_text = "SELECT order_num FROM quotehead, customer ", 
	" WHERE customer.cust_code = quotehead.cust_code ", 
	" AND quotehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND customer.cmpy_code = quotehead.cmpy_code ", 
	" AND ",where_text clipped, 
	" ORDER BY order_num " 
	PREPARE s_quotehead FROM query_text 
	DECLARE c_quotehead SCROLL CURSOR FOR s_quotehead 
	OPEN c_quotehead 
	FETCH FIRST c_quotehead INTO pr_order_num 
	INITIALIZE where_text TO NULL 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		CALL display_quote(pr_order_num) 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION query() 
	DEFINE 
	pr_order_num LIKE quotehead.order_num, 
	pr_quotehead RECORD LIKE quotehead.* 

	CLEAR FORM 
	LET pr_arparms.inv_ref1_text = pr_arparms.inv_ref1_text clipped, 
	"................" 
	DISPLAY pr_arparms.inv_ref1_text TO inv_ref1_text 
	MENU " Quotation" 
		BEFORE MENU 
			IF where_text IS NOT NULL THEN 
				IF select_quote() THEN 
					FETCH FIRST c_quotehead INTO pr_order_num 
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "First" 
					SHOW option "Last" 
					SHOW option "Detail" 
					NEXT option "Detail" 
				ELSE 
					LET msgresp = kandoomsg("Q",9243,"") 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Last" 
					HIDE option "Detail" 
				END IF 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
			CALL publish_toolbar("kandoo","Q12","menu-quotation-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Enter selection criteria FOR quotation" 
			IF select_quote() THEN 
				FETCH FIRST c_quotehead INTO pr_order_num 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				LET msgresp = kandoomsg("Q",9243,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected quotation" 
			FETCH NEXT c_quotehead INTO pr_order_num 
			IF status <> notfound THEN 
				CALL display_quote(pr_order_num) 
			ELSE 
				LET msgresp = kandoomsg("G",9157,"") 
				#9157 END of entries reached
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected quotation" 
			FETCH previous c_quotehead INTO pr_order_num 
			IF status <> notfound THEN 
				CALL display_quote(pr_order_num) 
			ELSE 
				LET msgresp = kandoomsg("G",9156,"") 
				#9156 Start of entries reached
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View quotation details" 
			SELECT * INTO pr_quotehead.* FROM quotehead 
			WHERE order_num = pr_order_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL lquoshow(glob_rec_kandoouser.cmpy_code, 
			pr_quotehead.order_num) 
		COMMAND KEY ("F",f18) "First" " DISPLAY first quotation in the selected list" 
			FETCH FIRST c_quotehead INTO pr_order_num 
			IF status <> notfound THEN 
				CALL display_quote(pr_order_num) 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last quotation in the selected list" 
			FETCH LAST c_quotehead INTO pr_order_num 
			IF status <> notfound THEN 
				CALL display_quote(pr_order_num) 
			END IF 
		COMMAND KEY(interrupt, "E") "Exit" " RETURN TO the Menu" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_quote(pr_order_num) 
	DEFINE 
	pr_order_num LIKE quotehead.order_num, 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_customer RECORD LIKE customer.* 

	SELECT * INTO pr_quotehead.* FROM quotehead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Quotation") 
	END IF 
	INITIALIZE pr_customer.* TO NULL 
	SELECT * INTO pr_customer.* FROM customer 
	WHERE cust_code = pr_quotehead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME pr_quotehead.cust_code, 
	pr_customer.name_text, 
	pr_quotehead.order_num, 
	pr_quotehead.currency_code, 
	pr_quotehead.goods_amt, 
	pr_quotehead.hand_amt, 
	pr_quotehead.freight_amt, 
	pr_quotehead.tax_amt, 
	pr_quotehead.total_amt, 
	pr_quotehead.cost_amt, 
	pr_quotehead.disc_amt, 
	pr_quotehead.approved_by, 
	pr_quotehead.approved_date, 
	pr_quotehead.ord_text, 
	pr_quotehead.quote_date, 
	pr_quotehead.valid_date, 
	pr_quotehead.ship_date, 
	pr_quotehead.status_ind, 
	pr_quotehead.entry_code, 
	pr_quotehead.entry_date, 
	pr_quotehead.rev_date, 
	pr_quotehead.rev_num, 
	pr_quotehead.com1_text, 
	pr_quotehead.com2_text, 
	pr_quotehead.com3_text, 
	pr_quotehead.com4_text 

END FUNCTION 
