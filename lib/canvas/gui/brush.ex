defmodule Canvas.GUI.Brush do
  def draw_circle(canvas = %Canvas{context: context}, center, radius, color) do
    set_color(canvas, color)
    :wxDC.drawCircle(context, center, radius)
  end

  def draw_rectangle(
    canvas = %Canvas{context: context},
    upper_left,
    width_and_height,
    color
  ) do
    set_color(canvas, color)
    :wxDC.drawRectangle(context, upper_left, width_and_height)
  end

  defp set_color(%Canvas{context: context, brushes: brushes}, color) do
    {pen, brush} = Map.fetch!(brushes, color)
    :wxDC.setPen(context, pen)
    :wxDC.setBrush(context, brush)
  end
end
