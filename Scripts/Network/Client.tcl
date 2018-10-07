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
#  Last Modified : <181006.1850>
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
package require orsa
package require base64
package require tclgd

namespace eval PlanetarySystemClient {
    snit::type QueueAbleObject {
        option -myunits -readonly yes -default $orsa::units -type orsa::Units
        option -updatecallback -default {}
        option -impactcallback -default {}
        option -damagecallback -default {}
        variable position
        method position {} {
            return $position
        }
        method setposition {newpos} {
            $position set $newpos
        }
        method GetPositionXYZUnits {units} {
            orsa::Units validate $units
            set l_unit [[$self cget -myunits] GetLengthBaseUnit]
            set x [$units FromUnits_length_unit [$position GetX] $l_unit 1]
            set y [$units FromUnits_length_unit [$position GetY] $l_unit 1]
            set z [$units FromUnits_length_unit [$position GetZ] $l_unit 1]
            return [list $x $y $z]
        }
        variable velocity
        method velocity {} {
            return $velocity
        }
        method setvelocity {newvel} {
            $velocity set $newvel
        }
        method GetVelocityXYZUnits {units} {
            orsa::Units validate $units
            set l_unit [[$self cget -myunits] GetLengthBaseUnit]
            set x [$units FromUnits_length_unit [$velocity GetX] $l_unit 1]
            set y [$units FromUnits_length_unit [$velocity GetY] $l_unit 1]
            set z [$units FromUnits_length_unit [$velocity GetZ] $l_unit 1]
            return [list $x $y $z]
        }
        variable thrustvector
        method thrustvector {} {
            return $thrustvector
        }
        method setthrustvector {newthrust} {
            $thrustvector set $newthrust
        }
        method GetThustvectorXYZUnits {units} {
            orsa::Units validate $units
            set l_unit [[$self cget -myunits] GetLengthBaseUnit]
            set x [$units FromUnits_length_unit [$thrustvector GetX] $l_unit 1]
            set y [$units FromUnits_length_unit [$thrustvector GetY] $l_unit 1]
            set z [$units FromUnits_length_unit [$thrustvector GetZ] $l_unit 1]
            return [list $x $y $z]
        }
        variable mass 1
        method mass {} {
            return $mass
        }
        method setmass {newmass} {
            set mass $newmass
        }
        method GetMassUnits {units} {
            orsa::Units validate $units
            set m_unit [[$self cget -myunits] GetMassBaseUnit]
            return [$units FromUnits_mass_unit $mass $m_unit 1]
        }
        variable epoch 0
        method epoch {} {
            return $epoch
        }
        method setepoch {newepoch} {
            set epoch $newepoch
        }
        method updateepoch {epoch units} {
            orsa::Units validate $units
            set t_unit [[$self cget -myunits] GetTimeBaseUnit]
            $self setepoch [[$self cget -myunits] FromUnits_time_unit \
                            $epoch [$units GetTimeBaseUnit] 1]
            set callback [$self cget -updatecallback]
            if {$callback ne {}} {
                uplevel #0 $callback
            }
        }
        method updateposvel {pos vel units} {
            orsa::Units validate $units
            set l_unit [$units GetLengthBaseUnit]
            $position SetX [[$self cget -myunits] FromUnits_length_unit [$pos GetX] $l_unit 1]
            $position SetY [[$self cget -myunits] FromUnits_length_unit [$pos GetY] $l_unit 1]
            $position SetZ [[$self cget -myunits] FromUnits_length_unit [$pos GetZ] $l_unit 1]
            $velocity SetX [[$self cget -myunits] FromUnits_length_unit [$vel GetX] $l_unit 1]
            $velocity SetY [[$self cget -myunits] FromUnits_length_unit [$vel GetY] $l_unit 1]
            $velocity SetZ [[$self cget -myunits] FromUnits_length_unit [$vel GetZ] $l_unit 1]
            set callback [$self cget -updatecallback]
            if {$callback ne {}} {
                uplevel #0 $callback
            }
        }
        variable damage 0
        method impact {} {
            set callback [$self cget -impactcallback]
            if {$callback ne {}} {
                return [uplevel #0 $callback]
            } else {
                set vellen [$velocity Length]
                return [expr {$vellen * $mass}]
            }
        }
        method damage {netimpactenergy} {
            set callback [$self cget -damagecallback]
            set effectivedamagepercent [expr {$mass / double($netimpactenergy)}]
            if {$callback ne {}} {
                set damage [expr {$damage + [uplevel #0 $callback $netimpactenergy]}]
            } else {
                set damage [expr {$damage + $effectivedamagepercent}]
            }
            return [expr {$damage * 100}]
        }
            
                
        constructor {args} {
            $self configurelist $args
            set position [orsa::Vector create %AUTO%]
            set velocity [orsa::Vector create %AUTO%]
            set thrustvector [orsa::Vector create %AUTO%]
        }
    }
    snit::type ObjectQueue {
        option -id -readonly yes
        option -object -readonly yes -default {}
        typevariable pendingobjects [list]
        typevariable _ID 0
        constructor {args} {
            $self configurelist $args
            incr _ID
            set options(-id) $_ID
            lappend pendingobjects $self
        }
        destructor {
            set index [lsearch -exact $pendingobjects $self]
            set pendingobjects [lreplace $pendingobjects $index $index]
        }
        typemethod findbyid {id} {
            foreach o $pendingobjects {
                if {[$o cget -id] == $id} {
                    return $o
                }
            }
            return {}
        }
    }
    snit::type Client {
        variable objects -array {}
        ## Objects in this system we are responsible for.
        variable objids -array {}
        typemethod SequenceNumber {} {
            return [clock milliseconds]
        }
        variable channel
        option -port -readonly yes -default 5050
        option -host -readonly yes -default localhost
        option -sensehandler -readonly yes -default {}
        constructor {args} {
            $self configurelist $args
            set channel [socket $options(-host) $options(-port)]
            puts stderr "*** $type create $self: channel = $channel"
            fconfigure $channel  -buffering line
            puts stderr "*** $type create $self: fconfigure $channel = [fconfigure $channel]"
            fileevent $channel readable [mymethod _listener]
        }
        proc getHeaders {channel} {
            set result [list]
            while {[gets $channel line] > 0} {
                puts stderr "*** getHeaders: line is $line"
                if {[regexp {^([^:]+):[[:space:]]+(.*)$} $line => key value] > 0} {
                    lappend result $key $value
                }
            }
            puts stderr "*** getHeaders: result is $result"
            return $result
        }
        method _listener {} {
            if {[gets $channel line] < 0} {
                $self destroy
            } else {
                puts stderr "*** $self _listener: line = '$line'"
                set response [split $line " "]
                puts stderr "*** $self _listener: response is $response"
                set status [lindex $response 0]
                puts stderr "*** $self _listener: status is $status"
                set sequence [lindex $response 1]
                puts stderr "*** $self _listener: sequence is $sequence"
                set command [lindex $response 2]
                puts stderr "*** $self _listener: command is $command"
                set args [lrange $response 3 end]
                puts stderr "*** $self _listener: args are $args"
                array set headers [getHeaders $channel]
                if {$headers(DataLength) > 0} {
                    set data [::base64::decode [read $channel $headers(DataLength)]]
                    lappend args -data $data
                }
                switch [expr {int($status / 100)}] {
                    2 {
                        $self processOKreponse $status $sequence $command $args
                    }
                    4 -
                    5 {
                        $self processErrorResponse $status $sequence $command $args
                    }
                }
            }
        }
        variable myunits {}
        method processOKreponse {status sequence command arglist} {
            switch [string toupper $command] {
                INIT {
                    set myunits [orsa::Units %AUTO% \
                                 [from arglist -timeunits] \
                                 [from arglist -lengthunits] \
                                 [from arglist -massunits]]
                }
                ADD {
                    set id [from arglist -id]
                    set remoteid [from arglist -remoteid]
                    set epoch [from arglist -epoch]
                    set o [ObjectQueue findbyid $id]
                    set objects($remoteid) [$o cget -object]
                    set objids($object) $remoteid
                    $object updateepoch $epoch $myunits
                }
                UPDATE {
                    set remoteid [from arglist -remoteid]
                    set newpos   [from arglist -position]
                    set newvel   [from arglist -velocity]
                    set epoch [from arglist -epoch]
                    $objects($remoteid) updateposvel $newpos $newvel $myunits
                    $objects($remoteid) updateepoch $epoch
                }
                SENSOR {
                    set thetype   [from arglist -type VISIBLE]
                    set direction [eval [list Vector create %AUTO%] [from arglist -direction [list 0 0 0]]]
                    set origin    [eval [list Vector create %AUTO%] [from arglist -origin [list 0 0 0]]]
                    set spread    [from arglist -spread 0.0]
                    set sensorImage [GD create_from_gd #auto [from arglist -data {}]]
                    set sh [$self cget -sensehandler]
                    if {$sh ne {}} {
                        uplevel #0 $sh $thetype $direction $origin $spread \
                              $sensorImage
                    }
                    rename $sensorImage {}
                }
                IMPACT {
                    set remoteid [from arglist -remoteid]
                    set otherimpact [from arglist -otherimpact]
                    set myimpact [$objects($remoteid) impact]
                    set mydamage [$objects($remoteid) damage \
                                  [expr {$otherimpact - $myimpact}]]
                    if {$mydamage >= 100} {
                        $objects($remoteid) destroy
                        unset objids($objects($remoteid))
                        unset objects($remoteid)
                    }
                }
            }
        }
        method _sendmessage {command args} {
            set seq [SequenceNumber]
            set cmdlist [linsert $args 0 $command $seq]
            puts $channel $cmdlist
        }
            
        destructor {
            catch {close $channel}
        }
        method add {object} {
            set o [$ObjectQueue create %AUTO% -object $object]
            $self _sendmessage ADD -id [$o cget -id] \
                  -position [$object GetPositionXYZUnits $myunits] \
                  -velocity [$object GetVelocityXYZUnits $myunits] \
                  -thustvector [$object GetThustvectorXYZUnits $myunits] \
                  -mass [$object GetMassUnits $myunits]
        }
        method updatethrustvector {object} {
            if {[catch {set objids($object)} remoteid]} {
                error [format "Object not registered: %s" $object]
            } else {
                $self _sendmessage UPDATE_THRUST -remoteid $remoteid \
                      -thustvector [$object GetThustvectorXYZUnits $myunits]
            }
        }
        method updatemass {object} {
            if {[catch {set objids($object)} remoteid]} {
                error [format "Object not registered: %s" $object]
            } else {
                $self _sendmessage UPDATE_MASS -remoteid $remoteid \
                      -mass [$object GetMassUnits $myunits]
            }
        }
    }
    namespace export Client
}

        

package provide PlanetarySystemClient 0.1

