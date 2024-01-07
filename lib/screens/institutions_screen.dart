import 'package:flutter/material.dart';
import '../services/libproxydb_api.dart';

class InstitutionScreen extends StatefulWidget {
  @override
  _InstitutionScreenState createState() => _InstitutionScreenState();
}

class _InstitutionScreenState extends State<InstitutionScreen> {
  List<ProxyData> allProxies = [];
  List<ProxyData> filteredProxies = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProxies();
  }

  void fetchProxies() async {
    try {
      List<ProxyData> proxies = await ProxyService.fetchProxies();
      setState(() {
        allProxies = proxies;
        filteredProxies = proxies;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void filterProxies(String query) {
    List<ProxyData> filteredList = allProxies
        .where((proxy) =>
            proxy.name.toLowerCase().contains(query.toLowerCase()) ||
            proxy.url.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      filteredProxies = filteredList;
    });
  }

  void onInstitutionSelected(String name, String url) {
    Navigator.pop(context, {'name': name, 'url': url});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select your institution'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (query) {
                filterProxies(query);
              },
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProxies.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredProxies[index].name),
                  subtitle: Text(filteredProxies[index].url),
                  onTap: () {
                    onInstitutionSelected(
                      filteredProxies[index].name,
                      filteredProxies[index].url,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
