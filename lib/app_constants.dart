// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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

const String appVersion = '0.2.0';
const String githubRepoOwner = 'SinnCrowley';
const String githubRepoName = 'crowleys_cloud';
