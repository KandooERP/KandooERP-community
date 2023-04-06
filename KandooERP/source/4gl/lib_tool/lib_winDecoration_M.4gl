GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_m(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters

		WHEN "M100" #Configuration Add
		WHEN "M117" #Manufacturing Product Details
		WHEN "M119" 

		WHEN "M126" #Manufacturing Product Lookup
		WHEN "M166" #Warehouse Scan

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_M(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
