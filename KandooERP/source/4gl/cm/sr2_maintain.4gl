{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	 $Id$
}


{**
 *
 * Functions FOR maintaining lookup tables
 *
 * @author: Andrej Falout
 *
 *}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 

DEFINE 
class_cursor, 
exist_class 
SMALLINT, 

p_select_desc2, 
p_select_desc3, 
p_select_desc4, 
p_select_desc5, 
p_select_desc6, 
p_select_desc7, 
p_select_desc8, 
#	 p_select_desc9,


p_select_sql2, 
p_select_sql3, 
p_select_sql4, 
p_select_sql5, 
p_select_sql6, 
p_select_sql7, 
p_select_sql8, 
p_select_sql9 
CHAR(70) 



#############################
FUNCTION code_maintain_menu() 
	#############################

	MENU "Codes" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Codes-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Roles" 
			"Maintain all role codes (address,phone,account,cc,age,contact role&relation,mail termonation)" 
			CALL m_role() 


		COMMAND "Credit card type" "Maintain Credit card type codes" 
			CALL m_cc_type() 

		COMMAND "Time restrictions" "Maintain phone number time restriction codes" 
			CALL m_time_restrict() 

		COMMAND "Mailing list" "Maintain mailing list codes" #"list" IS actuali a "role" 
			CALL m_mailing_role() 

		COMMAND KEY ("d", "D") "mailing Dates" "Schedule mailing events" 
			CALL m_mailing_dates() 


		COMMAND "Options" "Set OPTIONS FOR this program" 
			MESSAGE"" 
			CALL options_menu() 
			CALL contact_info("1") 

			#        COMMAND "Point in time" "Generate a REPORT FOR this Contact on specific date"
			#            ERROR "Not implemented yet"

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "Exit TO the previous menu" 
			EXIT MENU 

	END MENU 

END FUNCTION #code_maintain_menu() 

#########################################################################
#                        cc_type
#########################################################################


#########################
FUNCTION m_cc_type() 
	#########################

	CALL func_name ("M_cc_type") 

	OPEN WINDOW cc_type_w with FORM "code_x" 
	CALL winDecoration("code_x") -- albo kd-766 

	MENU "cc_type codes" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-type_codes-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query the table" 
			CALL q_cc_type() 

		COMMAND "+" "Next found" 
			CALL n_cc_type() 

		COMMAND "-" "Previous found" 
			CALL pr_cc_type() 

		COMMAND "Add" "Add new cc_type code" 
			CALL a_cc_type() 

		COMMAND "Update" "Change this cc_type code name" 
			CALL u_cc_type() 

		COMMAND "List" "Show list of all cc_type names" 
			CALL cc_type_lp() RETURNING dummy, dummy 

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "RETURN TO the previous menu" 
			CALL end_cc_type() 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW cc_type_w 


END FUNCTION #cc_type() 


#############################
FUNCTION q_cc_type() 
	#############################

	CALL FUNC_NAME("Q_cc_type") 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT query_1 ON cc_type.* 
	FROM 
	code, 
	NAME 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","maintain","construct-type-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF 
	int_flag <> 0 
	THEN 
		GOTO endcc_type 
	END IF 

	LET query_1 ="SELECT * ", 
	"FROM cc_type ", 
	"WHERE ", query_1 clipped 

	PREPARE s_cc_type FROM query_1 

	MESSAGE "Searching...please wait" 

	DECLARE c_cc_type SCROLL CURSOR FOR s_cc_type 
	LET cc_type_cursor = true 
	OPEN c_cc_type 

	FETCH FIRST c_cc_type INTO p_cc_type.* 

	IF 
	status = notfound 
	THEN 
		LET exist_cc_type = false 
		MESSAGE "There IS no cc_type with that name/code" 
	ELSE 
		MESSAGE "" 
		LET exist_cc_type = true 
		DISPLAY p_cc_type.* TO s_code.* 
	END IF 



	LABEL endcc_type: 

	MESSAGE "" 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

END FUNCTION #q_cc_type() 

##############################
FUNCTION n_cc_type() 
	##############################
	CALL func_name ("N_cc_type") 

	IF 
	exist_cc_type 
	THEN 
		FETCH NEXT c_cc_type INTO p_cc_type.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_cc_type.* TO s_code.* 
		END IF 

	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #n_cc_type() 

##################################
FUNCTION pr_cc_type() 
	##################################

	CALL func_name ("Pr_cc_type") 

	IF 
	exist_cc_type 
	THEN 
		FETCH previous c_cc_type INTO p_cc_type.* 
		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_cc_type.* TO s_code.* 
		END IF 
	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #pr_cc_type() 

###############################
FUNCTION a_cc_type() 
	###############################

	CALL func_name ("A_cc_type") 

	MESSAGE "" 
	CLEAR FORM 

	INPUT p_cc_type.* FROM s_code.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-cc_type-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			###########
		AFTER INPUT 
			###########

			IF 
			p_cc_type.cc_type_name IS NULL 
			OR 
			length(P_cc_type.cc_type_name) < 1 
			THEN 
				ERROR "Please enter the cc_type NAME" 
				NEXT FIELD NAME 
			ELSE 
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########


	IF 
	int_flag <> 0 
	THEN 
		GOTO endcc_type17 
	END IF 

	LET p_cc_type.cc_type_code = 0 


	INSERT INTO cc_type VALUES (p_cc_type.*) 

	MESSAGE "New RECORD added" 

	LABEL endcc_type17: 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
		CLEAR FORM 
	END IF 

	MESSAGE "" 

END FUNCTION #a_cc_type() 

############################
FUNCTION u_cc_type() 
	############################

	CALL func_name ("U_cc_type") 

	INPUT p_cc_type.cc_type_name WITHOUT DEFAULTS 
	FROM s_code.name 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-cc_type-2") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#HELP 229

			###########
		AFTER INPUT 
			###########

			IF 
			p_cc_type.cc_type_name IS NULL 
			OR 
			length(P_cc_type.cc_type_name) < 1 
			THEN 
				ERROR "Please enter the cc_type NAME" 
				NEXT FIELD NAME 
			ELSE 
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########

	IF 
	int_flag <> 0 
	THEN 
		GOTO endcc_type19 
	END IF 

	UPDATE cc_type 
	SET cc_type.cc_type_name = p_cc_type.cc_type_name 
	WHERE cc_type.cc_type_code = p_cc_type.cc_type_code 

	MESSAGE "Record updated" 

	LABEL endcc_type19: 
	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

	MESSAGE "" 

END FUNCTION #u_cc_type() 



###########################
FUNCTION end_cc_type() 
	###########################

	CALL func_name ("End_cc_type") 

	IF 
	cc_type_cursor 
	THEN 
		CLOSE c_cc_type 
		FREE c_cc_type 
	END IF 

END FUNCTION #kraj_cc_type() 


########################
FUNCTION cc_type_lp() 
	########################
	DEFINE 
	a_cc_type array[100] OF RECORD 
		cc_type_code LIKE cc_type.cc_type_code, 
		cc_type_name LIKE cc_type.cc_type_name 
	END RECORD, 
	a_cc_type_name ARRAY [100] OF RECORD 
		cc_type_name LIKE cc_type.cc_type_name 
	END RECORD, 
	cnt, 
	arr_max, 
	arr_full SMALLINT 

	LET arr_max = 100 
	LET arr_full = 1 

	OPEN WINDOW w_cc_type_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	DECLARE c_cc_type_lp CURSOR 
	FOR SELECT * FROM cc_type 
	ORDER BY cc_type_name 

	MESSAGE "Searching...please wait" 

	#####################################################
	FOREACH c_cc_type_lp INTO a_cc_type[arr_full].* 
		#####################################################

		LET a_cc_type_name[arr_full].cc_type_name = a_cc_type[arr_full].cc_type_name 

		LET arr_full = arr_full + 1 

		IF 
		arr_full = arr_max + 1 
		THEN 
			ERROR "Cannot load all codes..." 
			SLEEP 5 
			EXIT FOREACH 
		END IF 


		###########
	END FOREACH 
	###########

	MESSAGE "" 

	LET arr_full = arr_full - 1 

	CLOSE c_cc_type_lp 
	FREE c_cc_type_lp 

	CALL set_count(arr_full) 

	MESSAGE "SELECT AND press Accept" 

	DISPLAY ARRAY a_cc_type_name TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-type_name-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 


	CLOSE WINDOW w_cc_type_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null, gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_cc_type[cnt].cc_type_code, a_cc_type[cnt].cc_type_name 

