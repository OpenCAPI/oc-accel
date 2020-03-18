# add the executable
add_executable(hdl_perf_test hdl_perf_test.cpp)
target_link_libraries(hdl_perf_test ocaccel pthread)
target_include_directories(hdl_perf_test PRIVATE
    ${OCACCEL_ROOT}/software/include
    .
    )
