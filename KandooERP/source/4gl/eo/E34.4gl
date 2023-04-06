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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E3_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E34_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_orderdetl RECORD LIKE orderdetl.* 
DEFINE modu_rec_backorder RECORD LIKE backorder.* 
DEFINE modu_ans char(1) 
DEFINE modu_noerror SMALLINT 
DEFINE modu_doit char(1) 
DEFINE modu_eprod char(15) 
DEFINE modu_bprod char(15) 
DEFINE modu_ecust char(8) 
DEFINE modu_bcust char(8) 
DEFINE modu_eware char(3) 
DEFINE modu_bware char(3) 
DEFINE modu_try_again char(1) 
DEFINE modu_err_message char(40) 
 
###########################################################################
# FUNCTION E34_main()
#
# E34  Releases back orders TO current orders
###########################################################################
FUNCTION E34_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E34") 

	LET modu_noerror = 1 
	LET modu_doit = "Y" 
	WHILE modu_doit = "Y" 
		CALL E34_query_backorders() 
		LET modu_doit = "Y" 
	END WHILE 
	
END FUNCTION 
###########################################################################
# END FUNCTION E34_main()
###########################################################################


###########################################################################
# FUNCTION E34_query_backorders() 
#
# 
###########################################################################
FUNCTION E34_query_backorders() 

	CLEAR screen 

	OPEN WINDOW E417 with FORM "E417" 
	 CALL windecoration_e("E417") -- albo kd-755 


	INPUT 
		modu_bprod, 
		modu_eprod, 
		modu_bware, 
		modu_eware WITHOUT DEFAULTS 
	FROM
		bprod, 
		eprod, 
		bware, 
		eware ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E34","input-modu_bprod-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(bprod) 
					LET modu_bprod = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_bprod TO bprod 

					NEXT FIELD bprod
					 
		ON ACTION "LOOKUP" infield(eprod) 
					LET modu_eprod = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_eprod TO eprod

					NEXT FIELD eprod
					 
		ON ACTION "LOOKUP" infield(bware) 
					LET modu_bware = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_bware TO bware

					NEXT FIELD bware 
					
		ON ACTION "LOOKUP" infield(eware) 
					LET modu_eware = show_ware(glob_rec_kandoouser.cmpy_code) 
					DISPLAY modu_eware TO eware 

					NEXT FIELD eware 


		AFTER FIELD modu_bprod 
			IF modu_bprod IS NULL THEN 
				LET modu_bprod = " " 
				DISPLAY modu_bprod  TO bprod
			END IF 

		AFTER FIELD modu_eprod 
			IF modu_eprod IS NULL THEN 
				LET modu_eprod = "zzzzzzzzzzzzzzz" 
				DISPLAY modu_eprod  TO eprod
			END IF 

		AFTER FIELD modu_bware 
			IF modu_bware IS NULL THEN 
				LET modu_bware = " " 
				DISPLAY modu_bware TO bware 
			END IF 

		AFTER FIELD modu_eware 
			IF modu_eware IS NULL THEN 
				LET modu_eware = "zzz" 
				DISPLAY modu_eware TO eware 
			END IF 

		AFTER INPUT 
			IF modu_bprod IS NULL THEN 
				LET modu_bprod = " " 
			END IF 
			IF modu_eprod IS NULL THEN 
				LET modu_eprod = "zzzzzzzzzzzzzzz" 
			END IF 
			IF modu_bware IS NULL THEN 
				LET modu_bware = " " 
			END IF 
			IF modu_eware IS NULL THEN 
				LET modu_eware = "zzz" 
			END IF 

			DISPLAY modu_bprod TO bprod
			DISPLAY modu_eprod TO eprod
			DISPLAY modu_bware TO bware
			DISPLAY modu_eware TO eware 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 
	{  -- albo
	       OPEN WINDOW confirm AT 10,8 with 2 rows,30 columns
	            ATTRIBUTE(border, reverse, prompt line last)
	       DISPLAY "      Confirm entry        " AT 1,1
	       prompt "   Any Key TO continue     " FOR CHAR modu_ans
	       CLOSE WINDOW confirm
	}
	-- albo --
	--       OPEN WINDOW confirm AT 10,8 with 2 rows,30 columns  -- albo  KD-755
	--            ATTRIBUTE(border, reverse, prompt line last)
	--DISPLAY " Confirm entry" at 3,1 
	CALL eventsuspend() 
	--       CLOSE WINDOW confirm  -- albo  KD-755
	----------
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW E417 
		RETURN 
	END IF 

	CLOSE WINDOW E417 

	CALL E34_process_backorders() 

