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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E3_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E31_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_doit char(1) 
DEFINE modu_start_product, modu_end_product char(15) 
DEFINE modu_start_warehouse, modu_end_warehouse char(3) 
DEFINE modu_days_forward SMALLINT 
############################################################
# FUNCTION E31_main()
#
# E31 - Back Order Allocation
############################################################
FUNCTION E31_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E31") 

	WHILE get_info() 
	END WHILE 
 
END FUNCTION 
###########################################################################
# END FUNCTION E31_main()  
###########################################################################

############################################################
# FUNCTION get_info() 
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_counter SMALLINT
	
	OPEN WINDOW E418 with FORM "E418" 
	 CALL windecoration_e("E418") -- albo kd-755 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1020,"Back Order") #1020 Enter Back Order Details; OK TO Continue.
	INPUT 
		modu_start_product, 
		modu_end_product, 
		modu_start_warehouse, 
		modu_end_warehouse, 
		modu_days_forward WITHOUT DEFAULTS 
	FROM
		start_product, 
		end_product, 
		start_warehouse, 
		end_warehouse, 
		days_forward ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E31","input-pr_start_product-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "LOOKUP"  infield(start_product) 
					LET modu_start_product = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_start_product TO start_product

					NEXT FIELD start_product
					 
		ON ACTION "LOOKUP" infield(end_product) 
					LET modu_end_product = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_end_product TO end_product 

					NEXT FIELD end_product
					 
		ON ACTION "LOOKUP" infield(start_warehouse) 
					LET modu_start_warehouse = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_start_warehouse TO start_warehouse

					NEXT FIELD start_warehouse
					 
		ON ACTION "LOOKUP" infield(end_warehouse) 
					LET modu_end_warehouse = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_end_warehouse TO end_warehouse 

					NEXT FIELD end_warehouse 

		AFTER FIELD start_product 
			IF modu_start_product IS NULL THEN 
				LET modu_start_product = " " 
				DISPLAY modu_start_product TO start_product 
			END IF 

		AFTER FIELD end_product 
			IF modu_end_product IS NULL THEN 
				LET modu_end_product = "zzzzzzzzzzzzzzz" 
				DISPLAY modu_end_product TO end_product

			END IF 

		AFTER FIELD start_warehouse 
			IF modu_start_warehouse IS NULL THEN 
				LET modu_start_warehouse = " " 
				DISPLAY modu_start_warehouse TO start_warehouse
			END IF 

		AFTER FIELD end_warehouse 
			IF modu_end_warehouse IS NULL THEN 
				LET modu_end_warehouse = "zzz" 
				DISPLAY modu_end_warehouse TO end_warehouse

			END IF 

		AFTER FIELD days_forward 
			IF modu_days_forward IS NULL THEN 
				LET modu_days_forward = 0 
				DISPLAY modu_days_forward TO days_forware

			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_start_product IS NULL THEN 
					LET modu_start_product = " " 
				END IF 
				IF modu_end_product IS NULL THEN 
					LET modu_end_product = "zzzzzzzzzzzzzzz" 
				END IF 
				IF modu_start_warehouse IS NULL THEN 
					LET modu_start_warehouse = " " 
				END IF 
				IF modu_end_warehouse IS NULL THEN 
					LET modu_end_warehouse = "zzz" 
				END IF 
				IF modu_days_forward IS NULL THEN 
					LET modu_days_forward = 0 
				END IF 
				
				DISPLAY modu_start_product TO start_product 
				DISPLAY modu_end_product TO end_product 
				DISPLAY modu_start_warehouse TO start_warehouse 
				DISPLAY modu_end_warehouse TO end_warehouse 
				DISPLAY modu_days_forward TO days_forward

			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF
	
	SELECT count(*) INTO l_counter FROM backorder 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code between modu_start_warehouse AND modu_end_warehouse 
	IF l_counter > 0 THEN 
	 
		IF promptTF("",kandoomsg2("E",8034,""),1) THEN	#8034 Confirm TO Process Back Order Allocations?
			IF check_backorder() THEN 
				CALL process_backorder() 
			END IF 
		END IF
	ELSE
		ERROR "No Backorders found"	 
	END IF
	CLOSE WINDOW E418
		
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION get_info()   
###########################################################################


############################################################
# FUNCTION check_backorder()   
#
#
############################################################
FUNCTION check_backorder() 
	DEFINE l_counter SMALLINT 

	SELECT count(*) INTO l_counter FROM backorder 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code between modu_start_warehouse AND modu_end_warehouse 
	IF l_counter > 0 THEN 
		IF promptTF("",kandoomsg2("E",8009,""),1) THEN	#8009 Confirm TO Delete Existing Back Order Entries?
			DELETE FROM backorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code >= modu_start_warehouse 
			AND ware_code <= modu_end_warehouse
			RETURN TRUE  
		ELSE 
			RETURN FALSE 
		END IF 
	ELSE
		ERROR "No backorders found"
		RETURN FALSE 		
	END IF 
--	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION check_backorder()   
###########################################################################


