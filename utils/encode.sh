#!/usr/bin/env bash
#
# Encode movies to HLS
#
# Usage: ./utils/encode.sh [options]
#
# Copyright (c) 2024 AVEQ GmbH.
# License: MIT

set -e

cd "$(dirname "$0")/.."

CONTENT_DIR=content
START_OFFSET=5
ENCODE_TIME=180

usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -ss <time>        Start time offset in seconds (default: $START_OFFSET)"
  echo "  -t <time>         Encode time in seconds (default: $ENCODE_TIME)"
  echo "  -h, --help        Display this help message and exit"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    usage
    ;;
  -ss)
    START_OFFSET="$2"
    shift 2
    ;;
  -t)
    ENCODE_TIME="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
done

# ========================
# VARIABLES AND FUNCTIONS

declare -A input_movies=(
  ["bbb"]="./content_original/Big Buck Bunny 60fps 4K - Official Blender Foundation Short Film [aqz-KE-bpKQ].mkv"
  ["charge"]="./content_original/CHARGE - Blender Open Movie [UXqq0ZvbOnk].webm"
  ["wing_it"]="./content_original/WING IT! - Blender Open Movie [u9lj-c29dxI].webm"
  ["tears_of_steel"]="./content_original/Tears of Steel - Blender VFX Open Movie [R6MlUcmOul8].webm"
)

encode_movie() {
  local input_movie="$1"
  local output_movie="$2"
  local hls_directory="${output_movie%.*}"
  # e.g. content/bbb/
  mkdir -p "${CONTENT_DIR}/${hls_directory}"

  # Detect source frame rate
  local src_fps
  src_fps=$(ffprobe -v 0 -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$input_movie" | head -1)
  local fps_num fps_den fps_int
  fps_num=${src_fps%/*}
  fps_den=${src_fps#*/}
  if [[ "$fps_den" == "$src_fps" ]]; then
    fps_int=$fps_num
  else
    fps_int=$((fps_num / fps_den))
  fi

  # Use source fps, default to 30 if detection fails
  local target_fps=${fps_int:-30}
  # Keyint = 2 seconds worth of frames (for 2-second HLS segments)
  local keyint=$((target_fps * 2))

  echo "  Source fps: $src_fps (using $target_fps fps, keyint=$keyint)"

  ffmpeg -y \
    -ss "$START_OFFSET" \
    -i "$input_movie" \
    -filter_complex "[0:v]split=5[v1][v2][v3][v4][v5]; \
    [v1]scale=w=-2:h=360,drawtext=text='360p':x=20*360/1080:y=20*360/1080:fontsize=72*360/1080:fontcolor=white[v1out]; \
    [v2]scale=w=-2:h=480,drawtext=text='480p':x=20*480/1080:y=20*480/1080:fontsize=72*480/1080:fontcolor=white[v2out]; \
    [v3]scale=w=-2:h=720,drawtext=text='720p':x=20*720/1080:y=20*720/1080:fontsize=72*720/1080:fontcolor=white[v3out]; \
    [v4]scale=w=-2:h=1080,drawtext=text='1080p':x=20:y=20:fontsize=72:fontcolor=white[v4out]; \
    [v5]scale=w=-2:h=2160,drawtext=text='4K':x=40:y=40:fontsize=144:fontcolor=white[v5out]" \
    -shortest \
    -map "[v1out]" -c:v:0 libx264 -x264opts:v:0 keyint=${keyint}:min-keyint=${keyint}:no-scenecut -b:v:0 1200k \
    -map "[v2out]" -c:v:1 libx264 -x264opts:v:1 keyint=${keyint}:min-keyint=${keyint}:no-scenecut -b:v:1 2100k \
    -map "[v3out]" -c:v:2 libx264 -x264opts:v:2 keyint=${keyint}:min-keyint=${keyint}:no-scenecut -b:v:2 4500k \
    -map "[v4out]" -c:v:3 libx264 -x264opts:v:3 keyint=${keyint}:min-keyint=${keyint}:no-scenecut -b:v:3 8000k \
    -map "[v5out]" -c:v:4 libx264 -x264opts:v:4 keyint=${keyint}:min-keyint=${keyint}:no-scenecut -b:v:4 20000k \
    -var_stream_map "v:0 v:1 v:2 v:3 v:4" \
    -master_pl_name "${output_movie}" \
    -f hls -hls_time 2 -hls_list_size 0 \
    -hls_segment_filename "${CONTENT_DIR}/${hls_directory}/segment_%v_%03d.ts" \
    -t "$ENCODE_TIME" \
    "${CONTENT_DIR}/${hls_directory}/playlist_%v.m3u8"
}

# ========================
# MAIN

mkdir -p "$CONTENT_DIR"

# iterate and encode
for movie in "${!input_movies[@]}"; do
  echo "Encoding $movie ..."
  encode_movie "${input_movies[$movie]}" "$movie.m3u8"
done

echo "Done"
