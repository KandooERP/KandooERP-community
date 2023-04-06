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
DEFINE modu_rec_inparms RECORD LIKE inparms.* 
DEFINE modu_year_num LIKE ibthead.year_num
DEFINE modu_period_num LIKE ibthead.period_num
DEFINE modu_uom_code LIKE uom.uom_code
DEFINE modu_conf_total LIKE prodledg.tran_qty 
DEFINE modu_receipt_total LIKE prodledg.tran_qty 
DEFINE modu_transit_total LIKE prodledg.tran_qty 
DEFINE modu_cost_total LIKE prodledg.cost_amt 

############################################################
# FUNCTION I5T_main()
# RETURN VOID
#
# Purpose - Stock Transfer Confirmation Report
############################################################
FUNCTION I5T_main() 

	CALL setModuleId("I5T") 

	CREATE TEMP TABLE t_transfer 
	(from_ware_code CHAR(3), 
	to_ware_code CHAR(3), 
	trans_num INTEGER, 
	conf_qty FLOAT, 
	uom_code CHAR(4), 
	source_cost DECIMAL(16,4), 
	pick_num INTEGER, 
	conf_date DATE, 
	transit_qty FLOAT, 
	receipt_date DATE, 
	receipt_qty FLOAT, 
	part_code CHAR(15), 
	desc_text CHAR(30), 
	vehicle_code CHAR(8)) WITH NO LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I706 WITH FORM "I706" 
			 CALL windecoration_i("I706")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product Status" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","I5T","menu-Stock Transfer-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL I5T_rpt_process(I5T_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL I5T_rpt_process(I5T_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I706

		WHEN "2" #Background Process with rmsreps.report_code
			CALL I5T_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I706 with FORM "I706" 
			 CALL windecoration_i("I706") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(I5T_rpt_query()) #save where clause in env 
			CLOSE WINDOW I706 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL I5T_rpt_process(get_url_sel_text())
	END CASE	

	DROP TABLE t_transfer

END FUNCTION 
############################################################
# END FUNCTION I5T_main() 
############################################################ 

############################################################
# FUNCTION I5T_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION I5T_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text
	DEFINE l_rec_uom RECORD LIKE uom.* 

	CLEAR FORM
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT modu_year_num,modu_period_num,modu_uom_code WITHOUT DEFAULTS FROM year_num,period_num,uom_code 

			AFTER FIELD uom_code 
				INITIALIZE l_rec_uom.* TO NULL 
				IF modu_uom_code IS NOT NULL THEN 
					SELECT * INTO l_rec_uom.* FROM uom 
					WHERE uom_code = modu_uom_code AND 
							cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF STATUS = NOTFOUND THEN 
						ERROR kandoomsg2("U",9105,"") 
						#9105 RECORD Not Found; Try Window
						NEXT FIELD uom_code 
					END IF 
				END IF 
				DISPLAY BY NAME l_rec_uom.desc_text 

			AFTER INPUT 
				IF modu_year_num IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD year_num 
				END IF 
				IF modu_period_num IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD period_num 
				END IF 
				SELECT UNIQUE 1 FROM period 
				WHERE period_num = modu_period_num	AND 
						year_num = modu_year_num AND 
						cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF STATUS = NOTFOUND THEN 
					ERROR kandoomsg2("A",9223,"") 
					#9223 Invalid Year & Period
					NEXT FIELD year_num 
				END IF 
		END INPUT 

		CONSTRUCT BY NAME r_where_text ON 
		ibthead.from_ware_code, 
		ibthead.to_ware_code, 
		ibthead.trans_num, 
		ibthead.trans_date, 
		ibthead.status_ind, 
		prodledg.ref_num, 
		prodledg.part_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","I5T","construct-from_ware_code-1") -- albo kd-505 

		END CONSTRUCT 

		BEFORE DIALOG
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,TODAY) RETURNING modu_year_num,modu_period_num

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

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
# END FUNCTION I5T_rpt_query() 
############################################################

