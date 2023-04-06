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
GLOBALS "../eo/ESV_GLOBALS.4gl" 

###########################################################################
# FUNCTION ESV_main()    
#
# Verify the OE system, check all possibilities 
###########################################################################
FUNCTION ESV_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ESV")  

	MENU " Verify OE " 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","ESV","menu-Verify_OE-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Verify" " Verify Order entry" 
			CALL verify() 

		ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print"  " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND "Exit" " Exit TO menu" 
			EXIT MENU 

	END MENU 
END FUNCTION  
###########################################################################
# END FUNCTION ESV_main()    
###########################################################################


###########################################################################
# FUNCTION verify()     
#
# 
###########################################################################
FUNCTION verify() 

	#CALL authenticate("ESV") returning glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code #huho don't get the point
	--LET rpt_wid = "132" 
	LET glob_problem = 0 

	DISPLAY "VERIFY OF ORDER ENTRY SYSTEM TAKING place" at 8,10 

	DECLARE ord_curs 
	cursor with hold FOR 
	SELECT * 
	INTO glob_rec_orderhead.* 
	FROM orderhead 
	WHERE orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN ord_curs 

	FOREACH ord_curs 
		DISPLAY "Order Number: " , glob_rec_orderhead.order_num at 10,10 

		# check that ORDER amt = sum of all parts

		IF glob_rec_orderhead.total_amt != (glob_rec_orderhead.goods_amt 
		+ glob_rec_orderhead.tax_amt 
		+ glob_rec_orderhead.freight_amt 
		+ glob_rec_orderhead.hand_amt) 
		THEN 
			LET glob_line_info = "Order amount NOT equal TO bits ", glob_rec_orderhead.order_num, "Header amt", glob_rec_orderhead.total_amt 
			CALL prob(glob_line_info) 
		END IF 

		# check that line totals = ORDER total

		SELECT sum(line_tot_amt) 
		INTO glob_sum_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = glob_rec_orderhead.order_num 

		IF glob_sum_amt != glob_rec_orderhead.total_amt - glob_rec_orderhead.hand_amt 
		- glob_rec_orderhead.freight_amt - glob_rec_orderhead.hand_tax_amt 
		- glob_rec_orderhead.freight_tax_amt 
		THEN 
			LET glob_line_info = "Order Line amount NOT equal TO header ", glob_rec_orderhead.order_num, "Header amt", glob_rec_orderhead.total_amt, "Line amt" ,glob_sum_amt 
			CALL prob(glob_line_info) 
		END IF 

		# check that tax lines = invoice header tax

		SELECT sum(ext_tax_amt) 
		INTO glob_sum_tax 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = glob_rec_orderhead.order_num 

		IF glob_sum_tax != glob_rec_orderhead.tax_amt - glob_rec_orderhead.hand_tax_amt 
		- glob_rec_orderhead.freight_tax_amt 
		THEN 
			LET glob_line_info = "Order Line tax NOT equal TO header ", glob_rec_orderhead.order_num, "Header amt", glob_rec_orderhead.tax_amt, "Line amt" ,glob_sum_tax 
			CALL prob(glob_line_info) 
		END IF 

		# check that invoice lines costs = invoice header cost

		SELECT sum(ext_cost_amt) 
		INTO glob_sum_cost 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = glob_rec_orderhead.order_num 

		IF glob_sum_cost != glob_rec_orderhead.cost_amt 
		THEN 
			LET glob_line_info = "Order Line cost NOT equal TO header ", glob_rec_orderhead.order_num, "Header amt", glob_rec_orderhead.cost_amt, "Line amt" ,glob_sum_cost 
			CALL prob(glob_line_info) 
		END IF 

		# check that no nulls are around

		IF glob_rec_orderhead.total_amt IS NULL 
		OR glob_rec_orderhead.tax_amt IS NULL 
		OR glob_rec_orderhead.freight_amt IS NULL 
		OR glob_rec_orderhead.cost_amt IS NULL 
		OR glob_rec_orderhead.hand_amt IS NULL 
		THEN 
			LET glob_line_info = "Order has nulls somewhere", glob_rec_orderhead.order_num, "Order amt", glob_rec_orderhead.total_amt, "tax ", glob_rec_orderhead.tax_amt, " frt ", 
			glob_rec_orderhead.freight_amt, " cost ", glob_rec_orderhead.cost_amt, " labour ", glob_rec_orderhead.hand_amt 
			CALL prob(glob_line_info) 
		END IF 

	END FOREACH 

	CLEAR screen 

	IF glob_problem = 1 
	THEN 
		FINISH REPORT ESV_rpt_list_ver 
		DISPLAY " DATABASE VERIFIED - PROBLEMS exist" at 16,10 
		attribute (magenta) 
		SLEEP 15 
	ELSE 
		DISPLAY " DATABASE VERIFIED - ALL ok" at 16,10 
		attribute (magenta) 
		SLEEP 15 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION verify()     
###########################################################################


###########################################################################
# FUNCTION prob(p_line1)      
#
# 
###########################################################################
FUNCTION prob(p_line1) 
	DEFINE p_line1 char(132) 
	DEFINE l_rpt_idx SMALLINT  #report array index

	IF glob_problem = 0 
	THEN 
		LET glob_problem = 1 
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"ESV_rpt_list_ver","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT AB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
	END IF 

	#---------------------------------------------------------
	OUTPUT TO REPORT ESV_rpt_list_ver(l_rpt_idx,
	p_line1)  
	#---------------------------------------------------------

 
END FUNCTION 
###########################################################################
# END FUNCTION prob(p_line1)      
###########################################################################