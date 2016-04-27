#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Wed Apr 6 18:32:00 2016
#  Last Modified : <160427.1019>
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

namespace eval stargen {
    snit::enum Planet_Type -values {tUnknown tRock tVenusian tTerrestrial 
        tGasGiant tMartian tWater tIce tSubGasGiant tSubSubGasGiant tAsteroids
        t1Face}
    snit::type Gas {
        option -num -type {snit::integer -min 0} -default 0
        option -surf_pressure -type snit::double -default 0
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        constructor {args} {
            $self configurelist $args
        }
    }
    snit::type GasList {
        pragma -hastypeinfo no -hastypedestroy no -hasinstances no
        typemethod validate {o} {
            foreach g $o {
                ::stargen::Gas validate $g
            }
        }
        typemethod copy {other} {
            $type validate $other
            set result [list]
            foreach g $other {
                lappend result [::stargen::Gas copy %AUTO% $g]
            }
            return $result
        }
    }
    
    snit::type PlanetList {
        pragma -hastypeinfo no -hastypedestroy no -hasinstances no
        typemethod validate {o} {
            foreach p $o {
                ::stargen::Planets_Record validate $p
            }
        }
        typemethod copy {other {copy_all yes}} {
            $type validate $other
            set result [list]
            foreach p $other {
                lappend result [::stargen::Planets_Record copy %AUTO% $p $copy_all]
            }
            return $result
        }
    }
    snit::type Sun {
        option -luminosity -default 0.0 -type {snit::double -min 0.0}
        option -mass -default 0.0 -type {snit::double -min 0.0}
        option -life -default 0.0 -type {snit::double -min 0.0}
        option -age -default 0.0 -type {snit::double -min 0.0}
        option -r_ecosphere -default 0.0 -type {snit::double -min 0.0}
        option -name -default ""
        variable planets [list]
        
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        constructor {args} {
            $self configurelist $args
        }
        method addplanet {planet} {
            ::stargen::Planets_Record validate  $planet
            lappend planets $planet
        }
        method setplanets {_planets} {
            ::stargen::PlanetList validate $_planets
            set planets $_planets
        }
        method getplanets {} {
            return $planets
        }
        method planetcount {} {
            return [llength $planets]
        }
        destructor {
            foreach planet $planets {
                $planet destroy
            }
        }
    }
    
