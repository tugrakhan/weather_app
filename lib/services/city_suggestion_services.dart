import 'dart:convert';
import 'package:http/http.dart' as http;

//ücretsiz sürümde öneri limiti yalnızca 1 olduğundan dolayı sadece bir şehir önerisi alıyoruz
//eğer premium apiye sahipseniz en iyi 10 eşleşmeyi alabilirsiniz
//mesela flori yazdığımda florianopolis geliyor ancak florid yazdığımda florida önerisi yapıyor
//bu yüzden premium apiye geçmeyi düşünebilirsiniz
// In the free version, the suggestion limit is only 1, so we only get one city suggestion
// If you have the premium API, you can get the best 10 matches
// For example, when I write flori, florianopolis comes, but when I write florid, it suggests florida
// So you might consider switching to the premium API
class CitySuggestionService {
  static const String _apiKey = "YOUR API KEY HERE API NINJAS";
  static const String _baseUrl = "https://api.api-ninjas.com/v1/city";

  static Future<List<String>> getCitySuggestions(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse("$_baseUrl?name=$query"),
      headers: {"X-Api-Key": _apiKey},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      // Aynı isimleri set ile ayıklayıp listeye dönüştürdük
      // We filtered the same names with set and converted to list
      return data
          .map<String>((city) => city['name'] as String)
          .toSet()
          .toList();
    } else {
      return [];
    }
  }
}
