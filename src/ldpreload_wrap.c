/*
#Copyright (c) 2020, Red Hat, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#define _GNU_SOURCE

#include <string.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>

/*
 * Usage:
 * gcc ./foo.c -o /tmp/foo
 * gcc -shared -fPIC ldpreload_wrap.c -o /tmp/ldpreload_wrap.so -ldl
 * CSEXEC_WRAP_CMD=$'--skip-ld-linux\a/usr/bin/valgrind' LD_PRELOAD=/tmp/ldpreload_wrap.so /tmp/foo
 */

//#define DEBUG

#ifndef CSEXEC_PATH
#define CSEXEC_PATH "/usr/bin/csexec"
#endif

//const char tool_binary[] = "/usr/local/bin/csexec";
const char tool_binary[] = CSEXEC_PATH;
const char tool_name[] = "csexec";


/*
 * List of executable names for which their main functions should not be hijacked
 * This list is currently NOT used, the checks are made based on the directories
 */
const char* name_list[] = {"autoreconf","configure"};
//const int name_list_size = 2; //used just for disabling some directories for testing purposes
const int name_list_size = sizeof(name_list) / sizeof(char*);

/*
 * Similar, but this time we use path to the executable
 * This list IS used, files located in these directories and their subdirectories
 * are run unchanged
 */
const char* path_list[] = {"/usr","/bin"};
//const int path_list_size = 2; //used just for disabling some directories for testing purposes
const int path_list_size = sizeof(path_list) / sizeof(char*);

static int (*original_main) (int, char**, char**);
static int get_executable_path (char* buf, int size);
static int is_prefix_in_list (char* buf, const char** list, int list_size);
static int is_string_in_list (char* buf, const char** list, int list_size);


/*
 * This function is currently unused. but its purpose is to concatenate two arrays of strings
 */
static int merge_argv (const char** argv1,const int argc1,const char** argv2,const int argc2, char** merged_argv)
{
  for (int i = 0; i < argc1; i++)
  {
    merged_argv[i] = strdup(argv1[i]);
    if (merged_argv[i] == NULL)
    {
      return 0;
    }
  }
  for (int i = 0; i < argc2; i++)
  {
    merged_argv[argc1+i] = strdup(argv2[i]);
    if (merged_argv[argc1+i] == NULL)
    {
      return 0;
    }
  }
  merged_argv[argc1+argc2] = NULL;
  return (argc1 + argc2);
}
/*
 * This function prepends a string (head) to an array of string (tail)
 */
static int prepend_execfn (const char* head,const char** tail,const int len, char** array)
{
  array[0] = strdup(head);
  for (int i = 0; i < len; i++)
  {
    array[i+1] = strdup(tail[i]);
    if (array[1+i] == NULL)
    {
      return 0;
    }
  }
  array[1+len] = NULL;
  return (1 + len);
}
/*
 * This function will replace the normal main function
 */
int hijacked_main(int argc, char** argv, char** envp)
{
  /*
   * Get the FULL path to the executable (not just the argv[0])
   */
  int buffsize=2048;
  char buf[buffsize];
  int l = get_executable_path (buf,buffsize);

  unsetenv("LD_PRELOAD");

  char **merged_argv = malloc((argc+1)*sizeof (char*));
  //create a new argv -> prepend the execfn to the argv
  int merged_argc = prepend_execfn(buf,(const char**) argv,argc,merged_argv);
#ifdef DEBUG
  for (int i = 0; i< merged_argc;i++)
  {
      fprintf(stderr,"merged_argv[%d] is: %s\n",i,merged_argv[i]);
  }
#endif
  //call csexec
  int rv = execve(tool_binary,merged_argv,envp);

  return rv;
}

int get_executable_path (char* buf, int size)
{
  int l = readlink("/proc/self/exe",buf,size);
  //readlink does not append \0
  buf[l] = '\0';
  return l;
}

/*
 * Returns zero if some prefix of buf is in the list.
 */
int is_prefix_in_list (char* buf, const char** list, int list_size)
{
  for (int i = 0; i < list_size; i++)
  {
    if (strncmp(list[i],buf,strlen(list[i])) == 0)
    {
      return 0;
    }
  }
  return 1;
}

/*
 * Return zero if the whole buf is in the list
 */
int is_string_in_list (char* buf, const char** list, int list_size)
{
  for (int i = 0; i < list_size; i++)
  {
    if (strcmp(list[i],buf) == 0)
    {
      return 0;
    }
  }
  return 1;
}

/*
 * gets just the name of the executable (TODO does not work if there are escaped '/')
 * currently unused, the idea is to use this in conjuction with the name_list
 */
void strip_the_path (const char * path, char* name)
{
  int last = 0;
  name[0] = '\0';
  for (int i = 0; path[i] != '\0'; i++)
  {
    if (path[i] == '/')
    {
      last = i;
    }
  }
  if (last+1 <= strlen(path))
  {
    strcpy(name,&path[last+1]);
  }
}

/*
 * This function gets preloaded
 */
int __libc_start_main(int (*main) (int, char**, char**), int argc, char** ubp_av, void (*init) (void), void (*fini) (void), void (*rtld_fini) (void), void (* stack_end))
{
  original_main = main;
  typeof(&__libc_start_main) orig_libc_start_main = dlsym(RTLD_NEXT, "__libc_start_main");

  //get the path to exe
  int buffsize=2048;
  char buf[buffsize]; //store the whole path
  char buf2[buffsize]; //store just the name //currently unused
  int l = get_executable_path (buf,buffsize);
  //get just the name (if we use ubp_av[0], it may contain ./ or similar)
  strip_the_path(buf,buf2);

  //use one of the following two approaches
  if (is_prefix_in_list(buf, path_list, path_list_size) == 0) // checking the location of the executable
  //if (is_string_in_list(buf2, name_list, name_list_size) == 0) // checking just the name of the executable
  {
#ifdef DEBUG
    fprintf(stderr, "Running original main for %s\n",buf);
#endif
    return orig_libc_start_main(original_main, argc, ubp_av, init, fini, rtld_fini, stack_end);
  }
    else
  {
#ifdef DEBUG
    fprintf(stderr, "Running hijacked main for %s\n",buf);
#endif
    return orig_libc_start_main(hijacked_main, argc, ubp_av, init, fini, rtld_fini, stack_end);
  }
}
