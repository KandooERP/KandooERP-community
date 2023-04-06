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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_rec_structure RECORD LIKE structure.* 
DEFINE modu_rec_reporthead RECORD LIKE reporthead.* 
DEFINE modu_rec_reportdetl RECORD LIKE reportdetl.* 
DEFINE modu_rec_account RECORD LIKE account.* 
DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
DEFINE modu_rec_accountcur RECORD LIKE accountcur.* 
DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.* 
DEFINE modu_rec_saved_values RECORD 
	saved_num INTEGER, 
	saved_amt money(15,2) 
END RECORD

DEFINE modu_seg_length LIKE structure.length_num 
--	DEFINE modu_select_cmpy CHAR(2) 
DEFINE modu_q1_text CHAR(500) 
--DEFINE modu_query_text CHAR(900) 
DEFINE modu_runner CHAR(900) #huho - this has TO go... 
DEFINE modu_rep_wid SMALLINT
--DEFINE modu_where_part CHAR(1200) 
DEFINE modu_line CHAR(360) 
--	DEFINE modu_rpt_name CHAR(60) 
--	DEFINE modu_show_name CHAR(48) 
DEFINE modu_line_amt money(15,2) 

DEFINE modu_rec_linebuild RECORD 
	column_num SMALLINT, 
	label_text CHAR(20), 
	print_amt DECIMAL(15,2), 
	col_info CHAR(1) 
END RECORD
-- DEFINE	modu_rep_name CHAR(7)
DEFINE modu_segment_text CHAR(50)
DEFINE modu_rpt_note LIKE rmsreps.report_text

DEFINE modu_tot_cb money(15,2)
DEFINE modu_tot_a1 money(15,2)
 
DEFINE modu_tot_a2 money(15,2)
DEFINE modu_tot_a3 money(15,2)
DEFINE modu_tot_a4 money(15,2)
 
DEFINE modu_tot_pa money(15,2) 
DEFINE modu_tot_p1 money(15,2) 

DEFINE modu_tot_p2 money(15,2)
DEFINE modu_tot_p3 money(15,2)
DEFINE modu_tot_p4 money(15,2)

DEFINE modu_tot_yp money(15,2)
DEFINE modu_tot_y1 money(15,2)

DEFINE modu_tot_y2 money(15,2)
DEFINE modu_tot_y3 money(15,2)
DEFINE modu_tot_y4 money(15,2)

DEFINE modu_tot_a5 money(15,2)
DEFINE modu_tot_a6 money(15,2)

DEFINE modu_tot_p5 money(15,2)
DEFINE modu_tot_p6 money(15,2)
DEFINE modu_tot_y5 money(15,2)


DEFINE modu_tot_y6 money(15,2)
DEFINE modu_tot_ps money(15,2)
DEFINE modu_tot_ys money(15,2)
 
DEFINE modu_tot_yr money(15,2)
DEFINE modu_tot_pr money(15,2)
 
DEFINE modu_last_start LIKE account.acct_code 
DEFINE modu_last_end LIKE account.acct_code 
DEFINE modu_start_acct LIKE account.acct_code 

DEFINE modu_end_acct LIKE account.acct_code
--	DEFINE modu_select_acct LIKE account.acct_code

DEFINE modu_last_flex_code LIKE reportdetl.flex_code 
DEFINE modu_retcode INTEGER
DEFINE modu_start_save INTEGER
DEFINE modu_end_save INTEGER
 
DEFINE modu_msgresp CHAR(1)
DEFINE modu_night_shift CHAR(1)
DEFINE modu_background CHAR(1)

DEFINE modu_displays CHAR(1)
DEFINE modu_zero_suppress CHAR(1)
 
DEFINE modu_sign CHAR(1)
DEFINE modu_repeat CHAR(1)
DEFINE modu_acct_type CHAR(1)

DEFINE modu_life_type CHAR(1)
DEFINE modu_curr_type CHAR(1)
 
DEFINE modu_lengther SMALLINT 
DEFINE modu_startpos SMALLINT 
DEFINE modu_endpos SMALLINT 

--	DEFINE modu_idx SMALLINT
	DEFINE modu_old_sa SMALLINT

	DEFINE modu_dropit SMALLINT
	DEFINE modu_old_sn SMALLINT

	DEFINE modu_save_year SMALLINT 
	DEFINE modu_col SMALLINT 
	DEFINE modu_nogo SMALLINT 

	DEFINE modu_save_per SMALLINT 
	DEFINE modu_dum_per SMALLINT 
	DEFINE modu_counter SMALLINT 

	DEFINE modu_rpt_year SMALLINT
	DEFINE modu_show_per SMALLINT
	DEFINE modu_rpt_per SMALLINT
 
		
	DEFINE modu_period SMALLINT
	DEFINE modu_pagenumb SMALLINT
	DEFINE modu_len SMALLINT
	 
--	DEFINE modu_numargs SMALLINT	 
DEFINE modu_thisdate DATE
--	DEFINE glob_show_date DATE

DEFINE modu_tempstr CHAR(30) 
DEFINE modu_high_ref DECIMAL(5,2) 
DEFINE modu_errmsg CHAR(50)
DEFINE i SMALLINT
	 
############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GS1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GS1_main()
END MAIN