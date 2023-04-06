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
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl" 

############################################################
# REPORT E52_rpt_list_flat_file(p_rec_pickhead) 
#
#
############################################################
REPORT E52_rpt_list_flat_file(p_rec_pickhead) 
	DEFINE p_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_delim char(1) 

	OUTPUT 
--	PAGE length 1 
	FORMAT 

		ON EVERY ROW 
			LET l_delim = '|' 
			## need TO know first ORDER num of shipment FOR delivery date
			DECLARE c_pickhead1 cursor FOR 
			SELECT order_num FROM pickdetl 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND ware_code = p_rec_pickhead.ware_code 
			AND pick_num = p_rec_pickhead.pick_num 

			OPEN c_pickhead1 
			FETCH c_pickhead1 INTO l_order_num 
			SELECT * INTO l_rec_orderhead.* FROM orderhead 
			WHERE cmpy_code = p_rec_pickhead.cmpy_code 
			AND order_num = l_order_num 

			PRINT COLUMN 01, '1', l_delim, 
			COLUMN 03, p_rec_pickhead.batch_num USING "#######", 
			COLUMN 10, l_delim, 
			COLUMN 11, p_rec_pickhead.pick_num USING "#######", 
			COLUMN 18, l_delim, 
			COLUMN 19, l_rec_orderhead.ship_date USING 'ddmmyyyy', 
			COLUMN 27, l_delim, 
			COLUMN 28, p_rec_pickhead.cust_code 

			DECLARE c_pickdetl_fl cursor FOR 
			SELECT pickdetl.* 
			FROM pickdetl 
			WHERE pickdetl.cmpy_code = p_rec_pickhead.cmpy_code 
			AND pickdetl.ware_code = p_rec_pickhead.ware_code 
			AND pickdetl.pick_num = p_rec_pickhead.pick_num 
			ORDER BY pickdetl.part_code 

			FOREACH c_pickdetl_fl INTO l_rec_pickdetl.* 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE cmpy_code = p_rec_pickhead.cmpy_code 
				AND part_code = l_rec_pickdetl.part_code 
				PRINT COLUMN 01, '2', l_delim, 
				COLUMN 03, p_rec_pickhead.batch_num USING "#######", 
				COLUMN 10, l_delim, 
				COLUMN 11, p_rec_pickhead.pick_num USING "#######", 
				COLUMN 18, l_delim, 
				COLUMN 19, l_rec_pickdetl.part_code[1,8], 
				COLUMN 27, l_delim, 
				COLUMN 28, l_rec_product.short_desc_text[1,10], 
				COLUMN 38, l_delim, 
				COLUMN 39, l_rec_product.desc_text, 
				COLUMN 69, l_delim, 
				COLUMN 70, l_rec_product.desc2_text[1,3], 
				COLUMN 73, l_delim, 
				COLUMN 74, l_rec_product.desc2_text[5,9], 
				COLUMN 79, l_delim, 
				COLUMN 80, l_rec_product.desc2_text[14,23], 
				COLUMN 90, l_delim, 
				COLUMN 91, l_rec_product.desc2_text[11,12], 
				COLUMN 93, l_delim, 
				COLUMN 94, l_rec_pickdetl.picked_qty USING "-----&", 
				COLUMN 100, l_delim, 
				COLUMN 101, l_rec_product.vend_code, 
				COLUMN 109, l_delim, 
				COLUMN 110, l_rec_pickdetl.order_num USING "########", 
				COLUMN 118, l_delim, 
				COLUMN 119, l_rec_pickdetl.order_line_num USING "####" 
			END FOREACH 

END REPORT
############################################################
# END REPORT E52_rpt_list_flat_file(p_rec_pickhead) 
############################################################