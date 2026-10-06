import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_reports_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class AdminReportsCubit extends Cubit<AdminReportsState> {
  AdminReportsCubit() : super(const AdminReportsState());

  // In a real app, methods to generate/download reports would be here.
}
