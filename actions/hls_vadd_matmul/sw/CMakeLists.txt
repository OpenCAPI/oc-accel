# Require boost lib
find_package(Boost 1.65 REQUIRED COMPONENTS
                 program_options)

if (NOT Boost_FOUND)
    message(FATAL_ERROR "libboost_program_options not found!")
endif()

# add the executable
add_executable(hls_vadd_matmul hls_vadd_matmul.cpp)
target_link_libraries(hls_vadd_matmul ocaccel ${Boost_LIBRARIES})
target_include_directories(hls_vadd_matmul PRIVATE
    ${OCACCEL_ROOT}/software/include
    .
    )
