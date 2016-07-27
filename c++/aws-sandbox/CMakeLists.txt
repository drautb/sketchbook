#Change this if you need to target a specific CMake version
cmake_minimum_required(VERSION 2.6)

# Enable debug symbols by default
# must be done before project() statement
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build (Debug or Release)" FORCE)
endif()
# (you can also set it on the command line: -D CMAKE_BUILD_TYPE=Release)

project(aws-sandbox)

# Define sources and executable
set(EXECUTABLE_NAME "aws-sandbox")
add_executable(${EXECUTABLE_NAME} main.cpp)

# AWS SDK
set(aws-sdk-cpp_DIR "/Users/drautb/GitHub/aws/aws-sdk-cpp")
find_package(aws-sdk-cpp REQUIRED)
if (aws-sdk-cpp_FOUND)
  include_directories("${aws-sdk-cpp_DIR}/aws-cpp-sdk-core/include")
  include_directories("${aws-sdk-cpp_DIR}/aws-cpp-sdk-cloudformation/include")
  target_link_libraries(${EXECUTABLE_NAME} aws-cpp-sdk-cloudformation)
endif()

# Install target
install(TARGETS ${EXECUTABLE_NAME} DESTINATION bin)
