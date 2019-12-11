/* snap_helloworld_python.i */
%include <argcargv.i>
%apply (int ARGC, char **ARGV) { (int argc, char *argv[]) }
%module snap_helloworld_python
%{
 /* Put header files here or function declarations like below */
 extern int mymain(int argc, char *argv[]);
%}
extern int mymain(int argc, char *argv[]);

