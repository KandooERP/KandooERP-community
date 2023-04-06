FUNCTION is_path_valid(pr_path_text) 
	DEFINE 
	pr_path_text CHAR(100), 
	runner CHAR(400), 
	ret_code INTEGER 

	IF os.path.exists(pr_path_text) THEN 
		IF os.path.readable(pr_path_text) THEN --huho changed TO os.path() method 
			RETURN TRUE 
		END IF
	ELSE 
		RETURN FALSE
	END IF 
END FUNCTION 
