dnl Initialize automake/autoconf
AC_INIT(dkfilter, 0.10)
AM_INIT_AUTOMAKE

dnl Check for Perl
AC_PATH_PROG(PERL, perl, perl)

dnl Installation locations
perllibdir='${prefix}/lib'
AC_SUBST(perllibdir)

AC_OUTPUT([
	Makefile
	lib/Makefile
	lib/Mail/Makefile
	lib/Mail/DomainKeys/Makefile
	lib/Mail/DomainKeys/Key/Makefile
	lib/MSDW/Makefile
	lib/MSDW/SMTP/Makefile
	scripts/Makefile
	])
