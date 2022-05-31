AC_INIT(StarshipFleet,0.0.0,[support@deepsoft.com],StarshipFleet)
AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_SUBST(build)
AC_CANONICAL_TARGET
AC_SUBST(target)
AC_CONFIG_SRCDIR(StarshipFleet.tcl)
AM_INIT_AUTOMAKE([-Wno-portability tar-ustar])
dnl Force cross_compiling, even if it *looks* like we can run cross-built 
dnl binaries (get around wine's cleverness).
if test ${cross_compiling} = "maybe"; then
  if test ${target_os} != ${build_os}; then
      cross_compiling=yes
  fi
fi  

AC_CONFIG_MACRO_DIR([m4])
RELEASEDATE=[`echo '$Date$'|sed 's/^\$Date:[[:space:]]*[^(]*.\(.*\))[[:space:]]\$$/\1/g'`]
AC_SUBST(RELEASEDATE)

if test "x${prefix}" = "xNONE"; then
    prefix=/usr/local
fi
if test "x${exec_prefix}" = "xNONE"; then
    exec_prefix="${prefix}"
fi


BUILD_DIR=`pwd`
TOP_DIR=${BUILD_DIR}

AC_SUBST(TOP_DIR)
AC_SUBST(BUILD_DIR)
       
srcdir=`dirname $0`
cd $srcdir
SRC_DIR=`pwd`
cd $BUILD_DIR

AC_SUBST(SRC_DIR)

AC_SUBST(target)

dnl Checks for programs.

AX_PKG_DOXYGEN(1.7.4, [], [ AC_MSG_ERROR([DOXYGEN 1.7.4 is required to build.]) ])
AC_PATH_PROG(PDFLATEX,pdflatex,/bin/true)
AC_PATH_PROG(LATEX,latex,/bin/true)
AC_PATH_PROG(MAKEINDEX,makeindex,/bin/true)
AC_PATH_PROG(BIBTEX,bibtex,/bin/true)
AC_PATH_PROG(DVIPS,dvips,/bin/true)
AC_PATH_PROG(PS2PDF,ps2pdf,/bin/true)
AC_USE_SYSTEM_EXTENSIONS
AM_GNU_GETTEXT
AC_PATH_PROG(MSGEN,msgen)

TEA_INIT([3.5])
TEA_PATH_TCLCONFIG
TEA_LOAD_TCLCONFIG
TEA_PREFIX
TEA_PROG_TCLSH

if test ${cross_compiling} = "no"; then
  HOSTTCLSH=${TCLSH_PROG}
else
  AC_PATH_PROGS(HOSTTCLSH,[tclsh8.5 tclsh])
fi

dnl Check for external Tcl/Tk libraries
AX_SNIT
AX_URI
AX_CONTROL
AX_TCLLOG
AX_STRUCT
AX_BASE64
AC_PATH_PROGS(UNZIP,unzip)

AC_MSG_CHECKING([Checking target tclkit])
case $target_os in 
  macos | darwin*) 
    AC_SUBST(TCLKITRUN, tclkit-8.6.11-Darwin-Img1.4.13)
    AC_SUBST(NEED_APP_BUNDLE,[true])
    ;;
  linux-gnu*)
    case $target_cpu in
      x86_64)
	AC_SUBST(TCLKITRUN, tclkit-8.6.11-x86_64-Img1.4.7)
	;;
      i*86)
	AC_SUBST(TCLKITRUN, tclkit-8.6.11-i386-Img1.4.7)
	;;
      arm*)
        AC_SUBST(TCLKITRUN, tclkit-8.6.11-armv7l-Img1.4.8)
        ;;
      aarch64)
        AC_SUBST(TCLKITRUN, tclkit-8.6.10-aarch64-Img1.4.9)
        ;;
      *)
	AC_MSG_ERROR([Unsupported Linux arch: $target_cpu])
	;;
     esac
     AC_SUBST(NEED_APP_BUNDLE,[false])
     ;;

   mingw* | winnt | windows* | cygwin)
     AC_SUBST(TCLKITRUN, tclkit-8.6.11-WIN64-Img1.4.13.exe)
     AC_MSG_NOTICE([Only supporting 64-bit!])
     AC_SUBST(NEED_APP_BUNDLE,[false])
     AC_SUBST(EXEEXT, .exe)
     ;;
   *) 
     AC_MSG_ERROR([Unsupported Operating System: $target_os])
     ;;
esac

AC_MSG_RESULT(TCLKITRUN is [$TCLKITRUN])

AM_CONDITIONAL(MACOSX, test x${NEED_APP_BUNDLE} = xtrue)
AC_PATH_PROG(CONVERT,convert,/bin/true)


AC_MSG_CHECKING([Checking build tclkit])
case $build_os in 
  macos | darwin*) 
    AC_SUBST(TCLKITBSRC, tclkit-8.6.11-Darwin-Img1.4.13)
    AC_SUBST(BEXEEXT, )
    ;;
  linux-gnu)
    AC_SUBST(BEXEEXT, )
    case $build_cpu in
      x86_64)
	AC_SUBST(TCLKITBSRC, tclkit-8.6.11-x86_64-Img1.4.7)
	;;
      i*86)
	AC_SUBST(TCLKITBSRC, tclkit-8.6.11-i386-Img1.4.7)
	;;
      arm*)
        AC_SUBST(TCLKITBSRC, tclkit-8.6.11-armv7l-Img1.4.8)
        ;;
      aarch64)
        AC_SUBST(TCLKITBSRC, tclkit-8.6.10-aarch64-Img1.4.9)
        ;;
      *)
	AC_MSG_ERROR([Unsupported Linux arch: $build_cpu])
	;;
     esac
     ;;

   mingw* | winnt | windows* | cygwin)
     AC_SUBST(BEXEEXT, .exe)
     AC_SUBST(TCLKITBSRC, tclkit-8.6.11-WIN64-Img1.4.13.exe)
     AC_MSG_NOTICE([Only supporting 64-bit])
     ;;
   *) 
     AC_MSG_ERROR([Unsupported Operating System: $build_os])
     ;;
esac
AC_MSG_RESULT([TCLKITBSRC is $TCLKITBSRC])

AC_PATH_PROG(SED,sed)

AC_SUBST(TCL_DBGX)
AC_SUBST(TCL_VERSION)
AC_SUBST(TCL_PREFIX)
AC_SUBST(TCL_EXEC_PREFIX)
AC_CONFIG_FILES([Makefile \
                 BuildScripts/Makefile \
                 BuildData/Makefile \
                 Scripts/Makefile \
                 Scripts/ORSA_Port/Makefile \
                 Scripts/PlanetarySystem/Makefile \
                 Scripts/StarGen/Makefile \
                 Scripts/GUISupport/Makefile \
                 Scripts/Network/Makefile \
                 Scripts/BridgeConsoles/Makefile \
                 Scripts/ShipyardCommand/Makefile \
                 Docs/Makefile \
                 Docs/Doxyfile \
                 Docs/tcldoxyfilter.sh \
                 UserManual/Makefile \
                 UserManual/Doxyfile \
                 po/Makefile \
                 intl/Makefile \
                 ])
AC_CONFIG_COMMANDS([default],[chmod +x Docs/tcldoxyfilter.sh])
AC_CONFIG_SUBDIRS([tcl.gd])
AC_OUTPUT

