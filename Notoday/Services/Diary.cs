namespace Notoday.Services; 

public class Diary
{
    public List<Day> Days = new(); 

    public List<Day> GetHistory()
    {

        return Days; 
    }
}

