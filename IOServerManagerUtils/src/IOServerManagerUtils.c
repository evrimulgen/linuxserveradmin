/*
 ============================================================================
 Name        : IOServerManagerUtils.c
 Author      : Ilker Özcan
 Version     : 1.0.0
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include "IOServerManagerUtils_pcx.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include "IO_ArgumentParser.h"

IO_ARGUMENT_START()
	IO_ARGUMENT_LONG_ENTRY("help", 4, "h", 1, "Display usage", 0)
	IO_ARGUMENT_LONG_ENTRY("version", 7, "v", 1, "Display version information", 0)
	IO_ARGUMENT_LONG_ENTRY("build", 5, "bi", 2, "Display build information", 0)
	IO_ARGUMENT_LONG_ENTRY("encryptpassword", 15, "epwd", 4, "Encrypt plain password", 0)
	IO_ARGUMENT_LONG_ENTRY("matchpassword", 13, "mpwd", 4, "Check passwords", 0)
	IO_ARGUMENT_STRING_ENTRY("plainpassword", 13, "ppwd", 4, "Plain password", 1)
	IO_ARGUMENT_STRING_ENTRY("cryptedpasswd", 13, "cpwd", 4, "Encrypted password", 1)
IO_ARGUMENT_END()

static char *io_server_manager_utils_get_time_string() /* {{{ */ {

	unsigned long saltInt = (unsigned long)time(NULL);
	size_t buffSize = 40;
	char buff[buffSize];
	sprintf(buff, "%lu", saltInt);
	char *returnChar = strdup(buff);
	return returnChar;
}
/* }}} */

static char *io_server_manager_utils_get_password() {

	char *inputPassword = IO_GET_ARGUMENT_STR_VALUE("plainpassword", 13, "");
	char salt[21];
	char *currentTimeString = io_server_manager_utils_get_time_string();
	sprintf(salt, "$6$%s$", currentTimeString);
	free(currentTimeString);
	char *cryptedPassword = (char *)crypt(inputPassword, salt);

	return cryptedPassword;
}

static unsigned char io_server_manager_check_password() /* {{{ */ {

	char *result;
	char *plainPassword = IO_GET_ARGUMENT_STR_VALUE("plainpassword", 13, "");
	char *cryptedPassword = IO_GET_ARGUMENT_STR_VALUE("cryptedpasswd", 13, "");
	size_t plainPasswordLen = strlen(plainPassword);
	size_t cryptedPasswordLen = strlen(cryptedPassword);
	char *trimmedPlainPassword = malloc(plainPasswordLen + 1);
	char *trimmedCryptedPassword = malloc(cryptedPasswordLen + 1);
	memset(trimmedPlainPassword, 0, plainPasswordLen + 1);
	memset(trimmedCryptedPassword, 0, cryptedPasswordLen + 1);
	strncpy(trimmedPlainPassword, plainPassword, plainPasswordLen);
	strncpy(trimmedCryptedPassword, cryptedPassword, cryptedPasswordLen);

	result = crypt(trimmedPlainPassword, trimmedCryptedPassword);
	if(strcmp (result, trimmedCryptedPassword) == 0) {

		free(trimmedPlainPassword);
		free(trimmedCryptedPassword);
		return 1;
	}else{
		free(trimmedPlainPassword);
		free(trimmedCryptedPassword);
		return 0;
	}
}
/* }}} */

int main(int argc, const char *argv[]) {

	IO_PREPARE_ARGUMENT_ENTIRES()
	if(IO_PARSE_ARGUMENT_ENTRIES(argc, argv) == IO_TRUE) {

		if(IO_GET_ARGUMENT_LONG_VALUE("help", 4, 0) == 1) {
			IO_GET_USAGE(PACKAGE_NAME)
			IO_DTOR_ARGUMENTS()
			return EXIT_SUCCESS;
		}

		if(IO_GET_ARGUMENT_LONG_VALUE("version", 7, 0) == 1) {
			IO_GET_VERSION(PACKAGE_NAME, PACKAGE_VERSION)
			IO_DTOR_ARGUMENTS()
			return EXIT_SUCCESS;
		}

		if(IO_GET_ARGUMENT_LONG_VALUE("build", 5, 0) == 1) {

			char *buildInfo = "Compiler: \t%s\nLibraries: \t%s\nPrefix: \t%s\nCompiler OS: \t%s\nCompiler ARCH: \t%s\nVendor: \t%s\n";
			size_t buildInfoSize = snprintf(NULL, 0, buildInfo,
					SERVER_MANAGER_UTILS_CC, SERVER_MANAGER_UTILS_LDFLAGS, SERVER_MANAGER_UTILS_PREFIX,
					SERVER_MANAGER_UTILS_CC_OS, SERVER_MANAGER_UTILS_CC_ARC, SERVER_MANAGER_UTILS_CC_VENDOR);
			char *buildInfoString = malloc(buildInfoSize + 1);
			sprintf(buildInfoString, buildInfo,
					SERVER_MANAGER_UTILS_CC, SERVER_MANAGER_UTILS_LDFLAGS, SERVER_MANAGER_UTILS_PREFIX,
					SERVER_MANAGER_UTILS_CC_OS, SERVER_MANAGER_UTILS_CC_ARC, SERVER_MANAGER_UTILS_CC_VENDOR);
			IO_GET_BUILD_INFO(PACKAGE_NAME, PACKAGE_VERSION, PACKAGE_BUGREPORT, buildInfoString)
			free(buildInfoString);
			IO_DTOR_ARGUMENTS()
			return EXIT_SUCCESS;
		}

		if(IO_GET_ARGUMENT_LONG_VALUE("encryptpassword", 15, 0) == 1) {

			if(IO_GET_ARGUMENT_STR_LEN("plainpassword", 13) > 2) {

				printf("%s\n", io_server_manager_utils_get_password());
				IO_DTOR_ARGUMENTS()
				return EXIT_SUCCESS;
			}else{
				IO_DTOR_ARGUMENTS()
				return EXIT_FAILURE;
			}
		}

		if(IO_GET_ARGUMENT_LONG_VALUE("matchpassword", 13, 0) == 1) {

			if(IO_GET_ARGUMENT_STR_LEN("plainpassword", 13) > 2 && IO_GET_ARGUMENT_STR_LEN("cryptedpasswd", 13) > 2) {

				unsigned char passwordStatus = io_server_manager_check_password();
				if(passwordStatus == 1){
					printf("%s\n", "OK");
				}else{
					printf("%s\n", "FAIL");
				}
				IO_DTOR_ARGUMENTS()
				return EXIT_SUCCESS;
			}else{
				IO_DTOR_ARGUMENTS()
				return EXIT_FAILURE;
			}
		}
	}
}