END FUNCTION 
###########################################################################
# END FUNCTION E34_query_backorders()
###########################################################################


###########################################################################
# FUNCTION E34_process_backorders()
#
# 
###########################################################################
FUNCTION E34_process_backorders() 

	# SELECT back orders that have an allocation within bounds specified

	DECLARE c_baccurs cursor FOR 
	SELECT * 
	INTO modu_rec_backorder.* 
	FROM backorder 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code between modu_bprod AND modu_eprod 
	AND ware_code between modu_bware AND modu_eware 
	AND alloc_qty > 0 

	OPEN c_baccurs 
	FOREACH c_baccurs 

		--DISPLAY "" at 12,10 
		MESSAGE " Product: ", modu_rec_backorder.part_code -- at 12,10	attribute (yellow) 

		# SELECT orders awaiting this product

		GOTO bypass 
		LABEL recovery: 
		LET modu_try_again = error_recover(modu_err_message, status) 
		IF modu_try_again != "Y" THEN  #????
			CALL fgl_winmessage("ERROR","Exit Program","ERROR") 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 

			LET modu_err_message = "O34 - Order line update" 
			DECLARE ordcurs cursor FOR 
			SELECT * 
			INTO modu_rec_orderdetl.* 
			FROM orderdetl 
			WHERE cmpy_code = modu_rec_backorder.cmpy_code 
			AND cust_code = modu_rec_backorder.cust_code 
			AND ware_code = modu_rec_backorder.ware_code 
			AND order_num = modu_rec_backorder.order_num 
			AND line_num = modu_rec_backorder.line_num 

			FOREACH ordcurs 
				IF modu_rec_orderdetl.back_qty - modu_rec_backorder.alloc_qty = 0 THEN 
					LET modu_rec_orderdetl.status_ind = 0 
				END IF 
				DISPLAY "" at 13,10 
				DISPLAY " Order: ", modu_rec_orderdetl.order_num at 13,10 


				UPDATE orderdetl 
				SET back_qty = 
					back_qty - modu_rec_backorder.alloc_qty, 
					sched_qty = sched_qty + modu_rec_backorder.alloc_qty, 
					status_ind = modu_rec_orderdetl.status_ind 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = modu_rec_orderdetl.cust_code 
				AND order_num = modu_rec_orderdetl.order_num 
				AND line_num = modu_rec_orderdetl.line_num 

				LET modu_err_message = "O34 - Itemstat update" 

				UPDATE prodstatus 
				SET 
					reserved_qty = reserved_qty + modu_rec_backorder.alloc_qty, 
					back_qty = back_qty - modu_rec_backorder.alloc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = modu_rec_backorder.part_code 
				AND ware_code = modu_rec_backorder.ware_code 
			END FOREACH 

			LET modu_err_message = "O34 - Bacallo deletion" 
			DELETE FROM backorder 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_backorder.ware_code 
			AND cust_code = modu_rec_backorder.cust_code 
			AND part_code = modu_rec_backorder.part_code 
			AND order_num = modu_rec_backorder.order_num 
			AND line_num = modu_rec_backorder.line_num 

			CLOSE ordcurs 

		COMMIT WORK 

		OPEN c_baccurs 
	END FOREACH 

END FUNCTION
###########################################################################
# END FUNCTION E34_process_backorders()
###########################################################################