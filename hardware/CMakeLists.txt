set(HW_SRC_DIR        ${CMAKE_CURRENT_SOURCE_DIR})
set(HW_BIN_DIR        ${CMAKE_CURRENT_BINARY_DIR})
set(HW_LOG_DIR        ${HW_BIN_DIR}/logs)
set(HW_OUTPUT_DIR     ${HW_BIN_DIR}/output)

# make build directory for vivado projects
file(MAKE_DIRECTORY ${HW_OUTPUT_DIR})
file(MAKE_DIRECTORY ${HW_OUTPUT_DIR}/interfaces)
file(MAKE_DIRECTORY ${HW_LOG_DIR})

# steps to make a hardware project
foreach(step
        define_interfaces
        package_hostside
        package_infrastructure
        top_project
        )
    add_custom_command (
        OUTPUT ${HW_OUTPUT_DIR}/.${step}
        POST_BUILD

        COMMAND
        OCACCEL_HARDWARE_ROOT=${HW_SRC_DIR}
        OCACCEL_HARDWARE_BUILD_DIR=${HW_BIN_DIR} 
        ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
        -q --ocaccel_root ${OCACCEL_ROOT}
        --make_hw_project ${step}

        DEPENDS ${HW_SRC_DIR}/setup/steps/${step}.tcl
        WORKING_DIRECTORY ${HW_OUTPUT_DIR}
        )
endforeach()

add_custom_command (
    OUTPUT ${HW_OUTPUT_DIR}/.config
    PRE_BUILD

    COMMAND
    ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
    -q --ocaccel_root ${OCACCEL_ROOT}
    config

    DEPENDS ${OCACCEL_ROOT}/scripts/Kconfig
    WORKING_DIRECTORY ${HW_OUTPUT_DIR}
    )

add_custom_target (
    hw_project
    DEPENDS ${HW_OUTPUT_DIR}/.config
    DEPENDS ${HW_OUTPUT_DIR}/.define_interfaces
    WORKING_DIRECTORY ${HW_OUTPUT_DIR}
    )
