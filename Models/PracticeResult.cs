namespace PianistApp.Models;

public sealed class PracticeResult
{
    public int ExpectedNotes { get; init; }
    public int ProcessedNotes { get; init; }
    public int CorrectNotes { get; init; }
    public int WrongNotes { get; init; }
    public int MetronomeOnBeat { get; init; }
    public int MetronomeTotal { get; init; }
    public bool IsComplete { get; init; }

    public double NoteAccuracy => ExpectedNotes == 0 ? 0.0 : (double)CorrectNotes / ExpectedNotes;
    public double MetronomeAccuracy => MetronomeTotal == 0 ? 0.0 : (double)MetronomeOnBeat / MetronomeTotal;
}
