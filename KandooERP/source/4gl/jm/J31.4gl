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

	Source code beautified by beautify.pl on 2020-01-02 19:48:03	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J31, invoice a job
#
# This program calls Four Major Functions
#          - J31_header()    J31a.4gl
#          - jobitems()  J31b.4gl
#          - summup()    J31e.4gl
#          - write_inv() J31f.4gl
#


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J31_GLOBALS.4gl" 

MAIN 
	DEFINE 
	ans CHAR(1), 
	pr_exit SMALLINT 


	#Initial UI Init
	CALL setModuleId("J31") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	LET pr_kandoooption_sn = get_kandoooption_feature_state("JM","SN") 

	SELECT jmparms.* INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J", 7002, "") 
		#7002 " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	SELECT glparms.* INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G", 7006, "") 
		#7006 " Must SET up GL Parameters first in GZP"
		EXIT program 
	END IF 
	SELECT arparms.* INTO pr_arparms.* 
	FROM arparms 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G", 7005, "") 
		#7005 " Must SET up AR Parameters first in AZP"
		EXIT program 
	END IF 
	CALL create_temp1() 
	LET pr_exit = false 
	LET pv_corp_cust = false 
	OPEN WINDOW j169 with FORM "J169" -- alch kd-747 
	CALL winDecoration_j("J169") -- alch kd-747 
	WHILE J31_header() 
		OPEN WINDOW j127c with FORM "J127c" -- alch kd-747 
		CALL winDecoration_j("J127c") -- alch kd-747 
		CALL serial_init(glob_rec_kandoouser.cmpy_code,"V","","") 
		WHILE select_lines() 
			WHILE disp_lineitems() 
				IF summup() THEN 
					CALL write_inv() 
					CASE (glob_password) 
						WHEN "INVJOB" 
							# WHEN invoice IS corrupted ie out of balance
							OPEN WINDOW A140 with FORM "A140" -- alch kd-747 
							CALL winDecoration_a("A140") -- alch kd-747 
							DISPLAY " Unsuccessfull addition of invoice " at 4, 1 
							MENU "Job Invoicing" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","J31","menu-job_invoicing-1") -- alch kd-506 
								ON ACTION "WEB-HELP" -- albo kd-373 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND "Invoice" "Invoice another Job" 
									LET pr_exit = true 
									LET quit_flag = true 
									EXIT MENU 
								COMMAND "Exit" "Exit Job Management Invoicing" 
									LET pr_exit = true 
									LET int_flag = false 
									LET quit_flag = false 
									EXIT MENU 
								COMMAND KEY(control-w) 
									CALL kandoohelp("") 
							END MENU 
							CLOSE WINDOW A140 
						WHEN " " 
							# WHEN invoice IS okay
							OPEN WINDOW A140 with FORM "A140" -- alch kd-747 
							CALL winDecoration_a("A140") -- alch kd-747 
							DISPLAY BY NAME pr_invoicehead.inv_num 
							MENU "Job Invoicing" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","J31","menu-job_invoicing-2") -- alch kd-506 
								ON ACTION "WEB-HELP" -- albo kd-373 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND "Invoice" "Invoice another Job" 
									LET pr_exit = true 
									LET quit_flag = true 
									EXIT MENU 
								COMMAND "Exit" "Exit Job Management Invoicing" 
									LET pr_exit = true 
									LET int_flag = false 
									LET quit_flag = false 
									EXIT MENU 
								COMMAND KEY(control-w) 
									CALL kandoohelp("") 
							END MENU 
							CLOSE WINDOW A140 
						WHEN "BLKINV" 
							# WHEN blank invoice IS created
							OPEN WINDOW A140 with FORM "A140" -- alch kd-747 
							CALL winDecoration_a("A140") -- alch kd-747 
							DISPLAY "Blank Invoice created - Not added TO database " at 4, 1 
							MENU "Job Invoicing" 
								BEFORE MENU 
									CALL publish_toolbar("kandoo","J31","menu-job_invoicing-1") -- alch kd-506 
								ON ACTION "WEB-HELP" -- albo kd-373 
									CALL onlinehelp(getmoduleid(),null) 
								COMMAND "Invoice" "Invoice another Job" 
									LET pr_exit = true 
									LET quit_flag = true 
									EXIT MENU 
								COMMAND "Exit" "Exit Job Management Invoicing" 
									LET pr_exit = true 
									LET int_flag = false 
									LET quit_flag = false 
									EXIT MENU 
								COMMAND KEY(control-w) 
									CALL kandoohelp("") 
							END MENU 
							CLOSE WINDOW A140 
					END CASE 
					EXIT WHILE 
				ELSE 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
			END WHILE 
			CALL setup_invhead() 
			IF pr_exit THEN 
				LET pr_exit = false 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE WINDOW j127c 
		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW j169 
END MAIN 
