#*****************************************************************************
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Mon Apr 11 14:23:34 2016
#  Last Modified : <160422.1543>
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


namespace eval ::stargen::enviro {
    
    #define	NONE			0
    variable NONE 0
    #define	BREATHABLE		1
    variable BREATHABLE 1
    #define	UNBREATHABLE	2
    variable UNBREATHABLE 2
    #define	POISONOUS		3
    variable POISONOUS 3
    
    variable breathability_phrase [list "none" "breathable" "unbreathable" \
                                   "poisonous"]
    
    proc luminosity {mass_ratio} {
        if {$mass_ratio < 1.0} {
            set n [expr {1.75 * ($mass_ratio - 0.1) + 3.325}]
        } else {
            set n [expr {0.5 * (2.0 - $mass_ratio) + 4.4}]
        }
        return [expr {pow($mass_ratio,$n)}]
    }
    #*--------------------------------------------------------------------------*/
    #*	 This function, given the orbital radius of a planet in AU, returns		*/
    #*	 the orbital 'zone' of the particle.									*/
    #*--------------------------------------------------------------------------*/
    proc orb_zone {luminosity orb_radius} {
        if {$orb_radius < (4.0 * sqrt($luminosity))} {
            return 1
        } elseif {$orb_radius < (15.0 * sqrt($luminosity))} {
            return 2
        } else {
            return 3
        }
    }
    #*--------------------------------------------------------------------------*/
    #*	 The mass is in units of solar masses, and the density is in units		*/
    #*	 of grams/cc.  The radius returned is in units of km.					*/
    #*--------------------------------------------------------------------------*/

    proc volume_radius {mass density} {
	
	set mass [expr {$mass * $::stargen::SOLAR_MASS_IN_GRAMS}]
	set volume [expr {$mass / $density}]
	return [expr {pow((3.0 * $volume) / (4.0 * $::stargen::PI),(1.0 / 3.0)) / $::stargen::CM_PER_KM}]
    }

    #*--------------------------------------------------------------------------*/
    #*	 Returns the radius of the planet in kilometers.						*/
    #*	 The mass passed in is in units of solar masses.						*/
    #*	 This formula is listed as eq.9 in Fogg's article, although some typos	*/
    #*	 crop up in that eq.  See "The Internal Constitution of Planets", by	*/
    #*	 Dr. D. S. Kothari, Mon. Not. of the Royal Astronomical Society, vol 96 */
    #*	 pp.833-843, 1936 for the derivation.  Specifically, this is Kothari's	*/
    #*	 eq.23, which appears on page 840.										*/
    #*--------------------------------------------------------------------------*/
    
    proc kothari_radius {mass giant zone} {
	
	if {$zone == 1} {
            if {$giant} {
                set atomic_weight 9.5
                set atomic_num 4.5
            } else {
                set atomic_weight 15.0
                set atomic_num 8.0
            }
	} elseif {$zone == 2} {
            if {giant} {
                set atomic_weight 2.47
                set atomic_num 2.0
            } else {
                set atomic_weight 10.0
                set atomic_num 5.0
            }
        } else {
            if {$giant} {
                set atomic_weight 7.0
                set atomic_num 4.0
            } else {
                set atomic_weight 10.0
                set atomic_num 5.0
            }
        }
	
	set temp1 [expr {$atomic_weight * $atomic_num}]
	
	set temp [expr {(2.0 * $::stargen::BETA_20 * pow($::stargen::SOLAR_MASS_IN_GRAMS,(1.0 / 3.0))) \
                  / ($::stargen::A1_20 * pow($temp1, (1.0 / 3.0)))}]
	
	set temp2 [expr {$::stargen::A2_20 * pow($atomic_weight,(4.0 / 3.0)) * pow($::stargen::SOLAR_MASS_IN_GRAMS,(2.0 / 3.0))}]
	set temp2 [expr {$temp2 * pow($mass,(2.0 / 3.0))}]
	set temp2 [expr {$temp2 / ($::stargen::A1_20 * pow2($atomic_num))}]
	set temp2 [expr {1.0 + $temp2}]
	set temp [expr {$temp / $temp2}]
	set temp [expr { ($temp * pow($mass,(1.0 / 3.0))) / $::stargen::CM_PER_KM}]
	
	set temp [expr {$temp / $::stargen::JIMS_FUDGE}];			#* Make Earth = actual earth */
	
	return $temp
    }
    
    
    #*--------------------------------------------------------------------------*/
    #*	The mass passed in is in units of solar masses, and the orbital radius	*/
    #*	is in units of AU.	The density is returned in units of grams/cc.		*/
    #*--------------------------------------------------------------------------*/
    
