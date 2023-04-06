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

	Source code beautified by beautify.pl on 2020-01-03 10:10:05	$Id: $
}




#      FOR handling cursors FOR def_rpt

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW5_GLOBALS.4gl" 

DEFINE 
mr_def RECORD 
	rowid INTEGER, 
	rpt_id LIKE rpthead.rpt_id END RECORD 

FUNCTION header_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_query_1 = " 1=1" THEN 
		LET gv_query_1 = NULL 
	ELSE 
		LET gv_query_1 = "AND ", gv_query_1 clipped 
	END IF 

	LET fv_s1 = "SELECT * ", 
	"FROM rpthead ", 
	"WHERE rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	gv_query_1 clipped, 
	" ORDER BY 2" 

	PREPARE s_1 FROM fv_s1 

	# now DECLARE a CURSOR FOR the relevant info in the cheque table
	MESSAGE "Selecting records, please wait..." 

	DECLARE scurs1_def CURSOR 
	with HOLD 
	FOR s_1 

	LET gv_test = "Y" 

	--prompt "Do you wish TO PRINT COLUMN AND line details with this REPORT? (Y/N) "  -- albo
	--    FOR gv_colline
	LET gv_colline = promptYN(""," Are you sure you wish TO cancel (y/n)? ","Y") -- albo 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	IF gv_colline = "Y" OR gv_colline = "y" THEN 
		LET gv_test = "N" 
		CALL def_line_range() 
	END IF 

	OPEN scurs1_def 
	FOREACH scurs1_def INTO gr_rpthead.* 
		LET gv_scurs_def_open = true 
		CALL def_rpthdr() 
	END FOREACH 
	CLOSE scurs1_def 
	LET gv_colline = "N" 

END FUNCTION 


FUNCTION column_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_colline = "N" THEN 
		IF gv_query_1 = " 1=1" THEN 
			LET gv_query_1 = NULL 
		ELSE 
			LET gv_query_1 = "AND ", gv_query_1 clipped 
		END IF 

		#SET up the SELECT statement
		LET fv_s1 = "SELECT * ", 
		"FROM rptcolgrp ", 
		"WHERE rptcolgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		gv_query_1 clipped, 
		" ORDER BY 2" 
	ELSE 
		LET fv_s1 = "SELECT * ", 
		"FROM rptcolgrp ", 
		"WHERE rptcolgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptcolgrp.col_code = '", gr_rpthead.col_code, "' ", 
		" ORDER BY 2" 
	END IF 

	PREPARE s_2 FROM fv_s1 

	MESSAGE "Selecting records, please wait..." 

	DECLARE scurs2_def CURSOR 
	with HOLD 
	FOR s_2 

	FOREACH scurs2_def INTO gr_rptcolgrp.* 
		LET gv_scurs_def_open = true 
		CALL def_rptcolgrp() 
	END FOREACH 

END FUNCTION 


FUNCTION line_curs() 

	DEFINE 
	fv_s1 CHAR(1500) 

	-- having 1 = 1 in the query causes the optimizer TO make incorrect decisions.
	-- This will help performance WHERE no condition IS selected on the first
	-- SCREEN.

	IF gv_colline = "N" THEN 
		IF gv_query_1 = " 1=1" THEN 
			LET gv_query_1 = NULL 
		ELSE 
			LET gv_query_1 = "AND ", gv_query_1 clipped 
		END IF 

		LET gv_test = "Y" 
		LET fv_s1 = "SELECT * ", 
		"FROM rptlinegrp ", 
		"WHERE rptlinegrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		gv_query_1 clipped, 
		" ORDER BY 2" 
	ELSE 
		LET fv_s1 = "SELECT * ", 
		"FROM rptlinegrp ", 
		"WHERE rptlinegrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND rptlinegrp.line_code = '", gr_rpthead.line_code, "' ", 
		" ORDER BY 2" 
	END IF 

	PREPARE s_3 FROM fv_s1 

	MESSAGE "Selecting records, please wait..." 

	DECLARE scurs3_def CURSOR 
	with HOLD 
	FOR s_3 

	IF gv_test <> "N" THEN 
		CALL def_line_range() 
	END IF 
	FOREACH scurs3_def INTO gr_rptlinegrp.* 
		LET gv_scurs_def_open = true 
		CALL def_rptlinegrp() 
	END FOREACH 

END FUNCTION 
