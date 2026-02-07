namespace PianistApp.Services;

public sealed partial class MidiInputService : IDisposable
{
    public event Action<int>? NoteOnReceived;

    public partial IReadOnlyList<MidiDeviceInfo> GetDevices();
    public partial void Start(int deviceIndex);
    public partial void Stop();

    public void Dispose()
    {
        Stop();
    }

    private void RaiseNoteOn(int midiNote)
    {
        NoteOnReceived?.Invoke(midiNote);
    }
}

public sealed record MidiDeviceInfo(int DeviceIndex, string Name);
