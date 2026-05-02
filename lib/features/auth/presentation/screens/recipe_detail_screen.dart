import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String id;
  const RecipeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Detalle receta $id')),
    );
  }
}