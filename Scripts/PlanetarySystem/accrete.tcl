#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Mon Apr 11 14:23:05 2016
#  Last Modified : <160412.1345>
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

#/*----------------------------------------------------------------------*/
#/*							 BIBLIOGRAPHY								*/
#/*	Dole, Stephen H.  "Formation of Planetary Systems by Aggregation:	*/
#/*		a Computer Simulation"	October 1969,  Rand Corporation Paper	*/
#/*		P-4226.															*/
#/*----------------------------------------------------------------------*/

package require control
namespace import control::*

namespace eval ::stargen::accrete {
    #/* Now for some variables global to the accretion process:	    */
    variable dust_left no
    variable r_inner 0.0
    variable r_outer 0.0
    variable reduced_mass 0.0
    variable dust_density 0.0
    variable cloud_eccentricity 0.0
    variable dust_head [list]
    variable planet_head [list]
    variable hist_head [list]
    
    namespace import ::stargen::*
    namespace import ::stargen::utils::*
    
    proc set_initial_conditions {inner_limit_of_dust outer_limit_of_dust} {
        variable dust_head
        variable planet_head
        variable hist_head
        variable dust_left
        variable cloud_eccentricity
        
        set hist [Generation %AUTO% -dusts $dust_head -planets $planet_head]
        set hist_head [linsert $hist_head 0 $hist]
        set dust_head [list [Dust_Record %AUTO% \
                             -inner_edge $inner_limit_of_dust \
                             -outer_edge $outer_limit_of_dust \
                             -dust_present yes -gas_present yes]]
        set planet_head [list]
        set dust_left yes
        set cloud_eccentricity 0.2
    }
    proc stellar_dust_limit {stell_mass_ratio} {
        return [expr {200.0 * pow($stell_mass_ratio,(1.0 / 3.0))}]
    }
    proc nearest_planet {stell_mass_ratio} {
        return [expr {0.3 * pow($stell_mass_ratio,(1.0 / 3.0))}]
    }
    proc farthest_planet {stell_mass_ratio} {
        return [expr {50.0 * pow($stell_mass_ratio,(1.0 / 3.0))}]
    }
    proc inner_effect_limit {a e mass} {
        variable cloud_eccentricity
        return [expr {($a * (1.0 - $e) * (1.0 - $mass) / (1.0 + $cloud_eccentricity))}]
    }
    proc outer_effect_limit {a e mass} {
        variable cloud_eccentricity
        return [expr {($a * (1.0 + $e) * (1.0 - $mass) / (1.0 + $cloud_eccentricity))}]
    }
    proc dust_available {inside_range outside_range} {
        variable dust_head
        set dust_here false
        set foundstart no
        
        foreach current_dust_band $dust_head {
            if {!$foundstart} {
                if {[$current_dust_band cget -outer_edge] >= $inside_range} {
                    set dust_here [$current_dust_band cget -dust_present]
                    set foundstart yes
                }
            }
            if {$foundstart} {
                if {[$current_dust_band cget -inner_edge] < $outside_range} {
                    if {[$current_dust_band cget -dust_present]} {
                        set dust_here true
                    }
                } else {
                    break
                }
            }
            
        }
        return $dust_here
    }
    proc eqbool {b1 b2} {
        if {$b1 && $b2} {
            return true
        } elseif {!$b1 && !$b2} {
            return true
        } else {
            return false
        }
    }
    proc update_dust_lanes {min max mass crit_mass body_inner_bound 
        body_outer_bound} {
        variable dust_left
        variable dust_head
        
        set dust_left false
        if {$mass > $crit_mass} {
            set gas false
        } else {
            set gas true
        }
        set node1_i 0
        while {$node1_i < [llength $dust_head]} {
            set node1 [lindex $dust_head $node1_i]
            if {([$node1 cget -inner_edge] < $min) &&
                ([$node1 cget -outer_edge] < $max)} {
                if {[$node1 cget -gas_present]} {
                    set node2_gp $gas
                } else {
                    set node2_gp false
                }
                set node2 [Dust_Record %AUTO% -inner_edge $min \
                           -outer_edge $max \
                           -dust_present false \
                           -gas_present $node2_gp]
                set node3 [Dust_Record %AUTO% -inner_edge $max \
                           -outer_edge [$node1 cget -outer_edge] \
                           -gas_present [$node1 cget -gas_present] \
                           -dust_present [$node1 cget -dust_present]]
                $node1 configure -outer_edge $min
                set dust_head [linsert $dust_head [expr {$node1_i + 1}] \
                               $node2 $node3]
                incr node1_i 3
            } elseif {([$node1 cget -inner_edge] < $max) &&
                ([$node1 cget -outer_edge] > $max)} {
                set node2 [Dust_Record %AUTO% \
                           -dust_present [$node1 cget -dust_present] \
                           -gas_present  [$node1 cget -gas_present] \
                           -outer_edge   [$node1 cget -outer_edge] \
                           -inner_edge   $max]
                $node1 configure -outer_edge $max
                if {[$node1 cget -gas_present]} {
                    $node1 configure -gas_present $gas
                } else {
                    $node1 configure -gas_present false
                }
                $node1 configure -dust_present false
                set dust_head [linsert $dust_head [expr {$node1_i + 1}] \
                               $node2]
                incr node1_i 2
            } elseif {([$node1 cget -inner_edge] >= $min) &&
                ([$node1 cget -outer_edge] <= $max)} {
                if {[$node1 cget -gas_present]} {
                    $node1 configure -gas_present $gas
                }
                $node1 configure -dust_present false
                incr node1_i
            } elseif {([$node1 cget -outer_edge] < $min) || ([$node1 cget -inner_edge] > $max)} {
                incr node1_i
            }
        }
        set node1_i 0
        while {$node1_i < [llength $dust_head]} {
            set node1 [lindex $dust_head $node1_i]
            if {([$node1 cget -dust_present]) &&
                (([$node1 cget -outer_edge] >= $body_inner_bound) 
                 && ([$node1 cget -inner_edge] <= $body_inner_bound))} {
                set dust_left true
            }
            set node2_i [expr {$node1_i + 1}]
            set node2 [lindex $dust_head $node2_i]
            if {$node2 ne {}} {
                if {[eqbool [$node1 cget -dust_present] [$node2 cget -dust_present]] &&
                    [eqbool [$node1 cget -gas_present] [$node2 cget -gas_present]]} {
                    $node1 configure -outer_edge [$node2 cget -outer_edge]
                    set dust_head [lreplace $dust_head $node2_i $node2_i]
                    $node2 destroy
                }
            }
            incr node1_i
        }
    }
    proc collect_dust {last_mass new_dustName new_gasName a e crit_mass 
        dust_band} {
        variable dust_left
        variable r_inner
        variable r_outer
        variable reduced_mass
        variable dust_density
        variable cloud_eccentricity
        variable dust_head
        variable planet_head
        variable hist_head
        upvar $new_dustName new_dust
        upvar $new_gasName new_gas

        set gas_density 0.0
        set next_dust 0.0
        set next_gas 0.0
        set temp [expr {$last_mass / (1.0 + $last_mass)}]
        set reduced_mass [expr {pow($temp,(1.0 / 4.0))}]
        set r_inner [inner_effect_limit $a $e $reduced_mass]
        set r_outer [outer_effect_limit $a $e $reduced_mass]
        
        if {$r_inner < 0.0} {
            set r_inner 0.0
        }
        
        if {[llength $dust_band] == 0} {
            return 0.0
        } else {
            set dust_band1 [lindex $dust_band 0]
            if {![$dust_band1 cget -dust_present]} {
                set temp_density 0.0
            } else {
                set temp_density $dust_density
            }
            if {($last_mass < $crit_mass) || (![$dust_band1 cget -gas_present])} {
                set mass_density $temp_density
            } else {
                set mass_density [expr {$::stargen::K * $temp_density / (1.0 + sqrt($crit_mass / $last_mass) * ($::stargen::K - 1.0))}]
                set gas_density [expr {$mass_density - $temp_density}]
            }
            if {([$dust_band1 cget -outer_edge] <= $r_inner) ||
                ([$dust_band1 cget -inner_edge] >= $r_outer)} {
                return [collect_dust $last_mass new_dust new_gas $a $e \
                        $crit_mass [lrange $dust_band 1 end]]
            } else {
                set bandwidth [expr {$r_outer - $r_inner}]
                set temp1 [expr {$r_outer - [$dust_band1 cget -outer_edge]}]
                if {$temp1 < 0.0} {set temp1 0.0}
                set width [expr {$bandwidth - $temp1}]
                set temp2 [expr {[$dust_band1 cget -inner_edge] - $r_inner}]
                if {$temp2 < 0.0} {set temp2 0.0}
                set width [expr {$width - $temp2}]
                set temp [expr {4.0 * $::stargen::PI * pow($a,2.0) * $reduced_mass * (1.0 - $e * ($temp1 - $temp2) / $bandwidth)}]
                set volume [expr {$temp * $width}]
                set new_mass [expr {$volume * $mass_density}]
                set new_gas  [expr {$volume * $gas_density}]
                set new_dust [expr {$new_mass - $new_gas}]
                set next_mass [collect_dust $last_mass next_dust next_gas $a $e $crit_mass [lrange $dust_band 1 end]]
                set new_gas [expr {$new_gas + $next_gas}]
                set new_dust [expr {$new_dust + $next_dust}]
                return [expr {$new_mass + $next_mass}]
            }
        }
    }
    #/*--------------------------------------------------------------------------*/
    #/*	 Orbital radius is in AU, eccentricity is unitless, and the stellar		*/
    #/*	luminosity ratio is with respect to the sun.  The value returned is the */
    #/*	mass at which the planet begins to accrete gas as well as dust, and is	*/
    #/*	in units of solar masses.												*/
    #/*--------------------------------------------------------------------------*/

