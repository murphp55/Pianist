using PianistApp.Helpers;
using PianistApp.Models;

namespace PianistApp.ViewModels;

public sealed class PracticeTaskViewModel
{
    public PracticeTaskViewModel(PracticeTask task)
    {
        Task = task;
        ExpectedNoteNames = task.ExpectedNotes.Select(NoteNameHelper.ToName).ToArray();
    }

    public PracticeTask Task { get; }
    public string Name => Task.Name;
    public string Description => Task.Description;
    public string FingeringDiagram => Task.FingeringDiagram;
    public IReadOnlyList<FingeredNote> FingeringNotes => Task.FingeringNotes;
    public IReadOnlyList<int> ExpectedNotes => Task.ExpectedNotes;
    public IReadOnlyList<string> ExpectedNoteNames { get; }
    public bool RequiresMidiInput => Task.RequiresMidiInput;
    public bool RequireMetronome => Task.RequireMetronome;
    public int TempoBpm => Task.TempoBpm;
    public int BeatToleranceMs => Task.BeatToleranceMs;
    public double MinNoteAccuracy => Task.MinNoteAccuracy;
    public double MinMetronomeAccuracy => Task.MinMetronomeAccuracy;
}
