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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################ 
DEFINE modu_packages_num DECIMAL(4,0) 
DEFINE modu_kit_components CHAR(1) 
DEFINE modu_prt_value CHAR(1) 
DEFINE modu_comments1 CHAR(60) 
DEFINE modu_comments2 CHAR(60) 
DEFINE modu_comments3 CHAR(60) 
DEFINE modu_comments4 CHAR(60) 
DEFINE modu_mast_warecode LIKE inparms.mast_ware_code 

############################################################
# FUNCTION ISM_main()
#
# Purpose - Dispatch Label Report
############################################################
FUNCTION ISM_main()

	CALL setModuleId("ISM") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT inparms.mast_ware_code INTO modu_mast_warecode 
	FROM inparms 
	WHERE inparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inparms.parm_code = "1" 
	IF STATUS = NOTFOUND THEN 
		CALL msgerror("","Inventory Parameters are not set up.\n                Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",5002,"") 
		#5002 In Parameters NOT SET up refer TO menu IZP
		EXIT program 
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I664 WITH FORM "I664" 
			 CALL windecoration_i("I664")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Dispatch Labels" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ISM","menu-Dispatch_Labels-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ISM_rpt_process(ISM_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ISM_rpt_process(ISM_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I664

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ISM_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I664 with FORM "I664" 
			 CALL windecoration_i("I664") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ISM_rpt_query()) #save where clause in env 
			CLOSE WINDOW I664 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ISM_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION ISM_main()
############################################################

############################################################
# FUNCTION ISM_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ISM_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	LET modu_kit_components = "Y" 
	LET modu_prt_value  ="Y"

	CLEAR FORM 
	DIALOG ATTRIBUTES(UNBUFFERED)

		CONSTRUCT BY NAME r_where_text ON 
		ibthead.trans_num, 
		ibthead.desc_text, 
		ibthead.from_ware_code, 
		ibthead.to_ware_code, 
		ibthead.trans_date, 
		ibthead.year_num, 
		ibthead.period_num, 
		ibthead.sched_ind, 
		ibthead.status_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ISM","construct-ibthead-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
		END CONSTRUCT 

		INPUT 
		modu_packages_num, 
		modu_kit_components, 
		modu_prt_value, 
		modu_comments1, 
		modu_comments2, 
		modu_comments3, 
		modu_comments4 WITHOUT DEFAULTS 
		FROM
		packages_num, 
		kit_components, 
		prt_value, 
		comments1, 
		comments2, 
		comments3, 
		comments4		
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ISM","input-packages_num-1") -- albo kd-505 
				MESSAGE " Enter criteria FOR selection - ESC TO begin search"
		END INPUT 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

		AFTER DIALOG
			IF modu_packages_num IS NULL
				THEN ERROR "The field requires a value entry."
				NEXT FIELD packages_num
			END IF

	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF
 
END FUNCTION 
############################################################
# END FUNCTION ISM_rpt_query() 
############################################################

