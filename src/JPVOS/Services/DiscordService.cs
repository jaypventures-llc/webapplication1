using System.Net.Http.Headers;
using System.Text.Json;

public class DiscordService
{
    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    public DiscordService(HttpClient http, IConfiguration config)
    {
        _http = http;
        _config = config;
    }

    public async Task AssignRoleAsync(string discordUserId, string roleId)
    {
        var guildId = _config["DISCORD_GUILD_ID"];
        var botToken = _config["DISCORD_BOT_TOKEN"];
        var url = $"https://discord.com/api/v10/guilds/{guildId}/members/{discordUserId}/roles/{roleId}";
        var req = new HttpRequestMessage(HttpMethod.Put, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bot", botToken);
        await _http.SendAsync(req);
    }

    public async Task RemoveRoleAsync(string discordUserId, string roleId)
    {
        var guildId = _config["DISCORD_GUILD_ID"];
        var botToken = _config["DISCORD_BOT_TOKEN"];
        var url = $"https://discord.com/api/v10/guilds/{guildId}/members/{discordUserId}/roles/{roleId}";
        var req = new HttpRequestMessage(HttpMethod.Delete, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bot", botToken);
        await _http.SendAsync(req);
    }
}
