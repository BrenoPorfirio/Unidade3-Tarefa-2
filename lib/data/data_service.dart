import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

var values = [3, 7, 15];

enum TableStatus { idle, loading, ready, error }

enum ItemType {
  computer,
  food,
  vehicle,
  none;

  String get asString => '$name';

  List<String> get columns => this == computer
      ? ["Plataforma", "Tipo", "Sistema Operacional"]
      : this == vehicle
          ? ["Modelo", "Cor", "Transmissão"]
          : this == food
              ? ["Prato", "Ingredientes", "Medição"]
              : [];

  List<String> get properties => this == computer
      ? ["platform", "type", "os"]
      : this == vehicle
          ? ["make_and_model", "color", "transmission"]
          : this == food
              ? ["dish", "ingredient", "measurement"]
              : [];
}

class DataService {
  static int get MAX_N_ITEMS => values[2];
  static int get MIN_N_ITEMS => values[0];
  static int get DEFAULT_N_ITEMS => values[1];

  int _numberOfItems = DEFAULT_N_ITEMS;

  set numberOfItems(n) {
    _numberOfItems = n < 0
        ? MIN_N_ITEMS
        : n > MAX_N_ITEMS
            ? MAX_N_ITEMS
            : n;
  }

  int get numberOfItems {
    return _numberOfItems;
  }

  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
    'itemType': ItemType.none,
    'sortCriteria': '',
    'ascending': true,
  });

  void carregar(index) {
    final params = [ItemType.computer, ItemType.vehicle, ItemType.food];

    carregarPorTipo(params[index]);
  }

  void ordenarEstadoAtual(String propriedade) {
    List objetos = tableStateNotifier.value['dataObjects'] ?? [];

    if (objetos.isEmpty) return;

    bool ascending = true;
    var sortCriteria = tableStateNotifier.value['sortCriteria'];

    if (sortCriteria == propriedade) {
      ascending = !tableStateNotifier.value[
          'ascending']; // Alternar entre crescente e decrescente se a mesma coluna for clicada novamente
    }

    objetos.sort((a, b) {
      final valueA = a[propriedade];
      final valueB = b[propriedade];
      return ascending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
    });

    emitirEstadoOrdenado(objetos, propriedade, ascending);
  }

  Uri montarUri(ItemType type) {
    return Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/${type.asString}/random_${type.asString}',
        queryParameters: {'size': '$_numberOfItems'});
  }

  Future<List<dynamic>> acessarApi(Uri uri) async {
    var jsonString = await http.read(uri);
    var json = jsonDecode(jsonString);

    json = [...tableStateNotifier.value['dataObjects'], ...json];

    return json;
  }

  void emitirEstadoOrdenado(
      List objetosOrdenados, String propriedade, bool ascending) {
    var estado = Map<String, dynamic>.from(tableStateNotifier.value);

    estado['dataObjects'] = objetosOrdenados;
    estado['sortCriteria'] = propriedade;
    estado['ascending'] = ascending;

    tableStateNotifier.value = estado;
  }

  void emitirEstadoCarregando(ItemType type) {
    tableStateNotifier.value = {
      'status': TableStatus.loading,
      'dataObjects': [],
      'itemType': type,
      'sortCriteria': '',
      'ascending': true,
    };
  }

  void emitirEstadoPronto(ItemType type, var json) {
    tableStateNotifier.value = {
      'itemType': type,
      'status': TableStatus.ready,
      'dataObjects': json,
      'propertyNames': type.properties,
      'columnNames': type.columns,
      'sortCriteria': '',
      'ascending': true,
    };
  }

  bool temRequisicaoEmCurso() =>
      tableStateNotifier.value['status'] == TableStatus.loading;

  bool mudouTipoDeItemRequisitado(ItemType type) =>
      tableStateNotifier.value['itemType'] != type;

  void carregarPorTipo(ItemType type) async {
    //ignorar solicitação se uma requisição já estiver em curso
    if (temRequisicaoEmCurso()) {
      return;
    }
    if (mudouTipoDeItemRequisitado(type)) {
      emitirEstadoCarregando(type);
    }

    var uri = montarUri(type);
    var json = await acessarApi(uri); //, type);

    emitirEstadoPronto(type, json);
  }
}

final dataService = DataService();
