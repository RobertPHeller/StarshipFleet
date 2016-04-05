#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Tue Apr 5 09:53:26 2016
#  Last Modified : <160405.1638>
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
package require control
namespace import control::*

namespace eval planetarysystem {
    variable PLANETARYSYSTEM_DIR [file dirname [info script]]

    namespace import ::orsa::*
    
    snit::type NameGenerator {
        pragma -hastypeinfo false -hastypedestroy false -hasinstances false
        typevariable _corpus {}
        typeconstructor {
            set _corpus { }
            foreach w {} {
                regsub -all {[^[:alpha:]]} $w {} word
                if {$word eq {}} {continue}
                set word [string tolower $word]
                append _corpus "$word "
            }
        }
        proc rchar {{context ""}} {
            set p "${context}(.)"
            set n [expr {int(rand()*[string length $_corpus])}]
            if {[regexp -start $n -indices $p $_corpus n_i c_i] < 1} {
                if {[regexp -indices $p $_corpus n_i c_i] < 1} {
                    return {}
                }
            }
            set rc1 [string index $_corpus [lindex $c_i 0]]
            set n [lindex $n_i 0]
            incr n
            if {[regexp -start $n -indices $p $_corpus n_i c_i] < 1} {
                if {[regexp -indices $p $_corpus n_i c_i] < 1} {
                    return {}
                }
            }
            set rc2 [string index $_corpus [lindex $c_i 0]]
            if {rand() > .5} {
                return $rc1
            } else {
                return $rc2
            }
        }
        typemethod rword {k} {
            set result " "
            set c ""
            while {$c ne " "} {
                set len [string length $result]
                set s [expr {$len - $k}]
                set context [string range $result $s end]
                set c [rchar $context]
                append result $c
            }
            return [string trim $result]
        }
    }
    
    snit::type Sun {
        ## @brief A sun.
        # The ``sun'' is the center of the PlanetarySystem, located at position
        # {0,0,0} with a velicity of {0,0,0}.
        #
        # Options:
        # @arg -mass The stellar mass in Solar Masses.
        # @arg -luminosity The stellar luminosity.
        # @arg -age The age of the star in billions of years.
        # @arg -habitable The habitable ecosphere radius in AUs
        # @par
        
        component body
        ## @privatesection The orsa::body for the sun.
        delegate method * to body
        option -mass -default 0 -readonly yes -type {snit::double -min 0.0}
        option -luminosity -default 0 -readonly yes -type {snit::double -min 0.0}
        option -age -default 0 -readonly yes -type {snit::double -min 0.0}
        option -habitable -default 0 -readonly yes -type {snit::double -min 0.0}
        constructor {args} {
            ## @publicsection Construct a sun (star).
            #
            # @param name The name of the sun.
            # @param ... Options:
            # @arg -mass The stellar mass in Solar Masses.
            # @arg -luminosity The stellar luminosity.
            # @arg -age The age of the star in billions of years.
            # @arg -habitable The habitable ecosphere radius in AUs
            # @par
            
            $self configurelist $args
            set m [$orsa::units FromUnits_mass_unit $options(-mass) MSUN 1]
            install body using Body %AUTO% $self $m [Vector %AUTO% 0 0 0] [Vector %AUTO% 0 0 0]
        }
        typemethod namegenerator {} {
            return [planetarysystem::NameGenerator 2]
        }
    }
    snit::type Planet {
        ## @brief A planet.
        # A PlanetarySystem has one or more planets, in orbit about its sun.
        #
        # Options:
        # @arg -mass The mass in Earth Masses
        # @arg -distance The distance in AU
        # @arg -radius The Equatorial radius in Km
        # @arg -eccentricity Eccentricity of orbit
        # @arg -period Length of year in days
        # @par
        
        component body
        ## @privatesection The orsa body for this planet.
        deledate method * to body
        component orbit
        ## The orbit of this planet
        option -mass -default 0 -readonly yes -type {snit::double -min 0}
        option -distance -default 0 -readonly yes -type {snit::double -min 0}
        option -radius -default 0 -readonly yes -type {snit::double -min 0}
        option -eccentricity -default 0 -readonly yes -type {snit::double -min 0}
        option -period -default 0 -readonly yes -type {snit::double -min 0}
        constructor {args} {
            ## @publicsection Create a planetary body.
            #
            # @param name Name of the planetary body.
            # @param ... Options:
            # @arg -mass The mass in Earth Masses
            # @arg -distance The distance in AU
            # @arg -radius The Equatorial radius in Km
            # @arg -eccentricity Eccentricity of orbit
            # @arg -period Length of year in days
            # @par
            
            $self configurelist $args
            ## Body options
            set m [$orsa::units FromUnits_mass_unit $options(-mass) MEARTH 1]
            set r [$orsa::units FromUnits_length_unit $options(-radius) KM 1]
            install body using Body %AUTO% $self $m $r
            
            ## Orbit options
            set d [$orsa::units FromUnits_length_unit $options(-distance) AU 1]
            set p [$orsa::units FromUnits_time_unit $options(-period) DAY 1]
            
            ## Need: orbital parameters.
            set a ?
            set e $options(-eccentricity)
            set i [expr {acos(rand()*.125-0.0625)}]
            set omega_pericenter ?
            set omega_node ?
            set M ?
            set mu [expr {(4*$orsa::pisq*$a*$a*$a)/($p*$p)}]
            
            install orbit using Orbit %AUTO% \
                  -a $a\
                  -e $e \
                  -i $i \
                  -omega_pericenter $omega_pericenter \
                  -omega_node $omega_node \
                  -m_ $M \
                  -mu $mu
        }
        method update {} {
            $orbit RelativePosVel pos vel
            $self SetPosition $pos
            $self SetVelocity $vel
            return [list [$pos GetX] [$pos GetY] [$post GetY]]
        }
        typemethod namegenerator {starname} {
            namespace eval $starname {}
            return ::$starname::[planetarysystem::NameGenerator 2]
        }
    }
    
