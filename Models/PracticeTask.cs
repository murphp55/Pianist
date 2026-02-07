using System;
using System.Collections.Generic;

namespace PianistApp.Models;

public sealed class PracticeTask
{
    public string Name { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string FingeringDiagram { get; init; } = string.Empty;
    public IReadOnlyList<FingeredNote> FingeringNotes { get; init; } = Array.Empty<FingeredNote>();
    public IReadOnlyList<int> ExpectedNotes { get; init; } = Array.Empty<int>();
    public bool RequiresMidiInput { get; init; } = true;
    public bool RequireMetronome { get; init; }
    public int TempoBpm { get; init; } = 60;
    public int BeatToleranceMs { get; init; } = 120;
    public double MinNoteAccuracy { get; init; } = 0.95;
    public double MinMetronomeAccuracy { get; init; } = 0.9;
}
