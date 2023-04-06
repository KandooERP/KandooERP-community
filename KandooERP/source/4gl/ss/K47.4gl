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

	Source code beautified by beautify.pl on 2019-12-31 14:28:30	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K47  allows the user TO edit  Accounts Receivable credits
#               updating inventory     AND subscription details
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("K47") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CREATE temp TABLE statab (cmpy CHAR(2), 
	ware CHAR(3), 
	part CHAR(15), 
	ship DECIMAL(12,3), 
	which CHAR(3)) WITH no LOG 
	LET func_type = "Edit Credit " 
	LET f_type = "J" 
	LET noerror = 1 
	LET first_time = 1 
	LET display_cred_num = "N" 
	LET ans = "Y" 
	WHILE ans = "Y" 
		DELETE FROM statab WHERE 1=1 
		INITIALIZE pr_credithead.* TO NULL 
		INITIALIZE pr_creditdetl.* TO NULL 
		LET noerror = 1 
		LABEL linesel: 
		CALL cred_select() 
		IF ans = "N" THEN 
			EXIT WHILE 
		END IF 
		IF goon = "N" THEN 
			GOTO linesel 
		END IF 
		# save original credit  FOR back out
		LET ps_credithead.* = pr_credithead.* 
		LET goon = "Y" 
		LABEL headlab: 
		CALL K41_header() 
		IF ans = "N" THEN 
			CALL out_stat() 
			CALL in_stat() 
			GOTO linesel 
		END IF 
		LABEL linelab: 
		IF (ans = "Y" AND goon = "Y") 
		OR (ans = "C" AND goon = "Y") THEN 
			CALL lineitem() 
		END IF 
		# on del key go back a SCREEN
		IF ans = "N" 
		OR ans = "C" 
		THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			GOTO headlab 
		END IF 

		IF ans = "Y" 
		AND goon = "Y" 
		THEN 
			CALL summup() 
		END IF 

		IF ans = "N" 
		THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			LET ans = "C" 
			GOTO linelab 
		END IF 

		IF ans = "Y" 
		AND goon = "Y" 
		THEN 
			CALL write_cred() 
			IF noerror = 1 
			THEN 
				FOR i = 1 TO arr_size 
					INITIALIZE st_creditdetl[i].* TO NULL 
				END FOR 
				LET temp_cred_num = pr_credithead.cred_num 
				LET display_cred_num = "Y" 
			ELSE ROLLBACK WORK 

			OPEN WINDOW w77 at 10,4 
			WITH 2 ROWS, 60 COLUMNS 
			attribute(border, reverse) 
			MESSAGE "Credit NOT changed, files NOT updated, CALL FOR assistance" 
			#      sleep 60
			SLEEP 5 
			CLOSE WINDOW w77 
		END IF 
	END IF 
END WHILE 
END MAIN 


FUNCTION in_stat() 
	DEFINE 
	save_line SMALLINT, 
	which CHAR(3) 

	LET which = TRAN_TYPE_INVOICE_IN 
	LET save_line = 0 
	DECLARE ml1_curs CURSOR FOR 
	SELECT * 
	INTO pr_creditdetl.* 
	FROM creditdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_credithead.cust_code 
	AND cred_num = pr_credithead.cred_num 
	AND line_num > save_line 
	FOREACH ml1_curs 
		LET save_line = pr_creditdetl.line_num 
		LET pr_creditdetl.seq_num = stat_res(glob_rec_kandoouser.cmpy_code, 
		pr_creditdetl.ware_code, 
		pr_creditdetl.part_code, 
		pr_creditdetl.ship_qty, 
		which) 
		OPEN ml1_curs 
	END FOREACH 
END FUNCTION 
