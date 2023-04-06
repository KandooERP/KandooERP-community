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

	Source code beautified by beautify.pl on 2020-01-02 10:35:23	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - piswtind.4gl
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY statistical details
#           WHEN doing a product inquiry.
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION prod_stats(p_cmpy,p_product_part_code)
############################################################
FUNCTION prod_stats(p_cmpy,p_product_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE l_arr_rec_prodmenu array[9] OF #array[9] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			option_num CHAR(1), 
			option_text CHAR(30) 
		END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		LET l_idx = 0 
		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_product_part_code 
		IF status = 0 THEN 
			FOR l_idx = 1 TO 5 
				LET l_arr_rec_prodmenu[l_idx].option_num = l_idx 
				LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pistwind",l_idx) 
			END FOR 
			CALL set_count(5) #array 9.. loop/count 5... ??? am l_i missing something here ? 

			OPEN WINDOW w1_pistwind with FORM "I146" 
			CALL windecoration_i("I146") 

			DISPLAY BY NAME l_rec_product.part_code, 
			l_rec_product.desc_text 

			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET l_msgresp=kandoomsg("A",1030,"") 

			#INPUT ARRAY l_arr_rec_prodmenu WITHOUT DEFAULTS FROM sr_prodmenu.*
			DISPLAY ARRAY l_arr_rec_prodmenu TO sr_prodmenu.* ATTRIBUTE(UNBUFFERED) 

				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","pistwind","input-arr-prodmenu") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					# LET scrn = scr_line()
					# DISPLAY l_arr_rec_prodmenu[l_idx].*
					#      TO sr_prodmenu[scrn].*

				ON ACTION "ACCEPT" 
					CASE l_idx 
						WHEN "1" ## general details 
							CALL prgdwind(p_cmpy,p_product_part_code) 
						WHEN "2" ## turnover STATISTICS 
							CALL run_prog("EB2",p_product_part_code,"","","") 
						WHEN "3" ## items bought AND sold 
							CALL run_prog("EB3",p_product_part_code,"","","") 
						WHEN "4" ## product sales 
							CALL run_prog("EB4",p_product_part_code,"","","") 
						WHEN "5" ## profit figures 
							CALL run_prog("EB5",p_product_part_code,"","","") 
					END CASE 

					 {
					         AFTER FIELD scroll_flag
					--#IF fgl_lastkey() = fgl_keyval("accept")
					--#AND fgl_fglgui() THEN
					--#   NEXT FIELD option_num
					--#END IF
					            IF l_arr_rec_prodmenu[l_idx].scroll_flag IS NULL THEN
					               IF fgl_lastkey() = fgl_keyval("down")
					               AND arr_curr() = arr_count() THEN
					                  LET l_msgresp=kandoomsg("A",9001,"")
					                  NEXT FIELD scroll_flag
					               END IF
					            END IF
					         BEFORE FIELD option_num
					            IF l_arr_rec_prodmenu[l_idx].scroll_flag IS NULL THEN
					               LET l_arr_rec_prodmenu[l_idx].scroll_flag = l_arr_rec_prodmenu[l_idx].option_num
					            ELSE
					               LET l_i = 1
					               WHILE (l_arr_rec_prodmenu[l_idx].scroll_flag IS NOT NULL)
					                  IF l_arr_rec_prodmenu[l_i].option_num IS NULL THEN
					                     LET l_arr_rec_prodmenu[l_idx].scroll_flag = NULL
					                  ELSE
					                     IF l_arr_rec_prodmenu[l_idx].scroll_flag=
					                        l_arr_rec_prodmenu[l_i].option_num THEN
					                        EXIT WHILE
					                     END IF
					                  END IF
					                  LET l_i = l_i + 1
					               END WHILE
					            END IF
					            CASE l_arr_rec_prodmenu[l_idx].scroll_flag
					               WHEN "1"  ## General Details
					                  CALL prgdwind(p_cmpy,p_product_part_code)
					               WHEN "2"  ## Turnover Statistics
					                  CALL run_prog("EB2",p_product_part_code,"","","")
					               WHEN "3"  ## Items Bought AND Sold
					                  CALL run_prog("EB3",p_product_part_code,"","","")
					               WHEN "4"  ## Product Sales
					                  CALL run_prog("EB4",p_product_part_code,"","","")
					               WHEN "5"  ## Profit Figures
					                  CALL run_prog("EB5",p_product_part_code,"","","")
					            END CASE
					            OPTIONS INSERT KEY F36,
					                    DELETE KEY F36
					            LET l_arr_rec_prodmenu[l_idx].scroll_flag = NULL
					            NEXT FIELD scroll_flag
					#AFTER ROW
					#   DISPLAY l_arr_rec_prodmenu[l_idx].*
					#        TO sr_prodmenu[scrn].*
					 }

			END DISPLAY 

			CLOSE WINDOW w1_pistwind 

		END IF 

		LET int_flag = FALSE 
		LET quit_flag = FALSE 

END FUNCTION 


