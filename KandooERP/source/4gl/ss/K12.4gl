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

	Source code beautified by beautify.pl on 2019-12-31 14:28:28	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module K12 allows the user TO inquire upon customer subscription infor

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("K12") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	OPEN WINDOW k153 WITH FORM "K153" 

	CALL query() 
	CLOSE WINDOW k153 
END MAIN 

FUNCTION select_sub() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_rowid INTEGER, 
	where_text CHAR(800), 
	query_text CHAR(1000) 

	CLEAR FORM 
	LET msgresp=kandoomsg("K",1001,"") 
	#K1001 " Enter criteria FOR selection - ESC TO begin search "
	CONSTRUCT where_text ON subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	customership.name_text, 
	customership.addr_text, 
	customership.addr2_text, 
	customership.city_text, 
	customership.state_code, 
	customership.post_code, 
	customership.country_code, --@db-patch_2020_10_04--
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	subcustomer.sub_qty 
	FROM subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	customership.name_text, 
	customership.addr_text, 
	customership.addr2_text, 
	customership.city_text, 
	customership.state_code, 
	customership.post_code, 
	customership.country_code, --@db-patch_2020_10_04--
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	subcustomer.sub_qty 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("K",1002,"") 
	#K1005 " Serachingdat
	LET query_text = "SELECT subcustomer.rowid ", 
	"FROM customer,", 
	"subcustomer,", 
	"customership ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customership.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND subcustomer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code = subcustomer.cust_code ", 
	"AND customer.cust_code = customership.cust_code ", 
	"AND subcustomer.ship_code = customership.ship_code ", 
	"AND ",where_text," ", 
	"ORDER BY subcustomer.cust_code,", 
	"subcustomer.ship_code,", 
	"subcustomer.comm_date desc,", 
	"subcustomer.part_code" 
	PREPARE s_subcustomer FROM query_text 
	DECLARE c_subcustomer SCROLL CURSOR FOR s_subcustomer 
	OPEN c_subcustomer 
	FETCH c_subcustomer INTO pr_rowid 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
	CALL display_sub(pr_rowid) 
	RETURN true 
END IF 
END FUNCTION 


FUNCTION query() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_rowid INTEGER, 
	pr_subcustomer RECORD LIKE subcustomer.* 

	MENU " Customer subscription" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Enter selection criteria FOR subscriptions " 
			IF select_sub() THEN 
				FETCH FIRST c_subcustomer INTO pr_rowid 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
			LET msgresp = kandoomsg("K",9001,"") 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 
		END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected subscription" 
			FETCH NEXT c_subcustomer INTO pr_rowid 
			IF status = 0 THEN 
				CALL display_sub(pr_rowid) 
			ELSE 
			LET msgresp = kandoomsg("K",9001,"") 
		END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected subscription" 
			FETCH previous c_subcustomer INTO pr_rowid 
			IF status = 0 THEN 
				CALL display_sub(pr_rowid) 
			ELSE 
			LET msgresp = kandoomsg("K",9001,"") 
			#9070 You have reached the start of the subscription selected"
		END IF 
		COMMAND KEY ("D",f20) "Detail" " View subscription details" 
			SELECT * INTO pr_subcustomer.* 
			FROM subcustomer 
			WHERE rowid = pr_rowid 
			CALL show_subaudit(glob_rec_kandoouser.cmpy_code,pr_subcustomer.cust_code, 
			pr_subcustomer.ship_code, 
			pr_subcustomer.part_code, 
			pr_subcustomer.sub_type_code, 
			pr_subcustomer.comm_date, 
			pr_subcustomer.end_date) 
		COMMAND KEY ("F",f18) "First" " DISPLAY first subscription in the selected list" 
			FETCH FIRST c_subcustomer INTO pr_rowid 
			IF status = 0 THEN 
				CALL display_sub(pr_rowid) 
			ELSE 
			LET msgresp = kandoomsg("K",9001,"") 
		END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last subscription in the selected list" 
			FETCH LAST c_subcustomer INTO pr_rowid 
			IF status = 0 THEN 
				CALL display_sub(pr_rowid) 
			ELSE 
			LET msgresp = kandoomsg("K",9001,"") 
		END IF 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the menu" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_sub(pr_rowid) 
	DEFINE 
	pr_rowid INTEGER, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_issue_date LIKE subaudit.tran_date, 
	pr_update_date LIKE subaudit.tran_date, 
	pr_product RECORD LIKE product.* 

	SELECT * INTO pr_subcustomer.* 
	FROM subcustomer 
	WHERE rowid = pr_rowid 
	SELECT * INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	SELECT * INTO pr_substype.* 
	FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_subcustomer.sub_type_code 
	SELECT * INTO pr_customership.* 
	FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	SELECT sum(tran_qty) INTO pr_subcustomer.sub_qty 
	FROM subaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND part_code = pr_subcustomer.part_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND start_date = pr_subcustomer.comm_date 
	AND end_date = pr_subcustomer.end_date 
	AND tran_type_ind = "SUB" 
	SELECT sum(tran_qty) INTO pr_subcustomer.issue_qty 
	FROM subaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND part_code = pr_subcustomer.part_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND start_date = pr_subcustomer.comm_date 
	AND end_date = pr_subcustomer.end_date 
	AND tran_type_ind = "ISS" 
	SELECT max(tran_date) INTO pr_issue_date 
	FROM subaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND part_code = pr_subcustomer.part_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND start_date = pr_subcustomer.comm_date 
	AND end_date = pr_subcustomer.end_date 
	AND tran_qty > 0 
	AND tran_type_ind = "ISS" 
	SELECT max(tran_date) INTO pr_update_date 
	FROM subaudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND part_code = pr_subcustomer.part_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND start_date = pr_subcustomer.comm_date 
	AND end_date = pr_subcustomer.end_date 
	AND tran_type_ind = "ISS" 
	SELECT * INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subcustomer.part_code 
	DISPLAY BY NAME pr_subcustomer.cust_code, 
	pr_customer.name_text, 
	pr_subcustomer.ship_code, 
	pr_customership.name_text, 
	pr_customership.addr_text, 
	pr_customership.addr2_text, 
	pr_customership.city_text, 
	pr_customership.state_code, 
	pr_customership.post_code, 
	pr_customership.country_code, --@db-patch_2020_10_04--
	pr_subcustomer.part_code, 
	pr_subcustomer.sub_type_code, 
	pr_subcustomer.sub_qty, 
	pr_subcustomer.issue_qty, 
	pr_subcustomer.comm_date, 
	pr_subcustomer.end_date, 
	pr_product.desc_text, 
	pr_product.desc2_text 

	DISPLAY pr_customership.name_text, 
	pr_substype.desc_text, 
	pr_update_date 
	TO customership.name_text, 
	sub_type_text, 
	update_date 

END FUNCTION 

