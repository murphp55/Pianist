using System.Text.Json;
using PianistApp.Models;

namespace PianistApp.Services;

public sealed class ProgressStore
{
    private readonly string _filePath;

    public ProgressStore()
    {
        _filePath = Path.Combine(FileSystem.AppDataDirectory, "progress.json");
    }

    public Dictionary<string, TaskProgress> Load()
    {
        try
        {
            if (!File.Exists(_filePath))
            {
                return new Dictionary<string, TaskProgress>(StringComparer.OrdinalIgnoreCase);
            }

            string json = File.ReadAllText(_filePath);
            var data = JsonSerializer.Deserialize<Dictionary<string, TaskProgress>>(json)
                       ?? new Dictionary<string, TaskProgress>();
            return new Dictionary<string, TaskProgress>(data, StringComparer.OrdinalIgnoreCase);
        }
        catch
        {
            return new Dictionary<string, TaskProgress>(StringComparer.OrdinalIgnoreCase);
        }
    }

    public void Save(Dictionary<string, TaskProgress> progress)
    {
        try
        {
            string? directory = Path.GetDirectoryName(_filePath);
            if (!string.IsNullOrWhiteSpace(directory))
            {
                Directory.CreateDirectory(directory);
            }

            string json = JsonSerializer.Serialize(progress, new JsonSerializerOptions
            {
                WriteIndented = true
            });
            File.WriteAllText(_filePath, json);
        }
        catch
        {
            // Best-effort persistence; ignore I/O failures.
        }
    }
}
