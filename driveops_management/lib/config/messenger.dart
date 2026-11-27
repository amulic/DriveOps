import 'package:flutter/material.dart';

/// App-wide messenger used by background listeners (SignalR fleet updates,
/// service reminders) that have no BuildContext of their own.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
