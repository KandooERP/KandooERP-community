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

	Source code beautified by beautify.pl on 2020-01-02 17:31:20	$Id: $
}


# Purpose - BOR Rollup

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pv_tot_sel SMALLINT, 
	pv_tot_left SMALLINT, 
	ma_keyptr INTEGER, 

	pr_menunames RECORD LIKE menunames.*, 

	ma_borkey array[1000] OF RECORD 
		pic CHAR(15), 
		seqnum SMALLINT, 
		cic CHAR(15), 
		est_cost_amt DECIMAL(16,4), 
		wgted_cost_amt DECIMAL(16,4), 
		act_cost_amt DECIMAL(16,4), 
		cogs_cost_amt DECIMAL(16,4), 
		list_price_amt DECIMAL(16,4), 
		qty FLOAT 
	END RECORD 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M1A") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL rollup_main() 

END MAIN 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the part FROM the SCREEN                               #
#-------------------------------------------------------------------------#

FUNCTION query_parent() 

	DEFINE 
	fv_cnt INTEGER, 
	fv_where_part CHAR(500), 
	fv_query_text CHAR(500) 


	LET msgresp = kandoomsg("M", 1500, "") 
	# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

	CONSTRUCT BY NAME fv_where_part 
	ON parent_part_code 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M", 9555, "") 
		# ERROR "Query Aborted"
		RETURN false 
	END IF 

	LET msgresp = kandoomsg("M", 1532, "") 
	# MESSAGE "Searching database - please wait"

	LET fv_query_text = "SELECT unique parent_part_code ", 
	"FROM bor ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", fv_where_part clipped 

	PREPARE statement1 FROM fv_query_text 
	DECLARE s_sroot_cursor SCROLL CURSOR FOR statement1 

	LET fv_cnt = 0 

	FOREACH s_sroot_cursor 
		LET fv_cnt = fv_cnt + 1 
	END FOREACH 

	IF fv_cnt = 0 THEN 
		LET msgresp = kandoomsg("M", 9621, "") 
		# ERROR "There are no root parts that fit your query"
		RETURN false 
	END IF 

	LET pv_tot_sel = fv_cnt 
	LET pv_tot_left = fv_cnt 
	OPEN s_sroot_cursor 
	RETURN true 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the SCREEN AND control the program flow            #
#-------------------------------------------------------------------------#

