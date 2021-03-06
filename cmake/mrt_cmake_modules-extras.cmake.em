# Generated from: mrt_cmake_modules/cmake/mrt_cmake_modules-extra.cmake.em
if(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_)
    return()
endif()
set(_MRT_CMAKE_MODULES_EXTRAS_INCLUDED_ TRUE)

# Set the cmake install path
@[if DEVELSPACE]@
# cmake dir in develspace
list(APPEND CMAKE_MODULE_PATH "@(CMAKE_CURRENT_SOURCE_DIR)/cmake/Modules")
@[else]@
# cmake dir in installspace
list(APPEND CMAKE_MODULE_PATH "@(PKG_CMAKE_DIR)/Modules")
@[end if]@
set(MCM_ROOT "@(CMAKE_CURRENT_SOURCE_DIR)")

# cache or load environment for non-catkin build
if( NOT DEFINED CATKIN_DEVEL_PREFIX AND EXISTS "${CMAKE_CURRENT_BINARY_DIR}/mrt_cached_variables.cmake")
    message(STATUS "Non-catkin build detected. Loading cached variables from last catkin run.")
    include("${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/mrt_cached_variables.cmake")
else()
    set(_ENV_CMAKE_PREFIX_PATH $ENV{CMAKE_PREFIX_PATH})
    configure_file(${MCM_ROOT}/cmake/Templates/mrt_cached_variables.cmake.in "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/mrt_cached_variables.cmake" @@ONLY)
endif()


# Set build flags to MRT_SANITIZER_CXX_FLAGS based on the current sanitizer configuration
# based on the configruation in the MRT_SANITIZER variable
if(MRT_SANITIZER STREQUAL "checks")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_EXE_CXX_FLAGS "-fsanitize=address,leak,undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_LINK_FLAGS "-static-libasan" "-lubsan")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=undefined,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_EXE_CXX_FLAGS "-fsanitize=address,leak,undefined,float-divide-by-zero,float-cast-overflow" "-fsanitize-recover=alignment")
        set(MRT_SANITIZER_LINK_FLAGS "-static-libasan" "-lubsan")
    endif()
    set(MRT_SANITIZER_ENABLED 1)
elseif(MRT_SANITIZER STREQUAL "check_race")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=thread,undefined,bounds-strict,float-divide-by-zero,float-cast-overflow")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fsanitize=thread,undefined,float-divide-by-zero,float-cast-overflow")
    endif()
    set(MRT_SANITIZER_LINK_FLAGS "-static-libtsan")
    set(MRT_SANITIZER_ENABLED 1)
endif()
if(MRT_SANITIZER_RECOVER STREQUAL "no_recover")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 6.3)
        set(MRT_SANITIZER_CXX_FLAGS "-fno-sanitize-recover=undefined,bounds-strict,float-divide-by-zero,float-cast-overflow" ${MRT_SANITIZER_CXX_FLAGS})
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        set(MRT_SANITIZER_CXX_FLAGS "-fno-sanitize-recover=undefined,float-divide-by-zero,float-cast-overflow" ${MRT_SANITIZER_CXX_FLAGS})
    endif()
endif()


#
# Adds a file or folder or a list of each to the list of files shown by the IDE
# The files will not be marked for installation. Paths should be relative to ``CMAKE_CURENT_LISTS_DIR``
#
# If a file or folder does not exist, it will be ignored without warning.
#
# Example:
# ::
#
#  mrt_add_to_ide(
#      myfile1 myfile2.txt myFolder
#      )
#
# @@public
#
function(mrt_add_to_ide files)
    foreach(ELEMENT ${ARGV})
        if(IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            file(GLOB_RECURSE DIRECTORY_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${ELEMENT}/[^.]*[^~]")
            if(DIRECTORY_FILES)
                STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${ELEMENT})
                add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${DIRECTORY_FILES})
            endif()
        elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-show-${ELEMENT})
            add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${ELEMENT})
        endif()
    endforeach()
endfunction()


