#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Fri Apr 8 13:01:31 2016
#  Last Modified : <160419.1010>
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
package require Tk
package require tile
package require ScrollWindow
package require ButtonBox

namespace eval planetarysystem {
    
    snit::widget PlanetaryDisplay {
        component scrollw
        component canvas
        component tools
        component system
        delegate method * to system
        delegate option * to system
        variable scalex
        variable scaley
        variable zoomfactor 1.0
        variable zoomfactor_fmt [format "Zoom: %7.4f" 1.0]
        variable sunmenu
        variable planetmenus -array {}
        
        constructor {args} {
            #puts stderr "*** $type create $self $args"
            install system using PlanetarySystem %AUTO% \
                  -seed [from args -seed 0] \
                  -stellarmass [from args -stellarmass 0.0] \
                  -generate [from args -generate yes] \
                  -filename [from args -filename PlanetarySystem.system]
            install scrollw using ScrolledWindow $win.scrollw \
                  -scrollbar both -auto both
            pack $scrollw -expand yes -fill both
            install canvas using canvas $win.scrollw.canvas \
                  -background black -relief flat -borderwidth 0
            $scrollw setwidget $canvas
            install tools using ButtonBox $win.tools \
                  -orient horizontal
            pack $tools -fill x
            set extents [$system PlanetExtents]
            foreach {MinX MaxX MinY MaxY MinZ MaxZ} $extents {break}
            set maxXabs [expr {max(abs($MinX),abs($MaxX))}]
            set maxYabs [expr {max(abs($MinY),abs($MaxY))}]
            set scalex [expr {2000.0 / double($maxXabs)}]
            set scaley [expr {2000.0 / double($maxYabs)}]
            set sun [$system GetSun]
            set lum [$sun cget -luminosity]
            set smass [$sun cget -mass]
            set yellow [expr {int(($smass * 128))}]
            set green $yellow
            set red $yellow
            set blue 0
            if {$lum < 1} {
                set green [expr {int($yellow * $lum)}]
                set red $yellow
            } elseif {$lum > 1} {
                set blue [expr {int(($lum - 1) * 64)}]
                if {$blue > 255} {set blue 255}
            }
            set color [format {#%02x%02x%02x} $red $green $blue]
            set suntag $sun
            $canvas create oval -4 -4 4 4 -fill $color -outline {} -tag $suntag
            $canvas bind $suntag <3> [mymethod _sunMenu %X %Y]
            set nplanets [$system GetPlanetCount]
            for {set i 1} {$i <= $nplanets} {incr i} {
                set p [$system GetPlanet $i planet]
                set pos [$p position]
                set centerx [expr {[$pos GetX] * $scalex}]
                set centery [expr {[$pos GetY] * $scaley}]
                set color black
                set size 1
                switch [$p cget -ptype] {
                    Rock {
                        set color grey
                        set size 1
                    }
                    Venusian {
                        set color white
                        set size 1
                    }
                    Terrestrial {
                        set color green
                        set size 1
                    }
                    Martian {
                        set color red
                        set size 1
                    }
                    Water {
                        set color blue
                        set size 1
                    }
                    Ice {
                        set color lightblue
                        set size 1
                    }
                    GasGiant {
                        set color orange
                        set size 5
                    }
                    SubGasGiant {
                        set color blue
                        set size 4
                    }
                    SubSubGasGiant {
                        set color brown
                        set size 3
                    }
                }
                #puts "*** $type create $self: ptype [$p cget -ptype], color = $color, size = $size"
                $canvas create oval [expr {$centerx - $size}] \
                      [expr {$centery - $size}] \
                      [expr {$centerx + $size}] \
                      [expr {$centery + $size}] -fill $color -outline {} \
                      -tag $p
                $canvas bind $p <3> [mymethod _planetMenu $i %X %Y]
                if {$i < 100} {$self draw_orbit $p $color}
            }
            $canvas configure -scrollregion [list -2500 -2500 2500 2500]
            $self _addtools
        }
        method draw_orbit {planet {color white}} {
            set oe [OrbitWithEpoch copy [$planet GetOrbit]]
            #set maxdelta [expr {((2*[$oe cget -a]*$::orsa::pi) / 10.0)*3}]
            set period [$oe Period]
            #puts stderr "*** $self draw_orbit ($planet): period = $period"
            set incr [expr {$period / double(100)}]
            set ocoords [list]
            #set prevpos [$planet position]
            #puts stderr "*** $self draw_orbit: prevpos is $prevpos"
            #set mindelta {}
            #set maxdelta {}
            #set deltasum 0.0
            #set numbdeltas 0
            for {set p 0} {$p <= ($period + $incr)} {set p [expr {$p + $incr}]} {
                #puts stderr "*** $self draw_orbit ($planet): p = $p"
                if {$p > $period} {
                    set pp $period
                } else {
                    set pp $p
                }                
                #puts stderr "*** $self draw_orbit ($planet): pp = $pp"
                set pos [Vector %AUTO% 0 0 0]
                set vel [Vector %AUTO% 0 0 0]
                $oe RelativePosVelAtTime pos vel $pp
                #puts stderr "*** $self draw_orbit: pos is $pos"
                #puts stderr [format "*** $self draw_orbit pos = {%12.7lg, %12.7lg, %12.7lg}" [$pos GetX] [$pos GetY] [$pos GetZ]]
                #puts stderr [format "*** $self draw_orbit prevpos = {%12.7lg, %12.7lg, %12.7lg}" [$prevpos GetX] [$prevpos GetY] [$prevpos GetZ]]
                #set dp [$prevpos - $pos]
                #puts stderr [format "*** $self draw_orbit dp = {%12.7lg, %12.7lg, %12.7lg}" [$dp GetX] [$dp GetY] [$dp GetZ]]
                #set delta [$dp Length]                
                #puts stderr "*** $self draw_orbit: delta = $delta, maxdelta = $maxdelta"
                #if {$p == 0} {
                #    set mindelta $delta
                #    set maxdelta $delta
                #} else {
                #    if {$delta < $mindelta} {set mindelta $delta}
                #    if {$delta > $maxdelta} {set maxdelta $delta}
                #}
                #set deltasum [expr {$deltasum + $delta}]
                #incr numbdeltas
                set x [expr {[$pos GetX] * $scalex}]
                set y [expr {[$pos GetY] * $scaley}]
                lappend ocoords $x $y
                #set prevpos $pos
            }
            #set avedelta [expr {$deltasum / double($numbdeltas)}]
            #puts stderr [format "*** $self draw_orbit: mindelta = %g, maxdelta = %g, avedelta = %g, numdeltas = %d" $mindelta $maxdelta $avedelta $numbdeltas]
            $canvas create polygon $ocoords -fill {} -outline $color -tag ${planet}_orbit
            $canvas lower ${planet}_orbit [$system GetSun]
        }
        method _addtools {} {
            $tools add ttk::button zoomin -text "Zoom In" -command [mymethod _zoomin]
            $tools add ttk::button zoom1 -text "Zoom 1.0" -command [mymethod _zoom1]
            $tools add ttk::button zoomout -text "Zoom Out" -command [mymethod _zoomout]
            $tools add ttk::label  currentzoom -textvariable [myvar zoomfactor_fmt]
        }
        method _zoomin {} {
            if {$zoomfactor < 16.0} {
                $self _DoZoom 2.0
            }
        }
        method _zoom1 {} {
            if {$zoomfactor != 1.0} {
                $self _DoZoom [expr {1.0 / $zoomfactor}]
            }
        }
        method _zoomout {} {
            if {$zoomfactor > .0625} {
                $self _DoZoom .5
            }
        }
        method _DoZoom {zoom} {
            set scalex [expr {$scalex * $zoom}]
            set scaley [expr {$scaley * $zoom}]
            $canvas scale all 0.0 0.0 $zoom $zoom
            set osr [$canvas cget -scrollregion]
            foreach v $osr {
                lappend nsr [expr {$v * $zoom}]
            }
            $canvas configure -scrollregion $nsr
            set zoomfactor [expr {$zoomfactor * $zoom}]
            set zoomfactor_fmt [format "Zoom: %7.4f" $zoomfactor]
            
        }
        
        method _sunMenu {X Y} {
            if {[info exists sunmenu] && [winfo exists $sunmenu]} {
                $sunmenu post $X $Y
            } else {
                set sunmenu [menu $win.sunmenu -tearoff 0]
                $sunmenu add command -label Info -command [mymethod _sunInfo]
                $sunmenu post $X $Y
            }
        }
        method _sunInfo {} {
            set sun [$system GetSun]
            tk_messageBox -type ok \
                  -message [format {%s: mass %f, luminosity %f} \
                            [namespace tail $sun] \
                            [$sun cget -mass] \
                            [$sun cget -luminosity]]
        }
        method _planetMenu {iplanet X Y} {
            if {[info exists planetmenus($iplanet)] && 
                [winfo exists $planetmenus($iplanet)]} {
                $planetmenus($iplanet) post $X $Y
            } else {
                set planetmenus($iplanet) [menu $win.planetmenu$iplanet -tearoff 0]
                $planetmenus($iplanet) add command -label Info \
                      -command [mymethod _planetInfo $iplanet]
                $planetmenus($iplanet) post $X $Y
            }
        }
        method _planetInfo {iplanet} {
            set sun [$system GetSun]
            set planet [$system GetPlanet $iplanet planet]
            tk_messageBox -type ok \
                  -message [format {%s %d: %s, mass %f, ptype %s, period %f} \
                            [namespace tail $sun] $iplanet \
                            [namespace tail $planet] \
                            [$planet cget -mass] \
                            [$planet cget -ptype] \
                            [$planet cget -period]]
        }
    }
    
    
    
    namespace export PlanetaryDisplay
}
