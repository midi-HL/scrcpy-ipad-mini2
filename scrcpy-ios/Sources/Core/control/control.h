/**
 * control.h
 *
 * Control message interface for sending input events to Android.
 * This is a placeholder for the official scrcpy control module.
 */

#ifndef CONTROL_H
#define CONTROL_H

#include <stdint.h>

// Control message types
#define CONTROL_MSG_TYPE_KEYCODE         0
#define CONTROL_MSG_TYPE_TEXT            1
#define CONTROL_MSG_TYPE_MOUSE           2
#define CONTROL_MSG_TYPE_SCROLL          3
#define CONTROL_MSG_TYPE_BACK_OR_HOME    4
#define CONTROL_MSG_TYPE_EXPAND_NOTIFICATION  5
#define CONTROL_MSG_TYPE_EXPAND_SETTINGS     6
#define CONTROL_MSG_TYPE_COLLAPSE_PANELS      7
#define CONTROL_MSG_TYPE_ROTATE_DEVICE        8

// Keycodes
#define KEYCODE_HOME            3
#define KEYCODE_BACK            4
#define KEYCODE_APP_SWITCH      187
#define KEYCODE_VOLUME_UP       24
#define KEYCODE_VOLUME_DOWN     25
#define KEYCODE_POWER           26

// Control message structure
typedef struct control_msg {
    uint32_t type;
    union {
        struct {
            uint32_t action;
            uint32_t keycode;
        } key;
        struct {
            uint16_t x;
            uint16_t y;
            uint16_t width;
            uint16_t height;
            uint8_t buttons;
        } mouse;
        struct {
            int32_t x;
            int32_t y;
        } scroll;
        struct {
            char text[301];
        } text;
    };
} control_msg_t;

// Send control message
int control_send(int socket, const control_msg_t *msg);

// Helper functions
int control_send_keycode(int socket, uint32_t keycode, uint32_t action);
int control_send_touch(int socket, int action, int x, int y, int width, int height);
int control_send_scroll(int socket, int x, int y);
int control_send_text(int socket, const char *text);

#endif // CONTROL_H
