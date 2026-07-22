/**
 * common.h
 *
 * Common definitions and utilities.
 * This is a placeholder for the official scrcpy common module.
 */

#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>
#include <stddef.h>

// Version
#define SCRCPY_VERSION "1.24"
#define SCRCPY_VERSION_CODE 124

// Default values
#define SCRCPY_DEFAULT_MAX_SIZE     720
#define SCRCPY_DEFAULT_BIT_RATE     2000000
#define SCRCPY_DEFAULT_MAX_FPS      30
#define SCRCPY_DEFAULT_ADB_PORT     5555

// Pixel formats
#define SCRCPY_PIXEL_FORMAT_RGB24   0
#define SCRCPY_PIXEL_FORMAT_RGBA    1
#define SCRCPY_PIXEL_FORMAT_YUV420  2

// Screen orientation
#define SCRCPY_ORIENTATION_0        0
#define SCRCPY_ORIENTATION_90       1
#define SCRCPY_ORIENTATION_180      2
#define SCRCPY_ORIENTATION_270      3

// Utility macros
#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))

// Get milliseconds
uint64_t get_current_time_ms(void);

// Log functions
void scrcpy_log_info(const char *tag, const char *fmt, ...);
void scrcpy_log_error(const char *tag, const char *fmt, ...);
void scrcpy_log_debug(const char *tag, const char *fmt, ...);

#endif // COMMON_H
