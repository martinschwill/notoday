namespace Notoday.Model; 

public partial class Day : ObservableObject
{
	public string Date { get; set; }

	[ObservableProperty]
	[NotifyPropertyChangedFor(nameof(howManyCravings))] 
	public List<Question> questions;

	public Day()
	{
	
	}

	public int howManyCravings => Questions.Count; 

    public async Task<List<Question>> GetQuestions()
	{
		using var stream = await FileSystem.OpenAppPackageFileAsync("questions.json");
		using var reader = new StreamReader(stream);
		var contents = await reader.ReadToEndAsync();
		questions = JsonSerializer.Deserialize<List<Question>>(contents);

		return questions; 
	}

	
}

