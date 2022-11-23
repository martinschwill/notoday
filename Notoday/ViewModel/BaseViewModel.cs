namespace Notoday.ViewModel;

public partial class BaseViewModel : ObservableObject

{
    public BaseViewModel()
    {
    }

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsNotBusy))]
    bool isBusy;

    [ObservableProperty]
    string date;

    public bool IsNotBusy => !isBusy; 

}


