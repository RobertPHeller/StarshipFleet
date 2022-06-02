#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sun Apr 3 08:50:05 2016
#  Last Modified : <220601.2100>
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

namespace eval orsa {
    snit::type time_unit {
        pragma -hastypeinfo false -hastypedestroy false -hasinstances false
        typevariable enums {YEAR DAY HOUR MINUTE SECOND}
        typevariable labels -array {
            YEAR y
            DAY d
            HOUR h
            MINUTE m
            SECOND s
        }
        typemethod label {tu} {
            $type validate $tu
            return $labels($tu)
        }
        typemethod validate {o} {
            if {[lsearch -exact $enums $o] < 0} {
                error [format "%s is not a %s" $o $type]
            }
            return $o
        }
        typemethod convert {tuName i} {
            upvar $tuName tu
            snit::integer validate $i
            if {$i < 1 || $i > [llength $enums]} {
                error [format "%s: conversion problem: i = %i" $type $i]
            }
            set tu [lindex $enums [expr {$i - 1}]]
        }
    }
    snit::type length_unit {
        pragma -hastypeinfo false -hastypedestroy false -hasinstances false
        typevariable enums {MPARSEC KPARSEC PARSEC LY AU EARTHMOON REARTH RMOON KM M CM}
        typevariable aliases -array {
            LD EARTHMOON
            ER REARTH
            MR RMOON
        }
        typevariable labels -array {
            MPARSEC   "Mpc"
            KPARSEC   "kpc"
            PARSECn   "pc"
            LY        "ly"
            AU        "AU"
            EARTHMOON "LD"
            REARTH    "ER"
            RMOON     "MR"
            KM        "km"
            M         "m"
            CM        "cm"
            LD        "LD"
            ER        "ER"
            MR        "MR"
        }
        typemethod validate {o} {
            if {[lsearch -exact $enums $o] < 0 &&
                [lsearch -exact [array names aliases] $o] < 0} {
                error [format "%s is not a %s" $o $type]
            }
            return $o
        }
        typemethod label {lu} {
            $type validate $lu
            return $labels($lu)
        }
        typemethod convert {luName i} {
            upvar $luName lu
            snit::integer validate $i
            if {$i < 1 || $i > [llength $enums]} {
                error [format "%s: conversion problem: i = %i" $type $i]
            }
            set lu [lindex $enums [expr {$i - 1}]]
        }
    }
    snit::type mass_unit {
        pragma -hastypeinfo false -hastypedestroy false -hasinstances false
        typevariable enums {MSUN MJUPITER MEARTH MMOON MT KG GRAM}
        typevariable labels -array {
            MSUN     "Sun mass"
            MJUPITER "Jupiter mass"
            MEARTH   "Earth mass"
            MMOON    "Moon mass"
            MT       "MTon"
            KG       "kg"
            GRAM     "g"
        }
        typemethod validate {o} {
            if {[lsearch -exact $enums $o] < 0} {
                error [format "%s is not a %s" $o $type]
            }
            return $o
        }
        typemethod label {mu} {
            $type validate $mu
            return $labels($mu)
        }
        typemethod convert {muName i} {
            upvar $muName mu
            snit::integer validate $i
            if {$i < 1 || $i > [llength $enums]} {
                error [format "%s: conversion problem: i = %i" $type $i]
            }
            set mu [lindex $enums [expr {$i - 1}]]
        }
    }
    snit::macro ::orsa::UnitBaseScale {UNIT} {
        constructor {{unit {}}} [regsub -all {%UNIT%} {
            if {$unit ne {}} {
                %UNIT% validate $unit
                set base_unit $unit
            }
        } $UNIT]
        method Set {unit} [regsub -all {%UNIT%} {
            %UNIT% validate $unit
            set base_unit $unit
        } $UNIT]
        method GetBaseUnit {} {return $base_unit}
        variable base_unit
    }
    snit::type UnitBaseScale<time_unit> {
        orsa::UnitBaseScale time_unit
    }
    snit::type UnitBaseScale<length_unit> {
        orsa::UnitBaseScale length_unit
    }
    snit::type UnitBaseScale<mass_unit> {
        orsa::UnitBaseScale mass_unit
    }
    variable        G_MKS 6.67259e-11
    variable     MSUN_MKS 1.9889e30
    variable MJUPITER_MKS 1.8989e27
    variable   MEARTH_MKS 5.9742e24
    variable    MMOON_MKS 7.3483e22
    variable       AU_MKS 1.49597870660e11
    variable        c_MKS 299792458.0
    variable  R_EARTH_MKS 6378140.0
    variable   R_MOON_MKS 1737400.0
    
