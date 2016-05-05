#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Wed Apr 20 11:30:12 2016
#  Last Modified : <160505.1301>
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
package require ScrollWindow
package require ListBox
package require LabelFrames

namespace eval planetarysystem {
    
    snit::widget ObjectDetailDisplay {
        widgetclass ObjectDetailDisplay
        hulltype tk::toplevel
        component head;# heading frame (ttk::frame)
        component   graphic;# Object colored disk (canvas)
        component   namelabel;# Object name (ttk::label -- large font)
        component   mass;# Object mass (LabelEntry, RO)
        component   position;# Object position (LabelEntry, RO)
        component   velocity;# Object velocity (LabelEntry, RO)
        component optsscroll;# Object option list scroll window (ScrollWindow)
        component   optlist;# Object option list (ListBox)
        component dismis;# Dismis button (ttk::button)
        option -diskcolor -default white -readonly yes
        option -disksize -default 10 -type snit::pixels -readonly yes
        delegate option -name to namelabel as -text
        option -mass -readonly yes -type snit::double -default 0
        option -munits -readonly yes -default "Sun Masses"
        option -position -readonly yes -type ::orsa::Vector
        option -velocity -readonly yes -type ::orsa::Vector
        option -optlist  -readonly yes -type snit::listtype 
        option -style -default ObjectDetailDisplay
        option -parent -default . -type snit::window
        typeconstructor {
            ttk::style layout ObjectDetailDisplay {
                ObjectDetailDisplay.head 
                     -side top 
                     -sticky nswe 
                     -children {
                         ObjectDetailDisplay.graphic 
                             -side left 
                             -sticky nswe
                         ObjectDetailDisplay.info
                             -side right
                             -sticky nswe
                             -children {
                                 ObjectDetailDisplay.name -side top -sticky nswe
                                 ObjectDetailDisplay.mass -side top -sticky nswe   
                                 ObjectDetailDisplay.position -side top -sticky nswe
                                 ObjectDetailDisplay.velocity -side top -sticky nswe   
                             }
                         }
                ObjectDetailDisplay.body
                    -side bottom
                    -sticky nswe
            }
            ttk::style layout ObjectDetailDisplay.Name [ttk::style layout TLabel]
            eval [list ttk::style configure ObjectDetailDisplay.Name] [ttk::style configure TLabel]
            ttk::style configure ObjectDetailDisplay.Name \
                  -font [list Courier -24 bold]
        }
        constructor {args} {
            set options(-parent) [from args -parent]
            wm transient $win $options(-parent)
            set options(-style) [from args -style]
            install head using ttk::frame $win.head
            pack $head -fill x -expand yes
            install graphic using canvas $head.graphic -background black \
                  -borderwidth 0 -width 100 -height 100
            grid columnconfigure $head 0 -weight 0
            grid columnconfigure $head 1 -weight 1
            grid $graphic -column 0 -row 0 -sticky news
            set info [ttk::frame $head.info]
            grid $info -column 1 -row 0 -sticky news
            install namelabel using ttk::label $info.namelabel \
                  -style ${options(-style)}.Name
            pack $namelabel -fill x
            install mass using LabelEntry $info.mass -editable no \
                  -label "Mass:"
            pack $mass -fill x
            install position using LabelEntry $info.position -editable no \
                  -label "Position:"
            pack $position -fill x
            install velocity using LabelEntry $info.velocity -editable no \
                  -label "Velocity:"
            pack $velocity -fill x
            install optsscroll using ScrolledWindow $win.optsscroll \
                  -scrollbar vertical -auto vertical
            pack $optsscroll -fill both -expand yes
            install optlist using ListBox $optsscroll.optlist
            $optsscroll setwidget $optlist
            install dismis using ttk::button $win.dismis -text "Dismis" \
                  -command "destroy $win"
            pack $dismis -fill x
            $self configurelist $args
            wm title $win [format "Object details for %s" \
                           [$namelabel cget -text]]
            update idle
            set cw [winfo reqwidth $graphic]
            set ch [winfo reqheight $graphic]
            set centerx [expr {$cw / 2.0}]
            set centery [expr {$ch / 2.0}]
            set dxdy [expr {$options(-disksize) / 2.0}]
            set x1   [expr {$centerx - $dxdy}]
            set y1   [expr {$centery - $dxdy}]
            set x2   [expr {$centerx + $dxdy}]
            set y2   [expr {$centery + $dxdy}]
            $graphic create oval $x1 $y1 $x2 $y2 -fill $options(-diskcolor)
            $mass configure -text [format "%g %s" $options(-mass) $options(-munits)]
            $position configure -text [format "%g %g %g" \
                                       [$options(-position) GetX] \
                                       [$options(-position) GetY] \
                                       [$options(-position) GetZ]]
            $velocity configure -text [format "%g %g %g" \
                                       [$options(-velocity) GetX] \
                                       [$options(-velocity) GetY] \
                                       [$options(-velocity) GetZ]]
            foreach {option value} $options(-optlist) {
                $optlist insert end $option -text "$option $value"
            }
        }
    }
    namespace export ObjectDetailDisplay

}

package provide ObjectDetail 0.1            
