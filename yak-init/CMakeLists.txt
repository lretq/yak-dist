cmake_minimum_required(VERSION 3.31)

project(yak-init)

find_package(PkgConfig REQUIRED)
pkg_check_modules(READLINE REQUIRED IMPORTED_TARGET GLOBAL readline)

add_executable(init init.c)

target_link_libraries(init PUBLIC
	PkgConfig::READLINE) 

install(TARGETS init RUNTIME DESTINATION bin)
