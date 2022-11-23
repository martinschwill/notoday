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
    string day;

    public bool IsNotBusy => !isBusy; 

}


