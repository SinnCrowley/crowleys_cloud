import 'package:crowleys_cloud/app_theme.dart';
import 'package:flutter/material.dart';

export 'package:crowleys_cloud/app_theme.dart';

Color get appBackground => AppTheme.current.background;
Color get appSurface => AppTheme.current.surface;
Color get appAccent => AppTheme.current.accent;
Color get appText => AppTheme.current.text;
Color get appSubtext => AppTheme.current.subtext;
Color get appBorder => AppTheme.current.border;

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

const String appVersion = '1.0.0';
const String githubRepoOwner = 'SinnCrowley';
const String githubRepoName = 'crowleys_cloud';
