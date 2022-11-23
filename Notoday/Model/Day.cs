namespace Notoday.Model; 

public class Day
{
	public string Date { get; set; }

	public List<Question> questions = new(); 

	public Day()
	{
	}

	public async Task<List<Question>> GetQuestions()
	{
		using var stream = await FileSystem.OpenAppPackageFileAsync("questions.json");
		using var reader = new StreamReader(stream);
		var contents = await reader.ReadToEndAsync();
		questions = JsonSerializer.Deserialize<List<Question>>(contents);

		return questions; 
	}
}

