/*
 * IOServerManagerUtils_pcx.h
 *
 *  Created on: Nov 9, 2015
 *      Author: ilk3r
 */

#ifndef SRC_IOSERVERMANAGERUTILS_PCX_H_
#define SRC_IOSERVERMANAGERUTILS_PCX_H_

#ifndef _XOPEN_SOURCE
#	define _XOPEN_SOURCE
#endif

#ifndef _XOPEN_SOURCE_EXTENDED
#	define _XOPEN_SOURCE_EXTENDED
#endif

#ifdef IO_SERVER_MANAGER_UTILS_HAVE_A_CONFIG_H_
#	include "ServerManagerUtils_Config.h"
#else
#	define SERVER_MANAGER_UTILS_CC "clang"
#	define SERVER_MANAGER_UTILS_LDFLAGS ""
#	define SERVER_MANAGER_UTILS_PREFIX "/usr/local"
#	define SERVER_MANAGER_UTILS_CC_OS "AnyOs"
#	define SERVER_MANAGER_UTILS_CC_ARC "x86_64"
#	define SERVER_MANAGER_UTILS_CC_VENDOR "Dev"
#	define SERVER_MANAGER_UTILS_ARC 64
#endif

#ifndef PACKAGE_VERSION
#	define PACKAGE_VERSION "~ Dev"
#endif

#ifndef PACKAGE_NAME
#	define PACKAGE_NAME "~ SRVMDev"
#endif

#ifndef PACKAGE_BUGREPORT
#	define PACKAGE_BUGREPORT "~ SRVMDev"
#endif

#endif /* SRC_IOSERVERMANAGERUTILS_PCX_H_ */
