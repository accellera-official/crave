#[=======================================================================[.rst:
FindUVM-SystemC
-------

Finds UVM-SystemC and provides an imported target.

Imported Targets
^^^^^^^^^^^^^^^^
``UVM::uvm-systemc``
  The UVM-SystemC library

Result Variables
^^^^^^^^^^^^^^^^
``UVM_SystemC_FOUND``
``UVM_SystemC_INCLUDE_DIRS``
``UVM_SystemC_LIBRARIES``
#]=======================================================================]

if(DEFINED ENV{UVM_SYSTEMC_HOME} AND NOT UVM_SYSTEMC_HOME)
  set(UVM_SYSTEMC_HOME "$ENV{UVM_SYSTEMC_HOME}")
endif()

find_path(UVM_SystemC_INCLUDE_DIR
  HINTS
    ${UVM_SYSTEMC_HOME}/include
    $ENV{UVM_SYSTEMC_HOME}/include
  NAMES
    uvm.h
)

find_library(UVM_SystemC_LIBRARY
  HINTS
    ${UVM_SYSTEMC_HOME}/lib
    ${UVM_SYSTEMC_HOME}/lib-linux
    ${UVM_SYSTEMC_HOME}/lib-linux64
    ${UVM_SYSTEMC_HOME}/lib-macos
    $ENV{UVM_SYSTEMC_HOME}/lib
    $ENV{UVM_SYSTEMC_HOME}/lib-linux
    $ENV{UVM_SYSTEMC_HOME}/lib-linux64
    $ENV{UVM_SYSTEMC_HOME}/lib-macos
  NAMES
    uvm-systemc
)

set(UVM_SystemC_INCLUDE_DIRS ${UVM_SystemC_INCLUDE_DIR})
set(UVM_SystemC_LIBRARIES ${UVM_SystemC_LIBRARY})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(UVM-SystemC
  REQUIRED_VARS
    UVM_SystemC_INCLUDE_DIR
    UVM_SystemC_LIBRARY
)

if(UVM_SystemC_FOUND AND NOT TARGET UVM::uvm-systemc)
  add_library(UVM::uvm-systemc UNKNOWN IMPORTED)
  set_target_properties(UVM::uvm-systemc PROPERTIES
    IMPORTED_LOCATION ${UVM_SystemC_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES "${UVM_SystemC_INCLUDE_DIRS}"
  )
endif()

mark_as_advanced(UVM_SystemC_INCLUDE_DIRS UVM_SystemC_LIBRARIES)
