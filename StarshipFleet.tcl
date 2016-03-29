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
#  Last Modified : <160329.1353>
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

proc _ {args} {
    return [eval format $args]
}


namespace eval starships {
    ##
    # @brief Starship code, Version 0
    #
    # This is an idea that came to me in a dream.  Don't know where it will
    # lead.
    #
    # @author Robert Heller \<heller\@deepsoft.com\>
    #
    
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
    
    snit::double StarshipAcceleration  -min 0.0 -max .5
    ## @typedef double StarshipAcceleration
    # Starship acceleration type:  A double between 0.0 and .5.
    
    snit::type StarshipEngine {
        ## @brief Starship Engine type.
        #
        # Defines a Starship Engine object.  A Starship Engine provides thrust
        # (acceleration) in the direction of travel.
        #
        # Options:
        # 
        # @arg -maxdesignaccel This is a floating point number from 0.0 to .5 
        #                      and is the fraction of the speed of light (\f$c\f$) 
        #                      of acceleration the engine can develop when it 
        #                      is working at peak performance level.  This is
        #                      a readonly option with a default of 0.2.
        # @arg -maxaccel       This is a floating point number from 0.0 to .5 
        #                      and is the fraction of the speed of light (\f$c\f$) 
        #                      of acceleration the engine can develop at its
        #                      current performance level. The default is the
        #                      @c -maxdesignaccel setting.
        # @arg -acceleration   This is a floating point number from 0.0 to .5 
        #                      and is the fraction of the speed of light (\f$c\f$) 
        #                      of acceleration the engine is currently 
        #                      developing.  The default is 0.0 (at rest or 
        #                      drifting).
        # @par
        
        option -maxdesignaccel -readonly yes -default 0.2 \
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
            set accellimit 0.2
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
            #                      .5 and is the fraction of the speed of 
            #                      light (\f$c\f$) of acceleration the engine can 
            #                      develop when it is working at peak 
            #                      performance level.  This is a readonly 
            #                      option with a default of 0.2.
            # @arg -maxaccel       This is a floating point number from 0.0 to 
            #                      .5 and is the fraction of the speed of 
            #                      light (\f$c\f$) of acceleration the engine can 
            #                      develop at its current performance level. 
            #                      The default is the @c -maxdesignaccel 
            #                      setting.
            # @arg -acceleration   This is a floating point number from 0.0 to 
            #                      .5 and is the fraction of the speed of 
            #                      light (\f$c\f$) of acceleration the engine is 
            #                      currently developing.  The default is 0.0 
            #                      (at rest or drifting).
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
    snit::enum LauncherSize -values {
        ## @enum LauncherSize
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
    
    snit::double radians -max [expr {acos(-1)}] -min [expr {acos(1)}]
    ## @typedef double radians
    # A double between \f$0\f$ and \f$\pi\f$.
    
    snit::type ThrustVector {
        ## @brief ThrustVector object, representing a 3D thrust vector.
        #
        # This is a 3D vector object representing the thrust vector of an 
        # object (such as a ship or missle) in space.
        # 
        # Options:
        # @arg -acceleration The fraction of \f$c\f$ of thrust. This is a
        #            readonly option and defaults to 0.0.
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
        # millions of kilometers per second, squared.
        variable dy
        ## This is the y component of the thrust vector, in millions of 
        # kilometers per second, squared.
        variable dz
        ## This is the z component of the thrust vector, in millions of 
        # kilometers per second, squared.
        typevariable c 299.792458 
        ## The speed of light (\f$c\f$) in millions of kilometers per second.
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
            # @arg -acceleration The fraction of \f$c\f$ of thrust. This is a
            #            readonly option and defaults to 0.0.
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
            set adelta [expr {($options(-acceleration) * $c) / $ulength}]
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
        
        option -count -readonly yes -default 4 -type starships::LauncherCount
        option -size  -readonly yes -default mark1 \
              -type starships::LauncherSize
        variable launchers -array {}
        ## @privatesection These are the actual launchers, with their 
        # magazines.
        typevariable launcherspecs -array {
            mark1,magazine 20
            mark1,ewpercent 25
            mark1,acceleration .1
            mark1,range 1.0
            mark2,magazine 50
            mark2,ewpercent 25
            mark2,acceleration .15
            mark2,range 1.25
            mark4,magazine 100
            mark4,ewpercent 25
            mark4,acceleration .175
            mark4,range 1.5
            mark10,magazine 20
            mark10,ewpercent 2
            mark10,acceleration .2
            mark10,range 1.75
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
        method launch {xang yang zang {number all}} {
            ## @brief Launch missiles.
            # Launch up to one missle per launcher.  
            #
            # @param xang The x launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param yang The y launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param zang The z launch angle in radians, between
            #             \f$0\f$ and \f$\pi\f$.
            # @param number The number of missles to launch or all.  If all, 
            # launch a missle from all launchers that are functional.
            # @return The ThrustVector, range, missle size with a list of the 
            # missles launched.
            
            if {$number eq "all"} {set number $options(-count)}
            set launched [list]
            for {set i 0} {$i < $number} {incr i} {
                if {$launchers($i,functional) && 
                    [llength $launchers($i,magazine)] > 0} {
                    lappend launched [lindex $launchers($i,magazine) 0]
                    set launchers($i,magazine) [lrange $launchers($i,magazine) 1 end]
                }
            }
            if {[llength $launched] == 0} {
                return $launched
            } else {
                set size [$self cget -size]
                set accel $launcherspecs($size,acceleration)
                set range $launcherspecs($size,range)
                return [linsert $launched 0 [starships::ThrustVector $size%AUTO% \
                                             -acceleration $accel \
                                             -xang $xang \
                                             -yang $yang \
                                             -zang $zang] $range $size]
            }
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
        # @arg -class The class of ship.  An Enum of StarshipClasses type.
        #      No default value, readonly, @b must be specified at construct 
        #      time.
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
        
        
        option -class -readonly yes -type starships::StarshipClasses
        component engine
        ## @privatesection @brief The engine.
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
        delegate method launchmissiles to misslelaunchers as launch
        delegate method reloadmissiles to misslelaunchers as reload
        delegate method misslesavailable to misslelaunchers as available
        delegate method reloadspaceavailable to misslelaunchers as reloadspace
        delegate method launchersavailable to misslelaunchers
        
        constructor {args} {
            ## @publicsection The constructor constructs a Starship object.
            #
            # @param name The name of the starship.
            # @param ... Options:
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
            install engine using starships::StarshipEngine %AUTO% \
                  -maxdesignaccel [from args -maxdesignaccel 0.2]
            install shields using starships::StarshipShields %AUTO%
            install misslelaunchers using starships::StarshipMissleLaunchers \
                  %AUTO% -count [from args -numberoflaunchers 4] \
                  -size [from args -sizeofmissle mark1]
            $self configurelist $args
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
        typemethod destroyer {name} {
            ## Create a destroyer.  Destroyer accelerate at up to \f$.1c\f$,
            # and have 4 Mark1 launchers.
            #
            # @param name The name of the destroyer.
            # @return A destroyer class starship.
            
            return [$type create $name -class destroyer -maxdesignaccel .1 \
                    -numberoflaunchers 4 -sizeofmissle mark1]
        }
        typemethod lightcrusier {name} {
            ## Create a lightcrusier.  Lightcrusiers accelerate at up to 
            # \f$.11c\f$, and have 6 Mark1 launchers.
            #
            # @param name The name of the lightcrusier.
            # @return A lightcrusier class starship.
            
            return [$type create $name -class lightcrusier \
                    -maxdesignaccel .11 -numberoflaunchers 6 \
                    -sizeofmissle mark1]
        }
        typemethod heavycrusier {name} {
            ## Create a heavycrusier.  Heavycrusiers accelerate at up to 
            # \f$.12c\f$, and have 8 Mark2 launchers.
            #
            # @param name The name of the heavycrusier.
            # @return A heavycrusier class starship.
            
            return [$type create $name -class heavycrusier \
                    -maxdesignaccel .12 -numberoflaunchers 8 \
                    -sizeofmissle mark2]
        }
        typemethod battlecrusier {name} {
            ## Create a battlecrusier.  Battlecrusiers accelerate at up to 
            # \f$.15c\f$, and have 10 Mark2 launchers.
            #
            # @param name The name of the battlecrusier.
            # @return A battlecrusier class starship.
            
            return [$type create $name -class battlecrusier \
                    -maxdesignaccel .15 -numberoflaunchers 10 \
                    -sizeofmissle mark2]
        }
        typemethod dreadnought {name} {
            ## Create a dreadnought.  Dreadnoughts accelerate at up to 
            # \f$.18c\f$, and have 15 Mark4 launchers.
            #
            # @param name The name of the dreadnought.
            # @return A dreadnought class starship.
            
            return [$type create $name -class dreadnought \
                    -maxdesignaccel .18 -numberoflaunchers 15 \
                    -sizeofmissle mark4]
        }
        typemethod superdreadnought {name} {
            ## Create a super dreadnought.  Super Dreadnoughts accelerate at 
            # up to \f$.2c\f$, and have 25 Mark4 launchers.
            #
            # @param name The name of the super dreadnought.
            # @return A super dreadnought class starship.
            
            return [$type create $name -class superdreadnought \
                    -maxdesignaccel .2 -numberoflaunchers 25 \
                    -sizeofmissle mark4]
        }
        typemethod ammunition {name} {
            ## Create an ammunition ship.  Ammunition ships accelerate at up 
            # to \f$.2c\f$, and have no missle launchers.
            #
            # @param name The name of the ammunition ship.
            # @return A ammunition ship class starship.
            
            return [$type create $name -class ammunition \
                    -maxdesignaccel .2  -numberoflaunchers 0]
        }
        typemethod troopcarrier {name} {
            ## Create a troop carrier.  Troop Carriers accelerate at up to 
            # \f$.15c\f$, and have no missle launchers.
            #
            # @param name The name of the troop carrier.
            # @return A troop carrier class starship.
            
            return [$type create $name -class troopcarrier \
                    -maxdesignaccel .15 -numberoflaunchers 0]
        }
        
        
        
        
        
    }
}


