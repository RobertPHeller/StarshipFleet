#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Mon Apr 11 10:23:40 2016
#  Last Modified : <160427.1325>
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


source [file join [file dirname [info script]] stargen.tcl]
#namespace import stargen::*

package require snit




snit::type stargen {
    pragma -hastypeinfo no -hastypedestroy no -hasinstances no
    
    typeconstructor {
        #*
        #*		StarGen supports private catalogs. The two here are ones I am using
        #*		for debuggery. They may go away.
        #*
        
        #*  No 	Orbit	Eccen. 	Tilt	Mass		Giant?	Dust Mass	Gas
        #planets sphinx3   ={ 4,	3.0,	0.046,	10.5,	EM(2.35),	FALSE,	EM(2.35),	0, 	ZEROES,0,NULL, NULL};
        #planets sphinx2   ={ 3,	2.25,	0.02,	10.5,	EM(2.35),	FALSE,	EM(2.35),	0, 	ZEROES,0,NULL, &sphinx3};
        #planets sphinx    ={ 2,	1.6,	0.02,	10.5,	EM(2.2),	FALSE,	EM(2.2),	0, 	ZEROES,0,NULL, &sphinx2};
        #planets manticore ={ 1,	1.115,	0.017,	23.5,	EM(1.01),	FALSE,	EM(1.01),	0, 	ZEROES,0,NULL, &sphinx};
        
        #namespace import ::stargen::*
        
        Planets_Record sphinx3  -planet_no 4 -a 3.0 -e 0.046 \
              -axial_tilt 10.5 -mass [EM 2.35] -gas_giant false \
              -dust_mass [EM 2.35] -gas_mass 0
        Planets_Record sphinx2 -planet_no 3  -a 2.25 -e 0.02 \
              -axial_tilt 10.5 -mass [EM 2.35] -gas_giant false \
              -dust_mass [EM 2.35] -gas_mass 0
        Planets_Record sphinx -planet_no 2 -a 1.6 -e 0.02 \
              -axial_tilt 10.5 -mass [EM 2.2] -gas_giant false \
              -dust_mass [EM 2.2] -gas_mass 0
        Planets_Record manticore -planet_no 1 -a 1.115 \
              -e 0.017 -axial_tilt 23.5 -mass [EM 1.01] \
              -gas_giant false -dust_mass [EM 1.01] -gas_mass 0
        set manticore_planets [list ${type}::manticore ${type}::sphinx \
                               ${type}::sphinx2 ${type}::sphinx3]
        
        #star	manticores[] = 
        #// L		Mass	Mass2	Eccen.	SMAxis	 Planets	Designation			Name
        #{{1.00,		1.00,	0,		0,		0,		 &mercury,	"Sol",		 	 1, "The Solar System"},
        # {1.24,		1.047,	1.0,	0.05,	79.2,	 &manticore,"Manticore A",	 1, "Manticore A"},
        # {1.0,		1.00,	1.047,	0.05,	79.2,	 NULL,		"Manticore B",	 1, "Manticore B"},
        #};
        #
        #catalog	manticore_cat	= {sizeof(manticores) / sizeof (star),	"B", &manticores};
        
        Catalog manticore_cat -arg "B" \
              ::stargen::Sol_ \
              [Star "Manticore A" -luminosity 1.24 -mass 1.047 -m2 1.0 -e 0.05 \
               -a 79.2 -known_planets $manticore_planets -in_celestia true \
               -name "Manticore A"] \
              [Star "Manticore B" -luminosity 1.0 -mass 1.00 -m2 1.047 -e 0.05 \
               -a 79.2 -known_planets {} -in_celestia true -name "Manticore B"]
        
        
        #star	helios[] = 
        #// L		Mass	Mass2	Eccen.	SMAxis	 Planets	Designation		Name
        #{{1.00,		1.00,	0,		0,		0,		 &mercury,	"Sol",		 1, "The Solar System"},
        # {1.08,		1.0,	0.87,	0.45,	8.85,	 NULL,		"Helio A",	 1, "Helio A"},
        # {0.83,		0.87,	1.0,	0.45,	8.85,	 NULL,		"Helio B",	 1, "Helio B"},
        #};
        #
        #catalog	helio		= {sizeof(helios) / sizeof (star), "?",	&helios};
    
    
        Catalog helio -arg "?" \
              ::stargen::Sol_ \
              [Star "Helio A" -luminosity 1.08 -mass 1.0 -m2 0.87 -e 0.45 \
               -a 8.85 -known_planets {} -in_celestia true -name "Helio A"] \
              [Star "Helio B" -luminosity 0.83 -mass 0.87 -m2 1.0 -e 0.45 \
               -a 8.85 -known_planets {} -in_celestia true -name "Helio B"]
        
        #*	No Orbit Eccen. Tilt   Mass    Gas Giant? Dust Mass   Gas */
        #planets ilaqrb={1, 0.21, 0.1,   0,     EM(600.),TRUE,     0,   EM(600.), ZEROES,0,NULL, NULL};
        #planets ilaqrc={2, 0.13, 0.27,  0,     EM(178.),TRUE,     0,   EM(178.), ZEROES,0,NULL, &ilaqrb};
        #planets ilaqrd={3, 0.021,0.22,  0,     EM(5.9), FALSE,    EM(5.9),    0, ZEROES,0,NULL, &ilaqrc};	// EM(5.9) or 7.53 +/- 0.70 Earth-masses

        Planets_Record ilaqrb -planet_no 1 -a 0.21 -e 0.1 \
              -axial_tilt 0 -mass [EM 600.] -gas_giant true \
              -dust_mass 0 -gas_mass [EM 600.]
        Planets_Record ilaqrc -planet_no 2 -a 0.13 -e 0.27 \
              -axial_tilt 0 -mass [EM 178.] -gas_giant true \
              -dust_mass 0 -gas_mass [EM 178.]
        Planets_Record ilaqrd -planet_no 3 -a 0.021 -e 0.22 \
              -axial_tilt 0 -mass [EM 5.9] -gas_giant false \
              -dust_mass [EM 5.9] -gas_mass 0
        set ilAqrs_planets [list ${type}::ilaqrb ${type}::ilaqrc \
                            ${type}::ilaqrd]
    
        #star	ilAqrs[] = 
        #// L		Mass	Mass2	Eccen.	SMAxis	 Planets	Designation	Celes	Name
        #{{1.00,		1.00,	0,		0,		0,		 &mercury,	"Sol",		1, "The Solar System"},
        #{0.0016,	0.32,	0,		0,		0,		 &ilaqrd,	"IL Aqr",	1, "IL Aquarii/Gliese 876"}	// 15.2
        #};
        
        #catalog	ilAqr_cat		= {sizeof(ilAqrs) / sizeof (star),	"G", &ilAqrs};
    
        Catalog ilAqr_cat -arg "G" \
              ::stargen::Sol_ \
              [Star "IL Aqr" -luminosity 0.0016 -mass 0.32 -m2 0 -e 0 -a 0 \
               -known_planets $ilAqrs_planets -in_celestia true \
               -name "IL Aquarii/Gliese 876"]
    }
    typemethod main {args} {
        set flag_char "?"
        set arg_name ""
        set mass_arg 0.0
        set seed_arg 0
        set count_arg 1
        set increment_arg 1
        set catalog {}
        set sys_no_arg 0
        set ratio_arg 0.0
        set flags_arg 0
        
        #namespace import ::stargen::*
        set seed_arg [from args -seed $seed_arg]
        #puts stderr "*** $type main: seed_arg = $seed_arg"
        set mass_arg [from args -mass $mass_arg]
        #puts stderr "*** $type main: mass_arg = $mass_arg"
        set count_arg [from args -count $count_arg]
        #puts stderr "*** $type main: count_arg = $count_arg"
        set increment_arg [from args -increment $increment_arg]
        #puts stderr "*** $type main: increment_arg = $increment_arg"
        set I [lsearch $args -use_solar_system]
        #puts stderr "*** $type main: I = $I (-use_solar_system)"
        if {$I >= 0} {
            set flag_char x
            set flags_arg [expr {$flags_arg | $::stargen::fUseSolarsystem}]
            if {$mass_arg == 0} {set mass_arg 1.0}
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -alternate_solar_system]
        #puts stderr "*** $type main: I = $I (-alternate_solar_system)"
        if {$I >= 0} {
            set flag_char a
            set flags_arg [expr {$flags_arg | $::stargen::fReuseSolarsystem}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -dole]
        #puts stderr "*** $type main: I = $I (-dole)"
        if {$I >= 0} {
            set catalog ::stargen::dole
            set flag_char D
            set f [lindex $args [expr {$I + 1}]]
            if {$f ne "" && [string index $f 0] ne "-"} {
                set sys_no_arg [expr {[from args -dole 0] + 1}]
            } else {
                set args [lreplace $args $I $I]
            }
        }
        set I [lsearch $args -web]
        #puts stderr "*** $type main: I = $I (-web)"
        if {$I >= 0} {
            set catalog ::stargen::solstation
            set flag_char W
            set f [lindex $args [expr {$I + 1}]]
            if {$f ne "" && [string index $f 0] ne "-"} {
                set sys_no_arg [expr {[from args -web 0] + 1}]
            } else {
                set args [lreplace $args $I $I]
            }
        }
        set I [lsearch $args -jimb]
        #puts stderr "*** $type main: I = $I (-jimb)"
        if {$I >= 0} {
            set catalog ::stargen::jimb
            set flag_char F
            set f [lindex $args [expr {$I + 1}]]
            if {$f ne "" && [string index $f 0] ne "-"} {
                set sys_no_arg [expr {[from args -jimb 0] + 1}]
            } else {
                set args [lreplace $args $I $I]
            }
        }
        set I [lsearch $args -manticore]
        #puts stderr "*** $type main: I = $I (-manticore)"
        if {$I >= 0} {
            set catalog [namespace current]::manticore_cat
            set flag_char B
            set f [lindex $args [expr {$I + 1}]]
            if {$f ne "" && [string index $f 0] ne "-"} {
                set sys_no_arg [expr {[from args -manticore 0] + 1}]
            } else {
                set args [lreplace $args $I $I]
            }
            set flags_arg [expr {$flags_arg | $::stargen::fNoGenerate}]
            sphinx configure -greenhouse_effect true
        }
        set I [lsearch $args -ilaqr]
        #puts stderr "*** $type main: I = $I (-ilaqr)"
        if {$I >= 0} {
            set catalog [namespace current]::ilAqr_cat
            set flag_char B
            set f [lindex $args [expr {$I + 1}]]
            if {$f ne "" && [string index $f 0] ne "-"} {
                set sys_no_arg [expr {[from args -ilaqr 0] + 1}]
            } else {
                set args [lreplace $args $I $I]
            }
            set flags_arg [expr {$flags_arg | $::stargen::fNoGenerate}]
        }
        set I [lsearch $args -gas]
        #puts stderr "*** $type main: I = $I (-gas)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -moons]
        #puts stderr "*** $type main: I = $I (-moons)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoMoons}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -habitable]
        #puts stderr "*** $type main: I = $I (-habitable)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases | $::stargen::fOnlyHabitable}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -multihabitable]
        #puts stderr "*** $type main: I = $I (-multihabitable)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases | $::stargen::fOnlyMultiHabitable}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -jovianhabitable]
        #puts stderr "*** $type main: I = $I (-jovianhabitable)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases | $::stargen::fOnlyJovianHabitable}]
            set args [lreplace $args $I $I]
        }
        set I [lsearch $args -earthlike]
        #puts stderr "*** $type main: I = $I (-earthlike)"
        if {$I >= 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases | $::stargen::fOnlyEarthlike}]
            set args [lreplace $args $I $I]
        }
        set ratio [from args -ratio 0.0]
        #puts stderr "*** $type main: I = $I (-ratio)"
        if {$ratio > 0.0} {set ratio_arg $ratio}
        set ::stargen::flag_verbose [from args -verbose 0]
        if {($::stargen::flag_verbose & 0x0001) != 0} {
            set flags_arg [expr {$flags_arg | $::stargen::fDoGases}]
        }
        
        if {[lsearch -glob $args "-*"] >= 0} {
            puts stderr "Unknown extra args: $args"
            return {}
        }
        #puts stderr "*** $type main: args = $args"
        set arg_name [join $args " "]
        return [System stargen $flag_char $arg_name $mass_arg \
                $seed_arg $count_arg $increment_arg $catalog $sys_no_arg \
                $ratio_arg $flags_arg]
    }
}
package provide stargen 0.1
