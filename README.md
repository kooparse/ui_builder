# ZUI [WORK IN PROGRESS]
<br/>
Immediade-mode graphical interface. 

It's public because I'm applying for a job, please don't use this library (yet)!! :-)

## Examples
```zig
const Interface = @import("zui");
const Font = @import("font");

const alloc = std.heap.page_allocator;
const myFont = Font.get("helvetica");

// Function to compute width of given text width.
// your custom font.
pub fn calc_text_size(font: *Font, size: f32, text: []const u8) f32 {
    return 200;
}

const ui = try Interface(Font).init(.{
  .allocator = &alloc,
  .font = &myFont,
  .font_size = 16,
  // Function pointer.
  .calc_text_size = calc_text_size,
}, .{}),

var shadows = true;
var modes = [_][]u8{ "Forward", "Deferred" };
var mode_selected: usize = 0;
var slider_value: f32 = 55;
const graph_data = [_]f32{ 200, 5, 10, 20, 30 };

// Game loop.
while (true) {

  // Updates the UI state.
  ui.reset();
  ui.send_scroll_offset(0);
  ui.send_cursor_position(50, 20);
  try ui.send_input_key(.Cursor, is_down(.MouseLeft));
  try ui.send_input_key(.Bspc, is_down(.Bspc));
  try ui.send_input_key(.Esc, is_down(.Esc));
  try ui.send_codepoint(unicode);

  // Build the interface.
  // Create new floating panel.
  if (ui.panel("My Panel!", 25, 25, 400, 700)) {
    try ui.label_alloc("Framerates: {d:.2}", .{60.3456}, .Left);
    ui.checkbox_label("Activate shadows", &shadows);

    // Update the layout mode by creating rows of two columns.
    ui.row_array_static(&[_]f32{ 50, 150 }, 0);
    ui.label("Rendering mode:", .Left);
    mode_selected = ui.select(&modes, mode_selected);

    // Update the layout mode by setting 1 column per row 
    // with the minimum height (font height + padding).
    ui.row_flex(0, 1);
    ui.padding_space(35);

    // Create tree, it exists two mode, Collapser and Tree. 
    // The second one nice for directories structures, thing like that.
    if (ui.tree_begin("New tree!", false, .Collapser)) {
      try ui.label("My Label", .Right);
      ui.tree_end();
    }

    // Create slider.
    slider_value = ui.slider(0, 100, slider_value, 1);

    // Create graph
    ui.graph(&graph_data, 200);
  }
  
  //
  // Process and draw the interface.
  //
  
  // Get all vertices and indices.
  const data = ui.process_ui();
  send_data_to_your_gpu(&data.vertex, &data.indices);

  for (ui.draw()) |d, i| {
    // Fake gl functions, just for the README.
    glScissor(clip.x, clip.y, clip.w, clip.h);
    glDrawElements(GL_TRIANGLES, d.vertex_count, GL_UNSIGNED_INT, d.offset);
    
    for (d.texts) |text| render_your_text(text.content, text.x, text.y, text.color);
  }
}

```