FUNCTION rollup_main() 

	DEFINE 
	fv_data_exists SMALLINT, 
	fv_rollup_ok SMALLINT, 
	fv_cnt SMALLINT, 
	fv_answer CHAR(1), 
	fv_part_code LIKE bor.parent_part_code, 
	fv_old_bor LIKE bor.parent_part_code, 
	fv_cost_ind LIKE inparms.cost_ind, 

	fr_prodmfg RECORD LIKE prodmfg.* 


	SELECT cost_ind 
	INTO fv_cost_ind 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET fv_part_code = NULL 

	CREATE temp TABLE indent_bor 
	( 
	cmpy_code CHAR(2), 
	parent_part_code CHAR(15), 
	sequence_no INTEGER, 
	child_part_code CHAR(15), 
	required_qty FLOAT, 
	level SMALLINT 
	) 

	OPEN WINDOW w0_bor_rollup with FORM "M178" 
	CALL  windecoration_m("M178") -- albo kd-762 

	CALL kandoomenu("M", 110) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # query 
			LET fv_data_exists = query_parent() 

			IF fv_data_exists THEN 
				CALL get_root("F", fv_part_code) 
				RETURNING fv_part_code, fv_rollup_ok 
				CALL display_root(fv_part_code) 
			END IF 

			NEXT option pr_menunames.cmd2_code # "Next" 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			IF fv_data_exists THEN 
				CALL get_root("N", fv_part_code) 
				RETURNING fv_part_code, fv_rollup_ok 
				CALL display_root(fv_part_code) 
			ELSE 
				LET msgresp = kandoomsg("M",9622,"") 
				# ERROR "You must perform a query BEFORE looking AT an part"
				NEXT option pr_menunames.cmd1_code # query 
			END IF 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text 
			IF fv_data_exists THEN 
				CALL get_root("P", fv_part_code) 
				RETURNING fv_part_code, fv_rollup_ok 
				CALL display_root(fv_part_code) 
			ELSE 
				LET msgresp = kandoomsg("M",9622,"") 
				# ERROR "You must perform a query BEFORE looking AT an part"
				NEXT option pr_menunames.cmd1_code # query 
			END IF 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			IF fv_data_exists THEN 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET fv_rollup_ok = false 
					LET msgresp = kandoomsg("M", 9623, "") 
					# ERROR "Rollup Aborted"
				ELSE 
					CALL get_root("F",fv_part_code) 
					RETURNING fv_part_code, fv_rollup_ok 
					CALL display_root(fv_part_code) 

					LET fv_rollup_ok = true 
					LET fv_old_bor = NULL 
					LET fv_cnt = 0 

					BEGIN WORK 

						WHILE fv_rollup_ok 
							IF fv_part_code = fv_old_bor THEN 
								EXIT WHILE 
							END IF 

							SELECT * 
							INTO fr_prodmfg.* 
							FROM prodmfg 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = fv_part_code 

							IF (fr_prodmfg.last_program_text <> "M1A") 
							OR (fr_prodmfg.last_change_date <> today) THEN 
								CALL do_bor_rollup(fv_part_code,fv_cost_ind) 
								LET fv_cnt = fv_cnt + 1 
							END IF 

							LET fv_old_bor = fv_part_code 

							CALL get_root("N",fv_part_code) 
							RETURNING fv_part_code, fv_rollup_ok 

							LET pv_tot_left = pv_tot_left - 1 
							CALL display_root(fv_part_code) 
						END WHILE 

					COMMIT WORK 

					IF fv_cnt = 0 THEN 
						CALL generate_sure() RETURNING fv_answer 

						IF fv_answer = "Y" THEN 
							UPDATE prodmfg 
							SET last_program_text = "" 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

							LET msgresp = kandoomsg("M",9624,"") 
							# ERROR "Reselect products FOR rollup"
						END IF 
					END IF 

					OPEN s_sroot_cursor 
					CALL get_root("L",fv_part_code) 
					RETURNING fv_part_code, fv_rollup_ok 
					CALL display_root(fv_part_code) 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M",9625,"") 
				# ERROR "You must perform a query BEFORE rolling up a bill"
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

			NEXT option pr_menunames.cmd2_code # "Next" 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW w0_bor_rollup 

	#PEM indent_bor may NOT have been created IF MENU IS aborted
	WHENEVER ERROR CONTINUE 
	DELETE FROM indent_bor 
	WHENEVER ERROR stop 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get a bill of resource RECORD FROM the database            #
#-------------------------------------------------------------------------#

FUNCTION get_root(fp_option,fp_old_bor) 

	DEFINE 
	fp_option CHAR(1), 
	fv_ok SMALLINT, 
	fp_old_bor LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.parent_part_code 


	LET fv_part_code = NULL 
	LET fv_ok = true 

	CASE 
		WHEN fp_option = "F" 
			FETCH FIRST s_sroot_cursor INTO fv_part_code 

		WHEN fp_option = "L" 
			FETCH LAST s_sroot_cursor INTO fv_part_code 

		WHEN fp_option = "N" 
			FETCH NEXT s_sroot_cursor INTO fv_part_code 

			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9626,"") 
				# ERROR "There are no more bills in this direction"
				LET fv_part_code = fp_old_bor 
				LET fv_ok = false 
			END IF 

		WHEN fp_option = "P" 
			FETCH previous s_sroot_cursor INTO fv_part_code 
			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9626,"") 
				# ERROR "There are no more bills in this direction"
				LET fv_part_code = fp_old_bor 
				LET fv_ok = false 
			END IF 
	END CASE 

	RETURN fv_part_code, fv_ok 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the root part on the SCREEN                        #
#-------------------------------------------------------------------------#

FUNCTION display_root(fp_part_code) 

	DEFINE 
	fp_part_code LIKE bor.parent_part_code, 
	fv_description LIKE product.desc_text 


	SELECT product.desc_text 
	INTO fv_description 
	FROM product 
	WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND product.part_code = fp_part_code 

	DISPLAY 
	fp_part_code, fv_description, 
	pv_tot_sel, pv_tot_left 
	TO parent_part_code, part_desc, 
	tot_sel, tot_left 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO perform a cost rollup on a single shop ORDER               #
#-------------------------------------------------------------------------#

FUNCTION do_bor_rollup(fp_part_code, fv_cost_ind) 

	DEFINE 
	fp_part_code LIKE bor.parent_part_code, 
	fv_kandoo_parts INTEGER, 
	fv_qty LIKE bor.required_qty, 
	fv_cost LIKE bor.cost_amt, 
	fv_price LIKE bor.price_amt, 
	fv_cost_ind LIKE inparms.cost_ind, 
	fr_bor RECORD LIKE bor.* 


	CALL clear_stack() 
	CALL traverse(fp_part_code, 10, true, fv_cost_ind) 
	RETURNING fv_kandoo_parts 

