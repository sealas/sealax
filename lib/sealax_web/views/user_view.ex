defmodule SealaxWeb.UserView do
  use SealaxWeb, :view

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("token.json", %{status: status, token_hash: token_hash, token: token}) do
    %{status: status, token_hash: token_hash, token: token}
  end

  def render("status.json", %{status: status}) do
    %{status: status}
  end

  def render("registration.json", %{verification_code: verification_code}) do
    %{verification_code: verification_code}
  end
end
