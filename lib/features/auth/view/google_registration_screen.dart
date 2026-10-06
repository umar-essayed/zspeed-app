import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/auth/view/user_type_selection_screen.dart';
import 'package:z_speed/features/driver/view/driver_application_form.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_application_form.dart';

/// Shown after a new Google user signs in.
/// Asks them to pick a role, then routes to extra info screen if needed.
class GoogleRegistrationScreen extends StatelessWidget {
  final AppUser pendingUser;

  const GoogleRegistrationScreen({super.key, required this.pendingUser});

  void _onRoleSelected(BuildContext context, UserType role) {
    final userWithRole = pendingUser.copyWith(type: role);

    switch (role) {
      case UserType.driver:
        context.read<AuthCubit>().completeGoogleRegistration(userWithRole);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthCubit>(),
            child: DriverApplicationForm(
              initialEmail: pendingUser.email,
              initialEmailVerified: true,
            ),
          ),
        ));
      case UserType.vendor:
        context.read<AuthCubit>().completeGoogleRegistration(userWithRole);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthCubit>(),
            child: RestaurantApplicationForm(
              initialEmail: pendingUser.email,
              initialEmailVerified: true,
            ),
          ),
        ));
      case UserType.customer:
      case UserType.admin:
      case UserType.superAdmin:
        // No extra info needed — save and authenticate
        context.read<AuthCubit>().completeGoogleRegistration(userWithRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserTypeSelection(
      onUserTypeSelected: (role) => _onRoleSelected(context, role),
    );
  }
}
