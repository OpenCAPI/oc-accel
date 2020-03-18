cmake_minimum_required(VERSION 3.10)
include(CheckLibraryExists)

project(oc-accel)

set(OCSE_PATH "~/oc/ocse")

if (${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "x86_64")
    message ("Running on x86_64 system, build software with OCSE")
    set (SIM_ONLY TRUE)

    # for x86, vivado is required for simulation and bitstream generation
    find_program(VIVADO vivado)
    if(NOT VIVADO)
        message(FATAL_ERROR "Vivado not found!")
    endif()
elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "ppc64le")
    message ("Running on PowerPCsystem, build software with real libocxl")
    set (SIM_ONLY FALSE)

    # make sure libocxl is installed on ppc systems
    find_library (OCXL ocxl)
    if (NOT OCXL)
        message (FATAL_ERROR "No libocxl found on PowerPC systems.")
    endif()
endif()

find_package(Curses REQUIRED)

if (NOT CURSES_FOUND)
    message(FATAL_ERROR "libncurses not found!")
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(OCACCEL_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

add_definitions(-D_GNU_SOURCE=1)

add_subdirectory(software)
add_subdirectory(actions)
