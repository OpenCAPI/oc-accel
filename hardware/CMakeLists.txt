set(HW_SRC_DIR        ${CMAKE_CURRENT_SOURCE_DIR})
set(HW_BIN_DIR        ${CMAKE_CURRENT_BINARY_DIR})
set(HW_LOG_DIR        ${HW_BIN_DIR}/logs)
set(HW_OUTPUT_DIR     ${HW_BIN_DIR}/output)

set(HW_INTF_OUTPUT_DIR  ${HW_OUTPUT_DIR}/interfaces)
set(HW_IP_REPO_DIR      ${HW_OUTPUT_DIR}/ip_repo)
set(HW_IP_HLS_DIR       ${HW_OUTPUT_DIR}/hls)

# make build directory for vivado projects
file(MAKE_DIRECTORY ${HW_OUTPUT_DIR})
file(MAKE_DIRECTORY ${HW_LOG_DIR})
file(MAKE_DIRECTORY ${HW_INTF_OUTPUT_DIR})
file(MAKE_DIRECTORY ${HW_IP_REPO_DIR})
file(MAKE_DIRECTORY ${HW_IP_HLS_DIR})

# steps to make a hardware project
foreach(step
        define_interfaces
        package_hostside
        package_infrastructure
        package_kernel_helper
        action_hw
        top_project
        )
    add_custom_command (
        OUTPUT ${HW_OUTPUT_DIR}/.${step}
        POST_BUILD

        COMMAND
        ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
        -q --ocaccel_root ${OCACCEL_ROOT} --ocaccel_build_dir ${OCACCEL_BUILD_DIR}
        --make_hw_project ${step}

        # DEPENDS <add dependencies here> -- TODO
        WORKING_DIRECTORY ${HW_OUTPUT_DIR}
        )
endforeach()

add_custom_command (
    OUTPUT ${HW_OUTPUT_DIR}/.config
    POST_BUILD

    COMMAND
    ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
    -q --ocaccel_root ${OCACCEL_ROOT} --ocaccel_build_dir ${OCACCEL_BUILD_DIR}
    config

    DEPENDS ${OCACCEL_ROOT}/scripts/Kconfig
    WORKING_DIRECTORY ${HW_OUTPUT_DIR}
    )

add_custom_target (
    config
    DEPENDS ${HW_OUTPUT_DIR}/.config
    )

add_custom_target (
    hw_project
    DEPENDS ${HW_OUTPUT_DIR}/.config
    DEPENDS ${HW_OUTPUT_DIR}/.define_interfaces
    DEPENDS ${HW_OUTPUT_DIR}/.package_hostside
    DEPENDS ${HW_OUTPUT_DIR}/.package_infrastructure
    DEPENDS ${HW_OUTPUT_DIR}/.package_kernel_helper
    DEPENDS ${HW_OUTPUT_DIR}/.action_hw
    DEPENDS ${HW_OUTPUT_DIR}/.top_project
    WORKING_DIRECTORY ${HW_OUTPUT_DIR}
    )
