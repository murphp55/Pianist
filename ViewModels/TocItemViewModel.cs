using PianistApp.Models;

namespace PianistApp.ViewModels;

public sealed class TocItemViewModel
{
    public TocItemViewModel(string title, PracticeTask task)
    {
        Title = title;
        Task = task;
    }

    public string Title { get; }
    public PracticeTask Task { get; }
}
