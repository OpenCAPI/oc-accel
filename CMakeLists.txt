cmake_minimum_required(VERSION 3.17)

project(oc-accel)
set(OCACCEL_ROOT        ${CMAKE_CURRENT_SOURCE_DIR})
set(OCACCEL_BUILD_DIR   ${CMAKE_CURRENT_BINARY_DIR})

if (${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "x86_64")
    message("Running on x86_64 system, build software with OCSE")
    set(OCSE_PATH ${OCACCEL_ROOT}/hardware/sim/ocse)
    set(SIM_ONLY TRUE)

    # for x86, vivado is required for simulation and bitstream generation
    find_program(VIVADO vivado)
    if(NOT VIVADO)
        message(FATAL_ERROR "Vivado not found!")
    endif()
elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "ppc64le")
    message("Running on PowerPCsystem, build software with real libocxl")
    set(SIM_ONLY FALSE)

    # make sure libocxl is installed on ppc systems
    find_library(OCXL ocxl)
    if (NOT OCXL)
        message (FATAL_ERROR "No libocxl found on PowerPC systems.")
    endif()
endif()

# Make sure python is correctly installed
find_package(Python COMPONENTS REQUIRED Interpreter)

if (NOT Python_FOUND)
    message(FATAL_ERROR "No python executable found!")
endif()

# Make sure we have pip installed
find_program(PIP pip)
if (NOT PIP)
    message(FATAL_ERROR "pip not found!")
endif()

# Define variables used in this project
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# add common compiler flags
add_definitions(-D_GNU_SOURCE=1)

# add software projects
add_subdirectory(software)
add_subdirectory(actions)

# hardware projects are only available in x86 systems
if (${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "x86_64")
    # hardware projects all depends on vivado
    add_subdirectory(hardware)
endif()
