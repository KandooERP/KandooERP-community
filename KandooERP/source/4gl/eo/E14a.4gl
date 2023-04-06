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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E14_GLOBALS.4gl" 
###########################################################################
# FUNCTION insert_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_event_text, 	p_curr_text,p_prev_text)   
#
# FUNCTION TO INSERT an event OR COLUMN change INTO the
#              orderlog table.
###########################################################################
FUNCTION insert_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_event_text,p_curr_text,p_prev_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_order_num LIKE orderlog.order_num 
	DEFINE p_event_text LIKE orderlog.event_text 
	DEFINE p_prev_text LIKE orderlog.prev_text 
	DEFINE p_curr_text LIKE orderlog.curr_text 
	DEFINE l_time LIKE orderlog.amend_time 

	SELECT unique 1 FROM opparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_num = "1" 
	AND log_flag in ("1","3") 
	IF sqlca.sqlcode = 0 THEN 
		LET p_event_text = kandooword("orderlog.event_text",p_event_text) 
		IF p_event_text IS NULL THEN 
			LET p_event_text = "******************" 
		END IF 
		LET l_time = time 
		WHENEVER ERROR CONTINUE 
		#----------------------------------------
		# IF database lock occurrs THEN continue
		INSERT INTO orderlog VALUES (
			p_cmpy_code, 
			p_order_num, 
			0, 
			today, 
			l_time, 
			p_kandoouser_sign_on_code, 
			p_event_text, 
			p_prev_text, 
			p_curr_text) 
		WHENEVER ERROR stop 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION insert_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_event_text, 	p_curr_text,p_prev_text)
###########################################################################


###########################################################################
# FUNCTION insert_line_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_part_code,p_line_num,p_rec_orderdetl,p_rec_t_orderdetl)   
#
# 
###########################################################################
FUNCTION insert_line_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_part_code,p_line_num,p_rec_orderdetl,p_rec_t_orderdetl) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_order_num LIKE orderhead.order_num 
	DEFINE p_part_code LIKE orderdetl.part_code 
	DEFINE p_line_num LIKE orderdetl.line_num 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE p_rec_t_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_orderdetlog RECORD LIKE orderdetlog.* 

	SELECT unique 1 FROM opparms 
	WHERE cmpy_code = p_cmpy_code 
	AND key_num = "1" 
	AND log_flag in ("2","3") 
	IF sqlca.sqlcode = 0 THEN 
		LET l_rec_orderdetlog.cmpy_code = p_cmpy_code 
		LET l_rec_orderdetlog.order_num = p_order_num 
		LET l_rec_orderdetlog.line_num = p_line_num 
		LET l_rec_orderdetlog.part_code = p_part_code 
		LET l_rec_orderdetlog.pre_qty = p_rec_orderdetl.order_qty 
		LET l_rec_orderdetlog.post_qty = p_rec_t_orderdetl.order_qty 
		LET l_rec_orderdetlog.pre_price_amt = p_rec_orderdetl.unit_price_amt 
		LET l_rec_orderdetlog.post_price_amt = p_rec_t_orderdetl.unit_price_amt 
		LET l_rec_orderdetlog.pre_tax_amt = p_rec_orderdetl.unit_tax_amt 
		LET l_rec_orderdetlog.post_tax_amt = p_rec_t_orderdetl.unit_tax_amt 
		LET l_rec_orderdetlog.ammend_date = today 
		LET l_rec_orderdetlog.ammend_code = p_kandoouser_sign_on_code 
		LET l_rec_orderdetlog.ammend_time = time 
		LET l_rec_orderdetlog.update_ind = "U" 
		
		IF l_rec_orderdetlog.pre_qty IS NULL THEN 
			LET l_rec_orderdetlog.pre_qty = 0 
		END IF 
		IF l_rec_orderdetlog.post_qty IS NULL THEN 
			LET l_rec_orderdetlog.post_qty = 0 
		END IF 
		IF l_rec_orderdetlog.pre_price_amt IS NULL THEN 
			LET l_rec_orderdetlog.pre_price_amt = 0 
		END IF 
		IF l_rec_orderdetlog.post_price_amt IS NULL THEN 
			LET l_rec_orderdetlog.post_price_amt = 0 
		END IF 
		IF l_rec_orderdetlog.pre_tax_amt IS NULL THEN 
			LET l_rec_orderdetlog.pre_tax_amt = 0 
		END IF 
		IF l_rec_orderdetlog.post_tax_amt IS NULL THEN 
			LET l_rec_orderdetlog.post_tax_amt = 0 
		END IF
		 
		INSERT INTO orderdetlog VALUES (l_rec_orderdetlog.*)
		 
	END IF 
	
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION insert_line_log(p_cmpy_code,p_kandoouser_sign_on_code,p_order_num,p_part_code,p_line_num,p_rec_orderdetl,p_rec_t_orderdetl)
###########################################################################