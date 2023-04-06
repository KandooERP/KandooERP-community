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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N1_GROUP_GLOBALS.4gl" 
GLOBALS "../re/N11_GLOBALS.4gl" 
#    N11f Database Update/Insert Routines used by Requisition Entry
########################################################################
# Functions in this module are:
# * write_req  - Write the newly added Requisition Header/Line Details
# * update_req - Update Requisition Details
# * back_out   - Back out any stock changes made IF SQL error occurs

FUNCTION write_req() 
	DEFINE l_rec_reqparms RECORD LIKE reqparms.*
	DEFINE pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_tot_reserved_qty LIKE reqdetl.reserved_qty, 
	err_message CHAR(30), 
	idx SMALLINT 

	LET msgresp=kandoomsg("U",1005,"") 
	#U1005 Updating database...
	LET pr_tot_reserved_qty = 0 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	
	BEGIN WORK 
		LET err_message = "Collect RE Parameters - N11f" 
		DECLARE c_reqparms CURSOR FOR 
		SELECT * FROM reqparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_reqparms 
		FETCH c_reqparms INTO l_rec_reqparms.* 
		LET pr_reqhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_reqhead.req_num = l_rec_reqparms.next_req_num 
		LET pr_reqhead.type_ind = 1 
		LET pr_reqhead.rev_num = 1 
		LET pr_reqhead.total_tax_amt = 0 
		LET pr_reqhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_reqhead.entry_date = today 
		LET pr_reqhead.last_mod_code = glob_rec_kandoouser.sign_on_code 
		LET pr_reqhead.last_mod_date = today 
		LET pr_reqhead.line_num = 0 
		LET pr_reqhead.last_del_no = 0 
		DECLARE c_t_reqdetl CURSOR FOR 
		SELECT * FROM t_reqdetl 
		ORDER BY line_num 
		FOREACH c_t_reqdetl INTO pr_reqdetl.* 
			LET pr_reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_reqdetl.req_num = pr_reqhead.req_num 
			LET pr_reqhead.line_num = pr_reqhead.line_num + 1 
			LET pr_reqdetl.line_num = pr_reqhead.line_num 
			LET pr_reqdetl.unit_cost_amt = pr_reqdetl.unit_sales_amt 
			LET pr_reqdetl.unit_tax_amt = 0 
			LET pr_reqdetl.seq_num = 1 
			LET pr_reqdetl.unit_tax_amt = 0 
			LET pr_reqdetl.level_ind = "C" 
			LET err_message = "Requisition Detail Insert - N11f" 
			INSERT INTO reqdetl VALUES (pr_reqdetl.*) 
			#LET pr_reqaudit.cmpy_code      = glob_rec_kandoouser.cmpy_code
			#LET pr_reqaudit.req_num        = pr_reqhead.req_num
			#LET pr_reqaudit.line_num       = pr_reqhead.line_num
			#LET pr_reqaudit.seq_num        = 1
			#LET pr_reqaudit.tran_type_ind  = "AR"
			#LET pr_reqaudit.tran_date      = today
			#LET pr_reqaudit.entry_code     = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt  = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt   = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty       = pr_reqdetl.req_qty
			#LET err_message = "Requisition Audit INSERT - N11f"
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET pr_tot_reserved_qty = pr_tot_reserved_qty 
			+ pr_reqdetl.reserved_qty 
		END FOREACH 
		SELECT sum(unit_sales_amt * req_qty) 
		INTO pr_reqhead.total_sales_amt 
		FROM t_reqdetl 
		IF pr_reqhead.total_sales_amt IS NULL THEN 
			LET pr_reqhead.total_sales_amt = 0 
		END IF 
		LET pr_reqhead.total_cost_amt = pr_reqhead.total_sales_amt 
		LET err_message = "Requisition header INSERT - N11f" 
		INSERT INTO reqhead VALUES (pr_reqhead.*) 
		LET l_rec_reqparms.next_req_num = l_rec_reqparms.next_req_num + 1 
		LET err_message = "RE Parameter Update - N11f" 
		UPDATE reqparms 
		SET next_req_num = l_rec_reqparms.next_req_num 
		WHERE CURRENT OF c_reqparms 
		CLOSE c_reqparms 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 
