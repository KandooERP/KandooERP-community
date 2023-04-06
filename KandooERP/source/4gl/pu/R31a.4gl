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


#GLOBALS "../common/glob_GLOBALS.4gl"
#as GLOBALS FROM R31
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R31_GLOBALS.4gl" 

# This routine receives a "SELECT statement" AND displays the
# lines retreived TO the SCREEN.  This FUNCTION requires that one of
# the following windows already be OPEN.
#
#  - R31 GL Commitments R115
#  - R32 JM Commitments R117
#  - R33 IN Commitments R121




FUNCTION scan_commitments(where_text) 
	DEFINE 
	query_text CHAR(500), 
	where_text CHAR(200), 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pa_purchdetl ARRAY [1000] OF RECORD 
		order_num LIKE purchdetl.order_num, 
		type_ind LIKE purchdetl.type_ind, 
		vend_code LIKE purchdetl.vend_code, 
		desc_text LIKE purchdetl.desc_text, 
		order_qty LIKE poaudit.order_qty, 
		line_total_amt LIKE poaudit.line_total_amt 
	END RECORD, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_total_amt LIKE poaudit.line_total_amt, 
	idx SMALLINT 

	LET idx = 0 
	LET pr_total_amt = 0 
	LET msgresp=kandoomsg("U",1002,"") 
	LET query_text = "SELECT purchdetl.* FROM purchdetl,purchhead ", 
	"WHERE purchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchhead.order_num = purchdetl.order_num ", 
	"AND purchhead.status_ind != 'C' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY purchdetl.order_num" 
	PREPARE s_purchdetl FROM query_text 
	DECLARE c_purchdetl CURSOR FOR s_purchdetl 
	FOREACH c_purchdetl INTO pr_purchdetl.* 
		LET idx = idx + 1 
		LET pa_purchdetl[idx].order_num = pr_purchdetl.order_num 
		LET pa_purchdetl[idx].type_ind = pr_purchdetl.type_ind 
		LET pa_purchdetl[idx].vend_code = pr_purchdetl.vend_code 
		LET pa_purchdetl[idx].desc_text = pr_purchdetl.desc_text 
		CALL po_line_info(glob_rec_kandoouser.cmpy_code,pr_purchdetl.order_num, 
		pr_purchdetl.line_num) 
		RETURNING pr_poaudit.order_qty, 
		pr_poaudit.received_qty, 
		pr_poaudit.voucher_qty, 
		pr_poaudit.unit_cost_amt, 
		pr_poaudit.ext_cost_amt, 
		pr_poaudit.unit_tax_amt, 
		pr_poaudit.ext_tax_amt, 
		pr_poaudit.line_total_amt 
		LET pa_purchdetl[idx].order_qty = pr_poaudit.order_qty 
		- pr_poaudit.received_qty 
		IF pa_purchdetl[idx].order_qty = 0 THEN 
			INITIALIZE pa_purchdetl[idx].* TO NULL 
			LET idx = idx - 1 
			CONTINUE FOREACH 
		END IF 
		LET pa_purchdetl[idx].line_total_amt = pr_poaudit.line_total_amt 
		IF pa_purchdetl[idx].line_total_amt IS NOT NULL THEN 
			LET pr_total_amt = pr_total_amt + pa_purchdetl[idx].line_total_amt 
		END IF 
		IF idx = 1000 THEN 
			LET msgresp=kandoomsg("U",9100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("U",9101,"") 
		SLEEP 2 ## required 
	ELSE 
		CALL set_count(idx) 
		LET msgresp=kandoomsg("R",1007,"") 
		DISPLAY pr_total_amt TO commit_total 

		DISPLAY ARRAY pa_purchdetl TO sr_purchdetl.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","R31a","display-arr-purchdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (tab) 
				LET idx = arr_curr() 
				CALL pohdwind(glob_rec_kandoouser.cmpy_code, pa_purchdetl[idx].order_num) 
			ON KEY (RETURN) 
				LET idx = arr_curr() 
				CALL pohdwind(glob_rec_kandoouser.cmpy_code, pa_purchdetl[idx].order_num) 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END DISPLAY 
	END IF 
END FUNCTION 