END FUNCTION #cc_type_lp() 
#########################################################################
#                        time_restrict
#########################################################################


#########################
FUNCTION m_time_restrict() 
	#########################

	CALL func_name ("M_time_restrict") 

	OPEN WINDOW time_restrict_w with FORM "code_x" 
	CALL winDecoration("code_x") -- albo kd-766 

	LET time_restrict_cursor = false 


	MENU "Time restrict codes" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-restrict_codes-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query the table" 
			CALL q_time_restrict() 

		COMMAND "+" "Next found" 
			CALL n_time_restrict() 

		COMMAND "-" "Previous found" 
			CALL pr_time_restrict() 

		COMMAND "Add" "Add new time_restrict code" 
			CALL a_time_restrict() 

		COMMAND "Update" "Change this time_restrict code name" 
			CALL u_time_restrict() 

		COMMAND "List" "Show list of all time_restrict names" 
			CALL time_restrict_lp() RETURNING dummy, dummy 

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "RETURN TO the previous menu" 
			CALL end_time_restrict() 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW time_restrict_w 


END FUNCTION #time_restrict() 


#############################
FUNCTION q_time_restrict() 
	#############################

	CALL FUNC_NAME("Q_time_restrict") 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT query_1 ON time_restrict.* 
	FROM 
	code, 
	NAME 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","maintain","construct-time-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF 
	int_flag <> 0 
	THEN 
		GOTO endtime_restrict 
	END IF 

	LET query_1 ="SELECT * ", 
	"FROM time_restrict ", 
	"WHERE ", query_1 clipped 

	MESSAGE "Searching...please wait" 

	PREPARE s_time_restrict FROM query_1 

	DECLARE c_time_restrict SCROLL CURSOR FOR s_time_restrict 
	LET time_restrict_cursor = true 
	OPEN c_time_restrict 

	FETCH FIRST c_time_restrict INTO p_time_restrict.* 

	IF 
	status = notfound 
	THEN 
		LET exist_time_restrict = false 
		MESSAGE "There IS no time_restrict with that name/code" 
	ELSE 
		MESSAGE "" 
		LET exist_time_restrict = true 
		DISPLAY p_time_restrict.* TO s_code.* 
	END IF 

	LABEL endtime_restrict: 

	MESSAGE "" 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

END FUNCTION #q_time_restrict() 

##############################
FUNCTION n_time_restrict() 
	##############################
	CALL func_name ("N_time_restrict") 

	IF 
	exist_time_restrict 
	THEN 
		FETCH NEXT c_time_restrict INTO p_time_restrict.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_time_restrict.* TO s_code.* 
		END IF 

	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #n_time_restrict() 

##################################
FUNCTION pr_time_restrict() 
	##################################

	CALL func_name ("Pr_time_restrict") 

	IF 
	exist_time_restrict 
	THEN 
		FETCH previous c_time_restrict INTO p_time_restrict.* 
		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_time_restrict.* TO s_code.* 
		END IF 
	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #pr_time_restrict() 

###############################
FUNCTION a_time_restrict() 
	###############################

	CALL func_name ("A_time_restrict") 

	MESSAGE "" 
	CLEAR FORM 

	INPUT p_time_restrict.* FROM s_code.* 
	# HELP 229

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-time_restrict-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 


			###########
		AFTER INPUT 
			###########

			IF 
			p_time_restrict.time_restrict_name IS NULL 
			OR 
			length(P_time_restrict.time_restrict_name) < 1 
			THEN 
				ERROR "Please enter the time_restrict NAME" 
				NEXT FIELD NAME 
			ELSE 
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########


	IF 
	int_flag <> 0 
	THEN 
		GOTO endtime_restrict17 
	END IF 

	LET p_time_restrict.time_restrict_code = 0 


	INSERT INTO time_restrict VALUES (p_time_restrict.*) 

	MESSAGE "New RECORD added" 

	LABEL endtime_restrict17: 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
		CLEAR FORM 
	END IF 

	MESSAGE "" 

END FUNCTION #a_time_restrict() 

############################
FUNCTION u_time_restrict() 
	############################

	CALL func_name ("U_time_restrict") 

	INPUT p_time_restrict.time_restrict_name WITHOUT DEFAULTS 
	FROM s_code.name 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-time_restrict-3") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#HELP 229

			###########
		AFTER INPUT 
			###########

			IF 
			p_time_restrict.time_restrict_name IS NULL 
			OR 
			length(P_time_restrict.time_restrict_name) < 1 
			THEN 
				ERROR "Please enter the time_restrict NAME" 
				NEXT FIELD NAME 
			ELSE 
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########

	IF 
	int_flag <> 0 
	THEN 
		GOTO endtime_restrict19 
	END IF 

	UPDATE time_restrict 
	SET time_restrict.time_restrict_name = p_time_restrict.time_restrict_name 
	WHERE time_restrict.time_restrict_code = p_time_restrict.time_restrict_code 

	MESSAGE "Record updated" 

	LABEL endtime_restrict19: 
	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

	MESSAGE "" 

END FUNCTION #u_time_restrict() 



###########################
FUNCTION end_time_restrict() 
	###########################

	CALL func_name ("End_time_restrict") 

	IF 
	time_restrict_cursor 
	THEN 
		CLOSE c_time_restrict 
		FREE c_time_restrict 
	END IF 

END FUNCTION #kraj_time_restrict() 


########################
FUNCTION time_restrict_lp() 
	########################
	DEFINE 
	a_time_restrict array[100] OF RECORD 
		time_restrict_code LIKE time_restrict.time_restrict_code, 
		time_restrict_name LIKE time_restrict.time_restrict_name 
	END RECORD, 
	a_time_restrict_name ARRAY [100] OF RECORD 
		time_restrict_name LIKE time_restrict.time_restrict_name 
	END RECORD, 
	cnt, 
	arr_max, 
	arr_full SMALLINT 

	LET arr_max = 100 
	LET arr_full = 1 

	OPEN WINDOW w_time_restrict_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	MESSAGE "Searching...please wait" 

	DECLARE c_time_restrict_lp CURSOR 
	FOR SELECT * FROM time_restrict 
	ORDER BY time_restrict_name 

	#####################################################
	FOREACH c_time_restrict_lp INTO a_time_restrict[arr_full].* 
		#####################################################

		LET a_time_restrict_name[arr_full].time_restrict_name = a_time_restrict[arr_full].time_restrict_name 

		LET arr_full = arr_full + 1 

		IF 
		arr_full = arr_max + 1 
		THEN 
			ERROR "Cannot load all codes..." 
			SLEEP 5 
			EXIT FOREACH 
		END IF 


		###########
	END FOREACH 
	###########

	MESSAGE "" 

	LET arr_full = arr_full - 1 

	CLOSE c_time_restrict_lp 
	FREE c_time_restrict_lp 

	CALL set_count(arr_full) 

	MESSAGE "SELECT AND press Accept" 

	DISPLAY ARRAY a_time_restrict_name TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-time_restrict-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 
	CLOSE WINDOW w_time_restrict_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null, gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_time_restrict[cnt].time_restrict_code, a_time_restrict[cnt].time_restrict_name 

END FUNCTION #time_restrict_lp() 

