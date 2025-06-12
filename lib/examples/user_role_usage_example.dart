import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/user_role_provider.dart';
import 'package:nursery_app/models/user/user_role_model.dart';

/// Example screen showing how to use UserRoleProvider
class UserRoleExampleScreen extends StatelessWidget {
  const UserRoleExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Role Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh roles from Firebase
              context.read<UserRoleProvider>().refreshRoles();
            },
          ),
        ],
      ),
      body: Consumer<UserRoleProvider>(
        builder: (context, userRoleProvider, child) {
          if (userRoleProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user roles...'),
                ],
              ),
            );
          }

          if (userRoleProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${userRoleProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      userRoleProvider.refreshRoles();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available User Roles (${userRoleProvider.roles.length})',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // Display all roles
                Expanded(
                  child: ListView.builder(
                    itemCount: userRoleProvider.roles.length,
                    itemBuilder: (context, index) {
                      final role = userRoleProvider.roles[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(role.id.toString()),
                          ),
                          title: Text(role.roleName),
                          subtitle: Text('Type: ${role.type.name}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () => _showRoleDetails(context, role),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Quick access buttons
                const SizedBox(height: 16),
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final parentRole = userRoleProvider.parentRole;
                          if (parentRole != null) {
                            _showRoleDetails(context, parentRole);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Parent role not found')),
                            );
                          }
                        },
                        child: const Text('Get Parent Role'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final teacherRole = userRoleProvider.teacherRole;
                          if (teacherRole != null) {
                            _showRoleDetails(context, teacherRole);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Teacher role not found')),
                            );
                          }
                        },
                        child: const Text('Get Teacher Role'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRoleDetails(BuildContext context, UserRole role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Role Details: ${role.roleName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${role.id}'),
            Text('Name: ${role.roleName}'),
            Text('Type: ${role.type.name}'),
            Text('Created: ${role.timestamps.createdAt}'),
            Text('Updated: ${role.timestamps.updatedAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Example widget showing how to use roles in a widget
class RoleBasedWidget extends StatelessWidget {
  const RoleBasedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRoleProvider>(
      builder: (context, userRoleProvider, child) {
        // Check if specific roles exist
        final hasParentRole = userRoleProvider.roleExists(RoleType.parent);
        final hasTeacherRole = userRoleProvider.roleExists(RoleType.teacher);
        final hasAdminRole = userRoleProvider.roleExists(RoleType.admin);

        return Column(
          children: [
            if (hasParentRole)
              const ListTile(
                leading: Icon(Icons.family_restroom),
                title: Text('Parent features available'),
              ),
            if (hasTeacherRole)
              const ListTile(
                leading: Icon(Icons.school),
                title: Text('Teacher features available'),
              ),
            if (hasAdminRole)
              const ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text('Admin features available'),
              ),
          ],
        );
      },
    );
  }
}

/// Example function showing how to use UserRoleProvider methods
void exampleUsage(BuildContext context) {
  final userRoleProvider = context.read<UserRoleProvider>();

  // Get specific role
  final parentRole = userRoleProvider.parentRole;
  if (parentRole != null) {
    print('Parent role found: ${parentRole.roleName}');
  }

  // Check if role exists
  if (userRoleProvider.roleExists(RoleType.teacher)) {
    print('Teacher role is available');
  }

  // Get all roles
  final allRoles = userRoleProvider.roles;
  print('Total roles: ${allRoles.length}');

  // Refresh roles manually
  userRoleProvider.refreshRoles();
} 