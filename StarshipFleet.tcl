#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Thu Mar 24 12:57:13 2016
#  Last Modified : <220601.2142>
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

## @mainpage Starship objects.
#
# 
# @author Robert Heller \<heller\@deepsoft.com\>


package require snit
package require orsa
package require PlanetarySystemClient
package require PlanetarySystem
package require BridgeConsoles
package require ShipyardCommand
package require tclgd

namespace eval starships {
    ##
    # @brief Starship code, Version 0
    #
    # This is an idea that came to me in a dream.  Don't know where it will
    # lead.
    #
    # @author Robert Heller \<heller\@deepsoft.com\>
    #
    
    namespace import ::orsa::*
    namespace import ::planetarysystem::*
    namespace import ::PlanetarySystemClient::*
    
    snit::double radians -max [expr {acos(-1)}] -min [expr {-acos(-1)}]
    ## @typedef double radians
    # A double between \f$-\pi\f$ and \f$\pi\f$.
    
    snit::double rhotype -min 0.0
    ## @typedef double rhotype
    # A positive double.
    
    snit::integer masstype -min 1
    ## @typedef integer masstype
    # A positive non-zero integer.
    
    snit::listtype cartesiancoordtype -minlen 3 -maxlen 3 -type snit::double
    ## @typedef listtype cartesiancoordtype
    # A list of three doubles representing a cartesian coordinate.
    # The three doubles are the \$x\f$, \f$y\f$, and \f$z\f$ values of the 
    # coordinate.
    
    snit::type sphericalcoordtype {
        ## @typedef listtype sphericalcoordtype
        # A list of three doubles representing a spherical coordinate.
        # The three doubles are the \$\rho\f$, \$\theta\f$, and \$\phi\f$
        # values of the coordinate.
        
        pragma -hastypeinfo no -hastypedestroy no -hasinstances no
        typemethod validate {object} {
            ## @brief Validate the object as a sphericalcoordtype.
            #
            # A sphericalcoordtype is a list of three doubles representing a 
            # spherical coordinate. \$\rho\f$, \$\theta\f$, and \$\phi\f$. 
            # \$\rho\f$ is a positive double, \$\theta\f$ and \$\phi\f$ are 
            # doubles between \$-\pi\f$ and \f$\pi\f$.
            #
            # @param object A possible sphericalcoordtype.
            
            if {[llength $object] != 3} {
                error [_ "%s is not a %s!" $object $type]
            } else {
                if {[catch {starships::rhotype validate [lindex $object 0]}]} {
                    error [_ "%s is not a %s (bad rho value: %s)!" $object \
                           $type [lindex $object 0]]
                }
                if {[catch {starships::radians validate [lindex $object 1]}]} {
                    error [_ "%s is not a %s (bad theta value: %s)!" $object \
                           $type [lindex $object 1]]
                }
                if {[catch {starships::radians validate [lindex $object 2]}]} {
                    error [_ "%s is not a %s (bad phi value: %s)!" $object \
                           $type [lindex $object 2]]
                }
                return $object
            }
        }
    }
    
    snit::type Coordinates {
        ## @brief A set of 3D Coordinates.
        #
        # A representation of point in 3D space.  The coordinates are available
        # as either cartesian or spherical (polar) coordinates, depending on
        # what is needed.
        #
        # Options:
        # @arg -cartesian A list of three floating point values 
        #                 (\f$[x \quad y \quad z]\f$) representing The
        #                 point in 3D space using cartesian coordinates.  The
        #                 default is {0.0 0.0 0.0}.
        # @arg -spherical A list of three floating point values 
        #                 (\f$[\rho \quad \theta \quad \phi]\f$) representing the
        #                 point in 3D space using spherical (polar) 
        #                 coordinates. The default is {0.0 0.0 0.0}.
        # @par
        
        variable cartesian yes
        ## @privatesection A flag indicating that the internal representation
        # is in cartesian coordinates.
        variable x 0.0
        ## The X cartesian coordinate.
        variable y 0.0
        ## The Y cartesian coordinate.
        variable z 0.0
        ## The Z cartesian coordinate.
        variable rho 0.0
        ## The \f$\rho\f$ spherical (polar) coordinate.
        variable theta 0.0
        ## The \f$\theta\f$ spherical (polar) coordinate.
        variable phi 0.0
        ## The \f$\phi\f$ spherical (polar) coordinate.
        option -cartesian -type starships::cartesiancoordtype \
              -default {0.0 0.0 0.0} -configuremethod _configurecart \
              -cgetmethod _cgetcart
        option -spherical -type starships::sphericalcoordtype \
              -default {0.0 0.0 0.0} -configuremethod _configuresphere \
              -cgetmethod _cgetsphere
        method _configurecart {option value} {
            ## @brief Configure the cartesian coordinates.
            # Configure the cartesian coordinates, setting the cartesian flag 
            # to yes, which invalidates the spherical (polar) coordinates.
            #
            # @param option Always  -cartesian.
            # @param value The cartesian coordinates.
            
            foreach {x y z} $value {break}
            set cartesian yes
        }
        method _cgetcart {option} {
            ## @brief CGet the cartesian coordinates.
            #
            # @param option Always  -cartesian.
            # @return A list of three doubles, containing the cartesian 
            # coordinates.
            
            if {$cartesian} {
                # We have the cartesian coordinates -- just return them.
                return [list $x $y $z]
            } else {
                set x [expr {$rho * cos($theta) * sin($phi)}]
                set y [expr {$rho * sin($theta) * sin($phi)}]
                set z [expr {$rho * cos($phi)}]
                return [list $x $y $z]
            }
        }
        method _configuresphere {option value} {
            ## @brief Configure the spherical coordinates.
            # Configure the spherical coordinates, setting the cartesian flag 
            # to no, which invalidates the cartesian coordinates.
            #
            # @param option Always  -spherical.
            # @param value The spherical coordinates.
            
            foreach {rho theta phi} $value {break}
            set cartesian no
        }
        method _cgetsphere {option} {
            ## @brief CGet the spherical coordinates.
            #
            # @param option Always  -spherical.
            # @return A list of three doubles, containing the spherical
            # coordinates.
            
            if {!$cartesian} {
                # We have the spherical coordinates -- just return them.
                return [list $rho $theta $phi]
            } else {
                set rho [expr {sqrt(($x*$x) + ($y*$y) + ($z*$z))}]
                set theta  [expr {atan2($y,$x)}]
                if {abs($z) < .00001 && abs($rho) > .00001} {
                    set phi [expr {acos($z/$rho)}]
                } else {
                    set phi [expr {atan2(sqrt(($x*$x) + ($y*$y)),$z)}]
                }
                return [list $rho $theta $phi]
            }
        }
        constructor {args} {
            ## @publicsection Construct a set of coordinates.
            #
            # @param name The name of the coordinate set.
            # @param ... Options:
            # @arg -cartesian A list of three floating point values 
            #                 (\f$[x \quad y \quad z]\f$) representing The
            #                 point in 3D space using cartesian coordinates.
            #                 The default is {0.0 0.0 0.0}.
            # @arg -spherical A list of three floating point values 
            #                 (\f$[\rho \quad \theta \quad \phi]\f$) 
            #                 representing the point in 3D space using 
            #                 spherical (polar) coordinates. The default is 
            #                 {0.0 0.0 0.0}.
            # @par
            
            $self configurelist $args
        }
        typemethod copy {name othercoords} {
            ## Copy constructor, make a copy of the passed Coordinates object.
            #
            # @param name The name of the new Coordinates object.
            # @param othercoords A Coordinates object to copy.
            # @return A freshly copied Coordinates object.
            
            $type valivate $othercoords
            return [$type $name -cartesian [$othercoords cget -cartesian]]
        }
        
        typemethod validate {object} {
            ## Validate object as a Coordinates object.
            #
            # @param object The object to validate.
            #
            
            if {[catch {$object info type} otype]} {
                error [_ "%s is not a %s!" $object $type]
            } elseif {$otype ne $type} {
                error [_ "%s is not a %s!" $object $type]
            } else {
                return $object
            }
        }
    }

