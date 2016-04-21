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
#  Last Modified : <160421.0932>
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
package require pdf4tcl

namespace eval planetarysystem {
    variable PLANETARYSYSTEM_DIR [file dirname [info script]]

    namespace import ::orsa::*
    
    snit::enum planet_type -values {Unknown Rock Venusian Terrestrial 
        GasGiant Martian Water Ice SubGasGiant SubSubGasGiant Asteroids
        1Face}
    snit::type filename {
        typemethod validate {o} {
            return $o
        }
        option -isdirectory -default false -type snit::boolean -readonly yes
        option -exists      -default false -type snit::boolean -readonly yes
        option -readable    -default false -type snit::boolean -readonly yes
        option -writable    -default false -type snit::boolean -readonly yes
        constructor {args} {
            $self configurelist $args
        }
        method validate {o} {
            if {[$self cget -exists]} {
                if {![file exists $o]} {
                    error "$o does not exist"
                }
            }
            if {[$self cget -isdirectory]} {
                if {![file isdirectory $o]} {
                    error "$o is not a directory"
                }
            }
            if {[$self cget -readable]} {
                if {![file readable $o]} {
                    error "$o is not readable"
                }
            }
            if {[$self cget -writable]} {
                if {![file writable $o]} {
                    error "$o is not writable"
                }
            }
            return $o
        }
    }
    
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
        method SunColor {} {
            set lum [$self cget -luminosity]
            set smass [$self cget -mass]
            set yellow [expr {int(($smass * 128))}]
            set green $yellow
            set red $yellow
            set blue 0
            if {$lum < 1} {
                set green [expr {int($yellow * $lum)}]
                set red $yellow
            } elseif {$lum > 1} {
                set blue [expr {int(($lum - 1) * 64)}]
                if {$blue > 255} {set blue 255}
            }
            set color [format {#%02x%02x%02x} $red $green $blue]
            return $color
        }
        method ReportPDF {{filename {}}} {
            if {"$filename" eq ""} {
                set filename [tk_getSaveFile -defaultextension .pdf \
                              -filetypes { {{PDF Files} {.pdf} }} \
                              -initialdir [pwd] \
                              -initialfile "[namespace tail $self].pdf" \
                              -parent . \
                              -title "File to save report to"]
            }
            if {"$filename" eq ""} {return}
            set pdfobject [::pdf4tcl::new %AUTO% -file $filename \
                           -paper "letter"]
            $self PDFPage $pdfobject
            $pdfobject finish
            $pdfobject destroy
        }
        method PDFPage {pdfobject} {
            $pdfobject startPage -margin {36p 36p 72p 72p}
            $pdfobject setFillColor #000000
            $pdfobject rectangle 0 0 200p 200p -filled yes
            $pdfobject setFillColor [$self SunColor]
            $pdfobject oval 100p 100p 60p 60p -filled yes
            $pdfobject setFillColor #000000
            $pdfobject setTextPosition 250p 48p
            $pdfobject setFont 48p Times-Roman
            $pdfobject text [namespace tail $self]
            $pdfobject newLine
            $pdfobject setFont 24p Times-Roman
            $pdfobject text [format {Mass: %g Sun Masses} [$self cget -mass]]
            $pdfobject newLine
            $pdfobject setTextPosition 0 250p
            foreach orec [$self configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                $pdfobject text [format {%s: %s} $o $ov]
                $pdfobject newLine
            }
            $pdfobject endPage
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
    snit::listtype PlanetList -type ::planetarysystem::Planet
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
        # @arg -refbody The reference body.  This is the same as the sun,
        # if this is a planet.  If this is a moon, it is the body of the
        # planet this moon orbits.
        # @arg -gasgiant Flag indicating whether this is a gas giant.
        # @arg -gravity Surface gravity.
        # @arg -pressure Surface pressure.
        # @arg -greenhouse Flag indicating whether this is a runaway 
        # greenhouse planet.
        # @arg -temperature Surface temperature.
        # @arg -density Planetary density.
        # @arg -escapevelocity Escape velocity.
        # @arg -molweightretained Molecular weight retained.
        # @arg -acceleration Surface acceleration.
        # @arg -tilt Axial tilt.
        # @arg -albedo Planetary albedo.
        # @arg -day Length of day.
        # @arg -waterboils Boiling point of water.
        # @arg -hydrosphere Hydrosphere percentage.
        # @arg -cloudcover Cloud cover percentage.
        # @arg -icecover Ice cover percentage.
        # @arg -moons The moons of this planet.
        # @par
        # Plus all of the options of ::orsa::Orbit.
        
        component body
        ## @privatesection The orsa body for this planet.
        delegate method * to body
        component orbit
        ## The orbit of this planet
        delegate option * to orbit
        option -mass -default 0 -readonly yes -type {snit::double -min 0}
        option -distance -default 0 -readonly yes -type {snit::double -min 0}
        option -radius -default 0 -readonly yes -type {snit::double -min 0}
        option -eccentricity -default 0 -readonly yes -type {snit::double -min 0}
        option -period -default 0 -readonly yes -type {snit::double -min 0}
        option -ptype -default Unknown -type planetarysystem::planet_type
        option -sun -type planetarysystem::Sun -readonly yes
        option -refbody -type ::orsa::Body -readonly yes
        option -gasgiant -default false -readonly yes -type snit::boolean
        option -gravity -default 0 -readonly yes -type {snit::double -min 0}
        option -pressure -default 0 -readonly yes -type {snit::double -min 0}
        option -greenhouse -default false -readonly yes -type snit::boolean
        option -temperature -default 0 -readonly yes -type snit::double
        option -density -default 0 -readonly yes -type {snit::double -min 0}
        option -escapevelocity -default 0 -readonly yes -type {snit::double -min 0}
        option -molweightretained -default 0 -readonly yes -type {snit::double -min 0}
        option -acceleration -default 0 -readonly yes -type {snit::double -min 0}
        option -tilt -default 0 -readonly yes -type snit::double
        option -albedo -default 0 -readonly yes -type {snit::double -min 0}
        option -day -default 0 -readonly yes -type {snit::double -min 0}
        option -waterboils -default 0 -readonly yes -type snit::double
        option -hydrosphere -default 0 -readonly yes -type {snit::double -min 0 -max 100}
        option -cloudcover -default 0 -readonly yes -type {snit::double -min 0 -max 100}
        option -icecover -default 0 -readonly yes -type {snit::double -min 0 -max 100}
        option -moons -default {} -readonly yes \
              -type planetarysystem::PlanetList \
              -cgetmethod _getMoons -configuremethod _setMoons
        variable moons [list]
        ## List of moons
        method _checkmoon {m} {
            $type validate $m
            if {[$m cget -sun] ne [$self cget -sun]} {
                error [format "%s is not in the same solar system as %s!" $m $self]
            }
            if {[$m cget -refbody] ne $self} {
                error [format "%s is not one of %s's moons!" $m $self]
            }
            return $m
        }
        method _getMoons {o} {return $moons}
        method _setMoons {o v} {
            foreach m $v {
                $self _checkmoon $m
            }
            set moons $v
        }
        method {moon add} {mname args} {
            from args -sun
            from args -refbody
            set m [eval [list $type create ${self}::$mname \
                         -sun [$self cget -sun] \
                         -refbody $body] $args]
            lappend moons $m
        }
        method {moon count} {} {return [llength $moons]}
        method {moon get} {i} {
            if {$i < 1 || $i > [llength $moons]} {
                error [format "Moon index (%d) is out of range: 1..%d" $i [llength $moons]]
            }
            return [lindex $moons [expr {$i - 1}]]
        }
        
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
            # @arg -refbody The reference body.  This is the same as the sun,
            # if this is a planet.  If this is a moon, it is the body of the
            # planet this moon orbits.
            # @arg -gasgiant Flag indicating whether this is a gas giant.
            # @arg -gravity Surface gravity.
            # @arg -pressure Surface pressure.
            # @arg -greenhouse Flag indicating whether this is a runaway 
            # greenhouse planet.
            # @arg -temperature Surface temperature.
            # @arg -density Planetary density.
            # @arg -escapevelocity Escape velocity.
            # @arg -molweightretained Molecular weight retained.
            # @arg -acceleration Surface acceleration.
            # @arg -tilt Axial tilt.
            # @arg -albedo Planetary albedo.
            # @arg -day Length of day.
            # @arg -waterboils Boiling point of water.
            # @arg -hydrosphere Hydrosphere percentage.
            # @arg -cloudcover Cloud cover percentage.
            # @arg -icecover Ice cover percentage.
            # @arg -moons The list of moons.
            # @par
            # Plus all of the options of ::orsa::Orbit.
            
            if {[lsearch $args -sun] < 0} {
                error "The -sun option is required!"
            } else {
                set options(-sun) [from args -sun]
                planetarysystem::Sun validate $options(-sun)
            }
            if {[lsearch $args -refbody] < 0} {
                set options(-refbody) [$options(-sun) GetBody]
            }
            set needorbit true
            ## Need: orbital parameters.
            if {[lsearch -exact $args -a] > 0 &&
                [lsearch -exact $args -e] > 0 &&
                [lsearch -exact $args -i] > 0 &&
                [lsearch -exact $args -omega_pericenter] > 0 &&
                [lsearch -exact $args -omega_node] > 0 &&
                [lsearch -exact $args -m_] > 0 &&
                [lsearch -exact $args -mu] > 0} {
                install orbit using Orbit %AUTO% \
                      -a [from args -a] \
                      -e [from args -e] \
                      -i [from args -i] \
                      -omega_pericenter [from args -omega_pericenter] \
                      -omega_node [from args -omega_node] \
                      -m_ [from args -m_] \
                      -mu [from args -mu]
                $orbit RelativePosVel pos vel
                set needorbit false
            }
            $self configurelist $args
            ## Body options
            set m [$orsa::units FromUnits_mass_unit $options(-mass) MEARTH 1]
            set r [$orsa::units FromUnits_length_unit $options(-radius) KM 1]
            install body using Body %AUTO% $self $m $r
            
            if {$needorbit} {
                ## Orbit options
                set d [$orsa::units FromUnits_length_unit $options(-distance) AU 1]
                set p [$orsa::units FromUnits_time_unit $options(-period) DAY 1]
                
                set a  $d
                set e  $options(-eccentricity)
                set i  [expr {asin(rand()*.125-0.0625)}]
                set omega_pericenter [expr {asin(rand()*.25-0.125)}]
                set omega_node [expr {asin(rand()*.125-0.0625)}]
                set mu [expr {(4*$orsa::pisq*$a*$a*$a)/($p*$p)}]
                
                set haveGoodM false
                while {!$haveGoodM} {
                    set M  [expr {acos(rand()*2.0-1.0)*2.0}]
                    install orbit using Orbit %AUTO% \
                          -a $a \
                          -e $e \
                          -i $i \
                          -omega_pericenter $omega_pericenter \
                          -omega_node $omega_node \
                          -m_ $M \
                          -mu $mu
                    set haveGoodM [$orbit RelativePosVel pos vel]
                }
            }
            
            $body SetPosition $pos
            $body SetVelocity $vel
            

            #puts stderr [format {*** %s create %s: pos = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$pos GetX] [$pos GetY] [$pos GetZ]]
            #puts stderr [format {*** %s create %s: vel = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$vel GetX] [$vel GetY] [$vel GetZ]]
            
        }
        method GetBody {} {return $body}
        method GetOrbit {} {return $orbit}
        method PlanetColor {} {
            set color #000000
            switch [$self cget -ptype] {
                Rock {
                    set color #808080
                }
                Venusian {
                    set color #FFFFFF
                }
                Terrestrial {
                    set color #00FF00
                }
                Martian {
                    set color #FF0000
                }
                Water {
                    set color #0000FF
                }
                Water {
                    set color [format {#%02X%02X%02X} 173 216 230]
                }
                GasGiant {
                    set color [format {#%02X%02X%02X} 255 165   0]
                }
                SubGasGiant {
                    set color #0000FF
                }
                SubSubGasGiant {
                    set color [format {#%02X%02X%02X} 165  42  42]
                }
            }
            return $color
        }
        method PDFPage {pdfobject} {
            set pageheight [expr {[lindex [::pdf4tcl::getPaperSize \
                                           [$pdfobject cget -paper]] \
                                           1] - (72+72)}]
            $pdfobject startPage -margin {36p 36p 72p 72p}
            $pdfobject setFillColor #000000
            $pdfobject rectangle 0 0 200p 200p -filled yes
            $pdfobject setFillColor [$self PlanetColor]
            $pdfobject oval 100p 100p 60p 60p -filled yes
            $pdfobject setFillColor #000000
            $pdfobject setTextPosition 250p 48p
            $pdfobject setFont 48p Times-Roman
            $pdfobject text [namespace tail $self]
            $pdfobject newLine
            $pdfobject setFont 24p Times-Roman
            $pdfobject text [format {Mass: %g Earth Masses} [$self cget -mass]]
            $pdfobject newLine
            $pdfobject setTextPosition 0p 250p
            set y [expr {int($pageheight - 250)}]
            foreach orec [$self configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                $pdfobject text [format {%s: %s} $o $ov]
                $pdfobject newLine
                incr y -24
                if {$y < 24} {
                    $pdfobject startPage -margin {36p 36p 72p 72p}
                    $pdfobject setTextPosition 0 24p
                    set y [expr {int($pageheight - 24)}]
                }
            }
            $pdfobject endPage
        }
        method ReportPDF {{filename {}}} {
            if {"$filename" eq ""} {
                set filename [tk_getSaveFile -defaultextension .pdf \
                              -filetypes { {{PDF Files} {.pdf} }} \
                              -initialdir [pwd] \
                              -initialfile "[namespace tail $self].pdf" \
                              -parent . \
                              -title "File to save report to"]
            }
            if {"$filename" eq ""} {return}
            set pdfobject [::pdf4tcl::new %AUTO% -file $filename \
                           -paper "letter"]
            $self PDFPage $pdfobject
            $pdfobject finish
            $pdfobject destroy
        }
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
        # @arg -generate A boolean flag to select generation of a system.
        # @arg -filename The file asociated with this system.
        # @par
        
        variable sun {}
        ## @privatesection The sun.
        variable planetlist [list]
        ## The planets and their moons.
        variable objects [list]
        ## Other objects
        typevariable STARGEN /home/heller/Deepwoods/StarshipFleet/assets/StarGenSource/stargen
        ## StarGen executable path.
        option -seed -default 0 -type snit::integer
        option -stellarmass -default 0.0 -type {snit::double -min 0.0}
        option -generate -default true -type snit::boolean -readonly yes
        option -filename -default PlanetarySystem.system -type ::planetarysystem::filename
        constructor {args} {
            ## @publicsection Construct a planetary system.
            #
            # @param name The name of the system.
            # @param ... Options:
            # @arg -seed STARGEN Seed to use.
            # @arg -stellarmass The Stellar mass.
            # @arg -generate A boolean flag to select generation of a system.
            # @arg -filename The file asociated with this system.
            # @par
            
            #puts stderr "*** $type create $self $args"
            $self configurelist $args
            if {[$self cget -generate]} {
                $self _generate
            } else {
                $self load [$self cget -filename]
            }
        }
        method _generate {} {
            if {$options(-stellarmass) == 0.0} {
                set $options(-stellarmass) [expr {.8+(rand()*.4)}]
            }
            if {$options(-seed) == 0} {
                set cmdline "$STARGEN -m$options(-stellarmass) -p/tmp -H -M -t -n20"
            } else {
                set cmdline "$STARGEN -s$options(-seed) -m$options(-stellarmass) -p/tmp -H -M -t -n20"
            }
            #puts stderr "*** $type create $self: options(-stellarmass) = $options(-stellarmass)"
            set genout [open "|$cmdline" r]
            set line [gets $genout]
            #puts stderr "*** $type create $self: line = \{$line\}"
            set StargenSeed 0
            if {[regexp {seed=([[:digit:]]+)$} $line => StargenSeed] < 0} {
                error "Format error: $line, expecting seed="
            }
            set options(-seed) $StargenSeed
            #puts stderr "*** $type create $self: StargenSeed = $StargenSeed"
            set line [gets $genout];# SYSTEM  CHARACTERISTICS
            #puts stderr "*** $type create $self: $line"
            set line [gets $genout]
            #puts stderr "*** $type create $self: $line"
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
            #puts stderr "*** $type create $self: sun = $sun"
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
                #puts stderr "*** $type create $self: $i $planets($i,dist) $planets($i,mass) $planets($i,char)"
                while {[gets $genout line] == 0} {
                    #puts stderr $line
                    #skip blank lines
                }
                set checkreg [format {^Planet %d} $i]
                #puts stderr "*** $type create $self: line is '$line'"
                if {[regexp $checkreg $line] < 1} {
                    error "Opps: Planet n check failed at line \{$line\}"
                } else {
                    if {[regexp {\*gas giant\*} $line] > 0} {
                        set planets($i,gasgiant) yes
                        set planets($i,gravity)  INF
                        set planets($i,pressure) INF
                        set planets($i,greenhouse) no
                        set planets($i,temperature) INF
                        set planets($i,waterboils) INF
                        set planets($i,hydrosphere) 0
                        set planets($i,cloudcover) 100
                        set planets($i,icecover) 0
                    } else {
                        set planets($i,gasgiant) no
                        if {$planets($i,ptype) eq "GasGiant"} {
                            puts stderr "Opps: ptype wrong, fixing"
                            set planets($i,ptype) Rock
                        }
                    }
                }
                while {[gets $genout line] > 0} {
                    #puts stderr "*** $type create $self: line is '$line'"
                    if {[regexp {^Planet is} $line] > 0} {
                        set line [gets $genout];# skip "Planet is <mumble>" line
                    } elseif {[regexp {^Planet's rotation is in a resonant} $line] > 0} {
                        set line [gets $genout];# skip "Planet's rotation is in a resonant <mumble>" line
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
                    if {$planets($i,mass) < 20} {
                        set planets($i,ptype) SubGasGiant
                    }
                }
                set planetname [planetarysystem::Planet namegenerator $starname]
                #puts stderr "*** $type create $self: $starname $i: planetname = $planetname"
                set planets($i,planet) [planetarysystem::Planet $planetname \
                                        -mass     $planets($i,mass) \
                                        -distance $planets($i,distance) \
                                        -radius   $planets($i,radius) \
                                        -eccentricity $planets($i,eccentricity) \
                                        -period   $planets($i,year) \
                                        -ptype    $planets($i,ptype) \
                                        -sun      $sun \
                                        -gasgiant $planets($i,gasgiant) \
                                        -gravity  $planets($i,gravity) \
                                        -pressure  $planets($i,pressure) \
                                        -greenhouse  $planets($i,greenhouse) \
                                        -temperature  $planets($i,temperature) \
                                        -density  $planets($i,density) \
                                        -escapevelocity  $planets($i,escapevelocity) \
                                        -molweightretained  $planets($i,molweightretained) \
                                        -acceleration  $planets($i,acceleration) \
                                        -tilt  $planets($i,tilt) \
                                        -albedo  $planets($i,albedo) \
                                        -day  $planets($i,day) \
                                        -waterboils  $planets($i,waterboils) \
                                        -hydrosphere  $planets($i,hydrosphere) \
                                        -cloudcover  $planets($i,cloudcover) \
                                        -icecover  $planets($i,icecover)]
                $self add $planets($i,planet)
                lappend planetlist $planets($i,planet)

            }
        }
        method add {object} {
            ## Add an object to the list of known objects.
            # @param object The object to add.
            
            lappend objects $object
        }
        method GetSun {} {return $sun}
        method GetPlanet {i} {
            set nplanets [$self GetPlanetCount]
            if {$i < 1 || $i > $nplanets } {
                error [format {Planet index (%d) is out of range (1..%d)} \
                       $i $nplanets]
            }
            return [lindex $planetlist [expr {$i - 1}]]
        }
        method GetPlanetCount {} {return [llength $planetlist]}
        method PlanetExtents {} {
            set MinX {}
            set MaxX {}
            set MinY {}
            set MaxY {}
            set MinZ {}
            set MaxZ {}
            foreach p $planetlist {
                set ppos [$p position]
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
            if {$MinX eq ""} {
                return [list 0 0 0 0 0 0]
            } else {
                return [list $MinX $MaxX $MinY $MaxY $MinZ $MaxZ]
            }
        }
        method ReportPDF {{filename {}}} {
            if {"$filename" eq ""} {
                set filename [tk_getSaveFile -defaultextension .pdf \
                              -filetypes { {{PDF Files} {.pdf} }} \
                              -initialdir [pwd] \
                              -initialfile "[namespace tail $self].pdf" \
                              -parent . \
                              -title "File to save report to"]
            }
            if {"$filename" eq ""} {return}
            set pdfobject [::pdf4tcl::new %AUTO% -file $filename \
                           -paper "letter"]
            $sun PDFPage $pdfobject
            foreach p $planetlist {
                $p PDFPage $pdfobject
            }
            $pdfobject finish
            $pdfobject destroy
        }
        method save {filename} {
            if {[catch {open $filename w} ofp]} {
                error [format "Could not open %s for writing because: %s" $filename $ofp]
            }
            foreach o [array names options] {
                puts $ofp [list $o $options($o)]
            }
            puts $ofp "\{set sun \[[$sun info type] $sun \\"
            set sunopts [$sun configure]
            foreach orec $sunopts {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                puts $ofp "\t[list $o $ov] \\"
            }
            puts $ofp "\]\}"
            foreach planet $planetlist {
                puts $ofp "\{lappend planetlist \[[$planet info type] $planet \\"
                set moons {}
                foreach orec [$planet configure] {
                    set o [lindex $orec 0]
                    set ov [lindex $orec 4]
                    if {$o eq "-moons"} {
                        set moons $ov
                    } else {
                        puts $ofp "\t[list $o $ov] \\"
                    }
                }
                puts $ofp "\]\}"
                if {[llength $moons] > 0} {
                    foreach m $moons {
                        puts $ofp "\{$planet moon add $m \\"
                        foreach orec [$m configure] {
                            set o [lindex $orec 0]
                            set ov [lindex $orec 4]
                            if {$o ne "-moons" && 
                                $o ne "-refbody" && 
                                $o ne "-sun"} {
                                puts $ofp "\t[list $o $ov] \\"
                            }
                        }
                        puts $ofp "\}"
                    }
                }
            }
            close $ofp
            $self configure -filename $filename
        }
        method load {filename} {
            if {[catch {open $filename r} ifp]} {
                error [format "Could not open %s for reading because: %s" $filename $ifp]
            }
            while {[gets $ifp line] >= 0} {
                if {[regexp {^-} $line] < 1} {break}
                foreach {o v} [split $line] {break}
                set options($o) $v
            }
            set buffer $line
            while {![info complete $buffer]} {
                if {[gets $ifp line] < 0} {break}
                append buffer "\n$line"
            }
            #puts stderr "*** $self load: $buffer"
            #puts stderr "*** $self load: llength of buffer is [llength $buffer]"
            eval [lindex $buffer 0]
            #puts stderr "*** $self load: sun is $sun"
            while {![eof $ifp]} {
                set buffer [gets $ifp]
                while {![info complete $buffer]} {
                    if {[gets $ifp line] < 0} {break}
                    append buffer "\n$line"
                }
                #puts stderr "*** $self load: [lindex $buffer 0]"
                eval [lindex $buffer 0]
                #puts stderr "*** $self load: planetlist is $planetlist"
            }
            close $ifp
            $self configure -filename $filename
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

    namespace export Sun Planet PlanetList PlanetarySystem
}

source [file join $planetarysystem::PLANETARYSYSTEM_DIR  SystemDisplay.tcl]
source [file join $planetarysystem::PLANETARYSYSTEM_DIR  ObjectDetail.tcl]
source [file join $planetarysystem::PLANETARYSYSTEM_DIR  MainDisplay.tcl]

namespace import planetarysystem::*

package provide PlanetarySystem 0.1


