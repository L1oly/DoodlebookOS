/*
 * Tiny wlr-gamma-control helper.
 *
 * Reads "temperature brightness" lines from stdin (temperature in Kelvin,
 * brightness 0..1) and applies a matching gamma ramp to every output. It keeps
 * the Wayland connection open because a gamma table is reset when its client
 * disconnects.
 */

#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>

#include <wayland-client.h>
#include "gamma-protocol.h"

struct output {
    struct wl_output *wl_output;
    struct zwlr_gamma_control_v1 *control;
    uint32_t size;
    uint16_t *ramp;
    struct output *next;
};

static struct wl_display *display;
static struct wl_registry *registry;
static struct zwlr_gamma_control_manager_v1 *manager;
static struct output *outputs;
static float current_temperature = 6500.0f;
static float current_brightness = 1.0f;

static void gamma_size(void *data, struct zwlr_gamma_control_v1 *control,
                       uint32_t size)
{
    struct output *output = data;
    (void)control;
    if (size == 0 || size > 65536)
        return;
    free(output->ramp);
    output->size = size;
    output->ramp = calloc((size_t)size * 3, sizeof(uint16_t));
}

static const struct zwlr_gamma_control_v1_listener gamma_listener = {
    .gamma_size = gamma_size,
};

static void noop_output_geometry(void *data, struct wl_output *output, int32_t x,
                                 int32_t y, int32_t physical_width,
                                 int32_t physical_height, int32_t subpixel,
                                 const char *make, const char *model,
                                 int32_t transform)
{
    (void)data; (void)output; (void)x; (void)y; (void)physical_width;
    (void)physical_height; (void)subpixel; (void)make; (void)model;
    (void)transform;
}

static void noop_output_mode(void *data, struct wl_output *output,
                             uint32_t flags, int32_t width, int32_t height,
                             int32_t refresh)
{
    (void)data; (void)output; (void)flags; (void)width; (void)height;
    (void)refresh;
}

static void noop_output_done(void *data, struct wl_output *output)
{
    (void)data; (void)output;
}

static void noop_output_scale(void *data, struct wl_output *output,
                              int32_t factor)
{
    (void)data; (void)output; (void)factor;
}

static void noop_output_name(void *data, struct wl_output *output,
                             const char *name)
{
    (void)data; (void)output; (void)name;
}

static void noop_output_description(void *data, struct wl_output *output,
                                    const char *description)
{
    (void)data; (void)output; (void)description;
}

static const struct wl_output_listener output_listener = {
    .geometry = noop_output_geometry,
    .mode = noop_output_mode,
    .done = noop_output_done,
    .scale = noop_output_scale,
    .name = noop_output_name,
    .description = noop_output_description,
};

static void attach_control(struct output *output)
{
    if (!manager || output->control)
        return;
    output->control = zwlr_gamma_control_manager_v1_get_gamma_control(
        manager, output->wl_output);
    zwlr_gamma_control_v1_add_listener(output->control, &gamma_listener, output);
}

static void attach_all_controls(void)
{
    for (struct output *o = outputs; o; o = o->next)
        attach_control(o);
}

static void registry_global(void *data, struct wl_registry *reg, uint32_t name,
                            const char *interface, uint32_t version)
{
    (void)data;
    if (strcmp(interface, wl_output_interface.name) == 0) {
        struct output *output = calloc(1, sizeof(*output));
        if (!output)
            return;
        output->wl_output = wl_registry_bind(reg, name, &wl_output_interface,
                                             version < 4 ? version : 4);
        wl_output_add_listener(output->wl_output, &output_listener, output);
        output->next = outputs;
        outputs = output;
        attach_control(output);
    } else if (strcmp(interface, zwlr_gamma_control_manager_v1_interface.name) == 0) {
        manager = wl_registry_bind(reg, name,
                                   &zwlr_gamma_control_manager_v1_interface,
                                   version < 1 ? version : 1);
        attach_all_controls();
    }
}

