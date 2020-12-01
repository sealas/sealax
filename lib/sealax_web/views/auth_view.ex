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

  def render("auth.json", %{token: token, workspace_keys: workspace_keys}) do
    %{token: token,
      workspace_keys: Enum.map(workspace_keys, fn x -> %{
        appkey: x.appkey,
        workspace_id: x.workspace_id
      } end)}
  end
  def render("auth.json", %{token: token, workspace_id: workspace_id, appkey: appkey, appkey_salt: appkey_salt}) do
    %{
      token: token,
      workspace_id: workspace_id,
      appkey: appkey,
      appkey_salt: appkey_salt
    }
  end
  def render("auth.json", %{token: token}) do
    %{token: token}
  end
end
