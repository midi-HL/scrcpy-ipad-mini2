/**
 * video.h
 *
 * Video stream interface.
 * This is a placeholder for the official scrcpy video module.
 */

#ifndef VIDEO_H
#define VIDEO_H

#include <stdint.h>
#include <stddef.h>

// Video packet structure
typedef struct video_packet {
    uint32_t pts;
    uint32_t dts;
    size_t size;
    uint8_t *data;
    int keyframe;
} video_packet_t;

// Video configuration
typedef struct video_config {
    int width;
    int height;
    int crop_left;
    int crop_top;
    int crop_right;
    int crop_bottom;
} video_config_t;

// Video packet callback
typedef void (*video_packet_callback)(const video_packet_t *packet, void *user_data);

// Initialize video decoder
int video_init(void);

// Start video stream
int video_start(int socket, video_packet_callback callback, void *user_data);

// Stop video stream
void video_stop(void);

// Get video configuration
const video_config_t* video_get_config(void);

// Free video packet
void video_packet_free(video_packet_t *packet);

#endif // VIDEO_H
