import 'dart:collection';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

const Map<String, String> en = {
  'hello': 'Hello',
  'multipleLanguage': 'Multiple language',
  'recent_images': 'Recent images',
  'recent_files': 'Recent files',
  'see_all': 'See all',
  'ago': 'ago',
  'seconds': 'seconds',
  'minutes': 'minutes',
  'hours': 'hours',
  'days': 'days',
  'working_space_empty': 'Your working space is empty.',
  'file_save_in_download_folder': 'File saved in download folder.',
  'file_save_failed': 'File save failed.',
  'delete': 'Delete',
  'share': 'Share',
  'save': 'Save',
  'file_managers': 'File managers',
  'today': 'Today',
  'yesterday': 'Yesterday',
  'last_7_days': 'Last 7 days',
  'last_30_days': 'Last 30 days',
  'older': 'Older',
  'all': 'All',
  'select': 'Select',
  'open': 'Open',
  'check': 'Check',
  'some_thing_went_wrong': 'Sorry, something went wrong!',
  'export_report_successfully': 'Export report successfully!',
  'photo_gallery': 'Photo gallery',
  'item_selected': 'item selected',
  "language": "Language",
  'light_mode': 'Light mode',
  'dark_mode': 'Dark mode',
  'sign_out': 'Sign out',
  'update_name': 'Update name',
  'enter_your_new_name': 'Enter your new name',
  'cancel': 'Cancel',
  'update': 'Update',
  'update_failed': 'Update failed!',
  'uploading_avatar': 'Uploading avatar...',
  'update_avatar_failed': 'Update avatar failed!',
  'update_avatar_successfully': 'Update avatar successfully!',
  'top_panel_processing':'Processing...',
  'top_panel_finished': 'Finished',
  'top_panel_start_detecting': 'Starting...',
  'top_panel_success': 'Success',
  'top_panel_failed': 'Failed',
  'dont_have_an_account': "Don't have an account?",
  'register': 'Register',
  "already_have_an_account": "Already have an account?",
  'sign_in': 'Sign in',
  'anonymous_sign_in': 'Anonymous sign in',
};

const Map<String, String> vi = {
  'hello': 'Xin chào',
  'multipleLanguage': 'Đa ngôn ngữ',
  'recent_images': 'Ảnh gần đây',
  'recent_files': 'Tệp gần đây',
  'see_all': 'Xem tất cả',
  'ago': 'trước',
  'seconds': 'giây',
  'minutes': 'phút',
  'hours': 'giờ',
  'days': 'ngày',
  'working_space_empty': 'Không có dữ liệu.',
  'file_save_in_download_folder': 'Tệp đã được lưu trong thư mục tải xuống.',
  'file_save_failed': 'Lưu tệp tin thất bại.',
  'delete': 'Xóa',
  'share': 'Chia sẻ',
  'save': 'Lưu',
  'file_managers': 'Quản lý tệp',
  'today': 'Hôm nay',
  'yesterday': 'Hôm qua',
  'last_7_days': '7 ngày trước',
  'last_30_days': '30 ngày trước',
  'older': 'Cũ hơn',
  'all': 'Tất cả',
  'select': 'Chọn',
  'open': 'Mở',
  'check': 'So sánh',
  'some_thing_went_wrong': 'Có lỗi xảy ra!',
  'export_report_successfully': 'Xuất báo cáo thành công!',
  'photo_gallery': 'Thư viện ảnh',
  'item_selected': 'đã chọn',
  "language": "Ngôn ngữ",
  'light_mode': 'Chế độ sáng',
  'dark_mode': 'Chế độ tối',
  'sign_out': 'Đăng xuất',
  'update_name': 'Đổi tên',
  'enter_your_new_name': 'Nhập tên mới',
  'cancel': 'Hủy',
  'update': 'Cập nhật',
  'update_failed': 'Cập nhật thất bại!',
  'uploading_avatar': 'Đang tải lên ảnh đại diện...',
  'update_avatar_failed': 'Cập nhật ảnh đại diện thất bại!',
  'update_avatar_successfully': 'Cập nhật ảnh đại diện thành công!',
  'top_panel_processing':'Đang xử lý...',
  'top_panel_finished': 'Đã hoàn thành',
  'top_panel_success': 'Thành công',
  'top_panel_start_detecting':'Đang bắt đầu...',
  'top_panel_failed': 'Thất bại',
  'dont_have_an_account': "Chưa có tài khoản?",
  'register': 'Đăng ký',
  "already_have_an_account": "Đã có tài khoản?",
  'sign_in': 'Đăng nhập',
  'anonymous_sign_in': 'Đăng nhập ẩn danh',
};

class LocalizationService extends Translations {
  static final locale = _getLocaleFromStorage();

  static const defaultLocale = Locale('vi', 'VN');

  static final langCodes = [
    'en',
    'vi',
  ];

  // các Locale được support
  static final locales = [
    const Locale('en', 'US'),
    const Locale('vi', 'VN'),
  ];

  static final langs = LinkedHashMap.from({
    'en': 'English',
    'vi': 'Tiếng Việt',
  });

  static void changeLocale(String langCode) {
    final locale = _getLocaleFromLanguage(langCode);
    Get.updateLocale(locale);
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'vi_VN': vi,
      };

  static Locale _getLocaleFromLanguage(String? langCode) {
    for (int i = 0; i < langCodes.length; i++) {
      if (langCode == langCodes[i]) return locales[i];
    }
    return defaultLocale;
  }

  static _getLocaleFromStorage() {
    var langCode = GetStorage().read('language');
    return _getLocaleFromLanguage(langCode);
  }
}
