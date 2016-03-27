##-*- makefile -*-############################################################
#
#  System        : 
#  Module        : 
#  Object Name   : $RCSfile$
#  Revision      : $Revision$
#  Date          : $Date$
#  Author        : $Author$
#  Created By    : Robert Heller
#  Created       : Sun Mar 27 16:34:52 2016
#  Last Modified : <160327.1640>
#
#  Description	
#
#  Notes
#
#  History
#	
#  $Log$
#
##############################################################################
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
##############################################################################


TCL_INTERNALS_TCLS = $(top_srcdir)/StarshipFleet.tcl

EXTRA_DIST = tcldoxyfilter.sh.in tcl2dox.kit tcl2dox.tcl



pkgdatadir = $(datadir)/$(PACKAGE)/Doc
noinst_DATA=html/index.html 
pkgdata_DATA = internals.pdf
man3dir = $(mandir)/man3
tcldoxyfilter.sh: tcldoxyfilter.sh.in $(top_builddir)/config.status
	$(top_builddir)/config.status --file=tcldoxyfilter.sh:$(srcdir)/tcldoxyfilter.sh.in
	chmod +x tcldoxyfilter.sh

html/index.html latex/refman.tex man/man3 : Doxyfile $(TCL_INTERNALS_TCLS) tcldoxyfilter.sh
	-rm -rf html latex man
	-chmod +x tcldoxyfilter.sh
	$(DOXYGEN)
	-rm -f man/man3/*.h.3 man/man3/*.tcl.3

internals.pdf: latex/refman.tex 
	$(MAKE) -C latex
	mv latex/refman.pdf internals.pdf

clean-local:
	-rm -rf html latex man
	-rm -f doxygen.log  internals.pdf

install-data-hook: html/index.html man/man3
	$(INSTALL) -d $(DESTDIR)$(pkgdatadir)/InternalsHTML
	for p in html/*; do \
	  if test -f "$$p"; then d=; else d="$(srcdir)/"; fi; \
	  f=`echo $$p | sed -e 's|^.*/||'`; \
	  echo " $(INSTALL_DATA) '$$d$$p' '$(DESTDIR)$(pkgdatadir)/InternalsHTML/$$f'"; \
	  $(INSTALL_DATA) "$$d$$p" "$(DESTDIR)$(pkgdatadir)/InternalsHTML/$$f"; \
	done
	test -z "$(man3dir)" || $(mkdir_p) "$(DESTDIR)$(man3dir)"
	@list=man/man3/* ; \
	for i in $$list; do \
	  file=$$i; \
	  ext=`echo $$i | sed -e 's/^.*\\.//'`; \
	  case "$$ext" in \
	    3*) ;; \
	    *) ext='3' ;; \
	  esac; \
	  inst=`echo $$i | sed -e 's/\\.[0-9a-z]*$$//'`; \
	  inst=`echo $$inst | sed -e 's/^.*\///'`; \
	  inst=`echo $$inst | sed '$(transform)'`.$$ext; \
	  echo " $(INSTALL_DATA) '$$file' '$(DESTDIR)$(man3dir)/$$inst'"; \
	  $(INSTALL_DATA) "$$file" "$(DESTDIR)$(man3dir)/$$inst"; \
	done
	
uninstall-hook: 
	for p in $(DESTDIR)$(pkgdatadir)/InternalsHTML/*; do \
	  if test -f "$$p"; then d=; else d="$(srcdir)/"; fi; \
	  f=`echo $$p | sed -e 's|^.*/||'`; \
	  echo " rm -f '$(DESTDIR)$(pkgdatadir)/InternalsHTML/$$f'"; \
	  rm -f "$(DESTDIR)$(pkgdatadir)/InternalsHTML/$$f"; \
	done
	@list=man/man3/* ; \
	for i in $$list; do \
	  file=$$i; fi; \
	  ext=`echo $$i | sed -e 's/^.*\\.//'`; \
	  case "$$ext" in \
	    3*) ;; \
	    *) ext='3' ;; \
	  esac; \
	  inst=`echo $$i | sed -e 's/\\.[0-9a-z]*$$//'`; \
	  inst=`echo $$inst | sed -e 's/^.*\///'`; \
	  inst=`echo $$inst | sed '$(transform)'`.$$ext; \
	  echo " rm -f '$(DESTDIR)$(man3dir)/$$inst'"; \
	  rm -f "$(DESTDIR)$(man3dir)/$$inst"; \
	done


