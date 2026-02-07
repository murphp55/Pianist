namespace PianistApp.Models;

public enum Hand
{
    Right,
    Left
}

public sealed class FingeredNote
{
    public FingeredNote(int midiNote, int finger, Hand hand)
    {
        MidiNote = midiNote;
        Finger = finger;
        Hand = hand;
    }

    public int MidiNote { get; }
    public int Finger { get; }
    public Hand Hand { get; }
}
