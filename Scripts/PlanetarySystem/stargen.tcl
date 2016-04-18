#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sat Apr 9 13:53:21 2016
#  Last Modified : <160411.1458>
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


package require snit

source [file join [file dirname [info script]] const.tcl]
source [file join [file dirname [info script]] structs.tcl]
source [file join [file dirname [info script]] utils.tcl]
source [file join [file dirname [info script]] accrete.tcl]
source [file join [file dirname [info script]] enviro.tcl]

namespace eval stargen {
       
    variable fUseSolarsystem		0x0001
    variable fReuseSolarsystem		0x0002
    variable fUseKnownPlanets		0x0004
    variable fNoGenerate		0x0008
    variable fDoGases			0x0010
    variable fDoMoons			0x0020
    
    variable fOnlyHabitable		0x0100
    variable fOnlyMultiHabitable	0x0200
    variable fOnlyJovianHabitable	0x0400
    variable fOnlyEarthlike		0x0800
    
    variable stargen_revision {$Revision$ (Tcl version Based on C version 1.43)}
    
    namespace export fUseSolarsystem fReuseSolarsystem fUseKnownPlanets \
          fNoGenerate fDoGases fDoMoons fOnlyHabitable fOnlyMultiHabitable \
          fOnlyJovianHabitable fOnlyEarthlike stargen_revision
    
    proc diminishing_abundance {xp yp} {
        set xx [expr {[$xp cget -abunds] * [$xp cget -abunde]}]
        set yy [expr {[$yp cget -abunds] * [$yp cget -abunde]}]
        if {$xx < $yy} {
            return 1
        } elseif {$xx > $yy} {
            return -1
        } else {
            return 0
        }
    }
    proc diminishing_pressure {xp yp} {
        if {[$xp cget -surf_pressure] < [$yp cget -surf_pressure]} {
            return 1
        } elseif {[$xp cget -surf_pressure] > [$yp cget -surf_pressure]} {
            return -1
        } else {
            return 0
        }
    }
    
    proc EM {x} {
        return [expr {$x / $::stargen::SUN_MASS_IN_EARTH_MASSES}]
    }
    proc AVE {x y} {
        return [expr {double($x + $y) / 2.0}]
    }
    namespace export EM AVE
    
    #planets luna     ={1,2.571e-3,0.055,1.53, EM(.01229), FALSE, EM(.01229), 0, ZEROES,0,NULL, NULL};
    Planets_Record luna -planet_no 1 -a 2.571e-3 -e 0.055 -axial_tilt 1.53 \
          -mass [EM .01229] -gas_giant no -dust_mass [EM .01229] -gas_mass 0 \
          -minor_moons 0 -moons {}
    #puts stderr "luna: [luna configure]"
    #planets callisto ={4,1.259e-2,0    ,0   , EM(1.62e-2),FALSE,EM(1.62-2 ), 0, ZEROES,0,NULL, NULL};
    Planets_Record callisto -planet_no 4 -a 1.259e-2 -e 0 -axial_tilt 0 \
          -mass [EM 1.62e-2] -gas_giant no -dust_mass [EM 1.62e-2] -gas_mass 0 \
          -minor_moons 0 -moons {}
    #puts stderr "callisto: [callisto configure]"
    #planets ganymede ={3,7.16e-3,0.0796,0   , EM(2.6e-2 ),FALSE,EM(2.6e-2 ), 0, ZEROES,0,NULL, &callisto};
    Planets_Record ganymede -planet_no 3 -a 7.16e-3 -e 0.0796 -axial_tilt 0   \
          -mass [EM 2.6e-2] -gas_giant false -dust_mass [EM 2.6e-2] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "ganymede: [ganymede configure]"
    #planets europa   ={2,4.49e-3,0.0075,0   , EM(7.9e-3 ),FALSE,EM(7.9e-3 ), 0, ZEROES,0,NULL, &ganymede};
    Planets_Record europa -planet_no 2 -a 4.49e-3 -e 0.0075 -axial_tilt 0   \
          -mass [::stargen::EM 7.9e-3] -gas_giant false \
          -dust_mass [::stargen::EM 7.9e-3] \
          -gas_mass 0 -minor_moons 0 -moons {}
    #puts stderr "europa: [europa configure]"
    #planets io       ={1,2.82e-3,0.0006,0   , EM(1.21e-2),FALSE,EM(1.21e-2), 0, ZEROES,0,NULL, &europa};
    Planets_Record io -planet_no     1 -a 2.82e-3 -e 0.0006 -axial_tilt 0   \
              -mass [EM 1.21e-2] -gas_giant false -dust_mass [EM 1.21e-2] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "io: [io configure]"
    set jupiter_moons [list ::stargen::io ::stargen::europa \
                       ::stargen::ganymede ::stargen::callisto]
    #foreach m $jupiter_moons {
    #    puts stderr "Jupiter: $m [$m configure]"
    #}
    #planets iapetus  ={6,2.38e-2,0.029, 0   , EM(8.4e-4 ),FALSE,EM(8.4e-4 ), 0, ZEROES,0,NULL, NULL};
    Planets_Record iapetus -planet_no 6 -a 2.38e-2 -e 0.029 -axial_tilt  0   \
          -mass [EM 8.4e-4] -gas_giant false -dust_mass [EM 8.4e-4] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "iapetus: [iapetus configure]"
    #planets hyperion ={5,9.89e-3,0.110, 0   , EM(1.82e-5),FALSE,EM(1.82e-5), 0, ZEROES,0,NULL, &iapetus};
    Planets_Record hyperion -planet_no 5 -a 9.89e-3 -e 0.110 -axial_tilt  0   \
          -mass [EM 1.82e-5] -gas_giant false -dust_mass [EM 1.82e-5] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "hyperion: [hyperion configure]"
    #planets titan    ={4,8.17e-3,0.0289,0   , EM(2.3e-2 ),FALSE,EM(2.3e-2 ), 0, ZEROES,0,NULL, &hyperion};
    Planets_Record titan -planet_no 4 -a 8.17e-3 -e 0.0289 -axial_tilt 0   \
              -mass [EM 2.3e-2] -gas_giant false -dust_mass [EM 2.3e-2] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "titan: [titan configure]"
    #planets rhea     ={3,3.52e-3,0.0009,0   , EM(3.85e-4),FALSE,EM(3.85e-4), 0, ZEROES,0,NULL, &titan};
    Planets_Record rhea -planet_no 3 -a 3.52e-3 -e 0.0009 -axial_tilt 0   \
              -mass [EM 3.85e-4] -gas_giant false -dust_mass [EM 3.85e-4] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "rhea: [rhea configure]"
    #planets dione    ={2,2.52e-3,0.0021,0   , EM(1.74e-4),FALSE,EM(1.74e-4), 0, ZEROES,0,NULL, &rhea};
    Planets_Record dione -planet_no 2 -a 2.52e-3 -e 0.0021 -axial_tilt 0   \
          -mass [EM 1.74e-4] -gas_giant false -dust_mass [EM 1.74e-4] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "dione: [dione configure]"
    #planets tethys   ={1,1.97e-3,0.000, 0   , EM(1.09e-4),FALSE,EM(1.09e-4), 0, ZEROES,0,NULL, &dione};
    Planets_Record tethys -planet_no 1 -a 1.97e-3 -e 0.000 -axial_tilt  0   \
              -mass [EM 1.09e-4] -gas_giant false -dust_mass [EM 1.09e-4] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "tethys: [tethys configure]"
    set saturn_moons [list ::stargen::tethys ::stargen::dione ::stargen::rhea \
                      ::stargen::titan ::stargen::hyperion ::stargen::iapetus]
    #foreach m $saturn_moons {
    #     puts stderr "Saturn: $m: [$m configure]"
    #}
    #planets triton   ={1,2.36e-3,0.000, 0   , EM(2.31e-2),FALSE,EM(2.31e-2), 0, ZEROES,0,NULL, NULL};
    Planets_Record triton -planet_no 1 -a 2.36e-3 -e 0.000 -axial_tilt  0   \
              -mass [EM 2.31e-2] -gas_giant false -dust_mass [EM 2.31e-2] -gas_mass 0\
          -minor_moons 0 -moons {}
    #puts stderr "triton: [triton configure]"
    #planets charon   ={1,19571/KM_PER_AU,0.000, 0   , EM(2.54e-4),FALSE,EM(2.54e-4), 0, ZEROES,0,NULL, NULL};
    Planets_Record charon -planet_no 1 -a [expr {19571/$KM_PER_AU}] -e 0.000 -axial_tilt  0   \
              -mass [EM 2.54e-4] -gas_giant false -dust_mass [EM 2.54e-4] -gas_mass 0\
              -minor_moons 0 -moons {}
    #puts stderr "charon: [charon configure]"
    