#
# Automatically sets up and installs python modules located under ``src/${PROJECT_NAME}``.
# Modules can afterwards simply be included using "import <project_name>" in python.
#
# The python folder (under src/${PROJECT_NAME}) is required to have an __init__.py file.
#
# The command will automatically generate a setup.py in your project folder.
# This file should not be commited, as it will be regenerated at every new CMAKE run.
# Due to restrictions imposed by catkin (searches hardcoded for this setup.py), the file cannot
# be placed elsewhere.
#
# Example:
# ::
#
#   mrt_python_module_setup()
#
# @@public
#
function(mrt_python_module_setup)
    find_package(catkin REQUIRED)
    if(ARGN)
        message(FATAL_ERROR "mrt_python_module_setup() called with unused arguments: ${ARGN}")
    endif()
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/src/${PROJECT_NAME}/__init__.py")
        return()
    endif()
    set(PKG_PYTHON_MODULE ${PROJECT_NAME})
    set(${PROJECT_NAME}_PYTHON_MODULE ${PROJECT_NAME} PARENT_SCOPE)
    set(PACKAGE_DIR "src")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${CMAKE_CURRENT_LIST_DIR}/setup.py" @@ONLY)
    catkin_python_setup()
endfunction()


#
# Generates a python module from boost-python cpp files.
#
# The files are automatically linked with boost-python libraries and a python module is generated
# and installed from the resulting library. If this project declares any libraries with ``mrt_add_library()``, they will automatically be linked with this library.
#
# This function will define the compiler variable ``PYTHON_API_MODULE_NAME`` with the name of the generated library. This can be used in the ``BOOST_PYTHON_MODULE`` C++ Macro.
#
# .. note:: This function can only be called once per package.
#
# :param modulename: Name of the module needs to be passed as first parameter.
# :type modulename: string
# :param FILES: list of C++ files defining the BOOST-Python API.
# :type FILES: list of strings
#
# Example:
# ::
#
#   mrt_add_python_api( example_package
#       FILES python_api/python.cpp
#       )
#
# @@public
#
function(mrt_add_python_api modulename)
    cmake_parse_arguments(MRT_ADD_PYTHON_API "" "" "FILES" ${ARGN})
    if(NOT MRT_ADD_PYTHON_API_FILES)
        return()
    endif()

    #set and check target name
    set( PYTHON_API_MODULE_NAME ${modulename})
    set( TARGET_NAME "${PROJECT_NAME}-${PYTHON_API_MODULE_NAME}-pyapi")
    set( LIBRARY_NAME "${PYTHON_API_MODULE_NAME}_pyapi")
    if("${${PROJECT_NAME}_PYTHON_MODULE}" STREQUAL "${PYTHON_API_MODULE_NAME}")
        message(FATAL_ERROR "The name of the python_api module conflicts with the name of the python module. Please choose a different name")
    endif()

    if("${PYTHON_API_MODULE_NAME}" STREQUAL "${PROJECT_NAME}")
        # mark that catkin_python_setup() was called and the setup.py file contains a package with the same name as the current project
        # in order to disable installation of generated __init__.py files in generate_messages() and generate_dynamic_reconfigure_options()
        set(${PROJECT_NAME}_CATKIN_PYTHON_SETUP_HAS_PACKAGE_INIT TRUE PARENT_SCOPE)
    endif()
    if(${PACKAGE_NAME}_PYTHON_API_TARGET)
        message(FATAL_ERROR "mrt_add_python_api() was already called for this project. You can add only one python_api per project!")
    endif()

    # find pythonLibs
    find_package(BoostPython REQUIRED)
    find_package(PythonLibs 2.7 REQUIRED)
    include_directories(${PYTHON_INCLUDE_DIRS})

    # add library as target
    message(STATUS "Adding python api library \"${LIBRARY_NAME}\" as python module \"${PYTHON_API_MODULE_NAME}\"")
    add_library( ${TARGET_NAME}
        ${MRT_ADD_PYTHON_API_FILES}
        )
    target_compile_definitions(${TARGET_NAME} PRIVATE -DPYTHON_API_MODULE_NAME=lib${LIBRARY_NAME})
    set_target_properties(${TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
        )
    target_link_libraries( ${TARGET_NAME}
        ${PYTHON_LIBRARY}
        ${BoostPython_LIBRARIES}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    add_dependencies(${TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS})

    # append to list of all targets in this project
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_PYTHON_API_TARGET ${TARGET_NAME} PARENT_SCOPE)
    # put in devel folder
    set(PREFIX  ${CATKIN_DEVEL_PREFIX})
    set(PYTHON_MODULE_DIR ${PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_API_MODULE_NAME})
    add_custom_command(TARGET ${TARGET_NAME}
        POST_BUILD
        COMMAND mkdir -p ${PYTHON_MODULE_DIR} && cp -v $<TARGET_FILE:${TARGET_NAME}> ${PYTHON_MODULE_DIR}/$<TARGET_FILE_NAME:${TARGET_NAME}> && echo "from lib${LIBRARY_NAME} import *" > ${PYTHON_MODULE_DIR}/__init__.py
        WORKING_DIRECTORY ${PREFIX}
        COMMENT "Copying library files to python directory"
        )
    # configure setup.py for install
    set(PKG_PYTHON_MODULE ${PYTHON_API_MODULE_NAME})
    set(PACKAGE_DIR ${PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION})
    set(PACKAGE_DATA "*.so*")
    configure_file(${MCM_ROOT}/cmake/Templates/setup.py.in "${CMAKE_CURRENT_BINARY_DIR}/setup.py" @@ONLY)
    configure_file(${MCM_ROOT}/cmake/Templates/python_api_install.sh.in "${CMAKE_CURRENT_BINARY_DIR}/python_api_install.sh" @@ONLY)
    install(CODE "execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/python_api_install.sh)")
endfunction()


#
# Adds a library.
#
# This command ensures the library is compiled with all necessary dependencies. If no files are passed, the command will return silently.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# :param libname: Name of the library to generate as first argument (without lib or .so)
# :type libname: string
# :param INCLUDES: Include files needed for the library, absolute or relative to ${CMAKE_CURRENT_LIST_DIR}
# :type INCLUDES: list of strings
# :param SOURCES: Source files to be added. If empty, a header-only library is assumed
# :type SOURCES: list of strings
# :param DEPENDS: List of extra (non-catkin, non-mrt) dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_library( example_package
#       INCLUDES include/example_package/myclass.h include/example_package/myclass2.h
#       SOURCES src/myclass.cpp src/myclass.cpp
#       )
#
# @@public
#
function(mrt_add_library libname)
    set(LIBRARY_NAME ${libname})
    if(NOT LIBRARY_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_library!")
    endif()
    cmake_parse_arguments(MRT_ADD_LIBRARY "" "" "INCLUDES;SOURCES;DEPENDS;LIBRARIES" ${ARGN})
    set(LIBRARY_TARGET_NAME ${PROJECT_NAME}-${LIBRARY_NAME}-lib)

    if(NOT MRT_ADD_LIBRARY_INCLUDES AND NOT MRT_ADD_LIBRARY_SOURCES)
        return()
    endif()

    # catch header-only libraries
    if(NOT MRT_ADD_LIBRARY_SOURCES)
        # we only set a fake target to make the files show up in IDEs
        message(STATUS "Adding header-only library with files ${MRT_ADD_LIBRARY_INCLUDES}")
        add_custom_target(${LIBRARY_TARGET_NAME} SOURCES ${MRT_ADD_LIBRARY_INCLUDES})
        return()
    endif()

    # generate the target
    message(STATUS "Adding library \"${LIBRARY_NAME}\" with source ${MRT_ADD_LIBRARY_SOURCES}")
    add_library(${LIBRARY_TARGET_NAME}
        ${MRT_ADD_LIBRARY_INCLUDES} ${MRT_ADD_LIBRARY_SOURCES}
        )
    set_target_properties(${LIBRARY_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${LIBRARY_NAME}
        )
    target_compile_options(${LIBRARY_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    add_dependencies(${LIBRARY_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_LIBRARY_DEPENDS})
    target_link_libraries(${LIBRARY_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_LIBRARY_LIBRARIES}
        ${MRT_SANITIZER_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    # add dependency to python_api if existing (needs to be declared before this library)
    if(${PACKAGE_NAME}_PYTHON_API_TARGET)
        target_link_libraries(${${PACKAGE_NAME}_PYTHON_API_TARGET} ${LIBRARY_TARGET_NAME})
    endif()

    # append to list of all targets in this project
    set(${PACKAGE_NAME}_GENERATED_LIBRARIES ${${PACKAGE_NAME}_GENERATED_LIBRARIES} ${LIBRARY_TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${LIBRARY_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds an executable.
#
# This command ensures the executable is compiled with all necessary dependencies.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# :param execname: name of the executable
# :type execname: string
# :param FOLDER: Folder containing the .cpp/.cc-files and .h/.hh/.hpp files for the executable, relative to ``${CMAKE_CURRENT_LIST_DIR}``.
# :type FOLDER: string
# :param FILES: List of extra source files to add. This or the FOLDER parameter is mandatory.
# :type FILES: list of strings
# :param DEPENDS: List of extra (non-catkin, non-mrt) dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_executable( example_package
#       FOLDER src/example_package
#       )
#
# @@public
#
function(mrt_add_executable execname)
    set(EXEC_NAME ${execname})
    if(NOT EXEC_NAME)
        message(FATAL_ERROR "No executable name specified for call to mrt_add_executable()!")
    endif()
    cmake_parse_arguments(MRT_ADD_EXECUTABLE "" "FOLDER" "FILES;DEPENDS;LIBRARIES" ${ARGN})
    if(NOT MRT_ADD_EXECUTABLE_FOLDER AND NOT MRT_ADD_EXECUTABLE_FILES)
        message(FATAL_ERROR "No FOLDER or FILES argument passed to mrt_add_executable()!")
    endif()
    set(EXEC_TARGET_NAME ${PROJECT_NAME}-${EXEC_NAME}-exec)

    # get the files
    if(MRT_ADD_EXECUTABLE_FOLDER)
        file(GLOB_RECURSE EXEC_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_EXECUTABLE_FOLDER}/*.h" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh")
        file(GLOB_RECURSE EXEC_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc")
    endif()
    if(MRT_ADD_EXECUTABLE_FILES)
        list(APPEND EXEC_SOURCE_FILES_SRC ${MRT_ADD_EXECUTABLE_FILES})
        list(REMOVE_DUPLICATES EXEC_SOURCE_FILES_SRC)
    endif()
    if(NOT EXEC_SOURCE_FILES_SRC)
        return()
    endif()

    # generate the target
    message(STATUS "Adding executable \"${EXEC_NAME}\"")
    add_executable(${EXEC_TARGET_NAME}
        ${EXEC_SOURCE_FILES_INC}
        ${EXEC_SOURCE_FILES_SRC}
        )
    set_target_properties(${EXEC_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${EXEC_NAME}
        )
    target_compile_options(${EXEC_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    add_dependencies(${EXEC_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_EXECUTABLE_DEPENDS})
    target_link_libraries(${EXEC_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_EXECUTABLE_LIBRARIES}
        ${MRT_SANITIZER_EXE_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    # append to list of all targets in this project
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${EXEC_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds a nodelet.
#
# This command ensures the nodelet is compiled with all necessary dependencies. Make sure to add lib{NAME}_nodelet to the ``nodelet_plugins.xml`` file.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# It requires a ``*_nodelet.cpp``-File to be present in this folder.
# The command will look for a ``*_node.cpp``-file and remove it from the list of files to avoid ``main()``-functions to be compiled into the library.
#
# :param nodeletname: base name of the nodelet (_nodelet will be appended to the base name to avoid conflicts with library packages)
# :type nodeletname: string
# :param FOLDER: Folder with cpp files for the executable, relative to ``${CMAKE_CURRENT_LIST_DIR}``
# :type FOLDER: string
# :param DEPENDS: List of extra (non-catkin, non-mrt) CMAKE dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
# :param TARGETNAME: Choose the name of the internal CMAKE target. Will be autogenerated if not specified.
# :type TARGETNAME: string
#
# Example:
# ::
#
#   mrt_add_nodelet( example_package
#       FOLDER src/example_package
#       )
#
# The resulting entry in the ``nodelet_plugins.xml`` is thus: <library path="lib/libexample_package_nodelet">
#
# @@public
#
function(mrt_add_nodelet nodeletname)

    set(NODELET_NAME ${nodeletname})
    if(NOT NODELET_NAME)
        message(FATAL_ERROR "No nodelet name specified for call to mrt_add_nodelet()!")
    endif()
    cmake_parse_arguments(MRT_ADD_NODELET "" "FOLDER;TARGETNAME" "DEPENDS;LIBRARIES" ${ARGN})
    if(NOT MRT_ADD_NODELET_TARGETNAME)
        set(NODELET_TARGET_NAME ${PROJECT_NAME}-${NODELET_NAME}-nodelet)
    else()
        set(NODELET_TARGET_NAME ${MRT_ADD_NODELET_TARGETNAME})
    endif()

    # get the files
    file(GLOB NODELET_SOURCE_FILES_INC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*.h" "${MRT_ADD_NODELET_FOLDER}/*.hpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.hh")
    file(GLOB NODELET_SOURCE_FILES_SRC RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*.cpp" "${MRT_ADD_EXECUTABLE_FOLDER}/*.cc")

    # Find nodelet
    file(GLOB NODELET_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*_nodelet.cpp" "${MRT_ADD_NODELET_FOLDER}/*_nodelet.cc")
    if(NOT NODELET_CPP)
        return()
    endif()

    # Remove nodes (with their main) from src-files
    file(GLOB NODE_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NODELET_FOLDER}/*_node.cpp" "${MRT_ADD_NODELET_FOLDER}/*_node.cc")
    if (NODE_CPP)
        list(REMOVE_ITEM NODELET_SOURCE_FILES_SRC ${NODE_CPP})
    endif ()

    # determine library name
    STRING(REGEX REPLACE "_node" "" NODELET_NAME ${NODELET_NAME})
    STRING(REGEX REPLACE "_nodelet" "" NODELET_NAME ${NODELET_NAME})
    set(NODELET_NAME ${NODELET_NAME}_nodelet)

    # generate the target
    message(STATUS "Adding nodelet \"${NODELET_NAME}\"")
    add_library(${NODELET_TARGET_NAME}
        ${NODELET_SOURCE_FILES_INC}
        ${NODELET_SOURCE_FILES_SRC}
        )
    set_target_properties(${NODELET_TARGET_NAME}
        PROPERTIES OUTPUT_NAME ${NODELET_NAME}
        )
    target_compile_options(${NODELET_TARGET_NAME}
        PRIVATE ${MRT_SANITIZER_CXX_FLAGS}
        )
    add_dependencies(${NODELET_TARGET_NAME} ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${MRT_ADD_NODELET_DEPENDS})
    target_link_libraries(${NODELET_TARGET_NAME}
        ${catkin_LIBRARIES}
        ${mrt_LIBRARIES}
        ${MRT_ADD_NODELET_LIBRARIES}
        ${MRT_SANITIZER_CXX_FLAGS}
        ${MRT_SANITIZER_LINK_FLAGS}
        )
    # append to list of all targets in this project
    set(${PACKAGE_NAME}_GENERATED_LIBRARIES ${${PACKAGE_NAME}_GENERATED_LIBRARIES} ${NODELET_TARGET_NAME} PARENT_SCOPE)
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} ${NODELET_TARGET_NAME} PARENT_SCOPE)
endfunction()


#
# Adds a node and a corresponding nodelet.
#
# This command ensures the node/nodelet are compiled with all necessary dependencies. Make sure to add lib{NAME}_nodelet to the ``nodelet_plugins.xml`` file.
#
# .. note:: Make sure to call this after all messages and parameter generation CMAKE-Commands so that all dependencies are visible.
#
# The files are automatically added to the list of installable targets so that ``mrt_install`` can mark them for installation.
#
# It requires a ``*_nodelet.cpp`` file and a ``*_node.cpp`` file to be present in this folder. It will then compile a nodelet-library, create an executable from the ``*_node.cpp`` file and link the executable with the nodelet library.
#
# :param basename: base name of the node/nodelet (_nodelet will be appended for the nodelet name to avoid conflicts with library packages)
# :type basename: string
# :param FOLDER: Folder with cpp files for the executable, relative to ``${CMAKE_CURRENT_LIST_DIR}``
# :type FOLDER: string
# :param DEPENDS: List of extra (non-catkin, non-mrt) CMAKE dependencies. This should only be required for including external projects.
# :type DEPENDS: list of strings
# :param LIBRARIES: Extra (non-catkin, non-mrt) libraries to link to. This should only be required for external projects
# :type LIBRARIES: list of strings
#
# Example:
# ::
#
#   mrt_add_node_and_nodelet( example_package
#       FOLDER src/example_package
#       )
#
# The resulting entry in the ``nodelet_plugins.xml`` is thus: <library path="lib/libexample_package_nodelet">
#
# @@public
#
function(mrt_add_node_and_nodelet basename)
    cmake_parse_arguments(MRT_ADD_NN "" "FOLDER" "DEPENDS;LIBRARIES" ${ARGN})
    set(BASE_NAME ${basename})
    if(NOT BASE_NAME)
        message(FATAL_ERROR "No base name specified for call to mrt_add_node_and_nodelet()!")
    endif()
    set(NODELET_TARGET_NAME ${PROJECT_NAME}-${BASE_NAME}-nodelet)

    # add nodelet
    mrt_add_nodelet(${BASE_NAME}
        FOLDER ${MRT_ADD_NN_FOLDER}
        TARGETNAME ${NODELET_TARGET_NAME}
        DEPENDS ${MRT_ADD_NN_DEPENDS}
        LIBRARIES ${MRT_ADD_NN_LIBRARIES}
        )
    # pass lists on to parent scope
    set(${PACKAGE_NAME}_GENERATED_LIBRARIES ${${PACKAGE_NAME}_GENERATED_LIBRARIES} PARENT_SCOPE)
    set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} PARENT_SCOPE)

    # check if a target was added
    if(NOT TARGET ${NODELET_TARGET_NAME} OR DEFINED MRT_SANITIZER_ENABLED)
        unset(NODELET_TARGET_NAME)
        file(GLOB NODE_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NN_FOLDER}/*.cpp" "${MRT_ADD_NN_FOLDER}/*.cc")
    else()
        file(GLOB NODE_CPP RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NN_FOLDER}/*_node.cpp" "${MRT_ADD_NN_FOLDER}/*_node.cc")
    endif()

    # find node files and add them as executable
    file(GLOB NODE_H RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${MRT_ADD_NN_FOLDER}/*.h" "${MRT_ADD_NN_FOLDER}/*.hpp" "${MRT_ADD_NN_FOLDER}/*.hh")
    if(NODE_CPP)
        mrt_add_executable(${BASE_NAME}
            FILES ${NODE_CPP} ${NODE_H}
            DEPENDS ${MRT_ADD_NN_DEPENDS} ${NODELET_TARGET_NAME}
            LIBRARIES ${MRT_ADD_NN_LIBRARIES} ${NODELET_TARGET_NAME}
            )
        # pass lists on to parent scope
        set(${PACKAGE_NAME}_GENERATED_LIBRARIES ${${PACKAGE_NAME}_GENERATED_LIBRARIES} PARENT_SCOPE)
        set(${PACKAGE_NAME}_MRT_TARGETS ${${PACKAGE_NAME}_MRT_TARGETS} PARENT_SCOPE)
    endif()
endfunction()


#
# Adds all rostests (identified by a .test file) contained in a folder as unittests.
#
# If a .cpp file exists with the same name, it will be added and comiled as a gtest test.
# Unittests can be run with "catkin run_tests" or similar. "-test" will be appended to the name of the test node to avoid conflicts (i.e. the type argument should then be <test ... type="mytest-test"/> in a mytest.test file).
#
# :param folder: folder containing the tests (relative to ``${CMAKE_CURRENT_LIST_DIR}``) as first argument
# :type folder: string
# :param LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
# :type LIBRARIES: list of strings
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
#
# Example:
# ::
#
#   mrt_add_ros_tests( test
#       )
#
# @@public
#
function(mrt_add_ros_tests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_ROS_TESTS "" "" "LIBRARIES;DEPENDS" ${ARGN})
    file(GLOB _ros_tests RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${TEST_FOLDER}/*.test")
    add_custom_target(${PROJECT_NAME}-rostest_test_files SOURCES ${_ros_tests})

    foreach(_ros_test ${_ros_tests})
        get_filename_component(_test_name ${_ros_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_TARGET_NAME ${_test_name})
        set(TEST_TARGET_NAME ${TEST_TARGET_NAME}-test)
        # look for a matching .cpp
        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}/${_test_name}.cpp")
            message(STATUS "Adding gtest-rostest \"${TEST_TARGET_NAME}\" with test file ${_ros_test}")
            add_rostest_gtest(${TEST_TARGET_NAME} ${_ros_test} "${TEST_FOLDER}/${_test_name}.cpp")
            target_compile_options(${TEST_TARGET_NAME}
                PRIVATE ${MRT_SANITIZER_EXE_CXX_FLAGS}
                )
            target_link_libraries(${TEST_TARGET_NAME}
                ${${PACKAGE_NAME}_GENERATED_LIBRARIES}
                ${catkin_LIBRARIES}
                ${mrt_LIBRARIES}
                ${MRT_ADD_ROS_TESTS_LIBRARIES}
                ${MRT_SANITIZER_EXE_CXX_FLAGS}
                ${MRT_SANITIZER_LINK_FLAGS}
                gtest_main
                )
            add_dependencies(${TEST_TARGET_NAME}
                ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PACKAGE_NAME}_MRT_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDS}
                )
            set(TARGET_ADDED True)
        else()
            message(STATUS "Adding plain rostest \"${_ros_test}\"")
            add_rostest(${_ros_test}
                DEPENDENCIES ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PACKAGE_NAME}_MRT_TARGETS} ${MRT_ADD_ROS_TESTS_DEPENDS}
                )
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage)
        setup_target_for_coverage(${PROJECT_NAME}-coverage coverage)
        # make sure the target is built after running tests
        add_dependencies(run_tests ${PROJECT_NAME}-coverage)
        add_dependencies(${PROJECT_NAME}-coverage _run_tests_${PROJECT_NAME})
    endif()
endfunction()

#
# Adds all gtests (without a corresponding .test file) contained in a folder as unittests.
#
# :param folder: folder containing the tests (relative to ``${CMAKE_CURRENT_LIST_DIR}``) as first argument
# :type folder: string
# :param LIBRARIES: Additional (non-catkin, non-mrt) libraries to link to
# :type LIBRARIES: list of strings
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
#
# Example:
# ::
#
#   mrt_add_tests( test
#       )
#
# @@public
#
function(mrt_add_tests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_TESTS "" "" "LIBRARIES;DEPENDS" ${ARGN})
    file(GLOB _tests RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${TEST_FOLDER}/*.cpp" "${TEST_FOLDER}/*.cc")

    foreach(_test ${_tests})
        get_filename_component(_test_name ${_test} NAME_WE)
        # make sure we add only one -test to the target
        STRING(REGEX REPLACE "-test" "" TEST_TARGET_NAME ${_test_name})
        set(TEST_TARGET_NAME ${TEST_TARGET_NAME}-test)
        # exclude cpp files with a test file (those are ros tests)
        if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}/${_test_name}.test")
            message(STATUS "Adding gtest unittest \"${TEST_TARGET_NAME}\" with working dir ${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER}")
            catkin_add_gtest(${TEST_TARGET_NAME} ${_test} WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER})
            target_link_libraries(${TEST_TARGET_NAME}
                ${${PACKAGE_NAME}_GENERATED_LIBRARIES}
                ${catkin_LIBRARIES}
                ${mrt_LIBRARIES}
                ${MRT_ADD_TESTS_LIBRARIES}
                ${MRT_SANITIZER_EXE_CXX_FLAGS}
                ${MRT_SANITIZER_LINK_FLAGS}
                gtest_main)
            target_compile_options(${TEST_TARGET_NAME}
                PRIVATE ${MRT_SANITIZER_EXE_CXX_FLAGS}
                )
            add_dependencies(${TEST_TARGET_NAME}
                ${catkin_EXPORTED_TARGETS} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PACKAGE_NAME}_MRT_TARGETS} ${MRT_ADD_TESTS_DEPENDS}
                )
            set(TARGET_ADDED True)
        endif()
    endforeach()
    if(MRT_ENABLE_COVERAGE AND TARGET_ADDED AND NOT TARGET ${PROJECT_NAME}-coverage)
        setup_target_for_coverage(${PROJECT_NAME}-coverage coverage)
        # make sure the target is built after running tests
        add_dependencies(run_tests ${PROJECT_NAME}-coverage)
        add_dependencies(${PROJECT_NAME}-coverage _run_tests_${PROJECT_NAME})
    endif()
endfunction()


# Adds python nosetest contained in a folder. Wraps the function catkin_add_nosetests.
#
# :param folder: folder containing the tests (relative to ``${CMAKE_CURRENT_LIST_DIR}``) as first argument
# :type folder: string
# :param DEPENDS: Additional (non-catkin, non-mrt) dependencies (e.g. with catkin_download_test_data)
# :type DEPENDS: list of strings
# :param DEPENDENCIES: Alias for DEPENDS
# :type DEPENDENCIES: list of strings
#
# Example:
# ::
#
#   mrt_add_nosetests(test)
#
# @@public
#
function(mrt_add_nosetests folder)
    set(TEST_FOLDER ${folder})
    cmake_parse_arguments(MRT_ADD_NOSETESTS "" "" "DEPENDS;DEPENDENCIES" ${ARGN})
    if(NOT IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${TEST_FOLDER})
        return()
    endif()

    message(STATUS "Adding nosetests in folder ${TEST_FOLDER}")
    catkin_add_nosetests(${TEST_FOLDER}
        DEPENDENCIES ${MRT_ADD_NOSETESTS_DEPENDENCIES} ${${PROJECT_NAME}_EXPORTED_TARGETS} ${${PACKAGE_NAME}_PYTHON_API_TARGET}
        )
endfunction()


# Installs all relevant project files.
#
# All targets added by the mrt_add_<library/executable/nodelet/...> commands will be installed automatically when using this command. Other files/folders (launchfiles, scripts) need to be specified explicitly.
# Non existing files and folders will be silently ignored. All files will be marked as project flies for IDEs.
#
# :param PROGRAMS: List of all folders and files that are programs (python scripts will be indentified and treated separately). Files will be made executable.
# :type PROGRAMS: list of strings
# :param FILES: List of non-executable files and folders. Subfolders will be installed recursively.
# :type FILES: list of strings
#
# Example:
# ::
#
#   mrt_install(
#       PROGRAMS scripts
#       FILES launch nodelet_plugins.xml
#       )
#
# @@public
#
function(mrt_install)
    cmake_parse_arguments(MRT_INSTALL "" "" "PROGRAMS;FILES" ${ARGN})

    # install targets
    if(${PACKAGE_NAME}_MRT_TARGETS)
        message(STATUS "Marking targets \"${${PACKAGE_NAME}_MRT_TARGETS}\" of package \"${PROJECT_NAME}\" for installation")
        install(TARGETS ${${PACKAGE_NAME}_MRT_TARGETS}
            ARCHIVE DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION}
            RUNTIME DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
            )
    endif()

    # install header
    if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/include/${PROJECT_NAME}/)
        message(STATUS "Marking HEADER FILES in \"include\" folder of package \"${PROJECT_NAME}\" for installation")
        install(DIRECTORY include/${PROJECT_NAME}/
            DESTINATION ${CATKIN_PACKAGE_INCLUDE_DESTINATION}
            PATTERN ".gitignore" EXCLUDE
            )
    endif()

    # helper function for installing programs
    function(mrt_install_program program_path)
        get_filename_component(extension ${program_path} EXT)
        get_filename_component(program ${program_path} NAME)
        if("${extension}" STREQUAL ".py")
            message(STATUS "Marking PYTHON PROGRAM \"${program}\" of package \"${PROJECT_NAME}\" for installation")
            catkin_install_python(PROGRAMS ${program_path}
                DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
                )
        else()
            message(STATUS "Marking PROGRAM \"${program}\" of package \"${PROJECT_NAME}\" for installation")
            install(PROGRAMS ${program_path}
                DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
                )
        endif()
        # make it show up in IDEs
        STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${program_path})
        add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${program_path})
    endfunction()

    # install programs
    foreach(ELEMENT ${MRT_INSTALL_PROGRAMS})
        if(IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            file(GLOB FILES "${CMAKE_CURRENT_LIST_DIR}/${ELEMENT}/[^.]*[^~]")
            foreach(FILE ${FILES})
                if(NOT IS_DIRECTORY ${FILE})
                    mrt_install_program(${FILE})
                endif()
            endforeach()
        elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            mrt_install_program(${ELEMENT})
        endif()
    endforeach()

    # install files
    foreach(ELEMENT ${MRT_INSTALL_FILES})
        if(IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            message(STATUS "Marking SHARED CONTENT FOLDER \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(DIRECTORY ${ELEMENT}
                DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
                )
            # make them show up in IDEs
            file(GLOB_RECURSE DIRECTORY_FILES RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "${ELEMENT}/[^.]*[^~]")
            if(DIRECTORY_FILES)
                STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${ELEMENT})
                add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${DIRECTORY_FILES})
            endif()
        elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${ELEMENT})
            message(STATUS "Marking FILE \"${ELEMENT}\" of package \"${PROJECT_NAME}\" for installation")
            install(FILES ${ELEMENT} DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
            STRING(REGEX REPLACE "/" "-" CUSTOM_TARGET_NAME ${PROJECT_NAME}-${ELEMENT})
            add_custom_target(${CUSTOM_TARGET_NAME} SOURCES ${ELEMENT})
        endif()
    endforeach()
endfunction()
