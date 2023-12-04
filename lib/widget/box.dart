import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Box extends StatelessWidget {
  final  number;
  final  selectedBox;
  final Function(int) onSelect;

  Box(this.number, this.selectedBox, this.onSelect);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelect(number);
      },
      child: Container(
        width: 100,
        height: 100,
        color: selectedBox == number ? Colors.blue : Colors.grey,
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}