
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Plot grant allocation								   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Plot graph
							
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Figure 3: Allocation of Resources by Type of Grant
						"${master_fig}/fig3-grant.png"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- */
	
	* Load master data at the school level
	use "${master_dt_fin}/master_schoollevel.dta"   	, clear
	
	* Transform variable in thousands of Reais
	gen school_resource_k   = 		 school_resource 	/ 1000
	gen school_resource_str = string(school_resource_k) + "k"  if !mi(school_resource_k)
	
	* Plot graph
	#d	;
		gr bar, over(school_resource_str)
			    ytitle(Percentage of schools)
				
				blab(bar, format(%9.2f) size(medsmall))
					 bar(1, color(${treatmentColor}%75))
				
				ylab(0(10)30) yscale(range(0(10)35))
				
				text(28 82.5 " {bf:Assignment rule}: " 
						     "1 class       | R$ 30k"
						     "2 classes   | R$ 36k"
						     "3 classes   | R$ 39k"
						     "4 classes   | R$ 42k"
						     "5+ classes | R$ 45k" ,
					orient(horizontal)  size(medsmall)
					justification(left) linegap(1.2)
					fcolor(white) margin(b+2 t+2 l+2 r+2)
					box
					)
				
					${graphOptions}
		;
	#d	cr
	
	gr  export  "${master_fig}/fig3-grant.png", replace as(png) width(5000)
	

******************************** End of do-file ********************************