#
# Update Requisition Details
#
FUNCTION update_req() 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	ps_reqhead, 
	pt_reqhead RECORD LIKE reqhead.*, 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_status INTEGER, 
	pr_err_message CHAR(80) 

	LET msgresp=kandoomsg("U",1005,"") 
	#U1005 Updating Database...
	GOTO bypass 
	LABEL recovery: 
	LET pr_status = status 
	LET pr_reqhead.* = ps_reqhead.* 
	IF error_recover(pr_err_message, pr_status) != "Y" THEN 
		CALL back_out() 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		### Declare INSERT cursors ###
		DECLARE c_reqdetl CURSOR FOR 
		INSERT INTO reqdetl VALUES (pr_reqdetl.*) 
		OPEN c_reqdetl 
		LET ps_reqhead.* = pr_reqhead.* 
		LET pr_err_message = "Locking Requisition Header - N14f" 
		DECLARE c_reqhead CURSOR FOR 
		SELECT * FROM reqhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
		FOR UPDATE 
		OPEN c_reqhead 
		FETCH c_reqhead INTO pt_reqhead.* 
		IF pt_reqhead.rev_num != pr_reqhead.rev_num THEN 
			LET pr_err_message = "Requisition has changed during Edit - N14f" 
			GOTO recovery 
		END IF 
		### Lines Processing ###
		LET pr_err_message = "Removing Existing Requisition Line Items" 
		#DECLARE c1_reqdetl CURSOR FOR
		#   SELECT * FROM reqdetl
		#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#      AND req_num = pr_reqhead.req_num
		#   FOR UPDATE
		#FOREACH c1_reqdetl INTO pr_reqdetl.*
		#LET pr_reqaudit.cmpy_code      = glob_rec_kandoouser.cmpy_code
		#LET pr_reqaudit.req_num        = pr_reqhead.req_num
		#LET pr_reqaudit.line_num       = pr_reqdetl.line_num
		#LET pr_reqaudit.seq_num        = pr_reqdetl.seq_num + 1
		#LET pr_reqaudit.tran_type_ind  = "ER"
		#LET pr_reqaudit.tran_date      = today
		#LET pr_reqaudit.entry_code     = glob_rec_kandoouser.sign_on_code
		#LET pr_reqaudit.unit_cost_amt  = pr_reqdetl.unit_sales_amt
		#LET pr_reqaudit.unit_tax_amt   = 0
		#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
		#LET pr_reqaudit.tran_qty       = pr_reqdetl.req_qty * -1
		#LET pr_err_message = "Problems Inserting Requistion Line Audit"
		#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
		#LET pr_err_message = "Problems Deleting Requisition Line"
		#   DELETE FROM reqdetl
		#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#      AND req_num   = pr_reqhead.req_num
		#      AND line_num  = pr_reqdetl.line_num
		#END FOREACH
		LET pr_err_message = "Problems Deleting Requisition Lines" 
		DELETE FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
		LET pr_reqhead.line_num = 0 
		DECLARE c2_t_reqdetl CURSOR FOR 
		SELECT * FROM t_reqdetl 
		ORDER BY line_num 
		FOREACH c2_t_reqdetl INTO pr_reqdetl.* 
			#LET pr_reqhead.line_num = pr_reqhead.line_num + 1
			#LET pr_reqaudit.cmpy_code      = glob_rec_kandoouser.cmpy_code
			#LET pr_reqaudit.req_num        = pr_reqhead.req_num
			#LET pr_reqaudit.line_num       = pr_reqdetl.line_num
			#LET pr_reqaudit.seq_num        = pr_reqdetl.seq_num + 2
			#LET pr_reqaudit.tran_type_ind  = "ER"
			#LET pr_reqaudit.tran_date      = today
			#LET pr_reqaudit.entry_code     = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt  = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt   = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty       = pr_reqdetl.req_qty
			#LET pr_err_message = "Problems Inserting Requistion Line Audit"
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET pr_err_message = "Problems Inserting Requistion Line" 
			PUT c_reqdetl 
		END FOREACH 
		CLOSE c_reqdetl 
		IF NOT held_order THEN 
			SELECT unique 1 FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqhead.req_num 
			AND po_qty = 0 
			IF status = notfound THEN 
				LET pr_reqhead.status_ind = "9" 
			ELSE 
				SELECT unique 1 FROM reqdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqhead.req_num 
				AND po_qty > 0 
				IF status = notfound THEN 
					LET pr_reqhead.status_ind = "1" 
				ELSE 
					LET pr_reqhead.status_ind = "2" 
				END IF 
			END IF 
		END IF 
		SELECT sum(unit_sales_amt * req_qty) INTO pr_reqhead.total_sales_amt 
		FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
		AND req_qty IS NOT NULL 
		AND unit_sales_amt IS NOT NULL 
		IF pr_reqhead.total_sales_amt IS NULL THEN 
			LET pr_reqhead.total_sales_amt = 0 
		END IF 
		LET pr_reqhead.total_cost_amt = pr_reqhead.total_sales_amt 
		LET pr_reqhead.last_mod_code = glob_rec_kandoouser.sign_on_code 
		LET pr_reqhead.last_mod_date = today 
		LET pr_reqhead.rev_num = pr_reqhead.rev_num + 1 
		LET pr_err_message = "N14 - Requisition Header Update" 
		UPDATE reqhead 
		SET * = pr_reqhead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 


FUNCTION back_out() 
	DEFINE 
	pr_line_num INTEGER 

	DECLARE c_backout CURSOR with HOLD FOR 
	SELECT line_num FROM t_reqdetl 
	FOREACH c_backout INTO pr_line_num 
		IF stock_line(pr_line_num,TRAN_TYPE_INVOICE_IN,0) THEN 
		END IF 
	END FOREACH 
	IF stock_line(pr_reqhead.req_num,"REQ",0) THEN 
	END IF 
	CLOSE c_backout 
END FUNCTION 
