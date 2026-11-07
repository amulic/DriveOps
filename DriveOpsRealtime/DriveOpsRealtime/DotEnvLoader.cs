/// <summary>
/// Minimal .env loader for local development. Looks for the nearest .env walking up
/// from the app base directory and copies its KEY=VALUE pairs into the process
/// environment so the standard ASP.NET configuration env-var provider picks them up.
/// No-op when no .env exists (containers get env vars from docker compose).
/// </summary>
internal static class DotEnvLoader
{
    public static void Load()
    {
        var path = FindEnvFile();
        if (path == null)
            return;

        var content = File.ReadAllText(path);
        foreach (var raw in content.Split('\n'))
        {
            var line = raw.Trim().TrimStart('\uFEFF');
            if (line.Length == 0 || line.StartsWith('#'))
                continue;

            if (line.StartsWith("export ", StringComparison.Ordinal))
                line = line["export ".Length..].Trim();

            var separator = line.IndexOf('=');
            if (separator <= 0)
                continue;

            var key = line[..separator].Trim();
            var value = line[(separator + 1)..].Trim();
            if (value.Length >= 2
                && ((value[0] == '"' && value[^1] == '"') || (value[0] == '\'' && value[^1] == '\'')))
            {
                value = value[1..^1];
            }

            // Explicitly provided environment variables win over the file.
            if (Environment.GetEnvironmentVariable(key) is null)
                Environment.SetEnvironmentVariable(key, value);
        }
    }

    private static string? FindEnvFile()
    {
        // 1) Nearest .env walking up from the app (works for the API project and repo-root placement).
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir != null; dir = dir.Parent)
        {
            var candidate = Path.Combine(dir.FullName, ".env");
            if (File.Exists(candidate))
                return candidate;
        }

        // 2) The canonical DriveOpsAPI/.env, found from a sibling project (Realtime).
        for (var dir = new DirectoryInfo(AppContext.BaseDirectory); dir != null; dir = dir.Parent)
        {
            var candidate = Path.Combine(dir.FullName, "DriveOpsAPI", ".env");
            if (File.Exists(candidate))
                return candidate;
        }

        return null;
    }
}
