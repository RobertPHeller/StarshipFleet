#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sat Apr 2 20:44:55 2016
#  Last Modified : <160419.1209>
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
    
    snit::listtype Body_list -type orsa::Body
    
    snit::type BodyConstants {
        #const std::string name_;
        variable name_ ""
        #const double mass_;
        variable mass_ 0
        #const double mu_;
        variable mu_ 0
        #const bool zero_mass_;
        variable zero_mass_ yes
        #const double radius_;
        variable radius_ 0
        #const JPL_planets planet_;
        # -- not using JPL_planets
        #const double J2_, J3_, J4_;
        variable J2_ 0
        variable J3_ 0
        variable J4_ 0
        #const double C22_, C31_, C32_, C33_, C41_, C42_, C43_, C44_; 
        variable C22_ 0
        variable C31_ 0
        variable C32_ 0
        variable C33_ 0
        variable C41_ 0
        variable C42_ 0
        variable C43_ 0
        variable C44_ 0
        #const double       S31_, S32_, S33_, S41_, S42_, S43_, S44_;
        variable S31_ 0
        variable S32_ 0
        variable S33_ 0
        variable S41_ 0
        variable S42_ 0
        variable S43_ 0
        variable S44_ 0
        #static unsigned int used_body_id;
        typevariable used_body_id 0
        #const unsigned int id;
        variable id
        #static std::list<BodyConstants*> list_bc;
        typevariable list_bc [list]
        variable users 1
        constructor {args} {
            incr used_body_id
            set id $used_body_id
            lappend list_bc $self
            if {[llength $args] > 0} {
                set name_ [lindex $args 0]
            }
            if {[llength $args] > 1} {
                set mass [lindex $args 1]
                snit::double validate $mass
                set mass_ $mass
                set zero_mass_ [expr {$mass_ == 0.0}]
                set mu_ [expr {[::orsa::GetG] * $mass_}]
            }
            if {[llength $args] > 2} {
                set radius [lindex $args 2]
                snit::double validate $radius
                set radius_ $radius
            }
            if {[llength $args] > 3} {
                set J2 [lindex $args 3]
                snit::double validate $J2
                set J2_ $J2
            }
            if {[llength $args] > 4} {
                set J3 [lindex $args 4]
                snit::double validate $J3
                set J3_ $J3
            }
            if {[llength $args] > 5} {
                set J4 [lindex $args 5]
                snit::double validate $J4
                set J4_ $J4
            }
            if {[llength $args] > 6} {
                set C22 [lindex $args 6]
                snit::double validate $C22
                set C22_ $C22
            }
            if {[llength $args] > 7} {
                set C31 [lindex $args 7]
                snit::double validate $C31
                set C31_ $C31
            }
            if {[llength $args] > 8} {
                set C32 [lindex $args 8]
                snit::double validate $C32
                set C32_ $C32
            }
            if {[llength $args] > 9} {
                set C33 [lindex $args 9]
                snit::double validate $C33
                set C33_ $C33
            }
            if {[llength $args] > 10} {
                set C41 [lindex $args 10]
                snit::double validate $C41
                set C41_ $C41
            }
            if {[llength $args] > 11} {
                set C42 [lindex $args 11]
                snit::double validate $C42
                set C42_ $C42
            }
            if {[llength $args] > 12} {
                set C43 [lindex $args 12]
                snit::double validate $C43
                set C43_ $C43
            }
            if {[llength $args] > 13} {
                set C44 [lindex $args 13]
                snit::double validate $C44
                set C44_ $C44
            }
            if {[llength $args] > 14} {
                set S31 [lindex $args 14]
                snit::double validate $S31
                set S31_ $S31
            }
            if {[llength $args] > 15} {
                set S32 [lindex $args 15]
                snit::double validate $S32
                set S32_ $S32
            }
            if {[llength $args] > 16} {
                set S33 [lindex $args 16]
                snit::double validate $S33
                set S33_ $S33
            }
            if {[llength $args] > 17} {
                set S41 [lindex $args 17]
                snit::double validate $S41
                set S41_ $S41
            }
            if {[llength $args] > 18} {
                set S42 [lindex $args 18]
                snit::double validate $S42
                set S42_ $S42
            }
            if {[llength $args] > 19} {
                set S43 [lindex $args 19]
                snit::double validate $S43
                set S43_ $S43
            }
            if {[llength $args] > 20} {
                set S44 [lindex $args 20]
                snit::double validate $S44
                set S44_ $S44
            }
        }
        destructor {
            set i [lsearch -exact $list_bc $self]
            if {$i >= 0} {set list_bc [lreplace $list_bc $i $i]}
        }
        method name {} {return $name_}
        method mass {} {return $mass_}
        method mu {} {return $mu_}
        method zero_mass {} {return $zero_mass_}
        method radius {} {return $radius_}
        method J2 {} {return $J2_}
        method J3 {} {return $J3_}
        method J4 {} {return $J4_}
        method C22 {} {return $C22_}
        method C31 {} {return $C31_}
        method C32 {} {return $C32_}
        method C33 {} {return $C33_}
        method C41 {} {return $C41_}
        method C42 {} {return $C42_}
        method C43 {} {return $C43_}
        method C44 {} {return $C44_}
        method S31 {} {return $S31_}
        method S32 {} {return $S32_}
        method S33 {} {return $S33_}
        method S41 {} {return $S41_}
        method S42 {} {return $S42_}
        method S43 {} {return $S43_}
        method S44 {} {return $S44_}
        method BodyId {} {return $id}
        method Id {} {return $id}
        method AddUser {} {incr users}
        method RemoveUser {} {incr users -1}
        method Users {} {return $users}
    }
    snit::type Body {
        component bc
        delegate method * to bc except {AddUser RemoveUser}
        variable _position 
        variable _velocity
        option -par -default 0.0 -type snit::double
        constructor {args} {
            #puts stderr "*** $type create $self $args"
            set par [from args -par 0.0]
            #puts stderr "*** $type create $self: par = $par"
            snit::double validate $par
            #puts stderr "*** $type create $self: par validated"
            set _position [orsa::Vector %AUTO% 0 0 0]
            #puts stderr "*** $type create $self: _position = $_position"
            set _velocity [orsa::Vector %AUTO% 0 0 0]
            #puts stderr "*** $type create $self: _velocity = $_velocity"
            #puts stderr "*** $type create $self: llength \$args is [llength $args]"
            switch [llength $args] {
                1 {
                    set arg [lindex $args 0]
                    if {[catch {snit::double validate $arg}]} {
                        install bc using BodyConstants %AUTO% $arg 0.0
                    } else {
                        install bc using BodyConstants %AUTO% "" $arg 0
                    }
                }
                2 {
                    foreach {name mass} $args {break}
                    install bc using BodyConstants %AUTO% \
                          $name $mass 0
                }
                3 {
                    foreach {name mass radius} $args {break}
                    install bc using BodyConstants %AUTO% \
                          $name $mass $radius
                }
                4 {
                    foreach {name mass position velocity} $args {break}
                    orsa::Vector validate $position
                    orsa::Vector validate $velocity
                    install bc using BodyConstants %AUTO% $name $mass
                    $_position = $position
                    $_velocity = $velocity
                }
                5 {
                    foreach {name mass radius position velocity} $args {break}
                    orsa::Vector validate $position
                    orsa::Vector validate $velocity
                    install bc using BodyConstants %AUTO% $name $mass $radius
                    $_position = $position
                    $_velocity = $velocity
                }
                6 {
                    foreach {name mass radius J2 J3 J4} $args {break}
                    install bc using BodyConstants %AUTO% $name $mass $radius \
                          $J2 $J3 $J4
                }
                7 {
                    foreach {name mass position velocity J2 J3 J4} $args  {break}
                    orsa::Vector validate $position
                    orsa::Vector validate $velocity
                    install bc using BodyConstants %AUTO% $name $mass 0 \
                          $J2 $J3 $J4
                    $_position = $position
                    $_velocity = $velocity
                }
                8 {
                    foreach {name mass radius position velocity J2 J3 J4} $args  {break}
                    orsa::Vector validate $position
                    orsa::Vector validate $velocity
                    install bc using BodyConstants %AUTO% $name $mass $radius \
                          $J2 $J3 $J4
                    $_position = $position
                    $_velocity = $velocity
                }
                21 {
                    foreach {name mass radius J2 J3 J4 C22 C31 C32 C33 C41 C42 C43 C44 S31 S32 S33 S41 S42 S43 S44} $args {break}
                    install bc using BodyConstants %AUTO% $name $mass $radius \
                          $J2 $J3 $J4 $C22 $C31 $C32 $C33 $C41 $C42 $C43 $C44 \
                          $S31 $S32 $S33 $S41 $S42 $S43 $S44
                }
                default {
                    error "Wrong number of arguments!"
                }
            }
            #puts stderr "*** $type create $self: bc = \{$bc\}"
        }
        method = {b} {
            $type validate $b
            set b_bc [$b info vars bc]
            #puts stderr "*** $self =: bc = \{$bc\}, b_bc = \{$b_bc\}"
            if {[set $b_bc] ne $bc} {
                $bc RemoveUser
                if {[$bc Users] == 0} {
                    $bc destroy
                    unset bc
                }
                set bc [set $b_bc]
                $bc AddUser
            }
            set _position [$b position]
            set _velocity [$b velocity]
            return $self
        }
        destructor {
            #puts stderr "*** $self destroy: bc = \{$bc\}"
            $bc RemoveUser
            if {[$bc Users] == 0} {
                $bc destroy
                unset bc
            }
        }
        method position {} {return $_position}
        method velocity {} {return $_velocity}
        method AddToPosition {v} {$_position += $v}
        method AddToVelocity {v} {$_velocity += $v}
        method SetPosition {v} {$_position = $v}
        method SetPositionXYZ {x y z} {
            $self SetPosition [orsa::Vector %AUTO% $x $y $z]
        }
        method SetVelocity {v} {$_velocity = $v}
        method SetVelocityXYZ {x y z} {
            $self SetVelocity [orsa::Vector %AUTO% $x $y $z]
        }
        method distanceVector {b} {
            $type validate $b
            return [[$b position] - [$self position]]
        }
        method distance {b} {
            $type validate $b
            return [[$self distanceVector $b] Length]
        }
        method DistanceVector {b} {return [$self distanceVector $b]}
        method Distance {b} {return [$self distance $b]}
        method KineticEnergy {} {
            return [expr {[$bc mass] * [$_velocity LengthSquared] / 2.0}]
        }
        method < {b} {
            $type validate $b
            return [expr {[$b mass] < [$self mass]}]
        }
        method == {b2} {
            $type validate $b2
            if {[$self BodyId]   != [$b2 BodyId]} {return false}
            if {[$self name]     ne [$b2 name]} {return false}
            if {[$self mass]     != [$b2 mass]} {return false}
            if {[$self position] != [$b2 position]} {return false}
            if {[$self velocity] != [$b2 velocity]} {return false}
            return true
        }
        method != {b2} {
            $type validate $b2
            return [expr {![$self == $b2]}]
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
        
        
        typemethod Interpolate {b_in x b_outName err_b_outName} {
            orsa::Body_list validate $b_in
            snit::double validate $x
            upvar $b_outName b_out
            orsa::Body validate $b_out
            upvar $err_b_outName err_b_out
            orsa::Body validate $err_b_out
            
            set n_points [llength $b_in]
            
            set p_interpolated [orsa::Vector %AUTO% 0 0 0]
            set err_p_interpolated [orsa::Vector %AUTO% 0 0 0]
            set v_interpolated [orsa::Vector %AUTO% 0 0 0]
            set err_v_interpolated [orsa::Vector %AUTO% 0 0 0]
            
            set pp [list]
            set vv [list]
            
            foreach b $b_in {
                set p [$b position]
                lappend pp [orsa::Vector %AUTO% [$p GetX] [$p GetY] [$p GetZ] -par [$b cget -par]]
                set v [$b velocity]
                lappend vv [orsa::Vector %AUTO% [$v GetX] [$v GetY] [$v GetZ] -par [$b cget -par]]
            }
            Vector Interpolate $pp $x p_interpolated err_p_interpolated
            Vector Interpolate $vv $x v_interpolated err_v_interpolated
            $b_out = [lindex $b_in 0]
            $b_out SetPosition $p_interpolated
            $b_out SetVelocity $v_interpolated
            $err_b_out  = [lindex $b_in 0]
            $err_b_out SetPosition $err_p_interpolated
            $err_b_out SetVelocity $err_v_interpolated
            
        }
        
        typemethod print {b {fp stdout}} {
            puts $fp [format "Body name %s   mass %15.10g" [$b name] [$b mass]]
            set p [$b position]
            puts $fp [format "position  %15.10g %15.10g %15.10g" [$p GetX] [$p GetY] [$p GetZ]]
            set v [$b velocity]
            puts $fp [format "velocity  %15.10g %15.10g %15.10g" [$v GetX] [$v GetY] [$v GetZ]]
        }
        
    }
    namespace export Body_list Body
}
