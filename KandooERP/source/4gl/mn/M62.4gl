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


# Purpose - Forecast Inquiry

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
	pr_shopordhead RECORD LIKE shopordhead.*, 
	pt_shopordhead RECORD LIKE shopordhead.*, 
	pr_company RECORD LIKE company.*, 
	pr_shoporddetl RECORD LIKE shoporddetl.*, 
	pa_shopordhead array[200] OF RECORD 
		start_date LIKE shopordhead.start_date, 
		end_date LIKE shopordhead.end_date, 
		uom_code LIKE shopordhead.uom_code, 
		order_qty LIKE shopordhead.order_qty, 
		forecast_num LIKE shopordhead.shop_order_num 
	END RECORD, 
	idx INTEGER, 
	r INTEGER, 
	i INTEGER, 
	scrn INTEGER, 
	cnt INTEGER, 
	forecast_count INTEGER, 
	no_of_forecast SMALLINT, 
	err_flag SMALLINT, 
	ok LIKE prodmfg.part_code, 
	try_again LIKE prodmfg.part_code, 
	fv_part_code LIKE prodmfg.part_code, 
	fv_part_type LIKE prodmfg.part_type_ind, 
	ans, chgann CHAR(1), 
	err_message CHAR(40) 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M62") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	WHILE true 
		CALL getforecast() 
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		CALL showforecast() 
		CLOSE WINDOW wm131 
	END WHILE 

END MAIN 


FUNCTION getforecast() 

	OPEN WINDOW wm131 with FORM "M131" 
	CALL  windecoration_m("M131") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE "esc TO accept del TO EXIT"

	INPUT BY NAME pt_shopordhead.part_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET fv_part_type = "M" 
					CALL show_mfgprods(glob_rec_kandoouser.cmpy_code,fv_part_type) 
					RETURNING pt_shopordhead.part_code 
					DISPLAY BY NAME pt_shopordhead.part_code 

					NEXT FIELD part_code 
			END CASE 

		AFTER FIELD part_code 
			SELECT desc_text 
			INTO pr_product.desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pt_shopordhead.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9511,"") 
				# ERROR "this product does NOT exist in the database"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO pr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pt_shopordhead.part_code 
			AND mps_ind = "Y" 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9673,"") 
				# ERROR " Product NOT found, OR IS NOT an MPS part"
				NEXT FIELD part_code 
			END IF 

		AFTER INPUT 
			IF int_flag 
			OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			DISPLAY BY NAME pr_prodmfg.part_code, pr_product.desc_text 
	END INPUT 

	IF int_flag 
	OR quit_flag THEN 
		MESSAGE "" 
		RETURN 
	END IF 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION showforecast() 

	LET msgresp = kandoomsg("U",1008,"") 

	DECLARE dforecast CURSOR FOR 
	SELECT shopordhead.* 
	INTO pr_shopordhead.* 
	FROM shopordhead 
	WHERE cmpy_code = cmpy_code 
	AND part_code = pr_prodmfg.part_code 
	AND order_type_ind = "F" 
	ORDER BY start_date 

	LET idx = 0 

	FOREACH dforecast INTO pr_shopordhead.* 
		LET idx = idx + 1 
		LET pa_shopordhead[idx].start_date = pr_shopordhead.start_date 
		LET pa_shopordhead[idx].end_date = pr_shopordhead.end_date 
		LET pa_shopordhead[idx].uom_code = pr_shopordhead.uom_code 
		LET pa_shopordhead[idx].order_qty = pr_shopordhead.order_qty 
		LET pa_shopordhead[idx].forecast_num = pr_shopordhead.shop_order_num 
	END FOREACH 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("M",9675,"") 
		#ERROR " No Forecasts FOR this Product "
	END IF 

	CALL set_count(idx) 

	DISPLAY ARRAY pa_shopordhead TO sr_forecast.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M62","display-arr-shopordhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 
END FUNCTION 
