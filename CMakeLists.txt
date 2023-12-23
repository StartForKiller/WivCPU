cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0074 NEW)
project(WivCPU)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator not found")
endif()

include(FetchContent)
FetchContent_Declare(
    SFML
    GIT_REPOSITORY https://github.com/SFML/SFML.git
    GIT_TAG 2.6.0
)
FetchContent_MakeAvailable(SFML)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED true)

set(CMAKE_CXX_FLAGS_DEBUG "-O2")

add_executable(wivcpu src/sim.cpp)
target_link_libraries(wivcpu PRIVATE sfml-graphics sfml-window sfml-system)
target_include_directories(wivcpu PRIVATE ${SFML_SOURCE_DIR}/include)

verilate(wivcpu INCLUDE_DIRS "rtl/" "rtl/core/" "rtl/core/stages/" "rtl/core/cache/" "rtl/core/regs/" "rtl/core/debug/" "rtl/peripherals/" SOURCES rtl/top.sv rtl/core/defines.sv TRACE)