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
#  Last Modified : <160408.1428>
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
        
        constructor {args} {
            install system using PlanetarySystem %AUTO% \
                  -seed [from args -seed 0] \
                  -stellarmass [from args -stellarmass 0.0]
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
            set scalex [expr {500.0 / double($maxXabs)}]
            set scaley [expr {500.0 / double($maxYabs)}]
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
            $canvas create oval -5 -5 5 5 -fill $color -outline {} -tag $suntag
            $canvas bind $suntag <3> [mymethod _sunMenu]
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
                        set size 3
                    }
                }
                $canvas create oval [expr {$centerx - $size}] \
                      [expr {$centery - $size}] \
                      [expr {$centerx + $size}] \
                      [expr {$centery + $size}] -fill $color -outline {} \
                      -tag $p
                $canvas bind $p <3> [mymethod _planetmenu $i]
            }
            $canvas configure -scrollregion [$canvas bbox all]
        }
                         
    }
    namespace export PlanetaryDisplay
}