static void registry_global_remove(void *data, struct wl_registry *reg,
                                   uint32_t name)
{
    (void)data; (void)reg; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static double clamp01(double value)
{
    return value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
}

/* Tanner Helland's colour-temperature approximation. */
static void temperature_gains(float kelvin, double gains[3])
{
    double t = kelvin;
    if (t < 1000.0)
        t = 1000.0;
    if (t > 40000.0)
        t = 40000.0;
    if (t >= 6500.0) {
        gains[0] = gains[1] = gains[2] = 1.0;
        return;
    }

    t /= 100.0;
    double r, g, b;
    if (t <= 66.0) {
        r = 255.0;
        g = 99.4708025861 * log(t) - 161.1195681661;
        b = t <= 19.0 ? 0.0 : 138.5177312231 * log(t - 10.0) - 305.0447927307;
    } else {
        r = 329.698727446 * pow(t - 60.0, -0.1332047592);
        g = 288.1221695283 * pow(t - 60.0, -0.0755148492);
        b = 255.0;
    }

    gains[0] = clamp01(r / 255.0);
    gains[1] = clamp01(g / 255.0);
    gains[2] = clamp01(b / 255.0);
    if (gains[0] > 0.0) {
        /* Normalise so the ramp never becomes darker than requested. */
        double peak = gains[0];
        if (gains[1] > peak) peak = gains[1];
        if (gains[2] > peak) peak = gains[2];
        if (peak > 0.0) {
            gains[0] /= peak;
            gains[1] /= peak;
            gains[2] /= peak;
        }
    }
}

static int apply_output(struct output *output)
{
    if (!output->control || output->size == 0 || !output->ramp)
        return 0;

    double gains[3];
    temperature_gains(current_temperature, gains);
    double brightness = clamp01(current_brightness);
    uint32_t size = output->size;

    for (uint32_t i = 0; i < size; i++) {
        double base = size > 1 ? (double)i / (double)(size - 1) : 0.0;
        output->ramp[i] = (uint16_t)lround(clamp01(base * gains[0] * brightness) * 65535.0);
        output->ramp[size + i] = (uint16_t)lround(clamp01(base * gains[1] * brightness) * 65535.0);
        output->ramp[2 * size + i] = (uint16_t)lround(clamp01(base * gains[2] * brightness) * 65535.0);
    }

    size_t bytes = (size_t)size * 3 * sizeof(uint16_t);
    int fd = memfd_create("doodlebook-gamma", MFD_CLOEXEC);
    if (fd < 0)
        return -1;
    if (ftruncate(fd, (off_t)bytes) < 0) {
        close(fd);
        return -1;
    }
    void *mapped = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (mapped == MAP_FAILED) {
        close(fd);
        return -1;
    }
    memcpy(mapped, output->ramp, bytes);
    munmap(mapped, bytes);
    lseek(fd, 0, SEEK_SET);
    zwlr_gamma_control_v1_set_gamma(output->control, fd);
    close(fd);
    return 0;
}

static void apply_all(void)
{
    for (struct output *o = outputs; o; o = o->next)
        apply_output(o);
    if (display)
        wl_display_flush(display);
}

int main(void)
{
    display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "doodlebook-gamma: cannot connect to Wayland\n");
        return 1;
    }

    registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);
    wl_display_roundtrip(display);

    if (!manager) {
        fprintf(stderr, "doodlebook-gamma: compositor lacks wlr-gamma-control\n");
        wl_display_disconnect(display);
        return 2;
    }

    for (struct output *o = outputs; o; o = o->next) {
        if (o->size == 0) {
            fprintf(stderr, "doodlebook-gamma: output has no gamma ramp\n");
        }
    }

    char line[128];
    while (fgets(line, sizeof(line), stdin)) {
        float temperature = 6500.0f;
        float brightness = 1.0f;
        int parsed = sscanf(line, "%f %f", &temperature, &brightness);
        if (parsed >= 1) {
            current_temperature = temperature;
            current_brightness = parsed >= 2 ? brightness : 1.0f;
            apply_all();
        }
    }

    for (struct output *o = outputs; o; o = o->next) {
        if (o->control)
            zwlr_gamma_control_v1_destroy(o->control);
        free(o->ramp);
    }
    if (manager)
        zwlr_gamma_control_manager_v1_destroy(manager);
    wl_display_flush(display);
    wl_display_disconnect(display);
    return 0;
}
