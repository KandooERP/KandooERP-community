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

	Source code beautified by beautify.pl on 2020-01-02 17:06:23	Source code beautified by beautify.pl on 2020-01-02 17:03:33	$Id: $
}
############################################################
# RZ3 IS used TO enter AND maintain type codes which determine the output FORMAT when printing Purchase Orders.  KandooERP provides multiple Purchase Order PRINT formats TO cater
# for multiple special stationery prints, AND for file formats suitable for upload TO third party software.  Vendors are assigned a Purchase Order type code, AND that code IS
# subsequently recorded against the Vendor’s Purchase Orders AND used by the Print facility TO determine the appropriate REPORT file FORMAT.
#Refer TO RS1 - Print Purchase Orders for further details of how PRINT formats are allocated.
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS 
	DEFINE temp_text CHAR(20) 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
#   RZ3 - Purchase Order Type Maintenance
#######################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("RZ3") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r600 with FORM "R600" 
	CALL  windecoration_r("R600") 

	WHILE select_purchtype(l_withquery) 
		LET l_withquery = scan_purchtype() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW r600 
END MAIN 


#######################################################################
# FUNCTION select_purchtype()
#
#
#######################################################################
FUNCTION select_purchtype(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON purchtype_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","RZ3","construct-purchtype-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 


	LET l_msgresp = kandoomsg("A",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM purchtype ", 
	"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY purchtype.purchtype_code" 

	PREPARE s_purchtype FROM l_query_text 
	DECLARE c_purchtype CURSOR FOR s_purchtype 

	RETURN 1 
END FUNCTION 



#######################################################################
# FUNCTION scan_purchtype()
#
#
#######################################################################
FUNCTION scan_purchtype() 
	DEFINE l_rec_purchtype RECORD LIKE purchtype.* 
	DEFINE l_arr_rec_purchtype DYNAMIC ARRAY OF 
	RECORD 
		purchtype_code LIKE purchtype.purchtype_code, 
		desc_text LIKE purchtype.desc_text 
	END RECORD 
	DEFINE idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_index DYNAMIC ARRAY OF SMALLINT 

	LET idx = 0 
	FOREACH c_purchtype INTO l_rec_purchtype.* 
		LET idx = idx + 1 
		LET l_arr_rec_purchtype[idx].purchtype_code = l_rec_purchtype.purchtype_code 
		LET l_arr_rec_purchtype[idx].desc_text = l_rec_purchtype.desc_text 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("R",9001,idx) 
			#9509 " First ??? Purchase Order Types Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("R",9002,"") 
		#9510 No Purchase Order Types satisfied selection criteria
		LET idx = 1 
	END IF 

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 

	#1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	#   INPUT ARRAY l_arr_rec_purchtype WITHOUT DEFAULTS FROM sr_purchtype.*  ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_purchtype TO sr_purchtype.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","RZ3","display-arr-purchtype-1") 

		BEFORE ROW 
			LET idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","ACCEPT") 
			IF l_arr_rec_purchtype[idx].purchtype_code IS NOT NULL THEN 
				LET l_rec_purchtype.purchtype_code = l_arr_rec_purchtype[idx].purchtype_code 
				IF edit_purchtype(l_rec_purchtype.purchtype_code,"U") THEN 
					SELECT * 
					INTO l_rec_purchtype.* 
					FROM purchtype 
					WHERE purchtype_code = l_rec_purchtype.purchtype_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET l_arr_rec_purchtype[idx].purchtype_code = l_rec_purchtype.purchtype_code 
					LET l_arr_rec_purchtype[idx].desc_text = l_rec_purchtype.desc_text 
				END IF 
			END IF 
			RETURN 0 

		ON ACTION ("NEW") 
			CALL edit_purchtype("","A") 
			RETURN 0 

		ON ACTION "DELETE" 
			LET l_arr_index = getTableRowsSelected("sr_purchtype") --index OF all selected ROWS 
			LET l_del_cnt = l_arr_index.getsize() 
			IF l_del_cnt > 0 THEN 
				IF kandoomsg("R",8001,l_del_cnt) = "Y" THEN 

					FOR idx = 1 TO l_arr_index.getsize() 
						LET l_del_cnt = l_del_cnt - db_purchtype_delete(l_arr_rec_purchtype[l_arr_index[idx]].purchtype_code) 
					END FOR 
				END IF 
				MESSAGE l_del_cnt clipped, " row(s) deleted" 
			ELSE 
				ERROR "No row(s) selected TO delete" 
			END IF 
			RETURN 0 
	END DISPLAY 
	#---------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	ELSE 
		RETURN 0 --refresh data source WITHOUT query 
	END IF 

END FUNCTION 



#######################################################################
# FUNCTION edit_purchtype(p_purchtype_code,p_mode)
#
#
#######################################################################
FUNCTION edit_purchtype(p_purchtype_code,p_mode) 
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code 
	DEFINE p_mode CHAR(1) 
	DEFINE l_rec_s_purchtype RECORD LIKE purchtype.* 
	DEFINE l_rec_purchtype RECORD LIKE purchtype.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ret SMALLINT 

	OPEN WINDOW r601 with FORM "R601" 
	CALL  windecoration_r("R601") 

	IF p_mode IS NULL THEN 
		CALL fgl_winmessage("Internal Error","Error <p_mode IS NULL RZ3.4gl>\Contact support@kandooerp.org","error") 
	END IF 

	IF upshift(p_mode) = "U" THEN {update} 
		CALL db_purchtype_get_rec(p_purchtype_code) RETURNING l_rec_purchtype.* 

		DISPLAY BY NAME l_rec_purchtype.desc_text, 
		l_rec_purchtype.format_ind, 
		l_rec_purchtype.rms_flag, 
		l_rec_purchtype.footer1_text, 
		l_rec_purchtype.footer2_text, 
		l_rec_purchtype.footer3_text 

	ELSE 
		INITIALIZE l_rec_purchtype.* TO NULL 
		LET l_rec_purchtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	LET l_rec_s_purchtype.* = l_rec_purchtype.* 
	LET l_msgresp = kandoomsg("R",1001,"") 

	#1001" Enter Purchase Order Format Type details - ESC TO continue
	DISPLAY BY NAME l_rec_purchtype.purchtype_code 
	LET l_rec_purchtype.rms_flag = "N" --make n(o) default 

	INPUT BY NAME l_rec_purchtype.purchtype_code, 
	l_rec_purchtype.desc_text, 
	l_rec_purchtype.format_ind, 
	l_rec_purchtype.rms_flag, 
	l_rec_purchtype.footer1_text, 
	l_rec_purchtype.footer2_text, 
	l_rec_purchtype.footer3_text 
	WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RZ3","inp-purchtype-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD purchtype_code 
			IF p_mode = "U" THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD purchtype_code 
			IF db_purchtype_validate_purchtype_code(l_rec_purchtype.purchtype_code,1,p_mode) THEN 
				NEXT FIELD purchtype_code 
			END IF 

		AFTER FIELD desc_text 
			IF db_purchtype_validate_desc_text(l_rec_purchtype.desc_text,1,p_mode) THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF db_purchtype_validate_purchtype_code(l_rec_purchtype.purchtype_code,1,p_mode) THEN 
					NEXT FIELD purchtype_code 
					CONTINUE INPUT 
				END IF 

				IF db_purchtype_validate_desc_text(l_rec_purchtype.desc_text,1,p_mode) THEN 
					NEXT FIELD desc_text 
					CONTINUE INPUT 
				END IF 

				CASE upshift(p_mode) 
					WHEN "U" 
						LET l_ret = db_purchtype_update(l_rec_purchtype.*) 
					WHEN "A" 
						LET l_ret = db_purchtype_insert(l_rec_purchtype.*) 
				END CASE 

			END IF 

	END INPUT 

	CLOSE WINDOW r601 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN l_ret 
	END IF 

END FUNCTION 


######################################################################################################################################################
# Purchase Type
# The three character code which identifies the Purchase Order FORMAT type.
#
# Description
# A description of the FORMAT type.
#
# Format Indicator
# The output file FORMAT indicator of this Purchase Order type.  Each customised PRINT FORMAT IS allocated a FORMAT indicator.
# No validation IS performed on this field, however Purchase Orders of a type without a known FORMAT will NOT be printed.
# The standard KandooERP FORMAT indicator IS ‘00’.
#
# Output PO’S TO one file ?
# Enter 'Y' TO create a single file containing all Purchase Orders selected for printing.  Enter 'N' TO create a separate output file for each Purchase Order printed.
#
# Footer 1
# Enter up TO 60 characters for printing as the first line of footer text.  This text will only be used if specified in the associated custom FORMAT.  Entry TO this field IS optional.
#
# Footer 2
# Enter up TO 60 characters for printing as the second line of footer text.  This text will only be used if specified in the associated custom FORMAT.  Entry TO this field IS optional.
#
# Footer 3
# Enter up TO 60 characters for printing as the third line of footer text.  This text will only be used if specified in the associated custom FORMAT.  Entry TO this field IS optional.
######################################################################################################################################################