############################################################
# FUNCTION ISM_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ISM_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_ibthead RECORD LIKE ibthead.* 
	DEFINE l_rec_ibtdetl RECORD LIKE ibtdetl.* 
	DEFINE l_uom_code LIKE product.sell_uom_code 
	DEFINE l_package SMALLINT 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ISM_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT ISM_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT ibthead.*,ibtdetl.*,sell_uom_code ", 
	"FROM ibthead,ibtdetl,product ", 
	"WHERE ",p_where_text CLIPPED," ", 
	"AND ibthead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ibtdetl.trans_num = ibthead.trans_num ", 
	"AND ibtdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ibtdetl.part_code = product.part_code ", 
	"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"ORDER BY ibthead.trans_num,ibtdetl.part_code,ibtdetl.line_num" 

	PREPARE s_transfer FROM l_query_text 
	DECLARE c_transfer CURSOR FOR s_transfer 

	FOR l_package = 1 TO modu_packages_num 
		FOREACH c_transfer INTO l_rec_ibthead.*,l_rec_ibtdetl.*,l_uom_code 
			#---------------------------------------------------------
			OUTPUT TO REPORT ISM_rpt_list(
			l_rpt_idx,
			l_rec_ibthead.*, 
			l_rec_ibtdetl.*, 
			l_uom_code, 
			l_package, 
			modu_packages_num, 
			modu_kit_components, 
			modu_prt_value, 
			modu_mast_warecode) 
			IF NOT rpt_int_flag_handler2("Transfer: ",l_rec_ibthead.trans_num,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF
			#---------------------------------------------------------
		END FOREACH 
	END FOR 

	#------------------------------------------------------------
	FINISH REPORT ISM_rpt_list
	RETURN rpt_finish("ISM_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ISM_rpt_process() 
############################################################

############################################################
# REPORT ISM_rpt_list(p_rpt_idx,p_rec_ibthead,p_rec_ibtdetl,p_uom_code,p_package,p_packages_num,p_kit_components,p_prt_value,p_master_warecode)
#
# Report Definition/Layout
############################################################
REPORT ISM_rpt_list(p_rpt_idx,p_rec_ibthead,p_rec_ibtdetl,p_uom_code,p_package,p_packages_num,p_kit_components,p_prt_value,p_master_warecode) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_ibthead RECORD LIKE ibthead.*
	DEFINE p_rec_ibtdetl RECORD LIKE ibtdetl.*
	DEFINE p_uom_code LIKE product.sell_uom_code 
	DEFINE p_package DECIMAL(4,0)
	DEFINE p_packages_num DECIMAL(4,0)
	DEFINE p_kit_components CHAR(1)
	DEFINE p_prt_value CHAR(1)
	DEFINE p_master_warecode LIKE warehouse.ware_code
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_kitdetl RECORD LIKE kitdetl.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_waregrp_desc LIKE waregrp.name_text 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_product_desc CHAR(53) 
	DEFINE l_count SMALLINT 
	DEFINE l_ware_code_use LIKE warehouse.ware_code 

	ORDER EXTERNAL BY p_package,p_rec_ibthead.trans_num,p_rec_ibtdetl.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

			PRINT COLUMN 30, "DISPATCH LABEL" 
			SELECT * INTO l_rec_warehouse.* FROM warehouse 
			WHERE warehouse.ware_code = p_rec_ibthead.to_ware_code 
			AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT name_text INTO l_waregrp_desc FROM waregrp 
			WHERE waregrp.waregrp_code = l_rec_warehouse.waregrp_code 
			AND waregrp.cmpy_code = glob_rec_kandoouser.cmpy_code 

			PRINT COLUMN 01,"Destination. " 
			PRINT COLUMN 01, l_rec_warehouse.waregrp_code, 
			COLUMN 15, l_waregrp_desc CLIPPED 
			PRINT COLUMN 01, p_rec_ibthead.to_ware_code, 
			COLUMN 15, l_rec_warehouse.desc_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.addr1_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.addr2_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.city_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.contact_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.tele_text CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.mobile_phone CLIPPED 
			PRINT COLUMN 15, l_rec_warehouse.email CLIPPED 
			SKIP 2 LINES 
			PRINT COLUMN 01,"Number of Packages", 
			4 SPACES, p_package, 
			4 SPACES, "of", 
			4 SPACES, p_packages_num 
			SKIP 2 LINES 
			PRINT COLUMN 01,"Comments" 
			PRINT COLUMN 15,modu_comments1 CLIPPED 
			PRINT COLUMN 15,modu_comments2 CLIPPED 
			PRINT COLUMN 15,modu_comments3 CLIPPED 
			SKIP 2 LINES 
			PRINT COLUMN 15,modu_comments4 CLIPPED 
			PRINT COLUMN 01,"Transfer No.",p_rec_ibthead.trans_num USING "<<<<<<<<", 
			COLUMN 27,p_rec_ibthead.trans_date USING "dd/mm/yyyy" 
			SKIP 2 LINE 
			PRINT COLUMN 01,"Details of Contents:" 
			SKIP 1 LINE 
			PRINT COLUMN 01,"Description", 
			COLUMN 33,"Product Code", 
			COLUMN 50,"Asset No.", 
			COLUMN 64,"Serial No." 

		BEFORE GROUP OF p_rec_ibthead.trans_num 
			SKIP TO TOP OF PAGE 

		ON EVERY ROW 
			# Find out the stock we are dealing with - watch asmay have been retransferred
			LET l_ware_code_use = " " 
			SELECT count(*) INTO l_count 
			FROM serialinfo 
			WHERE serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND serialinfo.ware_code = p_rec_ibthead.from_ware_code 
			AND serialinfo.part_code = p_rec_ibtdetl.part_code 
			AND serialinfo.ref_num = p_rec_ibthead.trans_num 
			IF l_count > 0 THEN 
				LET l_ware_code_use = p_rec_ibthead.from_ware_code 
			ELSE 
				SELECT count(*) INTO l_count 
				FROM serialinfo 
				WHERE serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND serialinfo.ware_code = p_rec_ibthead.to_ware_code 
				AND serialinfo.part_code = p_rec_ibtdetl.part_code 
				AND serialinfo.ref_num = p_rec_ibthead.trans_num 
				IF l_count > 0 THEN 
					LET l_ware_code_use = p_rec_ibthead.to_ware_code 
				END IF 
			END IF 

			IF l_ware_code_use = " " THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE product.part_code = p_rec_ibtdetl.part_code 
				AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				SKIP 1 LINE 
				PRINT COLUMN 01,l_rec_product.desc_text, 
				COLUMN 33,l_rec_product.part_code, 
				COLUMN 50, "Stock re-transferred, information unavailable" 
			ELSE 
				DECLARE c_serialinfo CURSOR FOR 
				SELECT * FROM serialinfo 
				WHERE serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND serialinfo.ware_code = l_ware_code_use 
				AND serialinfo.part_code = p_rec_ibtdetl.part_code 
				AND serialinfo.ref_num = p_rec_ibthead.trans_num 
 
				FOREACH c_serialinfo INTO l_rec_serialinfo.* 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE product.part_code = p_rec_ibtdetl.part_code 
					AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
					SKIP 1 LINE 
					PRINT COLUMN 01,l_rec_product.desc_text, 
					COLUMN 33,l_rec_product.part_code, 
					COLUMN 50,l_rec_serialinfo.asset_num, 
					COLUMN 64,l_rec_serialinfo.serial_code 

					IF p_kit_components = "Y" THEN 
						SKIP 1 LINE 
						SELECT * FROM kithead 
						WHERE kithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND kithead.kit_code = p_rec_ibtdetl.part_code 
						IF STATUS = NOTFOUND THEN 
						ELSE 
							DECLARE c_kitdetl CURSOR FOR 
							SELECT * FROM kitdetl 
							WHERE kitdetl.kitdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND kitdetl.kitdetl.kit_code = p_rec_ibtdetl.part_code 

							FOREACH c_kitdetl INTO l_rec_kitdetl.* 
								SELECT product.* 
								INTO l_rec_product.* 
								FROM product 
								WHERE product.product.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND product.part_code = l_rec_kitdetl.part_code 
								SELECT prodstatus.* 
								INTO l_rec_prodstatus.* 
								FROM prodstatus 
								WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND prodstatus.part_code = l_rec_kitdetl.part_code 
								AND prodstatus.ware_code = p_master_warecode 

								LET l_product_desc = l_rec_product.desc_text CLIPPED, 
								" ", 
								l_rec_product.desc2_text CLIPPED 

								IF p_prt_value = "Y" THEN 
									PRINT COLUMN 04, l_rec_kitdetl.kit_qty	USING "--&.&&"," x ", 
									COLUMN 13, l_rec_kitdetl.part_code CLIPPED, 
									COLUMN 29, l_product_desc CLIPPED, 
									COLUMN 82, l_rec_prodstatus.list_amt 	USING "$<<<<<<<<<<<<&.&&" 
								ELSE 
									PRINT COLUMN 04, l_rec_kitdetl.kit_qty	USING "--&.&&"," x ", 
									COLUMN 13, l_rec_kitdetl.part_code CLIPPED, 
									COLUMN 29, l_product_desc CLIPPED 
								END IF 
							END FOREACH 
 
						END IF 
					END IF 
				END FOREACH 
 
			END IF 

			PAGE TRAILER 
				SELECT * INTO l_rec_warehouse.* FROM warehouse 
				WHERE warehouse.ware_code = p_rec_ibthead.from_ware_code 
				AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
				PRINT COLUMN 01,"Source......",p_rec_ibthead.from_ware_code, 
				" ",l_rec_warehouse.desc_text CLIPPED 
				PRINT COLUMN 15, l_rec_warehouse.addr1_text CLIPPED 
				PRINT COLUMN 15, l_rec_warehouse.addr2_text CLIPPED 
				PRINT COLUMN 15, l_rec_warehouse.city_text CLIPPED 
				PRINT COLUMN 15, l_rec_warehouse.contact_text CLIPPED 
				PRINT COLUMN 15, l_rec_warehouse.tele_text CLIPPED 
				SKIP 1 LINE

END REPORT 
