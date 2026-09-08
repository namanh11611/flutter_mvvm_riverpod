import 'routes.dart';

String? accountAccessRedirect(String access, String path) {
  final adminPath = path == Routes.admin || path.startsWith('${Routes.admin}/');
  if (access == 'banned' || access == 'suspended') {
    return path == Routes.accountBanned ? null : Routes.accountBanned;
  }
  if (access == 'admin') return adminPath ? null : Routes.admin;
  if (adminPath || path == Routes.accountBanned) {
    return access == 'anonymous' ? Routes.login : Routes.main;
  }
  return null;
}
