cmake_minimum_required(VERSION 3.22)
project(zauxoflix_seek_frames LANGUAGES C)

include(FetchContent)
# fvp 0.37.3 ships libffmpeg built from this revision. Only headers are
# compiled here. The reader checks the library's ABI before opening video.
FetchContent_Declare(ffmpeg_headers
    URL https://codeload.github.com/FFmpeg/FFmpeg/tar.gz/464fc8c2ed53648b9ede81555921e3995d32bbe5
    URL_HASH SHA256=a83944df2ba0758a6fa23e9a9fd1d7ed5fb8ca6771e164eef064f77cf1d2a0bb)
FetchContent_MakeAvailable(ffmpeg_headers)
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-config/libavutil")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-config/libavutil/avconfig.h"
    "#define AV_HAVE_BIGENDIAN 0\n#define AV_HAVE_FAST_UNALIGNED 0\n")

add_library(zauxoflix_seek_frames SHARED
    ../../../../../tools/webos/seek-frames.c)
target_include_directories(zauxoflix_seek_frames SYSTEM PRIVATE
    "${ffmpeg_headers_SOURCE_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg-config")
target_compile_options(zauxoflix_seek_frames PRIVATE -Wall -Wextra -Werror)
target_link_libraries(zauxoflix_seek_frames PRIVATE dl)
