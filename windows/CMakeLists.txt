cmake_minimum_required(VERSION 3.14)
project(medios LANGUAGES CXX)

set(BINARY_NAME "MediOS")
set(APPLICATION_ID "com.medios.pharmacy")

cmake_policy(SET CMP0063 NEW)
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

flutter_add_executable_wrapper(medios WIN32_MANIFEST windows/runner/runner.exe.manifest)

install(TARGETS medios RUNTIME DESTINATION .)