END FUNCTION 



FUNCTION generate_sure() 

	DEFINE 
	fv_answer CHAR(1) 

	{   -- albo
	    LET fv_answer = "A"

	    WHILE fv_answer NOT matches "[NY]"
	        prompt "BOR rollup already processed, regenerate it (Y/N)?"
	            FOR CHAR fv_answer
	        LET fv_answer = upshift(fv_answer)
	    END WHILE
	}
	-- albo --
	LET fv_answer = promptYN("","BOR rollup already processed, regenerate it (Y/N)?","Y") -- albo 
	LET fv_answer = upshift(fv_answer) 
	----------
	RETURN fv_answer 

END FUNCTION 

#-------------------------------------------------------------------------#
# Unknown reason behind this famous FUNCTION                              #
#-------------------------------------------------------------------------#

FUNCTION clear_stack() 
	# dummy FUNCTION
END FUNCTION 

#-------------------------------------------------------------------------#
# {  This FUNCTION exists only as a stepping stone between the previous   #
# version of this AND the new recursive traversal FUNCTION below}#
#-------------------------------------------------------------------------#

FUNCTION traverse(fp_part_code, fp_sequence_no, fp_window, fv_cost_ind) 

	DEFINE 
	fp_part_code LIKE bor.parent_part_code, 
	fp_sequence_no LIKE bor.sequence_num, 
	fp_window SMALLINT, 
	fv_cost_ind LIKE inparms.cost_ind, 
	fv_count INTEGER 

	{
	    OPEN WINDOW w0_working AT 15,8 with 3 rows, 56 columns   -- albo  KD-762
	        attributes (white, border)
	}
	CALL explode(fp_part_code,"",0,0,1,fv_cost_ind) 
	--    CLOSE WINDOW w0_working      -- albo  KD-762

	SELECT unique count(*) 
	INTO fv_count 
	FROM indent_bor 

	RETURN fv_count 

END FUNCTION 

#---------------------------------------------------------------------------#
#  This FUNCTION IS the basic structure FOR any traversal of the bill of    #
#  resources.  It IS in four main sections.                                 #
#                                                                           #
#  1.   Initial processing of the current child part.  This IS always       #
#       conditioned on the parent being NULL TO stop processing of the      #
#       first record.                                                       #
#                                                                           #
#  2.   The second section IS the CALL TO pushpart.  The push part FUNCTION #
#       builds a stack of all all parts in the tree TO this node including  #
#       parts (in this CASE DESC) AT the current AND preceding levels  BUT  #
#       no parts that have ever been processed.                             #
#                                                                           #
#  3.   The third section IS conditioned on the whether this part has any   #
#       children AT all (nkids = 0).  This code IS processed WHEN dealing   #
#       with leaf nodes - by definition nkids = 0                           #
#                                                                           #
#  4.   The next section IS used WHEN nkids IS > 0 - i.e. the current part  #
#       IS itself a parent of many other parts.  In this instance each child#
#       IS recursively processed through this FUNCTION.                     #
#       Note that it IS here that any returned VALUES are also processed.   #
#                                                                           #
#  5.   The last section processes any parent records AFTER the children    #
#       have been processed (in contrast with the initial section which     #
#       processes them before the children).                                #
#---------------------------------------------------------------------------#

