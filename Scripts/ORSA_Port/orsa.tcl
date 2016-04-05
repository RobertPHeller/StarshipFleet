#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sat Apr 2 06:49:13 2016
#  Last Modified : <160403.2214>
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


namespace eval orsa {
    variable ORSA_DIR [file dirname [info script]]
}

source [file join $orsa::ORSA_DIR orsa_common.tcl]
source [file join $orsa::ORSA_DIR orsa_coord.tcl]
source [file join $orsa::ORSA_DIR orsa_body.tcl]
source [file join $orsa::ORSA_DIR orsa_units.tcl]
source [file join $orsa::ORSA_DIR orsa_orbit.tcl]


namespace eval ::tcl::mathfunc {
    ## From orsa_secure_math.{h,cc}
    
    # avoids domain errors when x<0 and non-integer y
    proc secure_pow {x  y} {
    
        if {$x<0.0} {
            if {int($y)!=$y} {
                #ORSA_DOMAIN_ERROR("secure_pow(%g,%g) is undefined!",x,y);
                return 1.0;# better value?
            } else {
                return [pow $x $y]
            }
        } else {
            return [pow $x $y]
        }
    }
  
    # avoids domain errors when x<=0
    proc secure_log {x} {
        if {$x>0} {
            return [log $x]
        } else {
            #ORSA_DOMAIN_ERROR("secure_log(%g) is undefined!",x);
            return 1.0;#/ better value?
        }
    }
  
    # avoids domain errors when x<=0
    proc secure_log10 {x} {
        if {$x>0} {
            return [log10 $x]
        } else {
            #ORSA_DOMAIN_ERROR("secure_log10(%g) is undefined!",x);
            return 1.0;# better value?
        }
    }
  
    # avoids domain errors when x=y=0
    proc secure_atan2 {x y} {
        if {$x==0.0} {
            if {$y==0.0} {
                # domain error
                # ORSA_DOMAIN_ERROR("secure_atan2(%g,%g) is undefined!",x,y);
                return 1.0;# better value?
            } else {
                return [atan2 $x $y]
            }
        } else {
            return [atan2 $x $y]
        }
    }
  
    # avoids domain errors when x is not in [-1,1]
    proc secure_asin {x} {
        if {($x>1.0) || ($x<-1.0)} {
            # domain error
            #ORSA_DOMAIN_ERROR("secure_asin(%g) is undefined!",x);
            return 1.0;# better value?
        } else {
            return [asin $x]
        }
    }
  
    # avoids domain errors when x is not in [-1,1]
    proc secure_acos {x} {
        if {($x>1.0) || ($x<-1.0)} {
            # domain error
            # ORSA_DOMAIN_ERROR("secure_acos(%g) is undefined!",x);
            return 1.0;# better value?
        } else {
            return [acos $x]
        }
    }
    
    # avoids domain errors when x<0
    proc secure_sqrt {x} {
        if {$x<0} {
            #domain error
            #ORSA_DOMAIN_ERROR("secure_sqrt(%g) is undefined!",x);
            return [sqrt [abs $x]];# better value?
        } else {
            return [sqrt $x];
        }
    }
    
    # missing cbrt function.  Fake it with pow
    proc cbrt {x} {
        return [expr {secure_pow($x,1.0/3.0)}]
    }
    
}

namespace import orsa::*

package provide orsa 0.7

