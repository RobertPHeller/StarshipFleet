#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Fri Apr 1 22:16:30 2016
#  Last Modified : <160403.1831>
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

namespace eval orsa {

    snit::listtype Vector_list -type Vector

    snit::type Vector {
        variable x 0.0
        variable y 0.0
        variable z 0.0
        option -par -default 0.0 -type snit::double
        method GetX {} {return $x}
        method GetY {} {return $y}
        method GetZ {} {return $z}
        method Set {v} {
            $type validate $v
            set x [$v GetX]
            set y [$v GetY]
            set z [$v GetZ]
        }
        method = {v} {$self Set $v}
        method += {v} {
            $type validate $v
            set x [expr {$x + [$v GetX]}]
            set y [expr {$y + [$v GetY]}]
            set z [expr {$z + [$v GetZ]}]
        }
        method -= {v} {
            $type validate $v
            set x [expr {$x - [$v GetX]}]
            set y [expr {$y - [$v GetY]}]
            set z [expr {$z - [$v GetZ]}]
        }
        method *= {f} {
            snit::double validate $f
            set x [expr {$x * $f}]
            set y [expr {$y * $f}]
            set z [expr {$z * $f}]
        }
        method /= {f} {
            snit::double validate $f
            set x [expr {$x / $f}]
            set y [expr {$y / $f}]
            set z [expr {$z / $f}]
        }
        method + {} {return [$type create %AUTO% $x $y $z]}
        method - {} {return [$type create %AUTO% [expr {-$x}] [expr {-$y}] [expr {-$z}] ]}
        method Length {} {
            return [expr {sqrt(($x*$x) + ($y*$y) + ($z*$z))}]
        }
        method LengthSquared {} {
            return [expr {($x*$x) + ($y*$y) + ($z*$z)}]
        }
        method ManhattanLength {} {
            return [expr {abs($x) + abs($y) + abs($z)}]
        }
        method IsZero {} {
            set LS [$self LengthSquared]
            if {$LS < .00001} {
                return yes
            } else {
                return no
            }
        }
        method Normalize {} {
            set l [$self Length]
            if {$l < .00001} {
                set x 0.0
                set y 0.0
                set z 0.0
            } else {
                set x [expr {$x / $l}]
                set y [expr {$y / $l}]
                set z [expr {$z / $l}]
            }
        }
        method * {f} {
            snit::double validate $f
            return [$type create %AUTO% [expr {$x * $f}] [expr {$y * $f}] [expr {$z * $f}]]
        }
        method / {f} {
            snit::double validate $f
            return [$type create %AUTO% [expr {$x / $f}] [expr {$y / $f}] [expr {$z / $f}]]
        }
        method + {v} {
            $type validate $v
            return [$type create %AUTO% [expr {$x + [$v GetX]}] [expr {$y + [$v GetY]}] [expr {$z + [$v GetZ]}]]
        }
        method - {v} {
            $type validate $v
            return [$type create %AUTO% [expr {$x - [$v GetX]}] [expr {$y - [$v GetY]}] [expr {$z - [$v GetZ]}]]
        }
        method ExternalProduct {v} {
            $type validate $v
            return [$type create %AUTO% [expr {$y*[$v GetZ]-$z*[$v GetY]}] [expr {$z*[$v GetX]-$x*[$v GetZ]}] [expr {$x*[$v GetY]-$y*[$v GetX]}]]
        }
        method Cross {v} {
            $type validate $v
            return [$type create %AUTO% [expr {$y*[$v GetZ]-$z*[$v GetY]}] [expr {$z*[$v GetX]-$x*[$v GetZ]}] [expr {$x*[$v GetY]-$y*[$v GetX]}]]
        }
        method ScalarProduct {v} {
            $type validate $v
            return [expr {($x*[$v GetX])+($y*[$v GetY])+($z*[$v GetZ])}]
        }
        method == {v} {
            $type validate $v
            if {$x != [$v GetX]} {return no}
            if {$y != [$v GetY]} {return no}
            if {$z != [$v GetZ]} {return no}
            return yes
        }
        method != {v} {
            return [expr {![$self == $v]}]
        }
        method rotate {omega_per i omega_nod} {
            snit::double validate $omega_per
            snit::double validate $i
            snit::double validate $omega_nod
            
            set s_i [expr {sin($i)}]
            set c_i [expr {cos($i)}]
            #
            set s_on [expr {sin($omega_nod)}]
            set c_on [expr {cos($omega_nod)}]
            #
            set s_op [expr {sin($omega_per)}]
            set c_op [expr {cos($omega_per)}]
            
            set new_x [expr {$c_on*($x*$c_op - $y*$s_op) + $s_on*($z*$s_i - $c_i*($y*$c_op + $x*$s_op))}]
            set new_y [expr {-($z*$c_on*$s_i) + $c_i*$c_on*($y*$c_op + $x*$s_op) + $s_on*($x*$c_op - $y*$s_op)}]
            set new_z [expr {$z*$c_i + $s_i*($y*$c_op + $x*$s_op)}]
            
            set x $new_x
            set y $new_y
            set z $new_z
        }
        constructor {_x _y _z args} {
            set x $_x
            set y $_y
            set z $_z
            $self configurelist $args
        }
        typemethod copy {name other} {
            $type validate $other
            return [$type create $name [$other GetX] [$other GetY] [$other GetZ] -par [$other cget -par]]
        }
        typemethod validate {object} {
            if {[catch {$object info type} otype]} {
                error [format {%s is not a %s} $object $type]
            } elseif {$type ne $otype} {
                error [format {%s is not a %s} $object $type]
            } else {
                return $object
            }
        }
        
        typemethod Interpolate {vx_in x v_outName err_v_outName} {
            upvar $v_outName v_out
            upvar $err_v_outName err_v_out
            orsa::Vector_list validate $vx_in
            snit::double validate $x
            if {[catch {orsa::Vector validate $v_out}]} {
                set v_out [orsa::Vector %AUTO% 0 0 0]
            }
            if {[catch {orsa::Vector validate $err_v_out}]} {
                set err_v_out [orsa::Vector %AUTO% 0 0 0] 
            }
            
            set n_points [llength $vx_in]
            if {$n_points < 2} {
                puts stderr "too few points..."
                $v_out = [lindex $vx_in 0]
                $err_v_out = [orsa::Vector %AUTO% 0 0 0]
                return
            }
            set c [list]
            set d [list]
            set w [orsa::Vector %AUTO% 0 0 0]
            set diff [expr {abs($x - [[lindex $vx_in 0] cget -par])}]
            set i_closest 0
            set j 0
            foreach vp_j $vx_in {
                set tmp_double [expr {abs($x - [$vp_j cget -par])}]
                if {$tmp_double < $diff} {
                    set diff $tmp_double
                    set i_closest $j
                }
                lappend c $vp_j
                lappend d $vp_j
                incr j
            }
            $v_out = [lindex $vx_in $i_closest]
            $err_v_out = [lindex $vx_in $i_closest]
            incr i_closest -1
            
            for {set m 1} {$m <= ($n_points - 2)} {incr m} {
                for {set i 0} {$i < ($n_points - $m)} {incr i} {
                    set ho [expr {[[lindex $vx_in $i] cget -par] - $x}]
                    set hp [expr {[[lindex $vx_in [expr {$i + $m}]] cget -par] - $x}]
                    set denom [expr {$ho - $hp}]
                    if {$denom == 0} {
                        puts stderr "interpolate() --> Error: divide by zero"
                        puts stderr "i: $i  m: $m"
                        set j 0
                        foreach vp_j $vx_in {
                            puts stderr "vx_in\[$j\].par = [$vp_j cget -par]"
                            incr j
                        }
                        error "interpolate() --> Error: divide by zero"
                        return
                    }
                    set w [[lindex $c [expr {$i + 1}]] + [lindex $d $i]]
                    lset d $i [[$w / $denom] * $hp]
                    lset c $i [[$w / $denom] * $ho]
                }
                if { (2*$i_closest) < ($n_points-$m) } {
                    $err_v_out Set [lindex $c [expr {$i_closest + 1}]]
                } else {
                    $err_v_out Set [lindex $d $i_closest]
                    incr i_closest -1
                }
                $v_out += $err_v_out
            }
        }
    }
}
