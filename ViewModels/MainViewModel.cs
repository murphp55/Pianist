using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Windows.Input;
using PianistApp.Drawables;
using PianistApp.Helpers;
using PianistApp.Models;
using PianistApp.Services;

namespace PianistApp.ViewModels;

public sealed class MainViewModel : ViewModelBase
{
    private readonly MidiInputService _midiInputService;
    private readonly ProgressStore _progressStore;
    private readonly Stopwatch _taskStopwatch = new();
    private PracticeEvaluator? _evaluator;
    private Dictionary<string, TaskProgress> _progress = new(StringComparer.OrdinalIgnoreCase);

    private PracticeTaskViewModel? _selectedTask;
    private MidiDeviceInfo? _selectedDevice;
    private TocItemViewModel? _selectedTocItem;
    private string _selectedConnectionType = "USB";
    private string _connectionStatus = "Not connected";
    private string _taskStatus = "No task running";
    private string _progressText = "Progress: 0 / 0";
    private string _accuracyText = "Accuracy: --";
    private string _metronomeText = "Metronome: --";
    private string _lastNoteText = "Last note: --";
    private string _selectedProgressText = "Progress: --";
    private string _selectedLastCompletedText = "Last completed: --";
    private bool _isConnected;
    private bool _isRunning;
    private bool _isTocOpen = true;
    private IDrawable? _fingeringDrawable;
    private bool _showFingeringPlaceholder = true;

    public MainViewModel(MidiInputService midiInputService, ProgressStore progressStore)
    {
        _midiInputService = midiInputService;
        _progressStore = progressStore;
        _midiInputService.NoteOnReceived += OnNoteOnReceived;

        RefreshDevicesCommand = new Command(RefreshDevices);
        ToggleConnectCommand = new Command(ToggleConnect);
        StartTaskCommand = new Command(StartTask, () => CanStart);
        StopTaskCommand = new Command(StopTask, () => CanStop);
        ResetTaskCommand = new Command(ResetTask);
        CompleteLessonCommand = new Command(CompleteLesson, () => CanCompleteLesson);
        ToggleTocCommand = new Command(() => IsTocOpen = !IsTocOpen);

        LoadDefaultPlan();
        RefreshDevices();
    }

    public ObservableCollection<PracticeTaskViewModel> Tasks { get; } = new();
    public ObservableCollection<MidiDeviceInfo> MidiDevices { get; } = new();
    public ObservableCollection<TocGroupViewModel> TocGroups { get; } = new();
    public ObservableCollection<string> ConnectionTypes { get; } = new() { "USB", "Bluetooth" };

    public ICommand RefreshDevicesCommand { get; }
    public ICommand ToggleConnectCommand { get; }
    public ICommand StartTaskCommand { get; }
    public ICommand StopTaskCommand { get; }
    public ICommand ResetTaskCommand { get; }
    public ICommand CompleteLessonCommand { get; }
    public ICommand ToggleTocCommand { get; }

    public PracticeTaskViewModel? SelectedTask
    {
        get => _selectedTask;
        set
        {
            if (SetProperty(ref _selectedTask, value))
            {
                UpdateSelectedProgressDisplay();
                UpdateFingeringDiagram();
                OnPropertyChanged(nameof(CanStart));
                OnPropertyChanged(nameof(CanCompleteLesson));
                ((Command)StartTaskCommand).ChangeCanExecute();
                ((Command)CompleteLessonCommand).ChangeCanExecute();
            }
        }
    }

    public MidiDeviceInfo? SelectedDevice
    {
        get => _selectedDevice;
        set => SetProperty(ref _selectedDevice, value);
    }

    public TocItemViewModel? SelectedTocItem
    {
        get => _selectedTocItem;
        set
        {
            if (SetProperty(ref _selectedTocItem, value) && value != null)
            {
                PracticeTaskViewModel? match = Tasks.FirstOrDefault(task => task.Task == value.Task);
                if (match != null)
                {
                    SelectedTask = match;
                }
            }
        }
    }

    public string SelectedConnectionType
    {
        get => _selectedConnectionType;
        set => SetProperty(ref _selectedConnectionType, value);
    }

    public string ConnectionStatus
    {
        get => _connectionStatus;
        set => SetProperty(ref _connectionStatus, value);
    }

    public string TaskStatus
    {
        get => _taskStatus;
        set => SetProperty(ref _taskStatus, value);
    }

    public string ProgressText
    {
        get => _progressText;
        set => SetProperty(ref _progressText, value);
    }

    public string AccuracyText
    {
        get => _accuracyText;
        set => SetProperty(ref _accuracyText, value);
    }

    public string MetronomeText
    {
        get => _metronomeText;
        set => SetProperty(ref _metronomeText, value);
    }

    public string LastNoteText
    {
        get => _lastNoteText;
        set => SetProperty(ref _lastNoteText, value);
    }

