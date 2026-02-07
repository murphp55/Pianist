using System.Collections.Generic;

namespace PianistApp.Models;

public sealed class PracticePlan
{
    public List<PracticeTask> Tasks { get; } = new();
}
