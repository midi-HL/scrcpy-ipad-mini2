/**
 * video_stream.c
 *
 * Video stream receiver implementation.
 * Receives video packets from scrcpy server socket.
 */

#include "video_stream.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>

// Video stream state
static struct {
    int socket;
    video_packet_callback callback;
    void *user_data;
    video_config_t config;
    pthread_t thread;
    volatile int running;
} video_stream;

// Initialize
int video_stream_init(void) {
    memset(&video_stream, 0, sizeof(video_stream));
    video_stream.socket = -1;
    video_stream.running = 0;
    return 0;
}

// Receive thread function
static void* receive_thread(void *arg) {
    (void)arg;

    while (video_stream.running) {
        // Read packet header
        uint8_t header[12];
        ssize_t received = recv(video_stream.socket, header, sizeof(header), MSG_WAITALL);

        if (received <= 0) {
            if (video_stream.running) {
                printf("[VideoStream] Connection lost\n");
            }
            break;
        }

        // Parse header
        uint32_t packet_size = ntohl(*(uint32_t *)header);
        uint32_t pts_high = ntohl(*(uint32_t *)(header + 4));
        uint32_t pts_low = ntohl(*(uint32_t *)(header + 8));
        uint64_t pts = ((uint64_t)pts_high << 32) | pts_low;

        // Validate size
        if (packet_size > 10 * 1024 * 1024) {
            printf("[VideoStream] Invalid packet size: %u\n", packet_size);
            break;
        }

        // Allocate buffer
        uint8_t *data = (uint8_t *)malloc(packet_size);
        if (!data) {
            printf("[VideoStream] Memory allocation failed\n");
            break;
        }

        // Receive data
        ssize_t data_received = recv(video_stream.socket, data, packet_size, MSG_WAITALL);
        if (data_received != packet_size) {
            printf("[VideoStream] Incomplete packet\n");
            free(data);
            continue;
        }

        // Check if keyframe (starts with IDR NALU type 5)
        int keyframe = 0;
        if (packet_size > 0) {
            uint8_t nalu_type = data[0] & 0x1F;
            if (nalu_type == 5) { // IDR
                keyframe = 1;
            }
        }

        // Create packet
        video_packet_t packet;
        packet.pts = pts;
        packet.size = packet_size;
        packet.data = data;
        packet.keyframe = keyframe;

        // Call callback
        if (video_stream.callback) {
            video_stream.callback(&packet, video_stream.user_data);
        }

        // Free data (callback should copy if needed)
        free(data);
    }

    printf("[VideoStream] Receive thread exiting\n");
    return NULL;
}

// Start receiving
int video_stream_start(int socket, video_packet_callback callback, void *user_data) {
    if (video_stream.running) {
        video_stream_stop();
    }

    video_stream.socket = socket;
    video_stream.callback = callback;
    video_stream.user_data = user_data;
    video_stream.running = 1;

    int result = pthread_create(&video_stream.thread, NULL, receive_thread, NULL);
    if (result != 0) {
        printf("[VideoStream] Failed to create thread\n");
        video_stream.running = 0;
        return -1;
    }

    printf("[VideoStream] Started receiving\n");
    return 0;
}

// Stop receiving
void video_stream_stop(void) {
    if (!video_stream.running) return;

    video_stream.running = 0;

    if (video_stream.thread) {
        pthread_join(video_stream.thread, NULL);
        video_stream.thread = 0;
    }

    video_stream.socket = -1;
    video_stream.callback = NULL;
    video_stream.user_data = NULL;

    printf("[VideoStream] Stopped\n");
}

// Get config
const video_config_t* video_stream_get_config(void) {
    return &video_stream.config;
}

// Free packet
void video_packet_free(video_packet_t *packet) {
    if (packet && packet->data) {
        free(packet->data);
        packet->data = NULL;
    }
}
