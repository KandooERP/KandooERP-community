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

	Source code beautified by beautify.pl on 2020-01-02 17:31:17	$Id: $
}


# Purpose - BOR Add - Globals & Main

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M14_GLOBALS.4gl" 

MAIN 

	#Initial UI Init
	CALL setModuleId("M14") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	IF pr_mnparms.ref1_text IS NOT NULL THEN 
		LET pr_mnparms.ref1_text = pr_mnparms.ref1_text clipped, 
		"..................." 
	END IF 

	IF pr_mnparms.ref2_text IS NOT NULL THEN 
		LET pr_mnparms.ref2_text = pr_mnparms.ref2_text clipped, 
		"..................." 
	END IF 

	IF pr_mnparms.ref3_text IS NOT NULL THEN 
		LET pr_mnparms.ref3_text = pr_mnparms.ref3_text clipped, 
		"..................." 
	END IF 

	OPEN WINDOW w1_m106 with FORM "M106" 
	CALL  windecoration_m("M106") -- albo kd-762 

	IF num_args() > 0 THEN 
		CALL bor_add(arg_val(1), arg_val(2)) 

		IF pv_cont THEN 
			IF pv_seq_cnt > 0 THEN 
				LET msgresp = kandoomsg("M", 7505, "") 
				# prompt "Bill of Resource added successfully - Any key TO cont"
			ELSE 
				LET msgresp = kandoomsg("M", 7506, "") 
				# prompt "No Bill of Resource was added - Any key TO continue"
			END IF 
		END IF 
	ELSE 
		CALL parent_input() 
	END IF 

	CLOSE WINDOW w1_m106 

END MAIN 
