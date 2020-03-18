# Require boost lib
find_package(Boost 1.65 REQUIRED COMPONENTS
                 program_options)

message("boost lib: ${Boost_LIBRARIES}")
if (NOT Boost_FOUND)
    message(FATAL_ERROR "libboost_program_options not found!")
endif()

# add the executable
add_executable(hls_vadd hls_vadd.cpp)
target_link_libraries(hls_vadd ocaccel boost_program_options)
target_include_directories(hls_vadd PRIVATE
    ${OCACCEL_ROOT}/software/include
    .
    )
