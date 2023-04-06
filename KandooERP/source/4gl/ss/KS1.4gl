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
GLOBALS "../ss/K_SS_GLOBALS.4gl"
GLOBALS "../ss/KR_GROUP_GLOBALS.4gl" 
GLOBALS "../ss/KS1_GLOBALS.4gl"
###########################################################################
# MAIN
#
# KS1 - Stage I of Voyager I/F
#     - unload TO customers file
#     - unload TO subscription file
#     - unload TO products file ( using Warehouse 1 )
###########################################################################
MAIN 
	DEFINE pr_criteria RECORD 
		cust_flag CHAR(1), 
		part_flag CHAR(1), 
		subs_flag CHAR(1), 
		sub_type_code CHAR(3), 
		year_num SMALLINT 
	END RECORD 
	DEFINE pr_customer RECORD LIKE customer.* 
	DEFINE pr_customership RECORD LIKE customership.* 
	DEFINE pr_subcustomer RECORD LIKE subcustomer.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
	DEFINE msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("KS1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	OPEN WINDOW k111 WITH FORM "K111" 
	CALL winDecoration_k("K111") 

	LET pr_criteria.cust_flag = "Y" 
	LET pr_criteria.part_flag = "Y" 
	LET pr_criteria.subs_flag = "Y" 
	LET pr_criteria.year_num = year(today) 
	INPUT BY NAME pr_criteria.* WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","KS1","input-pr_criteria-1") 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
	IF pr_criteria.cust_flag = "Y" THEN 
		DECLARE c_customer CURSOR FOR 
		SELECT customer.*, customership.* 
		FROM customer, customership 
		WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customer.cmpy_code = customership.cmpy_code 
		AND customer.cust_code = customership.cust_code 
		AND customer.delete_flag = "N" 
		AND customer.ref1_code matches "[Yy]" 
		START REPORT cust_list TO "data/export/dos/public/customers" 
		DISPLAY "Creating CUSTOMERS file" at 1,1 

		FOREACH c_customer INTO pr_customer.*, pr_customership.* 
			OUTPUT TO REPORT cust_list( pr_customer.*, pr_customership.* ) 
		END FOREACH 
		FINISH REPORT cust_list 
	END IF 
	IF pr_criteria.part_flag = "Y" THEN 
		DECLARE c_product CURSOR FOR 
		SELECT product.*, prodstatus.* 
		FROM product, prodstatus 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND prodstatus.cmpy_code = product.cmpy_code 
		AND prodstatus.part_code = product.part_code 
		AND prodstatus.ware_code = '3' 
		AND prodstatus.status_ind != '3' 
		AND product.status_ind != '3' 
		START REPORT prod_list TO "data/export/dos/public/products" 
		DISPLAY "" at 1,1 
		DISPLAY "Creating PRODUCTS file" at 1,1 

		FOREACH c_product INTO pr_product.*,pr_prodstatus.* 
			OUTPUT TO REPORT prod_list(pr_product.*,pr_prodstatus.*) 
		END FOREACH 
		FINISH REPORT prod_list 
	END IF 
	IF pr_criteria.subs_flag = "Y" THEN 
		DECLARE c_subcustomer CURSOR FOR 
		SELECT * FROM subcustomer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_type_code = pr_criteria.sub_type_code 
		AND year(comm_date) = pr_criteria.year_num 
		#START REPORT sub_list  TO "/tmp/subs"
		START REPORT sub_list TO "data/export/dos/public/subscriptions" 
		DISPLAY "" at 1,1 
		DISPLAY "Creating SUBSCRIPTIONS file" at 1,1 

		FOREACH c_subcustomer INTO pr_subcustomer.* 
			OUTPUT TO REPORT sub_list( pr_subcustomer.* ) 
		END FOREACH 
		FINISH REPORT sub_list 
	END IF 
	CALL eventsuspend() # LET msgresp=kandoomsg("U",1,"") 
	## Any key TO continue
END IF 
CLOSE WINDOW k111 
END MAIN 


REPORT cust_list( pr_customer, pr_customership ) 
	DEFINE 
	pr_customer RECORD LIKE customer.*, 
	pr_customership RECORD LIKE customership.* 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 1 
	ORDER external BY pr_customer.cust_code, 
	pr_customership.cust_code 
	FORMAT 
		ON EVERY ROW 
			PRINT chk_delimiter(pr_customer.cust_code) clipped, ',', 
			chk_delimiter(pr_customership.ship_code) clipped, ',', 
			chk_delimiter(pr_customer.type_code) clipped, ',', 
			chk_delimiter(pr_customership.contact_text) clipped, ',', 
			chk_delimiter(pr_customership.name_text) clipped, ',', 
			chk_delimiter(pr_customership.addr_text) clipped, ',', 
			chk_delimiter(pr_customership.addr2_text) clipped, ',', 
			chk_delimiter(pr_customership.city_text) clipped, ',', 
			chk_delimiter(pr_customership.state_code) clipped, ',', 
			chk_delimiter(pr_customership.post_code) clipped, ',', 
			chk_delimiter(pr_customership.country_code) clipped, ',', --@db-patch_2020_10_04--
			chk_delimiter(pr_customership.tele_text) clipped, ',', 
			chk_delimiter(pr_customer.fax_text) clipped, ',', 
			chk_delimiter(pr_customer.hold_code) clipped, ',', 
			'"', today using "dd/mm/yyyy", ' ', time, '"' 
END REPORT 


REPORT sub_list( pr_subcustomer ) 
	DEFINE 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_sub_qty CHAR(3) 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 1 
	ORDER external BY pr_subcustomer.cust_code 
	FORMAT 
		ON EVERY ROW 
			IF pr_subcustomer.status_ind = "2" THEN 
				LET pr_subcustomer.status_ind = "H" 
			ELSE 
			LET pr_subcustomer.status_ind = NULL 
		END IF 
		LET pr_sub_qty = pr_subcustomer.sub_qty USING "###" 
		PRINT chk_delimiter(pr_subcustomer.cust_code) clipped, ',' , 
		chk_delimiter(pr_subcustomer.ship_code) clipped, ',' , 
		chk_delimiter(pr_subcustomer.part_code) clipped, ',' , 
		chk_delimiter(pr_subcustomer.status_ind) clipped, ',' , 
		chk_delimiter(pr_subcustomer.sub_qty) clipped, ',' 
END REPORT 


REPORT prod_list( pr_product, pr_prodstatus) ##, pr_subscription ) 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.* 

	OUTPUT 
	left margin 0 
	top margin 0 
	bottom margin 0 
	PAGE length 1 
	FORMAT 
		ON EVERY ROW 
			PRINT chk_delimiter(pr_product.part_code) clipped, ',', 
			chk_delimiter(pr_product.cat_code) clipped, ',', 
			chk_delimiter(pr_product.desc_text) clipped, ',', 
			chk_delimiter(pr_prodstatus.list_amt USING "-<<<<<<<<<<&.&&") 
			clipped, ',', 
			chk_delimiter(pr_prodstatus.stocked_flag) clipped, ','; 
			IF pr_prodstatus.stocked_flag = 'N' THEN 
				PRINT '"0",'; 
			ELSE 
			PRINT '"', 
			pr_prodstatus.onhand_qty - pr_prodstatus.reserved_qty 
			USING "-<<<<<<<<<<&", 
			'",'; 
		END IF 
		PRINT chk_delimiter(pr_product.sell_uom_code) clipped, ',', 
		'"', today using "dd/mm/yyyy", ' ', time, '"' 
END REPORT 


FUNCTION chk_delimiter(pr_text) 
	DEFINE 
	pr_text CHAR(100) , 
	pr_delimit_text CHAR(200) , 
	idx, j SMALLINT 

	LET j = 1 
	FOR idx = 1 TO length(pr_text) 
		IF pr_text[idx,idx] = '\\' 
		OR pr_text[idx,idx] = '"' THEN 
			LET pr_delimit_text[j,j+1] = '\\', pr_text[idx,idx] 
			LET j = j + 2 
		ELSE 
		LET pr_delimit_text[j,j] = pr_text[idx,idx] 
		LET j = j + 1 
	END IF 
END FOR 
LET pr_delimit_text = '"', pr_delimit_text clipped, '"' 
RETURN pr_delimit_text 
END FUNCTION 
