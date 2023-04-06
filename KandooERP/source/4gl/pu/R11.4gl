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

	Source code beautified by beautify.pl on 2020-01-02 17:06:13	Source code beautified by beautify.pl on 2020-01-02 17:03:23	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R11 - Purchase Order Entry
#        allows the user TO enter Purchase Orders updating inventory
#
#        Allows entry of G-General lines
#                        J-Job Management Lines Only IF JM installed
#                        I-Inventory Lines Only IF IN installed AND
#                             a valid warehouse IS entered

GLOBALS 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	jm_install, in_install SMALLINT, 
	winds_text CHAR(20), 
	line_text CHAR(70) 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R11") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r100 with FORM "R100" 
	CALL  windecoration_r("R100") 

	SELECT * INTO pr_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("U",5107,"") 
		#5107 General Ledger Parameters Not Set Up;  Refer Menu GZP.
		EXIT program 
	END IF 
	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("U",5118,"") 
		#5118 Purchasing Parameters Not Set Up;  Refer Menu RZP.
		EXIT program 
	END IF 
	LET line_text =" Valid Line Types - (G)General" 
	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET in_install = false 
	ELSE 
		LET in_install = true 
		LET line_text = line_text clipped," - (I)Inventory" 
	END IF 
	SELECT * INTO pr_jmparms.* FROM jmparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound 
	OR pr_jmparms.jm_flag != "Y" THEN 
		LET jm_install = false 
	ELSE 
		LET jm_install = true 
		LET line_text = line_text clipped," - (J)Job Management" 
	END IF 
	CALL create_table("purchdetl","t_purchdetl","","Y") 
	CALL create_table("poaudit","t_poaudit","","Y") 
	INITIALIZE pr_purchhead.* TO NULL 
	WHILE edit_header("ADD",glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
		IF po_mod(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"","ADD") THEN 
			CLEAR FORM 
			INITIALIZE pr_purchhead.* TO NULL 
			INITIALIZE pr_vendor.* TO NULL 
			DELETE FROM t_purchdetl WHERE 1=1 
			DELETE FROM t_poaudit WHERE 1=1 
		END IF 
	END WHILE 
	CLOSE WINDOW r100 
END MAIN 
