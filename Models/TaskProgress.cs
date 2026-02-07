namespace PianistApp.Models;

public sealed class TaskProgress
{
    public int TimesCompleted { get; set; }
    public string LastVerdict { get; set; } = "Not started";
    public DateTime? LastCompletedUtc { get; set; }
}