FUNCTION explode(fv_partc, fv_partp, fv_seq, ln, fv_qty, fv_cost_ind) 

	DEFINE 
	fv_partc CHAR(15), 
	fv_partp CHAR(15), 
	ln INTEGER, 
	fv_seq INTEGER, 
	nkids INTEGER, 
	okids INTEGER, 
	fv_qty FLOAT, 
	mult FLOAT, 
	fv_cost_ind LIKE inparms.cost_ind, 
	fr_bor RECORD LIKE bor.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.* 


	LET mult = fv_qty 

	------Section 1 : before children processing of any children ------------

	DISPLAY fv_partp clipped, ": ", fv_partc clipped, "" at 2,2 

	IF fv_partp IS NOT NULL THEN 
		SELECT * 
		INTO fr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_partc 

		IF (fr_prodmfg.last_program_text <> "M1A") 
		OR (fr_prodmfg.last_change_date <> today) THEN 
			SELECT * 
			INTO fr_bor.* 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = fv_partp 
			AND sequence_num = fv_seq 
			AND part_code = fv_partc 

			IF status = 0 THEN 
				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_prodmfg.part_code 
				AND ware_code = fr_prodmfg.def_ware_code 

				IF status = 0 THEN 
					LET fr_prodmfg.est_cost_amt = fr_prodstatus.est_cost_amt 
					LET fr_prodmfg.wgted_cost_amt = fr_prodstatus.wgted_cost_amt 
					LET fr_prodmfg.act_cost_amt = fr_prodstatus.act_cost_amt 
					LET fr_prodmfg.list_price_amt = fr_prodstatus.list_amt 
				ELSE 
					LET fr_prodmfg.est_cost_amt = 0 
					LET fr_prodmfg.wgted_cost_amt = 0 
					LET fr_prodmfg.act_cost_amt = 0 
					LET fr_prodmfg.list_price_amt = 0 
				END IF 

				CASE 
					WHEN fv_cost_ind = "W" 
						LET fr_prodmfg.cogs_cost_amt = fr_prodmfg.wgted_cost_amt 
					WHEN fv_cost_ind = "F" 
						LET fr_prodmfg.cogs_cost_amt = fr_prodmfg.wgted_cost_amt 
					WHEN fv_cost_ind = "S" 
						LET fr_prodmfg.cogs_cost_amt = fr_prodmfg.est_cost_amt 
					WHEN fv_cost_ind = "L" 
						LET fr_prodmfg.cogs_cost_amt = fr_prodmfg.act_cost_amt 
				END CASE 
			END IF 

			INSERT INTO indent_bor 
			VALUES (glob_rec_kandoouser.cmpy_code, 
			fr_bor.parent_part_code, 
			fr_bor.sequence_num, 
			fr_bor.part_code, 
			fv_qty, 
			ln) 
		END IF 
	END IF 

	----- Section 2 : Determine any children of this part. ----------------

	CALL pushpart(fv_partc, fv_cost_ind) RETURNING nkids, okids 

	----- Section 3 : special processing IF the current part IS a leaf node ----

	IF nkids = 0 THEN 
		IF fv_partc IS NOT NULL THEN 
			CALL updatepart(fv_partc, fv_cost_ind) 
		END IF 
	END IF 

	IF okids < 0 THEN 
		LET okids = 0 
	END IF 

	----- Section 4 : Process the children of this part ------------------

	IF nkids > 0 THEN 
		WHILE nkids > 0 
			LET nkids = nkids -1 

			CALL explode(ma_borkey[ma_keyptr].cic, 
			ma_borkey[ma_keyptr].pic, 
			ma_borkey[ma_keyptr].seqnum, 
			ln + 1, 
			ma_borkey[ma_keyptr].qty * mult, 
			fv_cost_ind) 

			LET ma_keyptr = ma_keyptr -1 
		END WHILE 

		CALL updatepart(ma_borkey[ma_keyptr + 1].pic, fv_cost_ind) 
	END IF 

END FUNCTION 



