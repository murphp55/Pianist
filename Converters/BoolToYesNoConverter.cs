using System.Globalization;

namespace PianistApp.Converters;

public sealed class BoolToYesNoConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value is bool flag && flag ? "Yes" : "No";
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value is string text && string.Equals(text, "Yes", StringComparison.OrdinalIgnoreCase);
    }
}
