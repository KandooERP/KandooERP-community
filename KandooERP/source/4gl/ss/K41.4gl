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

	Source code beautified by beautify.pl on 2019-12-31 14:28:29	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K41  allows the user TO enter subscription credits AND creates
# Accounts Receivable Credits
# updating inventory
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 

MAIN 
	DEFINE msgresp LIKE language.yes_flag 
	#
	# need TO defer interrupt AND quit because of UPDATE situation
	# of ps_prodstatus in K41b.4gl
	#


	#Initial UI Init
	CALL setModuleId("K41") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET cred_type = arg_val(1) 

	LET func_type = "Credit entry" 
	LET f_type = "C" 
	LET first_time = 1 
	LET noerror = 1 
	LET display_cred_num = "N" 
	WHENEVER ERROR CONTINUE 
	DROP TABLE statab 
	WHENEVER ERROR stop 

	CREATE temp TABLE statab (cmpy CHAR(2), 
	ware CHAR(3), 
	part CHAR(15), 
	ship DECIMAL(12,3), 
	which CHAR(3)) WITH no LOG 
	LET ans = "Y" 
	WHILE ans = "Y" 
		DELETE FROM statab WHERE 1=1 

		# INITIALIZE pr records

		LET arr_size = 0 
		INITIALIZE pr_credithead.* TO NULL 
		LET pr_credithead.goods_amt = 0 
		LET pr_credithead.total_amt = 0 
		LET pr_credithead.hand_amt = 0 
		LET pr_credithead.freight_amt = 0 
		LET pr_credithead.tax_amt = 0 
		LET pr_credithead.cost_amt = 0 
		LET pr_credithead.tax_per = 0 
		INITIALIZE pr_creditdetl.* TO NULL 
		LET noerror = 1 
		LET goon = "Y" 
		LABEL headlab: 
		CALL K41_header() 
		IF ans = "N" THEN 
			# delete OR quit has been hit - need TO back out ps_prodstatus updates
			#CALL out_stat()
			EXIT WHILE 
		END IF 
		LABEL linelab: 
		IF (ans = "Y" AND goon = "Y") 
		OR (ans = "C" AND goon = "Y") THEN 
			CALL lineitem() 
		END IF 
		# on del key go back a SCREEN
		IF ans = "N" OR ans = "C" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			IF ans = "N" THEN 
				LET arr_size = 0 
				#INITIALIZE pr_credithead.* TO NULL
				LET pr_warehouse.ware_code = NULL 
				LET pr_credithead.ref_num = NULL 
				LET pr_credithead.goods_amt = 0 
				LET pr_credithead.total_amt = 0 
				LET pr_credithead.hand_amt = 0 
				LET pr_credithead.freight_amt = 0 
				LET pr_credithead.tax_amt = 0 
				LET pr_credithead.cost_amt = 0 
				LET pr_credithead.tax_per = 0 
				INITIALIZE pr_creditdetl.* TO NULL 
				#CALL out_stat()
				FOR idx = 1 TO arr_size 
					INITIALIZE st_creditdetl[idx].* TO NULL 
					INITIALIZE px_creditdetl[idx].* TO NULL 
				END FOR 
				LET ans = "Y" 
			END IF 
			GOTO headlab 
		END IF 
		IF ans = "Y" AND goon = "Y" THEN 
			CALL summup() 
		END IF 
		IF ans = "N" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			LET ans = "C" 
			GOTO linelab 
		END IF 
		IF ans = "Y" AND goon = "Y" THEN 
			CALL write_cred() 
			IF noerror = 1 THEN 
				FOR i=1 TO arr_size 
					INITIALIZE st_creditdetl[i].* TO NULL 
					INITIALIZE px_creditdetl[i].* TO NULL 
				END FOR 
				IF imaging_used THEN 
					CALL direct_appl(glob_rec_kandoouser.cmpy_code, pr_credithead.*) 
				ELSE 
				CALL cred_appl(pr_credithead.cred_num, glob_rec_kandoouser.sign_on_code) 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
			LET temp_cred_num = pr_credithead.cred_num 
			LET display_cred_num = "Y" 
			LET first_time = 1 
		ELSE 
		ROLLBACK WORK 
		LET msgresp = kandoomsg("K",5004,"") 
		#9120 Credit NOT added AND files have NOT been updated.
	END IF 
END IF 
END WHILE 
END MAIN 