    #planets xena   ={11,67.6681,0.44177,0   , EM(.0025),FALSE, EM(.0025),    0, ZEROES,0,NULL,    NULL};
    Planets_Record xena   -planet_no 11 -a 67.6681 -e 0.44177 -axial_tilt 0   \
          -mass [EM .0025] -gas_giant false -dust_mass [EM .0025] \
          -gas_mass    0
    #puts stderr "xena: [xena configure]"
    #planets pluto  ={10,39.529,0.248,122.5, EM(0.002),  FALSE, EM(0.002),    0, ZEROES,0,&charon, &xena};
    Planets_Record pluto  -planet_no 10 -a 39.529 -e 0.248 -axial_tilt 122.5\
          -mass [EM 0.002] -gas_giant   false -dust_mass  [EM 0.002] \
          -gas_mass    0 -moons [list ::stargen::charon]
    #puts stderr "pluto: [pluto configure]"
    #planets neptune={ 9,30.061,0.010, 29.6, EM(17.14),  true,  0,   EM(17.14),  ZEROES,0,&triton, &pluto};
    Planets_Record neptune -planet_no  9 -a 30.061 -e 0.010 -axial_tilt  29.6\
          -mass [EM 17.14] -gas_giant   true -dust_mass   0 \
          -gas_mass   [EM 17.14] -moons [list ::stargen::triton]
    #puts stderr "neptune: [neptune configure]"
    #planets uranus ={ 8,19.191,0.046, 97.9, EM(14.530), TRUE,  0,   EM(14.530), ZEROES,0,NULL,    &neptune};
    Planets_Record uranus -planet_no  8 -a 19.191 -e 0.046 -axial_tilt  97.9\
          -mass [EM 14.530] -gas_giant  true -dust_mass   0 \
          -gas_mass   [EM 14.530]
    #puts stderr "uranus: [uranus configure]"
    #planets saturn ={ 7,9.539, 0.056, 26.7, EM(95.18),  TRUE,  0,   EM(95.18),  ZEROES,0,&tethys, &uranus};
    Planets_Record saturn -planet_no  7 -a 9.539 -e  0.056 -axial_tilt  26.7\
          -mass [EM 95.18] -gas_giant   true -dust_mass   0 \
          -gas_mass [EM 95.18] -moons $saturn_moons
    #puts stderr "saturn: [saturn configure]"
    #planets jupiter={ 6,5.203, 0.048,  3.1, EM(317.9),  TRUE,  0,   EM(317.9),  ZEROES,0,&io,     &saturn};
    Planets_Record jupiter -planet_no  6 -a 5.203 -e  0.048 -axial_tilt   3.1\
          -mass [EM 317.9] -gas_giant   true -dust_mass   0 \
          -gas_mass [EM 317.9] -moons $jupiter_moons
    #puts stderr "jupiter: [jupiter configure]"
    #planets ceres  ={ 5,2.766, 0.080,  0,   9.5e20 /SOLAR_MASS_IN_KILOGRAMS, FALSE, 9.5e20 /SOLAR_MASS_IN_KILOGRAMS, 0, ZEROES,0,NULL,    &jupiter};
    Planets_Record ceres  -planet_no  5 -a 2.766 -e  0.080 -axial_tilt   0\
          -mass [expr {9.5e20/$SOLAR_MASS_IN_KILOGRAMS}] -gas_giant  false \
          -dust_mass  [expr {9.5e20 /$SOLAR_MASS_IN_KILOGRAMS}] -gas_mass 0
    #puts stderr "ceres: [ceres configure]"
    #planets mars   ={ 4,1.524, 0.093, 25.2, EM(0.1074), FALSE, EM(0.1074),   0, ZEROES,0,NULL,    &ceres};
    Planets_Record mars   -planet_no  4 -a 1.524 -e  0.093 -axial_tilt  25.2\
          -mass [EM 0.1074] -gas_giant  false -dust_mass  [EM 0.1074] \
          -gas_mass   0
    #puts stderr "mars: [mars configure]"
    #planets earth  ={ 3,1.000, 0.017, 23.5, EM(1.00),   FALSE, EM(1.00),     0, ZEROES,0,&luna,   &mars};
    Planets_Record earth  -planet_no  3 -a 1.000 -e  0.017 -axial_tilt  23.5\
          -mass [EM 1.00] -gas_giant    false -dust_mass  [EM 1.00] \
          -gas_mass     0 -moons [list ::stargen::luna]
    #puts stderr "earth: [earth configure]"
    #planets venus  ={ 2,0.723, 0.007,177.3, EM(0.815),  FALSE, EM(0.815),    0, ZEROES,0,NULL,    &earth};
    Planets_Record venus  -planet_no  2 -a 0.723 -e  0.007 -axial_tilt 177.3\
          -mass [EM 0.815] -gas_giant   false -dust_mass  [EM 0.815] \
          -gas_mass    0
    #puts stderr "venus: [venus configure]"
    #planets mercury={ 1,0.387, 0.206,  2,   EM(0.055),  FALSE, EM(0.055),    0, ZEROES,0,NULL,    &venus};
    Planets_Record mercury -planet_no  1 -a 0.387 -e  0.206 -axial_tilt   2\
          -mass [EM 0.055] -gas_giant   false -dust_mass  [EM 0.055] \
          -gas_mass    0
    #puts stderr "mercury: [mercury configure]"
    #planet_pointer solar_system = &mercury;
    variable solar_system [list ::stargen::mercury ::stargen::venus \
                           ::stargen::earth ::stargen::mars ::stargen::ceres \
                           ::stargen::jupiter ::stargen::saturn \
                           ::stargen::uranus ::stargen::neptune \
                           ::stargen::pluto ::stargen::xena]
    namespace export solar_system
    namespace export earth
    
    #/* Seeds for accreting the solar system */
    #planets pluto1  ={10,39.529,0.248, 0, 0, 0, 0, 0, ZEROES,0,NULL, NULL};
    Planets_Record  pluto1  -planet_no 10 -a 39.529 -e 0.248
    #planets pluto2  ={10,39.529,0.15,  0, 0, 0, 0, 0, ZEROES,0,NULL, NULL};	// The real eccentricity 
    Planets_Record  pluto2  -planet_no 10 -a 39.529 -e 0.15
    #planets mars1   ={ 4,1.524, 0.093, 0, 0, 0, 0, 0, ZEROES,0,NULL, &pluto2};	// collides Pluto+Neptune
    Planets_Record  mars1   -planet_no  4 -a 1.524 -e  0.093
    #planets ceres1  ={ 5,2.767, 0.079, 0, 0, 0, 0, 0, ZEROES,0,NULL, &mars1};
    Planets_Record  ceres1  -planet_no  5 -a 2.767 -e  0.079
    #planets saturn1 ={ 7,9.539, 0.056, 0, 0, 0, 0, 0, ZEROES,0,NULL, &ceres1};
    Planets_Record  saturn1 -planet_no  7 -a 9.539 -e  0.056
    #planets uranus1 ={ 8,19.191,0.046, 0, 0, 0, 0, 0, ZEROES,0,NULL, &saturn1};
    Planets_Record  uranus1 -planet_no  8 -a 19.191 -e 0.046
    #planets neptune1={ 9,30.061,0.010, 0, 0, 0, 0, 0, ZEROES,0,NULL, &uranus1};
    Planets_Record  neptune1 -planet_no  9 -a 30.061 -e 0.010
    #planets jupiter1={ 6,5.203, 0.048, 0, 0, 0, 0, 0, ZEROES,0,NULL, &neptune1};
    Planets_Record  jupiter1 -planet_no  6 -a 5.203 -e  0.048
    #planets mercury1={ 1,0.387, 0.206, 0, 0, 0, 0, 0, ZEROES,0,NULL, &jupiter1};
    Planets_Record  mercury1 -planet_no  1 -a 0.387 -e  0.206
    #planets earth1  ={ 3,1.000, 0.017, 0, 0, 0, 0, 0, ZEROES,0,NULL, &mercury1};
    Planets_Record  earth1  -planet_no  3 -a 1.000 -e  0.017
    #planets venus1  ={ 2,0.723, 0.007, 0, 0, 0, 0, 0, ZEROES,0,NULL, &earth1};
    Planets_Record  venus1  -planet_no  2 -a 0.723 -e  0.007
    #planet_pointer solar_system1 = &venus1;
    variable solar_system1 [list ::stargen::venus1 ::stargen::earth1 \
                            ::stargen::mercury1 ::stargen::jupiter1 \
                            ::stargen::neptune1 ::stargen::uranus1 \
                            ::stargen::saturn1 ::stargen::ceres1 \
                            ::stargen::mars1 ::stargen::pluto2]

