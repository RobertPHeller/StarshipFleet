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
#  Last Modified : <160427.1045>
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
    Planets_Record charon -planet_no 1 -a [expr {19571/$::stargen::KM_PER_AU}] -e 0.000 -axial_tilt  0   \
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
    
    
    snit::type System {
        component sun
        delegate option * to sun
        delegate method * to sun
        typevariable flag_seed 0
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
        typevariable total_earthlike 0
        typevariable total_habitable 0
    
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
            
            if {$use_seed_system} {
                $sun setplanets [::stargen::PlanetList copy $seed_system no]
                $sun configure -age 5.0E9
            } else {
                set min_age 1.0E9
                set max_age 6.0E9
                if {[$sun cget -life] < $max_age} {
                    set max_age [$sun cget -life]
                }
                $sun setplanets [dist_planetary_masses \
                                      [$sun cget -mass] \
                                      [$sun cget -luminosity] \
                                      0.0 $outer_dust_limit \
                                      $outer_planet_limit \
                                      $dust_density_coeff \
                                      $seed_system \
                                      $do_moons]
                $sun configure -age [random_number $min_age $max_age]
            }
            $self generate_planets [expr {!$use_seed_system}] $flag_char \
                  $sys_no $system_name $do_gases $do_moons
        }
        method post_generate {only_habitable only_multi_habitable 
            only_jovian_habitable only_earthlike index use_solar_system 
            reuse_solar_system} {
            puts stderr "*** $self post_generate $only_habitable $only_multi_habitable"
            
            set wt_type_count $type_count
            set norm_type_count 0
		
            if {[lindex $type_counts 3]  > 0} {
                incr wt_type_count 20;#	// Terrestrial
            }
            if {[lindex $type_counts 8]  > 0} {
                incr wt_type_count 18;#	// Water
            }
            if {[lindex $type_counts 2]  > 0} {
                incr wt_type_count 16;#	// Venusian
            }
            if {[lindex $type_counts 7]  > 0} {
                incr wt_type_count 15;#	// Martian
            }
            if {[lindex $type_counts 9]  > 0} {
                incr wt_type_count 14;#	// Ice
            }
            if {[lindex $type_counts 10] > 0} {
                incr wt_type_count 13;#	// Asteroids
            }
            if {[lindex $type_counts 4]  > 0} {
                incr wt_type_count 12;#	// Gas Dwarf
            }
            if {[lindex $type_counts 5]  > 0} {
                incr wt_type_count 11;#	// Sub_Jovian
            }
            if {[lindex $type_counts 11] > 0} {
                incr wt_type_count 10;#	// 1-Face
            }
            if {[lindex $type_counts 1]  > 0} {
                incr wt_type_count 3;#		// Rock
            }
            if {[lindex $type_counts 6]  > 0} {
                incr wt_type_count 2;#		// Jovian
            }
            if {[lindex $type_counts 0]  > 0} {
                incr wt_type_count 1;#		// Unknown
            }
            
            set counter [$sun planetcount]
			
            set norm_type_count [expr {$wt_type_count - ($counter - $type_count)}]
			
            if {$max_type_count < $norm_type_count} {
                set max_type_count $norm_type_count
		
                if {($::stargen::flag_verbose & 0x10000) != 0} {
                    puts stderr [format "System %ld - %s (-s%ld -%c%d) has %d types out of %d planets. [%d]" \
                                 $flag_seed \
                                 $system_name \
                                 $flag_seed \
                                 $flag_char \
                                 $sys_no \
                                 $type_count \
                                 $counter \
                                 $norm_type_count]
                }
            }

            incr total_habitable $habitable
            incr total_earthlike $earthlike
        
            set result false
        
            if {(!($only_habitable || $only_multi_habitable || $only_jovian_habitable || $only_earthlike))
                || ($only_habitable && ($habitable > 0))
                || ($only_multi_habitable && ($habitable > 1))
                || ($only_jovian_habitable && ($habitable_jovians > 0)) 
                || ($only_earthlike && ($earthlike > 0))} {
                
                set result true
                
                if {($habitable > 1) && ($::stargen::flag_verbose & 0x0001) != 0} {
                    puts stderr "System %ld - %s (-s%ld -%c%d) has %d planets with breathable atmospheres." \
                          $flag_seed \
                          $system_name \
                          $flag_seed \
                          $flag_char \
                          $sys_no \
                          $habitable]
                }
            }

        
            if {! (($use_solar_system) && ($index == 0))} {
                incr flag_seed $seed_increment
            }
        
            if {$reuse_solar_system} {
                $::stargen::earth configure -mass \
                      [expr {[$::stargen::earth cget -mass] + [EM $inc_mass]}]
            }
            #// Free the dust and planets created by accrete:
            free_generations

            if {($::stargen::flag_verbose & 0x0001) != 0 || ($::stargen::flag_verbose & 0x0002) != 0} {
                puts stderr [format "Earthlike planets: %d" $total_earthlike]
                puts stderr [format "Breathable atmospheres: %d" $total_habitable]
                puts stderr [format "Breathable g range: %4.2lf -  %4.2lf" \
                             $min_breathable_g \
                             $max_breathable_g]
                puts stderr [format "Terrestrial g range: %4.2lf -  %4.2lf" \ 
                             $min_breathable_terrestrial_g \
                             $max_breathable_terrestrial_g]
                puts stderr [format "Breathable pressure range: %4.2lf -  %4.2lf" \
                             $min_breathable_p \
                             $max_breathable_p]
                puts stderr [format "Breathable temp range: %+.1lf C -  %+.1lf C" \
                             [expr {$min_breathable_temp - $::stargen::EARTH_AVERAGE_KELVIN}] \
                             [expr {$max_breathable_temp - $::stargen::EARTH_AVERAGE_KELVIN}]]
                puts stderr [format "Breathable illumination range: %4.2lf -  %4.2lf" \
                             $min_breathable_l \
                             $max_breathable_l]
                puts stderr [format "Terrestrial illumination range: %4.2lf -  %4.2lf" \
                             $min_breathable_terrestrial_l \
                             $max_breathable_terrestrial_l]
                puts stderr [format "Max moon mass: %4.2lf" \
                             [expr {$max_moon_mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
            }
            
            return $result
        }
        proc listdoubles {n} {
            set result [list]
            for {set i 0} {$i < $n} {incr  i} {
                lappend result 0.0
            }
            return $result
        }
        method calculate_gases {planets planet_id} {
            puts stderr "*** $self calculate_gases $planets $planet_id"
            if {[$planet cget -surf_pressure] > 0} {
                set amount [listdoubles [expr {$::stargen::max_gas + 1}]]
		set totamount 0.0
                set pressure [expr {[$planet cget -surf_pressure] / $::stargen::MILLIBARS_PER_BAR}]
                set n ;
                for {set i 0} {$i < $::stargen::max_gas} {incr i} {
                    set yp [expr {[[lindex $::stargen::gases $i] cget -boil] / \
                            (373. * ((log(($pressure) + 0.001) / -5050.5) + \
                                     (1.0 / 373.)))}]
                    if {($yp >= 0 && $yp < [$planet cget -low_temp])
                        && ([[lindex $::stargen::gases $i] cget -weight] >= [$planet cget -molec_weight])} {
                        set vrms [rms_vel \
                                  [[lindex $::stargen::gases $i] cget -weight] \
                                  [$planet cget -exospheric_temp]]
                        set pvrms [expr {pow(1 / (1 + $vrms / [$planet cget -esc_velocity]), [$sun cget -age] / 1e9)}]
                        set abund [[lindex $::stargen::gases $i] cget -abunds];# /* gases[i].abunde */
                        set react 1.0
                        set fract 1.0
                        set pres2 1.0
			
                        if {[[lindex $::stargen::gases $i] -symbol] eq "Ar"} {
                            set react [expr {.15 * [$sun cget -age]/4e9}]
                        } elseif {[[lindex $::stargen::gases $i] -symbol] eq "He"} {
                            set abund [expr {$abund * (0.001 + ([$planet cget -gas_mass] / [$planet cget -mass]))}]
                            set pres2 [expr {(0.75 + $pressure)}]
                            set react [expr {pow(1 / (1 + [[lindex $::stargen::gases $i] cget -reactivity]), [$sun cget -age]/2e9 * $pres2)}]
                        } elseif {([[lindex $::stargen::gases $i] -symbol] eq "O" ||
                                   [[lindex $::stargen::gases $i] -symbol] eq "O2") && 
                                  [$sun cget -age] > 2e9 &&
                                  [$planet cget -surf_temp] > 270 && [$planet cget -surf_temp] < 400} {
                            #/*	pres2 = (0.65 + pressure/2);			Breathable - M: .55-1.4 	*/
                            set pres2 [expr {(0.89 + $pressure/4.0)}];#		/*	Breathable - M: .6 -1.8 	*/
                            set react [expr {pow(1 / (1 + [[lindex $::stargen::gases $i] cget -reactivity]), \
                                                       pow([$sun cget -age]/2e9, 0.25) * $pres2)}]
                        } elseif {[[lindex $::stargen::gases $i] -symbol] eq "CO2" && 
                                  [$sun cget -age] > 2e9 &&
                                  [$planet cget -surf_temp] > 270 && [$planet cget -surf_temp] < 400} {
                            set pres2 [expr {(0.75 + pressure)}]
                            set react [expr {pow(1 / (1 + [[lindex $::stargen::gases $i] cget -reactivity]), \
                                                 pow([$sun cget -age]/2e9, 0.5) * $pres2)}]
                            set react [expr {$react * 1.5}]
                        } else {
                            set pres2 [expr {(0.75 + $pressure)}]
                            set react [expr {pow(1 / (1 + [[lindex $::stargen::gases $i] cget -reactivity]), \
                                                 [expr $sun cget -age]/2e9 * $pres2)}]
                        }
                        
                        set fract [expr {(1 - ([$planet cget -molec_weight] / [[lindex $::stargen::gases $i] cget -weight]))}]
                        
                        lset amount $i [expr {$abund * $pvrms * $react * $fract}]
                        
                        if {($::stargen::flag_verbose & 0x4000) != 0 &&
                            ([[lindex $::stargen::gases $i] cget -symbol] eq "O" ||
                             [[lindex $::stargen::gases $i] cget -symbol] eq "N" ||
                             [[lindex $::stargen::gases $i] cget -symbol] eq "Ar" ||
                             [[lindex $::stargen::gases $i] cget -symbol] eq "He" ||
                             [[lindex $::stargen::gases $i] cget -symbol] eq "CO2)} {
                            puts stderr [format {%-5.2lf %-3.3s, %-5.2lf = a %-5.2lf * p %-5.2lf * r %-5.2lf * p2 %-5.2lf * f %-5.2lf\t(%.3lf%%)}  \
                                         [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                         [[lindex $::stargen::gases $i] cget -symbol] \
                                         [lindex $amount $i] \
                                         $abund \
                                         $pvrms \
                                         $react \
                                         $pres2 \
                                         $fract \
                                         [expr {100.0 * ([$planet cget -gas_mass] / [$planet cget -mass])}] ]
                        }

                        set totamount [expr {$totamount + [lindex $amount $i]}]
                        if {[lindex $amount $i] > 0.0} {n++;}
                    } else {
                        lset amount $i 0.0
                    }
                }

		if {$n > 0} {
                    set atmospherelist [list]
                    
                    for {set i 0} {$i < $::stargen::max_gas} {incr i++} {
                        if {[lindex $amount $i] > 0.0} {
                            lappend atmospherelist \
                                  [::stargen::Gas %AUTO% \
                                   -num [[lindex $::stargen::gases $i] cget -num] \
                                   -surf_pressure [expr {[$planet cget -surf_pressure] \ 
                                                   * [lindex $amount $i] / $totamount}]
                            
                            if {($::stargen::flag_verbose & 0x2000) != 0} {
                                if {[[lindex $atmospherelist end] cget -num] == $::stargen::AN_O) && \
                                    [inspired_partial_pressure \
                                     [$planet cget -surf_pressure] \
                                     [[lindex $atmospherelist end] cget -surf_pressure]] \
                                    > [[lindex $::stargen::gases $i] cget -max_ipp]} {
                                    puts stderr [format "%s\t Poisoned by O2" planet_id]
                                }
                            }
                            
                        }
                    }
                    
                    $planet configure \
                          -atmosphere [lsort \
                                       -command ::stargen::diminishing_pressure \
                                       $atmospherelist]
                    
                    if {($::stargen::flag_verbose & 0x0010) != 0} {
                        puts stderr [format  "\n%s (%5.1lf AU) gases:" \
                                     $planet_id [$planet cget -a]]
                        
                        foreach agas [$planet cget -atmosphere] {
                            puts stderr [format "%3d: %6.1lf, %11.7lf%%" \
                                         [$agas cget -num] \
                                         [$agas cget -surf_pressure] \
                                         [expr {100. * ([$agas cget -surf_pressure] / \
                                                        [$planet cget -surf_pressure])}]]
                        }
                    }
		}
		
            }
            
        }
        method generate_planet {planet planet_no random_tilt planet_id 
            do_gases do_moons is_moon} {
            puts stderr "*** $self generate_planet $planet $planet_no $random_tilt $planet_id $do_gases $do_moons $is_moon"
            $planet configure -atmosphere {}
            $planet configure -surf_temp  0
            $planet configure -high_temp  0
            $planet configure -low_temp	  0
            $planet configure -max_temp	  0
            $planet configure -min_temp	  0
            $planet configure -greenhs_rise 0
            $planet configure -planet_no $planet_no
            $planet configure -sun	 $sun
            $planet configure -resonant_period  false
            
            $planet configure -orbit_zone [orb_zone \
                                           [$sun cget -luminosity] \
                                           [$planet cget -a]]
            
            $planet configure -orb_period [period \
                                           [$planet cget -a] \
                                           [$planet cget -mass] \
                                           [$sun cget -mass]]
            if {$random_tilt} {
                $planet configure -axial_tilt [inclination [$planet cget -a]]
            }
            $planet configure -exospheric_temp [expr {$::stargen::EARTH_EXOSPHERE_TEMP / pow2([$planet cget -a] / [$sun cget -r_ecosphere])}]
            $planet configure -rms_velocity    [rms_vel \
                                                $::stargen::MOL_NITROGEN \
                                                [$planet cget -exospheric_temp]]
            $planet configure -core_radius     [kothari_radius \
                                                [$planet cget -dust_mass] \
                                                false \
                                                [$planet cget -orbit_zone]]
            
            #// Calculate the radius as a gas giant, to verify it will retain gas.
            #// Then if mass > Earth, it's at least 5% gas and retains He, it's
            #// some flavor of gas giant.
            
            $planet configure -density 	    [empirical_density \
                                             [$planet cget -mass] \
                                             [$planet cget -a] \
                                             [$sun cget -r_ecosphere] \
                                             true]
            $planet configure -radius 	    [volume_radius \
                                             [$planet cget -mass] \
                                             [$planet cget -density]]
            
            $planet configure -surf_accel   [acceleration \
                                             [$planet cget -mass] \
                                             [$planet cget -radius]]
            $planet configure -surf_grav    [gravity [$planet cget -surf_accel]]
            
            $planet configure -molec_weight [min_molec_weight $planet]
            
            if {(([$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES) > 1.0)
                && (([$planet cget -gas_mass] / [$planet cget -mass])        > 0.05)
                && ([min_molec_weight $planet]				  <= 4.0)} {
                if {([$planet cget -gas_mass] / [$planet cget -mass]) < 0.20} {
                    $planet configure -type  tSubSubGasGiant
                } elseif {([$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES) < 20.0} {
                    $planet configure -type  tSubGasGiant
                } else {
                    $planet configure -type  tGasGiant
                }
            } else { #// If not, it's rocky.
                $planet configure -radius    [kothari_radius \
                                              [$planet cget -mass] \
                                              false \
                                              [$planet cget -orbit_zone]]
                $planet configure -density   [volume_density \
                                              [$planet cget -mass] \
                                              [$planet cget -radius]]
                
                $planet configure -surf_accel [acceleration \
                                               [$planet cget -mass] \
                                               [$planet cget -radius]]
                $planet configure -surf_grav [gravity \
                              [$planet cget -surf_accel]]
                
                if {([$planet cget -gas_mass] / [$planet cget -mass]) > 0.000001} {
                    set h2_mass [expr {[$planet cget -gas_mass] * 0.85}]
                    set he_mass [expr {([$planet cget -gas_mass] - $h2_mass) * 0.999}]
                    
                    set h2_loss 0.0
                    set he_loss 0.0
                    
                    
                    set h2_life [gas_life $::stargen::MOL_HYDROGEN $planet]
                    set he_life [gas_life $::stargen::HELIUM $planet]
                    
                    if {$h2_life < [$sun cget -age]} {
                        set h2_loss [expr {((1.0 - (1.0 / exp([$sun cget -age] / $h2_life))) * $h2_mass)}]
                        
                        $planet configure -gas_mass [expr {[$planet cget -gas_mass] - $h2_loss}]
                        $planet configure -mass     [expr {[$planet cget -mass] - $h2_loss}]
                        
                        $planet configure -surf_accel [acceleration \
                                                       [$planet cget -mass] \
                                                       [$planet cget -radius]]
                        $planet configure -surf_grav  [gravity \
                                                       [$planet cget -surf_accel]]
                    }
                    
                    if {$he_life < [$sun cget -age]} {
                        set he_loss [expr {((1.0 - (1.0 / exp([$sun cget -age] / $he_life))) * $he_mass)}]
                        
                        $planet configure -gas_mass [expr {[$planet cget -gas_mass] - $he_loss}]
                        $planet configure -mass     [expr {[$planet cget -mass]- $he_loss}]
                        
                        $planet configure -surf_accel [acceleration \
                                                       [$planet cget -mass] \
                                                       [$planet cget -radius]]
                        $planet configure -surf_grav  [gravity \
                                                       [$planet cget -surf_accel]]
                    }
                    
                    if {(($h2_loss + $he_loss) > .000001) && 
                        ($::stargen::flag_verbose & 0x0080) != 0} {
                        puts stderr [format \
                                     "%s\tLosing gas: H2: %5.3lf EM, He: %5.3lf EM" \
                                     $planet_id \
                                     [expr {$h2_loss * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     [expr {$he_loss * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
                    }
                }
            }
            $planet configure -day [day_length $planet];#	/* Modifies planet->resonant_period */
            $planet configure -esc_velocity [escape_vel \
                                             [$planet cget -mass] \
                                             [$planet cget -radius]]
            
            if {([$planet cget -ptype eq "tGasGiant")
                || ([$planet cget -ptype eq "tSubGasGiant") 
                || ([$planet cget -ptype eq "tSubSubGasGiant")} {
                $planet configure -greenhouse_effect 	  false
                $planet configure -volatile_gas_inventory $::stargen::INCREDIBLY_LARGE_NUMBER
                $planet configure -surf_pressure 	  $::stargen::INCREDIBLY_LARGE_NUMBER
                
                $planet configure -boil_point 		  $::stargen::INCREDIBLY_LARGE_NUMBER
                
                $planet configure -surf_temp		  $::stargen::INCREDIBLY_LARGE_NUMBER
                $planet configure -greenhs_rise 	  0
                $planet configure -albedo 		  [about $::stargen::GAS_GIANT_ALBEDO 0.1]
                $planet configure -hydrosphere 		  1.0
                $planet configure -cloud_cover	 	  1.0
                $planet configure -ice_cover	 	  0.0
                $planet configure -surf_grav		  [gravity \
                                                           [$planet cget -surf_accel]]
                $planet configure -molec_weight		  [min_molec_weight $planet]
                $planet configure -surf_grav 		  $::stargen::INCREDIBLY_LARGE_NUMBER
                $planet configure -estimated_temp	  [est_temp \
                                                           [$sun cget -r_ecosphere] \
                                                           [$planet cget -a] \
                                                           [$planet cget -albedo]]
                $planet configure -estimated_terr_temp	  [est_temp \
                                                           [$sun cget -r_ecosphere] \
                                                           [$planet cget -a] \
                                                           $::stargen::EARTH_ALBEDO]
                
                set temp [$planet cget -estimated_terr_temp]
                    
                if {($temp >= $::stargen::FREEZING_POINT_OF_WATER)
                    && ($temp <= $::stargen::EARTH_AVERAGE_KELVIN + 10.)
                    && ([$sun cget -age] > 2.0E9)} {
                    incr habitable_jovians++
                        
                    if {($::stargen::flag_verbose & 0x8000) != 0} {
                        puts stderr [format \
                                     "%s\t%s (%4.2lfEM %5.3lf By)%s with earth-like temperature (%.1lf C, %.1lf F, %+.1lf C Earth)." \
                                     $planet_id \
                                     [expr {[$planet cget -ptype] eq "tGasGiant" ? "Jovian" :
                                             [$planet cget -ptype] eq "tSubGasGiant" ? "Sub-Jovian" :
                                              [$planet cget -ptype] eq "tSubSubGasGiant" ? "Gas Dwarf" :
                                               "Big"}] \
                                     [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     [expr {[$sun cget -age] /1.0E9}] \
                                     [expr {[llength [$planet cget -moons]] == 0 ? "" : " WITH MOON"}] \
                                     [expr {$temp - $::stargen::FREEZING_POINT_OF_WATER}] \
                                     [expr {32 + (($temp - $::stargen::FREEZING_POINT_OF_WATER) * 1.8)}] \
                                     [expr {$temp - $::stargen::EARTH_AVERAGE_KELVIN}]]
                    }
                }
            } else {
                $planet configure -estimated_temp	[est_temp \
                                                         [$sun cget -r_ecosphere] \
                                                         [$planet cget -a] \
                                                         $::stargen::EARTH_ALBEDO]
                $planet configure -estimated_terr_temp	[est_temp \
                                                         [$sun cget -r_ecosphere] \
                                                         [$planet cget -a] \
                                                         $::stargen::EARTH_ALBEDO]
                
                $planet configure -surf_grav 		[gravity \
                                                         [$planet cget -surf_accel]]
                $planet configure -molec_weight		[min_molec_weight \
                                                         $planet]
                
                $planet configure -greenhouse_effect 	[grnhouse \
                                                         [$sun cget -r_ecosphere] \
                                                         [$planet cget -a]]
                $planet configure -volatile_gas_inventory [vol_inventory \
                                                           [$planet cget -mass] \
                                                           [$planet cget -esc_velocity] \
                                                           [$planet cget -rms_velocity] \
                                                           [$sun cget -mass] \
                                                           [$planet cget -orbit_zone] \
                                                           [$planet cget -greenhouse_effect] \
                                                           [expr {([$planet cget -gas_mass]
                                                                   / [$planet cget -mass]) > 0.000001}]]
                $planet configure -surf_pressure 	[pressure \
                                                         [$planet cget -volatile_gas_inventory] \
                                                         [$planet cget -radius] \
                                                         [$planet cget -surf_grav]]

                if {([$planet cget -surf_pressure] == 0.0)} {
                    $planet configure -boil_point 0.0
                } else {
                    $planet configure -boil_point [boiling_point \
                                                   [$planet cget -surf_pressure]]
                }
                iterate_surface_temp $planet;# /*	Sets:
                                             #  *		planet->surf_temp
                                             #  *		planet->greenhs_rise
                                             #  *		planet->albedo
                                             #  *		planet->hydrosphere
                                             #  *		planet->cloud_cover
                                             #  *		planet->ice_cover
                                             #  */

                if {$do_gases &&
                    ([$planet cget -max_temp] >= $::stargen::FREEZING_POINT_OF_WATER) &&
                    ([$planet cget -min_temp] <= [$planet cget -boil_point])} {
                    calculate_gases $sun $planet $planet_id
                }
                #/*
                # *	Next we assign a type to the planet.
                # */
                
                if {[$planet cget -surf_pressure] < 1.0} {
                    if {!$is_moon
                        && (([$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES) < $::stargen::ASTEROID_MASS_LIMIT)} {
                        $planet configure -ptype  tAsteroids
                    } else {
                        $planet configure -ptype  tRock
                    }
                } elseif {([$planet cget -surf_pressure] > 6000.0) &&
                    ([$planet cget -molec_weight] <= 2.0)} {	#// Retains Hydrogen
                    $planet configure -ptype  tSubSubGasGiant
                    $planet configure -gases  0
                    set olda [$planet cget -atmosphere]
                    foreach g $olda {$g destroy}
                    unset olda
                    $planet configure -atmosphere {}
                } else {#	// Atmospheres:
                    if {(int([$planet cget -day]) == int([$planet cget -orb_period] * 24.0)) || 
                        [$planet cget -resonant_period]} {
                        $planet configure -ptype  t1Face
                    } elseif {[$planet cget -hydrosphere] >= 0.95} {
                        $planet configure -ptype tWater;#	// >95% water
                    } elseif {[$planet cget -ice_cover] > 0.95} {
                        $planet configure -ptype  tIce;#	// >95% ice
                    } elseif {[$planet cget -hydrosphere] > 0.05} {
                        $planet configure -ptype  tTerrestrial;#// Terrestrial
                        #// else <5% water
                    } elseif {[$planet cget -max_temp] > [$planet cget -boil_point]} {
                        $planet configure -ptype  tVenusian;#// Hot = Venusian
                    } elseif {([$planet cget -gas_mass] / [$planet cget -mass]) > 0.0001} {										// Accreted gas
                        $planet configure -ptype  tIce;#// But no Greenhouse
                        $planet configure -ice_cover  1.0;#	// or liquid water
                        # // Make it an Ice World
                    } elseif {[$planet cget -surf_pressure] <= 250.0} {#// Thin air = Martian
                        $planet configure -ptype  tMartian
                    } elseif {[$planet -surf_temp] < $::stargen::FREEZING_POINT_OF_WATER} {
                        $planet configure -ptype  tIce
                    } else {
                        $planet configure -ptype  tUnknown
                        
                        if {($::stargen::flag_verbose & 0x0001) != 0} {
                            puts stderr [format "%12s\tp=%4.2lf\tm=%4.2lf\tg=%4.2lf\tt=%+.1lf\t%s\t Unknown %s" \ 
                                         [type_string [$planet cget -ptype]] \
                                         [$planet cget -surf_pressure] \
                                         [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                         [$planet cget -surf_grav] \
                                         [expr {[$planet cget -surf_temp]  - $::stargen::EARTH_AVERAGE_KELVIN}] \
                                         $planet_id \
                                         [expr {(int([$planet cget -day]) == int([$planet cget -orb_period] * 24.0) || 
                                                 ([$planet cget -resonant_period])) ? "(1-Face)" : ""}]]
                        }
                    }
                }
            }
            if {$do_moons && !$is_moon} {
                if {[llength [$planet cget -moons]] != 0} {
                    set n 0
                    foreach ptr [$planet cget -moons] {
                        if {[$ptr cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES > .000001} {
                            set roche_limit 0.0
                            set hill_sphere 0.0
                            
                            $ptr configure -a [$planet cget -a]
                            $ptr configure -e [$planet cget -e]
                               
                            incr n
                            
                            set moon_id [format "%s.%d" $planet_id $n]
                            
                            $self generate_planet $ptr $n $random_tilt \
                                  $moon_id $do_gases $do_moons true;#	// Adjusts ptr->density
                               
                            set roche_limit [expr {2.44 * [$planet cget -radius] * pow(([$planet cget -density] / [$ptr cget -density]), (1.0 / 3.0))}]
                            set hill_sphere [expr {[$planet cget -a] * $::stargen::KM_PER_AU * pow(([$planet cget -mass] / (3.0 * [$sun cget -mass])), (1.0 / 3.0))}]
                            
                            if {($roche_limit * 3.0) < $hill_sphere} {
                                $ptr configure -moon_a \
                                      [expr {[random_number \
                                              [expr {$roche_limit * 1.5}] \
                                              [expr {$hill_sphere / 2.0}]] / $::stargen::KM_PER_AU}]
                                    $ptr configure -moon_e [random_eccentricity]
                                } else {
                                    $ptr configure -moon_a 0
                                    $ptr configure -moon_e 0
                                }
                                
                                if {($::stargen::flag_verbose & 0x40000) != 0} {
                                    puts stderr \
                                          [format "   Roche limit: R = %4.2lg, rM = %4.2lg, rm = %4.2lg -> %.0lf km\n   Hill Sphere: a = %4.2lg, m = %4.2lg, M = %4.2lg -> %.0lf km\n   %s Moon orbit: a = %.0lf km, e = %.0lg" \
                                           [$planet cget -radius] \
                                           [$planet cget -density] \
                                           [$ptr -density] \
                                           $roche_limit \
                                           [expr {[$planet cget -a] * $::stargen::KM_PER_AU}] \
                                           [expr {[$planet cget -mass] * $::stargen::SOLAR_MASS_IN_KILOGRAMS}] \
                                           [expr {[$sun cget -mass] * $::stargen::SOLAR_MASS_IN_KILOGRAMS}] \
                                           $hill_sphere \
                                           $moon_id \
                                           [expr {[$ptr -moon_a] * $::stargen::KM_PER_AU}] \
                                           [$ptr cget -moon_e]]
                                }
                            }

                            if {($::stargen::flag_verbose & 0x1000) != 0} {
                                puts stderr [format "  %s: (%7.2lfEM) %d %4.2lgEM" \
                                             $planet_id \
                                             [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                             $n \
                                             [expr {[$ptr cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
                            }
                    }
                }
            }
        }
        method check_planet {planet planet_id is_moon} {
            puts stderr "*** $self check_planet $planet $planet_id $is_moon"
            set tIndex 0
	
            switch [$planet cget -ptype] {
                tUnknown         {set tIndex 0}
		tRock    	 {set tIndex 1}
		tVenusian:	 {set tIndex 2}
		tTerrestrial:	 {set tIndex 3}
		tSubSubGasGiant: {set tIndex 4}
		tSubGasGiant:	 {set tIndex 5}
		tGasGiant:	 {set tIndex 6}
		tMartian:	 {set tIndex 7}
		tWater:		 {set tIndex 8}
		tIce:		 {set tIndex 9}
		tAsteroids: 	 {set tIndex 10}
		t1Face:		 {set tIndex 11}
            }
		
            if {[lindex $type_counts $tIndex] == 0} {
                incr type_count
            }
		
	    lset type_counts $tIndex [expr {[lindex $type_counts $tIndex] + 1}]
		
            
            #/* Check for and list planets with breathable atmospheres */
	
            set breathe [breathability $planet]
		
            if {($breathe == $::stargen::enviro::BREATHABLE) &&
                (![$planet cet -resonant_period]) &&	#	// Option needed?
                (int([$planet cget -day]) != int([$planet cget -orb_period] * 24.0))} {
                set list_it false
                set illumination [expr {pow2 (1.0 / [$planet cget -a]) 
                                  * [[$planet cget -sun] cget -luminosity]}]
                
                incr habitable
                
                if {$min_breathable_temp > [$planet cget -surf_temp]} {
                    set min_breathable_temp [$planet cget -surf_temp]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {$max_breathable_temp < [$planet cget -surf_temp]} {
                    set max_breathable_temp [$planet cget -surf_temp]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
		
                if {$min_breathable_g > [$planet cget -surf_grav]} {
                    set min_breathable_g [$planet cget -surf_grav]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {$max_breathable_g < [$planet cget -surf_grav]} {
                    set max_breathable_g [$planet cget -surf_grav]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {$min_breathable_l > $illumination} {
                    set min_breathable_l $illumination
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {$max_breathable_l < $illumination} {
                    set max_breathable_l $illumination
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {[$planet cget -ptype] eq "tTerrestrial"} {
                    if {$min_breathable_terrestrial_g > [$planet cget -surf_grav]} {
                        set min_breathable_terrestrial_g [$planet cget -surf_grav]
                        
                        if {($::stargen::flag_verbose & 0x0002) != 0} {
                            set list_it true
                        }
                    }
                    
                    if {$max_breathable_terrestrial_g < [$planet cget -surf_grav]} {
                        set max_breathable_terrestrial_g [$planet cget -surf_grav]
                        
                        if {($::stargen::flag_verbose & 0x0002) != 0} {
                            set list_it true
                        }
                    }
                    
                    if {$min_breathable_terrestrial_l > $illumination} {
                        set min_breathable_terrestrial_l $illumination
                        
                        if {($::stargen::flag_verbose & 0x0002) != 0} {
                            set list_it true
                        }
		    }
                    
                    if {$max_breathable_terrestrial_l < $illumination} {
                        set max_breathable_terrestrial_l $illumination;
                        
                        if {($::stargen::flag_verbose & 0x0002) != 0} {
                            set list_it true
                        }
                    }
                }
                
                if {$min_breathable_p > [$planet cget -surf_pressure]} {
                    set min_breathable_p [$planet cget -surf_pressure]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {$max_breathable_p < [$planet cget -surf_pressure]} {
                    set max_breathable_p [$planet cget -surf_pressure]
                    
                    if {($::stargen::flag_verbose & 0x0002) != 0} {
                        set list_it true
                    }
                }
                
                if {($::stargen::flag_verbose & 0x0004) != 0} {
                    set list_it true
                }
                
                if {$list_it} {
                    puts stderr [format "%12s\tp=%4.2lf\tm=%4.2lf\tg=%4.2lf\tt=%+.1lf\tl=%4.2lf\t%s" \
                                 [type_string [$planet cget -ptype]] \
                                 [$planet cget -surf_pressure] \
                                 [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                 [$planet cget -surf_grav] \
                                 [expr {[$planet cget -surf_temp]  - $::stargen::EARTH_AVERAGE_KELVIN}] \
                                 $illumination \
                                 $planet_id]
                }
            }
            
            if {$is_moon  && $max_moon_mass < [$planet cget -mass]} {
                set max_moon_mass [$planet cget -mass]
            
                if {($::stargen::flag_verbose & 0x0002) != 0} {
                    puts stderr [format "%12s\tp=%4.2lf\tm=%4.2lf\tg=%4.2lf\tt=%+.1lf\t%s Moon Mass" \
                                 [type_string [$planet cget -ptype]] \
                                 [$planet cget -surf_pressure] \
                                 [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                 [$planet cget -surf_grav] \
                                 [expr {[$planet cget -surf_temp]  - $::stargen::EARTH_AVERAGE_KELVIN}] \
                                 $planet_id);
                }
        
                if {(($::stargen::flag_verbose & 0x0800) != 0)
                     && ([$planet cget -dust_mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES >= 0.0006)
                     && ([$planet cget -gas_mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES >= 0.0006)
                     && ([$planet cget -ptype] ne "tGasGiant") 
                     && ([$planet cget -ptype] ne "tSubGasGiant")} {
                     set core_size [expr {int(((50. * [$planet cget -core_radius]) / [$planet cget -radius]))}]
            
                     if {$core_size <= 49} {
                         puts stderr [format "%12s\tp=%4.2lf\tr=%4.2lf\tm=%4.2lf\t%s\t%d" \
                                      [type_string [$planet cget -ptype]] \
                                      [$planet cget -core_radius] \
                                      [$planet cget -radius] \
                                      [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                      $planet_id \
                                      [expr {50-$core_size}]]
                     }
                }
	
                set rel_temp [expr {([$planet cget -surf_temp] -  $::stargen::FREEZING_POINT_OF_WATER) -
                              $::stargen::EARTH_AVERAGE_CELSIUS}]
		set seas       [expr {([$planet cget -hydrosphere] * 100.0)}]
		set clouds     [expr {([$planet cget -cloud_cover] * 100.0)}]
		set pressure   [expr {([$planet cget -surf_pressure] / 
                                       $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)}]
		set ice        [expr {([$planet cget -ice_cover] * 100.0)}]
		set gravity    [$planet cget -surf_grav]
		set breathe    [breathability $planet]
	
		if {($gravity 	>= .8) &&
                    ($gravity 	<= 1.2) &&
                    ($rel_temp 	>= -2.0) &&
                    ($rel_temp 	<= 3.0) &&
                    ($ice 		<= 10.) &&
                    ($pressure   >= 0.5) &&
                    ($pressure   <= 2.0) &&
                    ($clouds		>= 40.) &&
                    ($clouds		<= 80.) &&
                    ($seas 		>= 50.) &&
                    ($seas 		<= 80.) &&
                    ([$planet cget -ptype] ne "tWater") &&
                    ($breathe    == $::stargen::enviro::BREATHABLE)} {
                    incr earthlike

                    if {($::stargen::flag_verbose & 0x0008) != 0} {
                        puts stderr [format "%12s\tp=%4.2lf\tm=%4.2lf\tg=%4.2lf\tt=%+.1lf\t%d %s\tEarth-like" \
                                     [type_string [$planet cget -ptype]] \
                                     [$planet cget -surf_pressure] \
                                     [expr {[$planet cget -mass] * SUN_MASS_IN_EARTH_MASSES}] \
                                     [$planet cget -surf_grav] \
                                     [expr {[$planet cget -surf_temp]  - EARTH_AVERAGE_KELVIN}] \
                                     $habitable \
                                     $planet_id]
                    }
		} elseif {(($::stargen::flag_verbose & 0x0008) != 0) &&
                          ($breathe   == $::stargen::enviro::BREATHABLE) &&
                          ($gravity	 > 1.3) &&
                          ($habitable	 > 1) &&
                          (($rel_temp  < -2.0) ||
                           ($ice	 > 10.))} {
                    puts stderr [format "%12s\tp=%4.2lf\tm=%4.2lf\tg=%4.2lf\tt=%+.1lf\t%s\tSphinx-like" \
                                 [type_string [$planet cget -ptype]] \
                                 [$planet cget -surf_pressure] \
                                 [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                 [$planet cget -surf_grav] \
                                 [expr {[$planet cget -surf_temp]  - $::stargen::EARTH_AVERAGE_KELVIN}] \
                                 $planet_id]
                }
            }
        }
        method generate_planets {random_tilt flag_char sys_no system_name 
            do_gases do_moons} {
            puts stderr "*** $self generate_planets $random_tilt $flag_char $sys_no $system_name $do_gases $do_moons"
            set planet_no 0
            set moons 0
            
            foreach planet [$sun getplanets] {
                incr planet_no
                set planet_id [format "%s (-s%ld -%c%d) %d" \
                               $system_name $flag_seed $flag_char $sys_no \
                               $planet_no]


		$self generate_planet $planet $planet_no $random_tilt \
                      $planet_id $do_gases $do_moons false
		
		#/*
		# *	Now we're ready to test for habitable planets,
		# *	so we can count and log them and such
		# */
		 
                $self check_planet $planet $planet_id false
						
                set moons 0
                foreach moon [$planet cget -moons] {
                    incr moons
                    set moon_id [format "%s.%d" $planet_id $moons]
                    $self check_planet $moon $moon_id true
		}
            }
            
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
                     $only_earthlike $index $use_solar_system \
                     $reuse_solar_system]} {
                    lappend result $system
                } else {
                    $system destroy
                    incr index -1
                }
                
            }
            $sun destroy
            return $result
        }
    }
    namespace export System
}    
    