    proc critical_limit {orb_radius eccentricity stell_luminosity_ratio} {
        set perihelion_dist [expr {$orb_radius - $orb_radius * $eccentricity}]
        set temp [expr {$perihelion_dist * sqrt($stell_luminosity_ratio)}]
        return [expr {$::stargen::B * pow($temp,-0.75)}]
    }
    proc accrete_dust {seed_massName new_dustName new_gasName a e crit_mass 
        body_inner_bound body_outer_bound} {
        upvar $seed_massName seed_mass
        upvar $new_dustName new_dust
        upvar $new_gasName new_gas
        variable dust_head
        variable r_inner
        variable r_outer
        
        set new_mass $seed_mass
        do {
            set temp_mass $new_mass
            set new_mass [collect_dust $new_mass new_dust new_gas $a $e $crit_mass $dust_head]
        } while {!(($new_mass - $temp_mass) < (0.0001 * $temp_mass))}
        set seed_mass [expr {$seed_mass + $new_mass}]
        update_dust_lanes $r_inner $r_outer $seed_mass $crit_mass \
              $body_inner_bound $body_outer_bound
    }
    proc insert_planet {theplanet} {
        variable planet_head
        
        for {set pindex 0} {$pindex < [llength $planet_head]} {incr pindex} {
            set p [lindex $planet_head $pindex]
            if {[$p cget -a] >= [$theplanet cget -a]} {
                break
            }
        }
        set planet_head [linsert $planet_head  $pindex $theplanet]
        return $pindex
    }
                