    #planets eriEpsI	={ 1,3.3,	0.608, 	0, 0, 0, 0, 0, ZEROES,0,NULL, NULL};
    Planets_Record  eriEpsI	-planet_no  1 -a 3.3 -e 	0.608
    #planets UMa47II	={ 2,3.73,	0,     	0, 0, 0, 0, 0, ZEROES,0,NULL, NULL};
    Planets_Record  UMa47II	-planet_no  2 -a 3.73 -e 	0
    #planets UMa47I	={ 1,2.11, 	0.096, 	0, 0, 0, 0, 0, ZEROES,0,NULL, &UMa47II};
    Planets_Record  UMa47I	-planet_no  1 -a 2.11 -e  	0.096
    set UMa47_planets [list ::stargen::UMa47I ::stargen::UMa47II]
    #planets horIotI	={ 1,0.925,	0.161,	0, 0, 0, 0, 0, ZEROES,0,NULL, NULL};
    Planets_Record  horIotI	-planet_no  1 -a 0.925 -e 	0.161
    
    #/*	No Orbit Eccen. Tilt   Mass    Gas Giant? Dust Mass   Gas */
    #planets	smallest={0, 0.0, 0.0,	20.0,	EM(0.4),   FALSE,  EM(0.4),   0.0, ZEROES,0,NULL, NULL};
    Planets_Record	smallest -planet_no 0 -a 0.0 -e 0.0 -axial_tilt	20.0 \
          -mass	[EM 0.4] -gas_giant   false -dust_mass  [EM 0.4] \
          -gas_mass   0.0
    #planets	average	={0, 0.0, 0.0,	20.0,	EM(1.0),   FALSE,  EM(1.0),    0.0, ZEROES,0,NULL, NULL};
    Planets_Record	average	 -planet_no 0 -a 0.0 -e 0.0 -axial_tilt	20.0 \
          -mass	[EM 1.0] -gas_giant   false -dust_mass  [EM 1.0] \
          -gas_mass    0.0
    #planets	largest	={0, 0.0, 0.0,	20.0,	EM(1.6),   FALSE,  EM(1.6),   0.0, ZEROES,0,NULL, NULL};
    Planets_Record	largest	 -planet_no 0 -a 0.0 -e 0.0 -axial_tilt	20.0 \
          -mass	[EM 1.6] -gas_giant   false -dust_mass  [EM 1.6] \
          -gas_mass   0.0
 
    
    #/*                       L  Mass	Mass2	Eccen.	SemiMajorAxis	Designation	Name	*/
    #star	perdole[] = {{0, 1.00,	0,		0,		0,				 &mercury,	"Sol",		 1, "The Solar System"},
    #                        {0, 1.08,	0.88,	0.52,	23.2,			 NULL,		"ALF Cen A", 1, "Alpha Centauri A"},
    #                        {0, 0.88,	1.08,	0.52,	23.2,			 NULL,		"ALF Cen B", 1, "Alpha Centauri B"},
    #                        {0, 0.80,	0,		0,		0,				 &eriEpsI,	"EPS Eri",	 1, "Epsilon Eridani"},
    #                        {0, 0.82,	0,		0,		0,				 NULL,		"TAU Cet",	 1, "Tau Ceti"},
    #                        {0, 0.90,	0.65,	0.50,	AVE(22.8,24.3),	 NULL,		"70 Oph",	 1, "70 Ophiuchi A"},
    #                        {0, 0.94,	0.58,	0.53,	AVE(69.,71.),	 NULL,		"ETA Cas",	 1, "Eta Cassiopeiae A"},
    #                        {0, 0.82,	0,		0,		0,				 NULL,		"SIG Dra",	 1, "Sigma Draconis"},
    #                        {0, 0.77,	0.76,	0,		22.,			 NULL,		"36 Oph",	 1, "36 Ophiuchi A"},
    #                        {0, 0.76,	0.77,	0,		22.,			 NULL,		"36 Oph B",	 0, "36 Ophiuchi B"},
    #/*			     {0, 0.76,	0,		0,		46.,			 NULL,		"HD 191408", 1, "HR7703 A"}, */
    #/* Fake up a B just to clip the distances -- need the real data */
    #                        {0, 0.76,	.5,		.5,		46.,			 NULL,		"HD 191408", 1, "HR7703 A"},
    #                        {0, 0.98,	0,		0,		0,				 NULL,		"DEL Pav",	 1, "Delta Pavonis"},
    #                        {0, 0.91,	0,		0,		0,				 NULL,		"82 Eri",	 1, "82 Eridani"},
    #                        {0, 1.23,	0,		0,		0,				 NULL,		"BET Hyi",	 1, "Beta Hydri"},
    #                        {0, 0.74,	0,		0,		0,				 NULL,		"HD 219134", 1, "HR8832"},
    #                        {0, 0.725,0,		0,		1100.,			 NULL,		"HD 16160",	 1, "HR753 A"}
    #                        };
    #Star desig -luminosity -mass -m2 -e -a known_planets -in_celestia -name
    Catalog dole -arg "d" \
          [Star "Sol" -luminosity 0 -mass 1.00 -m2 0 -e 0 -a 0 \
           -known_planets $solar_system -in_celestia true \
           -name "The Solar System"] \
          [Star "ALF Cen A" -luminosity 0 -mass 1.08 -m2 0.88 \
           -e 0.52 -a 23.2 -known_planets {} -in_celestia true \
           -name "Alpha Centauri A"] \
          [Star "ALF Cen B" -luminosity 0 -mass 0.88 -m2 1.08 \
           -e 0.52 -a 23.2 -known_planets {} -in_celestia true \
           -name "Alpha Centauri B"] \
          [Star "EPS Eri" -luminosity 0 -mass 0.80 -m2 0 -e 0 \
           -a 0 -known_planets [list ::stargen::eriEpsI] \
           -in_celestia true -name "Epsilon Eridani"] \
          [Star "TAU Cet" -luminosity 0 -mass 0.82 -m2 0 -e 0 \
           -a 0 -known_planets {} -in_celestia true \
           -name "Tau Ceti"] \
          [Star "70 Oph" -luminosity 0 -mass 0.90 -m2 0.65 \
           -e 0.50 -a [AVE 22.8 24.3] -known_planets {} \
           -in_celestia true -name "70 Ophiuchi A"] \
          [Star "ETA Cas" -luminosity 0 -mass 0.94 -m2 0.58 \
           -e 0.53 -a [AVE 69. 71.] -known_planets {} \
           -in_celestia true -name "Eta Cassiopeiae A"] \
          [Star "SIG Dra" -luminosity 0 -mass 0.82 -m2 0 -e 0 \
           -a 0 -known_planets {} -in_celestia true \
           -name "Sigma Draconis"] \
          [Star "36 Oph" -luminosity 0 -mass 0.77 -m2 0.76 -e 0 \
           -a 22. -known_planets {} -in_celestia true \
           -name "36 Ophiuchi A"] \
          [Star "36 Oph B" -luminosity 0 -mass 0.76 -m2 0.77 -e 0 \
           -a 22. -known_planets {} -in_celestia 0 \
           -name "36 Ophiuchi B"] \
          [Star "HD 191408" -luminosity 0 -mass 0.76 -m2 .5 -e .5 \
           -a 46. -known_planets {} -in_celestia true \
           -name "HR7703 A"] \
          [Star "DEL Pav" -luminosity 0 -mass 0.98 -m2 0 -e 0 \
           -a 0 -known_planets {} -in_celestia true \
           -name "Delta Pavonis"] \
          [Star "82 Eri" -luminosity 0 -mass 0.91 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true \
           -name "82 Eridani"] \
          [Star "BET Hyi" -luminosity 0 -mass 1.23 -m2 0 -e 0 \
           -a 0 -known_planets {} -in_celestia true \
           -name "Beta Hydri"] \
          [Star "HD 219134" -luminosity 0 -mass 0.74 -m2 0 -e 0 \
           -a 0 -known_planets {} -in_celestia true \
           -name "HR8832"] \
          [Star "HD 16160" -luminosity 0 -mass 0.725 -m2 0 -e 0 \
           -a 1100. -known_planets {} -in_celestia true \
           -name "HR753 A"]
    namespace export dole