    snit::type Units {
        component Time
        component Length
        component Mass
        constructor {args} {
            if {[llength $args] == 3} {
                ## Units(time_unit, length_unit, mass_unit);
                foreach {tu lu mu} $args {break}
                $self init_base
                install Time using orsa::UnitBaseScale<time_unit> %AUTO% $tu
                install Length using orsa::UnitBaseScale<length_unit> %AUTO% $lu
                install Mass using orsa::UnitBaseScale<mass_unit> %AUTO% $mu
                $self Recompute
            } elseif {[llength $args] == 0} {
                ## Units();
                $self init_base
                install Time using orsa::UnitBaseScale<time_unit> %AUTO% SECOND
                install Length using orsa::UnitBaseScale<length_unit> %AUTO% M
                install Mass using orsa::UnitBaseScale<mass_unit> %AUTO% KG
                $self Recompute
            } else {
                error [format "%s: Wrong number of arguments in constructor: %s" $type $args]
            }
        }
        method init_base {} {
            set G_base $orsa::G_MKS
            set MSun_base          $orsa::MSUN_MKS
            set MJupiter_base  $orsa::MJUPITER_MKS
            set MEarth_base      $orsa::MEARTH_MKS
            set MMoon_base        $orsa::MMOON_MKS
            set AU_base              $orsa::AU_MKS
            set c_base                $orsa::c_MKS
            set r_earth_base    $orsa::R_EARTH_MKS
            set r_moon_base      $orsa::R_MOON_MKS
        }
        method SetSystem {tu lu mu} {
            orsa::time_unit validate $tu
            orsa::length_unit validate $lu
            orsa::mass_unit validate $mu
            $Time Set $tu
            $Length Set $lu
            $Mass Set $mu
            $self Recompute
        }
        method GetG {} {return $G}
        method GetMSun {} {return $MSun}
        method GetC {} {return $c}
        method GetG_MKS {} {return $orsa::G_MKS}
        method label {uniteum} {
            if {![catch {orsa::time_unit validate $uniteum}]} {
                return [orsa::time_unit label $uniteum]
            } elseif {![catch {orsa::length_unit validate $uniteum}]} {
                return [orsa::length_unit label $uniteum]
            } elseif {![catch {orsa::mass_unit validate $uniteum}]} {
                return [orsa::mass_unit label $uniteum]
            } else {
                error [format "%s is not a known unit type" $uniteum]
            }
        }
        method TimeLabel {} {
            return [$self label [$Time GetBaseUnit]]
        }
        method LengthLabel {} {
            return [$self label [$Length GetBaseUnit]]
        }
        method MassLabel {} {
            return [$self label [$Mass GetBaseUnit]]
        }
        proc __int_pow__ {x p} {
            snit::double validate $x
            snit::integer validate $p
            if {$p == 0} {return 1.0}
            set _pow $x
            set max_k [expr {abs($p)}]
            for {set k 1} {$k < $max_k} {incr k} {
                set _pow [expr {$_pow * $x}]
            }
            if {$p < 0} {
                set _pow [expr {1.0 / $_pow}]
            }
            return $_pow
        }
        method FromUnits_time_unit {x t_in {power 1}} {
            snit::double validate $x
            orsa::time_unit validate $t_in
            snit::integer validate $power
            set scale [expr {[$self GetTimeScale $t_in] / [$self GetTimeScale]}]
            return [expr {$x * [__int_pow__ $scale $power]}]
        }
        method FromUnits_length_unit {x l_in {power 1}} {
            snit::double validate $x
            orsa::length_unit validate $l_in
            snit::integer validate $power
            set scale [expr {[$self GetLengthScale $l_in] / [$self GetLengthScale]}]
            return [expr {$x * [__int_pow__ $scale $power]}]
        }
        method FromUnits_mass_unit {x m_in {power 1}} {
            snit::double validate $x
            orsa::mass_unit validate $m_in
            snit::integer validate $power
            set scale [expr {[$self GetMassScale $m_in] / [$self GetMassScale]}]
            return [expr {$x * [__int_pow__ $scale $power]}]
        }
        method GetTimeBaseUnit {} {return [$Time GetBaseUnit]}
        method GetLengthBaseUnit {} {return [$Length GetBaseUnit]}
        method GetMassBaseUnit {} {return [$Mass GetBaseUnit]}
        method GetTimeScale {{tu {}}} {
            if {$tu eq {}} {
                set tu [$self GetTimeBaseUnit]
            }
            orsa::time_unit validate $tu
            switch $tu {
                YEAR   {return 31557600.0}
                DAY    {return 86400.0}
                HOUR   {return 3600.0}
                MINUTE {return 60.0}
                SECOND {return 1.0}
            }
        }
        method GetLengthScale {{lu {}}} {
            if {$lu eq {}} {
                set lu [$self GetLengthBaseUnit]
            }
            orsa::length_unit validate $lu
            set ls 1.0
            switch $lu {
                  MPARSEC {set ls [expr {($parsec_base*1.0e6)}]}
                  KPARSEC {set ls [expr {($parsec_base*1.0e3)}]}
                   PARSEC {set ls [expr {($parsec_base)}]}
                       LY {set ls [expr {($c_base*31557600.0)}]}
                       AU {set ls [expr {($AU_base)}]}
                EARTHMOON {set ls [expr {(3.844e8)}]}
                   REARTH {set ls [expr {($r_earth_base)}]}
                    RMOON {set ls [expr {($r_moon_base)}]}
                       KM {set ls [expr {(1000.0)}]}
                        M {set ls [expr {(1.0)}]}
                       CM {set ls [expr {(0.01)}]}
            }
            return $ls
        }
        method GetMassScale {{mu {}}} {
            if {$mu eq {}} {
                set mu [$self GetMassBaseUnit]
            }
            orsa::mass_unit validate $mu
            set ma 1.0
            switch $mu {
                MSUN     {set ms  $MSun_base}
                MJUPITER {set ms  $MJupiter_base}
                MEARTH   {set ms  $MEarth_base}
                MMOON    {set ms  $MMoon_base}
                MT       {set ms  1000.0}
                KG       {set ms  1.0}
                GRAM     {set ms  0.001}
            }
            return $ms
        }
        method Recompute {} {
            set G [expr {$G_base * [__int_pow__ [$self GetTimeScale] 2] * [__int_pow__ [$self GetLengthScale] -3] * [__int_pow__ [$self GetMassScale] 1]}]
            set MSun [expr {$MSun_base / [$self GetMassScale]}]
            set c [expr {$c_base * [$self GetTimeScale] / [$self GetLengthScale]}]
            set parsec_base [expr {$AU_base / (2*sin(($orsa::pi/180)/3600.0/2))}]
        }
        variable G
        variable G_base
        variable MSun
        variable MSun_base
        variable MJupiter_base
        variable MEarth_base
        variable MMoon_base
        variable AU_base
        variable c
        variable c_base
        variable r_earth_base
        variable r_moon_base
        variable parsec_base
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
    }
    
    variable units [orsa::Units %AUTO% SECOND KM MT]
    
    proc GetG {} {return [$orsa::units GetG]}
    proc GetG_MKS {} {return [$orsa::units GetG_MKS]}
    proc GetMSun {} {return [$orsa::units GetMSun]}
    proc GetC {} {return [$orsa::units GetC]}
    
    namespace export time_unit length_unit mass_unit UnitBaseScale<time_unit> \
          UnitBaseScale<length_unit> UnitBaseScale<mass_unit> GetG G_MKS \
          MSUN_MKS MJUPITER_MKS MEARTH_MKS MMOON_MKS AU_MKS c_MKS R_EARTH_MKS \
          R_MOON_MKS Units units units GetG_MKS GetMSun GetC
    
}
