import 'package:flutter/material.dart';

import '../settings/app_settings_controller.dart';
import '../theme/app_palette.dart';

class AppStrings {
  AppStrings(this.language);

  final AppLanguage language;

  static const _translations = {
    AppLanguage.english: {
      'appTitle': 'Women Safety',
      'welcomeTitle': 'WOMEN SAFETY',
      'welcomeSubtitle': 'Start your daily commute safe and secure',
      'getStarted': 'Get Started',
      'registrationTitle': 'Create your profile',
      'fullName': 'FULL NAME',
      'email': 'EMAIL',
      'password': 'PASSWORD',
      'confirmPassword': 'CONFIRM PASSWORD',
      'signUp': 'Sign Up',
      'fullNameRequired': 'Enter the full name.',
      'fullNameShort': 'Full name is too short.',
      'emailRequired': 'Enter the email address.',
      'emailInvalid': 'Enter a valid email address.',
      'passwordRequired': 'Enter the password.',
      'passwordShort': 'Use at least 6 characters.',
      'confirmPasswordRequired': 'Confirm the password.',
      'passwordMismatch': 'Passwords do not match.',
      'registrationReady': 'Welcome {name}, your registration is ready.',
      'homeTitle': 'Move Safety',
      'homeSubtitle': 'Daily reporting tools in one place.',
      'offline': 'Offline',
      'live': 'Live',
      'homeOverviewTitle': 'Today\'s overview',
      'homeOverviewOffline':
          'The app is currently ready to collect reports offline.',
      'homeOverviewOnline':
          'The app is connected and ready for direct report submission.',
      'noSavedOfflineReports': 'No saved offline reports right now.',
      'savedOfflineQueue': '{count} reports are waiting in the offline queue.',
      'openReportForm': 'Open report form',
      'savedOffline': 'Saved offline',
      'quickAccess': 'Quick access',
      'report': 'Report',
      'guide': 'Guide',
      'sync': 'Sync',
      'emergencyGuidance': 'Emergency guidance',
      'emergencyGuidanceBody':
          'If someone is in immediate danger, contact emergency services or a trusted responder first. Use reporting right after you are safe.',
      'reportSectionTitle': 'Open report form',
      'reportSectionSubtitle':
          'Capture incident time inside the form and submit safely.',
      'offlineSectionTitle': 'Saved offline',
      'offlineSectionSubtitle':
          'Reports stored on this phone while connection is unavailable.',
      'guideTitle': 'Safety guide',
      'guideSubtitle': 'Quick steps and reminders for everyday use.',
      'privacyReminder': 'Privacy reminder',
      'privacyReminderBody':
          'Share only the details needed to understand the incident. Avoid exposing extra personal information if it is not necessary.',
      'locationGuidance': 'Location guidance',
      'locationGuidanceBody':
          'Use current location when possible so reports are easier to map later, especially when the incident happened during travel.',
      'syncCenterTitle': 'Sync center',
      'syncCenterSubtitle': 'Connection status and offline delivery tools.',
      'settingsTitle': 'Settings',
      'settingsSubtitle':
          'Control language, display mode, reminders, and how the app behaves offline.',
      'themeTitle': 'Themes',
      'themeSubtitle':
          'Choose the color style people see while using the app every day.',
      'languageSetting': 'Language',
      'modeSetting': 'Display mode',
      'themeSetting': 'Theme style',
      'english': 'English',
      'swahili': 'Swahili',
      'lightMode': 'Light',
      'darkMode': 'Dark',
      'autoSyncTitle': 'Auto sync saved reports',
      'autoSyncSubtitle':
          'When connection comes back, try to send pending reports automatically.',
      'locationHintsTitle': 'Show location guidance',
      'locationHintsSubtitle':
          'Keep everyday reminders that help users capture accurate locations.',
      'privacyTipsTitle': 'Show privacy reminders',
      'privacyTipsSubtitle':
          'Keep short safety reminders about what details to share in reports.',
      'drawerHome': 'Home',
      'drawerReport': 'Open report form',
      'drawerOffline': 'Saved offline',
      'drawerGuide': 'Safety guide',
      'drawerSyncCenter': 'Sync center',
      'drawerSettings': 'Settings',
      'drawerThemes': 'Themes',
      'queueEmptyTitle': 'Nothing is waiting offline',
      'queueEmptyBody':
          'When connection is unavailable, submitted reports will appear here.',
      'createReport': 'Create report',
      'pendingQueue': 'Pending queue',
      'offlineReport': 'Offline report',
      'queuedAt': 'Queued {time}',
      'connectionSnapshot': 'Connection snapshot',
      'currentMode': 'Current mode',
      'offlineCapture': 'Offline capture',
      'connected': 'Connected',
      'pendingReports': 'Pending reports',
      'autoSync': 'Auto sync',
      'enabled': 'Enabled',
      'manualOnly': 'Manual only',
      'syncNow': 'Sync now',
      'syncing': 'Syncing...',
      'retryConnection': 'Retry connection',
      'anonymousReporting': 'Anonymous reporting',
      'heroTitleA': 'Report unsafe\nincidents with\n',
      'heroTitleB': 'clarity and care.',
      'heroBody':
          'Use the quick navigation to move through the app, then open the form only when you are ready to record the incident.',
      'newIncidentReport': 'New incident report',
      'reportFormBody':
          'The form keeps the same reporting flow, but now it lives inside its own report section.',
      'detailsReady': '{count} of 8 details ready',
      'incidentCategory': 'Incident category',
      'locationType': 'Location type',
      'selectDateTime': 'Select date and time',
      'approxAreaName': 'Approximate area name',
      'wardDistrict': 'Ward or district',
      'currentLocationReady': 'Current location ready',
      'attachCurrentLocation': 'Attach your current location',
      'currentLocationBody':
          'Coordinates are saved in the background and will be sent with the report.',
      'attachLocationBody':
          'The app will use your phone location so people do not need to type latitude or longitude.',
      'gettingLocation': 'Getting current location...',
      'updateCurrentLocation': 'Update current location',
      'useCurrentLocation': 'Use current location',
      'whatHappened': 'What happened?',
      'whatHappenedHint':
          'Describe the incident using only the details needed to understand it.',
      'consentText':
          'I confirm this report can be stored for safety analysis.',
      'submitReport': 'Submit report',
      'submitting': 'Submitting...',
      'incidentTimeRequired': 'Please choose when the incident happened.',
      'taxonomyWait':
          'Please wait for categories and location types to load.',
      'locationRequired':
          'Please tap \'Use current location\' before submitting.',
      'consentRequired':
          'Consent must be acknowledged before submission.',
      'locationCaptured': 'Current location captured.',
      'locationServiceOff': 'Turn on phone location services, then try again.',
      'locationPermissionDenied': 'Location permission was denied.',
      'locationPermissionForever':
          'Location permission is permanently denied. Allow it in your phone settings.',
      'locationCaptureFailed':
          'Could not get the current location. Please try again.',
      'offlineStatusTitle': 'Offline mode is active',
      'offlineStatusTitleSaved': 'Reports waiting to sync',
      'offlineStatusBody':
          'The report form is using built-in categories. New reports will be saved on this phone and sent later. Pending saved reports: {count}.',
      'offlineSavedBody':
          'Connection is back, but {count} saved reports are still waiting to sync.',
      'tryConnectionAgain': 'Try connection again',
      'submissionSaved': 'Submission saved',
      'savedOfflineTitle': 'Saved offline',
      'reference': 'Reference',
      'localRef': 'Local ref',
      'loadingTaxonomies': 'Loading categories and location types...',
      'quickStep1': 'Incident',
      'quickStep2': 'Area',
      'quickStep3': 'Location',
      'quickStep4': 'Submit',
      'reportFlowTitle': 'Report flow',
      'reportFlowBody':
          'Move through the report in clear steps before you submit.',
      'syncSavedReports': 'Sync saved reports',
      'syncComplete': 'All offline reports synced successfully.',
      'syncPartial':
          '{synced} offline reports synced. {remaining} still waiting.',
      'syncWaiting': 'Saved reports are still waiting for a stable connection.',
      'syncOfflineLater': 'Still offline. Saved reports will sync later.',
      'approxAreaRequired': 'Approximate area is required.',
    },
    AppLanguage.swahili: {
      'appTitle': 'Usalama wa Wanawake',
      'welcomeTitle': 'USALAMA WA WANAWAKE',
      'welcomeSubtitle': 'Anza safari yako ya kila siku kwa usalama',
      'getStarted': 'Anza',
      'registrationTitle': 'Tengeneza wasifu wako',
      'fullName': 'JINA KAMILI',
      'email': 'BARUA PEPE',
      'password': 'NENOSIRI',
      'confirmPassword': 'THIBITISHA NENOSIRI',
      'signUp': 'Jisajili',
      'fullNameRequired': 'Weka jina kamili.',
      'fullNameShort': 'Jina ni fupi sana.',
      'emailRequired': 'Weka barua pepe.',
      'emailInvalid': 'Weka barua pepe sahihi.',
      'passwordRequired': 'Weka nenosiri.',
      'passwordShort': 'Tumia angalau herufi 6.',
      'confirmPasswordRequired': 'Thibitisha nenosiri.',
      'passwordMismatch': 'Nenosiri hazifanani.',
      'registrationReady': 'Karibu {name}, usajili wako uko tayari.',
      'homeTitle': 'Move Safety',
      'homeSubtitle': 'Vifaa vya kila siku vya kuripoti sehemu moja.',
      'offline': 'Nje ya mtandao',
      'live': 'Mtandao upo',
      'homeOverviewTitle': 'Muhtasari wa leo',
      'homeOverviewOffline':
          'Programu iko tayari kukusanya ripoti bila mtandao.',
      'homeOverviewOnline':
          'Programu imeunganishwa na iko tayari kutuma ripoti moja kwa moja.',
      'noSavedOfflineReports': 'Hakuna ripoti zilizohifadhiwa kwa sasa.',
      'savedOfflineQueue': 'Ripoti {count} zinasubiri kwenye foleni ya nje ya mtandao.',
      'openReportForm': 'Fungua fomu ya ripoti',
      'savedOffline': 'Imehifadhiwa nje ya mtandao',
      'quickAccess': 'Ufikiaji wa haraka',
      'report': 'Ripoti',
      'guide': 'Mwongozo',
      'sync': 'Sawazisha',
      'emergencyGuidance': 'Mwongozo wa dharura',
      'emergencyGuidanceBody':
          'Kama mtu yuko katika hatari ya haraka, wasiliana na huduma za dharura au msaidizi unayemwamini kwanza. Tumia kuripoti baada ya kuwa salama.',
      'reportSectionTitle': 'Fungua fomu ya ripoti',
      'reportSectionSubtitle':
          'Chagua muda wa tukio ndani ya fomu na utume kwa usalama.',
      'offlineSectionTitle': 'Imehifadhiwa nje ya mtandao',
      'offlineSectionSubtitle':
          'Ripoti zimehifadhiwa kwenye simu hii wakati hakuna muunganisho.',
      'guideTitle': 'Mwongozo wa usalama',
      'guideSubtitle': 'Hatua za haraka na vikumbusho vya matumizi ya kila siku.',
      'privacyReminder': 'Kikumbusho cha faragha',
      'privacyReminderBody':
          'Toa maelezo muhimu tu ya kueleza tukio. Epuka kuweka taarifa binafsi zisizo za lazima.',
      'locationGuidance': 'Mwongozo wa eneo',
      'locationGuidanceBody':
          'Tumia eneo la sasa inapowezekana ili ripoti ziwe rahisi kuwekwa kwenye ramani baadaye, hasa wakati wa safari.',
      'syncCenterTitle': 'Kituo cha usawazishaji',
      'syncCenterSubtitle':
          'Hali ya muunganisho na zana za kutuma ripoti zilizohifadhiwa.',
      'settingsTitle': 'Mipangilio',
      'settingsSubtitle':
          'Dhibiti lugha, hali ya mwonekano, vikumbusho, na jinsi programu inavyofanya kazi nje ya mtandao.',
      'themeTitle': 'Mandhari',
      'themeSubtitle':
          'Chagua mtindo wa rangi ambao watu wataona kila siku wanapotumia programu.',
      'languageSetting': 'Lugha',
      'modeSetting': 'Hali ya mwonekano',
      'themeSetting': 'Mtindo wa mandhari',
      'english': 'Kiingereza',
      'swahili': 'Kiswahili',
      'lightMode': 'Mwanga',
      'darkMode': 'Giza',
      'autoSyncTitle': 'Sawazisha ripoti zilizohifadhiwa moja kwa moja',
      'autoSyncSubtitle':
          'Muunganisho ukirudi, jaribu kutuma ripoti zilizosubiri moja kwa moja.',
      'locationHintsTitle': 'Onyesha mwongozo wa eneo',
      'locationHintsSubtitle':
          'Hifadhi vikumbusho vya kila siku vinavyosaidia kuchukua eneo sahihi.',
      'privacyTipsTitle': 'Onyesha vikumbusho vya faragha',
      'privacyTipsSubtitle':
          'Hifadhi vikumbusho vifupi kuhusu maelezo gani ya kuweka kwenye ripoti.',
      'drawerHome': 'Nyumbani',
      'drawerReport': 'Fungua fomu ya ripoti',
      'drawerOffline': 'Imehifadhiwa nje ya mtandao',
      'drawerGuide': 'Mwongozo wa usalama',
      'drawerSyncCenter': 'Kituo cha usawazishaji',
      'drawerSettings': 'Mipangilio',
      'drawerThemes': 'Mandhari',
      'queueEmptyTitle': 'Hakuna kinachosubiri nje ya mtandao',
      'queueEmptyBody':
          'Muunganisho unapokosekana, ripoti zilizotumwa zitaonekana hapa.',
      'createReport': 'Tengeneza ripoti',
      'pendingQueue': 'Foleni inayosubiri',
      'offlineReport': 'Ripoti ya nje ya mtandao',
      'queuedAt': 'Imewekwa kwenye foleni {time}',
      'connectionSnapshot': 'Muhtasari wa muunganisho',
      'currentMode': 'Hali ya sasa',
      'offlineCapture': 'Kukusanya bila mtandao',
      'connected': 'Imeunganishwa',
      'pendingReports': 'Ripoti zinazosubiri',
      'autoSync': 'Usawazishaji wa moja kwa moja',
      'enabled': 'Umewashwa',
      'manualOnly': 'Kwa mkono tu',
      'syncNow': 'Sawazisha sasa',
      'syncing': 'Inasawazisha...',
      'retryConnection': 'Jaribu muunganisho tena',
      'anonymousReporting': 'Kuripoti bila jina',
      'heroTitleA': 'Ripoti matukio\nyasiyo salama kwa\n',
      'heroTitleB': 'uwazi na uangalifu.',
      'heroBody':
          'Tumia urambazaji wa haraka kusonga ndani ya programu, kisha fungua fomu pale unapokuwa tayari kurekodi tukio.',
      'newIncidentReport': 'Ripoti mpya ya tukio',
      'reportFormBody':
          'Fomu inaendelea na mtiririko ule ule wa kuripoti, lakini sasa iko kwenye sehemu yake ya ripoti.',
      'detailsReady': 'Maelezo {count} kati ya 8 yako tayari',
      'incidentCategory': 'Aina ya tukio',
      'locationType': 'Aina ya eneo',
      'selectDateTime': 'Chagua tarehe na saa',
      'approxAreaName': 'Jina la eneo la kukadiria',
      'wardDistrict': 'Wadi au wilaya',
      'currentLocationReady': 'Eneo la sasa lipo tayari',
      'attachCurrentLocation': 'Ambatisha eneo lako la sasa',
      'currentLocationBody':
          'Viunganishi vya eneo vimehifadhiwa nyuma ya pazia na vitatumwa pamoja na ripoti.',
      'attachLocationBody':
          'Programu itatumia eneo la simu ili watu wasilazimike kuandika latitude au longitude.',
      'gettingLocation': 'Inachukua eneo la sasa...',
      'updateCurrentLocation': 'Sasisha eneo la sasa',
      'useCurrentLocation': 'Tumia eneo la sasa',
      'whatHappened': 'Nini kilitokea?',
      'whatHappenedHint':
          'Eleza tukio kwa kutumia maelezo muhimu tu ya kulielewa.',
      'consentText':
          'Ninakubali kuwa ripoti hii inaweza kuhifadhiwa kwa uchambuzi wa usalama.',
      'submitReport': 'Tuma ripoti',
      'submitting': 'Inatuma...',
      'incidentTimeRequired': 'Tafadhali chagua muda tukio lilipotokea.',
      'taxonomyWait':
          'Tafadhali subiri aina za tukio na eneo zipakie.',
      'locationRequired':
          'Tafadhali gusa \'Tumia eneo la sasa\' kabla ya kutuma.',
      'consentRequired':
          'Ridhaa lazima ikubaliwe kabla ya kutuma.',
      'locationCaptured': 'Eneo la sasa limechukuliwa.',
      'locationServiceOff': 'Washa huduma ya eneo la simu, kisha jaribu tena.',
      'locationPermissionDenied': 'Ruhusa ya eneo imekataliwa.',
      'locationPermissionForever':
          'Ruhusa ya eneo imekataliwa kabisa. Irudishe kwenye mipangilio ya simu.',
      'locationCaptureFailed':
          'Imeshindwa kupata eneo la sasa. Tafadhali jaribu tena.',
      'offlineStatusTitle': 'Hali ya nje ya mtandao imewashwa',
      'offlineStatusTitleSaved': 'Ripoti zinasubiri kusawazishwa',
      'offlineStatusBody':
          'Fomu ya ripoti inatumia aina zilizojengwa ndani ya programu. Ripoti mpya zitahifadhiwa kwenye simu hii na kutumwa baadaye. Ripoti zinazosubiri: {count}.',
      'offlineSavedBody':
          'Muunganisho umerudi, lakini ripoti {count} bado zinasubiri kusawazishwa.',
      'tryConnectionAgain': 'Jaribu muunganisho tena',
      'submissionSaved': 'Ripoti imehifadhiwa',
      'savedOfflineTitle': 'Imehifadhiwa nje ya mtandao',
      'reference': 'Rejea',
      'localRef': 'Rejea ya simu',
      'loadingTaxonomies': 'Inapakia aina za tukio na eneo...',
      'quickStep1': 'Tukio',
      'quickStep2': 'Eneo',
      'quickStep3': 'Mahali',
      'quickStep4': 'Tuma',
      'reportFlowTitle': 'Mtiririko wa ripoti',
      'reportFlowBody':
          'Pitia ripoti kwa hatua zilizo wazi kabla ya kuituma.',
      'syncSavedReports': 'Sawazisha ripoti zilizohifadhiwa',
      'syncComplete': 'Ripoti zote za nje ya mtandao zimesawazishwa vizuri.',
      'syncPartial':
          'Ripoti {synced} zimesawazishwa. {remaining} bado zinasubiri.',
      'syncWaiting':
          'Ripoti zilizohifadhiwa bado zinasubiri muunganisho thabiti.',
      'syncOfflineLater':
          'Bado nje ya mtandao. Ripoti zilizohifadhiwa zitasawazishwa baadaye.',
      'approxAreaRequired': 'Jaza jina la eneo la kukadiria.',
    },
  };

