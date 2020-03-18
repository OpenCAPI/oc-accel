if (${SIM_ONLY})
    add_library(ocxl SHARED ${OCSE_PATH}/libocxl/libocxl.c ${OCSE_PATH}/common/debug.c ${OCSE_PATH}/common/utils.c)
    set_property(TARGET ocxl PROPERTY INTERFACE_POSITION_INDEPENDENT_CODE ON)
    target_include_directories(ocxl PRIVATE ${OCSE_PATH}/libocxl)
endif()

add_library(ocaccel SHARED ./lib/ocaccel.c ./lib/ocaccel_job_manager.cpp)
set_property(TARGET ocaccel PROPERTY INTERFACE_POSITION_INDEPENDENT_CODE ON)
target_include_directories(ocaccel PRIVATE
    ./include
    ${OCSE_PATH}/libocxl)
target_link_libraries(ocaccel ocxl)

# add the executable
add_executable(ocaccel_maint ./tools/ocaccel_maint.c)
target_link_libraries(ocaccel_maint ocxl ocaccel pthread)
if (${SIM_ONLY})
    target_include_directories(ocaccel_maint PRIVATE 
        ${OCSE_PATH}/libocxl
        )
endif()
target_include_directories(ocaccel_maint PRIVATE
    ./include)

# add the executable
add_executable(ocaccel_peek ./tools/ocaccel_peek.c ./tools/force_cpu.c)
target_link_libraries(ocaccel_peek ocxl ocaccel pthread)
if (${SIM_ONLY})
    target_include_directories(ocaccel_peek PRIVATE 
        ${OCSE_PATH}/libocxl
        )
endif()
target_include_directories(ocaccel_peek PRIVATE
    ./include
    ./tools)

# add the executable
add_executable(ocaccel_poke ./tools/ocaccel_poke.c ./tools/force_cpu.c)
target_link_libraries(ocaccel_poke ocxl ocaccel pthread)
if (${SIM_ONLY})
    target_include_directories(ocaccel_poke PRIVATE 
        ${OCSE_PATH}/libocxl
        )
endif()
target_include_directories(ocaccel_poke PRIVATE
    ./include
    ./tools)
