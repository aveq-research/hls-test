# HLS Test

This repo is an example of streaming HLS via the localhost, with optional limiting of network throughput (via Docker).

We encode various video files into HLS format and stream them via the localhost using a Docker-based setup.

Contents:

- [Requirements](#requirements)
- [Usage](#usage)
  - [Downloading the Videos](#downloading-the-videos)
  - [Encoding](#encoding)
  - [Running the Server](#running-the-server)
  - [Playing via HLS](#playing-via-hls)
- [How to Modify the Encoding/Streaming](#how-to-modify-the-encodingstreaming)
- [Limiting Network Throughput](#limiting-network-throughput)
- [License](#license)

## Requirements

- Docker and Docker Compose
- ffmpeg from https://ffmpeg.org/download.html
- `yt-dlp` from https://github.com/yt-dlp/yt-dlp
- For limiting: Python (the needed `tc` commands can be run inside Docker) 

## Usage

First, clone the repo.

### Downloading the Videos

We do not provide the video files in this repo. You can download them from YouTube using `yt-dlp`.

We use open-source movies from the Blender Foundation. Run the download script to fetch all videos to `content_original/`:

```bash
./utils/download.sh
```

The script will skip videos that have already been downloaded.

### Encoding

Encode the movies with `./utils/encode.sh`.

This creates various representations of the videos in the `content` directory, using HLS and multiple bitrate renditions. The videos will have their resolution embedded into the stream so you can see the difference in quality. Sources with 4K resolution get 5 renditions (360p-4K), others get 4 (360p-1080p).

By default, all movies are encoded. To encode only specific movies, pass their names as arguments:

```bash
# Encode all movies (default)
./utils/encode.sh

# Encode only specific movies
./utils/encode.sh bbb charge

# Combine with other options
./utils/encode.sh --codec hevc bbb
```

By default, H.264 is used. To encode with HEVC (H.265) instead, use `--codec hevc`:

```bash
# H.264 (default)
./utils/encode.sh

# HEVC
./utils/encode.sh --codec hevc
```

HEVC variants are placed in separate directories with an `_hevc` suffix (e.g. `bbb_hevc/bbb_hevc.m3u8`) so both codecs can coexist.

HEVC encoding uses Main profile at Level 5.1 with `hvc1` tag for HLS compatibility. Bitrates are roughly 40% lower than H.264 at (somewhat) equivalent perceptual quality:

- 360p: 800 kbps
- 480p: 1400 kbps
- 720p: 3000 kbps
- 1080p: 5500 kbps
- 4K: 14000 kbps

Note that the quality will obviously depend on the content. But this is just a dummy repository anyway.

#### Local Files

To encode from a local folder (e.g., Netflix test sequences), use the `--local` flag. This can be combined with `--codec`:

```bash
# H.264
LOCAL_FOLDER="/path/to/netflix" ./utils/encode.sh --local

# HEVC
LOCAL_FOLDER="/path/to/netflix" ./utils/encode.sh --local --codec hevc
```

This encodes Sparks and Meridian test sequences from the specified folder.

The Netflix test sequences can be downloaded from:

- Sparks: http://download.opencontent.netflix.com.s3.amazonaws.com/sparks/sdr/Sparks_SDR_UHD_4096x2160_5994fps.mov
- Meridian: http://download.opencontent.netflix.com.s3.amazonaws.com/Meridian/Meridian_UHD4k5994_HDR_P3PQ.mp4

### Running the Server

Run the server with:

```bash
docker compose up
```

Open the browser and navigate to `http://localhost:3005/` to see the videos. We use `hls.js` to play the videos directly in the browser.

To stop the server, press `Ctrl+C` in the terminal.

### Playing via HLS

You can access the videos directly via the m3u8 links.

H.264 streams:

- http://localhost:3005/bbb/bbb.m3u8
- http://localhost:3005/charge/charge.m3u8
- http://localhost:3005/wing_it/wing_it.m3u8
- http://localhost:3005/tears_of_steel/tears_of_steel.m3u8

HEVC streams (when encoded with `--codec hevc`):

- http://localhost:3005/bbb_hevc/bbb_hevc.m3u8
- http://localhost:3005/charge_hevc/charge_hevc.m3u8
- http://localhost:3005/wing_it_hevc/wing_it_hevc.m3u8
- http://localhost:3005/tears_of_steel_hevc/tears_of_steel_hevc.m3u8

When using `--local`, these are also available:

- http://localhost:3005/sparks/sparks.m3u8
- http://localhost:3005/meridian/meridian.m3u8
- http://localhost:3005/sparks_hevc/sparks_hevc.m3u8 (HEVC)
- http://localhost:3005/meridian_hevc/meridian_hevc.m3u8 (HEVC)

## How to Modify the Encoding/Streaming

Feel free to adjust the encoding settings in `utils/encode.sh`. We've chosen a simple set of renditions with a one-pass fixed target bitrate, and no audio. The script supports both H.264 (`libx264`) and HEVC (`libx265`) codecs.

You can also modify the `content/index.html` page to adjust the `hls.js` settings or video display.

## Limiting Network Throughput

To simulate a slow network, you can use the `tc` command to limit the network throughput. To help set up the commands, we use a Python script.

The script can interact with the running Docker container, so you do not have to set up any network interfaces manually on your host:

```bash
python3 ./limit.py --use-docker apply-profile 3g
```

This will limit the network throughput to simulate a 3G network. You can also remove the limit with:

```bash
python3 ./limit.py --use-docker clear
```

Check out the script help with:

```bash
python3 limit.py -h
```

## License

Copyright (c) 2024 AVEQ GmbH.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
