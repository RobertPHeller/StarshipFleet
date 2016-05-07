#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sun Apr 3 13:06:27 2016
#  Last Modified : <160507.0924>
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
package require control

namespace import control::*


namespace eval orsa {
    snit::type Orbit {
        #typevariable epsilon 1e-323
        typevariable epsilon 1e-17
        option -a -default 0.0 -type snit::double
        option -e -default 0.0 -type snit::double
        option -i -default 0.0 -type snit::double
        option -omega_node -default  0.0 -type snit::double
        option -omega_pericenter -default  0.0 -type snit::double
        option -m_ -default 0.0 -type snit::double
        option -mu -default 0.0  -type snit::double;# G*(m+M)
        constructor {args} {$self configurelist $args}
        method Period {} {
            set mu [$self cget -mu]
            set a  [$self cget -a]
            return [expr {secure_sqrt(4*$orsa::pisq*$a*$a*$a/$mu)}]
        }
        method GetE {} {
            if {[$self cget -e] >= 1.0} {
                # ORSA_WARNING("orsa::Orbit::GetE() called with eccentricity = %g; returning M.",e);
                return [$self cget -m_]
            }
            set E 0.0
            set M [$self cget -m_]
            set e [$self cget -e]
            if {$e < 0.8} {
                set sm [expr {sin($M)}]
                set cm [expr {cos($M)}]
                set x [expr {$M + $e*$sm*( 1.0 + $e*( $cm + $e*( 1.0 -1.5*$sm*$sm)))}]
                set sx 0.0
                set cx 0.0
                set E $x
                set old_E 0.0
                set es 0.0
                set ec 0.0
                set f 0.0
                set fp 0.0
                set fpp 0.0 
                set fppp 0.0
                set dx 0.0
                set count 0
                set max_count  128
                do {
                    set sx   [expr {sin($x)}]
                    set cx   [expr {cos($x)}]
                    set es   [expr {$e*$sx}]
                    set ec   [expr {$e*$cx}]
                    set f    [expr {$x - $es  - $M}]
                    set fp   [expr {1.0 - $ec}]
                    set fpp  $es
                    set fppp $ec 
                    #puts stderr "*** $self GetE (e < .8): f = $f"
                    if {abs($f) < $epsilon} {
                        set f [expr {[signof $f] * $epsilon}]
                    }
                    set dx   [expr {-$f/double($f)}]
                    set dx   [expr {-$f/($fp + $dx*$fpp/2.0)}]
                    set dx   [expr {-$f/double($fp + $dx*$fpp/2.0 + $dx*$dx*$fppp/6.0)}]
                    #
                    set old_E $E
                    set E    [expr {$x + $dx}]
                    incr count
                    # update x, ready for the next iteration
                    set x $E
                } while {(abs($E-$old_E) > (400*(abs($E)+abs($M))*$epsilon)) && ($count < $max_count)}
                if {$count >= $max_count} {
                    puts stderr [format "Orbit::GetE(): max count reached, e = %g    E = %g fabs(E-old_E) = %g   400*(fabs(E)+fabs(M))*std::numeric_limits<double>::epsilon() = %g" $e $E [expr {abs($E-$old_E)}] [expr {400*(abs($E)+abs($M))*$epsilon}]]
                }
            } else {
                set m [expr {fmod(10*$orsa::twopi+fmod($M,$orsa::twopi),$orsa::twopi)}]
                set iflag false
                if {$m > $orsa::pi} {
                    set m [expr {$orsa::twopi - $m}]
                    set iflag true
                }
                set x [expr {secure_pow(6.0*$m,1.0/3.0) - $m}]
                set E $x
                set old_E 0.0
                set es 0.0
                set ec 0.0
                set f 0.0
                set fp 0.0
                set fpp 0.0 
                set fppp 0.0
                set dx 0.0
                set count 0
                set max_count  128
                do {
                    set sa [expr {sin($x+$m)}]
                    set ca [expr {cos($x+$m)}]
                    set esa [expr {$e*$sa}]
                    set eca [expr {$e*$ca}]
                    set f [expr {$x - $esa}]
                    set fp [expr {1.0 - $eca}]
                    #puts stderr "*** $self GetE (e >= .8): f = $f"
                    if {abs($f) < $epsilon} {
                        set f [expr {[signof $f] * $epsilon}]
                    }
                    set dx [expr {-$f/double($fp)}]
                    set dx [expr {-$f/($fp + 0.5*$dx*$esa)}]
                    set dx [expr {-$f/($fp + 0.5*$dx*($esa+1.0/3.0*$eca*$dx))}]
                    set x  [expr {$x + $dx}]
                    #
                    set old_E $E
                    set E [expr {$x + $m}]
                    incr count;
                    
                } while {(abs($E-$old_E) > (10*(abs($E)+abs($M)+$orsa::twopi)*$epsilon)) && ($count < $max_count)}
                if {$iflag} {
                    set E [expr {$orsa::twopi - $old_E}]
                }
                if {$count >= $max_count} {
                    puts stderr [format "Orbit::GetE(): max count reached, e = %g    E = %g fabs(E-old_E) = %g   10*(fabs(E)+fabs(M))*std::numeric_limits<double>::epsilon() = %g" $e $E [expr {abs($E-$old_E)}] [expr {10*(abs($E)+abs($M))*$epsilon}]]
                }
            }
            if {$E == 0.0} {
                error "E==0.0 in orsa::Orbit::GetE(); this should never happen."
            }
            return $E
        }
        proc signof {x} {
            if {$x < 0} {
                return -1.0
            } else {
                return 1.0
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
        method RelativePosVel {relative_positionName relative_velocityName} {
            upvar $relative_positionName relative_position
            upvar $relative_velocityName relative_velocity
            if {![info exists relative_position] ||
                $relative_position eq {}} {
                set relative_position [orsa::Vector %AUTO% 0 0 0]
            }
            orsa::Vector validate $relative_position
            if {![info exists relative_velocity] ||
                $relative_velocity eq {}} {
                set relative_velocity  [orsa::Vector %AUTO% 0 0 0]
            }
            orsa::Vector validate $relative_velocity
            
            #/////////////////////////////////////////////////////
            #// This alghoritm is taken from the swift package, 
            #// ORBEL_EL2XV.F file written by M. Duncan.
            #/////////////////////////////////////////////////////
            # (by way of the ORSA package, translated from C++ to Tcl by 
            # Robert Heller <heller@deepsoft.com>)
    
            # Generate rotation matrices (on p. 42 of Fitzpatrick)
    
            # double sp,cp,so,co,si,ci;
            
            set sp [expr {sin([$self cget -omega_pericenter])}]
            set cp [expr {cos([$self cget -omega_pericenter])}]
            
            set so [expr {sin([$self cget -omega_node])}]
            set co [expr {cos([$self cget -omega_node])}]
            
            set si [expr {sin([$self cget -i])}]
            set ci [expr {cos([$self cget -i])}]   
            
            set d1 [orsa::Vector %AUTO% \
                    [expr {$cp*$co - $sp*$so*$ci}] \
                    [expr {$cp*$so + $sp*$co*$ci}] \
                    [expr {$sp*$si}]]
            set d2 [orsa::Vector %AUTO% \
                    [expr {-$sp*$co - $cp*$so*$ci}] \
                    [expr {-$sp*$so + $cp*$co*$ci}] \
                    [expr {$cp*$si}]]
    
            # Get the other quantities depending on orbit type
    
            set cape 0.0
            set tmp  0.0
            
            set xfac1 0.0
            set xfac2 0.0
            set vfac1 0.0
            set vfac2 0.0
    
            set capf 0.0
            set shcap 0.0
            set chcap 0.0
            set zpara 0.0
            
            set e [$self cget -e]
            set mu [$self cget -mu]
            set a  [$self cget -a]
            if {$e < 1.0} {
      
                #/* 
                #int count = 0;
                #cape = M;
                #do {
                #    tmp  = cape;
                #    cape = e * sin(cape) + M;
                #    ++count;
                #} while ( (fabs((cape-tmp)/cape) > 1.0e-15) && (count < 100) );
                #*/
                
                set cape [$self GetE]
      
                #// cerr << "tmp: " << tmp << "  cape: " << cape << "  fabs(cape - tmp)" << fabs(cape - tmp) << endl;
      
                set scap [expr {sin($cape)}]
                set ccap [expr {cos($cape)}]
                
                set sqe [expr {secure_sqrt(1.0 - $e*$e)}]
                set sqgma [expr {secure_sqrt($mu*$a)}]
                
                set xfac1 [expr {$a*($ccap - $e)}]
                set xfac2 [expr {$a*$sqe*$scap}]
                #// ri = 1/r
                set ri [expr {1.0/($a*(1.0 - $e*$ccap))}]
                set vfac1 [expr {-$ri * $sqgma * $scap}]
                set vfac2 [expr { $ri * $sqgma * $ccap * $sqe}]
                
            } elseif {$e > 1.0} {
      
                set x 0.0
                set shx 0.0
                set chx 0.0
                set esh 0.0
                set ech 0.0
                set f 0.0
                set fp 0.0
                set fpp 0.0
                set fppp 0.0
                set dx 0.0
                
                # // use the 'right' value for M -- NEEDED!
                set local_M [$self cget -m_]
                if {abs($local_M-$orsa::twopi) < abs($local_M)} {
                    set local_M [expr {$local_M - $orsa::twopi}]
                }
                
                // begin with a guess proposed by Danby	
                if {$local_M < 0.0} {
                    set tmp [expr {-2.0*$local_M/$e + 1.8}]
                    set x   [expr {-secure_log($tmp)}]
                } else {
                    set tmp [expr {+2.0*$local_M/$e + 1.8}]
                    set x   [expr { secure_log(tmp)}]
                }
                
                set capf $x
      
                set count 0
                do {
                    set x $capf
                    set shx [expr {sinh($x)}]
                    set chx [expr {cosh($x)}]
                    set esh [expr {$e*$shx}]
                    set ech [expr {$e*$chx}]
                    set f [expr {$esh-$x-$local_M}]
                    set fp [expr {$ech - 1.0}]
                    set fpp $esh; 
                    set fppp $ech; 
                    set dx [expr {-$f/$fp}]
                    set dx [expr {-$f/($fp + $dx*$fpp/2.0)}]
                    set dx [expr {-$f/($fp + $dx*$fpp/2.0 + $dx*$dx*$fppp/6.0)}]
                    set capf [expr {$x + $dx}]
                    incr count
                } while {(abs($dx) > 1.0e-14) && ($count < 100)};
                
                set shcap [expr {sinh($capf)}]
                set chcap [expr {cosh($capf)}]
                
                set sqe [expr {secure_sqrt($e*$e - 1.0)}]
                set sqgma [expr {secure_sqrt($mu*$a)}]
                set xfac1 [expr {$a*(e - chcap)}]
                set xfac2 [expr {$a*$sqe*$shcap}]
                set ri [expr {1.0/($a*($e*$chcap - 1.0))}]
                set vfac1 [expr {-$ri * $sqgma * $shcap}]
                set vfac2 [expr { $ri * $sqgma * $chcap * $sqe}]
                
            } else { # e = 1.0 within roundoff errors
                
                set q [$self cget -m_]
                if {q < 1.0e-3} {
                    set zpara [expr {$q*(1.0 - ($q*$q/3.0)*(1.0-$q*$q))}]
                } else {
                    set x [expr {0.5*(3.0*$q+secure_sqrt(9.0*($q*$q)+4.0))}]
                    # double tmp = secure_pow(x,(1.0/3.0));
                    set tmp [expr {cbrt($x)}]
                    set zpara [expr {$tmp - 1.0/$tmp}]
                }
                
                set sqgma [expr {secure_sqrt(2.0*$mu*$a)}]
                set xfac1 [expr {$a*(1.0 - $zpara*$zpara)}]
                set xfac2 [expr {2.0*$a*$zpara}]
                set ri    [expr {1.0/($a*(1.0 + $zpara*$zpara))}]
                set vfac1 [expr {-$ri * $sqgma * $zpara}]
                set vfac2 [expr { $ri * $sqgma}]
                
            }
            
            $relative_position = [[$d1 * $xfac1] + [$d2 * $xfac2]]
            $relative_velocity = [[$d1 * $vfac1] + [$d2 * $vfac2]]
        }
        method {Compute Body} {b ref_b} {
            orsa::Body validate $b
            orsa::Body validate $ref_b
            set dr [[$b position] - [$ref_b position]]
            set dv [[$b velocity] - [$ref_b velocity]]
            set mu [expr {[orsa::GetG] * ([$b mass] + [$ref_b mass])}]
            $self Compute Vector $dr $dv $mu
        }
        method {Compute Vector} {relative_position relative_velocity mu_in} {
            orsa::Vector validate $relative_position
            orsa::Vector validate $relative_velocity
            snit::double validate $mu_in
            
            #/////////////////////////////////////////////////////
            #// This alghoritm is taken from the swift package, 
            #// ORBEL_XV2EL.F file written by M. Duncan.
            #/////////////////////////////////////////////////////
            # (by way of the ORSA package, translated from C++ to Tcl by 
            # Robert Heller <heller@deepsoft.com>)
                
            set mu $mu_in
    
            set tiny 1.0e-100;#  about 4.0e-15
    
            # internals
            set face 0.0
            set cape 0.0
            set capf 0.0
            set tmpf 0.0
            set cw   0.0
            set sw   0.0
            set w    0.0
            set u    0.0
            set ialpha 0
    
            # angular momentum
            set  h [$relative_position ExternalProduct $relative_velocity]
    
            set h2 [$h LengthSquared]
            set hh [$h Length]
    
            # inclination
            set i [expr {secure_acos([$h GetZ]/$hh)}]
            
    
            # Compute longitude of ascending node omega_node and the argument of latitude u
            # double fac = secure_sqrt(secure_pow(h.x,2)+secure_pow(h.y,2))/h2;
            set fac [expr {secure_sqrt([$h GetX]*[$h GetX]+[$h GetY]*[$h GetY])/$h2}];
            
            if {$fac < $tiny} {
                set omega_node 0.0
                set u [expr {secure_atan2([$relative_position GetY], [$relative_position GetX])}]
                if { fabs($i-$orsa::pi) < 10.0 * $tiny } {
                    set u [expr {-$u}] 
                }
            } else {
                set omega_node [expr {secure_atan2([$h GetX],-[$h GetY])}]
                set u [expr {secure_atan2([$relative_position GetZ]/sin($i), [$relative_position GetX]*cos($omega_node)+[$relative_position GetY]*sin($omega_node))}]
            }
            
            if {$omega_node < 0.0} {
                set omega_node [expr {$omega_node + $orsa::twopi}]
            }
            if {$u < 0.0} {
                set u [expr {$u + $orsa::twopi}]
            }
            
            #  Compute the radius r and velocity squared v2, and the dot
            #  product rdotv, the energy per unit mass energy 
            set r  [$relative_position Length]
            set v2 [$relative_velocity LengthSquared]
            
            set vdotr [$relative_position ScalarProduct $relative_velocity]
            
            set energy [expr {$v2/2.0 - $mu/$r}]
            
            # Determine type of conic section and label it via ialpha
            if {abs($energy*$r/$mu) < $tiny} {
                set ialpha 0
            } else {
                if {$energy < 0} {set ialpha -1}
                if {$energy > 0} {set ialpha +1}
            }
            
            # Depending on the conic type, determine the remaining elements 
            
            # ellipse 
            if {$ialpha == -1} {
                 
                set a [expr {-$mu/(2.0*$energy)}]
                
                set fac [expr {1.0 - $h2/($mu*$a)}] 
                
                if {$fac > $tiny} {
                    set e [expr {secure_sqrt($fac)}]
                    set face [expr {($a-$r)/($a*$e)}]
                    
                    if {$face > 1.0} {
                        set cape 0.0
                    } else {
                        if {$face > -1.0} {
                            set cape [expr {secure_acos($face)}]
                        } else {
                            set cape $orsa::pi
                        }
                    }
                        
                    if {$vdotr < 0.0} {set cape [expr {$orsa::twopi - $cape}]}
                    set cw [expr {(cos($cape)-$e)/(1.0-$e*cos($cape))}]
                    set sw [expr {secure_sqrt(1.0-$e*$e)*sin($cape)/(1.0-$e*cos($cape))}]
                    set w  [expr {secure_atan2($sw,$cw)}]
                    if {$w < 0.0} {set w [expr {$w + $orsa::twopi}]}
                    
                } else {
                    set e 0.0
                    set w $u
                    set cape $u
                }
                
                set M [expr {$cape - $e*sin($cape)}]
                set omega_pericenter [expr {$u - $w}]
                if {$omega_pericenter < 0} {
                    set omega_pericenter [expr {$omega_pericenter + $orsa::twopi}]
                }
                set omega_pericenter [expr {fmod($omega_pericenter,$orsa::twopi)}]
                
            }
            
            # hyperbola
            if {$ialpha == 1} {
                set a [expr {$mu/(2.0*$energy)}]
                set fac [expr {$h2/($mu*$a)}]
                
                if {$fac > $tiny} {
                    set e [expr {secure_sqrt(1.0+$fac)}]
                    set tmpf [expr {($a+$r)/($a*$e)}]
                    if {$tmpf < 1.0} {set tmpf 1.0}
                    
                    set capf [expr {secure_log($tmpf+secure_sqrt($tmpf*$tmpf-1.0))}]
                    
                    if {$vdotr < 0.0} {set capf [expr {-$capf}]}
                    
                    set cw [expr {($e-cosh($capf))/($e*cosh($capf)-1.0)}]
                    set sw [expr {secure_sqrt($e*$e-1.0)*sinh($capf)/($e*cosh($capf)-1.0)}]
                    set w  [expr {secure_atan2($sw,$cw)}]
                    if {$w < 0.0} {set w [expr {$w + $orsa::twopi}]}
                } else {
                    # we only get here if a hyperbola is essentially a parabola 
                    # so we calculate e and w accordingly to avoid singularities
                    set e 1.0
                    set tmpf [expr {$h2/(2.0*$mu)}]
                    set w    [expr {secure_acos(2.0*$tmpf/$r - 1.0)}]
                    if {$vdotr < 0.0} {set w [expr {$orsa::twopi - $w}]}
                    set tmpf [expr {($a+$r)/($a*$e)}]
                    set capf [expr {secure_log($tmpf+secure_sqrt($tmpf*$tmpf-1.0))}]
                }
                
                set M [expr {$e * sinh($capf) - $capf}]
                set omega_pericenter [expr {$u - $w}]
                if {$omega_pericenter < 0} {
                    set omega_pericenter [expr {$omega_pericenter + $orsa::twopi}]
                }
                set omega_pericenter [expr {fmod($omega_pericenter,$orsa::twopi)}]
            }
            
            # parabola
            #  NOTE - in this case we use "a" to mean pericentric distance
            if {$ialpha == 0} {
                set a [expr {0.5*$h2/$mu}]
                set e 1.0
                set w [expr {secure_acos(2.0*$a/$r -1.0)}]
                if {$vdotr < 0.0} {
                    set w [expr {$orsa::twopi - $w}]
                }
                set tmpf [expr {tan(0.5*$w)}]
                
                set M [expr {$tmpf*(1.0+$tmpf*$tmpf/3.0)}]
                set omega_pericenter [expr {$u - $w}]
                if {$omega_pericenter < 0} {
                    set omega_pericenter [expr {$omega_pericenter + $orsa::twopi}]
                }
                set omega_pericenter [expr {fmod($omega_pericenter,$orsa::twopi)}]
            }
            
            # Stash the orbit parameters
            $self configure \
                  -a $a \
                  -e $e \
                  -i $i \
                  -omega_node $omega_node \
                  -omega_pericenter $omega_pericenter \
                  -m_ $M \
                  -mu $mu
        }
    }
    snit::type OrbitWithEpoch {
        component orbit
        delegate option * to orbit
        delegate method * to orbit
        option -epoch -type {snit::integer -min 0} -default 0
        constructor {args} {
            install orbit using Orbit %AUTO%
            $self configurelist $args
        }
        method {Compute Vector} {relative_position relative_velocity mu epoch_in} {
            $self configure -epoch $epoch_in
            $orbit Compute Vector $relative_position $relative_velocity $mu
        }
        method {Compute Body} {b ref_b epoch_in} {
            $self configure -epoch $epoch_in
            $orbit Compute Body $b $ref_b
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
        typemethod copy {o {name %AUTO%}} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s or %s" $o $type [$orbit info type]]
            } elseif {$ot eq "::orsa::Orbit"} {
                set epoch 0
            } elseif {$ot eq $type} {
                set epoch [$o cget -epoch]
            }
            return [$type create $name \
                    -a [$o cget -a] \
                    -e [$o cget -e] \
                    -i [$o cget -i] \
                    -omega_node [$o cget -omega_node] \
                    -omega_pericenter [$o cget -omega_pericenter] \
                    -m_ [$o cget -m_] \
                    -mu [$o cget -mu] \
                    -epoch $epoch]
        }
        method RelativePosVelAtTime {relative_positionName relative_velocityName epoch_in} {
            upvar $relative_positionName relative_position
            upvar $relative_velocityName relative_velocity
            set o [$type copy $self]
            #puts stderr "*** $self RelativePosVelAtTime: epoch_in = $epoch_in"
            #puts stderr "*** $self RelativePosVelAtTime: base M = [$o cget -m_]"
            set M [expr {[$o cget -m_] + $::orsa::twopi*double($epoch_in - [$self cget -epoch])/double([$self Period])}]
            #puts stderr "*** $self RelativePosVelAtTime: M = $M"
            set M [expr {fmod(10*$::orsa::twopi+fmod($M,$::orsa::twopi),$::orsa::twopi)}]
            #puts stderr "*** $self RelativePosVelAtTime: fmod'd M = $M"
            $o configure -m_ $M
            $o RelativePosVel relative_position relative_velocity
        }
    }
    namespace export Orbit OrbitWithEpoch
}

