import 'package:flutter/cupertino.dart';
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
import 'package:intl/intl.dart';
import 'secrets.dart';
import 'package:flutter_cupertino_date_picker_fork/flutter_cupertino_date_picker_fork.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  @HiveField(2)
  DateTime dob;

  @HiveField(3)
  String gender;

  @HiveField(3)
  String login;

  User(this.username, this.password, this.dob, this.gender, this.login);
}

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  await Hive.deleteBoxFromDisk('new_users111');
  await Hive.openBox<User>('new_users111');

  runApp(MyApp());
}

class ApimedicService {
  Future<List<String>> fetchData(String query) async {
    const url = 'https://symptom-checker4.p.rapidapi.com/analyze';
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': '7ba3a224f8msh08ce829a784fd0ap1a4a81jsnbc96ce47d9af',
      'X-RapidAPI-Host': 'symptom-checker4.p.rapidapi.com'
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

Future<List<dynamic>> fetchJsonData(id, token) async {
  final url =
      'https://healthservice.priaid.ch/diagnosis/specialisations?symptoms=[$id]&gender=male&year_of_birth=1992&token=$token&format=json&language=en-gb';
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> jsonArray = jsonDecode(response.body);
      return jsonArray;
    } else {
      print('Запрос вернул код ошибки ${response.statusCode}.');
    }
  } catch (e) {
    print('Произошла ошибка: $e');
  }

