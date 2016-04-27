#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Mon Apr 11 14:01:31 2016
#  Last Modified : <160427.1347>
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


namespace eval stargen::utils {
    proc random_number {inner outer} {
        set range [expr {$outer - $inner}]
        return [expr {(rand() * $range) + $inner}]
    }
    proc about {value variation} {
        set mv [expr {0.0 - $variation}]
        return [expr {$value + [random_number $mv $variation]}]
    }
    proc random_eccentricity {} {
        set e [expr {1.0 - pow(rand(),$::stargen::ECCENTRICITY_COEFF)}]
        if {$e > .99} {set e .99}
        return $e
    }
    namespace export random_number about random_eccentricity
}

namespace eval ::tcl::mathfunc:: {
    namespace import ::stargen::utils::about
}


