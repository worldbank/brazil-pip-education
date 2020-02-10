	
/*******************************************************************************
*  Project:				PIP													   *
*																 			   *
*  PURPOSE:  			Estimate quantile treatment effect in 6th grade	   	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										   	   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:			Figure C1: Impact on Average Test Score by Gender in 6th Grade
						(a) "${master_fig}/figC1a-qreg_MT_grade6.png"
						(b) "${master_fig}/figC1b-qreg_LT_grade6.png"
						(c) "${master_fig}/figC1c-qreg_CH_grade6.png"
						(d) "${master_fig}/figC1d-qreg_CN_grade6.png"
			
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
		
	local 			   figCount			= 1	
		
	* Loop on different subjects
	foreach subject in MT LT CH CN {
		
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
			eststo `subject'_grade6_q`integerQuantile': 			///
					qreg2 prof_`subject' school_treated strata_*	///
					if grade == 6 ,									///
					q(`roundQuantile') cl(inep)
			
			* Add these estimate to locals
			local 	quantileLabels `"`quantileLabels' `quantileCount++' "Q{sub:`integerQuantile'}""'
			local 	modelsList 	   `"`modelsList' 				`subject'_grade6_q`integerQuantile' || "'
		}
		
		* Plot coefficients 
		#d	;
			coefplot `modelsList',					
				vertical keep(*school_treated*) bycoefs
				mlab format(%9.2g) msymbol(diamond)
				mcolor(ebblue) mlabcolor(black)
				ciopts(recast(rcap) lcolor(ebblue)) levels(`statSignLevel')
				xlab(none) xlabe(`quantileLabels', add)
				ytitle("Standard deviations") yline(0, lstyle(foreground))
				legend(off)
				${graphOptions}
				xscale(nofextend) 
			    yscale(nofextend)
			;
		#d	cr
		
		local   figLetter =  word("`c(alpha)'", `figCount')
		 
		* Store graph in PNG format
		gr 		export 		"${master_fig}/figC1`figLetter'-qreg_`subject'_grade6.png", replace as(png) width(5000)
		
		local	figCount  = `figCount' + 1
	}

	
******************************** End of do-file ********************************
