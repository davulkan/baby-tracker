// // lib/screens/add_head_circumference_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:baby_tracker/providers/auth_provider.dart';
// import 'package:baby_tracker/providers/baby_provider.dart';
// import 'package:baby_tracker/providers/events_provider.dart';
// import 'package:baby_tracker/providers/theme_provider.dart';
// import 'package:baby_tracker/models/event.dart';
// import 'package:baby_tracker/widgets/date_time_picker.dart';

// class AddHeadCircumferenceScreen extends StatefulWidget {
//   final Event? event;

//   const AddHeadCircumferenceScreen({super.key, this.event});

//   @override
//   State<AddHeadCircumferenceScreen> createState() =>
//       _AddHeadCircumferenceScreenState();
// }

// class _AddHeadCircumferenceScreenState
//     extends State<AddHeadCircumferenceScreen> {
//   DateTime _dateTime = DateTime.now();
//   double _circumferenceCm = 35.0;
//   final _notesController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//   }

//   Future<void> _initializeData() async {
//     setState(() => _isLoading = true);

//     if (widget.event != null) {
//       _dateTime = widget.event!.startedAt;
//       if (widget.event!.notes != null) {
//         _notesController.text = widget.event!.notes!;
//       }
//       if (widget.event!.headCircumferenceCm != null) {
//         _circumferenceCm = widget.event!.headCircumferenceCm!;
//       }
//     }

//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDateTime(BuildContext context) async {
//     final selected = await showCupertinoDateTimePicker(context, _dateTime);
//     if (selected != null) {
//       setState(() {
//         _dateTime = selected;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         appBar: AppBar(
//           backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back,
//                 color: Theme.of(context).appBarTheme.foregroundColor),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.child_care, color: context.appColors.primaryAccent),
//               SizedBox(width: 8),
//               Text(
//                 widget.event != null
//                     ? 'Редактировать окружность'
//                     : 'Окружность головы',
//                 style: TextStyle(
//                     color: Theme.of(context).appBarTheme.foregroundColor),
//               ),
//             ],
//           ),
//           centerTitle: true,
//         ),
//         body: Center(
//           child: CircularProgressIndicator(
//             color: context.appColors.primaryAccent,
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back,
//               color: Theme.of(context).appBarTheme.foregroundColor),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.child_care, color: context.appColors.primaryAccent),
//             SizedBox(width: 8),
//             Text(
//               widget.event != null
//                   ? 'Редактировать окружность'
//                   : 'Окружность головы',
//               style: TextStyle(
//                   color: Theme.of(context).appBarTheme.foregroundColor),
//             ),
//           ],
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildDateTimeSelector(),
//             const SizedBox(height: 32),
//             _buildCircumferenceSelector(),
//             const SizedBox(height: 32),
//             _buildNotesField(),
//             const SizedBox(height: 32),
//             _buildSaveButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateTimeSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Дата и время',
//           style: TextStyle(
//             color: context.appColors.textPrimaryColor,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 12),
//         GestureDetector(
//           onTap: () => _selectDateTime(context),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: context.appColors.surfaceVariantColor,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: context.appColors.primaryAccent),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   DateFormat('dd.MM.yyyy HH:mm').format(_dateTime),
//                   style: TextStyle(
//                     color: context.appColors.textPrimaryColor,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const Spacer(),
//                 Icon(
//                   Icons.calendar_today,
//                   color: context.appColors.primaryAccent,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCircumferenceSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Окружность головы (см)',
//           style: TextStyle(
//             color: context.appColors.textPrimaryColor,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: context.appColors.surfaceVariantColor,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: context.appColors.primaryAccent),
//           ),
//           child: Column(
//             children: [
//               GestureDetector(
//                 onTap: _showCircumferenceInputDialog,
//                 child: Text(
//                   _circumferenceCm.toStringAsFixed(1),
//                   style: TextStyle(
//                     color: context.appColors.textPrimaryColor,
//                     fontSize: 48,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Slider(
//                 value: _circumferenceCm,
//                 min: 25.0,
//                 max: 60.0,
//                 divisions: 350,
//                 activeColor: context.appColors.primaryAccent,
//                 inactiveColor:
//                     context.appColors.surfaceVariantColor.withOpacity(0.5),
//                 onChanged: (value) {
//                   setState(() {
//                     _circumferenceCm = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '25 см',
//                     style: TextStyle(
//                       color: context.appColors.textSecondaryColor,
//                       fontSize: 12,
//                     ),
//                   ),
//                   Text(
//                     '60 см',
//                     style: TextStyle(
//                       color: context.appColors.textSecondaryColor,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _showCircumferenceInputDialog() async {
//     final controller =
//         TextEditingController(text: _circumferenceCm.toStringAsFixed(1));
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Theme.of(context).dialogBackgroundColor,
//         title: Text(
//           'Введите окружность (см)',
//           style:
//               TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
//         ),
//         content: TextField(
//           controller: controller,
//           keyboardType: TextInputType.numberWithOptions(decimal: true),
//           decoration: InputDecoration(
//             hintText: 'Например: 35.0',
//             hintStyle: TextStyle(color: context.appColors.textHintColor),
//             filled: true,
//             fillColor: context.appColors.surfaceVariantColor,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide.none,
//             ),
//           ),
//           style: TextStyle(color: context.appColors.textPrimaryColor),
//           autofocus: true,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               'Отмена',
//               style: TextStyle(color: context.appColors.textSecondaryColor),
//             ),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, controller.text),
//             child: Text(
//               'OK',
//               style: TextStyle(color: context.appColors.primaryAccent),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (result != null && result.isNotEmpty) {
//       final value = double.tryParse(result.replaceAll(',', '.'));
//       if (value != null && value >= 25.0 && value <= 60.0) {
//         setState(() {
//           _circumferenceCm = value;
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//                 'Введите корректное значение окружности (25.0-60.0 см)'),
//             backgroundColor: context.appColors.errorColor,
//           ),
//         );
//       }
//     }
//   }

