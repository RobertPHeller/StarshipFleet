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
AC_PATH_PROGS(UNZIP,unzip)

AC_MSG_CHECKING([Checking target Img and tclkit])
case $target_os in 
  macos | darwin*)
    AC_SUBST(IMG_ZIP, Img-1.4-Mac-Universalx86.zip)
    AC_SUBST(TCLKITRUN, tclkit-darwin-univ-aqua)
    AC_SUBST(NEED_APP_BUNDLE,[true])
    ;;
  linux-gnu*)
    case $build_cpu in
      x86_64)
        AC_SUBST(IMG_ZIP, Img-1.4-Linux64.zip)
        AC_SUBST(TCLKITRUN, tclkit-linux-x86_64)
        ;;
      i*86)
        AC_SUBST(IMG_ZIP, Img-1.4-Linux32.zip)
        AC_SUBST(TCLKITRUN, tclkit-linux-x86)
        ;;
      arm*)
        AC_SUBST(IMG_ZIP, Img-1.3-Linuxarmv7l.zip)
        AC_SUBST(TCLKITRUN, tclkit-linux-armv7l)
        ;;
      *)
        AC_MSG_ERROR([Unsupported Linux arch: $target_cpu])
        ;;
    esac
    AC_SUBST(NEED_APP_BUNDLE,[false])
    ;;
  mingw32 | winnt | windows* | cygwin)
    AC_SUBST(IMG_ZIP, Img-1.4-win32.zip)
    AC_SUBST(TCLKITRUN, tclkit-win32.exe)
    AC_SUBST(EXEEXT, .exe)
    AC_SUBST(NEED_APP_BUNDLE,[false])
    ;;
  *)
    AC_MSG_ERROR([Unsupported Operating System: $target_os])
    ;;
esac
AC_MSG_RESULT([IMG_ZIP is $IMG_ZIP and TCLKITRUN is $TCLKITRUN])
AM_CONDITIONAL(MACOSX, test x${NEED_APP_BUNDLE} = xtrue)

AC_MSG_CHECKING([Checking build tclkit])
case $build_os in 
  macos | darwin*) 
    AC_SUBST(TCLKITBSRC, tclkit-darwin-univ-aqua)
    AC_SUBST(BEXEEXT, )
    ;;
  linux-gnu*)
    AC_SUBST(BEXEEXT, )
    case $build_cpu in
      x86_64)
        AC_SUBST(TCLKITBSRC, tclkit-linux-x86_64)
        ;;
      i*86)
        AC_SUBST(TCLKITBSRC, tclkit-linux-x86)
        ;;
      arm*)
        AC_SUBST(TCLKITBSRC, tclkit-linux-armv7l)
        ;;
      *)
        AC_MSG_ERROR([Unsupported Linux arch: $build_cpu])
        ;;
     esac
     ;;

   mingw32 | winnt | windows* | cygwin)
     AC_SUBST(BEXEEXT, .exe)
     AC_SUBST(TCLKITBSRC, tclkit-win32.exe)
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
                 Docs/Makefile \
                 Docs/Doxyfile \
                 Docs/tcldoxyfilter.sh \
                 UserManual/Makefile \
                 UserManual/Doxyfile \
                 po/Makefile \
                 intl/Makefile \
                 ])
AC_CONFIG_COMMANDS([default],[chmod +x Docs/tcldoxyfilter.sh])
AC_OUTPUT

