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
#  Last Modified : <160409.2230>
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
    snit::listtype GasList -type ::stargen::Gas
    snit::listtype Planetlist -type ::stargen::Planets_Record
    snit::type Sun {
        option -luminosity -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -mass -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -life -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -age -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -r_ecosphere -default 0.0 -type {snit::double -min 0.0} -readonly yes
        option -name -default "" -readonly yes
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
	option -sun -type ::stargen::Sun
	option -atmosphere -type ::stargen::GasList
	option -ptype -type ::stargen::Planet_Type -default tUnknown;# Type code
	option -minor_moons -type snit::integer -default 0
	variable moons [list]
        #planet_pointer first_moon;
        constructor {args} {
            $self configurelist $args
        }
        method addmoon {moon} {
            ::stargen::Planets_Record validate $moon
            lappend moons $moon
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
        option -luminosity -default 0.0 -type {snit::double -min 0.0}
        option -mass -default 0.0 -type {snit::double -min 0.0}
        option -m2 -default 0.0 -type {snit::double -min 0.0}
        option -e -default 0.0 -type {snit::double -min 0.0 -max 1.0}
        option -a -default 0.0 -type {snit::double -min 0.0}
        variable known_planets [list]
        constructor {args} {
            $self configurelist $args
        }
        method addplanet {planet} {
            ::stargen::Planets_Record validate $planet
            lappend known_planets $planet
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
        variable dusts [list]
        variable planets [list]
        constructor {args} {
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
}

