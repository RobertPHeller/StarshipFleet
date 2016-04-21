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
#  Last Modified : <160421.1451>
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
        delegate option -height to hull
        delegate option -width  to hull
        delegate method {mainframe *} to hull except {getframe addtoobar 
            gettoolbar showtoolbar}
        component tabs
        component   systemdisplay
        delegate method {systemdisplay *} to systemdisplay
        delegate option * to systemdisplay
        component   lidar
        delegate method {lidar *} to lidar
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
            bind $toplevel <Control-q> [mymethod _exit]
            bind $toplevel <Control-Q> [mymethod _exit]
            wm protocol $toplevel WM_DELETE_WINDOW [mymethod _exit]
            wm title    $toplevel "Main Starship Display"
            set frame [$hull getframe]
            install tabs using ttk::notebook $frame.tabs
            pack $tabs -fill both -expand yes
            install systemdisplay using planetarysystem::PlanetaryDisplay \
                  $tabs.pd -seed [from args -seed 0] \
                  -stellarmass [from args -stellarmass 0.0] \
                  -generate [from args -generate yes] \
                  -filename [from args -filename PlanetarySystem.system]
            $tabs add $systemdisplay -sticky news -text {System Schematic}
            install lidar using planetarysystem::LidarDisplay \
                  $tabs.lidar
            $tabs add $lidar  -sticky news -text {LIDAR}
            install communication using planetarysystem::CommunicationsPanel \
                  $tabs.communication
            $tabs add $communication -sticky news -text {Communications Panel}
            install weaponsystem using planetarysystem::WeaponSystem \
                  $tabs.weaponsystem
            $tabs add $weaponsystem -sticky news -text {Weapons System}
            $self configurelist $args
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
    
    snit::widget LidarDisplay {
        typeconstructor {
            ttk::style layout LidarDisplay {
                LidarDisplay.head -side top -sticky nswe -children {
                    LidarDisplay.outoforder -side top -sticky nswe}}
            ttk::style layout LidarDisplay.OutOfOrder \
                  [ttk::style layout TLabel]
            eval [list ttk::style configure LidarDisplay.OutOfOrder] [ttk::style configure TLabel]
            ttk::style configure LidarDisplay.OutOfOrder \
                  -font [list Courier -72 bold] \
                  -foreground red \
                  -background black
        }
        component outoforder
        option -style -default LidarDisplay
        constructor {args} {
            set options(-style) [from args -style]
            install outoforder using ttk::label $win.outoforder \
                  -style ${options(-style)}.OutOfOrder -text "Out Of Order"
            pack $outoforder -fill both -expand yes
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

