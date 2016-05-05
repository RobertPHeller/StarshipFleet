#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu May 5 12:23:23 2016
#  Last Modified : <160505.1348>
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

namespace eval PlanetarySystemClient {
    snit::type Client {
        variable channel
        option -port -readonly yes -default 5050
        option -host -readonly yes -default localhost
        constructor {args} {
            $self configurelist $args
            set channel [socket $options(-host) $options(-port)]
            fileevent readable $channel [mytypemethod _listener]
        }
        method _listener {} {
            if {[gets $channel line] < 0} {
                $self destroy
            } else {
            }
        }
        destructor {
            catch {close $channel}
        }
    }
    namespace export Client
}

        

package provide PlanetarySystemClient 0.1