    proc reinsert_planet {pindex} {
        variable planet_head
        
        set the_planet [lindex $planet_head $pindex]
        set planet_head [lreplace $planet_head $pindex $pindex]
        return [insert_planet $the_planet]
    }
    proc coalesce_planetesimals {a e mass crit_mass dust_mass gas_mass 
        stell_luminosity_ratio body_inner_bound body_outer_bound do_moons} {
        variable dust_left
        variable r_inner
        variable r_outer
        variable reduced_mass
        variable dust_density
        variable cloud_eccentricity
        variable dust_head
        variable planet_head
        variable hist_head
        
        set finished false
        #// First we try to find an existing planet with an over-lapping orbit.
	set pindex 0
        while {$pindex < [llength $planet_head]} {
            set the_planet [lindex $planet_head $pindex]
            
            set diff [expr {[$the_planet cget -a] - $a}]
            if {$diff > 0.0} {
                set dist1 [expr {($a * (1.0 + $e) * (1.0 + $reduced_mass)) - $a}]
                #/* x aphelion    */
		set reduced_mass [expr {pow(([$the_planet cget -mass] / (1.0 + [$the_planet cget -mass])),(1.0 / 4.0))}]
                set dist2 [expr {[$the_planet cget -a] - ([$the_planet cget -a] * (1.0 - [$the_planet cget -e]) * (1.0 - $reduced_mass))}]
            } else {
                set dist1 [expr {$a - ($a * (1.0 - $e) * (1.0 - $reduced_mass))}]
                #/* x perihelion */    
                set reduced_mass [expr {pow(([$the_planet cget -mass] / (1.0 + [$the_planet cget -mass])),(1.0 / 4.0))}]
                set dist2 [expr {([$the_planet cget -a] * (1.0 + [$the_planet cget -e]) * (1.0 + $reduced_mass)) - [$the_planet cget -a]}]
            }
                    
            if {((abs($diff) <= abs($dist1)) || (abs($diff) <= abs($dist2)))} {
                set new_dust 0.0
                set new_gas  0.0
                set new_a [expr {([$the_planet cget -mass] + $mass) / (([$the_planet cget -mass] / [$the_planet cget -a]) + ($mass / $a))}]
                
                set temp [expr {[$the_planet cget -mass] * sqrt([$the_planet cget -a]) * sqrt(1.0 - pow([$the_planet cget -e],2.0))}]
                set temp [expr {$temp + ($mass * sqrt($a) * sqrt(sqrt(1.0 - pow($e,2.0))))}]
                set temp [expr {$temp / (([$the_planet cget -mass] + $mass) * sqrt($new_a))}]
                set temp [expr {1.0 - pow($temp,2.0)}]
                if {(($temp < 0.0) || ($temp >= 1.0))} {
                    set temp 0.0
                }
                set e [expr {sqrt($temp)}]
			
                if {$do_moons} {
                    set existing_mass 0.0
				
                    if {[llength [$the_planet cget -moons]] > 0} {
                        foreach m [$the_planet cget -moons] {
                            set existing_mass [expr {$existing_mass + [$m cget -mass]}]
                        }
                    }
                    
                    if {$mass < $crit_mass} {
                        if {($mass * $::stargen::SUN_MASS_IN_EARTH_MASSES) < 2.5
                            && ($mass * $::stargen::SUN_MASS_IN_EARTH_MASSES) > .0001
                            && $existing_mass < ([$the_planet cget -mass] * .05)} {
                            set the_moon [Planets_Record %AUTO% \
                                          -ptype      tUnknown \
                                          -mass       $mass \
                                          -dust_mass  $dust_mass \
                                          -gas_mass   $gas_mass \
                                          -atmosphere [list] \
                                          -moons      [list] \
                                          -gas_giant  false \
                                          -albedo     0 \
                                          -gases      0 \
                                          -surf_temp  0 \
                                          -high_temp  0 \
                                          -low_temp   0 \
                                          -max_temp   0 \
                                          -min_temp   0 \
                                          -greenhs_rise 0\
                                          -minor_moons 0]
	
                            if {([$the_moon cget -dust_mass] + [$the_moon cget -gas_mass])
                                 > ([$the_planet cget -dust_mass] + [$the_planet cget -gas_mass])} {
                                 set temp_dust [$the_planet cget -dust_mass]
                                 set temp_gas  [$the_planet cget -gas_mass]
                                 set temp_mass [$the_planet cget -mass]
							
                                 $the_planet configure -dust_mass [$the_moon cget -dust_mass];
                                 $the_planet configure -gas_mass  [$the_moon cget -gas_mass];
                                 $the_planet configure -mass      [$the_moon cget -mass]
							
                                 $the_moon configure -dust_mass   $temp_dust
                                 $the_moon configure -gas_mass    $temp_gas
                                 $the_moon configure -mass        $temp_mass;
                            }
	
                            $the_planet consmoon $the_moon
                             
                            set finished true
                             
                            if {($::stargen::flag_verbose & 0x0100) != 0} {
                                 puts stderr [format "Moon Captured... %5.3lf AU (%.2lfEM) <- %.2lfEM" \
                                              [$the_planet cget -a] \
                                              [expr {[$the_planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                              [expr {$mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}]]
                            }
                       } else {
                            if {($::stargen::flag_verbose & 0x0100) != 0} {
                                puts stderr [format "Moon Escapes... %5.3lf AU (%.2lfEM)%s %.2lfEM%s" \
                                             [$the_planet cget -a] \
                                             [expr {[$the_planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \ 
                                             [expr {$existing_mass < ([$the_planet cget -mass] * .05) ? "" : " (big moons)"}] \
                                             [expr {$mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                             [expr {($mass * $::stargen::SUN_MASS_IN_EARTH_MASSES) >= 2.5 ? ", too big" : \
                                              ($mass * $::stargen::SUN_MASS_IN_EARTH_MASSES) <= .0001 ? ", too small" : ""}]]
                            }
                        }
                    }
                }
                 
                if {!$finished} {
                    if {($::stargen::flag_verbose & 0x0100) != 0} {
                        puts stderr [format {Collision between two planetesimals! %4.2lf AU (%.2lfEM) + %4.2lf AU (%.2lfEM = %.2lfEMd + %.2lfEMg [%.3lfEM])-> %5.3lf AU (%5.3lf)} \
                                     [$the_planet cget -a] \
                                     [expr {[$the_planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     $a [expr {$mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     [expr {$dust_mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     [expr {$gas_mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     [expr {$crit_mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                                     $new_a $e]
                    }
                    set temp [expr {[$the_planet cget -mass] + $mass}]
                    accrete_dust temp new_dust new_gas $new_a $e \
                          $stell_luminosity_ratio $body_inner_bound \
                          $body_outer_bound
                     
                    $the_planet configure -a $new_a
                    $the_planet configure -e $e
                    $the_planet configure -mass $temp
                    $the_planet configure -dust_mass [expr {[$the_planet cget -dust_mass] + $dust_mass + $new_dust}]
                    $the_planet configure -gas_mass  [expr {[$the_planet cget -gas_mass] + $gas_mass + $new_gas}]
                    if {$temp >= $crit_mass} {
                        $the_planet configure -gas_giant true
                    }
                    
                    set pindex [reinsert_planet $pindex]
                    incr pindex
                }
                
                set finished true
                break;
            }
        }
        
        if {!$finished} {	# Planetesimals didn't collide. Make it a planet.
            
            set the_planet [Planets_Record %AUTO% -ptype tUnknown -a $a -e $e \
                            -mass $mass -dust_mass $dust_mass \
                            -gas_mass $gas_mass -atmosphere [list] \
                            -moons [list] -albedo 0 -gases 0 -surf_temp 0 \
                            -high_temp 0 -low_temp 0 -max_temp 0 -min_temp 0 \
                            -greenhs_rise 0 -minor_moons= 0]
            if {$mass >= $crit_mass} {
                $the_planet configure -gas_giant true
            } else {
                $the_planet configure -gas_giant false
            }
        
            set pindex [insert_planet $the_planet]
        }
        
    }
    proc dist_planetary_masses {stell_mass_ratio stell_luminosity_ratio 
        inner_dust outer_dust outer_planet_limit dust_density_coeff 
        seed_system do_moons} {
    }
    proc free_dust {head} {
    }
    proc free_planet {head} {
    }
    proc free_atmosphere {head} {
    }
    proc free_generations {} {
    }
    namespace export set_initial_conditions stellar_dust_limit nearest_planet \
          farthest_planet inner_effect_limit outer_effect_limit dust_available \
          update_dust_lanes collect_dust critical_limit accrete_dust \
          coalesce_planetesimals dist_planetary_masses free_dust free_planet \
          free_atmosphere free_generations
}

