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
#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM J33a.4gl
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../jm/J_JM_GLOBALS.4gl"
GLOBALS "../jm/J3_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J33_GLOBALS.4gl"
###########################################################################
# MAIN
#
# J33 selects which TO PRINT before calling FUNCTION in_cr_print
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("J33") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO glob_rec_arparms.* 
	FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
{
	SELECT kandoouser.* 
	INTO pr_rec_kandoouser.* 
	FROM kandoouser 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sign_on_code = glob_rec_kandoouser.sign_on_code 

	SELECT company.* 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		#   ERROR " Company NOT found - Cannot continue"
		LET msgresp = kandoomsg("U",9502,"") 
		SLEEP 5 
		EXIT program 
	END IF 
}
	IF num_args() > 0 THEN 
		CALL auto_run() 
	ELSE 
		WHILE get_prnt_optns() 
		END WHILE 
	END IF 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION auto_run() 
#
# FUNCTION TO Automatically PRINT invoices
###########################################################################
FUNCTION auto_run() 
	DEFINE l_rec_print_options RECORD 
		cmpy_print char, 
		docm_print char, 
		glob_prt_message char, 
		start_inv, 
		end_inv INTEGER 
	END RECORD 

	LET l_rec_print_options.cmpy_print = arg_val(1) 
	LET l_rec_print_options.docm_print = arg_val(2) 
	LET l_rec_print_options.start_inv = arg_val(3) 
	LET l_rec_print_options.end_inv = arg_val(4) 
	LET l_rec_print_options.glob_prt_message = arg_val(5) 
	CALL jm_inv_print(l_rec_print_options.*) 
	--RETURNING pr_output 
END FUNCTION #auto_run 
###########################################################################
# END FUNCTION auto_run() 
###########################################################################


###########################################################################
# FUNCTION get_prnt_optns()
#
# 
###########################################################################
FUNCTION get_prnt_optns() 
	DEFINE l_rec_prnt_optns RECORD 
		cmpy_prnt CHAR(1), 
		docm_prnt CHAR(1), 
		glob_prt_message CHAR(1), 
		start_inv INTEGER, 
		end_inv INTEGER 
	END RECORD 
	DEFINE l_ans CHAR(1)
	 
	CLEAR screen 

	OPEN WINDOW J161 with FORM "J161" -- alch kd-747 
	CALL winDecoration_j("J161") -- alch kd-747 

	LET l_rec_prnt_optns.cmpy_prnt = "Y" 
	LET l_rec_prnt_optns.docm_prnt = "N" 
	LET l_rec_prnt_optns.glob_prt_message = "N" 

	INPUT BY NAME l_rec_prnt_optns.cmpy_prnt, 
	l_rec_prnt_optns.docm_prnt, 
	l_rec_prnt_optns.glob_prt_message 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J33","input-l_rec_prnt_optns-1") -- alch kd-506 

		AFTER FIELD cmpy_prnt 
			CASE l_rec_prnt_optns.cmpy_prnt 
				WHEN "Y" 
					EXIT CASE 
				WHEN "N" 
					EXIT CASE 
				OTHERWISE 
					ERROR 
					" (Y)-Print Company Details (N)-Company Details Blank" 
					NEXT FIELD cmpy_prnt 
			END CASE 

		AFTER FIELD docm_prnt 
			CASE l_rec_prnt_optns.docm_prnt 
				WHEN "N" 
					# Don't want Invoice range window displayed
					# Invopice range SET manually below
					#  CALL inv_range()
					#     returning l_rec_prnt_optns.start_inv,
					#               l_rec_prnt_optns.end_inv
					LET l_rec_prnt_optns.start_inv = 0 
					LET l_rec_prnt_optns.end_inv = 99999999 
					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD docm_prnt 
						NEXT FIELD glob_prt_message 
					END IF 

				WHEN "R" 
					CALL inv_range() 
					RETURNING l_rec_prnt_optns.start_inv, 
					l_rec_prnt_optns.end_inv 
					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD docm_prnt 
					END IF 

				WHEN l_rec_prnt_optns.docm_prnt IS NULL 
					LET l_rec_prnt_optns.docm_prnt = "N" 
					NEXT FIELD docm_prnt 

				OTHERWISE 
					ERROR 
					" Response must be (N)-Never Printed (R)-Print Range" 
			END CASE 
			NEXT FIELD glob_prt_message 

		AFTER FIELD glob_prt_message 
			CASE 
				WHEN "N" OR "Y" 
					EXIT CASE 

				WHEN l_rec_prnt_optns.glob_prt_message IS NULL 
					LET l_rec_prnt_optns.glob_prt_message = "Y" 
					NEXT FIELD glob_prt_message 

				OTHERWISE 
					ERROR " Response must be (Y)es OR (N)o" 
					NEXT FIELD glob_prt_message 
			END CASE 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE 
		{   -- albo
		      OPEN WINDOW invprnt AT 16,24 with 1 rows,28 columns
		         ATTRIBUTE(border, reverse)
		      prompt " Any Key TO Start Printing" FOR CHAR l_ans
		      CLOSE WINDOW invprnt
		}
		CALL eventsuspend()  --LET l_ans = AnyKey(" Any Key TO Start Printing",15,22) -- albo 
		CLEAR WINDOW J161 
		MESSAGE "Searching Database Please Stand By" 

		CALL jm_inv_print(l_rec_prnt_optns.*) 
		--RETURNING pr_output 
--		CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
		CLOSE WINDOW J161 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION get_prnt_optns()
#
# 
###########################################################################


###########################################################################
# FUNCTION inv_range()
#
# 
###########################################################################
FUNCTION inv_range() 
	DEFINE l_start_inv INTEGER 
	DEFINE l_end_inv INTEGER
	 
	OPEN WINDOW J162 with FORM "J162" -- alch kd-747 
	CALL winDecoration_j("J162") -- alch kd-747
 
	LET l_start_inv = 0 
	LET l_end_inv = 99999999 
	
	INPUT 
	l_start_inv, 
	l_end_inv WITHOUT DEFAULTS 
	FROM
	start_inv,
	end_inv ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J33","input-inv-1") -- alch kd-506 

		AFTER FIELD start_inv 
			IF l_start_inv IS NULL THEN 
				LET l_start_inv = 0 
			END IF 

		AFTER FIELD end_inv 
			IF l_end_inv IS NULL THEN 
				LET l_end_inv = 99999999 
			END IF 
			IF l_end_inv < l_start_inv THEN 
				ERROR "END Doc. Number must NOT be less than Start Doc. Number" 
				NEXT FIELD end_inv 
			END IF 

		AFTER INPUT 
			IF l_start_inv IS NULL THEN 
				LET l_start_inv = 0 
			END IF 
			IF l_end_inv IS NULL THEN 
				LET l_end_inv = 99999999 
			END IF 

	END INPUT 

	CLOSE WINDOW J162 
	RETURN l_start_inv, l_end_inv 
END FUNCTION 
###########################################################################
# END FUNCTION inv_range()
#
# 
###########################################################################