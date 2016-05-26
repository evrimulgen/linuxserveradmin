dnl Process this file with autoconf to produce a configure script.

m4_define([srvmutil_version], [1.0.0])

AC_PREREQ(2.59)
AC_INIT(IOServerManagerUtils, [srvmutil_version], [info@ilker.rocks])

SRVM_UTILS_VERSION=srvm_version

echo "## ------------------------------------ ##"
echo "## Configuring ServerManagerUtils $SRVM_VERSION ##"
echo "## ------------------------------------ ##"

if test "$prefix" == "NONE"
then
	prefix="/usr/local/$PACKAGE_NAME"
fi

AC_CANONICAL_SYSTEM
AC_PROG_CC([clang gcc])
AC_LANG(C)

CFLAGS="$CFLAGS -O1 -g0 -W -Wall -std=gnu99"

LIBS="$LIBS"
INCLUDES="$INCLUDES -I$SSM_TOP_BUILD_DIR/IO"
DEFS="$DEFS"
CPPFLAGS="$CPPFLAGS"
SERVER_MANAGER_UTILS_LDFLAGS=""

echo "Checking libraries ..."
AC_CHECK_LIB(crypt, [main], [
	SERVER_MANAGER_UTILS_LDFLAGS="$SERVER_MANAGER_UTILS_LDFLAGS -lcrypt"
], [])

echo "Checking headers ..."
AC_CHECK_HEADER(stdio.h, [echo "OK!!"], [echo "Failed!!"])
AC_CHECK_HEADER(stdlib.h, [echo "OK!!"], [echo "Failed!!"])
AC_CHECK_HEADER(unistd.h, [echo "OK!!"], [echo "Failed!!"])
AC_CHECK_HEADER(time.h, [echo "OK!!"], [echo "Failed!!"])
AC_CHECK_HEADER(string.h, [echo "OK!!"], [echo "Failed!!"])

echo "Checking methods ..."
AC_CHECK_FUNCS([memset malloc free sprintf crypt])

AC_TRY_RUN([
int main(int argc, char *argv[]) {
	if(sizeof(void*) == 8) {
		return 0;
	}else{
		return 1;
	}
}
],[
AC_SUBST(servermanager_utils_build_architecture,  ["64"])
], [
AC_SUBST(servermanager_utils_build_architecture,  ["32"])
])

AC_SUBST(SERVER_MANAGER_UTILS_LDFLAGS, ["$SERVER_MANAGER_UTILS_LDFLAGS"])
AC_CONFIG_FILES(src/ServerManagerUtils_Config.h)

AC_DEFINE_UNQUOTED([IO_SERVER_MANAGER_UTILS_HAVE_A_CONFIG_H_], 1, [])

AM_INIT_AUTOMAKE([subdir-objects])

AC_CONFIG_FILES(Makefile src/Makefile)
AC_OUTPUT

echo "Configure OK"

