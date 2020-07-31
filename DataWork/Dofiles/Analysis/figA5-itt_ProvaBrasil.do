
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Back-of-the-envelope for Prova Brasil				   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Estimate treatment effects
						Plot back-of-the-envelope graph
	
	** REQUIRES:   		"${master_dt_fin}/Brazil_ProvaBrasil.dta"
						"${master_dt_fin}/scores_rescaled_PB.dta"
						
	** CREATES:	   		Figure A5: Learning Gains in 6th Grade Rescaled to Prova Brasil - Projection over Time
						(a) Math
						"${master_fig}/figA5a-itt_ProvaBrasil_MT.png"
						(b) Portuguese
						"${master_fig}/figA5b-itt_ProvaBrasil_LT.png"
				
* ---------------------------------------------------------------------------- *
*								Prepare data					   			   *
* ---------------------------------------------------------------------------- */

	use 	 "${master_dt_fin}/Brazil_ProvaBrasil.dta", clear
	
	replace  LT_5 = . if year == 2017
	replace  MT_5 = . if year == 2017
	 
	replace  LT_9 = . if year == 2013
	replace  MT_9 = . if year == 2013
	
	collapse *_5 *_9, by(region)
	
	foreach  subject in LT MT {
	
		gen `subject'_7 = (`subject'_5 + `subject'_9) / 2
		gen	`subject'_6 = (`subject'_5 + `subject'_7) / 2
		gen	`subject'_8 = (`subject'_9 + `subject'_7) / 2
	}	
	
	set obs `=_N+1'
	replace region = "PIP - OLS"  in `=_N'
		
* ---------------------------------------------------------------------------- *
*						Estimate TE in Prova Brasil points		   			   *
* ---------------------------------------------------------------------------- *
	
	preserve
	
		use "${master_dt_fin}/scores_rescaled_ProvaBrasil.dta", clear
		
		* OLS estimation
		foreach  subject 		in MT LT {
		
			reghdfe proficiencia_`subject'_rescaled school_treated	///
				 if grade == 6 & grade_treated == 6 				/// 
				  , abs(strata) cl(inep)
					
			matrix results = r(table)
			
			scalar TE_`subject'_OLS = results[1,1]
			scalar SE_`subject'_OLS = results[2,1]
			scalar  p_`subject'_OLS = results[4,1]	
		}
	
	restore
	
	* List scalar
	scalar list
	
	* Estimate trajectories
	foreach  subject 		in MT LT {
		forv year	  = 6/9	  {
			replace MT_`year' = MT_`year'[2] + TE_`subject'_OLS in `=_N'
			replace LT_`year' = LT_`year'[2] + TE_`subject'_OLS in `=_N'
		}
	}
	
	* ------- *
	* Reshape *
	* ------- *
	reshape long LT_@ MT_@, i(region) j(year)
	rename		 LT_  LT
	rename		 MT_  MT
		
* ---------------------------------------------------------------------------- *
*								Plot line graph	   			   				   *
* ---------------------------------------------------------------------------- *

	local figCount  = 1	
	
	foreach subject in MT LT {
		
		
		if "`subject'" == "MT" local showLegend `"legend(off)"' //pos(5) ring(0) 
		if "`subject'" == "LT" local showLegend `"legend(lab(1 "Brazil") lab(2 "RN") lab(3 "PIP ITT effect") row(1) )"'
		
		if "`subject'" == "MT" local textPos 	  "202.5 5.52"
		if "`subject'" == "LT" local textPos 	  "193.5 5.52"
		
		if "`subject'" == "MT" local marginSize   "b+4 	  t+4    l+1 	r+1"
		if "`subject'" == "LT" local marginSize   "b+2.25 t+2.25 l+1.25 r+1.25"
		
		local TE_OLS   = string(TE_`subject'_OLS, "%9.2f")
		local SE_OLS   = string(SE_`subject'_OLS, "%9.2f")

		local p_OLS    	 ""
		
		foreach ttest_p_level in 0.1 0.05 0.01 {
			if p_`subject'_OLS < `ttest_p_level' local p_OLS "`p_OLS'*"
		}
		
		#d	;
		
			line `subject' year if region == "Brazil"  			  , color(gs6)	   ||
			line `subject' year if region == "Rio Grande do Norte", color(navy)    ||
			line `subject' year if region == "PIP - OLS"		  ,		  
								   lpattern(dash)
								   lwidth(medthick)					color(ebblue)  ||
				,			
					`showLegend'
					
					 xtitle(Grade)
					 ytitle("")
					 
					 xlab(5 "5th"
						  6 "6th"
						  7 "7th"
						  8 "8th"
						  9 "9th")
					 ylab(,  nogrid)
				   /*xline(6, lcolor(maroon))*/
				     					 
					 text(`textPos' "{&beta}{subscript:ITT}: `TE_OLS'(`SE_OLS')`p_OLS'",
						  orient(horizontal) size(medsmall) justification(center)
								fcolor(white) margin(`marginSize')
								box 
						 )
						 
					 ${graphOptions}
					 xscale(nofextend titlegap(2)) 
					 yscale(nofextend)
			;
		#d	cr
		
		local figLetter = word("`c(alpha)'", `figCount')
		
		gr 	  export 	  "${master_fig}/figA5`figLetter'-itt_ProvaBrasil_`subject'.png", ///
			  width(5000) as(png) replace
		
		local figCount  = `figCount' + 1
	}
	

******************************** End of do-file ********************************
