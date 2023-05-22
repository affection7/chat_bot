import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:dialogflow_flutter/language.dart';
import 'package:dialogflow_flutter/message.dart';
import 'data_service.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:convert';
import 'package:http/http.dart' as http;

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  User(this.username, this.password);
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<User>('users'); // Open the box with type User
  runApp(MyApp());
}

class ApimedicService {
  Future<List<String>> fetchData(String query) async {
    const url =
        'https://symptom-checker4.p.rapidapi.com/analyze?symptoms=Headache';
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': '9a9cb32170msha9ecc20b7cc97d5p1f6104jsn77807ad7e963',
      'X-RapidAPI-Host': 'symptom-checker4.p.rapidapi.com',
    };
    final body = {
      'symptoms': query,
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: json.encode(body));
      final result = response.body;
      print(result);

      // Decode the JSON response
      final jsonResult = json.decode(result);

      // Extract the potential causes
      final List<dynamic> potentialCausesJson = jsonResult['potentialCauses'];
      final List<String> potentialCauses =
          potentialCausesJson.map((cause) => cause.toString()).toList();

      return potentialCauses;
    } catch (error) {
      print(error);
      throw error;
    }
  }
}

Future<String> translateText(String query, String len, String len1) async {
  final url = Uri.parse('https://text-translator2.p.rapidapi.com/translate');
  final headers = {
    'content-type': 'application/x-www-form-urlencoded',
    'X-RapidAPI-Key': '9a9cb32170msha9ecc20b7cc97d5p1f6104jsn77807ad7e963',
    'X-RapidAPI-Host': 'text-translator2.p.rapidapi.com',
  };
  final body = {
    'source_language': len,
    'target_language': len1,
    'text': query,
  };

  final encodedParams = Uri(queryParameters: body).query;

  try {
    final response =
        await http.post(url, headers: headers, body: encodedParams);
    final result = json.decode(response.body);
    print(result);

    final translatedText = result['data']['translatedText'];
    return translatedText;
  } catch (error) {
    throw error;
    ;
  }
}

int getIdForName(String jsonString, List<String> namesList) {
  List<Map<String, dynamic>> jsonDataList =
      List<Map<String, dynamic>>.from(jsonDecode(jsonString));

  for (var jsonData in jsonDataList) {
    var name = jsonData['Name'];
    if (namesList.contains(name)) {
      return jsonData['ID'];
    }
  }

  return 0;
}

Future<String> getName() async {
  final url =
      'https://healthservice.priaid.ch/diagnosis/specialisations?symptoms=[981]&gender=male&year_of_birth=2001&token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InNhbGtvdzEyMzQ1QGdtYWlsLmNvbSIsInJvbGUiOiJVc2VyIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvc2lkIjoiOTY3NyIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdmVyc2lvbiI6IjEwOSIsImh0dHA6Ly9leGFtcGxlLm9yZy9jbGFpbXMvbGltaXQiOiIxMDAiLCJodHRwOi8vZXhhbXBsZS5vcmcvY2xhaW1zL21lbWJlcnNoaXAiOiJCYXNpYyIsImh0dHA6Ly9leGFtcGxlLm9yZy9jbGFpbXMvbGFuZ3VhZ2UiOiJlbi1nYiIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvZXhwaXJhdGlvbiI6IjIwOTktMTItMzEiLCJodHRwOi8vZXhhbXBsZS5vcmcvY2xhaW1zL21lbWJlcnNoaXBzdGFydCI6IjIwMjMtMDUtMTYiLCJpc3MiOiJodHRwczovL2F1dGhzZXJ2aWNlLnByaWFpZC5jaCIsImF1ZCI6Imh0dHBzOi8vaGVhbHRoc2VydmljZS5wcmlhaWQuY2giLCJleHAiOjE2ODQ3NTc4MTgsIm5iZiI6MTY4NDc1MDYxOH0.HmYiEWbdsWshD3QUn-sca-ZOu7R2fjY6eZrbjkK0NrI&format=json&language=en-gb';
  String name = '';
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);

      for (final spec in jsonResponse) {
        if (spec['Name'] != null) {
          name = spec['Name'];
          print(name);
        }
      }
    } else {
      print('Запрос вернул код ошибки ${response.statusCode}.');
    }
  } catch (e) {
    print('Произошла ошибка: $e');
  }
  return name;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 0;

  @override
  User read(BinaryReader reader) {
    return User(
      reader.readString(),
      reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.username);
    writer.writeString(obj.password);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Чат-бот',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePageDialogflow(),
    );
  }
}

