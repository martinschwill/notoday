namespace Notoday.ViewModel;

public partial class BaseViewModel : ObservableObject

{
    public BaseViewModel()
    {
    }

    [ObservableProperty]
  //  [AlsoNotifyChangeFor(nameof(IsNotBusy))]   <--- to nie działa, trzeba się dowiedzieć dlaczego 
    bool isBusy;

    [ObservableProperty]
    string date; 


    public bool IsNotBusy => !isBusy; 

}


