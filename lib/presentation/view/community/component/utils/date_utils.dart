import 'package:intl/intl.dart';

String formatDate(String dateTime) {
  try {
    final parsedDate = DateTime.parse(dateTime);
    final formattedDate = DateFormat('MMM yyyy, hh:mm a').format(parsedDate);
    return formattedDate;
  } catch (e) {
    return '';
  }
}

String formatTime(String dateTime) {
  try {
    final parsedDate = DateTime.parse(dateTime);
    final formattedDate = DateFormat('hh:mm a').format(parsedDate);
    return formattedDate;
  } catch (e) {
    return '';
  }
}

String formatDateWithMinMonth(String dateTime) {
  try {
    final parsedDate = DateFormat("MMMM dd, yyyy").parse(dateTime);
    return DateFormat("MMM dd, yyyy").format(parsedDate);
  } catch (e) {
    return dateTime;
  }
}

String formatHourMinute(DateTime dateTime) {
  try {
    return DateFormat('hh:mm').format(dateTime);
  } catch (e) {
    return '';
  }
}

String formatTimeJM(DateTime dateTime) {
  try {
    return DateFormat.jm().format(dateTime);
  } catch (e) {
    return '';
  }
}

String formatYMMMd(DateTime dateTime) {
  try {
    return DateFormat.yMMMd().format(dateTime);
  } catch (e) {
    return '';
  }
}

String formatDeadline(String? endedAt) {
  if (endedAt == null || endedAt.isEmpty) return '';
  try {
    final dateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').parse(endedAt, true).toLocal();
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  } catch (e) {
    return endedAt;
  }
}

String formatIsoDeadline(String? endedAt) {
  if (endedAt == null || endedAt.isEmpty) return '';
  try {
    final dateTime = DateTime.parse(endedAt).toLocal();
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  } catch (e) {
    return endedAt ?? '';
  }
}
