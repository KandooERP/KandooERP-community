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

	Source code beautified by beautify.pl on 2020-01-03 09:12:28	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "I51_GLOBALS.4gl" 
# cloned FROM
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I51.4gl - Inter Branch Stock Transfer
#               allows entry of items TO Transfer FROM one warehouse TO
#               another.  A product ledger RECORD IS created FOR both
#               stock movements. Transfer prodledg enties are NOT posted
#
#### Module scope variables
DEFINE 	pr_mode CHAR(10) 
DEFINE	pr_sched_ind CHAR(1)
DEFINE	pr_inparms RECORD LIKE inparms.*
DEFINE pr_ibthead RECORD LIKE ibthead.*
DEFINE pr_ibtdetl RECORD LIKE ibtdetl.*
DEFINE pr_prodledg RECORD LIKE prodledg.* 



####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I5B") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",5002,"") 
		# I5002 Inventory parameters NOT SET up, run IZP
		EXIT program 
	END IF 
	LET pr_sched_ind = "0" 
	LET pr_mode = "ADD" 
	CALL create_table("ibtdetl","t_ibtdetl","","N") 
	OPEN WINDOW i669 with FORM "I669" 
	 CALL windecoration_i("I669") -- albo kd-758 
	INITIALIZE pr_ibthead.* TO NULL 
	WHILE enter_ware() 
		IF line_entry() THEN 
			INITIALIZE pr_ibthead.* TO NULL 
			DELETE FROM t_ibtdetl WHERE 1=1 
		END IF 
	END WHILE 
	CLOSE WINDOW i669 
END MAIN 
