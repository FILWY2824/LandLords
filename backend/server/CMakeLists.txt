cmake_minimum_required(VERSION 3.20)
project(landlords_server LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

get_filename_component(LANDLORDS_REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)

function(landlords_init_cache var type description)
  cmake_parse_arguments(ARG "" "DEFAULT;ENV" "" ${ARGN})
  if(DEFINED ${var} AND NOT "${${var}}" STREQUAL "")
    return()
  endif()

  set(value "${ARG_DEFAULT}")
  if(DEFINED ARG_ENV AND
     NOT "${ARG_ENV}" STREQUAL "" AND
     DEFINED ENV{${ARG_ENV}} AND
     NOT "$ENV{${ARG_ENV}}" STREQUAL "")
    set(value "$ENV{${ARG_ENV}}")
  endif()

  set(${var} "${value}" CACHE ${type} "${description}")
endfunction()

function(landlords_normalize_repo_path var)
  if(NOT DEFINED ${var} OR "${${var}}" STREQUAL "")
    return()
  endif()
  if(IS_ABSOLUTE "${${var}}")
    return()
  endif()
  get_property(_cache_type CACHE ${var} PROPERTY TYPE)
  if(NOT _cache_type)
    set(_cache_type PATH)
  endif()
  cmake_path(ABSOLUTE_PATH ${var} BASE_DIRECTORY "${LANDLORDS_REPO_ROOT}" NORMALIZE)
  set(${var} "${${var}}" CACHE ${_cache_type} "Normalized path for ${var}" FORCE)
endfunction()

landlords_init_cache(
  LANDLORDS_ENABLE_ONNXRUNTIME BOOL
  "Enable ONNX Runtime based bot inference"
  DEFAULT ON
  ENV LANDLORDS_ENABLE_ONNXRUNTIME)
landlords_init_cache(
  LANDLORDS_PROTOBUF_ROOT PATH
  "Protobuf SDK root"
  DEFAULT ""
  ENV LANDLORDS_PROTOBUF_ROOT)
landlords_init_cache(
  LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE FILEPATH
  "protoc executable"
  DEFAULT ""
  ENV LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE)
landlords_init_cache(
  LANDLORDS_PROTOBUF_INCLUDE_DIR PATH
  "protobuf include"
  DEFAULT ""
  ENV LANDLORDS_PROTOBUF_INCLUDE_DIR)
landlords_init_cache(
  LANDLORDS_PROTOBUF_LIBRARY FILEPATH
  "protobuf library"
  DEFAULT ""
  ENV LANDLORDS_PROTOBUF_LIBRARY)
landlords_init_cache(
  LANDLORDS_LIBEVENT_ROOT PATH
  "libevent install root"
  DEFAULT ""
  ENV LANDLORDS_LIBEVENT_ROOT)
landlords_init_cache(
  LANDLORDS_LIBEVENT_CMAKE_DIR PATH
  "libevent CMake package directory"
  DEFAULT ""
  ENV LANDLORDS_LIBEVENT_CMAKE_DIR)
landlords_init_cache(
  LANDLORDS_ONNXRUNTIME_ROOT PATH
  "ONNX Runtime SDK root"
  DEFAULT ""
  ENV LANDLORDS_ONNXRUNTIME_ROOT)

landlords_normalize_repo_path(LANDLORDS_PROTOBUF_ROOT)
landlords_normalize_repo_path(LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE)
landlords_normalize_repo_path(LANDLORDS_PROTOBUF_INCLUDE_DIR)
landlords_normalize_repo_path(LANDLORDS_PROTOBUF_LIBRARY)
landlords_normalize_repo_path(LANDLORDS_LIBEVENT_ROOT)
landlords_normalize_repo_path(LANDLORDS_LIBEVENT_CMAKE_DIR)
landlords_normalize_repo_path(LANDLORDS_ONNXRUNTIME_ROOT)

if(LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE)
  set(Protobuf_PROTOC_EXECUTABLE "${LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE}" CACHE FILEPATH
      "protoc executable" FORCE)
endif()
if(LANDLORDS_PROTOBUF_INCLUDE_DIR)
  set(Protobuf_INCLUDE_DIR "${LANDLORDS_PROTOBUF_INCLUDE_DIR}" CACHE PATH
      "protobuf include" FORCE)
endif()
if(LANDLORDS_PROTOBUF_LIBRARY)
  set(Protobuf_LIBRARY "${LANDLORDS_PROTOBUF_LIBRARY}" CACHE FILEPATH
      "protobuf library" FORCE)
endif()
if(LANDLORDS_PROTOBUF_ROOT)
  if(EXISTS "${LANDLORDS_PROTOBUF_ROOT}/lib/libprotobufd.lib")
    set(Protobuf_LIBRARY_DEBUG "${LANDLORDS_PROTOBUF_ROOT}/lib/libprotobufd.lib" CACHE FILEPATH
        "protobuf debug library" FORCE)
  endif()
  if(EXISTS "${LANDLORDS_PROTOBUF_ROOT}/lib/libprotobuf.lib")
    set(Protobuf_LIBRARY_RELEASE "${LANDLORDS_PROTOBUF_ROOT}/lib/libprotobuf.lib" CACHE FILEPATH
        "protobuf release library" FORCE)
  endif()
endif()

if(LANDLORDS_LIBEVENT_CMAKE_DIR)
  list(PREPEND CMAKE_PREFIX_PATH "${LANDLORDS_LIBEVENT_CMAKE_DIR}")
endif()

set(LANDLORDS_RUNTIME_DLLS "")
if(WIN32)
  foreach(_libevent_runtime IN ITEMS
      "${LANDLORDS_LIBEVENT_ROOT}/lib/event_core.dll"
      "${LANDLORDS_LIBEVENT_ROOT}/lib/event_extra.dll")
    if(EXISTS "${_libevent_runtime}")
      list(APPEND LANDLORDS_RUNTIME_DLLS "${_libevent_runtime}")
    endif()
  endforeach()

  if(EXISTS "${LANDLORDS_PROTOBUF_ROOT}/bin/libprotobufd.dll")
    list(APPEND LANDLORDS_RUNTIME_DLLS "${LANDLORDS_PROTOBUF_ROOT}/bin/libprotobufd.dll")
  elseif(EXISTS "${LANDLORDS_PROTOBUF_ROOT}/bin/libprotobuf.dll")
    list(APPEND LANDLORDS_RUNTIME_DLLS "${LANDLORDS_PROTOBUF_ROOT}/bin/libprotobuf.dll")
  endif()
endif()

if(LANDLORDS_ENABLE_ONNXRUNTIME)
  set(LANDLORDS_ONNXRUNTIME_INCLUDE_DIR "${LANDLORDS_ONNXRUNTIME_ROOT}/build/native/include")
  if(WIN32)
    set(LANDLORDS_ONNXRUNTIME_LIBRARY "${LANDLORDS_ONNXRUNTIME_ROOT}/runtimes/win-x64/native/onnxruntime.lib")
    set(LANDLORDS_ONNXRUNTIME_DLL "${LANDLORDS_ONNXRUNTIME_ROOT}/runtimes/win-x64/native/onnxruntime.dll")
  else()
    set(LANDLORDS_ONNXRUNTIME_LIBRARY "${LANDLORDS_ONNXRUNTIME_ROOT}/runtimes/linux-x64/native/libonnxruntime.so")
  endif()

  if(NOT EXISTS "${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}/onnxruntime_cxx_api.h")
    message(FATAL_ERROR "LANDLORDS_ENABLE_ONNXRUNTIME=ON but ONNX Runtime headers were not found under LANDLORDS_ONNXRUNTIME_ROOT")
  endif()
  if(NOT EXISTS "${LANDLORDS_ONNXRUNTIME_LIBRARY}")
    message(FATAL_ERROR "LANDLORDS_ENABLE_ONNXRUNTIME=ON but ONNX Runtime library was not found under LANDLORDS_ONNXRUNTIME_ROOT")
  endif()
  if(WIN32)
    list(APPEND LANDLORDS_RUNTIME_DLLS "${LANDLORDS_ONNXRUNTIME_DLL}")
  endif()
endif()

find_package(Protobuf REQUIRED)
find_package(Libevent CONFIG REQUIRED)

add_executable(landlords_server
  src/bid_strategy.cpp
  src/bot_strategy.cpp
  src/logging.cpp
  src/main.cpp
  src/models.cpp
  src/onnx_bot_strategy.cpp
  src/file_friend_request_repository.cpp
  src/file_system_repository.cpp
  src/file_user_repository.cpp
  src/room.cpp
  src/game_service.cpp
  src/tcp_server.cpp
  generated/landlords.pb.cc
)

add_executable(landlords_room_tests
  tests/room_simulation_test.cpp
  src/bid_strategy.cpp
  src/logging.cpp
  src/models.cpp
  src/room.cpp
  generated/landlords.pb.cc
)

add_executable(landlords_friend_center_tests
  tests/friend_center_service_test.cpp
  src/bid_strategy.cpp
  src/bot_strategy.cpp
  src/file_friend_request_repository.cpp
  src/file_system_repository.cpp
  src/file_user_repository.cpp
  src/game_service.cpp
  src/logging.cpp
  src/models.cpp
  src/onnx_bot_strategy.cpp
  src/room.cpp
  generated/landlords.pb.cc
)

add_executable(landlords_room_lifecycle_tests
  tests/room_lifecycle_service_test.cpp
  src/bid_strategy.cpp
  src/bot_strategy.cpp
  src/file_friend_request_repository.cpp
  src/file_system_repository.cpp
  src/file_user_repository.cpp
  src/game_service.cpp
  src/logging.cpp
  src/models.cpp
  src/onnx_bot_strategy.cpp
  src/room.cpp
  generated/landlords.pb.cc
)

if(LANDLORDS_ENABLE_ONNXRUNTIME)
  add_executable(landlords_onnx_tests
    tests/onnx_strategy_test.cpp
    src/bid_strategy.cpp
    src/logging.cpp
    src/models.cpp
    src/onnx_bot_strategy.cpp
    src/room.cpp
    generated/landlords.pb.cc
  )

  add_executable(landlords_strategy_benchmark
    tests/strategy_benchmark.cpp
    src/logging.cpp
    src/models.cpp
    src/onnx_bot_strategy.cpp
    src/room.cpp
    src/bid_strategy.cpp
    generated/landlords.pb.cc
  )

  add_executable(landlords_onnx_decision_cli
    tests/onnx_decision_cli.cpp
    src/logging.cpp
    src/models.cpp
    src/onnx_bot_strategy.cpp
    generated/landlords.pb.cc
  )
endif()

target_include_directories(landlords_server PRIVATE
  include
  generated
  ${Protobuf_INCLUDE_DIRS}
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}>
)

