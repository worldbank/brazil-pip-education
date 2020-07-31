
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Compare retention and dropout across grades			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Plot graphs
							
	** REQUIRES:   		"${master_dt_fin}/Brazil_rates.dta"
						
	** CREATES:	   		Figure 1: Grade Repetition and School Dropout Rates by Grade in Rio Grande do Norte
						
						(a) Grade Repetition Rate
						"${master_fig}/fig1a-grade_comparison_retention.png"
						
						(b) School Dropout Rate
						"${master_fig}/fig1b-grade_comparison_dropout.png"
	
* ---------------------------------------------------------------------------- */
	
	* Load clean data
	use 	  "${master_dt_fin}/Brazil_rates.dta", clear
		
	* Keep RN - public
	tab 	   state
	keep if    state	  == "Rio Grande do Norte"
	
	tab		   type
	keep if	   type		  == "Total"
	
	tab		   dependence
	keep if    dependence == "Pública"
	
	gen		   retention_ef55 = .
	gen		   retention_ef95 = .
	
	order	   retention_ef55, after(retention_ef5)
	order	   retention_ef95, after(retention_ef9)
	
	#d	;
		gr bar retention_ef1-retention_em3,
			   
			   ${graphOptions} 
				
			   asyvars bargap(50)
			   
			   yvaroptions(relab( 1 "1"  	   2  "2"  3  "3"  4 "4"  5 "{bf:5}" 6 "-"
								  7 "{bf:6}"   8  "7"  9  "8" 10 "9" 11 "-"
								 12 "{bf:10}" 13 "11" 14 "12"))
			   
			   ytitle(%, orientation(horizontal))
			   
			   showyvars
			   
			   blab(bar, format(%9.2f))
			   
			   bar( 1, bcolor(navy*.5))
			   bar( 2, bcolor(navy*.5))
			   bar( 3, bcolor(navy*.5))
			   bar( 4, bcolor(navy*.5))
			   bar( 5, bcolor(navy))
			   bar( 7, bcolor(navy))
			   bar( 8, bcolor(navy*.5))
			   bar( 9, bcolor(navy*.5))
			   bar(10, bcolor(navy*.5))
			   bar(12, bcolor(navy))
			   bar(13, bcolor(navy*.5))
			   bar(14, bcolor(navy*.5))
			  
			   legend(off)
			   
			   text(29 16 "{it:Primary schools}",
					orient(horizontal)
					size(medium)
					justification(center)
					fcolor(white)
					)
					
			   text(35.5 56 "{it:Lower secondary schools}",
					orient(horizontal)
					size(medium)
					justification(center)
					fcolor(white)
					)
					
			   text(26.5 90 "{it:Upper secondary}" "{it:schools}",
					orient(horizontal)
					size(medium)
					justification(center)
					fcolor(white)
					)
					
			   graphregion(margin(t+7))
		;
	#d	cr
	
	gr  export "${master_fig}/fig1a-grade_comparison_retention.png", replace as(png) width(5000)
	
	gen		   dropout_ef55 = .
	gen		   dropout_ef95 = .
	
	order	   dropout_ef55, after(dropout_ef5)
	order	   dropout_ef95, after(dropout_ef9)
	
	#d	;
		gr bar dropout_ef1-dropout_em3,
			   
			   ${graphOptions} 

			   asyvars bargap(50)
			   
			   yvaroptions(relab( 1 "1"  	   2  "2"  3  "3"  4 "4"  5 "{bf:5}" 6 "-"
								  7 "{bf:6}"   8  "7"  9  "8" 10 "9" 11 "-"
								 12 "{bf:10}" 13 "11" 14 "12"))
			   
			   ytitle(%, orientation(horizontal))
			   
			   showyvars
			   
			   blab(bar, format(%9.2f))
			   
			   bar( 1, bcolor(navy*.5))
			   bar( 2, bcolor(navy*.5))
			   bar( 3, bcolor(navy*.5))
			   bar( 4, bcolor(navy*.5))
			   bar( 5, bcolor(navy))
			   bar( 7, bcolor(navy))
			   bar( 8, bcolor(navy*.5))
			   bar( 9, bcolor(navy*.5))
			   bar(10, bcolor(navy*.5))
			   bar(12, bcolor(navy))
			   bar(13, bcolor(navy*.5))
			   bar(14, bcolor(navy*.5))
			   
			   legend(order(7 "{bf:PIP grades}"
							8 "Other grades"))
		;
	#d	cr
	
	gr  export  "${master_fig}/fig1b-grade_comparison_dropout.png", replace as(png) width(5000)
	
	
******************************** End of do-file ********************************
