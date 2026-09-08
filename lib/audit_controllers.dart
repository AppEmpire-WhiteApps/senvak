import 'package:signals_flutter/signals_flutter.dart';

/// Tracks which slide of the audit introduction is currently shown.
class AuditIntroController {
  AuditIntroController({required this.slideCount});

  final int slideCount;
  final _value = signal(0);
  late final _isFinalSlide = computed(() => value == slideCount - 1);

  int get value => _value.value;
  set value(int value) => _value.value = value;

  bool get isFinalSlide => _isFinalSlide.value;

  void showSlide(int index) {
    if (index == value) return;
    value = index;
  }
}

/// Selects the active workspace section of the Senvak shell.
class WorkspaceTabsController {
  final _value = signal(0);

  int get value => _value.value;
  set value(int value) => _value.value = value;

  void selectTab(int index) => value = index;
}

/// Holds the choices of a measurement while it is being captured.
class AuditDraftController {
  final _saving = signal(false);
  final _takePhoto = signal(false);

  bool get saving => _saving.value;
  set saving(bool value) => _saving.value = value;

  bool get takePhoto => _takePhoto.value;
  set takePhoto(bool value) => _takePhoto.value = value;

  void beginSaving() {
    saving = true;
  }

  void finishSaving() {
    saving = false;
  }

  void selectPhotoCapture(bool value) {
    if (takePhoto == value) return;
    takePhoto = value;
  }
}

/// Guards the site creation sheet against duplicate submissions.
class SiteCreationController {
  final _submitting = signal(false);

  bool get submitting => _submitting.value;
  set submitting(bool value) => _submitting.value = value;

  bool beginSubmitting() {
    if (submitting) return false;
    submitting = true;
    return true;
  }
}
