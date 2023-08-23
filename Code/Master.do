						*** Master.do ***
 
*Authors: Ricardo Duque Gabriel, Mathias Klein, and Ana Sofia Pessoa
*Start Date: 04/12/2020
*Last Update: 08/10/2023
*Recommended Stata version: 15
*Estimated running time: ~10 minutes

clear all
set more off
set matsize 11000

graph set window fontface  "Linux Libertine O"     // set default font (window)
graph set window fontfacesans  "Linux Libertine O"  // set default sans font (window)
graph set window fontfaceserif "Linux Libertine O"    // set default serif font (window)
graph set window fontfacemono "Linux Libertine O"    // set default mono font (window)
set varabbrev off

*Call paths file
do Paths

*Choose Nuts level to perform the analysis on
global nu = 2

*Choose main instrument (Alesina4) - alternative instruments are (IMF, Alesina5, Alesina4_unpredict for Rob Table C3)
global inst Alesina4

*Clean data and produce key datasets
do Preamble

********************************************************************************
* Producing Figures
********************************************************************************

*Figure 1
do Fig1

*Figure 2
do Fig2

*Figure 3
do Fig3

*Figure 4 (and Figure 6d)
do Fig4	

*Figure 5 	
do Fig5

*Figure 6
do Fig6

*Figure 7
do Fig7
	
*Figure 8
do Fig8

*Figure A1 (and Table A6)
do FigA1

*Figure C1
do FigC1

*Figure C2
do FigC2

*Figure D1
do FigD1

********************************************************************************
* Producing Tables
********************************************************************************


*Table 1
do Tab1
	
*Table 2 (and Figure B2 on Tab2_4.do)
do Tab2
	/*
*Table A3
do TabA3

*Table A4
do TabA4

*Table A5
do TabA5

*Table C1 and Table C2
do TabC1C2

* Table C3
do TabC3

* Table C4
do TabC4

* Table C5
do TabC5
