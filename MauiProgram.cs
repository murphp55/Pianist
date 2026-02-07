using PianistApp.Services;
using PianistApp.ViewModels;

namespace PianistApp;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        MauiAppBuilder builder = MauiApp.CreateBuilder();
        builder.UseMauiApp<App>();

        builder.Services.AddSingleton<MidiInputService>();
        builder.Services.AddSingleton<ProgressStore>();
        builder.Services.AddSingleton<MainViewModel>();
        builder.Services.AddSingleton<MainPage>();

        return builder.Build();
    }
}
