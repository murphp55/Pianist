namespace PianistApp.Helpers;

public static class NoteNameHelper
{
    private static readonly string[] NoteNames =
    {
        "C", "C#", "D", "D#", "E", "F",
        "F#", "G", "G#", "A", "A#", "B"
    };

    public static string ToName(int midiNote)
    {
        if (midiNote < 0 || midiNote > 127)
        {
            return "Unknown";
        }

        int octave = (midiNote / 12) - 1;
        string name = NoteNames[midiNote % 12];
        return $"{name}{octave}";
    }
}
