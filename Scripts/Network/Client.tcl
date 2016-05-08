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
#  Last Modified : <160508.1509>
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

namespace eval PlanetarySystemClient {
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
        constructor {args} {
            $self configurelist $args
            set channel [socket $options(-host) $options(-port)]
            puts stderr "*** $type create $self: channel = $channel"
            fconfigure $channel  -buffering line
            puts stderr "*** $type create $self: fconfigure $channel = [fconfigure $channel]"
            fileevent $channel readable [mymethod _listener]
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

