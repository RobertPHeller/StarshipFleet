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
#  Last Modified : <160507.1713>
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
    snit::type clientobjects {
        option -serverid -readonly yes -default 0
        option -position -default {0 0 0}
        option -velocity -default {0 0 0}
        option -thustvector -default {0 0 0}
        option -clientconnection -readonly yes -default {}
        constructor {args} {
            $self configurelist $args
        }
    }
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
            #$system print stderr
            set serversocket [socket -server [mytypemethod _accept] \
                              -myaddr $myaddr $port]
        }
        typemethod _accept {channel address host} {
            $type create %AUTO% $channel $address $host
        }
        typevariable objects -array {}
        typevariable _ID 0
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
                set message [split $line " "]
                set command [lindex $response 0]
                set sequence [lindex $response 1]
                set args [lrange $response 3 end]
                switch [string toupper $command] {
                    ADD {
                        incr _ID
                        set serverid $_ID
                        set clientid [from args -id]
                        set position [from args -position]
                        set velocity [from args -velocity]
                        set thustvector [from args -thustvector]
                        set objects($serverid) [clientobjects create %AUTO% \
                                         -serverid $serverid \
                                         -position $position \
                                         -velocity $velocity \
                                         -thustvector $thustvector \
                                         -clientconnection $self]
                        $self sendResponse 200 $sequence $command \
                              -id $clientid -remoteid $serverid \
                              -epoch [$system getepoch]
                    }
                    UPDATE_THRUST {
                        set serverid [from args -remoteid]
                        set thustvector [from args -thustvector]
                        if {[catch {set objects($serverid)} object]} {
                            $self sendResponse 410 $sequence $command \
                                  -message [format "No such object (%d)" $serverid]
                        } else {
                            $object configure -thustvector $thustvector
                        }
                    }
                    default {
                        $self _response 404 $sequence $command -message [format "Unknown command %s" $command]
                    }
                }
            }
        }
        method _response {args} {
            puts $channel $args
        }
        destructor {
            catch {close $channel}
        }
    }
    namespace export Server
}

    
    
    
    
    
    
    
    
    






package provide PlanetarySystemServer 0.1

