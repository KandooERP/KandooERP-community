############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS

	DEFINE dt_rec_dochead TYPE AS RECORD 
		doc_type CHAR(1), 
		cmpy_code LIKE invoicehead.cmpy_code, 
		doc_num LIKE invoicehead.inv_num, 
		doc_ind LIKE invoicehead.inv_ind, 
		cust_code LIKE invoicehead.cust_code, 
		org_cust_code LIKE invoicehead.org_cust_code, 
		doc_date LIKE invoicehead.inv_date, 
		cond_code LIKE invoicehead.cond_code, 
		tax_code LIKE invoicehead.tax_code, 
		carrier_code LIKE invoicehead.carrier_code, 
		term_code LIKE invoicehead.term_code, 
		territory_code LIKE invoicehead.territory_code, 
		sale_code LIKE invoicehead.sale_code, 
		ord_num LIKE invoicehead.ord_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		goods_amt LIKE invoicehead.goods_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		total_amt LIKE invoicehead.total_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		hand_tax_amt LIKE invoicehead.hand_tax_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		freight_tax_amt LIKE invoicehead.freight_tax_amt, 
		invoice_to_ind LIKE invoicehead.invoice_to_ind, 
		name_text LIKE invoicehead.name_text, 
		addr1_text LIKE invoicehead.addr1_text, 
		addr2_text LIKE invoicehead.addr2_text, 
		city_text LIKE invoicehead.city_text, 
		state_code LIKE invoicehead.state_code, 
		post_code LIKE invoicehead.post_code, 
		country_code LIKE invoicehead.country_code, --@db-patch_2020_10_04--
		com1_text LIKE invoicehead.com1_text, 
		com2_text LIKE invoicehead.com2_text, 
		conv_qty LIKE invoicehead.conv_qty,
		printed_num LIKE invoicehead.printed_num 
	END RECORD 
	
	DEFINE dt_rec_docdetl TYPE AS RECORD
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		order_num LIKE invoicedetl.order_num, 
		offer_code LIKE invoicedetl.offer_code, 
		tax_code LIKE invoicedetl.tax_code, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		unit_tax_amt LIKE invoicedetl.unit_tax_amt, 
		ext_sale_amt LIKE invoicedetl.ext_sale_amt, 
		ext_tax_amt LIKE invoicedetl.ext_tax_amt, 
		ord_qty LIKE invoicedetl.ord_qty, 
		ship_qty LIKE invoicedetl.ship_qty, 
		back_qty LIKE invoicedetl.back_qty, 
		sold_qty LIKE invoicedetl.sold_qty, 
		line_text LIKE invoicedetl.line_text, 
		ware_code LIKE invoicedetl.ware_code, 
		level_code LIKE invoicedetl.level_code, 
		disc_amt LIKE invoicedetl.disc_amt 
	END RECORD 

END GLOBALS