    snit::enum StarshipClasses -values {
        ## @enum StarshipClasses
        # Starship classes
        #
        destroyer
        ## @brief Destroyer
        lightcrusier
        ## @brief Light Crusier
        heavycrusier
        ## @brief Heavy Crusier
        battlecrusier
        ## @brief Battle Crusier
        dreadnought
        ## @brief Dreadnought
        superdreadnought
        ## @brief Super Dreadnought
        ammunition
        ## @brief Ammunition Ship
        troopcarrier
        ## @brief Troop Carrier
        other
        ## @brief All Others
    }
    
    snit::double StarshipAcceleration  -min 0.0 -max 1000
    ## @typedef double StarshipAcceleration
    # Starship acceleration type:  A double between 0.0 and 1000.
    
    snit::type StarshipEngine {
        ## @brief Starship Engine type.
        #
        # Defines a Starship Engine object.  A Starship Engine provides thrust
        # (acceleration) in the direction of travel.
        #
        # Options:
        # 
        # @arg -maxdesignaccel This is a floating point number from 0.0 to 
        #                      1000 and is the number of times the Earth normal
        #                      gravitational constant (\f$9.80665m/s^2\f$). 
        #                      This is a readonly option with a default of 500.
        # @arg -maxaccel       This is a floating point number from 0.0 to
        #                      1000 and is the number of times the Earth 
        #                      normal gravitational constant 
        #                      (\f$9.80665m/s^2\f$) of acceleration the engine 
        #                      can develop at its current performance level. 
        #                      The default is the @c -maxdesignaccel setting.
        # @arg -acceleration   This is a floating point number from 0.0 to
        #                      1000 and is the number of times the Earth normal
        #                      gravitational constant (\f$9.80665m/s^2\f$) 
        #                      of acceleration the engine is currently 
        #                      developing.  The default is 0.0 (at rest or 
        #                      drifting).
        # @par
        
        typemethod validate {o} {
            puts stderr "*** $type validate $o"
            if {[catch {$o info type} thetype]} {
                error "Not a $type: $o"
            } elseif {$thetype ne $type} {
                puts stderr "*** $type validate: thetype is $thetype"
                error "Not a $type: $o"
            } else {
                return $o
            }
        }
        option -maxdesignaccel -readonly yes -default 500 \
              -type starships::StarshipAcceleration
        option -maxaccel -type starships::StarshipAcceleration \
              -configuremethod _checkaccel
        option -acceleration -type starships::StarshipAcceleration \
              -configuremethod _checkaccel -default 0.0
        method _checkaccel {option value} {
            ## @privatesection Limit acceleration settings to maximum values,
            # design or current: The @c -maxaccel value must be less than or
            # equal to the @c -maxdesignaccel value, and the @c -acceleration 
            # must be less than or equal to the @c -maxaccel value.
            set accellimit 1000
            switch -- $option {
                -maxaccel {
                    catch {set options(-maxdesignaccel)} accellimit
                }
                -acceleration {
                    if {[catch {set options(-maxaccel)} accellimit]} {
                        catch {set options(-maxdesignaccel)} accellimit
                    }
                }
            }
            if {$value > $accellimit} {
                set value $accellimit
            }
            set options($option) $value
            if {$option eq {-maxaccel} && $options(-acceleration) > $value} {
                set options(-acceleration) $value
            }
        }
        constructor {args} {
            ## @publicsection Construct a Starship engine, which can provide
            # thrust along the direction of travel.  
            #
            # @param name The name of the engine.
            # @param ... Options:
            # @arg -maxdesignaccel This is a floating point number from 0.0 to 
            #                      1000 and is the number of times the Earth 
            #                      normal gravitational constant 
            #                      (\f$9.80665m/s^2\f$). This is a readonly 
            #                      option with a default of 500.
            # @arg -maxaccel       This is a floating point number from 0.0 to
            #                      1000 and is the number of times the Earth 
            #                      normal gravitational constant 
            #                      (\f$9.80665m/s^2\f$) of acceleration the 
            #                      engine can develop at its current 
            #                      performance level. The default is the 
            #                      @c -maxdesignaccel setting.
            # @arg -acceleration   This is a floating point number from 0.0 to
            #                      1000 and is the number of times the Earth 
            #                      normal gravitational constant 
            #                      (\f$9.80665m/s^2\f$) of acceleration the 
            #                      engine is currently developing.  The 
            #                      default is 0.0 (at rest or drifting).
            # @par
            
            $self configurelist $args
            if {[lsearch -exact $args -maxaccel] < 0} {
                $self configure -maxaccel [$self cget -maxdesignaccel]
            }
        }
    }
    
    snit::double ShieldStrength -min 0.0 -max 1.0
    ## @typedef double ShieldStrength
    # The current strength of the shields, as a floating point number from 0.0
    # to 1.0. A value of 0.0 means the shields are completely down and a value
    # of 1.0 means the shields are at maximum strength.
    
