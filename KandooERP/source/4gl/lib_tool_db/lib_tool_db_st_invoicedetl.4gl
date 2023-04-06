##############################################################################################
# TABLE t_invoicedetl
# Static Temp Table
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_st_invoicedetl_get_count()
#
# Return total number of rows in product 
############################################################
FUNCTION db_st_invoicedetl_get_count()
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM t_invoicedetl 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION

{
FUNCTION db_st_invoicedetl_get_arr_rec_invoice_lines(p_ware_code,p_show_tax_flag)
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE p_show_tax_flag LIKE arparms.show_tax_flag #glob_rec_arparms.show_tax_flag
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF #array[300] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE invoicedetl.line_num, 
			part_code LIKE invoicedetl.part_code, 
			line_text LIKE invoicedetl.line_text, 
			ship_qty LIKE invoicedetl.ship_qty, 
			unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
			line_total_amt LIKE invoicedetl.line_total_amt 
		END RECORD 
	DEFINE l_idx SMALLINT
	
		DECLARE c1_invoicedetl CURSOR FOR 
		SELECT * FROM t_invoicedetl 
		ORDER BY line_num 

		LET l_idx = 0 
		FOREACH c1_invoicedetl INTO l_rec_invoicedetl.* 
			LET l_idx = l_idx + 1 
			LET l_rec_invoicedetl.ware_code = p_ware_code #glob_rec_warehouse.ware_code 

			IF l_rec_invoicedetl.line_num != l_idx THEN 
				UPDATE t_invoicedetl 
				SET line_num = l_idx 
				WHERE line_num = l_rec_invoicedetl.line_num 
				LET l_rec_invoicedetl.line_num = l_idx 
			END IF 

			LET l_arr_rec_invoicedetl[l_idx].line_num = l_rec_invoicedetl.line_num 
			LET l_arr_rec_invoicedetl[l_idx].part_code = l_rec_invoicedetl.part_code 
			LET l_arr_rec_invoicedetl[l_idx].line_text = l_rec_invoicedetl.line_text 
			LET l_arr_rec_invoicedetl[l_idx].ship_qty = l_rec_invoicedetl.ship_qty 
			LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = l_rec_invoicedetl.unit_sale_amt 
			IF p_show_tax_flag = "Y" THEN  #glob_rec_arparms.show_tax_flag 
				LET l_arr_rec_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.line_total_amt 
			ELSE 
				LET l_arr_rec_invoicedetl[l_idx].line_total_amt =l_rec_invoicedetl.ext_sale_amt 
			END IF 
		END FOREACH 
		
	RETURN l_arr_rec_invoicedetl
END FUNCTION	
}


{
create table "informix".invoicedetl 
  (
    cmpy_code nchar(2),
    cust_code nchar(8),
    inv_num integer,
    line_num smallint,
    part_code nchar(15),
    ware_code nchar(3),
    cat_code nchar(3),
    ord_qty float,
    ship_qty float,
    prev_qty float,
    back_qty float,
    ser_flag nchar(1),
    ser_qty float,
    line_text nvarchar(40),
    uom_code nchar(4),
    unit_cost_amt decimal(16,4),
    ext_cost_amt decimal(16,2),
    disc_amt decimal(16,2),
    unit_sale_amt decimal(16,4),
    ext_sale_amt decimal(16,2),
    unit_tax_amt decimal(16,4),
    ext_tax_amt decimal(16,2),
    line_total_amt decimal(16,2),
    seq_num integer,
    line_acct_code nchar(18),
    level_code nchar(1),
    comm_amt decimal(16,2),
    comp_per decimal(6,3),
    tax_code nchar(3),
    order_line_num smallint,
    order_num integer,
    disc_per decimal(6,3),
    offer_code nchar(6),
    sold_qty float,
    bonus_qty float,
    ext_bonus_amt decimal(16,2),
    ext_stats_amt decimal(16,2),
    prodgrp_code nchar(3),
    maingrp_code nchar(3),
    list_price_amt decimal(16,4),
    var_code smallint,
    activity_code nchar(8),
    jobledger_seq_num integer,
    contract_line_num smallint,
    price_uom_code nchar(4),
    return_qty float,
    km_qty float,
    proddept_code nchar(3)
  );

}