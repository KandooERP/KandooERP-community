database kandoo_dev
DEFINE t_my_uom TYPE AS RECORD
	my_uom_code CHAR(5), 
	desc_text char(20)
END RECORD 

####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE m_sql_statement STRING
	DEFINE l_prp_my_uom PREPARED			# Prepared object to build the cursor
	DEFINE l_crs_my_uom CURSOR				# cursor as variable
	DEFINE pa_my_uom DYNAMIC ARRAY OF t_my_uom	# the dynamic array for INPUT ARRAY
	DEFINE my_uom_cnt,idx,scr_line SMALLINT
	DEFINE rep char(1)
	WHENEVER SQLERROR CONTINUE
	DROP table my_uom
	WHENEVER SQLERROR STOP
	create table my_uom ( cmpy_code CHAR(2),uom_code CHAR(5),description char(20))
	INSERT INTO my_uom VALUES ('KA','BOX','Box')
	INSERT INTO my_uom VALUES ('KA','DOZ','Dozen')
	INSERT INTO my_uom VALUES ( 'KA','EACH','Each / Single')
	INSERT INTO my_uom VALUES ( 'KA','KG','Kg')
	INSERT INTO my_uom VALUES ( 'KA','LIT','Liter')
	
	LET m_sql_statement = "SELECT uom_code,description FROM my_uom WHERE cmpy_code = ? ORDER BY uom_code"
	CALL l_crs_my_uom.declare(m_sql_statement)	

	CALL l_crs_my_uom.SetParameters("KA")
	CALL l_crs_my_uom.open()

	LET idx = 1
	WHILE true
		CALL  l_crs_my_uom.SetResults(pa_my_uom[idx].*)
		IF l_crs_my_uom.fetchNext() = 100 THEN
			CALL pa_my_uom.delete(idx)
			EXIT WHILE
		END IF
		DISPLAY pa_my_uom[idx].*
		LET idx = idx + 1  
	END WHILE

	prompt "Use the debuger and check the array contents" for char rep
	 
	DROP TABLE my_my_uom
END MAIN 
