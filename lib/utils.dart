import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

IconData getNumberOfRephotosIcon(int numberOfRephotos) {
  IconData numberOfRephotosIcon;

  switch (numberOfRephotos) {
    case 1:
      numberOfRephotosIcon = Icons.filter_1;
      break;
    case 2:
      numberOfRephotosIcon = Icons.filter_2;
      break;
    case 3:
      numberOfRephotosIcon = Icons.filter_3;
      break;
    case 4:
      numberOfRephotosIcon = Icons.filter_4;
      break;
    case 5:
      numberOfRephotosIcon = Icons.filter_5;
      break;
    case 6:
      numberOfRephotosIcon = Icons.filter_6;
      break;
    case 7:
      numberOfRephotosIcon = Icons.filter_7;
      break;
    case 8:
      numberOfRephotosIcon = Icons.filter_8;
      break;
    case 9:
      numberOfRephotosIcon = Icons.filter_9;
      break;
    default:
      numberOfRephotosIcon = Icons.filter_9_plus;
      break;
  }

  return numberOfRephotosIcon;
}
