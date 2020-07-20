defmodule SealaxWeb.AuthView do
  use SealaxWeb, :view

  def render("error.json", _params) do
    %{error: "auth fail"}
  end

  def render("inactive.json", _params) do
    %{error: "inactive"}
  end

  def render("tfa.json", %{token: token}) do
    %{tfa: true, token: token}
  end

  def render("token.json", %{token: token}) do
    %{token: token}
  end

  def render("auth.json", %{token: token, account_id: account_id, appkey: appkey, appkey_salt: appkey_salt}) do
    %{
      token: token,
      account_id: account_id,
      appkey: appkey,
      appkey_salt: appkey_salt
    }
  end
end
