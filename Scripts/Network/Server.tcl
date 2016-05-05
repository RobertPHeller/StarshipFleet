#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu May 5 12:22:56 2016
#  Last Modified : <160505.1254>
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
package require PlanetarySystem

namespace eval PlanetarySystemServer {
    snit::type Server {
        typecomponent system
        delegate typemethod * to system except {load destroy _generate _print
            _init _sunMenu _planetMenu _suncenter _planetcenter _addtools
            _cleartools _zoomin _zoom1 _zoomout _DoZoom _togglesunlabel
            _sunInfo _detailedSunInfo _planetInfo _toggleplanetlabel
            _toggleplanetorbit _detailedPlanetInfo}
        typecomponent serversocket
        typemethod InitServer {args} {
            set port [from args -port 5050]
            set myaddr [from args -myaddr 0.0.0.0]
            set seed [from args -seed 0]
            set stellarmass [from args -stellarmass  0.0]
            set generate [from args -generate true]
            set filename [from args -filename PlanetarySystem.system]
            set system [PlanetarySystem %AUTO% -generate $generate \
                        -seed $seed -stellarmass $stellarmass \
                        -filename $filename]
            set serversocket [socket -server [mytypemethod _accept] \
                              -myaddr $myaddr $port]
        }
        typemethod _accept {channel address host} {
            $type create %AUTO% $channel $address $host
        }
        variable channel 
        variable address 
        variable host
        constructor {_channel _address _host} {
            set channel $_channel
            set address $_address
            set host $_host
            fileevent $channel readable [mymethod _listener]
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
    namespace export Server
}

    
    
    
    
    
    
    
    
    






package provide PlanetarySystemServer 0.1

