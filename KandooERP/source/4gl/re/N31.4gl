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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N3_GROUP_GLOBALS.4gl"
GLOBALS "../re/N31_GLOBALS.4gl"  
GLOBALS 
	DEFINE where_text CHAR(400) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N31 - Requisition Back Order Product Allocation
############################################################
MAIN 
	CALL setModuleId("N31") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n124 with FORM "N124" 
	CALL windecoration_n("N124") -- albo kd-763 
	WHILE select_reqs() 
		IF reqback_delete() THEN 
			CALL rec_allocate() 
		END IF 
	END WHILE 
	CLOSE WINDOW n124 
END MAIN 


FUNCTION select_reqs() 
	CLEAR FORM 
	MESSAGE " Enter Selection Criteria - ESC TO Continue " 
	attribute(yellow) 
	CONSTRUCT BY NAME where_text ON reqhead.ware_code, 
	reqdetl.part_code, 
	reqhead.req_num, 
	reqdetl.back_qty, 
	reqhead.person_code, 
	reqhead.req_date, 
	reqhead.year_num, 
	reqhead.period_num 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION reqback_delete() 
	DEFINE 
	pr_reqbackord RECORD LIKE reqbackord.*, 
	query_text CHAR(800), 
	ans CHAR(1) 

	LET query_text = 
	"SELECT reqbackord.* ", 
	"FROM reqbackord,", 
	"reqhead,", 
	"reqdetl ", 
	"WHERE reqbackord.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqbackord.cmpy_code = reqhead.cmpy_code ", 
	"AND reqbackord.req_num = reqhead.req_num ", 
	"AND reqbackord.cmpy_code = reqdetl.cmpy_code ", 
	"AND reqbackord.req_num = reqdetl.req_num ", 
	"AND reqbackord.part_code = reqdetl.part_code ", 
	"AND reqbackord.line_num = reqdetl.line_num ", 
	"AND ",where_text clipped," " 
	PREPARE s1_reqbackord FROM query_text 
	DECLARE c1_reqbackord CURSOR FOR s1_reqbackord 
	OPEN c1_reqbackord 
	FETCH c1_reqbackord INTO pr_reqbackord.* 
	IF status = notfound THEN 
		RETURN true 
	ELSE 
		{     -- albo
		      OPEN WINDOW w1_N31 AT 16,13 with 1 rows,50 columns
		         ATTRIBUTE(border,cyan)
		      prompt " Delete Existing Back Order Allocations? (Y/N):"
		         FOR CHAR ans
		         ATTRIBUTE(yellow)
		      CLOSE WINDOW w1_N31
		}
		LET ans = promptYN(""," Delete Existing Back Order Allocations? (Y/N)","Y") -- albo 
		LET int_flag = false 
		LET quit_flag = false 
		IF upshift(ans) = "Y" THEN 
			WHILE status != notfound 
				DELETE FROM reqbackord 
				WHERE cmpy_code = pr_reqbackord.cmpy_code 
				AND part_code = pr_reqbackord.part_code 
				AND req_num = pr_reqbackord.req_num 
				AND line_num = pr_reqbackord.line_num 
				FETCH c1_reqbackord INTO pr_reqbackord.* 
			END WHILE 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	END IF 
END FUNCTION 


