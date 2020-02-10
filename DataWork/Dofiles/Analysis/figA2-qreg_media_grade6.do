
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate quantile treatment effect in 6th grade		   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		"${master_fig}/figA2-qreg_media_grade6.png"
			
	** NOTES:

* --------------------------------------------------------------------------- */
			
	* Load master data at the student level
	use 	      "${master_dt_fin}/master_studentlevel", clear
						
	* Generate dummies for strata (factor variables do not work with 'qreg2')
	tab  polo	, gen(polo_  )
	tab  strata , gen(strata_)

	sum  polo*		  strata*
	
	* Define regression options
	local 	      	   quantileInterval = 0.1
	local 			   statSignLevel 	= 90
	
	* Color palette
	local 	blue			"27 159 171"	// for girls
	local	red 			"242 94 54"		//for boys
	//from Financial Times newsroom
	
	* Initiate locals
	* (to be filled in the next loop)
	local quantileLabels = ""		//x-axis label
	local modelsList 	 = ""		//estimates name
	local quantileCount  = 1		//count of quantile regression
		
	* Loop on quantiles
	forv quantile   = `quantileInterval'(`quantileInterval')`=1-`quantileInterval'' {
			
		local 	roundQuantile   =  round(real(string(`quantile'*100, "%4.0f")),10)/100 //this is needed, otherwise Stata gives issue with the last numbers of the sequence and with rounding
		local 	integerQuantile = `roundQuantile'*100
		
		* Store estimates from quantile regression with fixed effects and clustered standard errors
		eststo `subject'_all_q`integerQuantile': 			///
				qreg2 prof_media school_treated strata_*	///
				if grade == 6,								///
				q(`roundQuantile') cl(inep)
		
		* Add these estimate to locals
		local 	quantileLabels `"`quantileLabels' `quantileCount++' "Q{sub:`integerQuantile'}""'
		local 	modelsList 	   `"`modelsList' 				`subject'_all_q`integerQuantile' || "'
	}
		
	* Plot coefficients 
	#d	;
		coefplot `modelsList',					
			vertical keep(*school_treated*) bycoefs
			mlab format(%9.2g) msymbol(diamond)
			mcolor(ebblue) mlabcolor(black)
			ciopts(recast(rcap) lcolor(ebblue)) levels(`statSignLevel')
			xlab(none) xlab(`quantileLabels', add)
			ytitle("Standard deviations") yline(0, lstyle(foreground))
			legend(off)
			${graphOptions}
			xscale(nofextend) 
			yscale(nofextend)
		;
	#d	cr
		
	* Store graph in PNG format
	gr export "${master_fig}/figA2-qreg_media_grade6.png", replace as(png) width(5000)
	

******************************** End of do-file ********************************
	