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

We use open-source movies from the Blender Foundation. Download the original contents to `content_original`. You can get them like so:

```bash
cd content_original
# CHARGE
yt-dlp https://youtu.be/UXqq0ZvbOnk
# WING IT!
yt-dlp https://youtu.be/u9lj-c29dxI
# Tears of Steel
yt-dlp https://youtu.be/R6MlUcmOul8
# Big Buck Bunny
yt-dlp https://youtu.be/aqz-KE-bpKQ
```

### Encoding

Encode the movies with `./utils/encode.sh`.

This creates various representations of the videos in the `content` directory, using HLS and multiple bitrate renditions. The videos will have their resolution embedded into the stream so you can see the difference in quality.

### Running the Server

Run the server with:

```bash
docker compose up
```

Open the browser and navigate to `http://localhost:3005/` to see the videos. We use `hls.js` to play the videos directly in the browser.

To stop the server, press `Ctrl+C` in the terminal.

### Playing via HLS

You can access the videos directly via the m3u8 links:

- http://localhost:3005/bbb/bbb.m3u8
- http://localhost:3005/charge/charge.m3u8
- http://localhost:3005/wing_it/wing_it.m3u8
- http://localhost:3005/tears_of_steel/tears_of_steel.m3u8

## How to Modify the Encoding/Streaming

Feel free to adjust the encoding settings in `utils/encode.sh`. We've chosen a simple set of renditions with a one-pass fixed target bitrate, and no audio.

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