target_include_directories(landlords_room_tests PRIVATE
  include
  generated
  ${Protobuf_INCLUDE_DIRS}
)

target_include_directories(landlords_friend_center_tests PRIVATE
  include
  generated
  ${Protobuf_INCLUDE_DIRS}
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}>
)

target_include_directories(landlords_room_lifecycle_tests PRIVATE
  include
  generated
  ${Protobuf_INCLUDE_DIRS}
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}>
)

if(LANDLORDS_ENABLE_ONNXRUNTIME)
  target_include_directories(landlords_onnx_tests PRIVATE
    include
    generated
    ${Protobuf_INCLUDE_DIRS}
    ${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}
  )

  target_include_directories(landlords_strategy_benchmark PRIVATE
    include
    generated
    ${Protobuf_INCLUDE_DIRS}
    ${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}
  )

  target_include_directories(landlords_onnx_decision_cli PRIVATE
    include
    generated
    ${Protobuf_INCLUDE_DIRS}
    ${LANDLORDS_ONNXRUNTIME_INCLUDE_DIR}
  )
endif()

target_link_libraries(landlords_server PRIVATE
  protobuf::libprotobuf
  libevent::core
  libevent::extra
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_LIBRARY}>
)

target_link_libraries(landlords_room_tests PRIVATE
  protobuf::libprotobuf
)

