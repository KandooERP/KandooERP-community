# Purpose - CTRL-B lookup window FOR UOM codes

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION lookup_uom(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cnt SMALLINT 
 	DEFINE l_formname CHAR(15) 
	DEFINE l_man_uom_code LIKE prodmfg.man_uom_code 
	DEFINE l_pur_uom_code LIKE product.pur_uom_code 
	DEFINE l_sell_uom_code LIKE product.sell_uom_code 
	DEFINE l_stock_uom_code LIKE product.stock_uom_code 
	DEFINE l_arr_uom ARRAY[5] OF 
		RECORD 
			uom_code LIKE uom.uom_code, 
			desc_text LIKE uom.desc_text 
		END RECORD 

	OPEN WINDOW w1_m125 with FORM "M125" 
	CALL windecoration_m("M125") -- albo kd-767 

	LET l_msgresp = kandoomsg("M", 1504, "") 
	# MESSAGE "ESC TO SELECT - DEL TO Exit"

	SELECT man_uom_code, sell_uom_code, stock_uom_code, pur_uom_code 
	INTO l_man_uom_code, l_sell_uom_code, l_stock_uom_code, l_pur_uom_code 
	FROM product, prodmfg 
	WHERE prodmfg.cmpy_code = p_cmpy 
	AND product.cmpy_code = prodmfg.cmpy_code 
	AND product.part_code = prodmfg.part_code 
	AND product.part_code = p_part_code 

	DECLARE c_uom CURSOR FOR 
	SELECT uom_code, desc_text 
	FROM uom 
	WHERE cmpy_code = p_cmpy 
	AND (uom_code = l_man_uom_code OR 
	uom_code = l_sell_uom_code OR 
	uom_code = l_stock_uom_code OR 
	uom_code = l_pur_uom_code) 

	LET l_cnt = 1 

	FOREACH c_uom INTO l_arr_uom[l_cnt].* 
		LET l_cnt = l_cnt + 1 
	END FOREACH 

	CALL set_count(l_cnt - 1) 

	DISPLAY ARRAY l_arr_uom TO sr_uom.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","mfguomwind","display-arr-uom") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 


	LET l_cnt = arr_curr() 

	CLOSE WINDOW w1_m125 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_arr_uom[l_cnt].uom_code 
	END IF 

END FUNCTION 
