#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu Oct 4 16:50:05 2018
#  Last Modified : <220602.1842>
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
                  $win.visible
            pack $visible -side left -expand yes -fill both
            install lidar using ::bridgeconsole::LidarDisplay \
                  $win.lidar
            pack $lidar -side right -expand yes -fill both
            $self configurelist $args
        }
        method update {epoch} {
        }
        method updatesensor {epoch thetype direction origin spread sensorImage} {
        }
    }
    snit::widget JoyButtons {
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
    snit::macro ::bridgeconsole::SensorTools {} {
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
        }
        method _init {args} {
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
        ::bridgeconsole::SensorTools
        constructor {args} {
            $self _init {*}$args
            $hull configure  -text "Visible Light" -labelanchor n
        }
        method _getSensorImage {} {
        }
    }
    snit::widget LidarDisplay {
        ::bridgeconsole::SensorTools
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
        method _getSensorImage {} {
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
    }
    snit::widget CaptiansChair {
        widgetclass CaptiansChair
        hulltype ttk::frame
        option -ship -readonly yes -default {} -type ::starships::Starship
        option -style -default CaptiansChair
        typeconstructor {
            ttk::style layout CaptiansChair {
                CaptiansChair.head -side top -sticky nswe -children {
                    CaptiansChair.status -side left -sticky ns 
                    CaptiansChair.status.position -side top -sticky we
                    CaptiansChair.status.position.label -side top -sticky we
                    CaptiansChair.status.position.x -side left -sticky ns
                    CaptiansChair.status.position.y -side left -sticky ns
                    CaptiansChair.status.position.z -side left -sticky ns
                    CaptiansChair.status.velocity  -side top -sticky we
                    CaptiansChair.status.velocity.label -side top -sticky we
                    CaptiansChair.status.velocity.x -side left -sticky ns
                    CaptiansChair.status.velocity.y -side left -sticky ns
                    CaptiansChair.status.velocity.z -side left -sticky ns
                    CaptiansChair.status.filler    -side bottom -sticky we
                    CaptiansChair.controls -side right -sticky we
                    
                }
            }
            ttk::style layout CaptiansChairHeading [ttk::style layout TLabel]
            ttk::style configure CaptiansChairHeading \
                  -font [list Courier -72 bold] -foreground white \
                  -background black
            ttk::style layout CaptiansChairPositionLabel [ttk::style layout TLabel]
            ttk::style configure CaptiansChairPositionLabel \
                  -font [list Courier -36 bold] -foreground green \
                  -background black
            ttk::style layout CaptiansChair.status.position.label [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.position.label \
                  -font [list Courier -36 bold] -foreground green \
                  -background black
            ttk::style layout CaptiansChair.status.position.x [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.position.y \
                  -font [list Courier -36 bold] -foreground green \
                  -background black
            ttk::style layout CaptiansChair.status.position.y [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.position.y \
                  -font [list Courier -36 bold] -foreground green \
                  -background black
            ttk::style layout CaptiansChair.status.position.z [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.position.z \
                  -font [list Courier -36 bold] -foreground green \
                  -background black
            ttk::style layout CaptiansChairVelocityLabel [ttk::style layout TLabel]
            ttk::style configure CaptiansChairVelocityLabel \
                  -font [list Courier -36 bold] -foreground yellow \
                  -background black
            ttk::style layout CaptiansChair.status.velocity.label [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.velocity.label \
                  -font [list Courier -36 bold] -foreground yellow \
                  -background black
            ttk::style layout CaptiansChair.status.velocity.x [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.velocity.x \
                  -font [list Courier -36 bold] -foreground yellow \
                  -background black
            ttk::style layout CaptiansChair.status.velocity.y [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.velocity.y \
                  -font [list Courier -36 bold] -foreground yellow \
                  -background black
            ttk::style layout CaptiansChair.status.velocity.z [ttk::style layout TLabel]
            ttk::style configure CaptiansChair.status.velocity.z \
                  -font [list Courier -36 bold] -foreground yellow \
                  -background black
        }
        variable _posX
        variable _posY
        variable _posZ
        variable _velX
        variable _velY
        variable _velZ
        variable _epoch
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            set options(-style) [from args -style]
            set head [ttk::label $win.head -textvariable [myvar _epoch] -style CaptiansChairHeading]
            pack $head -fill x
            set status [ttk::frame $win.status]
            pack $status -side left -fill y
            set position [ttk::frame $status.position]
            pack $position -fill x
            set poslabel [ttk::label $position.label -text Position -style CaptiansChairPositionLabel]
            grid $poslabel -row 0 -columnspan 3 -column 0 -sticky news
            set posx [ttk::label $position.x -textvariable [myvar _posX] -style CaptiansChairPositionLabel]
            grid $posx -row 1 -column 0 -sticky news
            set posy [ttk::label $position.y -textvariable [myvar _posY] -style CaptiansChairPositionLabel]
            grid $posy -row 1 -column 1 -sticky news
            set posz [ttk::label $position.z -textvariable [myvar _posZ] -style CaptiansChairPositionLabel]
            grid $posz -row 1 -column 2 -sticky news
            set velocity [ttk::frame $status.velocity]
            pack $velocity -fill x
            set poslabel [ttk::label $velocity.label -text Velocity -style CaptiansChairVelocityLabel]
            grid $poslabel -row 0 -columnspan 3 -column 0 -sticky news
            set posx [ttk::label $velocity.x -textvariable [myvar _velX] -style CaptiansChairVelocityLabel]
            grid $posx -row 1 -column 0 -sticky news
            set posy [ttk::label $velocity.y -textvariable [myvar _velY] -style CaptiansChairVelocityLabel]
            grid $posy -row 1 -column 1 -sticky news
            set posz [ttk::label $velocity.z -textvariable [myvar _velZ] -style CaptiansChairVelocityLabel]
            grid $posz -row 1 -column 2 -sticky news
            pack [ttk::frame $status.filler] -side bottom -expand yes -fill both
            set controls [ttk::frame $win.controls]
            pack $controls  -side right -fill y -expand yes
            $self configurelist $args
        }
        method update {epoch} {
            set _epoch [format {%20lld} [expr {wide($epoch)}]]
            set position [$options(-ship) position]
            set _posX [format {%10.3g} [$position GetX]]
            set _posY [format {%10.3g} [$position GetY]]
            set _posZ [format {%10.3g} [$position GetZ]]
            set velocity [$options(-ship) velocity]
            set _velX [format {%10.3g} [$velocity GetX]]
            set _velY [format {%10.3g} [$velocity GetY]]
            set _velZ [format {%10.3g} [$velocity GetZ]]
        }
    }
    snit::widget NavigationHelm {
        option -ship -readonly yes -default {} -type ::starships::Starship
        constructor {args} {
            if {[lsearch -exact $args -ship] < 0} {
                error [_ "The -ship option must be specified!"]
            }
            set options(-ship) [from args -ship]
            $self configurelist $args
        }
        method update {epoch} {
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
        method updatesensor {epoch thetype direction origin spread sensorImage} {
            $sensors updatesensor $epoch $thetype $direction $origin $spread $sensorImage
        }
    }
}


package provide BridgeConsoles 0.1
