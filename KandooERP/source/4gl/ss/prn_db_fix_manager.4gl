# module  generated by Querix Ffg(c) 		                                                                                    	#@G00001
# Generated on 2018-09-16 13:43:59		                                                                                       	#@G00002
# template E:\Users\BeGooden-IT\Projects\QuerixTools\ffg/templates/parent_standard.mtplt 		                                	#@G00003

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"                                                                                                        	#@G00005
	DEFINE m_program CHAR(30)		                                                                                               	#@G00006

	DEFINE tbl_db_fix_manager RECORD 		                                                                                       	#@G00008
		fix_id INTEGER,		                                                                                                          	#@G00009
		fix_dbvendor CHAR(15),		                                                                                                   	#@G00010
		fix_apply_date datetime year TO second,		                                                                                  	#@G00011
		fix_abstract CHAR(80),		                                                                                                   	#@G00012
		fix_type CHAR(15),		                                                                                                       	#@G00013
		fix_statements lvarchar(10000),		                                                                                          	#@G00014
		fix_dependencies varchar(255),		                                                                                           	#@G00015
		fix_tableslist varchar(255)				                                                                                                                         	#@G00016
	END RECORD		                                                                                                              	#@G00017

	DEFINE frm_db_fix_manager RECORD 		                                                                                       	#@G00019
		fix_id  INTEGER,		                                                                                                         	#@G00020
		fix_dbvendor  CHAR(15),		                                                                                                  	#@G00021
		fix_apply_date  datetime year TO second,		                                                                                 	#@G00022
		fix_abstract  CHAR(80),		                                                                                                  	#@G00023
		fix_type  CHAR(15),		                                                                                                      	#@G00024
		fix_statements  lvarchar(10000),		                                                                                         	#@G00025
		fix_dependencies  varchar(255),		                                                                                          	#@G00026
		fix_tableslist  varchar(255)				                                                                                                                         	#@G00027
	END RECORD		                                                                                                              	#@G00028

	DEFINE sav_db_fix_manager RECORD 		                                                                                       	#@G00030
		fix_id  INTEGER,		                                                                                                         	#@G00031
		fix_dbvendor  CHAR(15),		                                                                                                  	#@G00032
		fix_apply_date  datetime year TO second,		                                                                                 	#@G00033
		fix_abstract  CHAR(80),		                                                                                                  	#@G00034
		fix_type  CHAR(15),		                                                                                                      	#@G00035
		fix_statements  lvarchar(10000),		                                                                                         	#@G00036
		fix_dependencies  varchar(255),		                                                                                          	#@G00037
		fix_tableslist  varchar(255)				                                                                                                                         	#@G00038
	END RECORD		                                                                                                              	#@G00039

		                                                                                                                         	#@G00041

MAIN		                                                                                                                     	#@G00043
	DEFER INTERRUPT		                                                                                                         	#@G00044
	OPTIONS		                                                                                                                 	#@G00045
	help file "db_fix_manager.iem",		                                                                                         	#@G00046
	help key F1		                                                                                                             	#@G00047

	# WHENEVER ERROR CALL error_mngmt		                                                                                       	#@G00049
	# CALL ui_init(0) 		                                                                                                      	#@G00050
	LET m_program="p_db_fix_manager_dbschema_fix"		                                                                           	#@G00051

	CALL main_db_fix_manager_dbschema_fix()		                                                                                 	#@G00053

END MAIN		                                                                                                                 	#@G00055

#######################################################		                                                                  	#@G00057
# definition variable sccs		                                                                                               	#@G00058
FUNCTION mc_db_fix_manager_sccs()		                                                                                        	#@G00059
	DEFINE sccs_var CHAR(70)		                                                                                                	#@G00060
LET sccs_var="%W% %D%"		                                                                                                   	#@G00061
END FUNCTION		                                                                                                             	#@G00062

FUNCTION main_db_fix_manager_dbschema_fix ()		                                                                             	#@G00064

	OPEN WINDOW f_dbschema_fix WITH FORM "f_dbschema_fix" attributes(border)		                                                	#@G00068

	CALL prepare_queries_db_fix_manager_dbschema_fix () # INITIALIZE all cursors on master table		                            	#@G00070
			                                                                                                                         	#@G00070

	CALL menu_db_fix_manager_dbschema_fix()      		                                                                           	#@G00072

	CLOSE WINDOW f_dbschema_fix		                                                                                             	#@G00074

END FUNCTION		                                                                                                             	#@G00076

######################################################################		                                                   	#@G00078
# menu_db_fix_manager_dbschema_fix		                                                                                       	#@G00079
# the top level menu 		                                                                                                    	#@G00080
# input arguments: none		                                                                                                  	#@G00081
# output arguments: none		                                                                                                 	#@G00082
FUNCTION menu_db_fix_manager_dbschema_fix ()		                                                                             	#@G00083
	DEFINE nbsel_dbschema_fix INTEGER		                                                                                       	#@G00084
	DEFINE sql_stmt_status INTEGER		                                                                                          	#@G00085
	DEFINE record_num INTEGER		                                                                                               	#@G00086
	DEFINE action SMALLINT		                                                                                                  	#@G00087
	DEFINE xnumber SMALLINT		                                                                                                 	#@G00088
	DEFINE arr_elem_num SMALLINT		                                                                                            	#@G00089
	DEFINE pky_dbschema_fix RECORD 		                                                                                         	#@G00090
				                                                                                                                         	#@G00091
	END RECORD		                                                                                                              	#@G00092

	LET nbsel_dbschema_fix = 0		                                                                                              	#@G00094
	MENU "dbschema_fix"		                                                                                                     	#@G00095
	BEFORE MENU		                                                                                                             	#@G00096
