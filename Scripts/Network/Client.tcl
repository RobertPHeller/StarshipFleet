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
#  Last Modified : <160506.1326>
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
    snit::type ObjectQueue {
        option -id -readonly yes
        option -object -readonly -default {}
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
            return [clock clicks]
        }
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
                set response [split $line " "]
                set status [lindex $response 0]
                set sequence [lindex $response 1]
                set command [lindex $response 2]
                set args [lrange $response 3 end]
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
        method processOKreponse {status sequence command arglist} {
            switch [string toupper $command] {
                ADD {
                    set id [from arglist -id]
                    set remoteid [from arglist -remoteid]
                    set epoch [from arglist -epoch]
                    set o [ObjectQueue findbyid $id]
                    set objects($remoteid) [$o cget -object]
                    set objids($object) $remoteid
                    $object configure -epoch $epoch
                }
                UPDATE {
                    set remoteid [from arglist -remoteid]
                    set newpos   [from arglist -position]
                    set newvel   [from arglist -velocity]
                    set epoch [from arglist -epoch]
                    $objects($remoteid) updateposvel $newpos $newvel
                    $objects($remoteid) configure -epoch $epoch
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
                  -position [$object cget -positionXYZ] \
                  -velocity [$object cget -velocityXYZ] \
                  -thustvector [$object cget -thustvectorXYZ]
        }
        method updatethrustvector {object} {
            set remoteid $objids($object)
            $self _sendmessage UPDATE_THRUST -remoteid $remoteid \
                  -thustvector [$object cget -thustvectorXYZ]
        }
    }
    namespace export Client
}

        

package provide PlanetarySystemClient 0.1

