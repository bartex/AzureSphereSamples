IF(NOT ${CMAKE_GENERATOR} STREQUAL "Ninja")
    MESSAGE(FATAL_ERROR "Azure Sphere CMake projects must use the Ninja generator")
ENDIF()

SET(AZURE_SPHERE_MAKE_IMAGE_FILE "${AZURE_SPHERE_CMAKE_PATH}/AzureSphereMakeImage.cmake" CACHE INTERNAL "Path to the MakeImage CMake target")

# Get API set from environment set from input variables
IF(DEFINED AZURE_SPHERE_TARGET_API_SET)
    SET(ENV{AzureSphereTargetApiSet} ${AZURE_SPHERE_TARGET_API_SET})
ENDIF()
SET(AZURE_SPHERE_TARGET_API_SET $ENV{AzureSphereTargetApiSet})

# Get available API sets
FILE(GLOB AZURE_SPHERE_AVAILABLE_API_SETS RELATIVE "${AZURE_SPHERE_SDK_PATH}/Sysroots" "${AZURE_SPHERE_SDK_PATH}/Sysroots/*")

# Set include paths and check if given API set is valid
SET(AZURE_SPHERE_API_SET_VALID 0)
FOREACH(AZURE_SPHERE_API_SET ${AZURE_SPHERE_AVAILABLE_API_SETS})
    SET(ENV{INCLUDE} "${AZURE_SPHERE_SDK_PATH}/Sysroots/${AZURE_SPHERE_API_SET}/usr/include;$ENV{INCLUDE}")
    IF("${AZURE_SPHERE_TARGET_API_SET}" STREQUAL "${AZURE_SPHERE_API_SET}")
        SET(AZURE_SPHERE_API_SET_VALID 1)
    ENDIF()
ENDFOREACH()

IF(NOT AZURE_SPHERE_API_SET_VALID)
    # Create API set list
    SET(AZURE_SPHERE_API_SET_LIST "[\"${AZURE_SPHERE_AVAILABLE_API_SETS}\"]")
    STRING(REPLACE ";" "\", \"" AZURE_SPHERE_API_SET_LIST "${AZURE_SPHERE_API_SET_LIST}")
    # Change error message depending on whether it's set
    IF("${AZURE_SPHERE_TARGET_API_SET}" STREQUAL "")
        MESSAGE(FATAL_ERROR "Variable AZURE_SPHERE_TARGET_API_SET is not set. "
            "Please set this variable to one of the available API sets: ${AZURE_SPHERE_API_SET_LIST}")
    ELSE()
        MESSAGE(FATAL_ERROR "API set \"${AZURE_SPHERE_TARGET_API_SET}\" is not valid. "
            "Valid API sets are: ${AZURE_SPHERE_API_SET_LIST}")
    ENDIF()
ENDIF()

SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Get hardware definition directory
IF(DEFINED AZURE_SPHERE_TARGET_HARDWARE_DEFINITION_DIRECTORY)
    SET(ENV{AzureSphereTargetHardwareDefinitionDirectory} ${AZURE_SPHERE_TARGET_HARDWARE_DEFINITION_DIRECTORY})
ENDIF()
SET(AZURE_SPHERE_HW_DIRECTORY $ENV{AzureSphereTargetHardwareDefinitionDirectory})

# Get hardware definition json
IF(DEFINED AZURE_SPHERE_TARGET_HARDWARE_DEFINITION)
    SET(ENV{AzureSphereTargetHardwareDefinition} ${AZURE_SPHERE_TARGET_HARDWARE_DEFINITION})
ENDIF()
SET(AZURE_SPHERE_HW_DEFINITION $ENV{AzureSphereTargetHardwareDefinition})

# Check if the hardware definition file exists at the specified path
IF((NOT ("${AZURE_SPHERE_HW_DEFINITION}" STREQUAL "")) AND (NOT ("${AZURE_SPHERE_HW_DIRECTORY}" STREQUAL "")))
    IF(NOT EXISTS "${AZURE_SPHERE_HW_DIRECTORY}/${AZURE_SPHERE_HW_DEFINITION}")
        MESSAGE(FATAL_ERROR "${AZURE_SPHERE_HW_DIRECTORY}/${AZURE_SPHERE_HW_DEFINITION} does not exist")
    ELSEIF(EXISTS "${AZURE_SPHERE_HW_DIRECTORY}/${AZURE_SPHERE_HW_DEFINITION}" AND IS_DIRECTORY "${AZURE_SPHERE_HW_DIRECTORY}/${AZURE_SPHERE_HW_DEFINITION}")
        MESSAGE(FATAL_ERROR "${AZURE_SPHERE_HW_DIRECTORY}/${AZURE_SPHERE_HW_DEFINITION} is a directory")
    ENDIF()
ENDIF()

# Disable linking during try_compile since our link options cause the generation to fail
SET(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "Disable linking for try_compile")

# Add ComponentId to app_manifest if necessary
IF(EXISTS "${CMAKE_SOURCE_DIR}/app_manifest.json")
    FILE(READ "${CMAKE_SOURCE_DIR}/app_manifest.json" AZURE_SPHERE_APP_MANIFEST_CONTENTS)
    STRING(REGEX MATCH "\"ComponentId\": \"([^\"]*)\"" AZURE_SPHERE_COMPONENTID "${AZURE_SPHERE_APP_MANIFEST_CONTENTS}")
    SET(AZURE_SPHERE_COMPONENTID_VALUE "${CMAKE_MATCH_1}")
    # CMake Regex doesn't support syntax for matching exact number of characters, so we get to do guid matching the fun way
    SET(AZURE_SPHERE_GUID_REGEX "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_2 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_3 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_4 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_5 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    STRING(APPEND AZURE_SPHERE_GUID_REGEX "-" ${AZURE_SPHERE_GUID_REGEX_2} "-" ${AZURE_SPHERE_GUID_REGEX_3} "-" ${AZURE_SPHERE_GUID_REGEX_4} "-" ${AZURE_SPHERE_GUID_REGEX_5})
    STRING(REGEX MATCH "${AZURE_SPHERE_GUID_REGEX}" AZURE_SPHERE_COMPONENTID_GUID "${AZURE_SPHERE_COMPONENTID_VALUE}")
    IF("${AZURE_SPHERE_COMPONENTID_GUID}" STREQUAL "")
        # Generate random GUID
        STRING(RANDOM LENGTH 8 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_2)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_3)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_4)
        STRING(RANDOM LENGTH 12 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_5)
        STRING(APPEND AZURE_SPHERE_GUID "-" ${AZURE_SPHERE_GUID_2} "-" ${AZURE_SPHERE_GUID_3} "-" ${AZURE_SPHERE_GUID_4} "-" ${AZURE_SPHERE_GUID_5})
        # Write GUID to ComponentId
        STRING(REGEX REPLACE "\"ComponentId\": \"[^\"]*\"" "\"ComponentId\": \"${AZURE_SPHERE_GUID}\"" AZURE_SPHERE_APP_MANIFEST_CONTENTS "${AZURE_SPHERE_APP_MANIFEST_CONTENTS}")
        FILE(WRITE "${CMAKE_SOURCE_DIR}/app_manifest.json" ${AZURE_SPHERE_APP_MANIFEST_CONTENTS})
    ENDIF()
ENDIF()