    snit::type PlanetarySystem {
        ## @brief A planetary system.
        # The object implements a planetary system, which consists of a ``sun''
        # at the origin of the coordenate system, and a collection of planets,
        # moons, asteroids, etc. in various orbits.
        #
        # Options:
        # @arg -seed STARGEN Seed to use.
        # @arg -stellarmass The Stellar mass.
        # @par
        
        typevariable STARGEN /home/heller/Deepwoods/StarshipFleet/assets/StarGenSource/stargen
        
        variable sun {}
        ## @privatesection The sun.
        variable planets -array {}
        ## The planets and their moons.
        variable object [list]
        ## Other objects
        variable StargenSeed
        ## Stargen Seed
        option -seed -default 0 -type snit::integer
        option -stellarmass -default 0.0 -type {snit::double -min 0.0}
        constructor {args} {
            ## @publicsection Construct a planetary system.
            #
            # @param name The name of the system.
            # @param ... Options:
            # @arg -seed STARGEN Seed to use.
            # @arg -stellarmass The Stellar mass.
            # @par
            
            $self configurelist $args
            if {$options(-stellarmass) == 0.0} {
                set stellarmass [expr {.8+(rand()*.4)}]
            } else {
                set stellarmass $options(-stellarmass)
            }
            if {$options(-seed) == 0} {
                set cmdline "$STARGEN -m$stellarmass -p/tmp -H -M -t -n20"
            } else {
                set cmdline "$STARGEN -s$options(-seed) -m$stellarmass -p/tmp -H -M -t -n20"
            }
            #puts stderr "*** $type create $self: stellarmass = $stellarmass"
            set genout [open "|$cmdline" r]
            regexp {seed=([[:digit:]]+)$} [gets $genout] => StargenSeed
            #puts stderr "*** $type create $self: StargenSeed = $StargenSeed"
            gets $genout;# SYSTEM  CHARACTERISTICS
            regexp {^Stellar mass:[[:space:]]+([[:digit:].]+)[[:space:]]+solar masses} [gets $genout] => sm
            regexp {^Stellar luminosity:[[:space:]]+([[:digit:].]+)$} [gets $genout] => sl
            regexp {^Age:[[:space:]]+([[:digit:].]+)[[:space:]]+billion years} [gets $genout] => sa
            regexp {^Habitable ecosphere radius: ([[:digit:].]+)[[:space:]]+AU$} [gets $genout] => hr
            
            set starname [planetarysystem::Sun namegenerator]
            set sun [planetarysystem::Sun $starname -mass $sm -luminosity $sl -age $sa -habitable $hr]
            
            #puts stderr "*** $type create $self: sm = $sm, sl = $sl, sa = $sa, hr = $hr"
            gets $genout;# 
            gets $genout;# Planets present at:
            set nplanets 0
            # n d.dd AU d.dd EM c
            while {[gets $genout line] > 0} {
                #puts stderr $line
                if {[regexp {^([[:digit:]]+)[[:space:]]+([[:digit:].]+)[[:space:]]+AU[[:space:]]+([[:digit:].]+)[[:space:]]+EM[[:space:]]+(.)$} \
                     $line => indx dist mass char] > 0} {
                    incr nplanets
                    set  planet_table($indx,dist) $dist
                    set  planet_table($indx,mass) $mass
                    set  planet_table($indx,char) $char
                } else {
                    error "Opps: planet_table regexp failed at line \{$line\}"
                }
                
            }
            #puts stderr "*** $type create $self: nplanets = $nplanets"
            for {set i 1} {$i <= $nplanets} {incr i} {
                #puts stderr "*** $type create $self: $i $planet_table($i,dist) $planet_table($i,mass) $planet_table($i,char)"
                while {[gets $genout line] == 0} {
                    #puts stderr $line
                    #skip blank lines
                }
                set checkreg [format {^Planet %d} $i]
                if {[regexp $checkreg $line] < 1} {
                    error "Opps: Planet n check failed at line \{$line\}"
                } else {
                    if {[regexp {\*gas giant\*} $line] > 0} {
                        set planets($i,gasgiant) yes
                    } else {
                        set planets($i,gasgiant) no
                    }
                }
                while {[gets $genout line] > 0} {
                    if {[regexp {^Planet is} $line] > 0} {
                        set line [gets $genout];# skip "Planet is <mumble>" line
                    }
                    if {[regexp {^[[:space:]]*Distance from primary star:[[:space:]]+([[:digit:].]+)[[:space:]]+AU} \
                         $line => distance] > 0} {
                        set planets($i,distance) $distance
                    } elseif {[regexp {^[[:space:]]*Mass:[[:space:]]+([[:digit:].]+)[[:space:]]+Earth masses} \
                               $line => mass] > 0} {
                        set planets($i,mass) $mass
                    } elseif {[regexp {^[[:space:]]*Surface gravity:[[:space:]]+([[:digit:].]+)[[:space:]]+Earth gees} \
                               $line => gravity] > 0} {
                        set planets($i,gravity) $gravity
                    } elseif {[regexp {^[[:space:]]*Surface pressure:[[:space:]]+([[:digit:].]+)[[:space:]]+Earth atmospheres} \
                               $line => pressure] > 0} {
                        set planets($i,pressure) $pressure
                        if {[regexp {GREENHOUSE EFFECT} $line] > 0} {
                            set planets($i,greenhouse) yes
                        } else {
                            set planets($i,greenhouse) no
                        }
                    } elseif {[regexp {^[[:space:]]*Surface temperature:[[:space:]]+(-?[[:digit:].]+)[[:space:]]+degrees Celcius} \
                               $line => temperature] > 0} {
                        set planets($i,temperature) $temperature
                    } elseif {[regexp {^[[:space:]]*Equatorial radius:[[:space:]]+([[:digit:].]+)[[:space:]]+Km} \
                               $line => radius] > 0} {
                        set planets($i,radius) $radius
                    } elseif {[regexp {^[[:space:]]*Density:[[:space:]]+([[:digit:].]+)[[:space:]]+grams/cc} \
                               $line => density] > 0} {
                        set planets($i,density) $density
                    } elseif {[regexp {^[[:space:]]*Eccentricity of orbit:[[:space:]]+([[:digit:].]+)$} \
                               $line => eccentricity] > 0} {
                        set planets($i,eccentricity) $eccentricity
                    } elseif {[regexp {^[[:space:]]*Escape Velocity:[[:space:]]+([[:digit:].]+)[[:space:]]+Km/sec} \
                               $line => escapevelocity] > 0} {
                        set planets($i,escapevelocity) $escapevelocity
                    } elseif {[regexp {^[[:space:]]*Molecular weight retained:[[:space:]]+([[:digit:].]+)[[:space:]]+and above} \
                               $line => molweightretained] > 0} {
                        set planets($i,molweightretained) $molweightretained
                    } elseif {[regexp {^[[:space:]]*Surface acceleration:[[:space:]]+([[:digit:].]+)[[:space:]]+cm/sec2} \
                               $line => acceleration] > 0} {
                        set planets($i,acceleration) $acceleration
                    } elseif {[regexp {^[[:space:]]*Axial tilt:[[:space:]]+(-?[[:digit:].]+)[[:space:]]+degrees} \
                               $line => tilt] > 0} {
                        set planets($i,tilt) $tilt
                    } elseif {[regexp {^[[:space:]]*Planetary albedo:[[:space:]]+([[:digit:].]+)$} \
                               $line => albedo] > 0} {
                        set planets($i,albedo) $albedo
                    } elseif {[regexp {^[[:space:]]*Length of year:[[:space:]]+([[:digit:].]+)[[:space:]]+days} \
                               $line => year] > 0} {
                        set planets($i,year) $year
                    } elseif {[regexp {^[[:space:]]*Length of day:[[:space:]]+([[:digit:].]+)[[:space:]]+hours} \
                               $line => day] > 0} {
                        set planets($i,day) $day
                    } elseif {[regexp {^[[:space:]]*Boiling point of water:[[:space:]]+(-?[[:digit:].]+)[[:space:]]+degrees Celcius} \
                               $line => waterboils] > 0} {
                        set planets($i,waterboils) $waterboils
                    } elseif {[regexp {^[[:space:]]*Hydrosphere percentage:[[:space:]]+([[:digit:].]+)$} \
                               $line => hydrosphere] > 0} {
                        set planets($i,hydrosphere) $hydrosphere
                    } elseif {[regexp {^[[:space:]]*Cloud cover percentage:[[:space:]]+([[:digit:].]+)$} \
                               $line => cloudcover] > 0} {
                        set planets($i,cloudcover) $cloudcover
                    } elseif {[regexp {^[[:space:]]*Ice cover percentage:[[:space:]]+([[:digit:].]+)$} \
                               $line => icecover] > 0} {
                        set planets($i,icecover) $icecover
                    } else {
                        puts stderr "*** Not matched: \{$line\}"
                    }
                }
                set planetname [planetarysystem::Planet namegenerator $starname]
                set planets($i,planet) [planetarysystem::Planet $planetname \
                                        -mass     planets($i,mass) \
                                        -distance planets($i,distance) \
                                        -radius   planets($i,radius) \
                                        -eccentricity planets($i,eccentricity) \
                                        -period   planets($i,year)]
                $self add $planets($i,planet)
            }
        }
        method add {object} {
            ## Add an object to the list of known objects.
            # @param object The object to add.
            
            lappend objects $object
        }
        method _updater {} {
            ## @privatesection Update everything.
            
            foreach p [array names planets] {
                $planets($p) update
            }
            foreach o $objects {
                $o update
            }
            after 100 [mymethod _updater]
        }
        
        typemethod validate {object} {
            ## Validate object as a PlantarySystem object.
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


}



namespace import planetarysystem::*

package provide PlanetarySystem 0.1


