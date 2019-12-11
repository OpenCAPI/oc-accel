/* snap_helloworld_python.i */
%include <argcargv.i>
%apply (int ARGC, char **ARGV) { (int argc, char *argv[]) }
%module snap_helloworld_python
%{
 /* Put header files here or function declarations like below */
 extern int uppercase(char *input_str, char *output_str);
%}
extern int uppercase(char *input_str, char *output_str);

