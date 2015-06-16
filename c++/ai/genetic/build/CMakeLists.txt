cmake_minimum_required(VERSION 2.8)

project(genetic)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/../)

set(CMAKE_BUILD_TYPE Debug)

add_definitions("-Wall -g")
add_definitions("-std=c++0x")

add_executable(genetic ${CMAKE_SOURCE_DIR}/../main.cpp)