############################################################
# FUNCTION process_backorder()  
#
#
############################################################
FUNCTION process_backorder() 
	DEFINE l_rec_orderdetl RECORD 
		cmpy_code char(2), 
		part_code char(15), 
		ware_code char(3), 
		cust_code char(8), 
		order_num INTEGER, 
		line_num SMALLINT, 
		order_date DATE, 
		back_qty decimal(8,2) 
	END RECORD 
	DEFINE l_rec_backorder RECORD LIKE backorder.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_tran_qty LIKE prodstatus.back_qty 
	DEFINE l_prod_avail decimal(10,2) 

	DECLARE c_prodstatus cursor FOR 
	SELECT unique * FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code between modu_start_product AND modu_end_product 
	AND ware_code between modu_start_warehouse AND modu_end_warehouse 
	AND onhand_qty - reserved_qty > 0 
	AND back_qty > 0 
	--   OPEN WINDOW w1 AT 4,15 with 3 rows, 30 columns  -- albo  KD-755
	--      ATTRIBUTE(border)
	FOREACH c_prodstatus INTO l_rec_prodstatus.* 
		DISPLAY "" at 2,2 
		DISPLAY " Product: ", l_rec_prodstatus.part_code at 2,2 

		### Take stock transfers INTO account
		SELECT sum(d.back_qty) INTO l_tran_qty 
		FROM ibtdetl d, ibthead h 
		WHERE h.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND d.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND d.trans_num = h.trans_num 
		AND h.from_ware_code = l_rec_prodstatus.ware_code 
		AND d.part_code = l_rec_prodstatus.part_code 
		AND d.back_qty > 0 
		AND h.status_ind in ("U","P") 
		IF l_tran_qty IS NULL THEN 
			LET l_tran_qty = 0 
		END IF 
		LET l_prod_avail = l_rec_prodstatus.onhand_qty - 
		(l_rec_prodstatus.reserved_qty + l_tran_qty) 
		DECLARE c_orderdetl cursor FOR 
		SELECT unique l.cmpy_code, l.part_code, l.ware_code, l.cust_code, 
		l.order_num, l.line_num, o.order_date, l.back_qty 
		FROM orderdetl l, orderhead o, customer c 
		WHERE l.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND l.part_code = l_rec_prodstatus.part_code 
		AND l.ware_code = l_rec_prodstatus.ware_code 
		AND l.back_qty > 0 
		AND o.order_date <= today + modu_days_forward 
		AND o.cmpy_code = l.cmpy_code 
		AND o.cust_code = l.cust_code 
		AND o.order_num = l.order_num 
		AND c.cmpy_code = l.cmpy_code 
		AND c.cust_code = l.cust_code 
		AND o.hold_code IS NULL 
		ORDER BY o.order_date 

		FOREACH c_orderdetl INTO l_rec_orderdetl.* 
			--DISPLAY "" at 2,2 
			--DISPLAY " Order: ", l_rec_orderdetl.order_num at 2,2 

			--DISPLAY "" at 3,2 
			--DISPLAY " Available: ", l_prod_avail at 3,2 

			LET l_rec_backorder.cmpy_code = l_rec_orderdetl.cmpy_code 
			LET l_rec_backorder.part_code = l_rec_orderdetl.part_code 
			LET l_rec_backorder.ware_code = l_rec_orderdetl.ware_code 
			LET l_rec_backorder.cust_code = l_rec_orderdetl.cust_code 
			LET l_rec_backorder.order_num = l_rec_orderdetl.order_num 
			LET l_rec_backorder.line_num = l_rec_orderdetl.line_num 
			LET l_rec_backorder.order_date= l_rec_orderdetl.order_date 
			LET l_rec_backorder.avail_qty = l_prod_avail 
			LET l_rec_backorder.req_qty = l_rec_orderdetl.back_qty 
			IF l_prod_avail > l_rec_orderdetl.back_qty THEN 
				LET l_rec_backorder.alloc_qty = l_rec_orderdetl.back_qty 
			ELSE 
				IF l_prod_avail <= 0 THEN 
					LET l_rec_backorder.alloc_qty = 0 
				ELSE 
					LET l_rec_backorder.alloc_qty = l_prod_avail 
				END IF 
			END IF 
			LET l_prod_avail = l_prod_avail - l_rec_orderdetl.back_qty
			 
			INSERT INTO backorder VALUES ( l_rec_backorder.*) 
			IF status < 0 THEN 
				CALL errorlog("E31 Back ORDER INSERT failed") 
				ERROR kandoomsg2("E",9262,"") 				#9262 "Back ORDER INSERT failed"
				RETURN 
			END IF
			 
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				IF kandoomsg("U",8023,"") = "N" THEN 
					RETURN 
				END IF 
			END IF 
		END FOREACH 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			IF kandoomsg("U",8023,"") = "N" THEN 
				RETURN 
			END IF 
		END IF
		 
	END FOREACH 
END FUNCTION
###########################################################################
# FUNCTION process_backorder()   
###########################################################################