  return []; // Возвращаем пустой список, если произошла ошибка или данные не удалось загрузить
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

Future<String> getName(String inputString, id) async {
  List<dynamic> jsonArray =
      await fetchJsonData(id, tokens); // Загрузка данных JSON

  List<String> inputList = inputString.split(" ");
  String itemName = '';
  for (String element in inputList) {
    bool foundMatch = false;

    for (var item in jsonArray) {
      itemName = item["Name"].toString().toLowerCase();
      if (itemName.contains(element)) {
        foundMatch = true;
        print("Элемент '$element' найден в JSON. ID: ${item["ID"]}");
        break;
      }
    }

    if (!foundMatch) {
      print("Элемент '$element' не найден в JSON.");
    }
  }
  return itemName;
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 0;

  @override
  User read(BinaryReader reader) {
    return User(
      reader.readString(),
      reader.readString(),
      DateTime.parse(reader.readString()),
      reader.readString(),
      reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.username);
    writer.writeString(obj.password);
    writer.writeString(obj.dob.toIso8601String());
    writer.writeString(obj.gender);
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

class NewForm extends StatefulWidget {
  @override
  _NewFormState createState() => _NewFormState();
}

class _NewFormState extends State<NewForm> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  String gender = "";
  String login = "";
  String name = "";
  DateTime dob = DateTime.now();

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    await Hive.openBox<User>('new_users111');
    final box = Hive.box<User>('new_users111');
    final String login = loginController.text;
    final String password = passwordController.text;
    final String username = usernameController.text;

    if (login.isNotEmpty &&
        password.isNotEmpty &&
        gender != null &&
        dob != null &&
        username.isNotEmpty) {
      var user = User(login, password, dob, gender, username);
      box.put('new_users111', user);
      setState(() {
        name = username;
      });
      Navigator.pop(context);
    } else {
      // Handle case when any of the fields is empty
    }
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Пол',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Radio<String>(
              value: 'Male',
              groupValue: gender,
              onChanged: (value) {
                setState(() {
                  gender = value!;
                });
              },
            ),
            Text('Мужской'),
            Radio<String>(
              value: 'Female',
              groupValue: gender,
              onChanged: (value) {
                setState(() {
                  gender = value!;
                });
              },
            ),
            Text('Женский'),
          ],
        ),
      ],
    );
  }

  Widget _buildDateOfBirthSelection() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дата рождения',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              _showDatePicker(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                dob != null
                    ? DateFormat('yyyy-MM-dd').format(dob)
                    : 'Select date',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    DatePicker.showDatePicker(
      context,
      pickerMode: DateTimePickerMode.date,
      initialDateTime: DateTime.now(),
      locale: DateTimePickerLocale.ru,
      pickerTheme: DateTimePickerTheme(
        confirm: Text('Готово', style: TextStyle(color: Colors.blue)),
        cancel: Text('Отмена', style: TextStyle(color: Colors.red)),
      ),
      onChange: (DateTime newDateTime, DateTime) {
        setState(() {
          dob = newDateTime;
        });
      },
    );
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
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Имя пользователя',
              ),
            ),
            SizedBox(height: 16.0),
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
            _buildGenderSelection(),
            SizedBox(height: 16.0),
            _buildDateOfBirthSelection(),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _handleRegistration,
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
  DateTime _dob = DateTime.now();
  String _gender = "";
  String _login = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double screenHeight = MediaQuery.of(context).size.height;
      double alertHeight = screenHeight * 0.4;
      double screenWidth = MediaQuery.of(context).size.width;
      double alertWidth = screenWidth * 0.4;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 20.0),
            title: const Text(
              "Вход",
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                const SizedBox(height: 5),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewForm(),
                        ),
                      );
                    },
                    child: const Text(
                      "Еще не зарегистрированы?",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),

                const SizedBox(
                    height: 40), // Увеличение промежутка между кнопками
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
          ),
        );
      },
    );
  }

  void _handleRegistration() async {
    final box = Hive.box<User>('new_users111');
    if (_username.isNotEmpty && _password.isNotEmpty) {
      var user = User(_username, _password, _dob, _gender, _login);
      box.put('new_users111', user);
    } else {}
  }

  void _handleLogin() async {
    final userBox = Hive.box<User>('new_users111');

    if (userBox.isEmpty || userBox.get('new_users111')!.username != _username) {
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
    DateTime messageTimestamp = DateTime.now();
    _textController.clear();

    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            text: text,
            username: _username,
            type: true,
            timestamp: messageTimestamp,
          ));
      isLoading = true; // Установка флага загрузки в true
    });
    final transresp = await translateText(text.toLowerCase(), 'ru', 'en');
    _getResponse(transresp);
  }

  Future<void> _getResponse(String query) async {
    DateTime messageTimestamp = DateTime.now();
    if (query.isEmpty) {
      ChatMessage errorMessage = ChatMessage(
        text: "Пустой запрос, пожалуйста, повторите",
        username: "Бот",
        type: false,
        timestamp: messageTimestamp,
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
          'https://healthservice.priaid.ch/symptoms?token=$tokens&format=json&language=en-gb');
      http.Response response1 = await http.get(url);
      int id = getIdForName(response1.body, diagnosis);
      int matchedId = -1;
      double? matchedAcc = -1;
      bool containsMatch = false;
      try {
        final jsonString = response1.body;
        List<dynamic> jsonArray = json.decode(jsonString);
        List<String> words = query.split(" ");
        print(words);
        for (var item in jsonArray) {
          String itemName = item["Name"].toString().toLowerCase();
          if (itemName.contains(query)) {
            containsMatch = true;
            matchedId = item["ID"];
            matchedAcc = item["Accuracy"];
            break;
          }
        }

        if (containsMatch) {
          print("Строка содержит совпадение. ID: $matchedId, Acc: $matchedAcc");
        } else {
          print("Строка не содержит совпадений.");
        }
      } catch (error) {
        print("Произошла ошибка: $error");
      }

      final translatedText = await translateText(query1, 'en', 'ru');
      String name = await getName(query, matchedId);

      String translatedName = '';
      if (!containsMatch) {
        translatedName = '-';
      } else {
        translatedName = await translateText(name, 'en', 'ru');
      }

      print(translatedText);

      message = ChatMessage(
        text: 'Результат: \n$translatedText.\nВозможные врачи: $translatedName',
        username: 'Бот',
        type: false,
        timestamp: messageTimestamp,
      );
    } catch (e) {
      if (response.getMessage() != null) {
        message = ChatMessage(
          text: response.getMessage().toString(),
          username: "Бот",
          type: false,
          timestamp: messageTimestamp,
        );
      } else if (response.getListMessage()?.isNotEmpty ?? false) {
        message = ChatMessage(
          text: CardDialogflow(response.getListMessage()?.elementAt(0)).title ??
              "",
          username: "Бот",
          type: false,
          timestamp: messageTimestamp,
        );
      } else {
        message = ChatMessage(
          text: "Извините, я не понимаю ваш запрос",
          username: "Бот",
          type: false,
          timestamp: messageTimestamp,
        );
      }
    }
    setState(() {
      _messages.insert(0, message);
      isLoading = false;
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
            child: Column(
              children: <Widget>[
                if (isLoading) // Проверка флага загрузки
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child:
                        CircularProgressIndicator(), // Отображение индикатора загрузки
                  ),
                if (!isLoading) // Если флаг загрузки равен false
                  _buildTextComposer(), // Отображение текстового поля ввода
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({
    required this.text,
    required this.username,
    required this.type,
    required this.timestamp,
  });

  final String text;
  final String username;
  final bool type;
  final DateTime timestamp;

  List<Widget> otherMessage(BuildContext context) {
    return <Widget>[
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 219, 241, 220),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Colors.green,
            ),
          ),
          margin: const EdgeInsets.only(right: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  username,
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
                Container(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> myMessage(BuildContext context) {
    return <Widget>[
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.35, // Adjust the maximum width as needed
            ),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 232, 223, 232),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Color.fromARGB(255, 202, 154, 210),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    username,
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
                  Container(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _getFormattedDate(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(left: 16.0),
      ),
    ];
  }

  String _getFormattedDate() {
    return DateFormat('HH:mm').format(timestamp);
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
