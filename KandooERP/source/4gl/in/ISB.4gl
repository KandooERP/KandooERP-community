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

	Source code beautified by beautify.pl on 2020-01-03 09:12:42	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# ISB Updates product lead times FOR supplying vendor

GLOBALS 
	DEFINE 
	pr_product RECORD LIKE product.* 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE 
	pr_updated CHAR(1), 
	prod_num SMALLINT, 
	ans CHAR(1) 
	#Initial UI Init
	CALL setModuleId("ISB") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	OPEN WINDOW i217 with FORM "I217" 
	 CALL windecoration_i("I217") -- albo kd-758 

	LET msgresp = kandoomsg("I",1050,"") 
	#1050 Enter Vendor & Lead Time FOR Product Update "

	WHILE enter_vend() 
		LET pr_updated = 'N' 
		--      OPEN WINDOW w1 AT 10,18 with 3 rows,50 columns  -- albo  KD-758
		--         ATTRIBUTE(border, menu line 2)
		MENU " Update Product Lead Time" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ISB","menu-Update_Product-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "All" " Update All Products supplied by this Vendor" 
				--            CLEAR window w1  -- albo  KD-758
				CALL update_prod("A") 
				RETURNING prod_num 
				LET pr_updated = 'Y' 
				EXIT MENU 
			COMMAND "Selected" " Update products without an existing lead time" 
				--            CLEAR window w1  -- albo  KD-758
				CALL update_prod("S") 
				RETURNING prod_num 
				LET pr_updated = 'Y' 
				EXIT MENU 
			COMMAND KEY(interrupt,"E")"Exit" " Do NOT continue with Update" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		--      CLOSE WINDOW w1  -- albo  KD-758
		IF pr_updated = 'Y' THEN 
			LET msgresp = kandoomsg("I",7077, prod_num) 
			#7077 prod_num," Products Updated "
		END IF 
		LET int_flag = false 
		LET quit_flag = false 
		LET prod_num = 0 
		INITIALIZE pr_product.* TO NULL 
	END WHILE 
END MAIN 


FUNCTION enter_vend() 
	DEFINE 
	pr_vendor RECORD LIKE vendor.* 

	CLEAR FORM 
	INPUT BY NAME pr_product.vend_code, 
	pr_product.days_lead_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISB","input-pr_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 


		ON KEY (control-b)infield (vend_code) 
			LET pr_product.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,pr_product.vend_code) 
			NEXT FIELD vend_code 


		AFTER FIELD vend_code 
			SELECT name_text INTO pr_vendor.name_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_product.vend_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("N",9043,"") 
				#9043 Vendor NOT found - Try Window "
				CLEAR name_text 
				NEXT FIELD vend_code 
			ELSE 
				DISPLAY BY NAME pr_vendor.name_text 

			END IF 

		AFTER FIELD days_lead_num 
			IF pr_product.days_lead_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD days_lead_num 
			END IF 
			IF pr_product.days_lead_num < 0 THEN 
				LET msgresp = kandoomsg("A",9309,"") 
				#9309 Value must NOT be less than 0.
				NEXT FIELD days_lead_num 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_product.vend_code IS NULL THEN 
					NEXT FIELD vend_code 
				END IF 
				IF pr_product.days_lead_num IS NULL 
				OR pr_product.days_lead_num < 0 THEN 
					NEXT FIELD days_lead_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION update_prod(prod_ind) 
	DEFINE 
	prod_ind CHAR(1), 
	upd_text CHAR(200), 
	where_text CHAR(100), 
	err_message CHAR(40), 
	err_continue CHAR(1) 

	LET msgresp = kandoomsg("U",1010,"") 
	#1010  Updating Database;  Please wait.
	IF prod_ind = "A" THEN 
		LET where_text = "1=1" 
	ELSE 
		LET where_text = " ( days_lead_num = 0 OR days_lead_num IS NULL )" 
	END IF 
	LET upd_text = "UPDATE product ", 
	" SET days_lead_num = ",pr_product.days_lead_num," ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vend_code = \"",pr_product.vend_code,"\" ", 
	"AND ",where_text clipped 
	PREPARE update_curs FROM upd_text 
	LET err_message = "ISA - Error in Update of Product Table" 
	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE product in share MODE 
		EXECUTE update_curs 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN sqlca.sqlerrd[3] 
END FUNCTION 