target_link_libraries(landlords_friend_center_tests PRIVATE
  protobuf::libprotobuf
  libevent::core
  libevent::extra
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_LIBRARY}>
)

target_link_libraries(landlords_room_lifecycle_tests PRIVATE
  protobuf::libprotobuf
  libevent::core
  libevent::extra
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:${LANDLORDS_ONNXRUNTIME_LIBRARY}>
)

if(LANDLORDS_ENABLE_ONNXRUNTIME)
  target_link_libraries(landlords_onnx_tests PRIVATE
    protobuf::libprotobuf
    ${LANDLORDS_ONNXRUNTIME_LIBRARY}
  )

  target_link_libraries(landlords_strategy_benchmark PRIVATE
    protobuf::libprotobuf
    ${LANDLORDS_ONNXRUNTIME_LIBRARY}
  )

  target_link_libraries(landlords_onnx_decision_cli PRIVATE
    protobuf::libprotobuf
    ${LANDLORDS_ONNXRUNTIME_LIBRARY}
  )
endif()

target_compile_definitions(landlords_server PRIVATE
  $<$<BOOL:${WIN32}>:NOMINMAX>
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:LANDLORDS_WITH_ONNXRUNTIME>
)

target_compile_definitions(landlords_room_tests PRIVATE
  $<$<BOOL:${WIN32}>:NOMINMAX>
)

