#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sat Apr 9 13:57:46 2016
#  Last Modified : <160410.1044>
#
#  Description	
#
#  Notes
#
#  History
#	
#*****************************************************************************
#
#    Copyright (C) 2016  Robert Heller D/B/A Deepwoods Software
#			51 Locke Hill Road
#			Wendell, MA 01379-9728
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# 
#
#*****************************************************************************


namespace eval stargen {
    variable RAND_MAX 32767.0
    variable PI 3.1415926536
    variable RADIANS_PER_ROTATION [expr {2.0 * $PI}]
    variable ECCENTRICITY_COEFF		0.077;#			/* Dole's was 0.077			*/
    variable PROTOPLANET_MASS		1.0E-15;#		/* Units of solar masses	*/
    variable CHANGE_IN_EARTH_ANG_VEL -1.3E-15;#		/* Units of radians/sec/year*/
    variable SOLAR_MASS_IN_GRAMS		1.989E33;#		/* Units of grams			*/
    variable SOLAR_MASS_IN_KILOGRAMS	1.989E30;#		/* Units of kg				*/
    variable EARTH_MASS_IN_GRAMS		5.977E27;#		/* Units of grams			*/
    variable EARTH_RADIUS			6.378E8;#		/* Units of cm				*/
    variable EARTH_DENSITY			5.52;#			/* Units of g/cc			*/
    variable KM_EARTH_RADIUS			6378.0;#		/* Units of km				*/
    #//      EARTH_ACCELERATION		(981.0)			/* Units of cm/sec2			*/
    variable EARTH_ACCELERATION		980.7;#			/* Units of cm/sec2			*/
    variable EARTH_AXIAL_TILT		23.4;#			/* Units of degrees			*/
    variable EARTH_EXOSPHERE_TEMP	1273.0;#		/* Units of degrees Kelvin	*/
    variable SUN_MASS_IN_EARTH_MASSES 332775.64;#
    variable ASTEROID_MASS_LIMIT		0.001;#			/* Units of Earth Masses	*/
    variable EARTH_EFFECTIVE_TEMP	250.0;#			/* Units of degrees Kelvin (was 255)	*/
    variable CLOUD_COVERAGE_FACTOR	1.839E-8;#		/* Km2/kg					*/
    variable EARTH_WATER_MASS_PER_AREA	 3.83E15;#	/* grams per square km		*/
    variable EARTH_SURF_PRES_IN_MILLIBARS 1013.25;#
    variable EARTH_SURF_PRES_IN_MMHG	760.;#			/* Dole p. 15				*/
    variable EARTH_SURF_PRES_IN_PSI	14.696;#		/* Pounds per square inch	*/
    variable MMHG_TO_MILLIBARS $EARTH_SURF_PRES_IN_MILLIBARS;#  / EARTH_SURF_PRES_IN_MMHG;#
    variable PSI_TO_MILLIBARS $EARTH_SURF_PRES_IN_MILLIBARS;# / EARTH_SURF_PRES_IN_PSI)
    variable H20_ASSUMED_PRESSURE	[expr {47. * $MMHG_TO_MILLIBARS}];# /* Dole p. 15      */
    variable MIN_O2_IPP	[expr {72. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 15				*/
    variable MAX_O2_IPP	[expr {400. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 15				*/
    variable MAX_HE_IPP	[expr {61000. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16			*/
    variable MAX_NE_IPP	[expr {3900. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_N2_IPP	[expr {2330. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_AR_IPP	[expr {1220. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_KR_IPP	[expr {350. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_XE_IPP	[expr {160. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_CO2_IPP [expr {7. * $MMHG_TO_MILLIBARS}];#	/* Dole, p. 16				*/
    variable MAX_HABITABLE_PRESSURE [expr {118 * $PSI_TO_MILLIBARS}];#	/* Dole, p. 16		*/
    # The next gases are listed as poisonous in parts per million by volume at 1 atm:
    variable PPM_PRSSURE [expr {$EARTH_SURF_PRES_IN_MILLIBARS / 1000000.}];#
    variable MAX_F_IPP	[expr {0.1 * $PPM_PRSSURE}];#			/* Dole, p. 18				*/
    variable MAX_CL_IPP	[expr {1.0 * $PPM_PRSSURE}];#			/* Dole, p. 18				*/
    variable MAX_NH3_IPP	[expr {100. * $PPM_PRSSURE}];#		/* Dole, p. 18				*/
    variable MAX_O3_IPP	[expr {0.1 * $PPM_PRSSURE}];#			/* Dole, p. 18				*/
    variable MAX_CH4_IPP	[expr {50000. * $PPM_PRSSURE}];#		/* Dole, p. 18				*/



    variable EARTH_CONVECTION_FACTOR 0.43;#			/* from Hart, eq.20			*/
    #//      FREEZING_POINT_OF_WATER (273.0)			/* Units of degrees Kelvin	*/
    variable FREEZING_POINT_OF_WATER 273.15;#		/* Units of degrees Kelvin	*/
    #//      EARTH_AVERAGE_CELSIUS   (15.5)			/* Average Earth Temperature */
    variable EARTH_AVERAGE_CELSIUS   14.0;#			/* Average Earth Temperature */
    variable EARTH_AVERAGE_KELVIN    EARTH_AVERAGE_CELSIUS + FREEZING_POINT_OF_WATER;#
    variable DAYS_IN_A_YEAR			365.256;#		/* Earth days per Earth year*/
    #//		gas_retention_threshold = 5.0;  		/* ratio of esc vel to RMS vel */
    variable GAS_RETENTION_THRESHOLD 6.0;#			/* ratio of esc vel to RMS vel */

    variable ICE_ALBEDO				0.7;#
    variable CLOUD_ALBEDO			0.52;#
    variable GAS_GIANT_ALBEDO		0.5;#			/* albedo of a gas giant	*/
    variable AIRLESS_ICE_ALBEDO		0.5;#
    variable EARTH_ALBEDO			0.3;#			/* was .33 for a while */
    variable GREENHOUSE_TRIGGER_ALBEDO 0.20;#
    variable ROCKY_ALBEDO			0.15;#
    variable ROCKY_AIRLESS_ALBEDO	0.07;#
    variable WATER_ALBEDO			0.04;#

    variable SECONDS_PER_HOUR		3600.0;#
    variable CM_PER_AU				1.495978707E13;#/* number of cm in an AU	*/
    variable CM_PER_KM				1.0E5;#			/* number of cm in a km		*/
    variable KM_PER_AU				[expr {$CM_PER_AU / $CM_PER_KM}];#
    variable CM_PER_METER			100.0;#
    #//#define MILLIBARS_PER_BAR		(1013.25)
    variable MILLIBARS_PER_BAR		1000.00;#

    variable GRAV_CONSTANT			6.672E-8;#		/* units of dyne cm2/gram2	*/
    variable MOLAR_GAS_CONST			8314.41;#		/* units: g*m2/(sec2*K*mol) */
    variable K						50.0;#			/* K = gas/dust ratio		*/
    variable B						1.2E-5;#		/* Used in Crit_mass calc	*/
    variable DUST_DENSITY_COEFF		2.0E-3;#		/* A in Dole's paper		*/
    variable ALPHA					5.0;#			/* Used in density calcs	*/
    variable N						3.0;#			/* Used in density calcs	*/
    variable J						1.46E-19;#		/* Used in day-length calcs (cm2/sec2 g) */
    variable INCREDIBLY_LARGE_NUMBER 9.9999E37;#

    #/*	Now for a few molecular weights (used for RMS velocity calcs):	   */
    #/*	This table is from Dole's book "Habitable Planets for Man", p. 38  */

    variable ATOMIC_HYDROGEN			1.0;#	/* H   */
    variable MOL_HYDROGEN			2.0;#	/* H2  */
    variable HELIUM					4.0;#	/* He  */
    variable ATOMIC_NITROGEN			14.0;#	/* N   */
    variable ATOMIC_OXYGEN			16.0;#	/* O   */
    variable METHANE					16.0;#	/* CH4 */
    variable AMMONIA					17.0;#	/* NH3 */
    variable WATER_VAPOR				18.0;#	/* H2O */
    variable NEON					20.2;#	/* Ne  */
    variable MOL_NITROGEN			28.0;#	/* N2  */
    variable CARBON_MONOXIDE			28.0;#	/* CO  */
    variable NITRIC_OXIDE			30.0;#	/* NO  */
    variable MOL_OXYGEN				32.0;#	/* O2  */
    variable HYDROGEN_SULPHIDE		34.1;#	/* H2S */
    variable ARGON					39.9;#	/* Ar  */
    variable CARBON_DIOXIDE			44.0;#	/* CO2 */
    variable NITROUS_OXIDE			44.0;#	/* N2O */
    variable NITROGEN_DIOXIDE		46.0;#	/* NO2 */
    variable OZONE					48.0;#	/* O3  */
    variable SULPH_DIOXIDE			64.1;#	/* SO2 */
    variable SULPH_TRIOXIDE			80.1;#	/* SO3 */
    variable KRYPTON					83.8;#	/* Kr  */
    variable XENON					131.3;# /* Xe  */

    #//	And atomic numbers, for use in ChemTable indexes
    variable AN_H	1
    variable AN_HE	2
    variable AN_N	7
    variable AN_O	8
    variable AN_F	9
    variable AN_NE	10
    variable AN_P	15
    variable AN_CL	17
    variable AN_AR	18
    variable AN_BR	35
    variable AN_KR	36
    variable AN_I	53
    variable AN_XE	54
    variable AN_HG	80
    variable AN_AT	85
    variable AN_RN	86
    variable AN_FR	87

    variable AN_NH3	900
    variable AN_H2O	901
    variable AN_CO2	902
    variable AN_O3	903
    variable AN_CH4	904
    variable AN_CH3CH2OH	905

    #/*	The following defines are used in the kothari_radius function in	*/
    #/*	file enviro.c.														*/
    variable A1_20					6.485E12;#		/* All units are in cgs system.	 */
    variable A2_20					4.0032E-8;#		/*	 ie: cm, g, dynes, etc.		 */
    variable BETA_20					5.71E12;#

    variable JIMS_FUDGE				1.004;#

    #/*	 The following defines are used in determining the fraction of a planet	 */
    #/*	covered with clouds in function cloud_fraction in file enviro.c.		 */
    variable Q1_36					1.258E19;#		/* grams	*/
    variable Q2_36					0.0698;#		/* 1/Kelvin */
    
}

namespace eval ::tcl::mathfunc {
    
    #/* macros: */
    #define pow2(a) ((a) * (a))
    proc pow2 {a} {
        return [::tcl::mathop::* $a $a]
    }
    #define pow3(a) ((a) * (a) * (a))
    proc pow3 {a} {
        return [::tcl::mathop::* $a $a $a]
    }
    #define pow4(a) ((a) * (a) * (a) * (a))
    proc pow4 {a} {
        return [::tcl::mathop::* $a $a $a $a]
    }
    #define pow1_4(a)		sqrt(sqrt(a))
    proc pow1_4 {a} {
        return [sqrt [sqrt $a]]
    }
    #define pow1_3(a)		pow(a,(1.0/3.0))
    proc pow1_3 {a} {
        return [pow $a [::tcl::mathop::/ 1.0 3.0]]
    }
}


    
