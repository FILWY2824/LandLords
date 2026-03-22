cmake_minimum_required(VERSION 3.20)
project(landlords_server LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(LANDLORDS_USE_LOCAL_WINDOWS_DEPS "Use local Windows libevent/protobuf bundle" ON)
option(LANDLORDS_ENABLE_ONNXRUNTIME "Enable ONNX Runtime based bot inference" ON)
set(LANDLORDS_ONNXRUNTIME_ROOT "F:/CodeXProject/LandLords/third_party/onnxruntime/Microsoft.ML.OnnxRuntime.1.24.3" CACHE PATH "ONNX Runtime SDK root")

if(WIN32 AND LANDLORDS_USE_LOCAL_WINDOWS_DEPS)
  set(LANDLORDS_DEPS_ROOT "F:/PersonalProject/Linux/libevent/out/vs2022_64" CACHE PATH "Windows dependency bundle root")
  set(Protobuf_PROTOC_EXECUTABLE "${LANDLORDS_DEPS_ROOT}/protobuf/bin/protoc.exe" CACHE FILEPATH "protoc executable")
  set(Protobuf_INCLUDE_DIR "${LANDLORDS_DEPS_ROOT}/protobuf/include" CACHE PATH "protobuf include")
  set(Protobuf_LIBRARY "${LANDLORDS_DEPS_ROOT}/protobuf/lib/libprotobufd.lib" CACHE FILEPATH "protobuf library")
  set(LANDLORDS_RUNTIME_DLLS
      "${LANDLORDS_DEPS_ROOT}/libevent/lib/event_core.dll"
      "${LANDLORDS_DEPS_ROOT}/libevent/lib/event_extra.dll"
      "${LANDLORDS_DEPS_ROOT}/protobuf/bin/libprotobufd.dll")
  set(CMAKE_PREFIX_PATH
      "${LANDLORDS_DEPS_ROOT}/libevent/lib/cmake/libevent"
      ${CMAKE_PREFIX_PATH})
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

if(WIN32 AND LANDLORDS_USE_LOCAL_WINDOWS_DEPS)
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
