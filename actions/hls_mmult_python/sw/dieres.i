/*  Example of wrapping a C function that takes a C double array as input using
 *  numpy typemaps for SWIG. */

%module dieres
%{
    /* the resulting C file should be built as a python extension */
    #define SWIG_FILE_WITH_INIT
    /*  Includes the header in the wrapper code */
    #include "dieres.h"
%}

/*  include the numpy typemaps */
%include "numpy.i"
/*  need this for correct module initialization */
%init %{
    import_array();
%}

/*  typemaps for the three arrays, the last will be modified in-place */
%apply (int* IN_ARRAY1, int DIM1) {(int * input_arr_a, int size_in_a)}
%apply (int* IN_ARRAY1, int DIM1) {(int * input_arr_b, int size_in_b)}
%apply (int* INPLACE_ARRAY1, int DIM1) {(int * output_arr_c, int size_out)}


%include "dieres.h"



