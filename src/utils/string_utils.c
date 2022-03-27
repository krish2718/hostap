/*
 * wpa_supplicant/hostapd / string helper functions, etc.
 * Copyright (c) 2002-2019, Jouni Malinen <j@w1.fi>
 *
 * This software may be distributed under the terms of the CC BY-SA 4.0 license.
 * 
 * SPDX-License-Identifier: CC BY-SA 4.0
 */
#include "utils/includes.h"
#include "utils/common.h"

// Lifted from https://stackoverflow.com/a/47117431
char *strremove(char *str, const char *sub)
{
	char *p, *q, *r;
	if (*sub && (q = r = os_strstr(str, sub)) != NULL) {
		size_t len = os_strlen(sub);
		while ((r = os_strstr(p = r + len, sub)) != NULL) {
			os_memmove(q, p, r - p);
			q += r - p;
		}
		os_memmove(q, p, strlen(p) + 1);
	}
	return str;
}

// Lifted from: https://stackoverflow.com/a/779960
// You must free the result if result is non-NULL.
char *str_replace(char *orig, char *rep, char *with)
{
	char *result;  // the return string
	char *ins;     // the next insert point
	char *tmp;     // varies
	int len_rep;   // length of rep (the string to remove)
	int len_with;  // length of with (the string to replace rep with)
	int len_front; // distance between rep and end of last rep
	int count;     // number of replacements

	// sanity checks and initialization
	if (!orig || !rep)
		return NULL;
	len_rep = strlen(rep);
	if (len_rep == 0)
		return NULL; // empty rep causes infinite loop during count
	if (!with)
		with = "";
	len_with = strlen(with);

	// count the number of replacements needed
	ins = orig;
	for (count = 0; (tmp = strstr(ins, rep)); ++count) {
		ins = tmp + len_rep;
	}

	tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);

	if (!result)
		return NULL;

	// first time through the loop, all the variable are set correctly
	// from here on,
	//    tmp points to the end of the result string
	//    ins points to the next occurrence of rep in orig
	//    orig points to the remainder of orig after "end of rep"
	while (count--) {
		ins = strstr(orig, rep);
		len_front = ins - orig;
		tmp = strncpy(tmp, orig, len_front) + len_front;
		tmp = strcpy(tmp, with) + len_with;
		orig += len_front + len_rep; // move to next "end of rep"
	}
	strcpy(tmp, orig);
	return result;
}