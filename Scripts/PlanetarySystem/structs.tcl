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
#  Last Modified : <160406.1904>
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
    snit::enum planet_type -values {tUnknown tRock tVenusian tTerrestrial 
        tGasGiant tMartian tWater tIce tSubGasGiant tSubSubGasGiant tAsteroids
        t1Face}
    snit:;type gas {
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
    }
    snit::type sun {
        option -luminosity -default 0.0 -type {snit::double -min 0.0}
        option -mass -default 0.0 -type {snit::double -min 0.0}
        option -life -default 0.0 -type {snit::double -min 0.0}
        option -age -default 0.0 -type {snit::double -min 0.0}
        option -r_ecosphere -default 0.0 -type {snit::double -min 0.0}
        option -name -default ""
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
    }
    snit::type planets_record {
        typemethod validate {o} {
            if {[catch {$o info type} ot]} {
                error [format "%s is not a %s" $o $type]
            } elseif {$ot ne $type} {
                error [format "%s is not a %s" $o $type]
            } else {
                return $o
            }
        }
        typevariable numberofplanets 0
        variable planet_no 1
        option -a -type {snit::double -min 0.0} -default 0.0;# semi-major axis of solar orbit (in AU)
        option -e -type {snit::double -min 0.0 -max 1.0} -default 0.0;# eccentricity of solar orbit
	option -axial_tilt -type snit::double -default 0.0;# units of degrees
	option -mass -type {snit::double -min 0.0} -default 0.0;# mass (in solar masses)
	option -gas_giant -type snit::boolean -default no;# TRUE if the planet is a gas giant
	option -dust_mass -type {snit::double -min 0.0} -default 0.0;# mass, ignoring gas
	option -gas_mass -type {snit::double -min 0.0} -default 0.0;# mass, ignoring dust
        #  ZEROES start here
	option -moon_a -type {snit::double -min 0.0} -default 0.0; semi-major axis of lunar orbit (in AU)
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
	option -sun -type ::stargen::sun
        option -gases -type {snit::integer -min 0} -default 0;# Count of gases in the atmosphere:
	option -atmosphere -type ::stargen::gas
	option -ptype -type ::stargen::planet_type -default tUnknown;# Type code
	option -minor_moons -type snit::integer -default 0
	#planet_pointer first_moon;
        constructor {args} {
            incr numberofplanets
            set planet_no $numberofplanets
        }
    }
}

