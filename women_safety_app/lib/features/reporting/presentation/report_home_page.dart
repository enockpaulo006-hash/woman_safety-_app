import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../../core/settings/app_settings_scope.dart';
import '../../../../core/theme/app_palette.dart';
import '../data/models/incident_category.dart';
import '../data/models/location_type.dart';
import '../data/models/pending_incident_report.dart';
import '../data/models/report_submission_result.dart';
import '../data/services/offline_report_store.dart';
import '../data/services/reporting_api_service.dart';
import '../data/services/reporting_seed_data.dart';

const _deepIndigo = AppPalette.deepBerry;
const _primaryIndigo = AppPalette.primaryRose;
const _brightIndigo = AppPalette.brightRose;
const _mint = AppPalette.blush;
const _pink = AppPalette.accentCoral;
const _softPink = AppPalette.softShell;
const _softLilac = AppPalette.softRose;
const _mutedText = AppPalette.mutedRose;
const _cardShadow = AppPalette.cardShadow;

enum _AppSection {
  home,
  report,
  offline,
  guide,
  syncCenter,
  settings,
  themes,
}

class ReportHomePage extends StatefulWidget {
  const ReportHomePage({super.key});

  @override
  State<ReportHomePage> createState() => _ReportHomePageState();
}

class _ReportHomePageState extends State<ReportHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = ReportingApiService();
  final _offlineStore = OfflineReportStore();

  final _areaController = TextEditingController();
  final _wardController = TextEditingController();
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
  bool _isSyncingPendingReports = false;
  int _pendingReportCount = 0;
  int _selectedBottomIndex = 0;
  _AppSection _currentSection = _AppSection.home;
  bool _autoSyncEnabled = true;
  bool _locationHintsEnabled = true;
  bool _privacyTipsEnabled = true;
  ReportSubmissionResult? _lastSubmission;

  AppStrings get _strings => AppSettingsScope.readStringsOf(context);
  AppSettingsController get _settingsController =>
      AppSettingsScope.readControllerOf(context);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _wardController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _refreshPendingReportCount();
    await _loadTaxonomies();
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
    final previousLocationTypeCode = _selectedLocationType?.code;

    setState(() {
      _isLoading = true;
    });

    try {
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
          previousLocationTypeCode,
        );
        _usingOfflineTaxonomies = false;
        _isLoading = false;
      });

      if (_pendingReportCount > 0) {
        await _syncPendingReports(
          showSnack: false,
          onlineCategories: categories,
          onlineLocationTypes: locationTypes,
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
          previousLocationTypeCode,
        );
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
    setState(() {
      _selectedBottomIndex = 1;
      _currentSection = _AppSection.report;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectBottomDestination(int index) {
    final section = switch (index) {
      0 => _AppSection.home,
      1 => _AppSection.report,
      2 => _AppSection.offline,
      _ => _AppSection.guide,
    };

    setState(() {
      _selectedBottomIndex = index;
      _currentSection = section;
    });
  }

  void _openSection(_AppSection section) {
    setState(() {
      _currentSection = section;

      switch (section) {
        case _AppSection.home:
          _selectedBottomIndex = 0;
        case _AppSection.report:
          _selectedBottomIndex = 1;
        case _AppSection.offline:
          _selectedBottomIndex = 2;
        case _AppSection.guide:
          _selectedBottomIndex = 3;
        case _AppSection.syncCenter:
        case _AppSection.settings:
        case _AppSection.themes:
          break;
      }
    });
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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw _LocationCaptureException(
          strings.text('locationServiceOff'),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw _LocationCaptureException(
          strings.text('locationPermissionDenied'),
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw _LocationCaptureException(
          strings.text('locationPermissionForever'),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedLatitude = position.latitude;
        _capturedLongitude = position.longitude;
        _isGettingLocation = false;
      });
      _showSnack(strings.text('locationCaptured'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGettingLocation = false;
      });

      if (error is _LocationCaptureException) {
        _showSnack(error.message);
        return;
      }

      _showSnack(strings.text('locationCaptureFailed'));
    }
  }

  Future<void> _submit() async {
    final strings = _strings;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      _showSnack(strings.text('incidentTimeRequired'));
      return;
    }

    if (_selectedCategory == null || _selectedLocationType == null) {
      _showSnack(strings.text('taxonomyWait'));
      return;
    }

    if (_capturedLatitude == null || _capturedLongitude == null) {
      _showSnack(strings.text('locationRequired'));
      return;
    }

    if (!_consentAcknowledged) {
      _showSnack(strings.text('consentRequired'));
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
        _showSnack(result.message);
        _resetForm();
        return;
      }

      final result = await _api.submitReport(
        categoryId: _selectedCategory!.id,
        locationTypeId: _selectedLocationType!.id,
        occurredAt: _selectedDateTime!,
        latitude: _capturedLatitude!,
        longitude: _capturedLongitude!,
        approxAreaName: _areaController.text,
        wardOrDistrict: _wardController.text,
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
      _showSnack(result.message);
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
          _usingOfflineTaxonomies = true;
        });
        _showSnack(result.message);
        _resetForm();
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      _showSnack(error.toString());
    }
  }

  Future<ReportSubmissionResult> _queueCurrentReportOffline() async {
    final queuedReport = PendingIncidentReport(
      localId: "offline-${DateTime.now().microsecondsSinceEpoch}",
      categoryCode: _selectedCategory!.code,
      locationTypeCode: _selectedLocationType!.code,
      occurredAt: _selectedDateTime!,
      latitude: _capturedLatitude!,
      longitude: _capturedLongitude!,
      approxAreaName: _areaController.text.trim(),
      wardOrDistrict: _wardController.text.trim(),
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
    List<LocationType>? onlineLocationTypes,
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
        _showSnack(_strings.text('noSavedOfflineReports'));
      }
      return;
    }

    setState(() {
      _isSyncingPendingReports = true;
    });

    try {
      final categories =
          onlineCategories ?? await _api.fetchIncidentCategories();
      final locationTypes =
          onlineLocationTypes ?? await _api.fetchLocationTypes();

      final categoriesByCode = {
        for (final category in categories) category.code: category,
      };
      final locationTypesByCode = {
        for (final locationType in locationTypes)
          locationType.code: locationType,
      };

      final remainingReports = <PendingIncidentReport>[];
      var syncedCount = 0;

      for (var index = 0; index < pendingReports.length; index++) {
        final pendingReport = pendingReports[index];
        final category = categoriesByCode[pendingReport.categoryCode];
        final locationType =
            locationTypesByCode[pendingReport.locationTypeCode];

        if (category == null || locationType == null) {
          remainingReports.add(pendingReport);
          continue;
        }

        try {
          await _api.submitReport(
            categoryId: category.id,
            locationTypeId: locationType.id,
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
        _usingOfflineTaxonomies = false;
      });

      if (!showSnack) {
        return;
      }

      if (syncedCount > 0 && remainingReports.isEmpty) {
        _showSnack(_strings.text('syncComplete'));
      } else if (syncedCount > 0) {
        _showSnack(
          _strings.text('syncPartial', {
            'synced': syncedCount.toString(),
            'remaining': remainingReports.length.toString(),
          }),
        );
      } else {
        _showSnack(_strings.text('syncWaiting'));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingPendingReports = false;
      });

      if (showSnack) {
        _showSnack(_strings.text('syncOfflineLater'));
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _areaController.clear();
    _wardController.clear();
    _descriptionController.clear();
    setState(() {
      _capturedLatitude = null;
      _capturedLongitude = null;
      _consentAcknowledged = false;
      _selectedDateTime = null;
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _selectedLocationType = _locationTypes.isNotEmpty
          ? _locationTypes.first
          : null;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleHomeRefresh() async {
    await _loadTaxonomies();
    if (_autoSyncEnabled && _pendingReportCount > 0 && !_usingOfflineTaxonomies) {
      await _syncPendingReports(showSnack: false);
    }
  }

  Widget _buildCurrentSection() {
    switch (_currentSection) {
      case _AppSection.home:
        return _buildHomeSection();
      case _AppSection.report:
        return _buildReportSection();
      case _AppSection.offline:
        return _buildOfflineSection();
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

    return RefreshIndicator(
      onRefresh: _handleHomeRefresh,
      color: _deepIndigo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('homeTitle'),
            subtitle: strings.text('homeSubtitle'),
            onMenuPressed: _openDrawer,
            action: _StatusPill(
              label: _usingOfflineTaxonomies
                  ? strings.text('offline')
                  : strings.text('live'),
              color: _usingOfflineTaxonomies ? _primaryIndigo : _mint,
            ),
          ),
          const SizedBox(height: 18),
          _HeroCard(onOpenForm: _openReportForm),
          const SizedBox(height: 18),
          _HomeOverviewCard(
            pendingReportCount: _pendingReportCount,
            usingOfflineTaxonomies: _usingOfflineTaxonomies,
            onOpenReportForm: _openReportForm,
            onOpenOfflineQueue: () => _openSection(_AppSection.offline),
          ),
          const SizedBox(height: 18),
          _HomeQuickActionsCard(
            pendingReportCount: _pendingReportCount,
            onOpenReportForm: _openReportForm,
            onOpenOfflineQueue: () => _openSection(_AppSection.offline),
            onOpenGuide: () => _openSection(_AppSection.guide),
            onOpenSyncCenter: () => _openSection(_AppSection.syncCenter),
          ),
          if (_lastSubmission != null) ...[
            _SubmissionResultCard(result: _lastSubmission!),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return RefreshIndicator(
      onRefresh: _loadTaxonomies,
      color: _deepIndigo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('reportSectionTitle'),
            subtitle: strings.text('reportSectionSubtitle'),
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          if (_usingOfflineTaxonomies ||
              _pendingReportCount > 0 ||
              _isSyncingPendingReports) ...[
            _OfflineStatusCard(
              isOfflineMode: _usingOfflineTaxonomies,
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
              locationTypes: _locationTypes,
              selectedCategory: _selectedCategory,
              selectedLocationType: _selectedLocationType,
              selectedDateTime: _selectedDateTime,
              consentAcknowledged: _consentAcknowledged,
              hasCapturedLocation:
                  _capturedLatitude != null && _capturedLongitude != null,
              isGettingLocation: _isGettingLocation,
              areaController: _areaController,
              wardController: _wardController,
              descriptionController: _descriptionController,
              isSubmitting: _isSubmitting,
              onCategoryChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              onLocationTypeChanged: (value) {
                setState(() => _selectedLocationType = value);
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

    return RefreshIndicator(
      onRefresh: _refreshPendingReportCount,
      color: _deepIndigo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('offlineSectionTitle'),
            subtitle: strings.text('offlineSectionSubtitle'),
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          _OfflineStatusCard(
            isOfflineMode: _usingOfflineTaxonomies,
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

  Widget _buildSyncCenterSection() {
    final strings = AppSettingsScope.stringsOf(context);

    return RefreshIndicator(
      onRefresh: _handleHomeRefresh,
      color: _deepIndigo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _SectionTopBar(
            title: strings.text('syncCenterTitle'),
            subtitle: strings.text('syncCenterSubtitle'),
            onMenuPressed: _openDrawer,
          ),
          const SizedBox(height: 18),
          _SyncStatusCard(
            isOfflineMode: _usingOfflineTaxonomies,
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
          onMenuPressed: _openDrawer,
        ),
        const SizedBox(height: 18),
        _SettingsCard(
          language: _settingsController.language,
          themeMode: _settingsController.themeMode,
          autoSyncEnabled: _autoSyncEnabled,
          locationHintsEnabled: _locationHintsEnabled,
          privacyTipsEnabled: _privacyTipsEnabled,
          onLanguageChanged: _settingsController.setLanguage,
          onThemeModeChanged: _settingsController.setThemeMode,
          onAutoSyncChanged: (value) {
            setState(() => _autoSyncEnabled = value);
          },
          onLocationHintsChanged: (value) {
            setState(() => _locationHintsEnabled = value);
          },
          onPrivacyTipsChanged: (value) {
            setState(() => _privacyTipsEnabled = value);
          },
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: visuals.pageBackground,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _SafetyDrawer(
          currentSection: _currentSection,
          pendingReportCount: _pendingReportCount,
          usingOfflineTaxonomies: _usingOfflineTaxonomies,
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
    );
  }
}

class _SectionTopBar extends StatelessWidget {
  const _SectionTopBar({
    required this.title,
    required this.subtitle,
    this.onMenuPressed,
    this.action,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onMenuPressed;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onMenuPressed != null)
          Container(
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
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
              color: visuals.deep,
            ),
          ),
        if (onMenuPressed != null) const SizedBox(width: 14),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                  color: visuals.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
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
            style: TextStyle(
              color: visuals.deep,
              fontWeight: FontWeight.w800,
            ),
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
                  color: _softPink,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: _primaryIndigo,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.text('queueEmptyTitle'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.text('queueEmptyBody'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _mutedText, height: 1.5),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...pendingReports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _softPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.schedule_send_rounded,
                          color: _primaryIndigo,
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
                              style: const TextStyle(
                                color: _deepIndigo,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${strings.categoryName(report.categoryCode, report.categoryCode)} • ${strings.locationTypeName(report.locationTypeCode, report.locationTypeCode)}",
                              style: const TextStyle(
                                color: _mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.text('queuedAt', {
                                'time': _formatDateTime(report.queuedAt),
                              }),
                              style: const TextStyle(color: _mutedText),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedText),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _deepIndigo,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.language,
    required this.themeMode,
    required this.autoSyncEnabled,
    required this.locationHintsEnabled,
    required this.privacyTipsEnabled,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
    required this.onAutoSyncChanged,
    required this.onLocationHintsChanged,
    required this.onPrivacyTipsChanged,
  });

  final AppLanguage language;
  final ThemeMode themeMode;
  final bool autoSyncEnabled;
  final bool locationHintsEnabled;
  final bool privacyTipsEnabled;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onAutoSyncChanged;
  final ValueChanged<bool> onLocationHintsChanged;
  final ValueChanged<bool> onPrivacyTipsChanged;

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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
              selected: {language},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onLanguageChanged(selection.first);
                }
              },
            ),
            const SizedBox(height: 22),
            Text(
              strings.text('modeSetting'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onThemeModeChanged(selection.first);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(strings.text('lightMode'))),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(strings.text('darkMode')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SwitchListTile(
              value: autoSyncEnabled,
              onChanged: onAutoSyncChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('autoSyncTitle')),
              subtitle: Text(
                strings.text('autoSyncSubtitle'),
              ),
            ),
            SwitchListTile(
              value: locationHintsEnabled,
              onChanged: onLocationHintsChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('locationHintsTitle')),
              subtitle: Text(
                strings.text('locationHintsSubtitle'),
              ),
            ),
            SwitchListTile(
              value: privacyTipsEnabled,
              onChanged: onPrivacyTipsChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.text('privacyTipsTitle')),
              subtitle: Text(
                strings.text('privacyTipsSubtitle'),
              ),
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
          children: AppThemePreset.values.map((preset) {
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
                                  ?.copyWith(color: _mutedText, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? visuals.primary : _mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
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

class _SafetyDrawer extends StatelessWidget {
  const _SafetyDrawer({
    required this.currentSection,
    required this.pendingReportCount,
    required this.usingOfflineTaxonomies,
    required this.onSelectSection,
  });

  final _AppSection currentSection;
  final int pendingReportCount;
  final bool usingOfflineTaxonomies;
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
                if (usingOfflineTaxonomies)
                  _StatusPill(
                    label: strings.text('offline'),
                    color: visuals.primary,
                  ),
              ],
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
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
              color: selected ? const Color(0xFFE8EEFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? _primaryIndigo : _deepIndigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? _primaryIndigo : _deepIndigo,
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
}

class _BottomQuickNavigation extends StatelessWidget {
  const _BottomQuickNavigation({
    required this.selectedIndex,
    required this.pendingReportCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int pendingReportCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;
    final items = [
      (icon: Icons.home_outlined, label: strings.text('drawerHome')),
      (icon: Icons.edit_note_rounded, label: strings.text('report')),
      (icon: Icons.cloud_upload_outlined, label: strings.text('savedOffline')),
      (icon: Icons.shield_outlined, label: strings.text('guide')),
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
              final badge = index == 2 && pendingReportCount > 0
                  ? pendingReportCount.toString()
                  : null;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? visuals.primary.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? visuals.primary.withValues(alpha: 0.28)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                item.icon,
                                size: 24,
                                color: selected ? Colors.white : visuals.muted,
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
                                      borderRadius: BorderRadius.circular(999),
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
              );
            }),
          ),
        ),
      ),
    );
  }
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
    final textTheme = Theme.of(context).textTheme;
    final strings = AppSettingsScope.stringsOf(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: _cardShadow, blurRadius: 28, offset: Offset(0, 18)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_deepIndigo, _primaryIndigo, _brightIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const Positioned(
              top: -14,
              right: -10,
              child: _HeroOrb(size: 120, color: Color(0xCC14DEC8)),
            ),
            const Positioned(
              bottom: -54,
              left: -36,
              child: _HeroOrb(size: 170, color: Color(0xCC11D1C8)),
            ),
            const Positioned(
              top: 44,
              left: 18,
              child: _HeroOrb(size: 20, color: Color(0xFF14DEC8)),
            ),
            const Positioned.fill(
              child: CustomPaint(painter: _HeroLinePainter()),
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
                          color: const Color(0x1DFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Text(
                          strings.text('anonymousReporting'),
                          style: TextStyle(
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
                          style: TextStyle(color: _mint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.text('heroBody'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xE2F6F4FF),
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
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0x14FFFFFF),
                          side: const BorderSide(color: Color(0x30FFFFFF)),
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
  const _HeroLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fill = Paint()
      ..color = const Color(0x14FFFFFF)
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
      Paint()..color = const Color(0x10FFFFFF),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedText, height: 1.45),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _StepBubble(
                  icon: Icons.shield_outlined,
                  label: strings.text('quickStep1'),
                  color: _primaryIndigo,
                ),
                _StepBubble(
                  icon: Icons.place_outlined,
                  label: strings.text('quickStep2'),
                  color: Color(0xFFFFC24B),
                ),
                _StepBubble(
                  icon: Icons.notes_rounded,
                  label: strings.text('quickStep3'),
                  color: _mint,
                ),
                _StepBubble(
                  icon: Icons.send_rounded,
                  label: strings.text('quickStep4'),
                  color: _pink,
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
              color: _deepIndigo,
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
                color: _softLilac,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: _primaryIndigo,
              ),
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
                      color: _mutedText,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            CircularProgressIndicator(color: _primaryIndigo),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedText, height: 1.5),
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
    final statusColor = isQueuedOffline ? _primaryIndigo : _mint;
    final statusBackground = isQueuedOffline
        ? const Color(0xFFFBE8F1)
        : const Color(0xFFE7FFF8);
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
                color: _deepIndigo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _ProgressBar(value: 1),
            const SizedBox(height: 14),
            Text(
              result.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _mutedText, height: 1.5),
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
    required this.locationTypes,
    required this.selectedCategory,
    required this.selectedLocationType,
    required this.selectedDateTime,
    required this.consentAcknowledged,
    required this.hasCapturedLocation,
    required this.isGettingLocation,
    required this.areaController,
    required this.wardController,
    required this.descriptionController,
    required this.isSubmitting,
    required this.onCategoryChanged,
    required this.onLocationTypeChanged,
    required this.onConsentChanged,
    required this.onUseCurrentLocation,
    required this.onPickDateTime,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<IncidentCategory> categories;
  final List<LocationType> locationTypes;
  final IncidentCategory? selectedCategory;
  final LocationType? selectedLocationType;
  final DateTime? selectedDateTime;
  final bool consentAcknowledged;
  final bool hasCapturedLocation;
  final bool isGettingLocation;
  final TextEditingController areaController;
  final TextEditingController wardController;
  final TextEditingController descriptionController;
  final bool isSubmitting;
  final ValueChanged<IncidentCategory?> onCategoryChanged;
  final ValueChanged<LocationType?> onLocationTypeChanged;
  final ValueChanged<bool?> onConsentChanged;
  final Future<void> Function() onUseCurrentLocation;
  final Future<void> Function() onPickDateTime;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppSettingsScope.stringsOf(context);
    final completion = _completionValue();
    final completedItems = _completedItems();

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
                  color: _mutedText,
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
                        color: _deepIndigo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    "${(completion * 100).round()}%",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _primaryIndigo,
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
                decoration: InputDecoration(
                  labelText: strings.text('incidentCategory'),
                ),
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(strings.categoryName(item.code, item.name)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LocationType>(
                key: ValueKey<String>(
                  "location-${selectedLocationType?.code ?? 'none'}",
                ),
                initialValue: selectedLocationType,
                decoration: InputDecoration(
                  labelText: strings.text('locationType'),
                ),
                items: locationTypes
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          strings.locationTypeName(item.code, item.name),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onLocationTypeChanged,
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
              TextFormField(
                controller: wardController,
                decoration: InputDecoration(
                  labelText: strings.text('wardDistrict'),
                  hintText: "Ilala",
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasCapturedLocation
                      ? const Color(0xFFF0FFFB)
                      : const Color(0xFFF7F7FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: hasCapturedLocation
                        ? const Color(0x3314DEC8)
                        : const Color(0x1A3E42D3),
                  ),
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
                            color: hasCapturedLocation ? _mint : _softLilac,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            hasCapturedLocation
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: hasCapturedLocation
                                ? Colors.white
                                : _primaryIndigo,
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
                                  color: _mutedText,
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
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _softLilac,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x1E3E42D3)),
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
                        child: Text(
                          strings.text('consentText'),
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
                    gradient: const LinearGradient(
                      colors: [_mint, _primaryIndigo],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2214DEC8),
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
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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
    if (selectedLocationType != null) {
      count++;
    }
    if (selectedDateTime != null) {
      count++;
    }
    if (areaController.text.trim().isNotEmpty) {
      count++;
    }
    if (wardController.text.trim().isNotEmpty) {
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

  double _completionValue() => _completedItems() / 8;

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 138,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_softPink, Color(0xFFFBD2DB), Color(0xFFD7D8FF)],
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
                    color: _pink,
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
                    color: const Color(0xFFFFC14B),
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
                child: CustomPaint(painter: _BannerLinePainter()),
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
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Container(color: const Color(0xFFE6E7FB)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_mint, _primaryIndigo]),
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

class _LocationCaptureException implements Exception {
  const _LocationCaptureException(this.message);

  final String message;
}
