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

	Source code beautified by beautify.pl on 2020-01-03 10:10:03	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 

# FOR handling cursors FOR rptcol


DEFINE 
mr_col RECORD 
	rpt_rowid INTEGER, 
	col_code LIKE rptcol.col_code, 
	col_rowid INTEGER, 
	col_id LIKE rptcol.col_id 
END RECORD 


FUNCTION col_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	CALL close_scurs_col() 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_query_1 = " 1=1" THEN 
		LET fv_s1 = "SELECT rptcolgrp.rowid, rptcolgrp.col_code, ", 
		" rptcol.rowid, rptcol.col_id ", 
		"FROM rptcolgrp, outer(rptcol) ", 
		"WHERE rptcolgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptcol.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptcolgrp.col_code = rptcol.col_code ", 
		"ORDER BY 2, 4" 
	ELSE 
		LET fv_s1 = "SELECT rptcolgrp.rowid, rptcolgrp.col_code, ", 
		"rptcol.rowid, rptcol.col_id ", 
		"FROM rptcolgrp, outer(rptcol) ", 
		"WHERE rptcolgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptcol.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptcolgrp.col_code = rptcol.col_code ", 
		"AND ", 
		gv_query_1 clipped, 
		" ORDER BY 2, 4" 
	END IF 

	PREPARE s_1 FROM fv_s1 

	MESSAGE "Selecting records, please wait..." 

	DECLARE scurs_col 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 

	CALL open_scurs_col() 

	MESSAGE "" 

END FUNCTION 



FUNCTION first_col() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_col INTO mr_col.* 

	IF status = notfound THEN 
		INITIALIZE mr_col.* TO NULL 
		INITIALIZE gr_rptcol.* TO NULL 
		INITIALIZE gr_rptcolgrp.* TO NULL 
		ERROR "No records match the criteria" 
		CALL close_scurs_col() 
	END IF 

	SELECT * 
	INTO gr_rptcolgrp.* 
	FROM rptcolgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = mr_col.col_code 

	IF mr_col.col_id IS NOT NULL THEN 
		SELECT * 
		INTO gr_rptcol.* 
		FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = mr_col.col_code 
		AND col_id = mr_col.col_id 
	ELSE 
		INITIALIZE gr_rptcol TO NULL 
	END IF 

END FUNCTION 



FUNCTION last_col(fv_disp_flag) 

	DEFINE fv_disp_flag SMALLINT 

	MESSAGE "Selecting the last RECORD in queried SET, please wait..." 

	FETCH LAST scurs_col INTO mr_col.* 
	IF status = notfound THEN 
		ERROR "There are no more rows in the direction that you are going" 
		INITIALIZE mr_col.* TO NULL 
		INITIALIZE gr_rptcol.* TO NULL 
		INITIALIZE gr_rptcolgrp.* TO NULL 
	ELSE 
		IF fv_disp_flag = true THEN 
			CALL slct_col() 
			CALL disp_col() 
		END IF 
	END IF 

END FUNCTION 



FUNCTION next_col() 

	MESSAGE "Selecting the next RECORD in queried SET, please wait..." 

	FETCH NEXT scurs_col INTO mr_col.* 
	IF status = notfound THEN 
		ERROR "There are no more rows in the direction that you are going" 
	ELSE 
		CALL slct_col() 
		CALL disp_col() 
	END IF 

END FUNCTION 



FUNCTION prev_col() 

	MESSAGE "Selecting the previous RECORD in queried SET, please wait..." 

	FETCH previous scurs_col INTO mr_col.* 
	IF status = notfound THEN 
		ERROR "There are no more rows in the direction that you are going" 
	ELSE 
		CALL slct_col() 
		CALL disp_col() 
	END IF 

END FUNCTION 



FUNCTION slct_col() 

	SELECT * 
	INTO gr_rptcolgrp.* 
	FROM rptcolgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = mr_col.col_code 

	IF mr_col.col_rowid IS NOT NULL THEN 
		SELECT * 
		INTO gr_rptcol.* 
		FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = mr_col.col_code 
		AND col_id = mr_col.col_id 
	ELSE 
		INITIALIZE gr_rptcol TO NULL 
	END IF 

	MESSAGE "" 

END FUNCTION 


FUNCTION base_first_col() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_col INTO mr_col.* 
	IF status THEN 
		RETURN status 
	ELSE 
		IF mr_col.col_rowid IS NOT NULL THEN 
			SELECT * 
			INTO gr_rptcol.* 
			FROM rptcol 
			WHERE rowid = mr_col.col_rowid 
		ELSE 
			INITIALIZE gr_rptcol TO NULL 
		END IF 

		SELECT * 
		INTO gr_rptcolgrp.* 
		FROM rptcolgrp 
		WHERE rowid = mr_col.rpt_rowid 

		RETURN status 
	END IF 

END FUNCTION 



FUNCTION base_next_col() 


	FETCH NEXT scurs_col INTO mr_col.* 
	IF status THEN 
		RETURN status 
	ELSE 
		IF mr_col.col_rowid IS NOT NULL THEN 
			SELECT * 
			INTO gr_rptcol.* 
			FROM rptcol 
			WHERE rowid = mr_col.col_rowid 
		ELSE 
			INITIALIZE gr_rptcol TO NULL 
		END IF 

		SELECT * 
		INTO gr_rptcolgrp.* 
		FROM rptcolgrp 
		WHERE rowid = mr_col.rpt_rowid 

		RETURN status 
	END IF 

END FUNCTION 



FUNCTION base_abs_col(fv_idx) 

	DEFINE 
	fv_idx SMALLINT 

	FETCH absolute fv_idx scurs_col INTO mr_col.* 
	IF status THEN 
		RETURN status 
	ELSE 
		IF mr_col.col_rowid IS NOT NULL THEN 
			SELECT * 
			INTO gr_rptcol.* 
			FROM rptcol 
			WHERE rowid = mr_col.col_rowid 
		ELSE 
			INITIALIZE gr_rptcol TO NULL 
		END IF 

		SELECT * 
		INTO gr_rptcolgrp.* 
		FROM rptcolgrp 
		WHERE rowid = mr_col.rpt_rowid 

		RETURN status 
	END IF 

END FUNCTION 



FUNCTION close_scurs_col() 

	IF gv_scurs_col_open THEN 
		CLOSE scurs_col 
		LET gv_scurs_col_open = false 
	END IF 

END FUNCTION 



FUNCTION open_scurs_col() 

	IF gv_scurs_col_open THEN 
		CLOSE scurs_col 
	END IF 

	OPEN scurs_col 
	LET gv_scurs_col_open = true 

END FUNCTION 
