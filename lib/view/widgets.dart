import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../data/data_service.dart';

class Selection {
  static const List<int> options = [3, 5, 15];
}

class MyCustomScroll extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return GlowingOverscrollIndicator(
      child: child,
      axisDirection: axisDirection,
      color: Colors.red,
      showLeading: false,
      showTrailing: false,
    );
  }
}

class MyApp extends StatelessWidget {
  final List<int> loadOptions = Selection.options;
  final TextEditingController searchController =
      TextEditingController(); // Novo campo para o controlador de texto da pesquisa

  // Atualizar a consulta de pesquisa
  void updateSearchQuery(String query) {
    dataService.tableStateNotifier.value = {
      ...dataService.tableStateNotifier.value,
      'status': TableStatus.loading,
    };
    Future.delayed(Duration(milliseconds: 500), () {
      dataService.tableStateNotifier.value = {
        ...dataService.tableStateNotifier.value,
        'status': TableStatus.ready,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Polimorfismo"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: SizedBox(
                width: 200,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) => updateSearchQuery(
                      query), // Chamar a função updateSearchQuery ao digitar
                ),
              ),
            ),
            PopupMenuButton(
              itemBuilder: (_) => loadOptions
                  .map(
                    (num) => PopupMenuItem(
                      value: num,
                      child: Text("Carregar $num itens por vez"),
                    ),
                  )
                  .toList(),
              onSelected: (number) {
                dataService.numberOfItems = number;
              },
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: dataService.tableStateNotifier,
          builder: (_, value, __) {
            switch (value['status']) {
              case TableStatus.idle:
                return Center(child: Text("Toque em algum botão"));
              case TableStatus.loading:
                return Center(child: CircularProgressIndicator());
              case TableStatus.ready:
                return SingleChildScrollView(
                  child: DataTableWidget(
                    jsonObjects: value['dataObjects'],
                    propertyNames: value['propertyNames'],
                    columnNames: value['columnNames'],
                    searchQuery: searchController
                        .text, // Passar a consulta de pesquisa para o DataTableWidget
                  ),
                );
              case TableStatus.error:
                return Text("Lascou");
            }
            return Text("...");
          },
        ),
        bottomNavigationBar:
            NewNavBar(itemSelectedCallback: dataService.carregar),
      ),
    );
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;

  NewNavBar({itemSelectedCallback})
      : _itemSelectedCallback = itemSelectedCallback ?? (int) {}

  @override
  Widget build(BuildContext context) {
    var state = useState(1);
    return BottomNavigationBar(
        onTap: (index) {
          state.value = index;
          _itemSelectedCallback(index);
        },
        currentIndex: state.value,
        items: const [
          BottomNavigationBarItem(
              label: "Computador", icon: Icon(Icons.computer_outlined)),
          BottomNavigationBarItem(
              label: "Veículos", icon: Icon(Icons.fire_truck_outlined)),
          BottomNavigationBarItem(
              label: "Comidas", icon: Icon(Icons.fastfood_outlined))
        ]);
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;
  final String searchQuery; // Novo campo para a consulta de pesquisa

  DataTableWidget({
    this.jsonObjects = const [],
    this.columnNames = const [],
    this.propertyNames = const [],
    this.searchQuery = '', // Atribuição do parâmetro searchQuery
  });

  @override
  Widget build(BuildContext context) {
    List filteredObjects = jsonObjects;
    var sortCriteria = dataService.tableStateNotifier.value['sortCriteria'];
    var ascending = dataService.tableStateNotifier.value['ascending'];

    // Filtrar objetos com base na consulta de pesquisa
    if (searchQuery.length >= 3) {
      filteredObjects = jsonObjects.where((obj) {
        // Verificar se algum valor em qualquer coluna corresponde à pesquisa
        for (var propName in propertyNames) {
          String propertyValue = obj[propName].toString().toLowerCase();
          String query = searchQuery.toLowerCase();
          if (propertyValue.contains(query)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    return DataTable(
      columns: columnNames
          .asMap()
          .map(
            (index, name) => MapEntry(
              index,
              DataColumn(
                onSort: (columnIndex, ascending) =>
                    dataService.ordenarEstadoAtual(propertyNames[columnIndex]),
                label: Expanded(
                  child: InkWell(
                    onTap: () => dataService.ordenarEstadoAtual(propertyNames[
                        index]), // Atualizar ordenação ao clicar na coluna
                    child: Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        if (sortCriteria == propertyNames[index])
                          Icon(
                            ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .values
          .toList(),
      rows: filteredObjects // Usar os objetos filtrados
          .map(
            (obj) => DataRow(
              cells: propertyNames
                  .map(
                    (propName) => DataCell(Text(obj[propName])),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
