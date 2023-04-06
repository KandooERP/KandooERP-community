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

	Source code beautified by beautify.pl on 2020-01-02 17:06:14	Source code beautified by beautify.pl on 2020-01-02 17:03:24	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

# Purpose - po_line_detail DISPLAY the audit trail info

GLOBALS 
	DEFINE 
	cust LIKE vendor.vend_code, 
	ponum LIKE poaudit.po_num, 
	linenum LIKE poaudit.line_num, 
	seqnum LIKE poaudit.seq_num, 
	ans CHAR(1), 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	where_part, query_text CHAR(900), 
	exist SMALLINT 
END GLOBALS 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R19") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW wr140 with FORM "R140" 
	CALL  windecoration_r("R140") 

	CALL query() 

	CLOSE WINDOW wr140 

END MAIN 

FUNCTION select_them1() 

	MESSAGE 
	"Enter criteria FOR selection - ESC TO begin search" 
	attribute(yellow) 

	CONSTRUCT BY NAME where_part ON vend_code, 
	po_num, 
	line_num, 
	tran_code, 
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
			CALL publish_toolbar("kandoo","R19","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	LET query_text = 
	" SELECT * ", 
	" FROM poaudit ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ", 
	where_part clipped 
END FUNCTION 

#Note: all arg_val need to be replaced with url accessor methods
FUNCTION select_them2() 
	LET query_text = 
	" SELECT poaudit.* ", 
	" FROM poaudit, purchdetl ", 
	" WHERE poaudit.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	" poaudit.cmpy_code = purchdetl.cmpy_code AND ", 
	" poaudit.vend_code = \"", arg_val(1), "\" AND ", 
	" poaudit.vend_code = purchdetl.vend_code AND ", 
	" poaudit.po_num = \"", arg_val(2), "\" AND ", 
	" poaudit.po_num = purchdetl.order_num AND ", 
	" poaudit.jour_num = \"", arg_val(3), "\" AND ", 
	" purchdetl.acct_code = \"", arg_val(4), "\" AND ", 
	" poaudit.line_num = purchdetl.line_num AND ", 
	" (poaudit.tran_code = \"GR\" OR poaudit.tran_code = \"GA\")" 
END FUNCTION 


FUNCTION select_them() 
	LET exist = 0 
	IF ((int_flag != 0 
	OR quit_flag != 0) 
	AND exist = 0) 
	THEN 
		EXIT program 
	END IF 

	PREPARE statement_1 FROM query_text 
	DECLARE poaudit_set SCROLL CURSOR FOR statement_1 
	OPEN poaudit_set 

	MESSAGE " " 
	FETCH poaudit_set INTO pr_poaudit.* 
	IF status <> notfound 
	THEN 
		LET exist = true 
	END IF 
END FUNCTION 

FUNCTION query() 
	CLEAR FORM 
	LET exist = false 
	IF num_args() > 0 THEN 
		CALL select_them2() 
		CALL select_them() 
		IF exist THEN 
			CALL show_it() 
		ELSE 
			ERROR "No ORDER satisfied the search criteria" 
		END IF 
	END IF 

	MENU "Audit Trail" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","R19","menu-audit_trail-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Query" "Use TO search FOR audit records " 
			IF num_args() > 0 THEN 
			ELSE 
				CALL select_them1() 
			END IF 
			CALL select_them() 
			IF exist THEN 
				CALL show_it() 
			ELSE 
				ERROR "No audit RECORD satisfied the query criteria" 
			END IF 
		COMMAND KEY ("N",f21) "Next" "DISPLAY next selected audit RECORD " 
			IF exist THEN 
				FETCH NEXT poaudit_set INTO pr_poaudit.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the audit records selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("P",f19) "Previous" "DISPLAY previous selected audit record" 
			IF exist THEN 
				FETCH previous poaudit_set INTO pr_poaudit.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the audit records selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("F",f18) "First" "DISPLAY first audit RECORD in the selected list" 
			IF exist THEN 
				FETCH FIRST poaudit_set INTO pr_poaudit.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the audit records selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("L",f22) "Last" "DISPLAY last audit RECORD in the selected list" 
			IF exist THEN 
				FETCH LAST poaudit_set INTO pr_poaudit.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the clients selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY (interrupt, escape) "DEL TO Exit" "Exit FROM this enquiry" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 

FUNCTION show_it() 

	SELECT * 
	INTO pr_vendor.* 
	FROM vendor 
	WHERE vendor.vend_code = pr_poaudit.vend_code 
	AND vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF (status = notfound) THEN 
		ERROR "Vendor FOR P.O. audit NOT found" 
		SLEEP 4 
		RETURN 
	END IF 

	DISPLAY BY NAME 
	pr_poaudit.vend_code, 
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
