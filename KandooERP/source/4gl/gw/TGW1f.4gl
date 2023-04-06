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

	Source code beautified by beautify.pl on 2020-01-03 10:10:02	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gw/T_GW_GLOBALS.4gl" 
GLOBALS "../gw/TGW1_GLOBALS.4gl" 


############################################################
# FUNCTION get_report_group()
#
# Purpose - This FUNCTION gets a report_group id FROM the user AND sets
#           the global RECORD gr_rpthead_group accordingly. It also
#           allows the user TO overwrite the date description text FOR
#           the group of reports.
############################################################
FUNCTION get_report_group() 
	DEFINE l_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE l_rptgrp_text LIKE rpthead_group.rptgrp_text 

	OPEN WINDOW w_rpt_grp with FORM "TG569" 
	CALL windecoration_t("TG569") -- albo kd-768 

	INPUT BY NAME gr_rpthead_group.rptgrp_id, 
	gr_rpthead_group.rptgrp_desc2 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW1f","input-rptgrp_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (rptgrp_id) 
			CALL pick_rptgrp(glob_rec_kandoouser.cmpy_code) 
			RETURNING l_rptgrp_id, l_rptgrp_text 

			IF l_rptgrp_id IS NOT NULL THEN 
				LET gr_rpthead_group.rptgrp_id = l_rptgrp_id 
				LET gr_rpthead_group.rptgrp_text = l_rptgrp_text 

				DISPLAY BY NAME gr_rpthead_group.rptgrp_id, 
				gr_rpthead_group.rptgrp_text 

			END IF 


		BEFORE FIELD rptgrp_id 
			MESSAGE "Enter REPORT group identifier, ESC TO accept, DEL TO abort" 
			attribute(yellow) 

		AFTER FIELD rptgrp_id 
			SELECT * 
			INTO gr_rpthead_group.* 
			FROM rpthead_group 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rptgrp_id = gr_rpthead_group.rptgrp_id 
			IF status 
			THEN 
				ERROR "Invalid REPORT identifier FOR current company" 
				NEXT FIELD rptgrp_id 
			ELSE 

				LET gr_rpthead.col_hdr_per_page = "Y" 
				LET gr_rpthead.std_head_per_page = "Y" 

				DISPLAY BY NAME gr_rpthead_group.rptgrp_id, 
				gr_rpthead_group.rptgrp_text, 
				gr_rpthead_group.rptgrp_desc2 

			END IF #status 

	END INPUT 

	CLOSE WINDOW w_rpt_grp 

	{ Error handling IS done in the calling FUNCTION.
	IF int_flag OR quit_flag THEN
	    LET int_flag = FALSE
	    LET quit_flag = FALSE
	END IF #int_flag OR quit_flag
	}

END FUNCTION #get_report_group() 
