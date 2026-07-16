import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../../core/localization/app_strings.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../../core/settings/app_settings_scope.dart';
import '../../../../core/theme/app_palette.dart';
import '../../auth/data/models/auth_session.dart';
import '../data/models/incident_category.dart';
import '../data/models/location_type.dart';
import '../data/models/pending_incident_report.dart';
import '../data/models/report_submission_result.dart';
import '../data/services/offline_report_store.dart';
import '../data/services/reporting_api_service.dart';
import '../data/services/reporting_seed_data.dart';
import '../data/services/reverse_geocoding_service.dart';

import '../data/services/emergency_api_service.dart';
import '../data/models/emergency_sos_result.dart';


enum _AppSection {
  home,
  hotspot,
  report,
  offline,
  sos,
  guide,
  syncCenter,
  settings,
  themes,
}

class ReportHomePage extends StatefulWidget {
  const ReportHomePage({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  final AuthenticatedUser currentUser;
  final Future<void> Function() onLogout;

  @override
  State<ReportHomePage> createState() => _ReportHomePageState();
}

class _ReportHomePageState extends State<ReportHomePage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = ReportingApiService();
  final _offlineStore = OfflineReportStore();

  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<IncidentCategory> _categories = const [];
  List<LocationType> _locationTypes = const [];
  List<PendingIncidentReport> _pendingReports = const [];
  IncidentCategory? _selectedCategory;
  LocationType? _selectedLocationType;
  DateTime? _selectedDateTime;
  double? _capturedLatitude;
  double? _capturedLongitude;
  bool _consentAcknowledged = false;
  bool _isGettingLocation = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _usingOfflineTaxonomies = false;
  bool _isLiveConnectionAvailable = false;
  bool _isSyncingPendingReports = false;
  bool _isPreparingSos = false;

  String? _emergencyReference;
  String _emergencyStatus = "Waiting for Emergency SOS...";

  Map<String, dynamic>? _cachedHotspots;

  int _pendingReportCount = 0;
  int? _selectedBottomIndex = 0;
  _AppSection _currentSection = _AppSection.home;
  ReportSubmissionResult? _lastSubmission;
  final List<_AppSection> _sectionHistory = [];

  AppStrings get _strings => AppSettingsScope.readStringsOf(context);
  AppSettingsController get _settingsController =>
      AppSettingsScope.readControllerOf(context);
  bool get _autoSyncEnabled => _settingsController.autoSyncEnabled;
  bool get _locationHintsEnabled => _settingsController.locationHintsEnabled;
  bool get _privacyTipsEnabled => _settingsController.privacyTipsEnabled;

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initialize();
}


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTaxonomies();
    }
  }

  Future<void> _initialize() async {
  await _refreshPendingReportCount();

  _cachedHotspots = await _offlineStore.loadHotspots();

  await _loadTaxonomies();
}

