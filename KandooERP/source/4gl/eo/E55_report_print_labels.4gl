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
GLOBALS "../eo/E55_GLOBALS.4gl"
###########################################################################
# REPORT E55_rpt_list_print_labels(p_rpt_idx,p_cmpy,p_kandoouser_sign_on_code,p_where_text)
#
# module E55a - Prepare AND PRINT shipping label(s) FOR required FORMAT
###########################################################################
REPORT E55_rpt_list_print_labels(p_rpt_idx,p_cmpy,p_kandoouser_sign_on_code,p_where_text)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code #huho NOT used 
	DEFINE p_where_text char(300) 
	DEFINE l_buff_idx SMALLINT 
	DEFINE l_arr_rec_lab_buff array[2] OF RECORD 
		cust_code LIKE invoicehead.cust_code, 
		ord_num LIKE invoicehead.ord_num, 
		name_text LIKE invoicehead.name_text, 
		addr1_text LIKE invoicehead.addr1_text, 
		addr2_text LIKE invoicehead.addr2_text, 
		city_text LIKE invoicehead.city_text, 
		post_code LIKE invoicehead.post_code, 
		state_code LIKE invoicehead.state_code, 
		label_text char(8) 
	END RECORD 
	DEFINE l_print_code LIKE warehouse.ship_print_code 
	DEFINE l_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_query_text char(400) 
	DEFINE i SMALLINT 

	OUTPUT 
