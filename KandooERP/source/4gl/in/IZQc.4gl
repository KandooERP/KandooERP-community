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

	Source code beautified by beautify.pl on 2020-01-03 09:12:50	$Id: $
}



#Provide external payments interface TO Westpac.
#Product Bin Text Update

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../in/I_IN_GLOBALS.4gl" 
GLOBALS "../in/ISR_GLOBALS.4gl" 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZQ") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CREATE temp TABLE t_rates( part_code CHAR(15), 
	bin1_text CHAR(15), 
	bin2_text CHAR(15), 
	bin3_text CHAR(15), 
	ware_code CHAR(3)) 
	with no LOG 
	LET pr_window_name = "Product Bin Update" 
	--LET pr_menu_path = "IZQ" 
	--LET pr_report_name = "Product Bin Update Error Report" 
	CALL menu_details() 
END MAIN 


FUNCTION validate_file() 
	DEFINE l_rpt_idx SMALLINT    
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_part_code CHAR(15), 
	pr_prodstat RECORD 
		part_code CHAR(15), 
		bin1_text CHAR(15), 
		bin2_text CHAR(15), 
		bin3_text CHAR(15), 
		ware_code CHAR(3) 
	END RECORD, 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	idx SMALLINT, 
	err_text,query_text CHAR(100) 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"IZQc_rpt_list_err",query_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT IZQc_rpt_list_err TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET idx = 0 
	LET pr_inserted_rows = 0 
	LET pr_err_cnt = 0 
	LET query_text = "SELECT * FROM t_rates" 
	PREPARE s_prodstat FROM query_text 
	DECLARE c_prodstat CURSOR with HOLD FOR s_prodstat 
	FOREACH c_prodstat INTO pr_prodstat.* 
		LET idx = idx + 1 
		SELECT unique 1 FROM product 
		WHERE part_code = pr_prodstat.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Product ",pr_prodstat.part_code, 
			" does NOT exist " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM warehouse 
		WHERE ware_code = pr_prodstat.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = "Warehouse ",pr_prodstat.ware_code, 
			" does NOT exist " 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_text = "Error Updating product ",pr_prodstat.part_code 
			LET pr_part_code = pr_prodstat.part_code clipped, "*" 
			UPDATE prodstatus SET bin1_text = pr_prodstat.bin1_text, 
			bin2_text = pr_prodstat.bin2_text, 
			bin3_text = pr_prodstat.bin3_text 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_prodstat.ware_code 
			AND part_code matches pr_part_code 
			LET pr_inserted_rows = pr_inserted_rows + 1 
		COMMIT WORK 
		CONTINUE FOREACH 
		LABEL recovery: 
		WHENEVER ERROR stop 
		LET pr_quaderr.error_text = "Error Updating product ", 
		pr_prodstat.part_code 
		LET pr_quaderr.line_num = idx 
		INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
		INITIALIZE pr_quaderr.* TO NULL 
		ROLLBACK WORK 
	END FOREACH 
END FUNCTION 
