using PianistApp.Models;

namespace PianistApp.Drawables;

public sealed class FingeringDiagramDrawable : IDrawable
{
    private readonly IReadOnlyList<FingeredNote> _fingerings;

    public FingeringDiagramDrawable(IReadOnlyList<FingeredNote> fingerings)
    {
        _fingerings = fingerings;
    }

    public bool HasNotes => _fingerings.Count > 0;

    public void Draw(ICanvas canvas, RectF dirtyRect)
    {
        if (_fingerings.Count == 0)
        {
            return;
        }

        int minNote = _fingerings.Min(n => n.MidiNote);
        int maxNote = _fingerings.Max(n => n.MidiNote);
        int startNote = minNote - (minNote % 12);
        int endNote = maxNote + (11 - (maxNote % 12));

        var whiteNotes = new List<int>();
        for (int note = startNote; note <= endNote; note++)
        {
            if (!IsBlackKey(note))
            {
                whiteNotes.Add(note);
            }
        }

        if (whiteNotes.Count == 0)
        {
            return;
        }

        float whiteWidth = dirtyRect.Width / whiteNotes.Count;
        float whiteHeight = MathF.Min(120, dirtyRect.Height);
        float blackWidth = whiteWidth * 0.65f;
        float blackHeight = whiteHeight * 0.62f;

        canvas.StrokeColor = Colors.Black;
        canvas.StrokeSize = 1;

        for (int i = 0; i < whiteNotes.Count; i++)
        {
            float x = i * whiteWidth;
            canvas.FillColor = Colors.White;
            canvas.FillRectangle(x, 0, whiteWidth, whiteHeight);
            canvas.DrawRectangle(x, 0, whiteWidth, whiteHeight);
        }

        for (int i = 0; i < whiteNotes.Count; i++)
        {
            int whiteNote = whiteNotes[i];
            int blackNote = whiteNote + 1;
            if (blackNote > endNote || !IsBlackKey(blackNote))
            {
                continue;
            }

            float left = (i * whiteWidth) + whiteWidth - (blackWidth / 2);
            canvas.FillColor = Colors.Black;
            canvas.FillRectangle(left, 0, blackWidth, blackHeight);
        }

        Color rightAccent = GetColor("Accent", Colors.SteelBlue);
        Color rightLight = GetColor("AccentSoft", Colors.LightSteelBlue);
        Color leftAccent = GetColor("LeftHand", Colors.Sienna);
        Color leftLight = GetColor("LeftHandSoft", Colors.Bisque);

        foreach (FingeredNote fingering in _fingerings)
        {
            if (fingering.MidiNote < startNote || fingering.MidiNote > endNote)
            {
                continue;
            }

            float centerX = GetKeyCenterX(fingering.MidiNote, whiteNotes, whiteWidth);
            bool isBlack = IsBlackKey(fingering.MidiNote);
            bool isRight = fingering.Hand == Hand.Right;
            float centerY = isBlack
                ? (isRight ? whiteHeight * 0.25f : whiteHeight * 0.38f)
                : (isRight ? whiteHeight * 0.75f : whiteHeight * 0.58f);

            Color accent = isRight ? rightAccent : leftAccent;
            Color light = isRight ? rightLight : leftLight;

            canvas.FillColor = light;
            canvas.StrokeColor = accent;
            canvas.StrokeSize = 1;
            canvas.FillCircle(centerX, centerY, 9);
            canvas.DrawCircle(centerX, centerY, 9);

            canvas.FontSize = 10;
            canvas.FontColor = accent;
            canvas.DrawString(
                fingering.Finger.ToString(),
                centerX - 4,
                centerY - 6,
                16,
                16,
                HorizontalAlignment.Center,
                VerticalAlignment.Center);
        }
    }

    private static bool IsBlackKey(int midiNote)
    {
        int pitchClass = midiNote % 12;
        return pitchClass == 1 || pitchClass == 3 || pitchClass == 6 || pitchClass == 8 || pitchClass == 10;
    }

    private static float GetKeyCenterX(int midiNote, List<int> whiteNotes, float whiteWidth)
    {
        if (!IsBlackKey(midiNote))
        {
            int whiteIndex = whiteNotes.IndexOf(midiNote);
            return (whiteIndex * whiteWidth) + (whiteWidth / 2);
        }

        int prevNote = midiNote - 1;
        while (prevNote >= 0 && IsBlackKey(prevNote))
        {
            prevNote--;
        }

        int prevIndex = whiteNotes.IndexOf(prevNote);
        return (prevIndex * whiteWidth) + whiteWidth;
    }

    private static Color GetColor(string key, Color fallback)
    {
        if (Application.Current?.Resources.TryGetValue(key, out object? value) == true && value is Color color)
        {
            return color;
        }

        return fallback;
    }
}