FUNCTION pushpart(fv_part, fv_cost_ind) 

	DEFINE 
	fr_bor RECORD LIKE bor.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fv_part CHAR(15), 
	fv_cost_ind LIKE inparms.cost_ind, 
	oldtop INTEGER 


	IF fv_part IS NOT NULL THEN 
		SELECT * 
		INTO fr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_part 

		IF (fr_prodmfg.last_program_text <> "M1A") 
		OR (fr_prodmfg.last_change_date <> today) THEN 
			DECLARE c2 CURSOR FOR 
			SELECT * 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = fv_part 
			ORDER BY cmpy_code, parent_part_code, sequence_num desc 

			LET oldtop = ma_keyptr 

			FOREACH c2 INTO fr_bor.* 
				IF fr_bor.type_ind NOT matches "[CB]" THEN 
					CONTINUE FOREACH 
				END IF 

				IF fr_bor.start_date IS NOT NULL 
				AND fr_bor.start_date > today THEN 
					CONTINUE FOREACH 
				END IF 

				IF fr_bor.end_date IS NOT NULL 
				AND fr_bor.end_date < today THEN 
					CONTINUE FOREACH 
				END IF 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_prodmfg.part_code 
				AND ware_code = fr_prodmfg.def_ware_code 

				IF status = 0 THEN 
					LET fr_prodmfg.est_cost_amt = fr_prodstatus.est_cost_amt 
					LET fr_prodmfg.wgted_cost_amt = fr_prodstatus.wgted_cost_amt 
					LET fr_prodmfg.act_cost_amt = fr_prodstatus.act_cost_amt 
					LET fr_prodmfg.list_price_amt = fr_prodstatus.list_amt 
				ELSE 
					LET fr_prodmfg.est_cost_amt = 0 
					LET fr_prodmfg.wgted_cost_amt = 0 
					LET fr_prodmfg.act_cost_amt = 0 
					LET fr_prodmfg.list_price_amt = 0 
				END IF 

				LET ma_borkey[ma_keyptr + 1].pic = fr_bor.parent_part_code 
				LET ma_borkey[ma_keyptr + 1].seqnum = fr_bor.sequence_num 
				LET ma_borkey[ma_keyptr + 1].cic = fr_bor.part_code 
				LET ma_borkey[ma_keyptr + 1].qty = fr_bor.required_qty 
				LET ma_borkey[ma_keyptr + 1].est_cost_amt = 
				fr_prodmfg.est_cost_amt 
				LET ma_borkey[ma_keyptr + 1].wgted_cost_amt = 
				fr_prodmfg.wgted_cost_amt 
				LET ma_borkey[ma_keyptr + 1].act_cost_amt = 
				fr_prodmfg.act_cost_amt 
				LET ma_borkey[ma_keyptr + 1].list_price_amt = 
				fr_prodmfg.list_price_amt 

				CASE 
					WHEN fv_cost_ind = "W" 
						LET ma_borkey[ma_keyptr + 1].cogs_cost_amt = 
						fr_prodmfg.wgted_cost_amt 
					WHEN fv_cost_ind = "F" 
						LET ma_borkey[ma_keyptr + 1].cogs_cost_amt = 
						fr_prodmfg.wgted_cost_amt 
					WHEN fv_cost_ind = "S" 
						LET ma_borkey[ma_keyptr + 1].cogs_cost_amt = 
						fr_prodmfg.est_cost_amt 
					WHEN fv_cost_ind = "L" 
						LET ma_borkey[ma_keyptr + 1].cogs_cost_amt = 
						fr_prodmfg.act_cost_amt 
				END CASE 

				LET ma_keyptr = ma_keyptr+1 
			END FOREACH 
		ELSE 
			LET oldtop = ma_keyptr 
		END IF 
	ELSE 
		LET oldtop = ma_keyptr 
	END IF 

	RETURN (ma_keyptr - oldtop ), oldtop 

END FUNCTION -- pushpart-- 