#########################################################################
#                        mailing_role
#########################################################################


#########################
FUNCTION m_mailing_role() 
	#########################

	CALL func_name ("M_mailing_role") 

	LET mailing_role_cursor = false 

	OPEN WINDOW mailing_role_w with FORM "mail_role" 
	CALL winDecoration("mail_role") -- albo kd-766 

	MENU "Mailing lists" #roles 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Mailing_lists-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query the table" #help 20000 
			CALL q_mailing_role() 

		COMMAND "+" "Next found" 
			CALL n_mailing_role() 

		COMMAND "-" "Previous found" 
			CALL pr_mailing_role() 

		COMMAND "Add" "Add new mailing list" 
			CALL a_mailing_role() 

		COMMAND "Update" "Change this mailing list" 
			CALL u_mailing_role() 

		COMMAND "Delete" "SET a valid_to date" 
			CALL delete_mailing_role() 

		COMMAND "List" "Show list of all mailing list names" 
			CALL mailing_role_lp(true) #and_hist 
			RETURNING dummy, dummy 

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "RETURN TO the previous menu" 
			CALL end_mailing_role() 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW mailing_role_w 


END FUNCTION #mailing_role() 


#############################
FUNCTION q_mailing_role() 
	#############################

	CALL FUNC_NAME("Q_mailing_role") 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT query_1 ON 
	mailing_role.mailing_name, 
	mailing_role.valid_from, 
	mailing_role.valid_to 
	FROM 
	mailing_name, 
	valid_from, 
	valid_to 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","maintain","construct-role-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF 
	int_flag <> 0 
	THEN 
		GOTO endmailing_role 
	END IF 

	LET query_1 ="SELECT * ", 
	"FROM mailing_role ", 
	"WHERE ", query_1 clipped 

	MESSAGE "Searching...please wait" 

	PREPARE s_mailing_role FROM query_1 

	DECLARE c_mailing_role SCROLL CURSOR FOR s_mailing_role 
	LET mailing_role_cursor = true 
	OPEN c_mailing_role 
	FETCH FIRST c_mailing_role INTO p_mailing_role.* 

	IF 
	status = notfound 
	THEN 
		LET exist_mailing_role = false 
		MESSAGE "There IS no mailing list with that name/code" #mailing role 
	ELSE 
		MESSAGE "" 
		LET exist_mailing_role = true 
		CALL disp_mailing_role() 
	END IF 

	LABEL endmailing_role: 

	MESSAGE "" 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

END FUNCTION #q_mailing_role() 

###############################
FUNCTION disp_mailing_role() 
	###############################


	DISPLAY p_mailing_role.* TO 
	s_code.mailing_role_code, 
	s_code.mailing_name, 
	s_code.valid_from, 
	s_code.valid_to, 
	s_code.select_sql, 
	s_code.select_desc 

	CALL assign_lines() 
	CALL display_lines() 


END FUNCTION #disp_mailing_role() 

#######################
FUNCTION assign_lines() 
	#######################

	LET p_select_desc2 = p_mailing_role.select_desc[71,140] 
	LET p_select_desc3 = p_mailing_role.select_desc[141,210] 
	LET p_select_desc4 = p_mailing_role.select_desc[211,280] 
	LET p_select_desc5 = p_mailing_role.select_desc[281,350] 
	LET p_select_desc6 = p_mailing_role.select_desc[351,420] 
	LET p_select_desc7 = p_mailing_role.select_desc[421,490] 
	LET p_select_desc8 = p_mailing_role.select_desc[491,560] 
	#                LET p_select_desc9 =  p_mailing_role.select_desc[561,630]


	LET p_select_sql2 = p_mailing_role.select_sql[71,140] 
	LET p_select_sql3 = p_mailing_role.select_sql[141,210] 
	LET p_select_sql4 = p_mailing_role.select_sql[211,280] 
	LET p_select_sql5 = p_mailing_role.select_sql[281,350] 
	LET p_select_sql6 = p_mailing_role.select_sql[351,420] 
	LET p_select_sql7 = p_mailing_role.select_sql[421,490] 
	LET p_select_sql8 = p_mailing_role.select_sql[491,560] 
	LET p_select_sql9 = p_mailing_role.select_sql[561,630] 

END FUNCTION #assign_lines() 

##########################
FUNCTION compose_lines() 
	##########################

	LET p_mailing_role.select_desc[71,140] = p_select_desc2 
	LET p_mailing_role.select_desc[141,210] = p_select_desc3 
	LET p_mailing_role.select_desc[211,280] = p_select_desc4 
	LET p_mailing_role.select_desc[281,350] = p_select_desc5 
	LET p_mailing_role.select_desc[351,420] = p_select_desc6 
	LET p_mailing_role.select_desc[421,490] = p_select_desc7 
	LET p_mailing_role.select_desc[491,560] = p_select_desc8 
	#                LET p_mailing_role.select_desc[561,630] = p_select_desc9


	LET p_mailing_role.select_sql[71,140] = p_select_sql2 
	LET p_mailing_role.select_sql[141,210] = p_select_sql3 
	LET p_mailing_role.select_sql[211,280] = p_select_sql4 
	LET p_mailing_role.select_sql[281,350] = p_select_sql5 
	LET p_mailing_role.select_sql[351,420] = p_select_sql6 
	LET p_mailing_role.select_sql[421,490] = p_select_sql7 
	LET p_mailing_role.select_sql[491,560] = p_select_sql8 
	LET p_mailing_role.select_sql[561,630] = p_select_sql9 

END FUNCTION #compose_lines() 

########################
FUNCTION display_lines() 
	########################

	DISPLAY p_select_desc2 TO s_code.select_desc2 
	DISPLAY p_select_desc3 TO s_code.select_desc3 
	DISPLAY p_select_desc4 TO s_code.select_desc4 
	DISPLAY p_select_desc5 TO s_code.select_desc5 
	DISPLAY p_select_desc6 TO s_code.select_desc6 
	DISPLAY p_select_desc7 TO s_code.select_desc7 
	DISPLAY p_select_desc8 TO s_code.select_desc8 
	# DISPLAY p_select_desc9 TO s_code.select_desc9


	DISPLAY p_select_sql2 TO s_code.select_sql2 
	DISPLAY p_select_sql3 TO s_code.select_sql3 
	DISPLAY p_select_sql4 TO s_code.select_sql4 
	DISPLAY p_select_sql5 TO s_code.select_sql5 
	DISPLAY p_select_sql6 TO s_code.select_sql6 
	DISPLAY p_select_sql7 TO s_code.select_sql7 
	DISPLAY p_select_sql8 TO s_code.select_sql8 
	DISPLAY p_select_sql9 TO s_code.select_sql9 


END FUNCTION #display_lines() 


##############################
FUNCTION n_mailing_role() 
	##############################
	CALL func_name ("N_mailing_role") 

	IF 
	exist_mailing_role 
	THEN 
		FETCH NEXT c_mailing_role INTO p_mailing_role.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			CALL disp_mailing_role() 
		END IF 

	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #n_mailing_role() 

##################################
FUNCTION pr_mailing_role() 
	##################################

	CALL func_name ("Pr_mailing_role") 

	IF 
	exist_mailing_role 
	THEN 
		FETCH previous c_mailing_role INTO p_mailing_role.* 
		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			CALL disp_mailing_role() 
		END IF 
	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #pr_mailing_role() 

