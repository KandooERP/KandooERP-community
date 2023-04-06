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

	Source code beautified by beautify.pl on 2020-01-02 17:31:25	$Id: $
}


# Purpose - Shop Order Maintenance - Globals & Main

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	err_continue CHAR(1), 
	err_message CHAR(50), 
	pv_text CHAR(16), 
	pv_cnt SMALLINT, 
	pv_cnt1 SMALLINT, 
	pv_config SMALLINT, 
	pv_end SMALLINT, 
	pv_arr_size SMALLINT, 
	pv_phant_cnt SMALLINT, 
	pv_orig_arr_size SMALLINT, 
	pv_temp_cnt SMALLINT, 
	pv_start SMALLINT, 
	pv_scost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_wcost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_lcost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_price_tot LIKE shopordhead.std_price_amt, 
	pv_ext_cost_amt LIKE shopordhead.std_est_cost_amt, 

	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_shopordhead RECORD LIKE shopordhead.*, 
	pr_shoporddetl RECORD LIKE shoporddetl.*, 

	pa_config array[500] OF RECORD 
		part_code LIKE bor.part_code, 
		required_qty LIKE bor.required_qty 
	END RECORD, 

	pa_parent array[500] OF RECORD 
		part_code LIKE bor.part_code, 
		required_qty LIKE bor.required_qty 
	END RECORD, 

	pa_shoporddetl array[2000] OF RECORD LIKE shoporddetl.*, 
	pa_sodetl_final array[2000] OF RECORD LIKE shoporddetl.*, 

	pa_scrn_sodetl array[2000] OF RECORD 
		type_ind LIKE shoporddetl.type_ind, 
		component_type_ind CHAR(1), 
		part_code LIKE shoporddetl.part_code, 
		desc_text LIKE product.desc_text, 
		required_qty LIKE shoporddetl.required_qty, 
		unit_cost_amt LIKE shoporddetl.std_est_cost_amt, 
		sequence_num LIKE shoporddetl.sequence_num 
	END RECORD, 

	pa_wip_seq array[1000] OF RECORD 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		sequence_num LIKE shoporddetl.sequence_num, 
		exist_flag CHAR(1), 
		temp_seq_num SMALLINT 
	END RECORD 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M34") -- albo 
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
		# prompt "Manufacturing parameters are NOT SET up - Press any key"
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Press any key"
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

	IF pr_mnparms.ref4_text IS NOT NULL THEN 
		LET pr_mnparms.ref4_text = pr_mnparms.ref4_text clipped, 
		"..................." 
	END IF 

	CALL query_orders() 

END MAIN 
