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

	Source code beautified by beautify.pl on 2019-12-31 14:28:30	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K1_GROUP_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 

FUNCTION update_sub(pr_sub_num) 
	DEFINE pr_sub_num INTEGER, 
	pr_tentsubhead RECORD LIKE tentsubhead.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_subschedule RECORD LIKE subschedule.*, 
	idx SMALLINT 


	DECLARE c_tsubhead CURSOR FOR 
	SELECT * INTO pr_subhead.* 
	FROM t_subhead 

	DECLARE c_tsubdetl CURSOR FOR 
	SELECT * FROM t_subdetl 
	WHERE sub_num = pr_sub_num 
	DECLARE c_tsubschedule CURSOR FOR 
	SELECT * FROM t_subschedule 
	WHERE sub_line_num = pr_subdetl.sub_line_num 
	AND sub_num = pr_subhead.sub_num 
	OPEN c_tsubhead 
	FETCH c_tsubhead 
	LET pr_tentsubhead.* = pr_subhead.* 

	DELETE FROM tentsubhead 
	WHERE sub_num = pr_sub_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DELETE FROM tentsubdetl 
	WHERE sub_num = pr_sub_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DELETE FROM tentsubschd 
	WHERE sub_num = pr_sub_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	INSERT INTO tentsubhead VALUES (pr_tentsubhead.*) 
	LET idx = 0 
	FOREACH c_tsubdetl INTO pr_subdetl.* 
		LET idx = idx + 1 
		LET pr_subdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subdetl.sub_num = pr_subhead.sub_num 
		FOREACH c_tsubschedule INTO pr_subschedule.* 
			LET pr_subschedule.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_subschedule.sub_num = pr_subhead.sub_num 
			LET pr_subschedule.sub_line_num = idx 
			INSERT INTO tentsubschd VALUES (pr_subschedule.*) 
		END FOREACH 
		LET pr_subdetl.sub_line_num = idx 
		INSERT INTO tentsubdetl VALUES (pr_subdetl.*) 
	END FOREACH 

END FUNCTION 


FUNCTION write_subs()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_subschedule RECORD LIKE subschedule.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_subhead RECORD LIKE subhead.*, 
	pr_sub_num INTEGER, 
	pr_corp_cust LIKE subhead.cust_code, 
	pr_output CHAR(60), 
	idx SMALLINT 

	OPEN WINDOW wka1 at 10,15 WITH 3 ROWS, 50 COLUMNS 
	attribute(border) 
	LET msgresp = kandoomsg("K",1017,"") 
	# Generating invoices please wait
	DISPLAY "Customer : " at 2,2 
	DISPLAY "Subscipt : " at 3,2 

	DECLARE c1_corpcust CURSOR WITH HOLD FOR 
	SELECT unique corp_cust_code INTO pr_corp_cust 
	FROM tentsubhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND corp_flag = "Y" 
	AND corp_cust_code IS NOT NULL 
	DECLARE c1_subhead CURSOR WITH HOLD FOR 
	SELECT * FROM tentsubhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND corp_flag = "Y" 
	AND corp_cust_code = pr_corp_cust 

	
		#"Corporate Subscription renewal")
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"K15_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT K15_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		LET glob_rpt_idx = l_rpt_idx #temporary until we move it to local scope
		#------------------------------------------------------------


	FOREACH c1_corpcust 
		DELETE FROM t_subhead WHERE 1=1 
		DELETE FROM t_invoicedetl WHERE 1=1 
		DELETE FROM t_subdetl WHERE 1=1 
		DELETE FROM t_subschedule WHERE 1=1 
		FOREACH c1_subhead INTO pr_subhead.* 
			INSERT INTO t_subhead VALUES ( pr_subhead.*) 
			INSERT INTO t_subdetl 
			SELECT * FROM tentsubdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			INSERT INTO t_subschedule 
			SELECT * FROM tentsubschd 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
		END FOREACH 
		LET pr_csubhead.* = pr_subhead.* 
		LET pr_csubhead.cust_code = pr_corp_cust 
		IF insert_sub() THEN 
			LET pr_sub_num = K11_write_sub("CORP") 
		END IF 
		DISPLAY pr_subhead.ship_name_text at 2,12 
		DISPLAY pr_sub_num at 3,12 
		FOREACH c1_subhead INTO pr_subhead.* 
			DELETE FROM tentsubdetl 
			WHERE sub_num = pr_subhead.sub_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM tentsubschd 
			WHERE sub_num = pr_subhead.sub_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END FOREACH 
		DELETE FROM tentsubhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND corp_flag = "Y" 
		AND corp_cust_code = pr_corp_cust 
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT K15_rpt_list
	CALL rpt_finish("K15_rpt_list")
	#------------------------------------------------------------

	 
	DECLARE c2_subhead CURSOR WITH HOLD FOR 
	SELECT * FROM tentsubhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOREACH c2_subhead INTO pr_subhead.* 
		DELETE FROM t_subhead WHERE 1=1 
		DELETE FROM t_invoicedetl WHERE 1=1 
		DELETE FROM t_subdetl WHERE 1=1 
		DELETE FROM t_subschedule WHERE 1=1 
		INSERT INTO t_subhead VALUES ( pr_subhead.*) 
		INSERT INTO t_subdetl 
		SELECT * FROM tentsubdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		INSERT INTO t_subschedule 
		SELECT * FROM tentsubschd 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		IF insert_sub() THEN 
			LET pr_sub_num = K11_write_sub("ADD") 
		END IF 
		DISPLAY pr_subhead.ship_name_text at 2,12 
		DISPLAY pr_sub_num at 3,12 
		DELETE FROM tentsubhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DELETE FROM tentsubdetl 
		WHERE sub_num = pr_subhead.sub_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DELETE FROM tentsubschd 
		WHERE sub_num = pr_subhead.sub_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END FOREACH 
	CLOSE WINDOW wka1 

END FUNCTION 


REPORT KA1_rpt_list_error(p_rpt_idx,err_message,pr_subhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_subhead RECORD LIKE subhead.*, 
	err_message CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = "KA1 Invoice Generation Error log" 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 

			PRINT COLUMN 1, rpt_date, 
			COLUMN offset1, line1 clipped, 
			COLUMN 120, "Page: ", pageno USING "####" 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Subscription", 
			COLUMN 25,"Error message" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
		ON EVERY ROW 
			PRINT COLUMN 1, pr_subhead.cust_code, 
			COLUMN 10,pr_subhead.sub_num USING "#########", 
			COLUMN 25,err_message clipped 

		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KA1 ERROR LOG *****" 

END REPORT 

REPORT KA1_rpt_list_subscription (p_rpt_idx,pr_subhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_subhead RECORD LIKE subhead.*, 
	pr_desc CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Invoice", 
			COLUMN 25,"Description", 
			COLUMN 90,"Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, pr_subhead.cust_code, 
			COLUMN 10,pr_subhead.sub_num USING "#########", 
			COLUMN 25,pr_subhead.ship_name_text clipped, 
			COLUMN 85,pr_subhead.total_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KA1 INVOICE LOG *****" 
END REPORT 
