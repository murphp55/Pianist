using NAudio.Midi;

namespace PianistApp.Services;

public sealed partial class MidiInputService
{
    private MidiIn? _midiIn;

    public partial IReadOnlyList<MidiDeviceInfo> GetDevices()
    {
        var devices = new List<MidiDeviceInfo>();
        for (int i = 0; i < MidiIn.NumberOfDevices; i++)
        {
            MidiInCapabilities caps = MidiIn.DeviceInfo(i);
            devices.Add(new MidiDeviceInfo(i, caps.ProductName));
        }

        return devices;
    }

    public partial void Start(int deviceIndex)
    {
        Stop();

        _midiIn = new MidiIn(deviceIndex);
        _midiIn.MessageReceived += OnMessageReceived;
        _midiIn.ErrorReceived += OnErrorReceived;
        _midiIn.Start();
    }

    public partial void Stop()
    {
        if (_midiIn == null)
        {
            return;
        }

        _midiIn.MessageReceived -= OnMessageReceived;
        _midiIn.ErrorReceived -= OnErrorReceived;
        _midiIn.Stop();
        _midiIn.Dispose();
        _midiIn = null;
    }

    private void OnMessageReceived(object? sender, MidiInMessageEventArgs e)
    {
        if (e.MidiEvent is NoteOnEvent noteOn && noteOn.Velocity > 0)
        {
            RaiseNoteOn(noteOn.NoteNumber);
        }
    }

    private void OnErrorReceived(object? sender, MidiInMessageEventArgs e)
    {
        // Ignore for now; keep handler to avoid unhandled events.
    }
}
