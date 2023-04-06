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
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl" 

###########################################################################
# FUNCTION reject_pickslip(p_cmpy,p_kandoouser_sign_on_code,p_rec_ware_code,p_pick_num) 
#
# Pickslip rejection FUNCTION TO pickslip maint
###########################################################################
FUNCTION reject_pickslip(p_cmpy,p_kandoouser_sign_on_code,p_rec_ware_code,p_pick_num)
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_ware_code LIKE pickhead.ware_code 
	DEFINE p_pick_num LIKE pickhead.pick_num
	 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_order_num LIKE pickdetl.order_num 
	DEFINE l_event_text char(20) 
	DEFINE l_con SMALLINT 

	LET l_order_num = 0 
	WHENEVER ERROR GOTO recovery 
	LET l_con = 0
	 
	DECLARE c_pickhead cursor FOR 
	SELECT * FROM pickhead 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_rec_ware_code 
	AND pick_num = p_pick_num 
	AND status_ind = "0" 
	AND con_status_ind = "0" 
	FOR UPDATE
	 
	OPEN c_pickhead 
	FETCH c_pickhead 
	IF status = NOTFOUND THEN 
		LET l_con = -1 
		GOTO recovery 
	END IF
	 
	DECLARE c_pickdetl cursor FOR 
	SELECT * FROM pickdetl 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_rec_ware_code 
	AND pick_num = p_pick_num
	 
	FOREACH c_pickdetl INTO l_rec_pickdetl.* 
		UPDATE orderdetl 
		SET 
			picked_qty = picked_qty - l_rec_pickdetl.picked_qty, 
			sched_qty = sched_qty + l_rec_pickdetl.picked_qty 
		WHERE cmpy_code = p_cmpy 
		AND order_num = l_rec_pickdetl.order_num 
		AND line_num = l_rec_pickdetl.order_line_num 
		IF l_rec_pickdetl.order_num != l_order_num THEN 
			LET l_event_text = l_rec_pickdetl.ware_code,":", 
			l_rec_pickdetl.pick_num USING "<<<<<<<<" 
			LET l_order_num = l_rec_pickdetl.order_num 
			CALL insert_log(p_cmpy,p_kandoouser_sign_on_code,l_order_num,55,l_event_text,"") 
		END IF 
	END FOREACH
	 
	UPDATE pickhead 
	SET 
		status_ind = "9", 
		con_status_ind = "9" 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_rec_ware_code 
	AND pick_num = p_pick_num 
	RETURN TRUE 
	
	LABEL recovery: 
	IF l_con < 0 THEN 
		RETURN l_con 
	ELSE 
		RETURN status 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION reject_pickslip(p_cmpy,p_kandoouser_sign_on_code,p_rec_ware_code,p_pick_num) 
###########################################################################