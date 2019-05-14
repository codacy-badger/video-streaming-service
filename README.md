# Video Streaming server

Short description

## How to setup

Build the image
```sh
docker build --no-cache -t hls_server .
```

Create the container
```sh
docker run --name some-nginx -d -v $(pwd)/videos:/var/www/hls/live -p 8080:80 -p 1935:1935 hls_server
```

Watch the logs
```sh
docker logs some-nginx -f
```

## Generate HLS 

Code Gist: `https://gist.github.com/mrbar42/ae111731906f958b396f30906004b3fa`
Explanation: `https://docs.peer5.com/guides/production-ready-hls-vod/`

```sh
./create-vod-hls.sh <video_file.mp4>
```

