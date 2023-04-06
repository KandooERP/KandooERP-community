############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#####################################################################
# FUNCTION rpt_set_kandooreport_defaults(NULL)
#
# Set the default report parameters
#####################################################################
FUNCTION rpt_set_kandooreport_defaults_I_IN(p_rec_kandooreport)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
	

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CASE upshift(p_rec_kandooreport.report_code)

		######################################################################
		# IN - Warehouse Inventory
		#
		######################################################################

		WHEN "I22"
			LET p_rec_kandooreport.header_text = "IN Stock Issue Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "I22" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			#LET p_rec_kandooreport.line1_text = " Transfer Currently Currently" 
			#LET p_rec_kandooreport.line2_text = "Product Quantity Scheduled Picked In Transit Received Remaining" 

		WHEN "I51"
			LET p_rec_kandooreport.header_text = "Stock Transfers Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "I51" #N41 / N43
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "N" 
			LET p_rec_kandooreport.line1_text = " Transfer Currently Currently" 
			LET p_rec_kandooreport.line2_text = "Product Quantity Scheduled Picked In Transit Received Remaining" 


		WHEN "I5A"
			LET p_rec_kandooreport.header_text = "Stock Transfers Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "I5A" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                                                      Transfer      Currently     Currently" 
			LET p_rec_kandooreport.line2_text = "Product                                               Quantity      Scheduled       Picked    In Transit      Received     Remaining" 

		WHEN "I5T"
			LET p_rec_kandooreport.header_text = "Stock Transfer Confirmation Status" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "I5T" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Transfer  Confirmed UOM      Source       Docket  Confirmed   Transit    Receipt  Receipt   Product                     Vehicle"
			LET p_rec_kandooreport.line2_text = "    Number    Quantity         W/H Cost       Ref.     Date     Quantity   Quantity    Date                                  No."

		WHEN "IA1"
			LET p_rec_kandooreport.header_text = "IN - Product Detail List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IA1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Product Code    Product Description                       Category                 Class            Purc.  Conv   Stock  Conv   Sell"
			LET p_rec_kandooreport.line2_text = "                                                     Code Description     Code     Description      UOM    Qty    UOM    Qty    UOM"
		
		WHEN "IA2"
			LET p_rec_kandooreport.header_text = "IN - Product List by Inventory Category" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IA2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Product Code    Product Description                    Class    Class                          Purc.    Conv   Stock    Conv   Sell"
			LET p_rec_kandooreport.line2_text = "                                                       Code     Description                    UOM      Qty    UOM      Qty    UOM"

		WHEN "IA3"
			LET p_rec_kandooreport.header_text = "IN - Product List by Inventory Class" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IA3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Product Code    Product Description                     Category                              Purc.    Conv   Stock     Conv    Sell"
			LET p_rec_kandooreport.line2_text = "                                                        Code Description                      UOM       Qty    UOM       Qty    UOM"

		WHEN "IA4"
			LET p_rec_kandooreport.header_text = "IN - Product Relationships" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IA4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Product         Product                              Second Product                  Alternative     Superseded      Companion"
			LET p_rec_kandooreport.line2_text = "Code            Description                          Description                     Product Code    Product Code    Product Code"

		WHEN "IAA"
			LET p_rec_kandooreport.header_text = "IN - Product History" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Product            Year Period       Sales        Credits     Reclass out     Reclass in       Purchases     Trans In      Trans Out"
			LET p_rec_kandooreport.line2_text = "    Warehouse                       Amount         Amount         Amount         Amount         Amount         Amount         Amount"

		WHEN "IAB"
			LET p_rec_kandooreport.header_text = "IN - Product Ledger" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Date     Period Reference        Number           Quantity               Unit          Extended             Unit           Extended"
			LET p_rec_kandooreport.line2_text = "         Year     Type                                                   Cost          Cost                 Price          Price"

		WHEN "IAB_B"
			LET p_rec_kandooreport.header_text = "IN - Product Ledger" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAB_B" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Date     Period Reference        Number           Quantity               Unit          Extended             Unit           Extended"
			LET p_rec_kandooreport.line2_text = "         Year     Type                                                   Cost          Cost                 Price          Price"

		WHEN "IAD"
			LET p_rec_kandooreport.header_text = "IN - Product Movement Ledger" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"		
			LET p_rec_kandooreport.line1_text = "Date        Period                 Number           Quantity           Balance"
			LET p_rec_kandooreport.line2_text = "         Year    Type                                                  Quantity"

		WHEN "IAE"
			LET p_rec_kandooreport.header_text = "IN - Product Master List" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAE" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product         Product                                      List  Superseded      Supersedes      Tariff          Duty Bin Location"
			LET p_rec_kandooreport.line2_text = "Code            Description                                  Price     By                           Code           Rate"

		WHEN "IAF"
			LET p_rec_kandooreport.header_text = "Stock Loss Report" 
			LET p_rec_kandooreport.width_num = 160 
			#LET p_rec_kandooreport.length_num = 66
			LET p_rec_kandooreport.menupath_text = "IAF" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Vendor,Name,Curr.,Main Group,Desc.,Part Group,Desc.,Part,Desc.,OEM,Tariff,Rate,Qty,For. Cost,For. Curr Code,Latest Cost,Receipt Date,Cost Amt" 

		WHEN "IAG"
			LET p_rec_kandooreport.header_text = "Zero Stock Supply Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAG" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Vendor Code,Vendor Name,Currency Code,Main Group Code,Description,Product Group,Description,Part Code,Description,OEM Code,Tariff Code,Tariff Rate,Qty,Latest Foreign Cost,Latest Cost,Last Receipt Date,Cost Amount" 

		WHEN "IAH"
			LET p_rec_kandooreport.header_text = "IN - Product Quantity History" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product            Year Period       Sales        Credits     Reclass out     Reclass In     Purchases       Trans In      Trans Out"
			LET p_rec_kandooreport.line2_text = "    Warehouse                     Quantity       Quantity       Quantity       Quantity       Quantity       Quantity       Quantity"

		WHEN "IAW"
			LET p_rec_kandooreport.header_text = "IN - Product Ledger by Warehouse" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IAW" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date     Period Reference      Number         Quantity            Unit               Extended          Unit               Extended"
			LET p_rec_kandooreport.line2_text = "         Year   Type                                              Cost                 Cost            Price                Price"

		WHEN "IB1"
			LET p_rec_kandooreport.header_text = "IN - Product Status by Warehouse" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "  Product        Status                  On Hand      Reserved    Back Order     Avail Now      Purchase   Forward Ord  Future Avail"
			LET p_rec_kandooreport.line2_text = "     Description                           Qty          Qty          Qty            Qty            Qty         Qty          Qty"

		WHEN "IB2"
			LET p_rec_kandooreport.header_text = "IN - Product Status by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Warehouse    On Hand        Reserved       Back Order       Avail Now       Purchase       Forward Ord     Future Avail"
			LET p_rec_kandooreport.line2_text = "               Qty             Qty             Qty             Qty             Qty             Qty              Qty"

		WHEN "IB3"
			LET p_rec_kandooreport.header_text = "IN - Stock Valuations" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                  Category      Class           On Hand       Avail Now             Unit           Onhand              Avail"
			LET p_rec_kandooreport.line2_text = "  Code                     Code         Code             Qty            Qty                Cost            Value              Value"
			LET p_rec_kandooreport.line3_text = " Valuation using Weighted Average Cost"
			LET p_rec_kandooreport.line4_text = " Valuation using Last Cost"
			LET p_rec_kandooreport.line5_text = " Valuation using Standard Cost"

		WHEN "IB4"
			LET p_rec_kandooreport.header_text = "IN - Minimum Reorder Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Ware          On Hand        Back Order        Purchase        Forward Ord      Future Avail       Reorder Point      Min Reorder"
			LET p_rec_kandooreport.line2_text = "House           Qty              Qty              Qty              Qty               Qty                Qty               Qty"

		WHEN "IB5"
			LET p_rec_kandooreport.header_text = "IN - Critical Status Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Ware           On Hand          Reserved         Back Order         Avail Now         Critical          Purchase         Forward Ord"
			LET p_rec_kandooreport.line2_text = "House            Qty               Qty               Qty               Qty               Qty               Qty               Qty"

		WHEN "IB8"
			LET p_rec_kandooreport.header_text = "IN - Top 100 Products" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Gross      Product                 Description                      Gross       GP          GP          Net Sales          Net Cost"
			LET p_rec_kandooreport.line2_text = "Ranking      Code                                                   Profit   Percent      Ranking         Amount            Amount"

		WHEN "IB9"
			LET p_rec_kandooreport.header_text = "IN - Bottom 100 Products" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IB9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Gross      Product                 Description                      Gross       GP          GP          Net Sales          Net Cost"
			LET p_rec_kandooreport.line2_text = "Ranking      Code                                                   Profit   Percent      Ranking         Amount            Amount"

		WHEN "IBA" --6
			LET p_rec_kandooreport.header_text = "IN - Top 100 Products by Net Sales Value"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Gross      Product                 Description              GP       Sales      Net Sales        Net Cost         Gross       GP"
			LET p_rec_kandooreport.line2_text = "Ranking      Code                                         Ranking   Volume        Amount          Amount          Profit       %"

		WHEN "IBA." --4
			LET p_rec_kandooreport.header_text = "IN - Top 100 Products by Gross Sales Value"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Gross      Product                 Description              GP       Sales      Net Sales        Net Cost         Gross       GP"
			LET p_rec_kandooreport.line2_text = "Ranking      Code                                         Ranking   Volume        Amount          Amount          Profit       %"
			
		WHEN "IBA.." --7
			LET p_rec_kandooreport.header_text = "IN - Top 100 Products by Sales Volume"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Gross      Product                 Description              GP       Sales      Net Sales        Net Cost         Gross       GP"
			LET p_rec_kandooreport.line2_text = "Ranking      Code                                         Ranking   Volume        Amount          Amount          Profit       %"
			
		WHEN "IBC"
			LET p_rec_kandooreport.header_text = "IN - Product Reorder Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBC" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Warehouse          On Hand    Reserved    Back Orde   Purchase Future Avail Reorder  Min Order  Recommended  Unit Cost   Total Cost"
			LET p_rec_kandooreport.line2_text = "                     Qty         Qty         Qty         Qty        Qty       Point      Qty        Qty"

		WHEN "IBD"
			LET p_rec_kandooreport.header_text = "IN - Stock Sales Extract Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBD" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                      Description              Cat Prod.Gr Onhand Qty  Onhand Value Last Purchase Last Sale Unit   Sales Qty"

		WHEN "IBT"
			LET p_rec_kandooreport.header_text = "IN - Product Trends Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBT" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                                                                                             Total Onhand  Year  Qtr       Year Qtr"

		WHEN "IBS"
			LET p_rec_kandooreport.header_text = "IN - Warehouse Period History Summary" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IBS" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Balance       Amount      Amount     Amount     Amount       Amount      Balance              Profit"
			LET p_rec_kandooreport.line2_text = "Opening        Sales     Credits   Purchases Adjustments   Transfers     Closing    Movement  Gross%"

		WHEN "IC1"
			LET p_rec_kandooreport.header_text = "IN - Product Pricing by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product     Warehouse                    Price                   List           Level 1        Level 2        Level 3        Level 4"
			LET p_rec_kandooreport.line2_text = "                                         Unit                    Level 5        Level 6        Level 7        Level 8        Level 9"

		WHEN "IC2"
			LET p_rec_kandooreport.header_text = "IN - Product Pricing by Warehouse" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                  Description              Warehouse   Stock      List"
			LET p_rec_kandooreport.line2_text = "                                                     Code     Unit"

		WHEN "IC3"
			LET p_rec_kandooreport.header_text = "IN - Product Pricing by Category (FIFO)" 
			LET p_rec_kandooreport.width_num = 120 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Category    Product       Warehouse    List        UOM    On Hand        FIFO          Last        Foreign     Foreign"
			LET p_rec_kandooreport.line2_text = "  Code        Code           Code      Price              Quantity       Cost          Cost          Cost      Currency"


		WHEN "IC5"
			LET p_rec_kandooreport.header_text = "IN - Product Pricing by Category" 
			LET p_rec_kandooreport.width_num = 120 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Category    Product       Warehouse    List        UOM    On Hand      Weighted        Last        Foreign     Foreign"
			LET p_rec_kandooreport.line2_text = "  Code        Code           Code      Price              Quantity       Cost          Cost          Cost      Currency"

		WHEN "IC6"
			LET p_rec_kandooreport.header_text = "IN - Detailed Book Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product                       Warehouse Source Type  Date       Qty     Cost Price     Curr Value     Curr W/off     Prev W/off"

		WHEN "IC6."
			LET p_rec_kandooreport.header_text = "IN - Detailed Tax Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product                       Warehouse Source Type  Date       Qty     Cost Price     Curr Value     Curr W/off     Prev W/off"

		WHEN "IC7"
			LET p_rec_kandooreport.header_text = "IN - Summary Book Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                        Category                                   Qty      Curr Value     Curr W/off     Prev W/off    Total Value"

		WHEN "IC7."
			LET p_rec_kandooreport.header_text = "IN - Summary Tax Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IC7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                        Category                                   Qty      Curr Value     Curr W/off     Prev W/off    Total Value"

		WHEN "ICE"
			LET p_rec_kandooreport.header_text = "IN - Price Execption Report by Product" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ICE" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product        Customer        Invoice        Invoice          Invoice        Invoice       Customer       Discount"
			LET p_rec_kandooreport.line2_text = "    Code            Code           Number          Date           Quantity        Price          List            %"

		WHEN "ICF"
			LET p_rec_kandooreport.header_text = "IN - Price Exception Report By Customer" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ICF" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "  Customer         Product        Invoice        Invoice          Invoice        Invoice       Customer       Discount"
			LET p_rec_kandooreport.line2_text = "    Code            Code           Number          Date           Quantity        Price          List            %"

		WHEN "ICG"
			LET p_rec_kandooreport.header_text = "IN - Price Gross Profit List by Group" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ICG" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product    Description  Vendor    Price       List        Std.   List  Lev 1  Lev 2  Lev 3  Lev 4  Lev 5  Lev 6  Lev 7  Lev 8  Lev 9"
			LET p_rec_kandooreport.line2_text = "  Code                   Code      UOM       Price        Cost   GP%    GP%    GP%    GP%    GP%    GP%    GP%    GP%    GP%    GP%"
			LET p_rec_kandooreport.line3_text = "Gross Profit Percentages"

		WHEN "ICH"
			LET p_rec_kandooreport.header_text = "IN - Price List by Vendor/Group" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ICH" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                                                                                               Price        List"
			LET p_rec_kandooreport.line2_text = "Product Code       Description                       Vendor Product Code (OEM)                  UOM        Price"

		WHEN "ICI"
			LET p_rec_kandooreport.header_text = "IN - Price Gross Profit List by Vendor/Group" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ICI" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "                                                                                   Price Purch      List         Std.     Gross"
			LET p_rec_kandooreport.line2_text = "Product Code       Description                       Vendor Product Code (OEM)      UOM   Tax       Price        Cost    Profit %"

		WHEN "ID1"
			LET p_rec_kandooreport.header_text = "IN - Stock Replenishment Report by Warehouse"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                                                  On Hand UOM         Required UOM     Stck/Purch.      Re-ORDER UOM"

		WHEN "ID2"
			LET p_rec_kandooreport.header_text = "IN - Stock Over-stock Report by Warehouse"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                                                  On Hand UOM         Required UOM       Over-Stock UOM    Over-Days"

		WHEN "ID3"
			LET p_rec_kandooreport.header_text = "IN - Stock Replenishment Report by Product"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                                           Warehouse   On Hand UOM         Required UOM     Stck/Purch.      Re-ORDER UOM"

		WHEN "ID4"
			LET p_rec_kandooreport.header_text = "IN - Stock Over-stock Report by Product"
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product                                           Warehouse   On Hand UOM         Required UOM       Over-Stock UOM      Over-Days"

		WHEN "ID6"
			LET p_rec_kandooreport.header_text = "IN - Product Reorder Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line2_text = "House            Qty               Qty               Qty               Qty               Qty               Qty               Qty" 

		WHEN "ID6."
			LET p_rec_kandooreport.header_text = "IN - Requistion Exception Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date Time                Comments"

		WHEN "ID7"
			LET p_rec_kandooreport.header_text = "IN - Weekly Recommended Reorder Report by Vendor" 
			LET p_rec_kandooreport.width_num = 102 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product Code    Description                              Net Stock         Total        Total Order"
			LET p_rec_kandooreport.line2_text = "                                                           Total         Reorder Qty        Cost"

		WHEN "ID8"
			LET p_rec_kandooreport.header_text = "IN - Stock Replenishment Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product         Description                            On Hand   Alloc  Available Purchase Future  Critical   Lead  Reorder Reorder"
			LET p_rec_kandooreport.line2_text = "Code                                                     Qty      Qty      Qty      Qty   Avail Qty   Qty     Time   Point  Quantity"
			LET p_rec_kandooreport.line3_text = "Grp Cat  Class    Last Receipt    Last Cost  Pur  Stk  Mth Demand   Demand        Value   Excess   Ordered    Quoted   Orders"
			LET p_rec_kandooreport.line4_text = "Sales Orders:    Customer    Order    Date      Required  UOM   Unit Price  Ext Price  Delivery"
			LET p_rec_kandooreport.line5_text = "Purchase Orders: Vendor      Order    Date      Quantity  UOM    Unit Cost  Ext Cost   Expected"

		WHEN "ID8."
			LET p_rec_kandooreport.header_text = "IN - Requistion Exception Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ID8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date Time                Comments"

		WHEN "IF4"
			LET p_rec_kandooreport.header_text = "IN - Detailed Book Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product                Warehouse    Source Type  Date       Qty       Cost Price      Curr Value      Curr W/off      Prev W/off"

		WHEN "IF4."
			LET p_rec_kandooreport.header_text = "IN - Detailed Tax Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product                Warehouse    Source Type  Date       Qty       Cost Price      Curr Value      Curr W/off      Prev W/off"

		WHEN "IF5"
			LET p_rec_kandooreport.header_text = "IN - Summary Book Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Category                                                     Qty      Curr Value       Curr W/off       Prev W/off      Total Value"

		WHEN "IF5."
			LET p_rec_kandooreport.header_text = "IN - Summary Tax Stock Valuation" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Category                                                     Qty      Curr Value       Curr W/off       Prev W/off      Total Value"

		WHEN "IF6"
			LET p_rec_kandooreport.header_text = "IN - Aged Book Stock Valuation Summary by Product Group" 
			LET p_rec_kandooreport.width_num = 160 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product            Total      Year 1        Year 2        Year 3        Year 4        Year 5        Year 6      > Year 6         Total         Written Down"
			LET p_rec_kandooreport.line2_text = "                    Qty       Value         Value         Value         Value         Value         Value         Value          Value       Qty        Value"

		WHEN "IF6."
			LET p_rec_kandooreport.header_text = "IN - Aged Tax Stock Valuation Summary by Product Group" 
			LET p_rec_kandooreport.width_num = 160 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product            Total      Year 1        Year 2        Year 3        Year 4        Year 5        Year 6      > Year 6         Total         Written Down"
			LET p_rec_kandooreport.line2_text = "                    Qty       Value         Value         Value         Value         Value         Value         Value          Value       Qty        Value"

		WHEN "IF7"
			LET p_rec_kandooreport.header_text = "IN - Costledger Validation Update Report" 
			LET p_rec_kandooreport.width_num = 124 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product         Description                       Warehouse   Prodstatus       Costledger       Difference      Action"
			LET p_rec_kandooreport.line2_text = "                                                       Code       On Hand           On Hand"

		WHEN "IF7."
			LET p_rec_kandooreport.header_text = "IN - Costledger Validation Report" 
			LET p_rec_kandooreport.width_num = 114 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product         Description                       Warehouse   Prodstatus       Costledger       Difference"
			LET p_rec_kandooreport.line2_text = "                                                       Code       On Hand           On Hand"

		WHEN "IF7.."
			LET p_rec_kandooreport.header_text = "IN - Costledger Validation Detailed Report" 
			LET p_rec_kandooreport.width_num = 114 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Product        Warehouse                           Transaction                   On Hand             Received"
			LET p_rec_kandooreport.line2_text = "                                       Date        Type          Qty                  Qty                  Qty"

		WHEN "IF8"
			LET p_rec_kandooreport.header_text = "IN - Aged Book Stock Valuation Summary by Product Group" 
			LET p_rec_kandooreport.width_num = 160 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product  Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value"
			LET p_rec_kandooreport.line2_text = "Category Year 1     Year 2     Year 3     Year 4     Year 5     Year 6     Year 7     Year 8     Year 9    Year 10    Year 11    Year 12    Year 12 >     Total"

		WHEN "IF8."
			LET p_rec_kandooreport.header_text = "IN - Aged Tax Stock Valuation Summary by Product Group" 
			LET p_rec_kandooreport.width_num = 160 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IF8" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product  Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value      Value"
			LET p_rec_kandooreport.line2_text = "Category Year 1     Year 2     Year 3     Year 4     Year 5     Year 6     Year 7     Year 8     Year 9    Year 10    Year 11    Year 12    Year 12 >     Total"

		WHEN "IK2"
			LET p_rec_kandooreport.header_text = "IN Kit Compilation Results" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IK2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = NULL 
			LET p_rec_kandooreport.line2_text = NULL 

		WHEN "IR1"
			LET p_rec_kandooreport.header_text = "IN - Period Activity" 
			LET p_rec_kandooreport.width_num = 112 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR1" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date     Reference      Reference    Quantity          Unit         Extended          Unit        Extended"
			LET p_rec_kandooreport.line2_text = "            ID           Number                        Cost           Cost            Price         Price"

		WHEN "IR2"
			LET p_rec_kandooreport.header_text = "IN - Period Activity by Reference" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR2" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Date    Reference       Reference      Quantity        Unit         Extended           Unit       Extended       ID        Warehouse"
			LET p_rec_kandooreport.line2_text = "           ID             Number                       Cost           Cost            Price         Price"

		WHEN "IR3"
			LET p_rec_kandooreport.header_text = "IN - Serialized Items" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR3" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Serial                Vendor    Purchase  Receipt    Receipt   Client    Invoice    Ship      Credit  Reference  Ware  Status"
			LET p_rec_kandooreport.line2_text = "   Number                  ID        Order     Date      Number     ID       Number    Date      Number    Number   Code"

		WHEN "IR4"
			LET p_rec_kandooreport.header_text = "IN - Serialised Products by Serial Number" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR4" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Serial               Item            Description                          Vendor   Purchase Receipt  Client    Invoice   Ship  Stat"
			LET p_rec_kandooreport.line2_text = "Number                ID                                                    ID       Order    Date     ID       Number   Date"

		WHEN "IR5"
			LET p_rec_kandooreport.header_text = "IN - Purchasing Quotes" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR5" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "   Vendor                                                                                                                    Expiry"
			LET p_rec_kandooreport.line2_text = "Product         Description                        O.E.M. Code                   APN (Barcode)          Cost Amt   List Amt   Date"

		WHEN "IR6"
			LET p_rec_kandooreport.header_text = "IN - Purchasing Quotes" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR6" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = ""
			LET p_rec_kandooreport.line2_text = ""

		WHEN "IR7"
			LET p_rec_kandooreport.header_text = "IN - Product Return on Investment Analysis" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR7" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "ID              Description                      Average       Sales       Cost of      Gross      G.P.  Target   Actual  Return on"
			LET p_rec_kandooreport.line2_text = "                                                  Stock                     Sales       Profit      %   Stockturn        Investment"

		WHEN "IR9"
			LET p_rec_kandooreport.header_text = "IN - Snapshot Detail" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IR9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Warehouse                            Stock Qty        Valuation        Avg Value"
			LET p_rec_kandooreport.line2_text = ""

		WHEN "IRA"
			LET p_rec_kandooreport.header_text = "IN - Inventory History" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IRA" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "11Months 10Months 9 Months 8 Months 7 Months 6 Months 5 Months 4 Months  3 Months  2 Months  1 Months   Current     YTD     On Hand"
			LET p_rec_kandooreport.line2_text = "   Ago      Ago      Ago      Ago      Ago      Ago      Ago      Ago       Ago       Ago       Ago      Month     Sales      Qty"

		WHEN "IRB"
			LET p_rec_kandooreport.header_text = "IN - Serialized Items" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IRB" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "       Serial                  Purchase    Receipt     Receip   Job       Invoice    Purchase      Ship      Credit Reference Status"
			LET p_rec_kandooreport.line2_text = "       Number                    Order      Date       Number  Number      Number    Charge Amt    Date      Number    Number"

		WHEN "IS9"
			LET p_rec_kandooreport.header_text = "Vendor Price List Comparison Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IS9" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y"
			LET p_rec_kandooreport.line1_text = "                                                                                         Price           List    Last Suppl.   Curr"  
			LET p_rec_kandooreport.line2_text = "Product Code      Description                            Product Code (OEM)               UOM           Price        Cost      Code" 

		WHEN "ISL"
			LET p_rec_kandooreport.header_text = "Product Label" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ISL" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " " 
			LET p_rec_kandooreport.line2_text = " " 

		WHEN "ISM"
			LET p_rec_kandooreport.header_text = "Dispatch Label" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ISM" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " " 
			LET p_rec_kandooreport.line2_text = " "

		WHEN "ISU"
			LET p_rec_kandooreport.header_text = "Inventory Purging Report" 
			LET p_rec_kandooreport.width_num = 66 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ISU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Ware  Product                                             Deleted" 

		WHEN "ISU."
			LET p_rec_kandooreport.header_text = "Purge Exeption Report" 
			LET p_rec_kandooreport.width_num = 80 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ISU" 
			LET p_rec_kandooreport.exec_ind = "1" 
			LET p_rec_kandooreport.exec_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Product         Ware  Reason" 

		WHEN "IT2"
			LET p_rec_kandooreport.header_text = "Stocktake Count Sheet " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IT2" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = " Bin Location Item Description Count Qty Notes" 

		WHEN "IT4"
			LET p_rec_kandooreport.header_text = "Stock-take Detail Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IT4" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Warehouse Bin Location Item Description Stock Count Unit Cost Count Value" 
			LET p_rec_kandooreport.line2_text = " Report Type:" 

		WHEN "IT5"
			LET p_rec_kandooreport.header_text = "Stock-take Adjustment Report " 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IT5" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Whse Bin Location Item Description Qty Before Stock Count Adjustment Adjustment Value" 
			LET p_rec_kandooreport.line2_text = " Report Type:" 

		WHEN "IT6"
			LET p_rec_kandooreport.header_text = "Stock-take Posting Adjustments" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IT6" 
			LET p_rec_kandooreport.selection_flag = "Y" 
			LET p_rec_kandooreport.line1_text = "Warehouse Item Description Qty Before Stock Count Adjustment Adjustment Value" 
						
		WHEN "ITA"
			LET p_rec_kandooreport.header_text = "Stocktake Load Exception Report" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "ITA" 
			LET p_rec_kandooreport.selection_flag= "N" 
			LET p_rec_kandooreport.line1_text = "Date Time Comments" 

		WHEN "IU2"
			LET p_rec_kandooreport.header_text = "IN - Price Amendment Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IU2" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y"
			LET p_rec_kandooreport.line1_text = "Product         Description                    Date           Unit       Listed       Level 1      Level 2      Level 3      Level 4" 
			LET p_rec_kandooreport.line2_text = "                                               User                      Level 5      Level 6      Level 7      Level 8      Level 9" 

		WHEN "IU3"
			LET p_rec_kandooreport.header_text = "IN Cost Amendment Listing" 
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IU3" 
			LET p_rec_kandooreport.exec_ind = "1"
			LET p_rec_kandooreport.exec_flag = "Y"
			LET p_rec_kandooreport.line1_text = "                                                                                                     -------- Product Costs --------" 
			LET p_rec_kandooreport.line2_text = "Product               Description               Amended Date          User         Unit  List Price   Standard    Latest    Foreign" 
								
		WHEN "IZQc"
			LET p_rec_kandooreport.header_text = "Product Bin Update Error Report"  
			LET p_rec_kandooreport.width_num = 132 
			LET p_rec_kandooreport.length_num = 66 
			LET p_rec_kandooreport.menupath_text = "IZQc" 
			LET p_rec_kandooreport.selection_flag = "N" 
			LET p_rec_kandooreport.line1_text = "Line Number Error Text" 
			LET p_rec_kandooreport.line2_text = "Product Bin Update"

		OTHERWISE
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"

	END CASE

	RETURN p_rec_kandooreport.* 		 
END FUNCTION 