###############################
FUNCTION a_mailing_role() 
	###############################

	CALL func_name ("A_mailing_role") 

	MESSAGE "" 
	CLEAR FORM 

	INPUT #by NAME 
	p_mailing_role.mailing_name, 
	p_mailing_role.valid_from, 
	p_mailing_role.valid_to, 
	p_mailing_role.select_sql, 
	p_select_sql2, 
	p_select_sql3, 
	p_select_sql4, 
	p_select_sql5, 
	p_select_sql6, 
	p_select_sql7, 
	p_select_sql8, 
	p_select_sql9, 

	p_mailing_role.select_desc, 
	p_select_desc2, 
	p_select_desc3, 
	p_select_desc4, 
	p_select_desc5, 
	p_select_desc6, 
	p_select_desc7, 
	p_select_desc8 
	#					p_select_desc9


	FROM 
	#					s_code.mailing_role_code,
	s_code.mailing_name, 
	s_code.valid_from, 
	s_code.valid_to, 
	s_code.select_sql, 
	s_code.select_sql2, 
	s_code.select_sql3, 
	s_code.select_sql4, 
	s_code.select_sql5, 
	s_code.select_sql6, 
	s_code.select_sql7, 
	s_code.select_sql8, 
	s_code.select_sql9, 

	s_code.select_desc, 
	s_code.select_desc2, 
	s_code.select_desc3, 
	s_code.select_desc4, 
	s_code.select_desc5, 
	s_code.select_desc6, 
	s_code.select_desc7, 
	s_code.select_desc8 
	#					s_code.select_desc9

	# HELP 229

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-p_select-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			###########
		AFTER INPUT 
			###########

			IF int_flag THEN 
				EXIT INPUT 
			END IF 


			IF 
			p_mailing_role.mailing_name IS NULL 
			OR 
			length(P_mailing_role.mailing_name) < 1 
			THEN 
				ERROR "Please enter the mailing_role NAME" 
				NEXT FIELD mailing_name 
			ELSE 
				#CALL check_stmt()
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########

	CALL compose_lines() 

	IF 
	int_flag <> 0 
	THEN 
		GOTO endmailing_role17 
	END IF 

	LET p_mailing_role.mailing_role_code = 0 

	IF 
	p_mailing_role.valid_from IS NULL 
	THEN 
		LET p_mailing_role.valid_from = today 
	END IF 

	INSERT INTO mailing_role VALUES (p_mailing_role.*) 

	MESSAGE "New RECORD added" 

	LABEL endmailing_role17: 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
		CLEAR FORM 
	END IF 

	MESSAGE "" 

END FUNCTION #a_mailing_role() 

############################
FUNCTION u_mailing_role() 
	############################

	CALL func_name ("U_mailing_role") 

	INPUT 
	p_mailing_role.mailing_name, 
	p_mailing_role.valid_to, 
	p_mailing_role.select_sql, 
	p_select_sql2, 
	p_select_sql3, 
	p_select_sql4, 
	p_select_sql5, 
	p_select_sql6, 
	p_select_sql7, 
	p_select_sql8, 
	p_select_sql9, 

	p_mailing_role.select_desc, 
	p_select_desc2, 
	p_select_desc3, 
	p_select_desc4, 
	p_select_desc5, 
	p_select_desc6, 
	p_select_desc7, 
	p_select_desc8 
	#					p_select_desc9


	WITHOUT DEFAULTS 

	#add valid_from / TO

	FROM 
	s_code.mailing_name, 
	s_code.valid_to, 
	s_code.select_sql, 
	s_code.select_sql2, 
	s_code.select_sql3, 
	s_code.select_sql4, 
	s_code.select_sql5, 
	s_code.select_sql6, 
	s_code.select_sql7, 
	s_code.select_sql8, 
	s_code.select_sql9, 

	s_code.select_desc, 
	s_code.select_desc2, 
	s_code.select_desc3, 
	s_code.select_desc4, 
	s_code.select_desc5, 
	s_code.select_desc6, 
	s_code.select_desc7, 
	s_code.select_desc8 
	#					s_code.select_desc9

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-p_select-2") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#HELP 229

			###########
		AFTER INPUT 
			###########

			IF 
			p_mailing_role.mailing_name IS NULL 
			OR 
			length(P_mailing_role.mailing_name) < 1 
			THEN 
				ERROR "Please enter the mailing_role NAME" 
				NEXT FIELD NAME 
			ELSE 
				#CALL check_stmt()
				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########

	IF 
	int_flag <> 0 
	THEN 
		GOTO endmailing_role19 
	END IF 

	CALL compose_lines() 



	UPDATE mailing_role 
	SET mailing_role.mailing_name = p_mailing_role.mailing_name, 
	mailing_role.valid_to = p_mailing_role.valid_to, 
	mailing_role.select_sql = p_mailing_role.select_sql, 
	mailing_role.select_desc = p_mailing_role.select_desc 
	WHERE mailing_role.mailing_role_code = p_mailing_role.mailing_role_code 

	MESSAGE "Record updated" 

	LABEL endmailing_role19: 
	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

	MESSAGE "" 

END FUNCTION #u_mailing_role() 


################################
FUNCTION delete_mailing_role() 
	################################
	CALL func_name ("delete_mailing_role") 
	MENU "Delete" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Delete-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Cancel" "Do NOT delete" 
			EXIT MENU 

		COMMAND "OK" "Set valid_to date TO fixed date" 

			INPUT p_mailing_role.valid_to WITHOUT DEFAULTS 
			FROM s_code.valid_to 

			#HELP 229
			############
				BEFORE INPUT 
					############
					CALL publish_toolbar("kandoo","maintain","input-mailing_role-1") -- albo kd-513 
					LET p_mailing_role.valid_to = today 
					DISPLAY p_mailing_role.valid_to TO s_code.valid_to 

				ON ACTION "WEB-HELP" -- albo 
					CALL onlinehelp(getmoduleid(),null) 
					#########
			END INPUT 
			#########

			IF 
			int_flag <> 0 
			THEN 
				GOTO endmailing_role192 
			END IF 

			UPDATE mailing_role 
			SET mailing_role.valid_to = p_mailing_role.valid_to 
			WHERE mailing_role.mailing_role_code = p_mailing_role.mailing_role_code 

			MESSAGE "Record updated" 

			LABEL endmailing_role192: 
			IF 
			int_flag <> 0 
			THEN 
				LET int_flag=0 
			END IF 

			MESSAGE "" 

	END MENU 



END FUNCTION 


###########################
FUNCTION end_mailing_role() 
	###########################

	CALL func_name ("End_mailing_role") 

	IF 
	mailing_role_cursor 
	AND 
	mailing_role_cursor IS NOT NULL 
	AND 
	p_mailing_role.mailing_role_code IS NOT NULL 
	THEN 
		CLOSE c_mailing_role 
		FREE c_mailing_role 
	END IF 

END FUNCTION #kraj_mailing_role() 


##################################
FUNCTION mailing_role_lp(and_hist) 
	##################################
	DEFINE 
	a_mailing_role array[100] OF RECORD 
		mailing_role_code LIKE mailing_role.mailing_role_code, 
		mailing_role_name LIKE mailing_role.mailing_name 

	END RECORD, 

	a_mailing_role_name ARRAY [100] OF RECORD 
		mailing_role_name LIKE mailing_role.mailing_name 
	END RECORD, 
	cnt, 
	arr_max, 
	and_hist, 
	arr_full 
	SMALLINT, 
	where_part CHAR(300) 


	LET arr_max = 100 
	LET arr_full = 1 

	OPEN WINDOW w_mailing_role_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	LET where_part = "SELECT mailing_role_code, mailing_name FROM mailing_role " 

	IF NOT and_hist THEN 
		LET where_part = where_part clipped, 
		" WHERE mailing_role.valid_to IS NULL OR mailing_role.valid_to > today" 
	END IF 

	LET where_part = where_part clipped, " ORDER BY mailing_name " 
	MESSAGE "Searching...please wait" 
	PREPARE xz23 FROM where_part 
	DECLARE c_mailing_role_lp CURSOR FOR xz23 

	#####################################################
	FOREACH c_mailing_role_lp INTO a_mailing_role[arr_full].* 
		#####################################################

		LET a_mailing_role_name[arr_full].mailing_role_name = 
		a_mailing_role[arr_full].mailing_role_name 

		LET arr_full = arr_full + 1 

		IF 
		arr_full = arr_max + 1 
		THEN 
			ERROR "Cannot load all codes..." 
			SLEEP 5 
			EXIT FOREACH 
		END IF 


		###########
	END FOREACH 
	###########

	MESSAGE "" 

	LET arr_full = arr_full - 1 

	CLOSE c_mailing_role_lp 
	FREE c_mailing_role_lp 

	CALL set_count(arr_full) 

	MESSAGE "SELECT AND press Accept" 

	DISPLAY ARRAY a_mailing_role_name TO s_name.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-mailing_role-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END DISPLAY 

	CLOSE WINDOW w_mailing_role_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null, gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_mailing_role[cnt].mailing_role_code, a_mailing_role[cnt].mailing_role_name 

