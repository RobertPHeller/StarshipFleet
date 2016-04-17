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
#  Last Modified : <160417.1616>
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
    
    snit::enum planet_type -values {Unknown Rock Venusian Terrestrial 
        GasGiant Martian Water Ice SubGasGiant SubSubGasGiant Asteroids
        1Face}
    
    snit::type NameGenerator {
        pragma -hastypeinfo false -hastypedestroy false -hasinstances false
        typevariable default_corpus {}
        typeconstructor {
            set default_corpus { }
            foreach w {} {
                regsub -all {[^[:alpha:]]} $w {} word
                if {$word eq {}} {continue}
                set word [string tolower $word]
                append default_corpus "$word "
            }
        }
        proc rchar {{context ""} {corpus {}}} {
            if {$corpus eq ""} {set corpus $default_corpus}
            set p "${context}(.)"
            set n [expr {int(rand()*[string length $corpus])}]
            if {[regexp -start $n -indices $p $corpus n_i c_i] < 1} {
                if {[regexp -indices $p $corpus n_i c_i] < 1} {
                    return {}
                }
            }
            set rc1 [string index $corpus [lindex $c_i 0]]
            set n [lindex $n_i 0]
            incr n
            if {[regexp -start $n -indices $p $corpus n_i c_i] < 1} {
                if {[regexp -indices $p $corpus n_i c_i] < 1} {
                    return {}
                }
            }
            set rc2 [string index $corpus [lindex $c_i 0]]
            if {rand() > .5} {
                return $rc1
            } else {
                return $rc2
            }
        }
        typemethod rword {k {corpus {}}} {
            set result " "
            set c ""
            while {$c ne " "} {
                set len [string length $result]
                set s [expr {$len - $k}]
                set context [string range $result $s end]
                set c [rchar $context $corpus]
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
        typevariable starname_corpus
        ## Star name corpus.
        typeconstructor {
            set starname_corpus { }
            foreach w {Acamar Achernar Achird Acrab Akrab Elakrab Graffias 
                Acrux Acubens Adhafera Adhara Ain Aladfar Alamak Alathfar 
                Alaraph Albaldah Albali Albireo Alchiba Alcor Alcyone 
                Aldebaran Alderamin Aldhafera Aldhanab Aldhibain Aldib Fawaris
                Alfecca Meridiana Alfirk Algedi Giedi Algenib Algenib Algieba 
                Algol Algorab Alhajoth Alhena Alioth Alkaid Kurud Kalb Rai 
                Alkalurops Kaphrah Alkes Alkurah Almach Minliar Asad Nair 
                Alnasl Alnilam Alnitak Alniyat Niyat Alphard Alphecca 
                Alpheratz Alrai Alrami Alrischa Alsafi Alsciaukat Alshain 
                Alshat Altair Altais Altarf Alterf Thalimain Thalimain Aludra 
                Alula Australis Alula Borealis Alwaid Alya Alzir Ancha 
                Angetenar Ankaa Antares Arcturus Arich Arkab Armus Arneb 
                Arrakis Alrakis Elrakis Ascella Asellus Australis Asellus 
                Borealis Asellus Primus Asellus Secundus Asellus Tertius 
                Askella Aspidiske Asterion Asterope Atik Atlas Atria Auva 
                Avior Azaleh Azelfafage Azha Azmidiske Baham Baten Kaitos 
                Becrux Mimosa Beid Bellatrix Benetnasch Betelgeuse Betria 
                Biham Botein Brachium Bunda Canopus Capella Caph Castor 
                Cebalrai Celaeno Chara Chara Cheleb Chertan Chort Chow Cor 
                Caroli Cursa Dabih Decrux Deneb Deneb Algedi Deneb Dulfim 
                Deneb Okab Deneb Kaitos Deneb Kaitos Schemali Denebola Dheneb 
                Diadem Diphda Dnoces Dschubba Dubhe Duhr Edasich Electra 
                Elmuthalleth Elnath Enif Errai Etamin Eltanin Fomalhaut Fum 
                Samakah Furud Gacrux Garnet Gatria Gemma Gianfar Giedi Gienah 
                Gurab Gienah Girtab Gomeisa Gorgonea Tertia Grumium Hadar 
                Haedus Haldus Hamal Ras Hammel Hassaleh Hydrus Heka Heze 
                Hoedus Hoedus Homam Hyadum Hyadum Hydrobius Jabbah Kabdhilinan 
                Kaffaljidhma Kajam Kastra Kaus Australis Kaus Borealis Kaus 
                Media Keid Kitalpha Kochab Kornephoros Kraz Rukbah Rucbah 
                Ksora Kullat Nunu Kuma Superba Lesath Lucida Anseris Maasym
                Mahasim Maia Marfark Marfik Markab Matar Mebsuta Media Megrez 
                Meissa Mekbuda Menchib Menkab Menkalinan Menkar Menkent Menkib 
                Merak Merga Merope Mesarthim Miaplacidus Minchir Minelava 
                Minkar Mintaka Mira Mirach Miram Mirfak Mirzam Misam Mizar 
                Mothallah Muliphein Muphrid Mufrid Murzim Muscida Muscida Nair
                Saif Naos Nash Nashira Navi Nekkar Nembus Nihal Nunki Nusakan 
                Okul Peacock Phact Phad Phecda Phekda Pherkad Pherkard Pleione 
                Polaris Cynosure Polaris Australis Pollux Porrima Praecipua 
                Procyon Propus Pulcherrima Izar Rana Ras Algethi Ras Alhague 
                Ras Elased Australis Rasalas Rastaban Ras Thaoum Regor Regulus 
                Rigel Rigil Kentaurus Rijl Awwa Rotanev Ruchba Rukbat Sabik 
                Sadachbia Sadalbari Sadalmelik Sadalsuud Sadatoni Sadr Saiph 
                Salm Sargas Sarin Sarir Sceptrum Scheat Scheddi Schedir 
                Schedar Segin Seginus Sham Shaula Sheliak Sheratan Sinistra 
                Sirius Situla Skat Spica Azimech Sterope Sualocin Subra Suhail 
                Sulafat Syrma Tabit Talitha Australis Talitha Borealis Tania 
                Australis Tania Borealis Tarazet Tarazed Taygeta Tegmen 
                Tegmine Terebellum Tejat Posterior Tejat Prior Thabit Theemin 
                Beemin Thuban Tien Kwan Torcularis Septentrionalis Tureis Tyl 
                Unuk Unukalhai Vega Vindemiatrix Wasat Wazn Wezen Yed Prior 
                Yed Posterior Yildun Zaniah Zaurak Zaurac Zavijava Zosma Zuben
                Akrab Zuben Akribi Zubenelgenubi Zuben genubi Lanx Australis 
                Zubeneschamali Zuben schemali Lanx Borealis} {
                regsub -all {[^[:alpha:]]} $w {} word
                if {$word eq {}} {continue}
                set word [string tolower $word]
                append starname_corpus "$word "
            }
        }
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
        method GetBody {} {return $body}
        typemethod namegenerator {} {
            do {
                set name [string totitle [planetarysystem::NameGenerator rword 2 $starname_corpus]]
            } while {[llength [info commands ::$name]] > 0 || 
                     [namespace exists ::$name]}
            return ::$name
        }
        typemethod validate {object} {
            ## @publicsection Validate object as a PlantarySystem object.
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
    snit::type Planet {
        ## @brief A planet.
        # A PlanetarySystem has one or more planets, in orbit about its sun.
        #
        # Options:
        # @arg -mass The mass in Earth Masses.
        # @arg -distance The distance in AU.
        # @arg -radius The Equatorial radius in Km.
        # @arg -eccentricity Eccentricity of orbit.
        # @arg -period Length of year in days.
        # @arg -sun The sun.
        # @arg -ptype The type of planet.
        # @par
        
        component body
        ## @privatesection The orsa body for this planet.
        delegate method * to body
        component orbit
        ## The orbit of this planet
        #delegate option * to orbit
        option -mass -default 0 -readonly yes -type {snit::double -min 0}
        option -distance -default 0 -readonly yes -type {snit::double -min 0}
        option -radius -default 0 -readonly yes -type {snit::double -min 0}
        option -eccentricity -default 0 -readonly yes -type {snit::double -min 0}
        option -period -default 0 -readonly yes -type {snit::double -min 0}
        option -ptype -default Unknown -type planetarysystem::planet_type
        option -sun -type planetarysystem::Sun -readonly yes
        typevariable planetname_corpus
        ## Planet name corpus.
        typeconstructor {
            set planetname_corpus { }
            foreach w {AMATERASU AMPHITRITE ANAHITA AMATERASU ARACELI ARACELIS 
                ARACELY ARCELIA CAELIA CELESTE CELESTINA CELESTINE CELESTYNA 
                CELIA CELINE CHIELA CIEL CORDELIA DI DIANA DIANE DIANN DIANNA 
                DIANNE DIDI DIVINA DIJANA DYAN HEAVEN INANA INANNA KAILANI 
                KAYLA KAYLE KIANA LANI LEIA LEILANI LUCINA MAPIYA MARICELA 
                MINOO MINU NALANI NEVAEH NOELANI OKELANI OTTHILD OURANIA 
                QUIANA QUIANNA URANIA VENUS AN ANHUR ANU ARISTARCHOS 
                ARISTARCHUS BAHRAM CAELESTINUS CAELINUS CAELIUS CELESTIN 
                CELESTINO CELESTYN CELINO CELIO DASHIELL GOKER GORLASSAR 
                GORLOIS JUPITER LANGIT MAHPEE MARS MERCURY NEPTUNE ORION ORTZI 
                OSKARBI OURANOS PHOBOS PHOIBOS PLUTO RANGI SATURN SVAROG TXERU 
                URANUS ZERU CAELESTIS HANEUL IHUICATL KALANI SKY SKYE SORA 
                XIHUITL} {
                regsub -all {[^[:alpha:]]} $w {} word
                if {$word eq {}} {continue}
                set word [string tolower $word]
                append planetname_corpus "$word "
            }
        }
        constructor {args} {
            ## @publicsection Create a planetary body.
            #
            # @param name Name of the planetary body.
            # @param ... Options:
            # @arg -mass The mass in Earth Masses.
            # @arg -distance The distance in AU.
            # @arg -radius The Equatorial radius in Km.
            # @arg -eccentricity Eccentricity of orbit.
            # @arg -period Length of year in days.
            # @arg -ptype The type of planet.
            # @arg -sun The sun.
            # @par
            
            if {[lsearch $args -sun] < 0} {
                error "The -sun option is required!"
            }
            $self configurelist $args
            ## Body options
            set m [$orsa::units FromUnits_mass_unit $options(-mass) MEARTH 1]
            set r [$orsa::units FromUnits_length_unit $options(-radius) KM 1]
            install body using Body %AUTO% $self $m $r
            
            ## Orbit options
            set d [$orsa::units FromUnits_length_unit $options(-distance) AU 1]
            set p [$orsa::units FromUnits_time_unit $options(-period) DAY 1]
            
            ## Need: orbital parameters.
            set a  $d
            set e  $options(-eccentricity)
            set i  [expr {asin(rand()*.125-0.0625)}]
            set omega_pericenter [expr {asin(rand()*.25-0.125)}]
            set omega_node [expr {asin(rand()*.125-0.0625)}]
            set M  [expr {acos(rand()*2.0-1.0)*2.0}]
            set mu [expr {(4*$orsa::pisq*$a*$a*$a)/($p*$p)}]
            
            install orbit using Orbit %AUTO% \
                  -a $a \
                  -e $e \
                  -i $i \
                  -omega_pericenter $omega_pericenter \
                  -omega_node $omega_node \
                  -m_ $M \
                  -mu $mu
            $orbit RelativePosVel pos vel
            $body SetPosition $pos
            $body SetVelocity $vel

            #puts stderr [format {*** %s create %s: pos = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$pos GetX] [$pos GetY] [$pos GetZ]]
            #puts stderr [format {*** %s create %s: vel = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$vel GetX] [$vel GetY] [$vel GetZ]]
            
        }
        method GetBody {} {return $body}
        method GetOrbit {} {return $orbit}
        method update {} {
            set pos [$body position]
            set vel [$pody velocity]
            $pos += $vel
            $self SetPosition $pos
            $orbit Compute Body $body [[$self cget -sun] GetBody]
            $orbit RelativePosVel pos vel
            $body SetPosition $pos
            $body SetVelocity $vel
            return [list [$pos GetX] [$pos GetY] [$post GetY]]
        }
        typemethod namegenerator {starname} {
            namespace eval $starname {}
            do {
                set name [string totitle [planetarysystem::NameGenerator rword 2 $planetname_corpus]]
            } while {[llength [info commands ${starname}::$name]] > 0}
            return ${starname}::$name
        }
        typemethod validate {object} {
            ## @publicsection Validate object as a PlantarySystem object.
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
        
        variable sun {}
        ## @privatesection The sun.
        variable planets -array {}
        ## The planets and their moons.
        variable nplanets 0
        ## The number of nplanets.
        variable objects [list]
        ## Other objects
        typevariable STARGEN /home/heller/Deepwoods/StarshipFleet/assets/StarGenSource/stargen
        ## StarGen executable path.
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
                set $options(-stellarmass) [expr {.8+(rand()*.4)}]
            }
            if {$options(-seed) == 0} {
                set cmdline "$STARGEN -m$options(-stellarmass) -p/tmp -H -M -t -n20"
            } else {
                set cmdline "$STARGEN -s$options(-seed) -m$options(-stellarmass) -p/tmp -H -M -t -n20"
            }
            puts stderr "*** $type create $self: options(-stellarmass) = $options(-stellarmass)"
            set genout [open "|$cmdline" r]
            set line [gets $genout]
            set StargenSeed 0
            if {[regexp {seed=([[:digit:]]+)$} $line => StargenSeed] < 0} {
                error "Format error: $line, expecting seed="
            }
            set options(-seed) $StargenSeed
            puts stderr "*** $type create $self: StargenSeed = $StargenSeed"
            set line [gets $genout];# SYSTEM  CHARACTERISTICS
            puts stderr "*** $type create $self: $line"
            set line [gets $genout]
            puts stderr "*** $type create $self: $line"
            if {[regexp {^Stellar mass:[[:space:]]+([[:digit:].]+)[[:space:]]+solar masses} $line => sm] < 1} {
                set sm 0
                puts stderr "Input error (Stellar mass): $line"
            }
            set line [gets $genout]
            #puts stderr "*** $type create $self: $line"
            if {[regexp {^Stellar luminosity:[[:space:]]+([[:digit:].]+)$} $line => sl] < 1} {
                set sl 0
                puts stderr "Input error (Stellar luminosity): $line"
            }
            set line [gets $genout]
            #puts stderr "*** $type create $self: $line"
            if {[regexp {^Age:[[:space:]]+([[:digit:].]+)[[:space:]]+billion years} $line => sa] < 1} {
                set sa 0
                puts stderr "Input error (Age): $line"
            }
            set line [gets $genout]
            #puts stderr "*** $type create $self: $line"
            if {[regexp {^Habitable ecosphere radius: ([[:digit:].]+)[[:space:]]+AU$} $line => hr] < 1} {
                set hr 0
                puts stderr "Input error (Habitable ecosphere radius): $line"
            }
            
            set starname [planetarysystem::Sun namegenerator]
            set sun [planetarysystem::Sun $starname -mass $sm -luminosity $sl -age $sa -habitable $hr]
            
            #puts stderr "*** $type create $self: starname = $starname, sm = $sm, sl = $sl, sa = $sa, hr = $hr"
            puts stderr "*** $type create $self: sun = $sun"
            gets $genout;# 
            gets $genout;# Planets present at:
            set nplanets 0
            # n d.dd AU d.dd EM c
            while {[gets $genout line] > 0} {
                #puts stderr $line
                if {[regexp {^([[:digit:]]+)[[:space:]]+([[:digit:].]+)[[:space:]]+AU[[:space:]]+([[:digit:].]+)[[:space:]]+EM[[:space:]]+(.)$} \
                     $line => indx dist mass char] > 0} {
                    incr nplanets
                    set  planets($indx,dist) $dist
                    set  planets($indx,mass) $mass
                    set  planets($indx,char) $char
                    set  planets($indx,ptype) [pchar2ptype $char]
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
                        if {$planets($i,ptype) eq "GasGiant"} {
                            puts stderr "Opps: ptype wrong, fixing"
                            set planets($i,ptype) Rock
                        }
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
                if {$planets($i,gasgiant)} {
                    set u [orsa::Units %AUTO% SECOND KM MSUN]
                    set psm [$u FromUnits_mass_unit $planets($i,mass) MEARTH]
                    if {$psm < 20} {
                        set planets($i,ptype) SubGasGiant
                    }
                }
                set planetname [planetarysystem::Planet namegenerator $starname]
                puts stderr "*** $type create $self: $starname $i: planetname = $planetname"
                set planets($i,planet) [planetarysystem::Planet $planetname \
                                        -mass     $planets($i,mass) \
                                        -distance $planets($i,distance) \
                                        -radius   $planets($i,radius) \
                                        -eccentricity $planets($i,eccentricity) \
                                        -period   $planets($i,year) \
                                        -ptype    $planets($i,ptype) \
                                        -sun      $sun]
                $self add $planets($i,planet)
            }
        }
        method add {object} {
            ## Add an object to the list of known objects.
            # @param object The object to add.
            
            lappend objects $object
        }
        method GetSun {} {return $sun}
        method GetPlanet {i field} {
            if {$i < 1 || $i > $nplanets} {
                error [format {Planet index (%d) is out of range (1..%d)} \
                       $i $nplanets]
            }
            return $planets($i,$field)
        }
        method GetPlanetCount {} {return $nplanets}
        method PlanetExtents {} {
            set MinX {}
            set MaxX {}
            set MinY {}
            set MaxY {}
            set MinZ {}
            set MaxZ {}
            for {set i 1} {$i < $nplanets} {incr i} {
                set ppos [$planets($i,planet) position]
                if {$MinX eq "" || [$ppos GetX] < $MinX} {
                    set MinX [$ppos GetX]
                }
                if {$MaxX eq "" || [$ppos GetX] > $MaxX} {
                    set MaxX [$ppos GetX]
                }
                if {$MinY eq "" || [$ppos GetY] < $MinY} {
                    set MinY [$ppos GetY]
                }
                if {$MaxY eq "" || [$ppos GetY] > $MaxY} {
                    set MaxY [$ppos GetY]
                }
                if {$MinZ eq "" || [$ppos GetZ] < $MinZ} {
                    set MinZ [$ppos GetZ]
                }
                if {$MaxZ eq "" || [$ppos GetZ] > $MaxZ} {
                    set MaxZ [$ppos GetZ]
                }
            }
            return [list $MinX $MaxX $MinY $MaxY $MinZ $MaxZ]
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
        proc pchar2ptype {ch} {
            switch -exact -- "$ch" {
                O {return GasGiant}
                + {return Venusian}
                * {return Terrestrial}
                . {return Rock}
                o {return Martian}
                default {return Unknown}
            }
        }
        typemethod validate {object} {
            ## @publicsection Validate object as a PlantarySystem object.
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

    namespace export Sun Planet PlanetarySystem
}

source [file join $planetarysystem::PLANETARYSYSTEM_DIR  SystemDisplay.tcl]

namespace import planetarysystem::*

package provide PlanetarySystem 0.1


