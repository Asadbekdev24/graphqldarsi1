import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_work/view/pages/todo_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final HttpLink httpLink = HttpLink("http://192.168.17.37:4000/");
    final HttpLink httpLink = HttpLink("http://localhost:4000/");
    //final HttpLink httpLink = HttpLink("http://192.168.17.37:4000/graphql");

    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(),
      ),
    );

    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TodosScreen(),
      ),
    );
  }
}
