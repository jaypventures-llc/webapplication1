namespace JPVOS.Components;

public sealed record PartnerItem(string Name, string Role, string Icon = "")
{
    public string Initials
    {
        get
        {
            var parts = Name.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            return parts.Length switch
            {
                0 => "",
                1 => parts[0][..1].ToUpperInvariant(),
                _ => $"{parts[0][0]}{parts[1][0]}".ToUpperInvariant()
            };
        }
    }
}