############################################################
# FUNCTION I5T_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION I5T_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_delivhead RECORD LIKE delivhead.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_transfer2 RECORD 
		from_ware_code CHAR(3), 
		to_ware_code CHAR(3), 
		trans_num LIKE ibthead.trans_num, 
		status_ind LIKE ibthead.status_ind, 
		pick_num LIKE prodledg.ref_num, 
		part_code LIKE prodledg.part_code, 
		conf_qty LIKE prodledg.tran_qty, 
		conf_date LIKE prodledg.tran_date, 
		source_cost LIKE prodledg.cost_amt 
	END RECORD 
	DEFINE l_rec_transfer RECORD 
		from_ware_code CHAR(3), 
		to_ware_code CHAR(3), 
		trans_num LIKE ibthead.trans_num, 
		conf_qty LIKE prodledg.tran_qty, 
		uom_code LIKE uom.uom_code, 
		source_cost LIKE prodledg.cost_amt, 
		pick_num LIKE prodledg.ref_num, 
		conf_date LIKE prodledg.tran_date, 
		transit_qty LIKE prodledg.tran_qty, 
		receipt_date LIKE prodledg.tran_date, 
		receipt_qty LIKE prodledg.tran_qty, 
		part_code LIKE prodledg.part_code, 
		desc_text LIKE product.desc_text, 
		vehicle_code LIKE delivhead.vehicle_code 
	END RECORD 
	DEFINE l_conv_qty FLOAT
	DEFINE l_cancelled SMALLINT

	DELETE FROM t_transfer WHERE 1=1 
	#TODO replace with global glob_rec_inparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_rec_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_conf_total = 0 
	LET modu_receipt_total = 0 
	LET modu_transit_total = 0 
	LET modu_cost_total = 0 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"I5T_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT I5T_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT ibthead.from_ware_code,", 
	"ibthead.to_ware_code,", 
	"ibthead.trans_num,", 
	"ibthead.status_ind,", 
	"prodledg.ref_num,",
	"prodledg.part_code,", 
	"sum(prodledg.tran_qty * -1),", 
	"MAX(prodledg.tran_date),", 
	"MAX(prodledg.cost_amt) ", 
	"FROM ibthead, prodledg ", 
	"WHERE ibthead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodledg.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ibthead.trans_num = prodledg.source_num ", 
	"AND ibthead.status_ind in ('",IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P, "','", IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C,"','",IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R ,"') ", 
	"AND prodledg.year_num = ",modu_year_num," ", 
	"AND prodledg.period_num = ",modu_period_num," ", 
	"AND prodledg.trantype_ind = 'T' ", 
	"AND (prodledg.source_code = '",modu_rec_inparms.ibt_ware_code CLIPPED, 
	"' OR prodledg.source_code = ibthead.to_ware_code) ", 
	"AND prodledg.ware_code = ibthead.from_ware_code ",
	"AND prodledg.tran_qty < 0 ",
	"AND ", p_where_text CLIPPED," ",
	"GROUP BY ibthead.from_ware_code, ibthead.to_ware_code, ibthead.trans_num, prodledg.ref_num, prodledg.part_code, ibthead.status_ind ", 
	"ORDER BY ibthead.from_ware_code, ibthead.to_ware_code, ibthead.trans_num, prodledg.ref_num, prodledg.part_code, ibthead.status_ind" 

	PREPARE s_ibtledg FROM l_query_text 
	DECLARE c_ibtledg CURSOR FOR s_ibtledg 

	FOREACH c_ibtledg INTO l_rec_transfer2.* 
		CALL get_receipt(l_rec_transfer2.*)	RETURNING l_rec_transfer.receipt_date, l_rec_transfer.receipt_qty 
		LET l_cancelled = FALSE 
		IF l_rec_transfer2.status_ind = "R" THEN 
			IF l_rec_transfer.receipt_qty = 0  
			OR l_rec_transfer.receipt_qty IS NULL THEN 
				CONTINUE FOREACH 
			ELSE 
				LET l_cancelled = TRUE 
			END IF 
		END IF 
		INITIALIZE l_rec_delivhead.* TO NULL 
		SELECT delivhead.* INTO l_rec_delivhead.* FROM delivhead 
		WHERE delivhead.pick_num = l_rec_transfer2.pick_num AND 
				delivhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF STATUS = NOTFOUND THEN 
			LET l_rec_transfer.conf_date = l_rec_transfer2.conf_date 
		ELSE 
			LET l_rec_transfer.conf_date = l_rec_delivhead.pick_date 
		END IF 
		INITIALIZE l_rec_product.* TO NULL 
		SELECT product.* INTO l_rec_product.* FROM product 
		WHERE product.part_code = l_rec_transfer2.part_code AND 
				product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF modu_uom_code IS NOT NULL THEN 
			LET l_conv_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_transfer2.part_code,modu_uom_code,l_rec_product.sell_uom_code,0) 
			LET l_rec_transfer.uom_code = modu_uom_code 
			IF l_conv_qty <= 0 THEN 
				LET l_conv_qty = 1 
			END IF 
		ELSE 
			LET l_rec_transfer.uom_code = l_rec_product.sell_uom_code 
			LET l_conv_qty = 1 
		END IF 
		LET l_rec_transfer.trans_num = l_rec_transfer2.trans_num 
		LET l_rec_transfer.receipt_qty = l_rec_transfer.receipt_qty	* l_conv_qty 
		IF l_cancelled THEN 
			LET l_rec_transfer.conf_qty = l_rec_transfer.receipt_qty 
		ELSE 
			LET l_rec_transfer.conf_qty = l_rec_transfer2.conf_qty * l_conv_qty 
		END IF 
		LET l_rec_transfer.to_ware_code = l_rec_transfer2.to_ware_code 
		LET l_rec_transfer.from_ware_code = l_rec_transfer2.from_ware_code 
		LET l_rec_transfer.source_cost = l_rec_transfer2.source_cost * l_rec_transfer.conf_qty 
		LET l_rec_transfer.pick_num = l_rec_transfer2.pick_num 
		IF l_rec_transfer.receipt_qty IS NULL THEN 
			LET l_rec_transfer.transit_qty = l_rec_transfer.conf_qty 
		ELSE 
			LET l_rec_transfer.transit_qty = l_rec_transfer.conf_qty - l_rec_transfer.receipt_qty 
		END IF 
		LET l_rec_transfer.part_code = l_rec_transfer2.part_code 
		LET l_rec_transfer.desc_text = l_rec_product.desc_text 
		LET l_rec_transfer.vehicle_code = l_rec_delivhead.vehicle_code 
		INSERT INTO t_transfer VALUES (l_rec_transfer.*) 
	END FOREACH 

	DECLARE c_transfer CURSOR FOR 
		SELECT t_transfer.* FROM t_transfer 
		ORDER BY t_transfer.from_ware_code,t_transfer.to_ware_code,t_transfer.trans_num,t_transfer.pick_num,t_transfer.part_code 

	FOREACH c_transfer INTO l_rec_transfer.*
		#---------------------------------------------------------
		OUTPUT TO REPORT I5T_rpt_list(l_rpt_idx,l_rec_transfer.*)   
		IF NOT rpt_int_flag_handler2("Transfer: ",l_rec_transfer.trans_num,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT I5T_rpt_list
	RETURN rpt_finish("I5T_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION I5T_rpt_process() 
############################################################

############################################################
# FUNCTION get_receipt(p_rec_transfer2) 
# 
# 	RETURN pr_receipt_date,pr_receipt_qty 
############################################################
FUNCTION get_receipt(p_rec_transfer2) 
	DEFINE p_rec_transfer2 RECORD 
		from_ware_code LIKE ibthead.from_ware_code, 
		to_ware_code LIKE ibthead.to_ware_code, 
		trans_num LIKE ibthead.trans_num, 
		status_ind LIKE ibthead.status_ind, 
		pick_num LIKE prodledg.ref_num, 
		part_code LIKE prodledg.part_code, 
		conf_qty LIKE prodledg.tran_qty, 
		conf_date LIKE prodledg.tran_date, 
		source_cost LIKE prodledg.cost_amt 
	END RECORD
	DEFINE r_receipt_date LIKE prodledg.tran_date 
	DEFINE r_receipt_qty LIKE prodledg.tran_qty 

	INITIALIZE r_receipt_date TO NULL 
	INITIALIZE r_receipt_qty TO NULL 
	IF p_rec_transfer2.pick_num IS NOT NULL THEN 
		SELECT MAX(tran_date), sum(tran_qty) 
		INTO r_receipt_date, r_receipt_qty 
		FROM prodledg 
		WHERE source_num = p_rec_transfer2.trans_num 
		AND ref_num = p_rec_transfer2.pick_num 
		AND trantype_ind = "T" 
		AND part_code = p_rec_transfer2.part_code 
		AND ware_code = p_rec_transfer2.to_ware_code 
		AND (source_text = modu_rec_inparms.ibt_ware_code 
		OR source_text = p_rec_transfer2.from_ware_code) 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_qty > 0 
	ELSE 
		SELECT MAX(tran_date), sum(tran_qty) 
		INTO r_receipt_date, r_receipt_qty 
		FROM prodledg 
		WHERE source_num = p_rec_transfer2.trans_num 
		AND ref_num IS NULL 
		AND trantype_ind = "T" 
		AND part_code = p_rec_transfer2.part_code 
		AND ware_code = p_rec_transfer2.to_ware_code 
		AND (source_text = modu_rec_inparms.ibt_ware_code 
		OR source_text = p_rec_transfer2.from_ware_code) 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_qty > 0 
	END IF 
	RETURN r_receipt_date,r_receipt_qty 

END FUNCTION 
############################################################
# END FUNCTION get_receipt() 
############################################################

############################################################
# REPORT I5T_rpt_list(p_rpt_idx,p_rec_transfer)
#
# Report Definition/Layout
############################################################
REPORT I5T_rpt_list(p_rpt_idx,p_rec_transfer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_transfer RECORD 
		from_ware_code CHAR(3), 
		to_ware_code CHAR(3), 
		trans_num LIKE ibthead.trans_num, 
		conf_qty LIKE prodledg.tran_qty, 
		uom_code LIKE uom.uom_code, 
		source_cost LIKE prodledg.cost_amt, 
		pick_num LIKE prodledg.ref_num, 
		conf_date LIKE prodledg.tran_date, 
		transit_qty LIKE prodledg.tran_qty, 
		receipt_date LIKE prodledg.tran_date, 
		receipt_qty LIKE prodledg.tran_qty, 
		part_code LIKE prodledg.part_code, 
		desc_text LIKE product.desc_text, 
		vehicle_code LIKE delivhead.vehicle_code 
	END RECORD 
	DEFINE l_cost_to LIKE prodledg.tran_qty 
	DEFINE l_cost_from LIKE prodledg.tran_qty 
	DEFINE l_conf_to LIKE prodledg.tran_qty 
	DEFINE l_conf_from LIKE prodledg.tran_qty 
 	DEFINE l_receipt_to LIKE prodledg.tran_qty 
	DEFINE l_receipt_from LIKE prodledg.tran_qty 
	DEFINE l_transit_to LIKE prodledg.tran_qty 
	DEFINE l_transit_from LIKE prodledg.tran_qty 
	DEFINE l_first SMALLINT 

	ORDER EXTERNAL BY p_rec_transfer.from_ware_code,p_rec_transfer.to_ware_code,p_rec_transfer.trans_num,p_rec_transfer.pick_num,p_rec_transfer.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_transfer.from_ware_code 
		SKIP 2 LINES 
		PRINT COLUMN 01, p_rec_transfer.from_ware_code CLIPPED, " TO ",p_rec_transfer.to_ware_code CLIPPED 
		LET l_first = TRUE 
		LET l_conf_from = 0 
		LET l_receipt_from = 0 
		LET l_transit_from = 0 

	BEFORE GROUP OF p_rec_transfer.to_ware_code 
		LET l_conf_to = 0 
		LET l_receipt_to = 0 
		LET l_transit_to = 0 
		IF l_first THEN 
			LET l_first = FALSE 
		ELSE 
			SKIP 1 LINES 
			PRINT COLUMN 01, p_rec_transfer.from_ware_code CLIPPED, " TO ",p_rec_transfer.to_ware_code CLIPPED 
		END IF 

	ON EVERY ROW 
		PRINT COLUMN 004, p_rec_transfer.trans_num USING "#######&", 
		COLUMN 014,p_rec_transfer.conf_qty         USING "######&.&", 
		COLUMN 024,p_rec_transfer.uom_code CLIPPED, 
		COLUMN 029,p_rec_transfer.source_cost      USING "---,---,--&.&&", 
		COLUMN 044,p_rec_transfer.pick_num         USING "#######&", 
		COLUMN 054,p_rec_transfer.conf_date        USING "dd/mm/yy", 
		COLUMN 064,p_rec_transfer.transit_qty      USING "######&.&", 
		COLUMN 075,p_rec_transfer.receipt_qty      USING "######&.&", 
		COLUMN 086,p_rec_transfer.receipt_date     USING "dd/mm/yy", 
		COLUMN 096,p_rec_transfer.part_code CLIPPED, 
		COLUMN 124,p_rec_transfer.vehicle_code CLIPPED
		PRINT COLUMN 096, p_rec_transfer.desc_text CLIPPED
		IF p_rec_transfer.conf_qty IS NOT NULL THEN 
			LET l_conf_to = l_conf_to + p_rec_transfer.conf_qty 
			LET l_conf_from = l_conf_from + p_rec_transfer.conf_qty 
			LET modu_conf_total = modu_conf_total + p_rec_transfer.conf_qty 
		END IF 
		IF p_rec_transfer.receipt_qty IS NOT NULL THEN 
			LET l_receipt_to = l_receipt_to + p_rec_transfer.receipt_qty 
			LET l_receipt_from = l_receipt_from + p_rec_transfer.receipt_qty 
			LET modu_receipt_total = modu_receipt_total + p_rec_transfer.receipt_qty 
		END IF 
		IF p_rec_transfer.transit_qty IS NOT NULL THEN 
			LET l_transit_to = l_transit_to + p_rec_transfer.transit_qty 
			LET l_transit_from = l_transit_from + p_rec_transfer.transit_qty 
			LET modu_transit_total = modu_transit_total + p_rec_transfer.transit_qty 
		END IF 
		IF p_rec_transfer.source_cost IS NOT NULL THEN 
			LET l_cost_to = l_cost_to + p_rec_transfer.source_cost 
			LET l_cost_from = l_cost_from + p_rec_transfer.source_cost 
			LET modu_cost_total = modu_cost_total + p_rec_transfer.source_cost 
		END IF 

	AFTER GROUP OF p_rec_transfer.to_ware_code 
		PRINT COLUMN 14, "---------", 
		COLUMN 29, "--------------", 
		COLUMN 64, "---------", 
		COLUMN 75, "---------" 
		PRINT COLUMN 14, l_conf_to USING "######&.&", 
		COLUMN 29, l_cost_to       USING "---,---,--&.&&", 
		COLUMN 64, l_transit_to    USING "######&.&", 
		COLUMN 75, l_receipt_to    USING "######&.&" 

	AFTER GROUP OF p_rec_transfer.from_ware_code 
		PRINT COLUMN 14, "=========", 
		COLUMN 29, "==============", 
		COLUMN 64, "=========", 
		COLUMN 75, "=========" 
		PRINT COLUMN 01, "Total", 
		COLUMN 14, l_conf_from     USING "######&.&", 
		COLUMN 29, l_cost_from     USING "---,---,--&.&&", 
		COLUMN 64, l_transit_from  USING "######&.&", 
		COLUMN 75, l_receipt_from  USING "######&.&" 

	ON LAST ROW 
		SKIP TO top OF PAGE 
		SKIP 2 LINES 
		PRINT COLUMN 14, "=========", 
		COLUMN 29, "==============", 
		COLUMN 64, "=========", 
		COLUMN 75, "=========" 
		PRINT COLUMN 01, "TOTAL", 
		COLUMN 14, modu_conf_total    USING "######&.&", 
		COLUMN 29, modu_cost_total    USING  "---,---,--&.&&",
		COLUMN 64, modu_transit_total USING "######&.&", 
		COLUMN 75, modu_receipt_total USING "######&.&" 
		SKIP 2 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO			

END REPORT
