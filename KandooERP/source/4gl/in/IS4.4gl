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

	Source code beautified by beautify.pl on 2020-01-03 09:12:40	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# Purpose - Recalculate Stock_turns & Reorder Information

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_inparms RECORD LIKE inparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	start_date, 
	end_date DATE, 
	reorder_flag CHAR(1), 
	tran_type_text CHAR(120) 
END GLOBALS 



####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IS4") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		ERROR " Inventory Parameters NOT found - Use IZP" 
		SLEEP 4 
		EXIT program 
	END IF 
	SELECT * 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	OPEN WINDOW i208 with FORM "I208" 
	 CALL windecoration_i("I208") -- albo kd-758 

	IF get_info() THEN 
		CALL get_items() 
	END IF 
	CLOSE WINDOW i208 
END MAIN 


FUNCTION get_info() 
	DEFINE 
	pr_tran_type RECORD 
		inv_flag CHAR(1), 
		cred_flag CHAR(1), 
		inv_iss_flag CHAR(1), 
		jm_iss_flag CHAR(1) 
	END RECORD 

	LET reorder_flag = "N" 
	LET start_date = today - 183 
	LET end_date = today 
	LET pr_tran_type.inv_flag = "Y" 
	LET pr_tran_type.cred_flag = "Y" 
	LET pr_tran_type.inv_iss_flag = "Y" 
	IF pr_jmparms.jm_flag = "Y" THEN 
		DISPLAY "Job Management Issues...." 
		TO jm_prompt_text 
		attribute(white) 
		LET pr_tran_type.jm_iss_flag = "Y" 
	ELSE 
		CLEAR jm_prompt_text 
		LET pr_tran_type.jm_iss_flag = NULL 
	END IF 
	DISPLAY BY NAME pr_inparms.last_del_date, 
	start_date, 
	end_date, 
	reorder_flag, 
	pr_tran_type.inv_flag, 
	pr_tran_type.cred_flag, 
	pr_tran_type.inv_iss_flag, 
	pr_tran_type.jm_iss_flag 

	INPUT BY NAME start_date, 
	end_date, 
	reorder_flag, 
	pr_tran_type.inv_flag, 
	pr_tran_type.cred_flag, 
	pr_tran_type.inv_iss_flag, 
	pr_tran_type.jm_iss_flag 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS4","input-start_date-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD start_date 
			IF start_date IS NULL THEN 
				LET start_date = today - 183 
			END IF 
		AFTER FIELD end_date 
			IF end_date IS NULL THEN 
				LET end_date = today 
			END IF 
			IF end_date < start_date THEN 
				ERROR " END Date IS less than Starting Date" 
				NEXT FIELD start_date 
			END IF 
		AFTER FIELD reorder_flag 
			IF reorder_flag IS NULL THEN 
				LET reorder_flag = "N" 
			END IF 
		BEFORE FIELD jm_iss_flag 
			IF pr_jmparms.jm_flag != "Y" THEN 
				EXIT INPUT 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET tran_type_text = "1!=1" 
	IF pr_tran_type.inv_flag = "Y" THEN 
		LET tran_type_text = tran_type_text clipped, 
		" OR trantype_ind = \"S\"" 
	END IF 
	IF pr_tran_type.cred_flag = "Y" THEN 
		LET tran_type_text = tran_type_text clipped, 
		" OR trantype_ind = \"C\"" 
	END IF 
	IF pr_tran_type.inv_iss_flag = "Y" THEN 
		LET tran_type_text = tran_type_text clipped, 
		" OR trantype_ind = \"I\"" 
	END IF 
	IF pr_tran_type.jm_iss_flag = "Y" THEN 
		LET tran_type_text = tran_type_text clipped, 
		" OR trantype_ind = \"J\"" 
	END IF 
	LET tran_type_text = "(",tran_type_text clipped,")" 
	UPDATE inparms 
	SET last_del_date = today 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	RETURN true 
END FUNCTION 


FUNCTION get_items() 
	DEFINE 
	pr_calc_turn RECORD 
		stk_turn_qty DECIMAL(10,4), 
		stk_cost_amt DECIMAL(16,4), 
		stk_sales_amt DECIMAL(16,4), 
		avg_stk_amt DECIMAL(16,4), 
		reorder_point_qty LIKE prodstatus.reorder_point_qty, 
		reorder_qty LIKE prodstatus.reorder_qty 
	END RECORD, 
	ans CHAR(1), 
	pr_part_code_save LIKE product.part_code, 
	counter SMALLINT 

	LET pr_part_code_save = " " 
	WHENEVER ERROR stop 
	--   OPEN WINDOW w1 AT 21,6 with 1 rows,64 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	DISPLAY "Reporting on Product....." at 1,1 
	attribute(white) 
	LET counter = 0 
	DECLARE itemcurs CURSOR FOR 
	SELECT * 
	INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOREACH itemcurs 
		IF pr_part_code_save != pr_prodstatus.part_code THEN 
			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			DISPLAY pr_product.part_code," ",pr_product.desc_text at 1,23 
			attribute (yellow) 
			CALL calc_turn(glob_rec_kandoouser.cmpy_code, 
			pr_prodstatus.part_code, 
			" ", 
			"zzz", 
			start_date, 
			end_date, 
			"N", 
			0, 
			tran_type_text) 
			RETURNING pr_calc_turn.* 
			UPDATE product 
			SET stock_turn_qty = pr_calc_turn.stk_turn_qty, 
			last_calc_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			LET pr_part_code_save = pr_prodstatus.part_code 
		END IF 
		CALL calc_turn(glob_rec_kandoouser.cmpy_code, 
		pr_prodstatus.part_code, 
		pr_prodstatus.ware_code, 
		pr_prodstatus.ware_code, 
		start_date, 
		end_date, 
		reorder_flag, 
		pr_product.days_lead_num, 
		tran_type_text) 
		RETURNING pr_calc_turn.* 
		IF reorder_flag = "Y" THEN 
			LET pr_prodstatus.reorder_qty = pr_calc_turn.reorder_qty 
			LET pr_prodstatus.reorder_point_qty = 
			pr_calc_turn.reorder_point_qty 
		END IF 
		UPDATE prodstatus 
		SET stockturn_qty = pr_calc_turn.stk_turn_qty, 
		reorder_qty = pr_prodstatus.reorder_qty, 
		reorder_point_qty = pr_prodstatus.reorder_point_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodstatus.part_code 
		AND ware_code = pr_prodstatus.ware_code 
		LET counter = counter + 1 
	END FOREACH 
	--   CLOSE WINDOW w1  -- albo  KD-758
	{  -- albo
	   OPEN WINDOW w1 AT 21,6 with 2 rows,64 columns
	      ATTRIBUTE(border,prompt line last)
	   DISPLAY "Total Number of Products Changed: ", counter AT 1,12
	   prompt  "                    Any Key TO Continue" FOR CHAR ans
	   CLOSE WINDOW w1
	}
	-- albo --
	--   OPEN WINDOW w1 AT 15,6 with 2 rows,64 columns  -- albo  KD-758
	--      ATTRIBUTE(border,prompt line last)
	DISPLAY "Total Number of Products Changed: ", counter at 3,12 
	CALL eventsuspend() 
	--   CLOSE WINDOW w1  -- albo  KD-758

END FUNCTION 