    snit::type StarshipShields {
        ## @brief Starship shield type.
        # The starship shields, which protects the starship both from small 
        # objects in space (rocks, meteorites, etc.) and from enemy weapon 
        # fire (lasers, missiles, etc.).
        #
        # Options:
        # @arg -shieldstrength The current strength of the shields as a 
        #                      floating point number from 0.0 to 1.0. A value 
        #                      of 0.0 means the shields are completely down 
        #                      and a value of 1.0 means the shields are at 
        #                      maximum strength. The default is 1.0.
        # @par
        
        typemethod validate {o} {
            puts stderr "*** $type validate $o"
            if {[catch {$o info type} thetype]} {
                error "Not a $type: $o"
            } elseif {$thetype ne $type} {
                puts stderr "*** $type validate: thetype is $thetype"
                error "Not a $type: $o"
            } else {
                return $o
            }
        }
        option -shieldstrength -type starships::ShieldStrength -default 1.0
        constructor {args} {
            ## The constructor constructs a shield array.
            #
            # @param name The name of the shield object.
            # @param ... Options:
            # @arg -shieldstrength The current strength of the shields as a 
            #                      floating point number from 0.0 to 1.0. A 
            #                      value of 0.0 means the shields are 
            #                      completely down and a value of 1.0 means 
            #                      the shields are at maximum strength. The 
            #                      default is 1.0.
            # @par
            
            $self configurelist $args
        }
    }
    
    snit::integer LauncherCount -min 0 -max 25
    ## @typedef integer LauncherCount
    # The number of missle launchers, and integer from 0 (a non-missle firing 
    # ship, such as a troop carrier) to 25 (super dreadnought).
    snit::enum MissleType -values {
        ## @enum MissleType
        # Missle size classes.
        #
        mark1
        ## @brief Small destroyer missle.
        mark2
        ## @brief Basic cruiser missle.
        mark4
        ## @brief Shipkiller missle.
        mark10
        ## @brief Planet buster missle.
    }
    
    
    snit::type ThrustVector {
        ## @brief ThrustVector object, representing a 3D thrust vector.
        #
        # This is a 3D vector object representing the thrust vector of an 
        # object (such as a ship or missle) in space.
        # 
        # Options:
        # @arg -acceleration This is a floating point number from 0.0 to 1000 
        #            and is the number of times the Earth normal gravitational 
        #            constant (\f$9.80665m/s^2\f$). This is a readonly option 
        #            and defaults to 0.0.
        # @arg -xang The x angle of the thrust vector as a floating point 
        #            number in radians between \f$0\f$ and \f$\pi\f$. 
        #            This is a readonly option and defaults to 0.0.
        # @arg -yang The y angle of the thrust vector as a floating point 
        #            number in radians between \f$0\f$ and \f$\pi\f$. 
        #            This is a readonly option and defaults to 0.0.
        # @arg -zang The z angle of the thrust vector as a floating point 
        #            number in radians between \f$0\f$ and \f$\pi\f$. 
        #            This is a readonly option and defaults to 0.0.
        # @par
        
        variable dx
        ## @privatesection This is the x component of the thrust vector, in
        # kilometers per second, squared.
        variable dy
        ## This is the y component of the thrust vector, in kilometers per 
        # second, squared.
        variable dz
        ## This is the z component of the thrust vector, in kilometers per 
        # second, squared.
        typevariable G 0.00980665
        ## Earth normal gravitional constant in kilometers per second, squared.
        option -acceleration -readonly yes -default 0.0 \
              -type starships::StarshipAcceleration
        option -xang -readonly yes -default 0.0 -type starships::radians
        option -yang -readonly yes -default 0.0 -type starships::radians
        option -zang -readonly yes -default 0.0 -type starships::radians
        
        constructor {args} {
            ## @publicsection Construct a ThrustVector.
            #
            # @param name The name of the Thrust Vector.
            # @param ... Options:
            # @arg -acceleration This is a floating point number from 0.0 to 
            #            1000 and is the number of times the Earth normal 
            #            gravitational constant (\f$9.80665m/s^2\f$). This is 
            #            a readonly option and defaults to 0.0.
            # @arg -xang The x angle of the thrust vector as a floating point 
            #            number in radians between \f$0\f$ and \f$\pi\f$. 
            #            This is a readonly option and defaults to 0.0.
            # @arg -yang The y angle of the thrust vector as a floating point 
            #            number in radians between \f$0\f$ and \f$\pi\f$. 
            #            This is a readonly option and defaults to 0.0.
            # @arg -zang The z angle of the thrust vector as a floating point 
            #            number in radians between \f$0\f$ and \f$\pi\f$. 
            #            This is a readonly option and defaults to 0.0.
            # @par
            
            $self configurelist $args
            # Now for some hairy math...
            # Math lifted from http://www.intmath.com/vectors/7-vectors-in-3d-space.php
            set alpha $options(-xang)
            set beta  $options(-yang)
            set gamma $options(-zang)
            
            set _dx [expr {cos($alpha)}]
            set _dy [expr {cos($beta)}]
            set _dz [expr {cos($gamma)}]
            set ulength [_length $_dx $_dy $_dz]
            #puts stderr "*** $type create: ulength = $ulength"
            if {$ulength < 1} {
                error [_ "Imposible launch angle: %f6.3 %f6.3 %f6.3!" $alpha $beta $gamma]
            }
            set adelta [expr {($options(-acceleration) * $G) / $ulength}]
            set dx [expr {$_dx *  $adelta}]
            set dy [expr {$_dy *  $adelta}]
            set dz [expr {$_dz *  $adelta}]
        }
        method DeltaX {} {
            ## Return the delta x component of the thrust vector.
            #
            # @return The delta x component.
            
            return $dx
        }
        method DeltaY {} {
            ## Return the delta y component of the thrust vector.
            #
            # @return The delta y component.
            
            return $dy
        }
        method DeltaZ {} {
            ## Return the delta z component of the thrust vector.
            #
            # @return The delta z component.
            
            return $dz
        }
        typemethod validate {object} {
            ## Validate that the object is a ThrustVector.
            #
            
            if {[catch {$object info type} thetype]} {
                error [_ "%s is not a %s!" $object $type]
            } elseif {$thetype ne $type} {
                error [_ "%s is not a %s!" $object $type]
            } else {
                return $object
            }
        }
        method Length {} {
            ## Return the unit length of the vector.
            #
            # @return The unit length of the vector. 
            
            return [_length $dx $dy $dz]
        }
        proc _length {x y z} {
            ## @privatesection Compute the length of a 
            # \f$[x \quad y \quad z]\f$.
            #
            # @param x The dx component.
            # @param y The dy component.
            # @param z The dz component.
            # @return \f$\sqrt{x^2+y^2+z^2}\f$
            
            return [expr {sqrt(($x*$x) + ($y*$y) + ($z*$z))}]
        }
    }
    
