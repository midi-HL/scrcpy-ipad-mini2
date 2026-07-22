/**
 * video_stream.h
 *
 * Video stream receiver and parser.
 */

#ifndef VIDEO_STREAM_H
#define VIDEO_STREAM_H

#include <stdint.h>
#include <stddef.h>

// Video packet structure
typedef struct video_packet {
    uint64_t pts;           // Presentation timestamp
    size_t size;            // Packet size
    uint8_t *data;          // Packet data (NAL units)
    int keyframe;           // Is keyframe
} video_packet_t;

// Video stream configuration
typedef struct video_config {
    int width;
    int height;
    int crop_left;
    int crop_top;
    int crop_right;
    int crop_bottom;
    int orientation;
} video_config_t;

// Packet callback
typedef void (*video_packet_callback)(const video_packet_t *packet, void *user_data);

// Initialize video stream
int video_stream_init(void);

// Start receiving from socket
int video_stream_start(int socket, video_packet_callback callback, void *user_data);

// Stop receiving
void video_stream_stop(void);

// Get current config
const video_config_t* video_stream_get_config(void);

// Free packet
void video_packet_free(video_packet_t *packet);

#endif // VIDEO_STREAM_H
