ACLOCAL_AMFLAGS = -I m4

SUBDIRS = BuildData BuildScripts Docs Scripts UserManual po intl

EXTRA_DIST = StarshipFleet.tcl bootstrap

noinst_SCRIPTS = StarshipFleet.kit

ORSA_PortScripts = Scripts/ORSA_Port/pkgIndex.tcl \
		   Scripts/ORSA_Port/orsa_body.tcl \
		   Scripts/ORSA_Port/orsa_common.tcl \
		   Scripts/ORSA_Port/orsa_coord.tcl \        
                   Scripts/ORSA_Port/orsa_body.tcl \
                   Scripts/ORSA_Port/orsa_units.tcl \
                   Scripts/ORSA_Port/orsa_orbit.tcl \
                   Scripts/ORSA_Port/orsa.tcl

PlanetarySystemScripts = Scripts/PlanetarySystem/pkgIndex.tcl \
		 	 Scripts/PlanetarySystem/PlanetarySystem.tcl \
		 	 Scripts/PlanetarySystem/SystemDisplay.tcl
		 	 
GUISupportScripts = Scripts/GUISupport/snitscrollw.tcl \
		    Scripts/GUISupport/snitbuttonbox.tcl

StarshipFleet.kit : StarshipFleet.tcl $(ORSA_PortScripts) \
		$(PlanetarySystemScripts) $(GUISupportScripts)
	-rm -rf StarshipFleet.vfs StarshipFleet.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit qwrap $(srcdir)/StarshipFleet.tcl
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit unwrap StarshipFleet.kit
	-rm -rf StarshipFleet.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
		lib $(CONTROLLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/ORSA_Port $(ORSA_PortScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/PlanetarySystem $(PlanetarySystemScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/GUISupport $(GUISupportScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit \
		StarshipFleet GUISupport
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit wrap StarshipFleet.kit
	-rm -rf StarshipFleet.vfs 

