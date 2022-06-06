ACLOCAL_AMFLAGS = -I m4

SUBDIRS = BuildData BuildScripts Docs Scripts UserManual po intl

EXTRA_DIST = StarshipFleet.tcl bootstrap

noinst_SCRIPTS = StarshipFleet${EXEEXT} StarSystemServer${EXEEXT}

ORSA_PortScripts = Scripts/ORSA_Port/pkgIndex.tcl \
		   Scripts/ORSA_Port/orsa_body.tcl \
		   Scripts/ORSA_Port/orsa_common.tcl \
		   Scripts/ORSA_Port/orsa_coord.tcl \
                   Scripts/ORSA_Port/orsa_body.tcl \
                   Scripts/ORSA_Port/orsa_units.tcl \
                   Scripts/ORSA_Port/orsa_orbit.tcl \
                   Scripts/ORSA_Port/orsa.tcl \
                   Scripts/ORSA_Port/orsa_frame.tcl \
                   Scripts/ORSA_Port/orsa_interaction.tcl

PlanetarySystemScripts = Scripts/PlanetarySystem/pkgIndex.tcl \
		 	 Scripts/PlanetarySystem/PlanetarySystem.tcl \
		 	 Scripts/PlanetarySystem/SystemDisplay.tcl \
		 	 Scripts/PlanetarySystem/ObjectDetail.tcl \
		 	 Scripts/PlanetarySystem/MainDisplay.tcl
		 	 
NetworkScripts = Scripts/Network/pkgIndex.tcl \
		 Scripts/Network/Server.tcl \
		 Scripts/Network/Client.tcl
		 
StarGenScripts = Scripts/StarGen/accrete.tcl \
                 Scripts/StarGen/const.tcl \
                 Scripts/StarGen/enviro.tcl \
                 Scripts/StarGen/main.tcl \
                 Scripts/StarGen/stargen.tcl \
                 Scripts/StarGen/structs.tcl \
                 Scripts/StarGen/utils.tcl \
                 Scripts/StarGen/pkgIndex.tcl
                 
		 	 
GUISupportScripts = Scripts/GUISupport/close.gif \
		    Scripts/GUISupport/DeepwoodsBanner.gif \
		    Scripts/GUISupport/DynamicHelp.tcl \
		    Scripts/GUISupport/gray50.xbm \
		    Scripts/GUISupport/IconsAndImages.tcl \
		    Scripts/GUISupport/info.xbm \
		    Scripts/GUISupport/mainwindow.tcl \
		    Scripts/GUISupport/new.gif \
		    Scripts/GUISupport/openfold.png \
		    Scripts/GUISupport/open.gif \
		    Scripts/GUISupport/palette.png \
		    Scripts/GUISupport/print.gif \
		    Scripts/GUISupport/questhead.xbm \
		    Scripts/GUISupport/save.gif \
		    Scripts/GUISupport/unknown.xpm \
		    Scripts/GUISupport/snitbuttonbox.tcl \
		    Scripts/GUISupport/snitdialog.tcl \
		    Scripts/GUISupport/snitHTMLHelp.tcl \
		    Scripts/GUISupport/snitLFs.tcl \
		    Scripts/GUISupport/snitlistbox.tcl \
		    Scripts/GUISupport/snitmainframe.tcl \
		    Scripts/GUISupport/snitpagesmanager.tcl \
		    Scripts/GUISupport/snitrotext.tcl \
		    Scripts/GUISupport/snitscrollableframe.tcl \
		    Scripts/GUISupport/snitscrollw.tcl \
		    Scripts/GUISupport/snitStdMenuBar.tcl \
		    Scripts/GUISupport/snittree.tcl \
		    Scripts/GUISupport/gettext.tcl

BridgeConsolesScripts = Scripts/BridgeConsoles/BridgeConsoles.tcl \
			Scripts/BridgeConsoles/pkgIndex.tcl

ShipyardCommandScripts = Scripts/ShipyardCommand/ShipyardCommand.tcl \
			 Scripts/ShipyardCommand/pkgIndex.tcl

StarshipFleet${EXEEXT} : StarshipFleet.tcl $(ORSA_PortScripts) \
		$(NetworkScripts) $(GUISupportScripts) \
		$(StarGenScripts)  $(GDLibFiles) $(BridgeConsolesScripts) \
		$(ShipyardCommandScripts) $(PlanetarySystemScripts)
	-rm -rf StarshipFleet.vfs StarshipFleet.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit qwrap $(srcdir)/StarshipFleet.tcl
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit unwrap StarshipFleet.kit
	-rm -rf StarshipFleet.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
		lib $(CONTROLLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
		lib $(STRUCTLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarshipFleet \
	 	lib $(BASE64LIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/ORSA_Port $(ORSA_PortScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/StarGen $(StarGenScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/Network $(NetworkScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/PlanetarySystem $(PlanetarySystemScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/GUISupport $(GUISupportScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/MakePkgIndex.kit \
		StarshipFleet GUISupport
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/BridgeConsoles $(BridgeConsolesScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarshipFleet lib/ShipyardCommand $(ShipyardCommandScripts)
	$(UNZIP) -qq -d StarshipFleet.vfs/lib \
		$(top_srcdir)/BuildData/pdf4tcl05.zip
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit wrap \
		StarshipFleet${EXEEXT} \
		-runtime $(top_srcdir)/BuildData/$(TCLKITRUN)
	-rm -rf StarshipFleet.vfs StarshipFleet.kit

StarSystemServer${EXEEXT} : StarSystemServer.tcl $(ORSA_PortScripts) \
		$(PlanetarySystemScripts) $(NetworkScripts) \
		$(StarGenScripts) $(GDLibFiles)
	-rm -rf StarSystemServer.vfs StarSystemServer.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit qwrap $(srcdir)/StarSystemServer.tcl
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit unwrap StarSystemServer.kit
	-rm -rf StarSystemServer.kit
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarSystemServer \
		lib $(SNITLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarSystemServer \
		lib $(CONTROLLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarSystemServer \
		lib $(TCLLOGLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarSystemServer \
		lib $(STRUCTLIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitDir.kit StarSystemServer \
		lib $(BASE64LIB)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarSystemServer lib/ORSA_Port $(ORSA_PortScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarSystemServer lib/StarGen $(StarGenScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarSystemServer lib/PlanetarySystem $(PlanetarySystemScripts)
	$(TCLKIT) $(top_srcdir)/BuildScripts/AddKitFile.kit -srcdir $(srcdir) \
		StarSystemServer lib/Network $(NetworkScripts)
	$(UNZIP) -qq -d StarSystemServer.vfs/lib \
		$(top_srcdir)/BuildData/pdf4tcl05.zip
	$(TCLKIT) $(top_srcdir)/BuildScripts/sdx.kit wrap \
		StarSystemServer${EXEEXT} \
		-runtime $(top_srcdir)/BuildData/$(TCLKITRUN)
	-rm -rf StarSystemServer.vfs StarSystemServer.kit

