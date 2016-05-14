#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Wed May 11 12:56:03 2016
#  Last Modified : <160514.1151>
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

package require struct::matrix


namespace eval orsa {
    snit::type TreeNode_ListInterator {
        variable parentnode
        variable index
        constructor {_p _i} {
            set parentnode $_p
            set index $_i
        }
        method getnode {
            if {$index < [$parentnode child size]} {
                return [$parentnode child get $index]
            } else {
                return {}
            }
        }
        method ++ {} {
            incr index
        }
        method isend {} {
            if {$index < [$parentnode child size]} {
                return false
            } else {
                return true
            }
        }
        method parentnode_eq {pn} {return [expr {$pn eq $parentnode}]}
        method index_== {in} {return [expr {$in == $index}]}
        method == {other} {
            if {[$other parentnode_eq $parentnode] &&
                [$other index_== $index]} {
                return true
            } else {
                return false
            }
        }
        method != {other} {
            if {[$self == $other]} {
                return false
            } else {
                return true
            }
        }
            
    }
    
    snit::type Stack {
        variable stack {}
        constructor {args} {
        }
        method push {it} {
            set stack [linsert $stack 0 $it]
        }
        method top {} {
            return [lindex $stack 0]
        }
        method pop {} {
            set t [lindex $stack 0]
            set stack [lrange $stack 1 end]
        }
        method size {} {
            return [llength $stack]
        }
    }
    
