#include <gtk-layer-shell.h>
#include <gtk/gtk.h>

#include <stdio.h>

typedef struct {
  int width;
  GdkRGBA from;
  GdkRGBA to;
  GList *windows;
} BorderState;

static gboolean draw_border(GtkWidget *widget, cairo_t *context, gpointer data) {
  const BorderState *state = data;
  const double width = gtk_widget_get_allocated_width(widget);
  const double height = gtk_widget_get_allocated_height(widget);
  const double inset = state->width / 2.0;
  cairo_pattern_t *gradient = cairo_pattern_create_linear(0.0, 0.0, width, height);

  cairo_set_operator(context, CAIRO_OPERATOR_SOURCE);
  cairo_set_source_rgba(context, 0.0, 0.0, 0.0, 0.0);
  cairo_paint(context);
  cairo_set_operator(context, CAIRO_OPERATOR_OVER);

  cairo_pattern_add_color_stop_rgba(
      gradient, 0.0, state->from.red, state->from.green, state->from.blue, state->from.alpha
  );
  cairo_pattern_add_color_stop_rgba(
      gradient, 1.0, state->to.red, state->to.green, state->to.blue, state->to.alpha
  );
  cairo_set_source(context, gradient);
  cairo_set_line_width(context, state->width);
  cairo_rectangle(context, inset, inset, width - state->width, height - state->width);
  cairo_stroke(context);
  cairo_pattern_destroy(gradient);

  return TRUE;
}

static void make_click_through(GtkWidget *widget, gpointer data) {
  cairo_region_t *empty = cairo_region_create();

  (void)data;
  gdk_window_input_shape_combine_region(gtk_widget_get_window(widget), empty, 0, 0);
  cairo_region_destroy(empty);
}

static GtkWidget *create_window(GdkMonitor *monitor, BorderState *state) {
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  GdkVisual *visual = gdk_screen_get_rgba_visual(gtk_widget_get_screen(window));

  if (visual != NULL) {
    gtk_widget_set_visual(window, visual);
  }
  gtk_widget_set_app_paintable(window, TRUE);
  gtk_window_set_accept_focus(GTK_WINDOW(window), FALSE);
  gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
  gtk_window_set_focus_on_map(GTK_WINDOW(window), FALSE);

  gtk_layer_init_for_window(GTK_WINDOW(window));
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
  gtk_layer_set_exclusive_zone(GTK_WINDOW(window), -1);
  gtk_layer_set_keyboard_mode(GTK_WINDOW(window), GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);
  gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_OVERLAY);
  gtk_layer_set_monitor(GTK_WINDOW(window), monitor);
  gtk_layer_set_namespace(GTK_WINDOW(window), "battery-screen-border");

  g_signal_connect(window, "draw", G_CALLBACK(draw_border), state);
  g_signal_connect(window, "realize", G_CALLBACK(make_click_through), NULL);
  gtk_widget_show(window);

  return window;
}

static void rebuild_windows(BorderState *state) {
  GdkDisplay *display = gdk_display_get_default();
  const int monitor_count = gdk_display_get_n_monitors(display);

  g_list_free_full(state->windows, (GDestroyNotify)gtk_widget_destroy);
  state->windows = NULL;

  for (int index = 0; index < monitor_count; ++index) {
    state->windows = g_list_prepend(
        state->windows, create_window(gdk_display_get_monitor(display, index), state)
    );
  }
}

static void monitors_changed(GdkDisplay *display, GdkMonitor *monitor, gpointer data) {
  (void)display;
  (void)monitor;
  rebuild_windows(data);
}

static gboolean read_state(const char *path, BorderState *state) {
  g_autofree char *contents = NULL;
  g_autoptr(GError) error = NULL;
  char from[16] = {0};
  char to[16] = {0};

  if (!g_file_get_contents(path, &contents, NULL, &error)) {
    g_printerr("battery-screen-border: %s\n", error->message);
    return FALSE;
  }
  if (sscanf(contents, "%d %15s %15s", &state->width, from, to) != 3
      || state->width < 1 || state->width > 20 || !gdk_rgba_parse(&state->from, from)
      || !gdk_rgba_parse(&state->to, to)) {
    g_printerr("battery-screen-border: invalid state in %s\n", path);
    return FALSE;
  }

  return TRUE;
}

int main(int argc, char **argv) {
  BorderState state = {0};
  GdkDisplay *display = NULL;

  if (argc != 2 || !read_state(argv[1], &state)) {
    return 2;
  }

  gtk_init(NULL, NULL);
  display = gdk_display_get_default();
  g_signal_connect(display, "monitor-added", G_CALLBACK(monitors_changed), &state);
  g_signal_connect(display, "monitor-removed", G_CALLBACK(monitors_changed), &state);
  rebuild_windows(&state);
  gtk_main();
  g_list_free_full(state.windows, (GDestroyNotify)gtk_widget_destroy);

  return 0;
}
