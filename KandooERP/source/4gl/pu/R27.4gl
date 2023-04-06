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

	Source code beautified by beautify.pl on 2020-01-02 17:06:16	Source code beautified by beautify.pl on 2020-01-02 17:03:26	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R27 allows the user TO view Goods Receipt Information

GLOBALS 
	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	exist SMALLINT 
END GLOBALS 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R27") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r151 with FORM "R151" 
	CALL  windecoration_r("R151") 

	CALL query() 
	CLOSE WINDOW r151 

END MAIN 


FUNCTION select_poaudit() 
	DEFINE 
	where_text CHAR(600), 
	query_text CHAR(900) 

	CLEAR FORM 
	IF num_args() > 0 THEN 
		LET query_text = "SELECT distinct pa.* ", 
		"FROM poaudit pa, purchdetl pd, purchhead ph ", 
		"WHERE pa.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
		"AND pd.cmpy_code = ph.cmpy_code ", 
		"AND pa.cmpy_code = ph.cmpy_code ", 
		"AND pa.po_num = pd.order_num ", 
		"AND pa.line_num = pd.line_num ", 
		"AND pd.order_num = ph.order_num ", 
		"AND (pa.tran_code = 'GA' OR pa.tran_code = 'GR') ", 
		"AND ",arg_val(1) 
		DISPLAY query_text 
	ELSE 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 "Enter criteria FOR selection - ESC TO begin search"
		CONSTRUCT BY NAME where_text ON vend_code, 
		po_num, 
		line_num, 
		tran_num, 
		seq_num, 
		entry_date, 
		entry_code, 
		orig_auth_flag, 
		now_auth_flag, 
		order_qty, 
		received_qty, 
		voucher_qty, 
		desc_text, 
		unit_cost_amt, 
		ext_cost_amt, 
		unit_tax_amt, 
		ext_tax_amt, 
		line_total_amt, 
		posted_flag, 
		jour_num, 
		year_num, 
		period_num 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","R27","construct-purchhead-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = true 
			LET quit_flag = true 
			RETURN false 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database; Please Wait
		LET query_text = " SELECT * FROM poaudit ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\"", 
		" AND (tran_code = \"GR\" OR ", " tran_code = \"GA\") ", 
		" AND ", where_text clipped 
	END IF 
	PREPARE s_poaudit FROM query_text 
	DECLARE c_poaudit SCROLL CURSOR FOR s_poaudit 
	OPEN c_poaudit 
	FETCH c_poaudit INTO pr_poaudit.* 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		CALL display_poaudit() 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION query() 
	IF num_args() > 0 THEN 
		IF select_poaudit() THEN 
			CALL display_poaudit() 
		ELSE 
			LET msgresp = kandoomsg("U",9101,"") 
			#9101 No Rows Satisfied Selection Criteria
			CALL eventsuspend() # LET msgresp = kandoomsg("U",1,"") 
			RETURN 
		END IF 
	END IF 

	MENU "Goods Receipt" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","R27","menu-goods_receipt-1") 

			IF num_args() > 0 THEN 
				HIDE option "Query" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Query" "Use TO search FOR goods receipt records " 
			IF select_poaudit() THEN 
				CALL display_poaudit() 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
			ELSE 
				LET msgresp = kandoomsg("U",9101,"") 
				#9101 No Rows Satisfied Selection Criteria
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
			END IF 
		COMMAND KEY ("N",f21) "Next" "DISPLAY next selected goods receipt RECORD " 
			FETCH NEXT c_poaudit INTO pr_poaudit.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9157,"") 
				#9157 "You have reached the END of entries selected"
			ELSE 
				CALL display_poaudit() 
			END IF 
		COMMAND KEY ("P",f19) "Previous" "DISPLAY previous selected goods receipt record" 
			FETCH previous c_poaudit INTO pr_poaudit.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9156,"") 
				#9157 "You have reached the start of entries selected"
			ELSE 
				CALL display_poaudit() 
			END IF 
		COMMAND KEY ("F",f18) "First" "DISPLAY first goods receipt RECORD in the selected list" 
			FETCH FIRST c_poaudit INTO pr_poaudit.* 
			CALL display_poaudit() 
		COMMAND KEY ("L",f22) "Last" "DISPLAY last goods receipt RECORD in the selected list" 
			FETCH LAST c_poaudit INTO pr_poaudit.* 
			CALL display_poaudit() 
		COMMAND KEY (interrupt,"E")"Exit" "Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_poaudit() 
	DEFINE 
	pr_vendor RECORD LIKE vendor.* 

	SELECT * INTO pr_vendor.* FROM vendor 
	WHERE vend_code = pr_poaudit.vend_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME pr_poaudit.vend_code, 
	pr_vendor.name_text, 
	pr_poaudit.po_num, 
	pr_poaudit.line_num, 
	pr_poaudit.tran_code, 
	pr_poaudit.tran_num, 
	pr_poaudit.seq_num, 
	pr_poaudit.entry_date, 
	pr_poaudit.entry_code, 
	pr_poaudit.orig_auth_flag, 
	pr_poaudit.now_auth_flag, 
	pr_poaudit.order_qty, 
	pr_poaudit.received_qty, 
	pr_poaudit.voucher_qty, 
	pr_poaudit.desc_text, 
	pr_poaudit.unit_cost_amt, 
	pr_poaudit.ext_cost_amt, 
	pr_poaudit.unit_tax_amt, 
	pr_poaudit.ext_tax_amt, 
	pr_poaudit.line_total_amt, 
	pr_poaudit.posted_flag, 
	pr_poaudit.jour_num, 
	pr_poaudit.year_num, 
	pr_poaudit.period_num 

END FUNCTION 
