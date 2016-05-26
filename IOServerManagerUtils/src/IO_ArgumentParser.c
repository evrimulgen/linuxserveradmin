/*
 * IO_ArgumentParser.c
 *
 *  Created on: Nov 10, 2015
 *      Author: ilk3r
 */

#ifndef _XOPEN_SOURCE
#	define _XOPEN_SOURCE
#endif

#ifndef _XOPEN_SOURCE_EXTENDED
#	define _XOPEN_SOURCE_EXTENDED
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "IO_ArgumentParser.h"

static size_t argumentEntriesSize;

size_t IO_getArgumentEntriesSize() /* {{{ */ {

	return argumentEntriesSize;
}
/* }}} */

void IO_Argument_Entries_AutoRelease(IO_Argument_Entries *self) /* {{{ */ {

	if(self->argStringValueLen > 0) {

		free(self->argStringValue);
		self->argStringValueLen = 0;
	}

}
/* }}} */

IO_Argument_Entries *IO_Get_Argument_Value_ex(const char *name, size_t nameLen) /* {{{ */ {

	size_t i = 0;

	for(i = 0; i < argumentEntriesSize; i++) {

		if((argumentEntriesPointer[i]->argName) && (argumentEntriesPointer[i]->argNameLen)) {

			if((nameLen >= ((argumentEntriesPointer[i]->argNameLen) - 2)) && (nameLen <= ((argumentEntriesPointer[i]->argNameLen) + 2)) ) {

				if(strcmp(argumentEntriesPointer[i]->argName, name) == 0) {

					return argumentEntriesPointer[i];
				}
			}
		}
	}

	size_t lastKey = argumentEntriesSize - 1;
	return argumentEntriesPointer[lastKey];

}
/* }}} */

char IO_Argument_Entries_Parse_ex(size_t entrySize, int argc, const char *argv[]) /* {{{ */ {

	argumentEntriesSize = entrySize;

	int i = 1;
	for(i = 1; i < argc; i++) {

		size_t argLen = strlen(argv[i]);
		if(argLen < 2) {
			continue;
		}

		char firstChar = (argv[i])[0];
		char nextArgumentExists = IO_FALSE;
		char secondChar = (argv[i])[1];
		int nextArgumentIdx = i + 1;
		const char *nextArgument;
		if(nextArgumentIdx < argc) {
			nextArgumentExists = IO_TRUE;
			nextArgument = argv[nextArgumentIdx];
		}else{
			nextArgument = "";
		}

		char *argName = malloc(argLen);
		memset(argName, '\0', argLen);

		if(firstChar == '-' && secondChar == '-') {

			if(argLen < 3) {
				free(argName);
				continue;
			}

			size_t longArgumentLen = argLen - 1;
			size_t j = 2;
			for(j = 2; j < argLen; j++) {
				size_t argNameIdx = j - 2;
				memset(&argName[argNameIdx], (argv[i])[j], sizeof(char));
			}

			if(IO_SET_ARGUMENT_VALUE_L(argumentEntriesSize, argName, longArgumentLen, nextArgument, (strlen(nextArgument) + 1)) == IO_TRUE
					&& nextArgumentExists == IO_TRUE) {
				i += 1;
			}
		}else if(firstChar == '-' && secondChar != '-') {

			size_t j = 1;
			for(j = 1; j < argLen; j++) {
				size_t argNameIdx = j - 1;
				memset(&argName[argNameIdx], (argv[i])[j], sizeof(char));
			}

			if(IO_SET_ARGUMENT_VALUE_S(argumentEntriesSize, argName, argLen, nextArgument, (strlen(nextArgument) + 1)) == IO_TRUE
					&& nextArgumentExists == IO_TRUE) {
				i += 1;
			}
		}else{
			free(argName);
			return IO_FALSE;
			break;
		}

		free(argName);
	}

	return IO_TRUE;
}
/* }}} */