END FUNCTION #mailing_role_lp() 


#########################################################################
#                   role
#########################################################################


#########################
FUNCTION m_role() 
	#########################

	CALL func_name ("M_role") 

	OPEN WINDOW role_w with FORM "role_x" 
	CALL winDecoration("role_x") -- albo kd-766 

	LET role_cursor = false 

	MENU "Roles codes" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Roles_codes-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query the table" #help 20000 
			CALL q_role() 

		COMMAND "+" "Next found" 
			CALL n_role() 

		COMMAND "-" "Previous found" 
			CALL pr_role() 

		COMMAND "Add" "Add new code" 
			CALL a_role() 

		COMMAND "Update" "Change this code name" 
			CALL u_role() 

		COMMAND "List" "Show list of all roles FOR one class" 
			CALL role_lp(role_class_lp()) RETURNING dummy, dummy 

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "RETURN TO the previous menu" 
			CALL end_role() 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW role_w 


END FUNCTION #role() 


#############################
FUNCTION q_role() 
	#############################

	CALL FUNC_NAME("Q_role") 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT query_1 ON 
	role.class_name, 
	role.role_name, 
	role.role_name_invert 
	FROM 
	class_name, 
	role_name, 
	role_name_invert 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","maintain","construct-role-2") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF 
	int_flag <> 0 
	THEN 
		GOTO endrole 
	END IF 

	LET query_1 ="SELECT * ", 
	"FROM role ", 
	"WHERE ", query_1 clipped, 
	" ORDER BY class_name " 

	MESSAGE "Searching...please wait" 
	PREPARE s_role FROM query_1 

	DECLARE c_role SCROLL CURSOR FOR s_role 
	LET role_cursor = true 
	OPEN c_role 

	FETCH FIRST c_role INTO p_role.* 

	IF 
	status = notfound 
	THEN 
		LET exist_role = false 
		MESSAGE "There IS no role with that name" 
	ELSE 
		MESSAGE "" 
		LET exist_role = true 
		DISPLAY BY NAME p_role.* #to s_code.* 
	END IF 

	LABEL endrole: 

	MESSAGE "" 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

END FUNCTION #q_role() 

##############################
FUNCTION n_role() 
	##############################
	CALL func_name ("N_role") 

	IF 
	exist_role 
	THEN 
		FETCH NEXT c_role INTO p_role.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_role.* TO s_code.* 
		END IF 

	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #n_role() 

##################################
FUNCTION pr_role() 
	##################################

	CALL func_name ("Pr_role") 

	IF 
	exist_role 
	THEN 
		FETCH previous c_role INTO p_role.* 
		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
		ELSE 
			DISPLAY p_role.* TO s_code.* 
		END IF 
	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #pr_role() 

###############################
FUNCTION a_role() 
	###############################

	CALL func_name ("A_role") 

	MESSAGE "" 
	CLEAR FORM 

	INPUT p_role.* FROM s_code.* 
	# HELP 229

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-role-2") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############
		ON KEY (F10) 
			############

			IF infield (class_name) THEN 
				LET p_role.class_name = role_class_lp() 
				DISPLAY BY NAME p_role.class_name 
			END IF 

			######################
		AFTER FIELD class_name 
			######################
			IF NOT is_valid_role_class(p_role.class_name) THEN 
				LET p_role.class_name = role_class_lp() 
				DISPLAY BY NAME p_role.class_name 
			END IF 

			###########
		AFTER INPUT 
			###########

			IF int_flag THEN 
				EXIT INPUT 
			END IF 

			IF 
			p_role.role_name IS NULL 
			OR 
			length(P_role.role_name) < 1 
			THEN 
				ERROR "Please enter the role NAME" 
				NEXT FIELD role_name 
			ELSE 
				IF NOT is_valid_role_class(p_role.class_name) THEN 
					LET p_role.class_name = role_class_lp() 
					DISPLAY BY NAME p_role.class_name 
				END IF 

				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########


	IF 
	int_flag <> 0 
	THEN 
		GOTO endrole17 
	END IF 

	LET p_role.role_code = 0 


	INSERT INTO role VALUES (p_role.*) 

	MESSAGE "New RECORD added" 

	LABEL endrole17: 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
		CLEAR FORM 
	END IF 

	MESSAGE "" 

END FUNCTION #a_role() 

############################
FUNCTION u_role() 
	############################

	CALL func_name ("U_role") 

	INPUT 
	p_role.role_name, 
	p_role.class_name, 
	p_role.role_name_invert 

	WITHOUT DEFAULTS 
	FROM 
	s_code.role_name, 
	s_code.class_name, 
	s_code.role_name_invert 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","maintain","input-role-3") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			#HELP 229
			############
		ON KEY (F10) 
			############

			IF infield (class_name) THEN 
				LET p_role.class_name = role_class_lp() 
				DISPLAY BY NAME p_role.class_name 
			END IF 

			######################
		BEFORE FIELD role_name 
			######################

			IF p_role.role_name = "DEFAULT" THEN 
				NEXT FIELD NEXT 
			END IF 


			######################
		AFTER FIELD class_name 
			######################

			IF NOT is_valid_role_class(p_role.class_name) THEN 
				LET p_role.class_name = role_class_lp() 
				DISPLAY BY NAME p_role.class_name 
			END IF 



			###########
		AFTER INPUT 
			###########

			IF 
			p_role.role_name IS NULL 
			OR 
			length(P_role.role_name) < 1 
			THEN 
				ERROR "Please enter the role NAME" 
				NEXT FIELD NAME 
			ELSE 
				IF NOT is_valid_role_class(p_role.class_name) THEN 
					LET p_role.class_name = role_class_lp() 
					DISPLAY BY NAME p_role.class_name 
				END IF 

				EXIT INPUT 
			END IF 

			#########
	END INPUT 
	#########

	IF 
	int_flag <> 0 
	THEN 
		GOTO endrole19 
	END IF 

	UPDATE role 
	SET 
	role.role_name = p_role.role_name, 
	role.class_name = p_role.class_name, 
	role.role_name_invert = p_role.role_name_invert 

	WHERE role.role_code = p_role.role_code 

	MESSAGE "Record updated" 

	LABEL endrole19: 
	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

	MESSAGE "" 

END FUNCTION #u_role() 



###########################
FUNCTION end_role() 
	###########################

	CALL func_name ("End_role") 

	IF 
	role_cursor 
	AND 
	role_cursor IS NOT NULL 
	AND 
	p_role.role_code IS NOT NULL 
	THEN 
		CLOSE c_role 
		FREE c_role 
	END IF 

END FUNCTION #kraj_role() 


