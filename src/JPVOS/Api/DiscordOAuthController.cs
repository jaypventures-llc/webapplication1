using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Net.Http.Headers;
using System.Text.Json;

[ApiController]
[Route("api/discord/oauth")]
public class DiscordOAuthController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly IHttpClientFactory _httpFactory;
    public DiscordOAuthController(IConfiguration config, IHttpClientFactory httpFactory)
    {
        _config = config;
        _httpFactory = httpFactory;
    }

    [HttpGet("connect")]
    public IActionResult Connect(string state)
    {
        var clientId = _config["DISCORD_CLIENT_ID"];
        var redirectUri = _config["DISCORD_REDIRECT_URI"];
        var scope = "identify email guilds.join";
        var url = $"https://discord.com/api/oauth2/authorize?client_id={clientId}&redirect_uri={Uri.EscapeDataString(redirectUri)}&response_type=code&scope={Uri.EscapeDataString(scope)}&state={state}";
        return Redirect(url);
    }

    [HttpGet("callback")]
    public async Task<IActionResult> Callback(string code, string state)
    {
        var clientId = _config["DISCORD_CLIENT_ID"];
        var clientSecret = _config["DISCORD_CLIENT_SECRET"];
        var redirectUri = _config["DISCORD_REDIRECT_URI"];
        var http = _httpFactory.CreateClient();
        var tokenReq = new HttpRequestMessage(HttpMethod.Post, "https://discord.com/api/oauth2/token")
        {
            Content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["client_id"] = clientId,
                ["client_secret"] = clientSecret,
                ["grant_type"] = "authorization_code",
                ["code"] = code,
                ["redirect_uri"] = redirectUri
            })
        };
        var tokenRes = await http.SendAsync(tokenReq);
        var tokenJson = await tokenRes.Content.ReadAsStringAsync();
        var token = JsonDocument.Parse(tokenJson).RootElement;
        var accessToken = token.GetProperty("access_token").GetString();
        // TODO: Store Discord user ID and link to entitlement
        return Redirect("/access");
    }
}
