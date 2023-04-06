############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
#	DEFINE glob_query_text STRING -- CHAR(1500)
#	DEFINE glob_where_part STRING -- CHAR(1500)
	DEFINE glob_ans CHAR(1)
	DEFINE glob_z_supp CHAR(1)
	DEFINE glob_idx INTEGER
	DEFINE glob_speriod INTEGER
	DEFINE glob_eperiod INTEGER
	DEFINE glob_name CHAR(7)
#	DEFINE glob_q1_text CHAR(500)
	DEFINE glob_budg_num SMALLINT
#	DEFINE glob_msg_ans CHAR(1)
	DEFINE glob_arr_per_num array[13] OF CHAR(1) 
END GLOBALS 