class NewForm extends StatelessWidget {
  String login = "";
  String password = "";
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _handleRegistration() async {
    final box = Hive.box<User>('users');
    if (login.isNotEmpty && login.isNotEmpty) {
      var user = User(login, password);
      box.put('user', user);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Форма регистрации'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: loginController,
              decoration: InputDecoration(
                labelText: 'Логин',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                login = loginController.text;
                password = passwordController.text;
                _handleRegistration();
                Navigator.pop(context);
              },
              child: Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePageDialogflow extends StatefulWidget {
  @override
  _HomePageDialogflowState createState() => _HomePageDialogflowState();
}

class _HomePageDialogflowState extends State<HomePageDialogflow> {
  bool isChecked = false;
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  String _username = "";
  String _password = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double screenHeight = MediaQuery.of(context).size.height;
      double alertHeight = screenHeight * 0.4;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 20.0),
            title: const Text(
              "Введите имя",
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              height: alertHeight,
              child: _buildUsernameForm(),
            ),
          );
        },
      );
    });
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).indicatorColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                    hintText: "Введите сообщения"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameForm() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: "Имя",
                  ),
                  onChanged: (String value) {
                    setState(() {
                      _username = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                  height: 10), // Увеличение промежутка между полями ввода
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: "Пароль",
                ),
                onChanged: (String value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 45, // Увеличение высоты кнопки регистрации
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewForm(),
                      ),
                    );
                  },
                  child: const Text(
                    "Зарегистрироваться",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(
                  height: 10), // Увеличение промежутка между кнопками
              SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    primary: _username.length > 1
                        ? Colors.green
                        : Colors.grey.withOpacity(0.5),
                  ),
                  onPressed: _username.length > 1 ? _handleLogin : null,
                  child: const Text(
                    "Начать чат",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  void _handleRegistration() async {
    final box = Hive.box<User>('users');
    if (_username.isNotEmpty && _password.isNotEmpty) {
      var user = User(_username, _password);
      box.put('user', user);
    } else {}
  }

  void _handleLogin() async {
    final userBox = Hive.box<User>('users');

    if (userBox.isEmpty || userBox.get('user')!.username != _username) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка входа"),
            content: const Text("Неверное имя пользователя или пароль."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("ОК"),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
    await Hive.close(); // Проверка
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      name: _username,
      type: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    final transresp = await translateText(text, 'ru', 'en');
    _getResponse(transresp);
  }

  Future<void> _getResponse(String query) async {
    if (query.isEmpty) {
      ChatMessage errorMessage = ChatMessage(
        text: "Пустой запрос, пожалуйста, повторите",
        name: "Бот",
        type: false,
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
      return;
    }

    AuthGoogle authGoogle =
        await AuthGoogle(fileJson: "assets/key.json").build();
    DialogFlow dialogflow =
        DialogFlow(authGoogle: authGoogle, language: Language.russian);
    AIResponse response = await dialogflow.detectIntent(query);
    ChatMessage message;

    try {
      response = await dialogflow.detectIntent(query);

      final diagnosis = await ApimedicService().fetchData(query);
      final formattedDiagnosis = diagnosis.join('\n');
      final query1 = diagnosis.join(', ');
      final query2 = diagnosis.join(' ');
      print(query2);
      Uri url = Uri.parse(
          'https://healthservice.priaid.ch/symptoms?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InNhbGtvdzEyMzQ1QGdtYWlsLmNvbSIsInJvbGUiOiJVc2VyIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvc2lkIjoiOTY3NyIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdmVyc2lvbiI6IjEwOSIsImh0dHA6Ly9leGFtcGxlLm9yZy9jbGFpbXMvbGltaXQiOiIxMDAiLCJodHRwOi8vZXhhbXBsZS5vcmcvY2xhaW1zL21lbWJlcnNoaXAiOiJCYXNpYyIsImh0dHA6Ly9leGFtcGxlLm9yZy9jbGFpbXMvbGFuZ3VhZ2UiOiJlbi1nYiIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvZXhwaXJhdGlvbiI6IjIwOTktMTItMzEiLCJodHRwOi8vZXhhbXBsZS5vcmcvY2xhaW1zL21lbWJlcnNoaXBzdGFydCI6IjIwMjMtMDUtMTYiLCJpc3MiOiJodHRwczovL2F1dGhzZXJ2aWNlLnByaWFpZC5jaCIsImF1ZCI6Imh0dHBzOi8vaGVhbHRoc2VydmljZS5wcmlhaWQuY2giLCJleHAiOjE2ODQ3NTc1NTQsIm5iZiI6MTY4NDc1MDM1NH0.aUCwwZqhYJYB4BFj9gPXiLyM8Y5INXuC-mlhUHXUS90&format=json&language=en-gb');
      http.Response response1 = await http.get(url);
      int id = getIdForName(response1.body, diagnosis);

      try {
        final jsonString = response1.body;
        List<dynamic> jsonArray = json.decode(jsonString);
        List<String> words = query2.split(" ");

        bool containsMatch = false;
        int matchedId = -1;
        for (var item in jsonArray) {
          String itemName = item["Name"].toString().toLowerCase();
          if (words.any((word) => word.toLowerCase() == itemName)) {
            containsMatch = true;
            matchedId = item["ID"];
            break;
          }
        }

        if (containsMatch) {
          print("Строка содержит совпадение. ID: $matchedId");
        } else {
          print("Строка не содержит совпадений.");
        }
      } catch (error) {
        print("Произошла ошибка: $error");
      }

      final translatedText = await translateText(query1, 'en', 'ru');
      String name = await getName();

      final translatedName = await translateText(name, 'en', 'ru');

      print(translatedText);
      message = ChatMessage(
        text:
            'Результат: \n$translatedText\n. Возможные врачи: $translatedName',
        name: 'Бот',
        type: false,
      );
    } catch (e) {
      if (response.getMessage() != null) {
        message = ChatMessage(
          text: response.getMessage().toString(),
          name: "Бот",
          type: false,
        );
      } else if (response.getListMessage()?.isNotEmpty ?? false) {
        message = ChatMessage(
          text: CardDialogflow(response.getListMessage()?.elementAt(0)).title ??
              "",
          name: "Бот",
          type: false,
        );
      } else {
        message = ChatMessage(
          text: "Извините, я не понимаю ваш запрос",
          name: "Бот",
          type: false,
        );
      }
    }
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Чат-бот"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.blue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: DrawerHeader(
                child: Text(
                  'Меню',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.local_hospital),
              title: const Text('Информация о больнице'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorInformationForm(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: const Text('Информация о врачах'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HospitalInformationForm(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.name, required this.type});

  final String text;
  final String name;
  final bool type;

  List<Widget> otherMessage(BuildContext context) {
    return <Widget>[
      Container(
        margin: const EdgeInsets.only(right: 16.0),
        child: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: Text(
                  text,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> myMessage(BuildContext context) {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              name,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.end,
            ),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(
                text,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(left: 16.0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: type ? myMessage(context) : otherMessage(context),
      ),
    );
  }
}

class DoctorInformationForm extends StatefulWidget {
  @override
  _DoctorInformationFormState createState() => _DoctorInformationFormState();
}

class _DoctorInformationFormState extends State<DoctorInformationForm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Информация о больнице"),
      ),
      body: const Center(
        child: Text("Форма больницы"),
      ),
    );
  }
}

class HospitalInformationForm extends StatefulWidget {
  @override
  _HospitalInformationFormState createState() =>
      _HospitalInformationFormState();
}

class _HospitalInformationFormState extends State<HospitalInformationForm> {
  List<Map<String, String>> tableData = [];
  List<Map<String, String>> secondTableData1 = [];
  List<Map<String, String>> detTableData1 = [];
  @override
  void initState() {
    super.initState();
    loadTableData();
    loadSecondTableData();
    loadDetTableData();
  }

  void loadTableData() async {
    List<Map<String, String>> data = await DataService.getTableData();
    setState(() {
      tableData = data;
    });
  }

  void loadSecondTableData() async {
    List<Map<String, String>> secondTableData =
        await DataService.getSecondTableData();
    setState(() {
      secondTableData1 = secondTableData;
    });
  }

  void loadDetTableData() async {
    List<Map<String, String>> detTableData =
        await DataService.getDetTableData();
    setState(() {
      detTableData1 = detTableData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Информация о врачах"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Узкие специалисты",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  const TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Кабинет"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("ФИОврача"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Специализация"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Дни/Часы приема"),
                        ),
                      ),
                    ],
                  ),
                  for (var data in tableData)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Кабинет'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['ФИОврача'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Специализация'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Дни/Часыприема'] ?? ''),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Стоматологическое отделение",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  const TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("ФИОврача"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Специализация"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Дни/Часыприема"),
                        ),
                      ),
                    ],
                  ),
                  for (var data1 in secondTableData1)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data1['ФИОврача'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data1['Специализация'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data1['Дни/Часыприема'] ?? ''),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Детская Поликлиника",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  const TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Кабинет"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("ФИОврача"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Специализация"),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Дни/Часы приема"),
                        ),
                      ),
                    ],
                  ),
                  for (var data in detTableData1)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Кабинет'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['ФИОврача'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Специализация'] ?? ''),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(data['Дни/Часыприема'] ?? ''),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
