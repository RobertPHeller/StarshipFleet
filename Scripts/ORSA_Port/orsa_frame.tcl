#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Wed May 11 10:46:35 2016
#  Last Modified : <160511.1527>
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


namespace eval orsa {
    snit::type Frame {
        variable body_vector
        option -epoch -default 0 -type {snit::integer -min 0}
        constructor {args} {
            $self configurelist $args
        }
        typemethod copy {name other} {
            $type validate $other
            set result [$type create $name -epoch [$other cget -epoch]]
            for {set i 0} {$i < [$other size]} {incr i} {
                $result add body [$other get body $i]
            }
            return $result
        }
        method {body size} {} {
            return [llength $body_vector]
        }
        method {body get} {i} {
            if {$i < 0 || $i >= [llength $body_vector]} {
                error [format "Index (%d) out of range 0..%d" $i [expr {[llength $body_vector] -1}]]
            }
            return [lindex $body_vector $i]
        }
        method {body add} {body} {
            ::orsa::Body validate $body
            lappend body_vector $body
        }
        typemethod validate {o} {
            if {[catch {$o info type} otype]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$otype ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        method < {f} {
            $type validate $f
            return [expr {[$self cget -epoch] < [$f  cget -epoch]}]
        }
        method CenterOfMass {} {
            set sum_vec Vector %AUTO% 0 0 0
            set sum_mass 0.0
            foreach b $body_vector {
                set mass [$b mass]
                if {$mass > 0.0} {
                    $sum_vec += [[$b position] * $mass]
                    set sum_mass [expr {$sum_mass + $mass}]
                }
            }
            return [$sum_vec / $sum_mass]
        }
        method CenterOfMassVelocity {} {
            set sum_vec [Vector %AUTO% 0 0 0]
            set sum_mass 0.0
            foreach b $body_vector {
                set mass [$b mass]
                if {$mass > 0.0} {
                    $sum_vec += [[$b velocity] * $mass]
                    set sum_mass [expr {$sum_mass + $mass}]
                }
            }
            return [$sum_vec / $sum_mass]
        }
        method Barycenter {} {
            return [$self CenterOfMass]
        }
        method BarycenterVelocity {} {
            return [$self CenterOfMassVelocity]
        }
        method modified_mu {body} {
            if {[$body has_zero_mass]} {return 0.0}
            set one_over_two_c [expr {1.0 / (2*[::orsa::GetC])}]
            set mu [list]
            set poslist [list]
            set mu_i 0.0
            foreach b1 $body_vector {
                if {[$b1 has_zero_mass]} {
                    set newmu 0.0
                } else {
                    set newmu [$b1 mu]
                }
                if {$b1 eq $body} {
                    set mu_i $newmu
                } else {
                    lappend mu $newmu
                    lappend poslist [$b1 position]
                }
            }
            set mod_mu 0.0
            set tmp_sum 0.0
            foreach mu_j $mu pos_j $poslist {
                set diffposL [[[$body position] - $pos_j] Length]
                set tmp_sum [expr {$tmp_sum + ($mu_j / $diffposL)}]
            }
            set mod_mu [expr {$mu_i * (1.0 + $one_over_two_c * ([[$body velocity] LengthSquared] - $tmp_sum))}]
            return $mod_mu
        }
            
        method RelativisticBarycenter {} {
            set sum_vec [Vector %AUTO% 0 0 0]
            set sum_mu 0.0
            foreach b $body_vector {
                set mod_mu [modified_mu $b]
                if {$mod_mu > 0.0} {
                    $sum_vec += [[$b position] * $mod_mu]
                    set sum_mu [expr {$sum_mu + $mod_mu}]
                }
            }
            return [$sum_vec / $sum_mu]
        }
        method RelativisticBarycenterVelocity {} {
            set sum_vec [Vector %AUTO% 0 0 0]
            set sum_mu 0.0
            foreach b $body_vector {
                set mod_mu [modified_mu $b]
                if {$mod_mu > 0.0} {
                    $sum_vec += [[$b velocity] * $mod_mu]
                    set sum_mu [expr {$sum_mu + $mod_mu}]
                }
            }
            return [$sum_vec / $sum_mu]
        }
        
        method AngularMomentum {center} {
            orsa::Vector validate $center
            set vec_sum [Vector %AUTO% 0 0 0]
            foreach b $body_vector {
                if {[$b mass] > 0} {
                    set ep [[[$b position] - $center] ExternalProduct [$b velocity]]
                    $sum_vec += [$ep * [$b mass]]
                }
            }
            return $sum_vec
        }
        method BarycentricAngularMomentum {} {
            return [$self AngularMomentum [$self Barycenter]]
        }
        method KineticEnergy {} {
            if {[llength $body_vector] == 0} {return 0.0}
            set energy 0
            foreach b $body_vector {
                set energy [expr {$energy + [$b KineticEnergy]}]
            }
            return $energy
        }
        
    }
    namespace export Frame
}

