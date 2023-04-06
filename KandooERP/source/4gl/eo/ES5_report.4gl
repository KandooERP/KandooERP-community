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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES5_GLOBALS.4gl" 
###########################################################################
# Order Confirmation Summary
###########################################################################


###########################################################################
# REPORT ES5_rpt_list(p_rec_invhead)
#
# 
###########################################################################
REPORT ES5_rpt_list(p_rpt_idx,p_rec_invhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_invhead RECORD 
		po_num char(15), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		ship_qty LIKE invoicedetl.ship_qty 
	END RECORD 
--	DEFINE pa_line array[4] OF char(132) 

	OUTPUT 

	ORDER BY p_rec_invhead.po_num, p_rec_invhead.part_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_rec_invhead.po_num 
			PRINT COLUMN 01, "Purchase order:", 
			COLUMN 17, p_rec_invhead.po_num 
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_invhead.po_num 
			NEED 3 LINES 
			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "Purchase Order Total: ",p_rec_invhead.po_num, 
			COLUMN 51, GROUP sum(p_rec_invhead.ship_qty) USING "--------&" 
			SKIP 1 line
			 
		AFTER GROUP OF p_rec_invhead.part_code 
			PRINT COLUMN 03, p_rec_invhead.part_code, 
			COLUMN 19, p_rec_invhead.desc_text, 
			COLUMN 51, GROUP sum(p_rec_invhead.ship_qty) USING "--------&" 
			
		ON LAST ROW 
			NEED 7 LINES 
			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "Report totals:", 
			COLUMN 51, sum(p_rec_invhead.ship_qty) USING "--------&" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			 
END REPORT
###########################################################################
# END REPORT ES5_rpt_list(p_rec_invhead)
###########################################################################