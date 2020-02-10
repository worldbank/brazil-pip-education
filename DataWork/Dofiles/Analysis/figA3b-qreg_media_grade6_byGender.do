
/*******************************************************************************
*						PIP								   					   *
*																 			   *
*  PURPOSE:  			Quantile treatment effect by gender			   		   *
*  WRITTEN BY:  		Matteo Ruzzante [mruzzante@worldbank.org]		   	   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:			Figure A3: Impact on Average Test Score by Gender in 6th Grade
						(b) Quantile Treatment Effect 
						"${master_fig}/figA3b-qreg_media_grade6_byGender.png"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- */			
	
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
	
	est clear
	
	local quantileLabels = ""
	local quantileCount  = 0.5 //manually adapt position in the graph
		
	local modelsList	 = ""
		
	forv  quantile   	 = `quantileInterval'(`quantileInterval')`=1-`quantileInterval'' {
			
		local 	 roundQuantile   =  round(real(string(`quantile'*100, "%4.0f")),10)/100
		local 	 integerQuantile = `roundQuantile'*100
			
		* Loop on gender dummy
		forv 	 genderId   = 0/1 {
		
			* Set color and estimate suffix depending on gender	
			if  `genderId' == 0 {
				 local gender 	   	"F"
				 local lineColor   	"`red'"
				 local markerSymbol	circle
			}
			if  `genderId' == 1 {
				 local gender 	   	"M"
				 local lineColor   	"`blue'"
				 local markerSymbol	diamond
			}
			
			eststo `subject'_grade6_q`integerQuantile'_`gender':	///
					qreg2 prof_media school_treated strata*			///
					if grade == 6 & student_gender == `genderId'	///
					, q(`roundQuantile') cl(inep)
			
			local 	modelsList	   `"`modelsList' (`subject'_grade6_q`integerQuantile'_`gender', ciopts(recast(rcap) lcolor("`lineColor'")) mcolor("`lineColor'") msymbol(`markerSymbol') ) "'
		}
		
		local 		quantileCount  =  0.1 + 		  `quantileCount'
		local 		quantileLabels `"`quantileLabels' `quantileCount' "Q{sub:`integerQuantile'}""'
		
	}
			
	#d	;
		coefplot `modelsList',			
			vertical keep(*school_treated*) bycoefs
			mlabel mlabcolor(black) format(%9.2g)
			levels(`statSignLevel')
			xlab(none) xlabel(`quantileLabels', add)
			legend(order(2 4) lab(2 "Female") lab(4 "Male"))
			ytitle("Standard deviations") yline(0, lstyle(foreground))
			${graphOptions}
			xscale(nofextend) 
			yscale(nofextend)
		;
	#d	cr
	
	gr export "${master_fig}/figA3b-qreg_media_grade6_byGender.png", replace as(png) width(5000)
		

******************************** End of do-file ********************************
