library xgrep.xgrep;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';
import 'package:collection/equality.dart';
import 'package:ebisu/ebisu.dart' as ebisu;
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

// custom <additional imports>
// end <additional imports>

part 'src/xgrep/grep.dart';
part 'src/xgrep/index.dart';
part 'src/xgrep/mlocate_index_updater.dart';
part 'src/xgrep/mongo_index_persister.dart';

final _logger = new Logger('xgrep');

// custom <library xgrep>
// end <library xgrep>
