import 'package:material_ui/material_ui.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final int unixTimestamp;

  const CountdownTimer({super.key, required this.unixTimestamp});

  @override
  CountdownTimerState createState() => CountdownTimerState();
}

class CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _remainingSeconds = widget.unixTimestamp - now;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _isExpired = true;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text(
        _isExpired ? 'EXPIRED' : _formatTime(_remainingSeconds),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _isExpired ? Colors.red : Colors.black,
        ),
      ),
    );
  }
}
