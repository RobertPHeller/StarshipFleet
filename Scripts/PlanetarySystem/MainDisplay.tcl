#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu Apr 21 09:30:02 2016
#  Last Modified : <220531.1738>
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


package require Tk
package require tile
package require MainFrame
package require snitStdMenuBar
package require SystemDisplay
package require ScrollWindow
package require ButtonBox

namespace eval planetarysystem {
    snit::widgetadaptor MainScreen {
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
        option -geometry -readonly yes -default 1024x768
        delegate option -height to hull
        delegate option -width  to hull
        delegate method {mainframe *} to hull except {getframe addtoobar 
            gettoolbar showtoolbar}
        component tabs
        component   systemdisplay
        delegate method {systemdisplay *} to systemdisplay
        delegate option * to systemdisplay
        component   sensors
        delegate method {sensors *} to sensors
        component   communication
        delegate method {communication *} to communication
        component   weaponsystem
        delegate method {weaponsystem *} to weaponsystem
        variable progress 0
        variable status {}
        constructor {args} {
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
            installhull using MainFrame -menu $menudesc -separator none \
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
            wm title    $toplevel "Main Starship Display"
            set frame [$hull getframe]
            #install systemdisplay using planetarysystem::PlanetaryDisplay \
            #      $frame.pd -seed [from args -seed 0] \
            #      -stellarmass [from args -stellarmass 0.0] \
            #      -generate [from args -generate yes] \
            #      -filename [from args -filename PlanetarySystem.system]
            #pack $systemdisplay -expand yes -fill both
            install tabs using ttk::notebook $frame.tabs
            pack $tabs -fill both -expand yes
            install systemdisplay using planetarysystem::PlanetaryDisplay \
                  $tabs.pd -seed [from args -seed 0] \
                  -stellarmass [from args -stellarmass 0.0] \
                  -generate [from args -generate yes] \
                  -filename [from args -filename PlanetarySystem.system]
            $tabs add $systemdisplay -sticky news -text {System Schematic}
            install sensors using planetarysystem::SensorsDisplay \
                  $tabs.sensors
            $tabs add $sensors  -sticky news -text {Sensors}
            install communication using planetarysystem::CommunicationsPanel \
                  $tabs.communication
            $tabs add $communication -sticky news -text {Communications Panel}
            install weaponsystem using planetarysystem::WeaponSystem \
                  $tabs.weaponsystem
            $tabs add $weaponsystem -sticky news -text {Weapons System}
            $self configurelist $args
            update idletasks
            wm geometry $toplevel $options(-geometry)
            $systemdisplay seecenter [$systemdisplay GetSun]
            wm deiconify $toplevel
        }
        method _exit {} {
            exit
        }
        method _new {} {
            # (-seed & -stellarmass ?)
            $systemdisplay renew
        }
        method _open {} {
            set filename [tk_getOpenFile -defaultextension .system \
                          -filetypes { {{System Files} .system} } \
                          -initialdir [pwd] \
                          -initialfile PlanetarySystem.system \
                          -parent [winfo toplevel $win] \
                          -title "System File to load"]
            if {$filename eq ""} {return}
            $systemdisplay reopen -filename $filename
        }
        method _save {} {
            $self _saveas [$systemdisplay cget -filename]
        }
        method _saveas {{filename {}}} {
            if {$filename eq ""} {
                set filename [tk_getSaveFile -defaultextension .system \
                          -filetypes { {{System Files} .system} } \
                          -initialdir [pwd] \
                          -initialfile [$systemdisplay cget -filename] \
                          -parent [winfo toplevel $win] \
                              -title "System File to load"]
                }
            if {$filename eq ""} {return}
            $systemdisplay save $filename
        }
        method _print {} {
            set pdffile [$systemdisplay _print]
            tk_messageBox -type ok -icon info \
                  -message [format "Output saved in %s" $pdffile]
        }
    }
    snit::widget SensorsDisplay {
        component visible
        delegate method {visible *} to visible
        component lidar
        delegate method {lidar *} to lidar
        option -style -default SensorsDisplay
        constructor {args} {
            install visible using planetarysystem::VisibleDisplay \
                  $win.visible
            pack $visible -side left -expand yes -fill both
            install lidar using planetarysystem::LidarDisplay \
                  $win.lidar
            pack $lidar -side right -expand yes -fill both
            $self configurelist $args
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
    snit::macro ::planetarysystem::SensorTools {} {
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
            $tools add planetarysystem::JoyButtons joybuttons \
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
        ::planetarysystem::SensorTools
        constructor {args} {
            $self _init {*}$args
            $hull configure  -text "Visible Light" -labelanchor n
        }
        method _getSensorImage {} {
        }
    }
    snit::widget LidarDisplay {
        ::planetarysystem::SensorTools
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
            eval [list ttk::style configure CommunicationsPanel.OutOfOrder] [ttk::style configure TLabel]
            ttk::style configure CommunicationsPanel.OutOfOrder \
                  -font [list Courier -72 bold] \
                  -foreground red \
                  -background black
        }
        component outoforder
        option -style -default CommunicationsPanel
        constructor {args} {
            set options(-style) [from args -style]
            install outoforder using ttk::label $win.outoforder \
                  -style ${options(-style)}.OutOfOrder -text "Out Of Order"
            pack $outoforder -fill both -expand yes
        }
    }
    snit::widget WeaponSystem {
        typeconstructor {
            ttk::style layout WeaponSystem {
                WeaponSystem.head -side top -sticky nswe -children {
                    WeaponSystem.outoforder -side top -sticky nswe}}
            ttk::style layout WeaponSystem.OutOfOrder \
                  [ttk::style layout TLabel]
            eval [list ttk::style configure WeaponSystem.OutOfOrder] [ttk::style configure TLabel]
            ttk::style configure WeaponSystem.OutOfOrder \
                  -font [list Courier -72 bold] \
                  -foreground red \
                  -background black
        }
        component outoforder
        option -style -default WeaponSystem
        constructor {args} {
            set options(-style) [from args -style]
            install outoforder using ttk::label $win.outoforder \
                  -style ${options(-style)}.OutOfOrder -text "Out Of Order"
            pack $outoforder -fill both -expand yes
        }
    }
    namespace export MainScreen LidarDisplay CommunicationsPanel WeaponSystem
}

package provide MainDisplay 0.1
