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

	Source code beautified by beautify.pl on 2020-01-02 19:48:07	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM J38a


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J38, list jobs FOR closure /invoicing
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J38_GLOBALS.4gl" 

MAIN 
	DEFINE 
	ans CHAR(1), 
	pr_exit SMALLINT 

	#Initial UI Init
	CALL setModuleId("J38") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up JM Parameters first in JZP"
		LET msgresp = kandoomsg("J",1501," ") 
		SLEEP 5 
		EXIT program 
	END IF 
	SELECT glparms.* 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up GL Parameters first in GZP"
		LET msgresp = kandoomsg("G",5007," ") 
		SLEEP 5 
		EXIT program 
	END IF 
	SELECT arparms.* 
	INTO pr_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		#ERROR " Must SET up AR Parameters first in AZP"
		LET msgresp = kandoomsg("A",9002," ") 
		SLEEP 5 
		EXIT program 
	END IF 
	LET pr_validate_ind = get_kandoooption_feature_state("JM","03") 
	CALL create_temp1() 
	LET pr_exit = false 

	LET pv_corp_cust = false 
	OPEN WINDOW j169 with FORM "J169" -- alch kd-747 
	CALL winDecoration_j("J169") -- alch kd-747 
	WHILE show_jobs() 
		IF pr_job.internal_flag = "Y" THEN 
			CONTINUE WHILE 
		END IF 
		WHILE J31_header() 
			OPEN WINDOW j127c with FORM "J127c" -- alch kd-747 
			CALL winDecoration_j("J127c") -- alch kd-747 
			WHILE select_lines() 
				WHILE disp_lineitems() 
					IF summup() THEN 
						CALL write_inv() 
						CALL run_prog("J33",glob_rec_kandoouser.cmpy_code,"R",pr_invoicehead.inv_num, pr_invoicehead.inv_num) 
						CASE (glob_password) 
							WHEN "INVJOB" 
								# WHEN invoice IS corrupted ie out of balance
								#                       OPEN WINDOW jform AT 10,10 with 2 rows, 60 columns
								#                          ATTRIBUTE(border)     -- alch KD-747
								#DISPLAY "  Unsuccessfull addition of invoice     " AT 4,1
								LET msgresp = kandoomsg("J",1523," ") 
								MENU "Job Invoicing" 
									BEFORE MENU 
										CALL publish_toolbar("kandoo","J38","menu-job_invoicing-5") -- alch kd-506 
									ON ACTION "WEB-HELP" -- albo kd-373 
										CALL onlinehelp(getmoduleid(),null) 
									COMMAND "RETURN" " RETURN TO Job selection Screen" 
										#RETURN ,  RETURN TO Job Selection SCREEN
										EXIT MENU 
									COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Main Menu" 
										LET pr_exit = true 
										EXIT MENU 
									COMMAND KEY (control-w) 
										CALL kandoohelp("") 
								END MENU 
								#								CLOSE WINDOW jform     -- alch KD-747
							WHEN " " 
								# WHEN invoice IS okay
								#								OPEN WINDOW jform AT 10,10 with 2 rows, 60 columns
								#									ATTRIBUTE(border)     -- alch KD-747
								LET msgresp = kandoomsg("J",1531, pr_invoicehead.inv_num) 
								#    DISPLAY BY NAME pr_invoicehead.inv_num
								MENU "Job Invoicing" 
									BEFORE MENU 
										CALL publish_toolbar("kandoo","J38","menu-job_invoicing-6") -- alch kd-506 
									ON ACTION "WEB-HELP" -- albo kd-373 
										CALL onlinehelp(getmoduleid(),null) 
									COMMAND "RETURN" " RETURN TO Job selection Screen" 
										#RETURN ,  RETURN TO Job Selection SCREEN
										EXIT MENU 
									COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Main Menu" 
										LET pr_exit = true 
										EXIT MENU 
									COMMAND KEY (control-w) 
										CALL kandoohelp("") 
								END MENU 
								#								CLOSE WINDOW jform     -- alch KD-747
							WHEN "BLKINV" 
								# WHEN blank invoice IS created
								#								OPEN WINDOW jform AT 10,10 with 2 rows, 60 columns
								#									ATTRIBUTE(border)     -- alch KD-747
								#DISPLAY "Blank Invoice created - Not added TO database  " AT 4,1
								LET msgresp = kandoomsg("J",1524," ") 
								MENU "Job Invoicing" 
									BEFORE MENU 
										CALL publish_toolbar("kandoo","J38","menu-job_invoicing-7") -- alch kd-506 
									ON ACTION "WEB-HELP" -- albo kd-373 
										CALL onlinehelp(getmoduleid(),null) 
									COMMAND "RETURN" " RETURN TO Job selection Screen" 
										#RETURN ,  RETURN TO Job Selection SCREEN
										EXIT MENU 
									COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Main Menu" 
										LET pr_exit = true 
										EXIT MENU 
									COMMAND KEY (control-w) 
										CALL kandoohelp("") 
								END MENU 
								#                       CLOSE WINDOW jform     -- alch KD-747

						END CASE 
						EXIT WHILE 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
					END IF 
				END WHILE 
				CALL setup_invhead() 

				EXIT WHILE 
			END WHILE 
			CLOSE WINDOW j127c 
			EXIT WHILE 
		END WHILE 
		IF pr_exit THEN 
			EXIT WHILE 
		END IF 
	END WHILE #show_job 
	CLOSE WINDOW j169 
END MAIN 
