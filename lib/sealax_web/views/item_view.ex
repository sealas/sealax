defmodule SealaxWeb.ItemView do
  use SealaxWeb, :view

  alias SealaxWeb.ItemView

  def render("index.json", %{item: item}) do
    %{items: render_many(item, ItemView, "item.json")}
  end

  def render("show.json", %{item: item}) do
    %{item: render_one(item, ItemView, "item.json")}
  end

  def render("conflict.json", %{conflict: conflict}) do
    %{type: conflict.type, server_item: render_one(conflict.server_item, ItemView, "item.json")}
  end

  def render("item.json", %{item: item}) do
    %{id: item.id,
      content: item.content,
      updated_at: item.updated_at}
  end

  def render("status.json", %{status: status}) do
    %{status: status}
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end
end
