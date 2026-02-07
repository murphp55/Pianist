using System.Collections.ObjectModel;

namespace PianistApp.ViewModels;

public sealed class TocGroupViewModel : ObservableCollection<TocItemViewModel>
{
    public TocGroupViewModel(string title, IEnumerable<TocItemViewModel> items) : base(items)
    {
        Title = title;
    }

    public string Title { get; }
}