    #
    #	The following values were taken from: http://www.solstation.com/stars.htm
    #

    #star	web[] = 
    #// L			Mass			Mass2			Eccen.	SMAxis	 Planets	Designation	Name
    #{{1.00,			1.00,			0,				0,		0,		 &mercury,	"Sol",		 1, "The Solar System"},		// 0
    #{1.60,			1.09,			0.90,			0.519,	23.7,	 NULL,		"ALF Cen A", 1, "Alpha Centauri A"},		// 4.4
    #{0.45,			0.90,			1.09,			0.519,	23.7,	 NULL,		"ALF Cen B", 1, "Alpha Centauri B"},		// 4.4
    #{0.34,			0.85,			0,				0,		0,		 &eriEpsI,	"EPS Eri",	 1, "Epsilon Eridani"},			// 10.5 
    #//{AVE(6.3,8.9),0.59,			0.5,			.48,	85.2,	 NULL,		"61 Cyg A",	 1, "61 Cygni A"},				// 11.4
    #{0.085,		0.59,			0.5,			.48,	85.2,	 NULL,		"61 Cyg A",	 1, "61 Cygni A"},				// 11.4
    #{0.59,			0.82,			0,				0,		0,		 NULL,		"TAU Cet",	 1, "Tau Ceti"},				// 11.9 
    #{0.38,			0.75,			(0.16+0.43),	0,		418.,	 NULL,		"40 Eri",	 1, "40 Eridani A"},			// 16.5
    #{AVE(.44,.47),	0.924,			0.701,			0.495,	23.3,	 NULL,		"70 Oph",	 1, "70 Ophiuchi A"},			// 16.6
    #{0.39,			0.82,			0,				0,		0,		 NULL,		"SIG Dra",	 1, "Sigma Draconis"},			// 18.8 
    #{0.156,		0.76,			(0.55+0.35),	0.20,	190.,	 NULL,		"33 g Lib",	 1, "HR 5568"},					// 19.3
    #{AVE(1.0,1.29),0.91,			0.56,			0.497,	71.0,	 NULL,		"ETA Cas",	 1, "Eta Cassiopeiae A"},		// 19.4
    #{0.23,			0.82,			0.20,			.5,		43.,	 NULL,		"HD 191408", 1, "HR 7703 (HJ 5173) A"},		// 19.7
    #{0.65,			0.97,			0,				0,		0,		 NULL,		"82 Eri",	 1, "82 Eridani"},				// 19.8
    #{1.2,			0.98,			0,				0,		0,		 NULL,		"DEL Pav",	 1, "Delta Pavonis"},			// 19.9
    #{0,			0.74,			0,				0,		0,		 NULL,		"HD 219134", 1, "HR 8832"},					// 21.3
    #{0.52,			0.90,			0.76,			0.51,	33.6,	 NULL,		"XI Boo",	 1, "Xi Bootis A"},				// 21.8
    #{0.21,			0.81,			0.082,			.75,	15.,	 NULL,		"HD 16160",	 1, "HR 753 A"},				// 23.5
    #{0.24,			0.83,			0,				0,		0,		 NULL,		"HD 4628",	 1, "BD+04 123 (HR 222)"},		// 24.3
    #{3.6,			1.1,			0,				0,		0,		 NULL,		"BET Hyi",	 1, "Beta Hydri"},				// 24.4 
    #{0.37,			0.89,			0,				0,		0,		 NULL,		"107 Psc",	 1, "107 Piscium"},				// 24.4 
    #// 107 Psc p1 = Klotho in Celestia's imagined.ssc
    #{3.,			1.3,			0,				0,		0,		 NULL,		"PI3 Ori",	 1, "Pi3 Orionis A"},			// 26.2
    #{0.28,			0.88,			0.86,			0.534,	63.7,	 NULL,		"RHO1 Eri",	 1, "Rho Eridani A"},			// 26.6 
    #{0.25,			0.86,			0.88,			0.534,	63.7,	 NULL,		"RHO2 Eri",	 1, "Rho Eridani B"},			// 26.6 
    #{1.2,			1.07,			0,				0,		0,		 NULL,		"BET CVn",	 1, "Chara"},					// 27.3 
    #{2.9,			.90,			1.45,			0.412,	21.2,	 NULL,		"XI UMa",	 1, "Xi Ursae Majoris Ba"},		// 27.3 
    #//																	Xi Urs Maj aka Alula Australis
    #//					55203:Alula Australis:XI UMa:53 UMa defined in Celestia starnames, but no data
    #{0.80,			0.96,			0,				0,		0,		 NULL,		"61 Vir",	 1, "61 Virginis"},				// 27.8  
    #{1.3,			0.98,			0,				0,		0,		 NULL,		"ZET Tuc",	 1, "Zeta Tucanae"},			// 28.0
    #{1.08,			1.0,			.15,			0.45,	6.4,	 NULL,		"CHI1 Ori",	 1, "Chi1 Orionis A"},			// 28.3 
    #//					41 Arae masses are Wieth-Knudsen's 1957 estimates,
    #{0.41,			0.9,			.6,				0.779,	91.5,	 NULL,		"41 Ari",	 1, "41 Arae A"},				// 28.7 
    #{0.21,			0.845,			0,				0,		0,		 NULL,		"HR 1614",	 0, "BD-05 1123 (HR 1614) A"},	// 28.8 
    #{0.33,			0.87,			0,				0,		0,		 NULL,		"HR 7722",	 0, "CD-27 14659 (HR 7722)"},	// 28.8 
    #{2.6,			1.2,			.63,			.5,		864.,	 NULL,		"GAM Lep",	 1, "Gamma Leporis A"},			// 29.3 
    #{1.4,			1.05,			0,				0,		0,		 NULL,		"BET Com",	 1, "Beta Comae Berenices"},	// 29.9   
    #{0.85,			1.0,			0,				0,		0,		 NULL,		"KAP1 Cet",	 1, "Kappa Ceti"},				// 29.9   
    #{1.5,			0.8,			0,				0,		0,		 NULL,		"GAM Pav",	 1, "Gamma Pavonis"},			// 30.1
    #{0.82,			0.8,			0.07,			0.6,	235.,	 NULL,		"HD 102365", 1, "HR 4523"},					// 30.1
    #{0.588,		0.81,			0,				0,		0,		 NULL,		"61 UMa",	 1, "61 Ursae Majoris"},		// 31.1  
    #{0.31,			0.87,			0,				0.5,	80.5,	 NULL,		"HR 4458",	 0, "CD-32 8179 (HR 4458)"},	// 31.1 
    #{AVE(.39,.41),	0.90,			0,				0,		0,		 NULL,		"12 Oph",	 1, "12 Ophiuchi"},				// 31.9
    #{0.46,			0.92,			0,				0,		0,		 NULL,		"HR 511",	 0, "BD+63 238 (HR 511)"},		// 32.5
    #{0.83,			0.87,			0,				0,		0,		 NULL,		"ALF Men",	 1, "Alpha Mensae"},			// 33.1
    #{0.93,			0.79,			1.02,			0.5,	9000.,	 NULL,		"ZET1 Ret",	 1, "Zeta 1 Reticuli"},			// 39.4-39.5
    #{0.99,			1.02,			0.79,			0.5,	9000.,	 NULL,		"ZET2 Ret",	 1, "Zeta 2 Reticuli"},			// 39.4-39.5
    #{1.14,			1.05,			2.0,			0.55,	48.5,	 NULL,		"44 Boo",	 1, "44 Bootis A"},				// 41.6
    #{1.7,			1.03,			0,				0,		0,		 &UMa47I,	"47 UMa",	 1, "47 Ursae Majoris"},		// 45.9
    #{1.8,			1.03,			0,				0,		0,		 &horIotI,	"IOT Hor",	 1, "Iota Horologii"},			// 56.2
    #
    #
    #{AVE(.13,.15),	AVE(.59,.71),	0,				0,		0,		 NULL,		"EPS Ind",	 1, "Epsilon Indi"},			// 11.8  
    #{AVE(.083,.09),0.701,			0.924,			0.495,	23.3,	 NULL,		"70 Oph",	 1, "70 Ophiuchi B"},			// 16.6
    #{0.28,			0.85,			0.85,			0.922,	88.,	 NULL,		"36 Oph",	 1, "36 Ophiuchi A"},			// 19.5
    #{0.27,			0.85,			0.85,			0.922,	88.,	 NULL,		"36 Oph B",	 0, "36 Ophiuchi B"},			// 19.5
    #{0.12,			0.75,			0.65,			0.58,	12.6,	 NULL,		"HR 6426",	 0, "MLO 4 (HR 6426) A"},		// 22.7
    #{0.146,		0.80,			0.50,			0.5,	500.,	 NULL,		"BD-05 1844 A",0,"BD-05 1844 A"}			// 28.3 
    #};
    #
    #// BD-05 1123 A:	 HR 1614, Gl 183 A, Hip 23311, HD 32147, SAO 131688, LHS 200, LTT 2412, LFT 382, and LPM 200. 
    #// CD-27 14659:		 HR 7722, Gl 785, Hip 99825, HD 192310, CP(D)-27 6972, SAO 189065, LHS 488, LTT 8009, LFT 1535, and LPM 731
    #// CD-32 8179 A:	 HR 4458, Gl 432 A, Hip 56452, HD 100623, CP(D)-32 3122, SAO 202583, LHS 308, LTT 4280, LFT 823, LPM 389, and E 439-246.  
    #// BD+63 238:		 HR 511*, Gl 75, Hip 8362, HD 10780, SAO 11983, LHS 1297, LTT 10619, and LFT 162. 
    #// 36 Ophiuchi B:	 HR 6401, Gl 663 B, HD 155885, SAO 185199, LHS 438, and ADS 10417 B. 
    #// MLO 4 A:			 HR 6426*, Gl 667 A, Hip 84709, HD 156384, CD-34 11626 A, CP-34 6803, SAO 208670, LHS 442, LTT 6888, LFT 1336, LPM 638, and UGPMF 433. 
    #// BD-05 1844 A:	 Gl 250 A, Hip 32984, HD 50281, SAO 133805, LHS 1875, LTT 2662, LFT 494, and LPM 244. 
    #
    #// {.00006,		0.105,			0.1,			0.62,	5.5,	 NULL,		"",	"Luyten 726-8 A"},		// 8.7
    #// {0.039,		0.5,			0.59,			.48,	85.2,	 NULL,		"",	"61 Cygni B"},			// 11.4
    #// {0.05,		0.65,			0.75,			0.58,	12.6,	 NULL,		"",	"MLO 4 (HR 6426) B"},	// 22.7
    #// {1.1,		1.05,			0.4,			0.53,	0.6,	 NULL,		"",	"Xi Ursae Majoris Aa"},	// 27.3 
    #// {0,			0.4,			1.05,			0.53,	0.6,	 NULL,		"",	"Xi Ursae Majoris Ab"},	// 27.3
    #// {0.064,		0.76,			0.90,			0.51,	33.0,	 NULL,		"",	"Xi Bootis B"},			// 21.8
    #
    
