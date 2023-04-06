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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# FUNCTION PBC()
#
# PBC Voucher Audit Trail REPORT
############################################################
FUNCTION PBC_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PBC")  

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
 
	OPEN WINDOW P152 with FORM "P152" 
	CALL windecoration_p("P152") 

	MENU " Voucher Detail" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PBC","menu-voucher-1") 
			CALL PBC_rpt_process(PBC_rpt_query()) 
			CALL rpt_rmsreps_reset(NULL)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 		#COMMAND "Run Report" " Selection Criteria AND Print Report"
			CALL PBC_rpt_process(PBC_rpt_query()) 
			CALL rpt_rmsreps_reset(NULL)

		ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO Menus"
			EXIT MENU 


	END MENU 

	CLOSE WINDOW P152 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PBC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PBC_rpt_query()) #save where clause in env 
			CLOSE WINDOW P120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PBC_rpt_process(get_url_sel_text())
	END CASE		
END FUNCTION 
############################################################
# END FUNCTION PBC()
############################################################


############################################################
# FUNCTION PBC_rpt_query() 
#
#
############################################################
FUNCTION PBC_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE" Enter Selection Criteria - ESC TO Continue " 

	CONSTRUCT BY NAME l_where_text ON voucherdist.vend_code, 
	voucherdist.vouch_code, 
	voucher.year_num, 
	voucher.period_num, 
	vendor.currency_code, 
	voucher.goods_amt, 
	voucher.dist_amt, 
	voucherdist.acct_code, 
	voucherdist.desc_text, 
	voucherdist.dist_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PBC","construct-voucherdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR " Printing was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION PBC_rpt_query() 
############################################################


############################################################
# FUNCTION PBC_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PBC_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	
	
	DEFINE l_rec_voucherdist RECORD 
		vend_code LIKE voucherdist.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		inv_text LIKE voucher.inv_text, 
		goods_amt LIKE voucher.goods_amt, 
		vouch_code LIKE voucherdist.vouch_code, 
		line_num LIKE voucherdist.line_num, 
		acct_code LIKE voucherdist.acct_code, 
		desc_text LIKE voucherdist.desc_text, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 	

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PBC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PBC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET l_query_text = 
	"SELECT unique voucherdist.vend_code,", 
	"vendor.name_text,", 
	"vendor.currency_code,", 
	"voucher.inv_text,", 
	"voucher.goods_amt,", 
	"voucherdist.vouch_code,", 
	"voucherdist.line_num,", 
	"voucherdist.acct_code, ", 
	"voucherdist.desc_text,", 
	"voucherdist.dist_amt ", 
	"FROM voucherdist,", 
	"vendor,", 
	"voucher ", 
	"WHERE voucherdist.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = voucherdist.cmpy_code ", 
	"AND vendor.vend_code = voucherdist.vend_code ", 
	"AND voucher.cmpy_code = voucherdist.cmpy_code ", 
	"AND voucher.vouch_code = voucherdist.vouch_code ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PBC_rpt_list")].sel_text clipped," ", 
	"ORDER BY voucherdist.vend_code,", 
	"voucherdist.vouch_code,", 
	"voucherdist.line_num" 
	
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 

	FOREACH c_voucher INTO l_rec_voucherdist.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PBC_rpt_list(l_rpt_idx,
		l_rec_voucherdist.*)
		IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucherdist.vouch_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT PBC_rpt_list
	CALL rpt_finish("PBC_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 
############################################################
# END FUNCTION PBC_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PBC_rpt_list(p_rpt_idx,p_rec_voucherdist)
#
#
############################################################
REPORT PBC_rpt_list(p_rpt_idx,p_rec_voucherdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucherdist RECORD 
		vend_code LIKE voucherdist.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		inv_text LIKE voucher.inv_text, 
		goods_amt LIKE voucher.goods_amt, 
		vouch_code LIKE voucherdist.vouch_code, 
		line_num LIKE voucherdist.line_num, 
		acct_code LIKE voucherdist.acct_code, 
		desc_text LIKE voucherdist.desc_text, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 
	DEFINE l_new_vend SMALLINT
	DEFINE l_new_vouch SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_voucherdist.vend_code, 
	p_rec_voucherdist.vouch_code, 
	p_rec_voucherdist.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, " Vendor", 
			COLUMN 16,"Vendor", 
			COLUMN 40,"Curr.", 
			COLUMN 46,"Vouch", 
			COLUMN 53,"Invoice", 
			COLUMN 63,"Total", 
			COLUMN 80," GL", 
			COLUMN 119, "Distribution" 
			PRINT COLUMN 1, " ID ", 
			COLUMN 16, "Name", 
			COLUMN 46, "Number", 
			COLUMN 53, "Number", 
			COLUMN 63, "Voucher", 
			COLUMN 80, "Account", 
			COLUMN 96, "Description", 
			COLUMN 124,"Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_voucherdist.vend_code 
			LET l_new_vend = 1 

		BEFORE GROUP OF p_rec_voucherdist.vouch_code 
			SKIP 1 LINES 
			LET l_new_vouch = 1 

		ON EVERY ROW 
			IF NOT l_new_vouch 
			AND NOT l_new_vend THEN 
				PRINT COLUMN 76, p_rec_voucherdist.acct_code, 
				COLUMN 92, p_rec_voucherdist.desc_text[1,25], 
				COLUMN 117, p_rec_voucherdist.dist_amt USING "-----,--$.&&" 
			END IF 

			IF l_new_vend THEN 
				PRINT COLUMN 1, p_rec_voucherdist.vend_code, 
				COLUMN 10, p_rec_voucherdist.name_text , 
				COLUMN 40, p_rec_voucherdist.currency_code , 
				COLUMN 44, p_rec_voucherdist.vouch_code USING "########" , 
				COLUMN 53, p_rec_voucherdist.inv_text[1,10], 
				COLUMN 63, p_rec_voucherdist.goods_amt USING "-----,--$.&&", 
				COLUMN 76, p_rec_voucherdist.acct_code, 
				COLUMN 92, p_rec_voucherdist.desc_text[1,25], 
				COLUMN 117, p_rec_voucherdist.dist_amt USING "-----,--$.&&" 
				LET l_new_vend = false 
			ELSE 
				IF l_new_vouch THEN 
					PRINT COLUMN 44, p_rec_voucherdist.vouch_code 
					USING "########" , 
					COLUMN 53, p_rec_voucherdist.inv_text[1,10], 
					COLUMN 63, p_rec_voucherdist.goods_amt 
					USING "-----,--$.&&", 
					COLUMN 76, p_rec_voucherdist.acct_code, 
					COLUMN 92, p_rec_voucherdist.desc_text[1,25], 
					COLUMN 117,p_rec_voucherdist.dist_amt 
					USING "-----,--$.&&" 
				END IF 
			END IF 
			LET l_new_vouch = false 

		AFTER GROUP OF p_rec_voucherdist.vouch_code 
			PRINT COLUMN 116,"================" 
			PRINT COLUMN 100,"Voucher Total", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "----,---,--$.&&" 
			SKIP 1 line 

		AFTER GROUP OF p_rec_voucherdist.vend_code 
			PRINT COLUMN 116,"================" 
			PRINT COLUMN 100,"Vendor Total", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "----,---,--$.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PBC_rpt_list(p_rpt_idx,p_rec_voucherdist)
############################################################