    snit::type TreeNode {
        variable b [list];# of Body
        variable child [list];# of TreeNode
        variable o [Vector %AUTO% 0 0 0]
        variable l 0.0
        variable depth 0
        variable _node_mass 0.0
        variable bool_node_mass_computed false
        variable _node_quadrupole 
        variable bool_node_quadrupole_computed false
        variable _node_center_of_mass
        variable bool_node_center_of_mass_computed false
        method reset {} {
            set bool_node_mass_computed false
            set bool_node_quadrupole_computed false
            set bool_node_center_of_mass_computed false
            set depth 0
            if {![info exists _node_quadrupole]} {
                set _node_quadrupole [struct::matrix]
            }
            if {![info exists _node_center_of_mass]} {
                set _node_center_of_mass [Vector %AUTO% 0 0 0]
            }
        }
        method SetO {v} {
            $o Set $v
        }
        method SetDepth {i} {set depth $i}
        method GetDepth {} {return $depth}
        method SetL {x} {set l $x}
        method GetL {} {return $l}
        
        destructor {
            catch {$_node_quadrupole destroy}
        }
        constructor {args} {
            $self reset
        }
        
        method {body add} {_b} {
            ::orsa::Body validate $_b
            lappend b $_b
        }
        method {body get} {i} {
            return [lindex $b $i]
        }
        method {body size} {} {
            return [llength $b]
        }
        method {body empty} {} {[expr {[llength $b] == 0}]}
        method {child size} {} {
            return [llength $child]
        }
        method {child add} {_c} {
            $type validate $_c
            lappend child $_c
        }
        method {child get} {i} {
            return [lindex $child $i]
        }
        method {child empty} {} {[expr {[llength $child] == 0}]}
        
        method {child begin} {} {
            return [TreeNode_ListInterator create %AUTO% $self 0]
        }
        method {child end} {} {
            return [TreeNode_ListInterator create %AUTO% $self [llength $child]]
        }
        
        method inside_domain {p} {
            ::orsa::Vector validate $p
            if {[$p GetX] < [$o GetX]} return false
            if {[$p GetY] < [$o GetY]} return false
            if {[$p GetZ] < [$o GetZ]} return false
            if {[$p GetX] > ([$o GetX] + $l)} return false
            if {[$p GetY] > ([$o GetY] + $l)} return false
            if {[$p GetZ] > ([$o GetZ] + $l)} return false
            return true
        }
        method is_leaf {} {
            if {[llength $child] == 0 &&
                [llength $b] != 0} {
                return true
            } else {
                return false
            }
        }
        method node_mass {} {
            if {$bool_node_mass_computed} {return $_node_mass}
            set _node_mass 0.0
            foreach c_it $child {
                set _node_mass [expr {$_node_mass + [$c_it node_mass]}]
            }
            foreach b_it $b {
                set _node_mass [expr {$_node_mass + [$b_it mass]}]
            }
            set bool_node_mass_computed true
            return $_node_mass
        }
        method node_quadrupole {} {
            if {$bool_node_quadrupole_computed} {
                return $_node_quadrupole
            }
            $_node_quadrupole deserialize {3 3 {{0 0 0} {0 0 0} {0 0 0}}}
            set x [::struct::matrix]
            $x deserialize {3 1 {0 0 0}}
            set l_sq 0.0
            set c_node_quadrupole [::struct::matrix]
            set vec [Vector %AUTO% 0 0 0]
            foreach c_it $child {
                $vec = [[$c_it node_center_of_mass] - [$self node_center_of_mass]]
                $x set cell 0 0 [$vec GetX]
                $x set cell 0 1 [$vec GetY]
                $x set cell 0 2 [$vec GetZ]
                set l_sq [$vec LengthSquared]
                $c_node_quadrupole = [$c_it node_quadrupole]
                for {set i 0} {$i < 3} {incr i} {
                    for {int j 0} {$j < 3} {incr j} {
                        $_node_quadrupole set cell $i $j \
                              [expr {[$_node_quadrupole get cell $i $j] + \
                               ([$c_it node_mass] * (3.0*[$x get cell 0 $i]*[$x get cell 0 $j]-$l_sq*[delta_function $i $j]) + [$c_node_quadrupole get cell $i $j])}]
                    }
                }
            }
            $c_node_quadrupole destroy
            foreach b_it $b {
                $vec = [[$b position] - [$self node_center_of_mass]]
                $x set cell 0 0 [$vec GetX]
                $x set cell 0 1 [$vec GetY]
                $x set cell 0 2 [$vec GetZ]
                for {set i 0} {$i < 3} {incr i} {
                    for {int j 0} {$j < 3} {incr j} {
                        $_node_quadrupole set cell $i $j \
                              [expr {[$_node_quadrupole get cell $i $j] + \
                               ([$b_it mass]  * (3.0*[$x get cell 0 $i]*[$x get cell 0 $j]-$l_sq*[delta_function $i $j]))}]
                    }
                }
            }
            $vec destroy
            $x destroy
            set bool_node_mass_computed true
            return $_node_quadrupole
        }
        method node_center_of_mass {} {
            if {$bool_node_center_of_mass_computed} {return $_node_center_of_mass}
            set vec_sum [Vector %AUTO% 0 0 0]
            set mass_sum 0.0
            foreach c_it $child {
                $vec_sum += [[$c_it node_center_of_mass] * [$c_it node_mass]]
                set mass_sum [expr {$mass_sum + [$c_it node_mass]}]
            }
            foreach b_it $b {
                $vec_sum += [[$b_it position] * [$b_it mass]]
                set mass_sum [expr {$mass_sum + [$b_it mass]}]
            }
            $_node_center_of_mass = [$vec_sum / $mass_sum]
            set bool_node_center_of_mass_computed true
            return $_node_center_of_mass
        }
        method BuildMesh {{root false}} {
            snit::boolean validate $root
            if {[llength $b] < 2} {return}
            if {$root} {
                set depth 0
                set p [Vector %AUTO% 0 0 0]
                $o = [$p = [[lindex $b 0] position]]
                set r [Vector %AUTO% 0 0 0]
                set total_bodies 1
                foreach b_it [lrange $b 1 end] {
                    $r = [$b_it position]
                    if {[$r GetX] < [$o GetX]} {$o SetX [$r GetX]}
                    if {[$r GetY] < [$o GetY]} {$o SetY [$r GetY]}
                    if {[$r GetZ] < [$o GetZ]} {$o SetZ [$r GetZ]}
                    if {[$r GetX] > [$p GetX]} {$p SetX [$r GetX]}
                    if {[$r GetY] > [$p GetY]} {$p SetY [$r GetY]}
                    if {[$r GetZ] > [$p GetZ]} {$p SetZ [$r GetZ]}
                    incr total_bodies
                }
                set l [expr {[p GetX] - [$o GetX]}]
                if {([$p GetY] - [$o GetY]) > l} {set l [expr {[$p GetY] - [$o GetY]}]}
                if {([$p GetZ] - [$o GetZ]) > l} {set l [expr {[$p GetZ] - [$o GetZ]}]}
                $p destroy
                $r destroy
            }
            
            set d [expr {0.01*$l}]
            $o -= $d
            set l [expr {$l + (2.0*$d)}]
            foreach b_it $b {
                if {![$self inside_domain [$b_it position]]} {
                    puts stderr "WARNING! One body outside domain..."
                }
            }
            set child [list]
            set n.l [expr {$l / 2.0}]
            set n.depth [expr {$depth + 1}]
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [$o GetX] [$o GetY] [$o GetZ]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [$o GetX] [$o GetY] [expr {[$o GetZ] + $n.l}]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [$o GetX] [expr {[$o GetY] + $n.l}] [$o GetZ]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [$o GetX] [expr {[$o GetY] + $n.l}] [expr {[$o GetZ] + $n.l}]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [expr {[$o GetX] + $n.l}] [$o GetY] [$o GetZ]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [expr {[$o GetX] + $n.l}] [$o GetY] [expr {[$o GetZ]] + $n.l}]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [expr {[$o GetX] + $n.l}] [expr {[$o GetY] + $n.l}] [$o GetZ]]
            lappend child $n
            set n [$type create %AUTO%]
            $n SetL $n.l
            $n SetDepth $n.depth
            $n SetO [Vector %AUTO% [expr {[$o GetX] + $n.l}] [expr {[$o GetY] + $n.l}] [expr {[$o GetZ]] + $n.l}]]
            lappend child $n

            set b_index 0
            while {$b_index < [llength $b]} {
                set b_it [lindex $b $b_index]
                set c_index 0
                while {$c_index < [llength $child]} {
                    set c_it [lindex $child $c_index]
                    if {[$c_it inside_domain [$b_it position]]} {
                        $c_it body add $b_it
                        set b [lreplace $b $b_index $b_index]
                        set b_index 0
                        if {[llength $b] == 0} {break}
                        set b_it [lindex $b $b_index]
                        set c_index -1
                    }
                    incr c_index
                }
                incr b_index
            }
            set c_index 0
            while {$c_index < [llength $child]} {
                set c_it [lindex $child $c_index]
                if {[$c_it body empty]} {
                    set child [lreplace $child $c_index $c_index]
                } else {
                    incr c_index
                }
            }
            foreach c_it $child {
                $c_it BuildMesh
            }
        }
        method print {} {
            set bodies [llength $b]
            set childs [llength $child]
            puts [format "node --- depth: %d   childs: %d   mass: %g   cube side: %g   origin: (%g,%g,%g)   bodies: %d\n" $depth $childs [$self node_mass] $l [$o GetX] [$o GetY] [$o GetZ] $bodies]
            foreach it $child {
                $it print
            }
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
    }
    
    snit::type GravitationalTree {
        option -g -default 0.0 -type snit::double
        option -theta -default 0.7 -type snit::double
        constructor {args} {
            set options(-g) [from args -g [::orsa::GetG]]
            $self configurelist $args
        }
        typemethod copy {name other args} {
            return [$type create $name \
                    -g [$other cget -g] \
                    -theta [$other cget -theta]]
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
        proc delta_function {i j} {
            if {$i == $j} {return 1.0}
            return 0.0
        }
        proc ComputeAcceleration {body_it node_domain_it {compute_quadrupole true}} {
            set a [Vector %AUTO% 0 0 0]
            if {[$node_domain_it node_mass] == 0} {return $a}
            set d [[$node_domain_it node_center_of_mass] - [$body_it position]]
            set l2 [$d LengthSquared]
            if {[$d IsZero]} {
                puts stderr [format "*** Warning: two objects in the same position! (%lg)" $l2]
                return $a
            }
            $a += [[$d * [expr {secure_pow($l2,-1.5)}]] * [$node_domain_it node_mass]]
            if {!$compute_quadrupole} {
                return $a
            }
            set x [::struct::matrix]
            $x deserialize [list 3 1 [list [$d GetX] [$d GetY] [$d GetZ]]]
            set coefficient 0.0
            set c_node_quadrupole [$node_domain_it node_quadrupole]
            for {int i 0} {$i < 3} {incr i} {
                for {int j 0} {$j < 3} {incr j} {
                    set coefficient [expr {$coefficient + \
                                     ([$c_node_quadrupole get cell $i $j] * \
                                      [$x get cell 0 $i] [$x get cell 0 $j])}]
                }
            }
            
            $x destroy
            $a += [[$d * [expr {secure_pow($l2,-3.0)}]] * $coefficient]
            return $a
        }
        method Acceleration {f aName} {
            ::orsa::Frame validate $f    
            upvar $aName a
            if {[$f body size] < 2} {return}
            set a [list]
            array unset frame_map
            for {set i 0} {$i < [$f size]} {incr i} {
                lappend a [Vector %AUTO% 0 0 0]
                set frame_map([[$f body get $i] BodyId]) $i
            }
            set root_node [TreeNode create %AUTO%]
            for {set i 0} {$i < [$f size]} {incr i} {
                $root_node body add [$f body get $i]
            }
            $root_node BuildMesh true
            $root_node print
            
            set stk_body [Stack create %AUTO%]
            set stk_domain [Stack create %AUTO%]
            
            set num_direct 0
            set num_domain 0
            set angle 0.0
            set node_body_it [$root_node child begin]
            while {[$node_body_it != [$root_node child end]]} {
                set node_body [$node_body_it getnode]
                if {[$node_body is_leaf]} {
                    set body_it 0
                    while {$body_it < [$node_body body size]} {
                        set body [$node_body body get $body_it]
                        set node_domain_it [$root_node child begin]
                        while {[$node_domain_it != [$root_node child end]]} {
                            set node_domain [$node_domain_it getnode]
                            set angle [expr {[$node_domain GetL] / ([$node_domain node_center_of_mass] - [[$body position] Length])}]
                            if {$angle < $theta} {
                                incr num_domain
                                $node_domain_it ++
                            } else if {[$node_domain is_leaf]} {
                                if {[$body BodyId] != [[$node_domain body get 0] BodyId]} {
                                    [lindex $a $frame_map([$body BodyId])] += \
                                          [ComputeAcceleration $body $node_domain]
                                    incr num_direct
                                }
                                $node_domain_it ++
                            } else {
                                $stk_domain push $node_domain_it
                                set node_domain_it [$node_domain child begin]
                            }
                            while {[$stk_domain size] > 0} {
                                if {[$node_domain_it == [[[$stk_domain top] getnode] child end]]} {
                                    set node_domain_it [$stk_domain top]
                                    $node_domain_it ++
                                    $stk_domain pop
                                } else {
                                    break
                                }
                            }
                        }
                        incr body_it
                    }
                    $node_body_it ++
                } else { # not leaf
                    $stk_body push $node_body_it
                    set node_body_it [$node_body child begin]
                }
                while {[$stk_body size] > 0} {
                    if {[$node_body_it == [[[$stk_body top] getnode] child end]]} {
                        set node_body_it [$stk_body top]
                        $node_body_it ++
                        $stk_body pop
                    } else {
                        break
                    }
                }
            }
            foreach ak $a {
                $ak *= $g
            }
        }     
        
    }



    namespace export GravitationalTree
}

