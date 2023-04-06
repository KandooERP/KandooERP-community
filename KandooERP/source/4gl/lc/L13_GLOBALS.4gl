############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pt_shiphead RECORD LIKE shiphead.*, 
	pa_shiphead array[250] OF RECORD 
		ship_code LIKE shiphead.ship_code, 
		ship_type_code LIKE shiphead.ship_type_code, 
		vend_code LIKE shiphead.vend_code, 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num, 
		discharge_text LIKE shiphead.discharge_text, 
		ship_status_code LIKE shiphead.ship_status_code 
	END RECORD, 
	idx, id_flag, scrn, cnt, err_flag SMALLINT, 
	sel_text, where_part CHAR(1500), 
	func_type CHAR(14), 
	pr_rec_kandoouser RECORD LIKE kandoouser.* 

END GLOBALS 
