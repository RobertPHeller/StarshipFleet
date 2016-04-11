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
#  Last Modified : <160411.1707>
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


namespace eval ::stargen::accrete {
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
    }
    proc critical_limit {orb_radius eccentricity stell_luminosity_ratio} {
    }
    proc accrete_dust {seed_massName new_dustName new_gasName a e crit_mass 
        body_inner_bound body_outer_bound} {
    }
    proc coalesce_planetesimals {a e mass crit_mass dust_mass gas_mass 
        stell_luminosity_ratio body_inner_bound body_outer_bound do_moons} {
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