    proc empirical_density {mass orb_radius r_ecosphere gas_giant} {
	
	set temp [expr {pow($mass * $::stargen::SUN_MASS_IN_EARTH_MASSES,(1.0 / 8.0));
	set temp [expr {$temp * pow1_4($r_ecosphere / $orb_radius);
	if {$gas_giant} {
            return [expr {$temp * 1.2}]
	} else {
            return [expr {$temp * 5.5}]
        }
    }

    
    #*--------------------------------------------------------------------------*/
    #*	The mass passed in is in units of solar masses, and the equatorial		*/
    #*	radius is in km.  The density is returned in units of grams/cc.			*/
    #*--------------------------------------------------------------------------*/
    
    proc volume_density {mass equat_radius} {
	
	set mass [expr {$mass * $::stargen::SOLAR_MASS_IN_GRAMS}]
	set equat_radius [expr {$equat_radius * $::stargen::CM_PER_KM}]
	set volume [expr {(4.0 * $::stargen::PI * pow3($equat_radius)) / 3.0}]
	return [expr {$mass / $volume}]
    }
    
    
    #*--------------------------------------------------------------------------*/
    #*	The separation is in units of AU, and both masses are in units of solar */
    #*	masses.	 The period returned is in terms of Earth days.					*/
    #*--------------------------------------------------------------------------*/
    
    proc period {separation small_mass large_mass} {
	long double period_in_years; 
	
	set period_in_years [expr {sqrt(pow3($separation) / ($small_mass + $large_mass))}]
	return [expr {$period_in_years * $::stargen::DAYS_IN_A_YEAR}]
    }
    
    
    #*--------------------------------------------------------------------------*/
    #*	 Fogg's information for this routine came from Dole "Habitable Planets	*/
    #* for Man", Blaisdell Publishing Company, NY, 1964.  From this, he came	*/
    #* up with his eq.12, which is the equation for the 'base_angular_velocity' */
    #* below.  He then used an equation for the change in angular velocity per	*/
    #* time (dw/dt) from P. Goldreich and S. Soter's paper "Q in the Solar		*/
    #* System" in Icarus, vol 5, pp.375-389 (1966).	 Using as a comparison the	*/
    #* change in angular velocity for the Earth, Fogg has come up with an		*/
    #* approximation for our new planet (his eq.13) and take that into account. */
    #* This is used to find 'change_in_angular_velocity' below.					*/
    #*																			*/
    #*	 Input parameters are mass (in solar masses), radius (in Km), orbital	*/
    #* period (in days), orbital radius (in AU), density (in g/cc),				*/
    #* eccentricity, and whether it is a gas giant or not.						*/
    #*	 The length of the day is returned in units of hours.					*/
    #*--------------------------------------------------------------------------*/
    
    proc day_length {planet} {
        
	set planetary_mass_in_grams [expr {[$planet cget -mass] * $::stargen::SOLAR_MASS_IN_GRAMS}]
	set equatorial_radius_in_cm [expr {[$planet cget -radius] * $::stargen::CM_PER_KM}]
	set year_in_hours [expr {[$planet cget -orb_period] * 24.0}]
	set giant [expr {[$planet cget -ptype] eq "tGasGiant" || \
                   [$planet cget -ptype] eq "tSubGasGiant" || \
                   [$planet cget -ptype] eq "tSubSubGasGiant"}];
        
	set stopped false
        
	$planet configure -resonant_period false;	#* Warning: Modify the planet */
        
	if {$giant} {
            set k2 0.24
	} else { 
            set k2 0.33
        }
        
	set base_angular_velocity [expr {sqrt(2.0 * $::stargen::J * ($planetary_mass_in_grams) / \
                                              ($k2 * pow2($equatorial_radius_in_cm)))}]
        
        #*	This next calculation determines how much the planet's rotation is	 */
        #*	slowed by the presence of the star.								 */
        
	set change_in_angular_velocity [expr {$::stargen::CHANGE_IN_EARTH_ANG_VEL * \
                                        ([$planet cget -density] / $::stargen::EARTH_DENSITY) * \
                                        ($equatorial_radius_in_cm / $::stargen::EARTH_RADIUS) * \
                                        ($::stargen::EARTH_MASS_IN_GRAMS / $planetary_mass_in_grams) * \
                                        pow([[$planet cget -sun] cget -mass], 2.0) * \
                                        (1.0 / pow([$planet cget -a], 6.0))}]
	set ang_velocity [expr {$base_angular_velocity + ($change_in_angular_velocity * \ 
                                                          [[$planet cget -sun] cget -age])}]
        
        #* Now we change from rad/sec to hours/rotation.						 */
        
	if {$ang_velocity <= 0.0} {
            set stopped true
            set day_in_hours $::stargen::INCREDIBLY_LARGE_NUMBER 
	} else {
            set day_in_hours [expr {$::stargen::RADIANS_PER_ROTATION / ($::stargen::SECONDS_PER_HOUR * $ang_velocity)}]
        }
        
	if {($day_in_hours >= $year_in_hours) || $stopped} {
            if {[$planet cget -e] > 0.1} {
                set spin_resonance_factor [expr { (1.0 - [$planet cget -e]) / (1.0 + [$planet cget -e])}]
                $planet configure -resonant_period true
                return [expr {$spin_resonance_factor * $year_in_hours}]
            } else {
                return $year_in_hours
            }
	}
        
	return $day_in_hours
    }
    

    #*--------------------------------------------------------------------------*/
    #*	 The orbital radius is expected in units of Astronomical Units (AU).	*/
    #*	 Inclination is returned in units of degrees.							*/
    #*--------------------------------------------------------------------------*/

    proc inclination {orb_radius} {
	
	set temp [expr {int(pow($orb_radius,0.2) * about($::stargen::EARTH_AXIAL_TILT,0.4))}]
	return [expr {$temp % 360}]
    }


    #*--------------------------------------------------------------------------*/
    #*	 This function implements the escape velocity calculation.	Note that	*/
    #*	it appears that Fogg's eq.15 is incorrect.								*/
    #*	The mass is in units of solar mass, the radius in kilometers, and the	*/
    #*	velocity returned is in cm/sec.											*/
    #*--------------------------------------------------------------------------*/
    
    proc escape_vel {mass radius} {
	
	set mass_in_grams [expr {$mass * $::stargen::SOLAR_MASS_IN_GRAMS}]
	set radius_in_cm [expr {$radius * $::stargen::CM_PER_KM}]
	return [expr {(sqrt(2.0 * $::stargen::GRAV_CONSTANT * $mass_in_grams / $radius_in_cm))}]
    }


    #*--------------------------------------------------------------------------*/
    #*	This is Fogg's eq.16.  The molecular weight (usually assumed to be N2)	*/
    #*	is used as the basis of the Root Mean Square (RMS) velocity of the		*/
    #*	molecule or atom.  The velocity returned is in cm/sec.					*/
    #*	Orbital radius is in A.U.(ie: in units of the earth's orbital radius).	*/
    #*--------------------------------------------------------------------------*/

    proc rms_vel {molecular_weight exospheric_temp} {
	return [expr {sqrt((3.0 * $::stargen::MOLAR_GAS_CONST * $exospheric_temp) / $molecular_weight) \
                * $::stargen::CM_PER_METER}]
    }
    
    
    #*--------------------------------------------------------------------------*/
    #*	 This function returns the smallest molecular weight retained by the	*/
    #*	body, which is useful for determining the atmosphere composition.		*/
    #*	Mass is in units of solar masses, and equatorial radius is in units of	*/
    #*	kilometers.																*/
    #*--------------------------------------------------------------------------*/
    
    proc molecule_limit {mass equat_radius exospheric_temp} {
	set esc_velocity [escape_vel $mass $equat_radius]
	
	return [expr {(3.0 * $::stargen::MOLAR_GAS_CONST * $exospheric_temp) / \
                (pow2(($esc_velocity/ $::stargen::GAS_RETENTION_THRESHOLD) / $::stargen::CM_PER_METER))}]
        
    }
    
    #*--------------------------------------------------------------------------*/
    #*	 This function calculates the surface acceleration of a planet.	 The	*/
    #*	mass is in units of solar masses, the radius in terms of km, and the	*/
    #*	acceleration is returned in units of cm/sec2.							*/
    #*--------------------------------------------------------------------------*/
    
    proc acceleration {mass radius} {
	return [expr {($::stargen::GRAV_CONSTANT * ($mass * $::stargen::SOLAR_MASS_IN_GRAMS) / \
                       pow2($radius * $::stargen::CM_PER_KM))}]
    }


    #*--------------------------------------------------------------------------*/
    #*	 This function calculates the surface gravity of a planet.	The			*/
    #*	acceleration is in units of cm/sec2, and the gravity is returned in		*/
    #*	units of Earth gravities.												*/
    #*--------------------------------------------------------------------------*/
    
    proc gravity {acceleration} {
	return [expr {($acceleration / $::stargen::EARTH_ACCELERATION)}]
    }

    #*--------------------------------------------------------------------------*/
    #*	This implements Fogg's eq.17.  The 'inventory' returned is unitless.	*/
    #*--------------------------------------------------------------------------*/

    proc vol_inventory {mass escape_vel rms_vel stellar_mass zone 
        greenhouse_effect accreted_gas} {
	
	
	set velocity_ratio [expr {$escape_vel / $rms_vel}]
	if {$velocity_ratio >= $::stargen::GAS_RETENTION_THRESHOLD} {
            switch $zone {
                1 {
                    set proportion_const 140000.0;	#* 100 -> 140 JLB */
                }
                2 {
                    set proportion_const 75000.0
                }
                3 {
                    set proportion_const 250.0
                }
                default {
                    set proportion_const 0.0
                    puts "Error: orbital zone not initialized correctly!"
                }
            }
            set earth_units [expr {$mass * $::stargen::SUN_MASS_IN_EARTH_MASSES}]
            set temp1 [expr {($proportion_const * $earth_units) / $stellar_mass}]
            set temp2 [expr {about($temp1,0.2)}]
            set temp2 $temp1
            if {$greenhouse_effect || $accreted_gas} {
                return $temp2
            } else {
                return [expr {$temp2 / 140.0}];	#* 100 -> 140 JLB */
            }
        } else {
            return 0.0
        }
    }
            
            
    #*--------------------------------------------------------------------------*/
    #*	This implements Fogg's eq.18.  The pressure returned is in units of		*/
    #*	millibars (mb).	 The gravity is in units of Earth gravities, the radius */
    #*	in units of kilometers.													*/
    #*																			*/
    #*  JLB: Aparently this assumed that earth pressure = 1000mb. I've added a	*/
    #*	fudge factor (EARTH_SURF_PRES_IN_MILLIBARS / 1000.) to correct for that	*/
    #*--------------------------------------------------------------------------*/

    proc pressure {volatile_gas_inventory equat_radius gravity} {
        set equat_radius [expr {$::stargen::KM_EARTH_RADIUS / $equat_radius}]
        return [expr {$volatile_gas_inventory * $gravity * \
                ($::stargen::EARTH_SURF_PRES_IN_MILLIBARS / 1000.) / \
                pow2($equat_radius)}]
    }

    #*--------------------------------------------------------------------------*/
    #*	 This function returns the boiling point of water in an atmosphere of	*/
    #*	 pressure 'surf_pressure', given in millibars.	The boiling point is	*/
    #*	 returned in units of Kelvin.  This is Fogg's eq.21.					*/
    #*--------------------------------------------------------------------------*/
    
    proc boiling_point {surf_pressure} {
       
	set surface_pressure_in_bars [expr {$surf_pressure / $::stargen::MILLIBARS_PER_BAR}]
	return [expr {(1.0 / ((log($surface_pressure_in_bars) / -5050.5) + \
                              (1.0 / 373.0) ))}]
	
    }


    #*--------------------------------------------------------------------------*/
    #*	 This function is Fogg's eq.22.	 Given the volatile gas inventory and	*/
    #*	 planetary radius of a planet (in Km), this function returns the		*/
    #*	 fraction of the planet covered with water.								*/
    #*	 I have changed the function very slightly:	 the fraction of Earth's	*/
    #*	 surface covered by water is 71%, not 75% as Fogg used.					*/
    #*--------------------------------------------------------------------------*/
    
    proc hydro_fraction {volatile_gas_inventory planet_radius} {
        
        set temp [expr {(0.71 * $volatile_gas_inventory / 1000.0) \
                  * pow2($::stargen::KM_EARTH_RADIUS / $planet_radius)}]
        if {temp >= 1.0} {
            return 1.0
        } else {
            return $temp
        }
    }


    #*--------------------------------------------------------------------------*/
    #*	 Given the surface temperature of a planet (in Kelvin), this function	*/
    #*	 returns the fraction of cloud cover available.	 This is Fogg's eq.23.	*/
    #*	 See Hart in "Icarus" (vol 33, pp23 - 39, 1978) for an explanation.		*/
    #*	 This equation is Hart's eq.3.											*/
    #*	 I have modified it slightly using constants and relationships from		*/
    #*	 Glass's book "Introduction to Planetary Geology", p.46.				*/
    #*	 The 'CLOUD_COVERAGE_FACTOR' is the amount of surface area on Earth		*/
    #*	 covered by one Kg. of cloud.											*/
    #*--------------------------------------------------------------------------*/

    proc cloud_fraction {surf_temp smallest_MW_retained equat_radius hydro_fraction} {

	if {$smallest_MW_retained > $::stargen::WATER_VAPOR} {
            return 0.0
	} else {
            set surf_area [expr {4.0 * $::stargen::PI * pow2($equat_radius)}]
            set hydro_mass [expr {$hydro_fraction * $surf_area * $::stargen::EARTH_WATER_MASS_PER_AREA}]
            set water_vapor_in_kg [expr {(0.00000001 * hydro_mass) * \
                                   exp($::stargen::Q2_36 * ($surf_temp - $::stargen::EARTH_AVERAGE_KELVIN))}]
            set fraction [expr {$::stargen::CLOUD_COVERAGE_FACTOR * $water_vapor_in_kg / $surf_area}]
            if {$fraction >= 1.0} {
                return 1.0
            } else {
                return $fraction
            }
	}
    }


    #*--------------------------------------------------------------------------*/
    #*	 Given the surface temperature of a planet (in Kelvin), this function	*/
    #*	 returns the fraction of the planet's surface covered by ice.  This is	*/
    #*	 Fogg's eq.24.	See Hart[24] in Icarus vol.33, p.28 for an explanation. */
    #*	 I have changed a constant from 70 to 90 in order to bring it more in	*/
    #*	 line with the fraction of the Earth's surface covered with ice, which	*/
    #*	 is approximatly .016 (=1.6%).											*/
    #*--------------------------------------------------------------------------*/

    proc ice_fraction {hydro_fraction surf_temp} {
	
	if {$surf_temp > 328.0} {
            set surf_temp 328.0
        }
	set temp [expr {pow(((328.0 - $surf_temp) / 90.0), 5.0)}]
	if {$temp > (1.5 * $hydro_fraction)} {
            set temp [expr {(1.5 * $hydro_fraction)}]
        }
        if {$temp >= 1.0} {
            return 1.0
	} else {
            return $temp
        }
    }


    #*--------------------------------------------------------------------------*/
    #*	This is Fogg's eq.19.  The ecosphere radius is given in AU, the orbital */
    #*	radius in AU, and the temperature returned is in Kelvin.				*/
    #*--------------------------------------------------------------------------*/

    proc eff_temp {ecosphere_radius orb_radius albedo} {
	return [expr {(sqrt($ecosphere_radius / $orb_radius) \
                       * pow1_4((1.0 - $albedo) / (1.0 - $::stargen::EARTH_ALBEDO)) \
                       * $::stargen::EARTH_EFFECTIVE_TEMP)}]
    }


    proc est_temp {ecosphere_radius orb_radius albedo} {
	return [expr{(sqrt($ecosphere_radius / $orb_radius) \
		  * pow1_4((1.0 - $albedo) / (1.0 - $::stargen::EARTH_ALBEDO)) \
		  * $::stargen::EARTH_AVERAGE_KELVIN)}]
    }


    #*--------------------------------------------------------------------------*/
    #* Old grnhouse:                                                            */
    #*	Note that if the orbital radius of the planet is greater than or equal	*/
    #*	to R_inner, 99% of it's volatiles are assumed to have been deposited in */
    #*	surface reservoirs (otherwise, it suffers from the greenhouse effect).	*/
    #*--------------------------------------------------------------------------*/
    #*	if ((orb_radius < r_greenhouse) && (zone == 1)) */
    
    #*--------------------------------------------------------------------------*/
    #*	The new definition is based on the inital surface temperature and what	*/
    #*	state water is in. If it's too hot, the water will never condense out	*/
    #*	of the atmosphere, rain down and form an ocean. The albedo used here	*/
    #*	was chosen so that the boundary is about the same as the old method		*/
    #*	Neither zone, nor r_greenhouse are used in this version				JLB	*/
    #*--------------------------------------------------------------------------*/

    proc grnhouse {r_ecosphere orb_radius} {
	set temp [eff_temp $r_ecosphere $orb_radius $::stargen::GREENHOUSE_TRIGGER_ALBEDO]
	
	if {$temp > $::stargen::FREEZING_POINT_OF_WATER} {
            return true
	} else {
            return false
        }
    }


    #*--------------------------------------------------------------------------*/
    #*	This is Fogg's eq.20, and is also Hart's eq.20 in his "Evolution of		*/
    #*	Earth's Atmosphere" article.  The effective temperature given is in		*/
    #*	units of Kelvin, as is the rise in temperature produced by the			*/
    #*	greenhouse effect, which is returned.									*/
    #*	I tuned this by changing a pow(x,.25) to pow(x,.4) to match Venus - JLB	*/
    #*--------------------------------------------------------------------------*/

    proc green_rise {optical_depth effective_temp surf_pressure} {
	set convection_factor [expr {$::stargen::EARTH_CONVECTION_FACTOR * \
                               pow($surf_pressure / \
                                   $::stargen::EARTH_SURF_PRES_IN_MILLIBARS, 0.4)}]
	set rise [expr {(pow1_4(1.0 + 0.75 * $optical_depth) - 1.0) * \
                  $effective_temp * $convection_factor}]
	
	if {$rise < 0.0} {set rise 0.0}
	
	return $rise;
    }


    #*--------------------------------------------------------------------------*/
    #*	 The surface temperature passed in is in units of Kelvin.				*/
    #*	 The cloud adjustment is the fraction of cloud cover obscuring each		*/
    #*	 of the three major components of albedo that lie below the clouds.		*/
    #*--------------------------------------------------------------------------*/

    proc planet_albedo {water_fraction cloud_fraction ice_fraction surf_pressure} {
	
	set rock_fraction [expr {1.0 - $water_fraction - $ice_fraction}]
	set components 0.0
	if {$water_fraction > 0.0} {
            set components [expr {$components + 1.0}]
	}
        if {$ice_fraction > 0.0} {
            set components [expr {$components + 1.0}]
        }
        if {$rock_fraction > 0.0} {
            set components [expr {$components + 1.0}]
        }
	
	set cloud_adjustment [expr {$cloud_fraction / $components}]
	
	if {$rock_fraction >= $cloud_adjustment} {
            set rock_fraction [expr {$rock_fraction - $cloud_adjustment}]
	} else {
            set rock_fraction 0.0
	}
	if {$water_fraction > $cloud_adjustment} {
            set water_fraction [expr {$water_fraction - $cloud_adjustment}]
	} else {
            set water_fraction 0.0
        }
	if {$ice_fraction > $cloud_adjustment} {
            set ice_fraction [expr {$ice_fraction - $cloud_adjustment}]
	} else {
            set ice_fraction 0.0
        }
	set cloud_part [expr {$cloud_fraction * $::stargen::CLOUD_ALBEDO}];		#* about(...,0.2); */
	
	if {$surf_pressure == 0.0} {
	{
            set rock_part [expr {$rock_fraction * $::stargen::ROCKY_AIRLESS_ALBEDO}];	#* about(...,0.3); */
            set ice_part [expr {$ice_fraction * $::stargen::AIRLESS_ICE_ALBEDO}];		#* about(...,0.4); */
            set water_part 0
	} else {
            set rock_part [expr {$rock_fraction * $::stargen::ROCKY_ALBEDO}];	#* about(...,0.1); */
            set water_part [expr {$water_fraction * $::stargen::WATER_ALBEDO}];	#* about(...,0.2); */
            set ice_part [expr {$ice_fraction * $::stargen::ICE_ALBEDO}];		#* about(...,0.1); */
	}

	return [expr {($cloud_part + $rock_part + $water_part + $ice_part)}]
    }


    #*--------------------------------------------------------------------------*/
    #*	 This function returns the dimensionless quantity of optical depth,		*/
    #*	 which is useful in determining the amount of greenhouse effect on a	*/
    #*	 planet.																*/
    #*--------------------------------------------------------------------------*/

    proc opacity {molecular_weight surf_pressure} {
	
	set optical_depth 0.0
	if {($molecular_weight >= 0.0) && ($molecular_weight < 10.0)} {
            set optical_depth [expr {$optical_depth + 3.0}]
        }
	if {($molecular_weight >= 10.0) && ($molecular_weight < 20.0)} {
            set optical_depth [expr {$optical_depth + 2.34}]
        }
	if {($molecular_weight >= 20.0) && ($molecular_weight < 30.0)} {
            set optical_depth [expr {$optical_depth + 1.0}]
        }
	if {($molecular_weight >= 30.0) && ($molecular_weight < 45.0)} {
            set optical_depth [expr {$optical_depth + 0.15}]
        }
	if {($molecular_weight >= 45.0) && ($molecular_weight < 100.0)} {
            set optical_depth [expr {$optical_depth + 0.05}]
        }

	if {$surf_pressure >= (70.0 * $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)} {
            set optical_depth [expr {$optical_depth * 8.333}]
        } else {
            if {$surf_pressure >= (50.0 * $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)} {
                set optical_depth [expr {$optical_depth * 6.666}]
            } else { 
                if {$surf_pressure >= (30.0 * $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)} {
                    set optical_depth [expr {optical_depth * 3.333}]
                } else {
                    if {$surf_pressure >= (10.0 * $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)} {
                        set optical_depth [expr {$optical_depth * 2.0}]
                    } else {
                        if {$surf_pressure >= (5.0 * $::stargen::EARTH_SURF_PRES_IN_MILLIBARS)} {
                            set optical_depth [expr {$optical_depth * 1.5}]
                        }
                    }
                }
            }
        }
        

	return $optical_depth
    }


    #*
    #*	calculates the number of years it takes for 1/e of a gas to escape
    #*	from a planet's atmosphere. 
    #*	Taken from Dole p. 34. He cites Jeans (1916) & Jones (1923)
    #*
    proc gas_life {molecular_weight planet} {
	
        set v [rms_vel $molecular_weight [$planet cget -exospheric_temp]]
	set g [expr {[$planet cget -surf_grav] * $::stargen::EARTH_ACCELERATION}]
	set r [expr {[$planet cget -radius] * $::stargen::CM_PER_KM}]
	set t [expr {(pow3($v) / (2.0 * pow2($g) * $r)) * exp((3.0 * $g * $r) / pow2($v))}]
	set years [expr {$t / ($::stargen::SECONDS_PER_HOUR * 24.0 * $::stargen::DAYS_IN_A_YEAR)}]
	
        #//	long double ve = planet->esc_velocity;
        #//	long double k = 2;
        #//	long double t2 = ((k * pow3(v) * r) / pow4(ve)) * exp((3.0 * pow2(ve)) / (2.0 * pow2(v)));
        #//	long double years2 = t2 / (SECONDS_PER_HOUR * 24.0 * DAYS_IN_A_YEAR);
		
        #//	if (flag_verbose & 0x0040)
        #//		fprintf (stderr, "gas_life: %LGs, V ratio: %Lf\n", 
        #//				years, ve / v);

	if {$years > 2.0E10} {
            set years $::stargen::INCREDIBLY_LARGE_NUMBER
        }
		
	return $years
    }

    proc  min_molec_weight {planet} {
	set mass [$planet cget -mass]
	set radius [$planet cget -radius]
	set temp [$planet cget -exospheric_temp]
	set target 5.0E9
	
	set guess_1 [molecule_limit $mass $radius $temp]
	set guess_2 $guess_1
	
	set life [gas_life $guess_1 $planet]
	
	set loops 0
	
	if {[cget $planet cget -sun] ne {}} {
		set target [[$planet cget -sun] cget -age]
	}

	if {$life > $target} {
            while {($life > $target) && ([incr loops] <= 25)} {
                set guess_1 [expr {$guess_1 / 2.0}]
                set life [gas_life $guess_1 $planet]
            }
	} else {
            while {($life < $target) && ([incr loops] <= 25)} {
                set guess_2 [expr {$guess_2 * 2.0}]
                set life [gas_life $guess_2 $planet]
            }
	}

	set loops 0

	while {(($guess_2 - $guess_1) > 0.1) && ([incr loops] <= 25)} {
            set guess_3 [expr {($guess_1 + $guess_2) / 2.0}]
            set life [gas_life $guess_3 $planet]

            if {$life < $target} {
                set guess_1 $guess_3
            } else {
                set guess_2 $guess_3
            }
	}
	
	set life [gas_life $guess_2 $planet]

	return $guess_2
    }


    #*--------------------------------------------------------------------------*/
    #*	 The temperature calculated is in degrees Kelvin.						*/
    #*	 Quantities already known which are used in these calculations:			*/
    #*		 planet->molec_weight												*/
    #*		 planet->surf_pressure												*/
    #*		 R_ecosphere														*/
    #*		 planet->a															*/
    #*		 planet->volatile_gas_inventory										*/
    #*		 planet->radius														*/
    #*		 planet->boil_point													*/
    #*--------------------------------------------------------------------------*/

    proc calculate_surface_temp {planet first last_water last_clouds last_ice
        last_temp last_albedo} {
	#long double effective_temp;
	#long double water_raw;
	#long double clouds_raw;
	#long double greenhouse_temp;
	#int			boil_off = FALSE;

	if {$first} {
            $planet configure -albedo $::stargen::EARTH_ALBEDO
	
            set effective_temp [eff_temp \
                                [[$planet cget -sun] cget -r_ecosphere] \
                                [$planet cget -a] \
                                [$planet cget -albedo]]
            set greenhouse_temp [green_rise \
                                 [opacity \
                                  [$planet cget -molec_weight] \
                                  [$planet cget -surf_pressure]] \ 
                                 $effective_temp \
                                 [$planet cget -surf_pressure]]
            $planet configure -surf_temp [expr {$effective_temp + $greenhouse_temp}]

            set_temp_range $planet
	}
	
	if {[$planet cget -greenhouse_effect] 
            && [$planet cget -max_temp] < [$planet cget -boil_point]} {
            if {($flag_verbose & 0x0010) != 0} {
                puts stderr [format "Deluge: %s %d max (%Lf) < boil (%Lf)"
                             [[$planet cget -sun] cget -name] \
                             [$planet cget -planet_no] \
                             [$planet cget -max_temp] \
                             [$planet cget -boil_point]]
            }
            $planet configure -greenhouse_effect no
		
            $planet configure -volatile_gas_inventory [vol_inventory \
                                                       [$planet cget -mass] \
                                                       [$planet cget -esc_velocity] \
                                                       [$planet cget -rms_velocity] \
                                                       [[$planet cget -sun] cget -mass] \
                                                       [$planet cget -orbit_zone] \
                                                       [$planet cget -greenhouse_effect] \
                                                       [expr {([$planet cget -gas_mass] / [$planet cget -mass]) > 0.000001}]]
            $planet configure -surf_pressure \
                    [pressure \
                     [$planet cget -volatile_gas_inventory] \
                     [$planet cget -radius] \
                     [$planet cget -surf_grav]]

            $planet configure -boil_point \
                    [boiling_point [$planet cget -surf_pressure]]
        }	
        
        ### HERE
        
	water_raw     			=
	planet->hydrosphere		= hydro_fraction(planet->volatile_gas_inventory, 
											 planet->radius);
	clouds_raw     			=
	planet->cloud_cover 	= cloud_fraction(planet->surf_temp, 
											 planet->molec_weight, 
											 planet->radius, 
											 planet->hydrosphere);
	planet->ice_cover   	= ice_fraction(planet->hydrosphere, 
										   planet->surf_temp);
	
	if ((planet->greenhouse_effect)
	 && (planet->surf_pressure > 0.0))
		planet->cloud_cover	= 1.0;
	
	if ((planet->high_temp >= planet->boil_point)
	 && (!first)
	 && !((int)planet->day == (int)(planet->orb_period * 24.0) ||
		  (planet->resonant_period)))
	{
		planet->hydrosphere	= 0.0;
		boil_off = TRUE;
		
		if (planet->molec_weight > WATER_VAPOR)
			planet->cloud_cover = 0.0;
		else
			planet->cloud_cover = 1.0;
	}

	if (planet->surf_temp < (FREEZING_POINT_OF_WATER - 3.0))
		planet->hydrosphere	= 0.0;
	
	planet->albedo			= planet_albedo(planet->hydrosphere, 
											planet->cloud_cover, 
											planet->ice_cover, 
											planet->surf_pressure);
	
	effective_temp 			= eff_temp(planet->sun->r_ecosphere, planet->a, planet->albedo);
	greenhouse_temp     	= green_rise(opacity(planet->molec_weight,
												 planet->surf_pressure), 
										 effective_temp, 
										 planet->surf_pressure);
	planet->surf_temp   	= effective_temp + greenhouse_temp;

	if (!first)
	{
		if (!boil_off)
			planet->hydrosphere	= (planet->hydrosphere + (last_water * 2))  / 3;
		planet->cloud_cover	    = (planet->cloud_cover + (last_clouds * 2)) / 3;
		planet->ice_cover	    = (planet->ice_cover   + (last_ice * 2))    / 3;
		planet->albedo		    = (planet->albedo      + (last_albedo * 2)) / 3;
		planet->surf_temp	    = (planet->surf_temp   + (last_temp * 2))   / 3;
	}

	set_temp_range(planet);

	if (flag_verbose & 0x0020)
		fprintf (stderr, "%5.1Lf AU: %5.1Lf = %5.1Lf ef + %5.1Lf gh%c "
				"(W: %4.2Lf (%4.2Lf) C: %4.2Lf (%4.2Lf) I: %4.2Lf A: (%4.2Lf))\n", 
				planet->a,
				planet->surf_temp - FREEZING_POINT_OF_WATER,
				effective_temp - FREEZING_POINT_OF_WATER,
				greenhouse_temp,
				(planet->greenhouse_effect) ? '*' :' ',
				planet->hydrosphere, water_raw,
				planet->cloud_cover, clouds_raw,
				planet->ice_cover,
				planet->albedo);
}

void iterate_surface_temp(planet)
planet_pointer planet; 
{
	int			count = 0;
	long double initial_temp = est_temp(planet->sun->r_ecosphere, planet->a, planet->albedo);

	long double h2_life  = gas_life (MOL_HYDROGEN,    planet);
	long double h2o_life = gas_life (WATER_VAPOR,     planet);
	long double n2_life  = gas_life (MOL_NITROGEN,    planet);
	long double n_life   = gas_life (ATOMIC_NITROGEN, planet);
	
	if (flag_verbose & 0x20000)
		fprintf (stderr, "%d:                     %5.1Lf it [%5.1Lf re %5.1Lf a %5.1Lf alb]\n",
				planet->planet_no,
				initial_temp,
				planet->sun->r_ecosphere, planet->a, planet->albedo
				);

	if (flag_verbose & 0x0040)
		fprintf (stderr, "\nGas lifetimes: H2 - %Lf, H2O - %Lf, N - %Lf, N2 - %Lf\n",
				h2_life, h2o_life, n_life, n2_life);

	calculate_surface_temp(planet, TRUE, 0, 0, 0, 0, 0);

	for (count = 0;
		 count <= 25;
		 count++)
	{
		long double	last_water	= planet->hydrosphere;
		long double last_clouds	= planet->cloud_cover;
		long double last_ice	= planet->ice_cover;
		long double last_temp	= planet->surf_temp;
		long double last_albedo	= planet->albedo;
		
		calculate_surface_temp(planet, FALSE, 
							   last_water, last_clouds, last_ice, 
							   last_temp, last_albedo);
		
		if (fabs(planet->surf_temp - last_temp) < 0.25)
			break;
	}

	planet->greenhs_rise = planet->surf_temp - initial_temp;
	
	if (flag_verbose & 0x20000)
		fprintf (stderr, "%d: %5.1Lf gh = %5.1Lf (%5.1Lf C) st - %5.1Lf it [%5.1Lf re %5.1Lf a %5.1Lf alb]\n",
				planet->planet_no,
				planet->greenhs_rise,
				planet->surf_temp,
				planet->surf_temp - FREEZING_POINT_OF_WATER,
				initial_temp,
				planet->sun->r_ecosphere, planet->a, planet->albedo
				);
}

#*--------------------------------------------------------------------------*/
#*	 Inspired partial pressure, taking into account humidification of the	*/
#*	 air in the nasal passage and throat This formula is on Dole's p. 14	*/
#*--------------------------------------------------------------------------*/

long double inspired_partial_pressure (long double surf_pressure,
									   long double gas_pressure)
{
	long double pH2O = (H20_ASSUMED_PRESSURE);
	long double fraction = gas_pressure / surf_pressure;
	
	return	(surf_pressure - pH2O) * fraction;
}


#*--------------------------------------------------------------------------*/
#*	 This function uses figures on the maximum inspired partial pressures   */
#*   of Oxygen, other atmospheric and traces gases as laid out on pages 15, */
#*   16 and 18 of Dole's Habitable Planets for Man to derive breathability  */
#*   of the planet's atmosphere.                                       JLB  */
#*--------------------------------------------------------------------------*/

unsigned int breathability (planet_pointer planet)
{
	int	oxygen_ok	= FALSE;
	int index;

	if (planet->gases == 0)
		return NONE;
	
	for (index = 0; index < planet->gases; index++)
	{
		int	n;
		int	gas_no = 0;
		
		long double ipp = inspired_partial_pressure (planet->surf_pressure,
													 planet->atmosphere[index].surf_pressure);
		
		for (n = 0; n < max_gas; n++)
		{
			if (gases[n].num == planet->atmosphere[index].num)
				gas_no = n;
		}

		if (ipp > gases[gas_no].max_ipp)
			return POISONOUS;
			
		if (planet->atmosphere[index].num == AN_O)
			oxygen_ok = ((ipp >= MIN_O2_IPP) && (ipp <= MAX_O2_IPP));
	}
	
	if (oxygen_ok)
		return BREATHABLE;
	else
		return UNBREATHABLE;
}

#* function for 'soft limiting' temperatures */

long double lim(long double x)
{
  return x / sqrt(sqrt(1 + x*x*x*x));
}

long double soft(long double v, long double max, long double min)
{
  long double dv = v - min;
  long double dm = max - min;
  return (lim(2*dv/dm-1)+1)/2 * dm + min;
}

void set_temp_range(planet_pointer planet)
{
  long double pressmod = 1 / sqrt(1 + 20 * planet->surf_pressure/1000.0);
  long double ppmod    = 1 / sqrt(10 + 5 * planet->surf_pressure/1000.0);
  long double tiltmod  = fabs(cos(planet->axial_tilt * PI/180) * pow(1 + planet->e, 2));
  long double daymod   = 1 / (200/planet->day + 1);
  long double mh = pow(1 + daymod, pressmod);
  long double ml = pow(1 - daymod, pressmod);
  long double hi = mh * planet->surf_temp;
  long double lo = ml * planet->surf_temp;
  long double sh = hi + pow((100+hi) * tiltmod, sqrt(ppmod));
  long double wl = lo - pow((150+lo) * tiltmod, sqrt(ppmod));
  long double max = planet->surf_temp + sqrt(planet->surf_temp) * 10;
  long double min = planet->surf_temp / sqrt(planet->day + 24);

  if (lo < min) lo = min;
  if (wl < 0)   wl = 0;

  planet->high_temp = soft(hi, max, min);
  planet->low_temp  = soft(lo, max, min);
  planet->max_temp  = soft(sh, max, min);
  planet->min_temp  = soft(wl, max, min);
}

    namespace export luminosity orb_zone volume_radius kothari_radius \
          empirical_density volume_density period day_length escape_vel \
          rms_vel molecule_limit min_molec_weight acceleration gravity \
          vol_inventory pressure boiling_point hydro_fraction cloud_fraction \
          ice_fraction eff_temp est_temp grnhouse green_rise planet_albedo \
          opacity gas_life calculate_surface_temp iterate_surface_temp \
          inspired_partial_pressure breathability NONE BREATHABLE \
          UNBREATHABLE POISONOUS breathability_phrase lim soft set_temp_range
}