    snit::type Missle {
        ## @brief A missle.
        # This is an object representing a fired missle.  It has an engine,
        # guidence system and a warhead or EW package.  The engine produces
        # thrust for a limited amount of time, then shuts down (runs out of
        # ``fuel'').  After engine shutdown, the missle drifts until it 
        # detonates or engages its EW package.
        #
        # Options, all readonly and must be set at create time, none have 
        # defaults:
        # @arg -missletype   The missle's type as an enum.
        # @arg -haswarhead   A boolean indicating if this missle has a 
        #                    warhead or an EW package.
        # @arg -start        The starting position as a orsa::Vector object.
        #                    This option can only be set at creation time.
        #                    It has no default value.
        # @arg -basevel      The base velocity (velocity of the starship at launch).
        # @arg -xang         The absolute X launch angle in radians, between 
        #                    \f$0\f$ and \f$\pi\f$.
        # @arg -yang         The absolute Y launch angle in radians, between 
        #                    \f$0\f$ and \f$\pi\f$.
        # @arg -zang         The absolute Z launch angle in radians, between 
        #                    \f$0\f$ and \f$\pi\f$.
        # @arg -mass           The mass of the missle in metric tons.
        #                      It has no default value and can only be set 
        #                      at creation time.
        # @arg -system         The planetary system the ship is in. See
        #                      PlantarySystem.
        # @par
        
        component thrustvector
        ## @privatesection Current thrustvector.
        variable thrusttime
        ## Remaining thrust time.
        option -mass  -readonly yes -type starships::masstype
        component system
        ## @privatesection @brief The planetary system.
        option -system -type starships::PlantarySystem \
              -configuremethod _setSystem -cgetmethod _getSystem
        method _setSystem {option value} {
            ## Set the planetary system.
            #
            # @param option Allways -system.
            # @param value The planetary system.
            #
            
            set system $value
        }
        method _getSystem {option} {
            ## Get the planetary system.
            #
            # @param option Allways -system.
            # @return The planetary system.
            
            return $system
        }
        
        component queueable
        ## Component to hold system updatable fields.
        delegate method * to queueable
        option -start -type orsa::Vector -readonly yes
        option -basevel -type orsa::Vector -readonly yes
        method _notsettable {option value} {
            ## Generic method for non settable options.
            #
            # @param option Name of the option.
            # @param value Not used.
            
            error [_ "Cannot set option %s!" $option]
        }
        typevariable misslespecs -array {
            mark1,acceleration 1000
            mark1,burntime 300
            mark1,mass 1
            mark2,acceleration 1000
            mark2,burntime 300
            mark2,mass 1
            mark4,acceleration 1000
            mark4,burntime 600
            mark4,mass 2
            mark10,acceleration 1000
            mark10,burntime 600
            mark10,mass 4
        }
        ## Missle specifications: acceleration (fraction of c) and burntime 
        # in seconds.
        option -missletype -readonly yes -default mark1 \
              -type starships::MissleType
        option -haswarhead -readonly yes -default yes -type snit::boolean
        option -xang -readonly yes -default 0.0 -type starships::radians
        option -yang -readonly yes -default 0.0 -type starships::radians
        option -zang -readonly yes -default 0.0 -type starships::radians
        variable launchepoch -1
        variable burnout false
        ## Launch time.
        constructor {args} {
            ## @publicsection @brief Construct a missle.
            # Create a new missle.  Missles are ``created'' when they are 
            # launched.
            #
            # @arg -missletype   The missle's type as an enum.
            # @arg -haswarhead   A boolean indicating if this missle has a 
            #                    warhead or an EW package.
            # @arg -start        The starting position as a orsa::Vector object.
            #                    This option can only be set at creation time.
            #                    It has no default value.
            # @arg -xang         The absolute X launch angle in radians, between 
            #                    \f$0\f$ and \f$\pi\f$.
            # @arg -yang         The absolute Y launch angle in radians, between 
            #                    \f$0\f$ and \f$\pi\f$.
            # @arg -zang         The absolute Z launch angle in radians, between 
            #                    \f$0\f$ and \f$\pi\f$.
            # @arg -mass           The mass of the missle in metric tons.
            #                      It has no default value and can only be set 
            #                      at creation time.
            # @arg -system         The planetary system the ship is in. See
            #                      PlantarySystem.
            # @par
            
            $self configurelist $args
            set mtype [$self cget -missletype]
            install thrustvector using ::starships::ThrustVector \
                  ${mtype}%AUTO% \
                  -acceleration $misslespecs($mtype,acceleration) \
                  -xang  [$self cget -xang] \
                  -yang  [$self cget -yang] \
                  -zang  [$self cget -zang]
            set thrusttime $misslespecs($mtype,burntime)
            set options(-mass) $misslespecs($mtype,mass)
            install queueable using PlanetarySystemClient::QueueAbleObject \
                  %AUTO% -updatecallback [mymethod _updatecallback]
            $self setposition [$self cget -start]
            $self setvelocity [$self cget -basevel]
            $self setmass [$self cget -mass]
            $self setthrustvector [orsa::Vector create %AUTO% \
                                   [$thrustvector DeltaX] \
                                   [$thrustvector DeltaY] \
                                   [$thrustvector DeltaZ]]
        }
        method _updatecallback {} {
            if {$launchepoch < 0} {
                set launchepoch [$self epoch]
                set burnout false
            }
            if {!$burnout} {
                if {([$self epoch] - $launchepoch) >= $thrusttime} {
                    set burnout true
                    $setthrustvector [orsa::Vector create %AUTO% 0 0 0]
                    $system updatethrustvector $self
                }
            }
        }
    }
    snit::type StarshipMissleLaunchers {
        ## @brief A bank of missle launchers mounted on a starship.
        #
        # These are the starship main long range weapon system.  A missle is
        # a small self-propeled device with some sort of warhead (usually
        # a nuclear bomb or [nuclear] bomb pumped X-Ray lasers), a simple 
        # guidence system, and some sort of propulsion system.  Some missles
        # have an electronic warfare package that will distrupt the enemy's
        # anti-missle defence system.
        #
        # Options
        # @arg -count The number of launchers, as a integer between 0 and 25. 
        #             This is a readonly option. The default is 4.
        # @arg -size  The size class of the launchers, as an enumerated type.
        #             This is a readonly option. The default is mark1.
        # @par
        typemethod validate {o} {
            puts stderr "*** $type validate $o"
            if {[catch {$o info type} thetype]} {
                error "Not a $type: $o"
            } elseif {$thetype ne $type} {
                puts stderr "*** $type validate: thetype is $thetype"
                error "Not a $type: $o"
            } else {
                return $o
            }
        }
        
        option -count -readonly yes -default 4 -type starships::LauncherCount
        option -size  -readonly yes -default mark1 \
              -type starships::MissleType
        variable launchers -array {}
        ## @privatesection These are the actual launchers, with their 
        # magazines.
        typevariable launcherspecs -array {
            mark1,magazine 20
            mark1,ewpercent 25
            mark2,magazine 50
            mark2,ewpercent 25
            mark4,magazine 100
            mark4,ewpercent 25
            mark10,magazine 20
            mark10,ewpercent 2
        }
        ## Launcher specifications: magazine size, percent of EW platforms,
        # range (10^6 Km), and acceleration (fraction of c).
        
        constructor {args} {
            ## @publicsection Construct banks of missle launchers.
            #
            # These are the starship's missle launchers.
            #
            # @param name The name of the missle launchers object.
            # @param ... Options:
            # @arg -count The number of launchers, as a integer between 0 and 25. 
            #             This is a readonly option. The default is 4.
            # @arg -size  The size class of the launchers, as an enumerated type.
            #             This is a readonly option. The default is mark1.
            # @par
            
            $self configurelist $args
            for {set ilaunch 0} {$ilaunch < $options(-count)} {incr ilaunch} {
                set launchers($ilaunch,magazine) {}
                set launchers($ilaunch,functional) yes
            }
        }
        method launch {position xang yang zang {number all}} {
            ## @brief Launch missiles.
            # Launch up to one missle per launcher.  
            #
            # @param position The launch position as a Coordinates object.
            # @param xang The x launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param yang The y launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param zang The z launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param number The number of missles to launch or all.  If all, 
            # launch a missle from all launchers that are functional.
            # @return A list of the missles launched (a list of 
            # starships::Missle objects).
            
            starships::Coordinates validate $position
            starships::radians validate $xang
            starships::radians validate $yang
            starships::radians validate $zang
            if {$number eq "all"} {set number $options(-count)}
            set launched [list]
            for {set i 0} {$i < $number} {incr i} {
                if {$launchers($i,functional) && 
                    [llength $launchers($i,magazine)] > 0} {
                    if {[lindex $launchers($i,magazine) 0] eq "w"} {
                        set haswarhead yes
                    } else {
                        set haswarhead no
                    }
                    set missle [starships::missle %AUTO% \
                                -missletype [$self cget -size] \
                                -haswarhead $haswarhead \
                                -start  [$self position] \
                                -basevel [$self velocity] \
                                -xang   $xang \
                                -yang   $yang \
                                -zang   $zang]
                    lappend launched $missle
                    set launchers($i,magazine) [lrange $launchers($i,magazine) 1 end]
                }
            }
            return $launched
        }
        method reload {missles} {
            ## Reload missle magazines from the supply provided.
            #
            # @param missles A supply of missles.  This is a list of 
            # ``missles'', which is a list of w's (warheads) and e's (EW 
            # platforms).
            # @return Unused missles.  This is a list containing w's and e's
            # that were not used.
            
            while {[llength $missles] > 0 && 
                [$self reloadspace] > 0 && 
                [lsearch -exact $missles w] >= 0} {
                #puts stderr "*** $self reload: missles = $missles, reloadspace is [$self reloadspace]"
                set unused [list]
                set i 0
                foreach next $missles {
                    set ew [$self _ewpercent]
                    #puts stderr "*** $self reload: i = $i, next = $next, ew = $ew"
                    while {!$launchers($i,functional) || 
                        [llength $launchers($i,magazine)] >= $launcherspecs($options(-size),magazine)} {
                        incr i
                        if {$i >= $options(-count)} {
                            set i 0
                        }
                    }
                    if {$next eq "e"} {
                        if {$ew < $launcherspecs($options(-size),ewpercent)} {
                            lappend launchers($i,magazine) $next
                        } else {
                            lappend unused $next
                        }
                    } else {
                        if {$ew >=  $launcherspecs($options(-size),ewpercent)} {
                            lappend launchers($i,magazine) $next
                        } else {
                            lappend unused $next
                        }
                    }
                    if {[$self reloadspace] <= 0 ||
                        [lsearch -exact $missles w] < 0} {break}
                    
                    incr i
                    if {$i >= $options(-count)} {
                        set i 0
                    }
                }
                set missles $unused
            }
            return $missles
        }
        method available {} {
            ## Return a count of available missles.
            #
            # @return A count of available missles.
            
            set total 0
            for {set i 0} {$i < $options(-count)} {incr i} {
                if {$launchers($i,functional)} {
                    incr total [llength $launchers($i,magazine)]
                }
            }
            return $total
        }
        method reloadspace {} {
            ## Return a count of available magazine space.
            #
            # @return A count of available space in the magazines.
            
            set total 0
            set msize $launcherspecs($options(-size),magazine)
            for {set i 0} {$i < $options(-count)} {incr i} {
                if {$launchers($i,functional)} {
                    set used [llength $launchers($i,magazine)]
                    incr total [expr {$msize - $used}]
                }
            }
            return $total
        }
        method launchersavailable {} {
            ## Return the number of available launchers.
            #
            # @return The number of available, functional launchers that
            # still have missles in their magazines.
            #
            
            set count 0
            for {set i 0} {$i < $options(-count)} {incr i} {
                if {$launchers($i,functional) && [llength $launchers($i,magazine)] > 0} {
                    incr count
                }
            }
            return $count
        }
        method _ewpercent {} {
            ## @privatesection Return the percentage of EW platforms in the
            # all of the magazines.
            #
            # @return The percentage of EW platforms in the magazine as a 
            # number from 0 to 100.
            
            set l 0
            set e 0
            for {set i 0} {$i < $options(-count)} {incr i} {
                if {$launchers($i,functional)} {
                    incr l [llength $launchers($i,magazine)]
                    incr e [llength [lsearch -all -inline -exact $launchers($i,magazine) e]]
                }
            }
            if {$l == 0} {return 100}
            return [expr {int(100 * (double($e) / double($l)))}]
        }
    }
    
