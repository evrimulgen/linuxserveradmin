/*
 * IO_ArgumentParher.h
 *
 *  Created on: Nov 10, 2015
 *      Author: ilk3r
 */

#ifndef IO_IO_ARGUMENTPARSER_H_
#define IO_IO_ARGUMENTPARSER_H_

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

#ifndef IO_TRUE
#	define IO_TRUE '1'
#endif

#ifndef IO_FALSE
#	define IO_FALSE '0'
#endif

typedef struct _IO_Argument_Entries IO_Argument_Entries;

struct _IO_Argument_Entries {

	char *argName;
	size_t argNameLen;

	char *argShorName;
	size_t argShortNameLen;

	char *helpString;

	char *argStringValue;
	size_t argStringValueLen;

	long argLongValue;

	char type;
	unsigned short takeValue;

	void (*autoRelease)(IO_Argument_Entries *);
};

extern IO_Argument_Entries *argumentEntriesPointer[];
extern char argumentEntriesReady;
void IO_Argument_Entries_AutoRelease(IO_Argument_Entries *self);
char IO_Argument_Entries_Parse_ex(size_t entrySize, int argc, const char *argv[]);
IO_Argument_Entries *IO_Get_Argument_Value_ex(const char *name, size_t nameLen);
size_t IO_getArgumentEntriesSize();

#define IO_GET_ARGUMENT_ENTRIES_SIZE (sizeof(argument_entries) / sizeof(IO_Argument_Entries))

#define IO_ARGUMENT_START()																				\
	static IO_Argument_Entries argument_entries[] = {

#define IO_ARGUMENT_END()																				\
	{ NULL, 0, NULL, 0, NULL, NULL, 0, 0, 'N', 0, NULL } };												\
	IO_Argument_Entries *argumentEntriesPointer[IO_GET_ARGUMENT_ENTRIES_SIZE];							\
	char argumentEntriesReady = IO_FALSE;

#define IO_ARGUMENT_STRING_ENTRY(longName, longNameLen, shortName, shortNameLen, helpString, takeValue)	\
	{ longName, longNameLen, shortName, shortNameLen, helpString, NULL, 0, 0, 'S',						\
		takeValue, &IO_Argument_Entries_AutoRelease },

#define IO_ARGUMENT_LONG_ENTRY(longName, longNameLen, shortName, shortNameLen, helpString, takeValue)	\
	{ longName, longNameLen, shortName, shortNameLen, helpString, NULL, 0, 0, 'L',						\
		takeValue, NULL },

#define IO_PREPARE_ARGUMENT_ENTIRES() {																	\
	size_t curPt = 0;																					\
	for(curPt = 0; curPt < IO_GET_ARGUMENT_ENTRIES_SIZE; curPt++) {										\
		argumentEntriesPointer[curPt] = (void *)(&(argument_entries[curPt]));							\
	}																									\
	argumentEntriesReady = IO_TRUE;																		\
}

#define IO_PARSE_ARGUMENT_ENTRIES(argc, argv) ( (argumentEntriesReady == '1') ? (IO_Argument_Entries_Parse_ex(IO_GET_ARGUMENT_ENTRIES_SIZE, argc, argv)) : IO_FALSE)

#define IO_SET_ARGUMENT_VALUE_L(argumentSize, lkd, lks, vd, vs) ({										\
	char status = IO_FALSE;																				\
	if(argumentEntriesReady == IO_TRUE) {																\
		size_t i = 0;																					\
		for(i = 0; i < argumentSize; i++) {																\
			if(lks >= argumentEntriesPointer[i]->argNameLen && argumentEntriesPointer[i]->argName) {	\
				if(strcmp(argumentEntriesPointer[i]->argName, lkd) == 0) {								\
					if(argumentEntriesPointer[i]->takeValue == 1) {										\
						status = IO_TRUE;																\
						if(argumentEntriesPointer[i]->type == 'S') {									\
							argumentEntriesPointer[i]->argStringValue = realloc(NULL, vs);				\
							memset(argumentEntriesPointer[i]->argStringValue, '\0', vs);				\
							memcpy(argumentEntriesPointer[i]->argStringValue, vd, vs);					\
							argumentEntriesPointer[i]->argStringValueLen = vs;							\
						}else if(argumentEntriesPointer[i]->type == 'L') {								\
							argumentEntriesPointer[i]->argLongValue = strtol(vd, NULL, 10);				\
						}																				\
					}else if(argumentEntriesPointer[i]->type == 'L') {									\
						argumentEntriesPointer[i]->argLongValue = 1;									\
					}																					\
				}																						\
			}																							\
		}																								\
	}																									\
	(status);																							\
})