    snit::type SunOrNull {
        pragma -hastypeinfo no -hastypedestroy no -hasinstances no
        typemethod validate {o} {
            if {$o eq {}} {
                return $o
            } else {
                ::stargen::Sun validate $o
            }
        }
    }
    
    
    snit::type Planets_Record {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        option -planet_no -type {snit::integer -min 0} -default 0
        option -a -type {snit::double -min 0.0} -default 0.0;# semi-major axis of solar orbit (in AU)
        option -e -type {snit::double -min 0.0 -max 1.0} -default 0.0;# eccentricity of solar orbit
	option -axial_tilt -type snit::double -default 0.0;# units of degrees
	option -mass -type {snit::double -min 0.0} -default 0.0;# mass (in solar masses)
	option -gas_giant -type snit::boolean -default no;# TRUE if the planet is a gas giant
	option -dust_mass -type {snit::double -min 0.0} -default 0.0;# mass, ignoring gas
	option -gas_mass -type {snit::double -min 0.0} -default 0.0;# mass, ignoring dust
        #  ZEROES start here
	option -moon_a -type {snit::double -min 0.0} -default 0.0;# semi-major axis of lunar orbit (in AU)
	option -moon_e -type {snit::double -min 0.0 -max 1.0} -default 0.0;# eccentricity of lunar orbit
	option -core_radius -type {snit::double -min 0.0} -default 0.0;# radius of the rocky core (in km)
	option -radius -type {snit::double -min 0.0} -default 0.0;# equatorial radius (in km)
	option -orbit_zone -type snit::integer -default 0;# the 'zone' of the planet
	option -density -type {snit::double -min 0.0} -default 0.0;# density (in g/cc)
	option -orb_period -type {snit::double -min 0.0} -default 0.0;# length of the local year (days)
	option -day -type {snit::double -min 0.0} -default 0.0;# length of the local day (hours)	 */
	option -resonant_period -type snit::boolean -default no;# TRUE if in resonant rotation
	option -esc_velocity -type {snit::double -min 0.0} -default 0.0;# units of cm/sec
	option -surf_accel -type {snit::double -min 0.0} -default 0.0;# units of cm/sec2
	option -surf_grav -type {snit::double -min 0.0} -default 0.0;# units of Earth gravities
	option -rms_velocity -type {snit::double -min 0.0} -default 0.0;# units of cm/sec
	option -molec_weight -type {snit::double -min 0.0} -default 0.0;# smallest molecular weight retained
	option -volatile_gas_inventory -type snit::double -default 0.0
	option -surf_pressure -type {snit::double -min 0.0} -default 0.0;# units of millibars (mb)
	option -greenhouse_effect -type snit::boolean -default no;# runaway greenhouse effect?
	option -boil_point -type snit::double -default 0.0;# the boiling point of water (Kelvin)
	option -albedo -type {snit::double -min 0.0} -default 0.0;# albedo of the planet
	option -exospheric_temp -type {snit::double -min 0.0} -default 0.0;# units of degrees Kelvin
	option -estimated_temp -type {snit::double -min 0.0} -default 0.0;# quick non-iterative estimate (K)
	option -estimated_terr_temp -type snit::double -default 0.0;# for terrestrial moons and the like
	option -surf_temp -type {snit::double -min 0.0} -default 0.0;# surface temperature in Kelvin
	option -greenhs_rise -type {snit::double -min 0.0} -default 0.0;# Temperature rise due to greenhouse
	option -high_temp -type snit::double -default 0.0;# Day-time temperature
	option -low_temp -type snit::double -default 0.0;# Night-time temperature
	option -max_temp -type snit::double -default 0.0;# Summer/Day
	option -min_temp -type snit::double -default 0.0;# Winter/Night
	option -hydrosphere -type {snit::double -min 0.0} -default 0.0;# fraction of surface covered
	option -cloud_cover -type {snit::double -min 0.0} -default 0.0;# fraction of surface covered
	option -ice_cover -type {snit::double -min 0.0} -default 0.0;# fraction of surface covered
	option -sun -type ::stargen::SunOrNull
        variable atmosphereGases
	option -atmosphere -type ::stargen::GasList -default {} \
              -configuremethod _setatmosphereGases \
              -cgetmethod _getatmosphereGases
        method _setatmosphereGases {o v} {
            set atmosphereGases $v
        }
        method _getatmosphereGases {o} {
            if {[catch {set atmosphereGases}]} {
                set atmosphereGases [list]
            }
            return $atmosphereGases
        }
        option -gases -readonly yes -configuremethod _noset \
              -cgetmethod _gascount
        method _noset {o v} {
            error [format "%s cannot be set" $o]
        }
        method _gascount {o} {
            return [llength $atmosphereGases]
        }
	option -ptype -type ::stargen::Planet_Type -default tUnknown;# Type code
	# Zeros end here
        option -minor_moons -type snit::integer -default 0
	variable moons
        option -moons -type ::stargen::PlanetList  -default {} -readonly yes \
              -configuremethod _setmoons -cgetmethod _getmoons
        method _setmoons {o v} {
            set moons $v
        }
        method _getmoons {o} {
            if {[catch {set moons}]} {
                set moons [list]
            }
            return $moons
        }
        #planet_pointer first_moon;
        constructor {args} {
            $self configurelist $args
        }
        destructor {
            foreach moon $moons {
                $moon destroy
            }
            foreach g $atmosphereGases {
                $g destroy
            }
        }
        method addmoon {moon} {
            ::stargen::Planets_Record validate $moon
            lappend moons $moon
        }
        method consmoon {moon} {
            ::stargen::Planets_Record validate $moon
            set moons [linsert $moons 0 $moon]
        }
        typemethod copy {name other {copy_all yes}} {
            $type validate $other
            if {$copy_all} {
                return[$type create $name \
                       -planet_no [$other cget -planet_no] \
                       -a [$other cget -a] \
                       -e [$other cget -e] \
                       -axial_tilt [$other cget -axial_tilt] \
                       -mass [$other cget -mass] \
                       -gas_giant [$other cget -gas_giant] \
                       -dust_mass [$other cget -dust_mass] \
                       -gas_mass [$other cget -gas_mass] \
                       -moon_a [$other cget -moon_a] \
                       -moon_e [$other cget -moon_e] \
                       -core_radius [$other cget -core_radius] \
                       -radius [$other cget -radius] \
                       -orbit_zone [$other cget -orbit_zone] \
                       -density [$other cget -density] \
                       -orb_period [$other cget -orb_period] \
                       -day [$other cget -day] \
                       -resonant_period [$other cget -resonant_period] \
                       -esc_velocity [$other cget -esc_velocity] \
                       -surf_accel [$other cget -surf_accel] \
                       -surf_grav [$other cget -surf_grav] \
                       -rms_velocity [$other cget -rms_velocity] \
                       -molec_weight [$other cget -molec_weight] \
                       -volatile_gas_inventory [$other cget -volatile_gas_inventory] \
                       -surf_pressure [$other cget -surf_pressure] \
                       -greenhouse_effect [$other cget -greenhouse_effect] \
                       -boil_point [$other cget -boil_point] \
                       -albedo [$other cget -albedo] \
                       -exospheric_temp [$other cget -exospheric_temp] \
                       -estimated_temp [$other cget -estimated_temp] \
                       -estimated_terr_temp [$other cget -estimated_terr_temp] \
                       -surf_temp [$other cget -surf_temp] \
                       -greenhs_rise [$other cget -greenhs_rise] \
                       -high_temp [$other cget -high_temp] \
                       -low_temp [$other cget -low_temp] \
                       -max_temp [$other cget -max_temp] \
                       -min_temp [$other cget -min_temp] \
                       -hydrosphere [$other cget -hydrosphere] \
                       -cloud_cover [$other cget -cloud_cover] \
                       -ice_cover [$other cget -ice_cover] \
                       -sun [$other cget -sun] \
                       -atmosphere [::stargen::GasList copy [$other cget -atmosphere]] \
                       -ptype [$other cget -ptype] \
                       -minor_moons [$other cget -minor_moons] \
                       -moons [::stargen::PlanetList copy [$other cget -moons] $copy_all]]
            } else {
                return[$type create $name \
                       -planet_no [$other cget -planet_no] \
                       -a [$other cget -a] \
                       -e [$other cget -e] \
                       -axial_tilt [$other cget -axial_tilt] \
                       -mass [$other cget -mass] \
                       -gas_giant [$other cget -gas_giant] \
                       -dust_mass [$other cget -dust_mass] \
                       -gas_mass [$other cget -gas_mass] \
                       -minor_moons [$other cget -minor_moons] \
                       -moons [::stargen::PlanetList copy [$other cget -moons] $copy_all]]
            }
       }

    }
    snit::listtype Dustlist -type ::stargen::Dust_Record
    snit::type Dust_Record {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        option -inner_edge -type {snit::double -min 0.0} -default 0.0
        option -outer_edge -type {snit::double -min 0.0} -default 0.0
        option -dust_present -type snit::boolean -default no
        option -gas_present -type snit::boolean -default no
        constructor {args} {
            $self configurelist $args
        }
    }
    snit::type Star {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        option -luminosity -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -mass -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -m2 -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -e -default 0.0 -type {snit::double -min 0.0 -max 1.0} -readonly yes
        option -a -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -name -default ""  -readonly yes
        option -in_celestia -default false -type snit::boolean -readonly yes
        option -known_planets -default {} -type ::stargen::PlanetList -readonly yes
        constructor {args} {
            $self configurelist $args
            
        }
    }
    snit::type Catalog {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        variable arg ""
        variable stars [list]
        constructor {args} {
            set arg [from args -arg ""]
            foreach star $args {
                ::stargen::Star validate $star
                lappend stars $star
            }
        }
        method getstar {i} {
            if {$i < 0 || $i >= [llength $stars]} {
                error [format "Index (%d) out of range: 0..%d" $i [expr {[llength $stars] - 1}]]
            }
            return [lindex $stars $i]
        }
        method numstars {} {return [llength $stars]}
        method getarg {} {return $arg}
    }
    snit::type Generation {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        variable dusts
        option -dusts -default {} -type ::stargen::DustList \
              -configuremethod _setdusts -cgetmethod _getdusts
        method _setdusts {o v} {set dusts $v}
        method _getdusts {o} {
            if {[catch {set dusts}]} {
                set dusts [list]
            }
            return $dusts
        }
        variable planets
        option -planets -default {} -type ::stargen::PlanetList \
              -configuremethod _setplanets -cgetmethod _getplanets
        method _setplanets {o v} {set planets $v}
        method _getplanets {o} {
            if {[catch {set planets}]} {
                set planets [list]
            }
            return $planets
        }
        constructor {args} {
            $self configurelist $args
        }
        destructor {
            foreach d $dusts {
                $d destroy
            }
            set dusts [list]
            foreach p $planets {
                $p destroy
            }
            set planets [list]
        }
        method adddust {dust} {
            ::stargen::Dust_Record validate $dust
            lappend dusts $dust
        }
        method getdust {i} {
            if {$i < 0 || $i >= [llength $dusts]} {
                error [format "Index (%d) out of range: 0..%d" \
                       $i [expr {[llength $dusts] - 1}]]
            }
            return [lindex $dusts $i]
        }
        method dustcount {} {return [llength $dusts]}
        method addplanet {planet} {
            ::stargen::Planets_Record validate $planet
            lappend planets $planet
        }
        method getplanet {i} {
            if {$i < 0 || $i >= [llength $planets]} {
                error [format "Index (%d) out of range: 0..%d" \
                       $i [expr {[llength $planets] - 1}]]
            }
            return [lindex $planets $i]
        }
        method planetcount {} {return [llength $planets]}
    }
    snit::type ChemTable {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        option -num -type {snit::integer -min 1} -readonly yes
        option -symbol -readonly yes
        option -name -readonly yes
        option -weight -type {snit::double -min 0.0} -readonly yes
        option -melt -type snit::double -readonly yes
        option -boil -type snit::double -readonly yes
        option -density -type {snit::double -min 0.0} -readonly yes
        option -abunde -type snit::double -readonly yes
        option -abunds -type snit::double -readonly yes
        option -reactivity -type snit::double -readonly yes
        option -max_ipp -type {snit::double -min 0.0} -readonly yes
        constructor {args} {
            $self configurelist $args
        }
    }
    snit::listtype ChemTableList -type ::stargen::ChemTable
    namespace export Planet_Type Gas GasList PlanetList Sun SunOrNull \
          Planets_Record Dustlist Dust_Record Star Catalog Generation \
          ChemTable ChemTableList
}