--	left margin 0 
--	top margin 2 
--	bottom margin 0 
--	PAGE length 18 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		ON EVERY ROW 
			LET l_buff_idx = 1 
			LET l_query_text = 
			"SELECT * ", 
			"FROM despatchdetl ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND ",p_where_text clipped," " 
			PREPARE s_despatchdetl FROM l_query_text 
			DECLARE c_despatchdetl cursor FOR s_despatchdetl 

			FOREACH c_despatchdetl INTO l_rec_despatchdetl.* 
				IF l_rec_despatchdetl.invoice_num IS NOT NULL THEN 
					SELECT * 
					INTO l_rec_invoicehead.* 
					FROM invoicehead 
					WHERE cmpy_code = l_rec_despatchdetl.cmpy_code 
					AND inv_num = l_rec_despatchdetl.invoice_num 
				ELSE 
					DECLARE c2_orders cursor FOR 
					SELECT * INTO l_rec_orderhead.* 
					FROM orderhead 
					WHERE cmpy_code = p_cmpy 
					AND order_num in 
					(select pd.order_num 
					FROM pickdetl pd,pickhead ph 
					WHERE pd.cmpy_code = l_rec_despatchdetl.cmpy_code 
					AND ph.cmpy_code = l_rec_despatchdetl.cmpy_code 
					AND ph.pick_num = l_rec_despatchdetl.pick_num 
					AND pd.pick_num = ph.pick_num 
					AND ph.carrier_code = l_rec_despatchdetl.carrier_code 
					AND ph.ware_code = pd.ware_code) 
					OPEN c2_orders 
					FETCH c2_orders 
					CLOSE c2_orders 
					LET l_rec_invoicehead.cust_code = l_rec_orderhead.cust_code 
					LET l_rec_invoicehead.name_text = l_rec_orderhead.ship_name_text 
					LET l_rec_invoicehead.addr1_text = l_rec_orderhead.ship_addr1_text 
					LET l_rec_invoicehead.addr2_text = l_rec_orderhead.ship_addr2_text 
					LET l_rec_invoicehead.city_text = l_rec_orderhead.ship_city_text 
					LET l_rec_invoicehead.state_code = l_rec_orderhead.state_code 
					LET l_rec_invoicehead.post_code = l_rec_orderhead.post_code 
					LET l_rec_invoicehead.country_code = l_rec_orderhead.country_code --@db-patch_2020_10_04--
					LET l_rec_invoicehead.ord_num = l_rec_orderhead.order_num 
				END IF
				 
				DECLARE c_warehouse cursor FOR 
				SELECT w.ship_print_code INTO l_print_code 
				FROM warehouse w,despatchhead d 
				WHERE w.cmpy_code = l_rec_despatchdetl.cmpy_code 
				AND d.cmpy_code = l_rec_despatchdetl.cmpy_code 
				AND d.manifest_num = l_rec_despatchdetl.manifest_num 
				AND d.carrier_code = l_rec_despatchdetl.carrier_code 
				AND w.ware_code = d.ware_code 
				OPEN c_warehouse 
				FETCH c_warehouse 
				CLOSE c_warehouse 
				INITIALIZE l_rec_printcodes.* TO NULL 
				SELECT * INTO l_rec_printcodes.* 
				FROM printcodes 
				WHERE print_code = l_print_code
				 
				FOR i = 1 TO l_rec_despatchdetl.despatch_qty 
					CASE l_buff_idx 
						WHEN 2 
							LET l_arr_rec_lab_buff[l_buff_idx].cust_code = l_rec_invoicehead.cust_code 
							LET l_arr_rec_lab_buff[l_buff_idx].ord_num = l_rec_invoicehead.ord_num 
							LET l_arr_rec_lab_buff[l_buff_idx].name_text = l_rec_invoicehead.name_text 
							LET l_arr_rec_lab_buff[l_buff_idx].addr1_text = l_rec_invoicehead.addr1_text 
							LET l_arr_rec_lab_buff[l_buff_idx].addr2_text = l_rec_invoicehead.addr2_text 
							LET l_arr_rec_lab_buff[l_buff_idx].city_text = l_rec_invoicehead.city_text 
							LET l_arr_rec_lab_buff[l_buff_idx].post_code = l_rec_invoicehead.post_code 
							LET l_arr_rec_lab_buff[l_buff_idx].state_code = l_rec_invoicehead.state_code 
							LET l_arr_rec_lab_buff[l_buff_idx].label_text = i USING "##"," OF ",	l_rec_despatchdetl.despatch_qty USING "##" 
							PRINT COLUMN 33, l_arr_rec_lab_buff[1].cust_code clipped,"/", 	l_arr_rec_lab_buff[1].ord_num USING "&&&&&&&&", 
								COLUMN 84, l_arr_rec_lab_buff[2].cust_code clipped,"/", 		l_arr_rec_lab_buff[2].ord_num USING "&&&&&&&&" 
							PRINT COLUMN 05, l_arr_rec_lab_buff[1].name_text, 	
								COLUMN 56, l_arr_rec_lab_buff[2].name_text 
							PRINT COLUMN 05, l_arr_rec_lab_buff[1].addr1_text, 
								COLUMN 56, l_arr_rec_lab_buff[2].addr1_text 
							PRINT COLUMN 05, l_arr_rec_lab_buff[1].addr2_text, 
								COLUMN 56, l_arr_rec_lab_buff[2].addr2_text 
							PRINT COLUMN 05, l_arr_rec_lab_buff[1].city_text, 
								COLUMN 45, l_arr_rec_lab_buff[1].post_code clipped, 
								COLUMN 56, l_arr_rec_lab_buff[2].city_text, 
								COLUMN 96, l_arr_rec_lab_buff[2].post_code clipped
								 
							IF l_rec_printcodes.compress_11 IS NOT NULL THEN 
								PRINT ascii(l_rec_printcodes.compress_11), 
								ascii(l_rec_printcodes.compress_12), 
								ascii(l_rec_printcodes.compress_13), 
								ascii(l_rec_printcodes.compress_14), 
								ascii(l_rec_printcodes.compress_15), 
								ascii(l_rec_printcodes.compress_16), 
								ascii(l_rec_printcodes.compress_17), 
								ascii(l_rec_printcodes.compress_18), 
								ascii(l_rec_printcodes.compress_19), 
								ascii(l_rec_printcodes.compress_20), 
								COLUMN 01,l_arr_rec_lab_buff[1].state_code clipped, 
								COLUMN 40,l_arr_rec_lab_buff[2].state_code clipped 
								PRINT ascii(l_rec_printcodes.normal_1), 
								ascii(l_rec_printcodes.normal_2), 
								ascii(l_rec_printcodes.normal_3), 
								ascii(l_rec_printcodes.normal_4), 
								ascii(l_rec_printcodes.normal_5), 
								ascii(l_rec_printcodes.normal_6), 
								ascii(l_rec_printcodes.normal_7), 
								ascii(l_rec_printcodes.normal_8), 
								ascii(l_rec_printcodes.normal_9), 
								ascii(l_rec_printcodes.normal_10), 
								COLUMN 39, l_arr_rec_lab_buff[1].label_text clipped, 
								COLUMN 90, l_arr_rec_lab_buff[2].label_text clipped 
							ELSE 
								PRINT COLUMN 05,l_arr_rec_lab_buff[1].state_code clipped, 
								COLUMN 56,l_arr_rec_lab_buff[2].state_code clipped 
								PRINT COLUMN 39, l_arr_rec_lab_buff[1].label_text, 
								COLUMN 90, l_arr_rec_lab_buff[2].label_text 
							END IF 
							SKIP TO top OF PAGE 
							FOR l_buff_idx = 1 TO 2 
								INITIALIZE l_arr_rec_lab_buff[l_buff_idx].* TO NULL 
							END FOR 
							LET l_buff_idx = 1 

						OTHERWISE 
							LET l_arr_rec_lab_buff[l_buff_idx].cust_code = l_rec_invoicehead.cust_code 
							LET l_arr_rec_lab_buff[l_buff_idx].ord_num = l_rec_invoicehead.ord_num 
							LET l_arr_rec_lab_buff[l_buff_idx].name_text = l_rec_invoicehead.name_text 
							LET l_arr_rec_lab_buff[l_buff_idx].addr1_text = l_rec_invoicehead.addr1_text 
							LET l_arr_rec_lab_buff[l_buff_idx].addr2_text = l_rec_invoicehead.addr2_text 
							LET l_arr_rec_lab_buff[l_buff_idx].city_text = l_rec_invoicehead.city_text 
							LET l_arr_rec_lab_buff[l_buff_idx].state_code = l_rec_invoicehead.state_code 
							LET l_arr_rec_lab_buff[l_buff_idx].post_code = l_rec_invoicehead.post_code 
							LET l_arr_rec_lab_buff[l_buff_idx].label_text = i USING "##", " of ", 
							l_rec_despatchdetl.despatch_qty USING "##" 
							LET l_buff_idx = l_buff_idx + 1 
					END CASE 
				END FOR 
			END FOREACH 
			
			IF l_buff_idx > 1 THEN 
				PRINT COLUMN 33, l_arr_rec_lab_buff[1].cust_code clipped,"/",	l_arr_rec_lab_buff[1].ord_num USING "&&&&&&&&", 
					COLUMN 84, l_arr_rec_lab_buff[2].cust_code clipped,"/",	l_arr_rec_lab_buff[2].ord_num USING "&&&&&&&&" 
				PRINT COLUMN 05, l_arr_rec_lab_buff[1].name_text, 
					COLUMN 56, l_arr_rec_lab_buff[2].name_text 
				PRINT COLUMN 05, l_arr_rec_lab_buff[1].addr1_text, 
					COLUMN 56, l_arr_rec_lab_buff[2].addr1_text 
				PRINT COLUMN 05, l_arr_rec_lab_buff[1].addr2_text, 
					COLUMN 56, l_arr_rec_lab_buff[2].addr2_text 
				PRINT COLUMN 05, l_arr_rec_lab_buff[1].city_text, 
					COLUMN 45, l_arr_rec_lab_buff[1].post_code clipped, 
					COLUMN 56, l_arr_rec_lab_buff[2].city_text, 
					COLUMN 96, l_arr_rec_lab_buff[2].post_code clipped 
				
				IF l_rec_printcodes.compress_11 IS NOT NULL THEN 
					PRINT ascii(l_rec_printcodes.compress_11), 
					ascii(l_rec_printcodes.compress_12), 
					ascii(l_rec_printcodes.compress_13), 
					ascii(l_rec_printcodes.compress_14), 
					ascii(l_rec_printcodes.compress_15), 
					ascii(l_rec_printcodes.compress_16), 
					ascii(l_rec_printcodes.compress_17), 
					ascii(l_rec_printcodes.compress_18), 
					ascii(l_rec_printcodes.compress_19), 
					ascii(l_rec_printcodes.compress_20),					 
						COLUMN 01,l_arr_rec_lab_buff[1].state_code clipped, 
						COLUMN 40,l_arr_rec_lab_buff[2].state_code clipped 
					PRINT ascii(l_rec_printcodes.normal_1), ascii(l_rec_printcodes.normal_2), 
					ascii(l_rec_printcodes.normal_3), ascii(l_rec_printcodes.normal_4), 
					ascii(l_rec_printcodes.normal_5), ascii(l_rec_printcodes.normal_6), 
					ascii(l_rec_printcodes.normal_7), ascii(l_rec_printcodes.normal_8), 
					ascii(l_rec_printcodes.normal_9), ascii(l_rec_printcodes.normal_10), 
						COLUMN 39, l_arr_rec_lab_buff[1].label_text clipped, 
						COLUMN 90, l_arr_rec_lab_buff[2].label_text clipped 
				ELSE 
					PRINT COLUMN 05,l_arr_rec_lab_buff[1].state_code clipped, 
						COLUMN 56,l_arr_rec_lab_buff[2].state_code clipped 
					PRINT COLUMN 39, l_arr_rec_lab_buff[1].label_text, 
						COLUMN 90, l_arr_rec_lab_buff[2].label_text 
				END IF 
				SKIP TO top OF PAGE 
			END IF 
			
			FOR l_buff_idx = 1 TO 2 
				INITIALIZE l_arr_rec_lab_buff[l_buff_idx] TO NULL 
			END FOR 
END REPORT
###########################################################################
# END REPORT E55_rpt_list_print_labels(p_rpt_idx,p_cmpy,p_kandoouser_sign_on_code,p_where_text)
###########################################################################