    public string SelectedProgressText
    {
        get => _selectedProgressText;
        set => SetProperty(ref _selectedProgressText, value);
    }

    public string SelectedLastCompletedText
    {
        get => _selectedLastCompletedText;
        set => SetProperty(ref _selectedLastCompletedText, value);
    }

    public bool IsConnected
    {
        get => _isConnected;
        set
        {
            if (SetProperty(ref _isConnected, value))
            {
                OnPropertyChanged(nameof(ConnectButtonText));
                OnPropertyChanged(nameof(CanStart));
                ((Command)StartTaskCommand).ChangeCanExecute();
            }
        }
    }

    public bool IsRunning
    {
        get => _isRunning;
        set
        {
            if (SetProperty(ref _isRunning, value))
            {
                OnPropertyChanged(nameof(CanStart));
                OnPropertyChanged(nameof(CanStop));
                OnPropertyChanged(nameof(CanCompleteLesson));
                ((Command)StartTaskCommand).ChangeCanExecute();
                ((Command)StopTaskCommand).ChangeCanExecute();
                ((Command)CompleteLessonCommand).ChangeCanExecute();
            }
        }
    }

    public bool CanStart => SelectedTask != null && !IsRunning && (IsConnected || !SelectedTask.RequiresMidiInput);
    public bool CanStop => IsRunning;
    public bool CanCompleteLesson => IsRunning && SelectedTask != null && !SelectedTask.RequiresMidiInput;
    public string ConnectButtonText => IsConnected ? "Disconnect" : "Connect";

    public bool IsTocOpen
    {
        get => _isTocOpen;
        set => SetProperty(ref _isTocOpen, value);
    }

    public IDrawable? FingeringDrawable
    {
        get => _fingeringDrawable;
        private set => SetProperty(ref _fingeringDrawable, value);
    }

    public bool ShowFingeringPlaceholder
    {
        get => _showFingeringPlaceholder;
        private set => SetProperty(ref _showFingeringPlaceholder, value);
    }

    private void LoadDefaultPlan()
    {
        _progress = _progressStore.Load();
        PracticePlan plan = CreateDefaultPlan();
        Tasks.Clear();
        foreach (PracticeTask task in plan.Tasks)
        {
            Tasks.Add(new PracticeTaskViewModel(task));
        }

        TocGroups.Clear();
        foreach (TocGroupViewModel group in CreateDefaultToc(plan))
        {
            TocGroups.Add(group);
        }

        SelectedTask = Tasks.FirstOrDefault();
        UpdateSelectedProgressDisplay();
        UpdateFingeringDiagram();
    }

    private void RefreshDevices()
    {
        MidiDevices.Clear();
        foreach (MidiDeviceInfo device in _midiInputService.GetDevices())
        {
            MidiDevices.Add(device);
        }

        SelectedDevice = MidiDevices.FirstOrDefault();
    }

    private void ToggleConnect()
    {
        if (IsConnected)
        {
            Disconnect();
            return;
        }

        if (SelectedDevice == null)
        {
            ConnectionStatus = "Select a MIDI device.";
            return;
        }

        try
        {
            _midiInputService.Start(SelectedDevice.DeviceIndex);
            IsConnected = true;
            ConnectionStatus = $"Connected via {SelectedConnectionType} to {SelectedDevice.Name}.";
        }
        catch (Exception ex)
        {
            ConnectionStatus = $"Connection failed: {ex.Message}";
        }
    }

    private void Disconnect()
    {
        _midiInputService.Stop();
        IsConnected = false;
        ConnectionStatus = "Not connected";
        StopTask();
    }

    private void StartTask()
    {
        if (SelectedTask == null)
        {
            TaskStatus = "Select a task.";
            return;
        }

        if (!IsConnected && SelectedTask.RequiresMidiInput)
        {
            TaskStatus = "Connect a MIDI device first.";
            return;
        }

        if (SelectedTask.RequiresMidiInput && SelectedTask.ExpectedNotes.Count > 0)
        {
            _evaluator = new PracticeEvaluator(SelectedTask.Task);
            _evaluator.Start(0);
            _taskStopwatch.Restart();
        }
        else
        {
            _evaluator = null;
            _taskStopwatch.Reset();
        }

        IsRunning = true;
        TaskStatus = $"Running: {SelectedTask.Name}";
        LastNoteText = "Last note: --";
        StartMetronomeIfNeeded(SelectedTask);
        UpdateProgress(_evaluator?.GetResult());
    }

    private void StopTask()
    {
        if (!IsRunning)
        {
            return;
        }

        IsRunning = false;
        _taskStopwatch.Stop();
        if (_evaluator != null)
        {
            PracticeResult result = _evaluator.GetResult();
            UpdateProgress(result);
        }

        if (SelectedTask != null)
        {
            TaskStatus = $"Stopped: {SelectedTask.Name}";
        }
    }

