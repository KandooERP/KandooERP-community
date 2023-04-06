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

	Source code beautified by beautify.pl on 2020-01-03 10:10:04	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

#   FOR handling cursors FOR rptline


DEFINE 
mr_line RECORD 
	rowid INTEGER, 
	line_code LIKE rptline.line_code 
END RECORD 

FUNCTION line_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	CALL close_scurs_line() 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_query_1 = " 1=1" THEN 
		LET fv_s1 = "SELECT rptlinegrp.rowid, rptlinegrp.line_code ", 
		"FROM rptlinegrp ", 
		"WHERE rptlinegrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"ORDER BY 2" 
	ELSE 
		LET fv_s1 = "SELECT rptlinegrp.rowid, rptlinegrp.line_code ", 
		"FROM rptlinegrp ", 
		"WHERE rptlinegrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", gv_query_1 clipped, 
		" ORDER BY 2" 
	END IF 

	PREPARE s_1 FROM fv_s1 
	MESSAGE "Selecting records, please wait..." 
	DECLARE scurs_line 
	SCROLL CURSOR 
	with HOLD 
	FOR s_1 

	CALL open_scurs_line() 

END FUNCTION 



FUNCTION first_line() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_line INTO mr_line.* 
	IF status = notfound THEN 
		INITIALIZE mr_line.* TO NULL 
		INITIALIZE gr_rptline.* TO NULL 
		INITIALIZE gr_rptlinegrp.* TO NULL 
		LET gv_scurs_line_open = false 
		ERROR "No records match the criteria" 
	END IF 

	SELECT * 
	INTO gr_rptlinegrp.* 
	FROM rptlinegrp 
	WHERE rowid = mr_line.rowid 

END FUNCTION 



FUNCTION last_line() 

	MESSAGE "Selecting the last RECORD in queried SET, please wait..." 

	FETCH LAST scurs_line INTO mr_line.* 
	IF status = notfound THEN 
		ERROR "No records match the criteria" 
	END IF 

	SELECT * 
	INTO gr_rptlinegrp.* 
	FROM rptlinegrp 
	WHERE rowid = mr_line.rowid 

END FUNCTION 



FUNCTION next_line() 

	MESSAGE "Selecting the next RECORD in queried SET, please wait..." 

	FETCH NEXT scurs_line INTO mr_line.* 
	IF status = notfound THEN 
		ERROR "Last RECORD selected" 
		RETURN 
	END IF 

	SELECT * 
	INTO gr_rptlinegrp.* 
	FROM rptlinegrp 
	WHERE rowid = mr_line.rowid 

	CALL disp_line() 

END FUNCTION 



FUNCTION prev_line() 

	MESSAGE "Selecting the previous RECORD in queried SET, please wait..." 

	FETCH previous scurs_line INTO mr_line.* 
	IF status = notfound THEN 
		ERROR "First RECORD selected" 
		RETURN 
	END IF 

	SELECT * 
	INTO gr_rptlinegrp.* 
	FROM rptlinegrp 
	WHERE rowid = mr_line.rowid 

	CALL disp_line() 

END FUNCTION 



FUNCTION base_first_line() 

	MESSAGE "Selecting the first RECORD in queried SET, please wait..." 

	FETCH FIRST scurs_line INTO mr_line.* 

	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rptlinegrp.* 
		FROM rptlinegrp 
		WHERE rowid = mr_line.rowid 
		RETURN status 
	END IF 


END FUNCTION 



FUNCTION base_next_line() 


	FETCH NEXT scurs_line INTO mr_line.* 

	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rptlinegrp.* 
		FROM rptlinegrp 
		WHERE rowid = mr_line.rowid 
		RETURN status 
	END IF 


END FUNCTION 



FUNCTION base_abs_line(fv_idx) 

	DEFINE 
	fv_idx SMALLINT 

	FETCH absolute fv_idx scurs_line INTO mr_line.* 

	IF status THEN 
		RETURN status 
	ELSE 
		SELECT * 
		INTO gr_rptlinegrp.* 
		FROM rptlinegrp 
		WHERE rowid = mr_line.rowid 
		RETURN status 
	END IF 

END FUNCTION 



FUNCTION close_scurs_line() 

	IF gv_scurs_line_open THEN 
		CLOSE scurs_line 
		LET gv_scurs_line_open = false 
	END IF 

END FUNCTION 



FUNCTION open_scurs_line() 

	IF gv_scurs_line_open THEN 
		CLOSE scurs_line 
	END IF 

	OPEN scurs_line 
	LET gv_scurs_line_open = true 

END FUNCTION 
