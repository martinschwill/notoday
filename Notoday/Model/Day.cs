namespace Notoday.Model; 

public class Day
{
	public string Date { get; set; }

	public List<Question> Questions = new(); 

	public Day()
	{
	}
}

