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

	Source code beautified by beautify.pl on 2020-01-02 17:31:34	$Id: $
}



# Purpose - Recommended Shop Order Inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_prodmfg RECORD LIKE prodmfg.*, 
	pr_product RECORD LIKE product.*, 
	pr_mpsdemand RECORD LIKE mpsdemand.*, 
	pt_mpsdemand RECORD LIKE mpsdemand.*, 
	pt_product RECORD LIKE product.*, 
	pr_company RECORD LIKE company.*, 
	pr_shoporddetl RECORD LIKE shoporddetl.*, 
	pa_mpsdemand array[1000] OF RECORD 
		plan_code LIKE mpsdemand.plan_code, 
		part_code LIKE mpsdemand.part_code, 
		start_date LIKE mpsdemand.start_date, 
		due_date LIKE mpsdemand.due_date, 
		required_qty LIKE mpsdemand.required_qty 
	END RECORD, 
	idx SMALLINT, 
	r, i, 
	scrn, 
	cnt, 
	recorder_count INTEGER, 
	no_of_recorder SMALLINT, 
	err_flag SMALLINT, 
	ok, 
	try_again, 
	fv_part_code LIKE prodmfg.part_code, 
	ans, chgann CHAR(1), 
	fv_type_text CHAR(3), 
	query_text CHAR(500), 
	where_part CHAR(500), 
	err_message CHAR(40) 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M72") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	WHILE true 
		CALL getrecorder() 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		#      CALL showrecorder()
		CLOSE WINDOW wm149 
		CLOSE WINDOW wm148 
	END WHILE 

END MAIN 



FUNCTION getrecorder() 

	OPEN WINDOW wm148 with FORM "M148" 
	CALL  windecoration_m("M148") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE "ESC TO Accept - DEL TO Exit"

	CONSTRUCT where_part ON mpsdemand.part_code, 
	mpsdemand.plan_code, 
	mpsdemand.start_date, 
	mpsdemand.due_date 
	FROM mpsdemand.part_code, 
	mpsdemand.plan_code, 
	mpsdemand.start_date, 
	mpsdemand.due_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	LET query_text = "SELECT * ", 
	"FROM mpsdemand ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND type_text = 'RO' ", 
	"AND ", where_part clipped, " ", 
	"ORDER BY part_code, plan_code, start_date" 

	PREPARE choice FROM query_text 

	OPEN WINDOW wm149 with FORM "M149" 
	CALL  windecoration_m("M149") -- albo kd-762 

	LET msgresp = kandoomsg("M",1509,"") 	# MESSAGE "F3 Fwd, F4 Bwd - DEL TO Exit"

	DECLARE drecorder CURSOR FOR choice 

	LET idx = 0 

	FOREACH drecorder INTO pr_mpsdemand.* 
		LET idx = idx + 1 
		LET pa_mpsdemand[idx].plan_code = pr_mpsdemand.plan_code 
		LET pa_mpsdemand[idx].part_code = pr_mpsdemand.part_code 
		LET pa_mpsdemand[idx].start_date = pr_mpsdemand.start_date 
		LET pa_mpsdemand[idx].due_date = pr_mpsdemand.due_date 
		LET pa_mpsdemand[idx].required_qty = pr_mpsdemand.required_qty 
		IF idx > 1000 THEN 
			LET msgresp = kandoomsg("M", 9500, "") 	# ERROR "Only the first 1000 recommended orders have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		ERROR " No Recommended Orders FOR query " 
	END IF 

	CALL set_count(idx) 

	DISPLAY ARRAY pa_mpsdemand TO sr_recorder.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M72","display-arr-mpsdemand") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

END FUNCTION 
