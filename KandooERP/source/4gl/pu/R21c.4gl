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

###########################################################################
# Requires
# common/note_disp.4gl
###########################################################################


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R21_GLOBALS.4gl" 


FUNCTION ord_window(p_cmpy, line_number, order_number, rec_qty) 
	DEFINE 
	line_number SMALLINT, 
	p_cmpy LIKE company.cmpy_code, 
	rec_qty DECIMAL(12,2), 
	order_number INTEGER 

	SELECT * INTO pr_purchdetl.* FROM t_purchdetl 
	WHERE line_num = line_number 
	AND order_num = order_number 
	OPEN WINDOW wr114 with FORM "R114" 
	CALL  windecoration_r("R114") 

	LET msgresp=kandoomsg("R",1024,"") 
	#R1024 Enter Notes Details;  OK TO Continue
	LET pr_poaudit.received_qty = rec_qty 
	DISPLAY BY NAME pr_purchdetl.type_ind, 
	pr_purchdetl.ref_text, 
	pr_purchdetl.oem_text, 
	pr_purchdetl.uom_code, 
	pr_poaudit.received_qty, 
	pr_purchdetl.desc_text 

	INPUT BY NAME pr_purchdetl.desc_text 
	WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R21c","inp-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "NOTES" --ON KEY (control-n) 
			IF pr_purchdetl.desc_text[1,3] = "###" 
			AND pr_purchdetl.desc_text[16,18] = "###" THEN 
				CALL note_disp(p_cmpy,pr_purchdetl.desc_text[4,15]) 
			ELSE 
				LET msgresp = kandoomsg("A",7027,"") 
				#7027 No Notes TO View
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wr114 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		UPDATE t_purchdetl 
		SET desc_text = pr_purchdetl.desc_text 
		WHERE order_num = pr_purchdetl.order_num 
		AND line_num = pr_purchdetl.line_num 
	END IF 
	RETURN 
END FUNCTION 