FUNCTION rec_allocate() 
	DEFINE 
	pr_reqbackord RECORD LIKE reqbackord.*, 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_available LIKE prodstatus.onhand_qty, 
	pr_save_ware LIKE prodstatus.ware_code, 
	pr_save_part LIKE prodstatus.part_code, 
	pr_alloc_cnt SMALLINT, 
	query_text CHAR(800) 

	LET query_text = 
	"SELECT reqhead.*,", 
	"reqdetl.* ", 
	"FROM reqhead,", 
	"reqdetl ", 
	"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqdetl.cmpy_code = reqhead.cmpy_code ", 
	"AND reqdetl.req_num = reqhead.req_num ", 
	"AND reqdetl.back_qty > 0 ", 
	"AND ",where_text clipped," ", 
	"ORDER BY reqhead.ware_code,", 
	"reqdetl.part_code,", 
	"reqhead.req_date" 
	PREPARE s2_reqdetl FROM query_text 
	DECLARE c2_reqdetl CURSOR FOR s2_reqdetl 
	LET pr_alloc_cnt = 0 
	LET pr_save_ware = NULL 
	LET pr_save_part = NULL 
	FOREACH c2_reqdetl INTO pr_reqhead.*, 
		pr_reqdetl.* 
		IF (pr_save_ware IS NULL OR pr_save_part IS null) 
		OR (pr_save_ware != pr_reqhead.ware_code) 
		OR (pr_save_part != pr_reqdetl.part_code) THEN 
			DECLARE c_prodstatus CURSOR FOR 
			SELECT prodstatus.*, 
			(onhand_qty - reserved_qty) 
			FROM prodstatus 
			WHERE cmpy_code = pr_reqhead.cmpy_code 
			AND ware_code = pr_reqhead.ware_code 
			AND part_code = pr_reqdetl.part_code 
			AND onhand_qty - reserved_qty > 0 
			AND back_qty > 0 
			OPEN c_prodstatus 
			FETCH c_prodstatus INTO pr_prodstatus.*, 
			pr_available 
			IF status = notfound THEN 
				CONTINUE FOREACH 
			ELSE 
				IF pr_alloc_cnt = 0 THEN 
					{
					               OPEN WINDOW w2_N31 AT 16,18 with 5 rows,40 columns     -- albo  KD-763
					                  ATTRIBUTE(border,cyan)
					               CLEAR window w2_N31
					}
					DISPLAY " Warehouse..........." at 1,1 

					DISPLAY " Allocating Product.." at 2,1 

					DISPLAY " TO Requisition No.." at 3,1 

					DISPLAY " Line No.." at 4,1 

					DISPLAY " Allocation.." at 5,1 

				END IF 
				LET pr_save_ware = pr_reqhead.ware_code 
				LET pr_save_part = pr_reqdetl.part_code 
			END IF 
			DISPLAY pr_save_ware at 1,22 
			attribute(yellow) 
			DISPLAY pr_save_part at 2,22 
			attribute(yellow) 
		END IF 
		DISPLAY pr_reqhead.req_num USING "<<<<<<<" at 3,22 
		attribute(yellow) 
		DISPLAY pr_reqdetl.line_num USING "<<<<<<<" at 4,22 
		attribute(yellow) 
		LET pr_alloc_cnt = pr_alloc_cnt + 1 
		DISPLAY pr_alloc_cnt USING "<<<<<<<" at 5,14 
		attribute(yellow) 
		LET pr_reqbackord.cmpy_code = pr_reqhead.cmpy_code 
		LET pr_reqbackord.part_code = pr_reqdetl.part_code 
		LET pr_reqbackord.ware_code = pr_reqhead.ware_code 
		LET pr_reqbackord.req_num = pr_reqhead.req_num 
		LET pr_reqbackord.line_num = pr_reqdetl.line_num 
		LET pr_reqbackord.person_code = pr_reqhead.person_code 
		LET pr_reqbackord.avail_qty = pr_available 
		LET pr_reqbackord.require_qty = pr_reqdetl.back_qty 
		IF pr_available > pr_reqdetl.back_qty THEN 
			LET pr_reqbackord.alloc_qty = pr_reqdetl.back_qty 
		ELSE 
			IF pr_available <= 0 THEN 
				LET pr_reqbackord.alloc_qty = 0 
			ELSE 
				LET pr_reqbackord.alloc_qty = pr_available 
			END IF 
		END IF 
		LET pr_available = pr_available - pr_reqbackord.alloc_qty 
		IF pr_reqbackord.alloc_qty IS NULL THEN 
			LET pr_reqbackord.alloc_qty = 0 
		END IF 
		IF pr_reqbackord.require_qty IS NULL THEN 
			LET pr_reqbackord.require_qty = 0 
		END IF 
		WHENEVER ERROR CONTINUE 
		INSERT INTO reqbackord VALUES (pr_reqbackord.*) 
		IF status < 0 THEN 
			CALL errorlog("N31 Requisition Back Order Insert ") 
		END IF 
		WHENEVER ERROR stop 
		SLEEP 1 
	END FOREACH 
	IF pr_alloc_cnt = 0 THEN 
		error" No Allocations Satisfied Selection Criteria " 
	ELSE 
		--      CLOSE WINDOW w2_N31     -- albo  KD-763
	END IF 
END FUNCTION 