target_compile_definitions(landlords_friend_center_tests PRIVATE
  $<$<BOOL:${WIN32}>:NOMINMAX>
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:LANDLORDS_WITH_ONNXRUNTIME>
)

target_compile_definitions(landlords_room_lifecycle_tests PRIVATE
  $<$<BOOL:${WIN32}>:NOMINMAX>
  $<$<BOOL:${LANDLORDS_ENABLE_ONNXRUNTIME}>:LANDLORDS_WITH_ONNXRUNTIME>
)

if(LANDLORDS_ENABLE_ONNXRUNTIME)
  target_compile_definitions(landlords_onnx_tests PRIVATE
    $<$<BOOL:${WIN32}>:NOMINMAX>
    LANDLORDS_WITH_ONNXRUNTIME
  )

  target_compile_definitions(landlords_strategy_benchmark PRIVATE
    $<$<BOOL:${WIN32}>:NOMINMAX>
    LANDLORDS_WITH_ONNXRUNTIME
  )

  target_compile_definitions(landlords_onnx_decision_cli PRIVATE
    $<$<BOOL:${WIN32}>:NOMINMAX>
    LANDLORDS_WITH_ONNXRUNTIME
  )
endif()

if(WIN32)
  foreach(runtime_dll IN LISTS LANDLORDS_RUNTIME_DLLS)
    add_custom_command(TARGET landlords_server POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${runtime_dll}"
              "$<TARGET_FILE_DIR:landlords_server>"
    )
    add_custom_command(TARGET landlords_room_tests POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${runtime_dll}"
              "$<TARGET_FILE_DIR:landlords_room_tests>"
    )
    add_custom_command(TARGET landlords_friend_center_tests POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${runtime_dll}"
              "$<TARGET_FILE_DIR:landlords_friend_center_tests>"
    )
    if(LANDLORDS_ENABLE_ONNXRUNTIME)
      add_custom_command(TARGET landlords_onnx_tests POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${runtime_dll}"
                "$<TARGET_FILE_DIR:landlords_onnx_tests>"
      )
      add_custom_command(TARGET landlords_strategy_benchmark POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${runtime_dll}"
                "$<TARGET_FILE_DIR:landlords_strategy_benchmark>"
      )
      add_custom_command(TARGET landlords_onnx_decision_cli POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${runtime_dll}"
                "$<TARGET_FILE_DIR:landlords_onnx_decision_cli>"
      )
    endif()
  endforeach()
endif()
