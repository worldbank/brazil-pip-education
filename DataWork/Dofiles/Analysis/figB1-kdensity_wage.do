	
/*******************************************************************************
*  Project:				PIP													   *
*																 			   *
*  PURPOSE:  			Estimate returns to PIP						   	   	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019										   	   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/RN_salaries_2016.dta"
	
	** CREATES:	   		Figure B1: Learning Gains in 6th Grade Rescaled to Annual Wage
						"${master_fig}/figB1-kdensity_wage.png"
						
	** NOTES:

* ---------------------------------------------------------------------------- */
		
	* Load clean data
	use    "${master_dt_fin}/RN_salaries_2016.dta"    , clear
	
	* Compute NPV of the intervention
	sum    monthly_wage  	 	 if monthly_wage  > 0 , d
	
	scalar average_wage       	  = r(mean) * 12
	
	scalar return_to_education 	  = 0.10
	
	scalar age_intervention		  = 20
	scalar age_enter_labor_market = 20
	scalar expected_work_life 	  = 40
	scalar discount_rate 	  	  = 0.03
	
	scalar USD_to_Reais			  = 4
	
	scalar effect_lowerBound 	  = 0.5
	scalar effect_repetition 	  = 0.4
	scalar effect_upperBound  	  = 0.9
		
	foreach method in lowerBound repetition upperBound {
		
		scalar extra_income_`method'  = effect_`method' * return_to_education
		di     extra_income_`method'
		
		scalar NPV_Reais_`method'	  = 0
		
		forv   yearAfterIntervention  = 1 / `=expected_work_life' 	  		   	   {
					
			scalar NPV_Reais_`method' = 										     ///
				   NPV_Reais_`method' + (extra_income_`method'  * average_wage)    / ///
										(1 + discount_rate)			  		       ^ ///
										(age_enter_labor_market - age_intervention + `yearAfterIntervention' - 1)
			
			di "After `yearAfterIntervention' year(s): `=NPV_Reais_`method''"				   				   
		}
		
		di 						  "`method' estimates:"
		di	   NPV_Reais_`method' " Reais"
	
		scalar NPV_USD_`method' = NPV_Reais_`method' / USD_to_Reais
		di	   NPV_USD_`method'   " USD"
		
		di 						  " "
	}
	
	gen		 annual_wage   		 = monthly_wage * 12 if monthly_wage > 0
	
	sum		 annual_wage         ,  d
	scalar	 median_wage         = `r(p50)'
	scalar   PIP_wage_lowerBound = median_wage  * (1 + extra_income_lowerBound )
	scalar   PIP_wage_upperBound = median_wage  * (1 + extra_income_upperBound )
	
	di		 PIP_wage_lowerBound
	di		 PIP_wage_upperBound
	
	xtile 	 annual_wage_deciles = annual_wage		    , nq(10)
	sum 	 annual_wage 		if annual_wage_deciles == 7
	sum 	 annual_wage 		if annual_wage_deciles == 7
	
	sum		 annual_wage 		 , d
	#d	;
		tw (kdensity annual_wage if annual_wage < `r(p90)' , lcolor(navy))
		   (function x = 0, lcolor(navy) )
		   (function x = 0, lcolor(ebblue)  lpattern(dash) 	 	lwidth(medthick) )
		   (function x = 0, lcolor(midblue) lpattern(shortdash) lwidth(medthick) )
		   (function x = 0, color(white) )
		   ,
									  
		   		 xline(`=median_wage'  		  , lcolor(navy) 	 									 )
				 xline(`=PIP_wage_lowerBound' , lcolor(ebblue)  lpattern(dash)      lwidth(medthick) )
				 xline(`=PIP_wage_upperBound' , lcolor(midblue) lpattern(shortdash) lwidth(medthick) )

				 ytitle(Kernel density estimate)
				 xtitle(Annual wage (in Reais))
				 
				 yscale(noextend			)
				 xscale(noextend titlegap(2))
				 
				 legend(order(2 "RN" 3 "PIP ITT" "lower bound" 4 "PIP ITT" "upper bound") rows(1))
				 
				 ${graphOptions}	 
		;
	#d	cr
	
	gr export "${master_fig}/figB1-kdensity_wage.png", as(png) replace width(5000)

	
******************************** End of do-file ********************************
