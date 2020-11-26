defmodule SealaxWeb.AuthView do
  use SealaxWeb, :view

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("tfa.json", %{token: token}) do
    %{tfa: true, token: token}
  end

  def render("token.json", %{token: token}) do
    %{token: token}
  end

  def render("otp.json", %{status: status, token_hash: token_hash, token: token}) do
    %{status: status, token_hash: token_hash, token: token}
  end

  def render("auth.json", %{token: token}) do
    %{token: token}
  end
end
