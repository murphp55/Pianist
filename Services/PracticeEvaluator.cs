using PianistApp.Models;

namespace PianistApp.Services;

public sealed class PracticeEvaluator
{
    private readonly PracticeTask _task;
    private int _currentIndex;
    private int _correctNotes;
    private int _wrongNotes;
    private int _metronomeOnBeat;
    private int _metronomeTotal;
    private long _startTimeMs;

    public PracticeEvaluator(PracticeTask task)
    {
        _task = task ?? throw new ArgumentNullException(nameof(task));
    }

    public void Start(long startTimeMs)
    {
        _startTimeMs = startTimeMs;
        _currentIndex = 0;
        _correctNotes = 0;
        _wrongNotes = 0;
        _metronomeOnBeat = 0;
        _metronomeTotal = 0;
    }

    public void ProcessNote(int midiNote, long timeMs)
    {
        if (_currentIndex >= _task.ExpectedNotes.Count)
        {
            return;
        }

        int expectedNote = _task.ExpectedNotes[_currentIndex];
        bool isCorrect = midiNote == expectedNote;

        if (isCorrect)
        {
            _correctNotes++;
        }
        else
        {
            _wrongNotes++;
        }

        if (_task.RequireMetronome)
        {
            _metronomeTotal++;
            long beatMs = (long)Math.Round(60000.0 / _task.TempoBpm);
            long expectedBeatTime = _startTimeMs + (_currentIndex * beatMs);
            long delta = Math.Abs(timeMs - expectedBeatTime);
            if (delta <= _task.BeatToleranceMs)
            {
                _metronomeOnBeat++;
            }
        }

        _currentIndex++;
    }

    public PracticeResult GetResult()
    {
        return new PracticeResult
        {
            ExpectedNotes = _task.ExpectedNotes.Count,
            ProcessedNotes = _currentIndex,
            CorrectNotes = _correctNotes,
            WrongNotes = _wrongNotes,
            MetronomeOnBeat = _metronomeOnBeat,
            MetronomeTotal = _metronomeTotal,
            IsComplete = _currentIndex >= _task.ExpectedNotes.Count
        };
    }
}