    snit::type Starship {
        ## @brief Main Starship type.
        #
        # Defines a Starship object.
        #
        # Options:
        # @arg -start        The starting position as a orsa::Vector object.
        #                    This option can only be set at creation time.
        #                    It has no default value.
        # @arg -initvel      The starting velocity as a orsa::Vector object.
        #                    This option can only be set at creation time.
        #                    It has no default value.
        # @arg -port         The server port, defaults to 5050.
        # @arg -host         The server host, defaults to localhost.
        # @arg -class The class of ship.  An Enum of StarshipClasses type.
        #      No default value, readonly, @b must be specified at construct 
        #      time.
        # @arg -mass           The mass of the starship in metric tons.
        #                      It has no default value and can only be set 
        #                      at creation time.
        # @arg -maxdesignaccel Delegated to the starship's engine component.  
        #                      See the StarshipEngine type.
        # @arg -maxaccel       Delegated to the starship's engine component.
        #                      See the StarshipEngine type.
        # @arg -acceleration   Delegated to the starship's engine component. 
        #                      See the StarshipEngine type.
        # @arg -shieldstrength Delegated to the starship's shields component.
        #                      See the StarshipShields type.
        # @arg -numberoflaunchers Delegated to the starship's misslelaunchers
        #                      component as its -count option.  See the 
        #                      StarshipMissleLaunchers type.
        # @arg -sizeofmissle   Delegated to the starship's misslelaunchers
        #                      component as its -size option.  See the 
        #                      StarshipMissleLaunchers type.
        # @par
        
        typemethod validate {o} {
            puts stderr "*** $type validate $o"
            if {[catch {$o info type} thetype]} {
                error "Not a $type: $o"
            } elseif {$thetype ne $type} {
                puts stderr "*** $type validate: thetype is $thetype"
                error "Not a $type: $o"
            } else {
                return $o
            }
        }
        
        option -class -readonly yes -type starships::StarshipClasses
        option -mass  -readonly yes -type starships::masstype
        option -start -type orsa::Vector -readonly yes
        option -initvel -type orsa::Vector -readonly yes
        component system
        ## @privatesection @brief The planetary system.
        delegate option -port to system
        delegate option -host to system
        component queueable
        ## Component to hold system updatable fields.
        delegate method * to queueable
        component bridgeconsole
        ## @brief The starship's bridge console set.
        # Includes all of the bridge stations: Captian's chair, 
        # navigation w/ helm, sensors, tactical, engineering, and 
        # communication. 
        component engine
        ## @brief The engine.
        # This is the engine, which provides thrust in the direction of travel.
        # It has a maximum design acceleration (@c -maxdesignaccel), a current
        # maximum acceleration (@c -maxaccel), and a current acceleration
        # (@c -acceleration).
        delegate option -maxdesignaccel to engine
        delegate option -maxaccel to engine
        delegate option -acceleration to engine
        component shields
        ## @brief The starship's shields.
        # The starship shields, which protects the starship both from 
        # small objects in space (rocks, meteorites, etc.) and from enemy
        # weapon fire (lasers, missiles, etc.).
        delegate option -shieldstrength to shields
        component misslelaunchers
        ## @brief The starship's missle launchers.
        # The starship missle launchers, which launch missles.  Bigger ships
        # have more of them and larger ones (can launch larger (more powerful) 
        # missles.
        delegate option -numberoflaunchers to misslelaunchers as -count
        delegate option -sizeofmissle to misslelaunchers as -size
        delegate method reloadmissiles to misslelaunchers as reload
        delegate method misslesavailable to misslelaunchers as available
        delegate method reloadspaceavailable to misslelaunchers as reloadspace
        delegate method launchersavailable to misslelaunchers
        component sensors
        ## @brief The starship's sensor suite        
        component lasers
        ## @brief The starship's lasers.
        # These are short range ship to ship weapons.
        component countermissles
        ## @brief The starship's counter missles.
        # These are small missles meant as an anti-missle defence.
        component pointdefence
        ## @brief The starship's point defence lasers.
        # These are small lasers meant as an anti-missle defence.
        component munitions
        ## @brief This is the cargo of an ammunition ship.
        component troops
        ## @brief The ship's marine complement.
        # The marine is usually a small group meant to be used as boarding
        # parties and SAR.  A troop carrier would have a much larger 
        # complement intended for planetary occupation.
        variable xang [expr {acos(1)}]
        ## The ship's current X orientation.
        variable yang [expr {acos(0)}]
        ## The ship's current Y orientation.
        variable zang [expr {acos(0)}]
        ## The ship's current Z orientation.
        
        constructor {args} {
            ## @publicsection The constructor constructs a Starship object.
            #
            # @param name The name of the starship.
            # @param ... Options:
            # @arg -start        The starting position as a orsa::Vector object.
            #                    This option can only be set at creation time.
            #                    It has no default value.
            # @arg -initvel      The starting velocity as a orsa::Vector object.
            #                    This option can only be set at creation time.
            #                    It has no default value.
            # @arg -mass         The mass of the starship in metric tons. 
            #                    It has no default value and can only be set 
            #                    at creation time.
            # @arg -port         The server port, defaults to 5050.
            # @arg -host         The server host, defaults to localhost.
            # @arg -class The class of ship.  An Enum of StarshipClasses type.
            #      No default value, readonly, @b must be specified at 
            #      construct time.
            # @arg -maxdesignaccel Delegated to the starship's engine component. 
            #                      See the StarshipEngine type.
            # @arg -maxaccel       Delegated to the starship's engine component. 
            #                      See the StarshipEngine type.
            # @arg -acceleration   Delegated to the starship's engine component. 
            #                      See the StarshipEngine type.
            # @arg -shieldstrength Delegated to the starship's shields component. 
            #                      See the StarshipShields type.
            # @arg -numberoflaunchers Delegated to the starship's misslelaunchers
            #                      component as its -count option.  See the 
            #                      StarshipMissleLaunchers type.
            # @arg -sizeofmissle   Delegated to the starship's misslelaunchers
            #                      component as its -size option.  See the 
            #                      StarshipMissleLaunchers type.
            # @par
            
            if {[lsearch -exact $args -class] < 0} {
                error [_ "The -class option must be specified!"]
            }
            if {[lsearch -exact $args -mass] < 0} {
                error [_ "The -mass option must be specified!"]
            }
            if {[lsearch -exact $args -start] < 0} {
                error [_ "The -start option must be specified!"]
            }
            if {[lsearch -exact $args -initvel] < 0} {
                error [_ "The -initvel option must be specified!"]
            }
            install system using PlanetarySystemClient::Client %AUTO% \
                  -port [from args -port 5050] \
                  -host [from args -host localhost]
            install engine using starships::StarshipEngine %AUTO% \
                  -maxdesignaccel [from args -maxdesignaccel 500]
            install shields using starships::StarshipShields %AUTO%
            install misslelaunchers using starships::StarshipMissleLaunchers \
                  %AUTO% -count [from args -numberoflaunchers 4] \
                  -size [from args -sizeofmissle mark1]
            install queueable using PlanetarySystemClient::QueueAbleObject \
                  %AUTO%
            $self configurelist $args
            install bridgeconsole using bridgeconsole::FullConsole .[string tolower [namespace tail $self]]_bridge \
                  -ship $self -system $system -engine $engine \
                  -shields $shields -misslelaunchers $misslelaunchers
            $self setposition [$self cget -start]
            $self setvelocity [$self cget -initvel]
            $self setmass [$self cget -mass]
            update 
            $system add $self
        }
        
        method statusreport {} {
            ## Return a status report.
            #
            # @return A status report.
            
            set report [list]
            foreach {c} [$self configure] {
                foreach {o n N def val} $c {break}
                lappend report $N $val
            }
            lappend report AvailableLaunchers [$self launchersavailable]
            lappend report AvailableMissles [$self misslesavailable]
            lappend report ReloadSpaceAvailable [$self reloadspaceavailable]
            return $report                                                     
        }
        method launchmissiles {xang yang zang {number all}} {
            ## @brief Launch missles.
            # Launch the selected number of missles in the specified direction.
            #
            # @param xang The x launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param yang The y launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param zang The z launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param number The number of missles to launch or all.  If all, 
            # launch a missle from all launchers that are functional.
            # @return A list of the missles launched (a list of 
            # starships::Missle objects).
            
            set launched [$misslelaunchers launch $position $xang $yang $zang $number]
            foreach m $launched {
                $m configure -system $system
                $system add $m
            }
            return $launched
        }
            
        method update {} {
            ## @brief Update the starship.
            # The starchip's x,y,z position is updated.
            #
            # @return A list containing the new X, Y, Z position of the 
            # starship.
            
            set thrustvector [starships::ThrustVector %AUTO% \
                              -acceleration [$engine cget -acceleration] \
                              -xang $xang \
                              -yang $yang \
                              -zang $zang]
            set xspeed [expr {$xspeed + [$thrustvector DeltaX]}]
            set yspeed [expr {$yspeed + [$thrustvector DeltaY]}]
            set zspeed [expr {$zspeed + [$thrustvector DeltaZ]}]
            foreach {xpos ypos zpos} [$position cget -cartesian] {break}
            set xpos [expr {$xpos + $xspeed}]
            set ypos [expr {$ypos + $yspeed}]
            set zpos [expr {$zpos + $zspeed}]
            $position configure -cartesian [list $xpos $ypos $zpos]
            return [list $xpos $ypos $zpos]
        }
        typemethod destroyer {name start initvel} {
            ## Create a destroyer.  Destroyer accelerate at up to 500 
            # gravities, and have 4 Mark1 launchers.
            #
            # @param name The name of the destroyer.
            # @param start The starting position as a orsa::Vector
            # @param initvel The starting velocity as a orsa::Vector
            # @return A destroyer class starship.
            
            return [$type create $name -class destroyer -maxdesignaccel 500 \
                    -numberoflaunchers 4 -sizeofmissle mark1 -start $start \
                    -mass 75000 \
                    -initvel $initvel]
        }
        typemethod lightcrusier {name start initvel} {
            ## Create a lightcrusier.  Lightcrusiers accelerate at up to 
            # 500 gravities, and have 6 Mark1 launchers.
            #
            # @param name The name of the lightcrusier.
            # @param start The starting position as a orsa::Vector
            # @param initvel The starting velocity as a orsa::Vector
            # @return A lightcrusier class starship.
            
            return [$type create $name -class lightcrusier \
                    -maxdesignaccel 500 -numberoflaunchers 6 \
                    -sizeofmissle mark1 -start $start \
                    -mass 200000 -initvel $initvel]
        }
        typemethod heavycrusier {name start psystem} {
            ## Create a heavycrusier.  Heavycrusiers accelerate at up to 
            # 500 gravities, and have 8 Mark2 launchers.
            #
            # @param name The name of the heavycrusier.
            # @param start The starting position as a Coordinates object.
            # @return A heavycrusier class starship.
            
            return [$type create $name -class heavycrusier \
                    -maxdesignaccel 500 -numberoflaunchers 8 \
                    -sizeofmissle mark2 -start $start \
                    -mass 350000 -system $psystem]
        }
        typemethod battlecrusier {name start psystem} {
            ## Create a battlecrusier.  Battlecrusiers accelerate at up to 
            # 450 gravities, and have 10 Mark2 launchers.
            #
            # @param name The name of the battlecrusier.
            # @param start The starting position as a Coordinates object.
            # @return A battlecrusier class starship.
            
            return [$type create $name -class battlecrusier \
                    -maxdesignaccel 450 -numberoflaunchers 10 \
                    -sizeofmissle mark2 -start $start \
                    -mass 500000 -system $psystem]
        }
        typemethod dreadnought {name start psystem} {
            ## Create a dreadnought.  Dreadnoughts accelerate at up to 
            # 450 gravities, and have 15 Mark4 launchers.
            #
            # @param name The name of the dreadnought.
            # @param start The starting position as a Coordinates object.
            # @return A dreadnought class starship.
            
            return [$type create $name -class dreadnought \
                    -maxdesignaccel 450 -numberoflaunchers 15 \
                    -sizeofmissle mark4 -start $start \
                    -mass 1000000 -system $psystem]
        }
        typemethod superdreadnought {name start psystem} {
            ## Create a super dreadnought.  Super Dreadnoughts accelerate at 
            # up to 400 gravities, and have 25 Mark4 launchers.
            #
            # @param name The name of the super dreadnought.
            # @param start The starting position as a Coordinates object.
            # @return A super dreadnought class starship.
            
            return [$type create $name -class superdreadnought \
                    -maxdesignaccel 400 -numberoflaunchers 25 \
                    -sizeofmissle mark4 -start $start \
                    -mass 8000000 -system $psystem]
        }
        typemethod ammunition {name start} {
            ## Create an ammunition ship.  Ammunition ships accelerate at up 
            # to 400 gravities, and have no missle launchers.
            #
            # @param name The name of the ammunition ship.
            # @param start The starting position as a Coordinates object.
            # @return A ammunition ship class starship.
            
            return [$type create $name -class ammunition \
                    -maxdesignaccel 400  -numberoflaunchers 0 -start $start \
                    -mass 5000000 -system $psystem]
        }
        typemethod troopcarrier {name start} {
            ## Create a troop carrier.  Troop Carriers accelerate at up to 
            # 450 gravities, and have no missle launchers.
            #
            # @param name The name of the troop carrier.
            # @param start The starting position as a Coordinates object.
            # @return A troop carrier class starship.
            
            return [$type create $name -class troopcarrier \
                    -maxdesignaccel 450 -numberoflaunchers 0 -start $start \
                    -mass 500000 -system $psystem]
        }
    }
    snit::enum StationClasses -values {
        ## @enum StationClasses
        # Station classes
        #
        small
        ## @brief Small station for "backwater" planets.
        medium
        ## @brief Medium sized station for intermediate planets.
        large
        ## @brief Large sized station for major planets.
        smallyard
        ## @brief Small sized yard station.
        mediumyard
        ## @brief Medium sized yard station.
        largeyard
        ## @brief Large sized yard station.
        specialpurpose
        ## @brief A special purpose station.
    }
    snit::type Station {
        ## @brief A space station: a place where starships dock and/or are built.
        #
        # Defines a Station object.
        #
        # Options:
        # @arg -port         The server port, defaults to 5050.
        # @arg -host         The server host, defaults to localhost.
        # @arg -mass         The mass of the starship in metric tons.
        #                    It has no default value and can only be set 
        #                    at creation time.
        # @arg -class        The class of station. An Enum of StationClasses 
        #                    type. No default value, readonly, @b must be 
        #                    specified at construct time.
        # @par
        
        option -class -readonly yes -type starships::StationClasses
        option -mass  -readonly yes -type starships::masstype
        component system
        ## @privatesection @brief The planetary system.
        delegate option -port to system
        delegate option -host to system
        component stationcommand
        ## @brief The station's command center.
        component docks
        ## @brief The station's (regular) docks.  Where starships dock to 
        # load/unload cargo and passengers and crew.  Also where fuel and
        # other supplies are taken on.  (Minor repairs might also be done
        # here.)
        component drydocks
        ## @brief The station's shipbuilding docks. A "yard" station will have 
        # these.  These are places where ships are built from the "keel" up.
        delegate option -numberofdockingbays to docks as -count
        delegate option -sizeofdockingbays to docks as -size
        delegate option -numberofdrydocks to drydocks as -count
        delegate option -sizeofdrydocks to drydocks as -size
        component shuttlebays
        ## @brief The station's shuttle bays.  Where planetary shuttles dock.
        delegate option -numberofshuttlebays to shuttlebays as -count
        component sensors
        ## @brief The station's sensor suite
        variable position
        ## Current position.
        variable velocity
        ## Current velocity.
        variable planet
        ## Planet we are in orbit around.
        variable sun
        ## The system sun.
        constructor {args} {
            ## @publicsection The constructor constructs a Station object.
            #
            # Defines a Station object.
            #
            # Options:
            # @arg -port         The server port, defaults to 5050.
            # @arg -host         The server host, defaults to localhost.
            # @arg -mass         The mass of the starship in metric tons.
            #                    It has no default value and can only be set 
            #                    at creation time.
            # @arg -class        The class of station. An Enum of StationClasses 
            #                    type. No default value, readonly, @b must be 
            #                    specified at construct time.
            # @par
            if {[lsearch -exact $args -class] < 0} {
                error [_ "The -class option must be specified!"]
            }
            if {[lsearch -exact $args -mass] < 0} {
                error [_ "The -mass option must be specified!"]
            }
            install system using PlanetarySystemClient::Client %AUTO% \
                  -port [from args -port 5050] \
                  -host [from args -host localhost] \
                  -sensehandler [mymethod _sensehandler]
            install docks using starships::DockingBays  %AUTO% \
                  -count [from args -numberofdockingbays 10] \
                  -size  [from args -sizeofdockingbays   SMALL]
            install drydocks using starships::DryDocks %AUTO% \
                  -count [from args -numberofdrydocks 0] \
                  -size  [from args -sizeofdrydocks SMALL]
            install shuttlebays using starships::ShuttleBays %AUTO% \
                  -count [from args -numberofshuttlebays 1]
            install stationcommand using stationcommand::StationCommand .[string tolower [namespace tail $self]]_ControlCenter \
                  -station $self -system $system -docks $docks \
                  -drydocks $drydocks -shuttlebays $shuttlebays
            $self configurelist $args
            
        }
            
    }
}



