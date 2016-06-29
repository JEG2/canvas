defmodule Canvas.GUI.Painting do
  @behaviour :wx_object

  defstruct ~w[panel bitmap painter_module painter_state brushes]a

  require Logger
  require Record
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxPaint, Record.extract(:wxPaint, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxKey, Record.extract(:wxKey, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link(parent, size, options) do
    :wx_object.start_link(__MODULE__, [parent, size, options], [ ])
  end

  # Server API

  def init(args) do
    :wx.batch(fn -> do_init(args) end)
  end

  def handle_call(:shutdown, _from, state = %__MODULE__{panel: panel}) do
    :wxPanel.destroy(panel)
    {:reply, :ok, state}
  end
  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_sync_event(wx(event: wxPaint()), _paint_event, state) do
    paint(state)
    :ok
  end

  def handle_event(
    wx(
      event: wxKey(
        keyCode: key,
        controlDown: control,
        shiftDown: shift,
        metaDown: meta,
        altDown: alt
      )
    ),
    state
  ) do
    new_state = do_key_down(key, shift, alt, control, meta, state)
    {:noreply, new_state}
  end
  def handle_event(wx, state) do
    Logger.debug "Unhandled event:  #{inspect wx}"
    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.debug "Unhandled info:  #{inspect info}"
    {:noreply, state}
  end

  def code_change(_old_vsn, _state, _extra) do
    {:error, :not_implemented}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Helpers

  defp do_init([parent, {width, height}, options]) do
    panel = :wxPanel.new(parent)
    bitmap = :wxBitmap.new(width, height)

    :wxFrame.connect(panel, :paint, [:callback])
    :wxPanel.connect(panel, :key_down)

    state =
      %__MODULE__{
        panel: panel,
        bitmap: bitmap,
        painter_module: Keyword.fetch!(options, :painter_module),
        painter_state: Keyword.get(options, :painter_state, %{ }),
        brushes: build_brushes(options)
      }
    {panel, state}
  end

  defp build_brushes(options) do
    Keyword.get(options, :brushes, %{ })
    |> Enum.reduce(%{ }, fn {name, colors}, brushes ->
      Map.put(brushes, name, colors_to_tools(colors))
    end)
  end

  defp colors_to_tools({brush_color, pen_color}) do
    {:wxPen.new(brush_color), :wxBrush.new(pen_color)}
  end
  defp colors_to_tools(brush_and_pen_color) do
    {:wxPen.new(brush_and_pen_color), :wxBrush.new(brush_and_pen_color)}
  end

  defp do_key_down(
    key,
    shift,
    alt,
    control,
    meta,
    state = %__MODULE__{
      painter_module: painter_module,
      painter_state: painter_state
    }
  ) do
    functions = painter_module.__info__(:functions)
    new_painter_state =
      if Keyword.get(functions, :handle_key_down) == 2 do
        key_combo =
          %{key: key, shift: shift, alt: alt, control: control, meta: meta}
        apply(painter_module, :handle_key_down, [key_combo, painter_state])
      else
        painter_state
      end
    %__MODULE__{state | painter_state: new_painter_state}
  end

  defp paint(
    %__MODULE__{
      panel: panel,
      bitmap: bitmap,
      painter_module: painter_module,
      painter_state: painter_state,
      brushes: brushes
    }
  ) do
    {width, height} = :wxPanel.getClientSize(panel)

    panel_context = :wxPaintDC.new(panel)
    bitmap_context = :wxMemoryDC.new(bitmap)
    canvas = %Canvas{context: bitmap_context, brushes: brushes}

    apply(
      painter_module,
      :paint,
      [canvas, width, height, painter_state]
    )

    :wxPaintDC.blit(
      panel_context,
      {0, 0},
      {width, height},
      bitmap_context,
      {0, 0}
    )

    :wxPaintDC.destroy(panel_context)
    :wxMemoryDC.destroy(bitmap_context)
  end
end
