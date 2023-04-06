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
GLOBALS "Q18_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# \brief module Q18  -  Client Quotations Acceptance
#######################################################################
MAIN 

	CALL setModuleId("Q18") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	CALL create_table("quotedetl","t_quotedetl","","Y") 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	OPEN WINDOW q101 with FORM "Q101" -- alch kd-747 
	CALL windecoration_q("Q101") -- alch kd-747 
	WHILE select_quote() 
		CALL scan_quote() 
	END WHILE 
	CLOSE WINDOW q101 
END MAIN 


FUNCTION select_quote() 
	DEFINE 
	query_text CHAR(400), 
	where_text CHAR(400) 

	CLEAR FORM 
	DISPLAY BY NAME pr_arparms.inv_ref2a_text, 
	pr_arparms.inv_ref2b_text 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001" Enter Selection Criteria; OK TO Continue"
	CONSTRUCT BY NAME where_text ON order_num, 
	cust_code, 
	ord_text, 
	quote_date, 
	valid_date, 
	total_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","Q18","const-order_num-3") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002" Searching database - please wait
	LET query_text = "SELECT * FROM quotehead ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND status_ind = 'U' ", 
	" AND ",where_text clipped, 
	" ORDER BY order_num " 
	PREPARE s_quotehead FROM query_text 
	DECLARE c_quotehead CURSOR FOR s_quotehead 
	RETURN true 
END FUNCTION 


