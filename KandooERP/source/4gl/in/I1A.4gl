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

	Source code beautified by beautify.pl on 2020-01-03 09:12:22	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}

# CleanCode priority 1 done by ericv on 2020-09-20
# Variables reorg,cursor rename, split MAIN
# CleanCode priority 2 done by ericv on 2020-09-20
# events reorg
# CleanCode priority 3 done by ericv on 2020-09-20

# \file
# \brief I1A - Product History Inquiry
# This menu path provides the facility to retrieve detailed product movement and sales information for specified products.  
# The historical information provided includes period sales, beginning and ending period quantities, gross percent profit, transfers, credits, purchases, and returns.  
# The values are updated using IS7 - Product History Update.

# Module scope variables
DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.*


MAIN 
	#Initial UI Init
	CALL setModuleId("I1A") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL I1A_main()

END MAIN 

FUNCTION I1A_main()
DEFINE l_part_code LIKE prodhist.part_code
DEFINE ans CHAR(1)
	# TODO: use processUrlArguments instead of arg_val
	LET l_part_code = arg_val(1)

	LET ans = "Y" 

	WHILE ans = "Y" 
		CALL query_product_history(l_part_code) 
		CLOSE WINDOW wi110 
		LET ans = "Y" 
	END WHILE 

END FUNCTION # I1A_main()


FUNCTION query_product_history(p_part_code) 
DEFINE p_part_code LIKE prodhist.part_code
DEFINE l_rec_prodhist RECORD LIKE prodhist.*
DEFINE l_rec_product RECORD LIKE product.*
DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
DEFINE idx SMALLINT
DEFINE id_flag SMALLINT
DEFINE l_arr_rec_prodhist DYNAMIC ARRAY OF RECORD 
	year_num LIKE prodhist.year_num, 
	period_num LIKE prodhist.period_num, 
	start_qty LIKE prodhist.start_qty, 
	sales_qty LIKE prodhist.sales_qty, 
	pur_qty LIKE prodhist.pur_qty, 
	end_qty LIKE prodhist.end_qty, 
	gross_per LIKE prodhist.gross_per 
END RECORD

	OPEN WINDOW wi110 with FORM "I110" 
	 CALL windecoration_i("I110") -- albo kd-758 
	MESSAGE " Enter Product Code, Warehouse, Year AND Period FOR history scan" 
	attribute (yellow) 
	LET l_rec_prodhist.part_code = p_part_code
	DISPLAY BY NAME l_rec_prodhist.part_code, 
	l_rec_prodhist.ware_code, 
	l_rec_prodhist.year_num, 
	l_rec_prodhist.period_num 

	INPUT BY NAME l_rec_prodhist.part_code, 
	l_rec_prodhist.ware_code, 
	l_rec_prodhist.year_num, 
	l_rec_prodhist.period_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I1A","input-l_rec_prodhist-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Lookup"
			CASE 
				WHEN infield (part_code) 
					LET l_rec_prodhist.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME l_rec_prodhist.part_code 

					NEXT FIELD part_code 

				WHEN infield (ware_code) 
					LET l_rec_prodhist.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME l_rec_prodhist.ware_code 

					NEXT FIELD ware_code 

			END CASE 
		ON KEY (control-w)
			CALL kandoohelp("") 

		ON CHANGE part_code 
			SELECT * 
			INTO l_rec_product.* 
			FROM product 
			WHERE part_code = l_rec_prodhist.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR " Product Not Found, Try Window" 
				NEXT FIELD part_code 
			END IF 

		ON CHANGE ware_code 
			SELECT * 
			INTO l_rec_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_prodhist.part_code 
			AND ware_code = l_rec_prodhist.ware_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR "Product Status Does Not Exist, Try Another Warehouse" 
				NEXT FIELD ware_code 
			END IF 

	END INPUT 
	IF int_flag != 0 OR quit_flag != 0 	THEN 
		EXIT program 
	END IF 
	
	DECLARE crs_product_history CURSOR FOR 
	SELECT year_num,
		period_num,
		start_qty,
		sales_qty-credit_qty,
		pur_qty,
		end_qty,
		gross_per
	FROM prodhist 
	WHERE part_code = l_rec_prodhist.part_code 
		AND ware_code = l_rec_prodhist.ware_code 
		AND year_num >= l_rec_prodhist.year_num 
		AND period_num >= l_rec_prodhist.period_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY year_num, period_num 
	IF (sqlca.sqlcode = NOTFOUND) THEN 
		ERROR "No history records have been established FOR this Product" 
	END IF 

	LET idx = 1 
	FOREACH crs_product_history INTO 
		l_arr_rec_prodhist[idx].year_num, 
		l_arr_rec_prodhist[idx].period_num ,
		l_arr_rec_prodhist[idx].start_qty,
		l_arr_rec_prodhist[idx].sales_qty,
		l_arr_rec_prodhist[idx].pur_qty,
		l_arr_rec_prodhist[idx].end_qty,
		l_arr_rec_prodhist[idx].gross_per
		LET idx = idx + 1 
	END FOREACH 
	CALL set_count (idx) 

	MESSAGE "" 
	MESSAGE " RETURN on line TO view history detail" 
	attribute (yellow) 

	DISPLAY ARRAY l_arr_rec_prodhist
	TO sr_prodhist.*

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET id_flag = 0 
			CALL display_product_history(glob_rec_kandoouser.cmpy_code, l_rec_prodhist.part_code, l_rec_prodhist.ware_code,l_arr_rec_prodhist[idx].year_num, l_arr_rec_prodhist[idx].period_num) 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 	# query_product_history(p_part_code)
