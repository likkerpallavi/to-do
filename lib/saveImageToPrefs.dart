import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveImageToPrefs(File imageFile) async {
  final bytes = await imageFile.readAsBytes(); // Convert image to bytes
  final base64Image = base64Encode(bytes); // Convert bytes to base64 string

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('background_image', base64Image); // Save base64 string
}
// Future<File?> getImageFromPrefs() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String? base64Image = prefs.getString('background_image');
//
//   if (base64Image != null) {
//     final bytes = base64Decode(base64Image); // Decode base64 to bytes
//     return File.fromRawPath(bytes); // Create file from bytes if needed
//   }
//   return null; // Return null if no image is stored
// }
Future<File?> getImageFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? base64Image = prefs.getString('background_image');

  if (base64Image != null) {
    final bytes = base64Decode(base64Image); // Decode base64 to bytes
    return File.fromRawPath(bytes); // Create file from bytes if needed
  }
  return null; // Return null if no image is stored
}

Future<File?> getImageWidgetFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? base64Image = prefs.getString('background_image');

  if (base64Image != null) {
    final bytes = base64Decode(base64Image); // Decode base64 to bytes
    return File.fromRawPath(bytes); // Create an image widget directly
  }
  return null;
}
