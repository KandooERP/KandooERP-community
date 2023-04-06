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
DEFINE modu_inparms RECORD LIKE inparms.* 
DEFINE modu_rpt_option CHAR(1)

############################################################
# FUNCTION IF7_main()
#
# Purpose - Costledger Validation Report
############################################################
FUNCTION IF7_main()

	CALL setModuleId("IF7") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT * INTO modu_inparms.*	FROM inparms 
	WHERE inparms.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			inparms.parm_code = "1" 
	IF modu_inparms.cost_ind != "F"	AND modu_inparms.cost_ind != "L" THEN 
		CALL msgerror("","Fifo or Lifo costing not used.\n          Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",9266,"") 
		#I9266 " Fifo OR Lifo costing NOT used "
		EXIT PROGRAM 
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I215 WITH FORM "I215" 
			 CALL windecoration_i("I215")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Costledger Validation" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IF7","menu-Costledg_Validation-1") -- albo kd-505
					CALL fgl_dialog_setactionlabel("Update","Adjustment","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",4,FALSE,"Adjust Incorrect Costledgers")
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					LET modu_rpt_option = "R"
					CALL rpt_rmsreps_reset(NULL)
					CALL IF7_rpt_process(IF7_rpt_query()) 

				ON ACTION "Update" #COMMAND "Update" " Adjust Incorrect Costledgers"
					LET modu_rpt_option = "U"
					CALL rpt_rmsreps_reset(NULL)
					CALL IF7_rpt_process(IF7_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I215

		WHEN "2" #Background Process with rmsreps.report_code
			LET modu_rpt_option = "R"
			CALL IF7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I215 with FORM "I215" 
			 CALL windecoration_i("I215") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IF7_rpt_query()) #save where clause in env 
			CLOSE WINDOW I215 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			LET modu_rpt_option = "R"
			CALL IF7_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION IF7_main()
############################################################

############################################################
# FUNCTION IF7_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IF7_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT r_where_text ON 
	product.cat_code, 
	product.class_code, 
	prodstatus.part_code, 
	prodstatus.ware_code 
	FROM 
	cat_code, 
	class_code, 
	part_code, 
	ware_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IF7","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION
############################################################
# END FUNCTION IF7_rpt_query() 
############################################################