#define IO_SET_ARGUMENT_VALUE_S(argumentSize, skd, sks, vd, vs) ({												\
	char status = IO_FALSE;																						\
	if(argumentEntriesReady == IO_TRUE) {																		\
		size_t i = 0;																							\
		for(i = 0; i < argumentSize; i++) {																		\
			if(sks >= argumentEntriesPointer[i]->argShortNameLen && argumentEntriesPointer[i]->argShorName) {	\
				if(strcmp(argumentEntriesPointer[i]->argShorName, skd) == 0) {									\
					if(argumentEntriesPointer[i]->takeValue == 1) {												\
						status = IO_TRUE;																		\
						if(argumentEntriesPointer[i]->type == 'S') {											\
							argumentEntriesPointer[i]->argStringValue = realloc(NULL, vs);						\
							memset(argumentEntriesPointer[i]->argStringValue, '\0', vs);						\
							memcpy(argumentEntriesPointer[i]->argStringValue, vd, vs);							\
							argumentEntriesPointer[i]->argStringValueLen = vs;									\
						}else if(argumentEntriesPointer[i]->type == 'L') {										\
							argumentEntriesPointer[i]->argLongValue = strtol(vd, NULL, 10);						\
						}																						\
					}else if(argumentEntriesPointer[i]->type == 'L') {											\
						argumentEntriesPointer[i]->argLongValue = 1;											\
					}																							\
				}																								\
			}																									\
		}																										\
	}																											\
	(status);																									\
})

#define IO_DTOR_ARGUMENTS() {																			\
	if(argumentEntriesReady == IO_TRUE) {																\
		size_t i = 0;																					\
		size_t iniArraySize = IO_getArgumentEntriesSize();												\
		for(i = 0; i < iniArraySize; i++) {																\
			if(argumentEntriesPointer[i]->type == 'S') {												\
				argumentEntriesPointer[i]->autoRelease(argumentEntriesPointer[i]);						\
			}																							\
		}																								\
	}																									\
}

#define IO_GET_ARGUMENT_VALUE_P(name, nameLen) (IO_Get_Argument_Value_ex(name, nameLen))

#define IO_GET_ARGUMENT_STR_LEN_EX(name, nameLen) ({													\
	IO_Argument_Entries *iv = IO_GET_ARGUMENT_VALUE_P(name, nameLen);									\
	( (iv->argStringValueLen) ? (iv->argStringValueLen) : 0 ); 											\
})

#define IO_GET_ARGUMENT_STR_VALUE_EX(name, nameLen, defaultValue) ({									\
	IO_Argument_Entries *iv = IO_GET_ARGUMENT_VALUE_P(name, nameLen);									\
	( (iv->argStringValue) ? (iv->argStringValue) : defaultValue ); 									\
})

#define IO_GET_ARGUMENT_LONG_VALUE_EX(name, nameLen, defaultValue) ({									\
	IO_Argument_Entries *iv = IO_GET_ARGUMENT_VALUE_P(name, nameLen);									\
	( (iv->argLongValue) ? (iv->argLongValue) : defaultValue ); 										\
})

#define IO_GET_ARGUMENT_STR_LEN(name, nameLen) ( IO_GET_ARGUMENT_STR_LEN_EX(name, nameLen) )
#define IO_GET_ARGUMENT_STR_VALUE(name, nameLen, defaultValue) ( IO_GET_ARGUMENT_STR_VALUE_EX(name, nameLen, defaultValue) )
#define IO_GET_ARGUMENT_LONG_VALUE(name, nameLen, defaultValue) ( IO_GET_ARGUMENT_LONG_VALUE_EX(name, nameLen, defaultValue) )

#define IO_GET_USAGE(pn) {																				\
	if(argumentEntriesReady == IO_TRUE) {																\
		printf("\x1B[31m %s \033[0m \n\nUsage: %s -arg1 value -arg2 value -arg3  value ...\n", pn, pn);	\
		printf("Arguments: \n\n");																		\
		size_t i = 0;																					\
		size_t argArraySize = IO_getArgumentEntriesSize();												\
		for(i = 0; i < argArraySize; i++) {																\
			if(argumentEntriesPointer[i]->type != 'N') {												\
				if(argumentEntriesPointer[i]->takeValue == 0) {											\
					printf("-%s (--%s)\t\t\t: %s\n", argumentEntriesPointer[i]->argShorName,			\
						argumentEntriesPointer[i]->argName, 											\
						argumentEntriesPointer[i]->helpString);											\
				}else{																					\
					printf("-%s (--%s) [value]\t\t: %s\n", argumentEntriesPointer[i]->argShorName,		\
						argumentEntriesPointer[i]->argName, 											\
						argumentEntriesPointer[i]->helpString);											\
				}																						\
			}																							\
		}																								\
	}else{																								\
		printf("\x1B[31m %s \033[0m", "On error occured!");												\
	}																									\
	printf("\n\n");																						\
}

#define IO_GET_VERSION(pn, pv) {																		\
	printf("\x1B[31m %s \033[0m \nVersion: %s\n", pn, pv);												\
	printf("Copyright (c) 2015 Ilker Özcan\n");															\
}

#define IO_GET_BUILD_INFO(pn, pv, br, otr) {															\
	printf("\x1B[31m %s \033[0m \nVersion: %s\n", pn, pv);												\
	printf("Bug report: %s\n", br);																		\
	printf("%s\n", otr);																				\
	printf("Copyright (c) 2015 Ilker Özcan\n");															\
}

#endif /* IO_IO_ARGUMENTPARSER_H_ */