    private void ResetTask()
    {
        _taskStopwatch.Reset();
        _evaluator = null;
        IsRunning = false;
        TaskStatus = "No task running";
        ProgressText = "Progress: 0 / 0";
        AccuracyText = "Accuracy: --";
        MetronomeText = "Metronome: --";
        LastNoteText = "Last note: --";
    }

    private void StartMetronomeIfNeeded(PracticeTaskViewModel task)
    {
        if (!task.RequireMetronome)
        {
            MetronomeText = "Metronome: not required";
            return;
        }

        MetronomeText = $"Metronome: 0 / 0 on-beat (tolerance {task.BeatToleranceMs} ms)";
    }

    private void OnNoteOnReceived(int midiNote)
    {
        MainThread.BeginInvokeOnMainThread(() =>
        {
            if (SelectedTask == null)
            {
                return;
            }

            string noteName = NoteNameHelper.ToName(midiNote);
            if (!IsRunning || _evaluator == null)
            {
                LastNoteText = $"Last note: {noteName} (ignored)";
                return;
            }

            PracticeResult beforeResult = _evaluator.GetResult();
            int? expectedNote = beforeResult.ProcessedNotes < SelectedTask.ExpectedNotes.Count
                ? SelectedTask.ExpectedNotes[beforeResult.ProcessedNotes]
                : null;

            _evaluator.ProcessNote(midiNote, _taskStopwatch.ElapsedMilliseconds);
            PracticeResult result = _evaluator.GetResult();

            if (expectedNote.HasValue && expectedNote.Value == midiNote)
            {
                LastNoteText = $"Last note: {noteName} (correct)";
            }
            else if (expectedNote.HasValue)
            {
                LastNoteText = $"Last note: {noteName} (expected {NoteNameHelper.ToName(expectedNote.Value)})";
            }
            else
            {
                LastNoteText = $"Last note: {noteName}";
            }

            UpdateProgress(result);

            if (result.IsComplete)
            {
                FinishTask(result);
            }
        });
    }

    private void UpdateProgress(PracticeResult? result)
    {
        if (SelectedTask == null)
        {
            return;
        }

        PracticeTask task = SelectedTask.Task;
        if (result == null)
        {
            ProgressText = "Progress: lesson (no MIDI)";
            AccuracyText = "Accuracy: --";
            MetronomeText = task.RequireMetronome
                ? $"Metronome: required at {task.TempoBpm} bpm"
                : "Metronome: not required";
            return;
        }

        ProgressText = $"Progress: {result.ProcessedNotes} / {result.ExpectedNotes}";
        AccuracyText = $"Accuracy: {result.NoteAccuracy:P1} (target {task.MinNoteAccuracy:P0})";

        if (task.RequireMetronome)
        {
            MetronomeText =
                $"Metronome: {result.MetronomeOnBeat} / {result.MetronomeTotal} on-beat (target {task.MinMetronomeAccuracy:P0})";
        }
        else
        {
            MetronomeText = "Metronome: not required";
        }
    }

    private void FinishTask(PracticeResult result)
    {
        IsRunning = false;
        _taskStopwatch.Stop();
        if (SelectedTask == null)
        {
            return;
        }

        PracticeTask task = SelectedTask.Task;
        bool notePass = result.NoteAccuracy >= task.MinNoteAccuracy;
        bool metronomePass = !task.RequireMetronome || result.MetronomeAccuracy >= task.MinMetronomeAccuracy;
        string verdict = notePass && metronomePass ? "Pass" : "Needs work";

        TaskStatus = $"Completed: {SelectedTask.Name} ({verdict})";
        RecordProgress(SelectedTask.Task.Name, verdict);
    }

    private void CompleteLesson()
    {
        if (SelectedTask == null)
        {
            return;
        }

        if (SelectedTask.RequiresMidiInput)
        {
            return;
        }

        IsRunning = false;
        TaskStatus = $"Completed: {SelectedTask.Name} (Completed)";
        RecordProgress(SelectedTask.Task.Name, "Completed");
    }

    private void RecordProgress(string taskName, string verdict)
    {
        if (!_progress.TryGetValue(taskName, out TaskProgress? progress))
        {
            progress = new TaskProgress();
            _progress[taskName] = progress;
        }

        progress.TimesCompleted += 1;
        progress.LastVerdict = verdict;
        progress.LastCompletedUtc = DateTime.UtcNow;

        _progressStore.Save(_progress);
        UpdateSelectedProgressDisplay();
    }

