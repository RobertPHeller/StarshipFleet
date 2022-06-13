#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu Oct 4 16:50:05 2018
#  Last Modified : <220613.1715>
#
#  Description	
#
#  Notes
#
#  History
#	
#*****************************************************************************
#
#    Copyright (C) 2018  Robert Heller D/B/A Deepwoods Software
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

package require Tk
package require snit
package require tile
package require ScrollWindow
package require ButtonBox
package require MainFrame
package require snitStdMenuBar
package require ROText

namespace eval bridgeconsole {
    snit::widget SensorsDisplay {
        component visible
        delegate method {visible *} to visible
        component lidar
        delegate method {lidar *} to lidar
        option -style -default SensorsDisplay
        option -ship -readonly yes -default {} -type ::starships::Starship
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            install visible using ::bridgeconsole::VisibleDisplay \
                  $win.visible -ship $options(-ship)
            pack $visible -side left -expand yes -fill both
            install lidar using ::bridgeconsole::LidarDisplay \
                  $win.lidar -ship $options(-ship)
            pack $lidar -side right -expand yes -fill both
            $self configurelist $args
        }
        method update {epoch} {
        }
        method updatesensor {epoch thetype direction origin spread imagefile} {
            switch $thetype {
                VISIBLE {
                    $visible updatesensor $imagefile
                }
                LIDAR {
                    #$lidar updatesensor $imagefile
                }
            }
        }
        method setorbiting {orbiting} {
        }
        method setsun {sun args} {
        }
        method setplanetinfo {args} {
        }
    }
    snit::enum State -values {normal disabled}
    snit::widget JoyButtons {
        hulltype ttk::frame
        typevariable _Up {
#define up_width 8
#define up_height 4
static unsigned char up_bits[] = {
   0x18, 0x3c, 0x7e, 0xff};
        }
        typevariable _Down {
#define down_width 8
#define down_height 4
static unsigned char down_bits[] = {
   0xff, 0x7e, 0x3c, 0x18};
        }
        typevariable _Left {
#define left_width 4
#define left_height 8
static unsigned char left_bits[] = {
   0x08, 0x0c, 0x0e, 0x0f, 0x0f, 0x0e, 0x0c, 0x08};
        }
        typevariable _Right {
#define right_width 4
#define right_height 8
static unsigned char right_bits[] = {
   0x01, 0x03, 0x07, 0x0f, 0x0f, 0x07, 0x03, 0x01};
        }
        typevariable _Home {
#define home_width 8
#define home_height 8
static unsigned char home_bits[] = {
   0x3c, 0x7e, 0xff, 0xff, 0xff, 0xff, 0x7e, 0x3c};
        }
        component up
        delegate option -upcommand to up as -command
        component down
        delegate option -downcommand to down as -command
        component left
        delegate option -leftcommand to left as -command
        component right
        delegate option -rightcommand to right as -command
        component home
        delegate option -homecommand to home as -command
        option -style -default JoyButtons
        typeconstructor {
            ttk::style configure JoyButton -relief flat -padding 0
            ttk::style layout JoyButton [ttk::style layout Toolbutton]
        }
        option -state -default normal -type ::bridgeconsole::State \
              -configuremethod _setstate
        method _setstate {option value} {
            set options($option) $value
            switch $value {
                normal {
                    $up configure -state normal -cursor {}
                    $down configure -state normal -cursor {}
                    $left configure -state normal -cursor {}
                    $right configure -state normal -cursor {}
                    $home configure -state normal -cursor {}
                    #$win configure -cursor {}
                }
                disabled {
                    $up configure -state disabled -cursor watch
                    $down configure -state disabled -cursor watch
                    $left configure -state disabled -cursor watch
                    $right configure -state disabled -cursor watch
                    $home configure -state disabled -cursor watch
                    #$win configure -cursor clock
                }
            }
        }
        constructor {args} {
            install up using ttk::button $win.up -image [image create bitmap -data $_Up] -style JoyButton
            install down using ttk::button $win.down -image [image create bitmap -data $_Down] -style JoyButton
            install left using ttk::button $win.left -image [image create bitmap -data $_Left] -style JoyButton
            install right using ttk::button $win.right -image [image create bitmap -data $_Right] -style JoyButton
            install home using ttk::button $win.home -image [image create bitmap -data $_Home] -style JoyButton
            grid $up -column 1 -row 0
            grid $down -column 1 -row 2
            grid $left -column 0 -row 1
            grid $right -column 2 -row 1
            grid $home -column 1 -row 1
            grid columnconfigure $win 0 -weight 0 -uniform yes
            grid columnconfigure $win 1 -weight 0 -uniform yes
            grid columnconfigure $win 2 -weight 0 -uniform yes
            grid rowconfigure $win 0 -weight 0 -uniform yes
            grid rowconfigure $win 1 -weight 0 -uniform yes
            grid rowconfigure $win 2 -weight 0 -uniform yes
            $self configurelist $args
        }
    }
    snit::enum SensorType -values {IFRARED RADIO VISIBLE LIDAR RADAR}
    snit::macro ::bridgeconsole::SensorTools {sensetype} {
        hulltype ttk::labelframe
        component canvas
        component tools
        variable sensoraimThetaX 0.0
        variable sensoraimThetaY 0.0
        variable fieldofview 0
        variable scalex
        variable scaley
        variable zoomfactor 1.0
        variable zoomfactor_fmt [format "Zoom: %7.4f" 1.0]
        variable labelfont
        variable _senseimage {}
        variable _displayedimage {}
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -sensortype -type ::bridgeconsole::SensorType -readonly yes -default $sensetype
        method _addtools {} {
            $tools add ttk::label  currentzoom -textvariable [myvar zoomfactor_fmt]
            $tools add ttk::button zoomin -text "Zoom In" -command [mymethod _zoomin]
            $tools add ttk::button zoom1 -text "Zoom 1.0" -command [mymethod _zoom1]
            $tools add ttk::button zoomout -text "Zoom Out" -command [mymethod _zoomout]
            $tools add ::bridgeconsole::JoyButtons joybuttons \
                  -upcommand [mymethod _cameraUp] \
                  -downcommand [mymethod _cameraDown] \
                  -leftcommand [mymethod _cameraLeft] \
                  -rightcommand [mymethod _cameraRight] \
                  -homecommand [mymethod _cameraHome]
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
            if {$zoomfactor > 1} {
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
            zoomImage [myvar _senseimage] [myvar _displayedimage] \
                  $zoomfactor $canvas
        }
        proc zoomImage {sourcename destname zoom canvas} {
            upvar $sourcename source
            upvar $destname dest
            if {$source eq {}} {return}
            catch {$canvas delete SenseImage}
            catch {image delete $dest}
            set dheight [expr {int(512 * $zoom)}]
            set dwidth  [expr {int(512 * $zoom)}]
            set xoff [expr {([image width  $source] - 512)/2}]
            set yoff [expr {([image height $source] - 512)/2}]
            set dest [image create photo -height $dheight -width $dwidth]
            $dest copy $source -from $xoff $yoff -zoom [expr {int($zoom)}]
            $canvas create image 0 0 -anchor c -image $dest -tag SenseImage
            $canvas raise _scale SenseImage
        }
        method _cameraUp {} {
            set sensoraimThetaX [expr {$sensoraimThetaX + ($::orsa::pi/18.0)}]
            if {$sensoraimThetaX >= (2*$::orsa::pi)} {
                set sensoraimThetaX [expr {$sensoraimThetaX - (2*$::orsa::pi)}]
            }
            $self _getSensorImage
            $self _redrawScale
        }
        method _cameraDown {} {
            set sensoraimThetaX [expr {$sensoraimThetaX - ($::orsa::pi/18.0)}]
            if {$sensoraimThetaX < 0} {
                set sensoraimThetaX [expr {$sensoraimThetaX + (2*$::orsa::pi)}]
            }
            $self _getSensorImage
            $self _redrawScale
        }
        method _cameraLeft {} {
            set sensoraimThetaY [expr {$sensoraimThetaY - ($::orsa::pi/18.0)}]
            if {$sensoraimThetaY < 0} {
                set sensoraimThetaY [expr {$sensoraimThetaY + (2*$::orsa::pi)}]
            }
            $self _getSensorImage
            $self _redrawScale
        }
        method _cameraRight {} {
            set sensoraimThetaY [expr {$sensoraimThetaY + ($::orsa::pi/18.0)}]
            if {$sensoraimThetaY >= (2*$::orsa::pi)} {
                set sensoraimThetaY [expr {$sensoraimThetaY - (2*$::orsa::pi)}]
            }
            $self _getSensorImage
            $self _redrawScale
        }
        method _cameraHome {} {
            set sensoraimThetaX 0.0
            set sensoraimThetaY 0.0
            $self _getSensorImage
            $self _redrawScale
        }
        method _redrawScale {} {
            if {[llength [$canvas find withtag _scale]] > 0} {
                for {set r 0} {$r < 250} {incr r 50} {
                    $canvas itemconfigure _scale_YLab_$r \
                          -text [format "%7.3f" [expr {$sensoraimThetaY + (($r/256.0)*$fieldofview)}]]
                    $canvas itemconfigure _scale_XLab_$r \
                          -text [format "%7.3f" [expr {$sensoraimThetaX + (($r/256.0)*$fieldofview)}]]
                    if {$r != 0} {
                        $canvas itemconfigure _scale_YLab_-$r \
                              -text [format "%7.3f" [expr {$sensoraimThetaY - (($r/256.0)*$fieldofview)}]]
                        $canvas itemconfigure _scale_XLab_-$r \
                              -text [format "%7.3f" [expr {$sensoraimThetaX - (($r/256.0)*$fieldofview)}]]
                    }
                }
            } else {
                for {set r 0} {$r < 250} {incr r 50} {
                    if {$r > 0} {
                        $canvas create oval -$r -$r $r $r -outline white \
                              -tag [list _scale _scale_r$r]
                    }
                    $canvas create text 0 -$r \
                          -text [format "%7.3f" [expr {$sensoraimThetaX + (($r/256.0)*$fieldofview)}]] \
                          -fill white \
                          -tag [list _scale _scale_XLab_$r] \
                          -anchor nw
                    $canvas create text $r 0 \
                          -text [format "%7.3f" [expr {$sensoraimThetaY + (($r/256.0)*$fieldofview)}]] \
                          -fill white \
                          -tag [list _scale _scale_YLab_$r] \
                          -anchor sw
                    if {$r != 0} {
                        $canvas create text 0 $r \
                              -text [format "%7.3f" [expr {$sensoraimThetaX - (($r/256.0)*$fieldofview)}]] \
                              -fill white \
                              -tag [list _scale _scale_XLab_-$r] \
                              -anchor nw
                        $canvas create text -$r 0 \
                              -text [format "%7.3f" [expr {$sensoraimThetaY - (($r/256.0)*$fieldofview)}]] \
                              -fill white \
                              -tag [list _scale _scale_YLab_-$r] \
                              -anchor sw
                    }
                }
                $canvas create line 0 -256 0 256 -fill white \
                      -tag [list _scale _scale_X]
                $canvas create line -256 0 256 0 -fill white \
                      -tag [list _scale _scale_Y]
            }
            catch {$canvas raise _scale SenseImage}
        }
        method _init {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            set options(-style) [from args -style]
            $hull configure -style $options(-style)
            set scrollw [ScrolledWindow $win.scrollw \
                         -scrollbar both -auto none]
            pack $scrollw;# -expand yes -fill both
            install canvas using canvas [$scrollw getframe].canvas \
                  -width 512 -height 512 -background black \
                  -scrollregion {-256 -256 256 256}
            $scrollw setwidget $canvas
            install tools using ButtonBox $win.tools -orient horizontal
            pack $tools -fill x
            $canvas delete all
            set labelfont [font create -size [expr {int($zoomfactor * -10)}] \
                           -family Courier]
            set sensoraimThetaX 0.0
            set sensoraimThetaY 0.0
            set maxXabs 256
            set maxYabs 256
            set scalex [expr {2000.0 / double($maxXabs)}]
            set scaley [expr {2000.0 / double($maxYabs)}]
            set fieldofview [expr {$::orsa::pi/18.0}]
            $self _addtools
            $self configurelist $args
            $self _getSensorImage
            $self _redrawScale
        }
        method _getSensorImage {} {
            $tools itemconfigure joybuttons -state disabled
            #puts stderr "*** $self _getSensorImage"
            #puts stderr "*** $self _getSensorImage: $options(-sensortype) $sensoraimThetaX $sensoraimThetaY $fieldofview"
            $options(-ship) getSensorImage $options(-sensortype) \
                  $sensoraimThetaY $sensoraimThetaX $fieldofview
        }
        method updatesensor {imagefile} {
            puts stderr "*** $self updatesensor $imagefile"
            catch {$canvas delete SenseImage}
            if {$_senseimage ne {}} {image delete $_senseimage}
            set _senseimage [image create photo -file $imagefile]
            #file delete -force $imagefile
            zoomImage [myvar _senseimage] [myvar _displayedimage] $zoomfactor $canvas
            $self _redrawScale
            $tools itemconfigure joybuttons -state normal
        }
    }
    snit::widget VisibleDisplay {
        option -style -default VisibleDisplay
        typeconstructor {
            ttk::style layout VisibleDisplay {
                VisibleDisplay.border -sticky nswe
                VisibleDisplay.scrollw -sticky nswe
                VisibleDisplay.tools -sticky nswe
            }
            ttk::style configure VisibleDisplay -relief flat
        }
        ::bridgeconsole::SensorTools VISIBLE
        constructor {args} {
            $self _init {*}$args
            $hull configure  -text "Visible Light" -labelanchor n
        }
        
    }
    snit::widget LidarDisplay {
        ::bridgeconsole::SensorTools LIDAR
        typeconstructor {
            ttk::style layout LidarDisplay {
                LidarDisplay.border -sticky nswe
                LidarDisplay.scrollw -sticky nswe
                LidarDisplay.tools -sticky nswe
            }
            ttk::style configure LidarDisplay -relief flat
        }
        component outoforder
        option -style -default LidarDisplay
        constructor {args} {
            $self _init {*}$args
            $hull configure  -text "LIDAR" -labelanchor n
        }
    }
    snit::widget CommunicationsPanel {
        typeconstructor {
            ttk::style layout CommunicationsPanel {
                CommunicationsPanel.head -side top -sticky nswe -children {
                    CommunicationsPanel.outoforder -side top -sticky nswe}}
            ttk::style layout CommunicationsPanel.OutOfOrder \
                  [ttk::style layout TLabel]
            eval ttk::style configure CommunicationsPanel.OutOfOrder {*}[ttk::style configure TLabel]
            ttk::style configure CommunicationsPanel.OutOfOrder \
                  -font [list Courier -72 bold] \
                  -foreground red \
                  -background black
        }
        component outoforder
        option -style -default CommunicationsPanel
        option -ship -readonly yes -default {} -type ::starships::Starship
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            set options(-style) [from args -style]
            install outoforder using ttk::label $win.outoforder \
                  -style ${options(-style)}.OutOfOrder -text "Out Of Order"
            pack $outoforder -fill both -expand yes
            $self configurelist $args
        }
        method update {epoch} {
        }
    }
    snit::widget TacticalSystem {
        typeconstructor {
            ttk::style layout TacticalSystem {
                TacticalSystem.head -side top -sticky nswe -children {
                    TacticalSystem.outoforder -side top -sticky nswe}}
            ttk::style layout TacticalSystem.OutOfOrder \
                  [ttk::style layout TLabel]
            ttk::style configure TacticalSystem.OutOfOrder {*}[ttk::style configure TLabel]
            ttk::style configure TacticalSystem.OutOfOrder \
                  -font [list Courier -72 bold] \
                  -foreground red \
                  -background black
        }
        component outoforder
        option -style -default TacticalSystem
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -shields -readonly yes -default {} -type ::starships::StarshipShields
        option -misslelaunchers -readonly yes -default {} -type ::starships::StarshipMissleLaunchers
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            if {[lsearch -exact $args -shields] < 0} {
                error [_ "The -shields option must be specified!"]
            }
            set options(-shields) [from args -shields]
            if {[lsearch -exact $args -misslelaunchers] < 0} {
                error [_ "The -misslelaunchers option must be specified!"]
            }
            set options(-misslelaunchers) [from args -misslelaunchers]
            set options(-style) [from args -style]
            install outoforder using ttk::label $win.outoforder \
                  -style ${options(-style)}.OutOfOrder -text "Out Of Order"
            pack $outoforder -fill both -expand yes
            $self configurelist $args
        }
        method update {epoch} {
        }
        method setorbiting {orbiting} {
        }
        method setsun {sun args} {
        }
        method setplanetinfo {args} {
        }
    }
    snit::widget CaptiansChair {
        widgetclass CaptiansChair
        hulltype ttk::frame
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -style -default CaptiansChair
        typeconstructor {
            ttk::style layout CaptiansChairLabelFrame [ttk::style layout TLabelframe]
            ttk::style layout CaptiansChairLabelFrame.Label [ttk::style layout TLabelframe.Label]
            ttk::style configure CaptiansChairLabelFrame \
                  {*}[ttk::style configure TLabelframe]
            ttk::style configure CaptiansChairLabelFrame  -background black
            ttk::style configure CaptiansChairLabelFrame.Label \
                  {*}[ttk::style configure TLabelframe.Label]
            ttk::style configure CaptiansChairLabelFrame.Label \
                  -font [list Courier -18 bold] -foreground white \
                  -background black
            ttk::style layout CaptiansChairLabel [ttk::style layout TLabel]
            ttk::style configure CaptiansChairLabel \
                  {*}[ttk::style configure TLabel]
            ttk::style configure CaptiansChairLabel \
                  -font [list Courier -18 bold] -foreground white \
                  -background black
            ttk::style configure CaptiansChairROText \
                  {*}[ttk::style configure ROText]
            ttk::style configure CaptiansChairROText \
                  -background black -foreground white \
                  -font [list {DejaVu Sans Mono} -10 bold] \
                  -relief flat -borderwidth 0 \
                  -selectbackground white -selectforeground black
        }
        component time
        component position
        component velocity
        component orientation
        component sunname
        component sunprops
        component planetname
        component planetprops
        component orbiting
        
        component units
        method formatEpoch {epoch} {
            return [format {%10.3g %s} \
                    [$units FromUnits_time_unit $epoch SECOND] \
                    [$units TimeLabel]]
        }
        method formatPosition {} {
            return [format {%10.3g %10.3g %10.3g %s} \
                    {*}[$options(-ship) GetPositionXYZUnits $units] \
                    [$units LengthLabel]]
        }
        method formatVelocity {} {
            return [format {%10.3g %10.3g %10.3g %s/%s} \
                    {*}[$options(-ship) GetVelocityXYZUnits $units] \
                    [$units LengthLabel] SECOND]
        }
        method formatRelativeOrientation {} {
            return [format {Roll: %5.3f Pitch: %5.3f Yaw: %5.3f} \
                    [$options(-ship) Roll] \
                    [$options(-ship) Pitch] \
                    [$options(-ship) Yaw]]
        }
        proc formatName {what} {
            return [format {%-30s} [namespace tail $what]]
        }
        method formatSunOpts {} {
            return [format {SM: %7.3f Lum: %7.3f Age: %7.3f} \
                    $_sunOpts(-mass) $_sunOpts(-luminosity) $_sunOpts(-age)]
        }
        variable _sun
        variable _sunOpts -array {-mass 0 -luminosity 0 -age 0}
        variable _orbiting
        variable _planet
        variable _planetprops -array {}
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            set options(-style) [from args -style]
            install units using ::orsa::Units %AUTO% DAY KM MEARTH
            set status [ttk::frame $win.status]
            pack $status -side left -fill y
            pack [ttk::labelframe $status.timeframe \
                  -style CaptiansChairLabelFrame -text Time] -fill x
            install time using ttk::label $status.timeframe.time \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $time -expand yes -fill x
            pack [ttk::labelframe $status.posframe \
                  -style CaptiansChairLabelFrame -text Position] -fill x
            install position using ttk::label $status.posframe.position \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $position -expand yes -fill x
            pack [ttk::labelframe $status.velframe \
                  -style CaptiansChairLabelFrame -text Velocity] -fill x
            install velocity using ttk::label $status.velframe.velocity \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $velocity -expand yes -fill x
            pack [ttk::labelframe $status.oriframe \
                  -style CaptiansChairLabelFrame -text "Relative Orientation"] -fill x
            install orientation using ttk::label $status.oriframe.orientation \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $orientation -expand yes -fill x
            pack [ttk::labelframe $status.orbitframe \
                  -style CaptiansChairLabelFrame -text Orbiting] -fill x
            install orbiting using ttk::label $status.orbitframe.orbiting \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $orbiting -expand yes -fill x
            pack [ttk::labelframe $status.sunframe \
                  -style CaptiansChairLabelFrame -text Sun] -fill x
            install sunname using ttk::label $status.sunframe.sunname \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $sunname -expand yes -fill x
            install sunprops using ttk::label $status.sunframe.sunprops \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $sunprops -expand yes -fill x
            pack [ttk::labelframe $status.planetframe \
                  -style CaptiansChairLabelFrame -text Planet] -fill x
            install planetname using ttk::label $status.planetframe.planetname \
                  -style CaptiansChairLabel -text {} -anchor w
            pack $planetname -expand yes -fill x
            install planetprops using ROText $status.planetframe.planetprops \
                  -width 80 -style CaptiansChairROText 
            pack $planetprops -expand yes -fill both
            pack [ttk::frame $status.filler] -side bottom -expand yes -fill both
            set controls [ttk::frame $win.controls]
            pack $controls  -side right -fill y -expand yes
            $self configurelist $args
        }
        method update {epoch} {
            $time configure -text [$self formatEpoch $epoch]
            $position configure -text [$self formatPosition]
            $velocity configure -text [$self formatVelocity]
            $orientation configure -text [$self formatRelativeOrientation]
        }
        method setorbiting {orbiting_} {
            set _orbiting $orbiting_
            $orbiting configure -text [formatName $_orbiting]
        }
        method setsun {sun args} {
            set _sun $sun
            array set _sunOpts $args
            $sunname configure -text [formatName $_sun]
            $sunprops configure -text [$self formatSunOpts]
        }
        method setplanetinfo {args} {
            #puts stderr "*** $self setplanetinfo $args"
            set _planet [from args -planet]
            $planetname configure -text [formatName $_planet]
            catch {array unset _planetprops}
            array set _planetprops $args
            $planetprops delete 1.0 end
            foreach {a b} [lsort [array names _planetprops]] {
                $planetprops insert end [format {%18s: %19s|} \
                                         [string range $a 1 end] \
                                         $_planetprops($a)]
                $planetprops insert end [format {%18s: %19s} \
                                         [string range $b 1 end] \
                                         $_planetprops($b)]
                
                $planetprops insert end "\n"
            }
        }
    }
    snit::widget NavigationHelm {
        widgetclass NavigationHelm
        hulltype ttk::frame
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -style -default NavigationHelm
        typeconstructor {
            ttk::style layout NavigationHelmLabelFrame [ttk::style layout TLabelframe]
            ttk::style layout NavigationHelmLabelFrame.Label [ttk::style layout TLabelframe.Label]
            ttk::style configure NavigationHelmLabelFrame \
                  {*}[ttk::style configure TLabelframe]
            ttk::style configure NavigationHelmLabelFrame  -background black
            ttk::style configure NavigationHelmLabelFrame.Label \
                  {*}[ttk::style configure TLabelframe.Label]
            ttk::style configure NavigationHelmLabelFrame.Label \
                  -font [list Courier -18 bold] -foreground white \
                  -background black
            ttk::style layout NavigationHelmLabel [ttk::style layout TLabel]
            ttk::style configure NavigationHelmLabel \
                  {*}[ttk::style configure TLabel]
            ttk::style configure NavigationHelmLabel \
                  -font [list Courier -18 bold] -foreground white \
                  -background black
            ttk::style layout NavigationHelmThrustorLabel [ttk::style layout TLabel]
            ttk::style configure NavigationHelmThrustorLabel \
                  {*}[ttk::style configure TLabel]
            ttk::style configure NavigationHelmThrustorLabel \
                  -font [list Courier -18 bold] -foreground white \
                  -background DarkOliveGreen
            ttk::style layout NavigationHelmThrustor \
                  {Vertical.Scale.trough -sticky nswe \
                  -children {Vertical.Scale.slider -side top -sticky {we}}}
            ttk::style configure NavigationHelmThrustor \
                  {*}[ttk::style configure TScale]
            ttk::style configure NavigationHelmThrustor \
                  -background green -focuscolor orange \
                  -troughcolor DarkOliveGreen
            ttk::style configure NavigationHelmThrustor.trough \
                  -background DarkOliveGreen
            ttk::style configure NavigationHelmThrustor.slider \
                  -background white
            ttk::style layout NavigationHelmMainEngineLabel [ttk::style layout TLabel]
                  
            ttk::style configure NavigationHelmThrustorLabel \
                  {*}[ttk::style configure TLabel]
            ttk::style configure NavigationHelmMainEngineLabel \
                  -font [list Courier -18 bold] -foreground white \
                  -background DarkRed
            ttk::style layout NavigationHelmMainEngine \
                  {Vertical.Scale.trough -sticky nswe \
                  -children {Vertical.Scale.slider -side top -sticky {we}}}
            ttk::style configure NavigationHelmMainEngine \
                  {Vertical.Scale.trough -sticky nswe \
                  -children {Vertical.Scale.slider -side top -sticky {we}}}
            ttk::style configure NavigationHelmMainEngine \
                  -background DarkRed -foreground white \
                  -troughcolor DarkRed 
            
            ttk::style configure NavigationHelmROText \
                  {*}[ttk::style configure ROText]
            ttk::style configure NavigationHelmROText \
                  -background black -foreground white \
                  -font [list {DejaVu Sans Mono} -10 bold] \
                  -relief flat -borderwidth 0 \
                  -selectbackground white -selectforeground black
            ttk::style configure NavigationHelmLeftPanel \
                  -background DarkOliveGreen -foreground white
            ttk::style layout NavigationHelmLeftPanel [ttk::style layout TFrame]
            ttk::style configure NavigationHelmStick \
                  -background DarkOrange -foreground white
            ttk::style layout NavigationHelmStick [ttk::style layout TFrame]
            ttk::style configure NavigationHelmRightPanel \
                  -background DarkRed -foreground white
            ttk::style layout NavigationHelmRightPanel [ttk::style layout TFrame]
        }
        component time
        component position
        component velocity
        component orientation
        component sunname
        component orbiting
        
        component thrustor1
        component thrustor1thrust
        component thrustor2
        component thrustor2thrust
        component main1
        component main1thrust
        component main2
        component main2thrust
        component units
        method formatEpoch {epoch} {
            return [format {%10.3g %s} \
                    [$units FromUnits_time_unit $epoch SECOND] \
                    [$units TimeLabel]]
        }
        method formatPosition {} {
            return [format {%10.3g %10.3g %10.3g %s} \
                    {*}[$options(-ship) GetPositionXYZUnits $units] \
                    [$units LengthLabel]]
        }
        method formatVelocity {} {
            return [format {%10.3g %10.3g %10.3g %s/%s} \
                    {*}[$options(-ship) GetVelocityXYZUnits $units] \
                    [$units LengthLabel] SECOND]
        }
        method formatRelativeOrientation {} {
            return [format {Roll: %5.3f Pitch: %5.3f Yaw: %5.3f} \
                    [$options(-ship) Roll] \
                    [$options(-ship) Pitch] \
                    [$options(-ship) Yaw]]
        }
        proc formatName {what} {
            return [format {%-30s} [namespace tail $what]]
        }
        
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            set options(-style) [from args -style]
            install units using ::orsa::Units %AUTO% DAY KM MEARTH
            set status [ttk::frame $win.status]
            pack $status -fill x
            grid columnconfigure $status 0 -weight 1 -uniform status
            grid columnconfigure $status 1 -weight 1 -uniform status
            grid [ttk::labelframe $status.timeframe \
                   -style NavigationHelmLabelFrame -text Time] \
                  -row 0 -column 0 -sticky news
            install time using ttk::label $status.timeframe.time \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $time -expand yes -fill x
            grid [ttk::labelframe $status.posframe \
                   -style NavigationHelmLabelFrame -text Position] \
                  -row 0 -column 1 -sticky news
            install position using ttk::label $status.posframe.position \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $position -expand yes -fill x
            grid [ttk::labelframe $status.oriframe \
                  -style NavigationHelmLabelFrame -text "Relative Orientation"] \
                  -row 1 -column 0 -sticky news
            install orientation using ttk::label $status.oriframe.orientation \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $orientation -expand yes -fill x
            grid [ttk::labelframe $status.velframe \
                   -style NavigationHelmLabelFrame -text Velocity] \
                  -row 1 -column 1 -sticky news 
            install velocity using ttk::label $status.velframe.velocity \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $velocity -expand yes -fill x
            grid [ttk::labelframe $status.sunframe \
                  -style NavigationHelmLabelFrame -text Sun] \
                  -row 2 -column 0 -sticky news
            install sunname using ttk::label $status.sunframe.sunname \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $sunname -expand yes -fill x
            grid [ttk::labelframe $status.orbitframe \
                  -style NavigationHelmLabelFrame -text Orbiting] \
                  -row 2 -column 1 -sticky news
            install orbiting using ttk::label $status.orbitframe.orbiting \
                  -style NavigationHelmLabel -text {} -anchor w
            pack $orbiting -expand yes -fill x
            set controls [ttk::frame $win.controls]
            pack $controls -expand yes -fill both
            grid columnconfigure $controls 0 -weight 1 -uniform engine
            grid columnconfigure $controls 1 -weight 5
            grid columnconfigure $controls 2 -weight 1 -uniform engine
            grid rowconfigure $controls 0 -weight 20
            set leftpanel  [ttk::frame $controls.leftpanel \
                            -style NavigationHelmLeftPanel]
            grid $leftpanel  -row 0 -column 0 -sticky news
            grid columnconfigure $leftpanel 0 -weight 1
            grid columnconfigure $leftpanel 1 -weight 1
            grid rowconfigure $leftpanel 0 -weight 1 -uniform lab
            grid rowconfigure $leftpanel 1 -weight 20
            grid rowconfigure $leftpanel 2 -weight 1 -uniform lab
            grid [ttk::label $leftpanel.thrustor1Lab \
                  -style NavigationHelmThrustorLabel -text "Thrustor 1"] \
                  -row 0 -column 0 -sticky news
            install thrustor1 using ttk::scale $leftpanel.thrustor1 \
                  -style NavigationHelmThrustor -orient vertical \
                  -command [mymethod _thrustor 1] -from 100 -to 0 -value 0
            grid $thrustor1 -row 1 -column 0 -sticky news
            install thrustor1thrust using ttk::label $leftpanel.thrustor1hrust \
                  -style NavigationHelmThrustorLabel -text 0.0 -anchor w
            grid $thrustor1thrust -row 2 -column 0 -sticky news
            
            grid [ttk::label $leftpanel.thrustor2Lab \
                  -style NavigationHelmThrustorLabel -text "Thrustor 2"] \
                  -row 0 -column 1 -sticky news
            install thrustor2 using ttk::scale $leftpanel.thrustor2 \
                  -style NavigationHelmThrustor -orient vertical \
                  -command [mymethod _thrustor 2] -from 100 -to 0 -value 0
            grid $thrustor2 -row 1 -column 1 -sticky news
            install thrustor2thrust using ttk::label $leftpanel.thrustor2hrust \
                  -style NavigationHelmThrustorLabel -text 0.0 -anchor w
            grid $thrustor2thrust -row 2 -column 1 -sticky news
            
            set stick      [ttk::frame $controls.stick \
                            -style NavigationHelmStick]
            grid $stick      -row 0 -column 1 -sticky news
            set rightpanel [ttk::frame $controls.rightpanel \
                            -style NavigationHelmRightPanel]
            grid $rightpanel -row 0 -column 2 -sticky news
            
            grid columnconfigure $rightpanel 0 -weight 1
            grid columnconfigure $rightpanel 1 -weight 1
            grid rowconfigure $rightpanel 0 -weight 1 -uniform lab
            grid rowconfigure $rightpanel 1 -weight 20
            grid rowconfigure $rightpanel 2 -weight 1 -uniform lab
            grid [ttk::label $rightpanel.main1Lab \
                  -style NavigationHelmMainEngineLabel -text "Main 1"] \
                  -row 0 -column 0 -sticky news
            install main1 using ttk::scale $rightpanel.main1 \
                  -style NavigationHelmMainEngine -orient vertical \
                  -command [mymethod _main 1] -from 100 -to 0 -value 0
            grid $main1 -row 1 -column 0 -sticky news
            install main1thrust using ttk::label $rightpanel.main1hrust \
                  -style NavigationHelmMainEngineLabel -text 0.0 -anchor w
            grid $main1thrust -row 2 -column 0 -sticky news
            
            grid [ttk::label $rightpanel.main2Lab \
                  -style NavigationHelmMainEngineLabel -text "Main 2"] \
                  -row 0 -column 1 -sticky news
            install main2 using ttk::scale $rightpanel.main2 \
                  -style NavigationHelmMainEngine -orient vertical \
                  -command [mymethod _main 2] -from 100 -to 0 -value 0
            grid $main2 -row 1 -column 1 -sticky news
            install main2thrust using ttk::label $rightpanel.main2hrust \
                  -style NavigationHelmMainEngineLabel -text 0.0 -anchor w
            grid $main2thrust -row 2 -column 1 -sticky news
            
        }
        method update {epoch} {
            $time configure -text [$self formatEpoch $epoch]
            $position configure -text [$self formatPosition]
            $velocity configure -text [$self formatVelocity]
            $orientation configure -text [$self formatRelativeOrientation]
        }
        method setorbiting {orbiting_} {
            set _orbiting $orbiting_
            $orbiting configure -text [formatName $_orbiting]
        }
        method setsun {sun args} {
            set _sun $sun
            #array set _sunOpts $args
            $sunname configure -text [formatName $_sun]
            #$sunprops configure -text [$self formatSunOpts]
        }
        method setplanetinfo {args} {
            #puts stderr "*** $self setplanetinfo $args"
            #set _planet [from args -planet]
            #$planetname configure -text [formatName $_planet]
            #catch {array unset _planetprops}
            #array set _planetprops $args
            #$planetprops delete 1.0 end
            #foreach {a b} [lsort [array names _planetprops]] {
            #    $planetprops insert end [format {%18s: %19s|} \
            #                             [string range $a 1 end] \
            #                             $_planetprops($a)]
            #    $planetprops insert end [format {%18s: %19s} \
            #                             [string range $b 1 end] \
            #                             $_planetprops($b)]
            #    
            #    $planetprops insert end "\n"
            #}
        }
        method _thrustor {index value} {
            [set thrustor${index}thrust] configure -text [format "%7.3f" $value]
        }
        method _main {index value} {
            [set main${index}thrust] configure -text [format "%7.3f" $value]
        }
        
            
    }
    snit::widget EngineeringDisplay {
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -engine -readonly yes -default {} -type ::starships::StarshipEngine
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            if {[lsearch -exact $args -engine] < 0} {
                error [_ "The -engine option must be specified!"]
            }
            set options(-engine) [from args -engine]
            $self configurelist $args
        }
        method update {epoch} {
        }
    }
    snit::widgetadaptor FullConsole {
        option -menu \
              -readonly yes \
              -default {
            "&File" {file:menu} {file} 0 {
	        {command "&New"     {file:new} ""     {Ctrl n} -command "[mymethod _new]"}
	        {command "&Open..." {file:open} "" {Ctrl o} -command "[mymethod _open]"}
	        {command "&Save"    {file:save} "" {Ctrl s} -command "[mymethod _save]"}
		{command "Save &As..." {file:saveas} "" {Ctrl a} -command "[mymethod _saveas]"}
		{command "&Print..." {file:print} "" {Ctrl p} -command "[mymethod _print]"}
	        {command "E&xit" {file:exit} "Exit the application" {Ctrl q} -command "[mymethod _exit]"}
	    }
	    "&Edit" {edit:menu} {edit} 0 {
		{command "&Undo" {edit:undo} "Undo last change" {Ctrl z}}
		{command "Cu&t" {edit:cut edit:havesel} "Cut selection to the paste buffer" {Ctrl x} -command {StdMenuBar EditCut}}
		{command "&Copy" {edit:copy edit:havesel} "Copy selection to the paste buffer" {Ctrl c} -command {StdMenuBar EditCopy}}
		{command "&Paste" {edit:paste edit:havesel} "Paste in the paste buffer" {Ctrl v} -command {StdMenuBar EditPaste}}
		{command "C&lear" {edit:clear edit:havesel} "Clear selection" {} -command {StdMenuBar EditClear}}
		{command "&Delete" {edit:delete edit:havesel} "Delete selection" {Ctrl d}}
		{separator}
		{command "Select All" {edit:selectall} "Select everything" {}}
		{command "De-select All" {edit:deselectall edit:havesel} "Select nothing" {}}
	    }
	    "&View" {view:menu} {view} 0 {
	    }
	    "&Options" {options:menu} {options} 0 {
	    }
	    "&Help" {help:menu} {help} 0 {
		{command "On &Help..." {help:help} "Help on help" {}}
		{command "On &Keys..." {help:keys} "Help on keyboard accelerators" {}}
		{command "&Index..." {help:index} "Help index" {}}
		{command "&Tutorial..." {help:tutorial} "Tutorial" {}}
		{command "On &Version" {help:version} "Version" {}}
		{command "Warranty" {help:warranty} "Warranty" {}}
		{command "Copying" {help:copying} "Copying" {}}
	    }
	}
        option {-extramenus extraMenus ExtraMenus} \
              -readonly yes \
              -default {}
        option -geometry -readonly yes -default 1100x650
        delegate option -height to hull
        delegate option -width  to hull
        delegate method {mainframe *} to hull except {getframe addtoobar 
            gettoolbar showtoolbar}
        
        component   tabs
        component     captianschair -public captianschair -inherit yes
        component     navigationhelm -public navigationhelm -inherit yes
        component     sensors -public sensors -inherit yes 
        component     tactical -public tactical -inherit yes
        component     engineering -public engineering -inherit yes
        component     communication -public communication -inherit yes
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -system -readonly yes -default {} -type ::PlanetarySystemClient::Client
        option -engine -readonly yes -default {} -type ::starships::StarshipEngine
        option -shields -readonly yes -default {} -type ::starships::StarshipShields
        option -misslelaunchers -readonly yes -default {} -type ::starships::StarshipMissleLaunchers
        variable progress 0
        variable status {}
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            if {[lsearch -exact $args -system] < 0} {
                error [_ "The -system option must be specified!"]
            }
            set options(-system) [from args -system]
            if {[lsearch -exact $args -engine] < 0} {
                error [_ "The -engine option must be specified!"]
            }
            set options(-engine) [from args -engine]
            if {[lsearch -exact $args -shields] < 0} {
                error [_ "The -shields option must be specified!"]
            }
            set options(-shields) [from args -shields]
            if {[lsearch -exact $args -misslelaunchers] < 0} {
                error [_ "The -misslelaunchers option must be specified!"]
            }
            set options(-misslelaunchers) [from args -misslelaunchers]
            set options(-menu) [from args -menu]
            set options(-extramenus) [from args -extramenus]
            if {[llength $options(-extramenus)] > 0} {
                set helpIndex [lsearch -exact $options(-menu) "&Help"]
                set menudesc  [eval [list linsert $options(-menu) $helpIndex] \
                               $options(-extramenus)]
            } else {
                set menudesc $options(-menu)
            }
            set menudesc [subst $menudesc]
            installhull using MainFrame  -menu $menudesc -separator none \
                  -textvariable [myvar status] \
                  -progressvar [myvar progress] \
                  -progressmax 100 \
                  -progresstype normal
            $hull showstatusbar progression
            set toplevel [winfo toplevel $win]
            wm withdraw $toplevel
            bind $toplevel <Control-q> [mymethod _exit]
            bind $toplevel <Control-Q> [mymethod _exit]
            wm protocol $toplevel WM_DELETE_WINDOW [mymethod _exit]
            wm title    $toplevel "Starship Bridge"
            set frame [$hull getframe]
            #puts stderr "*** $type create $self: frame is $frame"
            install tabs using ttk::notebook $frame.tabs
            pack $tabs -fill both -expand yes
            install captianschair using ::bridgeconsole::CaptiansChair \
                  $tabs.captianschair -ship $options(-ship)
            $tabs add $captianschair -sticky news -text {Captian's Chair}
            install navigationhelm using ::bridgeconsole::NavigationHelm \
                  $tabs.navigationhelm -ship $options(-ship)
            $tabs add $navigationhelm -sticky news -text {Navigation and Helm}
            install sensors using ::bridgeconsole::SensorsDisplay \
                  $tabs.sensors -ship $options(-ship)
            $tabs add $sensors  -sticky news -text {Sensors}
            install tactical using ::bridgeconsole::TacticalSystem \
                  $tabs.tactical -ship $options(-ship) \
                  -shields $options(-shields) \
                  -misslelaunchers $options(-misslelaunchers)
            $tabs add $tactical -sticky news -text {Tactical}
            install engineering using ::bridgeconsole::EngineeringDisplay \
                  $tabs.engineering -ship $options(-ship) \
                  -engine $options(-engine)
            $tabs add $engineering -sticky news -text {Engineering}
            install communication using ::bridgeconsole::CommunicationsPanel \
                  $tabs.communication -ship $options(-ship)
            $tabs add $communication -sticky news -text {Communications Panel}
            $self configurelist $args
            update idletasks
            wm geometry $toplevel $options(-geometry)
            wm deiconify $toplevel
        }
        method _exit {} {
            exit
        }
        method update {epoch} {
            $captianschair update $epoch
            $navigationhelm update $epoch
            $sensors update $epoch
            $tactical update $epoch
            $engineering update $epoch
            $communication update $epoch
        }
        method updatesensor {epoch thetype direction origin spread imagefile} {
            $sensors updatesensor $epoch $thetype $direction $origin $spread $imagefile
        }
        method setorbiting {orbiting} {
            $sensors setorbiting $orbiting
            $tactical setorbiting $orbiting
            $captianschair setorbiting $orbiting
            $navigationhelm setorbiting $orbiting
        }
        method setsun {sun args} {
            $sensors setsun $sun {*}$args
            $tactical setsun $sun {*}$args
            $captianschair setsun $sun {*}$args
            $navigationhelm setsun $sun {*}$args
        }
        method setplanetinfo {args} {
            #puts stderr "*** $self setplanetinfo $args"
            $sensors setplanetinfo {*}$args
            $tactical setplanetinfo {*}$args
            $captianschair setplanetinfo {*}$args
            $navigationhelm setplanetinfo {*}$args
        }
    }
}


package provide BridgeConsoles 0.1
