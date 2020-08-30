
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Compare implementation degree by grade				   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************

	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Figure 2: Implementation by Grade
						"${master_fig}/fig2-implementation_byGrade.png"

* ---------------------------------------------------------------------------- */

	* Load master data at the school level
	use 					 "${master_dt_fin}/master_schoollevel.dta", clear 

	* Summarize var by grade
	sum 	 school_implementation 		     , d
	local    obs	   		   			     = r(N)
	//the median is actually equal to one!
	
	sum		 school_implementation if grade == 5, d
	sum		 school_implementation if grade == 6, d
	sum		 school_implementation if grade == 1, d
		
	* Generate variable in percentage
	gen		 school_implementation70		 = school_implementation		 > 0.70 if !mi(school_implementation)
	gen	     school_implementation_pct 		 = school_implementation70 		 * 100
	sum		 school_implementation_pct		 , d
	
	* Turn school certificate into percentage
	gen		 school_clearance_pct 			 = school_clearance_certificate  * 100
	
	* % of budget received by December
	gen		 school_execution_december_pct	 = school_pct_execution_december * 100	
	
	* Check differences across grades
	tab  	 polo	, gen(polo_  )
	
	orth_out school_implementation_pct , by(grade) se pcompare covariates(polo_*)
	
	reghdfe  school_implementation_pct 6.grade if inlist(grade, 5, 6), vce(rob) abs(polo)
	
	matrix   results = r(table)
	
	scalar   diff5   = results[1,1]
	scalar   se5     = results[2,1]
	scalar   p5      = results[4,1]	
	
	local    diff5   = string(diff5 , "%9.2f")
	local    se5     = string(se5   , "%9.2f")
	local    p5      = string(p5    , "%9.3f")
	
	reg		 school_implementation_pct 6.grade if inlist(grade, 6, 1), vce(rob) abs(polo)
	
	matrix   results = r(table)
	
	scalar   diff10  = results[1,1]
	scalar   se10    = results[2,1]
	scalar   p10     = results[4,1]
	
	local    diff10  = string(diff10, "%9.2f")
	local    se10    = string(se10  , "%9.2f")
	local    p10     = string(p10   , "%9.3f")
	
	* Reshape 
	keep if school_treated == 1
	reshape wide *_pct 				 , i(inep) j(grade)
	reshape long @_pct5 @_pct6 @_pct1, i(inep) j(varname) string
	
	* Generate grade string variable for labels
	gen		order 	 = 1 	  if varname == "school_clearance"
	replace order 	 = 2 	  if varname == "school_execution_december"
	replace order 	 = 3 	  if varname == "school_implementation"
	
	* Plot graphs and export
	#d	;
	
		// Implementation by grade
		gr bar  _pct5 _pct6 _pct1
				if school_treated == 1,
				
				over(varname, sort(order) relab(1 `" "Schools with" "clearance" "certificate" "' 
												2 `" "Budget" 		"received"  "by December" "'
												3 `" "Schools with" "implementation" "> 70%"  "') )
				blab(bar, format(%9.2f) size(medsmall))
				ytitle("%", orientation(horizontal))
				
				bar(1, color(eltblue*0.45))
				bar(2, color(eltblue*0.8))
				bar(3, color(eltblue*1.25))
				
				${graphOptions}
				graphregion(margin(t+16))
				
			    yscale(range(0(20)100) nofextend titlegap(-1))
				ylab(0(20)100)
				
				legend(order(0 "Grade:"
							 1 "5th"
							 2 "6th"
							 3 "10th")
					   size(3.5) row(1))		
					   
				text(122 50    "{bf:Implementation comparisons by grade (t-test)}"
							   "6th — 5th   = `diff5'.   p = `p5'"
							   "6th — 10th = `diff10'. p = `p10'"
							   ,
								justification(left) linegap(1.5)
								fcolor(white) margin(b+2 t+2 l+1.5 r+1)
								box
					)
		;
	#d	cr
	
	gr  export "${master_fig}/fig2-implementation_byGrade.png", replace as(png) width(5000)
	
	
******************************** End of do-file ********************************