  String text(String key, [Map<String, String> replacements = const {}]) {
    final translation = _translations[language]?[key] ?? key;
    return replacements.entries.fold(
      translation,
      (value, entry) => value.replaceAll('{${entry.key}}', entry.value),
    );
  }

  String languageName(AppLanguage value) {
    return switch (value) {
      AppLanguage.english => text('english'),
      AppLanguage.swahili => text('swahili'),
    };
  }

  String themeModeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => text('lightMode'),
      ThemeMode.dark => text('darkMode'),
      ThemeMode.system => text('lightMode'),
    };
  }

  String themePresetName(AppThemePreset preset) {
    return switch (preset) {
      AppThemePreset.roseDawn => language == AppLanguage.swahili
          ? 'Waridi la Asubuhi'
          : 'Rose Dawn',
      AppThemePreset.oceanCalm => language == AppLanguage.swahili
          ? 'Bahari Tulivu'
          : 'Ocean Calm',
      AppThemePreset.emeraldGlow => language == AppLanguage.swahili
          ? 'Zumaridi Angavu'
          : 'Emerald Glow',
    };
  }

  String themePresetDescription(AppThemePreset preset) {
    return switch (preset) {
      AppThemePreset.roseDawn => language == AppLanguage.swahili
          ? 'Rangi laini za waridi kwa hisia ya joto na matumaini.'
          : 'Soft rose tones for a warm and hopeful feel.',
      AppThemePreset.oceanCalm => language == AppLanguage.swahili
          ? 'Bluu tulivu na aqua kwa mwonekano safi wa usiku na mchana.'
          : 'Calm blue and aqua for a clean day-and-night look.',
      AppThemePreset.emeraldGlow => language == AppLanguage.swahili
          ? 'Kijani na dhahabu kwa mwonekano wenye nguvu na utulivu.'
          : 'Emerald and gold for an energetic but grounded look.',
    };
  }

  String categoryName(String code, String fallback) {
    final english = {
      'VERBAL': 'Verbal harassment',
      'STALKING': 'Stalking or persistent following',
      'GESTURES': 'Unwanted sexual comments or gestures',
      'TOUCHING': 'Unwanted touching',
      'THREAT': 'Physical intimidation or threat',
      'ASSAULT': 'Physical assault',
      'AUTHORITY_ABUSE': 'Abuse by authority figure',
      'OTHER': 'Other safety incident',
    };
    final swahili = {
      'VERBAL': 'Unyanyasaji wa maneno',
      'STALKING': 'Kufuatwa au kusumbuliwa mara kwa mara',
      'GESTURES': 'Maoni au ishara za kingono zisizotakiwa',
      'TOUCHING': 'Kuguswa bila ridhaa',
      'THREAT': 'Vitisho au hofu ya kimwili',
      'ASSAULT': 'Shambulio la kimwili',
      'AUTHORITY_ABUSE': 'Unyanyasaji wa mwenye mamlaka',
      'OTHER': 'Tukio jingine la usalama',
    };

    return switch (language) {
      AppLanguage.english => english[code] ?? fallback,
      AppLanguage.swahili => swahili[code] ?? fallback,
    };
  }

  String locationTypeName(String code, String fallback) {
    final english = {
      'STREET': 'Street or roadside',
      'BUS_STOP': 'Bus stop or terminal',
      'PUBLIC_TRANSPORT': 'Public transport vehicle',
      'MARKET': 'Market or shopping area',
      'SCHOOL': 'School or university area',
      'WORKPLACE': 'Workplace or office area',
      'PARK': 'Park or recreation area',
      'ENTERTAINMENT': 'Bar, club, or entertainment area',
      'RESIDENTIAL': 'Residential area',
      'OTHER': 'Other public space',
    };
    final swahili = {
      'STREET': 'Barabara au kando ya njia',
      'BUS_STOP': 'Kituo cha basi au terminali',
      'PUBLIC_TRANSPORT': 'Usafiri wa umma',
      'MARKET': 'Soko au eneo la ununuzi',
      'SCHOOL': 'Shule au chuo',
      'WORKPLACE': 'Mahali pa kazi au ofisi',
      'PARK': 'Bustani au eneo la burudani',
      'ENTERTAINMENT': 'Baa, klabu, au burudani',
      'RESIDENTIAL': 'Eneo la makazi',
      'OTHER': 'Eneo jingine la umma',
    };

    return switch (language) {
      AppLanguage.english => english[code] ?? fallback,
      AppLanguage.swahili => swahili[code] ?? fallback,
    };
  }

  String statusLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('queued')) {
      return language == AppLanguage.swahili ? 'imehifadhiwa' : 'queued offline';
    }
    if (normalized.contains('submitted')) {
      return language == AppLanguage.swahili ? 'imetumwa' : 'submitted';
    }
    return value;
  }
}
