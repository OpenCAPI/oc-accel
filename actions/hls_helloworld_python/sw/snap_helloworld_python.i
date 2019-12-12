/* snap_helloworld_python.i */
%module snap_helloworld_python
%include "cstring.i"
%cstring_bounded_output(char *output_str, 1024);
%{
 /* Put header files here or function declarations like below */
 extern int uppercase(char *input_str, char *output_str);
%}
extern int uppercase(char *input_str, char *output_str);