############################################################
# FUNCTION IF7_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IF7_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rpt_idx_2 SMALLINT
	DEFINE l_rec_rep RECORD 
		cat_code LIKE product.cat_code, 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		act_cost_amt LIKE prodstatus.act_cost_amt, 
		sum_onhand_qty LIKE costledg.onhand_qty 
	END RECORD 
	DEFINE l_rec_rep2 RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE prodledg.ware_code, 
		tran_date LIKE prodledg.tran_date, 
		trantype_ind LIKE prodledg.trantype_ind, 
		tran_qty LIKE prodledg.tran_qty, 
		onhand_qty LIKE costledg.onhand_qty, 
		received_qty LIKE costledg.received_qty 
	END RECORD
	DEFINE l_prodledg_qty LIKE prodledg.tran_qty

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	IF modu_rpt_option = "U" THEN 
		LET l_rpt_idx = rpt_start(getmoduleid(),"IF7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	ELSE 
		LET l_rpt_idx = rpt_start(trim(getmoduleid())||".","IF7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	END IF
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	LET l_rpt_idx_2 = rpt_start(trim(getmoduleid())||"..","IF7_rpt_list_2",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx_2 = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF

	START REPORT IF7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	START REPORT IF7_rpt_list_2 TO rpt_get_report_file_with_path2(l_rpt_idx_2)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.cat_code,", 
	"prodstatus.part_code,", 
	"prodstatus.ware_code,", 
	"prodstatus.onhand_qty,",
	"prodstatus.act_cost_amt,", 
	"SUM (costledg.onhand_qty)", 
	"FROM product,prodstatus,costledg ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"costledg.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"product.part_code = prodstatus.part_code AND ", 
	"product.part_code = costledg.part_code AND ", 
	"costledg.ware_code = prodstatus.ware_code AND ", 
	p_where_text CLIPPED," ", 
	"GROUP BY product.cat_code, ", 
	"prodstatus.part_code, ", 
	"prodstatus.ware_code, ", 
	"prodstatus.onhand_qty,",
	"prodstatus.act_cost_amt ", 
	"HAVING prodstatus.onhand_qty != SUM(costledg.onhand_qty) ", 
	"ORDER BY product.cat_code,prodstatus.part_code,prodstatus.ware_code " 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR with HOLD FOR choice 

	FOREACH selcurs INTO l_rec_rep.* 
		# get unposted qty
		SELECT SUM(tran_qty) INTO l_prodledg_qty	FROM prodledg 
		WHERE prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				prodledg.part_code = l_rec_rep.part_code AND 
				prodledg.ware_code = l_rec_rep.ware_code AND 
				prodledg.post_flag = "N" AND 
				prodledg.trantype_ind NOT in ("A","U") 
		IF l_prodledg_qty IS NULL THEN 
			LET l_prodledg_qty = 0 
		END IF 
		LET l_rec_rep.sum_onhand_qty = l_rec_rep.sum_onhand_qty + l_prodledg_qty 
		IF l_rec_rep.sum_onhand_qty <> l_rec_rep.onhand_qty THEN 
			#---------------------------------------------------------
			OUTPUT TO REPORT IF7_rpt_list(l_rpt_idx,l_rec_rep.*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_rep.part_code,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			# now create a detailed REPORT of the transactions
			DECLARE ccurs CURSOR WITH HOLD FOR 
			SELECT p.part_code, p.ware_code, p.tran_date, 
			p.trantype_ind, p.tran_qty, c.onhand_qty, 
			c.received_qty, p.seq_num 
			FROM prodledg p, costledg c 
			WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					p.part_code = l_rec_rep.part_code AND 
					p.ware_code = l_rec_rep.ware_code AND 
					p.cmpy_code = c.cmpy_code         AND 
					p.part_code = c.part_code 		    AND 
					p.ware_code = c.ware_code		    AND
					p.tran_date = c.tran_date		    AND
					p.seq_num   = c.seq_num
			ORDER BY p.seq_num 
			FOREACH ccurs INTO l_rec_rep2.* 
				#---------------------------------------------------------
				OUTPUT TO REPORT IF7_rpt_list_2(l_rpt_idx_2,l_rec_rep2.*) 
				IF NOT rpt_int_flag_handler2("Product: ",l_rec_rep2.part_code,"",l_rpt_idx_2) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END FOREACH 

			IF modu_rpt_option = "U" 
			THEN # UPDATE costledg AND remove excess 
				BEGIN WORK 
					IF modu_inparms.cost_ind = "F" THEN 
						CALL update_fifo(glob_rec_kandoouser.cmpy_code, 
						l_rec_rep.part_code, 
						l_rec_rep.ware_code, 
						l_rec_rep.act_cost_amt, 
						l_rec_rep.sum_onhand_qty - l_rec_rep.onhand_qty) 
					ELSE 
						CALL update_lifo(glob_rec_kandoouser.cmpy_code, 
						l_rec_rep.part_code, 
						l_rec_rep.ware_code, 
						l_rec_rep.act_cost_amt, 
						l_rec_rep.sum_onhand_qty - l_rec_rep.onhand_qty) 
					END IF 
				COMMIT WORK 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IF7_rpt_list
	CALL rpt_finish("IF7_rpt_list")
	FINISH REPORT IF7_rpt_list_2
	RETURN rpt_finish("IF7_rpt_list_2")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IF7_rpt_process() 
############################################################

############################################################
# FUNCTION update_fifo() 
# 
# 
############################################################
FUNCTION update_fifo(p_cmpy,p_part_code,p_ware_code,p_act_cost_amt,p_tran_qty) 
	DEFINE p_cmpy LIKE prodledg.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_act_cost_amt LIKE prodstatus.act_cost_amt
	DEFINE p_tran_qty LIKE prodledg.tran_qty 
 	DEFINE l_rec_costledg RECORD LIKE costledg.* 
	DEFINE l_remain_qty LIKE prodledg.tran_qty 
	DEFINE l_cost_qty LIKE prodledg.tran_qty 
	DEFINE l_call_status INTEGER 
	DEFINE l_db_status INTEGER
	DEFINE l_rowid INTEGER

	#TODO rowid should be removed after creating Primary key for 'costledg' table (albo)

	LET l_remain_qty = p_tran_qty 

	DECLARE fcost_curs CURSOR FOR 
	SELECT *, rowid FROM costledg 
	WHERE costledg.cmpy_code = p_cmpy	   AND 
			costledg.part_code = p_part_code AND 
			costledg.ware_code = p_ware_code AND 
			costledg.onhand_qty != 0 
	ORDER BY costledg.tran_date 

	FOREACH fcost_curs INTO l_rec_costledg.*, l_rowid 
		IF l_remain_qty = 0 THEN 
			EXIT FOREACH 
		END IF 
		IF l_remain_qty < l_rec_costledg.onhand_qty THEN 
			LET l_cost_qty = l_remain_qty 
			LET l_rec_costledg.onhand_qty = l_rec_costledg.onhand_qty - l_cost_qty 
			# Update Fifo Costledg 
			UPDATE costledg SET costledg.onhand_qty = l_rec_costledg.onhand_qty 
			WHERE costledg.cmpy_code = p_cmpy      AND 
					costledg.part_code = p_part_code AND 
					costledg.ware_code = p_ware_code AND
					costledg.rowid     = l_rowid 
		ELSE 
			LET l_cost_qty = l_rec_costledg.onhand_qty 
			# Update 2 Fifo Costledg 
			UPDATE costledg SET costledg.onhand_qty = 0 
			WHERE costledg.cmpy_code = p_cmpy      AND 
					costledg.part_code = p_part_code AND 
					costledg.ware_code = p_ware_code AND
					costledg.rowid     = l_rowid					 
		END IF 
		LET l_remain_qty = l_remain_qty - l_cost_qty 
	END FOREACH 
	# IF cost ledgers are less than on hand, receipt the
	#                 remainder AT latest actual cost
	IF l_remain_qty <> 0 THEN 
		IF l_remain_qty < 0 THEN 
			LET l_remain_qty = l_remain_qty * -1 
		END IF 
		CALL fifo_lifo_receipt(p_cmpy,p_part_code,p_ware_code,TODAY,0,"A",l_remain_qty,modu_inparms.cost_ind,p_act_cost_amt)	RETURNING l_call_status,l_db_status 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION update_fifo() 
############################################################

############################################################
# FUNCTION update_lifo() 
# 
# 
############################################################
FUNCTION update_lifo(p_cmpy,p_part_code,p_ware_code,p_act_cost_amt,p_tran_qty) 
	DEFINE p_cmpy LIKE prodledg.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_act_cost_amt LIKE prodstatus.act_cost_amt
	DEFINE p_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_rec_costledg RECORD LIKE costledg.* 
	DEFINE l_remain_qty LIKE prodledg.tran_qty
	DEFINE l_cost_qty LIKE prodledg.tran_qty 
	DEFINE l_call_status, l_db_status INTEGER 
	DEFINE l_rowid INTEGER

	#TODO rowid should be removed after creating Primary key for 'costledg' table (albo)

	LET l_remain_qty = p_tran_qty 

	DECLARE cost_curs CURSOR FOR 
	SELECT *, rowid FROM costledg 
	WHERE costledg.cmpy_code = p_cmpy	   AND 
			costledg.part_code = p_part_code AND 
			costledg.ware_code = p_ware_code AND 
			costledg.onhand_qty != 0 
	ORDER BY costledg.tran_date DESC 

	FOREACH cost_curs INTO l_rec_costledg.*, l_rowid
		IF l_remain_qty = 0 THEN 
			EXIT FOREACH 
		END IF 
		IF l_remain_qty < l_rec_costledg.onhand_qty THEN 
			LET l_cost_qty = l_remain_qty 
			LET l_rec_costledg.onhand_qty = l_rec_costledg.onhand_qty - l_cost_qty 
			# Update Lifo Costledg 
			UPDATE costledg SET costledg.onhand_qty = l_rec_costledg.onhand_qty 
			WHERE costledg.cmpy_code = p_cmpy      AND 
					costledg.part_code = p_part_code AND 
					costledg.ware_code = p_ware_code AND
					costledg.rowid     = l_rowid					
		ELSE 
			LET l_cost_qty = l_rec_costledg.onhand_qty 
			# Update 2 Lifo Costledg 
			UPDATE costledg SET costledg.onhand_qty = 0 
			WHERE costledg.cmpy_code = p_cmpy      AND 
					costledg.part_code = p_part_code AND 
					costledg.ware_code = p_ware_code AND
					costledg.rowid     = l_rowid					 
		END IF 
		LET l_remain_qty = l_remain_qty - l_cost_qty 
	END FOREACH 
	# IF cost ledgers are less than on hand, receipt the
	#                 remainder AT latest actual cost
	IF l_remain_qty > 0 THEN 
		CALL fifo_lifo_receipt(p_cmpy,p_part_code,p_ware_code,TODAY,0,"A",l_remain_qty,modu_inparms.cost_ind,p_act_cost_amt)	RETURNING l_call_status,l_db_status 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION update_lifo() 
############################################################

############################################################
# REPORT IF7_rpt_list(p_rpt_idx,p_rec_rep)
# Costledger Validation (Update) Report
# Report Definition/Layout
############################################################
REPORT IF7_rpt_list(p_rpt_idx,p_rec_rep) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_rep RECORD 
		cat_code LIKE product.cat_code, 
		part_code LIKE prodstatus.part_code, 
		ware_code LIKE prodstatus.ware_code, 
		onhand_qty LIKE prodstatus.onhand_qty, 
		act_cost_amt LIKE prodstatus.act_cost_amt, 
		sum_onhand_qty LIKE costledg.onhand_qty 
	END RECORD
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_category RECORD LIKE category.* 

	ORDER EXTERNAL BY p_rec_rep.cat_code,p_rec_rep.part_code,p_rec_rep.ware_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_rep.cat_code 
		SELECT * INTO l_rec_category.* FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				cat_code = p_rec_rep.cat_code 
		PRINT COLUMN 01, "Category: ", 
		COLUMN 12, l_rec_category.cat_code CLIPPED, 
		COLUMN 17, l_rec_category.desc_text CLIPPED 

	ON EVERY ROW 
		SELECT *	INTO l_rec_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				part_code = p_rec_rep.part_code 
		IF modu_rpt_option = "U" AND 
			p_rec_rep.sum_onhand_qty > p_rec_rep.onhand_qty THEN 
			PRINT 
			COLUMN 04, p_rec_rep.part_code CLIPPED, 
			COLUMN 20, l_rec_product.desc_text CLIPPED, 
			COLUMN 57, p_rec_rep.ware_code CLIPPED, 
			COLUMN 61, p_rec_rep.onhand_qty                            USING "----,---,--&.&&&&", 
			COLUMN 79, p_rec_rep.sum_onhand_qty                        USING "----,---,--&.&&&&", 
			COLUMN 97, p_rec_rep.sum_onhand_qty - p_rec_rep.onhand_qty USING "----,---,--&.&&&&", 
			COLUMN 116,"Adjusted" 
		ELSE 
			PRINT 
			COLUMN 04, p_rec_rep.part_code CLIPPED, 
			COLUMN 20, l_rec_product.desc_text CLIPPED, 
			COLUMN 57, p_rec_rep.ware_code CLIPPED, 
			COLUMN 61, p_rec_rep.onhand_qty                            USING "----,---,--&.&&&&", 
			COLUMN 79, p_rec_rep.sum_onhand_qty                        USING "----,---,--&.&&&&", 
			COLUMN 97, p_rec_rep.sum_onhand_qty - p_rec_rep.onhand_qty USING "----,---,--&.&&&&" 
		END IF 
		IF l_rec_product.desc2_text IS NOT NULL THEN 
			PRINT COLUMN 20, l_rec_product.desc2_text CLIPPED 
		END IF 

	AFTER GROUP OF p_rec_rep.cat_code 
		SKIP 2 LINES 

	ON LAST ROW 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
############################################################
# END REPORT IF7_rpt_list()  
############################################################

############################################################
# REPORT IF7_rpt_list_2(p_rpt_idx,p_rec_rep2)
# Costledger Validation Detailed Report
# Report Definition/Layout
############################################################
REPORT IF7_rpt_list_2(p_rpt_idx,p_rec_rep2) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_rep2 RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE prodledg.ware_code, 
		tran_date LIKE prodledg.tran_date, 
		trantype_ind LIKE prodledg.trantype_ind, 
		tran_qty LIKE prodledg.tran_qty, 
		onhand_qty LIKE costledg.onhand_qty, 
		received_qty LIKE costledg.received_qty 
	END RECORD 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		PRINT 
		COLUMN 04, p_rec_rep2.part_code CLIPPED, 
		COLUMN 22, p_rec_rep2.ware_code CLIPPED, 
		COLUMN 38, p_rec_rep2.tran_date     USING "dd/mm/yy", 
		COLUMN 54, p_rec_rep2.trantype_ind CLIPPED, 
		COLUMN 57, p_rec_rep2.tran_qty      USING "----,---,--&.&&", 
		COLUMN 78, p_rec_rep2.onhand_qty    USING "----,---,--&.&&", 
		COLUMN 99, p_rec_rep2.received_qty  USING "----,---,--&.&&" 

	ON LAST ROW
		SKIP 2 LINES
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
############################################################
# END REPORT IF7_rpt_list_2()  
############################################################
