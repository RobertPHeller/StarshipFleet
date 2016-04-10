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
#  Last Modified : <160409.1913>
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
#source [file join [file dirname [info script]] accrete.tcl]
#source [file join [file dirname [info script]] enviro.tcl]
#source [file join [file dirname [info script]] utils.tcl]

namespace eval stargen {
       
    variable fUseSolarsystem		0x0001
    variable fReuseSolarsystem		0x0002
    variable fUseKnownPlanets		0x0004
    variable fNoGenerate		0x0008
    variable tDoGases			0x0010
    variable fDoMoons			0x0020
    
    variable fOnlyHabitable		0x0100
    variable fOnlyMultiHabitable	0x0200
    variable fOnlyJovianHabitable	0x0400
    variable fOnlyEarthlike		0x0800
    
    variable stargen_revision {$Revision$ (Tcl version Based on C version 1.43)}
    
    

    
    
    snit::type stargen {
        component sun
        delegate option * to sun
        delegate method * to sun
        typevariable flag_seed 0
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
        typevariable gases
        typeconstructor {
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
            set gases [lsort -command [myproc diminishing_abundance] $gases]
        }

        typemethod init {} {
            if {flag_seed != 0} {
                set seed [clock seconds]
                expr {srand($seed)}
                set flag_seed [expr {rand()*0x0ffffffff}]
            }
            expr {srand($flag_seed)}
        }
        constructor {args} {
            install sun using stargen::Sun %AUTO% \
                  -luminosity [from args -luminosity 0] \
                  -mass       [from args -mass 0] \
                  -life       [from args -life 0] \
                  -age        [from args -age 0] \
                  -r_ecosphere [from args -r_ecosphere 0] \
                  -name       [from args -name]
        }
        typemethod generate_stellar_system {use_seed_system seed_system 
            flag_char sys_no system_name outer_planet_limit do_gases 
            do_moons args} {
        }
        method calculate_gases {planets planet_id} {
        }
        method generate_planet {planet planet_no random_tilt do_gases do_moons is_moon} {
        }
        method generate_planets {random_tilt flag_char sys_no system_name do_gases do_moons} {
        }
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
        method diminishing_pressure {xp yp} {
        }
        typevariable min_mass 0.4
        typevariable inc_mass 0.05
        typevariable max_mass 2.35
        
        typemethod stargen {flag_char path url_path_arg filename_arg 
            sys_name_arg sgOut sgErr prognam mass_arg seed_arg incr_arg 
            cat_arg sys_no_arg ratio_arg flags_arg out_format graphic_format} {
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
            set do_moons [expr {($flags_arg & $::stargen::fDoMoons) != 0}]
            set only_habitable [expr {($flags_arg & $::stargen::fOnlyHabitable) != 0}]
            set only_multi_habitable [expr {($flags_arg & $::stargen::fOnlyMultiHabitable) != 0}]
            set only_jovian_habitable [expr {($flags_arg & $::stargen::fOnlyJovianHabitable) != 0}]
            set only_earthlike [expr {($flags_arg & $::stargen::fOnlyEarthlike) != 0}]
            
            if {$do_catalog} {
                set catalog_count [$cat_arg count]
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
            set sun_mass $mass_arg
            set system_count $count_arg
            set seed_increment $incr_arg
            if {$ratio_arg > 0.0} {
                set dust_density_coeff [expr {$dust_density_coeff * $ratio_arg}]
            }
            if {$reuse_solar_system} {
            }
            
            set result [list]
            for {set index 0} {$index < $system_count} {incr index} {
                $type init
                
                set system [$type generate_stellar_system $use_seed_system \
                            $seed_planets $flag_char $sys_no $system_name \
                            $outer_limit $do_gases $do_moons -luminosity \
                            $sun_lum -mass $sun_mass -life $sun_life \
                            -age $sun_age -r_ecosphere $sun_r_ecosphere \
                            -name $sun_name]
                
            }
        }
    }



    variable planets [list]
    variable dust_density_coeff $DUST_DENSITY_COEFF
    variable flag_verbose 0
    
    
}
