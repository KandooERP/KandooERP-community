############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
{
GLOBALS 
	DEFINE glob_tot_unpaid money(15,2)
	DEFINE glob_tot_curr money(15,2)
	DEFINE glob_tot_o30 money(15,2)
	DEFINE glob_tot_o60 money(15,2)
	DEFINE glob_tot_o90 money(15,2)
	DEFINE glob_tot_plus money(15,2) 
	DEFINE glob_age_date DATE 
	DEFINE glob_conv_ind CHAR(1) 
	DEFINE glob_rpt_notes_flag CHAR(1) 
END GLOBALS 

}