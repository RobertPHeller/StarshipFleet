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
#  Last Modified : <170123.1535>
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


package require log
package require snit
package require PlanetarySystem

namespace eval PlanetarySystemServer {
    snit::type clientobjects {
        option -serverid -readonly yes -default 0
        option -position -default {0 0 0}
        option -velocity -default {0 0 0}
        option -thustvector -default {0 0 0}
        option -clientconnection -readonly yes -default {}
        option -mass -default 0
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
        typemethod SequenceNumber {} {
            return [clock milliseconds]
        }
        typevariable logchan
        typemethod InitServer {args} {
            if {[llength $args] > 0 && [lindex $args 0] eq "-debug"} {
                set debugnotvis 0
                set args [lrange $args 1 end]
            } else {
                set debugnotvis 1
            }
            set logfilename [format {%s.log} [file tail $::argv0]]
            close stdin
            close stdout
            close stderr
            open /dev/null r
            open /dev/null w
            set logchan [open $logfilename w]
            fconfigure $logchan  -buffering none
            
            ::log::lvChannelForall $logchan
            ::log::lvSuppress info 0
            ::log::lvSuppress notice 0
            ::log::lvSuppress debug $debugnotvis
            ::log::lvCmdForall [mytypemethod LogPuts]
            
            ::log::logMsg [format "%s starting" $type]
            ::log::log debug [list *** $type InitServer: args = $args]
            
            set port [from args -port 5050]
            set myaddr [from args -myaddr 0.0.0.0]
            set seed [from args -seed 0]
            set stellarmass [from args -stellarmass  0.0]
            set generate [from args -generate true]
            set filename [from args -filename PlanetarySystem.system]
            set system [PlanetarySystem %AUTO% -generate $generate \
                        -seed $seed -stellarmass $stellarmass \
                        -filename $filename]
            #puts stderr "*** $type InitServer: system = $system"
            #$system print stderr
            $system add $type
            set serversocket [socket -server [mytypemethod _accept] \
                              -myaddr $myaddr $port]
        }
        typemethod _accept {channel address host} {
            $type create %AUTO% $channel $address $host
        }
        typemethod LogPuts {level message} {
            puts [::log::lv2channel $level] "[clock format [clock scan now] -format {%b %d %T}] \[[pid]\] $level $message"
	}
        typevariable objects -array {}
        typevariable _ID 0
        typemethod update {epoch} {
            ::log::log debug "*** $type update $epoch"
            foreach serverid [array names objects] {
                set object $objects($serverid)
                set o [$object cget -orbit]
                $o RelativePosVelAtTime pos vel $epoch
                set tv [$object cget -thustvector]
                set tvel [Vector copy [$object cget -velocity]]
                $tvel += $tv
                $tvel configure -par 1
                $vel configure -par 0
                Vector Interpolate [list $tvel $vel] 1.0 vout verr
                $pos configure -par 0
                set tpos [Vector copy [$object cget -position]]
                $tpos += $tvel
                Vector Interpolate [list $tpos $vel] 1.0 pout perr
                set refbody [$object cget -refbody]
                [$object cget -body] SetPosition $pout
                [$object cget -body] SetVelocity $vout
                set absvel [Vector copy $vout]
                $absvel += [$refbody velocity]
                $object configure -velocity $vout
                set abspos [Vector copy $pout]
                $abspos += [$refbody position]
                $object configure -position $pout
                # update pos: object
                $self sendResponse 200 [$type SequenceNumber] UPDATE \
                      -remoteid $serverid \
                      -position [list [$abspos GetX] [$abspos GetY] [$abspos GetZ]] \
                      -velocity [list [$absvel GetX] [$absvel GetY] [$absvel GetZ]] \
                      -epoch $epoch
            }
        }
        variable channel 
        variable address 
        variable port
        constructor {_channel _address _port} {
            set channel $_channel
            #puts stderr "*** $type create $self: channel = $channel"
            fconfigure $channel  -buffering line
            #puts stderr "*** $type create $self: fconfigure $channel = [fconfigure $channel]"
            set address $_address
            set port $_port
            log::logMsg [format "Connection from %s:%d accepted" $address $port]
            $self sendResponse 200 [$type SequenceNumber] INIT \
                  -timeunits [$::orsa::units GetTimeBaseUnit] \
                  -lengthunits [$::orsa::units GetLengthBaseUnit] \
                  -massunits [$::orsa::units GetMassBaseUnit]
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
                        set clientid [from args -id 0]
                        set position [eval [list Vector create %AUTO%] [from args -position [list 0 0 0]]]
                        set velocity [eval [list Vector create %AUTO%] [from args -velocity [list 0 0 0]]]
                        set mass     [from args -mass 0]
                        set thustvector [eval [list Vector create %AUTO%] [from args -thustvector [list 0 0 0]]]
                        # Assume orbit is about the sun.  Should really compute
                        # 'nearest' body
                        set refbody [[$system GetSun] GetBody]
                        $position -= [$refbody position]
                        $velocity -= [$refbody velocity]
                        set body [Body create %AUTO% "" $mass $position $velocity]
                        set orbit [OrbitWithEpoch create %AUTO%]
                        $orbit Compute Body $body $refbody [$system getepoch]
                        set objects($serverid) [clientobjects create %AUTO% \
                                                -serverid $serverid \
                                                -position $position \
                                                -velocity $velocity \
                                                -thustvector $thustvector \
                                                -mass $mass \
                                                -refbody $refbody \
                                                -body $body \
                                                -orbit $orbit \
                                                -clientconnection $self]
                        $self sendResponse 200 $sequence $command \
                              -id $clientid -remoteid $serverid \
                              -epoch [$system getepoch]
                    }
                    UPDATE_THRUST {
                        set serverid [from args -remoteid 0]
                        set thustvector [from args -thustvector [list 0 0 0]]
                        if {[catch {set objects($serverid)} object]} {
                            $self sendResponse 410 $sequence $command \
                                  -message [format "No such object (%d)" $serverid]
                        } else {
                            $object configure -thustvector $thustvector
                        }
                    }
                    UPDATE_MASS {
                        set serverid [from args -remoteid 0]
                        set mass     [from args -mass 0]
                        if {[catch {set objects($serverid)} object]} {
                            $self sendResponse 410 $sequence $command \
                                  -message [format "No such object (%d)" $serverid]
                        } else {
                            $object configure -mass $mass
                        }
                    }
                    ### Sensor logic: visible light, LIDAR, RADAR, etc.
                    ### SENSOR SEQ -type {VISIBLE LIDAR RADAR} -direction DirVect
                    ### Returns SEQ Sensor data (depends on type)
                    default {
                        $self sendResponse 404 $sequence $command -message [format "Unknown command %s" $command]
                    }
                }
            }
        }
        method sendResponse {args} {
            puts $channel $args
        }
        destructor {
            #puts stderr "*** $self destroy"
            catch {close $channel}
            #puts stderr "*** $self destroy: channel closed"
            foreach serverid [array names objects] {
                set object $objects($serverid)
                if {[$object cget -clientconnection] eq $self} {
                    $object destroy
                    unset objects($serverid)
                }
            }
            #puts stderr "*** $self destroy: removed client objects"
            ::log::logMsg [format "Connection from %s:%d closed" $address $port]
        }
    }
    namespace export Server
}

    
    
    
    
    
    
    
    
    






package provide PlanetarySystemServer 0.1

