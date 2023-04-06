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

############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# \brief module Q13 - Allows the user TO Scan Client Quotations
#######################################################################
MAIN 

	CALL setModuleId("Q13") -- albo 
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
	CALL scan_quote() 
END MAIN 


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
	idx,scrn SMALLINT, 
	query_text CHAR(800), 
	where_text CHAR(400) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW q101 with FORM "Q101" -- alch kd-747 
	CALL windecoration_q("Q101") -- alch kd-747 
	WHILE true 
		CLEAR FORM 
		DISPLAY BY NAME pr_arparms.inv_ref2a_text, 
		pr_arparms.inv_ref2b_text 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME where_text ON order_num, 
		cust_code, 
		ord_text, 
		quote_date, 
		valid_date, 
		total_amt, 
		status_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","Q13","const-order_num-2") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM quotehead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY order_num" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_quotehead FROM query_text 
		DECLARE c_quotehead CURSOR FOR s_quotehead 
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
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET msgresp=kandoomsg("U",9113,idx) 
		#U9113 idx records selected
		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE pa_quotehead[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		OPTIONS SQL interrupt off 
		LET msgresp = kandoomsg("A",1551,"") 
		#1551 " ENTER on line TO view; OK TO Continue.
		CALL set_count(idx) 
		INPUT ARRAY pa_quotehead WITHOUT DEFAULTS FROM sr_quotehead.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q13","inp_arr-pa_quotehead-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				DISPLAY pa_quotehead[idx].* TO sr_quotehead[scrn].* 

				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET pa_quotehead[idx].scroll_flag = NULL 
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
				AND pa_quotehead[idx+14].cust_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD order_num 
				IF pa_quotehead[idx].order_num IS NOT NULL 
				AND pa_quotehead[idx].order_num != 0 THEN 
					CALL run_prog("Q12",pa_quotehead[idx].order_num,"","","") 
				END IF 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY pa_quotehead[idx].* TO sr_quotehead[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 
	CLOSE WINDOW q101 
END FUNCTION 
