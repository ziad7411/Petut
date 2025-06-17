import 'package:flutter/material.dart';

import 'package:petut/Common/cards.dart';
import 'package:petut/Data/card_data.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      home: Scaffold(body:
      Padding(
        padding: const EdgeInsets.all(10),
        child: GridView(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2 , crossAxisSpacing: 5), children:  [
         Cards(data: CardData(rate: 4, image: 'assets/petut.png', title: 'Petut', description: 'description', weight: 5, price: 200), favFunction: (){}),
        
        ]),
      )),

