import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DataService {
  static Future<List<Map<String, String>>> getTableData() async {
    String jsonStr = await rootBundle.loadString('assets/vr.json');
    List<dynamic> jsonData = json.decode(jsonStr);

    List<Map<String, String>> tableData = [];
    for (var data in jsonData) {
      if (data != null &&
          data['Кабинет'] != null &&
          data['ФИОврача'] != null &&
          data['Специализация'] != null &&
          data['Дни/Часыприема'] != null) {
        tableData.add({
          'Кабинет': data['Кабинет'],
          'ФИОврача': data['ФИОврача'],
          'Специализация': data['Специализация'],
          'Дни/Часыприема': data['Дни/Часыприема'],
        });
      }
    }

    return tableData;
  }

  static Future<List<Map<String, String>>> getSecondTableData() async {
    String jsonStr = await rootBundle.loadString('assets/det.json');
    List<dynamic> jsonData = json.decode(jsonStr);

    List<Map<String, String>> tableData = [];
    for (var data in jsonData) {
      if (data != null &&
          data['ФИОврача'] != null &&
          data['Специализация'] != null &&
          data['Дни/Часыприема'] != null) {
        tableData.add({
          'ФИОврача': data['ФИОврача'],
          'Специализация': data['Специализация'],
          'Дни/Часыприема': data['Дни/Часыприема'],
        });
      }
    }

    return tableData;
  }

  static Future<List<Map<String, String>>> getDetTableData() async {
    String jsonStr = await rootBundle.loadString('assets/zub.json');
    List<dynamic> jsonData = json.decode(jsonStr);

    List<Map<String, String>> tableData = [];
    for (var data in jsonData) {
      if (data != null &&
          data['Кабинет'] != null &&
          data['ФИОврача'] != null &&
          data['Специализация'] != null &&
          data['Дни/Часыприема'] != null) {
        tableData.add({
          'Кабинет': data['Кабинет'],
          'ФИОврача': data['ФИОврача'],
          'Специализация': data['Специализация'],
          'Дни/Часыприема': data['Дни/Часыприема'],
        });
      }
    }

    return tableData;
  }
}
