# AMV Uploader

by Geoffrey Roberts

A quick, dead simple way of encoding video and uploading it to a S3 compatible store in one go.

## Requirements

* Ruby (1.9+)
* Rubygems
* Bundler gem
* HandbrakeCLI (see Installation)
* ffmpeg (see Installation)
* qtfaststart (see Installation)

## Usage

<code>bundle exec ruby process.rb "path/to/video"</code>

The above will do the following:

* Convert your video to an MP4 video that is playable via HTML5
* Generate a thumbnail from halfway through the video
* Upload both to AWS

## Installation

### 1. Configuration file

Copy config-example.rb to config.rb. You'll need to edit this file in the next few steps.

### 2. HandbrakeCLI

Download HandbrakeCLI.

http://handbrake.fr/downloads2.php

Place the executable somewhere, and remember the path to it. Make sure you have the rights to execute it.

Open up config.rb, and change path/to/handbrakecli to the path.

### 3. FFMpeg

Get ffmpeg installed. This includes ffprobe which is needed for some video detail stuff.

http://www.wikihow.com/Install-FFmpeg-on-Windows  
http://linuxers.org/tutorial/how-install-ffmpeg-linux  
http://jungels.net/articles/ffmpeg-howto.html

Once done, you'll need to get the paths to your ffmpeg executable, and the ffprobe executable.

Open up config.rb, and change path/to/ffmpeg to the ffmpeg path, and path/to/ffprobe to the ffprobe path.

### 4. qtfaststart

Download QTFaststart. Use the ZIP file from the following URL:

https://github.com/danielgtaylor/qtfaststart

Place it somewhere where you'll remember, unzip it, and take note of the path to the executable called bin/qtfaststart within that folder.

Open up config.rb, and change path/to/qtfaststart to the ffmpeg path, and path/to/ffprobe to the ffprobe path.

### 5. AWS settings

You'll need a bucket name, endpoint (which is usually AWS), a key and a secret. Open config.rb, and add these variables to the required points in $AWSSettings.

## License

Copyright (C) 2013 (for now).
