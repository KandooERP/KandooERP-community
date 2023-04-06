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
GLOBALS "../eo/ET_GROUP_GLOBALS.4gl"
GLOBALS "../eo/ET8_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_rec_statparms RECORD LIKE statparms.* 
	DEFINE modu_rec_statint RECORD LIKE statint.* 
	DEFINE modu_arr_rec_interval array[12] OF RECORD 
		int_text char(8), 
		year_num LIKE statint.year_num, 
		int_num LIKE statint.int_num, 
		cust_cnt SMALLINT, 
		sales_qty LIKE statsale.sales_qty, 
		net_amt LIKE statsale.net_amt, 
		sell_cust_cnt SMALLINT, 
		sell_sales_qty LIKE statsale.sales_qty, 
		sell_net_amt LIKE statsale.net_amt, 
		rpt_sales_qty LIKE statsale.sales_qty, 
		rpt_net_amt LIKE statsale.net_amt 
	END RECORD 
	DEFINE modu_temp_text char(500) 
	DEFINE modu_order_ind char(1) 
###########################################################################
# MAIN 
#
# ET8 - New Vs Repeat Sales Report
###########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET8") -- albo 
	CALL ui_init(0) 	#Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init e/eo module
	CALL ET8_main()
END MAIN