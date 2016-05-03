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
#  Last Modified : <160503.0953>
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
        delegate method * to system except {load destroy _generate _print 
            _init _sunMenu _planetMenu _suncenter _planetcenter _addtools 
            _cleartools _zoomin _zoom1 _zoomout _DoZoom _togglesunlabel 
            _sunInfo _detailedSunInfo _planetInfo _toggleplanetlabel 
            _toggleplanetorbit _detailedPlanetInfo}
        delegate option * to system
        typemethod new {name args} {
            return [$type create $name -generate yes \
                    -seed [from args -seed 0] \
                    -stellarmass [from args -stellarmass 0.0]]
        }
        method renew {args} {
            $system destroy
            unset system
            $self _cleartools
            install system using PlanetarySystem %AUTO% -generate yes \
                  -seed [from args -seed 0] \
                  -stellarmass [from args -stellarmass 0.0]
            $self _init
        }
        typemethod open {name args} {
            return [$type create $name -generate no \
                    -filename [from args -filename PlanetarySystem.system]]
        }
        method reopen {args} {
            $system destroy
            unset system
            $self _cleartools
            install system using PlanetarySystem %AUTO% -generate no \
                  -filename [from args -filename PlanetarySystem.system]
            $self _init
        }
        method _print {} {
            return [$system ReportPDF]
        }
        variable scalex
        variable scaley
        variable zoomfactor 1.0
        variable zoomfactor_fmt [format "Zoom: %7.4f" 1.0]
        variable sunmenu
        variable sunlabel on
        variable planetlabels -array {}
        variable planetorbits -array {}
        variable labelfont
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
            $self _init
        }
        method _init {} {
            $canvas delete all
            set extents [$system PlanetExtents]
            set labelfont [font create -size [expr {int($zoomfactor * -10)}] \
                           -family Courier]
            foreach {MinX MaxX MinY MaxY MinZ MaxZ} $extents {break}
            set maxXabs [expr {max(abs($MinX),abs($MaxX))}]
            set maxYabs [expr {max(abs($MinY),abs($MaxY))}]
            set scalex [expr {2000.0 / double($maxXabs)}]
            set scaley [expr {2000.0 / double($maxYabs)}]
            set sun [$system GetSun]
            set lum [$sun cget -luminosity]
            set smass [$sun cget -mass]
            set color [$sun SunColor]
            set suntag $sun
            $canvas create oval -6 -6 6 6 -fill $color -outline {} -tag $suntag
            $canvas create text 6 6 -anchor nw \
                  -text [namespace tail $sun] \
                  -font $labelfont \
                  -tag sunlabel -fill $color
            $canvas bind $suntag <3> [mymethod _sunMenu %X %Y]
            set nplanets [$system GetPlanetCount]
            for {set i 1} {$i <= $nplanets} {incr i} {
                set p [$system GetPlanet $i]
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
                $canvas create text [expr {$centerx + $size}] \
                      [expr {$centery + $size}] -fill $color \
                      -anchor nw -text [namespace tail $p] \
                      -font $labelfont -tag ${p}_label
                set planetlabels($i) on
                $canvas bind $p <3> [mymethod _planetMenu $i %X %Y]
                $self draw_orbit $p $color
                set planetorbits($i) on
            }
            set bbox [$canvas bbox all]
            set sr [list]
            foreach b $bbox {
                lappend sr [expr {$b * 1.25}]
            }
            $canvas configure -scrollregion $sr
            $self _addtools
            $self seecenter $sun
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
            $canvas create polygon $ocoords -fill {} -outline $color \
                  -tag ${planet}_orbit
            $canvas lower ${planet}_orbit [$system GetSun]
        }
        method see {tag} {
            #puts stderr "*** $self see $tag"
            foreach {x1 y1 x2 y2} [$canvas bbox $tag] {break}
            #puts stderr "*** $self see: x1 = $x1, y1 = $y1"
            foreach {left top right bottom} [$canvas cget -scrollregion] {break}
            set sr_width [expr {$right - $left}]
            set sr_height [expr {$bottom - $top}]
            #puts stderr "*** $self see: sr_width = $sr_width, sr_height = $sr_height"
            set leftfract [expr {double($x1-$left) / double($sr_width)}]
            #puts stderr "*** $self see: leftfract = $leftfract"
            set topfract [expr {double($y1-$top) / double($sr_height)}]
            #puts stderr "*** $self see: topfract = $topfract"
            $canvas xview moveto $leftfract
            $canvas yview moveto $topfract
        }
        method seecenter {tag} {
            #puts stderr "*** $self seecenter $tag"
            foreach {x1 y1 x2 y2} [$canvas bbox $tag] {break}
            #puts stderr "*** $self seecenter: x1 = $x1, y1 = $y1"
            foreach {left top right bottom} [$canvas cget -scrollregion] {break}
            set sr_width [expr {$right - $left}]
            set sr_height [expr {$bottom - $top}]
            #puts stderr "*** $self seecenter: sr_width = $sr_width, sr_height = $sr_height"
            #update idle
            set vwidth [winfo width $canvas]
            set vheight [winfo height $canvas]
            set leftfract [expr {double(($x1-$left)-($vwidth/2.0)) / double($sr_width)}]
            #puts stderr "*** $self seecenter: leftfract = $leftfract"
            set topfract [expr {double(($y1-$top)-($vheight/2.0)) / double($sr_height)}]
            #puts stderr "*** $self seecenter: topfract = $topfract"
            $canvas xview moveto $leftfract
            $canvas yview moveto $topfract
        }
        method _suncenter {} {
            $self seecenter [$system GetSun]
        }
        method _planetcenter {iplanet} {
            set planet [$system GetPlanet $iplanet]
            foreach {x1 y1 x2 y2} [$canvas bbox $planet] {break}
            set size [expr {$x2 -  $x1}]
            while {$size < 5 && $zoomfactor < 16.0} {
                $self _zoomin
                foreach {x1 y1 x2 y2} [$canvas bbox $planet] {break}
                set size [expr {$x2 -  $x1}]
            }
            $self seecenter $planet
        }
        method _addtools {} {
            $tools add ttk::label  currentzoom -textvariable [myvar zoomfactor_fmt]
            $tools add ttk::button zoomin -text "Zoom In" -command [mymethod _zoomin]
            $tools add ttk::button zoom1 -text "Zoom 1.0" -command [mymethod _zoom1]
            $tools add ttk::button zoomout -text "Zoom Out" -command [mymethod _zoomout]
            $tools add ttk::button suncenter -text "Sun Center" -command [mymethod _suncenter]
            set mbname [$tools add ttk::menubutton planetcenter -text "Planet Center"]
            set menu [menu $mbname.m -tearoff no]
            $mbname configure -menu $menu
            for {set i 1} {$i <= [$system GetPlanetCount]} {incr i} {
                $menu add command \
                      -label [namespace tail [$system GetPlanet $i]] \
                      -command [mymethod _planetcenter $i]
            }
        }
        method _cleartools {} {
            $tools deleteall
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
            font configure $labelfont -size [expr {int($zoomfactor * -10)}]
            set zoomfactor_fmt [format "Zoom: %7.4f" $zoomfactor]
            
        }
        method _sunMenu {X Y} {
            if {[info exists sunmenu] && [winfo exists $sunmenu]} {
                $sunmenu post $X $Y
            } else {
                set sunmenu [menu $win.sunmenu -tearoff 0]
                $sunmenu add command -label {Brief Info} \
                      -command [mymethod _sunInfo]
                $sunmenu add checkbutton -label {Enable Label} \
                      -variable [myvar sunlabel] \
                      -indicatoron yes \
                      -offvalue off -onvalue on \
                      -command [mymethod _togglesunlabel]
                $sunmenu add command -label {Detailed Info} \
                      -command [mymethod _detailedSunInfo]
                $sunmenu add command -label {Printable Report} \
                      -command "[$system GetSun] ReportPDF"
                $sunmenu post $X $Y
            }
        }
        method _togglesunlabel {} {
            switch $sunlabel {
                off {
                    $canvas itemconfigure sunlabel -state hidden
                }
                on {
                    $canvas itemconfigure sunlabel -state normal
                }
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
        method _detailedSunInfo {} {
            set sun [$system GetSun]
            set sunopts [list]
            foreach orec [$sun configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                lappend sunopts $o $ov
            }
            ObjectDetailDisplay $win.detailedSunInfo%AUTO% \
                  -disksize 60 \
                  -diskcolor [$canvas itemcget $sun -fill] \
                  -name [namespace tail $sun] \
                  -mass [$sun cget -mass] \
                  -munits "Sun Masses" \
                  -position [$sun position] \
                  -velocity [$sun velocity] \
                  -parent $win \
                  -optlist $sunopts
        }
            
        method _planetMenu {iplanet X Y} {
            if {[info exists planetmenus($iplanet)] && 
                [winfo exists $planetmenus($iplanet)]} {
                $planetmenus($iplanet) post $X $Y
            } else {
                set planetmenus($iplanet) [menu $win.planetmenu$iplanet -tearoff 0]
                $planetmenus($iplanet) add command -label {Brief Info} \
                      -command [mymethod _planetInfo $iplanet]
                $planetmenus($iplanet) add checkbutton -label {Enable Label} \
                      -variable [myvar planetlabels($iplanet)] \
                      -indicatoron yes \
                      -offvalue off -onvalue on \
                      -command [mymethod _toggleplanetlabel $iplanet]
                $planetmenus($iplanet) add checkbutton -label {Enable Orbit} \
                      -variable [myvar planetorbits($iplanet)] \
                      -indicatoron yes \
                      -offvalue off -onvalue on \
                      -command [mymethod _toggleplanetorbit $iplanet]
                $planetmenus($iplanet) add command -label {Detailed Info} \
                      -command [mymethod _detailedPlanetInfo $iplanet]
                $planetmenus($iplanet) add command -label {Printable Report} \
                      -command "[$system GetPlanet $iplanet] ReportPDF"
                $planetmenus($iplanet) post $X $Y
            }
        }
        method _planetInfo {iplanet} {
            set sun [$system GetSun]
            set planet [$system GetPlanet $iplanet]
            tk_messageBox -type ok \
                  -message [format {%s %d: %s, mass %f, ptype %s, period %f} \
                            [namespace tail $sun] $iplanet \
                            [namespace tail $planet] \
                            [$planet cget -mass] \
                            [$planet cget -ptype] \
                            [$planet cget -period]]
        }
        method _toggleplanetlabel {iplanet} {
            set p [$system GetPlanet $iplanet]
            switch $planetlabels($iplanet) {
                off {
                    $canvas itemconfigure ${p}_label -state hidden
                }
                on {
                    $canvas itemconfigure ${p}_label -state normal
                }
            }
        }
        method _toggleplanetorbit {iplanet} {
            set p [$system GetPlanet $iplanet]
            switch $planetorbits($iplanet) {
                off {
                    $canvas itemconfigure ${p}_orbit -state hidden
                }
                on {
                    $canvas itemconfigure ${p}_orbit -state normal
                }
            }
        }
        method _detailedPlanetInfo {iplanet} {
            set p [$system GetPlanet $iplanet]
            set popts [list]
            foreach orec [$p configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                lappend popts $o $ov
            }
            set size 10
            switch [$p cget -ptype] {
                Rock {
                    set color grey
                    set size 10
                }
                Venusian {
                    set color white
                    set size 10
                }
                Terrestrial {
                    set color green
                    set size 10
                }
                Martian {
                    set color red
                    set size 10
                }
                Water {
                    set color blue
                    set size 10
                }
                Ice {
                    set color lightblue
                    set size 10
                }
                GasGiant {
                    set color orange
                    set size 50
                }
                SubGasGiant {
                    set color blue
                    set size 40
                }
                SubSubGasGiant {
                    set color brown
                    set size 30
                }
            }
            ObjectDetailDisplay $win.detailedPlanetInfo${iplanet}%AUTO% \
                  -disksize $size -diskcolor $color \
                  -name [format {%s %d: %s} [namespace tail [$p cget -sun]] $iplanet \
                         [namespace tail $p]] \
                  -mass [$p cget -mass] \
                  -munits "Earth Masses" \
                  -position [$p position] \
                  -velocity [$p velocity] \
                  -parent $win \
                  -optlist $popts
                  
        }
    }
    
    
    
    namespace export PlanetaryDisplay 
}
