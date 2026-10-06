import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:z_speed/features/admin/datasource/audit_log_datasource.dart';
import 'package:z_speed/features/admin/cubit/admin_users_cubit.dart';
import 'package:z_speed/features/admin/view/admin_users_view.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
      ),
      body: BlocProvider(
        create: (ctx) => AdminUsersCubit(
          repository: getIt<AdminRepository>(),
          auditLogDatasource: getIt<AuditLogDatasource>(),
          currentUser: ctx.read<AuthCubit>().state.user,
        )..loadUsers(),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: AdminUsersView(),
        ),
      ),
    );
  }
}
