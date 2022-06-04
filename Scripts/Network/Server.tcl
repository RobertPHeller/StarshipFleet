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
#  Last Modified : <220604.1525>
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
package require orsa

namespace eval PlanetarySystemServer {
    snit::type clientobjects {
        option -serverid -readonly yes -default 0
        option -position -configuremethod _configureVector
        option -velocity  -configuremethod _configureVector
        option -thustvector  -configuremethod _configureVector
        method _configureVector {option value} {
            if {$options($option) eq {}} {
                set options($option) $value
            } else {
                $options($option) = $value
            }
        }
        option -clientconnection -readonly yes -default {}
        option -mass -default 0
        option -orbiting -default {}
        option -body -default {} -readonly yes
        option -orbit -default {} -readonly yes
        option -refbody -default {}
        constructor {args} {
            #puts stderr "*** $type create $self $args"
            $self configurelist $args
            #puts "*** $type create $self: after configurelist"
            #puts "*** $type create $self: opts: [array names options]"
            #foreach o [array names options] {
            #    puts "*** $type create $self: options($o) is $options($o)"
            #}
            foreach option {-position -velocity -thustvector} {
                #puts "*** $type create $self: options($option) is $options($option)"
                if {$options($option) eq {}} {
                    set options($option) [::orsa::Vector create %AUTO% 0 0 0]
                }
            }
            
        }
        destructor {
            foreach option {-position -velocity -thustvector} {
                if {![catch {$options($option) info type} thetype]} {
                    catch {$options($option) destroy}
                }
            }
        }
    }
    snit::enum OrbitType -values {SYNCRONIOUS LOW MEDIUM HIGH POLAR}
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
            ::log::log debug "*** $type update (before loop): Vector Count is [::orsa::Vector VectorCount]"
            #::log::log debug "*** $type update (before loop): Body Count is [::orsa::Body BodyCount]"
            #::log::log debug "*** $type update (before loop): Orbit Count is [::orsa::Orbit OrbitCount]"
            foreach serverid [array names objects] {
                ::log::log debug "*** $type update (compute new pos and vel) Vector Count is [::orsa::Vector VectorCount]"
                #::log::log debug "*** $type update: serverid is $serverid"
                set object $objects($serverid)
                #::log::log debug "*** $type update: object is $object"
                set orbit [$object cget -orbit]
                $orbit RelativePosVelAtTime pos vel $epoch;             #+2
                ::log::log debug "*** $type update (orbit at time) Vector Count is [::orsa::Vector VectorCount]"
                set tv [$object cget -thustvector]
                set tvel [Vector copy %AUTO% [$object cget -velocity]]; #+1
                $tvel += $tv
                $tvel configure -par 1
                $vel configure -par 0
                Vector Interpolate [list $tvel $vel] 1.0 velocity verr; #+2
                $verr destroy;                                          #-1
                unset verr
                $pos configure -par 0
                set tpos [Vector copy %AUTO% [$object cget -position]]; #+1
                $tpos += $tvel
                $tvel destroy;                                          #-1
                unset tvel
                ::log::log debug "*** $type update (Interpolatate vel) Vector Count is [::orsa::Vector VectorCount]"
                Vector Interpolate [list $tpos $vel] 1.0 position perr; #+2
                $tpos destroy;                                          #-1
                unset tpos
                $vel destroy;                                           #-1
                unset vel
                $pos destroy;                                           #-1
                unset pos
                $perr destroy;                                          #-1
                unset perr
                ::log::log debug "*** $type update (Interpolatate pos) Vector Count is [::orsa::Vector VectorCount]"
                set orbiting [$object cget -orbiting]
                set refbody [$object cget -refbody]
                set oldpos [::orsa::Vector copy %AUTO% [[$object cget -body] position]]
                [$object cget -body] SetPosition $position
                [$object cget -body] SetVelocity $velocity
                set mass [$object cget -mass]
                # Impact check line endpoints:
                set oldabspos [$oldpos + [$refbody position]]
                $oldpos destroy
                set newabspos [$position + [$refbody position]]
                #*********************************************************
                # Check for impact here!                                 *
                # Other objects, then planetary bodies, etc.             *
                # Check along the 3D line from $oldabspos to $newabspos  *
                # Handle missle war heads, etc.                          *
                #*********************************************************
                $oldabspos destroy
                $newabspos destroy
                ::log::log debug "*** $type update (after compute new pos and vel) Vector Count is [::orsa::Vector VectorCount]"
                $orbit Compute Body [$object cget -body]  [$object cget -refbody] [$system getepoch]
                if {$orbiting eq [$system GetSun]} {
                    set tempposition [$position + [$refbody position]]
                    set tempvelocity [$velocity + [$refbody velocity]]
                    set captureBody [$system PlantaryCapture $mass \
                                     $tempposition \
                                     $tempvelocity]
                    $tempposition destroy;unset tempposition
                    $tempvelocity destroy;unset tempvelocity
                    ::log::log debug "*** $type update (after PlantaryCapture)  Vector Count is [::orsa::Vector VectorCount]"
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
                    set pposition [Vector copy %AUTO% $position]
                    set pvelocity [Vector copy %AUTO% $velocity]
                    set prefbody $refbody
                    if {[$planet parent] ne {}} {
                        $pposition += [$prefbody position]
                        $pvelocity += [$prefbody velocity]
                        set planet [$planet parent]
                        set prefbody [$planet cget -refbody]
                    }
                    set temppposition [$pposition + [$prefbody position]]
                    set temppvelocity [$pvelocity + [$prefbody velocity]]
                    set captureBody [$planet SateliteCapture $mass \
                                     $temppposition \
                                     $temppvelocity]
                    $temppposition destroy;unset temppposition
                    $temppvelocity destroy;unset temppvelocity
                    $pposition destroy;unset pposition
                    $pvelocity destroy;unset pvelocity
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
                        set tempposition [$position + [$refbody position]]
                        set tempvelocity [$velocity + [$refbody velocity]]
                        set captureBody [$system PlantaryCapture $mass \
                                         $tempposition \
                                         $tempvelocity]
                        $tempposition destroy;unset tempposition
                        $tempvelocity destroy;unset tempvelocity
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
                ::log::log debug "*** $type update (after capture check) Vector Count is [::orsa::Vector VectorCount]"
                set absvel [Vector copy %AUTO% $velocity]
                $absvel += [$refbody velocity]
                $object configure -velocity $velocity
                $velocity destroy;unset velocity
                set abspos [Vector copy %AUTO% $position]
                $abspos += [$refbody position]
                $object configure -position $position
                $position destroy;unset position
                # update pos: object
                [$object cget -clientconnection] sendResponse 200 \
                      [$type SequenceNumber] UPDATE \
                      -remoteid $serverid \
                      -position [list [$abspos GetX] [$abspos GetY] [$abspos GetZ]] \
                      -velocity [list [$absvel GetX] [$absvel GetY] [$absvel GetZ]] \
                      -epoch $epoch \
                      -orbiting $orbiting
                $abspos destroy;unset abspos
                $absvel destroy;unset absvel
                ::log::log debug "*** $type update (after update) Vector Count is [::orsa::Vector VectorCount]"
            }
            ::log::log debug "*** $type update (after loop): Vector Count is [::orsa::Vector VectorCount]"
            #::log::log debug "*** $type update (after loop): Body Count is [::orsa::Body BodyCount]"
            #::log::log debug "*** $type update (after loop): Orbit Count is [::orsa::Orbit OrbitCount]"
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
                set message $line
                set command [lindex $message 0]
                set sequence [lindex $message 1]
                set args [lrange $message 2 end]
                switch [string toupper $command] {
                    ADD {
                        incr _ID
                        set serverid $_ID
                        set clientid [from args -id 0]
                        set position [Vector create %AUTO% {*}[from args -position [list 0 0 0]]]
                        set velocity [Vector create %AUTO% {*}[from args -velocity [list 0 0 0]]]
                        set mass     [from args -mass 0]
                        set thustvector [Vector create %AUTO% {*}[from args -thustvector [list 0 0 0]]]
                        set orbiting [from args -orbiting [$system GetSun]]
                        set refbody [$orbiting GetBody]
                        $position -= [$refbody position]
                        $velocity -= [$refbody velocity]
                        set body [Body create %AUTO% "" $mass $position $velocity]
                        set orbit [OrbitWithEpoch create %AUTO%]
                        $orbit Compute Body $body $refbody [$system getepoch]
                        if {$orbiting eq [$system GetSun]} {
                            set tempposition [$position + [$refbody position]]
                            set tempvelocity [$velocity + [$refbody velocity]]
                            set captureBody [$system PlantaryCapture $mass \
                                             $tempposition \
                                             $tempvelocity]
                            $tempposition destroy;unset tempposition
                            $tempvelocity destroy;unset tempvelocity
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
                                $body SetPosition $position
                                $body SetVelocity $velocity
                                $orbit Compute Body $body  $refbody [$system getepoch]
                            }
                        } elseif {[$orbit OrbitalType] eq "escape"} {
                            set planet $orbiting
                            set pposition [Vector copy %AUTO% $position]
                            set pvelocity [Vector copy %AUTO% $velocity]
                            set prefbody $refbody
                            if {[$planet parent] ne {}} {
                                $pposition += [$prefbody position]
                                $pvelocity += [$prefbody velocity]
                                set planet [$planet parent]
                                set prefbody [$planet GetBody]
                            }
                            set tempposition [$pposition + [$prefbody position]]
                            set tempvelocity [$pvelocity + [$prefbody velocity]]
                            set captureBody [$planet SateliteCapture $mass \
                                             $tempposition \
                                             $tempvelocity]
                            $tempposition destroy;unset tempposition
                            $tempvelocity destroy;unset tempvelocity
                            $pposition destroy;unset pposition
                            $pvelocity destroy;unset pvelocity
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
                                $body SetPosition $position
                                $body SetVelocity $velocity
                                $orbit Compute Body $body  $refbody [$system getepoch]
                            } else {
                                set tempposition [$position + [$refbody position]]
                                set tempvelocity [$velocity + [$refbody velocity]]
                                set captureBody [$system PlantaryCapture $mass \
                                                 $tempposition \
                                                 $tempvelocity]
                                $tempposition destroy;unset tempposition
                                $tempvelocity destroy;unset tempvelocity
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
                                    $body SetPosition $position
                                    $body SetVelocity $velocity
                                    $orbit Compute Body $body  $refbody [$system getepoch]
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
                                    $body SetPosition $position
                                    $body SetVelocity $velocity
                                    $orbit Compute Body $body  $refbody [$system getepoch]
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
                        set direction [Vector create %AUTO% {*}[from args -direction [list 0 0 0]]]
                        set origin    [Vector create %AUTO% {*}[from args -origin [list 0 0 0]]]
                        set spread    [from args -spread 0.0]
                        if {$spread <= 0.0 || $spread >= [expr {$::orsa::pi / 4.0}]} {
                            $self sendResponse 420 $sequence $command \
                                  -message [format \
                                            "Spread out of range (> 0.0 and < PI/4): %g" \
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
                              -epoch [$system getepoch] \
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
                        $direction destroy
                        $origin destroy
                    }
                    SUN {
                        $self sendResponse 200 $sequence $command \
                              -sun [namespace tail [$system GetSun]]
                    }
                    GOLDILOCKS {
                        set p [$system GoldilocksPlanet]
                        if {$p eq {}} {
                            $self sendResponse 204 $sequence $command
                        } else {
                            $self sendResponse 200 $sequence $command \
                                  -planetname [namespace tail $p]
                        }
                    }
                    PLANET_INFO {
                        set pname [from args -name]
                        set p [$system PlanetByName $pname]
                        if {$p eq {}} {
                            $self sendResponse 204 $sequence $command
                        } else {
                            $self sendResponse 200 $sequence $command \
                                  -name [namespace tail $p] \
                                  -mass [$p cget -mass] \
                                  -distance [$p cget -distance] \
                                  -radius [$p cget -radius] \
                                  -eccentricity [$p cget -eccentricity] \
                                  -period [$p cget -period] \
                                  -ptype [$p cget -ptype] \
                                  -gasgiant [$p cget -gasgiant] \
                                  -gravity [$p cget -gravity] \
                                  -pressure [$p cget -pressure] \
                                  -greenhouse [$p cget -greenhouse] \
                                  -temperature [$p cget -temperature] \
                                  -density [$p cget -density] \
                                  -escapevelocity [$p cget -escapevelocity] \
                                  -molweightretained [$p cget -molweightretained] \
                                  -acceleration [$p cget -acceleration] \
                                  -tilt [$p cget -tilt] \
                                  -albedo [$p cget -albedo] \
                                  -day [$p cget -day] \
                                  -waterboils [$p cget -waterboils] \
                                  -hydrosphere [$p cget -hydrosphere] \
                                  -cloudcover [$p cget -cloudcover] \
                                  -icecover [$p cget -icecover] \
                                  -creationepoch [$p cget -creationepoch]
                        }
                    }
                    PLANETARY_ORBIT {
                        set pname [from args -name]
                        set mass  [from args -mass]
                        set orbittype [from args -type SYNCRONIOUS]
                        if {[catch {OrbitType validate $orbittype} error]} {
                            $self sendResponse 408 $sequence $command \
                                  -message $error
                            return
                        }
                        set p [$system PlanetByName $pname]
                        if {$p eq {}} {
                            $self sendResponse 204 $sequence $command
                        } else {
                            set planetBody [$p GetBody]
                            set newbody    [::orsa::Body %AUTO% {} $mass]
                            ComputeOrbit $orbittype $planetBody $newbody \
                                  [$p cget -day] [$system getepoch] position \
                                  velocity
                            $newbody destroy
                            $self sendResponse 200 $sequence $command \
                                  -position [list [$position GetX] \
                                             [$position GetY] \
                                             [$position GetZ]] \
                                  -velocity [list [$velocity GetX] \
                                             [$velocity GetY] \
                                             [$velocity GetZ]]
                        }
                    }
                    default {
                        $self sendResponse 404 $sequence $command \
                              -message [format "Unknown command %s" \
                                        $command]
                    }
                }
            }
        }
        proc cuberoot {a} {
            set x 1
            while {true} {
                set x1 [expr {(($a / ($x*$x))+(2*$x)) / 3.0}]
                if {abs($x-$x1) < .000001} {
                    return $x1
                } else {
                    set x $x1
                }
            }
        }
        proc ComputeOrbit {orbittype refbody body day epoch posvarname \
                  velvarname} {
            upvar $posvarname position
            upvar $velvarname velocity
            set day [$orsa::units FromUnits_time_unit $day HOUR 1]
            set orbit [orsa::OrbitWithEpoch create %AUTO%]
            $orbit configure -mu [expr {[orsa::GetG] * ([$body mass] + [$refbody mass])}]
            
            if {$orbittype eq "SYNCRONIOUS"} {
                $orbit configure -i 0 -e 0.0
                set p $day
            } elseif {$orbittype eq "POLAR"} {
                $orbit configure -i [expr {asin(1.0)}] -e [expr {rand()*.0625}]
                set p [expr {$day * (rand()*.0312500000)+.06250}]
            } else {
                $orbit configure -i [expr {asin(rand()*.5-.25)}]
                if {$orbittype eq "LOW"} {
                    set p [expr {$day * ((rand()*.0446428571)+.0892857142)}]
                    $orbit configure -e [expr {rand()*.25}]
                } elseif {$orbittype eq "MEDIUM"} {
                    set p [expr {$day * ((rand()*.25)+.5)}]
                    $orbit configure -e [expr {rand()*.0625}]
                } else {
                    set p [expr {$day * ((rand()*4)+4)}]
                    $orbit configure -e [expr {rand()*.5}]
                }
            }
            $orbit configure -a \
                  [cuberoot [expr {($p*$p)*([$orbit cget -mu]/(4*$orsa::pisq))}]]
            $orbit configure \
                  -omega_pericenter [expr {asin(rand()*.25-0.125)}] \
                  -omega_node [expr {asin(rand()*.125-0.0625)}] \
                  -m_ [expr {acos(rand()*2.0-1.0)*2.0}] \
                  -epoch $epoch
            $orbit RelativePosVelAtTime position velocity $epoch
            $position += [$refbody position]
            $velocity += [$refbody velocity]
            $orbit destroy
        }
        method sendResponse {args} {
            if {$channel eq {}} {return}
            set binaryData [from args -data {}]
            catch {
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
        }
        destructor {
            #puts stderr "*** $self destroy"
            catch {close $channel}
            set channel {}
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

