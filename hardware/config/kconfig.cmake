# From https://github.com/zephyrproject-rtos/zephyr/blob/master/cmake/extensions.cmake
# import_kconfig(<prefix> <kconfig_fragment> [<keys>])
#
# Parse a KConfig fragment (typically with extension .config) and
# introduce all the symbols that are prefixed with 'prefix' into the
# CMake namespace. List all created variable names in the 'keys'
# output variable if present.
function(import_kconfig prefix kconfig_fragment)
    # Parse the lines prefixed with 'prefix' in ${kconfig_fragment}
    file(
        STRINGS
        ${kconfig_fragment}
        DOT_CONFIG_LIST
        REGEX "^${prefix}"
        ENCODING "UTF-8"
        )

    foreach (CONFIG ${DOT_CONFIG_LIST})
        # CONFIG could look like: CONFIG_NET_BUF=y

        # Match the first part, the variable name
        string(REGEX MATCH "[^=]+" CONF_VARIABLE_NAME ${CONFIG})

        # Match the second part, variable value
        string(REGEX MATCH "=(.+$)" CONF_VARIABLE_VALUE ${CONFIG})
        # The variable name match we just did included the '=' symbol. To just get the
        # part on the RHS we use match group 1
        set(CONF_VARIABLE_VALUE ${CMAKE_MATCH_1})

        if("${CONF_VARIABLE_VALUE}" MATCHES "^\"(.*)\"$") # Is surrounded by quotes
            set(CONF_VARIABLE_VALUE ${CMAKE_MATCH_1})
        endif()

        set("${CONF_VARIABLE_NAME}" "${CONF_VARIABLE_VALUE}" PARENT_SCOPE)
        list(APPEND keys "${CONF_VARIABLE_NAME}")
    endforeach()

    foreach(outvar ${ARGN})
        set(${outvar} "${keys}" PARENT_SCOPE)
    endforeach()
endfunction()

set(DOTCONFIG                  ${HW_CONFIG_DIR}/.config)
set(KCONFIG                    ${HW_SRC_DIR}/config/Kconfig)

# Force CMAKE configure when the Kconfig sources or configuration files changes.
foreach(kconfig_input
        ${DOTCONFIG}
        ${KCONFIG}
        )
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${kconfig_input})
endforeach()

add_custom_target(
    config

    ${CMAKE_COMMAND} -E env
    OCACCEL_ROOT=${OCACCEL_ROOT}
    OCACCEL_BUILD_DIR=${OCACCEL_BUILD_DIR}
    HW_CONFIG_DIR=${HW_CONFIG_DIR}
    ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
    -q --ocaccel_root ${OCACCEL_ROOT} --ocaccel_build_dir ${OCACCEL_BUILD_DIR}
    config

    WORKING_DIRECTORY ${HW_CONFIG_DIR}
    USES_TERMINAL
    )

execute_process(
    COMMAND
    ${OCACCEL_ROOT}/scripts/workflow/ocaccel_workflow.py
    -q --ocaccel_root ${OCACCEL_ROOT} --ocaccel_build_dir ${OCACCEL_BUILD_DIR}
    config

    OUTPUT_FILE /dev/stdout
    WORKING_DIRECTORY ${HW_CONFIG_DIR}
    # The working directory is set to the app dir such that the user
    # can use relative paths in CONF_FILE, e.g. CONF_FILE=nrf5.conf
    RESULT_VARIABLE ret
    )
if(NOT "${ret}" STREQUAL "0")
    message(FATAL_ERROR "command failed with return code: ${ret}")
endif()

add_custom_target(config-sanitycheck DEPENDS ${DOTCONFIG})

# Parse the lines prefixed with CONFIG_ in the .config file from Kconfig
import_kconfig(CONFIG_ ${DOTCONFIG} kconf_configs)

# Introduce action_name for building dependency between sim and action software
foreach (name ${kconf_configs})
    if("${name}" MATCHES "^CONFIG_ACTION_NAME")
        set(${name} ${${name}} CACHE STRING "")
    endif()
endforeach()