##############################
FUNCTION role_lp(p_class_name) 
	##############################
	DEFINE 
	a_role array[100] OF RECORD 
		role_code LIKE role.role_code, 
		class_name LIKE role.class_name, 
		role_name LIKE role.role_name, 
		role_name_invert LIKE role.role_name_invert 
	END RECORD, 
	a_role_name ARRAY [100] OF RECORD 
		role_name LIKE role.role_name 
	END RECORD, 
	cnt, 
	arr_max, 
	arr_full SMALLINT, 
	p_class_name LIKE role.class_name 

	LET arr_max = 100 
	LET arr_full = 1 


	IF p_class_name IS NULL 
	OR length(p_class_name) < 2 THEN 
		ERROR "Invalid role class name in maintain.4gl role_lp()" 
		SLEEP 3 
		RETURN gv_null, gv_null 
	END IF 

	OPEN WINDOW w_role_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 
	MESSAGE "Searching...please wait" 
	DECLARE c_role_lp CURSOR 
	FOR SELECT * FROM role 
	WHERE class_name = p_class_name 
	ORDER BY role_name 

	#######################################
	FOREACH c_role_lp INTO a_role[arr_full].* 
		#######################################

		LET a_role_name[arr_full].role_name = a_role[arr_full].role_name 

		LET arr_full = arr_full + 1 

		IF 
		arr_full = arr_max + 1 
		THEN 
			ERROR "Cannot load all codes..." 
			SLEEP 5 
			EXIT FOREACH 
		END IF 


		###########
	END FOREACH 
	###########

	MESSAGE "" 

	LET arr_full = arr_full - 1 

	CLOSE c_role_lp 
	FREE c_role_lp 

	CALL set_count(arr_full) 

	MESSAGE "SELECT AND press Accept" 

	DISPLAY ARRAY a_role_name TO s_name.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-role_name-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 
	END DISPLAY 
	CLOSE WINDOW w_role_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null, gv_null 
	END IF 

	LET cnt = arr_curr() #scr_line() 

	RETURN a_role[cnt].role_code, a_role[cnt].role_name 

END FUNCTION #role_lp() 


###########################
FUNCTION role_class_lp() 
	###########################
	DEFINE 
	a_class_name ARRAY [10] OF 
	CHAR(20), 
	cnt SMALLINT 

	LET a_class_name[1] = "PHONE" 
	LET a_class_name[2] = "ADDRESS" 
	LET a_class_name[3] = "MAIL TERMINATION" 
	LET a_class_name[4] = "AGE" 
	LET a_class_name[5] = "CONTACT ROLE" 
	LET a_class_name[6] = "BANK ACCOUNT" 
	LET a_class_name[7] = "CREDIT CARD" 
	LET a_class_name[8] = "RELATION" 

	CALL set_count(8) 

	OPEN WINDOW w_class_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	MESSAGE "SELECT AND press Accept" 

	DISPLAY ARRAY a_class_name TO s_name.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-class_name-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 
	END DISPLAY 
	LET cnt = arr_curr() #scr_line() 

	CLOSE WINDOW w_class_lp 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag = 0 
		RETURN gv_null 
	END IF 

	RETURN a_class_name[cnt] 

END FUNCTION #role_class_lp() 

##########################################
FUNCTION is_valid_role_class(p_class_name) 
	##########################################
	DEFINE 
	a_class_name ARRAY [10] OF 
	CHAR(20), 
	cnt, is_valid SMALLINT, 
	p_class_name CHAR(20) 

	LET a_class_name[1] = "PHONE" 
	LET a_class_name[2] = "ADDRESS" 
	LET a_class_name[3] = "MAIL TERMINATION" 
	LET a_class_name[4] = "AGE" 
	LET a_class_name[5] = "CONTACT ROLE" 
	LET a_class_name[6] = "BANK ACCOUNT" 
	LET a_class_name[7] = "CREDIT CARD" 
	LET a_class_name[8] = "RELATION" 


	LET is_valid = false 

	#################
	FOR cnt = 1 TO 10 
		#################
		IF p_class_name = a_class_name[cnt] THEN 
			LET is_valid = true 
			EXIT FOR 
		END IF 
		#######
	END FOR 
	#######


	RETURN is_valid 

END FUNCTION #role_class_lp() 


#########################################################################
#                        mailing_dates
#########################################################################


#########################
FUNCTION m_mailing_dates() 
	#########################

	CALL func_name ("M_mailing_dates") 

	OPEN WINDOW mailing_dates_w with FORM "mail_date" 
	CALL winDecoration("mail_date") -- albo kd-766 

	MENU "Mailing dates" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Mailing_dates-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" "Query the table" 
			CALL q_mailing_dates() 

		COMMAND "+" "Next found" 
			CALL n_mailing_dates() 

		COMMAND "-" "Previous found" 
			CALL pr_mailing_dates() 

		COMMAND "Add" "Add new mailing date" 
			CALL au_mailing_dates(true) 

		COMMAND "Update" "Change this mailing date" 
			CALL au_mailing_dates(false) 

		COMMAND "List" "Show all mailing dates" 
			CALL mailing_dates_lp() RETURNING dummy, dummy 

		COMMAND KEY ("X", "x",interrupt,escape) "eXit" "RETURN TO the previous menu" 
			CALL end_mailing_dates() 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW mailing_dates_w 


END FUNCTION #mailing_dates() 


#############################
FUNCTION q_mailing_dates() 
	#############################
	DEFINE 
	where_part 
	CHAR(300) 

	CALL FUNC_NAME("Q_mailing_dates") 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT where_part ON 
	mailing_role.mailing_name, 
	mailing_dates.mail_date, 
	mailing_dates.user_id_prepared, 
	mailing_dates.date_prepared, 
	mailing_dates.date_completed 
	FROM 
	s_mailing_dates.mailing_name, 
	s_mailing_dates.mail_date, 
	s_mailing_dates.user_id_prepared, 
	s_mailing_dates.date_prepared, 
	s_mailing_dates.date_completed 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","maintain","construct-role-3") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF 
	int_flag <> 0 
	THEN 
		GOTO endmailing_dates 
	END IF 

	LET query_1 ="SELECT mailing_dates.* FROM mailing_dates " 

	IF 
	query_1 matches "*mailing_role.mailing_name*" 
	THEN 
		LET query_1 = query_1 clipped, " ,mailing_role " 
	END IF 

	LET query_1 = query_1 clipped, " WHERE ", where_part clipped 

	IF 
	query_1 matches "*mailing_role.mailing_name*" 
	THEN 
		LET query_1 = query_1 clipped, 
		" AND mailing_role.mailing_role_code = mailing_dates.mailing_role_code " 
	END IF 

	IF 
	do_debug 
	THEN 
		CALL errorlog(query_1) 
	END IF 

	#SELECT mailing_dates.* FROM mailing_dates WHERE SELECT mailing_dates.* FROM mailing_dates

	MESSAGE "Searching...please wait" 

	PREPARE s_mailing_dates FROM query_1 

	DECLARE c_mailing_dates SCROLL CURSOR FOR s_mailing_dates 
	LET mailing_dates_cursor = true 
	OPEN c_mailing_dates 

	FETCH FIRST c_mailing_dates INTO p_mailing_dates.* 

	IF 
	status = notfound 
	THEN 
		LET exist_mailing_dates = false 
		MESSAGE "There IS no mailing_dates with that name/code" 
	ELSE 
		MESSAGE "" 
		LET exist_mailing_dates = true 
		CALL disp_mailing_dates() 
	END IF 

	LABEL endmailing_dates: 

	MESSAGE "" 

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
	END IF 

END FUNCTION #q_mailing_dates() 

#############################
FUNCTION disp_mailing_dates() 
	#############################
	DEFINE 
	p_mailing_name 
	LIKE mailing_role.mailing_name 

	DISPLAY p_mailing_dates.mail_date, 
	p_mailing_dates.user_id_prepared, 
	p_mailing_dates.date_prepared, 
	p_mailing_dates.date_completed 

	TO s_mailing_dates.mail_date, 
	s_mailing_dates.user_id_prepared, 
	s_mailing_dates.date_prepared, 
	s_mailing_dates.date_completed 


	SELECT mailing_name INTO p_mailing_name 
	FROM mailing_role 
	WHERE mailing_role_code = p_mailing_dates.mailing_role_code 

	DISPLAY p_mailing_name TO s_mailing_dates.mailing_name 


