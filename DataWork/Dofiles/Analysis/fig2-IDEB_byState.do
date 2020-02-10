
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Compare IDEB in Brazilian states					   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Plot graph
							
	** REQUIRES:   		"${master_dt_fin}/Brazil_IDEB.dta"
						
	** CREATES:	   		Figure 2: IDEB in Rio Grande do Norte vs. Other Brazilian states
						"${master_fig}/fig2-IDEB_byState.png"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- */
	
	* Load data
	use 	  "${master_dt_fin}/Brazil_IDEB.dta", clear
	
	* Generate variable for position
	sort	  ideb_2015 stateInitials
	
	* Store state labels for x-axis
	local 	  xlabArgument ""
	forv 	  labPosition  = 1/`=_N' {
	
		local stateString  = stateInitials[`labPosition']
		di 	"`stateString'"
		local xlabArgument `" `xlabArgument' `labPosition' "`stateString'" "'
	}
	di 	   `"`xlabArgument'"'
	
	gen 	 barPosition   = _n
	gen 	 bar_position  = ideb_2015	if state == "Rio Grande do Norte"
	
	* Overlay Brazilian states averages highlighting RN
	#d	;
		two (bar ideb_2015 barPosition  if state == "Rio Grande do Norte", color(maroon%80))
			(bar ideb_2015 barPosition  if state != "Rio Grande do Norte", color(navy%80))
	
			,
			
			${graphOptions}
			
			yscale(nofextend range(0  5))
			xscale(nofextend titlegap(2)) 
			
			ytitle("")
			xtitle("")
			   
			ylab(0/5)
			xlab(`xlabArgument', alt)
  			   
			legend(order(1 "{bf:Rio Grande do Norte}"
						   2 "Other Brazilian states"))
		  ;
	#d	cr
	
	gr export "${master_fig}/fig2-IDEB_byState.png", as(png) replace width(5000)
	
	
******************************** End of do-file ********************************