    Catalog solstation -arg "w" \
          [Star "Sol_" -luminosity 1.00 -mass 1.00 -m2 0 -e 0 -a 0 \
           -known_planets $solar_system	-in_celestia true \
           -name "The Solar System"] \
          [Star "ALF Cen A_" -luminosity 1.60 -mass 1.09 -m2 0.90 -e 0.519 \
           -a 23.7 -known_planets {} -in_celestia true \
           -name "Alpha Centauri A"] \
          [Star "ALF Cen B_" -luminosity 0.45 -mass 0.90 -m2 1.09 -e 0.519 \
           -a 23.7 -known_planets {} -in_celestia true \
           -name "Alpha Centauri B"] \
          [Star "EPS Eri_" -luminosity 0.34 -mass 0.85 -m2 0 -e 0 -a 0 \
           -known_planets [list ::stargen::eriEpsI] -in_celestia true \
           -name "Epsilon Eridani"] \
          [Star "61 Cyg A" -luminosity 0.085 -mass 0.59 -m2 0.5 -e .48 \
           -a 85.2 -known_planets {} -in_celestia true -name "61 Cygni A"] \
          [Star "TAU Cet_" -luminosity 0.59 -mass 0.82 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Tau Ceti"] \
          [Star "40 Eri" -luminosity 0.38 -mass 0.75 -m2 [expr {0.16+0.43}] \
           -e 0 -a 418. -known_planets {} -in_celestia true \
           -name "40 Eridani A"] \
          [Star "70 Oph_" -luminosity [AVE .44 .47] -mass 0.924 -m2 0.701 \
           -e 0.495 -a  23.3 -known_planets {} -in_celestia true \
           -name "70 Ophiuchi A"] \
          [Star "SIG Dra_" -luminosity 0.39 -mass 0.82 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Sigma Draconis"] \
          [Star "33 g Lib" -luminosity 0.156 -mass 0.76 \
           -m2 [expr {0.55+0.35}] -e  0.20 -a  190. -known_planets {} \
           -in_celestia true -name "HR 5568"] \
          [Star "ETA Cas_" -luminosity [AVE 1.0 1.29] -mass 0.91 -m2 0.56 \
           -e 0.497 -a  71.0 -known_planets {} -in_celestia true \
           -name "Eta Cassiopeiae A"] \
          [Star "HD 191408_" -luminosity 0.23 -mass 0.82 -m2 0.20 -e .5 -a 43. \
           -known_planets {} -in_celestia true -name "HR 7703 (HJ 5173) A"] \
          [Star "82 Eri_" -luminosity 0.65 -mass 0.97 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "82 Eridani"] \
          [Star "DEL Pav_" -luminosity 1.2 -mass 0.98 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Delta Pavonis"] \
          [Star "HD 219134_" -luminosity 0 -mass 0.74 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "HR 8832"] \
          [Star "XI Boo" -luminosity 0.52 -mass 0.90 -m2 0.76 -e 0.51 -a 33.6 \
           -known_planets {} -in_celestia true -name "Xi Bootis A"] \
          [Star "HD 16160_" -luminosity 0.21 -mass 0.81 -m2 0.082 -e .75 \
           -a 15. -known_planets {} -in_celestia true -name "HR 753 A"] \
          [Star "HD 4628" -luminosity 0.24 -mass 0.83 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "BD+04 123 (HR 222)"] \
          [Star "BET Hyi_" -luminosity 3.6 -mass 1.1 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Beta Hydri"] \
          [Star "107 Psc" -luminosity 0.37 -mass 0.89 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "107 Piscium"] \
          [Star "PI3 Ori" -luminosity 3. -mass 1.3 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Pi3 Orionis A"] \
          [Star "RHO1 Eri" -luminosity 0.28 -mass 0.88 -m2 0.86 -e 0.534 \
           -a 63.7 -known_planets {} -in_celestia true -name "Rho Eridani A"] \
          [Star "RHO2 Eri" -luminosity 0.25 -mass 0.86 -m2 0.88 -e 0.534 \
           -a 63.7 -known_planets {} -in_celestia true -name "Rho Eridani B"] \
          [Star "BET CVn" -luminosity 1.2 -mass 1.07 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Chara"] \
          [Star "XI UMa" -luminosity 2.9 -mass .90 -m2 1.45 -e 0.412 -a 21.2 \
           -known_planets {} -in_celestia true -name "Xi Ursae Majoris Ba"] \
          [Star "61 Vir" -luminosity 0.80 -mass 0.96 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "61 Virginis"] \
          [Star "ZET Tuc" -luminosity 1.3 -mass 0.98 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Zeta Tucanae"] \
          [Star "CHI1 Ori" -luminosity 1.08 -mass 1.0 -m2 .15 -e 0.45 -a 6.4 \
           -known_planets {} -in_celestia true -name "Chi1 Orionis A"] \
          [Star "41 Ari" -luminosity 0.41 -mass 0.9 -m2 .6 -e 0.779 -a 91.5 \
           -known_planets {} -in_celestia true -name "41 Arae A"] \
          [Star "HR 1614" -luminosity 0.21 -mass 0.845 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia false -name "BD-05 1123 (HR 1614) A"] \
          [Star "HR 7722" -luminosity 0.33 -mass 0.87 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia false -name "CD-27 14659 (HR 7722)"] \
          [Star "GAM Lep" -luminosity 2.6 -mass 1.2 -m2 .63 -e .5 -a 864. \
           -known_planets {} -in_celestia true -name "Gamma Leporis A"] \
          [Star "BET Com" -luminosity 1.4 -mass 1.05 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Beta Comae Berenices"] \
          [Star "KAP1 Cet" -luminosity 0.85 -mass 1.0 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Kappa Ceti"] \
          [Star "GAM Pav" -luminosity 1.5 -mass 0.8 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Gamma Pavonis"] \
          [Star "HD 102365" -luminosity 0.82 -mass 0.8 -m2 0.07 -e 0.6 \
           -a  235. -known_planets {} -in_celestia true -name "HR 4523"] \
          [Star "61 UMa" -luminosity 0.588 -mass 0.81 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "61 Ursae Majoris"] \
          [Star "HR 4458" -luminosity 0.31 -mass 0.87 -m2 0 -e 0.5 -a 80.5 \
           -known_planets {} -in_celestia false -name "CD-32 8179 (HR 4458)"] \
          [Star "12 Oph" -luminosity [AVE .39 .41] -mass 0.90 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "12 Ophiuchi"] \
          [Star "HR 511" -luminosity 0.46 -mass 0.92 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia false -name "BD+63 238 (HR 511)"] \
          [Star "ALF Men" -luminosity 0.83 -mass 0.87 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Alpha Mensae"] \
          [Star "ZET1 Ret" -luminosity 0.93 -mass 0.79 -m2 1.02 -e 0.5 \
           -a 9000. -known_planets {} -in_celestia true \
           -name "Zeta 1 Reticuli"] \
          [Star "ZET2 Ret" -luminosity 0.99 -mass 1.02 -m2 0.79 -e 0.5 \
           -a 9000. -known_planets {} -in_celestia true \
           -name "Zeta 2 Reticuli"] \
          [Star "44 Boo" -luminosity 1.14 -mass 1.05 -m2 2.0 -e 0.55 -a 48.5 \
           -known_planets {} -in_celestia true -name "44 Bootis A"] \
          [Star "47 UMa" -luminosity 1.7 -mass 1.03 -m2 0 -e 0 -a 0 \
           -known_planets $UMa47_planets -in_celestia true \
           -name "47 Ursae Majoris"] \
          [Star "IOT Hor" -luminosity 1.8 -mass 1.03 -m2 0 -e 0 -a 0 \
           -known_planets [list ::stargen::horIotI] -in_celestia true \
           -name "Iota Horologii"] \
          [Star "EPS Ind" -luminosity [AVE .13 .15] -mass [AVE .59 .71] \
           -m2 0 -e 0 -a 0 -known_planets {} -in_celestia true \
           -name "Epsilon Indi"] \
          [Star "70 Oph_B" -luminosity [AVE .083 .09] -mass 0.701 -m2 0.924 \
           -e 0.495 -a  23.3 -known_planets {} -in_celestia true \
           -name "70 Ophiuchi B"] \
          [Star "36 Oph_" -luminosity 0.28 -mass 0.85 -m2 0.85 -e 0.922 -a 88. \
           -known_planets {} -in_celestia true -name "36 Ophiuchi A"] \
          [Star "36 Oph B_" -luminosity 0.27 -mass 0.85 -m2 0.85 -e 0.922 \
           -a 88. -known_planets {} -in_celestia false -name "36 Ophiuchi B"] \
          [Star "HR 6426" -luminosity 0.12 -mass 0.75 -m2 0.65 -e 0.58 \
           -a 12.6 -known_planets {} -in_celestia false \
           -name "MLO 4 (HR 6426) A"] \
          [Star "BD-05 1844 A" -luminosity 0.146 -mass 0.80 -m2 0.50 -e 0.5 \
           -a  500. -known_planets {} -in_celestia false -name "BD-05 1844 A"]
    namespace export solstation

    #star	various[] = 
    #{
    #// L			Mass			Mass2			Eccen.	SMAxis	 Planets	Designation	Name
    #{1.00,			1.00,			0,				0,		0,		 &mercury,	"Sol",		 1, "The Solar System"},		// 0
    #{14800.,		8,				0,				0,		0,		 NULL,		"ALF Car",	 1, "Canopus"}
    #};
    #
    
    Catalog jimb -arg "F" \
          ::stargen::Sol_ \
          [Star "ALF Car" -luminosity 14800. -mass 8 -m2 0 -e 0 -a 0 \
           -known_planets {} -in_celestia true -name "Canopus"]
    namespace export jimb

    #//   An   sym   HTML symbol                      name                 Aw      melt    boil    dens       ABUNDe       ABUNDs         Rea	Max inspired pp
    #{AN_H,  "H",  "H<SUB><SMALL>2</SMALL></SUB>",	 "Hydrogen",         1.0079,  14.06,  20.40,  8.99e-05,  0.00125893,  27925.4,       1,		0.0},
    #{AN_HE, "He", "He",							 "Helium",           4.0026,   3.46,   4.20,  0.0001787, 7.94328e-09, 2722.7,        0,		MAX_HE_IPP},
    #{AN_N,  "N",  "N<SUB><SMALL>2</SMALL></SUB>",	 "Nitrogen",        14.0067,  63.34,  77.40,  0.0012506, 1.99526e-05, 3.13329,       0,		MAX_N2_IPP},
    #{AN_O,  "O",  "O<SUB><SMALL>2</SMALL></SUB>",	 "Oxygen",          15.9994,  54.80,  90.20,  0.001429,  0.501187,    23.8232,       10,	MAX_O2_IPP},
    #{AN_NE, "Ne", "Ne",							 "Neon",            20.1700,  24.53,  27.10,  0.0009,    5.01187e-09, 3.4435e-5,     0,		MAX_NE_IPP},
    #{AN_AR, "Ar", "Ar",							 "Argon",           39.9480,  84.00,  87.30,  0.0017824, 3.16228e-06, 0.100925,      0,		MAX_AR_IPP},
    #{AN_KR, "Kr", "Kr",							 "Krypton",         83.8000, 116.60, 119.70,  0.003708,  1e-10,       4.4978e-05,    0,		MAX_KR_IPP},
    #{AN_XE, "Xe", "Xe",							 "Xenon",          131.3000, 161.30, 165.00,  0.00588,   3.16228e-11, 4.69894e-06,   0,		MAX_XE_IPP},
    #//                                                                     from here down, these columns were originally: 0.001,         0
    #{AN_NH3, "NH3", "NH<SUB><SMALL>3</SMALL></SUB>", "Ammonia",       17.0000, 195.46, 239.66,  0.001,     0.002,       0.0001,        1,		MAX_NH3_IPP},
    #{AN_H2O, "H2O", "H<SUB><SMALL>2</SMALL></SUB>O", "Water",         18.0000, 273.16, 373.16,  1.000,     0.03,        0.001,         0,		0.0},
    #{AN_CO2, "CO2", "CO<SUB><SMALL>2</SMALL></SUB>", "CarbonDioxide", 44.0000, 194.66, 194.66,  0.001,     0.01,        0.0005,        0,		MAX_CO2_IPP},
    #{AN_O3,   "O3", "O<SUB><SMALL>3</SMALL></SUB>",  "Ozone",         48.0000,  80.16, 161.16,  0.001,     0.001,       0.000001,      2,		MAX_O3_IPP},
    #{AN_CH4, "CH4", "CH<SUB><SMALL>4</SMALL></SUB>", "Methane",       16.0000,  90.16, 109.16,  0.010,     0.005,       0.0001,        1,		MAX_CH4_IPP},
    #{ 0, "", "", 0, 0, 0, 0, 0, 0, 0, 0, 0}
    variable gases
    set gases [list]
    lappend gases [::stargen::ChemTable H -num $::stargen::AN_H \
                   -symbol "H" -name "Hydrogen" -weight 1.0079 \
                   -melt 14.06 -boil 20.40 -density 8.99e-05 \
                   -abunde 0.00125893 -abunds 27925.4 -reactivity 1 \
                   -max_ipp $::stargen::INCREDIBLY_LARGE_NUMBER]
    lappend gases [::stargen::ChemTable He -num $::stargen::AN_HE \
                   -symbol "He" -name "Helium" -weight 4.0026 -melt 3.46 \
                   -boil 4.20 -density 0.0001787 -abunde 7.94328e-09 \
                   -abunds 2722.7 -reactivity 0 \
                   -max_ipp $::stargen::MAX_HE_IPP]
    lappend gases [::stargen::ChemTable N -num $::stargen::AN_N \
                   -symbol  "N" -name "Nitrogen" -weight 14.0067 \
                   -melt 63.34 -boil 77.40 -density 0.0012506 \
                   -abunde 1.99526e-05 -abunds 3.13329 -reactivity 0 \
                   -max_ipp $::stargen::MAX_N2_IPP]
    lappend gases [::stargen::ChemTable O -num $::stargen::AN_O \
                   -symbol  "O" -name "Oxygen" -weight 15.9994 -melt  54.80 \
                   -boil  90.20 -density  0.001429 -abunde  0.501187 \
                   -abunds 23.8232 -reactivity 10 \
                   -max_ipp $::stargen::MAX_O2_IPP]
    lappend gases [::stargen::ChemTable Ne -num $::stargen::AN_NE \
                   -symbol "Ne" -name "Neon" -weight 20.1700 -melt  24.53 \
                   -boil  27.10 -density 0.0009 -abunde 5.01187e-09 \
                   -abunds 3.4435e-5 -reactivity 0 \
                   -max_ipp $::stargen::MAX_NE_IPP]
    lappend gases [::stargen::ChemTable Ar -num $::stargen::AN_AR \
                   -symbol "Ar" -name "Argon" -weight 39.9480 -melt  84.00 \
                   -boil  87.30 -density  0.0017824 -abunde 3.16228e-06 \
                   -abunds 0.100925 -reactivity 0 \
                   -max_ipp $::stargen::MAX_AR_IPP]
    lappend gases [::stargen::ChemTable Kr -num $::stargen::AN_KR \
                   -symbol "Kr" -name "Krypton" -weight 83.8000 \
                   -melt 116.60 -boil 119.70 -density  0.003708 \
                   -abunde 1e-10 -abunds 4.4978e-05 -reactivity 0 \
                   -max_ipp $::stargen::MAX_KR_IPP]
    lappend gases [::stargen::ChemTable Xe -num $::stargen::AN_XE \
                   -symbol "Xe" -name "Xenon" -weight 131.3000 \
                   -melt 161.30 -boil 165.00 -density  0.00588 \
                   -abunde 3.16228e-11 -abunds 4.69894e-06 \
                   -reactivity 0 -max_ipp $::stargen::MAX_XE_IPP]
    lappend gases [::stargen::ChemTable NH3 -num $::stargen::AN_NH3 \
                   -symbol "NH3" -name "Ammonia" -weight 17.0000 \
                   -melt 195.46 -boil 239.66 -density  0.001 \
                   -abunde 0.002 -abunds 0.0001 -reactivity 1 \
                   -max_ipp $::stargen::MAX_NH3_IPP]
    lappend gases [::stargen::ChemTable H2O -num $::stargen::AN_H2O \
                   -symbol "H2O" -name "Water" -weight 18.0000 \
                   -melt 273.16 -boil 373.16 -density  1.000 \
                   -abunde 0.03 -abunds 0.001 -reactivity 0 \
                   -max_ipp $::stargen::INCREDIBLY_LARGE_NUMBER]
    lappend gases  [::stargen::ChemTable CO2 -num $::stargen::AN_CO2 \
                    -symbol "CO2" -name "CarbonDioxide" \
                    -weight 44.0000 -melt 194.66 -boil 194.66 \
                    -density  0.001 -abunde 0.01 -abunds 0.0005 \
                    -reactivity 0 -max_ipp $::stargen::MAX_CO2_IPP]
    lappend gases  [::stargen::ChemTable O3 -num $::stargen::AN_O3 \
                    -symbol   "O3" -name "Ozone" -weight 48.0000 \
                    -melt  80.16 -boil 161.16 -density  0.001 \
                    -abunde 0.001 -abunds 0.000001 -reactivity 2 \
                    -max_ipp $::stargen::MAX_O3_IPP]
    lappend gases [::stargen::ChemTable CH4 -num $::stargen::AN_CH4 \
                   -symbol "CH4" -name "Methane" -weight 16.0000 \
                   -melt 90.16 -boil 109.16 -density 0.010 \
                   -abunde 0.005 -abunds 0.0001 -reactivity 1 \
                   -max_ipp $::stargen::MAX_CH4_IPP]
    set gases [lsort -command ::stargen::diminishing_abundance $gases]
    variable max_gas [llength $gases]
    namespace export gases max_gas
    
    variable flag_verbose 0
    
    namespace export dust_density_coeff flag_verbose
    
    variable total_earthlike 0
    variable total_habitable 0
    
    variable	min_breathable_terrestrial_g 1000.0
    variable	min_breathable_g 1000.0
    variable	max_breathable_terrestrial_g 0.0
    variable	max_breathable_g 0.0
    variable	min_breathable_temp 1000.0
    variable	max_breathable_temp 0.0
    variable	min_breathable_p 100000.0
    variable	max_breathable_p 0.0
    variable	min_breathable_terrestrial_l 1000.0
    variable	min_breathable_l 1000.0
    variable	max_breathable_terrestrial_l 0.0
    variable	max_breathable_l 0.0
    
    namespace export total_earthlike total_habitable \
          min_breathable_terrestrial_g min_breathable_g \
          max_breathable_terrestrial_g max_breathable_g \
          min_breathable_terrestrial_l min_breathable_l \
          max_breathable_terrestrial_l max_breathable_l \
          min_breathable_temp max_breathable_temp min_breathable_p \
          max_breathable_p
    
    snit::type System {
        component sun
        delegate option * to sun
        delegate method * to sun
        typevariable flag_seed 0
        variable innermost_planet {}
        typevariable dust_density_coeff 
        typeconstructor {
            set dust_density_coeff $::stargen::DUST_DENSITY_COEFF
            namespace import ::stargen::accrete::*
            namespace import ::stargen::enviro::*
            namespace import ::stargen::utils::*
        }
        variable earthlike 0
        variable habitable 0
        variable habitable_jovians 0
        
        variable type_counts [list]
        variable type_count 0
        
        typemethod clone {sun} {
            puts stderr "*** $type clone $sun"
            ::stargen::Sun validate $sun
            set sys [$type create %AUTO% \
                     -luminosity [$sun cget -luminosity] \
                     -mass [$sun cget -mass] \
                     -life [$sun cget -life] \
                     -age [$sun cget -age] \
                     -r_ecosphere [$sun cget -r_ecosphere] \
                     -name [$sun cget -name]]
            return $sys
        }
        typemethod init {} {
            puts stderr "*** $type init"
            if {$flag_seed != 0} {
                set seed [clock seconds]
                expr {srand($seed)}
                set flag_seed [expr {rand()*0x0ffffffff}]
            }
            expr {srand($flag_seed)}
        }
        
        constructor {args} {
            puts stderr "*** $type create $self $args"
            install sun using stargen::Sun %AUTO% \
                  -luminosity [from args -luminosity 0] \
                  -mass       [from args -mass 0] \
                  -life       [from args -life 0] \
                  -age        [from args -age 0] \
                  -r_ecosphere [from args -r_ecosphere 0] \
                  -name       [from args -name]
            set type_counts [list 0 0 0 0 0 0 0 0 0 0 0 0]
            set type_count 0
        }
        destructor {
            $sun destroy
        }
        
        method generate_stellar_system {use_seed_system seed_system 
            flag_char sys_no system_name outer_planet_limit do_gases 
            do_moons} {
            puts stderr "*** $self generate_stellar_system $use_seed_system \{$seed_system\} $flag_char $sys_no $system_name $outer_planet_limit $do_gases $do_moons"
            if {([$sun cget -mass] < 0.2) || ([$sun cget -mass] > 1.5)} {
                $sun configure -mass [random_number 0.7 1.4]
            }
            set outer_dust_limit [stellar_dust_limit [$sun cget -mass]]
            if {[$sun cget -luminosity] == 0.0} {
                $sun configure -luminosity [luminosity [$sun cget -mass]]
            }
            $sun configure -r_ecosphere [expr {sqrt([$sun cget -mass])}]
            $sun configure -life [expr {1.0E10 * ([$sun cget -mass] / [$sun cget -luminosity])}]
            
        }
        method post_generate {only_habitable only_multi_habitable 
            only_jovian_habitable only_earthlike} {
            puts stderr "*** $self post_generate $only_habitable $only_multi_habitable"
            return false
        }
        method calculate_gases {planets planet_id} {
            puts stderr "*** $self calculate_gases $planets $planet_id"
        }
        method generate_planet {planet planet_no random_tilt do_gases do_moons 
            is_moon} {
            puts stderr "*** $self generate_planet $planet $planet_no $random_tilt $do_gases $do_moons $is_moon"
        }
        method generate_planets {random_tilt flag_char sys_no system_name 
            do_gases do_moons} {
            puts stderr "*** $self generate_planets $random_tilt $flag_char $sys_no $system_name $do_gases $do_moons"
        }
        
        typevariable min_mass 0.4
        typevariable inc_mass 0.05
        typevariable max_mass 2.35
        
        typemethod stargen {flag_char sys_name_arg mass_arg seed_arg count_arg 
            incr_arg cat_arg sys_no_arg ratio_arg flags_arg} {

            
            set sun_mass $mass_arg
            set sun [::stargen::Sun %AUTO% -mass $sun_mass]
            set system_count 1
            set seed_increment 1
            
            if {$cat_arg ne {} && $sys_no_arg == 0} {
                set do_catalog yes
            } else {
                set do_catalog no
            }
            set do_gases [expr {($flags_arg & $::stargen::fDoGases) != 0}]
            set use_solar_system [expr {($flags_arg & $::stargen::fUseSolarsystem) != 0}]
            set reuse_solar_system [expr {($flags_arg & $::stargen::fReuseSolarsystem) != 0}]
            set use_known_planets [expr {($flags_arg & $::stargen::fUseKnownPlanets) != 0}]
            set no_generate [expr {($flags_arg & $::stargen::fNoGenerate) != 0}]
            set do_moons [expr {($flags_arg & $::stargen::fDoMoons) != 0}]
            set only_habitable [expr {($flags_arg & $::stargen::fOnlyHabitable) != 0}]
            set only_multi_habitable [expr {($flags_arg & $::stargen::fOnlyMultiHabitable) != 0}]
            set only_jovian_habitable [expr {($flags_arg & $::stargen::fOnlyJovianHabitable) != 0}]
            set only_earthlike [expr {($flags_arg & $::stargen::fOnlyEarthlike) != 0}]
            
            if {$do_catalog} {
                set catalog_count [$cat_arg numstars]
            } else {
                set catalog_count 0
            }
            
            if {$only_habitable && $only_multi_habitable} {
                set only_habitable no
            }
            if {$only_habitable && $only_earthlike} {
                set only_habitable no
            }
            
            set flag_seed $seed_arg
            set system_count $count_arg
            set seed_increment $incr_arg
            if {$ratio_arg > 0.0} {
                set dust_density_coeff [expr {$dust_density_coeff * $ratio_arg}]
            }
            ::stargen::earth configure -mass [EM 1.0]
            
            
            if {$reuse_solar_system} {
                set system_count [expr {1 + int(($max_mass - $min_mass) / $inc_mass)}]
                $::stargen::earth configure -mass [EM $min_mass]
                $sun configure -luminosity 1.0 -mass 1.0 -life 1.0E10 \
                      -age 5.0E9 -r_ecosphere 1.0
                set use_solar_system true
            } elseif {$do_catalog} {
                set system_count [expr {$catalog_count + (($system_count - 1) * ($catalog_count - 1))}]
                set use_solar_system true
            }
            
            set result [list]
            for {set index 0} {$index < $system_count} {incr index} {
                set system_name ""
                set designation ""
                set outer_limit 0.0
                set sys_no 0
                set has_known_planets false
                set seed_planets [list]
                set use_seed_system false
                set in_celestia false

                $type init
                
                if {$do_catalog || $sys_no_arg != 0} {
                    if {$sys_no_arg != 0} {
                        set sys_no [expr {$sys_no_arg - 1}]
                    } else {
                        if {$index >= $catalog_count} {
                            set sys_no = [expr {(($index - 1) % ($catalog_count - 1)) + 1}]
                        } else {
                            set sys_no $index
                        }
                    }
                    set star [$cat_arg getstar $sys_no]
                    if {[llength [$star cget -known_planets]] > 0} {
                        set has_known_planets true
                    }
                    if {$use_known_planets || $no_generate} {
                        set seed_planets [$star cget -known_planets]
                        set use_seed_system $no_generate
                    } else {
                        set seed_planets [list]
                    }
                    set in_celestia [$star cget -in_celestia]
                    $sun configure -mass [$star cget -mass]
                    $sun configure -luminosity [$star cget -luminosity]
                    if {$do_catalog || $sys_name_arg eq ""} {
                        set system_name [$star cget -name]
                        set designation [regexp -all {_$} [namespace tail $star] {}]
                    } else {
                        set system_name $sys_name_arg
                        set designation $sys_name_arg
                    }
                    if {[$star cget -m2] > .001} {
                        #*
                        #*	The following is Holman & Wiegert's equation 1 from
                        #*	Long-Term Stability of Planets in Binary Systems
                        #*	The Astronomical Journal, 117:621-628, Jan 1999
                        #*
                        set m1 [$sun cget -mass]
                        set m2 [$star cget -m2]
                        set mu [expr {$m2 / ($m1 + $m2)}]
                        set e  [$star cget -e]
                        set a  [$star cget -a]
                        
                        set outer_limit [expr {(0.464 + (-0.380 * $mu) + (-0.631 * $e) + \
                                                (0.586 * $mu * $e) + (0.150 * pow2($e)) + \
                                                (-0.198 * $mu * pow2($e))) * $a}]
                    } else {
                        set outer_limit 0.0
                    }
                } elseif {$reuse_solar_system} {
                    set system_name [format "Earth-M%lG" [expr {[$::stargen::earth cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
                    set designation [format "Earth-M%lG" [expr {[$::stargen::earth cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
                    set outer_limit 0.0
                } else {
                    if {$sys_name_arg ne ""} {
                        set system_name $sys_name_arg
                        set designation $sys_name_arg
                    } else {
                        set system_name [format {%s %ld-%lG} \
                                         [file rootname [file tail [info script]]] \
                                         $flag_seed [$sun cget -mass]]
                        set designation [file rootname [file tail [info script]]]
                    }
                    set outer_limit 0.0
                }
                $sun configure -name $system_name
                set earthlike 0
                set habitable 0
                set habitable_jovians 0
                if {$reuse_solar_system} {
                    set seed_planets $::stargen::solar_system
                    set use_seed_system true
                } elseif {$use_solar_system} {
                    if {$index == 0} {
                        set seed_planets $::stargen::solar_system
                        set use_seed_system true
                    } else {
                        set use_seed_system false
                        if {!$use_known_planets} {
                            set seed_planets [list]
                        }
                    }
                }
                
                set system [$type clone $sun]
                $system generate_stellar_system  $use_seed_system \
                      $seed_planets $flag_char $sys_no $system_name \
                      $outer_limit $do_gases $do_moons
                if {[$system post_generate $only_habitable \
                     $only_multi_habitable $only_jovian_habitable \
                     $only_earthlike]} {
                    lappend result $system
                } else {
                    $system destroy
                }
                
            }
            $sun destroy
            return $result
        }
    }
    namespace export System
}    
    


