/**
 * scrcpy_core.h
 *
 * Main header for scrcpy core functionality.
 * This module interfaces with the official scrcpy server.
 */

#ifndef SCRCPY_CORE_H
#define SCRCPY_CORE_H

#include <stdint.h>
#include <stddef.h>

// Scrcpy version
#define SCRCPY_SERVER_VERSION "1.24"

// Default options
#define SCRCPY_DEFAULT_MAX_SIZE     720
#define SCRCPY_DEFAULT_BIT_RATE     2000000
#define SCRCPY_DEFAULT_MAX_FPS      30

// Video codec
#define SCRCPY_VIDEO_CODEC_H264     0
#define SCRCPY_VIDEO_CODEC_H265     1

// Connection state
#define SCRCPY_STATE_DISCONNECTED   0
#define SCRCPY_STATE_CONNECTING     1
#define SCRCPY_STATE_CONNECTED      2
#define SCRCPY_STATE_STREAMING      3
#define SCRCPY_STATE_ERROR          4

// Scrcpy options
typedef struct scrcpy_options {
    int max_size;           // Max video size (longest dimension)
    int bit_rate;           // Video bit rate (bps)
    int max_fps;            // Max frame rate
    int crop_width;         // Crop width (0 = no crop)
    int crop_height;        // Crop height (0 = no crop)
    int crop_x;             // Crop X offset
    int crop_y;             // Crop Y offset
    int lock_video_orientation;  // Lock orientation (-1 = unlocked)
    int stay_awake;         // Keep device awake
    int turn_screen_off;    // Turn screen off
    int power_off_on_close; // Power off device on close
    int clipboard_autosync; // Auto-sync clipboard
} scrcpy_options_t;

// Video packet
typedef struct scrcpy_video_packet {
    uint64_t pts;           // Presentation timestamp (us)
    size_t size;            // Packet size
    uint8_t *data;          // H264 NALU data
    int keyframe;           // Is keyframe
} scrcpy_video_packet_t;

// Audio packet
typedef struct scrcpy_audio_packet {
    uint64_t pts;           // Presentation timestamp (us)
    size_t size;            // Packet size
    uint8_t *data;          // AAC data
} scrcpy_audio_packet_t;

// Event callbacks
typedef void (*scrcpy_video_callback)(const scrcpy_video_packet_t *packet, void *user_data);
typedef void (*scrcpy_audio_callback)(const scrcpy_audio_packet_t *packet, void *user_data);
typedef void (*scrcpy_state_callback)(int state, void *user_data);

// Initialize scrcpy
int scrcpy_init(void);

// Start scrcpy session
int scrcpy_start(const char *serial, const scrcpy_options_t *options,
                 scrcpy_video_callback video_cb,
                 scrcpy_audio_callback audio_cb,
                 scrcpy_state_callback state_cb,
                 void *user_data);

// Stop scrcpy session
void scrcpy_stop(void);

// Get current state
int scrcpy_get_state(void);

// Send control message
int scrcpy_send_key(int keycode, int action);
int scrcpy_send_touch(int action, int x, int y, int width, int height);
int scrcpy_send_text(const char *text);
int scrcpy_send_scroll(int x, int y);

// Get device info
int scrcpy_get_device_size(int *width, int *height);

// Set options
void scrcpy_set_max_size(int max_size);
void scrcpy_set_bit_rate(int bit_rate);
void scrcpy_set_max_fps(int max_fps);

#endif // SCRCPY_CORE_H
