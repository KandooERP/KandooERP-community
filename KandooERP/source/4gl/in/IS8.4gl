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

	Source code beautified by beautify.pl on 2020-01-03 09:12:41	$Id: $
}



#used as GLOBALS FROM Is8a.4gl


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS8 - Loads,Reports,Modifies AND Updates Product Quotations

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "IS8_GLOBALS.4gl" 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IS8") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET glob_rec_kandooreport.report_code = getmoduleid() 

	CALL kandooreport(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.report_code) 
	RETURNING glob_rec_kandooreport.* 
	OPEN WINDOW i618 with FORM "I618" 
	 CALL windecoration_i("I618") -- albo kd-758 
	MENU " Quotations" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IS8","menu-Quotations-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Load" " Load the Supplier Quotation file" 
			IF load_file_input() THEN 
				IF process_load_files() THEN 
					NEXT option "Print Manager" 
				END IF 
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view Load Report using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Modify" 

		COMMAND "Report" " Run the IN Purchasing Quotes Report" 
			CALL run_prog("IR5","","","","") 
		COMMAND "Compare" " Run the IN Vendor Price List Report" 
			CALL run_prog("IS9","","","","") 
		COMMAND "Edit" " Modify the Supplier Quotations" 
			CALL run_prog("I17","","","","") 
			NEXT option "Update" 
		COMMAND "Directory" " List entries in a specified directory" 
			CALL show_directory() 
			NEXT option "Load" 
		COMMAND "Update" " Update the database with the Supplier Quotes" 
			IF update_price_load() THEN 
				NEXT option "Exit" 
			END IF 
		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW i618 
END MAIN 
#
# Set Defaults FUNCTION IS designed TO PREPARE REPORT parameters prior
# TO printing the REPORT. As there are 2 reports referenced in this
# program there IS a parameter being passed in TO CALL either one.
#
FUNCTION set_defaults(pr_rep_type) 
	DEFINE 
	pr_rep_type SMALLINT 

	CASE pr_rep_type 
		WHEN 1 
			LET glob_rec_kandooreport.header_text = "Supplier Product Quotation ", 
			"Load - Error Log" 
			LET glob_rec_kandooreport.line1_text = "Error", 7 spaces, "Error", 
			95 spaces, "Line" 
			LET glob_rec_kandooreport.line2_text = "Number", 6 spaces, "Text", 
			96 spaces, "Number" 
		WHEN 2 
			LET glob_rec_kandooreport.header_text = "IN Purchasing Quotes Inventory Update" 
			LET glob_rec_kandooreport.line1_text = " Product", 9 spaces, "Description", 
			14 spaces, "O.E.M. Code", 24 spaces, 
			"--------------Cost Amount-------------", 
			7 spaces, "List Price" 
			LET glob_rec_kandooreport.line2_text = 77 spaces, "Standard", 6 spaces, 
			"Latest", 11 spaces, "Foreign" 
		WHEN 3 
			LET glob_rec_kandooreport.header_text = "IN Purchasing Quotes Inventory Update (Report Only)" 
			LET glob_rec_kandooreport.line1_text = " Product", 9 spaces, "Description", 
			14 spaces, "O.E.M. Code", 24 spaces, 
			"--------------Cost Amount-------------", 
			7 spaces, "List Price" 
			LET glob_rec_kandooreport.line2_text = 77 spaces, "Standard", 6 spaces, 
			"Latest", 11 spaces, "Foreign" 
	END CASE 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "IS8" 
	LET glob_rec_kandooreport.selection_flag = "Y" 

	UPDATE kandooreport SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 
