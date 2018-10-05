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
#  Last Modified : <181004.1726>
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
package require base64
package require tclgd

namespace eval PlanetarySystemServer {
    snit::type clientobjects {
        option -serverid -readonly yes -default 0
        option -position -default {0 0 0}
        option -velocity -default {0 0 0}
        option -thustvector -default {0 0 0}
        option -clientconnection -readonly yes -default {}
        option -mass -default 0
        option -orbiting -default {}
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
            ::log::log debug "*** $type InitServer: system = $system"
            if {!$debugnotvis} {$system print $logchan}
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
                set orbit [$object cget -orbit]
                $orbit RelativePosVelAtTime pos vel $epoch
                set tv [$object cget -thustvector]
                set tvel [Vector copy [$object cget -velocity]]
                $tvel += $tv
                $tvel configure -par 1
                $vel configure -par 0
                Vector Interpolate [list $tvel $vel] 1.0 velocity verr
                $pos configure -par 0
                set tpos [Vector copy [$object cget -position]]
                $tpos += $tvel
                Vector Interpolate [list $tpos $vel] 1.0 position perr
                set orbiting [$object cget -orbiting]
                set refbody [$object cget -refbody]
                [$object cget -body] SetPosition $position
                [$object cget -body] SetVelocity $velocity
                $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                if {$orbiting eq [$system GetSun]} {
                    set captureBody [$system PlantaryCapture $mass \
                                     [$position + [$refbody position]] \
                                     [$velocity + [$refbody velocity]]]
                    if {$captureBody ne {}} {
                        ### object is on a plantary capture orbit...
                        ### Update: orbiting, refbody, body, orbit; 
                        ### recompute position and velocity
                        set orbiting $captureBody
                        $velocity += [$refbody velocity]
                        $position += [$refbody position]
                        set refbody [$orbiting GetBody]
                        $velocity -= [$refbody velocity]
                        $position -= [$refbody velocity]
                        [$object cget -body] SetPosition $position
                        [$object cget -body] SetVelocity $velocity
                        $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                        $object configure -orbiting $orbiting \
                              -refbody $refbody
                    }
                } elseif {[$orbit OrbitalType] eq "escape"} {
                    set planet $orbiting
                    set pposition [Vector copy $position]
                    set pvelocity [Vector copy $velocity]
                    set prefbody $refbody
                    if {[$planet parent] ne {}} {
                        $pposition += [$prefbody position]
                        $pvelocity += [$prefbody velocity]
                        set planet [$planet parent]
                        set prefbody [$planet cget -refbody]
                    }
                    set captureBody [$planet SateliteCapture $mass \
                                     [$pposition + [$prefbody position]] \
                                     [$pvelocity + [$prefbody velocity]]]
                    if {$captureBody ne {}} {
                        ### object is on a transfer orbit to a moon
                        ### Update: orbiting, refbody, body, orbit; 
                        ### recompute position and velocity
                        set orbiting $captureBody
                        $velocity += [$refbody velocity]
                        $position += [$refbody position]
                        set refbody [$orbiting GetBody]
                        $velocity -= [$refbody velocity]
                        $position -= [$refbody velocity]
                        [$object cget -body] SetPosition $position
                        [$object cget -body] SetVelocity $velocity
                        $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                        $object configure -orbiting $orbiting \
                              -refbody $refbody
                    } else {
                        set captureBody [$system PlantaryCapture $mass \
                                         [$position + [$refbody position]] \
                                         [$velocity + [$refbody velocity]]]
                        if {$captureBody ne {}} {
                            ### object is on a transfer orbit to another planet
                            ### Update: orbiting, refbody, body, orbit; 
                            ### recompute position and velocity
                            set orbiting $captureBody
                            $velocity += [$refbody velocity]
                            $position += [$refbody position]
                            set refbody [$orbiting GetBody]
                            $velocity -= [$refbody velocity]
                            $position -= [$refbody velocity]
                            [$object cget -body] SetPosition $position
                            [$object cget -body] SetVelocity $velocity
                            $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                            $object configure -orbiting $orbiting \
                                  -refbody $refbody
                        } else {
                            ### object is now in a solar orbit
                            ### Update: orbiting, refbody, body, orbit; 
                            ### recompute position and velocity
                            set orbiting [$system GetSun]
                            $velocity += [$refbody velocity]
                            $position += [$refbody position]
                            set refbody [$orbiting GetBody]
                            $velocity -= [$refbody velocity]
                            $position -= [$refbody velocity]
                            [$object cget -body] SetPosition $position
                            [$object cget -body] SetVelocity $velocity
                            $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                            $object configure -orbiting $orbiting \
                                  -refbody $refbody
                        }
                    }
                }
                set absvel [Vector copy $velocity]
                $absvel += [$refbody velocity]
                $object configure -velocity $velocity
                set abspos [Vector copy $position]
                $abspos += [$refbody position]
                $object configure -position $position
                
                # update pos: object
                $self sendResponse 200 [$type SequenceNumber] UPDATE \
                      -remoteid $serverid \
                      -position [list [$abspos GetX] [$abspos GetY] [$abspos GetZ]] \
                      -velocity [list [$absvel GetX] [$absvel GetY] [$absvel GetZ]] \
                      -epoch $epoch \
                      -orbiting $orbiting
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
        proc infraredSense {direction origin spread} {
            set resultImage [GD create #auto 128 128]
            return $resultImage
        }
        proc radioSense {direction origin spread} {
            set resultImage [GD create #auto 128 128]
            return $resultImage
        }
        proc visibleSense {direction origin spread} {
            set resultImage [GD create_truecolor #auto 128 128]
            return $resultImage
        }
        proc lidarSense {direction origin spread} {
            set resultImage [GD create #auto 128 128]
            return $resultImage
        }
        proc radarSense {direction origin spread} {
            set resultImage [GD create #auto 128 128]
            return $resultImage
        }
        method _listener {} {
            if {[gets $channel line] < 0} {
                $self destroy
            } else {
                ::log::log debug "*** $self _listener: line is $line"
                set message [split $line " "]
                set command [lindex $message 0]
                set sequence [lindex $message 1]
                set args [lrange $message 3 end]
                switch [string toupper $command] {
                    ADD {
                        incr _ID
                        set serverid $_ID
                        set clientid [from args -id 0]
                        set position [eval [list Vector create %AUTO%] [from args -position [list 0 0 0]]]
                        set velocity [eval [list Vector create %AUTO%] [from args -velocity [list 0 0 0]]]
                        set mass     [from args -mass 0]
                        set thustvector [eval [list Vector create %AUTO%] [from args -thustvector [list 0 0 0]]]
                        set orbiting [from args -orbiting [$system GetSun]]
                        set refbody [$orbiting GetBody]
                        $position -= [$refbody position]
                        $velocity -= [$refbody velocity]
                        set body [Body create %AUTO% "" $mass $position $velocity]
                        set orbit [OrbitWithEpoch create %AUTO%]
                        $orbit Compute Body $body $refbody [$system getepoch]
                        if {$orbiting eq [$system GetSun]} {
                            set captureBody [$system PlantaryCapture $mass \
                                             [$position + [$refbody position]] \
                                             [$velocity + [$refbody velocity]]]
                            if {$captureBody ne {}} {
                                ### object is on a capture orbit...
                                ### Update: orbiting, refbody, body, orbit; 
                                ### recompute position and velocity
                                set orbiting $captureBody
                                $velocity += [$refbody velocity]
                                $position += [$refbody position]
                                set refbody [$orbiting GetBody]
                                $velocity -= [$refbody velocity]
                                $position -= [$refbody velocity]
                                [$object cget -body] SetPosition $position
                                [$object cget -body] SetVelocity $velocity
                                $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                            }
                        } elseif {[$orbit OrbitalType] eq "escape"} {
                            set planet $orbiting
                            set pposition [Vector copy $position]
                            set pvelocity [Vector copy $velocity]
                            set prefbody $refbody
                            if {[$planet parent] ne {}} {
                                $pposition += [$prefbody position]
                                $pvelocity += [$prefbody velocity]
                                set planet [$planet parent]
                                set prefbody [$planet GetBody]
                            }
                            set captureBody [$planet SateliteCapture $mass \
                                             [$pposition + [$prefbody position]] \
                                             [$pvelocity + [$prefbody velocity]]]
                            if {$captureBody ne {}} {
                                ### object is on a transfer orbit to a moon
                                ### Update: orbiting, refbody, body, orbit; 
                                ### recompute position and velocity
                                set orbiting $captureBody
                                $velocity += [$refbody velocity]
                                $position += [$refbody position]
                                set refbody [$orbiting GetBody]
                                $velocity -= [$refbody velocity]
                                $position -= [$refbody velocity]
                                [$object cget -body] SetPosition $position
                                [$object cget -body] SetVelocity $velocity
                                $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                            } else {
                                set captureBody [$system PlantaryCapture $mass \
                                                 [$position + [$refbody position]] \
                                                 [$velocity + [$refbody velocity]]]
                                if {$captureBody ne {}} {
                                    ### object is on a transfer orbit to another planet
                                    ### Update: orbiting, refbody, body, orbit; 
                                    ### recompute position and velocity
                                    set orbiting $captureBody
                                    $velocity += [$refbody velocity]
                                    $position += [$refbody position]
                                    set refbody [$orbiting GetBody]
                                    $velocity -= [$refbody velocity]
                                    $position -= [$refbody velocity]
                                    [$object cget -body] SetPosition $position
                                    [$object cget -body] SetVelocity $velocity
                                    $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                                } else {
                                    ### object is now in a solar orbit
                                    ### Update: orbiting, refbody, body, orbit; 
                                    ### recompute position and velocity
                                    set orbiting [$system GetSun]
                                    $velocity += [$refbody velocity]
                                    $position += [$refbody position]
                                    set refbody [$orbiting GetBody]
                                    $velocity -= [$refbody velocity]
                                    $position -= [$refbody velocity]
                                    [$object cget -body] SetPosition $position
                                    [$object cget -body] SetVelocity $velocity
                                    $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                                }
                            }
                        }
                        set objects($serverid) [clientobjects create %AUTO% \
                                                -serverid $serverid \
                                                -position $position \
                                                -velocity $velocity \
                                                -thustvector $thustvector \
                                                -mass $mass \
                                                -refbody $refbody \
                                                -body $body \
                                                -orbit $orbit \
                                                -orbiting $orbiting \
                                                -clientconnection $self]
                        $self sendResponse 200 $sequence $command \
                              -id $clientid -remoteid $serverid \
                              -epoch [$system getepoch] \
                              -orbiting $orbiting
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
                    SENSOR {
                        ### Sensor logic: visible light, LIDAR, RADAR, etc.
                        ### SENSOR SEQ -type {IFRARED RADIO VISIBLE LIDAR RADAR} -direction DirVect -origin OrgVect -spread angle
                        ### Returns SEQ Sensor data (depends on type)
                        set thetype   [from args -type VISIBLE]
                        set direction [eval [list Vector create %AUTO%] [from args -direction [list 0 0 0]]]
                        set origin    [eval [list Vector create %AUTO%] [from args -origin [list 0 0 0]]]
                        set spread    [from args -spread 0.0]
                        if {$spread <= 0.0 || $spread >= 45.0} {
                            $self sendResponse 420 $sequence $command \
                                  -message [format \
                                            "Spread out of range (> 0.0 and < 45.0): %g" \
                                            $spread]
                            break
                        }
                        switch $thetype {
                            IFRARED {
                                set senseimage [infraredSense $direction \
                                                $origin $spread]
                            }
                            RADIO {
                                set senseimage [radioSense $direction \
                                                $origin $spread]
                            }
                            VISIBLE {
                                set senseimage [visibleSense $direction \
                                                $origin $spread]
                            }
                            LIDAR {
                                set senseimage [lidarSense $direction $origin \
                                                $spread]
                            }
                            RADAR {
                                set senseimage [radarSense $direction $origin \
                                                $spread]
                            }
                            default {
                                $self sendResponse 430 $sequence $command \
                                      -message [format "Unknown Sensor %s" \
                                                $thetype]
                            }
                        }
                        $self sendResponse 200 $sequence $command \
                              -type $thetype \
                              -direction [list [$direction GetX] \
                                          [$direction GetY] \
                                          [$direction GetZ]] \
                              -origin [list [$origin GetX] \
                                       [$origin GetY] \
                                       [$origin GetZ]] \
                              -spread $spread \
                              -data [$senseimage gd_data]
                        rename $senseimage {}
                    }
                    default {
                        $self sendResponse 404 $sequence $command \
                              -message [format "Unknown command %s" \
                                        $command]
                    }
                }
            }
        }
        method sendResponse {args} {
            set binaryData [from args -data {}]
            puts $channel $args
            if {$binaryData ne {}} {
                set b64 [::base64::encode $binaryData]
                puts $channel [format {DataLength: %d} [string length $b64]]
                puts $channel {}
                puts $channel $b64
            } else {
                puts $channel [format {DataLength: %d} 0]
                puts $channel {}
            }
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

