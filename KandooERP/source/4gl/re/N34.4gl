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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N3_GROUP_GLOBALS.4gl"
GLOBALS "../re/N34_GLOBALS.4gl"  
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N34 - Requisition Back Order Allocation Release
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N34") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N124 with FORM "N124" 
	CALL windecoration_n("N124") -- albo kd-763 

	WHILE select_bkords() 
	END WHILE 

	CLOSE WINDOW n124 
END MAIN 


FUNCTION select_bkords() 
	DEFINE 
	pr_reqbackord RECORD LIKE reqbackord.*, 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	where_text CHAR(400), 
	query_text CHAR(700), 
	err_message CHAR(50), 
	err_continue CHAR(1), 
	pr_alloc_cnt SMALLINT 

	CLEAR FORM 
	DISPLAY "" at 2,1 
	MESSAGE " Enter Selection Criteria - ESC TO Continue " 
	attribute(yellow) 
	CONSTRUCT where_text ON reqbackord.ware_code, 
	reqbackord.part_code, 
	reqbackord.req_num, 
	reqbackord.require_qty, 
	reqbackord.person_code, 
	reqhead.req_date, 
	reqhead.year_num, 
	reqhead.period_num 
	FROM reqhead.ware_code, 
	reqdetl.part_code, 
	reqhead.req_num, 
	reqdetl.back_qty, 
	reqhead.person_code, 
	reqhead.req_date, 
	reqhead.year_num, 
	reqhead.period_num 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE " Searching database - please wait " 
		attribute(yellow) 
	END IF 
	LET query_text = 
	"SELECT reqbackord.* ", 
	"FROM reqbackord,", 
	"reqhead ", 
	"WHERE reqbackord.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqbackord.cmpy_code = reqhead.cmpy_code ", 
	"AND reqbackord.req_num = reqhead.req_num ", 
	"AND ",where_text clipped," ", 
	"ORDER BY reqbackord.ware_code,", 
	"reqbackord.part_code" 
	{
	   OPEN WINDOW w_N34 AT 16,18 with 5 rows,40 columns    -- albo  KD-763
	         ATTRIBUTE(border,cyan)
	   CLEAR window w_N34
	}
	DISPLAY " Warehouse..........." at 1,1 

	DISPLAY " Releasing Product.." at 2,1 

	DISPLAY " TO Requisition No.." at 3,1 

	DISPLAY " Line No.." at 4,1 

	DISPLAY " Allocation.." at 5,1 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_alloc_cnt = 0 
		PREPARE s_reqbackord FROM query_text 
		DECLARE c_reqbackord CURSOR FOR s_reqbackord 
		FOREACH c_reqbackord INTO pr_reqbackord.* 
			LET pr_alloc_cnt = pr_alloc_cnt + 1 
			DISPLAY pr_reqbackord.ware_code at 1,22 
			attribute(yellow) 
			DISPLAY pr_reqbackord.part_code at 2,22 
			attribute(yellow) 
			DISPLAY pr_reqbackord.req_num USING "<<<<<<<" at 3,22 
			attribute(yellow) 
			DISPLAY pr_reqbackord.line_num USING "<<<<<<<" at 4,22 
			attribute(yellow) 
			DISPLAY pr_alloc_cnt USING "<<<<<<<" at 5,14 
			attribute(yellow) 
			SLEEP 1 
			LET err_message = "N34 - Requisition Line Update" 
			DECLARE c_reqdetl CURSOR FOR 
			SELECT reqdetl.* 
			FROM reqdetl 
			WHERE cmpy_code = pr_reqbackord.cmpy_code 
			AND req_num = pr_reqbackord.req_num 
			AND line_num = pr_reqbackord.line_num 
			FOR UPDATE 
			OPEN c_reqdetl 
			FETCH c_reqdetl INTO pr_reqdetl.* 
			LET pr_reqdetl.seq_num = pr_reqdetl.seq_num + 1 
			LET pr_reqdetl.back_qty = pr_reqdetl.back_qty 
			- pr_reqbackord.alloc_qty 
			LET pr_reqdetl.reserved_qty = pr_reqdetl.reserved_qty 
			+ pr_reqbackord.alloc_qty 
			LET pr_reqdetl.po_rec_qty = pr_reqdetl.po_rec_qty 
			+ pr_reqbackord.alloc_qty 
			IF pr_reqdetl.po_rec_qty > pr_reqdetl.po_qty THEN 
				LET pr_reqdetl.po_rec_qty = pr_reqdetl.po_qty 
			END IF 
			UPDATE reqdetl 
			SET seq_num = pr_reqdetl.seq_num, 
			back_qty = pr_reqdetl.back_qty, 
			reserved_qty = pr_reqdetl.reserved_qty, 
			po_rec_qty = pr_reqdetl.po_rec_qty 
			WHERE CURRENT OF c_reqdetl 
			#LET err_message = "N34 - Requisition Audit Insert "
			#LET pr_reqaudit.cmpy_code = pr_reqdetl.cmpy_code
			#LET pr_reqaudit.req_num = pr_reqdetl.req_num
			#LET pr_reqaudit.line_num = pr_reqdetl.line_num
			#LET pr_reqaudit.seq_num = pr_reqdetl.seq_num
			#LET pr_reqaudit.tran_type_ind = "BA"
			#LET pr_reqaudit.tran_date = today
			#LET pr_reqaudit.entry_code = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty = pr_reqbackord.alloc_qty
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET err_message = "N34 - Prodstatus Update " 
			UPDATE prodstatus 
			SET reserved_qty = reserved_qty + pr_reqbackord.alloc_qty, 
			back_qty = back_qty - pr_reqbackord.alloc_qty, 
			seq_num = seq_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_reqbackord.ware_code 
			AND part_code = pr_reqbackord.part_code 
			LET err_message = "N34 - Req. Back Order Deletion" 
			DELETE FROM reqbackord 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_reqbackord.part_code 
			AND ware_code = pr_reqbackord.ware_code 
			AND req_num = pr_reqbackord.req_num 
			AND line_num = pr_reqbackord.line_num 
		END FOREACH 
	COMMIT WORK 
	--   CLOSE WINDOW w_N34     -- albo  KD-763
	IF pr_alloc_cnt = 0 THEN 
		error" No Back Order Allocations Satisfied Selection Criteria" 
	END IF 
	RETURN true 
END FUNCTION 
