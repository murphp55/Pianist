using Android.Content;
using Android.Media.Midi;
using Java.Lang;

namespace PianistApp.Services;

public sealed partial class MidiInputService
{
    private MidiManager? _midiManager;
    private MidiDevice? _device;
    private MidiOutputPort? _outputPort;
    private NoteOnReceiver? _receiver;
    private readonly List<MidiDeviceHandle> _deviceHandles = new();

    public partial IReadOnlyList<MidiDeviceInfo> GetDevices()
    {
        EnsureManager();
        _deviceHandles.Clear();

        if (_midiManager == null)
        {
            return Array.Empty<MidiDeviceInfo>();
        }

        var devices = new List<MidiDeviceInfo>();
        foreach (Android.Media.Midi.MidiDeviceInfo info in _midiManager.Devices)
        {
            string name = info.Properties?.GetString(Android.Media.Midi.MidiDeviceInfo.PropertyName)
                          ?? "MIDI Device";
            int index = _deviceHandles.Count;
            _deviceHandles.Add(new MidiDeviceHandle(info));
            devices.Add(new MidiDeviceInfo(index, name));
        }

        return devices;
    }

    public partial void Start(int deviceIndex)
    {
        Stop();
        EnsureManager();
        if (_midiManager == null)
        {
            return;
        }

        if (deviceIndex < 0 || deviceIndex >= _deviceHandles.Count)
        {
            throw new ArgumentOutOfRangeException(nameof(deviceIndex));
        }

        var handle = _deviceHandles[deviceIndex];
        _midiManager.OpenDevice(handle.Info, new DeviceOpenListener(device =>
        {
            if (device == null)
            {
                return;
            }

            _device = device;
            if (device.Info.OutputPortCount <= 0)
            {
                return;
            }

            _outputPort = device.OpenOutputPort(0);
            if (_outputPort == null)
            {
                return;
            }

            _receiver = new NoteOnReceiver(RaiseNoteOn);
            _outputPort.Connect(_receiver);
        }), null);
    }

    public partial void Stop()
    {
        try
        {
            _outputPort?.Disconnect(_receiver);
        }
        catch
        {
            // Ignore disconnect errors on teardown.
        }

        _outputPort?.Close();
        _outputPort = null;
        _receiver = null;

        _device?.Close();
        _device = null;
    }

    private void EnsureManager()
    {
        _midiManager ??= (MidiManager)Android.App.Application.Context.GetSystemService(Context.MidiService);
    }

    private sealed class MidiDeviceHandle
    {
        public MidiDeviceHandle(Android.Media.Midi.MidiDeviceInfo info)
        {
            Info = info;
        }

        public Android.Media.Midi.MidiDeviceInfo Info { get; }
    }

    private sealed class DeviceOpenListener : Java.Lang.Object, MidiManager.IOnDeviceOpenedListener
    {
        private readonly Action<MidiDevice?> _onOpened;

        public DeviceOpenListener(Action<MidiDevice?> onOpened)
        {
            _onOpened = onOpened;
        }

        public void OnDeviceOpened(MidiDevice? device)
        {
            _onOpened(device);
        }
    }

    private sealed class NoteOnReceiver : MidiReceiver
    {
        private readonly Action<int> _onNoteOn;

        public NoteOnReceiver(Action<int> onNoteOn)
        {
            _onNoteOn = onNoteOn;
        }

        public override void OnSend(byte[]? data, int offset, int count, long timestamp)
        {
            if (data == null || count < 3)
            {
                return;
            }

            byte status = data[offset];
            int messageType = status & 0xF0;
            if (messageType != 0x90)
            {
                return;
            }

            int note = data[offset + 1] & 0x7F;
            int velocity = data[offset + 2] & 0x7F;
            if (velocity > 0)
            {
                _onNoteOn(note);
            }
        }
    }
}