proc print {v} {
    Vector validate $v
    puts "[format {X: %10.5g, Y: %10.5g, Z: %10.5g} [$v GetX] [$v GetY] [$v GetZ]]"
}

#set system [planetarysystem::PlanetarySystem %AUTO% -generate no -filename test.system]
#
#
#set maindisp [planetarysystem::MainScreen .main -generate no -filename test.system]
#set pd [planetarysystem::PlanetaryDisplay .pd  -generate no -filename test.system]
#pack $pd -fill both -expand yes
#
#package require MainDisplay
#
#set maindisp [planetarysystem::MainScreen .main -generate yes \
#              -stellarmass 1.0 -seed 1 -geometry =1100x650+0-0]
#           pack $maindisp -fill both -expand yes
#$maindisp save test.system
#exit

#package require stargen
#
#set results [stargen main -mass 1.0 -seed 1 -habitable -moons \
#             -count 5 -verbose 0x7FFFF]
#
#foreach s $results {
#    $s print stdout
#}
#exit 0

#shipyardcommand::ShipyardCommand .shipyardcommand
#pack .shipyardcommand

::starships::Starship destroyer \
      test \
      [::orsa::Vector %AUTO% [expr {[$::orsa::units GetLengthScale AU] * 5.0}] 0 0] \
      [::orsa::Vector %AUTO% 0 [$::orsa::units GetLengthScale KM] 0]

      