Future<Map<String, dynamic>> _getHotspotsData() async {
  try {
    final data = await _api.getHotspots();

    await _offlineStore.saveHotspots(data);

    _cachedHotspots = data;

    return data;
  } catch (_) {
    if (_cachedHotspots != null) {
      return _cachedHotspots!;
    }

    final cached = await _offlineStore.loadHotspots();

    if (cached != null) {
      _cachedHotspots = cached;
      return cached;
    }

    return {
      'reports': [],
      'top_areas': [],
      'total': 0,
    };
  }
}

  Future<void> _refreshPendingReportCount() async {
    final pendingReports = await _offlineStore.loadPendingReports();
    if (!mounted) {
      return;
    }

    setState(() {
      _pendingReports = pendingReports;
      _pendingReportCount = pendingReports.length;
    });
  }

  IncidentCategory? _categoryForCode(
    List<IncidentCategory> categories,
    String? code,
  ) {
    if (categories.isEmpty) {
      return null;
    }

    for (final category in categories) {
      if (category.code == code) {
        return category;
      }
    }

    return categories.first;
  }

  LocationType? _locationTypeForCode(
    List<LocationType> locationTypes,
    String? code,
  ) {
    if (locationTypes.isEmpty) {
      return null;
    }

    for (final locationType in locationTypes) {
      if (locationType.code == code) {
        return locationType;
      }
    }

    return locationTypes.first;
  }

  Future<void> _loadTaxonomies() async {
    final previousCategoryCode = _selectedCategory?.code;
    var backendAvailable = false;

    setState(() {
      _isLoading = true;
    });

    try {
      backendAvailable = await _api.isBackendAvailable();
      if (!backendAvailable) {
        throw const SocketException("Backend is not reachable.");
      }

      final categories = await _api.fetchIncidentCategories();
      final locationTypes = await _api.fetchLocationTypes();

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _locationTypes = locationTypes;
        _selectedCategory = _categoryForCode(categories, previousCategoryCode);
        _selectedLocationType = _locationTypeForCode(
          locationTypes,
          "STREET",
        );
        _isLiveConnectionAvailable = true;
        _usingOfflineTaxonomies = false;
        _isLoading = false;
      });

      if (_pendingReportCount > 0) {
        await _syncPendingReports(
          showSnack: false,
          onlineCategories: categories,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final fallbackCategories = ReportingSeedData.incidentCategories;
      final fallbackLocationTypes = ReportingSeedData.locationTypes;

      setState(() {
        _categories = fallbackCategories;
        _locationTypes = fallbackLocationTypes;
        _selectedCategory = _categoryForCode(
          fallbackCategories,
          previousCategoryCode,
        );
        _selectedLocationType = _locationTypeForCode(
          fallbackLocationTypes,
          "STREET",
        );
        _isLiveConnectionAvailable = backendAvailable;
        _usingOfflineTaxonomies = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickOccurredDateTime() async {
    final now = DateTime.now();
    final initial = _selectedDateTime ?? now.subtract(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDate: initial,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _openReportForm() async {
    _setSection(_AppSection.report);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectBottomDestination(int index) {
    final section = switch (index) {
      0 => _AppSection.home,
      1 => _AppSection.hotspot,
      2 => _AppSection.report,
      3 => _AppSection.offline,
      _ => _AppSection.sos,
    };

    _setSection(section);
  }

  void _openSection(_AppSection section) {
    _setSection(section);
  }

  void _setSection(_AppSection section, {bool rememberHistory = true}) {
    if (section == _currentSection) {
      return;
    }

    setState(() {
      if (rememberHistory) {
        _sectionHistory.remove(section);
        _sectionHistory.add(_currentSection);
      }

      _currentSection = section;

      switch (section) {
        case _AppSection.home:
          _selectedBottomIndex = 0;
        case _AppSection.hotspot:
          _selectedBottomIndex = 1;
        case _AppSection.report:
          _selectedBottomIndex = 2;
        case _AppSection.offline:
          _selectedBottomIndex = 3;
        case _AppSection.sos:
          _selectedBottomIndex = 4;
        case _AppSection.guide:
        case _AppSection.syncCenter:
        case _AppSection.settings:
        case _AppSection.themes:
          _selectedBottomIndex = null;
          break;
      }
    });
  }

  void _goBackToPreviousSection() {
    while (_sectionHistory.isNotEmpty) {
      final previousSection = _sectionHistory.removeLast();
      if (previousSection != _currentSection) {
        _setSection(previousSection, rememberHistory: false);
        return;
      }
    }

    if (_currentSection != _AppSection.home) {
      _setSection(_AppSection.home, rememberHistory: false);
    }
  }

  Future<Position> _captureCurrentPosition() async {
    final strings = _strings;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw _LocationCaptureException(strings.text('locationServiceOff'));
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw _LocationCaptureException(strings.text('locationPermissionDenied'));
    }

    if (permission == LocationPermission.deniedForever) {
      throw _LocationCaptureException(
        strings.text('locationPermissionForever'),
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _useCurrentLocation() async {
    final strings = _strings;

    if (_isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _captureCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedLatitude = position.latitude;
        _capturedLongitude = position.longitude;
        _isGettingLocation = false;
      });
      _showSuccessSnack(strings.text('locationCaptured'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGettingLocation = false;
      });

      if (error is _LocationCaptureException) {
        _showErrorSnack(error.message);
        return;
      }

      _showErrorSnack(strings.text('locationCaptureFailed'));
    }
  }

  String _buildSosMessage(Position? position) {
    final strings = _strings;
    if (position == null) {
      return strings.text('sosMessageNoLocation');
    }

    return strings.text('sosMessageWithLocation', {
      'lat': position.latitude.toStringAsFixed(5),
      'lng': position.longitude.toStringAsFixed(5),
    });
  }

  Future<void> _activateSosSupport() async {
    final strings = _strings;
    if (_isPreparingSos) {
      return;
    }

    setState(() {
      _isPreparingSos = true;
    });

    Position? position;

    try {
      position = await _captureCurrentPosition();
      if (!mounted) {
        return;
      }

      setState(() {
        _capturedLatitude = position!.latitude;
        _capturedLongitude = position.longitude;
      });
    } catch (_) {
      position = null;
    }

    try {
       if (position == null) {
         throw Exception("Location is required to send an emergency SOS.");
  }

      final result = await EmergencyApiService().sendEmergencySOS(
        latitude: position.latitude,
        longitude: position.longitude,
  );

       setState(() {
        _emergencyReference = result.referenceNumber;
        _emergencyStatus = result.status;
       _isPreparingSos = false;
  });

     if (!mounted) {
       return;
    }

      _showSuccessSnack("Emergency SOS sent successfully.");
    } catch (_) {
  if (!mounted) {
    return;
  }

  setState(() {
    _isPreparingSos = false;
  });

  _showErrorSnack(strings.text('sosActivationFailed'));
}
  }

  Future<void> _showSosReadySheet({
    required String message,
    required bool hasLocation,
  }) {
    final strings = _strings;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final visuals = sheetContext.appVisuals;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: visuals.cardSurface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: visuals.cardShadow,
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.sos_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.text('sosReadyTitle'),
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(
                                color: visuals.deep,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.text('sosReadyBody'),
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(color: visuals.muted, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        (hasLocation
                                ? const Color(0xFF1FA971)
                                : const Color(0xFFE59F2F))
                            .withValues(alpha: 0.16),
                        visuals.softSurface,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hasLocation
                          ? strings.text('sosLocationAttached')
                          : strings.text('sosLocationMissing'),
                      style: Theme.of(sheetContext).textTheme.labelLarge
                          ?.copyWith(
                            color: visuals.deep,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: visuals.softSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SelectableText(
                      message,
                      style: Theme.of(sheetContext).textTheme.bodyMedium
                          ?.copyWith(color: visuals.deep, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openReportForm();
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(strings.text('openReportForm')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openSection(_AppSection.guide);
                    },
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(strings.text('drawerGuide')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final strings = _strings;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      _showErrorSnack(strings.text('incidentTimeRequired'));
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnack(strings.text('taxonomyWait'));
      return;
    }

    if (_capturedLatitude == null || _capturedLongitude == null) {
      _showErrorSnack(strings.text('locationRequired'));
      return;
    }

    if (!_consentAcknowledged) {
  _showErrorSnack(
    "Please confirm to ensure your privacy. This report must be submitted anonymously.",
  );
  return;
}

    setState(() {
      _isSubmitting = true;
      _lastSubmission = null;
    });

    try {
      if (_usingOfflineTaxonomies) {
        final result = await _queueCurrentReportOffline();

        if (!mounted) {
          return;
        }

        setState(() {
          _lastSubmission = result;
          _isSubmitting = false;
        });
        _showSuccessSnack(result.message);
        _resetForm();
        return;
      }

      final result = await _api.submitReport(
        categoryId: _selectedCategory!.id,
        occurredAt: _selectedDateTime!,
        latitude: _capturedLatitude!,
        longitude: _capturedLongitude!,
        approxAreaName: _areaController.text,
        wardOrDistrict: "",
        description: _descriptionController.text,
        consentAcknowledged: _consentAcknowledged,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastSubmission = result;
        _isSubmitting = false;
      });
      _showSuccessSnack(result.message);
      _resetForm();
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (ReportingApiService.isConnectivityError(error)) {
        final result = await _queueCurrentReportOffline();
        if (!mounted) {
          return;
        }

        setState(() {
          _lastSubmission = result;
          _isSubmitting = false;
          _isLiveConnectionAvailable = false;
          _usingOfflineTaxonomies = true;
        });
        _showSuccessSnack(result.message);
        _resetForm();
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      _showErrorSnack(error.toString());
    }
  }

  Future<ReportSubmissionResult> _queueCurrentReportOffline() async {
    final queuedReport = PendingIncidentReport(
      localId: "offline-${DateTime.now().microsecondsSinceEpoch}",
      categoryCode: _selectedCategory!.code,
      locationTypeCode: _selectedLocationType?.code ?? "STREET",
      occurredAt: _selectedDateTime!,
      latitude: _capturedLatitude!,
      longitude: _capturedLongitude!,
      approxAreaName: _areaController.text.trim(),
      wardOrDistrict: "",
      description: _descriptionController.text.trim(),
      languageCode: _settingsController.language.locale.languageCode,
      consentAcknowledged: _consentAcknowledged,
      queuedAt: DateTime.now(),
    );

    await _offlineStore.enqueueReport(queuedReport);
    final queuedReports = await _offlineStore.loadPendingReports();
    if (mounted) {
      setState(() {
        _pendingReports = queuedReports;
        _pendingReportCount = queuedReports.length;
      });
    }

    return ReportSubmissionResult.offlineQueued(
      localId: queuedReport.localId,
      pendingCount: queuedReports.length,
    );
  }

  Future<void> _syncPendingReports({
    bool showSnack = true,
    List<IncidentCategory>? onlineCategories,
  }) async {
    if (_isSyncingPendingReports) {
      return;
    }

    final pendingReports = await _offlineStore.loadPendingReports();
    if (pendingReports.isEmpty) {
      if (mounted) {
        setState(() {
          _pendingReports = const [];
          _pendingReportCount = 0;
        });
      }
      if (showSnack) {
        _showErrorSnack(_strings.text('noSavedOfflineReports'));
      }
      return;
    }

    setState(() {
      _isSyncingPendingReports = true;
    });

    try {
      final categories =
          onlineCategories ?? await _api.fetchIncidentCategories();

      final categoriesByCode = {
        for (final category in categories) category.code: category,
      };

      final remainingReports = <PendingIncidentReport>[];
      var syncedCount = 0;

      for (var index = 0; index < pendingReports.length; index++) {
        final pendingReport = pendingReports[index];
        final category = categoriesByCode[pendingReport.categoryCode];

        if (category == null) {
          remainingReports.add(pendingReport);
          continue;
        }

        try {
          await _api.submitReport(
            categoryId: category.id,
            occurredAt: pendingReport.occurredAt,
            latitude: pendingReport.latitude,
            longitude: pendingReport.longitude,
            approxAreaName: pendingReport.approxAreaName,
            wardOrDistrict: pendingReport.wardOrDistrict,
            description: pendingReport.description,
            consentAcknowledged: pendingReport.consentAcknowledged,
            languageCode: pendingReport.languageCode,
          );
          syncedCount++;
        } catch (error) {
          if (ReportingApiService.isConnectivityError(error)) {
            remainingReports.add(pendingReport);
            if (index + 1 < pendingReports.length) {
              remainingReports.addAll(pendingReports.sublist(index + 1));
            }
            break;
          }

          remainingReports.add(pendingReport);
        }
      }

      await _offlineStore.savePendingReports(remainingReports);

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingReports = remainingReports;
        _pendingReportCount = remainingReports.length;
        _isSyncingPendingReports = false;
        _isLiveConnectionAvailable = true;
        _usingOfflineTaxonomies = false;
      });

      if (!showSnack) {
        return;
      }

      if (syncedCount > 0 && remainingReports.isEmpty) {
        _showSuccessSnack(_strings.text('syncComplete'));
      } else if (syncedCount > 0) {
        _showErrorSnack(
          _strings.text('syncPartial', {
            'synced': syncedCount.toString(),
            'remaining': remainingReports.length.toString(),
          }),
        );
      } else {
        _showErrorSnack(_strings.text('syncWaiting'));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingPendingReports = false;
        _isLiveConnectionAvailable = false;
      });

      if (showSnack) {
        _showErrorSnack(_strings.text('syncOfflineLater'));
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _areaController.clear();
    _descriptionController.clear();
    setState(() {
      _capturedLatitude = null;
      _capturedLongitude = null;
      _consentAcknowledged = false;
      _selectedDateTime = null;
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _selectedLocationType = _locationTypeForCode(_locationTypes, "STREET");
    });
  }

void _showErrorSnack(String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void _showSuccessSnack(String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
  Future<void> _handleBackendUrlSaved(String value) async {
    try {
      await _settingsController.setBackendUrl(value);
      if (!mounted) {
        return;
      }

      _showSuccessSnack(_strings.text('backendUrlSaved'));
      await _loadTaxonomies();
    } on FormatException {
      if (!mounted) {
        return;
      }

      _showErrorSnack(_strings.text('backendUrlInvalid'));
    }
  }

  Future<void> _handleHomeRefresh() async {
    await _loadTaxonomies();
    if (_autoSyncEnabled &&
        _pendingReportCount > 0 &&
        _isLiveConnectionAvailable) {
      await _syncPendingReports(showSnack: false);
    }
  }

  Widget _buildCurrentSection() {
    switch (_currentSection) {
      case _AppSection.home:
        return _buildHomeSection();
      case _AppSection.hotspot:
        return _buildHotspotSection();
      case _AppSection.report:
        return _buildReportSection();
      case _AppSection.offline:
        return _buildOfflineSection();
      case _AppSection.sos:
        return _buildSosSection();
      case _AppSection.guide:
        return _buildGuideSection();
      case _AppSection.syncCenter:
        return _buildSyncCenterSection();
      case _AppSection.settings:
        return _buildSettingsSection();
      case _AppSection.themes:
        return _buildThemesSection();
    }
  }

  Widget _buildHomeSection() {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 20.0;
    final heroAspectRatio = screenWidth < 380 ? 0.72 : 0.74;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTopBar(
            title: strings.text('homeTitle'),
            subtitle: strings.text('homeSubtitle'),
            onMenuPressed: _openDrawer,
            action: _StatusPill(
              label: _isLiveConnectionAvailable
                  ? strings.text('online')
                  : strings.text('offline'),
              color: _isLiveConnectionAvailable
                  ? visuals.blush
                  : visuals.primary,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AspectRatio(
                  aspectRatio: heroAspectRatio,
                  child: _HeroCard(onOpenForm: _openReportForm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotSection() {
    final visuals = context.appVisuals;

    return FutureBuilder<Map<String, dynamic>>(
      future: _cachedHotspots != null
    ? Future.value(_cachedHotspots)
    : _getHotspotsData(),
      builder: (context, snapshot) {
        final topAreas = snapshot.data?['top_areas'] as List<dynamic>? ?? [];
        final total = snapshot.data?['total'] ?? 0;

        return RefreshIndicator(
         onRefresh: () async {
          await _getHotspotsData();
          setState(() {});
         },
          color: visuals.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _SectionTopBar(
                title: 'Incident Hotspots',
                subtitle: 'Areas with the most reported incidents',
                onBackPressed: _goBackToPreviousSection,
                onMenuPressed: _openDrawer,
              ),
              const SizedBox(height: 18),
              if (total > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: visuals.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: visuals.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Approved Reports: $total',
                        style: TextStyle(
                          color: visuals.deep,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (topAreas.isNotEmpty) ...[
                        Text(
                          'Top Areas',
                          style: TextStyle(
                            color: visuals.deep,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...topAreas.map((area) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: visuals.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    area['label'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: visuals.deep.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${area['count']} reports',
                                  style: TextStyle(
                                    color: visuals.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
               height: 280,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: visuals.border),
                  ),
  child: Builder(
    builder: (context) {
      final reports =
          snapshot.data?['reports'] as List<dynamic>? ?? const [];
final markers = reports.map((report) {
  final lat = double.tryParse('${report['latitude']}');
  final lng = double.tryParse('${report['longitude']}');

  if (lat == null || lng == null) {
    return null;
  }

  return Marker(
    point: latlng.LatLng(lat, lng),
    width: 40,
    height: 40,
    child: Tooltip(
      message: '${report['area']}\n${report['category']}',
      child: const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 36,
      ),
    ),
  );
}).whereType<Marker>().toList();
      final center =
          reports.isNotEmpty
              ? latlng.LatLng(
                  (reports.first['latitude'] as num).toDouble(),
                  (reports.first['longitude'] as num).toDouble(),
                )
              : latlng.LatLng(-6.7924, 39.2083);

      return FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          initialCenter: center,
         initialZoom: 13.5,
          minZoom: 10,
          maxZoom: 18,
        ),
        children: [
       TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.womensafety.app',
  maxZoom: 19,
),
          MarkerLayer(
            markers: markers,
          ),
        ],
      );
    },
  ),
),

const SizedBox(height: 16),

if (topAreas.isNotEmpty)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: visuals.cardSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: visuals.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Risk Areas',
          style: TextStyle(
            color: visuals.deep,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        ...topAreas.map((area) {
          final count = area['count'] ?? 0;

          Color riskColor;
          String riskLabel;

          if (count >= 10) {
            riskColor = Colors.red;
            riskLabel = 'High Risk';
          } else if (count >= 5) {
            riskColor = Colors.orange;
            riskLabel = 'Medium Risk';
          } else {
            riskColor = Colors.green;
            riskLabel = 'Low Risk';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: riskColor.withOpacity(0.08),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: riskColor,
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area['label'] ?? 'Unknown Area',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: visuals.deep,
                        ),
                      ),
                      Text(
                        '$riskLabel • $count reports',
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  ),

              if (total == 0)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: visuals.softSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'No approved incidents yet. Check back later.',
                      style: TextStyle(color: visuals.muted, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportSection() {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return RefreshIndicator(
      onRefresh: _loadTaxonomies,
      color: visuals.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('reportSectionTitle'),
            subtitle: strings.text('reportSectionSubtitle'),
            onBackPressed: _goBackToPreviousSection,
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          if (!_isLiveConnectionAvailable ||
              _pendingReportCount > 0 ||
              _isSyncingPendingReports) ...[
            _OfflineStatusCard(
              isOfflineMode: !_isLiveConnectionAvailable,
              pendingReportCount: _pendingReportCount,
              isSyncing: _isSyncingPendingReports,
              onRetryConnection: _loadTaxonomies,
              onSyncPendingReports: _syncPendingReports,
            ),
            const SizedBox(height: 18),
          ],
          if (_lastSubmission != null) ...[
            _SubmissionResultCard(result: _lastSubmission!),
            const SizedBox(height: 18),
          ],
          if (_isLoading)
            const _LoadingCard()
          else
            _ReportFormCard(
              formKey: _formKey,
              categories: _categories,
              selectedCategory: _selectedCategory,
              selectedDateTime: _selectedDateTime,
              consentAcknowledged: _consentAcknowledged,
              hasCapturedLocation:
                  _capturedLatitude != null && _capturedLongitude != null,
              isGettingLocation: _isGettingLocation,
              areaController: _areaController,
              descriptionController: _descriptionController,
              isSubmitting: _isSubmitting,
              onCategoryChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              onConsentChanged: (value) {
                setState(() => _consentAcknowledged = value ?? false);
              },
              onUseCurrentLocation: _useCurrentLocation,
              onPickDateTime: _pickOccurredDateTime,
              onSubmit: _submit,
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineSection() {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return RefreshIndicator(
      onRefresh: _refreshPendingReportCount,
      color: visuals.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('offlineSectionTitle'),
            subtitle: strings.text('offlineSectionSubtitle'),
            onBackPressed: _goBackToPreviousSection,
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          _OfflineStatusCard(
            isOfflineMode: !_isLiveConnectionAvailable,
            pendingReportCount: _pendingReportCount,
            isSyncing: _isSyncingPendingReports,
            onRetryConnection: _loadTaxonomies,
            onSyncPendingReports: _syncPendingReports,
          ),
          const SizedBox(height: 18),
          _PendingQueueCard(
            pendingReports: _pendingReports,
            onOpenReportForm: _openReportForm,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionTopBar(
          title: strings.text('guideTitle'),
          subtitle: strings.text('guideSubtitle'),
          onBackPressed: _goBackToPreviousSection,
          onMenuPressed: _openDrawer,
        ),
        const SizedBox(height: 18),
        const _QuickStepsCard(),
        const SizedBox(height: 18),
        if (_privacyTipsEnabled)
          _InfoCard(
            title: strings.text('privacyReminder'),
            body: strings.text('privacyReminderBody'),
          ),
        const SizedBox(height: 18),
        if (_locationHintsEnabled)
          _InfoCard(
            title: strings.text('locationGuidance'),
            body: strings.text('locationGuidanceBody'),
          ),
      ],
    );
  }

  Widget _buildSosSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionTopBar(
          title: strings.text('sos'),
          subtitle: strings.text('sosSubtitle'),
          onBackPressed: _goBackToPreviousSection,
          onMenuPressed: _openDrawer,
        ),
        const SizedBox(height: 18),
        _SosActionCard(
          isPreparing: _isPreparingSos,
          onActivate: _activateSosSupport,
          emergencyStatus: _emergencyStatus,
        ),
      ],
    );
  }

  Widget _buildSyncCenterSection() {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return RefreshIndicator(
      onRefresh: _handleHomeRefresh,
      color: visuals.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('syncCenterTitle'),
            subtitle: strings.text('syncCenterSubtitle'),
            onBackPressed: _goBackToPreviousSection,
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          _SyncStatusCard(
            isOfflineMode: !_isLiveConnectionAvailable,
            pendingReportCount: _pendingReportCount,
            isSyncing: _isSyncingPendingReports,
            autoSyncEnabled: _autoSyncEnabled,
            onRetryConnection: _loadTaxonomies,
            onSyncPendingReports: _syncPendingReports,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionTopBar(
          title: strings.text('settingsTitle'),
          subtitle: strings.text('settingsSubtitle'),
          onBackPressed: _goBackToPreviousSection,
          onMenuPressed: _openDrawer,
        ),
        const SizedBox(height: 18),
        _SettingsCard(
          language: _settingsController.language,
          autoSyncEnabled: _autoSyncEnabled,
          locationHintsEnabled: _locationHintsEnabled,
          privacyTipsEnabled: _privacyTipsEnabled,
          backendUrl: _settingsController.backendUrl,
          onLanguageChanged: _settingsController.setLanguage,
          onAutoSyncChanged: _settingsController.setAutoSyncEnabled,
          onLocationHintsChanged: _settingsController.setLocationHintsEnabled,
          onPrivacyTipsChanged: _settingsController.setPrivacyTipsEnabled,
          onBackendUrlSaved: _handleBackendUrlSaved,
        ),
      ],
    );
  }

  Widget _buildThemesSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _SectionTopBar(
          title: strings.text('themeTitle'),
          subtitle: strings.text('themeSubtitle'),
          onBackPressed: _goBackToPreviousSection,
          onMenuPressed: _openDrawer,
        ),
        const SizedBox(height: 18),
        _ThemeGalleryCard(
          currentPreset: _settingsController.themePreset,
          onThemePresetChanged: _settingsController.setThemePreset,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return PopScope(
      canPop: _currentSection == _AppSection.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return;
        }

        _goBackToPreviousSection();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: visuals.pageBackground,
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _SafetyDrawer(
            currentUser: widget.currentUser,
            currentSection: _currentSection,
            pendingReportCount: _pendingReportCount,
            isLiveConnectionAvailable: _isLiveConnectionAvailable,
            onLogout: widget.onLogout,
            onSelectSection: (section) {
              Navigator.of(context).pop();
              _openSection(section);
            },
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: _PageBackdrop()),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildCurrentSection(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomQuickNavigation(
          selectedIndex: _selectedBottomIndex,
          pendingReportCount: _pendingReportCount,
          onSelected: _selectBottomDestination,
        ),
      ),
    );
  }
}

class _SectionTopBar extends StatelessWidget {
  const _SectionTopBar({
    required this.title,
    required this.subtitle,
    this.onBackPressed,
    this.onMenuPressed,
    this.action,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;
    final trailingAction =
        action ??
        (onBackPressed != null && onMenuPressed != null
            ? _TopBarIconButton(
                icon: Icons.menu_rounded,
                onPressed: onMenuPressed!,
              )
            : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBackPressed != null || onMenuPressed != null)
          _TopBarIconButton(
            icon: onBackPressed != null
                ? Icons.arrow_back_rounded
                : Icons.menu_rounded,
            onPressed: onBackPressed ?? onMenuPressed!,
          ),
        if (onBackPressed != null || onMenuPressed != null)
          const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: visuals.deep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: visuals.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (trailingAction != null) ...[
          const SizedBox(width: 12),
          trailingAction,
        ],
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: visuals.cardSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: visuals.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: visuals.deep,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: visuals.cardSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: visuals.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: visuals.deep, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/*class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({
    required this.pendingReportCount,
    required this.usingOfflineTaxonomies,
    required this.onOpenReportForm,
    required this.onOpenOfflineQueue,
  });

  final int pendingReportCount;
  final bool usingOfflineTaxonomies;
  final Future<void> Function() onOpenReportForm;
  final VoidCallback onOpenOfflineQueue;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final queueText = pendingReportCount == 0
        ? strings.text('noSavedOfflineReports')
        : strings.text('savedOfflineQueue', {
            'count': pendingReportCount.toString(),
          });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('homeOverviewTitle'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              usingOfflineTaxonomies
                  ? strings.text('homeOverviewOffline')
                  : strings.text('homeOverviewOnline'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedText, height: 1.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _softPink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primaryIndigo,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.file_upload_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      queueText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _deepIndigo,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onOpenReportForm,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(strings.text('openReportForm')),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenOfflineQueue,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(strings.text('savedOffline')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickActionsCard extends StatelessWidget {
  const _HomeQuickActionsCard({
    required this.pendingReportCount,
    required this.onOpenReportForm,
    required this.onOpenOfflineQueue,
    required this.onOpenGuide,
    required this.onOpenSyncCenter,
  });

  final int pendingReportCount;
  final Future<void> Function() onOpenReportForm;
  final VoidCallback onOpenOfflineQueue;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenSyncCenter;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('quickAccess'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAccessTile(
                  label: strings.text('report'),
                  icon: Icons.note_add_rounded,
                  onTap: () => onOpenReportForm(),
                ),
                _QuickAccessTile(
                  label: strings.text('offline'),
                  icon: Icons.offline_bolt_rounded,
                  badge: pendingReportCount > 0 ? "$pendingReportCount" : null,
                  onTap: onOpenOfflineQueue,
                ),
                _QuickAccessTile(
                  label: strings.text('guide'),
                  icon: Icons.shield_outlined,
                  onTap: onOpenGuide,
                ),
                _QuickAccessTile(
                  label: strings.text('sync'),
                  icon: Icons.sync_rounded,
                  onTap: onOpenSyncCenter,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _primaryIndigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _deepIndigo,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryIndigo,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

class _PendingQueueCard extends StatelessWidget {
  const _PendingQueueCard({
    required this.pendingReports,
    required this.onOpenReportForm,
  });

  final List<PendingIncidentReport> pendingReports;
  final Future<void> Function() onOpenReportForm;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final queueSurface = _blendColors(
      visuals.cardSurface,
      visuals.primary,
      0.10,
    );

    if (pendingReports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: queueSurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.cloud_done_rounded,
                  color: visuals.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.text('queueEmptyTitle'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                strings.text('queueEmptyBody'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: visuals.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onOpenReportForm,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(strings.text('createReport')),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('pendingQueue'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...pendingReports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: queueSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: visuals.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.schedule_send_rounded,
                          color: visuals.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.approxAreaName.isEmpty
                                  ? strings.text('offlineReport')
                                  : report.approxAreaName,
                              style: TextStyle(
                                color: visuals.deep,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${strings.categoryName(report.categoryCode, report.categoryCode)} â€¢ ${strings.locationTypeName(report.locationTypeCode, report.locationTypeCode)}",
                              style: TextStyle(
                                color: visuals.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.text('queuedAt', {
                                'time': _formatDateTime(report.queuedAt),
                              }),
                              style: TextStyle(color: visuals.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.isOfflineMode,
    required this.pendingReportCount,
    required this.isSyncing,
    required this.autoSyncEnabled,
    required this.onRetryConnection,
    required this.onSyncPendingReports,
  });

  final bool isOfflineMode;
  final int pendingReportCount;
  final bool isSyncing;
  final bool autoSyncEnabled;
  final Future<void> Function() onRetryConnection;
  final Future<void> Function() onSyncPendingReports;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('connectionSnapshot'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _StatusRow(
              label: strings.text('currentMode'),
              value: isOfflineMode
                  ? strings.text('offlineCapture')
                  : strings.text('connected'),
            ),
            _StatusRow(
              label: strings.text('pendingReports'),
              value: pendingReportCount.toString(),
            ),
            _StatusRow(
              label: strings.text('autoSync'),
              value: autoSyncEnabled
                  ? strings.text('enabled')
                  : strings.text('manualOnly'),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: isSyncing ? null : onSyncPendingReports,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(
                    isSyncing
                        ? strings.text('syncing')
                        : strings.text('syncNow'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onRetryConnection,
                  icon: const Icon(Icons.wifi_tethering_rounded),
                  label: Text(strings.text('retryConnection')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: visuals.muted),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: visuals.deep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  const _SettingsCard({
    required this.language,
    required this.autoSyncEnabled,
    required this.locationHintsEnabled,
    required this.privacyTipsEnabled,
    required this.backendUrl,
    required this.onLanguageChanged,
    required this.onAutoSyncChanged,
    required this.onLocationHintsChanged,
    required this.onPrivacyTipsChanged,
    required this.onBackendUrlSaved,
  });

  final AppLanguage language;
  final bool autoSyncEnabled;
  final bool locationHintsEnabled;
  final bool privacyTipsEnabled;
  final String backendUrl;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onAutoSyncChanged;
  final ValueChanged<bool> onLocationHintsChanged;
  final ValueChanged<bool> onPrivacyTipsChanged;
  final Future<void> Function(String) onBackendUrlSaved;

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  late final TextEditingController _backendUrlController;
  bool _isSavingBackendUrl = false;

  @override
  void initState() {
    super.initState();
    _backendUrlController = TextEditingController(text: widget.backendUrl);
  }

  @override
  void didUpdateWidget(covariant _SettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backendUrl != widget.backendUrl &&
        _backendUrlController.text != widget.backendUrl) {
      _backendUrlController.text = widget.backendUrl;
    }
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBackendUrl() async {
    if (_isSavingBackendUrl) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingBackendUrl = true;
    });

    try {
      await widget.onBackendUrlSaved(_backendUrlController.text);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingBackendUrl = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('languageSetting'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppLanguage>(
              segments: AppLanguage.values
                  .map(
                    (value) => ButtonSegment<AppLanguage>(
                      value: value,
                      label: Text(strings.languageName(value)),
                    ),
                  )
                  .toList(growable: false),
              selected: {widget.language},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  widget.onLanguageChanged(selection.first);
                }
              },
            ),
            const SizedBox(height: 22),
            SwitchListTile(
              value: widget.autoSyncEnabled,
              onChanged: widget.onAutoSyncChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('autoSyncTitle')),
              subtitle: Text(strings.text('autoSyncSubtitle')),
            ),
            SwitchListTile(
              value: widget.locationHintsEnabled,
              onChanged: widget.onLocationHintsChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('locationHintsTitle')),
              subtitle: Text(strings.text('locationHintsSubtitle')),
            ),
            SwitchListTile(
              value: widget.privacyTipsEnabled,
              onChanged: widget.onPrivacyTipsChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('privacyTipsTitle')),
              subtitle: Text(strings.text('privacyTipsSubtitle')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeGalleryCard extends StatelessWidget {
  const _ThemeGalleryCard({
    required this.currentPreset,
    required this.onThemePresetChanged,
  });

  final AppThemePreset currentPreset;
  final ValueChanged<AppThemePreset> onThemePresetChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: AppThemePreset.values
              .map((preset) {
                final brightness = Theme.of(context).brightness;
                final visuals = AppPalette.visualsFor(preset, brightness);
                final selected = preset == currentPreset;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => onThemePresetChanged(preset),
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? visuals.primary.withValues(alpha: 0.08)
                            : visuals.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? visuals.primary
                              : visuals.primary.withValues(alpha: 0.16),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  visuals.bright,
                                  visuals.primary,
                                  visuals.deep,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ThemeColorDot(color: visuals.accent),
                                const SizedBox(width: 6),
                                _ThemeColorDot(color: visuals.blush),
                                const SizedBox(width: 6),
                                _ThemeColorDot(color: visuals.accentGold),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.themePresetName(preset),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  strings.themePresetDescription(preset),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: visuals.muted,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected ? visuals.primary : visuals.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ThemeColorDot extends StatelessWidget {
  const _ThemeColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SosActionCard extends StatelessWidget {
  const _SosActionCard({
  required this.isPreparing,
  required this.onActivate,
  required this.emergencyStatus,
});

  final bool isPreparing;
  final Future<void> Function() onActivate;
  final String emergencyStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD32F2F),
            Color(0xFFE53935),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44D32F2F),
            blurRadius: 25,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.sos,
              color: Colors.white,
              size: 70,
            ),

            const SizedBox(height: 18),

            const Text(
              "Emergency SOS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "If you are in immediate danger, press the button below. "
              "Your live location will be sent immediately to the Police Control Room.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isPreparing ? null : onActivate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                icon: isPreparing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD32F2F),
                        ),
                      )
                    : const Icon(Icons.warning_rounded),
                label: const Text(
                  "SEND EMERGENCY SOS",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
const SizedBox(height: 30),

const Divider(
  color: Colors.white38,
),

const SizedBox(height: 20),

Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "Police Response",
    style: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 18),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(18),
  ),
  child: Column(
    children: [
      Row(
        children: [
          const Icon(
            Icons.hourglass_top,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                emergencyStatus,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      const Row(
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.white54,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Officer Assignment",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      const Row(
        children: [
          Icon(
            Icons.local_police_outlined,
            color: Colors.white54,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Police On The Way",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 12),

      const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white54,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Emergency Resolved",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),


          ],
        ),
      ),
    );
  }
}

class _SafetyDrawer extends StatelessWidget {
  const _SafetyDrawer({
    required this.currentUser,
    required this.currentSection,
    required this.pendingReportCount,
    required this.isLiveConnectionAvailable,
    required this.onLogout,
    required this.onSelectSection,
  });

  final AuthenticatedUser currentUser;
  final _AppSection currentSection;
  final int pendingReportCount;
  final bool isLiveConnectionAvailable;
  final Future<void> Function() onLogout;
  final ValueChanged<_AppSection> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 90, 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: visuals.cardSurface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: visuals.cardShadow,
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ListView(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: visuals.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 12),
                /* const Expanded(
                  child: Text(
                    "Move Safety",
                    style: TextStyle(
                      color: _deepIndigo,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),*/
                _StatusPill(
                  label: isLiveConnectionAvailable
                      ? strings.text('online')
                      : strings.text('offline'),
                  color: isLiveConnectionAvailable
                      ? AppPalette.blush
                      : visuals.primary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              currentUser.fullName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: visuals.deep,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser.email,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: visuals.muted),
            ),
            const SizedBox(height: 24),
            _DrawerNavTile(
              icon: Icons.home_outlined,
              label: strings.text('drawerHome'),
              selected: currentSection == _AppSection.home,
              onTap: () => onSelectSection(_AppSection.home),
            ),
            _DrawerNavTile(
              icon: Icons.edit_note_rounded,
              label: strings.text('drawerReport'),
              selected: currentSection == _AppSection.report,
              onTap: () => onSelectSection(_AppSection.report),
            ),
            _DrawerNavTile(
              icon: Icons.cloud_upload_outlined,
              label: strings.text('drawerOffline'),
              selected: currentSection == _AppSection.offline,
              badge: pendingReportCount > 0 ? "$pendingReportCount" : null,
              onTap: () => onSelectSection(_AppSection.offline),
            ),
            _DrawerNavTile(
              icon: Icons.shield_outlined,
              label: strings.text('drawerGuide'),
              selected: currentSection == _AppSection.guide,
              onTap: () => onSelectSection(_AppSection.guide),
            ),
            _DrawerNavTile(
              icon: Icons.sync_rounded,
              label: strings.text('drawerSyncCenter'),
              selected: currentSection == _AppSection.syncCenter,
              onTap: () => onSelectSection(_AppSection.syncCenter),
            ),
            _DrawerNavTile(
              icon: Icons.palette_outlined,
              label: strings.text('drawerThemes'),
              selected: currentSection == _AppSection.themes,
              onTap: () => onSelectSection(_AppSection.themes),
            ),
            _DrawerNavTile(
              icon: Icons.settings_outlined,
              label: strings.text('drawerSettings'),
              selected: currentSection == _AppSection.settings,
              onTap: () => onSelectSection(_AppSection.settings),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _DrawerNavTile(
              icon: Icons.logout_rounded,
              label: strings.text('drawerLogout'),
              selected: false,
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;
    final theme = Theme.of(context);
    final selectedBackground = danger
        ? _blendColors(visuals.cardSurface, theme.colorScheme.error, 0.14)
        : _blendColors(
            visuals.cardSurface,
            visuals.primary,
            theme.brightness == Brightness.dark ? 0.24 : 0.14,
          );
    final foregroundColor = selected
        ? _bestContrastingColor(
            selectedBackground,
            light: Colors.white,
            dark: visuals.deep,
          )
        : danger
        ? theme.colorScheme.error
        : visuals.deep.withValues(alpha: 0.9);
    final borderColor = selected
        ? (danger ? theme.colorScheme.error : visuals.primary).withValues(
            alpha: 0.28,
          )
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, color: foregroundColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: visuals.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomQuickNavigation extends StatelessWidget {
  const _BottomQuickNavigation({
    required this.selectedIndex,
    required this.pendingReportCount,
    required this.onSelected,
  });

  final int? selectedIndex;
  final int pendingReportCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final items = [
      _BottomNavEntry(
        icon: Icons.home_outlined,
        label: strings.text('drawerHome'),
      ),
      _BottomNavEntry(icon: Icons.map_outlined, label: 'Hotspots'),
      _BottomNavEntry(
        icon: Icons.edit_note_rounded,
        label: strings.text('report'),
      ),
      _BottomNavEntry(
        icon: Icons.cloud_upload_outlined,
        label: strings.text('savedOffline'),
        showsBadge: true,
      ),
      _BottomNavEntry(label: strings.text('sos')),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.navBackground,
        boxShadow: [
          BoxShadow(
            color: visuals.cardShadow,
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              final badge = item.showsBadge && pendingReportCount > 0
                  ? pendingReportCount.toString()
                  : null;
              final selectedFill = _blendColors(
                visuals.navBackground,
                visuals.primary,
                0.30,
              );
              final selectedBorder = visuals.primary.withValues(alpha: 0.46);
              final inactiveForeground = _bestContrastingColor(
                visuals.navBackground,
                light: Colors.white,
                dark: visuals.deep,
              ).withValues(alpha: 0.78);
              final foregroundColor = selected
                  ? _bestContrastingColor(
                      selectedFill,
                      light: Colors.white,
                      dark: visuals.deep,
                    )
                  : inactiveForeground;
              final backgroundColor = selected
                  ? selectedFill
                  : Colors.transparent;
              final borderColor = selected
                  ? selectedBorder
                  : Colors.transparent;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: item.label,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: 48,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (item.icon != null)
                                  Icon(
                                    item.icon,
                                    size: 24,
                                    color: foregroundColor,
                                  )
                                else
                                  Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: foregroundColor,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                if (badge != null)
                                  Positioned(
                                    right: -10,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: visuals.bright,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: visuals.navBackground,
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Text(
                                        badge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavEntry {
  const _BottomNavEntry({
    this.icon,
    required this.label,
    this.showsBadge = false,
  });

  final IconData? icon;
  final String label;
  final bool showsBadge;
}

class _PageBackdrop extends StatelessWidget {
  const _PageBackdrop();

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _BackdropBlob(
              width: 190,
              height: 190,
              colors: [visuals.blobA, visuals.blobA.withValues(alpha: 0.08)],
            ),
          ),
          Positioned(
            top: 280,
            right: -60,
            child: _BackdropBlob(
              width: 220,
              height: 220,
              colors: [visuals.blobB, visuals.blobB.withValues(alpha: 0.06)],
            ),
          ),
          Positioned(
            bottom: -80,
            left: -20,
            child: _BackdropBlob(
              width: 180,
              height: 180,
              colors: [visuals.blobC, visuals.blobC.withValues(alpha: 0.06)],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpenForm});

  final Future<void> Function() onOpenForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final isDark = theme.brightness == Brightness.dark;
    final heroBase = isDark
        ? _blendColors(visuals.navBackground, visuals.cardSurface, 0.70)
        : _blendColors(visuals.navBackground, visuals.primary, 0.24);
    final heroMid = isDark
        ? _blendColors(visuals.cardSurface, visuals.softSurface, 0.74)
        : _blendColors(visuals.navBackground, visuals.deep, 0.12);
    final heroEnd = isDark
        ? _blendColors(visuals.cardSurface, visuals.primary, 0.10)
        : _blendColors(visuals.navBackground, visuals.accent, 0.24);
    final heroButtonColor = isDark
        ? _blendColors(visuals.cardSurface, visuals.accent, 0.18)
        : _blendColors(visuals.navBackground, visuals.accent, 0.30);
    final heroAccent = _bestContrastingColor(
      heroButtonColor,
      light: Colors.white,
      dark: visuals.deep,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: visuals.cardShadow.withValues(alpha: isDark ? 0.40 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [heroBase, heroMid, heroEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
                ),
              ),
            ),
            Positioned(
              top: -14,
              right: -10,
              child: _HeroOrb(
                size: 120,
                color: visuals.accent.withValues(alpha: isDark ? 0.16 : 0.12),
              ),
            ),
            Positioned(
              bottom: -54,
              left: -36,
              child: _HeroOrb(
                size: 170,
                color: visuals.deep.withValues(alpha: isDark ? 0.12 : 0.06),
              ),
            ),
            Positioned(
              top: 44,
              left: 18,
              child: _HeroOrb(
                size: 20,
                color: visuals.accent.withValues(alpha: isDark ? 0.32 : 0.26),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroLinePainter(
                  strokeColor: Colors.white.withValues(
                    alpha: isDark ? 0.10 : 0.08,
                  ),
                  fillColor: Colors.white.withValues(
                    alpha: isDark ? 0.03 : 0.025,
                  ),
                  glowColor: Colors.white.withValues(
                    alpha: isDark ? 0.025 : 0.02,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.07 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.10 : 0.12,
                            ),
                          ),
                        ),
                        child: Text(
                          strings.text('anonymousReporting'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.shield_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 0.96,
                      ),
                      children: [
                        TextSpan(text: strings.text('heroTitleA')),
                        TextSpan(
                          text: strings.text('heroTitleB'),
                          style: TextStyle(
                            color: _blendColors(
                              Colors.white,
                              visuals.accentGold,
                              isDark ? 0.38 : 0.32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.text('heroBody'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.74 : 0.72,
                      ),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: onOpenForm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: heroAccent,
                          backgroundColor: heroButtonColor,
                          side: BorderSide(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.12 : 0.14,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          strings.text('openReportForm'),
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeroLinePainter extends CustomPainter {
  const _HeroLinePainter({
    required this.strokeColor,
    required this.fillColor,
    required this.glowColor,
  });

  final Color strokeColor;
  final Color fillColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.38,
        size.width * 0.42,
        size.height * 0.02,
        size.width * 0.62,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.28,
        size.width * 0.96,
        size.height * 0.10,
        size.width,
        size.height * 0.20,
      );

    final lowerPath = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.54,
        size.width * 0.40,
        size.height * 0.90,
        size.width * 0.68,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.68,
        size.width * 0.96,
        size.height * 0.92,
        size.width,
        size.height * 0.84,
      );

    canvas.drawPath(topPath, stroke);
    canvas.drawPath(lowerPath, stroke);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.16), 12, fill);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.72), 18, fill);
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.20),
      36,
      Paint()..color = glowColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickStepsCard extends StatelessWidget {
  const _QuickStepsCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('reportFlowTitle'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              strings.text('reportFlowBody'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: visuals.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StepBubble(
                  icon: Icons.shield_outlined,
                  label: strings.text('quickStep1'),
                  color: visuals.primary,
                ),
                _StepBubble(
                  icon: Icons.place_outlined,
                  label: strings.text('quickStep2'),
                  color: visuals.accentGold,
                ),
                _StepBubble(
                  icon: Icons.notes_rounded,
                  label: strings.text('quickStep3'),
                  color: visuals.accent,
                ),
                _StepBubble(
                  icon: Icons.send_rounded,
                  label: strings.text('quickStep4'),
                  color: visuals.bright,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: visuals.deep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _blendColors(visuals.cardSurface, visuals.primary, 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.support_agent_rounded, color: visuals.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: visuals.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            CircularProgressIndicator(color: visuals.primary),
            const SizedBox(height: 16),
            Text(strings.text('loadingTaxonomies')),
          ],
        ),
      ),
    );
  }
}

class _OfflineStatusCard extends StatelessWidget {
  const _OfflineStatusCard({
    required this.isOfflineMode,
    required this.pendingReportCount,
    required this.isSyncing,
    required this.onRetryConnection,
    required this.onSyncPendingReports,
  });

  final bool isOfflineMode;
  final int pendingReportCount;
  final bool isSyncing;
  final Future<void> Function() onRetryConnection;
  final Future<void> Function() onSyncPendingReports;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final title = isOfflineMode
        ? strings.text('offlineStatusTitle')
        : strings.text('offlineStatusTitleSaved');
    final body = isOfflineMode
        ? strings.text('offlineStatusBody', {
            'count': pendingReportCount.toString(),
          })
        : strings.text('offlineSavedBody', {
            'count': pendingReportCount.toString(),
          });
    final buttonLabel = isSyncing
        ? strings.text('syncing')
        : isOfflineMode
        ? strings.text('tryConnectionAgain')
        : strings.text('syncSavedReports');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: visuals.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: isSyncing
                  ? null
                  : isOfflineMode
                  ? onRetryConnection
                  : onSyncPendingReports,
              child: Text(buttonLabel),
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white30),
            const SizedBox(height: 20),

            Text(
              "Police Response",
              style: TextStyle(
                color: Colors.white,
               fontSize: 18,
               fontWeight: FontWeight.bold,
               ),
              ),

              const SizedBox(height: 16),

              Row(
                children: const [
                 Icon(Icons.radio_button_checked,
                   color: Colors.white),
                 SizedBox(width: 10),
                 Text(
                   "Waiting for emergency request...",
                  style: TextStyle(color: Colors.white),
             ),
            ],
          ),

          ],
        ),
      ),
    );
  }
}

class _SubmissionResultCard extends StatelessWidget {
  const _SubmissionResultCard({required this.result});

  final ReportSubmissionResult result;

  @override
  Widget build(BuildContext context) {
    final isQueuedOffline = result.status.toLowerCase().contains("queued");
    final visuals = context.appVisuals;
    final statusColor = isQueuedOffline ? visuals.primary : visuals.accent;
    final statusBackground = _blendColors(
      visuals.cardSurface,
      statusColor,
      0.14,
    );
    final strings = AppSettingsScope.stringsOf(context);
    final resultTitle = isQueuedOffline
        ? strings.text('savedOfflineTitle')
        : strings.text('submissionSaved');
    final referenceLabel = isQueuedOffline
        ? strings.text('localRef')
        : strings.text('reference');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resultTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.statusLabel(result.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "$referenceLabel: ${result.publicReference}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: visuals.deep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _ProgressBar(value: 1),
            const SizedBox(height: 14),
            Text(
              result.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: visuals.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportFormCard extends StatelessWidget {
  const _ReportFormCard({
    required this.formKey,
    required this.categories,
    required this.selectedCategory,
    required this.selectedDateTime,
    required this.consentAcknowledged,
    required this.hasCapturedLocation,
    required this.isGettingLocation,
    required this.areaController,
    required this.descriptionController,
    required this.isSubmitting,
    required this.onCategoryChanged,
    required this.onConsentChanged,
    required this.onUseCurrentLocation,
    required this.onPickDateTime,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<IncidentCategory> categories;
  final IncidentCategory? selectedCategory;
  final DateTime? selectedDateTime;
  final bool consentAcknowledged;
  final bool hasCapturedLocation;
  final bool isGettingLocation;
  final TextEditingController areaController;
  final TextEditingController descriptionController;
  final bool isSubmitting;
  final ValueChanged<IncidentCategory?> onCategoryChanged;
  final ValueChanged<bool?> onConsentChanged;
  final Future<void> Function() onUseCurrentLocation;
  final Future<void> Function() onPickDateTime;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final completion = _completionValue();
    final completedItems = _completedItems();
    final locationPanelColor = _blendColors(
      visuals.cardSurface,
      hasCapturedLocation ? visuals.accent : visuals.primary,
      hasCapturedLocation ? 0.12 : 0.06,
    );
    final locationBorderColor =
        (hasCapturedLocation ? visuals.accent : visuals.primary).withValues(
          alpha: 0.26,
        );
    final consentPanelColor = _blendColors(
      visuals.cardSurface,
      visuals.primary,
      0.08,
    );
    final submitForeground = _bestContrastingColor(
      visuals.primary,
      light: Colors.white,
      dark: visuals.deep,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormShowcaseBanner(),
              const SizedBox(height: 18),
              Text(
                strings.text('newIncidentReport'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.text('reportFormBody'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: visuals.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.text('detailsReady', {
                        'count': completedItems.toString(),
                      }),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: visuals.deep,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${(completion * 100).round()}%",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: visuals.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProgressBar(value: completion),
              const SizedBox(height: 22),
              DropdownButtonFormField<IncidentCategory>(
                key: ValueKey<String>(
                  "category-${selectedCategory?.code ?? 'none'}",
                ),
                initialValue: selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.text('incidentCategory'),
                ),
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          strings.categoryName(item.code, item.name),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPickDateTime,
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(
                    selectedDateTime == null
                        ? strings.text('selectDateTime')
                        : _formatDateTime(selectedDateTime!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: areaController,
                decoration: InputDecoration(
                  labelText: strings.text('approxAreaName'),
                  hintText: "Kariakoo",
                ),
                validator: _requiredField(strings.text('approxAreaRequired')),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: locationPanelColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: locationBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasCapturedLocation
                                ? visuals.accent
                                : _blendColors(
                                    visuals.cardSurface,
                                    visuals.primary,
                                    0.14,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            hasCapturedLocation
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: hasCapturedLocation
                                ? _bestContrastingColor(
                                    visuals.accent,
                                    light: Colors.white,
                                    dark: visuals.deep,
                                  )
                                : visuals.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasCapturedLocation
                                    ? strings.text('currentLocationReady')
                                    : strings.text('attachCurrentLocation'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasCapturedLocation
                                    ? strings.text('currentLocationBody')
                                    : strings.text('attachLocationBody'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: visuals.muted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isGettingLocation
                            ? null
                            : onUseCurrentLocation,
                        icon: isGettingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                hasCapturedLocation
                                    ? Icons.refresh_rounded
                                    : Icons.gps_fixed_rounded,
                              ),
                        label: Text(
                          isGettingLocation
                              ? strings.text('gettingLocation')
                              : hasCapturedLocation
                              ? strings.text('updateCurrentLocation')
                              : strings.text('useCurrentLocation'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
             TextFormField(
  controller: descriptionController,
  minLines: 4,
  maxLines: 6,
  decoration: InputDecoration(
    labelText: strings.text('whatHappened'),
    hintText: strings.text('whatHappenedHint'),
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please describe what happened.";
    }
    return null;
  },
),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: consentPanelColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: visuals.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
Checkbox(
  value: consentAcknowledged,
  onChanged: onConsentChanged,
),
const SizedBox(width: 6),
Expanded(
  child: Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Submit this report anonymously.",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Your identity will remain confidential. Personal information is not shared with police, researchers, or partner organizations.",
          style: TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 5, 240, 13),
            height: 1.4,
          ),
        ),
      ],
    ),
  ),
),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [visuals.accent, visuals.primary],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: visuals.primary.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: submitForeground,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: submitForeground,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      isSubmitting
                          ? strings.text('submitting')
                          : strings.text('submitReport'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _completedItems() {
    var count = 0;

    if (selectedCategory != null) {
      count++;
    }
    if (selectedDateTime != null) {
      count++;
    }
    if (areaController.text.trim().isNotEmpty) {
      count++;
    }
    if (hasCapturedLocation) {
      count++;
    }
    if (descriptionController.text.trim().isNotEmpty) {
      count++;
    }
    if (consentAcknowledged) {
      count++;
    }

    return count;
  }

  double _completionValue() => _completedItems() / 6;

  FormFieldValidator<String> _requiredField(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }
}

class _FormShowcaseBanner extends StatelessWidget {
  const _FormShowcaseBanner();

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _blendColors(visuals.cardSurface, visuals.blush, 0.70),
              _blendColors(visuals.cardSurface, visuals.bright, 0.34),
              _blendColors(visuals.cardSurface, visuals.primary, 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 18, left: 22, child: _CloudShape(width: 70)),
            const Positioned(top: 28, left: 86, child: _CloudShape(width: 46)),
            Positioned(
              bottom: 18,
              left: 26,
              child: Transform.rotate(
                angle: -0.22,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visuals.bright,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 56,
              child: Transform.rotate(
                angle: 0.03,
                child: Container(
                  width: 104,
                  height: 26,
                  decoration: BoxDecoration(
                    color: visuals.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 22,
              right: 18,
              child: SizedBox(
                width: 96,
                height: 48,
                child: CustomPaint(
                  painter: _BannerLinePainter(
                    color: _bestContrastingColor(
                      visuals.primary,
                      light: Colors.white,
                      dark: visuals.deep,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudShape extends StatelessWidget {
  const _CloudShape({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.32,
      decoration: BoxDecoration(
        color: const Color(0xEAFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BannerLinePainter extends CustomPainter {
  const _BannerLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final left = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.26, size.height * 0.22)
      ..lineTo(size.width * 0.44, size.height * 0.68);

    final right = Path()
      ..moveTo(size.width * 0.60, size.height * 0.88)
      ..lineTo(size.width * 0.88, size.height * 0.18)
      ..lineTo(size.width, size.height * 0.42);

    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Container(
              color: _blendColors(visuals.cardSurface, visuals.primary, 0.10),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [visuals.accent, visuals.primary],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, "0");
  final minute = value.minute.toString().padLeft(2, "0");
  final month = value.month.toString().padLeft(2, "0");
  final day = value.day.toString().padLeft(2, "0");
  return "$day/$month/${value.year} $hour:$minute";
}

Color _blendColors(Color base, Color overlay, double opacity) {
  return Color.alphaBlend(
    overlay.withValues(alpha: opacity.clamp(0.0, 1.0)),
    base,
  );
}

Color _bestContrastingColor(
  Color background, {
  Color light = Colors.white,
  Color dark = const Color(0xFF101820),
}) {
  final lightContrast = _contrastRatio(background, light);
  final darkContrast = _contrastRatio(background, dark);
  return lightContrast >= darkContrast ? light : dark;
}

double _contrastRatio(Color a, Color b) {
  final lighter = math.max(a.computeLuminance(), b.computeLuminance());
  final darker = math.min(a.computeLuminance(), b.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

class _LocationCaptureException implements Exception {
  const _LocationCaptureException(this.message);

  final String message;
}
