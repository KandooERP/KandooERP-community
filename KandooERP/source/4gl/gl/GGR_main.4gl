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
GLOBALS "../gl/GGR_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_structure RECORD LIKE structure.*
	DEFINE modu_rec_coa RECORD LIKE coa.*
	DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE modu_rec_glsumdiv RECORD LIKE glsumdiv.*
	DEFINE modu_rec_glsummary RECORD LIKE glsummary.* 
	DEFINE modu_rec_glsumblock RECORD LIKE glsumblock.* 
	DEFINE modu_rec_data RECORD 
		cmpy_code LIKE accounthist.cmpy_code, 
		chart LIKE accounthist.acct_code, 
		acct_desc LIKE coa.desc_text, 
		block_code LIKE glsumblock.block_code, 
		block_desc LIKE glsumblock.desc_text, 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		summary_code LIKE glsummary.summary_code, 
		summary_desc LIKE glsummary.desc_text, 
		print_order LIKE glsummary.print_order, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD
	DEFINE modu_idx SMALLINT
	DEFINE modu_i SMALLINT
	 
	DEFINE modu_line1 CHAR(80)
	DEFINE modu_line2 CHAR(80)
	DEFINE modu_line3 CHAR(80)
	DEFINE modu_line4 CHAR(80)
	 
	DEFINE modu_query_text CHAR(200) 
	DEFINE modu_where_text CHAR(200) 
	DEFINE modu_arr_rec_temp array[4] OF RECORD 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE modu_rec_temp RECORD 
		total_code LIKE glsumblock.total_code, 
		total_seq LIKE glsumdiv.pos_code, 
		col1_amt LIKE accounthist.debit_amt, 
		col2_amt LIKE accounthist.debit_amt, 
		col3_amt LIKE accounthist.debit_amt, 
		col4_amt LIKE accounthist.debit_amt, 
		col5_amt LIKE accounthist.debit_amt, 
		col6_amt LIKE accounthist.debit_amt, 
		col7_amt LIKE accounthist.debit_amt, 
		col8_amt LIKE accounthist.debit_amt, 
		col9_amt LIKE accounthist.debit_amt 
	END RECORD 
	DEFINE modu_line_total DECIMAL(16,2) 
	DEFINE modu_arr_column array[9] OF RECORD 
		desc_text LIKE glsumdiv.desc_text 
	END RECORD 


############################################################
# MAIN
#
# GGR.4gl GL Segment Summary Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("GGR") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GGR_main()
END MAIN