GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_q(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	# DEFINE cb_field_name      VARCHAR(25)   --form field
	#	DEFINE pVariable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	#	DEFINE pSort SMALLINT  --0=Sort on first 1=Sort on 2nd
	#	DEFINE pSingle SMALLINT	--0=variable AND label 1= variable = label
	#	DEFINE pHint SMALLINT  --1 = show both VALUES in label


	CASE pwinname 
	# Prog: U11
	# User Parameters
		WHEN "Q100" -- quote inquiry 

		WHEN "Q101" -- quotation scan 

		WHEN "Q102" -- quotation scan 

		WHEN "Q103" 

		WHEN "Q117" 

		WHEN "Q119" 

		WHEN "Q124" 

		WHEN "Q125" 

		WHEN "Q210" 

		WHEN "Q211" 

		WHEN "Q212" 

		WHEN "Q214" 

		WHEN "Q215" 

		WHEN "Q216" 

		WHEN "Q220" 

		WHEN "Q224" 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_Q(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
