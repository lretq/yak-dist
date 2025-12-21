cmake_minimum_required(VERSION 3.31)

project(yak-init)

add_executable(init init.c)
target_link_libraries(init) 

install(TARGETS init RUNTIME DESTINATION bin)