    private void UpdateSelectedProgressDisplay()
    {
        if (SelectedTask == null)
        {
            SelectedProgressText = "Progress: --";
            SelectedLastCompletedText = "Last completed: --";
            return;
        }

        string name = SelectedTask.Task.Name;
        if (_progress.TryGetValue(name, out TaskProgress? progress))
        {
            SelectedProgressText = $"Progress: {progress.TimesCompleted} completions ({progress.LastVerdict})";
            SelectedLastCompletedText = progress.LastCompletedUtc.HasValue
                ? $"Last completed: {progress.LastCompletedUtc.Value.ToLocalTime():g}"
                : "Last completed: --";
        }
        else
        {
            SelectedProgressText = "Progress: 0 completions";
            SelectedLastCompletedText = "Last completed: --";
        }
    }

    private void UpdateFingeringDiagram()
    {
        if (SelectedTask == null || SelectedTask.FingeringNotes.Count == 0)
        {
            FingeringDrawable = new FingeringDiagramDrawable(Array.Empty<FingeredNote>());
            ShowFingeringPlaceholder = true;
            return;
        }

        FingeringDrawable = new FingeringDiagramDrawable(SelectedTask.FingeringNotes);
        ShowFingeringPlaceholder = false;
    }

    private PracticePlan CreateDefaultPlan()
    {
        var plan = new PracticePlan();
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Warmup: 5-finger C position",
            Description = "Place RH fingers 1-5 on C-D-E-F-G. Play up and down with relaxed wrist and even tone. Keep fingertips curved.",
            FingeringNotes = new List<FingeredNote>
            {
                new(60, 1, Hand.Right),
                new(62, 2, Hand.Right),
                new(64, 3, Hand.Right),
                new(65, 4, Hand.Right),
                new(67, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 60, 62, 64, 65, 67, 65, 64, 62, 60 },
            RequireMetronome = false,
            MinNoteAccuracy = 1.0
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: C major (hands together)",
            Description = "Play C major one octave, hands together. RH: 1-2-3-1-2-3-4-5. LH: 5-4-3-2-1-3-2-1. Keep crossings smooth.",
            FingeringNotes = new List<FingeredNote>
            {
                new(60, 1, Hand.Right),
                new(62, 2, Hand.Right),
                new(64, 3, Hand.Right),
                new(65, 1, Hand.Right),
                new(67, 2, Hand.Right),
                new(69, 3, Hand.Right),
                new(71, 4, Hand.Right),
                new(72, 5, Hand.Right),
                new(60, 5, Hand.Left),
                new(62, 4, Hand.Left),
                new(64, 3, Hand.Left),
                new(65, 2, Hand.Left),
                new(67, 1, Hand.Left),
                new(69, 3, Hand.Left),
                new(71, 2, Hand.Left),
                new(72, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 60, 62, 64, 65, 67, 69, 71, 72 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: G major (RH)",
            Description = "Play G major one octave, right hand. Fingering: 1-2-3-1-2-3-4-5.",
            FingeringNotes = new List<FingeredNote>
            {
                new(67, 1, Hand.Right),
                new(69, 2, Hand.Right),
                new(71, 3, Hand.Right),
                new(72, 1, Hand.Right),
                new(74, 2, Hand.Right),
                new(76, 3, Hand.Right),
                new(78, 4, Hand.Right),
                new(79, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 67, 69, 71, 72, 74, 76, 78, 79 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: D major (RH)",
            Description = "Play D major one octave, right hand. Fingering: 1-2-3-1-2-3-4-5.",
            FingeringNotes = new List<FingeredNote>
            {
                new(62, 1, Hand.Right),
                new(64, 2, Hand.Right),
                new(66, 3, Hand.Right),
                new(67, 1, Hand.Right),
                new(69, 2, Hand.Right),
                new(71, 3, Hand.Right),
                new(73, 4, Hand.Right),
                new(74, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 62, 64, 66, 67, 69, 71, 73, 74 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: A major (RH)",
            Description = "Play A major one octave, right hand. Fingering: 1-2-3-1-2-3-4-5.",
            FingeringNotes = new List<FingeredNote>
            {
                new(69, 1, Hand.Right),
                new(71, 2, Hand.Right),
                new(73, 3, Hand.Right),
                new(74, 1, Hand.Right),
                new(76, 2, Hand.Right),
                new(78, 3, Hand.Right),
                new(80, 4, Hand.Right),
                new(81, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 69, 71, 73, 74, 76, 78, 80, 81 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: E major (RH)",
            Description = "Play E major one octave, right hand. Fingering: 1-2-3-1-2-3-4-5.",
            FingeringNotes = new List<FingeredNote>
            {
                new(64, 1, Hand.Right),
                new(66, 2, Hand.Right),
                new(68, 3, Hand.Right),
                new(69, 1, Hand.Right),
                new(71, 2, Hand.Right),
                new(73, 3, Hand.Right),
                new(75, 4, Hand.Right),
                new(76, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 64, 66, 68, 69, 71, 73, 75, 76 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: B major (RH)",
            Description = "Play B major one octave, right hand. Fingering: 1-2-3-1-2-3-4-5.",
            FingeringNotes = new List<FingeredNote>
            {
                new(71, 1, Hand.Right),
                new(73, 2, Hand.Right),
                new(75, 3, Hand.Right),
                new(76, 1, Hand.Right),
                new(78, 2, Hand.Right),
                new(80, 3, Hand.Right),
                new(82, 4, Hand.Right),
                new(83, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 71, 73, 75, 76, 78, 80, 82, 83 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: F# major (RH)",
            Description = "Play F# major one octave, right hand. Fingering: 2-3-4-1-2-3-4-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(66, 2, Hand.Right),
                new(68, 3, Hand.Right),
                new(70, 4, Hand.Right),
                new(71, 1, Hand.Right),
                new(73, 2, Hand.Right),
                new(75, 3, Hand.Right),
                new(77, 4, Hand.Right),
                new(78, 1, Hand.Right)
            },
            ExpectedNotes = new List<int> { 66, 68, 70, 71, 73, 75, 77, 78 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: C# major (RH)",
            Description = "Play C# major one octave, right hand. Fingering: 2-3-4-1-2-3-4-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(61, 2, Hand.Right),
                new(63, 3, Hand.Right),
                new(65, 4, Hand.Right),
                new(66, 1, Hand.Right),
                new(68, 2, Hand.Right),
                new(70, 3, Hand.Right),
                new(72, 4, Hand.Right),
                new(73, 1, Hand.Right)
            },
            ExpectedNotes = new List<int> { 61, 63, 65, 66, 68, 70, 72, 73 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: F major (RH)",
            Description = "Play F major one octave, right hand. Fingering: 1-2-3-4-1-2-3-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(65, 1, Hand.Right),
                new(67, 2, Hand.Right),
                new(69, 3, Hand.Right),
                new(70, 4, Hand.Right),
                new(72, 1, Hand.Right),
                new(74, 2, Hand.Right),
                new(76, 3, Hand.Right),
                new(77, 4, Hand.Right)
            },
            ExpectedNotes = new List<int> { 65, 67, 69, 70, 72, 74, 76, 77 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Bb major (RH)",
            Description = "Play Bb major one octave, right hand. Fingering: 2-3-4-1-2-3-4-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(70, 2, Hand.Right),
                new(72, 3, Hand.Right),
                new(74, 4, Hand.Right),
                new(75, 1, Hand.Right),
                new(77, 2, Hand.Right),
                new(79, 3, Hand.Right),
                new(81, 4, Hand.Right),
                new(82, 1, Hand.Right)
            },
            ExpectedNotes = new List<int> { 70, 72, 74, 75, 77, 79, 81, 82 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Eb major (RH)",
            Description = "Play Eb major one octave, right hand. Fingering: 3-4-1-2-3-4-1-2.",
            FingeringNotes = new List<FingeredNote>
            {
                new(63, 3, Hand.Right),
                new(65, 4, Hand.Right),
                new(67, 1, Hand.Right),
                new(68, 2, Hand.Right),
                new(70, 3, Hand.Right),
                new(72, 4, Hand.Right),
                new(74, 1, Hand.Right),
                new(75, 2, Hand.Right)
            },
            ExpectedNotes = new List<int> { 63, 65, 67, 68, 70, 72, 74, 75 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Ab major (RH)",
            Description = "Play Ab major one octave, right hand. Fingering: 3-4-1-2-3-4-1-2.",
            FingeringNotes = new List<FingeredNote>
            {
                new(68, 3, Hand.Right),
                new(70, 4, Hand.Right),
                new(72, 1, Hand.Right),
                new(73, 2, Hand.Right),
                new(75, 3, Hand.Right),
                new(77, 4, Hand.Right),
                new(79, 1, Hand.Right),
                new(80, 2, Hand.Right)
            },
            ExpectedNotes = new List<int> { 68, 70, 72, 73, 75, 77, 79, 80 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Db major (RH)",
            Description = "Play Db major one octave, right hand. Fingering: 2-3-4-1-2-3-4-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(61, 2, Hand.Right),
                new(63, 3, Hand.Right),
                new(65, 4, Hand.Right),
                new(66, 1, Hand.Right),
                new(68, 2, Hand.Right),
                new(70, 3, Hand.Right),
                new(72, 4, Hand.Right),
                new(73, 1, Hand.Right)
            },
            ExpectedNotes = new List<int> { 61, 63, 65, 66, 68, 70, 72, 73 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Gb major (RH)",
            Description = "Play Gb major one octave, right hand. Fingering: 2-3-4-1-2-3-4-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(66, 2, Hand.Right),
                new(68, 3, Hand.Right),
                new(70, 4, Hand.Right),
                new(71, 1, Hand.Right),
                new(73, 2, Hand.Right),
                new(75, 3, Hand.Right),
                new(77, 4, Hand.Right),
                new(78, 1, Hand.Right)
            },
            ExpectedNotes = new List<int> { 66, 68, 70, 71, 73, 75, 77, 78 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: G major (LH)",
            Description = "Play G major one octave, left hand. Fingering: 5-4-3-2-1-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(67, 5, Hand.Left),
                new(69, 4, Hand.Left),
                new(71, 3, Hand.Left),
                new(72, 2, Hand.Left),
                new(74, 1, Hand.Left),
                new(76, 3, Hand.Left),
                new(78, 2, Hand.Left),
                new(79, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 67, 69, 71, 72, 74, 76, 78, 79 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: D major (LH)",
            Description = "Play D major one octave, left hand. Fingering: 5-4-3-2-1-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(62, 5, Hand.Left),
                new(64, 4, Hand.Left),
                new(66, 3, Hand.Left),
                new(67, 2, Hand.Left),
                new(69, 1, Hand.Left),
                new(71, 3, Hand.Left),
                new(73, 2, Hand.Left),
                new(74, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 62, 64, 66, 67, 69, 71, 73, 74 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: A major (LH)",
            Description = "Play A major one octave, left hand. Fingering: 5-4-3-2-1-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(69, 5, Hand.Left),
                new(71, 4, Hand.Left),
                new(73, 3, Hand.Left),
                new(74, 2, Hand.Left),
                new(76, 1, Hand.Left),
                new(78, 3, Hand.Left),
                new(80, 2, Hand.Left),
                new(81, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 69, 71, 73, 74, 76, 78, 80, 81 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: E major (LH)",
            Description = "Play E major one octave, left hand. Fingering: 5-4-3-2-1-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(64, 5, Hand.Left),
                new(66, 4, Hand.Left),
                new(68, 3, Hand.Left),
                new(69, 2, Hand.Left),
                new(71, 1, Hand.Left),
                new(73, 3, Hand.Left),
                new(75, 2, Hand.Left),
                new(76, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 64, 66, 68, 69, 71, 73, 75, 76 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: B major (LH)",
            Description = "Play B major one octave, left hand. Fingering: 4-3-2-1-4-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(71, 4, Hand.Left),
                new(73, 3, Hand.Left),
                new(75, 2, Hand.Left),
                new(76, 1, Hand.Left),
                new(78, 4, Hand.Left),
                new(80, 3, Hand.Left),
                new(82, 2, Hand.Left),
                new(83, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 71, 73, 75, 76, 78, 80, 82, 83 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: F# major (LH)",
            Description = "Play F# major one octave, left hand. Fingering: 4-3-2-1-4-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(66, 4, Hand.Left),
                new(68, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(71, 1, Hand.Left),
                new(73, 4, Hand.Left),
                new(75, 3, Hand.Left),
                new(77, 2, Hand.Left),
                new(78, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 66, 68, 70, 71, 73, 75, 77, 78 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: C# major (LH)",
            Description = "Play C# major one octave, left hand. Fingering: 3-2-1-4-3-2-1-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(61, 3, Hand.Left),
                new(63, 2, Hand.Left),
                new(65, 1, Hand.Left),
                new(66, 4, Hand.Left),
                new(68, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(72, 1, Hand.Left),
                new(73, 4, Hand.Left)
            },
            ExpectedNotes = new List<int> { 61, 63, 65, 66, 68, 70, 72, 73 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: F major (LH)",
            Description = "Play F major one octave, left hand. Fingering: 5-4-3-2-1-4-3-2.",
            FingeringNotes = new List<FingeredNote>
            {
                new(65, 5, Hand.Left),
                new(67, 4, Hand.Left),
                new(69, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(72, 1, Hand.Left),
                new(74, 4, Hand.Left),
                new(76, 3, Hand.Left),
                new(77, 2, Hand.Left)
            },
            ExpectedNotes = new List<int> { 65, 67, 69, 70, 72, 74, 76, 77 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Bb major (LH)",
            Description = "Play Bb major one octave, left hand. Fingering: 3-2-1-4-3-2-1-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(70, 3, Hand.Left),
                new(72, 2, Hand.Left),
                new(74, 1, Hand.Left),
                new(75, 4, Hand.Left),
                new(77, 3, Hand.Left),
                new(79, 2, Hand.Left),
                new(81, 1, Hand.Left),
                new(82, 4, Hand.Left)
            },
            ExpectedNotes = new List<int> { 70, 72, 74, 75, 77, 79, 81, 82 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Eb major (LH)",
            Description = "Play Eb major one octave, left hand. Fingering: 3-2-1-4-3-2-1-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(63, 3, Hand.Left),
                new(65, 2, Hand.Left),
                new(67, 1, Hand.Left),
                new(68, 4, Hand.Left),
                new(70, 3, Hand.Left),
                new(72, 2, Hand.Left),
                new(74, 1, Hand.Left),
                new(75, 4, Hand.Left)
            },
            ExpectedNotes = new List<int> { 63, 65, 67, 68, 70, 72, 74, 75 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Ab major (LH)",
            Description = "Play Ab major one octave, left hand. Fingering: 3-2-1-4-3-2-1-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(68, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(72, 1, Hand.Left),
                new(73, 4, Hand.Left),
                new(75, 3, Hand.Left),
                new(77, 2, Hand.Left),
                new(79, 1, Hand.Left),
                new(80, 4, Hand.Left)
            },
            ExpectedNotes = new List<int> { 68, 70, 72, 73, 75, 77, 79, 80 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Db major (LH)",
            Description = "Play Db major one octave, left hand. Fingering: 3-2-1-4-3-2-1-4.",
            FingeringNotes = new List<FingeredNote>
            {
                new(61, 3, Hand.Left),
                new(63, 2, Hand.Left),
                new(65, 1, Hand.Left),
                new(66, 4, Hand.Left),
                new(68, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(72, 1, Hand.Left),
                new(73, 4, Hand.Left)
            },
            ExpectedNotes = new List<int> { 61, 63, 65, 66, 68, 70, 72, 73 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Scales: Gb major (LH)",
            Description = "Play Gb major one octave, left hand. Fingering: 4-3-2-1-4-3-2-1.",
            FingeringNotes = new List<FingeredNote>
            {
                new(66, 4, Hand.Left),
                new(68, 3, Hand.Left),
                new(70, 2, Hand.Left),
                new(71, 1, Hand.Left),
                new(73, 4, Hand.Left),
                new(75, 3, Hand.Left),
                new(77, 2, Hand.Left),
                new(78, 1, Hand.Left)
            },
            ExpectedNotes = new List<int> { 66, 68, 70, 71, 73, 75, 77, 78 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.95
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Rhythm: quarter notes @ 70 bpm",
            Description = "Play steady quarter notes at 70 bpm. Focus on even timing.",
            RequiresMidiInput = false,
            RequireMetronome = true,
            TempoBpm = 70,
            BeatToleranceMs = 120
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Rhythm: eighth notes @ 80 bpm",
            Description = "Play even eighth notes at 80 bpm.",
            RequiresMidiInput = false,
            RequireMetronome = true,
            TempoBpm = 80,
            BeatToleranceMs = 120
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Chords: C-G-Am-F broken",
            Description = "Play broken chord progression C-G-Am-F with steady rhythm.",
            FingeringNotes = new List<FingeredNote>
            {
                new(60, 1, Hand.Right),
                new(64, 3, Hand.Right),
                new(67, 5, Hand.Right)
            },
            ExpectedNotes = new List<int> { 60, 64, 67, 67, 71, 74, 69, 72, 76, 65, 69, 72 },
            RequireMetronome = false,
            MinNoteAccuracy = 0.9
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Reading: simple melody @ 72 bpm",
            Description = "Sight-read a simple melody at 72 bpm.",
            RequiresMidiInput = false,
            RequireMetronome = true,
            TempoBpm = 72,
            BeatToleranceMs = 150
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Repertoire: phrase practice @ 76 bpm",
            Description = "Practice a short phrase at 76 bpm, keeping dynamics consistent.",
            RequiresMidiInput = false,
            RequireMetronome = true,
            TempoBpm = 76,
            BeatToleranceMs = 150
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: interval recognition (2nds & 3rds)",
            Description = "Play and identify 2nds and 3rds by ear.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: interval recognition (4ths & 5ths)",
            Description = "Play and identify 4ths and 5ths by ear.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: interval recognition (6ths & 7ths)",
            Description = "Play and identify 6ths and 7ths by ear.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: chord quality (triads)",
            Description = "Identify major, minor, diminished, and augmented triads.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: chord quality (7ths)",
            Description = "Identify common 7th chord qualities.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: scale degrees",
            Description = "Identify scale degrees by ear in major keys.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: melodic dictation (short phrases)",
            Description = "Transcribe short melodic phrases by ear.",
            RequiresMidiInput = false
        });
        plan.Tasks.Add(new PracticeTask
        {
            Name = "Ear Training: rhythm dictation",
            Description = "Transcribe rhythm patterns by ear.",
            RequiresMidiInput = false
        });

        return plan;
    }

    private IEnumerable<TocGroupViewModel> CreateDefaultToc(PracticePlan plan)
    {
        PracticeTask FindTask(string name) => plan.Tasks.First(task => task.Name == name);

        var warmup = new TocGroupViewModel("Warmup", new[]
        {
            new TocItemViewModel("5-finger C position", FindTask("Warmup: 5-finger C position"))
        });

        var scales = new TocGroupViewModel("Scales", new[]
        {
            new TocItemViewModel("C major (hands together)", FindTask("Scales: C major (hands together)")),
            new TocItemViewModel("G major (RH)", FindTask("Scales: G major (RH)")),
            new TocItemViewModel("D major (RH)", FindTask("Scales: D major (RH)")),
            new TocItemViewModel("A major (RH)", FindTask("Scales: A major (RH)")),
            new TocItemViewModel("E major (RH)", FindTask("Scales: E major (RH)")),
            new TocItemViewModel("B major (RH)", FindTask("Scales: B major (RH)")),
            new TocItemViewModel("F# major (RH)", FindTask("Scales: F# major (RH)")),
            new TocItemViewModel("C# major (RH)", FindTask("Scales: C# major (RH)")),
            new TocItemViewModel("F major (RH)", FindTask("Scales: F major (RH)")),
            new TocItemViewModel("Bb major (RH)", FindTask("Scales: Bb major (RH)")),
            new TocItemViewModel("Eb major (RH)", FindTask("Scales: Eb major (RH)")),
            new TocItemViewModel("Ab major (RH)", FindTask("Scales: Ab major (RH)")),
            new TocItemViewModel("Db major (RH)", FindTask("Scales: Db major (RH)")),
            new TocItemViewModel("Gb major (RH)", FindTask("Scales: Gb major (RH)")),
            new TocItemViewModel("G major (LH)", FindTask("Scales: G major (LH)")),
            new TocItemViewModel("D major (LH)", FindTask("Scales: D major (LH)")),
            new TocItemViewModel("A major (LH)", FindTask("Scales: A major (LH)")),
            new TocItemViewModel("E major (LH)", FindTask("Scales: E major (LH)")),
            new TocItemViewModel("B major (LH)", FindTask("Scales: B major (LH)")),
            new TocItemViewModel("F# major (LH)", FindTask("Scales: F# major (LH)")),
            new TocItemViewModel("C# major (LH)", FindTask("Scales: C# major (LH)")),
            new TocItemViewModel("F major (LH)", FindTask("Scales: F major (LH)")),
            new TocItemViewModel("Bb major (LH)", FindTask("Scales: Bb major (LH)")),
            new TocItemViewModel("Eb major (LH)", FindTask("Scales: Eb major (LH)")),
            new TocItemViewModel("Ab major (LH)", FindTask("Scales: Ab major (LH)")),
            new TocItemViewModel("Db major (LH)", FindTask("Scales: Db major (LH)")),
            new TocItemViewModel("Gb major (LH)", FindTask("Scales: Gb major (LH)"))
        });

        var rhythm = new TocGroupViewModel("Rhythm & Metronome", new[]
        {
            new TocItemViewModel("Quarter notes @ 70 bpm", FindTask("Rhythm: quarter notes @ 70 bpm")),
            new TocItemViewModel("Eighth notes @ 80 bpm", FindTask("Rhythm: eighth notes @ 80 bpm"))
        });

        var chords = new TocGroupViewModel("Chords & Progressions", new[]
        {
            new TocItemViewModel("C-G-Am-F broken", FindTask("Chords: C-G-Am-F broken"))
        });

        var reading = new TocGroupViewModel("Reading", new[]
        {
            new TocItemViewModel("Simple melody @ 72 bpm", FindTask("Reading: simple melody @ 72 bpm"))
        });

        var repertoire = new TocGroupViewModel("Repertoire", new[]
        {
            new TocItemViewModel("Phrase practice @ 76 bpm", FindTask("Repertoire: phrase practice @ 76 bpm"))
        });

        var earTraining = new TocGroupViewModel("Ear Training", new[]
        {
            new TocItemViewModel("Intervals: 2nds & 3rds", FindTask("Ear Training: interval recognition (2nds & 3rds)")),
            new TocItemViewModel("Intervals: 4ths & 5ths", FindTask("Ear Training: interval recognition (4ths & 5ths)")),
            new TocItemViewModel("Intervals: 6ths & 7ths", FindTask("Ear Training: interval recognition (6ths & 7ths)")),
            new TocItemViewModel("Chord quality: triads", FindTask("Ear Training: chord quality (triads)")),
            new TocItemViewModel("Chord quality: 7ths", FindTask("Ear Training: chord quality (7ths)")),
            new TocItemViewModel("Scale degrees", FindTask("Ear Training: scale degrees")),
            new TocItemViewModel("Dictation: melodic phrases", FindTask("Ear Training: melodic dictation (short phrases)")),
            new TocItemViewModel("Dictation: rhythm", FindTask("Ear Training: rhythm dictation"))
        });

        return new[] { warmup, scales, rhythm, chords, reading, repertoire, earTraining };
    }
}