//   Widget _buildNotesField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Комментарий',
//           style: TextStyle(
//             color: context.appColors.textPrimaryColor,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextField(
//           controller: _notesController,
//           maxLines: 3,
//           style: TextStyle(color: context.appColors.textPrimaryColor),
//           decoration: InputDecoration(
//             hintText: 'Ваш комментарий',
//             hintStyle: TextStyle(color: context.appColors.textHintColor),
//             filled: true,
//             fillColor: context.appColors.surfaceVariantColor,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSaveButton() {
//     return Consumer3<AuthProvider, BabyProvider, EventsProvider>(
//       builder: (context, authProvider, babyProvider, eventsProvider, child) {
//         return ElevatedButton(
//           onPressed: eventsProvider.isLoading
//               ? null
//               : () async {
//                   final baby = babyProvider.currentBaby;
//                   if (baby == null) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content:
//                             const Text('Ошибка: профиль ребенка не найден'),
//                         backgroundColor: context.appColors.errorColor,
//                       ),
//                     );
//                     return;
//                   }

//                   bool success;
//                   if (widget.event != null) {
//                     // Обновляем существующее событие
//                     final updatedEvent = widget.event!.copyWith(
//                       startedAt: _dateTime,
//                       notes: _notesController.text.trim().isEmpty
//                           ? null
//                           : _notesController.text.trim(),
//                       headCircumferenceCm: _circumferenceCm,
//                       lastModifiedAt: DateTime.now(),
//                     );

//                     success = await eventsProvider.updateEvent(updatedEvent);
//                   } else {
//                     // Создаем новое событие
//                     final eventId =
//                         await eventsProvider.addHeadCircumferenceEvent(
//                       babyId: baby.id,
//                       familyId: authProvider.familyId!,
//                       time: _dateTime,
//                       circumferenceCm: _circumferenceCm,
//                       createdBy: authProvider.currentUser!.uid,
//                       createdByName: authProvider.currentUser!.displayName ??
//                           'Пользователь',
//                       notes: _notesController.text.trim().isEmpty
//                           ? null
//                           : _notesController.text.trim(),
//                     );
//                     success = eventId != null;
//                   }

//                   if (success && context.mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(widget.event != null
//                             ? 'Окружность обновлена'
//                             : 'Окружность добавлена'),
//                         backgroundColor: context.appColors.successColor,
//                       ),
//                     );
//                     Navigator.pop(context);
//                   } else if (context.mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           eventsProvider.error ??
//                               (widget.event != null
//                                   ? 'Ошибка обновления окружности'
//                                   : 'Ошибка добавления окружности'),
//                         ),
//                         backgroundColor: context.appColors.errorColor,
//                       ),
//                     );
//                   }
//                 },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: context.appColors.primaryAccent,
//             padding: const EdgeInsets.all(20),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: eventsProvider.isLoading
//               ? SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: context.appColors.textPrimaryColor,
//                   ),
//                 )
//               : Text(
//                   widget.event != null ? 'Обновить' : 'Сохранить',
//                   style: TextStyle(
//                     color: context.appColors.textPrimaryColor,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         );
//       },
//     );
//   }
// }
