defmodule SealaxWeb.AuthView do
  use SealaxWeb, :view

  def render("error.json", _params) do
    %{error: "auth fail"}
  end

  def render("inactive.json", _params) do
    %{error: "inactive"}
  end

  def render("tfa.json", %{tfa: tfa}) do
    %{tfa: true, code: tfa}
  end

  def render("auth.json", %{auth: auth}) do
    %{auth: auth}
  end
end