END FUNCTION 


##############################
FUNCTION n_mailing_dates() 
	##############################
	CALL func_name ("N_mailing_dates") 

	IF 
	exist_mailing_dates 
	THEN 
		FETCH NEXT c_mailing_dates INTO p_mailing_dates.* 

		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			CALL disp_mailing_dates() 
			SLEEP 1 
		ELSE 
			CALL disp_mailing_dates() 
		END IF 

	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #n_mailing_dates() 

##################################
FUNCTION pr_mailing_dates() 
	##################################

	CALL func_name ("Pr_mailing_dates") 

	IF 
	exist_mailing_dates 
	THEN 
		FETCH previous c_mailing_dates INTO p_mailing_dates.* 
		IF 
		status = notfound 
		THEN 
			MESSAGE "No more RECORD in this direction" 
			SLEEP 1 
			CALL disp_mailing_dates() 
		ELSE 
			CALL disp_mailing_dates() 
		END IF 
	ELSE 
		MESSAGE "Enter the query condition first" 
		SLEEP 1 
	END IF 

END FUNCTION #pr_mailing_dates() 

###############################
FUNCTION au_mailing_dates(add_mode) 
	###############################
	DEFINE 
	p_mailing_name 
	LIKE mailing_role.mailing_name, 
	add_mode 
	SMALLINT, 
	p_store_mailing_dates RECORD LIKE mailing_dates.* 

	CALL func_name ("Au_mailing_dates") 

	IF NOT add_mode THEN 
		SELECT mailing_name INTO p_mailing_name 
		FROM mailing_role 
		WHERE mailing_role_code = p_mailing_dates.mailing_role_code 

		LET p_store_mailing_dates.* = p_mailing_dates.* 
		MESSAGE "Enter changes AND press Accept" 
	ELSE 
		CLEAR FORM 
		INITIALIZE p_mailing_dates.* TO NULL 
		MESSAGE "Enter new mailing event AND press Accept" 
	END IF 

	#####
	INPUT 
	#####
	p_mailing_name, 
	p_mailing_dates.mail_date, 
	#p_mailing_dates.user_id_prepared,
	#p_mailing_dates.date_prepared,
	p_mailing_dates.date_completed 
	WITHOUT DEFAULTS FROM 
	s_mailing_dates.mailing_name, 
	s_mailing_dates.mail_date, 
	#s_mailing_dates.user_id_prepared,
	#s_mailing_dates.date_prepared,
	s_mailing_dates.date_completed 

	# HELP 229

	############
		BEFORE INPUT 
			############
			CALL publish_toolbar("kandoo","maintain","input-role-4") -- albo kd-513 
			IF NOT add_mode THEN 
				DISPLAY p_mailing_name TO s_mailing_dates.mailing_name 
			END IF 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			############
		ON KEY (f10) 
			############

			####
			CASE 
			####
				WHEN infield (mailing_name) 
					CALL mailing_role_lp(false) #and_hist 
					RETURNING p_mailing_dates.mailing_role_code, p_mailing_name 

					DISPLAY p_mailing_name TO s_mailing_dates.mailing_name 

					########
			END CASE 
			########

			###########################
		BEFORE FIELD date_completed 
			###########################
			IF add_mode THEN 
				NEXT FIELD NEXT 
			END IF 

			###########
		AFTER INPUT 
			###########

			IF int_flag <> 0 THEN 
				EXIT INPUT 
			END IF 

			LET p_mailing_dates.user_id_prepared = glob_rec_kandoouser.sign_on_code 
			LET p_mailing_dates.date_prepared = today 

			IF 
			p_mailing_name IS NULL 
			OR 
			length(P_mailing_name) < 1 
			THEN 
				ERROR "Please enter the mailing_dates NAME" 
				NEXT FIELD mailing_name 
			ELSE 
				SELECT mailing_role_code INTO p_mailing_dates.mailing_role_code 
				FROM mailing_role 
				WHERE mailing_name = p_mailing_name 
				IF status = notfound THEN 
					ERROR "Please enter valid mailing list NAME" #mailing role 
					SLEEP 1 
					NEXT FIELD mailing_name 
				ELSE 
					EXIT INPUT 
				END IF 
			END IF 

			#########
	END INPUT 
	#########

	IF 
	int_flag <> 0 
	THEN 
		LET int_flag=0 
		CLEAR FORM 
	ELSE 
		IF add_mode THEN 

			INSERT INTO mailing_dates VALUES (p_mailing_dates.*) 

			IF status <> 0 THEN 
				ERROR "Cannot add" 
				SLEEP 3 
			ELSE 
				MESSAGE "New RECORD added" 
			END IF 

		ELSE 

			#			error p_mailing_dates.mailing_role_code sleep 5

			UPDATE mailing_dates 
			SET mailing_dates.* = p_mailing_dates.* 
			WHERE mailing_dates.mailing_role_code = p_store_mailing_dates.mailing_role_code 
			AND mailing_dates.mail_date = p_store_mailing_dates.mail_date 
			AND mailing_dates.user_id_prepared = p_store_mailing_dates.user_id_prepared 
			AND mailing_dates.date_prepared = p_store_mailing_dates.date_prepared 
			AND (mailing_dates.date_completed = p_store_mailing_dates.date_completed 
			OR 
			mailing_dates.date_completed IS null) 

			IF 
			status <> 0 
			THEN 
				ERROR "Cannot UPDATE" 
				SLEEP 3 
			ELSE 
				MESSAGE "Record updated" 
			END IF 

		END IF 
	END IF 

	MESSAGE "" 

END FUNCTION #a_mailing_dates() 


###########################
FUNCTION end_mailing_dates() 
	###########################

	CALL func_name ("End_mailing_dates") 

	IF 
	mailing_dates_cursor 
	THEN 
		CLOSE c_mailing_dates 
		FREE c_mailing_dates 
	END IF 

END FUNCTION #kraj_mailing_dates() 



