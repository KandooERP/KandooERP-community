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
# \brief module N11a - Internal Requisition Entry (Header Detail Entry)
########################################################################
# Functions in this module are:
#
# * stock_line     - Stock Line adjustments. Updates prodstatus table.
# * req_INITIALIZE - INITIALIZEs the t_reqdetl AND ARRAY variables.

#
#
FUNCTION stock_line(pr_key_num,pr_mode,in_trans) 
	DEFINE 
	pr_key_num INTEGER, 
	pr_mode CHAR(3), 
	in_trans INTEGER, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_rowid INTEGER, 
	err_message CHAR(60), 
	pr_temp_text CHAR(200) 

	IF pr_reqhead.stock_ind = '0' THEN 
		RETURN 1 
	END IF 
	LET pr_temp_text = "SELECT rowid,* FROM prodstatus ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND part_code = ? ", 
	"AND ware_code = ? ", 
	"AND stocked_flag = 'Y' " 
	PREPARE s_pdstatus FROM pr_temp_text 
	DECLARE c_pdstatus CURSOR FOR s_pdstatus 
	IF pr_key_num IS NOT NULL THEN 
		WHENEVER ERROR GOTO recovery 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message,status) != "Y" THEN 
			CALL errorlog(err_message) 
			RETURN 0 #### ROLLBACK no retry 
		ELSE 
			IF in_trans THEN 
				RETURN -1 #### ROLLBACK try again 
			END IF 
		END IF 
		LABEL bypass: 
		IF NOT in_trans THEN 
			BEGIN WORK 
			END IF 
			IF pr_mode = "REQ" THEN 
				LET pr_temp_text = "SELECT * FROM reqdetl ", 
				"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
				" AND req_num = '",pr_key_num,"'" 
			ELSE 
				LET pr_temp_text = "SELECT * FROM t_reqdetl ", 
				"WHERE line_num = '",pr_key_num,"'" 
			END IF 
			LET pr_temp_text = pr_temp_text clipped," ", 
			"AND part_code IS NOT NULL ", 
			"AND (reserved_qty!=0 OR back_qty!=0)" 
			PREPARE s_reqdetl FROM pr_temp_text 
			DECLARE c_reqdetl CURSOR with HOLD FOR s_reqdetl 
			FOREACH c_reqdetl INTO pr_reqdetl.* 
				LET err_message = "Error reserving stock FOR ", 
				" Ware: ",pr_reqhead.ware_code clipped, 
				" Part: ",pr_reqdetl.part_code 
				OPEN c_pdstatus USING pr_reqdetl.part_code, 
				pr_reqhead.ware_code 
				FETCH c_pdstatus INTO pr_rowid, 
				pr_prodstatus.* 
				IF sqlca.sqlcode = 0 THEN 
					IF pr_prodstatus.reserved_qty IS NULL THEN 
						LET pr_prodstatus.reserved_qty = 0 
					END IF 
					IF pr_prodstatus.back_qty IS NULL THEN 
						LET pr_prodstatus.back_qty = 0 
					END IF 
					LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
					IF (pr_prodstatus.stocked_flag = "Y") AND 
					(pr_reqhead.stock_ind != 0) 
					THEN 
						CASE 
							WHEN pr_mode = TRAN_TYPE_INVOICE_IN 
								LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty 
								- pr_reqdetl.reserved_qty 
								LET pr_prodstatus.back_qty = pr_prodstatus.back_qty 
								- pr_reqdetl.back_qty 
							WHEN pr_mode = "OUT" 
								LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty 
								+ pr_reqdetl.reserved_qty 
								LET pr_prodstatus.back_qty = pr_prodstatus.back_qty 
								+ pr_reqdetl.back_qty 
							WHEN pr_mode = "REQ" 
								LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty 
								+ pr_reqdetl.reserved_qty 
								LET pr_prodstatus.back_qty = pr_prodstatus.back_qty 
								+ pr_reqdetl.back_qty 
						END CASE 
						UPDATE prodstatus 
						SET reserved_qty = pr_prodstatus.reserved_qty, 
						back_qty = pr_prodstatus.back_qty, 
						seq_num = pr_prodstatus.seq_num 
						WHERE rowid = pr_rowid 
						WHENEVER ERROR stop 
					END IF 
				END IF 
			END FOREACH 
			IF NOT in_trans THEN 
			COMMIT WORK 
		END IF 
	END IF 
	RETURN 1 #### everything ok COMMIT WORK 
END FUNCTION 
#
#
FUNCTION req_initialize() 
	DEFINE 
	i SMALLINT 

	LET pr_reset_array = false 
	LET pr_arr_size = 2000 
	FOR i = 1 TO pr_arr_size 
		INITIALIZE pa_reqdetl[i].* TO NULL 
	END FOR 
	WHENEVER ERROR CONTINUE 
	DELETE FROM t_reqdetl WHERE 1=1 
	INITIALIZE pr_reqhead.* TO NULL 
	WHENEVER ERROR stop 
END FUNCTION 
