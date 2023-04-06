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

	Source code beautified by beautify.pl on 2020-01-03 09:12:48	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZ8 sets up Units of Measure

DEFINE t_uom TYPE AS RECORD
	uom_code LIKE uom.uom_code, 
	desc_text LIKE uom.desc_text
END RECORD 

FUNCTION IZ8_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE m_sql_statement STRING
	DEFINE l_prp_uom PREPARED			# Prepared object to build the cursor
	DEFINE l_crs_uom CURSOR				# cursor as variable
	#Initial UI Init
	CALL setModuleId("IZ8") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 
	OPEN WINDOW wi102 with FORM "I102" 
	 CALL windecoration_i("I102") -- albo kd-758 
	
	LET m_sql_statement = "SELECT uom_code,desc_text FROM uom WHERE cmpy_code = ? ORDER BY uom_code"
	CALL l_crs_uom.declare(m_sql_statement)	
	
	WHILE true 
		CALL maint_uom(l_crs_uom) 
		IF int_flag != 0 OR quit_flag != 0 	THEN 
			EXIT program 
		END IF 
	END WHILE 
END MAIN 

FUNCTION maint_uom(l_crs_uom) 
	DEFINE l_crs_uom CURSOR				# cursor as variable
	DEFINE pa_uom DYNAMIC ARRAY OF t_uom	# the dynamic array for INPUT ARRAY 
	DEFINE sav_uom t_uom					# the backup copy of the array element before it is modified
	DEFINE uom_cnt,idx,scr_line SMALLINT
	DEFINE after_insert,after_delete BOOLEAN
	CALL l_crs_uom.SetParameters(glob_rec_kandoouser.cmpy_code)
	CALL l_crs_uom.open()


	LET idx = 1 
	WHILE true
		CALL  l_crs_uom.SetResults(pa_uom[idx].*)
		IF l_crs_uom.fetchNext() = 100 THEN
			CALL pa_uom.delete(idx)
			LET idx = idx -1
			EXIT WHILE
		END IF
		LET idx = idx + 1  
	END WHILE

	MESSAGE " F1 add, F2 delete, RETURN TO change " 
	attribute(yellow) 

	INPUT ARRAY pa_uom WITHOUT DEFAULTS FROM sr_uom.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ8","input-pa_uom-1") -- albo kd-505 
			CALL fgl_setactionlabel("Append", "", "", 0, FALSE) -- Deactivation of Default Action "Append" (albo kd-2023)

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scr_line = scr_line() 
			LET sav_uom.* = pa_uom[idx].*		# take a backup of this element 
			LET  after_insert = FALSE
			LET  after_delete = FALSE

		AFTER FIELD uom_code 
			IF (pa_uom[idx].uom_code IS null) THEN 
				IF (pa_uom[idx].desc_text IS NOT null) THEN 
					ERROR "A UOM Code IS required." 
					NEXT FIELD uom_code 
				END IF 
			ELSE 
				IF (pa_uom[idx].uom_code != sav_uom.uom_code 
				OR pa_uom[idx].uom_code IS null) THEN 
					SELECT count(*) 
					INTO uom_cnt 
					FROM uom 
					WHERE uom_code = pa_uom[idx].uom_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (uom_cnt !=0) THEN 
						ERROR "UOM Code must be unique" 
						NEXT FIELD uom_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			IF pa_uom[idx].desc_text IS NULL THEN 
				ERROR " Must enter a description " 
				NEXT FIELD desc_text 
			END IF 

		BEFORE INSERT 
			--INITIALIZE pr_uom.* TO NULL 

		AFTER INSERT  
			IF (pa_uom[idx].uom_code IS NOT null) THEN 
				INSERT INTO uom VALUES (glob_rec_kandoouser.cmpy_code,pa_uom[idx].uom_code,	pa_uom[idx].desc_text)
				IF sqlca.sqlcode = 0 THEN
					MESSAGE "The UOM ", pa_uom[idx].uom_code, " has been inserted successfully"
				END IF
				LET after_insert = TRUE
			END IF 

		AFTER DELETE
			LET after_delete = TRUE 
			DELETE FROM uom WHERE uom_code = sav_uom.uom_code		-- pa_uom[idx].uom_code has gone! 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			IF sqlca.sqlcode = 0 THEN
				IF sqlca.sqlerrd[1] = 1 THEN		# one record has effectively been deleted
					MESSAGE "The UOM ", sav_uom.uom_code, " has been deleted successfully"
				ELSE
					MESSAGE "No UOM ", sav_uom.uom_code, " has been deleted"
				END IF 
			END IF
			 
		AFTER ROW 
			IF ((sav_uom.uom_code != pa_uom[idx].uom_code 
			OR sav_uom.desc_text != pa_uom[idx].desc_text)) THEN 
				IF NOT after_insert AND NOT after_delete THEN
					UPDATE uom SET 
					uom_code = pa_uom[idx].uom_code, 
					desc_text = pa_uom[idx].desc_text 
					WHERE uom_code = pa_uom[idx].uom_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
					IF sqlca.sqlcode = 0 THEN
						IF sqlca.sqlerrd[1] = 1 THEN		# one record has effectively been deleted
							MESSAGE "The UOM ", sav_uom.uom_code, " has been updated successfully"
						ELSE
							MESSAGE "No UOM ", sav_uom.uom_code, " has been updated"
						END IF 
					END IF
				END IF
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	--CLOSE WINDOW wi102 
END FUNCTION 