FUNCTION scan_quote() 
	DEFINE 
	pr_quotehead RECORD LIKE quotehead.*, 
	pa_quotehead array[520] OF RECORD 
		scroll_flag CHAR(1), 
		order_num LIKE quotehead.order_num, 
		cust_code LIKE quotehead.cust_code, 
		ord_text LIKE quotehead.ord_text, 
		quote_date LIKE quotehead.quote_date, 
		valid_date LIKE quotehead.valid_date, 
		total_amt LIKE quotehead.total_amt, 
		status_ind LIKE quotehead.status_ind 
	END RECORD, 
	pr_status_ind LIKE quotehead.status_ind, 
	pr_scroll_flag CHAR(1), 
	err_message CHAR(60), 
	idx,scrn,pr_stat, pr_back_flag SMALLINT 

	LET idx = 0 
	FOREACH c_quotehead INTO pr_quotehead.* 
		LET idx = idx + 1 
		LET pa_quotehead[idx].order_num = pr_quotehead.order_num 
		LET pa_quotehead[idx].cust_code = pr_quotehead.cust_code 
		LET pa_quotehead[idx].ord_text = pr_quotehead.ord_text 
		LET pa_quotehead[idx].quote_date = pr_quotehead.quote_date 
		LET pa_quotehead[idx].valid_date = pr_quotehead.valid_date 
		LET pa_quotehead[idx].total_amt = pr_quotehead.total_amt 
		LET pa_quotehead[idx].status_ind = pr_quotehead.status_ind 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First 500 entries selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 "idx rows selected"
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_quotehead[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("Q",1029,"") 
	#1029 "ENTER on line TO Accept Quotation "
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_quotehead WITHOUT DEFAULTS FROM sr_quotehead.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q18","inp_arr-pa_quotehead-3") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_quotehead[idx].scroll_flag 
			DISPLAY pa_quotehead[idx].* TO sr_quotehead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_quotehead[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_quotehead[idx+1].cust_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_quotehead[idx+10].cust_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD order_num 
			IF pa_quotehead[idx].order_num IS NULL 
			OR pa_quotehead[idx].order_num = 0 THEN 
				NEXT FIELD scroll_flag 
			END IF 
			SELECT * INTO pr_quotehead.* FROM quotehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_quotehead[idx].order_num 
			IF pr_quotehead.status_ind = "X" THEN 
				LET msgresp = kandoomsg("Q",9007,"") 
				#9007 Quote has been locked by another process.
				NEXT FIELD scroll_flag 
			END IF 
			IF pr_quotehead.status_ind = "C" THEN 
				LET msgresp = kandoomsg("Q",9004,"") 
				#9004 "Quotation already accepted"
				NEXT FIELD scroll_flag 
			END IF 
			IF kandoomsg("Q",8000,pa_quotehead[idx].order_num) = "N" THEN 
				#8000 Confirm TO change Quote: ??? TO ORDER.
				NEXT FIELD scroll_flag 
			END IF 
			LET msgresp = kandoomsg("U",1005,"") 
			#1005 Updating Database; Please Wait
			GOTO bypass 
			LABEL recovery: 
			IF error_recover(err_message,status) != "Y" THEN 
				LET msgresp = kandoomsg("Q",1029,"") 
				#1029 "ENTER on line TO Accept Quotation "
				NEXT FIELD scroll_flag 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "Locking quote RECORD FOR approval" 
				DECLARE c2_quotehead CURSOR FOR 
				SELECT * FROM quotehead 
				WHERE order_num = pa_quotehead[idx].order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c2_quotehead 
				FETCH c2_quotehead INTO pr_quotehead.* 
				IF valid_quote(pa_quotehead[idx].order_num) THEN 
					LET pr_status_ind = pr_quotehead.status_ind 
					LET err_message = "Update quote STATUS TO X" 
					UPDATE quotehead 
					SET status_ind = "X" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_quotehead[idx].order_num 
					CLOSE c_quotehead 
				COMMIT WORK 
				WHENEVER ERROR stop 
				INSERT INTO t_quotedetl 
				SELECT * FROM quotedetl 
				WHERE order_num = pa_quotehead[idx].order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL write_order(pa_quotehead[idx].order_num) 
				RETURNING pr_stat, pr_back_flag 
				DELETE FROM t_quotedetl WHERE 1=1 
				IF pr_stat THEN 
					LET pa_quotehead[idx].status_ind = "C" 
					UPDATE quotehead 
					SET status_ind = "C", 
					order_date = today 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_quotehead[idx].order_num 
					IF pr_back_flag THEN 
						LET msgresp = kandoomsg("Q",7062,pa_quotehead[idx].order_num) 
						#7062  Quotation  VALUE changed TO an ORDER. Stock placed on backorder.
					ELSE 
						LET msgresp = kandoomsg("Q",7061,pa_quotehead[idx].order_num) 
						#7061  Quotation  VALUE successfully changed TO an ORDER.
					END IF 
				ELSE 
					SELECT status_ind INTO pa_quotehead[idx].status_ind 
					FROM quotehead 
					WHERE order_num = pa_quotehead[idx].order_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					UPDATE quotehead 
					SET status_ind = pa_quotehead[idx].status_ind 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_quotehead[idx].order_num 
				END IF 
			ELSE 
				CLOSE c_quotehead 
				ROLLBACK WORK 
				WHENEVER ERROR stop 
				SELECT status_ind INTO pa_quotehead[idx].status_ind 
				FROM quotehead 
				WHERE order_num = pa_quotehead[idx].order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			LET msgresp = kandoomsg("Q",1029,"") 
			#1029 "ENTER on line TO Accept Quotation "
			NEXT FIELD scroll_flag 
		ON KEY (F5) 
			CALL run_prog("Q12",pa_quotehead[idx].order_num,"","","") 
		ON KEY (F8) 
			CALL run_prog("Q11",pa_quotehead[idx].order_num,"","","") 
		AFTER ROW 
			DISPLAY pa_quotehead[idx].* TO sr_quotehead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION valid_quote(pr_order_num) 
	DEFINE 
	pr_order_num LIKE quotehead.order_num, 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_product RECORD LIKE product.*, 
	pr_temp_text CHAR(40), 
	i SMALLINT 

	SELECT * INTO pr_quotehead.* FROM quotehead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Quotation") 
		#7001 "Logic error: Not a valid quotation number"
		RETURN false 
	END IF 
	CASE 
		WHEN pr_quotehead.status_ind = "C" 
			LET msgresp = kandoomsg("Q",9004,"") 
			#9004 "Quotation already accepted"
			RETURN false 
		WHEN pr_quotehead.status_ind = "D" 
			LET msgresp = kandoomsg("Q",9005,"") 
			#9005 "Quotation has been cancelled"
			RETURN false 
		WHEN pr_quotehead.hold_code IS NOT NULL 
			LET msgresp = kandoomsg("Q",9006,"") 
			#9006 "Quote IS held"
			RETURN false 
	END CASE 
	IF pr_quotehead.valid_date < today THEN 
		LET msgresp = kandoomsg("Q",9244,"") 
		#9244 This quote IS no longer valid.
		RETURN false 
	END IF 
	IF pr_quotehead.approved_by IS NULL THEN 
		LET msgresp = kandoomsg("Q",9245,"") 
		#9245 This quote has NOT been approved.
		RETURN false 
	END IF 
	SELECT * FROM customer 
	WHERE cust_code = pr_quotehead.cust_code 
	AND cmpy_code = pr_quotehead.cmpy_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Customer") 
		#7001 "Logic error customer: missing on quotation"
		RETURN false 
	END IF 
	IF pr_customer.hold_code IS NOT NULL THEN 
		LET msgresp = kandoomsg("A",9143,"") 
		#9143 "Customer IS held"
		RETURN false 
	END IF 
	IF pr_customer.delete_flag = "Y" THEN 
		LET msgresp = kandoomsg("A",9144,"") 
		#9144 Customer IS marked FOR deletion
		RETURN false 
	END IF 
	DECLARE c_quotedetl CURSOR FOR 
	SELECT * FROM quotedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = pr_order_num 
	FOREACH c_quotedetl INTO pr_quotedetl.* 
		INITIALIZE pr_product.* TO NULL 
		IF pr_quotedetl.part_code IS NOT NULL THEN 
			IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
			pr_quotedetl.ware_code,0,2,0,"","","") THEN 
				LET msgresp = kandoomsg("Q",9008,"") 
				#9008 There are lines on this quote with an invalid product
				RETURN false 
			END IF 
			SELECT unique 1 FROM product 
			WHERE part_code = pr_quotedetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trade_in_flag = "Y" 
			IF status = 0 THEN 
				IF pr_quotedetl.order_qty > 0 THEN 
					LET msgresp = kandoomsg("Q",9246,"") 
					#9246 Trade In Product with positive qty found on quote
					RETURN false 
				END IF 
			END IF 
		END IF 
	END FOREACH 
	RETURN true 
END FUNCTION 
