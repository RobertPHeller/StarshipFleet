#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Tue May 10 14:40:38 2016
#  Last Modified : <160510.1502>
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


lappend auto_path [file dirname [file normalize [info script]]]

package require orsa

namespace import ::orsa::*

proc print {v} {
    puts [format {%lg %lg %lg} [$v GetX] [$v GetY] [$v GetZ]]
}

Vector a 0 10 0

print a

Vector b 3 6 7

print b

print [a + b]

print a
print b
puts [a ScalarProduct b]

Vector c $::orsa::pi $::orsa::twopi $::orsa::pisq

print c

set d [a ExternalProduct b]

print $d

puts "(1) [$::orsa::units GetG]"
puts "(2) [GetG]"

puts "G*MSun = [expr {[GetG]*[GetMSun]}]"

puts [format {G*MSun = %24.18f} [expr {[GetG] * [GetMSun]}]]
puts [format {  MSun = %24.18f} [GetMSun]]

set samples [list \
             [Vector %AUTO% -5 0 77 -par 0] \
             [Vector %AUTO% -4 2 73 -par 1] \
             [Vector %AUTO% -3 4 72 -par 2] \
             [Vector %AUTO% -2 6 77 -par 3]]

puts "size: [llength $samples]"

Vector Interpolate $samples 1.9 vi verr

print $vi
print $verr

Vector per 1 2 3
Vector par 0 0 0
Vector pir 0 0 0

print per
print par
print pir

par = [per * 7.0]

print per
print par
print pir

pir = [per / 3.0]

print per
print par
print pir


