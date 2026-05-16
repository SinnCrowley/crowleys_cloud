import 'package:flutter/material.dart';

const appBackground = Color(0xFF222222);
const appSurface = Color(0xFF333333);
const appAccent = Color(0xFFfa5252);

class FileCategory {
  final String name;
  final IconData icon;
  const FileCategory(this.name, this.icon);
}

const photoExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.bmp',
  '.webp',
  '.avif',
  '.heif',
  '.heic',
};

const videoExtensions = {'.mp4', '.mkv', '.webm', '.mov', '.avi', '.flv'};

const audioExtensions = {'.mp3', '.wav', '.aac', '.m4a', '.ogg', '.flac'};

const documentExtensions = {
  '.pdf',
  '.doc',
  '.docx',
  '.xls',
  '.xlsx',
  '.ppt',
  '.pptx',
  '.txt',
  '.csv',
};

const textExtensions = {'.txt', '.md', '.log', '.csv', '.json'};