FUNCTION updatepart(fv_part, fv_cost_ind) 

	DEFINE 
	fr_bor RECORD LIKE bor.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fv_part CHAR(15), 
	fv_min_ord_qty LIKE product.min_ord_qty, 
	fv_cost_ind LIKE inparms.cost_ind, 
	fv_cost_est DECIMAL(16,4), 
	fv_cost_act DECIMAL(16,4), 
	fv_cost_wgt DECIMAL(16,4), 
	fv_cost_cog DECIMAL(16,4), 
	fv_price DECIMAL(16,4), 
	fv_wc_tot DECIMAL(16,4), 
	fv_setup_qty SMALLINT, 
	fv_count INTEGER, 
	oldtop INTEGER 


	SELECT * 
	INTO fr_prodmfg.* 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_part 

	IF fr_prodmfg.last_program_text <> "M1A" 
	OR fr_prodmfg.last_change_date <> today THEN 
		LET fv_cost_est = 0 
		LET fv_cost_act = 0 
		LET fv_cost_wgt = 0 
		LET fv_cost_cog = 0 
		LET fv_price = 0 

		SELECT unique count(*) 
		INTO fv_count 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fv_part 

		IF fv_count = 0 THEN 
			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			SELECT * 
			INTO fr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_prodmfg.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			IF status = 0 THEN 
				IF fr_prodmfg.man_stk_con_qty IS NULL 
				OR fr_prodmfg.man_stk_con_qty = 0 THEN 
					LET fr_prodmfg.man_stk_con_qty = 1 
				END IF 

				IF fr_product.pur_stk_con_qty IS NULL 
				OR fr_product.pur_stk_con_qty = 0 THEN 
					LET fr_product.pur_stk_con_qty = 1 
				END IF 

				IF fr_product.stk_sel_con_qty IS NULL 
				OR fr_product.stk_sel_con_qty = 0 THEN 
					LET fr_product.stk_sel_con_qty = 1 
				END IF 

				LET fv_cost_wgt = (fr_prodstatus.wgted_cost_amt * 
				fr_product.stk_sel_con_qty * 
				fr_prodmfg.man_stk_con_qty) 
				LET fv_cost_act = (fr_prodstatus.act_cost_amt * 
				fr_product.stk_sel_con_qty * 
				fr_prodmfg.man_stk_con_qty) 
				LET fv_cost_est = (fr_prodstatus.est_cost_amt * 
				fr_product.stk_sel_con_qty * 
				fr_prodmfg.man_stk_con_qty) 
				LET fv_price = (fr_prodstatus.list_amt * 
				fr_product.stk_sel_con_qty * 
				fr_prodmfg.man_stk_con_qty) 
			ELSE 
				LET fv_cost_est = 0 
				LET fv_cost_wgt = 0 
				LET fv_cost_act = 0 
				LET fv_price = 0 
			END IF 
		ELSE 
			SELECT min_ord_qty 
			INTO fv_min_ord_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fv_part 

			IF fv_min_ord_qty IS NULL 
			OR fv_min_ord_qty = 0 THEN 
				LET fv_min_ord_qty = 1 
			END IF 

			DECLARE c3 CURSOR FOR 
			SELECT * 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = fv_part 
			ORDER BY sequence_num desc 

			FOREACH c3 INTO fr_bor.* 
				IF fr_bor.start_date IS NOT NULL 
				AND fr_bor.start_date > today THEN 
					CONTINUE FOREACH 
				END IF 

				IF fr_bor.end_date IS NOT NULL 
				AND fr_bor.end_date < today THEN 
					CONTINUE FOREACH 
				END IF 

				CASE fr_bor.type_ind 
					WHEN "B" 
						CONTINUE FOREACH 

					WHEN "I" 
						CONTINUE FOREACH 

					WHEN "S" 
						IF fr_bor.cost_amt IS NULL THEN 
							LET fr_bor.cost_amt = 0 
						END IF 

						IF fr_bor.price_amt IS NULL THEN 
							LET fr_bor.price_amt = 0 
						END IF 

						IF fr_bor.cost_type_ind = "F" THEN 
							LET fv_cost_est = fv_cost_est + fr_bor.cost_amt 
							LET fv_cost_act = fv_cost_act + fr_bor.cost_amt 
							LET fv_cost_wgt = fv_cost_wgt + fr_bor.cost_amt 
							LET fv_price = fv_price + fr_bor.price_amt 
						ELSE 
							LET fv_cost_est = fv_cost_est + (fr_bor.cost_amt * 
							fv_min_ord_qty) 
							LET fv_cost_act = fv_cost_act + (fr_bor.cost_amt * 
							fv_min_ord_qty) 
							LET fv_cost_wgt = fv_cost_wgt + (fr_bor.cost_amt * 
							fv_min_ord_qty) 
							LET fv_price = fv_price + (fr_bor.price_amt * 
							fv_min_ord_qty) 
						END IF 

					WHEN "W" 
						SELECT * 
						INTO fr_workcentre.* 
						FROM workcentre 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_bor.work_centre_code 

						SELECT sum(rate_amt) 
						INTO fr_bor.cost_amt 
						FROM workctrrate 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_bor.work_centre_code 
						AND rate_ind = "V" 

						IF fr_bor.cost_amt IS NULL THEN 
							LET fr_bor.cost_amt = 0 
						END IF 

						SELECT sum(rate_amt) 
						INTO fr_bor.price_amt 
						FROM workctrrate 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_bor.work_centre_code 
						AND rate_ind = "F" 

						IF fr_bor.price_amt IS NULL THEN 
							LET fr_bor.price_amt = 0 
						END IF 

						IF fr_workcentre.processing_ind = "Q" THEN 
							LET fv_wc_tot = ((fr_bor.cost_amt / 
							fr_workcentre.time_qty) * fr_bor.oper_factor_amt 
							* fv_min_ord_qty) + fr_bor.price_amt 
							LET fv_cost_est = fv_cost_est + fv_wc_tot 
							LET fv_cost_act = fv_cost_act + fv_wc_tot 
							LET fv_cost_wgt = fv_cost_wgt + fv_wc_tot 
							LET fv_price = fv_price + fv_wc_tot + 
							((fv_wc_tot * fr_workcentre.cost_markup_per) 
							/ 100 ) 
						ELSE 
							LET fv_wc_tot = (fr_bor.cost_amt * 
							fr_bor.oper_factor_amt 
							* fv_min_ord_qty) 
							+ fr_bor.price_amt 
							LET fv_cost_est = fv_cost_est + fv_wc_tot 
							LET fv_cost_act = fv_cost_act + fv_wc_tot 
							LET fv_cost_wgt = fv_cost_wgt + fv_wc_tot 
							LET fv_price = fv_price + fv_wc_tot + 
							((fv_wc_tot * 
							fr_workcentre.cost_markup_per) 
							/ 100 ) 
						END IF 

					WHEN "U" 
						IF fr_bor.cost_amt IS NULL THEN 
							LET fr_bor.cost_amt = 0 
						END IF 

						IF fr_bor.price_amt IS NULL THEN 
							LET fr_bor.price_amt = 0 
						END IF 

						LET fv_cost_est = fv_cost_est + fr_bor.cost_amt 
						LET fv_cost_act = fv_cost_act + fr_bor.cost_amt 
						LET fv_cost_wgt = fv_cost_wgt + fr_bor.cost_amt 
						LET fv_price = fv_price + fr_bor.price_amt 

					OTHERWISE 
						SELECT * 
						INTO fr_prodmfg.* 
						FROM prodmfg 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fr_bor.part_code 

						SELECT * 
						INTO fr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fr_bor.part_code 

						IF fr_prodmfg.man_stk_con_qty IS NULL 
						OR fr_prodmfg.man_stk_con_qty = 0 THEN 
							LET fr_prodmfg.man_stk_con_qty = 1 
						END IF 

						IF fr_product.pur_stk_con_qty IS NULL 
						OR fr_product.pur_stk_con_qty = 0 THEN 
							LET fr_product.pur_stk_con_qty = 1 
						END IF 

						IF fr_product.stk_sel_con_qty IS NULL 
						OR fr_product.stk_sel_con_qty = 0 THEN 
							LET fr_product.stk_sel_con_qty = 1 
						END IF 

						IF fr_prodmfg.last_program_text <> "M1A" 
						OR fr_prodmfg.last_change_date <> today THEN 
							SELECT * 
							INTO fr_prodstatus.* 
							FROM prodstatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = fr_bor.part_code 
							AND ware_code = fr_prodmfg.def_ware_code 

							IF status = 0 THEN 
								LET fr_prodmfg.wgted_cost_amt = 
								(fr_prodstatus.wgted_cost_amt * 
								fr_product.stk_sel_con_qty * 
								fr_prodmfg.man_stk_con_qty) 
								LET fr_prodmfg.act_cost_amt = 
								(fr_prodstatus.act_cost_amt * 
								fr_product.stk_sel_con_qty * 
								fr_prodmfg.man_stk_con_qty) 
								LET fr_prodmfg.est_cost_amt = 
								(fr_prodstatus.est_cost_amt * 
								fr_product.stk_sel_con_qty * 
								fr_prodmfg.man_stk_con_qty) 
								LET fr_prodmfg.list_price_amt = 
								(fr_prodstatus.list_amt * 
								fr_product.stk_sel_con_qty * 
								fr_prodmfg.man_stk_con_qty) 
							ELSE 
								LET fr_prodmfg.wgted_cost_amt = 0 
								LET fr_prodmfg.act_cost_amt = 0 
								LET fr_prodmfg.est_cost_amt = 0 
								LET fr_prodmfg.list_price_amt = 0 
							END IF 

							CASE fv_cost_ind 
								WHEN "W" 
									LET fr_prodmfg.cogs_cost_amt = 
									fr_prodmfg.wgted_cost_amt 
								WHEN "F" 
									LET fr_prodmfg.cogs_cost_amt = 
									fr_prodmfg.wgted_cost_amt 
								WHEN "S" 
									LET fr_prodmfg.cogs_cost_amt = 
									fr_prodmfg.est_cost_amt 
								WHEN "L" 
									LET fr_prodmfg.cogs_cost_amt = 
									fr_prodmfg.act_cost_amt 
							END CASE 

							UPDATE prodmfg 
							SET est_cost_amt = fr_prodmfg.est_cost_amt, 
							wgted_cost_amt = fr_prodmfg.wgted_cost_amt, 
							act_cost_amt = fr_prodmfg.act_cost_amt, 
							cogs_cost_amt = fr_prodmfg.cogs_cost_amt, 
							list_price_amt = fr_prodmfg.list_price_amt, 
							last_change_date = today, 
							last_user_text = glob_rec_kandoouser.sign_on_code, 
							last_program_text = "M1A" 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = fr_bor.part_code 
						END IF 

						IF fr_bor.required_qty < 0 THEN 
							LET fr_bor.required_qty = fr_bor.required_qty * -1 
						END IF 

						LET fr_bor.required_qty = fr_bor.required_qty * 
						fv_min_ord_qty 

						LET fr_prodmfg.act_cost_amt = fr_prodmfg.act_cost_amt * 
						fr_bor.required_qty 
						LET fr_prodmfg.wgted_cost_amt = 
						fr_prodmfg.wgted_cost_amt * fr_bor.required_qty 
						LET fr_prodmfg.est_cost_amt = fr_prodmfg.est_cost_amt * 
						fr_bor.required_qty 
						LET fr_prodmfg.list_price_amt = 
						fr_prodmfg.list_price_amt * fr_bor.required_qty 

						CASE 
							WHEN fr_bor.uom_code = fr_product.pur_uom_code 
								LET fr_prodmfg.act_cost_amt = 
								fr_prodmfg.act_cost_amt / 
								(fr_prodmfg.man_stk_con_qty / 
								fr_product.pur_stk_con_qty) 
								LET fr_prodmfg.wgted_cost_amt = 
								fr_prodmfg.wgted_cost_amt / 
								(fr_prodmfg.man_stk_con_qty / 
								fr_product.pur_stk_con_qty) 
								LET fr_prodmfg.est_cost_amt = 
								fr_prodmfg.est_cost_amt / 
								(fr_prodmfg.man_stk_con_qty / 
								fr_product.pur_stk_con_qty) 
								LET fr_prodmfg.list_price_amt = 
								fr_prodmfg.list_price_amt / 
								(fr_prodmfg.man_stk_con_qty / 
								fr_product.pur_stk_con_qty) 

							WHEN fr_bor.uom_code = fr_product.stock_uom_code 
								LET fr_prodmfg.act_cost_amt = 
								fr_prodmfg.act_cost_amt / 
								fr_prodmfg.man_stk_con_qty 
								LET fr_prodmfg.wgted_cost_amt = 
								fr_prodmfg.wgted_cost_amt / 
								fr_prodmfg.man_stk_con_qty 
								LET fr_prodmfg.est_cost_amt = 
								fr_prodmfg.est_cost_amt / 
								fr_prodmfg.man_stk_con_qty 
								LET fr_prodmfg.list_price_amt = 
								fr_prodmfg.list_price_amt / 
								fr_prodmfg.man_stk_con_qty 

							WHEN fr_bor.uom_code = fr_product.sell_uom_code 
								LET fr_prodmfg.act_cost_amt = 
								fr_prodmfg.act_cost_amt / 
								(fr_prodmfg.man_stk_con_qty * 
								fr_product.stk_sel_con_qty) 
								LET fr_prodmfg.wgted_cost_amt = 
								fr_prodmfg.wgted_cost_amt / 
								(fr_prodmfg.man_stk_con_qty * 
								fr_product.stk_sel_con_qty) 
								LET fr_prodmfg.est_cost_amt = 
								fr_prodmfg.est_cost_amt / 
								(fr_prodmfg.man_stk_con_qty * 
								fr_product.stk_sel_con_qty) 
								LET fr_prodmfg.list_price_amt = 
								fr_prodmfg.list_price_amt / 
								(fr_prodmfg.man_stk_con_qty * 
								fr_product.stk_sel_con_qty) 
						END CASE 

						LET fv_cost_act = fv_cost_act + fr_prodmfg.act_cost_amt 
						LET fv_cost_wgt = fv_cost_wgt +fr_prodmfg.wgted_cost_amt 
						LET fv_cost_est = fv_cost_est + fr_prodmfg.est_cost_amt 
						LET fv_price = fv_price + fr_prodmfg.list_price_amt 
				END CASE 
			END FOREACH 

			LET fv_cost_act = fv_cost_act / fv_min_ord_qty 
			LET fv_cost_wgt = fv_cost_wgt / fv_min_ord_qty 
			LET fv_cost_est = fv_cost_est / fv_min_ord_qty 
			LET fv_price = fv_price / fv_min_ord_qty 
		END IF 

		CASE 
			WHEN fv_cost_ind = "W" 
				LET fv_cost_cog = fv_cost_wgt 
			WHEN fv_cost_ind = "F" 
				LET fv_cost_cog = fv_cost_wgt 
			WHEN fv_cost_ind = "S" 
				LET fv_cost_est = fv_cost_est 
			WHEN fv_cost_ind = "L" 
				LET fv_cost_act = fv_cost_act 
		END CASE 

		UPDATE prodmfg 
		SET est_cost_amt = fv_cost_est, 
		wgted_cost_amt = fv_cost_wgt, 
		act_cost_amt = fv_cost_act, 
		cogs_cost_amt = fv_cost_cog, 
		list_price_amt = fv_price, 
		last_change_date = today, 
		last_user_text = glob_rec_kandoouser.sign_on_code, 
		last_program_text = "M1A" 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_part 
	END IF 

END FUNCTION 
