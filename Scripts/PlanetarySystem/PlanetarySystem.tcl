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
#  Last Modified : <181005.0846>
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
package require stargen

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
        pragma -canreplace true
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
            #puts stderr "*** $type create $self: body is $body"
            #puts stderr "*** $type create $self: body is a [$body info type]"
        }
        destructor {
            return
            set l [info level]
            while {$l >= 0} {
                puts stderr "*** $self destroy: $l: [info level $l]"
                incr l -1
            }
            puts stderr "*** $self destroy: body is $body"
            puts stderr "*** $self destroy: body is a [$body info type]"
            catch {$body destroy}
            set body {}
        }
        method GetBody {} {
            #puts stderr "*** $self GetBody: body is $body"
            #catch {puts stderr "*** $self GetBody: body is a [$body info type]"}
            return $body
        }
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
            return $filename
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
        method print {{fp stdout}} {
            puts $fp [format "%s: Mass: %g Sun Masses" [namespace tail $self] [$self cget -mass]]
            foreach orec [$self configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                puts $fp [format {%s: %s} $o $ov]
            }
            ::orsa::Body print $body
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
        pragma -canreplace true
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
        # Plus all of the options of ::orsa::OrbitWithEpoch.
        
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
        option -creationepoch -default 0 -readonly yes -type {snit::integer -min 0}
        option -parent -default {} -readonly yes
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
            if {[$m cget -refbody] ne $body} {
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
                         -refbody $body \
                         -parent $self] $args]
            lappend moons $m
        }
        method {moon count} {} {return [llength $moons]}
        method {moon get} {i} {
            if {$i < 1 || $i > [llength $moons]} {
                error [format "Moon index (%d) is out of range: 1..%d" $i [llength $moons]]
            }
            return [lindex $moons [expr {$i - 1}]]
        }
        method parent {} {
            return [$self cget -parent]
        }
        method SateliteCapture {mass absposition absvelocity} {
            set tempbody [Body create %AUTO% "" $mass 0 0]
            set temporbit [OrbitWithEpoch create %AUTO%]
            set refbody [$self cget -refbody]
            set planetPosition [$absposition - [$refbody position]]
            set planetVelocity [$absvelocity - [$refbody velocity]]
            foreach moon $moons {
                set moonBody [$moon cget -refbody]
                $tempbody SetPositon [$planetPosition - [$moonBody position]]
                $tempbody SetVelocity [$planetVelocity - [$moonBody velocity]]
                if {[$temporbit Compute Body $tempbody $moonBody $epoch] eq "escape"} {continue}
                $tempbody destroy
                $temporbit destroy
                return $moon
            }
            $tempbody destroy
            $temporbit destroy
            return {}
        }
        variable CreationM 0.0
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
            # Plus all of the options of ::orsa::OrbitWithEpoch.
            
            #puts stderr "*** $type create $self $args"
            if {[lsearch $args -sun] < 0} {
                error "The -sun option is required!"
            } else {
                set options(-sun) [from args -sun]
                planetarysystem::Sun validate $options(-sun)
            }
            #puts stderr "*** $type create $self: -sun passed and validated"
            if {[lsearch $args -refbody] < 0} {
                set options(-refbody) [$options(-sun) GetBody]
            }
            set options(-creationepoch) [from args -creationepoch]
            #puts stderr "*** $type create $self: -refbody processed: $options(-refbody)"
            set needorbit true
            ## Need: orbital parameters.
            if {[lsearch -exact $args -a] > 0 &&
                [lsearch -exact $args -e] > 0 &&
                [lsearch -exact $args -i] > 0 &&
                [lsearch -exact $args -omega_pericenter] > 0 &&
                [lsearch -exact $args -omega_node] > 0 &&
                [lsearch -exact $args -m_] > 0 &&
                [lsearch -exact $args -mu] > 0} {
                #puts stderr "*** All orbital options passed..." 
                install orbit using OrbitWithEpoch %AUTO% \
                      -a [from args -a] \
                      -e [from args -e] \
                      -i [from args -i] \
                      -omega_pericenter [from args -omega_pericenter] \
                      -omega_node [from args -omega_node] \
                      -m_ [from args -m_] \
                      -mu [from args -mu] \
                      -epoch $options(-creationepoch)
                set needorbit false
            }
            #if {!$needorbit} {
            #    puts stderr "*** $type create $self: orbit options processed, orbit is $orbit"
            #} else {
            #    puts stderr "*** $type create $self: need to generate orbit..."
            #}
            $self configurelist $args
            #puts stderr "*** $type create $self: options processed"
            ## Body options
            set m [$orsa::units FromUnits_mass_unit $options(-mass) MEARTH 1]
            set r [$orsa::units FromUnits_length_unit $options(-radius) KM 1]
            install body using Body %AUTO% $self $m $r
            #puts stderr "*** $type create $self: body installed: $body"
            
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
                
                set M  [expr {acos(rand()*2.0-1.0)*2.0}]
                #puts stderr "*** Some orbital options generated..."
                install orbit using OrbitWithEpoch %AUTO% \
                      -a $a \
                      -e $e \
                      -i $i \
                      -omega_pericenter $omega_pericenter \
                      -omega_node $omega_node \
                      -m_ $M \
                      -mu $mu \
                      -epoch $options(-creationepoch)
                #puts stderr "*** $type create $self: orbit generated, orbit is $orbit"
            }
            
            $orbit RelativePosVelAtTime pos vel $options(-creationepoch)
            set CreationM [$orbit cget -m_]
            $body SetPosition $pos
            $body SetVelocity $vel
            

            #puts stderr [format {*** %s create %s: pos = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$pos GetX] [$pos GetY] [$pos GetZ]]
            #puts stderr [format {*** %s create %s: vel = [%20.15g %20.15g %20.15g]} \
            #             $type $self [$vel GetX] [$vel GetY] [$vel GetZ]]
            
        }
        destructor {
            return
            puts stderr "*** $self destroy: body = $body, a [$body info type]"
            puts stderr "*** $self destroy: orbit = $orbit a [$orbit info type]"
            catch {$body destroy}
            catch {$orbit destroy}
            foreach m $moons {
                $m destroy
            }
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
                    set color #0000CC
                }
                Ice {
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
        method print {{fp stdout} {tabs ""}} {
            puts $fp "$tabs[format {%s: Mass: %g Earth Masses} [namespace tail $self] [$self cget -mass]]"
            foreach orec [$self configure] {
                set o [lindex $orec 0]
                set ov [lindex $orec 4]
                if {$o eq "-mass"} {continue}
                if {$o eq "-moons"} {
                    puts $fp "${tabs}-moons:"
                    foreach m $ov {
                        $m print $fp "${tabs}\t"
                    }
                } else {
                    puts $fp "$tabs[format {%s: %s} $o $ov]"
                }
            }
            ::orsa::Body print $body $fp $tabs
            $orbit print $fp $tabs
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
            return $filename
        }
        method update {epoch} {
            #puts stderr "*** $self update $epoch"
            $orbit RelativePosVelAtTime pos vel $epoch
            $pos += [[$self cget -refbody] position]
            $vel += [[$self cget -refbody] velocity]
            $body SetPosition $pos
            $body SetVelocity $vel
            #puts stderr "*** $self update: pos: \{[$pos GetX] [$pos GetY] [$pos GetY]\} val: \{[$vel GetX] [$vel GetY] [$vel GetY]\}"
            foreach m $moons {
                $m update $epoch
            }
            return [list [$pos GetX] [$pos GetY] [$pos GetY]]
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
        variable epoch 0
        ## Current epoch (timestamp)
        variable _updater_id -1
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
            #puts stderr "*** $type create $self: options processed."
            if {[$self cget -generate]} {
                $self _generate
                #puts stderr "*** $type create $self: _generate completed"
            } else {
                puts stderr "*** $type create $self: about to load [$self cget -filename]"
                $self load [$self cget -filename]
                #puts stderr "*** $type create $self: load completed"
            }
            set _updater_id [after 1000 [mymethod _updater]]
            #puts stderr "*** $type create $self: _updater_id = $_updater_id"
        }
        method _generate {} {
            if {$options(-stellarmass) == 0.0} {
                set $options(-stellarmass) [expr {.8+(rand()*.4)}]
            }
            if {$options(-seed) == 0} {
                set generatedsystem [stargen main -mass $options(-stellarmass) -habitable -moons -count 1]
            } else {
                set generatedsystem [stargen main -seed $options(-seed) -mass $options(-stellarmass) -habitable -moons -count 1]
            }
            if {[llength $generatedsystem] > 1} {
                set generatedsystem [lindex $generatedsystem 0]
            }
            set StargenSeed [$generatedsystem get_seed]
            set options(-seed) $StargenSeed
            set sm [$generatedsystem cget -mass]
            set sl [$generatedsystem cget -luminosity]
            set sa [$generatedsystem cget -age]
            set hr [$generatedsystem cget -r_ecosphere]
            
            set starname [planetarysystem::Sun namegenerator]
            set sun [planetarysystem::Sun $starname -mass $sm -luminosity $sl -age $sa -habitable $hr]
            
            set nplanets [$generatedsystem planetcount]
            for {set i 1} {$i <= $nplanets} {incr i} {
                set planet [$generatedsystem getplanet $i]
                #puts stderr "*** $self _generate: i = $i ($nplanets), planet = $planet"
                set planets($i,dist) [$planet cget -a]
                set planets($i,mass) [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}]
                set planets($i,ptype) [regsub {^t} [$planet cget -ptype] {}]
                if {[$planet cget -gas_giant]} {
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
                }
                set planets($i,distance) [$planet cget -a]
                set planets($i,mass) [expr {[$planet cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}]
                if {!$planets($i,gasgiant)} {
                    set planets($i,gravity) [$planet cget -surf_grav]
                    set planets($i,pressure) [expr {[$planet cget -surf_pressure] / 1000.0}]
                    if {[$planet cget -greenhouse_effect] &&
                        [$planet cget -surf_pressure] > 0} {
                        set planets($i,greenhouse) yes
                    } else {
                        set planets($i,greenhouse) no
                    }
                    set planets($i,temperature) [expr {[$planet cget -surf_temp] - $::stargen::FREEZING_POINT_OF_WATER}]
                    set planets($i,waterboils) [expr {[$planet cget -boil_point] - $::stargen::FREEZING_POINT_OF_WATER}]
                    set planets($i,hydrosphere) [expr {[$planet cget -hydrosphere] * 100.0}]
                    set planets($i,cloudcover) [expr {[$planet cget -cloud_cover] * 100.0}]
                    set planets($i,icecover) [expr {[$planet cget -ice_cover] * 100.0}]
                }
                set planets($i,radius) [$planet cget -radius]
                set planets($i,density) [$planet cget -density]
                set planets($i,eccentricity) [$planet cget -e]
                set planets($i,escapevelocity) [expr {[$planet cget -esc_velocity] / $::stargen::CM_PER_KM}]
                set planets($i,molweightretained) [$planet cget -molec_weight]
                set planets($i,acceleration) [$planet cget -surf_accel]
                set planets($i,tilt) [$planet cget -axial_tilt]
                set planets($i,albedo) [$planet cget -albedo]
                set planets($i,year) [$planet cget -orb_period]
                set planets($i,day) [$planet cget -day]
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
                                        -icecover  $planets($i,icecover) \
                                        -creationepoch [$self getepoch]]
                set np $planets($i,planet)
                set nmoons [$planet mooncount]
                #puts stderr "*** $self _generate: $planetname has $nmoons moons"
                for {set im 1} {$im <= $nmoons} {incr im} {
                    set moon [$planet getmoon $im]
                    set newmoonname [planetarysystem::Planet namegenerator ${starname}::[namespace tail $planetname]]
                    #puts stderr "*** $self _generate: moon $im: $newmoonname"
                    if {[$moon cget -greenhouse_effect] &&
                        [$moon cget -surf_pressure] > 0} {
                        set moongrnh yes
                    } else {
                        set moongrnh no
                    }
                    $np moon add [namespace tail $newmoonname] \
                          -mass     [expr {[$moon  cget -mass] * $::stargen::SUN_MASS_IN_EARTH_MASSES}] \
                          -distance [$moon cget -moon_a] \
                          -radius   [$moon cget -radius] \
                          -eccentricity [$moon cget -moon_e] \
                          -period   [$moon cget -orb_period] \
                          -ptype    [regsub {^t} [$moon cget -ptype] {}] \
                          -gasgiant no \
                          -gravity  [$moon cget -surf_grav] \
                          -pressure [expr {[$moon  cget -surf_pressure] / 1000.0}] \
                          -greenhouse $moongrnh \
                          -temperature [expr {[$moon cget -surf_temp] - $::stargen::FREEZING_POINT_OF_WATER}] \
                          -density [$moon cget -density] \
                          -escapevelocity [expr {[$moon cget -esc_velocity] / $::stargen::CM_PER_KM}] \
                          -molweightretained [$moon cget -molec_weight] \
                          -acceleration [$moon cget -surf_accel] \
                          -tilt [$moon cget -axial_tilt] \
                          -day  [$moon cget -day] \
                          -waterboils [expr {[$moon cget -boil_point] - $::stargen::FREEZING_POINT_OF_WATER}] \
                          -hydrosphere [expr {[$moon cget -hydrosphere] * 100.0}] \
                          -cloudcover [expr {[$moon cget -cloud_cover] * 100.0}] \
                          -icecover [expr {[$moon cget -ice_cover] * 100.0}] \
                          -creationepoch [$self getepoch]
                }

                $self add $planets($i,planet)
                #foreach m [$planets($i,planet) cget -moons] {
                #    $self add $m
                #}
                lappend planetlist $planets($i,planet)

            }
        }
        method add {object} {
            ## Add an object to the list of known objects.
            # @param object The object to add.
            
            lappend objects $object
        }
        method getepoch {} {return $epoch}
        method GetSun {} {return $sun}
        method GetPlanet {i} {
            set nplanets [$self GetPlanetCount]
            if {$i < 1 || $i > $nplanets } {
                error [format {Planet index (%d) is out of range (1..%d)} \
                       $i $nplanets]
            }
            return [lindex $planetlist [expr {$i - 1}]]
        }
        method PlanetByName {name} {
            foreach p $planetlist {
                if {[string tolower [namespace tail $name]] eq [string tolower [namespace tail $p]]} {
                    return $p
                }
            }
            return {}
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
        method GoldilocksPlanet {} {
            if {[::tcl::mathfunc::rand] < .5} {
                for p $planetlist {
                    if {[$p cget -ptype] eq "Terrestrial"} {
                        return $p
                    }
                }
                return {}
            } else {
                for {set i [expr {[llength $planetlist] - 1}]} \
                      {$i >= 0} {incr i -1} {
                    set p [lindex $planetlist $i]
                    if {[$p cget -ptype] eq "Terrestrial"} {
                        return $p
                    }
                }
                return {}
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
            return $filename
        }
        method print {{fp stdout}} {
            $sun print $fp
            foreach p $planetlist {
                $p print $fp
            }
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
                    if {$o eq "-refbody"} {continue}
                    if {$o eq "-moons"} {
                        set moons $ov
                    } else {
                        puts $ofp "\t[list $o $ov] \\"
                    }
                }
                puts $ofp "\]\}"
                if {[llength $moons] > 0} {
                    foreach m $moons {
                        puts $ofp "\{$planet moon add [namespace tail $m] \\"
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
        typemethod new {name args} {
            return [$type create $name -generate yes \
                    -seed [from args -seed 0] \
                    -stellarmass [from args -stellarmass 0.0]]
        }
        typemethod open {name args} {
            return [$type create $name -generate no \
                    -filename [from args -filename PlanetarySystem.system]]
        }
        method PlantaryCapture {mass absposition absvelocity} {
            set tempbody [Body create %AUTO% "" $mass 0 0]
            set temporbit [OrbitWithEpoch create %AUTO%]
            foreach planet $planetlist {
                set planetBody [$planet cget -refbody]
                $tempbody SetPositon [$absposition - [$planetBody position]]
                $tempbody SetVelocity [$absvelocity - [$planetBody velocity]]
                if {[$temporbit Compute Body $tempbody $planetBody $epoch] eq "escape"} {continue}
                $tempbody destroy
                $temporbit destroy
                return $planet
            }
            $tempbody destroy
            $temporbit destroy
            return {}
        }
        destructor {
            catch {after cancel $_updater_id}    
            return
            puts stderr "*** $self destroy"
            set l [info level]
            while {$l >= 0} {
                puts stderr "*** $self destroy: $l: [info level $l]"
                incr l -1
            }
            foreach p $planetlist {
                puts stderr "*** $self destroy: $p"
                $p destroy
            }
            set planetlist {}
            puts stderr "*** $self destroy: $sun"
            $sun destroy
            namespace delete $sun
            set sun {}
        }
        method _updater {} {
            ## @privatesection Update everything.
            
            #puts stderr "*** $self _updater"
            incr epoch [expr {wide([$::orsa::units FromUnits_time_unit 1 MINUTE])}]
            #puts stderr "*** $self _updater: epoch = $epoch"
            foreach p $planetlist {
                $p update $epoch
            }
            foreach o $objects {
                $o update $epoch
            }
            set _updater_id [after 1000 [mymethod _updater]]
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

namespace import planetarysystem::*

package provide PlanetarySystem 0.1