############################
FUNCTION mailing_dates_lp() 
	############################
	DEFINE 
	p_mailing_role_code LIKE mailing_dates.mailing_role_code, 
	p_mail_date LIKE mailing_dates.mail_date, 

	a_mailing_dates ARRAY [100] OF RECORD 
		mailing_role_code LIKE mailing_role.mailing_role_code, 
		mail_date LIKE mailing_dates.mail_date, 
		user_id_prepared LIKE mailing_dates.user_id_prepared, 
		date_prepared LIKE mailing_dates.date_prepared, 
		date_completed LIKE mailing_dates.date_completed 
	END RECORD, 

	a_display ARRAY [100] OF RECORD 
		mailing_name LIKE mailing_role.mailing_name, 
		mail_date LIKE mailing_dates.mail_date, 
		user_id_prepared LIKE mailing_dates.user_id_prepared, 
		date_prepared LIKE mailing_dates.date_prepared, 
		date_completed LIKE mailing_dates.date_completed 
	END RECORD, 
	cnt, 
	and_exit 
	SMALLINT 


	OPEN WINDOW w_mailing_dates with FORM "mailing_da" 
	CALL winDecoration("mailing_da") -- albo kd-766 

	MESSAGE "Searching...please wait" 
	DECLARE c_mail_dates CURSOR FOR 
	SELECT * FROM mailing_dates 
	#WHERE date_completed IS NULL

	LET cnt = 1 

	################################################
	FOREACH c_mail_dates INTO a_mailing_dates[cnt].* 
		################################################

		SELECT mailing_role.mailing_name INTO a_display[cnt].mailing_name 
		FROM mailing_role 
		WHERE mailing_role_code = a_mailing_dates[cnt].mailing_role_code 

		LET a_display[cnt].mail_date = a_mailing_dates[cnt].mail_date 
		LET a_display[cnt].user_id_prepared = a_mailing_dates[cnt].user_id_prepared 
		LET a_display[cnt].date_prepared = a_mailing_dates[cnt].date_prepared 
		LET a_display[cnt].date_completed = a_mailing_dates[cnt].date_completed 

		LET cnt = cnt + 1 

		###########
	END FOREACH 
	###########

	MESSAGE "" 

	CLOSE c_mail_dates 
	FREE c_mail_dates 

	LET cnt = cnt - 1 
	CALL set_count(cnt) 

	MESSAGE "SELECT AND press Accept (F10=Show recipients)" 


	#########################################
	DISPLAY ARRAY a_display TO s_display.* 
	#########################################

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","maintain","display_arr-a_display-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			##########
		BEFORE ROW #for <suse> 
			{! BEFORE ROW !} #FOR <Anton Dickinson>
			#Informix:
			#|_____________^
			#|
			#|      A grammatical error has been found on line 2529, character 15.
			#| The CONSTRUCT IS NOT understandable in its context.
			#| See error number -4373.
			##########
			IF 
			and_exit 
			THEN 
				EXIT DISPLAY 
				{! EXIT DISPLAY !}
				#Informix
				#|
				#|      The program cannot EXIT a DISPLAY ARRAY statement AT this point because
				#| it IS NOT within a DISPLAY ARRAY statement.
				#| See error number -4628.
			END IF 

			############
		ON KEY (F10) 
			{!  ON KEY (F10) !}
			#Informix
			#|_____________^
			#|
			#|      A grammatical error has been found on line 2545, character 15.
			#| The CONSTRUCT IS NOT understandable in its context.
			#| See error number -4373.
			############
			LET cnt = arr_curr() #scr_line() 
			LET dummy = show_recipients(a_mailing_dates[cnt].mailing_role_code, 
			a_mailing_dates[cnt].mail_date) 

			###########
	END DISPLAY 
	{! END DISPLAY !}
	#Informix:
	#|__________________^
	#|
	#|      A grammatical error has been found on line 2545, character 20.
	#| The CONSTRUCT IS NOT understandable in its context.
	#| See error number -4373.
	###########

	CLOSE WINDOW w_mailing_dates 


	IF int_flag THEN 
		RETURN gv_null, gv_null 
	ELSE 
		RETURN p_mailing_role_code, p_mail_date 
	END IF 

END FUNCTION #mailing_dates_lp() 

#########################################################
FUNCTION show_recipients(p_mailing_role_code,p_mail_date) 
	#########################################################
	DEFINE 
	tmp_last LIKE contact.last_org_name, 
	tmp_first LIKE contact.first_name, 
	p_mailing_role_code LIKE mailing_dates.mailing_role_code, 
	p_mail_date LIKE mailing_dates.mail_date, 
	p_address RECORD LIKE address.*, 
	p_contact_id LIKE contact.contact_id, 
	p_address_id LIKE address.address_id, 
	where_part 
	CHAR (1000), 
	a_all_recp array[1000] OF RECORD 
		contact_id LIKE contact_address.contact_id, 
		address_id LIKE contact_address.address_id 
	END RECORD, 

	all_addr_owners_cnt 
	SMALLINT, 

	a_names array[1000] OF RECORD 
		NAME CHAR(15) 
	END RECORD, 
	cnt 
	SMALLINT, 
	tmp_name 
	CHAR(100) 

	IF do_debug THEN 
		CALL errorlog (p_mailing_role_code) 
		CALL errorlog (p_mail_date) 
	END IF 

	LET where_part = 

	" SELECT unique contact_id, address_id ", 
	" FROM contact_mailing, mailing_dates, mailing_role ", 
	" WHERE mailing_role.mailing_role_code = mailing_dates.mailing_role_code ", 
	" AND mailing_role.mailing_role_code = contact_mailing.mailing_role_code ", 
	" AND contact_mailing.valid_from <= mailing_dates.mail_date ", 
	" AND (contact_mailing.valid_to >= mailing_dates.mail_date OR contact_mailing.valid_to IS NULL) ", 
	" AND mailing_dates.mailing_role_code = ", p_mailing_role_code, 
	" AND mailing_dates.mail_date = '", p_mail_date, "' " 
	#," group by address_id "

	IF do_debug THEN 
		CALL errorlog(where_part) 
	END IF 
	MESSAGE "Searching...please wait" 
	PREPARE rcp_stmt FROM where_part 

	DECLARE c_rcp CURSOR FOR rcp_stmt 

	OPEN WINDOW w_allrecp_lp with FORM "code_lp" 
	CALL winDecoration("code_lp") -- albo kd-766 

	LET cnt = 1 

	##################################
	FOREACH c_rcp INTO a_all_recp[cnt].* 
		##################################

		CALL get_contact_name(a_all_recp[cnt].contact_id) RETURNING tmp_first, tmp_last 

		#CALL get_contact_address(p_address_id) returning p_address.*


		LET tmp_name = tmp_first clipped, " ", tmp_last clipped 
		LET a_names[cnt].name = tmp_name [1,15] 

		LET cnt = cnt + 1 
		IF cnt > 1000 THEN 
			ERROR "More THEN 1000..." 
				SLEEP 5 
				EXIT FOREACH 
			END IF 
			###########
		END FOREACH 
		###########

		CLOSE c_rcp 
		FREE c_rcp 

		CALL set_count(cnt) 

		MESSAGE "SELECT AND press Accept" 

		#################################
		DISPLAY ARRAY a_names TO s_name.* 
		#################################
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","maintain","display_arr-a_names-1") -- albo kd-513 

			ON ACTION "WEB-HELP" -- albo 
				CALL onlinehelp(getmoduleid(),null) 
		END DISPLAY 
		LET cnt = arr_curr() #scr_line() 

		CLOSE WINDOW w_allrecp_lp 

		IF 
		int_flag <> 0 
		THEN 
			LET int_flag = 0 
			RETURN gv_null 
		END IF 

		RETURN a_all_recp[cnt].contact_id 

END FUNCTION #show_recipients() 


#######################
FUNCTION options_menu() 
	#######################
	DEFINE 
	success 
	SMALLINT, 
	send1, send2, send3, send4 #where_part 
	CHAR (200) 

	MENU "Options" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","maintain","menu-Options-1") -- albo kd-513 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

			##################################################################
		COMMAND "Valid only/all" "Toggle valid only records / All records" 
			##################################################################
			MESSAGE"" 
			IF 
			show_valid 
			THEN 
				LET show_valid = false 
				LET show_history = true 
				ERROR "Show only valid records IS now OFF" 
				SLEEP 1 
			ELSE 
				LET show_valid = true 
				LET show_history = false 
				ERROR "Show only valid records IS now ON" 
				SLEEP 1 
			END IF 

			IF length (last_where_part) > 0 THEN 

				LET send1 = last_where_part[1,200] 
				LET send2 = last_where_part[201,400] 
				LET send3 = last_where_part[401,600] 
				LET send4 = last_where_part[601,800] 

				LET success = open_cursor(send1, send2, send3, send4) 
			END IF 

			EXIT MENU 

			#####################################################################
		COMMAND "Accept key" "Toggle between ESC/CTRL+C AND ENTER/ESC" 
			#####################################################################
			MESSAGE "" 

			IF accept_enter THEN 
				#OPTIONS accept key ESCAPE

				LET accept_enter = false 

				ERROR "Accept key IS now ESC, Abort IS CTRL+C" 
				SLEEP 1 
			ELSE 
				#OPTIONS accept key F34

				LET accept_enter = true 

				ERROR "Accept key IS now ENTER, Abort IS ESC" 
				SLEEP 1 
			END IF 

			#####################################################
		COMMAND KEY ("x", "X") "Exit" "Back TO previous menu" 
			#####################################################

			MESSAGE"" 
			EXIT MENU 
	END MENU 

END FUNCTION #options_menu() 


############################################################ END module

