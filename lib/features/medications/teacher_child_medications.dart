import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';

class TeacherChildMedicationsScreen   extends StatefulWidget {
  const TeacherChildMedicationsScreen({super.key, required this.childId});
  final String childId;

  @override
  State<TeacherChildMedicationsScreen> createState() => _TeacherChildMedicationsScreenState();
}

class _TeacherChildMedicationsScreenState extends State<TeacherChildMedicationsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Child Medications',
        showBackButton: true,
        userRole: 'teacher',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text('Child Medications'),
          ],
        ),
      ),
    );
  }
}